// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/documents/documents_providers.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class NewFolderDialog extends ConsumerStatefulWidget {
  const NewFolderDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(top: 0.0),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 500,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const NewFolderDialog(),
            ),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<NewFolderDialog> createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends ConsumerState<NewFolderDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _permissions = 'all'; // 'all' or 'custom'
  bool _isDropdownOpen = false;
  final List<String> _selectedOptions = ['Admin'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildDropdownItem({
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: Colors.blue.shade50,
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: Colors.grey.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Folder',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        
        // Body Content
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Folder Name Label
              Row(
                children: const [
                  Text(
                    'Folder Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFC5221F), // Red text for required field label
                    ),
                  ),
                  Text(
                    '*',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC5221F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Folder Name Input Box
              SizedBox(
                height: 36,
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.primaryBlue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Folder Permissions Label
              Row(
                children: const [
                  Text(
                    'Folder Permissions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFC5221F), // Red text for required field label
                    ),
                  ),
                  Text(
                    '*',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC5221F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Radio 1: All Users
              Row(
                children: [
                  Radio<String>(
                    value: 'all',
                    groupValue: _permissions,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _permissions = val);
                      }
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'All users with permission to access documents.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
              // Radio 2: Custom
              Row(
                children: [
                  Radio<String>(
                    value: 'custom',
                    groupValue: _permissions,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _permissions = val);
                      }
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Custom',
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
              if (_permissions == 'custom') ...[
                const SizedBox(height: 10),
                // Custom Permissions Selection Dropdown
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDropdownOpen = !_isDropdownOpen;
                    });
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isDropdownOpen ? const Color(0xFF1E88E5) : AppTheme.borderColor,
                        width: _isDropdownOpen ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _selectedOptions.isEmpty
                              ? const Text(
                                  'Select Users or Roles',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                )
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: _selectedOptions.map((opt) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            opt,
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedOptions.remove(opt);
                                              });
                                            },
                                            child: Icon(LucideIcons.x, size: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        Icon(
                          _isDropdownOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                          size: 14,
                          color: _isDropdownOpen ? const Color(0xFF1E88E5) : Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isDropdownOpen) ...[
                  const SizedBox(height: 4),
                  // Dropdown menu overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar inside dropdown
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 32,
                            child: TextField(
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search',
                                prefixIcon: const Icon(LucideIcons.search, size: 14),
                                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(color: AppTheme.borderColor),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: AppTheme.borderColor),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Users Section (Only show if not already selected)
                        if (!_selectedOptions.contains('zabnixprivatelimited')) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Text(
                              'Users',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          _buildDropdownItem(
                            value: 'zabnixprivatelimited',
                            isSelected: false,
                            onTap: () {
                              setState(() {
                                _selectedOptions.add('zabnixprivatelimited');
                                _isDropdownOpen = false;
                              });
                            },
                          ),
                        ],
                        // Roles Section (Only show if any role is not selected)
                        if (!_selectedOptions.contains('Admin') || !_selectedOptions.contains('Staff')) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Text(
                              'Roles',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          if (!_selectedOptions.contains('Admin'))
                            _buildDropdownItem(
                              value: 'Admin',
                              isSelected: false,
                              onTap: () {
                                setState(() {
                                    _selectedOptions.add('Admin');
                                    _isDropdownOpen = false;
                                });
                              },
                            ),
                          if (!_selectedOptions.contains('Staff'))
                            _buildDropdownItem(
                              value: 'Staff',
                              isSelected: false,
                              onTap: () {
                                setState(() {
                                  _selectedOptions.add('Staff');
                                  _isDropdownOpen = false;
                                });
                              },
                            ),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              
              // Info Message Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE), // Light blue background
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.info,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'By default, this folder is visible to all admins in Zoho Inventory and to admins in your integrated apps: Zoho Books and Zoho Billing.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        
        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Save button (green background, success style)
              SizedBox(
                height: 32,
                child: ZButton.primary(
                  label: 'Save',
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      final current = ref.read(documentsFoldersProvider);
                      ref.read(documentsFoldersProvider.notifier).state = [...current, name];
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Cancel button
              SizedBox(
                height: 32,
                child: ZButton.secondary(
                  label: 'Cancel',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
