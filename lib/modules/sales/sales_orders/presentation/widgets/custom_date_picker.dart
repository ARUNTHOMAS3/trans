import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onSelected;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.onSelected,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _viewDate;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _viewDate = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  void _prevMonth() {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _viewDate.year,
      _viewDate.month,
    );
    final firstDayOffset =
        DateTime(_viewDate.year, _viewDate.month, 1).weekday % 7;

    final prevMonthDate = DateTime(_viewDate.year, _viewDate.month - 1);
    final daysInPrevMonth = DateUtils.getDaysInMonth(
      prevMonthDate.year,
      prevMonthDate.month,
    );

    final List<Widget> dayWidgets = [];
    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    for (var day in weekDays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE11D48),
            ),
          ),
        ),
      );
    }

    for (int i = firstDayOffset - 1; i >= 0; i--) {
      dayWidgets.add(_buildDayCell(daysInPrevMonth - i, isOtherMonth: true));
    }

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_viewDate.year, _viewDate.month, i);
      final isSelected = DateUtils.isSameDay(date, _selectedDate);
      dayWidgets.add(_buildDayCell(i, isSelected: isSelected, date: date));
    }

    final totalCellsSoFar = dayWidgets.length - 7;
    final remainingCells = 42 - totalCellsSoFar;
    for (int i = 1; i <= remainingCells; i++) {
      dayWidgets.add(_buildDayCell(i, isOtherMonth: true));
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavBtn(icon: '«', onTap: _prevMonth),
                Text(
                  DateFormat('MMMM yyyy').format(_viewDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                _NavBtn(icon: '»', onTap: _nextMonth),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: dayWidgets,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    int day, {
    bool isOtherMonth = false,
    bool isSelected = false,
    DateTime? date,
  }) {
    return InkWell(
      onTap: date == null ? null : () => widget.onSelected(date),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF991B1B),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Center(
          child: Text(
            day.toString(),
            style: TextStyle(
              fontSize: 13,
              color: isSelected
                  ? Colors.white
                  : (isOtherMonth
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF374151)),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
          icon,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class CustomDateField extends StatefulWidget {
  final DateTime value;
  final ValueChanged<DateTime> onSelected;
  final String label;
  final double? width;
  final double height;

  const CustomDateField({
    super.key,
    required this.value,
    required this.onSelected,
    this.label = '',
    this.width,
    this.height = 40,
  });

  @override
  State<CustomDateField> createState() => _CustomDateFieldState();
}

class _CustomDateFieldState extends State<CustomDateField> {
  final _link = LayerLink();
  OverlayEntry? _overlay;

  void _showPicker() {
    if (_overlay != null) return;

    _overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closePicker,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(0, widget.height + 4),
            child: Material(
              color: Colors.transparent,
              child: CustomDatePicker(
                initialDate: widget.value,
                onSelected: (date) {
                  widget.onSelected(date);
                  _closePicker();
                },
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _closePicker() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: InkWell(
        onTap: _showPicker,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd-MM-yyyy').format(widget.value),
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
              const Icon(
                LucideIcons.calendar,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
