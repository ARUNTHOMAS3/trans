// PATH: lib/modules/auth/repositories/auth_repository.dart

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';
  static const _boxName = 'config';

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Box get _box => Hive.box(_boxName);

  /// Login user with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      AppLogger.debug('Attempting login', data: {'email': email}, module: 'auth');

      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.success) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        await _saveToken(token);
        await _saveUserData(userData);

        AppLogger.debug('Login successful', data: {'email': email}, module: 'auth');
        return {'token': token, 'user': User.fromJson(userData)};
      } else {
        throw Exception(response.message ?? 'Login failed');
      }
    } catch (e) {
      AppLogger.error('Login failed', error: e, module: 'auth');
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      AppLogger.debug('Logging out user', module: 'auth');

      final token = getToken();
      if (token != null) {
        await _apiClient.post('/auth/logout', data: {});
      }

      await _clearStoredData();
      AppLogger.debug('Logout successful', module: 'auth');
    } catch (e) {
      AppLogger.error('Logout error', error: e, module: 'auth');
      await _clearStoredData();
      rethrow;
    }
  }

  /// Refresh authentication token
  Future<String?> refreshToken() async {
    try {
      final currentToken = getToken();
      if (currentToken == null) return null;

      final response = await _apiClient.post(
        '/auth/refresh',
        data: {'token': currentToken},
      );

      if (response.success) {
        final data = response.data as Map<String, dynamic>;
        final newToken = data['access_token'] as String;
        await _saveToken(newToken);
        return newToken;
      }
    } catch (e) {
      AppLogger.error('Token refresh failed', error: e, module: 'auth');
    }
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
      AppLogger.debug('Registering new user', data: {'email': email}, module: 'auth');

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
        final userData = response.data as Map<String, dynamic>;
        AppLogger.debug('User registered successfully', data: {'email': email}, module: 'auth');
        return User.fromJson(userData);
      } else {
        throw Exception(response.message ?? 'Registration failed');
      }
    } catch (e) {
      AppLogger.error('Registration failed', error: e, module: 'auth');
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

      final response = await _apiClient.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Password change failed');
      }

      AppLogger.debug('Password changed successfully', module: 'auth');
    } catch (e) {
      AppLogger.error('Password change failed', error: e, module: 'auth');
      rethrow;
    }
  }

  /// Get current user profile
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/profile');

      if (response.success) {
        final userData = response.data as Map<String, dynamic>;
        final user = User.fromJson(userData);
        await _saveUserData(userData);
        return user;
      }
    } catch (e) {
      AppLogger.error('Failed to get current user', error: e, module: 'auth');
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
      await _box.delete(_userKey);
    } catch (e) {
      AppLogger.error('Failed to clear stored data', error: e, module: 'auth');
    }
  }
}
