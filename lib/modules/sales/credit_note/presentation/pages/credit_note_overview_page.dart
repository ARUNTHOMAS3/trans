import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/modules/sales/credit_note/models/credit_note_model.dart';
import 'package:zerpai_erp/modules/sales/credit_note/providers/credit_note_provider.dart';
import 'package:zerpai_erp/modules/sales/credit_note/repositories/credit_note_repository.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/column_customizer.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_bulk_update_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/pdf_corner_ribbon.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_metrics.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

// ── Loading skeleton (matching sales_return) ──────────────────────────────────

class _CreditNotesOverviewSkeleton extends StatelessWidget {
  /// Mirror the split (list + detail) layout rather than the full-width table.
  /// The placeholder has to match the view it resolves into, otherwise the page
  /// visibly snaps from one layout to the other the moment data lands.
  final bool split;

  const _CreditNotesOverviewSkeleton({this.split = false});

  @override
  Widget build(BuildContext context) => split ? _splitLayout() : _tableLayout();

  /// Full-width table: toolbar, header row, then body rows.
  Widget _tableLayout() {
    const columnWidths = <double>[90, 130, 120, 90, 150, 100, 80, 90, 80, 90];

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
          child: Row(
            children: [
              const Skeleton(width: 16, height: 16, borderRadius: 3),
              const SizedBox(width: 16),
              for (var index = 0; index < columnWidths.length; index++) ...[
                Skeleton(width: columnWidths[index], height: 12),
                if (index < columnWidths.length - 1) const SizedBox(width: 24),
              ],
            ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Skeleton(width: 16, height: 16, borderRadius: 3),
                  const SizedBox(width: 16),
                  for (var index = 0; index < columnWidths.length; index++) ...[
                    Skeleton(width: columnWidths[index], height: 12),
                    if (index < columnWidths.length - 1)
                      const SizedBox(width: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _splitLayout() {
    return Row(
      children: [
        // Left panel — compact list skeleton
        SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toolbar
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
                    Skeleton(width: 120, height: 18),
                    Spacer(),
                    Skeleton(width: 64, height: 28),
                    SizedBox(width: 8),
                    Skeleton(width: 28, height: 28),
                  ],
                ),
              ),
              // List items
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
                        Skeleton(width: 140, height: 13),
                        SizedBox(height: 6),
                        Skeleton(width: 100, height: 11),
                        SizedBox(height: 4),
                        Skeleton(width: 60, height: 11),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Vertical divider
        const VerticalDivider(width: 1, color: AppTheme.borderLight),
        // Right panel — detail skeleton
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                    Skeleton(width: 130, height: 18),
                    SizedBox(width: 12),
                    Skeleton(width: 70, height: 22, borderRadius: 12),
                    Spacer(),
                    Skeleton(width: 28, height: 28),
                    SizedBox(width: 8),
                    Skeleton(width: 28, height: 28),
                  ],
                ),
              ),
              // Action bar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundColor,
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
                    SizedBox(width: 20),
                    Skeleton(width: 28, height: 14),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(width: 180, height: 20),
                      const SizedBox(height: 8),
                      const Skeleton(width: 120, height: 14),
                      const SizedBox(height: 24),
                      const Skeleton(height: 40),
                      const SizedBox(height: 24),
                      // Items table header
                      Container(
                        height: 36,
                        color: const Color(0xFFF3F4F6),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: const [
                            Skeleton(width: 24, height: 12),
                            SizedBox(width: 16),
                            Expanded(child: Skeleton(height: 12)),
                            SizedBox(width: 16),
                            Skeleton(width: 70, height: 12),
                            SizedBox(width: 16),
                            Skeleton(width: 60, height: 12),
                            SizedBox(width: 16),
                            Skeleton(width: 70, height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      // Items rows
                      ...List.generate(
                        3,
                        (_) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: const [
                              Skeleton(width: 24, height: 12),
                              SizedBox(width: 16),
                              Expanded(child: Skeleton(height: 12)),
                              SizedBox(width: 16),
                              Skeleton(width: 70, height: 12),
                              SizedBox(width: 16),
                              Skeleton(width: 60, height: 12),
                              SizedBox(width: 16),
                              Skeleton(width: 70, height: 12),
                            ],
                          ),
                        ),
                      ),
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

class CreditNotesOverviewPage extends ConsumerStatefulWidget {
  /// Credit note number to open in the detail pane on arrival. Set by the
  /// report page's row tap (`?cn=`) so the deep link restores the same view.
  final String? initialCreditNoteNumber;

  const CreditNotesOverviewPage({super.key, this.initialCreditNoteNumber});

  @override
  ConsumerState<CreditNotesOverviewPage> createState() =>
      _CreditNotesOverviewPageState();
}

class _CreditNotesOverviewPageState
    extends ConsumerState<CreditNotesOverviewPage> {
  late Map<String, double> _columnWidths;

  /// Total width the header row and every body row lay out to.
  ///
  /// This must resolve each column exactly the way the cells do, including the
  /// `forId` fallback: summing only the entries present in [_columnWidths]
  /// under-counts any visible column missing from the map, and the row then
  /// overflows by that column's width.
  double get _tableWidth {
    final clip = _textMode == 'clip';
    final colSum = _visibleColumns.fold<double>(
      0.0,
      (sum, c) =>
          sum +
          (_columnWidths[c.id] ?? _CnColumnWidths.forId(c.id, clip: clip)),
    );
    return colSum +
        ZTableMetrics.chrome(hasSelection: _selectedIndices.isNotEmpty);
  }

  void _resizeColumn(String id, double delta) {
    setState(() {
      final current = _columnWidths[id] ?? 100;
      _columnWidths[id] = (current + delta).clamp(60.0, 600.0);
    });
  }

  /// Rows shown in the table, rebuilt from [creditNotesListProvider] on every
  /// build. Mutations here (bulk toolbar) are visual only and are overwritten
  /// on the next provider refresh — the source of truth is Supabase.
  List<_CreditNoteRow> _rows = <_CreditNoteRow>[];

  /// Maps a persisted credit note onto a table row. Columns the API does not
  /// carry (location, invoice, salesperson, balance) stay explicitly empty
  /// rather than showing invented values.
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
      invoiceNumber: m.invoiceNumber ?? '-',
      status: m.status,
      amount: m.formattedAmount,
      balance: '-',
      issueDate: m.formattedDate,
      salesPerson: '-',
      grandTotal: m.grandTotal,
      subTotal: m.subTotal,
      taxTotal: m.taxTotal,
      model: m,
    );
  }

  final ScrollController _horizontalScrollController = ScrollController();
  FavoriteFilterOption _activeOption = _cnFilterOptions.first;
  String get _selectedView => _activeOption.label;
  final Map<String, GlobalKey> _compactItemKeys = <String, GlobalKey>{};
  String? _selectedCreditNoteId;
  String? _lastRevealedCompactItemId;

  // Anchors for the list-header "more" menu — one per view (full / split), only
  // one of which is mounted at a time.
  final GlobalKey _fullMoreMenuKey = GlobalKey();
  final GlobalKey _compactMoreMenuKey = GlobalKey();
  bool _columnMenuOpen = false;
  bool _messageSidebarOpen = false;
  bool _isDeleting = false;

  /// Guards the one-shot `?cn=` selection so it can't fight the user's own
  /// navigation on every later rebuild.
  bool _deepLinkResolved = false;
  // 'clip' = ellipsis, 'wrap' = text wraps
  String _textMode = 'clip';
  final Set<int> _selectedIndices = {};
  int? _detailIndex;
  List<ColumnConfig> _columns = _defaultColumns();

  /// Id of the note whose refund form is open, or null for the normal detail
  /// pane. Keyed by id rather than a bool so selecting a different note drops
  /// the form automatically instead of carrying one note's entry onto another.
  String? _refundNoteId;
  final TextEditingController _refundAmountController = TextEditingController();
  final TextEditingController _refundReferenceController =
      TextEditingController();
  final TextEditingController _refundDescriptionController =
      TextEditingController();
  final TextEditingController _refundDateController = TextEditingController();
  final GlobalKey _refundDateKey = GlobalKey();
  DateTime _refundDate = DateTime.now();
  String _refundPaymentMode = 'Cash';
  String? _refundFromAccount = 'Petty Cash';

  final LayerLink _downloadLink = LayerLink();
  OverlayEntry? _downloadOverlay;

  final LayerLink _compactBulkLink = LayerLink();
  OverlayEntry? _compactBulkOverlay;

  final LayerLink _pdfPrintLink = LayerLink();
  OverlayEntry? _pdfPrintOverlay;
  final LayerLink _moreActionLink = LayerLink();
  OverlayEntry? _moreActionOverlay;

  /// Shared with the credit note report page so a view starred in one place
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

  void _onFilterChanged(FavoriteFilterOption option) {
    setState(() {
      _activeOption = option;
      _columnMenuOpen = false;
      _detailIndex = null;
      _selectedCreditNoteId = null;
      _lastRevealedCompactItemId = null;
      _selectedIndices.clear();
    });
  }

  List<_CreditNoteRow> get _filteredRows {
    // The main Credit Note list renders the repository response order. Keep
    // the overview on that same order instead of applying a second local sort.
    return _selectedView == 'All'
        ? List<_CreditNoteRow>.from(_rows)
        : _rows
              .where(
                (r) => r.status.toUpperCase() == _selectedView.toUpperCase(),
              )
              .toList();
  }

  GlobalKey _compactItemKeyFor(String creditNoteId) =>
      _compactItemKeys.putIfAbsent(creditNoteId, GlobalKey.new);

  void _scheduleCompactItemReveal({bool force = false}) {
    if (_detailIndex == null || _detailIndex! >= _filteredRows.length) return;
    final creditNoteId = _filteredRows[_detailIndex!].id;
    if (!force && _lastRevealedCompactItemId == creditNoteId) return;
    _lastRevealedCompactItemId = creditNoteId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _detailIndex == null) return;
      final targetContext = _compactItemKeys[creditNoteId]?.currentContext;
      if (targetContext == null) {
        // The compact list may not be mounted until the split view's next
        // frame. Allow that frame to schedule the reveal again.
        _lastRevealedCompactItemId = null;
        return;
      }
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _selectDetailAt(int index) {
    if (index < 0 || index >= _filteredRows.length) return;
    setState(() {
      _detailIndex = index;
      _selectedCreditNoteId = _filteredRows[index].id;
    });
    _scheduleCompactItemReveal(force: true);
  }

  bool get _allSelected =>
      _filteredRows.isNotEmpty &&
      _selectedIndices.length == _filteredRows.length;
  bool get _someSelected =>
      _selectedIndices.isNotEmpty &&
      _selectedIndices.length < _filteredRows.length;
  List<ColumnConfig> get _visibleColumns {
    final columns =
        _columns.where((c) => c.isVisible).map((c) => c.copy()).toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return columns;
  }

  static List<ColumnConfig> _defaultColumns() => [
    ColumnConfig(id: 'date', label: 'Date', orderIndex: 0, isLocked: true),
    ColumnConfig(
      id: 'creditNoteNumber',
      label: 'Credit Note#',
      orderIndex: 2,
      isLocked: true,
    ),
    ColumnConfig(id: 'referenceNumber', label: 'Reference#', orderIndex: 3),
    ColumnConfig(id: 'customerName', label: 'Customer Name', orderIndex: 4),
    ColumnConfig(id: 'invoiceNumber', label: 'Invoice#', orderIndex: 5),
    ColumnConfig(id: 'status', label: 'Status', orderIndex: 6),
    ColumnConfig(id: 'amount', label: 'Amount', orderIndex: 7),
    ColumnConfig(id: 'balance', label: 'Balance', orderIndex: 8),
    ColumnConfig(id: 'issueDate', label: 'Issue Date', orderIndex: 9),
    ColumnConfig(id: 'salesPerson', label: 'Sales Person', orderIndex: 10),
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

  /// Opens the list-header "more" menu anchored under [anchorKey]. Mirrors the
  /// Anchored list-header "more" menu button handler (the `...` icon near +New).
  /// Sort by / Export / Manage Custom Fields / Refresh List, with submenus
  /// expanding to the right.
  void _showListMoreMenu(BuildContext context, GlobalKey anchorKey) {
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;
    // Main card is 200 wide and submenus add 184 to its right.
    const menuWidth = 200.0;
    const submenuWidth = 184.0;
    double menuTop = 65;
    double menuLeft = screenWidth - menuWidth - 16;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      menuTop = pos.dy + box.size.height + 4;
      // Anchor by the LEFT edge so the main card holds its place when a submenu
      // opens; right-anchoring would shove it aside by the submenu's width.
      // Keep enough room on the right for the submenu to stay on screen.
      final maxLeft = screenWidth - 8 - (menuWidth + submenuWidth);
      final desiredLeft = pos.dx + box.size.width - menuWidth;
      menuLeft = desiredLeft.clamp(8.0, maxLeft < 8.0 ? 8.0 : maxLeft);
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
              child: _CnListMoreMenu(
                onManageCustomFields: () {
                  Navigator.of(dialogContext).pop();
                  _openColumnCustomizer();
                },
                onRefreshList: () {
                  Navigator.of(dialogContext).pop();
                  ref.invalidate(creditNotesListProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
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

  void _showDownloadMenu(BuildContext context) {
    if (_downloadOverlay != null) return;
    final overlay = Overlay.of(context);

    _downloadOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss layer
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeDownloadMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _downloadLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 38), // slightly below the button
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              child: Container(
                width: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DownloadMenuOption(
                      label: 'Export as PDF',
                      onTap: () {
                        _closeDownloadMenu();
                      },
                    ),
                    _DownloadMenuOption(
                      label: 'Export as E-Way Bill',
                      onTap: () {
                        _closeDownloadMenu();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_downloadOverlay!);
  }

  void _closeDownloadMenu() {
    _downloadOverlay?.remove();
    _downloadOverlay = null;
  }

  void _showCompactBulkMenu(BuildContext context) {
    if (_compactBulkOverlay != null) return;
    final overlay = Overlay.of(context);

    _compactBulkOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss layer
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeCompactBulkMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _compactBulkLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 38), // slightly below the button
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              child: Container(
                width: 180,
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
                      label: 'Bulk Update',
                      onTap: () {
                        _closeCompactBulkMenu();
                        showCreditNoteBulkUpdateDialog(context);
                      },
                    ),
                    _DownloadMenuOption(
                      label: 'Export as PDF',
                      onTap: () => _closeCompactBulkMenu(),
                    ),
                    _DownloadMenuOption(
                      label: 'Export as E-Way Bill',
                      onTap: () => _closeCompactBulkMenu(),
                    ),
                    _DownloadMenuOption(
                      label: 'Print',
                      onTap: () => _closeCompactBulkMenu(),
                    ),
                    _DownloadMenuOption(
                      label: 'Delete',
                      onTap: () {
                        _closeCompactBulkMenu();
                        setState(() {
                          final sorted = _selectedIndices.toList()
                            ..sort((a, b) => b.compareTo(a));
                          for (final i in sorted) {
                            _rows.removeAt(i);
                          }
                          _selectedIndices.clear();
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
    );

    overlay.insert(_compactBulkOverlay!);
  }

  void _closeCompactBulkMenu() {
    _compactBulkOverlay?.remove();
    _compactBulkOverlay = null;
  }

  void _showPdfPrintMenu(BuildContext context) {
    if (_pdfPrintOverlay != null) return;
    final overlay = Overlay.of(context);

    _pdfPrintOverlay = OverlayEntry(
      builder: (context) => Stack(
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
                      onTap: () {
                        _closePdfPrintMenu();
                        // Additional PDF download logic can go here
                      },
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

  void _showMoreActionMenu(BuildContext context) {
    if (_moreActionOverlay != null) {
      _closeMoreActionMenu();
      return;
    }
    final overlay = Overlay.of(context);

    _moreActionOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeMoreActionMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _moreActionLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              child: Container(
                width: 180,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MoreActionMenuOption(
                      label: 'Clone',
                      onTap: () {
                        _closeMoreActionMenu();
                        final row = _filteredRows[_detailIndex!];
                        context.go(
                          AppRoutes.creditNotesCreate,
                          extra: row.customerName,
                        );
                      },
                    ),
                    _MoreActionMenuOption(
                      label: 'Add e-Way Bill Details',
                      onTap: () {
                        _closeMoreActionMenu();
                      },
                    ),
                    _MoreActionMenuOption(
                      label: 'Void',
                      onTap: () {
                        _closeMoreActionMenu();
                        _showVoidReasonDialog(context);
                      },
                    ),
                    _MoreActionMenuOption(
                      label: 'Delete',
                      onTap: () {
                        _closeMoreActionMenu();
                        _showDeleteConfirmDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_moreActionOverlay!);
    setState(() {});
  }

  void _closeMoreActionMenu() {
    _moreActionOverlay?.remove();
    setState(() => _moreActionOverlay = null);
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final rowIndex = _detailIndex != null ? _filteredRows[_detailIndex!] : null;
    showDialog<void>(
      context: context,
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: EdgeInsets.zero,
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: AppTheme.backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Credit Note will be deleted forever and cannot be retrieved later. Are you sure about deleting it?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        if (rowIndex != null) {
                          _deleteCreditNote(rowIndex);
                        }
                      },
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textPrimary,
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
      ),
    );
  }

  /// Deletes the credit note after the confirmation dialog. The server
  /// cascades to credit_note_items and the posted ledger rows, so this is one
  /// call; on success the list refetches and the detail pane closes.
  Future<void> _deleteCreditNote(_CreditNoteRow row) async {
    if (_isDeleting) return;
    if (row.id.isEmpty) {
      ZerpaiToast.error(context, 'This credit note cannot be deleted.');
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await ref.read(deleteCreditNoteProvider)(row.id);
      if (!mounted) return;
      setState(() {
        _detailIndex = null;
        _selectedIndices.clear();
      });
      ref.invalidate(creditNotesListProvider);
      ZerpaiToast.success(context, 'Credit note deleted successfully.');
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete credit note',
        error: e,
        stackTrace: st,
        module: 'credit_note',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to delete credit note.');
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showVoidReasonDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a reason for marking this transaction as Void.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        final row = _filteredRows[_detailIndex!];
                        row.status = 'VOID';
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text(
                      'Void it',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEEEEE),
                      foregroundColor: AppTheme.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConvertDraftDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Convert to Draft',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Note down the reason as to why you want to undo a void transaction.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        final row = _filteredRows[_detailIndex!];
                        row.status = 'DRAFT';
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text(
                      'Convert to Draft',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEEEEE),
                      foregroundColor: AppTheme.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Invoices each credit note has been applied to, keyed by credit note
  /// number. Drives the "Credit Applied Invoices" panel and hides the "Apply to
  /// Invoices" action once the note's credit is spent.
  final Map<String, List<_CnAppliedInvoice>> _appliedByCreditNote = {};

  List<_CnAppliedInvoice> _appliedFor(_CreditNoteRow row) =>
      _appliedByCreditNote[row.creditNoteNumber] ?? const [];

  double _appliedTotalFor(_CreditNoteRow row) =>
      _appliedFor(row).fold(0.0, (sum, a) => sum + a.amountCredited);

  /// True once the note has no credit left to hand out.
  /// Credit still available to refund: the note total less whatever has already
  /// been applied to invoices. `row.balance` is a placeholder, so it is derived
  /// here from the same numbers the "Apply to Invoices" flow uses.
  double _refundableBalance(_CreditNoteRow row) {
    final total = double.tryParse(row.amount.replaceAll(',', '')) ?? 0.0;
    return (total - _appliedTotalFor(row)).clamp(0.0, double.infinity);
  }

  void _openRefundView(_CreditNoteRow row) {
    setState(() {
      _refundNoteId = row.id;
      _refundDate = DateTime.now();
      _refundDateController.text = DateFormat('dd-MM-yyyy').format(_refundDate);
      _refundAmountController.clear();
      _refundReferenceController.clear();
      _refundDescriptionController.clear();
      _refundPaymentMode = 'Cash';
      _refundFromAccount = 'Petty Cash';
    });
  }

  void _closeRefundView() => setState(() => _refundNoteId = null);

  void _saveRefund(_CreditNoteRow row) {
    final amount = double.tryParse(
      _refundAmountController.text.trim().replaceAll(',', ''),
    );
    if (amount == null || amount <= 0) {
      ZerpaiToast.error(context, 'Enter a refund amount');
      return;
    }
    final balance = _refundableBalance(row);
    if (amount > balance + 0.005) {
      ZerpaiToast.error(
        context,
        'Refund cannot exceed the balance of ${_inr(balance)}',
      );
      return;
    }
    if ((_refundFromAccount ?? '').isEmpty) {
      ZerpaiToast.error(context, 'Select an account to refund from');
      return;
    }
    // No refund endpoint exists on the credit notes API yet, so the entry is
    // validated and acknowledged rather than silently dropped.
    ZerpaiToast.info(
      context,
      'Refund of ${_inr(amount)} recorded for ${row.creditNoteNumber}',
    );
    _closeRefundView();
  }

  String _inr(double value) => '₹${NumberFormat('#,##0.00').format(value)}';

  /// Right-aligned label + field pairing used across the refund form.
  Widget _refundField(
    String label,
    Widget field, {
    bool required = false,
    double labelWidth = 130,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text(
              label,
              textAlign: TextAlign.right,
              // Required labels render fully red, matching the create page's
              // `labelColor: AppTheme.errorRed` convention.
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: required ? AppTheme.errorRed : AppTheme.textBody,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: field),
      ],
    );
  }

  Widget _refundPartyTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.bgDisabled,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 20, color: AppTheme.textMuted),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefundView(_CreditNoteRow row) {
    // `_buildSplitView`'s Row centres its children, so a bare scroll view would
    // shrink-wrap and float in the middle of the pane. The stretched Column +
    // Expanded forces full height and anchors the form to the top, matching how
    // `_buildDetailPanel` fills the same slot.
    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refund (${row.creditNoteNumber})',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _refundPartyTile(
                          icon: LucideIcons.user,
                          label: 'Customer Name',
                          value: row.customerName,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _refundPartyTile(
                          icon: LucideIcons.fileText,
                          label: 'Credit Note Number',
                          value: row.creditNoteNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Amount band
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 130,
                          child: RichText(
                            textAlign: TextAlign.right,
                            text: const TextSpan(
                              text: 'Amount',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.errorRed,
                              ),
                              children: [TextSpan(text: '*')],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          height: 36,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: const BoxDecoration(
                            color: AppTheme.backgroundColor,
                            border: Border(
                              top: BorderSide(color: AppTheme.borderLight),
                              left: BorderSide(color: AppTheme.borderLight),
                              bottom: BorderSide(color: AppTheme.borderLight),
                            ),
                          ),
                          child: const Text(
                            'INR',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textBody,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: CustomTextField(
                            controller: _refundAmountController,
                            height: 36,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Balance : ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textBody,
                          ),
                        ),
                        Text(
                          _inr(_refundableBalance(row)),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _refundField(
                          'Refunded On*',
                          CustomTextField(
                            key: _refundDateKey,
                            controller: _refundDateController,
                            readOnly: true,
                            height: 36,
                            onTap: () async {
                              final picked = await ZerpaiDatePicker.show(
                                context,
                                initialDate: _refundDate,
                                targetKey: _refundDateKey,
                              );
                              if (picked == null) return;
                              setState(() {
                                _refundDate = picked;
                                _refundDateController.text = DateFormat(
                                  'dd-MM-yyyy',
                                ).format(picked);
                              });
                            },
                          ),
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: _refundField(
                          'Payment Mode',
                          FormDropdown<String>(
                            value: _refundPaymentMode,
                            height: 36,
                            items: const [
                              'Cash',
                              'Check',
                              'Credit Card',
                              'Bank Transfer',
                              'Other',
                            ],
                            onChanged: (v) => setState(
                              () => _refundPaymentMode = v ?? 'Cash',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _refundField(
                          'Reference#',
                          CustomTextField(
                            controller: _refundReferenceController,
                            height: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: _refundField(
                          'From Account*',
                          FormDropdown<String>(
                            value: _refundFromAccount,
                            height: 36,
                            hint: 'Select an account',
                            items: const [
                              'Petty Cash',
                              'Undeposited Funds',
                              'Bank Account',
                            ],
                            onChanged: (v) =>
                                setState(() => _refundFromAccount = v),
                          ),
                          required: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _refundField(
                          'Description',
                          CustomTextField(
                            controller: _refundDescriptionController,
                            maxLines: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ZButton.primary(
                        label: 'Save',
                        onPressed: () => _saveRefund(row),
                      ),
                      const SizedBox(width: 12),
                      ZButton.secondary(
                        label: 'Cancel',
                        onPressed: _closeRefundView,
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

  bool _isFullyApplied(_CreditNoteRow row) {
    final total = double.tryParse(row.amount.replaceAll(',', '')) ?? 0.0;
    if (total <= 0) return false;
    return _appliedTotalFor(row) >= total - 0.005;
  }

  Future<void> _showApplyToInvoicesDialog(
    BuildContext context,
    _CreditNoteRow row,
  ) async {
    final result = await showDialog<CreditNoteInvoiceApplicationData>(
      context: context,
      useRootNavigator: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _ApplyToInvoicesDialog(
        creditNote: row,
        repository: ref.read(creditNoteRepositoryProvider),
      ),
    );

    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _appliedByCreditNote[row.creditNoteNumber] = result.applications
          .map(
            (application) => _CnAppliedInvoice(
              date: application.appliedOn ?? '',
              invoiceNumber: application.invoiceNumber,
              amountCredited: application.amount,
            ),
          )
          .toList();
      row.status = result.status;
    });
  }

  void _removeAppliedInvoice(_CreditNoteRow row, _CnAppliedInvoice applied) {
    setState(() {
      _appliedByCreditNote[row.creditNoteNumber]?.remove(applied);
      if (_appliedByCreditNote[row.creditNoteNumber]?.isEmpty ?? false) {
        _appliedByCreditNote.remove(row.creditNoteNumber);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _columnWidths = _CnColumnWidths.defaults(clip: true);
  }

  @override
  void didUpdateWidget(covariant CreditNotesOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCreditNoteNumber != widget.initialCreditNoteNumber) {
      _deepLinkResolved = false;
      _lastRevealedCompactItemId = null;
      _selectedCreditNoteId = null;
      if (_detailIndex != null) {
        setState(() => _detailIndex = null);
      }
    }
  }

  @override
  void dispose() {
    _refundAmountController.dispose();
    _refundReferenceController.dispose();
    _refundDescriptionController.dispose();
    _refundDateController.dispose();
    _horizontalScrollController.dispose();
    _downloadOverlay?.remove();
    _compactBulkOverlay?.remove();
    _pdfPrintOverlay?.remove();
    _moreActionOverlay?.remove();
    super.dispose();
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
  Widget build(BuildContext context) {
    // Source of truth is Supabase. Rebuild the table from the provider each
    // build; keep the last data during a background refresh so the list does
    // not blank out while a delete is refetching.
    final creditNotesAsync = ref.watch(creditNotesListProvider(null));
    final models = creditNotesAsync.valueOrNull;
    if (models != null) {
      _rows = models.map(_rowFromModel).toList();
      // Re-resolve selection by the record id after a provider refresh. The
      // API order is authoritative and can change as new notes are created.
      if (_selectedCreditNoteId != null) {
        final selectedIndex = _filteredRows.indexWhere(
          (row) => row.id == _selectedCreditNoteId,
        );
        _detailIndex = selectedIndex >= 0 ? selectedIndex : null;
        if (_detailIndex != null) {
          _scheduleCompactItemReveal();
        }
      }
    }
    final showLoading = creditNotesAsync.isLoading && _rows.isEmpty;
    final showError = creditNotesAsync.hasError && _rows.isEmpty;

    // Rows only exist once the fetch resolves, so the deep-linked note can't be
    // selected until then — resolve it on the first build that has data.
    if (!_deepLinkResolved && _rows.isNotEmpty) {
      _deepLinkResolved = true;
      final target = widget.initialCreditNoteNumber?.trim();
      if (target != null && target.isNotEmpty) {
        final index = _filteredRows.indexWhere(
          (r) => r.creditNoteNumber == target,
        );
        if (index >= 0) {
          _detailIndex = index;
          _selectedCreditNoteId = _filteredRows[index].id;
          _scheduleCompactItemReveal();
        }
      }
    }

    final messageDrawerWidth = MediaQuery.sizeOf(
      context,
    ).width.clamp(320.0, 400.0).toDouble();

    return PopScope(
      canPop: _detailIndex == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_detailIndex != null) {
          setState(() => _detailIndex = null);
        }
      },
      child: ZerpaiLayout(
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
                ? _CreditNotesOverviewSkeleton(split: _detailIndex != null)
                : showError
                ? _buildLoadErrorState(creditNotesAsync.error)
                : Stack(
                    children: [
                      if (_detailIndex != null)
                        Positioned.fill(child: _buildSplitView())
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _selectedIndices.isNotEmpty
                                ? _buildBulkToolbar()
                                : _buildToolbar(context),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                            Expanded(child: _buildFullTable()),
                          ],
                        ),
                      if (_columnMenuOpen)
                        Positioned(
                          top: 90,
                          left: 14,
                          child: Material(
                            elevation: 0,
                            color: AppTheme.backgroundColor.withValues(
                              alpha: 0,
                            ),
                            child: Container(
                              width: 200,
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.textPrimary.withValues(
                                      alpha: 0.12,
                                    ),
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
                                    onTap: _openColumnCustomizer,
                                  ),
                                  _ColumnMenuOption(
                                    label: _textMode == 'clip'
                                        ? 'Clip Text'
                                        : 'Wrap Text',
                                    icon: _textMode == 'clip'
                                        ? LucideIcons.minus
                                        : LucideIcons.alignLeft,
                                    selected: false,
                                    onTap: () => setState(() {
                                      _textMode = _textMode == 'clip'
                                          ? 'wrap'
                                          : 'clip';
                                      _columnWidths = _CnColumnWidths.defaults(
                                        clip: _textMode == 'clip',
                                      );
                                      _columnMenuOpen = false;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        top: 0,
                        bottom: 0,
                        width: messageDrawerWidth,
                        right: _messageSidebarOpen ? 0 : -messageDrawerWidth,
                        child: IgnorePointer(
                          ignoring: !_messageSidebarOpen,
                          child: _CreditNoteMessageSidebar(
                            row: _detailIndex == null
                                ? null
                                : _filteredRows[_detailIndex!],
                            onClose: () =>
                                setState(() => _messageSidebarOpen = false),
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
            onChanged: _onFilterChanged,
          ),
          const Spacer(),
          ZButton.primary(
            label: 'New',
            icon: LucideIcons.plus,
            onPressed: () => context.go(AppRoutes.creditNotesCreate),
          ),
          const SizedBox(width: 12),
          Container(
            key: _fullMoreMenuKey,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.moreHorizontal, size: 18),
              onPressed: () => _showListMoreMenu(context, _fullMoreMenuKey),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Floor the table at the *viewport* width, not the window width:
        // MediaQuery still counts the sidebar, which forced the table ~240px
        // wider than the content area and left it permanently scrolled right.
        final viewportWidth = constraints.maxWidth;
        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: viewportWidth),
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
                      clipText: _textMode == 'clip',
                      columnWidths: _columnWidths,
                      onColumnResize: _resizeColumn,
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _filteredRows.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: AppTheme.borderLight,
                        ),
                        itemBuilder: (context, index) => _CnTableRow(
                          row: _filteredRows[index],
                          selected: _selectedIndices.contains(index),
                          hasSelection: _selectedIndices.isNotEmpty,
                          onChanged: (v) => _toggleRow(index, v),
                          onTap: () => _selectDetailAt(index),
                          columns: _visibleColumns,
                          clipText: _textMode == 'clip',
                          columnWidths: _columnWidths,
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
    );
  }

  Widget _buildSplitView() {
    return Row(
      children: [
        _buildCompactList(),
        const VerticalDivider(width: 1, color: AppTheme.borderLight),
        Expanded(child: _buildDetailPanel()),
      ],
    );
  }

  Widget _buildCompactList() {
    return Container(
      width: 460,
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _selectedIndices.isNotEmpty
              ? _buildCompactBulkToolbar()
              : Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      FavoriteFilterDropdown(
                        moduleName: 'credit_notes',
                        options: _cnFilterOptions,
                        selectedOption: _activeOption,
                        showChevron: true,
                        isCompact: true,
                        onChanged: _onFilterChanged,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.creditNotesCreate),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            LucideIcons.plus,
                            size: 18,
                            color: AppTheme.backgroundColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () =>
                            _showListMoreMenu(context, _compactMoreMenuKey),
                        child: Container(
                          key: _compactMoreMenuKey,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderLight),
                            borderRadius: BorderRadius.circular(4),
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
          // List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _filteredRows.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderLight),
              itemBuilder: (context, index) => KeyedSubtree(
                key: _compactItemKeyFor(_filteredRows[index].id),
                child: _CnCompactItem(
                  row: _filteredRows[index],
                  selected: index == _detailIndex,
                  checked: _selectedIndices.contains(index),
                  onCheckChanged: (v) => _toggleRow(index, v),
                  onTap: () => _selectDetailAt(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    final row = _filteredRows[_detailIndex!];
    if (_refundNoteId == row.id) return _buildRefundView(row);
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                _DetailHeaderIconButton(
                  icon: LucideIcons.arrowLeft,
                  onTap: () => setState(() {
                    _detailIndex = null;
                    _messageSidebarOpen = false;
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        row.creditNoteNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                _DetailHeaderIconButton(
                  icon: LucideIcons.paperclip,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _DetailHeaderIconButton(
                  icon: LucideIcons.messageSquare,
                  onTap: () => setState(() {
                    _messageSidebarOpen = !_messageSidebarOpen;
                  }),
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: AppTheme.borderLight,
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.salesCreditNotes),
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
                ),
              ],
            ),
          ),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                if (row.status.toUpperCase() != 'VOID') ...[
                  _DetailActionBtn(
                    icon: LucideIcons.pencil,
                    label: 'Edit',
                    // The create page loads the note by id and saving updates
                    // it. edit_id is a query param, not `state.extra`: the
                    // top-level org-id redirect drops `extra` across a
                    // redirect, and a query param is also refresh-safe.
                    onTap: () => context.go(
                      '${AppRoutes.creditNotesCreate}?edit_id=${row.id}',
                    ),
                  ),
                  const _DetailActionDivider(),
                  _DetailActionBtn(
                    icon: LucideIcons.mail,
                    label: 'Email',
                    onTap: () {},
                  ),
                  const _DetailActionDivider(),
                ],
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
                if (row.status.toUpperCase() != 'VOID') ...[
                  // Drops off once the note's credit is fully applied — there
                  // is nothing left to hand to another invoice.
                  if (row.status.toUpperCase() != 'CLOSED' &&
                      !_isFullyApplied(row)) ...[
                    _DetailActionBtn(
                      icon: LucideIcons.fileUp,
                      label: 'Apply to Invoices',
                      onTap: () => _showApplyToInvoicesDialog(context, row),
                    ),
                    const _DetailActionDivider(),
                    _DetailActionBtn(
                      icon: LucideIcons.rotateCcw,
                      label: 'Refund',
                      onTap: () => _openRefundView(row),
                    ),
                    const _DetailActionDivider(),
                  ],
                ] else ...[
                  _DetailActionBtn(
                    icon: LucideIcons.rotateCw,
                    label: 'Convert to Draft',
                    onTap: () => _showConvertDraftDialog(context),
                  ),
                  const _DetailActionDivider(),
                ],
                CompositedTransformTarget(
                  link: _moreActionLink,
                  child: _DetailActionBtn(
                    icon: LucideIcons.moreHorizontal,
                    onTap: () => _showMoreActionMenu(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 44, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (row.status.toUpperCase() == 'DRAFT') ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                color: Colors.purple,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "WHAT'S NEXT?",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: 0.5,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "Go ahead and email this credit note to your customer or simply convert it to open.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: const Text(
                                      'Send Credit Note',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.textPrimary,
                                      side: const BorderSide(
                                        color: AppTheme.borderLight,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        row.status = 'OPEN';
                                      });
                                    },
                                    child: const Text(
                                      'Convert to Open',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_appliedFor(row).isNotEmpty) ...[
                        _CnAppliedInvoicesPanel(
                          applied: _appliedFor(row),
                          onRemove: (a) => _removeAppliedInvoice(row, a),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // Paper capped and centred. The ribbon is scaled to match
                      // in _CnDocumentPreview, so it stays proportional rather
                      // than looking oversized on the narrower page.
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: _CnDocumentPreview(row: row),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'More Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 160,
                            child: Text(
                              'Associated Invoice',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF777777),
                              ),
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: ': ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                  TextSpan(
                                    text: row.invoiceNumber,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 160,
                            child: Text(
                              'Salesperson',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF777777),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              ': ${row.salesPerson}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _CnJournalSection(row: row),
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

  Widget _buildCompactBulkToolbar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: _selectedIndices.isNotEmpty,
              tristate: false,
              onChanged: (v) => _toggleSelectAll(_allSelected ? false : true),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          CompositedTransformTarget(
            link: _compactBulkLink,
            child: _BulkActionButton(
              label: 'Bulk Actions',
              trailingIcon: LucideIcons.chevronDown,
              onTap: () => _showCompactBulkMenu(context),
            ),
          ),
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppTheme.borderLight,
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${_selectedIndices.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
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
            onTap: () => showCreditNoteBulkUpdateDialog(context),
          ),
          const SizedBox(width: 8),
          // Download with chevron
          CompositedTransformTarget(
            link: _downloadLink,
            child: _BulkActionButton(
              icon: LucideIcons.download,
              trailingIcon: LucideIcons.chevronDown,
              onTap: () => _showDownloadMenu(context),
            ),
          ),
          const SizedBox(width: 8),
          // Print
          _BulkActionButton(icon: LucideIcons.printer, onTap: () {}),
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
            onTap: () {
              setState(() {
                final sorted = _selectedIndices.toList()
                  ..sort((a, b) => b.compareTo(a));
                for (final i in sorted) {
                  _rows.removeAt(i);
                }
                _selectedIndices.clear();
              });
            },
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          // Hover lifts the button onto a white chip with a darker border, the
          // same treatment as the document action bars elsewhere in sales.
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

class _MoreActionMenuOption extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _MoreActionMenuOption({required this.label, required this.onTap});

  @override
  State<_MoreActionMenuOption> createState() => _MoreActionMenuOptionState();
}

class _MoreActionMenuOptionState extends State<_MoreActionMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: _hovered ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dropdown section header (FAVORITES / DEFAULT FILTERS) ───────────────────

class _DownloadMenuOption extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const _DownloadMenuOption({
    required this.label,
    required this.onTap,
    this.icon,
  });

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
      cursor: SystemMouseCursors.click,
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
                Icon(
                  widget.icon,
                  size: 16,
                  color: _hovered ? Colors.white : AppTheme.primaryBlue,
                ),
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
    final iconColor = filled
        ? AppTheme.backgroundColor
        : widget.selected
        ? AppTheme.primaryBlue
        : AppTheme.primaryBlue;

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
                : widget.selected
                ? AppTheme.primaryBlue.withValues(alpha: 0.07)
                : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: filled
                ? Border.all(color: AppTheme.primaryBlueDark, width: 2)
                : widget.selected
                ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3))
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
              // Show checkmark for the active text mode
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

class _CnTableHeader extends StatelessWidget {
  final bool allSelected;
  final bool someSelected;
  final bool hasSelection;
  final ValueChanged<bool?> onSelectAll;
  final bool columnMenuOpen;
  final VoidCallback onColumnMenuTap;
  final List<ColumnConfig> columns;
  final bool clipText;
  final Map<String, double> columnWidths;
  final void Function(String id, double delta) onColumnResize;

  const _CnTableHeader({
    required this.allSelected,
    required this.someSelected,
    required this.hasSelection,
    required this.onSelectAll,
    required this.columnMenuOpen,
    required this.onColumnMenuTap,
    required this.columns,
    required this.clipText,
    required this.columnWidths,
    required this.onColumnResize,
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
              value: allSelected || someSelected,
              tristate: false,
              onChanged: (v) {
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
              width:
                  columnWidths[column.id] ??
                  _CnColumnWidths.forId(column.id, clip: clipText),
              label: column.label.toUpperCase(),
              sorted: column.id == 'creditNoteNumber',
              sortAscending: false,
              clipText: true,
              onResize: (delta) => onColumnResize(column.id, delta),
              onSort: null,
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
    required this.columns,
    required this.clipText,
    required this.columnWidths,
    this.onTap,
  });
  final _CreditNoteRow row;
  final bool selected;
  final bool hasSelection;
  final ValueChanged<bool?> onChanged;
  final List<ColumnConfig> columns;
  final bool clipText;
  final Map<String, double> columnWidths;
  final VoidCallback? onTap;

  /// Kept on the widget rather than the state: `_CnCompactItem` calls it
  /// statically to colour the same statuses in the split-view list.
  static Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return AppTheme.primaryBlue;
      case 'CLOSED':
        return AppTheme.successGreen;
      case 'DRAFT':
        return AppTheme.textSecondary;
      case 'VOID':
        return const Color(0xFF666666);
      case 'PENDING APPROVAL':
        return const Color(0xFF9B59B6);
      default:
        return AppTheme.primaryBlue;
    }
  }

  @override
  State<_CnTableRow> createState() => _CnTableRowState();
}

class _CnTableRowState extends State<_CnTableRow> {
  bool _hovered = false;

  _CreditNoteRow get row => widget.row;
  bool get selected => widget.selected;
  bool get hasSelection => widget.hasSelection;
  ValueChanged<bool?> get onChanged => widget.onChanged;
  List<ColumnConfig> get columns => widget.columns;
  bool get clipText => widget.clipText;
  Map<String, double> get columnWidths => widget.columnWidths;
  VoidCallback? get onTap => widget.onTap;

  @override
  Widget build(BuildContext context) {
    final isClip = clipText;
    final rowContent = Row(
      crossAxisAlignment: isClip
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (!hasSelection) const SizedBox(width: ZTableMetrics.menuIcon),
        SizedBox(
          height: isClip ? 48 : null,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: ZTableMetrics.checkbox,
              child: Checkbox(
                value: selected,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
        for (final column in columns)
          _CnBodyCell(
            width:
                columnWidths[column.id] ??
                _CnColumnWidths.forId(column.id, clip: isClip),
            clip: isClip,
            child: _buildCell(column.id, isClip),
          ),
      ],
    );

    // Matches the sales return report: selection is the stronger tint, hover a
    // lighter one, so a hovered row never outshines the selected one.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // Clip mode: fixed 48 px row. Wrap mode: grows with content (min 48).
          height: isClip ? 48 : null,
          constraints: isClip ? null : const BoxConstraints(minHeight: 48),
          color: selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.07)
              : _hovered
              ? AppTheme.primaryBlue.withValues(alpha: 0.03)
              : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: ZTableMetrics.hPad,
            vertical: isClip ? 0 : 10,
          ),
          child: rowContent,
        ),
      ),
    );
  }

  Color _statusColor(String status) => _CnTableRow._statusColor(status);

  Widget _buildCell(String id, bool clipText) {
    switch (id) {
      case 'date':
        return _CnBodyText(row.date, clip: clipText);
      case 'location':
        return _CnBodyText(row.location, clip: clipText);
      case 'creditNoteNumber':
        return _CnBodyText(
          row.creditNoteNumber,
          color: AppTheme.primaryBlueDark,
          fontWeight: FontWeight.w600,
          clip: clipText,
        );
      case 'referenceNumber':
        return _CnBodyText(row.referenceNumber, clip: clipText);
      case 'customerName':
        return _CnBodyText(row.customerName, clip: clipText);
      case 'invoiceNumber':
        return _CnBodyText(row.invoiceNumber, clip: clipText);
      case 'status':
        return _CnBodyText(
          row.status,
          color: _statusColor(row.status),
          fontWeight: FontWeight.w500,
          clip: clipText,
        );
      case 'amount':
        return _CnBodyText(row.amount, clip: clipText);
      case 'balance':
        return _CnBodyText(row.balance, clip: clipText);
      case 'issueDate':
        return _CnBodyText(row.issueDate, clip: clipText);
      case 'salesPerson':
        return _CnBodyText(row.salesPerson, clip: clipText);
      default:
        return _CnBodyText('-', clip: clipText);
    }
  }
}

class _CnColumnWidths {
  // Clip mode — compact fixed widths
  static const double date = 110;
  static const double location = 260;
  static const double creditNoteNumber = 140;
  static const double referenceNumber = 140;
  static const double customerName = 180;
  static const double invoiceNumber = 140;
  static const double status = 100;
  static const double amount = 110;
  static const double balance = 110;
  static const double issueDate = 120;
  static const double salesPerson = 150;

  // Wrap mode — wider so text has room to wrap
  static const double dateWrap = 140;
  static const double locationWrap = 340;
  static const double creditNoteNumberWrap = 180;
  static const double referenceNumberWrap = 180;
  static const double customerNameWrap = 240;
  static const double invoiceNumberWrap = 180;
  static const double statusWrap = 130;
  static const double amountWrap = 140;
  static const double balanceWrap = 140;
  static const double issueDateWrap = 160;
  static const double salesPersonWrap = 200;

  static Map<String, double> defaults({required bool clip}) => {
    'date': clip ? date : dateWrap,
    'location': clip ? location : locationWrap,
    'creditNoteNumber': clip ? creditNoteNumber : creditNoteNumberWrap,
    'referenceNumber': clip ? referenceNumber : referenceNumberWrap,
    'customerName': clip ? customerName : customerNameWrap,
    'invoiceNumber': clip ? invoiceNumber : invoiceNumberWrap,
    'status': clip ? status : statusWrap,
    'amount': clip ? amount : amountWrap,
    'balance': clip ? balance : balanceWrap,
    'issueDate': clip ? issueDate : issueDateWrap,
    'salesPerson': clip ? salesPerson : salesPersonWrap,
  };

  static double forId(String id, {bool clip = true}) {
    switch (id) {
      case 'date':
        return clip ? date : dateWrap;
      case 'location':
        return clip ? location : locationWrap;
      case 'creditNoteNumber':
        return clip ? creditNoteNumber : creditNoteNumberWrap;
      case 'referenceNumber':
        return clip ? referenceNumber : referenceNumberWrap;
      case 'customerName':
        return clip ? customerName : customerNameWrap;
      case 'invoiceNumber':
        return clip ? invoiceNumber : invoiceNumberWrap;
      case 'status':
        return clip ? status : statusWrap;
      case 'amount':
        return clip ? amount : amountWrap;
      case 'balance':
        return clip ? balance : balanceWrap;
      case 'issueDate':
        return clip ? issueDate : issueDateWrap;
      case 'salesPerson':
        return clip ? salesPerson : salesPersonWrap;
      default:
        return clip ? 140 : 180;
    }
  }
}

class _CnHeaderCell extends StatefulWidget {
  const _CnHeaderCell({
    required this.width,
    required this.label,
    this.sorted = false,
    this.sortAscending = false,
    this.clipText = true,
    this.onResize,
    this.onSort,
  });
  final double width;
  final String label;
  final bool sorted;
  final bool sortAscending;
  final bool clipText;
  final void Function(double delta)? onResize;
  final VoidCallback? onSort;

  @override
  State<_CnHeaderCell> createState() => _CnHeaderCellState();
}

class _CnHeaderCellState extends State<_CnHeaderCell> {
  bool _resizeHovered = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (widget.sorted) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onSort,
                    child: Icon(
                      widget.sortAscending
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 14,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Resize handle on right edge
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              onEnter: (_) => setState(() => _resizeHovered = true),
              onExit: (_) => setState(() => _resizeHovered = false),
              child: GestureDetector(
                onHorizontalDragUpdate: (d) =>
                    widget.onResize?.call(d.delta.dx),
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: _resizeHovered
                            ? AppTheme.primaryBlue
                            : AppTheme.borderLight,
                        width: 2,
                      ),
                    ),
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

class _CnBodyCell extends StatelessWidget {
  const _CnBodyCell({
    required this.width,
    required this.child,
    this.clip = true,
  });
  final double width;
  final Widget child;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    if (clip) {
      // Fixed-height row — constrain to one line
      return SizedBox(width: width, child: child);
    }
    // Wrap mode — allow text to grow vertically, pad top to optically centre
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: SizedBox(width: width, child: child),
    );
  }
}

class _CnBodyText extends StatelessWidget {
  const _CnBodyText(
    this.text, {
    this.color = AppTheme.textPrimary,
    this.fontWeight = FontWeight.w400,
    this.clip = true,
  });
  final String text;
  final Color color;
  final FontWeight fontWeight;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: clip ? 1 : null,
      overflow: clip ? TextOverflow.ellipsis : TextOverflow.visible,
      style: TextStyle(fontSize: 13, fontWeight: fontWeight, color: color),
    );
  }
}

// ── Journal ───────────────────────────────────────────────────────────────────

// ignore: unused_element
class _CnJournalEntry {
  const _CnJournalEntry({
    required this.account,
    // ignore: unused_element_parameter
    this.debit = 0,
    // ignore: unused_element_parameter
    this.credit = 0,
  });

  final String account;
  final double debit;
  final double credit;
}

/// Double-entry view of the persisted Credit Note journal, shown at the foot
/// of the detail pane. The backend is the accounting source of truth.
class _CnJournalSection extends ConsumerWidget {
  const _CnJournalSection({required this.row});

  final _CreditNoteRow row;

  static const double _amountColumnWidth = 120;
  static const double _locationColumnWidth = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(creditNoteJournalProvider(row.id));

    return journalAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24.0),
        child: ZTableSkeleton(rows: 3, columns: 4),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Failed to load journal: $e',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (journalData) {
        double parseDouble(dynamic v) =>
            v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
        final fmt = NumberFormat('#,##,##0.00', 'en_IN');
        final entries = (journalData['entries'] as List<dynamic>?) ?? [];
        final totalDebit = parseDouble(journalData['totalDebit']);
        final totalCredit = parseDouble(journalData['totalCredit']);

        if (entries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No journal entries are available for this credit note.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Journal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            Container(height: 2, width: 64, color: AppTheme.primaryBlue),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Amount is displayed in your base currency',
                  style: TextStyle(fontSize: 13, color: Color(0xFF444444)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'INR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Table header
            Container(
              color: AppTheme.bgLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: const Row(
                children: [
                  Expanded(child: _CnJournalHeaderCell('ACCOUNT')),
                  SizedBox(
                    width: _locationColumnWidth,
                    child: _CnJournalHeaderCell('WAREHOUSE'),
                  ),
                  SizedBox(
                    width: _amountColumnWidth,
                    child: _CnJournalHeaderCell('DEBIT', alignRight: true),
                  ),
                  SizedBox(
                    width: _amountColumnWidth,
                    child: _CnJournalHeaderCell('CREDIT', alignRight: true),
                  ),
                ],
              ),
            ),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CnJournalCell(entry['account']?.toString() ?? ''),
                    ),
                    SizedBox(
                      width: _locationColumnWidth,
                      child: _CnJournalCell(
                        entry['warehouse']?.toString() ?? '-',
                      ),
                    ),
                    SizedBox(
                      width: _amountColumnWidth,
                      child: _CnJournalCell(
                        fmt.format(parseDouble(entry['debit'])),
                        alignRight: true,
                      ),
                    ),
                    SizedBox(
                      width: _amountColumnWidth,
                      child: _CnJournalCell(
                        fmt.format(parseDouble(entry['credit'])),
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  const Expanded(child: SizedBox()),
                  const SizedBox(width: _locationColumnWidth),
                  SizedBox(
                    width: _amountColumnWidth,
                    child: _CnJournalCell(
                      fmt.format(totalDebit),
                      alignRight: true,
                      bold: true,
                    ),
                  ),
                  SizedBox(
                    width: _amountColumnWidth,
                    child: _CnJournalCell(
                      fmt.format(totalCredit),
                      alignRight: true,
                      bold: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CnJournalHeaderCell extends StatelessWidget {
  const _CnJournalHeaderCell(this.label, {this.alignRight = false});

  final String label;
  final bool alignRight;

  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: alignRight ? TextAlign.right : TextAlign.left,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
      letterSpacing: 0.3,
    ),
  );
}

class _CnJournalCell extends StatelessWidget {
  const _CnJournalCell(
    this.value, {
    this.alignRight = false,
    this.bold = false,
  });

  final String value;
  final bool alignRight;
  final bool bold;

  @override
  Widget build(BuildContext context) => Text(
    value,
    textAlign: alignRight ? TextAlign.right : TextAlign.left,
    style: TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: const Color(0xFF111111),
    ),
  );
}

class _CreditNoteMessageSidebar extends StatelessWidget {
  const _CreditNoteMessageSidebar({required this.row, required this.onClose});

  final _CreditNoteRow? row;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final note = row;
    final description = note == null
        ? 'Credit note created'
        : note.invoiceNumber == '-'
        ? 'Credit note ${note.creditNoteNumber} created'
        : 'Credit note created for ${note.amount} from invoice ${note.invoiceNumber}';

    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(left: BorderSide(color: AppTheme.borderLight)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 82,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Comments & History',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onClose,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            LucideIcons.x,
                            size: 20,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 12, 26, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderLight),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: const BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: const Row(
                                children: [
                                  Text(
                                    'B',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(width: 24),
                                  Text(
                                    'I',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(width: 24),
                                  Text(
                                    'U',
                                    style: TextStyle(
                                      fontSize: 17,
                                      decoration: TextDecoration.underline,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 56),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                            SizedBox(
                              height: 58,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 14),
                                  child: OutlinedButton(
                                    onPressed: null,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(114, 33),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      side: const BorderSide(
                                        color: AppTheme.borderLight,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: const Text('Add Comment'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Text(
                            'ALL COMMENTS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.backgroundColor,
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: const Icon(
                              LucideIcons.fileText,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'zabnixprivatelimited',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Credit note created',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    description,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.45,
                                      color: AppTheme.textPrimary,
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditNoteRow {
  _CreditNoteRow({
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
    required this.model,
    this.grandTotal = 0,
    this.subTotal = 0,
    this.taxTotal = 0,
  });

  final String id;
  final String date;
  final String location;
  final String creditNoteNumber;
  final String referenceNumber;
  final String customerName;
  final String invoiceNumber;
  String status;
  final String amount;
  final String balance;
  final String issueDate;
  final String salesPerson;

  /// Raw figures behind [amount], kept unformatted so the journal can post
  /// them against accounts.
  final double grandTotal;
  final double subTotal;
  final double taxTotal;
  final CreditNoteModel model;
}

// ─── Compact list item (split-panel left) ────────────────────────────────────

class _CnCompactItem extends StatefulWidget {
  const _CnCompactItem({
    required this.row,
    required this.selected,
    required this.checked,
    required this.onCheckChanged,
    required this.onTap,
  });
  final _CreditNoteRow row;
  final bool selected;
  final bool checked;
  final ValueChanged<bool?> onCheckChanged;
  final VoidCallback onTap;

  @override
  State<_CnCompactItem> createState() => _CnCompactItemState();
}

class _CnCompactItemState extends State<_CnCompactItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppTheme.primaryBlue.withValues(alpha: 0.06)
        : _hovered
        ? AppTheme.primaryBlue.withValues(alpha: 0.04)
        : AppTheme.backgroundColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 80,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.row.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '₹${widget.row.amount}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.row.creditNoteNumber} • ${widget.row.date}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.row.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _CnTableRow._statusColor(widget.row.status),
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

// ─── Detail panel action button ───────────────────────────────────────────────

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
      cursor: SystemMouseCursors.click,
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
    // 16px tall with 4px gutters, matching the sales return action bar so the
    // hover chip clears the rule on both sides.
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppTheme.borderLight,
    );
  }
}

class _DetailActionBtn extends StatefulWidget {
  const _DetailActionBtn({
    this.icon,
    this.label,
    this.trailingIcon,
    required this.onTap,
  });
  final IconData? icon;
  final String? label;
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        // Matches the sales return overview action bar: the button lifts onto a
        // white chip with a light border on hover, rather than tinting blue.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white : Colors.transparent,
            border: Border.all(
              color: _hovered ? AppTheme.borderColor : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 14, color: AppTheme.textSecondary),
              if (widget.icon != null && widget.label != null)
                const SizedBox(width: 6),
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.trailingIcon,
                  size: 12,
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

// ─── Credit applied invoices panel ───────────────────────────────────────────

/// Collapsible summary of the invoices this credit note has been applied to.
///
/// Appears above the document preview once credit has been applied, and is the
/// counterpart to the "Apply to Invoices" action disappearing from the bar.
class _CnAppliedInvoicesPanel extends StatefulWidget {
  const _CnAppliedInvoicesPanel({
    required this.applied,
    required this.onRemove,
  });

  final List<_CnAppliedInvoice> applied;
  final ValueChanged<_CnAppliedInvoice> onRemove;

  @override
  State<_CnAppliedInvoicesPanel> createState() =>
      _CnAppliedInvoicesPanelState();
}

class _CnAppliedInvoicesPanelState extends State<_CnAppliedInvoicesPanel> {
  bool _expanded = true;
  final _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    'Credit Applied Invoices',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.applied.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text('Date', style: _kAppliedHeaderStyle),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text('Invoice Number', style: _kAppliedHeaderStyle),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text('Amount Credited', style: _kAppliedHeaderStyle),
                  ),
                  SizedBox(width: 32),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            for (final a in widget.applied) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(a.date, style: _kAppliedCellStyle),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        a.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        _money.format(a.amountCredited),
                        style: _kAppliedCellStyle,
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: _CnAppliedDeleteButton(
                        onTap: () => widget.onRemove(a),
                      ),
                    ),
                  ],
                ),
              ),
              if (a != widget.applied.last)
                const Divider(height: 1, color: AppTheme.borderLight),
            ],
          ],
        ],
      ),
    );
  }
}

const TextStyle _kAppliedHeaderStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: AppTheme.textSecondary,
);

const TextStyle _kAppliedCellStyle = TextStyle(
  fontSize: 13,
  color: AppTheme.textPrimary,
);

class _CnAppliedDeleteButton extends StatefulWidget {
  const _CnAppliedDeleteButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CnAppliedDeleteButton> createState() => _CnAppliedDeleteButtonState();
}

class _CnAppliedDeleteButtonState extends State<_CnAppliedDeleteButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Icon(
          LucideIcons.trash2,
          size: 15,
          color: _hovered ? AppTheme.errorRed : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ─── Credit note document preview ────────────────────────────────────────────

class _CnDocumentPreview extends ConsumerWidget {
  const _CnDocumentPreview({required this.row});
  final _CreditNoteRow row;

  static const Color _border = Color(0xFFCCCCCC);
  static const Color _outerBorder = Color(0xFFBBBBBB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgSettings = ref.watch(orgSettingsProvider).valueOrNull;
    // The ribbon belongs on the paper's corner, inside the outer frame's
    // padding — not on the frame itself, which would float it 60px away from
    // the document. ClipRect wraps the paper so the fold clips at its corner
    // with no cut-off tail, matching the sales return preview.
    return Container(
      // No border here — the paper below carries the only frame. The padding
      // stays as the margin the corner ribbon sits within.
      color: Colors.white,
      padding: const EdgeInsets.all(60),
      child: ClipRect(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _outerBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  // Use a plain Row — no IntrinsicHeight so Expanded works
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: _border, width: 0.8),
                      ),
                    ),
                    // Extra top padding so the header sits below the corner ribbon
                    // instead of under it — the same 80px allowance the sales
                    // return preview uses.
                    padding: const EdgeInsets.fromLTRB(12, 80, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 200x80, the same size the sales return preview uses.
                        // This one had been shrunk to 110x44.
                        _OrgLogoBox(
                          orgSettings: orgSettings,
                          width: 200,
                          height: 80,
                        ),
                        const SizedBox(width: 12),
                        // Company details — Expanded takes all remaining space
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'ZABNIX PRIVATE LIMITED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111111),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'PERINTHALMANNA',
                                style: TextStyle(fontSize: 10),
                              ),
                              Text(
                                'MALAPPURAM Kerala 679322',
                                style: TextStyle(fontSize: 10),
                              ),
                              Text('India', style: TextStyle(fontSize: 10)),
                              SizedBox(height: 3),
                              Text(
                                'GSTIN 32AACCZ4912F1ZL',
                                style: TextStyle(fontSize: 10),
                              ),
                              Text(
                                '8086355500',
                                style: TextStyle(fontSize: 10),
                              ),
                              Text(
                                'zabnixprivatelimited@gmail.com',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // CREDIT NOTE — fixed width so it never wraps regardless of screen size
                        const SizedBox(
                          width: 140,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              'CREDIT NOTE',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Details table ───────────────────────────────────────
                  Table(
                    border: TableBorder(
                      top: const BorderSide(color: _border, width: 0.8),
                      bottom: const BorderSide(color: _border, width: 0.8),
                      left: const BorderSide(color: _border, width: 0.8),
                      right: const BorderSide(color: _border, width: 0.8),
                      verticalInside: const BorderSide(
                        color: _border,
                        width: 0.8,
                      ),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _tableRow(
                        '#',
                        row.creditNoteNumber,
                        'Place Of Supply',
                        'Kerala (32)',
                      ),
                      _tableRow('Credit Date', row.date, '', ''),
                      _tableRow('Invoice#', row.invoiceNumber, '', ''),
                      _tableRow('Invoice Date', row.issueDate, '', ''),
                    ],
                  ),

                  // ── Bill To ────────────────────────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: _border, width: 0.8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: const Color(0xFFF5F5F5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: const Text(
                            'Bill To',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.customerName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 3),
                              if (row.model.billingAddressStreet?.isNotEmpty ??
                                  false)
                                Text(
                                  row.model.billingAddressStreet!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              if (row.model.billingAddressPlace?.isNotEmpty ??
                                  false)
                                Text(
                                  row.model.billingAddressPlace!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              if (row.model.billingAddressCity?.isNotEmpty ??
                                  false)
                                Text(
                                  row.model.billingAddressCity!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              if (row.model.billingAddressState?.isNotEmpty ??
                                  false)
                                Text(
                                  row.model.billingAddressState!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              if (row.model.billingAddressZip?.isNotEmpty ??
                                  false)
                                Text(
                                  row.model.billingAddressZip!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              if (row.model.billingAddressCountry?.isNotEmpty ??
                                  false)
                                Text(
                                  row.model.billingAddressCountry!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              const SizedBox(height: 3),
                              if (row.model.gstin?.isNotEmpty ?? false)
                                Text(
                                  'GSTIN ${row.model.gstin}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Items Table ─────────────────────────────────────────
                  Table(
                    border: const TableBorder(
                      top: BorderSide(color: _border, width: 0.8),
                      bottom: BorderSide(color: _border, width: 0.8),
                      verticalInside: BorderSide(color: _border, width: 0.8),
                      horizontalInside: BorderSide(color: _border, width: 0.8),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(0.8),
                      1: FlexColumnWidth(4),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(1.5),
                      4: FlexColumnWidth(1.5),
                      5: FlexColumnWidth(1.5),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5),
                        ),
                        children: [
                          _tableHeaderCell('#', align: TextAlign.center),
                          _tableHeaderCell('Item & Description'),
                          _tableHeaderCell('HSN/SAC'),
                          _tableHeaderCell('Qty', align: TextAlign.right),
                          _tableHeaderCell('Rate', align: TextAlign.right),
                          _tableHeaderCell('Amount', align: TextAlign.right),
                        ],
                      ),
                      for (int i = 0; i < row.model.items.length; i++)
                        TableRow(
                          children: [
                            _tableDataCell('${i + 1}', align: TextAlign.center),
                            _tableDataCell(
                              row.model.items[i].productName ?? '',
                            ),
                            _tableDataCell(row.model.items[i].hsnSacCode ?? ''),
                            _tableDataCell(
                              row.model.items[i].formattedQty,
                              align: TextAlign.right,
                            ),
                            _tableDataCell(
                              row.model.items[i].formattedRate,
                              align: TextAlign.right,
                            ),
                            _tableDataCell(
                              row.model.items[i].formattedLineTotal,
                              align: TextAlign.right,
                            ),
                          ],
                        ),
                    ],
                  ),

                  // ── Footer (Total and Words) ────────────────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left side (Aligns exactly with first 3 columns: 0.8 + 4 + 2 = 6.8)
                        Expanded(
                          flex: 68,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Total In Words',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF444444),
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Vertical divider exactly aligned with the table column
                        Container(width: 0.8, color: _border),
                        // Right side (Aligns exactly with last 3 columns: 1.5 + 1.5 + 1.5 = 4.5)
                        Expanded(
                          flex: 45,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  10,
                                  10,
                                  8,
                                ),
                                child: Column(
                                  children: [
                                    _summaryRow(
                                      'Sub Total',
                                      NumberFormat(
                                        '#,##0.00',
                                      ).format(row.model.subTotal),
                                    ),
                                    _summaryRow(
                                      'Tax',
                                      NumberFormat(
                                        '#,##0.00',
                                      ).format(row.model.taxTotal),
                                    ),
                                    const SizedBox(height: 8),
                                    _summaryRow(
                                      'Total',
                                      '₹${NumberFormat('#,##0.00').format(row.model.grandTotal)}',
                                      isBold: true,
                                    ),
                                    _summaryRow(
                                      'Credits Remaining',
                                      '₹${NumberFormat('#,##0.00').format(row.model.grandTotal)}',
                                      isBold: true,
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 0.8, color: _border),
                              Expanded(
                                child: Container(
                                  alignment: Alignment.bottomCenter,
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: const Text(
                                    'Authorized Signature',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF111111),
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

            // ── Corner status ribbon ────────────────────────────────────
            // Scaled down from the 110 default to stay proportional to the
            // capped paper width.
            Positioned(
              top: 0,
              left: 0,
              child: PdfCornerRibbon(
                label: row.status,
                color: _CnTableRow._statusColor(row.status),
                size: 88,
                // Band only — no triangular corner fold.
                showFold: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeaderCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
      ),
    );
  }

  Widget _tableDataCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(fontSize: 11, color: Color(0xFF111111)),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: const Color(0xFF111111),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: const Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(String l1, String v1, String l2, String v2) {
    const cellStyle = TextStyle(fontSize: 10, color: Color(0xFF444444));
    const valStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Color(0xFF111111),
    );

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 90, child: Text(l1, style: cellStyle)),
              Expanded(child: Text(v1.isEmpty ? '' : ': $v1', style: valStyle)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (l2.isNotEmpty)
                SizedBox(width: 120, child: Text(l2, style: cellStyle)),
              if (v2.isNotEmpty)
                Expanded(child: Text(': $v2', style: valStyle)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Apply to Invoices Dialog ──────────────────────────────────────────────────

/// One invoice a credit note has been applied to, as shown in the
/// "Credit Applied Invoices" panel after saving.
class _CnAppliedInvoice {
  const _CnAppliedInvoice({
    required this.date,
    required this.invoiceNumber,
    required this.amountCredited,
  });

  final String date;
  final String invoiceNumber;
  final double amountCredited;
}

class _AtiInvoiceRow {
  final String invoiceId;
  final String invoiceNumber;
  final String invoiceDate;
  final String location;
  final double invoiceAmount;
  final double invoiceBalance;
  final String creditsAppliedOn;
  final TextEditingController creditsToApplyController;

  _AtiInvoiceRow({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.location,
    required this.invoiceAmount,
    required this.invoiceBalance,
    required this.creditsAppliedOn,
    String initialCredits = '0',
  }) : creditsToApplyController = TextEditingController(text: initialCredits);

  void dispose() => creditsToApplyController.dispose();
}

class _ApplyToInvoicesDialog extends StatefulWidget {
  final _CreditNoteRow creditNote;
  final CreditNoteRepository repository;

  const _ApplyToInvoicesDialog({
    required this.creditNote,
    required this.repository,
  });

  @override
  State<_ApplyToInvoicesDialog> createState() => _ApplyToInvoicesDialogState();
}

class _ApplyToInvoicesDialogState extends State<_ApplyToInvoicesDialog> {
  bool _setAppliedOnDate = true;
  final List<_AtiInvoiceRow> _invoices = [];
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  double _availableCredit = 0;
  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _dateFmt = DateFormat('dd-MM-yyyy');

  double get _availableCredits => _availableCredit;

  double get _creditsApplied => _invoices.fold(
    0.0,
    (sum, inv) =>
        sum +
        (double.tryParse(
              inv.creditsToApplyController.text.replaceAll(',', ''),
            ) ??
            0.0),
  );

  double get _remainingCredits => _availableCredits - _creditsApplied;

  @override
  void initState() {
    super.initState();
    _loadEligibleInvoices();
  }

  Future<void> _loadEligibleInvoices() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final data = await widget.repository.getEligibleInvoices(
        widget.creditNote.id,
      );
      if (!mounted) {
        return;
      }
      for (final invoice in _invoices) {
        invoice.dispose();
      }
      _invoices
        ..clear()
        ..addAll(
          data.invoices.map(
            (invoice) => _AtiInvoiceRow(
              invoiceId: invoice.id,
              invoiceNumber: invoice.invoiceNumber,
              invoiceDate: _formatApiDate(invoice.invoiceDate),
              location: '-',
              invoiceAmount: invoice.invoiceAmount,
              invoiceBalance: invoice.outstandingAmount,
              creditsAppliedOn: _dateFmt.format(DateTime.now()),
            ),
          ),
        );
      for (final invoice in _invoices) {
        invoice.creditsToApplyController.addListener(_onAmountChanged);
      }
      setState(() {
        _availableCredit = data.remainingCredit;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = 'Unable to load outstanding invoices. Please try again.';
      });
    }
  }

  String _formatApiDate(String? value) {
    final date = value == null ? null : DateTime.tryParse(value);
    return date == null ? (value ?? '-') : _dateFmt.format(date);
  }

  void _onAmountChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveApplications() async {
    final allocations = [
      for (final invoice in _invoices)
        if ((double.tryParse(
                  invoice.creditsToApplyController.text.replaceAll(',', ''),
                ) ??
                0) >
            0)
          CreditNoteInvoiceAllocation(
            invoiceId: invoice.invoiceId,
            amount:
                double.tryParse(
                  invoice.creditsToApplyController.text.replaceAll(',', ''),
                ) ??
                0,
          ),
    ];
    if (allocations.isEmpty) {
      return;
    }
    if (_creditsApplied > _availableCredits + 0.005) {
      ZerpaiToast.error(
        context,
        'Credits applied cannot exceed the available credit note balance.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await widget.repository.applyToInvoices(
        widget.creditNote.id,
        allocations,
        appliedOn: _setAppliedOnDate
            ? DateTime.now().toIso8601String().split('T').first
            : null,
      );
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _loadError =
            'Unable to apply credits. Check the invoice balances and try again.';
      });
    }
  }

  @override
  void dispose() {
    for (final inv in _invoices) {
      inv.dispose();
    }
    super.dispose();
  }

  void _payInFull(_AtiInvoiceRow inv) {
    final alreadyApplied =
        double.tryParse(
          inv.creditsToApplyController.text.replaceAll(',', ''),
        ) ??
        0.0;
    final maxApplicable = _remainingCredits + alreadyApplied;
    final amount = inv.invoiceBalance.clamp(0.0, maxApplicable);
    inv.creditsToApplyController.text = _fmt.format(amount);
    inv.creditsToApplyController.selection = TextSelection.collapsed(
      offset: inv.creditsToApplyController.text.length,
    );
  }

  void _applyAvailableCreditsFifo() {
    var remainingCredit = _availableCredits;
    for (final invoice in _invoices) {
      final amount = remainingCredit <= 0
          ? 0.0
          : invoice.invoiceBalance.clamp(0.0, remainingCredit).toDouble();
      invoice.creditsToApplyController.text = _fmt.format(amount);
      invoice.creditsToApplyController.selection = TextSelection.collapsed(
        offset: invoice.creditsToApplyController.text.length,
      );
      remainingCredit -= amount;
    }
  }

  void _clearAppliedAmount() {
    for (final inv in _invoices) {
      inv.creditsToApplyController.text = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      // Flush to the top of the viewport — no inset above the card.
      insetPadding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, minWidth: 700),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title bar ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Apply Credits to Invoices',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: AppTheme.errorRed,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),

              // ── Info cards ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    // Credit Note# card (orange)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.warningOrange.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              LucideIcons.fileMinus,
                              size: 18,
                              color: AppTheme.warningOrange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Credit Note#',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.creditNote.creditNoteNumber,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Available Credits card (blue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              LucideIcons.wallet,
                              size: 18,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Available Credits',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${_fmt.format(_availableCredits)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  MouseRegion(
                                    cursor: _loading
                                        ? SystemMouseCursors.basic
                                        : SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _loading
                                          ? null
                                          : _applyAvailableCreditsFifo,
                                      child: const Text(
                                        'Apply Credits to Invoices',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryBlue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // "Unpaid Invoices" title + Set Applied on Date toggle
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Unpaid Invoices',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Set Applied on Date',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ZTooltip(
                          message:
                              'When enabled, the date on which credits are applied will be recorded.',
                        ),
                        const SizedBox(width: 6),
                        Switch(
                          value: _setAppliedOnDate,
                          onChanged: (v) =>
                              setState(() => _setAppliedOnDate = v),
                          activeThumbColor: AppTheme.backgroundColor,
                          activeTrackColor: AppTheme.successGreen,
                          inactiveThumbColor: AppTheme.backgroundColor,
                          inactiveTrackColor: AppTheme.borderLight,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    // "Clear Applied Amount" link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _clearAppliedAmount,
                        child: const Text(
                          'Clear Applied Amount',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Table grid ──
                    if (_loading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: TableSkeleton(
                          rows: 4,
                          columns: _setAppliedOnDate ? 6 : 5,
                        ),
                      )
                    else if (_loadError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: TextButton(
                            onPressed: _loadEligibleInvoices,
                            child: Text(_loadError!),
                          ),
                        ),
                      )
                    else if (_invoices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text(
                            'No outstanding invoices are available for this customer.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Table(
                          border: TableBorder.all(
                            color: AppTheme.borderLight,
                            width: 1,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          columnWidths: _setAppliedOnDate
                              ? const {
                                  0: FlexColumnWidth(1.8), // INVOICE NUMBER
                                  1: FlexColumnWidth(1.4), // INVOICE DATE
                                  2: FlexColumnWidth(1.6), // INVOICE AMOUNT
                                  3: FlexColumnWidth(1.6), // INVOICE BALANCE
                                  4: FlexColumnWidth(1.6), // CREDITS APPLIED ON
                                  5: FlexColumnWidth(2.0), // CREDITS TO APPLY
                                }
                              : const {
                                  0: FlexColumnWidth(1.8), // INVOICE NUMBER
                                  1: FlexColumnWidth(1.4), // INVOICE DATE
                                  2: FlexColumnWidth(1.6), // INVOICE AMOUNT
                                  3: FlexColumnWidth(1.6), // INVOICE BALANCE
                                  4: FlexColumnWidth(2.0), // CREDITS TO APPLY
                                },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            // Header row
                            TableRow(
                              decoration: const BoxDecoration(
                                color: AppTheme.bgLight,
                              ),
                              children: [
                                _AtiCell(
                                  child: _AtiColHeader('INVOICE NUMBER'),
                                ),
                                _AtiCell(child: _AtiColHeader('INVOICE DATE')),
                                _AtiCell(
                                  child: _AtiColHeader(
                                    'INVOICE AMOUNT',
                                    align: TextAlign.right,
                                  ),
                                ),
                                _AtiCell(
                                  child: _AtiColHeader(
                                    'INVOICE BALANCE',
                                    align: TextAlign.right,
                                  ),
                                ),
                                if (_setAppliedOnDate)
                                  _AtiCell(
                                    child: _AtiColHeader('CREDITS APPLIED ON'),
                                  ),
                                _AtiCell(
                                  child: _AtiColHeader(
                                    'CREDITS TO APPLY',
                                    align: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            // Data rows
                            ...List.generate(_invoices.length, (i) {
                              final inv = _invoices[i];
                              return TableRow(
                                decoration: const BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                ),
                                children: [
                                  _AtiCell(
                                    child: Text(
                                      inv.invoiceNumber,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _AtiCell(
                                    child: Text(
                                      inv.invoiceDate,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _AtiCell(
                                    child: Text(
                                      '₹${_fmt.format(inv.invoiceAmount)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _AtiCell(
                                    child: Text(
                                      '₹${_fmt.format(inv.invoiceBalance)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (_setAppliedOnDate)
                                    _AtiCell(
                                      child: Text(
                                        inv.creditsAppliedOn,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  // Credits to Apply — editable + Pay in Full link
                                  _AtiCell(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller:
                                              inv.creditsToApplyController,
                                          textAlign: TextAlign.right,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 8,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              borderSide: const BorderSide(
                                                color: AppTheme.borderLight,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              borderSide: const BorderSide(
                                                color: AppTheme.borderLight,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              borderSide: const BorderSide(
                                                color: AppTheme.primaryBlue,
                                                width: 1.5,
                                              ),
                                            ),
                                            isDense: true,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () => _payInFull(inv),
                                            child: const Text(
                                              'Pay in Full',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.primaryBlue,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ── Summary ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _AtiSummaryRow(
                            label: 'Credits Applied:',
                            value: _fmt.format(_creditsApplied),
                          ),
                          const SizedBox(height: 6),
                          _AtiSummaryRow(
                            label: 'Remaining Credits:',
                            value: _fmt.format(_remainingCredits),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppTheme.borderLight),

              // ── Footer ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: _saving || _creditsApplied <= 0
                          ? null
                          : _saveApplications,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: AppTheme.backgroundColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.borderLight),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Cancel'),
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

class _AtiColHeader extends StatelessWidget {
  final String label;
  final TextAlign align;

  const _AtiColHeader(this.label, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: align,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _AtiCell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _AtiCell({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}

class _AtiSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _AtiSummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 100,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared org logo widget ────────────────────────────────────────────────────

class _OrgLogoBox extends StatelessWidget {
  const _OrgLogoBox({
    required this.orgSettings,
    this.width = 160,
    this.height = 64,
  });

  final OrgSettings? orgSettings;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        'LOGO',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── List-header "more" menu (mirrors sales return overview) ───────────────────

class _CnListMoreMenu extends StatefulWidget {
  const _CnListMoreMenu({
    required this.onManageCustomFields,
    required this.onRefreshList,
  });

  final VoidCallback onManageCustomFields;
  final VoidCallback onRefreshList;

  @override
  State<_CnListMoreMenu> createState() => _CnListMoreMenuState();
}

class _CnListMoreMenuState extends State<_CnListMoreMenu> {
  bool _exportItemHovered = false;
  bool _exportSubmenuHovered = false;
  bool _customFieldsHovered = false;
  bool _refreshHovered = false;

  bool get _exportSubmenuVisible => _exportItemHovered || _exportSubmenuHovered;

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: AppTheme.borderLight),
    boxShadow: [
      BoxShadow(
        color: AppTheme.textPrimary.withValues(alpha: 0.12),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );

  Widget _menuItem({
    required String label,
    required IconData icon,
    required bool hovered,
    required bool active,
    bool hasChevron = false,
    VoidCallback? onTap,
  }) {
    final showActive = active || hovered;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: showActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: showActive ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: showActive ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (hasChevron)
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: showActive ? Colors.white : AppTheme.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main menu card. It comes first so the submenus below open to its
          // RIGHT; the dialog anchors this card by its left edge so it stays
          // put under the button whether or not a submenu is showing.
          Container(
            width: 200,
            decoration: _cardDecoration,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _exportItemHovered = true),
                  onExit: (_) => setState(() => _exportItemHovered = false),
                  child: _menuItem(
                    label: 'Export',
                    icon: LucideIcons.upload,
                    hovered: _exportItemHovered,
                    active: _exportSubmenuVisible,
                    hasChevron: true,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _customFieldsHovered = true),
                  onExit: (_) => setState(() => _customFieldsHovered = false),
                  child: _menuItem(
                    label: 'Manage Custom Fields',
                    icon: LucideIcons.columns,
                    hovered: _customFieldsHovered,
                    active: false,
                    onTap: widget.onManageCustomFields,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _refreshHovered = true),
                  onExit: (_) => setState(() => _refreshHovered = false),
                  child: _menuItem(
                    label: 'Refresh List',
                    icon: LucideIcons.refreshCw,
                    hovered: _refreshHovered,
                    active: false,
                    onTap: widget.onRefreshList,
                  ),
                ),
              ],
            ),
          ),
          // Export submenu opens to the right of the main card.
          if (_exportSubmenuVisible)
            Container(
              width: 184,
              margin: const EdgeInsets.only(top: 40),
              child: MouseRegion(
                onEnter: (_) => setState(() => _exportSubmenuHovered = true),
                onExit: (_) => setState(() => _exportSubmenuHovered = false),
                child: Container(
                  decoration: _cardDecoration,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CnSubmenuItem(
                        label: 'Export Credit Notes',
                        onTap: () {
                          Navigator.of(context).pop();
                          ZerpaiToast.success(
                            context,
                            'Exporting Credit Notes...',
                          );
                        },
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
}

class _CnSubmenuItem extends StatefulWidget {
  const _CnSubmenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_CnSubmenuItem> createState() => _CnSubmenuItemState();
}

class _CnSubmenuItemState extends State<_CnSubmenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _hovered ? Colors.white : AppTheme.textPrimary,
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

