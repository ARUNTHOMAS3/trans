import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';

const Color _expenseDateFieldBgWhite = Color(0xFFFFFFFF);
const Color _expenseDateFieldBorder = Color(0xFFD1D5DB);
const Color _expenseDateFieldHint = Color(0xFF9CA3AF);
const Color _expenseDateFieldLinkBlue = Color(0xFF3B82F6);

class ZExpensesDatePicker extends StatefulWidget {
  const ZExpensesDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.height = 32,
    this.hint = 'dd-MM-yyyy',
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final double height;
  final String hint;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  @override
  State<ZExpensesDatePicker> createState() => _ZExpensesDatePickerState();
}

class _ZExpensesDatePickerState extends State<ZExpensesDatePicker> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey _targetKey = GlobalKey();
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant ZExpensesDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _syncController();
    }
  }

  void _syncController() {
    _controller.text = widget.selectedDate == null
        ? ''
        : DateFormat('dd-MM-yyyy').format(widget.selectedDate!);
  }

  Future<void> _handleTap() async {
    if (!widget.enabled) {
      return;
    }
    final selected = await ZerpaiDatePicker.show(
      context,
      initialDate: widget.selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      targetKey: _targetKey,
    );
    if (selected != null) {
      _controller.text = DateFormat('dd-MM-yyyy').format(selected);
      widget.onDateSelected(selected);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SizedBox(
        height: widget.height,
        child: KeyedSubtree(
          key: _targetKey,
          child: TextField(
            controller: _controller,
            onTap: _handleTap,
            textAlignVertical: TextAlignVertical.center,
            readOnly: true,
            enabled: widget.enabled,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: const TextStyle(color: _expenseDateFieldHint),
              contentPadding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: _isHovered
                      ? _expenseDateFieldLinkBlue
                      : _expenseDateFieldBorder,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: _expenseDateFieldLinkBlue,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _expenseDateFieldBorder),
                borderRadius: BorderRadius.circular(4),
              ),
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: _expenseDateFieldHint,
              ),
              suffixIconConstraints: const BoxConstraints(
                maxHeight: 32,
                minHeight: 32,
                maxWidth: 32,
                minWidth: 16,
              ),
              filled: true,
              fillColor: _expenseDateFieldBgWhite,
            ),
          ),
        ),
      ),
    );
  }
}
