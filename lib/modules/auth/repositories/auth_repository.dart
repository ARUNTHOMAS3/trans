// PATH: lib/modules/auth/repositories/auth_repository.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Login user with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('Attempting login for user: $email');

      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.success) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        // Save token and user data securely
        await _saveToken(token);
        await _saveUserData(userData);

        debugPrint('Login successful for user: $email');
        return {'token': token, 'user': User.fromJson(userData)};
      } else {
        throw Exception(response.message ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      debugPrint('Logging out user');

      final token = await getToken();
      if (token != null) {
        await _apiClient.post('/auth/logout', data: {});
      }

      // Clear stored data
      await _clearStoredData();
      debugPrint('Logout successful');
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still clear local data even if API call fails
      await _clearStoredData();
      rethrow;
    }
  }

  /// Refresh authentication token
  Future<String?> refreshToken() async {
    try {
      final currentToken = await getToken();
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
      debugPrint('Token refresh failed: $e');
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
      debugPrint('Registering new user: $email');

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
        debugPrint('User registered successfully: $email');
        return User.fromJson(userData);
      } else {
        throw Exception(response.message ?? 'Registration failed');
      }
    } catch (e) {
      debugPrint('Registration failed: $e');
      rethrow;
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint('Changing user password');

      final response = await _apiClient.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Password change failed');
      }

      debugPrint('Password changed successfully');
    } catch (e) {
      debugPrint('Password change failed: $e');
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
        await _saveUserData(userData); // Update stored user data
        return user;
      }
    } catch (e) {
      debugPrint('Failed to get current user: $e');
    }
    return null;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  /// Get stored authentication token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('Failed to read token: $e');
      return null;
    }
  }

  /// Get stored user data
  Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userKey);
      if (userDataString != null) {
        final userData = Map<String, dynamic>.from(
          jsonDecode(userDataString) as Map,
        );
        return User.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Failed to read user data: $e');
    }
    return null;
  }

  // Private methods
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      debugPrint('Failed to save token: $e');
      rethrow;
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(userData));
    } catch (e) {
      debugPrint('Failed to save user data: $e');
      rethrow;
    }
  }

  Future<void> _clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Failed to clear stored data: $e');
    }
  }
}
