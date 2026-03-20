import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart' as di;
import '../../models/manual_journal_model.dart';
import '../../providers/manual_journal_provider.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';

enum ManualJournalSortField { date, journalNumber, referenceNumber }

class ManualJournalSortCommand {
  final ManualJournalSortField field;
  final bool ascending;

  const ManualJournalSortCommand({
    required this.field,
    required this.ascending,
  });
}

enum _PeriodFilter { all, today, thisWeek, thisMonth, thisQuarter, thisYear }

enum _ViewFilter { all, draft, published, cancelled }

enum _SortColumn {
  date,
  journalNumber,
  referenceNumber,
  status,
  amount,
  createdBy,
  reportingMethod,
}

class _AdvancedSearchFilters {
  final String journalNumber;
  final String referenceNumber;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String accountName;
  final ManualJournalStatus? status;
  final String notes;
  final double? minAmount;
  final double? maxAmount;
  final String customerName;
  final String vendorName;
  final String reportingMethod;
  final String journalType;

  const _AdvancedSearchFilters({
    this.journalNumber = '',
    this.referenceNumber = '',
    this.fromDate,
    this.toDate,
    this.accountName = '',
    this.status,
    this.notes = '',
    this.minAmount,
    this.maxAmount,
    this.customerName = '',
    this.vendorName = '',
    this.reportingMethod = '',
    this.journalType = '',
  });

  bool get hasAnyFilter =>
      journalNumber.trim().isNotEmpty ||
      referenceNumber.trim().isNotEmpty ||
      fromDate != null ||
      toDate != null ||
      accountName.trim().isNotEmpty ||
      status != null ||
      notes.trim().isNotEmpty ||
      minAmount != null ||
      maxAmount != null ||
      customerName.trim().isNotEmpty ||
      vendorName.trim().isNotEmpty ||
      reportingMethod.trim().isNotEmpty ||
      journalType.trim().isNotEmpty;

  _AdvancedSearchFilters copyWith({
    String? journalNumber,
    String? referenceNumber,
    Object? fromDate = _sentinel,
    Object? toDate = _sentinel,
    String? accountName,
    Object? status = _sentinel,
    String? notes,
    Object? minAmount = _sentinel,
    Object? maxAmount = _sentinel,
    String? customerName,
    String? vendorName,
    String? reportingMethod,
    String? journalType,
  }) {
    return _AdvancedSearchFilters(
      journalNumber: journalNumber ?? this.journalNumber,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      fromDate: identical(fromDate, _sentinel)
          ? this.fromDate
          : fromDate as DateTime?,
      toDate: identical(toDate, _sentinel) ? this.toDate : toDate as DateTime?,
      accountName: accountName ?? this.accountName,
      status: identical(status, _sentinel)
          ? this.status
          : status as ManualJournalStatus?,
      notes: notes ?? this.notes,
      minAmount: identical(minAmount, _sentinel)
          ? this.minAmount
          : minAmount as double?,
      maxAmount: identical(maxAmount, _sentinel)
          ? this.maxAmount
          : maxAmount as double?,
      customerName: customerName ?? this.customerName,
      vendorName: vendorName ?? this.vendorName,
      reportingMethod: reportingMethod ?? this.reportingMethod,
      journalType: journalType ?? this.journalType,
    );
  }
}

const Object _sentinel = Object();

class ManualJournalsListPanel extends ConsumerStatefulWidget {
  final bool compact;
  final ValueNotifier<ManualJournalSortCommand?>? sortCommandListenable;

  const ManualJournalsListPanel({
    super.key,
    this.compact = false,
    this.sortCommandListenable,
  });

  @override
  ConsumerState<ManualJournalsListPanel> createState() =>
      _ManualJournalsListPanelState();
}

