// PATH: lib/modules/auth/presentation/user_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import '../models/user_model.dart';
import '../repositories/user_management_repository.dart';
import '../widgets/user_list_tile.dart';
import '../widgets/user_form_dialog.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late final UserManagementRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = UserManagementRepository(apiClient: ApiClient());
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _repository.getUsers();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        onUserSaved: (user) {
          setState(() {
            _users.add(user);
          });
          Navigator.pop(context);
          ZerpaiToast.saved(context, 'User');
        },
      ),
    );
  }

  void _showEditUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        user: user,
        onUserSaved: (updatedUser) {
          setState(() {
            final index = _users.indexWhere((u) => u.id == updatedUser.id);
          if (index != -1) {
              _users[index] = updatedUser;
            }
          });
          Navigator.pop(context);
          ZerpaiToast.saved(context, 'User');
        },
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _users.removeWhere((u) => u.id == user.id);
      });
      if (!mounted) return;
      ZerpaiToast.deleted(context, 'User');
    }
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;

    return _users.where((user) {
      final query = _searchQuery.toLowerCase();
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Add User Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: Icon(Icons.add),
                  label: Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Users List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Add your first user to get started'
                              : 'No users match your search',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return UserListTile(
                        user: user,
                        onEdit: () => _showEditUserDialog(user),
                        onDelete: () => _deleteUser(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
