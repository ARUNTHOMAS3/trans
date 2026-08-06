import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/presentation/purchases_purchase_returns_overview.dart';

// ── List row model ────────────────────────────────────────────────────────────

class _PrListRow {
  final String id;
  final String returnNumber;
  final String date;
  final String vendorName;
  final String status;
  final double amount;
  final String? purchaseOrderNumber;

  const _PrListRow({
    required this.id,
    required this.returnNumber,
    required this.date,
    required this.vendorName,
    required this.status,
    required this.amount,
    this.purchaseOrderNumber,
  });
}

// ── Status helpers ─────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'confirmed':
      return AppTheme.primaryBlue;
    case 'vendor_received':
      return AppTheme.successGreen;
    default:
      return AppTheme.textSecondary;
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'confirmed':
      return 'Confirmed';
    case 'vendor_received':
      return 'Vendor Received';
    default:
      return 'Draft';
  }
}

// ── Report Page ───────────────────────────────────────────────────────────────

class PurchaseReturnsReportPage extends ConsumerStatefulWidget {
  final String? initialId;
  final String? initialSearch;
  final String? initialStatus;

  const PurchaseReturnsReportPage({
    super.key,
    this.initialId,
    this.initialSearch,
    this.initialStatus,
  });

  @override
  ConsumerState<PurchaseReturnsReportPage> createState() =>
      _PurchaseReturnsReportPageState();
}

