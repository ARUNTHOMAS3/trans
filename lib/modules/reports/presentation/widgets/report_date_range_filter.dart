import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compact_calendar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_popup_positioning.dart';

class ReportDateRangeSelection {
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  const ReportDateRangeSelection({
    required this.startDate,
    required this.endDate,
    required this.label,
  });
}

class ReportDateRangePresets {
  static const String today = 'Today';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';
  static const String thisQuarter = 'This Quarter';
  static const String thisYear = 'This Year';
  static const String yesterday = 'Yesterday';
  static const String previousWeek = 'Previous Week';
  static const String previousMonth = 'Previous Month';
  static const String previousQuarter = 'Previous Quarter';
  static const String previousYear = 'Previous Year';
  static const String custom = 'Custom';

  static const List<String> options = <String>[
    today,
    thisWeek,
    thisMonth,
    thisQuarter,
    thisYear,
    yesterday,
    previousWeek,
    previousMonth,
    previousQuarter,
    previousYear,
    custom,
  ];

  static ReportDateRangeSelection resolveRange(
    String label, {
    DateTime? anchor,
  }) {
    final now = anchor ?? DateTime.now();
    final todayStart = _startOfDay(now);
    final todayEnd = _endOfDay(now);

    switch (label) {
      case today:
        return ReportDateRangeSelection(
          startDate: todayStart,
          endDate: todayEnd,
          label: today,
        );
      case yesterday:
        final yesterdayDate = todayStart.subtract(const Duration(days: 1));
        return ReportDateRangeSelection(
          startDate: yesterdayDate,
          endDate: _endOfDay(yesterdayDate),
          label: yesterday,
        );
      case thisWeek:
        final start = _startOfWeek(now);
        return ReportDateRangeSelection(
          startDate: start,
          endDate: _endOfDay(start.add(const Duration(days: 6))),
          label: thisWeek,
        );
      case previousWeek:
        final start = _startOfWeek(now).subtract(const Duration(days: 7));
        return ReportDateRangeSelection(
          startDate: start,
          endDate: _endOfDay(start.add(const Duration(days: 6))),
          label: previousWeek,
        );
      case thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(const Duration(days: 1));
        return ReportDateRangeSelection(
          startDate: start,
          endDate: _endOfDay(end),
          label: thisMonth,
        );
      case previousMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(days: 1));
        return ReportDateRangeSelection(
          startDate: start,
          endDate: _endOfDay(end),
          label: previousMonth,
        );
      case thisQuarter:
        final start = _startOfFiscalQuarter(now);
        final end = _endOfFiscalQuarter(now);
        return ReportDateRangeSelection(
          startDate: start,
          endDate: _endOfDay(end),
          label: thisQuarter,
        );
      case previousQuarter:
        final currentQuarterStart = _startOfFiscalQuarter(now);
        final previousQuarterDate = currentQuarterStart.subtract(
          const Duration(days: 1),
        );
        final start = _startOfFiscalQuarter(previousQuarterDate);
        final end = _endOfFiscalQuarter(previousQuarterDate);
        return ReportDateRangeSelection(
          startDate: start,
          endDate: _endOfDay(end),
          label: previousQuarter,
        );
      case thisYear:
        final start = _startOfFiscalYear(now);
        final end = _endOfFiscalYear(now);
        return ReportDateRangeSelection(
          startDate: start,
          endDate: _endOfDay(end),
          label: thisYear,
        );
      case previousYear:
        final currentFiscalStart = _startOfFiscalYear(now);
        final previousFiscalDate = currentFiscalStart.subtract(
          const Duration(days: 1),
        );
        final start = _startOfFiscalYear(previousFiscalDate);
        final end = _endOfFiscalYear(previousFiscalDate);
        return ReportDateRangeSelection(
          startDate: start,
          endDate: _endOfDay(end),
          label: previousYear,
        );
      default:
        return ReportDateRangeSelection(
          startDate: todayStart,
          endDate: todayEnd,
          label: custom,
        );
    }
  }

  static String labelForRange(
    DateTime startDate,
    DateTime endDate, {
    DateTime? anchor,
    List<String> availableOptions = options,
  }) {
    for (final option in availableOptions.where((option) => option != custom)) {
      final preset = resolveRange(option, anchor: anchor);
      if (_sameDay(startDate, preset.startDate) &&
          _sameDay(endDate, preset.endDate)) {
        return option;
      }
    }
    return custom;
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  static DateTime _startOfWeek(DateTime date) {
    final normalized = _startOfDay(date);
    final weekday = normalized.weekday;
    return normalized.subtract(Duration(days: weekday - DateTime.monday));
  }

  static DateTime _startOfFiscalYear(DateTime date) {
    final year = date.month >= 4 ? date.year : date.year - 1;
    return DateTime(year, 4, 1);
  }

  static DateTime _endOfFiscalYear(DateTime date) {
    final start = _startOfFiscalYear(date);
    return DateTime(start.year + 1, 3, 31);
  }

  static DateTime _startOfFiscalQuarter(DateTime date) {
    final fiscalYearStart = _startOfFiscalYear(date);
    final monthsFromFiscalStart =
        (date.year - fiscalYearStart.year) * 12 +
        (date.month - fiscalYearStart.month);
    final quarterIndex = monthsFromFiscalStart ~/ 3;
    return DateTime(
      fiscalYearStart.year,
      fiscalYearStart.month + (quarterIndex * 3),
      1,
    );
  }

  static DateTime _endOfFiscalQuarter(DateTime date) {
    final start = _startOfFiscalQuarter(date);
    return DateTime(
      start.year,
      start.month + 3,
      1,
    ).subtract(const Duration(days: 1));
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class ReportDateRangeFilter extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final ValueChanged<ReportDateRangeSelection> onChanged;
  final List<String> availableOptions;
  final String label;
  final bool showLabel;
  final Color fillColor;
  final bool showBorder;
  final EdgeInsetsGeometry padding;
  final bool suppressHoverOverlay;

  const ReportDateRangeFilter({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onChanged,
    this.availableOptions = ReportDateRangePresets.options,
    this.label = 'Date Range',
    this.showLabel = true,
    this.fillColor = AppTheme.bgLight,
    this.showBorder = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppTheme.space12),
    this.suppressHoverOverlay = false,
  });

  @override
  State<ReportDateRangeFilter> createState() => _ReportDateRangeFilterState();
}

