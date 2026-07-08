import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';

class ConfigurePaymentModeDialog extends StatefulWidget {
  final List<String> paymentModes;
  final String defaultPaymentMode;
  final Function(List<String> updatedModes, String newDefault) onSave;

  const ConfigurePaymentModeDialog({
    super.key,
    required this.paymentModes,
    required this.defaultPaymentMode,
    required this.onSave,
  });

  @override
  State<ConfigurePaymentModeDialog> createState() => _ConfigurePaymentModeDialogState();
}

class _ConfigurePaymentModeDialogState extends State<ConfigurePaymentModeDialog> {
  late List<TextEditingController> _controllers;
  // Tracks which rows were added via "Add New" — only these get the red X.
  late List<bool> _isCustom;
  late String _defaultMode;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _defaultMode = widget.defaultPaymentMode;
    _controllers = widget.paymentModes
        .map((mode) => TextEditingController(text: mode))
        .toList();
    _isCustom = List<bool>.filled(_controllers.length, false, growable: true);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addNewMode() {
    setState(() {
      _controllers.add(TextEditingController(text: ''));
      _isCustom.add(true);
    });
  }

  void _deleteMode(int index) {
    setState(() {
      final deletedText = _controllers[index].text;
      _controllers.removeAt(index);
      _isCustom.removeAt(index);
      if (_defaultMode == deletedText && _controllers.isNotEmpty) {
        _defaultMode = _controllers.first.text;
      }
    });
  }

  void _handleSave() {
    final List<String> updated = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    widget.onSave(updated, _defaultMode);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, left: 24, right: 24, bottom: 24),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Payment Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            
            // List of Payment Modes
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  final controller = _controllers[index];
                  final isDefault = controller.text.trim() == _defaultMode;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: controller,
                              height: 32,
                              onChanged: (val) {
                                if (isDefault) {
                                  setState(() {
                                    _defaultMode = val.trim();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 150,
                            child: isDefault
                                ? Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF15803D), // green-700
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        'Default',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Fixed slot keeps the close icon aligned
                                      // whether or not the link is shown.
                                      SizedBox(
                                        width: 112,
                                        child: _hoveredIndex == index
                                            ? Align(
                                                alignment: Alignment.centerLeft,
                                                child: TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _defaultMode = controller.text.trim();
                                                    });
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: const Text(
                                                    'Mark as Default',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.primaryBlue,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                      // Red close (X) icon — only on custom
                                      // ("Add New") rows, and only on hover,
                                      // matching the "Mark as Default" link.
                                      if (_isCustom[index] && _hoveredIndex == index) ...[
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => _deleteMode(index),
                                          borderRadius: BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Icon(
                                              Icons.close,
                                              color: Color(0xFFEF4444),
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Add New Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: InkWell(
                onTap: _addNewMode,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.primaryBlue,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Add New',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: _handleSave,
                  ),
                  const SizedBox(width: 12),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
