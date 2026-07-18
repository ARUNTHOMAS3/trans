import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/models/payment_record.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/providers/payment_recieves_provider.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/presentation/payment_recieved_skeleton.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

/// A single column definition carrying id, label, width, and visibility.
class _ColumnDef {
  final String id;
  final String label;
  double width;
  bool visible;
  final bool isLocked; // locked columns show a lock icon; cannot be toggled
  _ColumnDef({
    required this.id,
    required this.label,
    required this.width,
    required this.visible,
    this.isLocked = false,
  });
}

class PaymentRecievesReportPage extends ConsumerStatefulWidget {
  const PaymentRecievesReportPage({super.key});

  @override
  ConsumerState<PaymentRecievesReportPage> createState() => _PaymentRecievesReportPageState();
}

class _PaymentRecievesReportPageState extends ConsumerState<PaymentRecievesReportPage> {
  FavoriteFilterOption get _selectedFilter => ref.watch(paymentRecievesProvider).selectedFilter;
  String get _sortField => ref.watch(paymentRecievesProvider).sortField;
  bool get _sortAscending => ref.watch(paymentRecievesProvider).sortAscending;

  final LayerLink _moreMenuLayerLink = LayerLink();
  bool _isMoreMenuOpen = false;
  OverlayEntry? _moreMenuOverlayEntry;
  _SubMenuType _activeSubMenu = _SubMenuType.none;

