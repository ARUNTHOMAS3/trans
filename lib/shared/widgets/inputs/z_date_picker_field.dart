import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';

class ZDatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? hintText;
  final double height;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;

  ZDatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.hintText,
    this.height = 32,
    this.required = false,
    this.firstDate,
    this.lastDate,
  });

  final GlobalKey _fieldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: _fieldKey,
      onTap: () async {
        final picked = await ZerpaiDatePicker.show(
          context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2000),
          lastDate: lastDate ?? DateTime(2100),
          targetKey: _fieldKey,
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: IgnorePointer(
        child: CustomTextField(
          height: height,
          hintText: hintText,
          controller: TextEditingController(
            text: selectedDate != null
                ? DateFormat('dd-MM-yyyy').format(selectedDate!)
                : '',
          ),
          suffixWidget: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(
              LucideIcons.calendar,
              size: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          readOnly: true,
        ),
      ),
    );
  }
}
