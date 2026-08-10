import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportCompactCalendar extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  const ReportCompactCalendar({
    super.key,
    required this.visibleMonth,
    required this.selectedDate,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  static const List<String> _months = <String>[
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

  static const List<String> _weekdays = <String>[
    'Su',
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
  ];

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final leadingDays = monthStart.weekday % 7;
    final gridStart = monthStart.subtract(Duration(days: leadingDays));
    final dates = List<DateTime>.generate(42, (index) => gridStart.add(Duration(days: index)));

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.space4),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              _CalendarHeader(
                visibleMonth: visibleMonth,
                maxWidth: constraints.maxWidth,
                onMonthChanged: onMonthChanged,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 18,
                child: Row(
                  children: _weekdays
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  children: List<Widget>.generate(6, (weekIndex) {
                    final rowDates = dates.skip(weekIndex * 7).take(7).toList();
                    return Expanded(
                      child: Row(
                        children: rowDates
                            .map(
                              (date) => Expanded(
                                child: _CalendarDateCell(
                                  date: date,
                                  inVisibleMonth: date.month == visibleMonth.month,
                                  isStart: _isSameDay(date, rangeStart),
                                  isEnd: _isSameDay(date, rangeEnd),
                                  isSelected: _isSameDay(date, selectedDate),
                                  isToday: _isSameDay(date, DateTime.now()),
                                  isInRange: _isWithinRange(date, rangeStart, rangeEnd),
                                  onTap: () => onDateSelected(date),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return !normalizedDate.isBefore(normalizedStart) &&
        !normalizedDate.isAfter(normalizedEnd);
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime visibleMonth;
  final double maxWidth;
  final ValueChanged<DateTime> onMonthChanged;

  const _CalendarHeader({
    required this.visibleMonth,
    required this.maxWidth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final years = List<int>.generate(21, (index) => visibleMonth.year - 10 + index);
    final monthWidth = maxWidth >= 190 ? 70.0 : 64.0;
    final yearWidth = maxWidth >= 190 ? 66.0 : 60.0;

    return SizedBox(
      height: 28,
      child: Row(
        children: [
          _CalendarSelect<int>(
            value: visibleMonth.month,
            items: List<int>.generate(12, (index) => index + 1),
            labelBuilder: (value) => ReportCompactCalendar._months[value - 1],
            onChanged: (month) => onMonthChanged(DateTime(visibleMonth.year, month, 1)),
            width: monthWidth,
          ),
          const SizedBox(width: 6),
          _CalendarSelect<int>(
            value: visibleMonth.year,
            items: years,
            labelBuilder: (value) => '$value',
            onChanged: (year) => onMonthChanged(DateTime(year, visibleMonth.month, 1)),
            width: yearWidth,
          ),
          const Spacer(),
          _CalendarIconButton(
            icon: Icons.chevron_left,
            onTap: () => onMonthChanged(DateTime(visibleMonth.year, visibleMonth.month - 1, 1)),
          ),
          const SizedBox(width: 10),
          _CalendarIconButton(
            icon: Icons.chevron_right,
            onTap: () => onMonthChanged(DateTime(visibleMonth.year, visibleMonth.month + 1, 1)),
          ),
        ],
      ),
    );
  }
}

class _CalendarSelect<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;
  final double width;

  const _CalendarSelect({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 28,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.space4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppTheme.textPrimary,
          ),
          style: AppTheme.bodyText.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
          dropdownColor: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.space4),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelBuilder(item), overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class _CalendarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CalendarIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.space4),
      child: SizedBox(
        width: 18,
        height: 18,
        child: Icon(
          icon,
          size: 18,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _CalendarDateCell extends StatelessWidget {
  final DateTime date;
  final bool inVisibleMonth;
  final bool isStart;
  final bool isEnd;
  final bool isSelected;
  final bool isToday;
  final bool isInRange;
  final VoidCallback onTap;

  const _CalendarDateCell({
    required this.date,
    required this.inVisibleMonth,
    required this.isStart,
    required this.isEnd,
    required this.isSelected,
    required this.isToday,
    required this.isInRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEdgeSelection = isStart || isEnd;
    final rangeBackground = isInRange && !isEdgeSelection ? AppTheme.bgDisabled : Colors.transparent;
    final textColor = isEdgeSelection
        ? AppTheme.backgroundColor
        : (inVisibleMonth ? AppTheme.textPrimary : AppTheme.borderColorDark);

    final circleDecoration = isEdgeSelection
        ? const BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          )
        : isToday
            ? BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                border: Border.all(color: AppTheme.primaryBlue),
              )
            : null;

    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        decoration: BoxDecoration(
          color: rangeBackground,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(isStart ? 6 : 0),
            right: Radius.circular(isEnd ? 6 : 0),
          ),
        ),
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: circleDecoration,
            child: Text(
              '${date.day}',
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                fontWeight: isEdgeSelection || isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
