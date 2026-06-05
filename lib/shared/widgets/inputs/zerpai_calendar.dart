import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker_style.dart';

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
      width: ZerpaiDatePickerStyle.popupWidth,
      padding: const EdgeInsets.all(ZerpaiDatePickerStyle.popupPadding),
      decoration: BoxDecoration(
        color: ZerpaiDatePickerStyle.surfaceColor,
        borderRadius: BorderRadius.circular(ZerpaiDatePickerStyle.popupRadius),
        boxShadow: ZerpaiDatePickerStyle.popupShadow,
        border: Border.all(color: ZerpaiDatePickerStyle.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: ZerpaiDatePickerStyle.sectionSpacing),
          if (_mode == _CalendarMode.days) ...[
            _buildWeekdayHeader(),
            const SizedBox(height: ZerpaiDatePickerStyle.weekdaySpacing),
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
      padding: const EdgeInsets.only(
        bottom: ZerpaiDatePickerStyle.headerBottomPadding,
      ),
      child: Row(
        children: [
          if (_mode == _CalendarMode.days) ...[
            InkWell(
              onTap: () => setState(() => _mode = _CalendarMode.months),
              borderRadius: BorderRadius.circular(
                ZerpaiDatePickerStyle.headerTapRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  DateFormat('MMMM').format(_viewMonth),
                  style: ZerpaiDatePickerStyle.headerTextStyle,
                ),
              ),
            ),
            const SizedBox(width: 2),
            InkWell(
              onTap: () => setState(() => _mode = _CalendarMode.years),
              borderRadius: BorderRadius.circular(
                ZerpaiDatePickerStyle.headerTapRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      DateFormat('yyyy').format(_viewMonth),
                      style: ZerpaiDatePickerStyle.headerTextStyle,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 12,
                      color: ZerpaiDatePickerStyle.iconColor,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () => setState(() => _mode = _CalendarMode.days),
              borderRadius: BorderRadius.circular(
                ZerpaiDatePickerStyle.headerTapRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(title, style: ZerpaiDatePickerStyle.headerTextStyle),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronUp,
                      size: 12,
                      color: ZerpaiDatePickerStyle.iconColor,
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
              color: ZerpaiDatePickerStyle.iconColor,
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(LucideIcons.chevronRight, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: ZerpaiDatePickerStyle.iconColor,
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
            style: ZerpaiDatePickerStyle.weekdayTextStyle,
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
            width: ZerpaiDatePickerStyle.monthCellWidth,
            height: ZerpaiDatePickerStyle.monthCellHeight,
            alignment: Alignment.center,
            margin: const EdgeInsets.all(ZerpaiDatePickerStyle.gridCellMargin),
            decoration: BoxDecoration(
              color: isSelected
                  ? ZerpaiDatePickerStyle.selectedFillColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(
                ZerpaiDatePickerStyle.monthYearCellRadius,
              ),
            ),
            child: Text(
              months[index],
              style: TextStyle(
                fontSize: ZerpaiDatePickerStyle.gridTextStyle.fontSize,
                color: isSelected
                    ? ZerpaiDatePickerStyle.selectedTextColor
                    : AppTheme.textPrimary,
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
            width: ZerpaiDatePickerStyle.monthCellWidth,
            height: ZerpaiDatePickerStyle.monthCellHeight,
            alignment: Alignment.center,
            margin: const EdgeInsets.all(ZerpaiDatePickerStyle.gridCellMargin),
            decoration: BoxDecoration(
              color: isSelected
                  ? ZerpaiDatePickerStyle.selectedFillColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(
                ZerpaiDatePickerStyle.monthYearCellRadius,
              ),
            ),
            child: Text(
              year.toString(),
              style: TextStyle(
                fontSize: ZerpaiDatePickerStyle.gridTextStyle.fontSize,
                color: isSelected
                    ? ZerpaiDatePickerStyle.selectedTextColor
                    : AppTheme.textPrimary,
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
        : ZerpaiDatePickerStyle.adjacentMonthTextColor;
    if (isDisabled) textColor = ZerpaiDatePickerStyle.disabledTextColor;

    BoxDecoration? decoration;

    if (isSelected) {
      textColor = ZerpaiDatePickerStyle.selectedTextColor;
      decoration = BoxDecoration(
        color: isDisabled
            ? ZerpaiDatePickerStyle.disabledSelectedFillColor
            : ZerpaiDatePickerStyle.selectedFillColor,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        border: Border.all(
          color: isDisabled
              ? ZerpaiDatePickerStyle.disabledTodayOutlineColor
              : ZerpaiDatePickerStyle.todayOutlineColor,
        ),
        shape: BoxShape.circle,
      );
    }

    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: ZerpaiDatePickerStyle.dayCellSize,
        height: ZerpaiDatePickerStyle.dayCellSize,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(
          vertical: ZerpaiDatePickerStyle.dayCellVerticalMargin,
          horizontal: ZerpaiDatePickerStyle.dayCellHorizontalMargin,
        ),
        decoration: decoration,
        child: Text(
          day.toString(),
          style: TextStyle(
            fontSize: ZerpaiDatePickerStyle.gridTextStyle.fontSize,
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
