import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as import_web;
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/responsive/responsive_table_shell.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_record.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expenses_list_query.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/dialogs/expenses_bulk_update_dialog.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/dialogs/expenses_export_current_view_dialog.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/dialogs/expenses_export_dialog.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/expenses_filter_dropdown_widget.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/expense_mileage_indicator_widget.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/widgets/expenses_more_menu_widgets.dart';
import 'package:zerpai_erp/modules/purchases/expenses/providers/expenses_provider.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';

class _ColumnDef {
  final String id;
  final String label;
  double width;
  bool visible;
  final bool isLocked;
  _ColumnDef({
    required this.id,
    required this.label,
    required this.width,
    required this.visible,
    this.isLocked = false,
  });
}

class ExpensesReportPage extends ConsumerStatefulWidget {
  const ExpensesReportPage({super.key});

  @override
  ConsumerState<ExpensesReportPage> createState() => _ExpensesReportPageState();
}

class _ExpensesReportPageState extends ConsumerState<ExpensesReportPage> {
  static const List<FavoriteFilterOption> _filterOptions = [
    FavoriteFilterOption(label: 'All', value: 'all'),
    FavoriteFilterOption(label: 'Unbilled', value: 'unbilled'),
    FavoriteFilterOption(label: 'Invoiced', value: 'invoiced'),
    FavoriteFilterOption(label: 'Reimbursed', value: 'reimbursed'),
    FavoriteFilterOption(label: 'Billable', value: 'billable'),
    FavoriteFilterOption(label: 'Non-Billable', value: 'non_billable'),
    FavoriteFilterOption(label: 'With Receipts', value: 'with_receipts'),
    FavoriteFilterOption(label: 'Without Receipts', value: 'without_receipts'),
  ];
  static const double _paginationFooterHeight = 76;
  static const double _moreMenuWidth = 220;
  static const double _moreSubMenuWidth = 200;
  static const double _moreMenuGap = 4;
  static const double _moreMenuLeftOffset = -182;
  static const double _moreMenuLeftOpenOffset =
      _moreMenuLeftOffset - _moreSubMenuWidth - _moreMenuGap;

  late FavoriteFilterOption _selectedFilter = _filterOptions[0];

  String get _sortField => ref.watch(expensesProvider).sortField;
  bool get _sortAscending => ref.watch(expensesProvider).sortAscending;

  final LayerLink _moreMenuLayerLink = LayerLink();
  final GlobalKey _moreMenuAnchorKey = GlobalKey();
  bool _isMoreMenuOpen = false;
  OverlayEntry? _moreMenuOverlayEntry;
  _SubMenuType _activeSubMenu = _SubMenuType.none;

  final LayerLink _uploadLayerLink = LayerLink();
  bool _isUploadMenuOpen = false;
  OverlayEntry? _uploadMenuOverlayEntry;

  bool _isLoading = false;

  void _showExportExpensesDialog() {
    showExpensesExportDialog(context, rows: _records);
  }

  List<ExpenseRecord> get _currentPageRecords => _records;

  void _openExportCurrentViewDialog() {
    final visibleColumns = _columns
        .where((column) => column.visible)
        .map(
          (column) => ExpensesCurrentViewExportColumn(
            label: column.label,
            valueBuilder: (row) => _cellValue(column, row),
          ),
        )
        .toList(growable: false);
    showExpensesExportCurrentViewDialog(
      context,
      rows: _currentPageRecords,
      columns: visibleColumns,
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _allSelected = false;
    });
    await ref.read(expensesProvider.notifier).fetchExpenses(_buildListQuery());
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onSort(String field, bool ascending) async {
    setState(() {
      _currentPage = 1;
      _allSelected = false;
    });
    await ref.read(expensesProvider.notifier).sort(field, ascending);
    if (!mounted) return;
    setState(_updateAllSelectedState);
  }

  Future<void> _changePage(int nextPage) async {
    if (nextPage < 1) return;
    setState(() {
      _currentPage = nextPage;
      _allSelected = false;
    });
    await ref.read(expensesProvider.notifier).setPage(nextPage);
    if (!mounted) return;
    setState(_updateAllSelectedState);
  }

  Future<void> _changePageSize(int nextPageSize) async {
    if (_rowsPerPage == nextPageSize) return;
    setState(() {
      _rowsPerPage = nextPageSize;
      _currentPage = 1;
      _allSelected = false;
    });
    await ref.read(expensesProvider.notifier).setPageSize(nextPageSize);
    if (!mounted) return;
    setState(_updateAllSelectedState);
  }

