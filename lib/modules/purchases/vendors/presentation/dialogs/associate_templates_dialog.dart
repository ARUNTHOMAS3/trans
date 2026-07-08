import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

/// Reusable "Associate Templates" dialog for a vendor — lets the user pick the
/// PDF templates used for Vendor Statement / Purchase Order / Bills.
///
/// Used by both the vendors report list and the vendor overview page. Show it
/// with `showDialog(builder: (_) => const AssociateTemplatesDialog())`.
class AssociateTemplatesDialog extends StatefulWidget {
  const AssociateTemplatesDialog({super.key});

  @override
  State<AssociateTemplatesDialog> createState() =>
      _AssociateTemplatesDialogState();
}

class _AssociateTemplatesDialogState extends State<AssociateTemplatesDialog> {
  static const List<String> _vendorStatementOptions = [
    'Standard',
    'Modern',
    'Classic',
  ];
  static const List<String> _purchaseOrderOptions = [
    'Standard Template',
    'Classic Template',
    'Compact Template',
  ];
  static const List<String> _billOptions = [
    'Standard Template',
    'Classic Template',
    'Compact Template',
  ];

  String _vendorStatement = _vendorStatementOptions.first;
  String _purchaseOrder = _purchaseOrderOptions.first;
  String _billTemplate = _billOptions.first;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Material(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 24,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 600,
            height: 453.96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFFF9F9FB),
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Associate Templates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'You can associate specific templates for transaction PDFs and emails that will be sent to your vendors.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF667085),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'PDF Templates',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Color(0xFF2563EB),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '+',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                height: 1,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'New PDF Template',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 18),
                          _TemplateRow(
                            label: 'Vendor Statement',
                            child: FormDropdown<String>(
                              value: _vendorStatement,
                              items: _vendorStatementOptions,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _vendorStatement = value);
                                }
                              },
                              displayStringForValue: (value) => value,
                              showSearch: false,
                              menuWidth: 270,
                              height: 38,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _TemplateRow(
                            label: 'Purchase Order',
                            child: FormDropdown<String>(
                              value: _purchaseOrder,
                              items: _purchaseOrderOptions,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _purchaseOrder = value);
                                }
                              },
                              displayStringForValue: (value) => value,
                              showSearch: false,
                              menuWidth: 270,
                              height: 38,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _TemplateRow(
                            label: 'Bills',
                            child: FormDropdown<String>(
                              value: _billTemplate,
                              items: _billOptions,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _billTemplate = value);
                                }
                              },
                              displayStringForValue: (value) => value,
                              showSearch: false,
                              menuWidth: 270,
                              height: 38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  child: Row(
                    children: [
                      ZButton.primary(
                        label: 'Save',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
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
        ),
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _TemplateRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 190,
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, color: Color(0xFF374151)),
          ),
        ),
        SizedBox(width: 270, child: child),
      ],
    );
  }
}
