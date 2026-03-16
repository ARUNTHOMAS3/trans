import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class ZerpaiReportShell extends StatefulWidget {
  final Widget child;
  final String reportTitle;
  final String organizationName;
  final DateTime startDate;
  final DateTime endDate;
  final String basis;
  final VoidCallback? onSearch;
  final VoidCallback? onPrint;
  final VoidCallback? onExport;
  final VoidCallback? onSchedule;

  const ZerpaiReportShell({
    super.key,
    required this.child,
    required this.reportTitle,
    this.organizationName = 'Zerpai ERP',
    required this.startDate,
    required this.endDate,
    required this.basis,
    this.onSearch,
    this.onPrint,
    this.onExport,
    this.onSchedule,
  });

  @override
  State<ZerpaiReportShell> createState() => _ZerpaiReportShellState();
}

class _ZerpaiReportShellState extends State<ZerpaiReportShell> {
  final LayerLink _dateRangeLink = LayerLink();
  bool _isDateRangeMenuOpen = false;
  OverlayEntry? _dateRangeOverlay;

  @override
  void dispose() {
    _removeDateRangeMenu();
    super.dispose();
  }

  void _toggleDateRangeMenu() {
    if (_isDateRangeMenuOpen) {
      _removeDateRangeMenu();
    } else {
      _showDateRangeMenu();
    }
  }

  void _removeDateRangeMenu() {
    _dateRangeOverlay?.remove();
    _dateRangeOverlay = null;
    setState(() => _isDateRangeMenuOpen = false);
  }

