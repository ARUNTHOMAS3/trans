// PATH: lib/modules/auth/repositories/user_management_repository.dart

import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';

class UserManagementRepository {
  final ApiClient _apiClient;

  UserManagementRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  /// Get all users in organization
  Future<List<User>> getUsers() async {
    try {
      final response = await _apiClient.get('/users');

      if (response.success) {
        // Handle both direct list and wrapped response
        late List<dynamic> usersData;
        if (response.data is List) {
          usersData = response.data as List<dynamic>;
        } else if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          usersData = dataMap['data'] ?? dataMap['users'] ?? [];
        } else {
          throw Exception('Unexpected response format: ${response.data.runtimeType}');
        }
        
        return usersData
            .map((userJson) => User.fromJson(userJson as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response.message ?? 'Failed to fetch users');
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final response = await _apiClient.get('/users/$userId');

      if (response.success) {
        final userData = response.data as Map<String, dynamic>;
        return User.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
    return null;
  }

  /// Create new user
  Future<User> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
    String? department,
    String? position,
  }) async {
    try {
      final response = await _apiClient.post(
        '/users',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'role': role,
          'phoneNumber': phoneNumber,
          'department': department,
          'position': position,
        },
      );

      if (response.success) {
        final userData = response.data as Map<String, dynamic>;
        return User.fromJson(userData);
      } else {
        throw Exception(response.message ?? 'Failed to create user');
      }
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  /// Update user
  Future<User> updateUser({
    required String userId,
    String? fullName,
    String? role,
    String? phoneNumber,
    String? department,
    String? position,
    bool? isActive,
  }) async {
    try {
      final response = await _apiClient.put(
        '/users/$userId',
        data: {
          'fullName': fullName,
          'role': role,
          'phoneNumber': phoneNumber,
          'department': department,
          'position': position,
          'isActive': isActive,
        },
      );

      if (response.success) {
        final userData = response.data as Map<String, dynamic>;
        return User.fromJson(userData);
      } else {
        throw Exception(response.message ?? 'Failed to update user');
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      final response = await _apiClient.delete('/users/$userId');

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to delete user');
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final response = await _apiClient.get('/users/profile');

      if (response.success) {
        final profileData = response.data as Map<String, dynamic>;
        return UserProfile.fromJson(profileData);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
    return null;
  }

  /// Update current user profile
  Future<UserProfile> updateCurrentUserProfile({
    String? fullName,
    String? phoneNumber,
    String? department,
    String? position,
    String? avatarUrl,
  }) async {
    try {
      final response = await _apiClient.put(
        '/users/profile',
        data: {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'department': department,
          'position': position,
          'avatarUrl': avatarUrl,
        },
      );

      if (response.success) {
        final profileData = response.data as Map<String, dynamic>;
        return UserProfile.fromJson(profileData);
      } else {
        throw Exception(response.message ?? 'Failed to update profile');
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        '/users/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to change password');
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }

  /// Get user activity log
  Future<List<Map<String, dynamic>>> getUserActivityLog({
    String? userId,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await _apiClient.get(
        '/users/${userId ?? 'me'}/activity-log',
        queryParameters: queryParams,
      );

      if (response.success) {
        return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
      } else {
        throw Exception(response.message ?? 'Failed to fetch activity log');
      }
    } catch (e) {
      debugPrint('Error fetching activity log: $e');
      return [];
    }
  }
}
