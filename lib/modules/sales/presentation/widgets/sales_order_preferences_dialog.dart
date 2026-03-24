import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SalesOrderPreferencesDialog extends StatefulWidget {
  final String currentPrefix;
  final String currentNextNumber;
  final bool isAutoGenerate;

  const SalesOrderPreferencesDialog({
    super.key,
    required this.currentPrefix,
    required this.currentNextNumber,
    required this.isAutoGenerate,
  });

  @override
  State<SalesOrderPreferencesDialog> createState() => _SalesOrderPreferencesDialogState();
}

class _SalesOrderPreferencesDialogState extends State<SalesOrderPreferencesDialog> {
  late bool _isAutoGenerate;
  late TextEditingController _prefixController;
  late TextEditingController _nextNumberController;

  @override
  void initState() {
    super.initState();
    _isAutoGenerate = widget.isAutoGenerate;
    _prefixController = TextEditingController(text: widget.currentPrefix);
    _nextNumberController = TextEditingController(text: widget.currentNextNumber);
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _nextNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Configure Sales Order# Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, color: Color(0xFFEF4444), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Associated Series
            const Text(
              'Associated Series',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Default Transaction Series',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Warning/Info Text
            const Text(
              'Your sales order numbers are set on auto-generate mode to save your time. Are you sure about changing this setting?',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Radio Options
            RadioGroup<bool>(
              groupValue: _isAutoGenerate,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _isAutoGenerate = val);
                }
              },
              child: Column(
                children: [
                  // Option 1: Auto-generate
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: Radio<bool>(
                          value: true,
                          activeColor: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Continue auto-generating sales order numbers',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.info_outline, size: 14, color: Colors.blue.shade400),
                              ],
                            ),
                            if (_isAutoGenerate) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Prefix',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: _prefixController,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(6),
                                              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                            ),
                                            isDense: true,
                                          ),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Next Number',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: _nextNumberController,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(6),
                                              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                            ),
                                            isDense: true,
                                          ),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Option 2: Manual
                  const Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Radio<bool>(
                          value: false,
                          activeColor: Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Enter sales order numbers manually',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'isAutoGenerate': _isAutoGenerate,
                      'prefix': _prefixController.text,
                      'nextNumber': _nextNumberController.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
