// PATH: lib/modules/auth/widgets/user_form_dialog.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserFormDialog extends StatefulWidget {
  final User? user;
  final Function(User) onUserSaved;

  const UserFormDialog({super.key, this.user, required this.onUserSaved});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  String _selectedRole = 'outlet_staff';
  bool _isEditing = false;

  final List<Map<String, String>> _roles = [
    {'value': 'ho_admin', 'label': 'Head Office Admin'},
    {'value': 'outlet_manager', 'label': 'Outlet Manager'},
    {'value': 'outlet_staff', 'label': 'Outlet Staff'},
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.user != null;

    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _fullNameController = TextEditingController(
      text: widget.user?.fullName ?? '',
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    if (_isEditing) {
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _saveUser() {
    if (!_formKey.currentState!.validate()) return;

    final user = User(
      id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      email: _emailController.text.trim(),
      fullName: _fullNameController.text.trim(),
      role: _selectedRole,
      orgId: widget.user?.orgId ?? 'default-org',
      orgName: widget.user?.orgName ?? 'Default Organization',
      isActive: widget.user?.isActive ?? true,
      createdAt: widget.user?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onUserSaved(user);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit User' : 'Add New User'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter full name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Role Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role['value'],
                    child: Text(role['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Password fields (only for new users)
              if (!_isEditing) ...[
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (!_isEditing && (value == null || value.isEmpty)) {
                      return 'Please enter password';
                    }
                    if (value != null && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (!_isEditing && (value == null || value.isEmpty)) {
                      return 'Please confirm password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
              ],

              // Active Status (editing only)
              if (_isEditing)
                SwitchListTile(
                  title: Text('Active Status'),
                  value: widget.user?.isActive ?? true,
                  onChanged: null, // Disabled for now
                  secondary: Icon(Icons.power_settings_new),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveUser,
          child: Text(_isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