class _ManualJournalsListPanelState
    extends ConsumerState<ManualJournalsListPanel> {
  static const double _minTableWidth = 1460;

  // Define columns
  final List<_ColumnDef> _columns = _getDefaultColumns();

  static List<_ColumnDef> _getDefaultColumns() => [
    _ColumnDef(
      id: 'date',
      label: 'DATE',
      flex: 13,
      sortColumn: _SortColumn.date,
      isLocked: true,
    ),
    _ColumnDef(
      id: 'journalNumber',
      label: 'JOURNAL#',
      flex: 13,
      sortColumn: _SortColumn.journalNumber,
      isLocked: true,
    ),
    _ColumnDef(
      id: 'referenceNumber',
      label: 'REFERENCE NUMBER',
      flex: 22,
      sortColumn: _SortColumn.referenceNumber,
    ),
    _ColumnDef(
      id: 'status',
      label: 'STATUS',
      flex: 11,
      sortColumn: _SortColumn.status,
    ),
    _ColumnDef(id: 'notes', label: 'NOTES', flex: 8),
    _ColumnDef(
      id: 'amount',
      label: 'AMOUNT',
      flex: 13,
      sortColumn: _SortColumn.amount,
      textAlign: TextAlign.right,
      headerAlignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 12),
      isLocked: true,
    ),
    _ColumnDef(
      id: 'createdBy',
      label: 'CREATED BY',
      flex: 18,
      sortColumn: _SortColumn.createdBy,
      padding: const EdgeInsets.only(left: 12),
    ),
    _ColumnDef(
      id: 'reportingMethod',
      label: 'REPORTING METHOD',
      flex: 16,
      sortColumn: _SortColumn.reportingMethod,
      padding: const EdgeInsets.only(left: 8),
    ),
  ];

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _horizontalScrollCtrl = ScrollController();
  _PeriodFilter _periodFilter = _PeriodFilter.all;
  _ViewFilter _viewFilter = _ViewFilter.all;
  _SortColumn _sortColumn = _SortColumn.date;
  bool _sortAscending = false;
  bool _clipText = true;
  _AdvancedSearchFilters _advancedFilters = const _AdvancedSearchFilters();
  final Set<String> _checkedJournalIds = <String>{};
  int _pageSize = 50;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.sortCommandListenable?.addListener(_handleExternalSortCommand);
  }

  @override
  void didUpdateWidget(covariant ManualJournalsListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sortCommandListenable != widget.sortCommandListenable) {
      oldWidget.sortCommandListenable?.removeListener(
        _handleExternalSortCommand,
      );
      widget.sortCommandListenable?.addListener(_handleExternalSortCommand);
    }
  }

  @override
  void dispose() {
    widget.sortCommandListenable?.removeListener(_handleExternalSortCommand);
    _searchCtrl.dispose();
    _horizontalScrollCtrl.dispose();
    super.dispose();
  }

  void _handleExternalSortCommand() {
    final command = widget.sortCommandListenable?.value;
    if (command == null) return;

    final mappedColumn = switch (command.field) {
      ManualJournalSortField.date => _SortColumn.date,
      ManualJournalSortField.journalNumber => _SortColumn.journalNumber,
      ManualJournalSortField.referenceNumber => _SortColumn.referenceNumber,
    };

    if (!mounted) return;
    setState(() {
      _sortColumn = mappedColumn;
      _sortAscending = command.ascending;
      _pageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manualJournalProvider);
    final notifier = ref.read(manualJournalProvider.notifier);

    final filtered = _filteredAndSorted(
      state.journals,
      _searchCtrl.text,
      _periodFilter,
      _viewFilter,
      _sortColumn,
      _sortAscending,
      _advancedFilters,
    );

    final pageCount = filtered.isEmpty
        ? 1
        : ((filtered.length - 1) ~/ _pageSize) + 1;
    final effectivePageIndex = _pageIndex.clamp(0, pageCount - 1);
    final pageStartIndex = filtered.isEmpty
        ? 0
        : effectivePageIndex * _pageSize;
    final pageEndIndex = math.min(pageStartIndex + _pageSize, filtered.length);
    final paged = filtered.isEmpty
        ? <ManualJournal>[]
        : filtered.sublist(pageStartIndex, pageEndIndex);

    final selectedIds = _selectedIdsFrom(state.journals);

    return Column(
      children: [
        _buildToolbar(state), // ALWAYS mounted - Focus is safe!
        if (selectedIds.isNotEmpty)
          _buildBulkActionBar(
            notifier: notifier,
            allJournals: state.journals,
            selectedIds: selectedIds,
            isMutating: state.isMutating,
          ),
        const Divider(height: 1, color: AppTheme.borderColor),
        Expanded(
          child: state.isLoading && state.journals.isEmpty
              ? (widget.compact
                    ? const TableSkeleton(columns: 1, showHeader: false)
                    : const TableSkeleton(columns: 8, showHeader: true))
              : (widget.compact
                    ? _buildCompactBody(state, paged, notifier)
                    : _buildTableBody(
                        state,
                        paged,
                        filtered,
                        effectivePageIndex,
                        pageCount,
                        pageStartIndex,
                        pageEndIndex,
                      )),
        ),
      ],
    );
  }

  Widget _buildTableBody(
    ManualJournalState state,
    List<ManualJournal> paged,
    List<ManualJournal> filtered,
    int effectivePageIndex,
    int pageCount,
    int pageStartIndex,
    int pageEndIndex,
  ) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = math.max(constraints.maxWidth, _minTableWidth);
              final showHorizontalScroll =
                  constraints.maxWidth < _minTableWidth;

              return Scrollbar(
                controller: _horizontalScrollCtrl,
                thumbVisibility: showHorizontalScroll,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _horizontalScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        _buildTableHeader(paged),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        Expanded(
                          child: (state.error != null && state.journals.isEmpty)
                              ? TableErrorPlaceholder(
                                  error: state.error!,
                                  onRetry: ref
                                      .read(manualJournalProvider.notifier)
                                      .fetchJournals,
                                )
                              : filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    _emptyMessage(),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: paged.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: AppTheme.borderColor,
                                  ),
                                  itemBuilder: (context, index) {
                                    final journal = paged[index];
                                    final selected =
                                        state.selectedJournalId == journal.id;
                                    return _buildDataRow(
                                      journal: journal,
                                      selected: selected,
                                      checked: _checkedJournalIds.contains(
                                        journal.id,
                                      ),
                                      onTap: () => context.go(
                                        AppRoutes.accountantManualJournalsDetail
                                            .replaceAll(':id', journal.id),
                                      ),
                                      onCheckChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            _checkedJournalIds.add(journal.id);
                                          } else {
                                            _checkedJournalIds.remove(
                                              journal.id,
                                            );
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildPaginationBar(
          totalCount: filtered.length,
          rangeStart: filtered.isEmpty ? 0 : pageStartIndex + 1,
          rangeEnd: pageEndIndex,
          canGoPrev: effectivePageIndex > 0,
          canGoNext: effectivePageIndex < pageCount - 1,
          onPrev: () {
            if (effectivePageIndex <= 0) return;
            setState(() => _pageIndex = effectivePageIndex - 1);
          },
          onNext: () {
            if (effectivePageIndex >= pageCount - 1) return;
            setState(() => _pageIndex = effectivePageIndex + 1);
          },
        ),
      ],
    );
  }

  Widget _buildCompactBody(
    ManualJournalState state,
    List<ManualJournal> journals,
    ManualJournalNotifier notifier,
  ) {
    if (state.error != null && state.journals.isEmpty) {
      return TableErrorPlaceholder(
        error: state.error!,
        onRetry: notifier.fetchJournals,
      );
    }

    return journals.isEmpty
        ? Center(
            child: Text(
              _emptyMessage(),
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: journals.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.borderColor),
            itemBuilder: (context, index) {
              final journal = journals[index];
              final isSelected = state.selectedJournalId == journal.id;
              return InkWell(
                onTap: () => context.go(
                  AppRoutes.accountantManualJournalsDetail.replaceAll(
                    ':id',
                    journal.id,
                  ),
                ),
                child: Container(
                  color: isSelected ? AppTheme.bgLight : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Checkbox centered
                      Transform.scale(
                        scale: 0.9,
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _checkedJournalIds.contains(journal.id),
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _checkedJournalIds.add(journal.id);
                                } else {
                                  _checkedJournalIds.remove(journal.id);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date and Reference
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(journal.journalDate),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              journal.journalNumber,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Amount and Status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '₹${NumberFormat('#,##0.00').format(journal.totalDebit)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _statusLabel(journal.status).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: _statusColor(journal.status),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildToolbar(ManualJournalState state) {
    if (widget.compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // View Filter (Styled as text dropdown)
                _buildViewSelector(),
                const Spacer(),
                // Split New Button
                _buildSplitNewButton(),
                const SizedBox(width: 8),
                // More Options
                _buildMoreActionsMenu(),
              ],
            ),
            const SizedBox(height: 12),
            // Period Filter
            _buildPeriodFilter(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // View Filter
              _buildViewSelector(),
              const Spacer(),
              const SizedBox(width: 12),
              // New Button (Primary Green)
              _buildSplitNewButton(showLabel: true),
              const SizedBox(width: 8),
              // More Options Dropdown
              _buildMoreActionsMenu(),
            ],
          ),
          const SizedBox(height: 12),
          _buildPeriodFilter(),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      menuChildren: [
        ..._ViewFilter.values.map(
          (v) => MenuItemButton(
            onPressed: () => setState(() {
              _viewFilter = v;
              _pageIndex = 0;
            }),
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    _viewLabel(v),
                    style: TextStyle(
                      fontSize: 14,
                      color: v == _viewFilter
                          ? AppTheme.primaryBlue
                          : AppTheme.textPrimary,
                      fontWeight: v == _viewFilter
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    LucideIcons.star,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        MenuItemButton(
          onPressed: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              children: [
                Icon(
                  LucideIcons.plusCircle,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(width: 8),
                Text(
                  'New Custom View',
                  style: TextStyle(fontSize: 14, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _viewLabel(_viewFilter),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                controller.isOpen
                    ? LucideIcons.chevronUp
                    : LucideIcons.chevronDown,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSplitNewButton({bool showLabel = false}) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.accentGreen,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go(AppRoutes.accountantManualJournalsCreate),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(4),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 8),
                child: Row(
                  children: [
                    const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                    if (showLabel) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'New',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(
            width: 1,
            color: Colors.white24,
            indent: 6,
            endIndent: 6,
          ),
          MenuAnchor(
            style: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              elevation: const WidgetStatePropertyAll(8),
            ),
            menuChildren: [
              _buildSplitMenuItem(
                label: 'New Journal',
                onPressed: () =>
                    context.push(AppRoutes.accountantManualJournalsCreate),
              ),
              _buildSplitMenuItem(
                label: 'Create from Template',
                onPressed: () => context.go(
                  AppRoutes.accountantManualJournalsCreate,
                  extra: {'showTemplates': true},
                ),
              ),
              _buildSplitMenuItem(
                label: 'New Template',
                onPressed: () =>
                    context.push(AppRoutes.accountantJournalTemplateCreation),
              ),
              _buildSplitMenuItem(
                label: 'New Recurring Journal',
                onPressed: () =>
                    context.push(AppRoutes.accountantRecurringJournalsCreate),
              ),
            ],
            builder: (context, controller, child) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSplitMenuItem({
    required String label,
    required VoidCallback onPressed,
  }) {
    return MenuItemButton(
      onPressed: onPressed,
      style: MenuItemButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 240,
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(LucideIcons.search, size: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ),
          ),
        ),
        ..._PeriodFilter.values.map(
          (v) => MenuItemButton(
            onPressed: () => setState(() {
              _periodFilter = v;
              _pageIndex = 0;
            }),
            child: Container(
              width: 240,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(_periodLabel(v), style: const TextStyle(fontSize: 14)),
                  const Spacer(),
                  if (v == _periodFilter)
                    const Icon(
                      LucideIcons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
            style: MenuItemButton.styleFrom(
              backgroundColor: v == _periodFilter ? AppTheme.primaryBlue : null,
              foregroundColor: v == _periodFilter ? Colors.white : null,
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Period: ',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              Text(
                _periodLabel(_periodFilter),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: AppTheme.textPrimary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoreActionsMenu() {
    return SizedBox(
      height: 28,
      width: 30,
      child: MenuAnchor(
        alignmentOffset: const Offset(-200, 4),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
          ),
          elevation: const WidgetStatePropertyAll(4),
        ),
        menuChildren: [
          MenuItemButton(
            onPressed: () {},
            child: const _ActionMenuRow(
              icon: LucideIcons.arrowUpDown,
              label: 'Sort',
            ),
          ),
          const Divider(height: 1),
          MenuItemButton(
            onPressed: () {},
            child: const _ActionMenuRow(
              icon: LucideIcons.download,
              label: 'Import',
            ),
          ),
          MenuItemButton(
            onPressed: () {},
            child: const _ActionMenuRow(
              icon: LucideIcons.upload,
              label: 'Export',
            ),
          ),
        ],
        builder: (context, controller, child) {
          return OutlinedButton(
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: const BorderSide(color: AppTheme.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Icon(
              LucideIcons.moreHorizontal,
              size: 14,
              color: AppTheme.textSecondary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBulkActionBar({
    required ManualJournalNotifier notifier,
    required List<ManualJournal> allJournals,
    required List<String> selectedIds,
    required bool isMutating,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          if (allJournals
              .where((j) => selectedIds.contains(j.id))
              .any((j) => j.status == ManualJournalStatus.draft))
            OutlinedButton(
              onPressed: isMutating
                  ? null
                  : () => _publishSelected(notifier, allJournals),
              child: const Text('Publish'),
            ),
          if (allJournals
              .where((j) => selectedIds.contains(j.id))
              .any((j) => j.status == ManualJournalStatus.draft))
            const SizedBox(width: 8),
          OutlinedButton(
            onPressed: isMutating
                ? null
                : () => _deleteSelected(notifier, allJournals),
            child: const Text('Delete'),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 24, color: AppTheme.borderColor),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  selectedIds.length.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Selected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Tooltip(
            message: 'Clear selection',
            child: InkWell(
              onTap: isMutating
                  ? null
                  : () => setState(() => _checkedJournalIds.clear()),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.errorRed.withValues(alpha: 0.06),
                ),
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: isMutating ? AppTheme.textMuted : AppTheme.errorRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publishSelected(
    ManualJournalNotifier notifier,
    List<ManualJournal> allJournals,
  ) async {
    final selectedIds = _selectedIdsFrom(allJournals);
    if (selectedIds.isEmpty) return;

    try {
      await notifier.publishJournals(selectedIds);
      if (!mounted) return;
      setState(() => _checkedJournalIds.clear());
      ZerpaiToast.success(
        context,
        'Published ${selectedIds.length} journal(s).',
      );
    } catch (e) {
      if (!mounted) return;
      final message = ErrorHandler.getFriendlyMessage(e);
      ZerpaiToast.error(context, message);
    }
  }

  Future<void> _deleteSelected(
    ManualJournalNotifier notifier,
    List<ManualJournal> allJournals,
  ) async {
    final selectedIds = _selectedIdsFrom(allJournals);
    if (selectedIds.isEmpty) return;

    final confirm = await showZerpaiConfirmationDialog(
      context,
      title: 'Are you sure about deleting ${selectedIds.length} journal(s)?',
      message: 'This will delete ${selectedIds.length} selected journal(s).',
      confirmLabel: 'OK',
      cancelLabel: 'Cancel',
    );

    if (confirm != true) return;

    try {
      await notifier.deleteJournals(selectedIds);
      if (!mounted) return;
      setState(() => _checkedJournalIds.clear());
      ZerpaiToast.deleted(context, '${selectedIds.length} journal(s)');
    } catch (e) {
      if (!mounted) return;
      final message = ErrorHandler.getFriendlyMessage(e);
      ZerpaiToast.error(context, message);
    }
  }

  Widget _buildPaginationBar({
    required int totalCount,
    required int rangeStart,
    required int rangeEnd,
    required bool canGoPrev,
    required bool canGoNext,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Text(
            'Total Count: $totalCount',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 170,
            child: di.FormDropdown<int>(
              value: _pageSize,
              items: const [10, 25, 50, 100, 200],
              hint: '50 per page',
              showSearch: true,
              displayStringForValue: (value) => '$value per page',
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _pageSize = value;
                  _pageIndex = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: canGoPrev ? onPrev : null,
            icon: const Icon(LucideIcons.chevronLeft, size: 16),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$rangeStart - $rangeEnd',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(LucideIcons.chevronRight, size: 16),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<ManualJournal> journals) {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppTheme.textSecondary,
    );
    final allChecked =
        journals.isNotEmpty &&
        journals.every((j) => _checkedJournalIds.contains(j.id));
    final anyChecked = journals.any((j) => _checkedJournalIds.contains(j.id));
    final headerValue = allChecked ? true : (anyChecked ? null : false);

    return Container(
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _showTableOptions,
              child: const Icon(
                Icons.tune,
                size: 15,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Checkbox(
              tristate: true,
              value: headerValue,
              visualDensity: VisualDensity.compact,
              onChanged: journals.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _checkedJournalIds.addAll(journals.map((j) => j.id));
                        } else {
                          _checkedJournalIds.removeAll(
                            journals.map((j) => j.id),
                          );
                        }
                      });
                    },
            ),
          ),
          ..._columns.where((c) => c.isVisible).map((col) {
            if (col.sortColumn != null) {
              return Expanded(
                flex: col.flex,
                child: _buildSortableHeader(
                  label: col.label,
                  column: col.sortColumn!,
                  style: headerStyle,
                  padding: col.padding,
                  textAlign: col.textAlign,
                ),
              );
            } else {
              return Expanded(
                flex: col.flex,
                child: Container(
                  alignment: col.headerAlignment,
                  padding: col.padding,
                  child: Text(col.label, style: headerStyle),
                ),
              );
            }
          }),
          // Search Icon at the far right of the table header
          SizedBox(
            width: 36,
            child: InkWell(
              onTap: () {
                // Focus search or show search modal in the future
              },
              borderRadius: BorderRadius.circular(4),
              child: const Icon(
                LucideIcons.search,
                size: 15,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader({
    required String label,
    required _SortColumn column,
    required TextStyle style,
    TextAlign textAlign = TextAlign.left,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    final isActive = _sortColumn == column;
    final icon = isActive
        ? (_sortAscending ? LucideIcons.chevronUp : LucideIcons.chevronDown)
        : null;

    return InkWell(
      onTap: () {
        setState(() {
          if (_sortColumn == column) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = column;
            _sortAscending = true;
          }
          _pageIndex = 0;
        });
      },
      child: Container(
        padding: padding,
        alignment: textAlign == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: style),
            if (icon != null) const SizedBox(width: 4),
            if (icon != null) Icon(icon, size: 14, color: AppTheme.textPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildCellContent(
    _ColumnDef col,
    ManualJournal journal,
    bool selected,
    String status,
    Color statusColor,
    String amount,
  ) {
    switch (col.id) {
      case 'date':
        return Text(
          DateFormat('dd-MM-yyyy').format(journal.journalDate),
          maxLines: _clipText ? 1 : null,
          overflow: _clipText ? TextOverflow.ellipsis : null,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        );
      case 'journalNumber':
        return Text(
          journal.journalNumber,
          maxLines: _clipText ? 1 : null,
          overflow: _clipText ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        );
      case 'referenceNumber':
        return Text(
          (journal.referenceNumber ?? '').isEmpty
              ? '-'
              : (journal.referenceNumber ?? ''),
          maxLines: _clipText ? 3 : null,
          overflow: _clipText ? TextOverflow.ellipsis : null,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        );
      case 'status':
        return Text(
          status,
          maxLines: _clipText ? 1 : null,
          overflow: _clipText ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        );
      case 'notes':
        return Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            (journal.notes ?? '').trim().isEmpty
                ? Icons.remove
                : Icons.sticky_note_2_outlined,
            size: 15,
            color: (journal.notes ?? '').trim().isEmpty
                ? AppTheme.textSecondary
                : AppTheme.textPrimary,
          ),
        );
      case 'amount':
        return Text(
          '₹$amount',
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        );
      case 'createdBy':
        return Text(
          (journal.userId ?? '').isEmpty
              ? 'zerpaiprivatelimited'
              : journal.userId!,
          maxLines: _clipText ? 2 : null,
          overflow: _clipText ? TextOverflow.ellipsis : null,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        );
      case 'reportingMethod':
        return Text(
          _reportingMethodLabel(journal.reportingMethod),
          maxLines: _clipText ? 2 : null,
          overflow: _clipText ? TextOverflow.ellipsis : null,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        );
      default:
        return const SizedBox();
    }
  }

  void _showTableOptions() async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);

    await showMenu<String>(
      context: context,
      color: Colors.white,
      position: RelativeRect.fromLTRB(
        offset.dx + 40,
        offset.dy + 120, // Approximate header height offset
        offset.dx + 200,
        offset.dy + 300,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem<String>(
          padding: EdgeInsets.zero,
          enabled: false,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              _showCustomizeColumnsDialog();
            },
            child: Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              color: AppTheme.primaryBlue,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    LucideIcons.layoutTemplate,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Customize Columns',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          padding: EdgeInsets.zero,
          onTap: () {
            setState(() => _clipText = !_clipText);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _clipText ? LucideIcons.alignLeft : LucideIcons.wrapText,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  _clipText ? 'Wrap Text' : 'Clip Text',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomizeColumnsDialog() {
    showDialog(
      context: context,
      builder: (context) => _CustomizeColumnsDialog(
        columns: _columns,
        onSave: (updatedColumns) {
          setState(() {
            _columns.clear();
            _columns.addAll(updatedColumns);
          });
        },
      ),
    );
  }

  Widget _buildDataRow({
    required ManualJournal journal,
    required bool selected,
    required bool checked,
    required VoidCallback onTap,
    required ValueChanged<bool?> onCheckChanged,
  }) {
    final status = _statusLabel(journal.status);
    final statusColor = _statusColor(journal.status);
    final amount = NumberFormat('#,##0.00').format(journal.totalDebit);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? AppTheme.primaryBlue.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 36),
            SizedBox(
              width: 36,
              child: Checkbox(
                value: checked,
                visualDensity: VisualDensity.compact,
                onChanged: onCheckChanged,
              ),
            ),
            ..._columns.where((c) => c.isVisible).map((col) {
              return Expanded(
                flex: col.flex,
                child: Padding(
                  padding: col.padding,
                  child: _buildCellContent(
                    col,
                    journal,
                    selected,
                    status,
                    statusColor,
                    amount,
                  ),
                ),
              );
            }),
            const SizedBox(width: 28),
          ],
        ),
      ),
    );
  }

  String _emptyMessage() {
    if (_searchCtrl.text.trim().isNotEmpty) {
      return 'No matching manual journals found';
    }
    if (_advancedFilters.hasAnyFilter) {
      return 'No journals found for the selected advanced filters';
    }

    switch (_viewFilter) {
      case _ViewFilter.draft:
        return 'No draft manual journals found';
      case _ViewFilter.published:
        return 'No published manual journals found';
      case _ViewFilter.cancelled:
        return 'No cancelled manual journals found';
      default:
        return 'No manual journals found';
    }
  }

  List<ManualJournal> _filteredAndSorted(
    List<ManualJournal> journals,
    String rawQuery,
    _PeriodFilter period,
    _ViewFilter view,
    _SortColumn sortColumn,
    bool sortAscending,
    _AdvancedSearchFilters advanced,
  ) {
    final query = rawQuery.trim().toLowerCase();
    final now = DateTime.now();

    bool periodMatch(DateTime date) {
      final d = DateTime(date.year, date.month, date.day);
      final today = DateTime(now.year, now.month, now.day);

      switch (period) {
        case _PeriodFilter.all:
          return true;
        case _PeriodFilter.today:
          return d == today;
        case _PeriodFilter.thisWeek:
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
        case _PeriodFilter.thisMonth:
          return d.year == today.year && d.month == today.month;
        case _PeriodFilter.thisQuarter:
          final currentQuarter = ((today.month - 1) ~/ 3) + 1;
          final dateQuarter = ((d.month - 1) ~/ 3) + 1;
          return d.year == today.year && dateQuarter == currentQuarter;
        case _PeriodFilter.thisYear:
          return d.year == today.year;
      }
    }

    final filtered = journals.where((j) {
      if (!periodMatch(j.journalDate)) return false;
      if (!_viewMatch(j, view)) return false;
      if (query.isEmpty) return true;

      return j.journalNumber.toLowerCase().contains(query) ||
          (j.referenceNumber ?? '').toLowerCase().contains(query) ||
          (j.notes ?? '').toLowerCase().contains(query) ||
          _statusLabel(j.status).toLowerCase().contains(query) ||
          _reportingMethodLabel(
            j.reportingMethod,
          ).toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final compare = _compareJournals(a, b, sortColumn);
      if (compare != 0) return sortAscending ? compare : -compare;
      return _stabilizeSort(a, b);
    });

    return filtered;
  }

  int _compareJournals(ManualJournal a, ManualJournal b, _SortColumn column) {
    switch (column) {
      case _SortColumn.date:
        return a.journalDate.compareTo(b.journalDate);
      case _SortColumn.journalNumber:
        return a.journalNumber.toLowerCase().compareTo(
          b.journalNumber.toLowerCase(),
        );
      case _SortColumn.referenceNumber:
        return (a.referenceNumber ?? '').toLowerCase().compareTo(
          (b.referenceNumber ?? '').toLowerCase(),
        );
      case _SortColumn.status:
        return _statusLabel(a.status).compareTo(_statusLabel(b.status));
      case _SortColumn.amount:
        return a.totalDebit.compareTo(b.totalDebit);
      case _SortColumn.createdBy:
        final aUser =
            ((a.userId ?? '').isEmpty ? 'zerpaiprivatelimited' : a.userId!)
                .toLowerCase();
        final bUser =
            ((b.userId ?? '').isEmpty ? 'zerpaiprivatelimited' : b.userId!)
                .toLowerCase();
        return aUser.compareTo(bUser);
      case _SortColumn.reportingMethod:
        return _reportingMethodLabel(a.reportingMethod).toLowerCase().compareTo(
          _reportingMethodLabel(b.reportingMethod).toLowerCase(),
        );
    }
  }

  int _stabilizeSort(ManualJournal a, ManualJournal b) {
    final byDate = b.journalDate.compareTo(a.journalDate);
    if (byDate != 0) return byDate;
    return b.createdAt.compareTo(a.createdAt);
  }

  bool _viewMatch(ManualJournal journal, _ViewFilter view) {
    switch (view) {
      case _ViewFilter.all:
        return true;
      case _ViewFilter.draft:
        return journal.status == ManualJournalStatus.draft;
      case _ViewFilter.published:
        return journal.status == ManualJournalStatus.posted;
      case _ViewFilter.cancelled:
        return journal.status == ManualJournalStatus.cancelled;
    }
  }

  String _periodLabel(_PeriodFilter filter) {
    switch (filter) {
      case _PeriodFilter.all:
        return 'All';
      case _PeriodFilter.today:
        return 'Today';
      case _PeriodFilter.thisWeek:
        return 'This Week';
      case _PeriodFilter.thisMonth:
        return 'This Month';
      case _PeriodFilter.thisQuarter:
        return 'This Quarter';
      case _PeriodFilter.thisYear:
        return 'This Year';
    }
  }

  String _viewLabel(_ViewFilter filter) {
    switch (filter) {
      case _ViewFilter.all:
        return 'All Manual Journals';
      case _ViewFilter.draft:
        return 'Draft';
      case _ViewFilter.published:
        return 'Published';
      case _ViewFilter.cancelled:
        return 'Cancelled';
    }
  }

  String _statusLabel(ManualJournalStatus status) {
    switch (status) {
      case ManualJournalStatus.draft:
        return 'DRAFT';
      case ManualJournalStatus.posted:
        return 'PUBLISHED';
      case ManualJournalStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _statusColor(ManualJournalStatus status) {
    switch (status) {
      case ManualJournalStatus.draft:
        return const Color(0xFFFF9900);
      case ManualJournalStatus.posted:
        return const Color(0xFF20A464);
      case ManualJournalStatus.cancelled:
        return AppTheme.errorRed;
    }
  }

  String _reportingMethodLabel(String method) {
    switch (method) {
      case 'accrual_and_cash':
        return 'Accrual and Cash';
      case 'accrual':
      case 'accrual_only':
        return 'Accrual Only';
      case 'cash':
      case 'cash_only':
        return 'Cash Only';
      default:
        return 'Accrual and Cash';
    }
  }

  List<String> _selectedIdsFrom(List<ManualJournal> journals) {
    final validIds = journals.map((journal) => journal.id).toSet();
    return _checkedJournalIds.where(validIds.contains).toList(growable: false);
  }
}

class _ActionMenuRow extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _ActionMenuRow({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CustomizeColumnsDialog extends StatefulWidget {
  final List<_ColumnDef> columns;
  final ValueChanged<List<_ColumnDef>> onSave;

  const _CustomizeColumnsDialog({required this.columns, required this.onSave});

  @override
  State<_CustomizeColumnsDialog> createState() =>
      _CustomizeColumnsDialogState();
}

class _CustomizeColumnsDialogState extends State<_CustomizeColumnsDialog> {
  late List<_ColumnDef> _localColumns;
  late TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _localColumns = widget.columns
        .map(
          (c) => _ColumnDef(
            id: c.id,
            label: c.label,
            flex: c.flex,
            isLocked: c.isLocked,
            isVisible: c.isVisible,
            sortColumn: c.sortColumn,
            headerAlignment: c.headerAlignment,
            padding: c.padding,
            textAlign: c.textAlign,
          ),
        )
        .toList();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _localColumns
        .where(
          (c) => c.label.toLowerCase().contains(_searchCtrl.text.toLowerCase()),
        )
        .toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      backgroundColor: AppTheme.bgLight,
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  LucideIcons.slidersHorizontal,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Customize Columns',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_localColumns.where((c) => c.isVisible).length} of ${_localColumns.length} Selected',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      _localColumns =
                          _ManualJournalsListPanelState._getDefaultColumns();
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      LucideIcons.rotateCcw,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Search
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            // List
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: ReorderableListView.builder(
                  itemCount: filtered.length,
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    if (_searchCtrl.text.isNotEmpty) return;
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = _localColumns.removeAt(oldIndex);
                      _localColumns.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final col = filtered[index];
                    return Container(
                      key: ValueKey(col.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: col.isLocked
                              ? null
                              : () {
                                  setState(
                                    () => col.isVisible = !col.isVisible,
                                  );
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(
                                    Icons.drag_indicator,
                                    size: 20,
                                    color: AppTheme.textMuted, // Lighter grey
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (col.isLocked)
                                  const Icon(
                                    LucideIcons.lock,
                                    size: 20,
                                    color: AppTheme.textSecondary,
                                  )
                                else
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: col.isVisible
                                          ? AppTheme.primaryBlue
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: col.isVisible
                                            ? AppTheme.primaryBlue
                                            : AppTheme.borderColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: col.isVisible
                                        ? const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    col.label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Footer
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.start, // Left aligned like Zoho
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.onSave(_localColumns);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    foregroundColor: AppTheme.textPrimary,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnDef {
  final String id;
  final String label;
  final int flex;
  final _SortColumn? sortColumn;
  final Alignment headerAlignment;
  final EdgeInsetsGeometry padding;
  final TextAlign textAlign;
  final bool isLocked;
  bool isVisible;

  _ColumnDef({
    required this.id,
    required this.label,
    required this.flex,
    this.sortColumn,
    this.headerAlignment = Alignment.centerLeft,
    this.padding = EdgeInsets.zero,
    this.textAlign = TextAlign.left,
    this.isLocked = false,
    this.isVisible = true,
  });
}