  void _showMoreMenu() {
    if (_moreMenuOverlayEntry != null) return;

    final overlay = Overlay.of(context);
    _moreMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        final hasRenderableSubMenu =
            _activeSubMenu == _SubMenuType.sortBy ||
            _activeSubMenu == _SubMenuType.export;
        final openSubMenuOnRight = _shouldOpenMoreSubMenuOnRight();
        final horizontalOffset = hasRenderableSubMenu && !openSubMenuOnRight
            ? _moreMenuLeftOpenOffset
            : _moreMenuLeftOffset;
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
              followerAnchor: Alignment.topLeft,
              targetAnchor: Alignment.bottomLeft,
              offset: Offset(horizontalOffset, 8),
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: _MoreMenuDropdownContent(
                  onClose: _closeMoreMenu,
                  activeSubMenu: _activeSubMenu,
                  openSubMenuOnRight: openSubMenuOnRight,
                  onSubMenuChanged: (type) {
                    if (_activeSubMenu == type) return;
                    _activeSubMenu = type;
                    _moreMenuOverlayEntry?.markNeedsBuild();
                  },
                  sortField: _sortField,
                  sortAscending: _sortAscending,
                  onSort: (field, ascending) {
                    unawaited(_onSort(field, ascending));
                  },
                  onRefresh: _refreshData,
                  onImport: _pickUploadExpenseFile,
                  onExportExpenses: _showExportExpensesDialog,
                  onExportCurrentView: _openExportCurrentViewDialog,
                  onResetWidths: () {
                    _closeMoreMenu();
                    setState(() {
                      for (var col in _columns) {
                        if (col.id == 'date') col.width = 110;
                        if (col.id == 'expenseAccount') col.width = 180;
                        if (col.id == 'reference') col.width = 160;
                        if (col.id == 'vendorName') col.width = 160;
                        if (col.id == 'paidThrough') col.width = 150;
                        if (col.id == 'customerName') col.width = 160;
                        if (col.id == 'status') col.width = 130;
                        if (col.id == 'amount') col.width = 130;
                      }
                      _showResizedBanner = false;
                    });
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

  bool _shouldOpenMoreSubMenuOnRight() {
    final anchorContext = _moreMenuAnchorKey.currentContext;
    if (anchorContext == null) return true;
    final renderBox = anchorContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return true;

    final anchorTopLeft = renderBox.localToGlobal(Offset.zero);
    final parentMenuLeft = anchorTopLeft.dx + _moreMenuLeftOffset;
    final parentMenuRight = parentMenuLeft + _moreMenuWidth;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final availableRightSpace = viewportWidth - parentMenuRight;

    return availableRightSpace >= (_moreSubMenuWidth + _moreMenuGap);
  }

  void _closeMoreMenu() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    setState(() {
      _isMoreMenuOpen = false;
      _activeSubMenu = _SubMenuType.none;
    });
  }

  void _toggleUploadMenu() {
    if (_uploadMenuOverlayEntry != null) {
      _closeUploadMenu();
    } else {
      _showUploadMenu();
    }
  }

  void _showUploadMenu() {
    if (_uploadMenuOverlayEntry != null) return;
    final overlay = Overlay.of(context);
    _uploadMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeUploadMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _uploadLayerLink,
              showWhenUnlinked: false,
              followerAnchor: Alignment.topRight,
              targetAnchor: Alignment.bottomRight,
              offset: const Offset(0, 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(6),
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      _UploadMenuItem(
                        label: 'Attach From Desktop',
                        onTap: () {
                          _closeUploadMenu();
                          _pickUploadExpenseFile();
                        },
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_uploadMenuOverlayEntry!);
    setState(() {
      _isUploadMenuOpen = true;
    });
  }

  void _closeUploadMenu() {
    _uploadMenuOverlayEntry?.remove();
    _uploadMenuOverlayEntry = null;
    setState(() {
      _isUploadMenuOpen = false;
    });
  }

  Future<void> _pickUploadExpenseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (mounted) {
          ZerpaiToast.success(context, 'Expense attached: ${file.name}');
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error selecting file: $e');
      }
    }
  }

  @override
  void dispose() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    _uploadMenuOverlayEntry?.remove();
    _uploadMenuOverlayEntry = null;
    super.dispose();
  }

  final List<_ColumnDef> _columns = [
    _ColumnDef(
      id: 'date',
      label: 'Date',
      width: 110,
      visible: true,
      isLocked: true,
    ),
    _ColumnDef(
      id: 'expenseAccount',
      label: 'Expense Account',
      width: 180,
      visible: true,
      isLocked: true,
    ),
    _ColumnDef(id: 'reference', label: 'Reference#', width: 160, visible: true),
    _ColumnDef(
      id: 'vendorName',
      label: 'Vendor Name',
      width: 160,
      visible: true,
    ),
    _ColumnDef(
      id: 'paidThrough',
      label: 'Paid Through',
      width: 150,
      visible: true,
    ),
    _ColumnDef(
      id: 'customerName',
      label: 'Customer Name',
      width: 160,
      visible: true,
    ),
    _ColumnDef(id: 'status', label: 'Status', width: 130, visible: true),
    _ColumnDef(
      id: 'amount',
      label: 'Amount',
      width: 130,
      visible: true,
      isLocked: true,
    ),
  ];

  static const double _amountAttachmentSlotWidth = 16;

  List<ExpenseRecord> get _records => ref.watch(expensesProvider).records;

  bool _allSelected = false;
  bool _showTotalCount = false;
  int _currentPage = 1;
  int _rowsPerPage = 100;