class _ReportDateRangeFilterState extends State<ReportDateRangeFilter> {
  final LayerLink _layerLink = LayerLink();
  final ScrollController _optionsScrollController = ScrollController();
  OverlayEntry? _overlayEntry;

  late ReportDateRangeSelection _selection;
  late ReportDateRangeSelection _draftSelection;
  late String _activeOption;
  late DateTime _leftVisibleMonth;
  late DateTime _rightVisibleMonth;
  bool _isOpen = false;
  bool _isDisposing = false;

  static const double _rowHeight = 40;
  static const double _listWidth = 156;
  static const double _compactWidth = 156;
  static const double _customWidth = 680;
  static const double _compactPopupHeight = 388;
  static const double _customPopupHeight = 438;
  static const double _calendarAreaHeight = 278;
  static const double _screenPadding = 8;
  static const double _popupOffsetY = 4;

  @override
  void initState() {
    super.initState();
    final label = ReportDateRangePresets.labelForRange(
      widget.initialStartDate,
      widget.initialEndDate,
      availableOptions: widget.availableOptions,
    );
    _selection = ReportDateRangeSelection(
      startDate: widget.initialStartDate,
      endDate: widget.initialEndDate,
      label: label,
    );
    _draftSelection = _selection;
    _activeOption = _selection.label;
    _syncVisibleMonthsWithDraft();
  }

