import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';

class LockConfiguration {
  final String name;
  final List<String> restrictedActions;

  const LockConfiguration({
    required this.name,
    required this.restrictedActions,
  });
}

class LockRecordDialog extends StatefulWidget {
  final String title;
  final List<LockConfiguration> configurations;
  final Function(LockConfiguration configuration, String reason) onLock;

  const LockRecordDialog({
    super.key,
    required this.title,
    this.configurations = const [
      LockConfiguration(name: 'rwrwe', restrictedActions: ['Edit', 'Delete']),
      LockConfiguration(
        name: 'Strict Lock',
        restrictedActions: ['Edit', 'Delete', 'Void'],
      ),
      LockConfiguration(
        name: 'Full Lock',
        restrictedActions: ['Edit', 'Delete', 'Void', 'Send Email'],
      ),
    ],
    required this.onLock,
  });

  @override
  State<LockRecordDialog> createState() => _LockRecordDialogState();
}

class _LockRecordDialogState extends State<LockRecordDialog> {
  LockConfiguration? _selectedConfig;
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.configurations.isNotEmpty) {
      _selectedConfig = widget.configurations.first;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, left: 16, right: 16),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.red, size: 20),
                  ),
                ],
              ),
              const Divider(height: 32, color: AppTheme.borderLight),

              // Lock Configuration Dropdown
              const Text(
                'Lock Configuration*',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.errorRed,
                ),
              ),
              const SizedBox(height: 8),
              FormDropdown<LockConfiguration>(
                value: _selectedConfig,
                items: widget.configurations,
                displayStringForValue: (item) => item.name,
                onChanged: (val) {
                  setState(() {
                    _selectedConfig = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Restricted Actions Display
              if (_selectedConfig != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Restricted Actions:',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedConfig!.restrictedActions.join(', '),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Reason for Locking
              const Text(
                'Reason for Locking*',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.errorRed,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _reasonController,
                hintText: 'Enter the reason for locking this record',
                maxLines: 4,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a reason for locking';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() == true &&
                          _selectedConfig != null) {
                        widget.onLock(_selectedConfig!, _reasonController.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF10B981,
                      ), // Emerald/Success Green
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Lock',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