  bool _isLoading = false;
  final ScrollController _horizontalScrollController = ScrollController();
  Map<String, double>? _customColumnWidths;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentRecievesProvider.notifier).loadPayments();
    });
    _loadColumnSettings();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _allSelected = false;
    });
    await ref.read(paymentRecievesProvider.notifier).refresh();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSort(String field, bool ascending) {
    ref.read(paymentRecievesProvider.notifier).sort(field, ascending);
  }



  void _showMoreMenu() {
    if (_moreMenuOverlayEntry != null) return;

    final overlay = Overlay.of(context);
    _moreMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMoreMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _moreMenuLayerLink,
              showWhenUnlinked: false,
              followerAnchor: Alignment.topRight,
              targetAnchor: Alignment.bottomRight,
              offset: const Offset(0, 8),
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: _MoreMenuDropdownContent(
                  onClose: _closeMoreMenu,
                  activeSubMenu: _activeSubMenu,
                  onSubMenuChanged: (type) {
                    setState(() {
                      _activeSubMenu = type;
                    });
                    _moreMenuOverlayEntry?.markNeedsBuild();
                  },
                  sortField: _sortField,
                  sortAscending: _sortAscending,
                  onSort: _onSort,
                  onRefresh: _refreshData,
                  onResetWidths: () {
                    _closeMoreMenu();
                    setState(() {
                      _customColumnWidths = null;
                      _showResizedBanner = false;
                    });
                    _saveColumnSettings();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_moreMenuOverlayEntry!);
    setState(() {
      _isMoreMenuOpen = true;
    });
  }

  void _closeMoreMenu() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    setState(() {
      _isMoreMenuOpen = false;
      _activeSubMenu = _SubMenuType.none;
    });
  }

  @override
  void dispose() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    super.dispose();
  }
  List<PaymentRecord> get _records => ref.watch(paymentRecievesProvider).records;

  bool _allSelected = false;
  bool _showTotalCount = false;
  int _currentPage = 1;
  int _rowsPerPage = 25;

  void _updateAllSelectedState() {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _records.length);
    if (startIndex >= endIndex) {
      _allSelected = false;
      return;
    }
    bool allPageSelected = true;
    for (int i = startIndex; i < endIndex; i++) {
      if (!_records[i].isSelected) {
        allPageSelected = false;
        break;
      }
    }
    _allSelected = allPageSelected;
  }

  int get _selectedCount => _records.where((r) => r.isSelected).length;

  bool _clipText = true;

  /// Ordered, sized, visible column definitions.
  final List<_ColumnDef> _columns = [
    _ColumnDef(id: 'status',    label: 'Status',           width: 100, visible: true),
    _ColumnDef(id: 'payment',   label: 'Payment#',         width: 110, visible: true),
    _ColumnDef(id: 'date',      label: 'Date',             width: 110, visible: true,  isLocked: true),
    _ColumnDef(id: 'reference', label: 'Reference#',       width: 160, visible: true),
    _ColumnDef(id: 'customer',  label: 'Customer Name',    width: 220, visible: true,  isLocked: true),
    _ColumnDef(id: 'invoice',   label: 'Invoice#',         width: 110, visible: true),
    _ColumnDef(id: 'mode',      label: 'Mode',             width: 110, visible: true,  isLocked: true),
    _ColumnDef(id: 'amount',    label: 'Amount',           width: 130, visible: true,  isLocked: true),
    _ColumnDef(id: 'unused',    label: 'Unused Amount',    width: 130, visible: true),
    _ColumnDef(id: 'location',  label: 'Warehouse',        width: 120, visible: true),
    _ColumnDef(id: 'paytype',   label: 'Payment Type',     width: 130, visible: false),
  ];

  bool _showResizedBanner = false;
  int? _hoveredRowIndex;
  bool _hoveringRowsPerPage = false;
  bool _hoveringPrevPage = false;
  bool _hoveringNextPage = false;

  Map<String, double> _calculateColumnWidths(double totalWidth) {
    const double staticPrefixWidth = 140.0;

    final Map<String, ({double min, double flex})> metrics = {
      'status': (min: 100.0, flex: 1.0),
      'payment': (min: 110.0, flex: 1.1),
      'date': (min: 110.0, flex: 1.1),
      'reference': (min: 120.0, flex: 1.2),
      'customer': (min: 180.0, flex: 1.8),
      'invoice': (min: 110.0, flex: 1.1),
      'mode': (min: 110.0, flex: 1.1),
      'amount': (min: 120.0, flex: 1.2),
      'unused': (min: 120.0, flex: 1.2),
      'location': (min: 120.0, flex: 1.2),
      'paytype': (min: 130.0, flex: 1.3),
    };

    double totalMinWidth = staticPrefixWidth;
    double totalFlex = 0;

    final visibleCols = _columns.where((c) => c.visible).toList();
    for (final col in visibleCols) {
      final colKey = col.id;
      final m = metrics[colKey] ?? (min: 120.0, flex: 1.0);
      totalMinWidth += m.min;
      totalFlex += m.flex;
    }

    final extraSpace = math.max(0.0, totalWidth - totalMinWidth);
    final results = <String, double>{};
    for (final col in visibleCols) {
      final colKey = col.id;
      final m = metrics[colKey] ?? (min: 120.0, flex: 1.0);
      results[colKey] = m.min + (m.flex / totalFlex) * extraSpace;
    }
    return results;
  }

  double _getMinColWidth(String key) {
    switch (key) {
      case 'status': return 80.0;
      case 'payment': return 100.0;
      case 'date': return 80.0;
      case 'reference': return 110.0;
      case 'customer': return 140.0;
      case 'invoice': return 100.0;
      case 'mode': return 80.0;
      case 'amount': return 90.0;
      case 'unused': return 140.0;
      case 'location': return 120.0;
      case 'paytype': return 130.0;
      default: return 80.0;
    }
  }

  void _resizeColumn(String key, double dx) {
    setState(() {
      if (_customColumnWidths == null) {
        _customColumnWidths = _calculateColumnWidths(
          context.size?.width ?? 1200,
        );
      }
      final current = _customColumnWidths![key] ?? 120.0;
      final minW = _getMinColWidth(key);
      _customColumnWidths![key] = (current + dx).clamp(minW, 1000.0);
    });
    _saveColumnSettings();
  }

  Future<void> _loadColumnSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final widthsJson = prefs.getString('payment_received_column_widths');
      if (widthsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(widthsJson);
        setState(() {
          _customColumnWidths = decoded.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading column settings: $e');
    }
  }

  Future<void> _saveColumnSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customColumnWidths == null) {
        await prefs.remove('payment_received_column_widths');
      } else {
        await prefs.setString(
          'payment_received_column_widths',
          jsonEncode(_customColumnWidths),
        );
      }
    } catch (e) {
      debugPrint('Error saving column settings: $e');
    }
  }

  TextAlign _columnAlign(String colId) {
    if (colId == 'status') return TextAlign.center;
    if (colId == 'amount' || colId == 'unused') return TextAlign.right;
    return TextAlign.left;
  }

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final formatted = intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '\u20B9$formatted.$decPart';
  }

  String _cellValue(_ColumnDef col, PaymentRecord r) {
    switch (col.id) {
      case 'status':    return r.status;
      case 'date':      return r.date;
      case 'payment':   return r.paymentNo;
      case 'reference': return r.reference;
      case 'customer':  return r.customer;
      case 'invoice':   return r.invoiceNo;
      case 'mode':      return r.mode;
      case 'amount':    return _fmt(r.amount);
      case 'unused':    return _fmt(r.unusedAmount);
      case 'location':  return r.location;
      default:          return '';
    }
  }

  bool _isLink(_ColumnDef col) => col.id == 'payment' || col.id == 'customer';



  void _showCustomizeColumnsDialog() {
    // Convert _ColumnDef list → ColumnConfig list for the shared dialog
    final configs = _columns.asMap().entries.map((e) => ColumnConfig(
      id: e.value.id,
      label: e.value.label,
      isVisible: e.value.visible,
      orderIndex: e.key,
      isLocked: e.value.isLocked,
    )).toList();

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => ColumnCustomizerDialog(
        columns: configs,
        onSave: (updated) {
          Navigator.of(ctx).pop();
          setState(() {
            // Apply visibility from updated ColumnConfig back to _ColumnDef
            for (final col in _columns) {
              final match = updated.firstWhere((u) => u.id == col.id, orElse: () => ColumnConfig(id: col.id, label: col.label, isVisible: col.visible, isLocked: col.isLocked));
              col.visible = match.isVisible;
            }
            // Reorder _columns to match the order from the dialog
            _columns.sort((a, b) {
              final ai = updated.indexWhere((u) => u.id == a.id);
              final bi = updated.indexWhere((u) => u.id == b.id);
              if (ai == -1 && bi == -1) return 0;
              if (ai == -1) return 1;
              if (bi == -1) return -1;
              return ai.compareTo(bi);
            });
          });
          ZerpaiToast.success(context, 'Custom View has been updated.');
        },
      ),
    );
  }


  bool _isSortable(String id) {
    return id == 'date';
  }

  Widget _buildSortIcon(String id) {
    final isSorted = _sortField == id;
    final isAsc = _sortAscending;
    const Color activeColor = Color(0xFF2563EB);
    const Color inactiveColor = Color(0xFF9CA3AF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _onSort(id, true),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Icon(
              Icons.arrow_upward_rounded,
              size: 14,
              color: isSorted && isAsc ? activeColor : inactiveColor,
            ),
          ),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: () => _onSort(id, false),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Icon(
              Icons.arrow_downward_rounded,
              size: 14,
              color: isSorted && !isAsc ? activeColor : inactiveColor,
            ),
          ),
        ),
      ],
    );
  }

  // ── Resizable column header cell (draggable reordering removed) ───────────
  Widget _buildHeader(
    _ColumnDef col,
    double width,
  ) {
    final align = _columnAlign(col.id);
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: align == TextAlign.center
              ? MainAxisAlignment.center
              : (align == TextAlign.right ? MainAxisAlignment.end : MainAxisAlignment.start),
          children: [
            Flexible(
              child: Text(
                col.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isSortable(col.id)) ...[
              const SizedBox(width: 4),
              _buildSortIcon(col.id),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleSelectAll(bool? val) {
    if (val == null) return;
    setState(() {
      _allSelected = val;
      final startIndex = (_currentPage - 1) * _rowsPerPage;
      final endIndex = (startIndex + _rowsPerPage).clamp(0, _records.length);
      ref.read(paymentRecievesProvider.notifier).toggleSelectAll(val, startIndex, endIndex);
    });
  }

  void _toggleRecordSelect(int absoluteIndex, bool? val) {
    if (val == null) return;
    setState(() {
      ref.read(paymentRecievesProvider.notifier).toggleRecordSelect(absoluteIndex, val);
      _updateAllSelectedState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _records.length);
    final paginatedRecords = _records.sublist(startIndex, endIndex);

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // ── Resized-columns save banner ────────────────
            if (_showResizedBanner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFEFF6FF),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You have resized the columns. Would you like to save the changes?',
                        style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setState(() => _showResizedBanner = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () => setState(() => _showResizedBanner = false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            // ── Ribbon replaces top bar when rows selected ─────────────
            if (_selectedCount > 0)
              _BulkActionRibbon(
                selectedCount: _selectedCount,
                onBulkUpdate: () {
                  showDialog(
                    context: context,
                    builder: (context) => _BulkUpdateDialog(
                      fields: const ['Payment Mode', 'Deposit To', 'Payment Date'],
                      onUpdate: (field, value) {
                        setState(() {
                          ref.read(paymentRecievesProvider.notifier).bulkUpdate(field, value);
                          _allSelected = false;
                          _updateAllSelectedState();
                        });
                        ZerpaiToast.success(context, 'Payments updated successfully');
                      },
                    ),
                  );
                },
                onDelete: () {
                  showDialog<bool>(
                    context: context,
                    builder: (context) => const _DeleteConfirmationDialog(),
                  ).then((confirmed) {
                    if (confirmed == true) {
                      setState(() {
                        ref.read(paymentRecievesProvider.notifier).deleteSelected();
                        _allSelected = false;
                        _currentPage = 1; // Reset to page 1
                        _updateAllSelectedState();
                      });
                      ZerpaiToast.deleted(context, 'Payment(s)');
                    }
                  });
                },
                onPdf: () {},
                onPrint: () {},
                onEmail: () {},
                onDismiss: () => setState(() {
                  _allSelected = false;
                  ref.read(paymentRecievesProvider.notifier).toggleSelectAll(false, 0, _records.length);
                }),
              )
            else
              // Normal Top Bar
              Container(
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: FavoriteFilterDropdown(
                        moduleName: 'payment_recieves',
                        options: const [
                          FavoriteFilterOption(
                            label: 'All Payments',
                            value: 'all_payments',
                          ),
                        ],
                        selectedOption: _selectedFilter,
                        onChanged: (opt) {
                          setState(() {
                            ref.read(paymentRecievesProvider.notifier).updateFilter(opt);
                          });
                        },
                      ),
                    ),
                    const Spacer(),
                    ZButton.primary(
                      onPressed: () {
                        final orgId = GoRouterState.of(context)
                            .pathParameters['orgSystemId'] ?? '6000000000';
                        context.go('/$orgId/sales/payments-received/create');
                      },
                      icon: LucideIcons.plus,
                      label: 'New',
                    ),
                    const SizedBox(width: 4),
                    CompositedTransformTarget(
                      link: _moreMenuLayerLink,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          border: Border.all(color: _isMoreMenuOpen ? const Color(0xFF2563EB) : AppTheme.borderLight),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (_isMoreMenuOpen) {
                              _closeMoreMenu();
                            } else {
                              _showMoreMenu();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            LucideIcons.moreHorizontal,
                            size: 16,
                            color: _isMoreMenuOpen ? const Color(0xFF2563EB) : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            // Table Header & Rows wrapped in scroll views for responsiveness
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final visibleCols = _columns.where((c) => c.visible).toList();
                  final columnWidths = _customColumnWidths ?? _calculateColumnWidths(constraints.maxWidth);
                  const double actualPrefixWidth = 102.0; // ZTableHeaderMenu placeholder/spacing
                  final double totalColumnsWidth = columnWidths.values.fold(
                    0.0,
                    (sum, w) => sum + w,
                  );
                  final screenWidth = math.max(
                    constraints.maxWidth,
                    totalColumnsWidth + actualPrefixWidth,
                  );

                  return Stack(
                    children: [
                      Scrollbar(
                        controller: _horizontalScrollController,
                        thumbVisibility: screenWidth > constraints.maxWidth,
                        trackVisibility: screenWidth > constraints.maxWidth,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: screenWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Table Header ─────────────────────────
                                Container(
                                  height: 36,
                                  color: const Color(0xFFF9FAFB),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 8),
                                      ZTableHeaderMenu(
                                        wrapText: !_clipText,
                                        onWrapChange: (v) => setState(() => _clipText = !v),
                                        onCustomize: _showCustomizeColumnsDialog,
                                      ),
                                      const SizedBox(width: 12),
                                      // Select-all checkbox
                                      SizedBox(
                                        width: 36,
                                        child: Checkbox(
                                          value: _allSelected,
                                          onChanged: _toggleSelectAll,
                                          activeColor: AppTheme.primaryBlue,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // ── Data columns (resizable) ──────
                                      ...visibleCols.map((col) {
                                        final w = columnWidths[col.id] ?? col.width;
                                        return _ResizableHeaderCell(
                                          width: w,
                                          onResize: (dx) => _resizeColumn(col.id, dx),
                                          child: _buildHeader(col, w),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                // ── Data Rows ──────────────────────────────────────
                                Expanded(
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: paginatedRecords.length,
                                    itemBuilder: (context, index) {
                                      final record = paginatedRecords[index];
                                      final isHovered = _hoveredRowIndex == index;
                                      return MouseRegion(
                                        onEnter: (_) => setState(() => _hoveredRowIndex = index),
                                        onExit: (_) => setState(() => _hoveredRowIndex = null),
                                        child: Container(
                                          height: _clipText ? 44 : null,
                                          constraints: _clipText ? null : const BoxConstraints(minHeight: 44),
                                          decoration: BoxDecoration(
                                            color: record.isSelected
                                                ? const Color(0xFFF8FAFF)
                                                : (isHovered ? const Color(0xFFF0F4FF) : Colors.white),
                                            border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                                          ),
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 8),
                                              const SizedBox(width: 28), // Placeholder to match ZTableHeaderMenu
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: 36,
                                                child: Checkbox(
                                                  value: record.isSelected,
                                                  onChanged: (v) => _toggleRecordSelect(startIndex + index, v),
                                                  activeColor: AppTheme.primaryBlue,
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () {
                                                    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
                                                    context.go('/$orgId/sales/payments-received/${record.paymentNo}');
                                                  },
                                                  child: Row(
                                                    children: [
                                                      ...visibleCols.map((col) {
                                                        final val = _cellValue(col, record);
                                                        final isLink = _isLink(col);
                                                        final isPayment = col.id == 'payment';
                                                        final w = columnWidths[col.id] ?? col.width;
                                                        final align = _columnAlign(col.id);

                                                        return SizedBox(
                                                          width: w,
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                                            child: Align(
                                                              alignment: align == TextAlign.center
                                                                  ? Alignment.center
                                                                  : (align == TextAlign.right
                                                                      ? Alignment.centerRight
                                                                      : Alignment.centerLeft),
                                                              child: isPayment
                                                                  ? Row(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        Text(
                                                                          val,
                                                                          style: const TextStyle(
                                                                            fontSize: 13,
                                                                            color: AppTheme.primaryBlue,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(width: 4),
                                                                        Icon(
                                                                          LucideIcons.copy,
                                                                          size: 12,
                                                                          color: AppTheme.textSecondary.withAlpha(150),
                                                                        ),
                                                                      ],
                                                                    )
                                                                  : Text(
                                                                      val,
                                                                      overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.visible,
                                                                      maxLines: _clipText ? 1 : null,
                                                                      softWrap: !_clipText,
                                                                      style: TextStyle(
                                                                        fontSize: 13,
                                                                        color: col.id == 'status'
                                                                            ? const Color(0xFF10B981)
                                                                            : (isLink ? AppTheme.primaryBlue : AppTheme.textPrimary),
                                                                        fontWeight: col.id == 'amount' || col.id == 'unused' || col.id == 'status'
                                                                            ? FontWeight.w500
                                                                            : FontWeight.normal,
                                                                      ),
                                                                    ),
                                                            ),
                                                          ),
                                                        );
                                                      }),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const Positioned.fill(
                          child: PaymentReportSkeleton(),
                        ),
                    ],
                  );
                },
              ),
            ),
            // ── Footer bar ────────────────────────────────────────────
            Container(
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Total Count: View
                  Text(
                    'Total Count: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showTotalCount = !_showTotalCount),
                    child: Text(
                      _showTotalCount ? '${_records.length}' : 'View',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Pagination
                  PopupMenuButton<int>(
                    tooltip: 'Rows per page',
                    offset: const Offset(0, -120),
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    onSelected: (val) {
                      setState(() {
                        _rowsPerPage = val;
                        _currentPage = 1;
                        _allSelected = false;
                        ref.read(paymentRecievesProvider.notifier).toggleSelectAll(false, 0, _records.length);
                      });
                    },
                    itemBuilder: (ctx) => [10, 25, 50, 100].map((val) => PopupMenuItem<int>(
                      value: val,
                      padding: EdgeInsets.zero,
                      height: 36,
                      child: _HoverPopupMenuItem(label: '$val per page'),
                    )).toList(),
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hoveringRowsPerPage = true),
                      onExit: (_) => setState(() => _hoveringRowsPerPage = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                          ),
                          color: _hoveringRowsPerPage ? const Color(0xFFEFF6FF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 13,
                              color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_rowsPerPage per page',
                              style: TextStyle(
                                fontSize: 12,
                                color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 14,
                              color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MouseRegion(
                          onEnter: (_) => setState(() => _hoveringPrevPage = true),
                          onExit: (_) => setState(() => _hoveringPrevPage = false),
                          cursor: _currentPage > 1 ? SystemMouseCursors.click : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: _currentPage > 1
                                ? () => setState(() {
                                      _currentPage--;
                                      _updateAllSelectedState();
                                    })
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _hoveringPrevPage && _currentPage > 1 ? const Color(0xFFEFF6FF) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                size: 16,
                                color: _currentPage > 1
                                    ? (_hoveringPrevPage ? const Color(0xFF2563EB) : const Color(0xFF374151))
                                    : const Color(0xFFD1D5DB),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _records.isEmpty ? '0 - 0' : '${startIndex + 1} - $endIndex',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                        ),
                        const SizedBox(width: 8),
                        MouseRegion(
                          onEnter: (_) => setState(() => _hoveringNextPage = true),
                          onExit: (_) => setState(() => _hoveringNextPage = false),
                          cursor: endIndex < _records.length ? SystemMouseCursors.click : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: endIndex < _records.length
                                ? () => setState(() {
                                      _currentPage++;
                                      _updateAllSelectedState();
                                    })
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _hoveringNextPage && endIndex < _records.length ? const Color(0xFFEFF6FF) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: endIndex < _records.length
                                    ? (_hoveringNextPage ? const Color(0xFF2563EB) : const Color(0xFF374151))
                                    : const Color(0xFFD1D5DB),
                              ),
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
      ),
    );
  }
}

// Filter dropdown content replaced by FavoriteFilterDropdown

// ─── Helper: plain menu row ────────────────────────────────────────────────
class _ColsMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ColsMenuItem({required this.icon, required this.label, required this.onTap});

  @override
  State<_ColsMenuItem> createState() => _ColsMenuItemState();
}

class _ColsMenuItemState extends State<_ColsMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hovered ? const Color(0xFF3B82F6) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: _hovered ? Colors.white : const Color(0xFF374151),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _hovered ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helper: toggle menu row ───────────────────────────────────────────────
class _ColsMenuToggleItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ColsMenuToggleItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ColsMenuToggleItem> createState() => _ColsMenuToggleItemState();
}

class _ColsMenuToggleItemState extends State<_ColsMenuToggleItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hovered ? const Color(0xFF3B82F6) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: _hovered ? Colors.white : const Color(0xFF374151),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: _hovered ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
              if (widget.value)
                Icon(
                  Icons.check,
                  size: 16,
                  color: _hovered ? Colors.white : const Color(0xFF2563EB),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool hasChevron;
  final bool isActive;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    this.hasChevron = false,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_MoreMenuItem> createState() => _MoreMenuItemState();
}

class _MoreMenuItemState extends State<_MoreMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _hovered || widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: isHighlighted ? const Color(0xFF3B82F6) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: isHighlighted ? Colors.white : const Color(0xFF374151),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHighlighted ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
              if (widget.hasChevron)
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: isHighlighted ? Colors.white : const Color(0xFF9CA3AF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SubMenuType { none, sortBy, import, export }

// ─── Helper: more menu dropdown content ─────────────────────────────────────
class _MoreMenuDropdownContent extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onResetWidths;
  final String sortField;
  final bool sortAscending;
  final void Function(String field, bool ascending) onSort;
  final VoidCallback onRefresh;
  final _SubMenuType activeSubMenu;
  final ValueChanged<_SubMenuType> onSubMenuChanged;

  const _MoreMenuDropdownContent({
    required this.onClose,
    required this.onResetWidths,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onRefresh,
    required this.activeSubMenu,
    required this.onSubMenuChanged,
  });

  @override
  State<_MoreMenuDropdownContent> createState() => _MoreMenuDropdownContentState();
}

class _MoreMenuDropdownContentState extends State<_MoreMenuDropdownContent> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.activeSubMenu != _SubMenuType.none) ...[
          _buildSubMenu(),
          const SizedBox(width: 4),
        ],
        _buildMainMenu(),
      ],
    );
  }

  Widget _buildMainMenu() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.sortBy),
            child: _MoreMenuItem(
              icon: Icons.swap_vert,
              label: 'Sort by',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.sortBy,
              onTap: () {},
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.import),
            child: _MoreMenuItem(
              icon: Icons.file_download_outlined,
              label: 'Import',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.import,
              onTap: () {},
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.export),
            child: _MoreMenuItem(
              icon: Icons.file_upload_outlined,
              label: 'Export',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.export,
              onTap: () {},
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.none),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MoreMenuItem(
                  icon: Icons.splitscreen_outlined,
                  label: 'Manage Custom Fields',
                  onTap: widget.onClose,
                ),
                _MoreMenuItem(
                  icon: Icons.computer_outlined,
                  label: 'Online Payments',
                  onTap: widget.onClose,
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MoreMenuItem(
                  icon: Icons.settings_backup_restore_outlined,
                  label: 'Reset Column Width',
                  onTap: widget.onResetWidths,
                ),
                _MoreMenuItem(
                  icon: Icons.refresh_outlined,
                  label: 'Refresh List',
                  onTap: () {
                    widget.onClose();
                    widget.onRefresh();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSubMenu() {
    switch (widget.activeSubMenu) {
      case _SubMenuType.sortBy:
        return _SubMenuPanel(
          children: [
            _buildSortItem('payment', 'Payment#'),
            _buildSortItem('date', 'Date'),
            _buildSortItem('reference', 'Reference#'),
            _buildSortItem('customer', 'Customer Name'),
            _buildSortItem('mode', 'Mode'),
            _buildSortItem('amount', 'Amount'),
            _buildSortItem('unused', 'Unused Amount'),
            _buildSortItem('created', 'Created Time'),
            _buildSortItem('modified', 'Last Modified Time'),
          ],
        );
      case _SubMenuType.import:
        return _SubMenuPanel(
          children: [
            _SubMenuItem(
              label: 'Import Payments',
              onTap: widget.onClose,
            ),
            _SubMenuItem(
              label: 'Import Retainer Payments',
              onTap: widget.onClose,
            ),
            _SubMenuItem(
              label: 'Import Applied Excess Payments',
              onTap: widget.onClose,
            ),
          ],
        );
      case _SubMenuType.export:
        return _SubMenuPanel(
          children: [
            _SubMenuItem(
              label: 'Export Payments',
              onTap: widget.onClose,
            ),
            _SubMenuItem(
              label: 'Export Current View',
              onTap: widget.onClose,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSortItem(String field, String label) {
    final isSelected = widget.sortField == field;
    IconData? icon;
    if (isSelected) {
      icon = widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward;
    } else if (field == 'date') {
      icon = Icons.arrow_downward;
    } else if (field == 'payment') {
      icon = Icons.arrow_upward;
    }

    return _SubMenuItem(
      label: label,
      rightIcon: icon,
      isSelected: isSelected,
      onTap: () {
        final asc = isSelected ? !widget.sortAscending : true;
        widget.onSort(field, asc);
        widget.onClose();
      },
    );
  }
}

// ─── Helper: submenu panel wrapper ──────────────────────────────────────────
class _SubMenuPanel extends StatelessWidget {
  final List<Widget> children;
  const _SubMenuPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Helper: submenu option row ─────────────────────────────────────────────
class _SubMenuItem extends StatefulWidget {
  final String label;
  final IconData? rightIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubMenuItem({
    required this.label,
    this.rightIcon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<_SubMenuItem> createState() => _SubMenuItemState();
}

class _SubMenuItemState extends State<_SubMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hovered ? const Color(0xFF3B82F6) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: _hovered
                        ? Colors.white
                        : (widget.isSelected
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF374151)),
                    fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (widget.rightIcon != null)
                Icon(
                  widget.rightIcon,
                  size: 14,
                  color: _hovered ? Colors.white : const Color(0xFF3B82F6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bulk Action Ribbon ───────────────────────────────────────────────────────
class _BulkActionRibbon extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onBulkUpdate;
  final VoidCallback onDelete;
  final VoidCallback onPdf;
  final VoidCallback onPrint;
  final VoidCallback onEmail;
  final VoidCallback onDismiss;

  const _BulkActionRibbon({
    required this.selectedCount,
    required this.onBulkUpdate,
    required this.onDelete,
    required this.onPdf,
    required this.onPrint,
    required this.onEmail,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          // ── Bulk Update ──────────────────────────────
          _RibbonTextButton(label: 'Bulk Update', onTap: onBulkUpdate),
          const SizedBox(width: 4),
          // ── Icon group: PDF, Print, Email ────────────
          _RibbonIconButton(icon: LucideIcons.fileText, tooltip: 'PDF', onTap: onPdf),
          _RibbonIconButton(icon: LucideIcons.printer, tooltip: 'Print', onTap: onPrint),
          _RibbonIconButton(icon: LucideIcons.mail, tooltip: 'Email', onTap: onEmail),
          const SizedBox(width: 4),
          // Divider
          Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 12),
          // ── Delete ───────────────────────────────────
          _RibbonTextButton(label: 'Delete', onTap: onDelete, isDestructive: true),
          const SizedBox(width: 16),
          // Divider
          Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 16),
          // ── Selected count badge ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            selectedCount == 1 ? 'Selected' : 'Selected',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // ── Esc × dismiss ────────────────────────────
          GestureDetector(
            onTap: onDismiss,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Esc',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RibbonTextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _RibbonTextButton({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_RibbonTextButton> createState() => _RibbonTextButtonState();
}

class _RibbonTextButtonState extends State<_RibbonTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFF3F4F6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.isDestructive
                  ? Colors.black
                  : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}

class _RibbonIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RibbonIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_RibbonIconButton> createState() => _RibbonIconButtonState();
}

class _RibbonIconButtonState extends State<_RibbonIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF3F4F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Tooltip(
            message: widget.tooltip,
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered ? const Color(0xFF374151) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkUpdateDialog extends StatefulWidget {
  final List<String> fields;
  final Function(String field, String value) onUpdate;

  const _BulkUpdateDialog({
    required this.fields,
    required this.onUpdate,
  });

  @override
  State<_BulkUpdateDialog> createState() => _BulkUpdateDialogState();
}

class _BulkUpdateDialogState extends State<_BulkUpdateDialog> {
  String? _selectedField;
  final TextEditingController _valController = TextEditingController();
  final GlobalKey _datePickerKey = GlobalKey();

  @override
  void dispose() {
    _valController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: DateTime.now(),
      targetKey: _datePickerKey,
    );
    if (picked != null) {
      final formatted = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      setState(() {
        _valController.text = formatted;
      });
    }
  }

  Widget _buildRightInput() {
    if (_selectedField == 'Payment Date') {
      return CustomTextField(
        key: _datePickerKey,
        controller: _valController,
        hintText: 'Select date',
        readOnly: true,
        height: 40,
        onTap: _selectDate,
        suffixWidget: const Icon(
          LucideIcons.calendar,
          size: 16,
          color: Color(0xFF9CA3AF),
        ),
      );
    } else if (_selectedField == 'Payment Mode') {
      final List<String> modes = ['Cash', 'Netbanking', 'Cheque', 'Bank Transfer', 'Card'];
      return FormDropdown<String>(
        value: modes.contains(_valController.text) ? _valController.text : null,
        items: modes,
        placeholder: 'Select a mode',
        height: 40,
        onChanged: (val) {
          setState(() {
            _valController.text = val ?? '';
          });
        },
      );
    } else if (_selectedField == 'Deposit To') {
      final List<String> displayLocations = [
        'Bandhan Bank',
        'COMPANY BANK ACCOUNT',
        'Zoho Payroll - Bank Account',
        'Petty Cash',
        'TESTINGS CASH',
        'TDS Payable',
        'GST Payable',
      ];
      return FormDropdown<String>(
        value: displayLocations.firstWhere(
          (loc) => loc.toUpperCase() == _valController.text.toUpperCase(),
          orElse: () => '',
        ).isNotEmpty ? displayLocations.firstWhere(
          (loc) => loc.toUpperCase() == _valController.text.toUpperCase()
        ) : null,
        items: displayLocations,
        placeholder: 'Select a location',
        height: 40,
        onChanged: (val) {
          setState(() {
            _valController.text = val ?? '';
          });
        },
        listBuilder: (items, itemBuilder) {
          final Map<String, List<String>> groups = {
            'Bank': ['Bandhan Bank', 'COMPANY BANK ACCOUNT', 'Zoho Payroll - Bank Account'],
            'Cash': ['Petty Cash', 'TESTINGS CASH'],
            'Other Current Liability': ['TDS Payable', 'GST Payable'],
          };
          final List<Widget> children = [];
          for (final entry in groups.entries) {
            final matching = entry.value.where((item) => items.contains(item)).toList();
            if (matching.isNotEmpty) {
              children.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              );
              for (final item in matching) {
                children.add(itemBuilder(item));
              }
            }
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        },
      );
    } else {
      return CustomTextField(
        controller: _valController,
        hintText: '',
        enabled: false,
        height: 40,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        width: 560,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bulk Update Payments Received',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            const Text(
              'Choose a field from the dropdown and update with new information.',
              style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FormDropdown<String>(
                    value: _selectedField,
                    items: widget.fields,
                    placeholder: 'Select a field',
                    onChanged: (val) {
                      setState(() {
                        _selectedField = val;
                        _valController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRightInput(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: All the selected customer payments will be updated with the new information and you cannot undo this action.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_selectedField == null ||
                        _valController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a field and enter a value.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    widget.onUpdate(
                      _selectedField!,
                      _valController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CB85C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(70, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    minimumSize: const Size(70, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFEAB308),
                      size: 26,
                    ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFEAB308),
                        size: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Are you sure about deleting the selected Payment(s)?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CB85C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(70, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    minimumSize: const Size(70, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverPopupMenuItem extends StatefulWidget {
  final String label;
  const _HoverPopupMenuItem({required this.label});

  @override
  State<_HoverPopupMenuItem> createState() => _HoverPopupMenuItemState();
}

class _HoverPopupMenuItemState extends State<_HoverPopupMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: _isHovered ? const Color(0xFF2563EB) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.centerLeft,
        width: double.infinity,
        height: 36,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            color: _isHovered ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class _ResizableHeaderCell extends StatefulWidget {
  final double width;
  final Widget child;
  final ValueChanged<double> onResize;

  const _ResizableHeaderCell({
    required this.width,
    required this.child,
    required this.onResize,
  });

  @override
  State<_ResizableHeaderCell> createState() => _ResizableHeaderCellState();
}

class _ResizableHeaderCellState extends State<_ResizableHeaderCell> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: SizedBox(
        width: widget.width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            Positioned(
              right: -5,
              top: 0,
              bottom: 0,
              width: 10,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) =>
                    widget.onResize(details.delta.dx),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(
                    color: _isHovering
                        ? AppTheme.primaryBlue.withAlpha(51)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
