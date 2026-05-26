import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';

class InventoryOrderDateDialog extends StatefulWidget {
  const InventoryOrderDateDialog({
    super.key,
    required this.title,
    required this.label,
    required this.initialDate,
  });

  final String title;
  final String label;
  final DateTime initialDate;

  static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    required String label,
    required DateTime initialDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InventoryOrderDateDialog(
        title: title,
        label: label,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<InventoryOrderDateDialog> createState() =>
      _InventoryOrderDateDialogState();
}

class _InventoryOrderDateDialogState extends State<InventoryOrderDateDialog> {
  final GlobalKey _dateFieldKey = GlobalKey();
  late DateTime _selectedDate;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _dateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(_selectedDate),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      targetKey: _dateFieldKey,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _dateController.text = DateFormat('dd-MM-yyyy').format(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      LucideIcons.x,
                      color: AppTheme.errorRed,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      widget.label,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.errorRedDark,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 200,
                    child: InkWell(
                      key: _dateFieldKey,
                      onTap: _pickDate,
                      child: IgnorePointer(
                        child: CustomTextField(
                          controller: _dateController,
                          readOnly: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop<DateTime>(_selectedDate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
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
