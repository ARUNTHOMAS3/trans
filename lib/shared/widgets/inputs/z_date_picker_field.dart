// lib/shared/widgets/inputs/z_date_picker_field.dart
//
// Compatibility shim — matches the ZDatePickerField API used in
// feat/lib-only-std sales/purchase files.  Delegates to ZerpaiDatePicker.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';

class ZDatePickerField extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final double height;

  const ZDatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.height = 36,
  });

  @override
  State<ZDatePickerField> createState() => _ZDatePickerFieldState();
}

class _ZDatePickerFieldState extends State<ZDatePickerField> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: () async {
        final picked = await ZerpaiDatePicker.show(
          context,
          initialDate: widget.selectedDate,
          targetKey: _key,
        );
        if (picked != null) {
          widget.onDateSelected(picked);
        }
      },
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd MMM yyyy').format(widget.selectedDate),
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            ),
          ],
        ),
      ),
    );
  }
}
