import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/presentation/purchases_vendor_credits_overview.dart';

class VendorCreditsOverviewPage extends ConsumerStatefulWidget {
  final String? initialCreditNoteNumber;
  const VendorCreditsOverviewPage({super.key, this.initialCreditNoteNumber});

  @override
  ConsumerState<VendorCreditsOverviewPage> createState() =>
      _VendorCreditsOverviewPageState();
}

final _inFmt = NumberFormat('#,##,##0.00', 'en_IN');

// ── Skeleton Loader ──────────────────────────────────────────────────────────

// ignore: unused_element
class _VendorCreditsOverviewSkeleton extends StatelessWidget {
  const _VendorCreditsOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Panel Compact list skeleton
        SizedBox(
          width: 460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: const [
                    Skeleton(width: 140, height: 16),
                    Spacer(),
                    Skeleton(width: 70, height: 28),
                    SizedBox(width: 8),
                    Skeleton(width: 28, height: 28),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: 8,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppTheme.borderLight),
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Skeleton(width: 160, height: 13),
                        SizedBox(height: 6),
                        Skeleton(width: 110, height: 11),
                        SizedBox(height: 4),
                        Skeleton(width: 70, height: 11),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: AppTheme.borderLight),
        // Right Panel details skeleton
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: const [
                    Skeleton(width: 150, height: 18),
                    SizedBox(width: 12),
                    Skeleton(width: 70, height: 22, borderRadius: 12),
                    Spacer(),
                    Skeleton(width: 28, height: 28),
                    SizedBox(width: 8),
                    Skeleton(width: 28, height: 28),
                  ],
                ),
              ),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.bgLight,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: const [
                    Skeleton(width: 50, height: 14),
                    SizedBox(width: 20),
                    Skeleton(width: 60, height: 14),
                    SizedBox(width: 20),
                    Skeleton(width: 80, height: 14),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(width: 200, height: 20),
                      SizedBox(height: 8),
                      Skeleton(width: 140, height: 14),
                      SizedBox(height: 24),
                      Skeleton(height: 40),
                      SizedBox(height: 24),
                      Skeleton(height: 150),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Screen State ─────────────────────────────────────────────────────────────

class _VendorCreditsOverviewPageState
    extends ConsumerState<VendorCreditsOverviewPage> {
  static const _viewOptions = ['All', 'Draft', 'Open', 'Closed', 'Void'];

  Map<String, double> _colWidths = {
    'date': _VcColumnWidths.date,
    'creditNoteNumber': _VcColumnWidths.creditNoteNumber,
    'referenceNumber': _VcColumnWidths.referenceNumber,
    'vendorName': _VcColumnWidths.vendorName,
    'status': _VcColumnWidths.status,
    'amount': _VcColumnWidths.amount,
    'balance': _VcColumnWidths.balance,
  };

  void _onColumnResize(String id, double delta) {
    final current = _colWidths[id] ?? 120;
    final next = (current + delta).clamp(60.0, 600.0);
    if ((next - current).abs() < 0.5) return;
    setState(() => _colWidths = {..._colWidths, id: next});
  }

  String _selectedView = 'All';
  bool _dropdownOpen = false;
  bool _columnMenuOpen = false;
  bool _favoritesExpanded = true;
  bool _defaultFiltersExpanded = true;
  String _textMode = 'clip';
  String _sortColumn = 'creditNoteNumber';
  bool _sortAscending = true;
  final Set<String> _starredViews = {'Draft', 'Open'};
  List<ColumnConfig> _columns = _defaultColumns();
  int? _detailIndex;
  final _moreMenuKey = GlobalKey();
  final _columnSettingsKey = GlobalKey();
  final ScrollController _hScrollController = ScrollController();
  final LayerLink _filterDropdownLink = LayerLink();
  final LayerLink _pdfPrintLink = LayerLink();
  OverlayEntry? _pdfPrintOverlay;

  bool _tabExpanded = true;
  final ScrollController _detailScrollController = ScrollController();
  final GlobalKey _journalKey = GlobalKey();
  final Set<int> _selectedIndices = {};

  bool get _allSelected =>
      _filteredRows.isNotEmpty &&
      _selectedIndices.length == _filteredRows.length;
  bool get _someSelected =>
      _selectedIndices.isNotEmpty &&
      _selectedIndices.length < _filteredRows.length;

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

  final List<_VendorCreditRow> _rows = [
    const _VendorCreditRow(
      id: 'VC-00001',
      date: '20-04-2026',
      creditNoteNumber: 'VC-00001',
      referenceNumber: 'REF-2026-049',
      vendorName: 'ZERPAI TESTING',
      status: 'Open',
      amount: '₹4,838.00',
      balance: '₹4,838.00',
    ),
    const _VendorCreditRow(
      id: 'VC-00002',
      date: '22-04-2026',
      creditNoteNumber: 'VC-00002',
      referenceNumber: 'REF-2026-050',
      vendorName: 'ACME SUPPLIES',
      status: 'Closed',
      amount: '₹12,450.00',
      balance: '₹0.00',
    ),
    const _VendorCreditRow(
      id: 'VC-00003',
      date: '25-04-2026',
      creditNoteNumber: 'VC-00003',
      referenceNumber: 'REF-2026-051',
      vendorName: 'GLOBAL IMAGING',
      status: 'Void',
      amount: '₹2,300.00',
      balance: '₹0.00',
    ),
    const _VendorCreditRow(
      id: 'VC-00004',
      date: '28-04-2026',
      creditNoteNumber: 'VC-00004',
      referenceNumber: 'REF-2026-052',
      vendorName: 'TECH DISTRIBUTORS',
      status: 'Draft',
      amount: '₹9,800.00',
      balance: '₹9,800.00',
    ),
  ];

  static List<ColumnConfig> _defaultColumns() => [
    ColumnConfig(id: 'date', label: 'Date', orderIndex: 0, isLocked: true),
    ColumnConfig(
      id: 'creditNoteNumber',
      label: 'Credit Note#',
      orderIndex: 1,
      isLocked: true,
    ),
    ColumnConfig(
      id: 'referenceNumber',
      label: 'Reference Number',
      orderIndex: 2,
    ),
    ColumnConfig(id: 'vendorName', label: 'Vendor Name', orderIndex: 3),
    ColumnConfig(id: 'status', label: 'Status', orderIndex: 4),
    ColumnConfig(id: 'amount', label: 'Amount', orderIndex: 5),
    ColumnConfig(id: 'balance', label: 'Balance', orderIndex: 6),
  ];

  List<ColumnConfig> get _visibleColumns =>
      _columns
          .where((c) => c.isVisible)
          .map(
            (c) => ColumnConfig(
              id: c.id,
              label: c.label,
              isVisible: c.isVisible,
              orderIndex: c.orderIndex,
              isLocked: c.isLocked,
            ),
          )
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  double get _tableWidth {
    final colSum = _visibleColumns.fold(
      0.0,
      (sum, c) => sum + (_colWidths[c.id] ?? 120),
    );
    return colSum + 92; // 16(pad) + 28(icon) + 32(checkbox) + 16(pad)
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCreditNoteNumber != null) {
      final index = _rows.indexWhere(
        (r) => r.creditNoteNumber == widget.initialCreditNoteNumber,
      );
      if (index != -1) _detailIndex = index;
    }
  }

  @override
  void didUpdateWidget(VendorCreditsOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCreditNoteNumber != widget.initialCreditNoteNumber) {
      if (widget.initialCreditNoteNumber == null) {
        setState(() => _detailIndex = null);
      } else {
        final index = _rows.indexWhere(
          (r) => r.creditNoteNumber == widget.initialCreditNoteNumber,
        );
        if (index != -1) setState(() => _detailIndex = index);
      }
    }
  }

  @override
  void dispose() {
    _pdfPrintOverlay?.remove();
    _hScrollController.dispose();
    _detailScrollController.dispose();
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
                width: 140,
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
                      onTap: () => _closePdfPrintMenu(),
                    ),
                    _DownloadMenuOption(
                      icon: LucideIcons.printer,
                      label: 'Print',
                      onTap: () => _closePdfPrintMenu(),
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

  int _compare(_VendorCreditRow a, _VendorCreditRow b, String column) {
    switch (column) {
      case 'date':
        try {
          final partsA = a.date.split('-');
          final partsB = b.date.split('-');
          final dtA = DateTime(
            int.parse(partsA[2]),
            int.parse(partsA[1]),
            int.parse(partsA[0]),
          );
          final dtB = DateTime(
            int.parse(partsB[2]),
            int.parse(partsB[1]),
            int.parse(partsB[0]),
          );
          return dtA.compareTo(dtB);
        } catch (_) {
          return a.date.compareTo(b.date);
        }
      case 'creditNoteNumber':
        return a.creditNoteNumber.compareTo(b.creditNoteNumber);
      case 'referenceNumber':
        return a.referenceNumber.compareTo(b.referenceNumber);
      case 'vendorName':
        return a.vendorName.compareTo(b.vendorName);
      case 'status':
        return a.status.compareTo(b.status);
      case 'amount':
        final double amtA =
            double.tryParse(a.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        final double amtB =
            double.tryParse(b.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        return amtA.compareTo(amtB);
      case 'balance':
        final double balA =
            double.tryParse(a.balance.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0.0;
        final double balB =
            double.tryParse(b.balance.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0.0;
        return balA.compareTo(balB);
      default:
        return 0;
    }
  }

  List<_VendorCreditRow> get _filteredRows {
    final list = _selectedView == 'All'
        ? List<_VendorCreditRow>.from(_rows)
        : _rows
              .where(
                (r) => r.status.toLowerCase() == _selectedView.toLowerCase(),
              )
              .toList();
    list.sort((a, b) {
      final cmp = _compare(a, b, _sortColumn);
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  void _showMoreMenu(BuildContext context) {
    final box = _moreMenuKey.currentContext?.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;
    double menuTop = 65;
    double menuLeft = 8;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      menuTop = pos.dy + box.size.height + 4;
      menuLeft = (pos.dx + box.size.width - 200).clamp(0.0, screenWidth - 200);
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
            left: menuLeft,
            child: Material(
              color: Colors.transparent,
              child: _VcMoreMenu(
                sortColumn: _sortColumn,
                sortAscending: _sortAscending,
                onSortChanged: (col, asc) {
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _sortColumn = col;
                    _sortAscending = asc;
                  });
                },
                onExport: () => Navigator.of(dialogContext).pop(),
                onManageCustomFields: () {
                  Navigator.of(dialogContext).pop();
                  _openColumnCustomizer();
                },
                onRefreshList: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColumnMenu(BuildContext context) {
    final box =
        _columnSettingsKey.currentContext?.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;
    double menuTop = 148;
    double menuLeft = 14;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      menuTop = pos.dy + box.size.height + 4;
      menuLeft = pos.dx.clamp(8.0, screenWidth - 208);
    }
    setState(() => _columnMenuOpen = true);
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
              onTap: () {
                Navigator.of(dialogContext).pop();
                setState(() => _columnMenuOpen = false);
              },
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: menuTop,
            left: menuLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
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
                      selected: false,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        setState(() => _columnMenuOpen = false);
                        _openColumnCustomizer();
                      },
                    ),
                    _ColumnMenuOption(
                      label: _textMode == 'clip' ? 'Clip Text' : 'Wrap Text',
                      icon: _textMode == 'clip'
                          ? LucideIcons.minus
                          : LucideIcons.alignLeft,
                      selected: false,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        setState(() {
                          _textMode = _textMode == 'clip' ? 'wrap' : 'clip';
                          _columnMenuOpen = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      if (mounted && _columnMenuOpen) {
        setState(() => _columnMenuOpen = false);
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
              _columns = columns
                  .map(
                    (c) => ColumnConfig(
                      id: c.id,
                      label: c.label,
                      isVisible: c.isVisible,
                      orderIndex: c.orderIndex,
                      isLocked: c.isLocked,
                    ),
                  )
                  .toList();
            });
            Navigator.of(dialogContext, rootNavigator: true).pop();
          },
        ),
      );
    });
  }

  static Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return AppTheme.primaryBlue;
      case 'CLOSED':
        return AppTheme.successGreen;
      case 'VOID':
        return AppTheme.errorRed;
      case 'DRAFT':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleColumns = _visibleColumns;
    final tableWidth = _tableWidth;
    final filteredRows = _filteredRows;

    return ZerpaiLayout(
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
                Positioned.fill(
                  child: _buildSplitView(
                    visibleColumns,
                    tableWidth,
                    filteredRows,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildToolbar(context),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Expanded(
                      child: _buildFullTable(
                        visibleColumns,
                        tableWidth,
                        filteredRows,
                      ),
                    ),
                  ],
                ),
              // View dropdown overlay — anchored to the "All Vendor Credits" text
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
                                    () => _favoritesExpanded =
                                        !_favoritesExpanded,
                                  ),
                                  child: _DropdownSectionHeader(
                                    label: 'FAVORITES',
                                    count: _starredViews.length,
                                    countColor: AppTheme.primaryBlue,
                                    expanded: _favoritesExpanded,
                                  ),
                                ),
                                if (_favoritesExpanded &&
                                    _starredViews.isNotEmpty)
                                  ..._viewOptions
                                      .where(
                                        (opt) => _starredViews.contains(opt),
                                      )
                                      .map(
                                        (opt) => _ViewFilterOption(
                                          label: opt,
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
                                            context.go(AppRoutes.vendorCredits);
                                          },
                                        ),
                                      ),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _defaultFiltersExpanded =
                                        !_defaultFiltersExpanded,
                                  ),
                                  child: _DropdownSectionHeader(
                                    label: 'DEFAULT FILTERS',
                                    count: _viewOptions.length,
                                    countColor: AppTheme.accentGreen,
                                    expanded: _defaultFiltersExpanded,
                                  ),
                                ),
                                if (_defaultFiltersExpanded)
                                  ..._viewOptions.map(
                                    (opt) => _ViewFilterOption(
                                      label: opt,
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
                                        context.go(AppRoutes.vendorCredits);
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Full Table View ────────────────────────────────────────────────────────

  Widget _buildFullTable(
    List<ColumnConfig> visibleColumns,
    double tableWidth,
    List<_VendorCreditRow> rows,
  ) {
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
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TableHeader(
                  columns: visibleColumns,
                  colWidths: _colWidths,
                  columnMenuOpen: _columnMenuOpen,
                  onColumnMenuTap: () => _showColumnMenu(context),
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
                  columnSettingsKey: _columnSettingsKey,
                  allSelected: _allSelected,
                  someSelected: _someSelected,
                  onSelectAll: _toggleSelectAll,
                  hasSelection: _selectedIndices.isNotEmpty,
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(
                          child: Text(
                            'No Vendor Credits found',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppTheme.borderLight,
                          ),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return _TableRow(
                              row: row,
                              columns: visibleColumns,
                              colWidths: _colWidths,
                              textMode: _textMode,
                              onTap: () {
                                setState(() => _detailIndex = index);
                                if (_detailScrollController.hasClients) _detailScrollController.jumpTo(0);
                                context.go(
                                  '${AppRoutes.vendorCredits}?id=${row.creditNoteNumber}',
                                );
                              },
                              selected: _selectedIndices.contains(index),
                              onChanged: (v) => _toggleRow(index, v),
                              hasSelection: _selectedIndices.isNotEmpty,
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

  // ── Split View ─────────────────────────────────────────────────────────────

  Widget _buildSplitView(
    List<ColumnConfig> visibleColumns,
    double tableWidth,
    List<_VendorCreditRow> rows,
  ) {
    return Row(
      children: [
        _buildCompactList(rows),
        const VerticalDivider(width: 1, color: AppTheme.borderLight),
        Expanded(child: _buildDetailPanel(rows)),
      ],
    );
  }

  Widget _buildCompactList(List<_VendorCreditRow> rows) {
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
                bottom: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                CompositedTransformTarget(
                  link: _filterDropdownLink,
                  child: GestureDetector(
                    onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedView == 'All'
                              ? 'All Vendor Credits'
                              : '$_selectedView Credits',
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
                    onPressed: () => context.go(AppRoutes.vendorCreditsCreate),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppTheme.accentGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  key: _moreMenuKey,
                  width: 32,
                  height: 32,
                  child: TextButton(
                    onPressed: () => _showMoreMenu(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Icon(
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
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderLight),
              itemBuilder: (context, index) {
                final row = rows[index];
                return _VcCompactItem(
                  row: row,
                  selected: index == _detailIndex,
                  onTap: () {
                    setState(() => _detailIndex = index);
                    if (_detailScrollController.hasClients) _detailScrollController.jumpTo(0);
                    context.go(
                      '${AppRoutes.vendorCredits}?id=${row.creditNoteNumber}',
                    );
                  },
                  checked: _selectedIndices.contains(index),
                  onCheckChanged: (v) => _toggleRow(index, v),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(List<_VendorCreditRow> rows) {
    if (_detailIndex! >= rows.length) {
      return const Center(child: Text('Selection out of range'));
    }
    final rawRow = rows[_detailIndex!];
    final creditNote = ref.watch(
      vendorCreditDetailProvider(rawRow.creditNoteNumber),
    );

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title header: VC number + status badge + icon buttons + close ──
          Container(
            height: 64,
            padding: const EdgeInsets.only(left: 20, right: 8),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  creditNote.creditNoteNumber,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(
                      creditNote.status,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    creditNote.status[0].toUpperCase() +
                        creditNote.status.substring(1).toLowerCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _statusColor(creditNote.status),
                    ),
                  ),
                ),
                const Spacer(),
                _DetailHeaderIconButton(
                  icon: LucideIcons.paperclip,
                  onTap: () {},
                ),
                const SizedBox(width: 6),
                _DetailHeaderIconButton(
                  icon: LucideIcons.messageSquare,
                  onTap: () {},
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: AppTheme.borderLight,
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _detailIndex = null);
                    context.go(AppRoutes.vendorCredits);
                  },
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Action bar ──
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                _DetailActionBtn(
                  icon: LucideIcons.pencil,
                  label: 'Edit',
                  onTap: () => context.push(
                    '${AppRoutes.vendorCreditsCreate}?id=${creditNote.id}',
                  ),
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
                if (creditNote.status.toLowerCase() == 'open') ...[
                  _DetailActionBtn(
                    icon: LucideIcons.clipboardCheck,
                    label: 'Apply to Bills',
                    onTap: () => showDialog(
                      context: context,
                      useRootNavigator: false,
                      builder: (_) =>
                          ApplyToBillsDialog(creditNote: creditNote),
                    ),
                  ),
                  const _DetailActionDivider(),
                ],
                _DetailMoreBtn(
                  onRefund: () {},
                  onVoid: () {},
                  onClone: () {},
                  onViewJournal: () {
                    final ctx = _journalKey.currentContext;
                    if (ctx != null) {
                      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    }
                  },
                  onDelete: () {
                    setState(() {
                      _rows.removeWhere((r) => r.id == rawRow.id);
                      _detailIndex = null;
                    });
                    context.go(AppRoutes.vendorCredits);
                  },
                ),
              ],
            ),
          ),
          // Credit Applied Bills — fixed tab, never scrolls away
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _buildCreditAppliedSection(creditNote),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _detailScrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAssociatedBillRow(creditNote),
                  const SizedBox(height: 16),
                  _VcPdfPreview(creditNote: creditNote),
                  const SizedBox(height: 24),
                  _VcJournalSection(key: _journalKey, creditNote: creditNote),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _mockAppliedBill(String creditNoteId) {
    const map = {'VC-00001': 'B2B/25-26/07761', 'VC-00002': 'B2B/25-26/07892'};
    return map[creditNoteId];
  }

  Widget _buildCreditAppliedSection(VendorCreditDetail creditNote) {
    final appliedBill = _mockAppliedBill(creditNote.id);
    final count = appliedBill != null ? 1 : 0;

    return GestureDetector(
      onTap: () => setState(() => _tabExpanded = !_tabExpanded),
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
              'Credit Applied Bills',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: _tabExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociatedBillRow(VendorCreditDetail creditNote) {
    final bill = _mockAppliedBill(creditNote.id);
    if (bill == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          children: [
            const TextSpan(text: 'Associated Bill: '),
            TextSpan(
              text: bill,
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
          CompositedTransformTarget(
            link: _filterDropdownLink,
            child: GestureDetector(
              onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedView == 'All'
                        ? 'All Vendor Credits'
                        : '$_selectedView Vendor Credits',
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
          ZButton.primary(
            label: 'New',
            icon: LucideIcons.plus,
            onPressed: () => context.go(AppRoutes.vendorCreditsCreate),
          ),
          const SizedBox(width: 12),
          SizedBox(
            key: _columnSettingsKey,
            width: 36,
            height: 36,
            child: TextButton(
              onPressed: () => _showMoreMenu(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Icon(
                LucideIcons.moreHorizontal,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Column widths ────────────────────────────────────────────────────────────

class _VcColumnWidths {
  static const double date = 140;
  static const double creditNoteNumber = 160;
  static const double referenceNumber = 200;
  static const double vendorName = 200;
  static const double status = 140;
  static const double amount = 160;
  static const double balance = 160;
}

// ── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatefulWidget {
  const _TableHeader({
    required this.columns,
    required this.colWidths,
    required this.columnMenuOpen,
    required this.onColumnMenuTap,
    required this.textMode,
    required this.sortColumn,
    required this.sortAscending,
    required this.onColumnResize,
    required this.onSort,
    required this.columnSettingsKey,
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
  final GlobalKey columnSettingsKey;
  final bool allSelected;
  final bool someSelected;
  final ValueChanged<bool?> onSelectAll;
  final bool hasSelection;

  @override
  State<_TableHeader> createState() => _TableHeaderState();
}

class _TableHeaderState extends State<_TableHeader> {
  String? _hoveredCol;
  String? _draggingCol;

  @override
  Widget build(BuildContext context) {
    final isWrap = widget.textMode == 'wrap';
    return Container(
      height: isWrap ? null : 40,
      constraints: isWrap ? const BoxConstraints(minHeight: 40) : null,
      color: AppTheme.bgLight,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isWrap ? 10 : 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.hasSelection)
              SizedBox(
                key: widget.columnSettingsKey,
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
                  onChanged: (v) => widget.onSelectAll(widget.allSelected ? false : true),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
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
                                overflow: isWrap ? null : TextOverflow.ellipsis,
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
                    // Resize handle — visible on hover/drag
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 12,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        onEnter: (_) => setState(() => _hoveredCol = col.id),
                        onExit: (_) => setState(() {
                          if (_hoveredCol == col.id) _hoveredCol = null;
                        }),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragStart: (_) =>
                              setState(() => _draggingCol = col.id),
                          onHorizontalDragUpdate: (details) =>
                              widget.onColumnResize(col.id, details.delta.dx),
                          onHorizontalDragEnd: (_) =>
                              setState(() => _draggingCol = null),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: showHandle ? 3 : 1,
                              height: showHandle ? 24 : 16,
                              decoration: BoxDecoration(
                                color: isDragging
                                    ? AppTheme.primaryBlue
                                    : showHandle
                                        ? AppTheme.primaryBlue.withValues(alpha: 0.55)
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

// ── Table Row ────────────────────────────────────────────────────────────────

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.row,
    required this.columns,
    required this.colWidths,
    required this.textMode,
    required this.onTap,
    required this.selected,
    required this.onChanged,
    required this.hasSelection,
  });

  final _VendorCreditRow row;
  final List<ColumnConfig> columns;
  final Map<String, double> colWidths;
  final String textMode;
  final VoidCallback onTap;
  final bool selected;
  final ValueChanged<bool?> onChanged;
  final bool hasSelection;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isWrap = widget.textMode == 'wrap';
    final columns = widget.columns;
    final colWidths = widget.colWidths;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          height: isWrap ? null : 48,
          constraints: isWrap ? const BoxConstraints(minHeight: 48) : null,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isWrap ? 12 : 0,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppTheme.primaryBlue.withValues(alpha: 0.07)
                : _hovered
                ? AppTheme.bgLight
                : Colors.white,
          ),
          child: Row(
            children: [
              if (!widget.hasSelection) const SizedBox(width: 28),
              SizedBox(
                height: isWrap ? null : 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 32,
                    child: Checkbox(
                      value: widget.selected,
                      onChanged: widget.onChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: AppTheme.primaryBlue,
                      side: const BorderSide(
                        color: AppTheme.borderLight,
                        width: 1.5,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
              ...columns.map((col) {
                final width = colWidths[col.id] ?? 120.0;
                final val = _rowValue(col.id);
                final isColored = col.id == 'creditNoteNumber';
                final isStatus = col.id == 'status';
                return SizedBox(
                  width: width,
                  child: isStatus
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _VendorCreditsOverviewPageState._statusColor(
                                    val,
                                  ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              val,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color:
                                    _VendorCreditsOverviewPageState._statusColor(
                                      val,
                                    ),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          val,
                          maxLines: isWrap ? null : 1,
                          overflow: isWrap ? null : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isColored
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isColored
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

  String _rowValue(String colId) {
    final row = widget.row;
    switch (colId) {
      case 'date':
        return row.date;
      case 'creditNoteNumber':
        return row.creditNoteNumber;
      case 'referenceNumber':
        return row.referenceNumber;
      case 'vendorName':
        return row.vendorName;
      case 'status':
        return row.status;
      case 'amount':
        return row.amount;
      case 'balance':
        return row.balance;
      default:
        return '-';
    }
  }
}

// ── Compact List Item ────────────────────────────────────────────────────────

class _VcCompactItem extends StatefulWidget {
  const _VcCompactItem({
    required this.row,
    required this.selected,
    required this.onTap,
    required this.checked,
    required this.onCheckChanged,
  });

  final _VendorCreditRow row;
  final bool selected;
  final VoidCallback onTap;
  final bool checked;
  final ValueChanged<bool?> onCheckChanged;

  @override
  State<_VcCompactItem> createState() => _VcCompactItemState();
}

class _VcCompactItemState extends State<_VcCompactItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.08)
              : _hovered
              ? AppTheme.bgLight
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: widget.checked,
                      onChanged: widget.onCheckChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: AppTheme.primaryBlue,
                      side: const BorderSide(
                        color: AppTheme.borderLight,
                        width: 1.5,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.vendorName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppTheme.primaryBlueDark
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    row.amount,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${row.creditNoteNumber} • ${row.date}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                row.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _VendorCreditsOverviewPageState._statusColor(
                    row.status,
                  ),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail Views & Previews ──────────────────────────────────────────────────

class _VcDocumentPreview extends StatefulWidget {
  const _VcDocumentPreview({
    required this.creditNote,
    required this.orgSettings,
  });
  final VendorCreditDetail creditNote;
  final OrgSettings? orgSettings;

  @override
  State<_VcDocumentPreview> createState() => _VcDocumentPreviewState();
}

class _VcDocumentPreviewState extends State<_VcDocumentPreview> {
  bool _hovered = false;
  bool _menuOpen = false;

  static Color _ribbonColor(String status) {
    switch (status.toUpperCase()) {
      case 'CLOSED':
        return AppTheme.successGreen;
      case 'OPEN':
        return AppTheme.primaryBlue;
      case 'VOID':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final creditNote = widget.creditNote;
    final orgSettings = widget.orgSettings;
    final fmt = _inFmt;
    final dateStr = DateFormat('dd-MM-yyyy').format(creditNote.date);
    final orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'YOUR COMPANY NAME';

    // Parse paymentStubAddress JSON to extract state
    String? orgState;
    final rawAddr = orgSettings?.paymentStubAddress;
    if (rawAddr != null && rawAddr.trim().startsWith('{')) {
      try {
        final addrJson = jsonDecode(rawAddr) as Map<String, dynamic>;
        final state =
            addrJson['state_name']?.toString().trim() ??
            addrJson['state']?.toString().trim();
        if (state != null && state.isNotEmpty) orgState = state;
      } catch (_) {}
    }

    // GSTIN from companyIdValue (label expected to be GSTIN-like)
    final orgGstin = orgSettings?.companyIdValue?.trim().isNotEmpty == true
        ? orgSettings!.companyIdValue!.trim()
        : null;
    final orgGstinLabel = orgSettings?.companyIdLabel?.trim() ?? 'GSTIN';

    final isInterstate =
        creditNote.sourceOfSupply != creditNote.destinationOfSupply;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 80),
                            Text(
                              orgName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (orgState != null) _orgLine(orgState),
                            _orgLine('India'),
                            if (orgGstin != null)
                              _orgLine('$orgGstinLabel $orgGstin'),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 80),
                          const Text(
                            'VENDOR CREDITS',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'CreditNote# ${creditNote.creditNoteNumber}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Credits Remaining',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₹${fmt.format(creditNote.balance)}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 20),
                // Vendor info + meta
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vendor Address',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              creditNote.vendorName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlueDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              creditNote.billingAddress,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSubtle,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _metaRow('Credit Date', dateStr),
                          _metaRow('Reference#', creditNote.referenceNumber),
                          _metaRow(
                            'Source of Supply',
                            creditNote.sourceOfSupply,
                          ),
                          _metaRow(
                            'Destination',
                            creditNote.destinationOfSupply,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Items table
                _buildItemsTable(creditNote.items, fmt),
                // Totals
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
                  child: Row(
                    children: [
                      const Spacer(),
                      SizedBox(
                        width: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _totalRow(
                              'Sub Total',
                              fmt.format(creditNote.subtotal),
                            ),
                            if (isInterstate)
                              _totalRow(
                                'IGST [18%]',
                                fmt.format(creditNote.taxAmount),
                              )
                            else ...[
                              _totalRow(
                                'CGST [9%]',
                                fmt.format(creditNote.taxAmount / 2),
                              ),
                              _totalRow(
                                'SGST [9%]',
                                fmt.format(creditNote.taxAmount / 2),
                              ),
                            ],
                            const Divider(
                              color: AppTheme.borderLight,
                              height: 16,
                            ),
                            _totalRow(
                              'Total',
                              fmt.format(creditNote.total),
                              isGrandTotal: true,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.infoBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Credit Balance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.infoTextDark,
                                    ),
                                  ),
                                  Text(
                                    '₹${fmt.format(creditNote.balance)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.infoTextDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Authorized signature
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(
                        width: 200,
                        child: Divider(
                          color: AppTheme.textPrimary,
                          thickness: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Authorized Signature',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Journal section
                _buildJournalSection(creditNote, fmt, isInterstate),
              ],
            ),
          ),

          // ── Customize button (top-right inside card) ─────────────────────
          if (_hovered || _menuOpen)
            Positioned(
              top: 12,
              right: 12,
              child: _VcCustomizeMenu(
                onOpen: () => setState(() => _menuOpen = true),
                onClose: () => setState(() => _menuOpen = false),
              ),
            ),

          // ── Corner status ribbon ──────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            child: ClipRect(
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  children: [
                    Positioned(
                      top: 18,
                      left: -28,
                      child: Transform.rotate(
                        angle: -0.785,
                        child: Container(
                          width: 130,
                          height: 36,
                          color: _ribbonColor(creditNote.status),
                          alignment: Alignment.center,
                          child: Text(
                            creditNote.status[0].toUpperCase() +
                                creditNote.status.substring(1).toLowerCase(),
                            style: const TextStyle(
                              color: AppTheme.backgroundColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.none,
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
        ],
      ),
    );
  }

  Widget _buildJournalSection(
    VendorCreditDetail creditNote,
    NumberFormat fmt,
    bool isInterstate,
  ) {
    final halfTax = creditNote.taxAmount / 2;
    final entries = [
      _JournalEntry('Other Expenses', 0, creditNote.subtotal),
      _JournalEntry(
        'Accounts Payable (${creditNote.vendorName})',
        creditNote.total,
        0,
      ),
      if (isInterstate)
        _JournalEntry('Input IGST', 0, creditNote.taxAmount)
      else ...[
        _JournalEntry('Input SGST', 0, halfTax),
        _JournalEntry('Input CGST', 0, halfTax),
      ],
    ];
    final totalDebit = entries.fold(0.0, (s, e) => s + e.debit);
    final totalCredit = entries.fold(0.0, (s, e) => s + e.credit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: AppTheme.borderLight),
        // Tab header row
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 14, bottom: 10),
                    child: Text(
                      'Journal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(height: 2, width: 48, color: AppTheme.primaryBlue),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        // Currency notice
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 14, 32, 14),
          child: Row(
            children: [
              const Text(
                'Amount is displayed in your base currency',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'INR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Section heading
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
          child: Text(
            'Vendor Credits',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        // Table header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: const [
              Expanded(
                child: Text(
                  'ACCOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  'DEBIT',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  'CREDIT',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Divider(height: 12, color: AppTheme.borderLight),
        ),
        // Entry rows
        ...entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.account,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    fmt.format(e.debit),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    fmt.format(e.credit),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Totals row
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Divider(height: 12, color: AppTheme.borderLight),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 4, 32, 28),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 120,
                child: Text(
                  fmt.format(totalDebit),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  fmt.format(totalCredit),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orgLine(String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        color: AppTheme.textSecondary,
        height: 1.5,
      ),
    ),
  );

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<VendorCreditItem> items, NumberFormat fmt) {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
    return Column(
      children: [
        Container(
          color: const Color(0xFF374151),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          child: Row(
            children: const [
              SizedBox(width: 28, child: Text('#', style: headerStyle)),
              Expanded(
                flex: 5,
                child: Text('Item & Description', style: headerStyle),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Qty',
                  style: headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  'Rate',
                  style: headerStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'Tax',
                  style: headerStyle,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'Amount',
                  style: headerStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    item.quantity.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 12.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    fmt.format(item.rate),
                    style: const TextStyle(fontSize: 12.5),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    item.taxRate,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    fmt.format(item.amount),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool isGrandTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isGrandTotal ? 14 : 12.5,
              fontWeight: isGrandTotal ? FontWeight.w800 : FontWeight.w400,
              color: isGrandTotal
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isGrandTotal ? 14 : 12.5,
              fontWeight: isGrandTotal ? FontWeight.w800 : FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dropdown and Menus Local Components ──────────────────────────────────────

class _DropdownSectionHeader extends StatelessWidget {
  const _DropdownSectionHeader({
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

class _ViewFilterOption extends StatefulWidget {
  const _ViewFilterOption({
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
  State<_ViewFilterOption> createState() => _ViewFilterOptionState();
}

class _ViewFilterOptionState extends State<_ViewFilterOption> {
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
                : AppTheme.backgroundColor.withValues(alpha: 0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.selected
                        ? FontWeight.w500
                        : FontWeight.w400,
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

class _ColumnMenuOption extends StatefulWidget {
  const _ColumnMenuOption({
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
  State<_ColumnMenuOption> createState() => _ColumnMenuOptionState();
}

class _ColumnMenuOptionState extends State<_ColumnMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: _hovered ? AppTheme.bgLight : Colors.transparent,
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
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

class _VcMoreMenu extends StatelessWidget {
  const _VcMoreMenu({
    required this.sortColumn,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onExport,
    required this.onManageCustomFields,
    required this.onRefreshList,
  });

  final String sortColumn;
  final bool sortAscending;
  final void Function(String column, bool ascending) onSortChanged;
  final VoidCallback onExport;
  final VoidCallback onManageCustomFields;
  final VoidCallback onRefreshList;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _menuHeader('SORT BY'),
          _sortOption('Credit Note#', 'creditNoteNumber'),
          _sortOption('Date', 'date'),
          _sortOption('Amount', 'amount'),
          _sortOption('Balance', 'balance'),
          const Divider(height: 1, color: AppTheme.borderLight),
          _actionOption(
            'Export Vendor Credits',
            LucideIcons.download,
            onExport,
          ),
          _actionOption(
            'Customize Columns',
            LucideIcons.columns,
            onManageCustomFields,
          ),
          _actionOption('Refresh List', LucideIcons.refreshCw, onRefreshList),
        ],
      ),
    );
  }

  Widget _menuHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sortOption(String label, String column) {
    final active = sortColumn == column;
    return InkWell(
      onTap: () => onSortChanged(column, active ? !sortAscending : true),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? AppTheme.primaryBlueDark
                      : AppTheme.textPrimary,
                ),
              ),
            ),
            if (active)
              Icon(
                sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                size: 13,
                color: AppTheme.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionOption(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VcCustomizeMenu extends StatefulWidget {
  const _VcCustomizeMenu({required this.onOpen, required this.onClose});
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  State<_VcCustomizeMenu> createState() => _VcCustomizeMenuState();
}

class _VcCustomizeMenuState extends State<_VcCustomizeMenu> {
  static const _options = [
    'Spreadsheet Template',
    'Change Template',
    'Edit Template',
    'Update Logo & Address',
    'Manage Custom Fields',
    'Terms & Conditions',
  ];

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      onOpen: widget.onOpen,
      onClose: widget.onClose,
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsetsDirectional.symmetric(vertical: 4),
        ),
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        elevation: WidgetStatePropertyAll(4),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
      ),
      menuChildren: _options
          .map(
            (opt) => MenuItemButton(
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                minimumSize: const WidgetStatePropertyAll(Size(220, 36)),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered)
                      ? AppTheme.primaryBlue
                      : Colors.transparent,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered)
                      ? Colors.white
                      : AppTheme.textPrimary,
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ),
              onPressed: () {},
              child: Text(opt),
            ),
          )
          .toList(),
      builder: (ctx, ctrl, _) => GestureDetector(
        onTap: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.accentGreen,
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(LucideIcons.settings2, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Customize',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Icon(LucideIcons.chevronDown, size: 13, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

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
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
          ),
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

class _DetailActionBtn extends StatefulWidget {
  const _DetailActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingIcon,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData? trailingIcon;

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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
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
                Icon(widget.trailingIcon, size: 11, color: AppTheme.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeaderIconButton extends StatefulWidget {
  const _DetailHeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_DetailHeaderIconButton> createState() =>
      _DetailHeaderIconButtonState();
}

class _DetailHeaderIconButtonState extends State<_DetailHeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.05)
                : AppTheme.bgLight,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(widget.icon, size: 16, color: AppTheme.textSecondary),
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
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppTheme.borderLight,
    );
  }
}

class _DetailMoreBtn extends StatelessWidget {
  const _DetailMoreBtn({
    required this.onRefund,
    required this.onVoid,
    required this.onClone,
    required this.onViewJournal,
    required this.onDelete,
  });

  final VoidCallback onRefund;
  final VoidCallback onVoid;
  final VoidCallback onClone;
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
      builder: (ctx, ctrl, _) => GestureDetector(
        onTap: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: const Icon(
            LucideIcons.moreHorizontal,
            size: 16,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      menuChildren: [
        _MoreMenuItem(label: 'Refund', onTap: onRefund),
        _MoreMenuItem(label: 'Void', onTap: onVoid),
        _MoreMenuItem(label: 'Clone', onTap: onClone),
        _MoreMenuItem(label: 'View Journal', onTap: onViewJournal),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
        _MoreMenuItem(
          label: 'Delete',
          onTap: onDelete,
          color: AppTheme.errorRed,
        ),
      ],
    );
  }
}

class _MoreMenuItem extends StatefulWidget {
  const _MoreMenuItem({
    required this.label,
    required this.onTap,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  State<_MoreMenuItem> createState() => _MoreMenuItemState();
}

class _MoreMenuItemState extends State<_MoreMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDestructive = widget.color != null;
    final textColor = _hovered
        ? (isDestructive ? Colors.white : Colors.white)
        : (widget.color ?? AppTheme.textPrimary);
    final bgColor = _hovered
        ? (isDestructive ? AppTheme.errorRed : AppTheme.primaryBlue)
        : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
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

class _VendorCreditRow {
  const _VendorCreditRow({
    required this.id,
    required this.date,
    required this.creditNoteNumber,
    required this.referenceNumber,
    required this.vendorName,
    required this.status,
    required this.amount,
    required this.balance,
  });

  final String id;
  final String date;
  final String creditNoteNumber;
  final String referenceNumber;
  final String vendorName;
  final String status;
  final String amount;
  final String balance;
}

class _JournalEntry {
  const _JournalEntry(this.account, this.debit, this.credit);
  final String account;
  final double debit;
  final double credit;
}

// ── PDF Preview widget ────────────────────────────────────────────────────────

class _VcPdfPreview extends StatelessWidget {
  const _VcPdfPreview({required this.creditNote});
  final VendorCreditDetail creditNote;

  static const Color _tableHeaderBg = Color(0xFF3D3D3D);
  static const Color _rowDivider = Color(0xFFE5E7EB);
  static const Color _outerBorder = Color(0xFFDDDDDD);

  static Color _ribbonColor(String status) {
    switch (status.toUpperCase()) {
      case 'CLOSED':
        return AppTheme.successGreen;
      case 'OPEN':
        return AppTheme.primaryBlue;
      case 'VOID':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = _inFmt;
    final dateStr = DateFormat('dd-MM-yyyy').format(creditNote.date);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _outerBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top header: logo+company (left) / title+number (right) ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 200,
                          height: 80,
                          color: const Color(0xFF1A1A2E),
                          alignment: Alignment.center,
                          child: const Text(
                            'Logo',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ZABNIX PRIVATE LIMITED',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PERINTHALMANNA',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF444444),
                          ),
                        ),
                        const Text(
                          'MALAPPURAM Kerala 679322',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF444444),
                          ),
                        ),
                        const Text(
                          'India',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF444444),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'GSTIN 32AACCZ4912F1ZL',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'VENDOR CREDITS',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'VC# ${creditNote.creditNoteNumber}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Credits Remaining: ₹${fmt.format(creditNote.balance)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Vendor + meta ──────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vendor',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF444444),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        creditNote.vendorName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ...creditNote.billingAddress
                          .split('\n')
                          .map(
                            (l) => Text(
                              l,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _metaRowPdf('Date', dateStr),
                      if (creditNote.referenceNumber.isNotEmpty)
                        _metaRowPdf('Reference', creditNote.referenceNumber),
                      _metaRowPdf('Source', creditNote.sourceOfSupply),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Items table: dark header ───────────────────────────────
              Container(
                color: _tableHeaderBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '#',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Item & Description',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        'Qty',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        'Rate',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Amount',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Item rows
              ...creditNote.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _rowDivider)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${idx + 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111111),
                              ),
                            ),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          item.quantity.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          fmt.format(item.rate),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          fmt.format(item.amount),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // ── Totals (right-aligned) ────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _pdfTotalRow('Sub Total', fmt.format(creditNote.subtotal)),
                    const SizedBox(height: 8),
                    _pdfTotalRow(
                      'Total',
                      '₹${fmt.format(creditNote.total)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),

        // ── Corner status ribbon ──────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          child: ClipRect(
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                children: [
                  Positioned(
                    top: 18,
                    left: -28,
                    child: Transform.rotate(
                      angle: -0.785,
                      child: Container(
                        width: 130,
                        height: 36,
                        color: _ribbonColor(creditNote.status),
                        alignment: Alignment.center,
                        child: Text(
                          creditNote.status[0].toUpperCase() +
                              creditNote.status.substring(1).toLowerCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
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
      ],
    );
  }

  Widget _metaRowPdf(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pdfTotalRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(width: 48),
        SizedBox(
          width: 90,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: const Color(0xFF111111),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Journal Section ───────────────────────────────────────────────────────────

class _VcJournalSection extends StatelessWidget {
  // ignore: unused_element
  const _VcJournalSection({super.key, required this.creditNote});
  final VendorCreditDetail creditNote;

  static const Color _colHeaderColor = Color(0xFF8A94A6);
  static const Color _dividerColor = Color(0xFFE5E7EB);

  List<_JournalEntry> _buildEntries() {
    final subtotal = creditNote.subtotal;
    final tax = creditNote.taxAmount;
    final total = creditNote.total;
    return [
      _JournalEntry('Inventory Asset', 0, subtotal),
      _JournalEntry('Cost of Goods Sold', subtotal, 0),
      _JournalEntry('Cost of Goods Sold', 0, tax),
      _JournalEntry('Accounts Payable', total, 0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fmt = _inFmt;
    final entries = _buildEntries();
    final totalDebit = entries.fold(0.0, (s, e) => s + e.debit);
    final totalCredit = entries.fold(0.0, (s, e) => s + e.credit);
    const orgName = 'ZABNIX PRIVATE LIMITED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Tab header ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _dividerColor)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Journal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Currency info ──────────────────────────────────────
                Row(
                  children: [
                    const Text(
                      'Amount is displayed in your base currency',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'INR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Section title ──────────────────────────────────────
                const Text(
                  'Inventory Valuation for Vendor Credits',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Column headers ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'ACCOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _colHeaderColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'LOCATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _colHeaderColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          'DEBIT',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _colHeaderColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          'CREDIT',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _colHeaderColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: _dividerColor),

                // ── Entry rows ─────────────────────────────────────────
                ...entries.map(
                  (e) => Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: _dividerColor, width: 0.5)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            e.account,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            orgName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            fmt.format(e.debit),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            fmt.format(e.credit),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Totals row ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Spacer(),
                      SizedBox(
                        width: 80,
                        child: Text(
                          fmt.format(totalDebit),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          fmt.format(totalCredit),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
