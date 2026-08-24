import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/sales/credit_note/models/credit_note_model.dart';
import 'package:zerpai_erp/modules/sales/credit_note/providers/credit_note_provider.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_metrics.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/widgets/credit_note_more_menu.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_bulk_update_dialog.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/column_customizer.dart';

/// Loading placeholder for the report table: toolbar, sticky header, rows.
class _CreditNotesReportSkeleton extends StatelessWidget {
  const _CreditNotesReportSkeleton();

  static const _columnWidths = <double>[
    90, 130, 120, 90, 150, 100, 80, 90, 80, 90,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: const [
              Skeleton(width: 180, height: 22),
              Spacer(),
              Skeleton(width: 72, height: 34, borderRadius: 4),
              SizedBox(width: 12),
              Skeleton(width: 36, height: 36, borderRadius: 4),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Container(
          height: 40,
          color: AppTheme.bgLight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                const Skeleton(width: 16, height: 16, borderRadius: 3),
                const SizedBox(width: 16),
                for (final width in _columnWidths) ...[
                  Skeleton(width: width, height: 12),
                  const SizedBox(width: 24),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: 10,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    const Skeleton(width: 16, height: 16, borderRadius: 3),
                    const SizedBox(width: 16),
                    for (final width in _columnWidths) ...[
                      Skeleton(width: width, height: 12),
                      const SizedBox(width: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CreditNotesReportPage extends ConsumerStatefulWidget {
  const CreditNotesReportPage({super.key});

  @override
  ConsumerState<CreditNotesReportPage> createState() =>
      _CreditNotesReportPageState();
}

class _CreditNotesReportPageState
    extends ConsumerState<CreditNotesReportPage> {
  /// Width the header row and every body row lay out to.
  ///
  /// Derived from the visible columns rather than hardcoded: the previous
  /// literal (1920) was 12px short of the real content — the columns sum to
  /// 1840, plus 28 (column-menu icon), 32 (checkbox) and 2x16 padding = 1932 —
  /// which overflowed every row by exactly 12px.
  double get _tableWidth {
    final colSum = _visibleColumns.fold<double>(
      0.0,
      (sum, c) => sum + _CnColumnWidths.forId(c.id),
    );
    return colSum +
        ZTableMetrics.chrome(hasSelection: _selectedIndices.isNotEmpty);
  }

  /// Rebuilt from `creditNotesListProvider` on every build. Held as a field so
  /// the last good data survives a background refetch instead of blanking out.
  List<_CreditNoteRow> _rows = <_CreditNoteRow>[];

  static _CreditNoteRow _rowFromModel(CreditNoteModel m) {
    return _CreditNoteRow(
      id: m.id,
      date: m.formattedDate,
      location: '-',
      creditNoteNumber: m.creditNoteNumber,
      referenceNumber: (m.referenceNumber?.trim().isNotEmpty ?? false)
          ? m.referenceNumber!.trim()
          : '-',
      customerName: m.customerName ?? m.customerNumber ?? '-',
      invoiceNumber: '-',
      status: m.status,
      amount: m.formattedAmount,
      balance: '-',
      issueDate: m.formattedDate,
      salesPerson: '-',
    );
  }

  final ScrollController _horizontalScrollController = ScrollController();
  FavoriteFilterOption _activeOption = _cnFilterOptions.first;
  bool _columnMenuOpen = false;
  bool _isDeleting = false;
  String? _sortField;
  bool _sortAscending = true;
  final Set<int> _selectedIndices = {};
  List<ColumnConfig> _columns = _defaultColumns();
  final _moreMenuKey = GlobalKey();

  /// Shared with the credit note overview page so a view starred in one place
  /// shows up as a favorite in the other (same `credit_notes` module bucket).
  static const _cnFilterOptions = <FavoriteFilterOption>[
    FavoriteFilterOption(label: 'All', value: 'All'),
    FavoriteFilterOption(label: 'Draft', value: 'Draft'),
    FavoriteFilterOption(label: 'Locked', value: 'Locked'),
    FavoriteFilterOption(label: 'Pending Approval', value: 'Pending Approval'),
    FavoriteFilterOption(label: 'Approved', value: 'Approved'),
    FavoriteFilterOption(label: 'Open', value: 'Open'),
    FavoriteFilterOption(label: 'Closed', value: 'Closed'),
    FavoriteFilterOption(label: 'Void', value: 'Void'),
    FavoriteFilterOption(
      label: 'Invoice unassociated',
      value: 'Invoice unassociated',
    ),
  ];

  List<_CreditNoteRow> get _filteredRows {
    final label = _activeOption.label;
    final rows = label == 'All'
        ? List<_CreditNoteRow>.from(_rows)
        : _rows
              .where((r) => r.status.toUpperCase() == label.toUpperCase())
              .toList();
    final sortField = _sortField;
    if (sortField == null) return rows;

    rows.sort((a, b) {
      final comparison = switch (sortField) {
        'date' => _displayDate(a.date).compareTo(_displayDate(b.date)),
        'creditNoteNumber' => a.creditNoteNumber.toLowerCase().compareTo(
          b.creditNoteNumber.toLowerCase(),
        ),
        'customerName' => a.customerName.toLowerCase().compareTo(
          b.customerName.toLowerCase(),
        ),
        'amount' => _amountValue(a.amount).compareTo(_amountValue(b.amount)),
        _ => 0,
      };
      return _sortAscending ? comparison : -comparison;
    });
    return rows;
  }

  DateTime _displayDate(String value) {
    final parts = value.split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  double _amountValue(String value) =>
      double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;

  void _setSortRows(String field, bool ascending) {
    setState(() {
      _sortField = field;
      _sortAscending = ascending;
      _selectedIndices.clear();
    });
  }

  void _showMoreMenu(BuildContext context) {
    final box = _moreMenuKey.currentContext?.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;
    var menuTop = 65.0;
    var menuRight = 24.0;
    if (box != null) {
      final position = box.localToGlobal(Offset.zero);
      menuTop = position.dy + box.size.height + 4;
      menuRight = screenWidth - (position.dx + box.size.width);
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(dialogContext).pop(),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: menuTop,
            right: menuRight,
            child: CreditNoteMoreMenu(
              sortColumn: _sortField,
              sortAscending: _sortAscending,
              onSortChanged: (field, ascending) {
                Navigator.of(dialogContext).pop();
                _setSortRows(field, ascending);
              },
              onImport: () {
                Navigator.of(dialogContext).pop();
                _showUnavailableAction('Import');
              },
              onExport: () {
                Navigator.of(dialogContext).pop();
                _showUnavailableAction('Export');
              },
              onPreferences: () {
                Navigator.of(dialogContext).pop();
                _showUnavailableAction('Preferences');
              },
              onManageCustomFields: () {
                Navigator.of(dialogContext).pop();
                _openColumnCustomizer();
              },
              onRefreshList: () {
                Navigator.of(dialogContext).pop();
                _refreshRows();
              },
              onResetColumnWidth: () {
                Navigator.of(dialogContext).pop();
                _resetColumnSettings();
              },
            ),
          ),
        ],
      ),
    );
  }
  void _refreshRows() {
    ref.invalidate(creditNotesListProvider);
    ZerpaiToast.success(context, 'Credit notes refreshed.');
  }

  void _resetColumnSettings() {
    setState(() => _columns = _defaultColumns());
    ZerpaiToast.success(context, 'Column widths reset.');
  }

  void _showUnavailableAction(String action) {
    ZerpaiToast.info(context, '$action is not available for credit notes yet.');
  }

  bool get _allSelected =>
      _filteredRows.isNotEmpty &&
      _selectedIndices.length == _filteredRows.length;
  bool get _someSelected =>
      _selectedIndices.isNotEmpty &&
      _selectedIndices.length < _filteredRows.length;
  List<ColumnConfig> get _visibleColumns {
    final columns = _columns
        .where((c) => c.isVisible)
        .map((c) => c.copy())
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return columns;
  }

  static List<ColumnConfig> _defaultColumns() => [
        ColumnConfig(
          id: 'date',
          label: 'Date',
          orderIndex: 0,
          isLocked: true,
        ),
        ColumnConfig(
          id: 'creditNoteNumber',
          label: 'Credit Note#',
          orderIndex: 2,
          isLocked: true,
        ),
        ColumnConfig(
          id: 'referenceNumber',
          label: 'Reference#',
          orderIndex: 3,
        ),
        ColumnConfig(
          id: 'customerName',
          label: 'Customer Name',
          orderIndex: 4,
        ),
        ColumnConfig(
          id: 'invoiceNumber',
          label: 'Invoice#',
          orderIndex: 5,
        ),
        ColumnConfig(
          id: 'status',
          label: 'Status',
          orderIndex: 6,
        ),
        ColumnConfig(
          id: 'amount',
          label: 'Amount',
          orderIndex: 7,
        ),
        ColumnConfig(
          id: 'balance',
          label: 'Balance',
          orderIndex: 8,
        ),
        ColumnConfig(
          id: 'issueDate',
          label: 'Issue Date',
          orderIndex: 9,
        ),
        ColumnConfig(
          id: 'salesPerson',
          label: 'Sales Person',
          orderIndex: 10,
        ),
      ];

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndices.addAll(List.generate(_filteredRows.length, (i) => i));
      } else {
        _selectedIndices.clear();
      }
    });
  }

  void _toggleRow(int index, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndices.add(index);
      } else {
        _selectedIndices.remove(index);
      }
    });
  }

  void _openColumnCustomizer() {
    setState(() => _columnMenuOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => ColumnCustomizerDialog(
          columns: _columns,
          onSave: (columns) {
            setState(() {
              _columns = columns.map((c) => c.copy()).toList();
            });
            Navigator.of(dialogContext, rootNavigator: true).pop();
          },
        ),
      );
    });
  }

  void _openBulkUpdateDialog() {
    showCreditNoteBulkUpdateDialog(context);
  }

  /// Deletes every selected row through the API, then refetches. Rows are now
  /// projected from the provider on each build, so removing them from `_rows`
  /// locally would simply be undone by the next rebuild.
  Future<void> _deleteSelected() async {
    if (_isDeleting) return;

    // Selection indices point at the filtered view, so resolve them to row
    // objects before touching the backing list.
    final visible = _filteredRows;
    final doomed = _selectedIndices
        .where((i) => i >= 0 && i < visible.length)
        .map((i) => visible[i])
        .where((row) => row.id.isNotEmpty)
        .toList();

    if (doomed.isEmpty) {
      ZerpaiToast.error(context, 'These credit notes cannot be deleted.');
      return;
    }

    setState(() => _isDeleting = true);
    try {
      for (final row in doomed) {
        await ref.read(deleteCreditNoteProvider)(row.id);
      }
      if (!mounted) return;
      setState(() => _selectedIndices.clear());
      ref.invalidate(creditNotesListProvider);
      ZerpaiToast.success(
        context,
        doomed.length == 1
            ? 'Credit note deleted successfully.'
            : '${doomed.length} credit notes deleted successfully.',
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete credit notes',
        error: e,
        stackTrace: st,
        module: 'credit_note',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to delete: $e');
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  /// Opens the split overview for a row. The sidebar lands here on the report,
  /// so this is the way through to the overview — `view=overview` is what the
  /// route builder keys off.
  void _openInOverview(_CreditNoteRow row) {
    context.go(
      Uri(
        path: AppRoutes.salesCreditNotesOverview,
        queryParameters: {
          'cn': row.creditNoteNumber,
          'view': 'overview',
        },
      ).toString(),
    );
  }

  Widget _buildLoadErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load credit notes',
              style: TextStyle(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ZButton.secondary(
              label: 'Retry',
              onPressed: () => ref.invalidate(creditNotesListProvider),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditNotesAsync = ref.watch(creditNotesListProvider(null));
    final models = creditNotesAsync.valueOrNull;
    if (models != null) {
      _rows = models.map(_rowFromModel).toList();
    }
    // Only stand in for content that isn't there yet — a background refetch
    // with rows already on screen must not flash the skeleton.
    final showLoading = creditNotesAsync.isLoading && _rows.isEmpty;
    final showError = creditNotesAsync.hasError && _rows.isEmpty;

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useTopPadding: false,
      useHorizontalPadding: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_columnMenuOpen) {
            setState(() => _columnMenuOpen = false);
          }
        },
        child: Container(
          color: AppTheme.backgroundColor,
          child: showLoading
              ? const _CreditNotesReportSkeleton()
              : showError
                  ? _buildLoadErrorState(creditNotesAsync.error)
                  : Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _selectedIndices.isNotEmpty
                      ? _buildBulkToolbar()
                      : _buildToolbar(context),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, tableConstraints) => Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      scrollbarOrientation: ScrollbarOrientation.bottom,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          // Floor at the viewport width, not the window width:
                          // MediaQuery still counts the sidebar and left the
                          // table permanently scrolled right.
                          constraints: BoxConstraints(
                            minWidth: tableConstraints.maxWidth,
                          ),
                          child: SizedBox(
                            width: _tableWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _CnTableHeader(
                                  allSelected: _allSelected,
                                  someSelected: _someSelected,
                                  hasSelection: _selectedIndices.isNotEmpty,
                                  onSelectAll: _toggleSelectAll,
                                  columnMenuOpen: _columnMenuOpen,
                                  onColumnMenuTap: () => setState(() {
                                    _columnMenuOpen = !_columnMenuOpen;
                                  }),
                                  columns: _visibleColumns,
                                ),
                                const Divider(
                                  height: 1,
                                  color: AppTheme.borderLight,
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: _filteredRows.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(
                                      height: 1,
                                      color: AppTheme.borderLight,
                                    ),
                                    itemBuilder: (context, index) =>
                                        _CnTableRow(
                                      row: _filteredRows[index],
                                      selected: _selectedIndices
                                          .contains(index),
                                      hasSelection:
                                          _selectedIndices.isNotEmpty,
                                      onChanged: (v) =>
                                          _toggleRow(index, v),
                                      onTap: () => _openInOverview(
                                        _filteredRows[index],
                                      ),
                                      columns: _visibleColumns,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),
                ],
              ),
              if (_columnMenuOpen)
                Positioned(
                  top: 90,
                  left: 14,
                  child: Material(
                    elevation: 0,
                    color: AppTheme.backgroundColor.withValues(alpha: 0),
                    child: Container(
                      width: 172,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.textPrimary.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ColumnMenuOption(
                            label: 'Customize Columns',
                            icon: LucideIcons.columns,
                            selected: true,
                            onTap: _openColumnCustomizer,
                          ),
                          _ColumnMenuOption(
                            label: 'Clip Text',
                            icon: LucideIcons.alignJustify,
                            onTap: () {
                              setState(() => _columnMenuOpen = false);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          FavoriteFilterDropdown(
            moduleName: 'credit_notes',
            options: _cnFilterOptions,
            selectedOption: _activeOption,
            showChevron: true,
            onChanged: (opt) {
              setState(() {
                _activeOption = opt;
                _columnMenuOpen = false;
                _selectedIndices.clear();
              });
            },
          ),
          const Spacer(),
          ZButton.primary(
            label: 'New',
            icon: LucideIcons.plus,
            onPressed: () => context.go(AppRoutes.creditNotesCreate),
          ),
          const SizedBox(width: 12),
          SizedBox(
            key: _moreMenuKey,
            child: _CreditNoteMoreActionButton(
              onTap: () => _showMoreMenu(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkToolbar() {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Bulk Update
          _BulkActionButton(
            label: 'Bulk Update',
            onTap: _openBulkUpdateDialog,
          ),
          const SizedBox(width: 8),
          // Download with chevron
          _BulkActionButton(
            icon: LucideIcons.download,
            trailingIcon: LucideIcons.chevronDown,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Print
          _BulkActionButton(
            icon: LucideIcons.printer,
            onTap: () {},
          ),
          // Separator
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
          // Delete
          _BulkActionButton(
            label: 'Delete',
            onTap: _deleteSelected,
          ),
          // Separator
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
          // Count badge
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${_selectedIndices.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          // Clear selection X
          GestureDetector(
            onTap: () => setState(() => _selectedIndices.clear()),
            child: const Icon(
              LucideIcons.x,
              size: 20,
              color: Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkActionButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  const _BulkActionButton({
    this.label,
    this.icon,
    this.trailingIcon,
    required this.onTap,
  });

  @override
  State<_BulkActionButton> createState() => _BulkActionButtonState();
}

class _BulkActionButtonState extends State<_BulkActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        // Hover lifts the button onto a white chip with a darker border, the
        // same treatment as the document action bars elsewhere in sales.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white : Colors.transparent,
            border: Border.all(
              color: _hovered ? AppTheme.borderColor : AppTheme.borderLight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 16, color: AppTheme.textPrimary),
              if (widget.icon != null && widget.label != null)
                const SizedBox(width: 6),
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.trailingIcon,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnMenuOption extends StatefulWidget {
  const _ColumnMenuOption({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_ColumnMenuOption> createState() => _ColumnMenuOptionState();
}

class _ColumnMenuOptionState extends State<_ColumnMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final filled = _hovered;
    final foreground = filled
        ? AppTheme.backgroundColor
        : widget.selected
            ? AppTheme.primaryBlue
            : AppTheme.textPrimary;
    final iconColor = filled ? foreground : AppTheme.primaryBlue;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 32,
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: filled
                ? AppTheme.primaryBlue.withValues(alpha: 0.9)
                : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: filled
                ? Border.all(
                    color: AppTheme.primaryBlueDark,
                    width: 2,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: foreground,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CnTableHeader extends StatelessWidget {
  final bool allSelected;
  final bool someSelected;
  final bool hasSelection;
  final ValueChanged<bool?> onSelectAll;
  final bool columnMenuOpen;
  final VoidCallback onColumnMenuTap;
  final List<ColumnConfig> columns;

  const _CnTableHeader({
    required this.allSelected,
    required this.someSelected,
    required this.hasSelection,
    required this.onSelectAll,
    required this.columnMenuOpen,
    required this.onColumnMenuTap,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: ZTableMetrics.hPad),
      child: Row(
        children: [
          if (!hasSelection)
            SizedBox(
              width: ZTableMetrics.menuIcon,
              child: GestureDetector(
                onTap: onColumnMenuTap,
                child: Icon(
                  LucideIcons.slidersHorizontal,
                  size: 16,
                  color: columnMenuOpen
                      ? AppTheme.primaryBlueDark
                      : AppTheme.primaryBlue,
                ),
              ),
            ),
          SizedBox(
            width: ZTableMetrics.checkbox,
            child: Checkbox(
              value: allSelected ? true : (someSelected ? null : false),
              tristate: true,
              onChanged: (v) {
                // tristate cycles: null→true, true→false, false→true
                // We want: indeterminate or unchecked → select all, checked → deselect all
                onSelectAll(allSelected ? false : true);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
              visualDensity: VisualDensity.compact,
            ),
          ),
          for (final column in columns)
            _CnHeaderCell(
              width: _CnColumnWidths.forId(column.id),
              label: column.label.toUpperCase(),
              sorted: column.id == 'creditNoteNumber',
            ),
        ],
      ),
    );
  }
}

class _CnTableRow extends StatefulWidget {
  const _CnTableRow({
    required this.row,
    required this.selected,
    required this.hasSelection,
    required this.onChanged,
    required this.onTap,
    required this.columns,
  });
  final _CreditNoteRow row;
  final bool selected;
  final bool hasSelection;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTap;
  final List<ColumnConfig> columns;

  @override
  State<_CnTableRow> createState() => _CnTableRowState();
}

class _CnTableRowState extends State<_CnTableRow> {
  bool _hovered = false;

  _CreditNoteRow get row => widget.row;

  @override
  Widget build(BuildContext context) {
    // Matches the sales return report: selection is the stronger tint, hover a
    // lighter one, so a hovered row never outshines the selected one.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
        height: 48,
        color: widget.selected
            ? AppTheme.primaryBlue.withValues(alpha: 0.07)
            : _hovered
            ? AppTheme.primaryBlue.withValues(alpha: 0.03)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: ZTableMetrics.hPad),
        child: Row(
          children: [
            if (!widget.hasSelection)
              const SizedBox(width: ZTableMetrics.menuIcon),
            SizedBox(
              width: ZTableMetrics.checkbox,
              child: Checkbox(
                value: widget.selected,
                onChanged: widget.onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
                visualDensity: VisualDensity.compact,
              ),
            ),
            for (final column in widget.columns)
              _CnBodyCell(
                width: _CnColumnWidths.forId(column.id),
                child: _buildCell(column.id),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCell(String id) {
    switch (id) {
      case 'date':
        return _CnBodyText(row.date);
      case 'location':
        return _CnBodyText(row.location);
      case 'creditNoteNumber':
        return _CnBodyText(
          row.creditNoteNumber,
          color: AppTheme.primaryBlueDark,
          fontWeight: FontWeight.w600,
        );
      case 'referenceNumber':
        return _CnBodyText(row.referenceNumber);
      case 'customerName':
        return _CnBodyText(row.customerName);
      case 'invoiceNumber':
        return _CnBodyText(row.invoiceNumber);
      case 'status':
        return _CnBodyText(
          row.status,
          color: switch (row.status.toUpperCase()) {
            'CLOSED' => AppTheme.successGreen,
            'DRAFT' => AppTheme.textSecondary,
            _ => AppTheme.primaryBlue,
          },
          fontWeight: FontWeight.w500,
        );
      case 'amount':
        return _CnBodyText(row.amount);
      case 'balance':
        return _CnBodyText(row.balance);
      case 'issueDate':
        return _CnBodyText(row.issueDate);
      case 'salesPerson':
        return _CnBodyText(row.salesPerson);
      default:
        return const _CnBodyText('-');
    }
  }
}

class _CnColumnWidths {
  static const double date = 140;
  static const double location = 300;
  static const double creditNoteNumber = 160;
  static const double referenceNumber = 160;
  static const double customerName = 200;
  static const double invoiceNumber = 160;
  static const double status = 140;
  static const double amount = 130;
  static const double balance = 130;
  static const double issueDate = 150;
  static const double salesPerson = 170;

  static double forId(String id) {
    switch (id) {
      case 'date':
        return date;
      case 'location':
        return location;
      case 'creditNoteNumber':
        return creditNoteNumber;
      case 'referenceNumber':
        return referenceNumber;
      case 'customerName':
        return customerName;
      case 'invoiceNumber':
        return invoiceNumber;
      case 'status':
        return status;
      case 'amount':
        return amount;
      case 'balance':
        return balance;
      case 'issueDate':
        return issueDate;
      case 'salesPerson':
        return salesPerson;
      default:
        return 140;
    }
  }
}

class _CnHeaderCell extends StatelessWidget {
  const _CnHeaderCell({
    required this.width,
    required this.label,
    this.sorted = false,
  });
  final double width;
  final String label;
  final bool sorted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          if (sorted) ...[
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronsUpDown,
              size: 14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ],
      ),
    );
  }
}

class _CnBodyCell extends StatelessWidget {
  const _CnBodyCell({required this.width, required this.child});
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: child);
}

class _CnBodyText extends StatelessWidget {
  const _CnBodyText(
    this.text, {
    this.color = AppTheme.textPrimary,
    this.fontWeight = FontWeight.w400,
  });
  final String text;
  final Color color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13, fontWeight: fontWeight, color: color),
    );
  }
}

class _CreditNoteRow {
  const _CreditNoteRow({
    required this.id,
    required this.date,
    required this.location,
    required this.creditNoteNumber,
    required this.referenceNumber,
    required this.customerName,
    required this.invoiceNumber,
    required this.status,
    required this.amount,
    required this.balance,
    required this.issueDate,
    required this.salesPerson,
  });

  final String id;
  final String date;
  final String location;
  final String creditNoteNumber;
  final String referenceNumber;
  final String customerName;
  final String invoiceNumber;
  final String status;
  final String amount;
  final String balance;
  final String issueDate;
  final String salesPerson;
}

class _CreditNoteMoreActionButton extends StatelessWidget {
  const _CreditNoteMoreActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderLight),
            color: AppTheme.backgroundColor,
          ),
          child: const Icon(
            LucideIcons.moreHorizontal,
            size: 16,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