class _PurchaseReturnsReportPageState
    extends ConsumerState<PurchaseReturnsReportPage> {
  static const _viewOptions = ['All', 'Draft', 'Confirmed', 'Vendor Received'];

  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');

  String _selectedView = 'All';
  bool _dropdownOpen = false;
  bool _favoritesExpanded = true;
  bool _defaultFiltersExpanded = true;
  final Set<String> _starredViews = {'Draft'};
  int? _detailIndex;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<int> _selectedIndices = {};

  bool _receiveBatchesExpanded = true;
  final GlobalKey _prJournalKey = GlobalKey();

  final ScrollController _detailScrollController = ScrollController();
  final ScrollController _hScrollController = ScrollController();
  final LayerLink _filterDropdownLink = LayerLink();
  final LayerLink _columnMenuLink = LayerLink();
  final LayerLink _pdfPrintLink = LayerLink();
  OverlayEntry? _pdfPrintOverlay;

  // ── Column config ────────────────────────────────────────────────────────────

  static List<ColumnConfig> _defaultColumns() => [
        ColumnConfig(id: 'date', label: 'Date', orderIndex: 0, isLocked: true),
        ColumnConfig(id: 'returnNumber', label: 'Return #', orderIndex: 1, isLocked: true),
        ColumnConfig(id: 'vendorName', label: 'Vendor', orderIndex: 2),
        ColumnConfig(id: 'purchaseOrder', label: 'Purchase Order', orderIndex: 3),
        ColumnConfig(id: 'status', label: 'Status', orderIndex: 4),
        ColumnConfig(id: 'amount', label: 'Amount', orderIndex: 5),
      ];

  List<ColumnConfig> _columns = _defaultColumns();
  bool _columnMenuOpen = false;

  Map<String, double> _colWidths = {
    'date': 140,
    'returnNumber': 140,
    'vendorName': 200,
    'purchaseOrder': 180,
    'status': 130,
    'amount': 130,
  };

  String _textMode = 'clip';
  String _sortColumn = 'returnNumber';
  bool _sortAscending = true;

  List<ColumnConfig> get _visibleColumns =>
      _columns.where((c) => c.isVisible).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  double get _tableWidth {
    final colSum = _visibleColumns.fold(
      0.0,
      (sum, c) => sum + (_colWidths[c.id] ?? 120),
    );
    return colSum + 92; // 16(pad) + 28(icon) + 32(checkbox) + 16(pad)
  }

  void _onColumnResize(String id, double delta) {
    final current = _colWidths[id] ?? 120;
    final next = (current + delta).clamp(60.0, 600.0);
    if ((next - current).abs() < 0.5) return;
    setState(() => _colWidths = {..._colWidths, id: next});
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
          onSave: (updated) {
            setState(() {
              _columns = updated
                  .map((c) => ColumnConfig(
                        id: c.id,
                        label: c.label,
                        isVisible: c.isVisible,
                        orderIndex: c.orderIndex,
                        isLocked: c.isLocked,
                      ))
                  .toList();
            });
            Navigator.of(dialogContext, rootNavigator: true).pop();
          },
        ),
      );
    });
  }

  bool get _allSelected =>
      _filteredRows.isNotEmpty &&
      _selectedIndices.length == _filteredRows.length;

  bool get _someSelected =>
      _selectedIndices.isNotEmpty &&
      _selectedIndices.length < _filteredRows.length;

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndices
            .addAll(List.generate(_filteredRows.length, (i) => i));
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

  final List<_PrListRow> _rows = const [
    _PrListRow(
      id: 'PR-00001',
      returnNumber: 'PR-00001',
      date: '20-04-2026',
      vendorName: 'ZERPAI TESTING',
      status: 'draft',
      amount: 4838.00,
      purchaseOrderNumber: 'PO-00042',
    ),
    _PrListRow(
      id: 'PR-00002',
      returnNumber: 'PR-00002',
      date: '22-04-2026',
      vendorName: 'ACME SUPPLIES',
      status: 'confirmed',
      amount: 12450.00,
      purchaseOrderNumber: 'PO-00045',
    ),
    _PrListRow(
      id: 'PR-00003',
      returnNumber: 'PR-00003',
      date: '25-04-2026',
      vendorName: 'GLOBAL IMAGING',
      status: 'vendor_received',
      amount: 2300.00,
      purchaseOrderNumber: 'PO-00047',
    ),
    _PrListRow(
      id: 'PR-00004',
      returnNumber: 'PR-00004',
      date: '28-04-2026',
      vendorName: 'TECH DISTRIBUTORS',
      status: 'draft',
      amount: 9800.00,
      purchaseOrderNumber: 'PO-00049',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      final mapped = _mapStatusParam(widget.initialStatus!);
      if (mapped != null) _selectedView = mapped;
    }
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchQuery = widget.initialSearch!;
      _searchController.text = widget.initialSearch!;
    }
    if (widget.initialId != null) {
      final idx = _filteredRows.indexWhere((r) => r.id == widget.initialId);
      if (idx >= 0) _detailIndex = idx;
    }
  }

  @override
  void didUpdateWidget(PurchaseReturnsReportPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool changed = false;

    if (widget.initialStatus != oldWidget.initialStatus) {
      final mapped = widget.initialStatus != null
          ? _mapStatusParam(widget.initialStatus!)
          : null;
      final next = mapped ?? 'All';
      if (next != _selectedView) {
        _selectedView = next;
        changed = true;
      }
    }

    if (widget.initialSearch != oldWidget.initialSearch) {
      final next = widget.initialSearch ?? '';
      if (next != _searchQuery) {
        _searchQuery = next;
        _searchController.text = next;
        changed = true;
      }
    }

    if (widget.initialId != oldWidget.initialId) {
      if (widget.initialId == null) {
        _detailIndex = null;
      } else {
        final idx = _filteredRows.indexWhere((r) => r.id == widget.initialId);
        _detailIndex = idx >= 0 ? idx : null;
      }
      changed = true;
    }

    if (changed) setState(() {});
  }

  String? _mapStatusParam(String param) {
    switch (param.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'confirmed':
        return 'Confirmed';
      case 'vendor_received':
      case 'vendor received':
        return 'Vendor Received';
      case 'all':
        return 'All';
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _pdfPrintOverlay?.remove();
    _searchController.dispose();
    _detailScrollController.dispose();
    _hScrollController.dispose();
    super.dispose();
  }

  void _showPdfPrintMenu(BuildContext context) {
    if (_pdfPrintOverlay != null) return;
    final overlay = Overlay.of(context);
    _pdfPrintOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePdfPrintMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _pdfPrintLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 36),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              child: Container(
                width: 160,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DownloadMenuOption(
                      icon: LucideIcons.fileText,
                      label: 'PDF',
                      onTap: _closePdfPrintMenu,
                    ),
                    _DownloadMenuOption(
                      icon: LucideIcons.printer,
                      label: 'Print',
                      onTap: _closePdfPrintMenu,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_pdfPrintOverlay!);
  }

  void _closePdfPrintMenu() {
    _pdfPrintOverlay?.remove();
    _pdfPrintOverlay = null;
  }

  List<_PrListRow> get _filteredRows {
    var list = _selectedView == 'All'
        ? List<_PrListRow>.from(_rows)
        : _rows
            .where((r) =>
                _statusLabel(r.status).toLowerCase() ==
                _selectedView.toLowerCase())
            .toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) {
        return r.returnNumber.toLowerCase().contains(q) ||
            r.vendorName.toLowerCase().contains(q) ||
            (r.purchaseOrderNumber ?? '').toLowerCase().contains(q);
      }).toList();
    }

    list.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 'date':
          // Parse dd-MM-yyyy for comparison
          DateTime _parseDate(String d) {
            final p = d.split('-');
            if (p.length == 3) {
              return DateTime(int.tryParse(p[2]) ?? 0, int.tryParse(p[1]) ?? 0, int.tryParse(p[0]) ?? 0);
            }
            return DateTime(0);
          }
          cmp = _parseDate(a.date).compareTo(_parseDate(b.date));
          break;
        case 'returnNumber':
          cmp = a.returnNumber.compareTo(b.returnNumber);
          break;
        case 'vendorName':
          cmp = a.vendorName.compareTo(b.vendorName);
          break;
        case 'purchaseOrder':
          cmp = (a.purchaseOrderNumber ?? '').compareTo(b.purchaseOrderNumber ?? '');
          break;
        case 'status':
          cmp = _statusLabel(a.status).compareTo(_statusLabel(b.status));
          break;
        case 'amount':
          cmp = a.amount.compareTo(b.amount);
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  String _buildUrl({String? id, String? status, String? q}) {
    final params = <String, String>{
      if (id != null) 'id': id,
      if (status != null && status != 'All') 'status': status.toLowerCase().replaceAll(' ', '_'),
      if (q != null && q.isNotEmpty) 'q': q,
    };
    if (params.isEmpty) return AppRoutes.purchaseReturns;
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '${AppRoutes.purchaseReturns}?$qs';
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.escape): () {
          if (_detailIndex != null) {
            setState(() => _detailIndex = null);
            context.go(_buildUrl(
              status: _selectedView != 'All' ? _selectedView : null,
              q: _searchQuery.isNotEmpty ? _searchQuery : null,
            ));
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useTopPadding: false,
      useHorizontalPadding: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_dropdownOpen || _columnMenuOpen) {
            setState(() {
              _dropdownOpen = false;
              _columnMenuOpen = false;
            });
          }
        },
        child: Container(
          color: AppTheme.backgroundColor,
          child: Stack(
            children: [
              if (_detailIndex != null)
                Positioned.fill(child: _buildSplitView(rows))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildToolbar(),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Expanded(child: _buildFullTable(rows)),
                  ],
                ),

              // Filter dropdown overlay
              if (_dropdownOpen)
                Positioned(
                  top: 0,
                  left: 0,
                  child: CompositedTransformFollower(
                    link: _filterDropdownLink,
                    showWhenUnlinked: false,
                    offset: const Offset(0, 40),
                    child: Material(
                      elevation: 0,
                      color: Colors.transparent,
                      child: Container(
                        width: 240,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 480),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _favoritesExpanded = !_favoritesExpanded,
                                  ),
                                  child: _PrDropdownSectionHeader(
                                    label: 'FAVORITES',
                                    count: _starredViews.length,
                                    countColor: AppTheme.primaryBlue,
                                    expanded: _favoritesExpanded,
                                  ),
                                ),
                                if (_favoritesExpanded && _starredViews.isNotEmpty)
                                  ..._viewOptions
                                      .where((opt) => _starredViews.contains(opt))
                                      .map(
                                        (opt) => _PrViewFilterOption(
                                          label: opt == 'All'
                                              ? 'All Purchase Returns'
                                              : '$opt Returns',
                                          selected: opt == _selectedView,
                                          starred: true,
                                          onStarTap: () => setState(
                                            () => _starredViews.remove(opt),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _selectedView = opt;
                                              _dropdownOpen = false;
                                              _detailIndex = null;
                                            });
                                            context.go(_buildUrl(
                                              status: opt != 'All' ? opt : null,
                                              q: _searchQuery.isNotEmpty
                                                  ? _searchQuery
                                                  : null,
                                            ));
                                          },
                                        ),
                                      ),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _defaultFiltersExpanded =
                                        !_defaultFiltersExpanded,
                                  ),
                                  child: _PrDropdownSectionHeader(
                                    label: 'DEFAULT FILTERS',
                                    count: _viewOptions.length,
                                    countColor: AppTheme.accentGreen,
                                    expanded: _defaultFiltersExpanded,
                                  ),
                                ),
                                if (_defaultFiltersExpanded)
                                  ..._viewOptions.map(
                                    (opt) => _PrViewFilterOption(
                                      label: opt == 'All'
                                          ? 'All Purchase Returns'
                                          : '$opt Returns',
                                      selected: opt == _selectedView,
                                      starred: _starredViews.contains(opt),
                                      onStarTap: () => setState(() {
                                        if (_starredViews.contains(opt)) {
                                          _starredViews.remove(opt);
                                        } else {
                                          _starredViews.add(opt);
                                        }
                                      }),
                                      onTap: () {
                                        setState(() {
                                          _selectedView = opt;
                                          _dropdownOpen = false;
                                          _detailIndex = null;
                                        });
                                        context.go(_buildUrl(
                                          status: opt != 'All' ? opt : null,
                                          q: _searchQuery.isNotEmpty
                                              ? _searchQuery
                                              : null,
                                        ));
                                      },
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

              // Column menu overlay
              if (_columnMenuOpen)
                Positioned(
                  top: 0,
                  left: 0,
                  child: CompositedTransformFollower(
                    link: _columnMenuLink,
                    showWhenUnlinked: false,
                    offset: const Offset(0, 44),
                    child: Material(
                      elevation: 0,
                      color: Colors.transparent,
                      child: Container(
                        width: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.textPrimary
                                  .withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PrColumnMenuOption(
                              label: 'Customize Columns',
                              icon: LucideIcons.columns,
                              selected: false,
                              onTap: _openColumnCustomizer,
                            ),
                            _PrColumnMenuOption(
                              label: _textMode == 'clip'
                                  ? 'Clip Text'
                                  : 'Wrap Text',
                              icon: _textMode == 'clip'
                                  ? LucideIcons.minus
                                  : LucideIcons.alignLeft,
                              selected: false,
                              onTap: () => setState(() {
                                _textMode =
                                    _textMode == 'clip' ? 'wrap' : 'clip';
                                _columnMenuOpen = false;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  // ── Toolbar ─────────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          CompositedTransformTarget(
            link: _filterDropdownLink,
            child: GestureDetector(
              onTap: () =>
                  setState(() => _dropdownOpen = !_dropdownOpen),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedView == 'All'
                        ? 'All Purchase Returns'
                        : '$_selectedView Returns',
                    style: AppTheme.pageTitle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _dropdownOpen
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 18,
                    color: AppTheme.primaryBlueDark,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 200,
            height: 32,
            child: TextField(
              controller: _searchController,
              style: AppTheme.tableCell,
              decoration: InputDecoration(
                hintText: 'Search returns…',
                hintStyle: AppTheme.tableCell
                    .copyWith(color: AppTheme.textSecondary),
                prefixIcon: const Icon(LucideIcons.search,
                    size: 14, color: AppTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryBlue, width: 1.5),
                ),
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                context.go(_buildUrl(
                  id: _detailIndex != null
                      ? _filteredRows[_detailIndex!.clamp(
                              0, _filteredRows.length - 1)]
                          .id
                      : null,
                  status: _selectedView != 'All' ? _selectedView : null,
                  q: v.isNotEmpty ? v : null,
                ));
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 32,
            height: 32,
            child: TextButton(
              onPressed: () =>
                  context.go(AppRoutes.purchaseReturnsCreate),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppTheme.accentGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Icon(LucideIcons.plus,
                  size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Full table (with horizontal scroll + resizable headers) ─────────────────

  Widget _buildFullTable(List<_PrListRow> rows) {
    final visibleCols = _visibleColumns;
    final tWidth = _tableWidth;
    return Scrollbar(
      controller: _hScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _hScrollController,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: SizedBox(
            width: tWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompositedTransformTarget(
                  link: _columnMenuLink,
                  child: _PrTableHeader(
                    columns: visibleCols,
                    colWidths: _colWidths,
                    columnMenuOpen: _columnMenuOpen,
                    onColumnMenuTap: () =>
                        setState(() => _columnMenuOpen = !_columnMenuOpen),
                    textMode: _textMode,
                    sortColumn: _sortColumn,
                    sortAscending: _sortAscending,
                    onColumnResize: _onColumnResize,
                    onSort: (colId) => setState(() {
                      if (_sortColumn == colId) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortColumn = colId;
                        _sortAscending = true;
                      }
                    }),
                    allSelected: _allSelected,
                    someSelected: _someSelected,
                    onSelectAll: _toggleSelectAll,
                    hasSelection: _selectedIndices.isNotEmpty,
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                if (rows.isEmpty)
                  Expanded(child: _buildEmpty())
                else
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: rows.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return _FullTableRow(
                          row: row,
                          fmt: _fmt,
                          columns: visibleCols,
                          colWidths: _colWidths,
                          textMode: _textMode,
                          checked: _selectedIndices.contains(index),
                          hasSelection: _selectedIndices.isNotEmpty,
                          onChanged: (v) => _toggleRow(index, v),
                          onTap: () {
                            setState(() => _detailIndex = index);
                            if (_detailScrollController.hasClients) {
                              _detailScrollController.jumpTo(0);
                            }
                            context.go(_buildUrl(
                              id: row.id,
                              status: _selectedView != 'All'
                                  ? _selectedView
                                  : null,
                              q: _searchQuery.isNotEmpty
                                  ? _searchQuery
                                  : null,
                            ));
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Split view ───────────────────────────────────────────────────────────────

  Widget _buildSplitView(List<_PrListRow> rows) {
    return Row(
      children: [
        _buildCompactList(rows),
        const VerticalDivider(width: 1, color: AppTheme.borderLight),
        Expanded(child: _buildDetailPanel(rows)),
      ],
    );
  }

  Widget _buildCompactList(List<_PrListRow> rows) {
    return Container(
      width: 460,
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: Row(
              children: [
                CompositedTransformTarget(
                  link: _filterDropdownLink,
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _dropdownOpen = !_dropdownOpen),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedView == 'All'
                              ? 'All Purchase Returns'
                              : '$_selectedView Returns',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _dropdownOpen
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 15,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: TextButton(
                    onPressed: () =>
                        context.go(AppRoutes.purchaseReturnsCreate),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppTheme.accentGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Icon(LucideIcons.plus,
                        size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.moreHorizontal,
                        size: 16, color: AppTheme.textSecondary),
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    onSelected: (val) {
                      if (val == 'customize') _openColumnCustomizer();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'customize',
                        child: Text('Customize Columns',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderLight),
              itemBuilder: (context, index) {
                final row = rows[index];
                return _CompactListItem(
                  row: row,
                  fmt: _fmt,
                  selected: index == _detailIndex,
                  checked: _selectedIndices.contains(index),
                  onCheckChanged: (v) => _toggleRow(index, v),
                  onTap: () {
                    setState(() => _detailIndex = index);
                    if (_detailScrollController.hasClients) {
                      _detailScrollController.jumpTo(0);
                    }
                    context.go(_buildUrl(
                      id: row.id,
                      status: _selectedView != 'All' ? _selectedView : null,
                      q: _searchQuery.isNotEmpty ? _searchQuery : null,
                    ));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(List<_PrListRow> rows) {
    final idx = _detailIndex!.clamp(0, rows.length - 1);
    if (idx >= rows.length) {
      return const Center(child: Text('Selection out of range'));
    }
    final row = rows[idx];
    final returnDetail = ref.watch(purchaseReturnDetailProvider(row.id));

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title header: PR number + status badge + icon buttons + close ──
          Container(
            height: 64,
            padding: const EdgeInsets.only(left: 20, right: 8),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
            ),
            child: Row(
              children: [
                Text(
                  returnDetail.returnNumber,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(returnDetail.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(returnDetail.status),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _statusColor(returnDetail.status)),
                  ),
                ),
                const Spacer(),
                _DetailIconBtn(icon: LucideIcons.paperclip, tooltip: 'Attachments', onTap: () {}),
                const SizedBox(width: 6),
                _DetailIconBtn(icon: LucideIcons.messageSquare, tooltip: 'Comments', onTap: () {}),
                Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 10), color: AppTheme.borderLight),
                GestureDetector(
                  onTap: () {
                    setState(() => _detailIndex = null);
                    context.go(_buildUrl(
                      status: _selectedView != 'All' ? _selectedView : null,
                      q: _searchQuery.isNotEmpty ? _searchQuery : null,
                    ));
                  },
                  child: const SizedBox(
                    width: 36, height: 36,
                    child: Icon(LucideIcons.x, size: 20, color: AppTheme.errorRed),
                  ),
                ),
              ],
            ),
          ),
          // ── Action bar ──
          Material(
            color: AppTheme.bgLight,
            child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
            ),
            child: Row(
              children: [
                _DetailActionBtn(
                  icon: LucideIcons.pencil,
                  label: 'Edit',
                  onTap: () => context.go('/purchases/purchase-returns/edit/${returnDetail.id}'),
                ),
                const _DetailActionDivider(),
                CompositedTransformTarget(
                  link: _pdfPrintLink,
                  child: _DetailActionBtn(
                    icon: LucideIcons.fileText,
                    label: 'PDF/Print',
                    trailingIcon: LucideIcons.chevronDown,
                    onTap: () => _showPdfPrintMenu(context),
                  ),
                ),
                const _DetailActionDivider(),
                if (returnDetail.status.toLowerCase() == 'draft') ...[
                  _DetailActionBtn(
                    icon: LucideIcons.checkCircle,
                    label: 'Confirm',
                    onTap: () {},
                  ),
                  const _DetailActionDivider(),
                ],

                _DetailMoreBtn(
                  onViewJournal: () {
                    final ctx = _prJournalKey.currentContext;
                    if (ctx != null) {
                      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    }
                  },
                  onDelete: () {
                    setState(() => _detailIndex = null);
                    context.go(_buildUrl(
                      status: _selectedView != 'All' ? _selectedView : null,
                      q: _searchQuery.isNotEmpty ? _searchQuery : null,
                    ));
                  },
                ),
              ],
            ),
            ),
          ),
          // ── Receive Batches — fixed tab, never scrolls away ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _buildReceiveBatchesSection(returnDetail),
          ),
          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              controller: _detailScrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_receiveBatchesExpanded && returnDetail.receiveHistory.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...returnDetail.receiveHistory.map((batch) => Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          children: [
                            const TextSpan(text: 'Receive Batch: '),
                            TextSpan(
                              text: batch.receiveNumber,
                              style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],
                  _PrPdfPreview(returnDetail: returnDetail),
                  const SizedBox(height: 24),
                  _PrJournalSection(key: _prJournalKey, returnDetail: returnDetail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveBatchesSection(PurchaseReturnDetailData returnDetail) {
    final count = returnDetail.receiveHistory.length;
    return GestureDetector(
      onTap: () => setState(() => _receiveBatchesExpanded = !_receiveBatchesExpanded),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Text(
              'Receive Batches',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(10)),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: _receiveBatchesExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.packageMinus,
              size: 40, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text('No purchase returns found',
              style: AppTheme.bodyText
                  .copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('Create your first return to get started.',
              style: AppTheme.tableCell
                  .copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ── Full table row ─────────────────────────────────────────────────────────────

class _FullTableRow extends StatefulWidget {
  final _PrListRow row;
  final NumberFormat fmt;
  final List<ColumnConfig> columns;
  final Map<String, double> colWidths;
  final String textMode;
  final bool checked;
  final bool hasSelection;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTap;

  const _FullTableRow({
    required this.row,
    required this.fmt,
    required this.columns,
    required this.colWidths,
    required this.textMode,
    required this.checked,
    required this.hasSelection,
    required this.onChanged,
    required this.onTap,
  });

  @override
  State<_FullTableRow> createState() => _FullTableRowState();
}

class _FullTableRowState extends State<_FullTableRow> {
  bool _hovered = false;

  String _cellValue(String colId) {
    final fmt = widget.fmt;
    switch (colId) {
      case 'date':
        return widget.row.date;
      case 'returnNumber':
        return widget.row.returnNumber;
      case 'vendorName':
        return widget.row.vendorName;
      case 'purchaseOrder':
        return widget.row.purchaseOrderNumber ?? '—';
      case 'status':
        return _statusLabel(widget.row.status);
      case 'amount':
        return '₹${fmt.format(widget.row.amount)}';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWrap = widget.textMode == 'wrap';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: isWrap
              ? const BoxConstraints(minHeight: 48)
              : null,
          height: isWrap ? null : 48,
          color: widget.checked
              ? AppTheme.primaryBlue.withValues(alpha: 0.07)
              : _hovered
              ? AppTheme.bgLight
              : Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isWrap ? 12 : 0,
          ),
          child: Row(
            crossAxisAlignment: isWrap
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (!widget.hasSelection) const SizedBox(width: 28),
              SizedBox(
                height: isWrap ? null : 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 32,
                    child: Checkbox(
                      value: widget.checked,
                      onChanged: widget.onChanged,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      activeColor: AppTheme.primaryBlue,
                      side: const BorderSide(
                          color: AppTheme.borderLight, width: 1.5),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
              ...widget.columns.map((col) {
                final width = widget.colWidths[col.id] ?? 120.0;
                final val = _cellValue(col.id);
                final isReturn = col.id == 'returnNumber';
                final isStatus = col.id == 'status';
                return SizedBox(
                  width: width,
                  child: isStatus
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            val,
                            maxLines: isWrap ? null : 1,
                            overflow:
                                isWrap ? null : TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _statusColor(widget.row.status),
                            ),
                          ),
                        )
                      : Text(
                          val,
                          maxLines: isWrap ? null : 1,
                          overflow:
                              isWrap ? null : TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isReturn
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isReturn
                                ? AppTheme.primaryBlueDark
                                : AppTheme.textPrimary,
                          ),
                        ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Compact list item ─────────────────────────────────────────────────────────

class _CompactListItem extends StatefulWidget {
  final _PrListRow row;
  final NumberFormat fmt;
  final bool selected;
  final bool checked;
  final ValueChanged<bool?> onCheckChanged;
  final VoidCallback onTap;

  const _CompactListItem({
    required this.row,
    required this.fmt,
    required this.selected,
    required this.checked,
    required this.onCheckChanged,
    required this.onTap,
  });

  @override
  State<_CompactListItem> createState() => _CompactListItemState();
}

class _CompactListItemState extends State<_CompactListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    if (widget.selected) {
      bgColor = AppTheme.primaryBlue.withValues(alpha: 0.08);
    } else if (_hovered) {
      bgColor = AppTheme.bgLight;
    } else {
      bgColor = Colors.white;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: bgColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: widget.checked,
                    onChanged: widget.onCheckChanged,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    activeColor: AppTheme.primaryBlue,
                    side: const BorderSide(
                        color: AppTheme.borderLight, width: 1.5),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.row.vendorName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: widget.selected
                                  ? AppTheme.primaryBlueDark
                                  : AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${widget.fmt.format(widget.row.amount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.row.returnNumber,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          widget.row.date,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(widget.row.status).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(widget.row.status),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Document preview (inline detail panel) ────────────────────────────────────

// ── PDF Preview (matches _VcPdfPreview style) ─────────────────────────────────

class _PrPdfPreview extends StatelessWidget {
  const _PrPdfPreview({required this.returnDetail});
  final PurchaseReturnDetailData returnDetail;

  static const Color _tableHeaderBg = Color(0xFF3D3D3D);
  static const Color _rowDivider = Color(0xFFE5E7EB);
  static const Color _outerBorder = Color(0xFFDDDDDD);

  static Color _ribbonColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.primaryBlue;
      case 'vendor_received':
        return AppTheme.successGreen;
      default:
        return const Color(0xFF5B6B7C);
    }
  }

  static String _ribbonLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return 'Confirmed';
      case 'vendor_received': return 'Received';
      default: return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateStr = DateFormat('dd-MM-yyyy').format(returnDetail.date);
    final isInterstate = returnDetail.sourceOfSupply != returnDetail.destinationOfSupply;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _outerBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo + company (left) / title + number (right) ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PdfOrgLogo(width: 200, height: 80),
                        const SizedBox(height: 16),
                        const Text('ZABNIX PRIVATE LIMITED',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                        const SizedBox(height: 4),
                        const Text('PERINTHALMANNA',
                            style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                        const Text('MALAPPURAM Kerala 679322',
                            style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                        const Text('India',
                            style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                        const SizedBox(height: 4),
                        const Text('GSTIN 32AACCZ4912F1ZL',
                            style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('PURCHASE RETURN',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF111111), letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Text('PR# ${returnDetail.returnNumber}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                      const SizedBox(height: 6),
                      Text('Balance: ₹${fmt.format(returnDetail.balance)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF444444))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // ── Vendor + meta ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vendor', style: TextStyle(fontSize: 13, color: Color(0xFF444444))),
                      const SizedBox(height: 4),
                      Text(returnDetail.vendorName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                      const SizedBox(height: 2),
                      ...returnDetail.vendorAddress.split('\n').map(
                        (l) => Text(l, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _metaRowPdf('Date', dateStr),
                      if (returnDetail.purchaseOrderNumber != null)
                        _metaRowPdf('PO#', returnDetail.purchaseOrderNumber!),
                      if (returnDetail.billNumber != null)
                        _metaRowPdf('Bill#', returnDetail.billNumber!),
                      _metaRowPdf('Source', returnDetail.sourceOfSupply),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ── Items table: dark header ──
              Container(
                color: _tableHeaderBg,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: const [
                    SizedBox(width: 32, child: Text('#', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
                    Expanded(child: Text('Item & Description',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
                    SizedBox(width: 70, child: Text('Qty', textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
                    SizedBox(width: 90, child: Text('Rate', textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
                    SizedBox(width: 100, child: Text('Amount', textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
                  ],
                ),
              ),
              // Item rows
              ...returnDetail.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Container(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _rowDivider))),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 32, child: Text('${idx + 1}', textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF444444)))),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontSize: 13, color: Color(0xFF111111))),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(item.description, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                            ],
                            if (item.reason != null) ...[
                              const SizedBox(height: 2),
                              Text('Reason: ${item.reason}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 70, child: Text('${item.returnQty.toStringAsFixed(0)} ${item.unit}',
                          textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Color(0xFF111111)))),
                      SizedBox(width: 90, child: Text(fmt.format(item.rate),
                          textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Color(0xFF111111)))),
                      SizedBox(width: 100, child: Text(fmt.format(item.amount),
                          textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Color(0xFF111111)))),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              // ── Totals (right-aligned) ──
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _pdfTotalRow('Sub Total', fmt.format(returnDetail.subtotal)),
                    const SizedBox(height: 4),
                    if (isInterstate)
                      _pdfTotalRow('IGST [18%]', fmt.format(returnDetail.taxAmount))
                    else ...[
                      _pdfTotalRow('CGST [9%]', fmt.format(returnDetail.taxAmount / 2)),
                      _pdfTotalRow('SGST [9%]', fmt.format(returnDetail.taxAmount / 2)),
                    ],
                    if (returnDetail.shipping > 0)
                      _pdfTotalRow('Shipping', fmt.format(returnDetail.shipping)),
                    const SizedBox(height: 8),
                    _pdfTotalRow('Total', '₹${fmt.format(returnDetail.total)}', bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        // ── Corner status ribbon ──
        Positioned(
          top: 0,
          left: 0,
          child: _PdfCornerRibbon(
            label: _ribbonLabel(returnDetail.status),
            color: _ribbonColor(returnDetail.status),
          ),
        ),
      ],
    );
  }

  Widget _metaRowPdf(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label : ', style: const TextStyle(fontSize: 12, color: Color(0xFF444444))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF111111))),
        ],
      ),
    );
  }

  Widget _pdfTotalRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: const Color(0xFF444444))),
        const SizedBox(width: 48),
        SizedBox(
          width: 90,
          child: Text(value, textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: const Color(0xFF111111))),
        ),
      ],
    );
  }
}

// ── Journal Section ───────────────────────────────────────────────────────────

class _PrJournalSection extends StatelessWidget {
  const _PrJournalSection({super.key, required this.returnDetail});
  final PurchaseReturnDetailData returnDetail;

  static const Color _colHeaderColor = Color(0xFF8A94A6);
  static const Color _dividerColor = Color(0xFFE5E7EB);

  List<_PrJournalEntry> _buildEntries() {
    return [
      _PrJournalEntry('Accounts Payable', returnDetail.total, 0),
      _PrJournalEntry('Purchase Returns & Allowances', 0, returnDetail.subtotal),
      if (returnDetail.taxAmount > 0)
        _PrJournalEntry('Input Tax Credit Reversal (GST)', 0, returnDetail.taxAmount),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final entries = _buildEntries();
    final totalDebit = entries.fold(0.0, (s, e) => s + e.debit);
    final totalCredit = entries.fold(0.0, (s, e) => s + e.credit);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
            child: Row(
              children: [
                const Icon(LucideIcons.bookOpen, size: 15, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                const Text('Journal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const Spacer(),
                Text(returnDetail.returnNumber, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          // Column headers
          Container(
            color: AppTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('Account',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _colHeaderColor))),
                SizedBox(width: 140, child: Text('Debit', textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _colHeaderColor))),
                SizedBox(width: 140, child: Text('Credit', textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _colHeaderColor))),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Rows
          ...entries.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _dividerColor))),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text(e.account, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
                SizedBox(width: 140, child: Text(e.debit > 0 ? fmt.format(e.debit) : '—',
                    textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
                SizedBox(width: 140, child: Text(e.credit > 0 ? fmt.format(e.credit) : '—',
                    textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
              ],
            ),
          )),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Totals
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(flex: 4, child: Text('Total',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                SizedBox(width: 140, child: Text(fmt.format(totalDebit), textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                SizedBox(width: 140, child: Text(fmt.format(totalCredit), textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrJournalEntry {
  final String account;
  final double debit;
  final double credit;
  const _PrJournalEntry(this.account, this.debit, this.credit);
}

// ── LEGACY: kept for reference, replaced by _PrPdfPreview ────────────────────

class _PrDocumentPreview extends StatelessWidget {
  final PurchaseReturnDetailData returnDetail;

  const _PrDocumentPreview({required this.returnDetail});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateStr =
        DateFormat('dd-MM-yyyy').format(returnDetail.date);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR COMPANY NAME',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Address Line 1\nCity, State PIN',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'PURCHASE RETURN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      returnDetail.returnNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),
          // Meta info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VENDOR',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        returnDetail.vendorName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _previewMetaRow('Date', dateStr),
                    if (returnDetail.purchaseOrderNumber != null)
                      _previewMetaRow(
                          'PO#', returnDetail.purchaseOrderNumber!),
                    _previewMetaRow(
                        'Warehouse', returnDetail.warehouseName),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items table header
          Container(
            color: const Color(0xFF374151),
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 8),
            child: Row(
              children: const [
                SizedBox(
                    width: 24,
                    child: Text('#',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white))),
                Expanded(
                  flex: 5,
                  child: Text('Item',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
                SizedBox(
                  width: 60,
                  child: Text('Qty',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('Rate',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('Amount',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ],
            ),
          ),

          // Item rows
          ...returnDetail.items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 9),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${idx + 1}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary)),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(item.name,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary)),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                        item.returnQty.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(fmt.format(item.rate),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(fmt.format(item.amount),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ),
                ],
              ),
            );
          }),

          // Totals
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _previewTotalRow(
                        'Sub Total', fmt.format(returnDetail.subtotal)),
                    _previewTotalRow(
                        'Tax', fmt.format(returnDetail.taxAmount)),
                    const Divider(
                        color: AppTheme.borderLight, height: 12),
                    _previewTotalRow(
                        'Total', fmt.format(returnDetail.total),
                        bold: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label : ',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _previewTotalRow(String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: bold ? 13 : 12,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400,
                color: bold
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              )),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 13 : 12,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w600,
                color: AppTheme.textPrimary,
              )),
        ],
      ),
    );
  }
}

// ── Table header with drag-resize handles ────────────────────────────────────

class _PrTableHeader extends StatefulWidget {
  const _PrTableHeader({
    required this.columns,
    required this.colWidths,
    required this.columnMenuOpen,
    required this.onColumnMenuTap,
    required this.textMode,
    required this.sortColumn,
    required this.sortAscending,
    required this.onColumnResize,
    required this.onSort,
    required this.allSelected,
    required this.someSelected,
    required this.onSelectAll,
    required this.hasSelection,
  });

  final List<ColumnConfig> columns;
  final Map<String, double> colWidths;
  final bool columnMenuOpen;
  final VoidCallback onColumnMenuTap;
  final String textMode;
  final String sortColumn;
  final bool sortAscending;
  final void Function(String id, double delta) onColumnResize;
  final ValueChanged<String> onSort;
  final bool allSelected;
  final bool someSelected;
  final ValueChanged<bool?> onSelectAll;
  final bool hasSelection;

  @override
  State<_PrTableHeader> createState() => _PrTableHeaderState();
}

class _PrTableHeaderState extends State<_PrTableHeader> {
  String? _hoveredCol;
  String? _draggingCol;

  @override
  Widget build(BuildContext context) {
    final isWrap = widget.textMode == 'wrap';
    return Container(
      height: isWrap ? null : 40,
      constraints: isWrap ? const BoxConstraints(minHeight: 40) : null,
      color: AppTheme.bgLight,
      padding: EdgeInsets.symmetric(
          horizontal: 16, vertical: isWrap ? 10 : 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.hasSelection)
              SizedBox(
                width: 28,
                child: GestureDetector(
                  onTap: widget.onColumnMenuTap,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      LucideIcons.slidersHorizontal,
                      size: 16,
                      color: widget.columnMenuOpen
                          ? AppTheme.primaryBlueDark
                          : AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 32,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Checkbox(
                  value: widget.allSelected || widget.someSelected,
                  tristate: false,
                  onChanged: (v) => widget
                      .onSelectAll(widget.allSelected ? false : true),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  activeColor: AppTheme.primaryBlue,
                  side: const BorderSide(
                      color: AppTheme.borderLight, width: 1.5),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            ...widget.columns.map((col) {
              final width = widget.colWidths[col.id] ?? 120.0;
              final isSorted = widget.sortColumn == col.id;
              final isHovered = _hoveredCol == col.id;
              final isDragging = _draggingCol == col.id;
              final showHandle = isHovered || isDragging;
              return SizedBox(
                width: width,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: () => widget.onSort(col.id),
                      child: Container(
                        padding: const EdgeInsets.only(right: 14),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                col.label.toUpperCase(),
                                maxLines: isWrap ? null : 1,
                                overflow: isWrap
                                    ? null
                                    : TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (isSorted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                widget.sortAscending
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                size: 12,
                                color: AppTheme.primaryBlue,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 12,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        onEnter: (_) =>
                            setState(() => _hoveredCol = col.id),
                        onExit: (_) => setState(() {
                          if (_hoveredCol == col.id)
                            _hoveredCol = null;
                        }),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragStart: (_) =>
                              setState(() => _draggingCol = col.id),
                          onHorizontalDragUpdate: (details) =>
                              widget.onColumnResize(
                                  col.id, details.delta.dx),
                          onHorizontalDragEnd: (_) =>
                              setState(() => _draggingCol = null),
                          child: Center(
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 120),
                              width: showHandle ? 3 : 1,
                              height: showHandle ? 24 : 16,
                              decoration: BoxDecoration(
                                color: isDragging
                                    ? AppTheme.primaryBlue
                                    : showHandle
                                        ? AppTheme.primaryBlue
                                            .withValues(alpha: 0.55)
                                        : AppTheme.borderLight,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Column menu option ─────────────────────────────────────────────────────────

class _PrColumnMenuOption extends StatefulWidget {
  const _PrColumnMenuOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PrColumnMenuOption> createState() => _PrColumnMenuOptionState();
}

class _PrColumnMenuOptionState extends State<_PrColumnMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final filled = _hovered;
    final foreground = filled
        ? AppTheme.backgroundColor
        : widget.selected
            ? AppTheme.primaryBlue
            : AppTheme.textPrimary;
    final iconColor = filled
        ? AppTheme.backgroundColor
        : AppTheme.primaryBlue;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 32,
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: filled
                ? AppTheme.primaryBlue.withValues(alpha: 0.9)
                : widget.selected
                    ? AppTheme.primaryBlue.withValues(alpha: 0.07)
                    : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: filled
                ? Border.all(
                    color: AppTheme.primaryBlueDark, width: 2)
                : widget.selected
                    ? Border.all(
                        color:
                            AppTheme.primaryBlue.withValues(alpha: 0.3))
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
                    fontWeight: widget.selected
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ),
              if (widget.selected)
                Icon(
                  LucideIcons.check,
                  size: 14,
                  color: filled
                      ? AppTheme.backgroundColor
                      : AppTheme.primaryBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helper widgets ───────────────────────────────────────────────────────

class _DetailIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _DetailIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _DetailActionBtn extends StatefulWidget {
  const _DetailActionBtn({
    required this.icon,
    required this.label,
    this.trailingIcon,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  @override
  State<_DetailActionBtn> createState() => _DetailActionBtnState();
}

class _DetailActionBtnState extends State<_DetailActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered ? AppTheme.borderLight : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 3),
                Icon(widget.trailingIcon, size: 12, color: AppTheme.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailActionDivider extends StatelessWidget {
  const _DetailActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppTheme.borderLight,
    );
  }
}

class _DetailMoreBtn extends StatelessWidget {
  const _DetailMoreBtn({
    required this.onViewJournal,
    required this.onDelete,
  });
  final VoidCallback onViewJournal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(4),
        shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.12)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.borderLight),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
        minimumSize: const WidgetStatePropertyAll(Size(180, 0)),
      ),
      builder: (ctx, ctrl, _) => InkWell(
        onTap: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
        hoverColor: AppTheme.bgLight,
        splashColor: Colors.transparent,
        highlightColor: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(LucideIcons.moreHorizontal, size: 15, color: AppTheme.textSecondary),
        ),
      ),
      menuChildren: [
        _PrMoreMenuItem(label: 'Refund', onTap: () {}),
        _PrMoreMenuItem(label: 'Void', onTap: () {}),
        _PrMoreMenuItem(label: 'Clone', onTap: () {}),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
        _PrMoreMenuItem(
          label: 'Delete',
          onTap: onDelete,
          color: AppTheme.errorRed,
        ),
      ],
    );
  }
}

class _PrMoreMenuItem extends StatefulWidget {
  const _PrMoreMenuItem({
    required this.label,
    required this.onTap,
    this.color,
  });
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  State<_PrMoreMenuItem> createState() => _PrMoreMenuItemState();
}

class _PrMoreMenuItemState extends State<_PrMoreMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = _hovered
        ? Colors.white
        : (widget.color ?? AppTheme.textPrimary);
    final bgColor = _hovered
        ? AppTheme.primaryBlue
        : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _hovered = false);
          widget.onTap();
        },
        child: Container(
          width: double.infinity,
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dropdown section header ───────────────────────────────────────────────────

class _PrDropdownSectionHeader extends StatelessWidget {
  const _PrDropdownSectionHeader({
    required this.label,
    required this.count,
    required this.countColor,
    required this.expanded,
  });

  final String label;
  final int count;
  final Color countColor;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: AppTheme.reportDropdownHeaderBg,
      child: Row(
        children: [
          Icon(
            expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
            size: 13,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: countColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.backgroundColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── View filter option row ────────────────────────────────────────────────────

class _PrViewFilterOption extends StatefulWidget {
  const _PrViewFilterOption({
    required this.label,
    required this.selected,
    required this.starred,
    required this.onTap,
    required this.onStarTap,
  });

  final String label;
  final bool selected;
  final bool starred;
  final VoidCallback onTap;
  final VoidCallback onStarTap;

  @override
  State<_PrViewFilterOption> createState() => _PrViewFilterOptionState();
}

// ── PDF/Print dropdown menu option ────────────────────────────────────────────

class _DownloadMenuOption extends StatefulWidget {
  const _DownloadMenuOption({required this.label, required this.onTap, this.icon});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<_DownloadMenuOption> createState() => _DownloadMenuOptionState();
}

class _DownloadMenuOptionState extends State<_DownloadMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: _hovered ? Colors.white : AppTheme.primaryBlue),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _hovered ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PrViewFilterOptionState extends State<_PrViewFilterOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppTheme.primaryBlue
                : _hovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        widget.selected ? FontWeight.w500 : FontWeight.w400,
                    color: widget.selected
                        ? AppTheme.backgroundColor
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onStarTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    widget.starred ? Icons.star : Icons.star_border,
                    size: 16,
                    color: widget.selected
                        ? AppTheme.backgroundColor.withValues(alpha: 0.85)
                        : widget.starred
                        ? AppTheme.warningOrange
                        : AppTheme.borderLight,
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


class _PdfOrgLogo extends ConsumerWidget {
  const _PdfOrgLogo({this.width = 160, this.height = 64});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = ref.watch(orgSettingsProvider).valueOrNull?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: const Text('LOGO',
            style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.8)),
      );
}

class _PdfCornerRibbon extends StatelessWidget {
  final String label;
  final Color color;

  const _PdfCornerRibbon({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    const double size = 110;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _CornerFoldPainter(color: color),
          ),
          Positioned(
            top: 29,
            left: -41,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 27,
            left: -43,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      HSLColor.fromColor(color)
                          .withLightness(
                            (HSLColor.fromColor(color).lightness * 0.85).clamp(
                              0.0,
                              1.0,
                            ),
                          )
                          .toColor(),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerFoldPainter extends CustomPainter {
  final Color color;
  _CornerFoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final darkColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness * 0.45).clamp(0.0, 1.0),
        )
        .toColor();

    final paint = Paint()..color = darkColor;

    final path = Path()
      ..moveTo(72, 0)
      ..lineTo(84, 0)
      ..lineTo(72, 12)
      ..close()
      ..moveTo(0, 72)
      ..lineTo(0, 84)
      ..lineTo(12, 72)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

