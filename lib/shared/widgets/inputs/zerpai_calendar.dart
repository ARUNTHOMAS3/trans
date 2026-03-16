import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ZerpaiCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const ZerpaiCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<ZerpaiCalendar> createState() => _ZerpaiCalendarState();
}

enum _CalendarMode { days, months, years }

class _ZerpaiCalendarState extends State<ZerpaiCalendar> {
  late DateTime _viewMonth;
  _CalendarMode _mode = _CalendarMode.days;
  late int _viewYearRangeStart;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _viewYearRangeStart = (widget.selectedDate.year ~/ 12) * 12;
  }

  void _previousMonth() {
    setState(() {
      if (_mode == _CalendarMode.days) {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
      } else if (_mode == _CalendarMode.years) {
        _viewYearRangeStart -= 12;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_mode == _CalendarMode.days) {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
      } else if (_mode == _CalendarMode.years) {
        _viewYearRangeStart += 12;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_mode == _CalendarMode.days) ...[
            _buildWeekdayHeader(),
            const SizedBox(height: 8),
            _buildGrid(),
          ] else if (_mode == _CalendarMode.months) ...[
            _buildMonthGrid(),
          ] else ...[
            _buildYearGrid(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    if (_mode == _CalendarMode.days) {
      title = DateFormat('MMMM yyyy').format(_viewMonth);
    } else if (_mode == _CalendarMode.months) {
      title = DateFormat('yyyy').format(_viewMonth);
    } else {
      title = '$_viewYearRangeStart - ${_viewYearRangeStart + 11}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (_mode == _CalendarMode.days) ...[
            InkWell(
              onTap: () => setState(() => _mode = _CalendarMode.months),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  DateFormat('MMMM').format(_viewMonth),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            InkWell(
              onTap: () => setState(() => _mode = _CalendarMode.years),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      DateFormat('yyyy').format(_viewMonth),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () => setState(() => _mode = _CalendarMode.days),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronUp,
                      size: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          if (_mode != _CalendarMode.months) ...[
            IconButton(
              onPressed: _previousMonth,
              icon: const Icon(LucideIcons.chevronLeft, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(LucideIcons.chevronRight, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: const Color(0xFF6B7280),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: Color(0xFF9CA3AF),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid() {
    final firstDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday

    final days = <Widget>[];

    // Previous month days
    final prevMonthLastDay = DateTime(_viewMonth.year, _viewMonth.month, 0).day;
    for (int i = firstWeekday - 1; i >= 0; i--) {
      final day = prevMonthLastDay - i;
      final date = DateTime(_viewMonth.year, _viewMonth.month - 1, day);
      days.add(_buildDayCell(day, date: date, isCurrentMonth: false));
    }

    // Current month days
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_viewMonth.year, _viewMonth.month, i);
      final isSelected = _isSameDay(date, widget.selectedDate);
      final isToday = _isSameDay(date, DateTime.now());
      days.add(
        _buildDayCell(
          i,
          date: date,
          isCurrentMonth: true,
          isSelected: isSelected,
          isToday: isToday,
          onTap: () => widget.onDateSelected(date),
        ),
      );
    }

    // Next month days
    final remainingCells = 42 - days.length;
    for (int i = 1; i <= remainingCells; i++) {
      final date = DateTime(_viewMonth.year, _viewMonth.month + 1, i);
      days.add(_buildDayCell(i, date: date, isCurrentMonth: false));
    }

    return Wrap(children: days);
  }

  Widget _buildMonthGrid() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Wrap(
      children: List.generate(12, (index) {
        final monthIdx = index + 1;
        final isSelected = _viewMonth.month == monthIdx;
        return InkWell(
          onTap: () {
            setState(() {
              _viewMonth = DateTime(_viewMonth.year, monthIdx);
              _mode = _CalendarMode.days;
            });
          },
          child: Container(
            width: 60,
            height: 40,
            alignment: Alignment.center,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              months[index],
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildYearGrid() {
    return Wrap(
      children: List.generate(12, (index) {
        final year = _viewYearRangeStart + index;
        final isSelected = _viewMonth.year == year;
        return InkWell(
          onTap: () {
            setState(() {
              _viewMonth = DateTime(year, _viewMonth.month);
              _mode = _CalendarMode.months;
            });
          },
          child: Container(
            width: 60,
            height: 40,
            alignment: Alignment.center,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              year.toString(),
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(
    int day, {
    required DateTime date,
    bool isCurrentMonth = true,
    bool isSelected = false,
    bool isToday = false,
    VoidCallback? onTap,
  }) {
    final bool isBeforeFirst =
        widget.firstDate != null && date.isBefore(widget.firstDate!);
    final bool isAfterLast =
        widget.lastDate != null && date.isAfter(widget.lastDate!);
    final bool isDisabled = isBeforeFirst || isAfterLast;

    Color textColor = isCurrentMonth
        ? AppTheme.textPrimary
        : const Color(0xFFD1D5DB);
    if (isDisabled) textColor = const Color(0xFFE5E7EB);

    BoxDecoration? decoration;

    if (isSelected) {
      textColor = Colors.white;
      decoration = BoxDecoration(
        color: isDisabled
            ? AppTheme.primaryBlue.withValues(alpha: 0.3)
            : AppTheme.primaryBlue,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        border: Border.all(
          color: isDisabled
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : AppTheme.primaryBlue,
        ),
        shape: BoxShape.circle,
      );
    }

    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: decoration,
        child: Text(
          day.toString(),
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
