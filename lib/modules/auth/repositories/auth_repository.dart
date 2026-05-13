// PATH: lib/modules/auth/repositories/auth_repository.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresAtKey = 'auth_expires_at';
  static const _userKey = 'user_data';
  static const _selectedTenantIdKey = 'selected_tenant_id';
  static const _selectedTenantTypeKey = 'selected_tenant_type';
  static const _selectedEntityIdKey = 'selected_entity_id';
  static const _selectedTenantRouteSystemIdKey =
      'selected_tenant_route_system_id';
  static const _boxName = 'config';

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Box get _box => Hive.box(_boxName);

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Login user with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      AppLogger.debug(
        'Attempting login',
        data: {'email': email},
        module: 'auth',
      );

      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.success) {
        final data = _asMap(response.data);
        if (data == null) {
          throw Exception('Invalid login response payload');
        }
        final token = data['access_token'] as String;
        final refreshToken = (data['refresh_token'] as String?) ?? '';
        final expiresAt = (data['expires_at'] as num?)?.toInt();
        final userData = _asMap(data['user']);
        if (userData == null) {
          throw Exception('Invalid login user payload');
        }

        await _saveToken(token);
        await _saveRefreshToken(refreshToken);
        await _saveExpiresAt(expiresAt);
        await _saveUserData(userData);

        AppLogger.debug(
          'Login successful',
          data: {'email': email},
          module: 'auth',
        );
        return {
          'token': token,
          'refreshToken': refreshToken,
          'user': User.fromJson(userData),
        };
      } else {
        throw Exception(response.message ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      AppLogger.debug('Logging out user', module: 'auth');

      final token = getToken();
      final refreshToken = getRefreshToken();
      if (token != null) {
        await _apiClient.post(
          '/auth/logout',
          data: refreshToken != null ? {'refresh_token': refreshToken} : {},
        );
      }

      await _clearStoredData();
      AppLogger.debug('Logout successful', module: 'auth');
    } catch (e) {
      await _clearStoredData();
      rethrow;
    }
  }

  /// Refresh authentication token
  Future<String?> refreshToken() async {
    try {
      final currentToken = getToken();
      final refreshToken = getRefreshToken();
      if (currentToken == null || refreshToken == null) return null;

      final response = await _apiClient.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.success) {
        final data = _asMap(response.data);
        if (data == null) {
          return null;
        }
        final newToken = data['access_token'] as String;
        final newRefreshToken =
            (data['refresh_token'] as String?) ?? refreshToken;
        final expiresAt = (data['expires_at'] as num?)?.toInt();
        await _saveToken(newToken);
        await _saveRefreshToken(newRefreshToken);
        await _saveExpiresAt(expiresAt);
        final userData = _asMap(data['user']);
        if (userData != null) {
          await _saveUserData(userData);
        }
        return newToken;
      }
    } catch (e) {}
    return null;
  }

  /// Register new user (admin only)
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      AppLogger.debug(
        'Registering new user',
        data: {'email': email},
        module: 'auth',
      );

      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role,
        },
      );

      if (response.success) {
        final userData = _asMap(response.data);
        if (userData == null) {
          throw Exception('Invalid register response payload');
        }
        AppLogger.debug(
          'User registered successfully',
          data: {'email': email},
          module: 'auth',
        );
        return User.fromJson(userData);
      } else {
        throw Exception(response.message ?? 'Registration failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.debug('Changing user password', module: 'auth');

      final refreshToken = getRefreshToken();
      if (refreshToken == null) {
        throw Exception('Missing refresh token');
      }

      final response = await _apiClient.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'refresh_token': refreshToken,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Password change failed');
      }

      AppLogger.debug('Password changed successfully', module: 'auth');
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user profile
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/profile');

      if (response.success) {
        final userData = _asMap(response.data);
        if (userData == null) {
          AppLogger.warning(
            'Auth profile returned empty/non-map payload',
            module: 'auth',
          );
          return null;
        }
        final user = User.fromJson(userData);
        await _saveUserData(userData);
        return user;
      }
    } catch (e) {
      AppLogger.error(
        'Failed to fetch current user profile',
        error: e,
        module: 'auth',
      );
    }
    return null;
  }

  /// Check if user is authenticated
  bool isAuthenticated() => getToken() != null;

  /// Get stored authentication token (synchronous — Hive is in-memory)
  String? getToken() {
    try {
      return _box.get(_tokenKey) as String?;
    } catch (e) {
      AppLogger.error('Failed to read token', error: e, module: 'auth');
      return null;
    }
  }

  String? getRefreshToken() {
    try {
      return _box.get(_refreshTokenKey) as String?;
    } catch (e) {
      AppLogger.error('Failed to read refresh token', error: e, module: 'auth');
      return null;
    }
  }

  int? getExpiresAt() {
    try {
      final value = _box.get(_expiresAtKey);
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      AppLogger.error('Failed to read auth expiry', error: e, module: 'auth');
      return null;
    }
  }

  /// Get stored user data
  User? getUser() {
    try {
      final userDataString = _box.get(_userKey) as String?;
      if (userDataString != null) {
        final userData = Map<String, dynamic>.from(
          jsonDecode(userDataString) as Map,
        );
        return User.fromJson(userData);
      }
    } catch (e) {
      AppLogger.error('Failed to read user data', error: e, module: 'auth');
    }
    return null;
  }

  // Private methods
  Future<void> _saveToken(String token) async {
    try {
      await _box.put(_tokenKey, token);
    } catch (e) {
      AppLogger.error('Failed to save token', error: e, module: 'auth');
      rethrow;
    }
  }

  Future<void> _saveRefreshToken(String refreshToken) async {
    try {
      await _box.put(_refreshTokenKey, refreshToken);
    } catch (e) {
      AppLogger.error('Failed to save refresh token', error: e, module: 'auth');
      rethrow;
    }
  }

  Future<void> _saveExpiresAt(int? expiresAt) async {
    try {
      if (expiresAt == null) {
        await _box.delete(_expiresAtKey);
        return;
      }
      await _box.put(_expiresAtKey, expiresAt);
    } catch (e) {
      AppLogger.error('Failed to save auth expiry', error: e, module: 'auth');
      rethrow;
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      await _box.put(_userKey, jsonEncode(userData));
    } catch (e) {
      AppLogger.error('Failed to save user data', error: e, module: 'auth');
      rethrow;
    }
  }

  Future<void> _clearStoredData() async {
    try {
      await _box.delete(_tokenKey);
      await _box.delete(_refreshTokenKey);
      await _box.delete(_expiresAtKey);
      await _box.delete(_userKey);
      await _box.delete(_selectedTenantIdKey);
      await _box.delete(_selectedTenantTypeKey);
      await _box.delete(_selectedEntityIdKey);
      await _box.delete(_selectedTenantRouteSystemIdKey);
    } catch (e) {
      AppLogger.error('Failed to clear stored data', error: e, module: 'auth');
    }
  }

  String? getSelectedTenantId() {
    try {
      return (_box.get(_selectedTenantIdKey) as String?)?.trim();
    } catch (_) {
      return null;
    }
  }

  String? getSelectedTenantType() {
    try {
      return (_box.get(_selectedTenantTypeKey) as String?)?.trim();
    } catch (_) {
      return null;
    }
  }

  String? getSelectedTenantRouteSystemId() {
    try {
      return (_box.get(_selectedTenantRouteSystemIdKey) as String?)?.trim();
    } catch (_) {
      return null;
    }
  }

  String? getSelectedEntityId() {
    try {
      return (_box.get(_selectedEntityIdKey) as String?)?.trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> setSelectedTenant({
    required String id,
    required String type,
    String? routeSystemId,
    String? entityId,
  }) async {
    await _box.put(_selectedTenantIdKey, id.trim());
    await _box.put(_selectedTenantTypeKey, type.trim());
    if (entityId != null && entityId.trim().isNotEmpty) {
      await _box.put(_selectedEntityIdKey, entityId.trim());
    }
    if (routeSystemId != null && routeSystemId.trim().isNotEmpty) {
      await _box.put(_selectedTenantRouteSystemIdKey, routeSystemId.trim());
    }
  }

  Future<void> requestPasswordReset(String email, {String? redirectTo}) async {
    try {
      final response = await _apiClient.post(
        '/auth/forgot-password',
        data: {
          'email': email,
          if (redirectTo != null && redirectTo.isNotEmpty)
            'redirect_to': redirectTo,
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Password reset request failed');
      }
    } catch (e) {
      rethrow;
    }
  }
}
