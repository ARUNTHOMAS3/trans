// PATH: lib/modules/auth/presentation/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import '../repositories/user_management_repository.dart';
import '../models/user_profile_model.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  UserProfile? _profile;
  bool _isLoading = true;
  late final UserManagementRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = UserManagementRepository(apiClient: ApiClient());
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _repository.getCurrentUserProfile();

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }

  void _showEditProfileDialog() {
    // Implementation for editing profile
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit profile functionality coming soon')),
    );
  }

  void _showChangePasswordDialog() {
    // Implementation for changing password
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Change password functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.edit), onPressed: _showEditProfileDialog),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _profile == null
          ? Center(child: Text('No profile data available'))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // Avatar
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  _profile!.fullName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _profile!.isVerified
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _profile!.isVerified
                                        ? Icons.verified
                                        : Icons.report,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Name and Role
                          Text(
                            _profile!.fullName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(
                                _profile!.role,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _formatRole(_profile!.role),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _getRoleColor(_profile!.role),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _profile!.email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Personal Information
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(),
                          _buildInfoRow(
                            context,
                            Icons.phone,
                            'Phone Number',
                            _profile!.phoneNumber ?? 'Not provided',
                          ),
                          _buildInfoRow(
                            context,
                            Icons.business,
                            'Department',
                            _profile!.department ?? 'Not specified',
                          ),
                          _buildInfoRow(
                            context,
                            Icons.work,
                            'Position',
                            _profile!.position ?? 'Not specified',
                          ),
                          _buildInfoRow(
                            context,
                            Icons.location_city,
                            'Organization',
                            _profile!.orgName,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Account Information
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(),
                          _buildInfoRow(
                            context,
                            Icons.vpn_key,
                            'User ID',
                            _profile!.id,
                          ),
                          _buildInfoRow(
                            context,
                            Icons.login,
                            'Last Login',
                            _profile!.lastLoginAt != null
                                ? '${_profile!.lastLoginAt!.day}/${_profile!.lastLoginAt!.month}/${_profile!.lastLoginAt!.year}'
                                : 'Never',
                          ),
                          _buildInfoRow(
                            context,
                            Icons.calendar_today,
                            'Member Since',
                            '${_profile!.createdAt.day}/${_profile!.createdAt.month}/${_profile!.createdAt.year}',
                          ),
                          _buildStatusRow(
                            context,
                            'Account Status',
                            _profile!.isActive ? 'Active' : 'Inactive',
                            _profile!.isActive,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Action Buttons
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showChangePasswordDialog,
                              icon: Icon(Icons.lock),
                              label: Text('Change Password'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _loadProfile,
                              icon: Icon(Icons.refresh),
                              label: Text('Refresh Profile'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    String label,
    String value,
    bool isActive,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.info, size: 20, color: theme.colorScheme.primary),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.green : AppTheme.errorRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'ho_admin':
        return Colors.blue;
      case 'outlet_manager':
        return Colors.orange;
      case 'outlet_staff':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Administrator';
      case 'ho_admin':
        return 'Head Office Admin';
      case 'outlet_manager':
        return 'Outlet Manager';
      case 'outlet_staff':
        return 'Outlet Staff';
      default:
        return role;
    }
  }
}