  List<ExpenseRecord> get _selectedRecords =>
      _records.where((r) => r.isSelected).toList(growable: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(expensesProvider.notifier).fetchExpenses(_buildListQuery());
    });
  }

  ExpensesListQuery _buildListQuery() {
    final state = ref.read(expensesProvider);
    return state.query.copyWith(
      page: _currentPage,
      limit: _rowsPerPage,
      favoriteFilter: _selectedFilter.value == 'all'
          ? null
          : _selectedFilter.value,
      sortBy: state.sortField,
      sortAscending: state.sortAscending,
    );
  }

  void _updateAllSelectedState() {
    if (_records.isEmpty) {
      _allSelected = false;
      return;
    }
    bool allPageSelected = true;
    for (final record in _records) {
      if (!record.isSelected) {
        allPageSelected = false;
        break;
      }
    }
    _allSelected = allPageSelected;
  }

  String _attachmentDownloadName(dynamic attachment) {
    final original = (attachment.originalFileName ?? '').toString().trim();
    if (original.isNotEmpty) {
      return original;
    }
    final stored = attachment.fileName.toString().trim();
    if (stored.isNotEmpty) {
      return stored;
    }
    return 'receipt';
  }

  void _downloadAttachmentUrl(String url, String fileName) {
    final anchor =
        import_web.document.createElement('a') as import_web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();
  }

  Future<void> _showNoReceiptsWarningDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => const _NoReceiptsWarningDialog(),
    );
  }

  Future<void> _downloadSelectedReceipts() async {
    final selectedWithReceipts = _selectedRecords
        .where((record) => record.hasAttachments)
        .toList(growable: false);
    if (selectedWithReceipts.isEmpty) {
      await _showNoReceiptsWarningDialog();
      return;
    }

    try {
      final repository = ref.read(expensesRepositoryProvider);
      var downloadCount = 0;

      for (final record in selectedWithReceipts) {
        final attachments = await repository.getExpenseAttachments(record.id);
        for (final attachment in attachments) {
          final fileUrl = attachment.fileUrl.trim();
          if (fileUrl.isEmpty) {
            continue;
          }
          _downloadAttachmentUrl(fileUrl, _attachmentDownloadName(attachment));
          downloadCount++;
        }
      }

      if (!mounted) {
        return;
      }
      if (downloadCount == 0) {
        await _showNoReceiptsWarningDialog();
        return;
      }
      ZerpaiToast.success(context, 'Downloading receipt(s)...');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ZerpaiToast.error(context, 'Failed to download receipt: $error');
    }
  }

  int get _selectedCount => _records.where((r) => r.isSelected).length;

  bool _clipText = true;

  int? _hoveredRowIndex;
  int? _hoveredHeaderIndex;
  bool _hoveringHeaderRow = false;
  bool _hoveringRowsPerPage = false;
  bool _hoveringPrevPage = false;
  bool _hoveringNextPage = false;

  bool _showResizedBanner = false;

  void _onColResize(int colIndex, double delta) {
    setState(() {
      _columns[colIndex].width = (_columns[colIndex].width + delta).clamp(
        50.0,
        600.0,
      );
      _showResizedBanner = true;
    });
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

  bool _isMileageExpense(ExpenseRecord record) {
    return isMileageExpenseRecord(record);
  }

  String _displayExpenseAccount(ExpenseRecord record) {
    return displayExpenseAccountLabel(record);
  }

  Widget _buildMileageExpenseAccountBlock({
    required ExpenseRecord record,
    required TextStyle style,
    int maxLines = 2,
  }) {
    return ExpenseMileageAccountInline(
      record: record,
      style: style,
      maxLines: maxLines,
    );
  }

  String _cellValue(_ColumnDef col, ExpenseRecord r) {
    switch (col.id) {
      case 'date':
        return r.date;
      case 'expenseAccount':
        return _displayExpenseAccount(r);
      case 'reference':
        return r.invoiceNumber.trim();
      case 'vendorName':
        return r.vendorName;
      case 'paidThrough':
        return r.paidThrough;
      case 'customerName':
        return r.customerName;
      case 'status':
        return r.isBillable ? 'Billable' : 'Non-Billable';
      case 'amount':
        return _fmt(r.amount);
      default:
        return '';
    }
  }

  bool _isLink(_ColumnDef col) => col.id == 'expenseAccount';

  void _showCustomizeColumnsDialog() {
    final configs = _columns
        .asMap()
        .entries
        .map(
          (e) => ColumnConfig(
            id: e.value.id,
            label: e.value.label,
            isVisible: e.value.visible,
            orderIndex: e.key,
            isLocked: e.value.isLocked,
          ),
        )
        .toList();

    showDialog(
      context: context,
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.16),
      builder: (ctx) => ColumnCustomizerDialog(
        columns: configs,
        onSave: (updated) {
          Navigator.of(ctx).pop();
          setState(() {
            for (final col in _columns) {
              final match = updated.firstWhere(
                (u) => u.id == col.id,
                orElse: () => ColumnConfig(
                  id: col.id,
                  label: col.label,
                  isVisible: col.visible,
                  isLocked: col.isLocked,
                ),
              );
              col.visible = match.isVisible;
            }
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
    return id == 'date' || id == 'amount';
  }

  void _toggleRecurringStyleSort(String id) {
    if (_sortField == id) {
      unawaited(_onSort(id, !_sortAscending));
    } else {
      unawaited(_onSort(id, true));
    }
  }

  Widget _buildRecurringStyleSortIcon(String id) {
    final isSorted = _sortField == id;

    return InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () => _toggleRecurringStyleSort(id),
      child: Icon(
        _sortAscending ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
        size: 14,
        color: isSorted ? AppTheme.primaryBlueDark : AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildSortIcon(String id) {
    final isSorted = _sortField == id;
    final isAsc = _sortAscending;
    const Color activeColor = AppTheme.primaryBlueDark;
    const Color inactiveColor = AppTheme.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => unawaited(_onSort(id, true)),
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
          onTap: () => unawaited(_onSort(id, false)),
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

  Widget _buildHeader(
    _ColumnDef col,
    int globalIdx,
    int visibleIdx,
    int totalVisible,
    double scaledWidth,
  ) {
    final isAmount = col.id == 'amount';
    final isExpenseAccount = col.id == 'expenseAccount';
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredHeaderIndex = visibleIdx),
      onExit: (_) => setState(() => _hoveredHeaderIndex = null),
      child: Container(
        width: scaledWidth,
        height: 42,
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: isAmount
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: isAmount
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          col.label.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.metaHelper.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: isAmount
                              ? TextAlign.right
                              : TextAlign.left,
                        ),
                      ),
                      if (isExpenseAccount) ...[
                        const SizedBox(width: 4),
                        _buildRecurringStyleSortIcon(col.id),
                      ],
                      if (_isSortable(col.id)) ...[
                        const SizedBox(width: 4),
                        _buildSortIcon(col.id),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) =>
                      _onColResize(globalIdx, d.delta.dx),
                  child: Container(
                    width: 8,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 2,
                        height: 16,
                        decoration: BoxDecoration(
                          color:
                              (_hoveringHeaderRow &&
                                  _hoveredHeaderIndex == visibleIdx)
                              ? AppTheme.borderMid
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(1),
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
    );
  }

  Widget _buildBodyCell(
    _ColumnDef col,
    ExpenseRecord record,
    double scaledWidth,
  ) {
    final val = _cellValue(col, record);
    final isLink = _isLink(col);
    final isAmount = col.id == 'amount';
    final isExpenseAccount = col.id == 'expenseAccount';
    final showAttachmentIndicator = isAmount && record.hasAttachments;
    final isMileage = _isMileageExpense(record);

    final text = Text(
      val,
      overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.visible,
      maxLines: _clipText ? 1 : 2,
      softWrap: !_clipText,
      textAlign: isAmount ? TextAlign.right : TextAlign.left,
      style: AppTheme.tableCell.copyWith(
        height: 1.7,
        color: col.id == 'status'
            ? AppTheme.textSecondary
            : (isLink ? AppTheme.primaryBlue : AppTheme.textPrimary),
        fontWeight: col.id == 'amount' || isLink
            ? FontWeight.w600
            : FontWeight.w400,
      ),
    );

    return SizedBox(
      width: scaledWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(
          alignment: isAmount ? Alignment.centerRight : Alignment.centerLeft,
          child: isAmount
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      text,
                      const SizedBox(width: 6),
                      SizedBox(
                        width: _amountAttachmentSlotWidth,
                        child: Center(
                          child: showAttachmentIndicator
                              ? const Icon(
                                  LucideIcons.paperclip,
                                  size: 12,
                                  color: AppTheme.textSecondary,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                )
              : isExpenseAccount && isMileage
              ? _buildMileageExpenseAccountBlock(
                  record: record,
                  style: text.style ?? AppTheme.tableCell,
                )
              : text,
        ),
      ),
    );
  }

  Widget _buildPaginationFooterRow({
    required int startIndex,
    required int endIndex,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        height: _paginationFooterHeight,
        decoration: const BoxDecoration(color: AppTheme.backgroundColor),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Text('Total Count: ', style: AppTextStyles.body),
            ZerpaiLinkText(
              text: _showTotalCount
                  ? '${ref.watch(expensesProvider).totalRecords}'
                  : 'View',
              style: AppTheme.tableCell.copyWith(
                color: AppTheme.primaryBlueDark,
                fontWeight: FontWeight.w500,
              ),
              onTap: () => setState(() => _showTotalCount = !_showTotalCount),
            ),
            const Spacer(),
            Container(
              height: AppTheme.inputHeight,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border.all(color: AppTheme.borderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<int>(
                    tooltip: 'Rows per page',
                    offset: const Offset(0, -160),
                    color: AppTheme.backgroundColor,
                    surfaceTintColor: AppTheme.backgroundColor,
                    onSelected: (val) async {
                      await _changePageSize(val);
                    },
                    itemBuilder: (ctx) => [10, 25, 50, 100, 200]
                        .map(
                          (val) => PopupMenuItem<int>(
                            value: val,
                            padding: EdgeInsets.zero,
                            height: 36,
                            child: _HoverPopupMenuItem(label: '$val per page'),
                          ),
                        )
                        .toList(),
                    child: MouseRegion(
                      onEnter: (_) =>
                          setState(() => _hoveringRowsPerPage = true),
                      onExit: (_) =>
                          setState(() => _hoveringRowsPerPage = false),
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        height: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        color: _hoveringRowsPerPage
                            ? AppTheme.bgDisabled
                            : AppTheme.bgLight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.settings,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_rowsPerPage per page',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppTheme.borderLight,
                  ),
                  Container(
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hoveringPrevPage = true),
                          onExit: (_) =>
                              setState(() => _hoveringPrevPage = false),
                          cursor: _currentPage > 1
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: _currentPage > 1
                                ? () async => _changePage(_currentPage - 1)
                                : null,
                            child: Container(
                              width: 20,
                              height: double.infinity,
                              color: _hoveringPrevPage && _currentPage > 1
                                  ? AppTheme.bgLight
                                  : Colors.transparent,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.chevron_left,
                                size: 18,
                                color: _currentPage > 1
                                    ? AppTheme.primaryBlueDark
                                    : AppTheme.borderMid,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 58),
                          alignment: Alignment.center,
                          child: Text(
                            ref.watch(expensesProvider).totalRecords == 0
                                ? '0 - 0'
                                : '${startIndex + 1} - $endIndex',
                            style: AppTheme.metaHelper.copyWith(
                              color: AppTheme.textBody,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hoveringNextPage = true),
                          onExit: (_) =>
                              setState(() => _hoveringNextPage = false),
                          cursor:
                              _currentPage <
                                  ref.watch(expensesProvider).totalPages
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap:
                                _currentPage <
                                    ref.watch(expensesProvider).totalPages
                                ? () async => _changePage(_currentPage + 1)
                                : null,
                            child: Container(
                              width: 20,
                              height: double.infinity,
                              color:
                                  _hoveringNextPage &&
                                      _currentPage <
                                          ref.watch(expensesProvider).totalPages
                                  ? AppTheme.bgLight
                                  : Colors.transparent,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.chevron_right,
                                size: 18,
                                color:
                                    _currentPage <
                                        ref.watch(expensesProvider).totalPages
                                    ? AppTheme.primaryBlueDark
                                    : AppTheme.borderMid,
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

  void _toggleSelectAll(bool? val) {
    if (val == null) return;
    setState(() {
      _allSelected = val;
      ref
          .read(expensesProvider.notifier)
          .toggleSelectAll(val, 0, _records.length);
    });
  }

  void _toggleRecordSelect(int absoluteIndex, bool? val) {
    if (val == null) return;
    setState(() {
      ref
          .read(expensesProvider.notifier)
          .toggleRecordSelect(absoluteIndex, val);
      _updateAllSelectedState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expensesProvider);
    final startIndex = state.totalRecords == 0
        ? 0
        : ((_currentPage - 1) * _rowsPerPage);
    final endIndex = state.totalRecords == 0
        ? 0
        : (startIndex + _records.length).clamp(0, state.totalRecords);
    final paginatedRecords = _records;

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Container(
        color: AppTheme.backgroundColor,
        child: Column(
          children: [
            // ── Resized-columns save banner ────────────────
            if (_showResizedBanner)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppTheme.infoBg,
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.primaryBlueDark,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You have resized the columns. Would you like to save the changes?',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.infoTextDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => _showResizedBanner = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: AppTheme.backgroundColor,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Save', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _showResizedBanner = false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            // ── Ribbon replaces top bar when rows selected ─────────────
            if (_selectedCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                child: _BulkActionRibbon(
                  selectedCount: _selectedCount,
                  onBulkUpdate: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExpensesBulkUpdateDialog(
                        fields: const [
                          'Expense Account',
                          'Paid Through',
                          'Date',
                          'Billable',
                          'Reference#',
                          'Notes',
                          'Customer Name',
                        ],
                        onUpdate: (field, value) {
                          setState(() {
                            ref
                                .read(expensesProvider.notifier)
                                .bulkUpdate(field, value);
                            _allSelected = false;
                            _updateAllSelectedState();
                          });
                          ZerpaiToast.success(
                            context,
                            'Expenses updated successfully',
                          );
                        },
                      ),
                    );
                  },
                  onDelete: () {
                    showZerpaiConfirmationDialog(
                      context,
                      title: 'Delete Expenses',
                      message:
                          'Are you sure about deleting the selected expense(s)?',
                      confirmLabel: 'Delete',
                      cancelLabel: 'Cancel',
                      variant: ZerpaiConfirmationVariant.danger,
                    ).then((confirmed) {
                      if (confirmed == true) {
                        setState(() {
                          _allSelected = false;
                          _currentPage = 1;
                          _updateAllSelectedState();
                        });
                        unawaited(
                          ref.read(expensesProvider.notifier).deleteSelected(),
                        );
                        ZerpaiToast.deleted(context, 'Expense(s)');
                      }
                    });
                  },
                  onDismiss: () => setState(() {
                    _allSelected = false;
                    ref
                        .read(expensesProvider.notifier)
                        .toggleSelectAll(false, 0, _records.length);
                  }),
                  onDownloadReceipts: _downloadSelectedReceipts,
                ),
              )
            else
              // Normal Top Bar matching mockup layout
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tabs
                    _tabItem(
                      'Receipts Inbox',
                      isActive: false,
                      onTap: () {
                        final orgId =
                            GoRouterState.of(
                              context,
                            ).pathParameters['orgSystemId'] ??
                            '6000000000';
                        context.go('/$orgId${AppRoutes.expensesReceiptsInbox}');
                      },
                    ),
                    const SizedBox(width: 24),
                    _buildExpensesTab(),
                    const Spacer(),
                    // Action Buttons: Upload Expense + New + More
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: InkWell(
                            onTap: _pickUploadExpenseFile,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Center(
                                child: Text(
                                  'Upload Expense',
                                  style: AppTextStyles.topBarTitle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        CompositedTransformTarget(
                          link: _uploadLayerLink,
                          child: Container(
                            height: 40,
                            width: 38,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppTheme.borderColor),
                                bottom: BorderSide(color: AppTheme.borderColor),
                                right: BorderSide(color: AppTheme.borderColor),
                              ),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                            child: InkWell(
                              onTap: _toggleUploadMenu,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: _isUploadMenuOpen
                                    ? AppTheme.primaryBlueDark
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    ZButton.primary(
                      onPressed: () {
                        final orgId =
                            GoRouterState.of(
                              context,
                            ).pathParameters['orgSystemId'] ??
                            '6000000000';
                        context.go('/$orgId/purchases/expenses/create');
                      },
                      icon: LucideIcons.plus,
                      label: 'New',
                    ),
                    const SizedBox(width: 10),
                    CompositedTransformTarget(
                      link: _moreMenuLayerLink,
                      child: Container(
                        key: _moreMenuAnchorKey,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (_isMoreMenuOpen) {
                              _closeMoreMenu();
                            } else {
                              _showMoreMenu();
                            }
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Icon(
                            LucideIcons.moreHorizontal,
                            size: 18,
                            color: _isMoreMenuOpen
                                ? AppTheme.primaryBlue
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final screenW = constraints.maxWidth;
                  final visibleCols = _columns.where((c) => c.visible).toList();
                  final colsTotalW = visibleCols.fold(
                    0.0,
                    (s, c) => s + c.width,
                  );
                  final offsetW = 12 + 28 + 10 + 20 + 24 + 40;
                  final minTableW = colsTotalW + offsetW;
                  final bool showPaginationFooter = state.totalRecords > 10;

                  final bool shouldStretch = screenW > minTableW;
                  final double scale = shouldStretch
                      ? (screenW - offsetW) / colsTotalW
                      : 1.0;
                  final double tableW = shouldStretch ? screenW : minTableW;

                  Widget tableContent = SizedBox(
                    width: tableW,
                    height: constraints.maxHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hoveringHeaderRow = true),
                          onExit: (_) => setState(() {
                            _hoveringHeaderRow = false;
                            _hoveredHeaderIndex = null;
                          }),
                          child: Container(
                            height: 42,
                            color: AppTheme.tableHeaderBg,
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                ZTableHeaderMenu(
                                  wrapText: !_clipText,
                                  onWrapChange: (wrapText) {
                                    setState(() => _clipText = !wrapText);
                                  },
                                  onCustomize: _showCustomizeColumnsDialog,
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _allSelected,
                                    onChanged: _toggleSelectAll,
                                    activeColor: AppTheme.primaryBlueDark,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                ...List.generate(visibleCols.length, (vi) {
                                  final col = visibleCols[vi];
                                  final globalIdx = _columns.indexOf(col);
                                  return _buildHeader(
                                    col,
                                    globalIdx,
                                    vi,
                                    visibleCols.length,
                                    col.width * scale,
                                  );
                                }),
                                const SizedBox(width: 40),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              SliverList.builder(
                                itemCount: paginatedRecords.length,
                                itemBuilder: (context, index) {
                                  final record = paginatedRecords[index];
                                  final isHovered = _hoveredRowIndex == index;
                                  return MouseRegion(
                                    onEnter: (_) => setState(
                                      () => _hoveredRowIndex = index,
                                    ),
                                    onExit: (_) =>
                                        setState(() => _hoveredRowIndex = null),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 100,
                                      ),
                                      height: _clipText ? 56 : null,
                                      constraints: _clipText
                                          ? null
                                          : const BoxConstraints(minHeight: 56),
                                      padding: EdgeInsets.symmetric(
                                        vertical: _clipText ? 0 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: record.isSelected
                                            ? AppTheme.selectionActiveBg
                                            : (isHovered
                                                  ? AppTheme.bgHover
                                                  : AppTheme.backgroundColor),
                                        border: const Border(
                                          bottom: BorderSide(
                                            color: AppTheme.borderLight,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 12),
                                          const SizedBox(width: 28),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value: record.isSelected,
                                              onChanged: (v) =>
                                                  _toggleRecordSelect(index, v),
                                              activeColor:
                                                  AppTheme.primaryBlueDark,
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                final orgId =
                                                    GoRouterState.of(
                                                      context,
                                                    ).pathParameters['orgSystemId'] ??
                                                    '6000000000';
                                                context.go(
                                                  '/$orgId/purchases/expenses/${record.id}',
                                                );
                                              },
                                              child: Row(
                                                children: [
                                                  ...visibleCols.map((col) {
                                                    return _buildBodyCell(
                                                      col,
                                                      record,
                                                      col.width * scale,
                                                    );
                                                  }),
                                                  const SizedBox(width: 40),
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
                              if (showPaginationFooter)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: _buildPaginationFooterRow(
                                      startIndex: startIndex,
                                      endIndex: endIndex,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  return Stack(
                    children: [
                      shouldStretch
                          ? tableContent
                          : ResponsiveTableShell(
                              minWidth: tableW,
                              child: tableContent,
                            ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            color: AppTheme.backgroundColor,
                            padding: const EdgeInsets.all(AppTheme.space16),
                            child: ZTableSkeleton(
                              rows: 8,
                              columns: math.max(1, visibleCols.length),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(
    String text, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: AppTheme.primaryBlue, width: 3),
                )
              : null,
        ),
        child: Text(
          text,
          style: _tabTextStyle(
            color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryBlue, width: 3),
        ),
      ),
      child: ExpensesFilterDropdownWidget(
        moduleName: 'expenses',
        options: _filterOptions,
        selectedOption: _selectedFilter,
        onChanged: (opt) {
          setState(() {
            _selectedFilter = opt;
            _currentPage = 1;
            _allSelected = false;
          });
          ref.read(expensesProvider.notifier).updateFilter(opt.value);
        },
      ),
    );
  }

  TextStyle _tabTextStyle({required Color color}) =>
      AppTextStyles.title.copyWith(color: color);
}

// ─── Helper: bulk action ribbon ─────────────────────────────────────────────
class _BulkActionRibbon extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onBulkUpdate;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;
  final VoidCallback onDownloadReceipts;

  const _BulkActionRibbon({
    required this.selectedCount,
    required this.onBulkUpdate,
    required this.onDelete,
    required this.onDismiss,
    required this.onDownloadReceipts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ── Bulk Update ──────────────────────────────
          _RibbonTextButton(label: 'Bulk Update', onTap: onBulkUpdate),
          const SizedBox(width: 12),
          // ── Icon group: PDF, Print, Email ────────────
          _RibbonSegmentedIconGroup(
            actions: [
              _RibbonSegmentedAction(
                icon: LucideIcons.fileText,
                tooltip: 'Export as PDF',
                onTap: () {},
              ),
              _RibbonSegmentedAction(
                icon: LucideIcons.printer,
                tooltip: 'Print',
                onTap: () {},
              ),
              _RibbonSegmentedAction(
                icon: LucideIcons.download,
                tooltip: 'Download Receipt',
                onTap: onDownloadReceipts,
              ),
            ],
          ),
          const _RibbonDivider(),
          // ── Delete ───────────────────────────────────
          _RibbonTextButton(label: 'Delete', onTap: onDelete),
          const _RibbonDivider(),
          // ── Selected count badge ──────────────────────
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.infoBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$selectedCount',
              style: AppTextStyles.body.copyWith(
                color: AppTheme.primaryBlueDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Selected',
            style: AppTextStyles.body.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          // ── Esc × dismiss ────────────────────────────
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(4),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Esc',
                    style: AppTextStyles.body.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.x, color: AppTheme.errorRed, size: 19),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RibbonDivider extends StatelessWidget {
  const _RibbonDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      color: AppTheme.borderColor,
      margin: const EdgeInsets.symmetric(horizontal: 18),
    );
  }
}

class _RibbonTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RibbonTextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: AppTextStyles.body.copyWith(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _RibbonSegmentedAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _RibbonSegmentedAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
}

class _RibbonSegmentedIconGroup extends StatelessWidget {
  final List<_RibbonSegmentedAction> actions;

  const _RibbonSegmentedIconGroup({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int index = 0; index < actions.length; index++) ...[
            _RibbonSegmentedIconButton(action: actions[index]),
            if (index != actions.length - 1)
              Container(
                width: 1,
                height: double.infinity,
                color: AppTheme.borderColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _RibbonSegmentedIconButton extends StatefulWidget {
  final _RibbonSegmentedAction action;

  const _RibbonSegmentedIconButton({required this.action});

  @override
  State<_RibbonSegmentedIconButton> createState() =>
      _RibbonSegmentedIconButtonState();
}

class _RibbonSegmentedIconButtonState
    extends State<_RibbonSegmentedIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.action.onTap != null;
    final background = enabled && _hovered
        ? AppTheme.bgDisabled
        : AppTheme.backgroundColor;
    final iconColor = enabled
        ? (_hovered ? AppTheme.textBody : AppTheme.textSecondary)
        : AppTheme.textMuted;

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.action.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 34,
          height: 34,
          color: background,
          child: ZTooltip(
            message: widget.action.tooltip,
            child: Icon(widget.action.icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _NoReceiptsWarningDialog extends StatelessWidget {
  const _NoReceiptsWarningDialog();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Dialog(
        alignment: Alignment.topCenter,
        insetPadding: EdgeInsets.zero,
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            margin: const EdgeInsets.only(top: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.alertTriangle,
                          size: 18,
                          color: AppTheme.warningOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "You haven't selected any expenses with receipts attached.\n\n"
                          'Go back and select expenses with receipts attached to continue.',
                          style: AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ZButton.primary(
                      label: 'Go Back',
                      onPressed: () => Navigator.of(context).pop(),
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

class _HoverPopupMenuItem extends StatefulWidget {
  final String label;
  const _HoverPopupMenuItem({required this.label});

  @override
  State<_HoverPopupMenuItem> createState() => _HoverPopupMenuItemState();
}

class _HoverPopupMenuItemState extends State<_HoverPopupMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: _hovered ? AppTheme.primaryBlueDark : Colors.transparent,
        alignment: Alignment.centerLeft,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            color: _hovered ? AppTheme.backgroundColor : AppTheme.textBody,
          ),
        ),
      ),
    );
  }
}

enum _SubMenuType { none, sortBy, import, export }

class _MoreMenuDropdownContent extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onResetWidths;
  final String sortField;
  final bool sortAscending;
  final void Function(String field, bool ascending) onSort;
  final VoidCallback onRefresh;
  final _SubMenuType activeSubMenu;
  final bool openSubMenuOnRight;
  final ValueChanged<_SubMenuType> onSubMenuChanged;
  final VoidCallback onImport;
  final VoidCallback onExportExpenses;
  final VoidCallback onExportCurrentView;

  const _MoreMenuDropdownContent({
    required this.onClose,
    required this.onResetWidths,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onRefresh,
    required this.activeSubMenu,
    required this.openSubMenuOnRight,
    required this.onSubMenuChanged,
    required this.onImport,
    required this.onExportExpenses,
    required this.onExportCurrentView,
  });

  @override
  State<_MoreMenuDropdownContent> createState() =>
      _MoreMenuDropdownContentState();
}

class _MoreMenuDropdownContentState extends State<_MoreMenuDropdownContent> {
  static const double _mainMenuWidth = 220;
  static const double _subMenuWidth = 200;
  static const double _subMenuGap = 4;
  static const double _menuTopInset = 4;
  static const double _menuRowHeight = 40;

  @override
  Widget build(BuildContext context) {
    final hasSubMenu =
        widget.activeSubMenu == _SubMenuType.sortBy ||
        widget.activeSubMenu == _SubMenuType.export;
    final mainMenuLeft = hasSubMenu && !widget.openSubMenuOnRight
        ? _subMenuWidth + _subMenuGap
        : 0.0;
    final subMenuLeft = widget.openSubMenuOnRight
        ? _mainMenuWidth + _subMenuGap
        : 0.0;

    return SizedBox(
      width: hasSubMenu
          ? _mainMenuWidth + _subMenuWidth + _subMenuGap
          : _mainMenuWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(left: mainMenuLeft),
            child: _buildMainMenu(),
          ),
          if (hasSubMenu)
            Positioned(
              left: subMenuLeft,
              top: _subMenuTopOffset(),
              child: _buildSubMenu(),
            ),
        ],
      ),
    );
  }

  double _subMenuTopOffset() {
    return switch (widget.activeSubMenu) {
      _SubMenuType.export => (_menuRowHeight * 2) - _menuTopInset,
      _ => 0,
    };
  }

  Widget _buildMainMenu() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.sortBy),
            child: ExpensesMoreMenuItem(
              icon: Icons.swap_vert,
              label: 'Sort by',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.sortBy,
              onTap: () {},
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.import),
            child: ExpensesMoreMenuItem(
              icon: Icons.file_download_outlined,
              label: 'Import Expenses',
              isActive: widget.activeSubMenu == _SubMenuType.import,
              onTap: () {
                widget.onClose();
                widget.onImport();
              },
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.export),
            child: ExpensesMoreMenuItem(
              icon: Icons.file_upload_outlined,
              label: 'Export',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.export,
              onTap: () {},
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.none),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExpensesMoreMenuItem(
                  icon: Icons.list,
                  label: 'Expense Category',
                  onTap: widget.onClose,
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                ExpensesMoreMenuItem(
                  icon: Icons.settings,
                  label: 'Preferences',
                  onTap: widget.onClose,
                ),
                ExpensesMoreMenuItem(
                  icon: Icons.splitscreen,
                  label: 'Manage Custom Fields',
                  onTap: widget.onClose,
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                ExpensesMoreMenuItem(
                  icon: Icons.refresh,
                  label: 'Refresh List',
                  onTap: () {
                    widget.onClose();
                    widget.onRefresh();
                  },
                ),
                ExpensesMoreMenuItem(
                  icon: Icons.settings_backup_restore,
                  label: 'Reset Column Width',
                  onTap: widget.onResetWidths,
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
        return ExpensesMoreSubMenuPanel(
          children: [
            _buildSortItem('date', 'Date'),
            _buildSortItem('expenseAccount', 'Expense Account'),
            _buildSortItem('reference', 'Reference#'),
            _buildSortItem('vendorName', 'Vendor Name'),
            _buildSortItem('customerName', 'Customer Name'),
            _buildSortItem('amount', 'Amount'),
            _buildSortItem('created', 'Created Time'),
          ],
        );
      case _SubMenuType.export:
        return ExpensesMoreSubMenuPanel(
          children: [
            ExpensesMoreSubMenuItem(
              label: 'Export Expenses',
              onTap: () {
                widget.onClose();
                widget.onExportExpenses();
              },
            ),
            ExpensesMoreSubMenuItem(
              label: 'Export Current View',
              onTap: () {
                widget.onClose();
                widget.onExportCurrentView();
              },
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
    } else {
      icon = Icons.arrow_upward;
    }

    return ExpensesMoreSubMenuItem(
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

class _UploadMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _UploadMenuItem({required this.label, required this.onTap});

  @override
  State<_UploadMenuItem> createState() => _UploadMenuItemState();
}

class _UploadMenuItemState extends State<_UploadMenuItem> {
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
          color: _hovered ? AppTheme.primaryBlueDark : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: _hovered ? AppTheme.backgroundColor : AppTheme.textBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
