import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart' as di;
import '../../models/recurring_journal_model.dart';
import '../../providers/recurring_journal_provider.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'recurring_journal_import_export_dialogs.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

enum RecurringJournalSortField {
  profileName,
  lastJournalDate,
  nextJournalDate,
  amount,
}

class RecurringJournalSortCommand {
  final RecurringJournalSortField field;
  final bool ascending;

  const RecurringJournalSortCommand({
    required this.field,
    required this.ascending,
  });
}

enum _SortColumn {
  profileName,
  frequency,
  lastJournalDate,
  nextJournalDate,
  status,
  amount,
}

class RecurringJournalsListPanel extends ConsumerStatefulWidget {
  final bool compact;
  final ValueNotifier<RecurringJournalSortCommand?>? sortCommandListenable;

  const RecurringJournalsListPanel({
    super.key,
    this.compact = false,
    this.sortCommandListenable,
  });

  @override
  ConsumerState<RecurringJournalsListPanel> createState() =>
      _RecurringJournalsListPanelState();
}

class _RecurringJournalsListPanelState
    extends ConsumerState<RecurringJournalsListPanel> {
  static const double _minTableWidth = 1000;

  // Define columns
  final List<_ColumnDef> _columns = _getDefaultColumns();

  static List<_ColumnDef> _getDefaultColumns() => [
    _ColumnDef(
      id: 'profileName',
      label: 'PROFILE NAME',
      flex: 20,
      sortColumn: _SortColumn.profileName,
      isLocked: true,
      textColor: AppTheme.primaryBlue,
    ),
    _ColumnDef(
      id: 'frequency',
      label: 'FREQUENCY',
      flex: 12,
      sortColumn: _SortColumn.frequency,
    ),
    _ColumnDef(
      id: 'lastJournalDate',
      label: 'LAST JOURNAL DATE',
      flex: 14,
      sortColumn: _SortColumn.lastJournalDate,
    ),
    _ColumnDef(
      id: 'nextJournalDate',
      label: 'NEXT JOURNAL DATE',
      flex: 14,
      sortColumn: _SortColumn.nextJournalDate,
    ),
    _ColumnDef(
      id: 'status',
      label: 'STATUS',
      flex: 10,
      sortColumn: _SortColumn.status,
    ),
    _ColumnDef(id: 'notes', label: 'NOTES', flex: 6),
    _ColumnDef(
      id: 'amount',
      label: 'AMOUNT',
      flex: 12,
      sortColumn: _SortColumn.amount,
      textAlign: TextAlign.right,
      headerAlignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 12),
    ),
  ];

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _horizontalScrollCtrl = ScrollController();

  _SortColumn _sortColumn = _SortColumn.profileName;
  bool _sortAscending = true;
  final Set<String> _checkedJournalIds = <String>{};
  int _pageSize = 50;
  int _pageIndex = 0;
  String _selectedFilter = 'all';
  bool _clipText = true;

  @override
  void initState() {
    super.initState();
    widget.sortCommandListenable?.addListener(_handleExternalSortCommand);
  }

  @override
  void didUpdateWidget(covariant RecurringJournalsListPanel oldWidget) {
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
      RecurringJournalSortField.profileName => _SortColumn.profileName,
      RecurringJournalSortField.lastJournalDate => _SortColumn.lastJournalDate,
      RecurringJournalSortField.nextJournalDate => _SortColumn.nextJournalDate,
      RecurringJournalSortField.amount => _SortColumn.amount,
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
    final state = ref.watch(recurringJournalProvider);
    final notifier = ref.read(recurringJournalProvider.notifier);

    final filtered = _filteredAndSorted(
      state.journals,
      _searchCtrl.text,
      _selectedFilter,
      _sortColumn,
      _sortAscending,
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
        ? <RecurringJournal>[]
        : filtered.sublist(pageStartIndex, pageEndIndex);

    if (widget.compact) {
      if (state.isLoading && state.journals.isEmpty) {
        return const TableSkeleton(columns: 3, showHeader: false);
      }
      if (state.error != null && state.journals.isEmpty) {
        return TableErrorPlaceholder(
          error: state.error!,
          onRetry: notifier.fetchJournals,
        );
      }
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'new_view') {
                      _showNewCustomViewDialog();
                      return;
                    }
                    setState(() {
                      _selectedFilter = value;
                      _pageIndex = 0;
                    });
                  },
                  tooltip: 'Filter Views',
                  itemBuilder: (context) {
                    final customViews = ref
                        .watch(recurringJournalProvider)
                        .customViews;
                    return [
                      const PopupMenuItem(value: 'all', child: Text('All')),
                      const PopupMenuItem(
                        value: 'active',
                        child: Text('Active'),
                      ),
                      const PopupMenuItem(
                        value: 'stopped',
                        child: Text('Stopped'),
                      ),
                      const PopupMenuItem(
                        value: 'expired',
                        child: Text('Expired'),
                      ),
                      if (customViews.isNotEmpty) ...[
                        const PopupMenuDivider(),
                        ...customViews.map(
                          (v) => PopupMenuItem(
                            value: 'custom_${v.id}',
                            child: Text(v.name),
                          ),
                        ),
                      ],
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'new_view',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.plusCircle,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'New Custom View',
                              style: TextStyle(color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                  child: Row(
                    children: [
                      Text(
                        _selectedFilter == 'all'
                            ? 'All Recurring Jo...'
                            : '${_selectedFilter[0].toUpperCase()}${_selectedFilter.substring(1)} Recurring...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Create Recurring Journal',
                  child: InkWell(
                    onTap: () =>
                        context.go(AppRoutes.accountantRecurringJournalsCreate),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: PopupMenuButton<String>(
                    tooltip: 'More actions',
                    onSelected: (value) {
                      if (value == 'import') {
                        _showImportDialog();
                      } else if (value == 'export') {
                        _showExportDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'import',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.download,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Import Recurring Journals',
                              style: TextStyle(color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.upload,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Export Recurring Journals',
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                    offset: const Offset(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      LucideIcons.moreHorizontal,
                      size: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              itemCount: paged.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppTheme.borderColor),
              itemBuilder: (context, index) {
                final journal = paged[index];
                final isSelected = state.selectedJournalId == journal.id;
                final nextRun = _calculateNextRun(journal);
                final f = NumberFormat.currency(symbol: '₹');
                final d = DateFormat('dd/MM/yyyy');

                return InkWell(
                   onTap: () => context.go(
                    AppRoutes.accountantRecurringJournalsDetail.replaceAll(
                      ':id',
                      journal.id,
                    ),
                  ),
                  child: Container(
                    color: isSelected
                        ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                        : Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                journal.profileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppTheme.primaryBlue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              f.format(journal.totalDebit),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              journal.lastGeneratedDate != null
                                  ? 'Last Run: ${d.format(journal.lastGeneratedDate!)}'
                                  : 'Starts: ${d.format(journal.startDate)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              _formatFrequency(journal),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StatusBadge(journal: journal),
                            const Spacer(),
                            Text(
                              'Next Journal Date: ${d.format(nextRun)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
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

    final selectedIds = _selectedIdsFrom(state.journals);

    return Column(
      children: [
        // Title Row not needed here as it is in overview screen, but we need search/filter bar
        _buildFilterBar(),

        if (selectedIds.isNotEmpty)
          _buildBulkActionBar(
            notifier: notifier,
            allJournals: state.journals,
            selectedIds: selectedIds,
            isMutating: state.isMutating,
          ),

        const Divider(height: 1, color: AppTheme.borderColor),

        Expanded(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tableWidth = math.max(
                      constraints.maxWidth,
                      _minTableWidth,
                    );
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
                              const Divider(
                                height: 1,
                                color: AppTheme.borderColor,
                              ),
                              Expanded(
                                child: state.isLoading && state.journals.isEmpty
                                    ? const TableSkeleton(
                                        columns: 7,
                                        showHeader: false,
                                      )
                                    : (state.error != null &&
                                          state.journals.isEmpty)
                                    ? TableErrorPlaceholder(
                                        error: state.error!,
                                        onRetry: notifier.fetchJournals,
                                      )
                                    : filtered.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No recurring journals found.',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: paged.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                              height: 1,
                                              color: AppTheme.borderColor,
                                            ),
                                        itemBuilder: (context, index) {
                                          final journal = paged[index];
                                          final selected =
                                              state.selectedJournalId ==
                                              journal.id;
                                          return _buildDataRow(
                                            journal: journal,
                                            selected: selected,
                                            checked: _checkedJournalIds
                                                .contains(journal.id),
                                            onTap: () => context.go(
                                              AppRoutes
                                                  .accountantRecurringJournalsDetail
                                                  .replaceAll(
                                                    ':id',
                                                    journal.id,
                                                  ),
                                            ),
                                            onCheckChanged: (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _checkedJournalIds.add(
                                                    journal.id,
                                                  );
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
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text(
            'All Recurring Journals', // Matches View Filter Title in Manual
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  List<String> _selectedIdsFrom(List<RecurringJournal> journals) {
    final validIds = journals.map((journal) => journal.id).toSet();
    return _checkedJournalIds.where(validIds.contains).toList(growable: false);
  }

  Widget _buildBulkActionBar({
    required RecurringJournalNotifier notifier,
    required List<RecurringJournal> allJournals,
    required List<String> selectedIds,
    required bool isMutating,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: isMutating
                ? null
                : () => _deleteSelected(notifier, allJournals),
            child: const Text('Delete'),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 24, color: AppTheme.borderColor),
          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              selectedIds.length.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Selected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: isMutating
                ? null
                : () => setState(() => _checkedJournalIds.clear()),
            child: const Text('Esc'),
          ),
          IconButton(
            tooltip: 'Clear selection',
            onPressed: isMutating
                ? null
                : () => setState(() => _checkedJournalIds.clear()),
            icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected(
    RecurringJournalNotifier notifier,
    List<RecurringJournal> allJournals,
  ) async {
    final selectedIds = _selectedIdsFrom(allJournals);
    if (selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recurring journals?'),
        content: Text(
          'This will delete ${selectedIds.length} selected journal(s).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Since provider doesn't support bulk delete yet, iterate
      for (final id in selectedIds) {
        await notifier.deleteJournal(id);
      }
      if (!mounted) return;
      setState(() => _checkedJournalIds.clear());
      ZerpaiToast.success(
        context,
        'Deleted ${selectedIds.length} recurring journal(s).',
      );
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to delete journals: $e');
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
            width: 130,
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

  Widget _buildTableHeader(List<RecurringJournal> journals) {
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
            width: 32, // Width to fit the columns icon
            child: PopupMenuButton<String>(
              tooltip: 'Customize Columns',
              onSelected: (value) async {
                if (value == 'customize') {
                  final newColumns = await showDialog<List<_ColumnDef>>(
                    context: context,
                    builder: (context) =>
                        _CustomizeColumnsDialog(columns: _columns),
                  );
                  if (newColumns != null && mounted) {
                    setState(() {
                      _columns.clear();
                      _columns.addAll(newColumns);
                    });
                  }
                } else if (value == 'clip') {
                  setState(() {
                    _clipText = !_clipText;
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'customize',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.columns,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      SizedBox(width: 8),
                      Text('Customize Columns'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clip',
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alignLeft,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ), // Use appropriate icon
                      const SizedBox(width: 8),
                      Text(_clipText ? 'Wrap Text' : 'Clip Text'),
                    ],
                  ),
                ),
              ],
              icon: const Icon(
                LucideIcons.slidersHorizontal,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                if (allChecked) {
                  setState(() => _checkedJournalIds.clear());
                } else {
                  setState(() {
                    _checkedJournalIds.addAll(journals.map((j) => j.id));
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Checkbox(
                  value: headerValue,
                  tristate: true,
                  onChanged: (v) {
                    if (v == true) {
                      setState(() {
                        _checkedJournalIds.addAll(journals.map((j) => j.id));
                      });
                    } else {
                      setState(() => _checkedJournalIds.clear());
                    }
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
          ..._columns.where((c) => c.isVisible).map((col) {
            return Expanded(
              flex: col.flex,
              child: Padding(
                padding: col.padding,
                child: InkWell(
                  onTap: col.sortColumn == null
                      ? null
                      : () {
                          setState(() {
                            if (_sortColumn == col.sortColumn) {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortColumn = col.sortColumn!;
                              _sortAscending = true;
                            }
                            _pageIndex = 0;
                          });
                        },
                  child: Row(
                    mainAxisAlignment:
                        col.headerAlignment == Alignment.centerRight
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Text(
                        col.label,
                        style: headerStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (col.sortColumn != null &&
                          _sortColumn == col.sortColumn) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _sortAscending
                              ? LucideIcons.arrowUp
                              : LucideIcons.arrowDown,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required RecurringJournal journal,
    required bool selected,
    required bool checked,
    required VoidCallback onTap,
    required ValueChanged<bool?> onCheckChanged,
  }) {
    final nextDate = _calculateNextRun(journal);
    final rowStyle = TextStyle(
      fontSize: 13,
      color: selected ? AppTheme.primaryBlue : AppTheme.textPrimary,
      fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected
            ? AppTheme.primaryBlue.withValues(alpha: 0.05)
            : (checked ? AppTheme.bgLight : Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 32),
            SizedBox(
              width: 36,
              child: Checkbox(
                value: checked,
                onChanged: onCheckChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            ..._columns.where((c) => c.isVisible).map((col) {
              Widget cellContent;
              switch (col.id) {
                case 'profileName':
                  cellContent = Text(
                    journal.profileName,
                    style: rowStyle.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: _clipText ? 1 : null,
                    overflow: _clipText ? TextOverflow.ellipsis : null,
                  );
                  break;
                case 'frequency':
                  cellContent = Text(
                    _formatFrequency(journal),
                    style: rowStyle,
                  );
                  break;
                case 'lastJournalDate':
                  cellContent = Text(
                    journal.lastGeneratedDate != null
                        ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(journal.lastGeneratedDate!)
                        : '-',
                    style: rowStyle,
                  );
                  break;
                case 'nextJournalDate':
                  cellContent = Text(
                    DateFormat('dd/MM/yyyy').format(nextDate),
                    style: rowStyle,
                  );
                  break;
                case 'status':
                  cellContent = _StatusBadge(journal: journal);
                  break;
                case 'notes':
                  cellContent = journal.notes?.isNotEmpty == true
                      ? Tooltip(
                          message: journal.notes!,
                          child: const Icon(
                            LucideIcons.fileText,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                        )
                      : const SizedBox.shrink();
                  break;
                case 'amount':
                  cellContent = Text(
                    NumberFormat.currency(
                      symbol: '₹',
                    ).format(journal.totalDebit),
                    style: rowStyle,
                    textAlign: TextAlign.right,
                  );
                  break;
                default:
                  cellContent = const SizedBox.shrink();
              }

              return Expanded(
                flex: col.flex,
                child: Padding(
                  padding: col.padding,
                  child: Align(
                    alignment: col.textAlign == TextAlign.right
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: cellContent,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatFrequency(RecurringJournal journal) {
    final unit = journal.repeatEvery.toLowerCase();

    // Safety check just in case backend has saved it with plural already
    final cleanUnit = unit.endsWith('s')
        ? unit.substring(0, unit.length - 1)
        : unit;
    final displayUnit = cleanUnit.isNotEmpty
        ? '${cleanUnit[0].toUpperCase()}${cleanUnit.substring(1)}'
        : '';

    if (journal.interval > 1) {
      return 'Every ${journal.interval} ${displayUnit}s';
    } else {
      return 'Every $displayUnit';
    }
  }

  DateTime _calculateNextRun(RecurringJournal journal) {
    DateTime base = journal.startDate;
    final unit = journal.repeatEvery.toLowerCase();
    final n = journal.interval > 0 ? journal.interval : 1;

    DateTime next = base;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (journal.lastGeneratedDate != null) {
      DateTime lastRun = DateTime(
        journal.lastGeneratedDate!.year,
        journal.lastGeneratedDate!.month,
        journal.lastGeneratedDate!.day,
      );
      while (next.compareTo(lastRun) <= 0) {
        if (unit.contains('week')) {
          next = next.add(Duration(days: 7 * n));
        } else if (unit.contains('month')) {
          next = DateTime(next.year, next.month + n, next.day);
        } else if (unit.contains('year')) {
          next = DateTime(next.year + n, next.month, next.day);
        } else {
          next = next.add(Duration(days: n));
        }
      }
    } else {
      // Visually project the next future schedule date for the user based on today
      // if it hasn't generated yet but is strictly in the past.
      while (next.isBefore(today)) {
        if (unit.contains('week')) {
          next = next.add(Duration(days: 7 * n));
        } else if (unit.contains('month')) {
          next = DateTime(next.year, next.month + n, next.day);
        } else if (unit.contains('year')) {
          next = DateTime(next.year + n, next.month, next.day);
        } else {
          next = next.add(Duration(days: n));
        }
      }
    }

    return next;
  }

  List<RecurringJournal> _filteredAndSorted(
    List<RecurringJournal> journals,
    String searchQuery,
    String filter,
    _SortColumn sortColumn,
    bool sortAscending,
  ) {
    var list = [...journals];

    // Status filter
    if (filter != 'all') {
      final now = DateTime.now();
      if (filter.startsWith('custom_')) {
        final viewId = filter.replaceFirst('custom_', '');
        final customViews = ref.read(recurringJournalProvider).customViews;
        final view = customViews.cast<RecurringJournalCustomView?>().firstWhere(
          (v) => v?.id == viewId,
          orElse: () => null,
        );

        if (view != null) {
          list = list.where((j) {
            bool matches = true;
            if (view.status != null && j.status != view.status) matches = false;
            if (view.minAmount != null && j.totalDebit < view.minAmount!)
              matches = false;
            if (view.maxAmount != null && j.totalDebit > view.maxAmount!)
              matches = false;
            if (view.profileNameContains != null &&
                !j.profileName.toLowerCase().contains(
                  view.profileNameContains!.toLowerCase(),
                ))
              matches = false;
            return matches;
          }).toList();
        }
      } else {
        list = list.where((j) {
          if (filter == 'active')
            return j.status == RecurringJournalStatus.active;
          if (filter == 'stopped')
            return j.status == RecurringJournalStatus.inactive;
          if (filter == 'expired') {
            return !j.neverExpires &&
                j.endDate != null &&
                j.endDate!.isBefore(now);
          }
          return true;
        }).toList();
      }
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((j) {
        return j.profileName.toLowerCase().contains(q) ||
            (j.referenceNumber?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    list.sort((a, b) {
      int cmp = 0;
      switch (sortColumn) {
        case _SortColumn.profileName:
          cmp = a.profileName.compareTo(b.profileName);
          break;
        case _SortColumn.frequency:
          cmp = a.repeatEvery.compareTo(b.repeatEvery);
          break;
        case _SortColumn.lastJournalDate:
          final da = a.lastGeneratedDate ?? DateTime(1900);
          final db = b.lastGeneratedDate ?? DateTime(1900);
          cmp = da.compareTo(db);
          break;
        case _SortColumn.nextJournalDate:
          final da = _calculateNextRun(a);
          final db = _calculateNextRun(b);
          cmp = da.compareTo(db);
          break;
        case _SortColumn.status:
          cmp = a.status.name.compareTo(b.status.name);
          break;
        case _SortColumn.amount:
          cmp = a.totalDebit.compareTo(b.totalDebit);
          break;
      }
      return sortAscending ? cmp : -cmp;
    });

    return list;
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => RecurringJournalImportDialog(
        onImport: () {
          Navigator.pop(context);
          ZerpaiToast.show(context, 'Import starting...');
        },
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => RecurringJournalExportDialog(
        onExport: () {
          Navigator.pop(context);
          ZerpaiToast.show(context, 'Exporting journals...');
        },
      ),
    );
  }

  void _showNewCustomViewDialog() {
    showDialog(
      context: context,
      builder: (context) => _NewCustomViewDialog(
        onSave: (view) {
          ref.read(recurringJournalProvider.notifier).addCustomView(view);
          setState(() {
            _selectedFilter = 'custom_${view.id}';
            _pageIndex = 0;
          });
        },
      ),
    );
  }
}

class _ColumnDef {
  final String id;
  final String label;
  final int flex;
  final _SortColumn? sortColumn;
  final bool isLocked;
  final TextAlign textAlign;
  final Alignment headerAlignment;
  final EdgeInsets padding;
  final Color? textColor;
  bool isVisible = true;

  _ColumnDef({
    required this.id,
    required this.label,
    required this.flex,
    this.sortColumn,
    this.isLocked = false,
    this.textAlign = TextAlign.left,
    this.headerAlignment = Alignment.centerLeft,
    this.padding = EdgeInsets.zero,
    this.textColor,
  });
}

class _StatusBadge extends StatelessWidget {
  final RecurringJournal journal;
  const _StatusBadge({required this.journal});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    // Check for expiration
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isExpired = false;

    if (journal.endDate != null && !journal.neverExpires) {
      final end = DateTime(
        journal.endDate!.year,
        journal.endDate!.month,
        journal.endDate!.day,
      );
      if (today.isAfter(end)) {
        isExpired = true;
      }
    }

    if (isExpired) {
      color = AppTheme.errorRed;
      label = 'EXPIRED';
    } else {
      switch (journal.status) {
        case RecurringJournalStatus.active:
          color = AppTheme.accentGreen;
          label = 'ACTIVE';
          break;
        case RecurringJournalStatus.inactive:
          color = AppTheme.textSecondary;
          label = 'INACTIVE';
          break;
        case RecurringJournalStatus.draft:
          color = AppTheme.primaryBlue;
          label = 'DRAFT';
          break;
      }
    }

    return Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    );
  }
}

class _CustomizeColumnsDialog extends StatefulWidget {
  final List<_ColumnDef> columns;

  const _CustomizeColumnsDialog({required this.columns});

  @override
  State<_CustomizeColumnsDialog> createState() =>
      _CustomizeColumnsDialogState();
}

class _CustomizeColumnsDialogState extends State<_CustomizeColumnsDialog> {
  late List<_ColumnDef> _columns;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _columns = List.from(widget.columns);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _columns.removeAt(oldIndex);
      _columns.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter for display, but reorder on main list is tricky if filtered.
    // For simplicity, disable reorder when searching.
    final displayColumns = _searchQuery.isEmpty
        ? _columns
        : _columns
              .where(
                (col) => col.label.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    return Dialog(
      backgroundColor: AppTheme.bgLight,
      elevation: 0,
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  '${_columns.where((c) => c.isVisible).length} of ${_columns.length} Selected',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      _columns =
                          _RecurringJournalsListPanelState._getDefaultColumns();
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
              onChanged: (val) => setState(() => _searchQuery = val),
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
            Flexible(
              child: _searchQuery.isEmpty
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: displayColumns.length,
                      onReorder: _onReorder,
                      itemBuilder: (context, index) =>
                          _buildItem(displayColumns[index], index, true),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: displayColumns.length,
                      itemBuilder: (context, index) =>
                          _buildItem(displayColumns[index], index, false),
                    ),
            ),
            const SizedBox(height: 16),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_columns),
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
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildItem(_ColumnDef col, int index, bool reorderEnabled) {
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
          borderRadius: BorderRadius.circular(4),
          onTap: col.isLocked
              ? null
              : () {
                  setState(() => col.isVisible = !col.isVisible);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_indicator,
                    size: 20,
                    color: AppTheme.textMuted,
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
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
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
  }
}

class _NewCustomViewDialog extends StatefulWidget {
  final Function(RecurringJournalCustomView) onSave;
  const _NewCustomViewDialog({required this.onSave});

  @override
  State<_NewCustomViewDialog> createState() => _NewCustomViewDialogState();
}

class _NewCustomViewDialogState extends State<_NewCustomViewDialog> {
  final _nameCtrl = TextEditingController();
  final _profileNameCtrl = TextEditingController();
  final _minAmtCtrl = TextEditingController();
  final _maxAmtCtrl = TextEditingController();
  RecurringJournalStatus? _status;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _profileNameCtrl.dispose();
    _minAmtCtrl.dispose();
    _maxAmtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Custom View'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'View Name',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., High Value active Journals',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Criteria',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            di.FormDropdown<RecurringJournalStatus?>(
              value: _status,
              items: const [null, ...RecurringJournalStatus.values],
              displayStringForValue: (v) =>
                  v?.name.toUpperCase() ?? 'ANY STATUS',
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 16),
            const Text(
              'Profile Name Contains',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _profileNameCtrl,
              decoration: const InputDecoration(
                hintText: 'Enter text',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Min Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _minAmtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Max Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _maxAmtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Any',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.isEmpty) {
              ZerpaiToast.error(context, 'Please enter a name for the view');
              return;
            }
            final view = RecurringJournalCustomView(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameCtrl.text,
              status: _status,
              minAmount: double.tryParse(_minAmtCtrl.text),
              maxAmount: double.tryParse(_maxAmtCtrl.text),
              profileNameContains: _profileNameCtrl.text.isEmpty
                  ? null
                  : _profileNameCtrl.text,
            );
            widget.onSave(view);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Create View'),
        ),
      ],
    );
  }
}