  void _showDateRangeMenu() {
    // Provide a standardized list of date ranges
    final options = [
      'Today',
      'This Week',
      'This Month',
      'This Quarter',
      'This Year',
      'Yesterday',
      'Previous Week',
      'Previous Month',
      'Previous Quarter',
      'Previous Year',
      'Custom',
    ];

    _dateRangeOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeDateRangeMenu,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.transparent,
              ),
            ),
            CompositedTransformFollower(
              link: _dateRangeLink,
              offset: const Offset(0, 40),
              showWhenUnlinked: false,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((option) {
                      return InkWell(
                        onTap: () {
                          _handleDateRangeSelection(option);
                          _removeDateRangeMenu();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.borderColor,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_dateRangeOverlay!);
    setState(() => _isDateRangeMenuOpen = true);
  }

  void _handleDateRangeSelection(String option) {
    final now = DateTime.now();
    DateTime newStart = widget.startDate;
    DateTime newEnd = widget.endDate;

    switch (option) {
      case 'Today':
        newStart = DateTime(now.year, now.month, now.day);
        newEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Month':
        newStart = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        newEnd = nextMonth.subtract(const Duration(milliseconds: 1));
        break;
      case 'This Year':
        newStart = DateTime(now.year, 1, 1);
        newEnd = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'Previous Month':
        newStart = DateTime(now.year, now.month - 1, 1);
        newEnd = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(milliseconds: 1));
        break;
      case 'Previous Year':
        newStart = DateTime(now.year - 1, 1, 1);
        newEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      // ... more logic for other ranges ...
      case 'Custom':
        // Logic for custom date picker
        return;
    }

    ReportUtils.updateReportParams(
      context,
      startDate: newStart,
      endDate: newEnd,
      basis: widget.basis,
    );
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _matchesRange(
    DateTime start,
    DateTime end,
    DateTime expectedStart,
    DateTime expectedEnd,
  ) {
    return _sameDay(start, expectedStart) && _sameDay(end, expectedEnd);
  }

  String _dateRangeLabel() {
    final now = DateTime.now();
    final start = widget.startDate;
    final end = widget.endDate;

    final todayStart = _startOfDay(now);
    final todayEnd = _endOfDay(now);
    if (_matchesRange(start, end, todayStart, todayEnd)) return 'Today';

    final thisWeekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final thisWeekEnd = _endOfDay(thisWeekStart.add(const Duration(days: 6)));
    if (_matchesRange(start, end, thisWeekStart, thisWeekEnd)) {
      return 'This Week';
    }

    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = _endOfDay(DateTime(now.year, now.month + 1, 0));
    if (_matchesRange(start, end, thisMonthStart, thisMonthEnd)) {
      return 'This Month';
    }

    final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    final thisQuarterStart = DateTime(now.year, quarterStartMonth, 1);
    final thisQuarterEnd = _endOfDay(
      DateTime(now.year, quarterStartMonth + 3, 1).subtract(
        const Duration(days: 1),
      ),
    );
    if (_matchesRange(start, end, thisQuarterStart, thisQuarterEnd)) {
      return 'This Quarter';
    }

    final thisYearStart = DateTime(now.year, 1, 1);
    final thisYearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
    if (_matchesRange(start, end, thisYearStart, thisYearEnd)) {
      return 'This Year';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStart = _startOfDay(yesterday);
    final yesterdayEnd = _endOfDay(yesterday);
    if (_matchesRange(start, end, yesterdayStart, yesterdayEnd)) {
      return 'Yesterday';
    }

    final previousWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final previousWeekEnd = _endOfDay(thisWeekStart.subtract(
      const Duration(days: 1),
    ));
    if (_matchesRange(start, end, previousWeekStart, previousWeekEnd)) {
      return 'Previous Week';
    }

    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthEnd = _endOfDay(DateTime(now.year, now.month, 0));
    if (_matchesRange(start, end, previousMonthStart, previousMonthEnd)) {
      return 'Previous Month';
    }

    final previousQuarterStart = DateTime(now.year, quarterStartMonth - 3, 1);
    final previousQuarterEnd = _endOfDay(
      thisQuarterStart.subtract(const Duration(days: 1)),
    );
    if (_matchesRange(start, end, previousQuarterStart, previousQuarterEnd)) {
      return 'Previous Quarter';
    }

    final previousYearStart = DateTime(now.year - 1, 1, 1);
    final previousYearEnd = DateTime(now.year - 1, 12, 31, 23, 59, 59);
    if (_matchesRange(start, end, previousYearStart, previousYearEnd)) {
      return 'Previous Year';
    }

    return 'Custom';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeaderBar(),
          _buildStickyToolbar(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    final df = DateFormat('MMM dd, yyyy');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.organizationName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.reportTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151), // Zoho Slate
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'From ${df.format(widget.startDate)} To ${df.format(widget.endDate)}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Filter 1: Date Range
          CompositedTransformTarget(
            link: _dateRangeLink,
            child: InkWell(
              onTap: _toggleDateRangeMenu,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: AppTheme.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _dateRangeLabel(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Filter 2: Basis Segment Control
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
              color: AppTheme.bgLight,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSegmentButton('Accrual', widget.basis == 'Accrual'),
                Container(width: 1, height: 24, color: AppTheme.borderColor),
                _buildSegmentButton('Cash', widget.basis == 'Cash'),
              ],
            ),
          ),

          const Spacer(),

          // Actions
          _buildActionButton(LucideIcons.search, 'Search', widget.onSearch),
          const SizedBox(width: 16),
          _buildActionButton(LucideIcons.printer, 'Print', widget.onPrint),
          const SizedBox(width: 16),
          _buildActionButton(LucideIcons.download, 'Export', widget.onExport),
          const SizedBox(width: 16),
          _buildActionButton(LucideIcons.clock, 'Schedule', widget.onSchedule),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/reports');
              }
            },
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
            tooltip: 'Close Report',
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        if (!isSelected) {
          ReportUtils.updateReportParams(
            context,
            startDate: widget.startDate,
            endDate: widget.endDate,
            basis: label,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, [VoidCallback? onTap]) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap ??
            () {
              ZerpaiToast.info(context, '$tooltip feature is coming soon!');
            },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