  @override
  void didUpdateWidget(covariant ReportDateRangeFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isOpen &&
        (oldWidget.initialStartDate != widget.initialStartDate ||
            oldWidget.initialEndDate != widget.initialEndDate)) {
      final label = ReportDateRangePresets.labelForRange(
        widget.initialStartDate,
        widget.initialEndDate,
        availableOptions: widget.availableOptions,
      );
      _selection = ReportDateRangeSelection(
        startDate: widget.initialStartDate,
        endDate: widget.initialEndDate,
        label: label,
      );
      _draftSelection = _selection;
      _activeOption = _selection.label;
      _syncVisibleMonthsWithDraft();
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _disposeOverlay();
    _optionsScrollController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
      return;
    }
    _draftSelection = _selection;
    _activeOption = _selection.label;
    _syncVisibleMonthsWithDraft();
    _showOverlay();
  }

  void _syncVisibleMonthsWithDraft() {
    _leftVisibleMonth = _monthStart(_draftSelection.startDate);
    _rightVisibleMonth = _monthStart(_draftSelection.endDate);
    if (_leftVisibleMonth.year == _rightVisibleMonth.year &&
        _leftVisibleMonth.month == _rightVisibleMonth.month) {
      _rightVisibleMonth = DateTime(
        _leftVisibleMonth.year,
        _leftVisibleMonth.month + 1,
        1,
      );
    }
  }

  DateTime _monthStart(DateTime date) => DateTime(date.year, date.month, 1);

  void _showOverlay() {
    if (!mounted || _isDisposing || _overlayEntry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    overlay.insert(_overlayEntry!);
    _safeSetState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _disposeOverlay();
    _safeSetState(() => _isOpen = false);
  }

  void _disposeOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry == null) return;
    if (entry.mounted) {
      entry.remove();
    }
    entry.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposing) return;
    setState(fn);
  }

  void _markOverlayNeedsBuild() {
    if (!mounted || _isDisposing) return;
    final entry = _overlayEntry;
    if (entry?.mounted ?? false) {
      entry!.markNeedsBuild();
    }
  }

  void _selectPreset(String option) {
    if (option == ReportDateRangePresets.custom) {
      _safeSetState(() {
        _activeOption = option;
      });
      _syncVisibleMonthsWithDraft();
      _markOverlayNeedsBuild();
      return;
    }

    final selection = ReportDateRangePresets.resolveRange(option);
    _selection = selection;
    widget.onChanged(selection);
    _removeOverlay();
  }

  void _updateDraftStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final end = _draftSelection.endDate.isBefore(normalized)
        ? normalized
        : _draftSelection.endDate;
    _safeSetState(() {
      _activeOption = ReportDateRangePresets.custom;
      _draftSelection = ReportDateRangeSelection(
        startDate: normalized,
        endDate: end,
        label: ReportDateRangePresets.custom,
      );
      _leftVisibleMonth = _monthStart(normalized);
      if (_rightVisibleMonth.isBefore(_leftVisibleMonth)) {
        _rightVisibleMonth = _monthStart(end);
      }
    });
    _markOverlayNeedsBuild();
  }

  void _updateDraftEnd(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final start = _draftSelection.startDate.isAfter(normalized)
        ? DateTime(normalized.year, normalized.month, normalized.day)
        : _draftSelection.startDate;
    _safeSetState(() {
      _activeOption = ReportDateRangePresets.custom;
      _draftSelection = ReportDateRangeSelection(
        startDate: start,
        endDate: normalized,
        label: ReportDateRangePresets.custom,
      );
      _rightVisibleMonth = _monthStart(normalized);
      if (_rightVisibleMonth.isBefore(_leftVisibleMonth)) {
        _leftVisibleMonth = _monthStart(start);
      }
    });
    _markOverlayNeedsBuild();
  }

  void _applyCustomRange() {
    _selection = ReportDateRangeSelection(
      startDate: DateTime(
        _draftSelection.startDate.year,
        _draftSelection.startDate.month,
        _draftSelection.startDate.day,
      ),
      endDate: DateTime(
        _draftSelection.endDate.year,
        _draftSelection.endDate.month,
        _draftSelection.endDate.day,
        23,
        59,
        59,
      ),
      label: ReportDateRangePresets.custom,
    );
    widget.onChanged(_selection);
    _removeOverlay();
  }

  void _cancelCustomRange() {
    _draftSelection = _selection;
    _activeOption = _selection.label;
    _syncVisibleMonthsWithDraft();
    _removeOverlay();
  }

  Widget _buildOverlay() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return const SizedBox.shrink();
    }

    final isCustom = _activeOption == ReportDateRangePresets.custom;
    final popupWidth = isCustom ? _customWidth : _compactWidth;
    final compactPopupHeight = math
        .min(
          _compactPopupHeight,
          math.max(_rowHeight, widget.availableOptions.length * _rowHeight),
        )
        .toDouble();
    final popupHeight = isCustom ? _customPopupHeight : compactPopupHeight;
    final placement = resolveReportPopupPlacement(
      context: context,
      anchorBox: renderObject,
      popupWidth: popupWidth,
      popupHeight: popupHeight,
      screenPadding: _screenPadding,
      popupGap: _popupOffsetY,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeOverlay,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: placement.targetAnchor,
          followerAnchor: placement.followerAnchor,
          offset: placement.offset,
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: popupWidth,
              height: popupHeight,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isCustom ? _buildCustomContent() : _buildPresetList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetList() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Scrollbar(
        controller: _optionsScrollController,
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(3),
        child: ListView.builder(
          controller: _optionsScrollController,
          padding: EdgeInsets.zero,
          itemCount: widget.availableOptions.length,
          itemBuilder: (context, index) {
            final option = widget.availableOptions[index];
            return _ReportDateRangeOptionRow(
              label: option,
              selected: _selection.label == option,
              onTap: () => _selectPreset(option),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          SizedBox(
            width: _listWidth,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Scrollbar(
                controller: _optionsScrollController,
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(3),
                child: ListView.builder(
                  controller: _optionsScrollController,
                  padding: EdgeInsets.zero,
                  itemCount: widget.availableOptions.length,
                  itemBuilder: (context, index) {
                    final option = widget.availableOptions[index];
                    return _ReportDateRangeOptionRow(
                      label: option,
                      selected: _activeOption == option,
                      onTap: () => _selectPreset(option),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space16,
                AppTheme.space12,
                AppTheme.space16,
                AppTheme.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ReportDateField(
                          value: _draftSelection.startDate,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      Expanded(
                        child: _ReportDateField(value: _draftSelection.endDate),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space16),
                  SizedBox(
                    height: _calendarAreaHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: ReportCompactCalendar(
                            visibleMonth: _leftVisibleMonth,
                            selectedDate: _draftSelection.startDate,
                            rangeStart: _draftSelection.startDate,
                            rangeEnd: _draftSelection.endDate,
                            onMonthChanged: (month) {
                              _safeSetState(() => _leftVisibleMonth = month);
                              _markOverlayNeedsBuild();
                            },
                            onDateSelected: _updateDraftStart,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: ReportCompactCalendar(
                            visibleMonth: _rightVisibleMonth,
                            selectedDate: _draftSelection.endDate,
                            rangeStart: _draftSelection.startDate,
                            rangeEnd: _draftSelection.endDate,
                            onMonthChanged: (month) {
                              _safeSetState(() => _rightVisibleMonth = month);
                              _markOverlayNeedsBuild();
                            },
                            onDateSelected: _updateDraftEnd,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${ReportFormatterCache.date('yyyy-MM-dd').format(_draftSelection.startDate)} - ${ReportFormatterCache.date('yyyy-MM-dd').format(_draftSelection.endDate)}',
                          style: AppTheme.bodyText.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _cancelCustomRange,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          textStyle: AppTheme.bodyText.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      SizedBox(
                        height: AppTheme.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _applyCustomRange,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: AppTheme.backgroundColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.space4,
                              ),
                            ),
                            textStyle: AppTheme.bodyText.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: widget.fillColor,
        borderRadius: BorderRadius.circular(AppTheme.space8),
        child: InkWell(
          onTap: _toggleOverlay,
          borderRadius: BorderRadius.circular(AppTheme.space8),
          hoverColor: widget.suppressHoverOverlay ? Colors.transparent : null,
          splashColor: widget.suppressHoverOverlay ? Colors.transparent : null,
          highlightColor: widget.suppressHoverOverlay
              ? Colors.transparent
              : null,
          child: Container(
            height: AppTheme.buttonHeight,
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.space8),
              border: widget.showBorder
                  ? Border.all(color: AppTheme.borderColor)
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showLabel)
                  Text(
                    '${widget.label} : ',
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  _selection.label,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Icon(
                  _isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: AppTheme.space16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return filter;
  }
}

class _ReportDateField extends StatelessWidget {
  final DateTime value;

  const _ReportDateField({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.buttonHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.space6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.calendar,
            size: AppTheme.space16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              ReportFormatterCache.date('yyyy-MM-dd').format(value),
              style: AppTheme.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDateRangeOptionRow extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReportDateRangeOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ReportDateRangeOptionRow> createState() =>
      _ReportDateRangeOptionRowState();
}

class _ReportDateRangeOptionRowState extends State<_ReportDateRangeOptionRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isHovered
        ? AppTheme.primaryBlue
        : (widget.selected ? AppTheme.bgDisabled : AppTheme.backgroundColor);
    final textColor = _isHovered
        ? AppTheme.backgroundColor
        : AppTheme.textPrimary;
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            height: _ReportDateRangeFilterState._rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
            alignment: Alignment.centerLeft,
            child: Text(
              widget.label,
              style: AppTheme.bodyText.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
