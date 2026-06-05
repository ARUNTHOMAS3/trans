import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/column_customizer.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/credit_note_bulk_update_dialog.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class CreditNotesOverviewPage extends StatefulWidget {
  const CreditNotesOverviewPage({super.key});

  @override
  State<CreditNotesOverviewPage> createState() =>
      _CreditNotesOverviewPageState();
}

class _CreditNotesOverviewPageState extends State<CreditNotesOverviewPage> {
  late Map<String, double> _columnWidths;

  double get _tableWidth {
    final visibleIds = _visibleColumns.map((c) => c.id).toSet();
    final colSum = _columnWidths.entries
        .where((e) => visibleIds.contains(e.key))
        .fold(0.0, (sum, e) => sum + e.value);
    return colSum + 92; // 16(pad) + 28(icon) + 32(checkbox) + 16(pad)
  }

  void _resizeColumn(String id, double delta) {
    setState(() {
      final current = _columnWidths[id] ?? 100;
      _columnWidths[id] = (current + delta).clamp(60.0, 600.0);
    });
  }

  final _rows = <_CreditNoteRow>[
    _CreditNoteRow(
      date: '15-05-2026',
      location: 'ZABNIX PRIVATE LIMITED',
      creditNoteNumber: 'CN-00011',
      referenceNumber: '-',
      customerName: 'CUS-1',
      invoiceNumber: 'INV-000082',
      status: 'OPEN',
      amount: '504.00',
      balance: '0.00',
      issueDate: '15-05-2026',
      salesPerson: 'ALTHAF',
    ),
    _CreditNoteRow(
      date: '12-05-2026',
      location: 'ZABNIX PRIVATE LIMITED',
      creditNoteNumber: 'CN-00010',
      referenceNumber: 'REF-0042',
      customerName: 'CUS-3',
      invoiceNumber: 'INV-000079',
      status: 'CLOSED',
      amount: '1,250.00',
      balance: '0.00',
      issueDate: '12-05-2026',
      salesPerson: 'MUHAMMED',
    ),
    _CreditNoteRow(
      date: '10-05-2026',
      location: 'ZABNIX PRIVATE LIMITED',
      creditNoteNumber: 'CN-00009',
      referenceNumber: 'REF-0039',
      customerName: 'CUS-7',
      invoiceNumber: 'INV-000075',
      status: 'DRAFT',
      amount: '320.00',
      balance: '320.00',
      issueDate: '10-05-2026',
      salesPerson: 'ALTHAF',
    ),
    _CreditNoteRow(
      date: '08-05-2026',
      location: 'ZABNIX PRIVATE LIMITED',
      creditNoteNumber: 'CN-00008',
      referenceNumber: '-',
      customerName: 'CUS-12',
      invoiceNumber: 'INV-000071',
      status: 'VOID',
      amount: '780.50',
      balance: '0.00',
      issueDate: '08-05-2026',
      salesPerson: 'RASHID',
    ),
    _CreditNoteRow(
      date: '05-05-2026',
      location: 'ZABNIX PRIVATE LIMITED',
      creditNoteNumber: 'CN-00007',
      referenceNumber: 'REF-0035',
      customerName: 'CUS-5',
      invoiceNumber: 'INV-000068',
      status: 'PENDING APPROVAL',
      amount: '2,100.00',
      balance: '2,100.00',
      issueDate: '05-05-2026',
      salesPerson: 'MUHAMMED',
    ),
    _CreditNoteRow(
      date: '02-05-2026',
      location: 'ZABNIX PRIVATE LIMITED',
      creditNoteNumber: 'CN-00006',
      referenceNumber: 'REF-0031',
      customerName: 'CUS-9',
      invoiceNumber: 'INV-000063',
      status: 'OPEN',
      amount: '945.75',
      balance: '945.75',
      issueDate: '02-05-2026',
      salesPerson: 'RASHID',
    ),
  ];

  final ScrollController _horizontalScrollController = ScrollController();
  String _selectedView = 'All';
  bool _sortAscending = false;
  bool _dropdownOpen = false;
  bool _columnMenuOpen = false;
  bool _favoritesExpanded = true;
  // 'clip' = ellipsis, 'wrap' = text wraps
  String _textMode = 'clip';
  final Set<String> _starredViews = {'Draft', 'Approved', 'Open', 'Closed', 'Void', 'Invoice unassociated'};
  final Set<int> _selectedIndices = {};
  int? _detailIndex;
  List<ColumnConfig> _columns = _defaultColumns();
  
  final LayerLink _downloadLink = LayerLink();
  OverlayEntry? _downloadOverlay;

  final LayerLink _compactBulkLink = LayerLink();
  OverlayEntry? _compactBulkOverlay;
  
  final LayerLink _pdfPrintLink = LayerLink();
  OverlayEntry? _pdfPrintOverlay;
  
  final LayerLink _customizeLink = LayerLink();
  OverlayEntry? _customizeOverlay;
  bool _pdfHovered = false;

  final LayerLink _moreActionLink = LayerLink();
  OverlayEntry? _moreActionOverlay;

  static const _viewOptions = [
    'All',
    'Draft',
    'Locked',
    'Pending Approval',
    'Approved',
    'Open',
    'Closed',
    'Void',
    'Invoice unassociated',
  ];

  List<_CreditNoteRow> get _filteredRows {
    final base = _selectedView == 'All'
        ? List<_CreditNoteRow>.from(_rows)
        : _rows.where((r) => r.status.toUpperCase() == _selectedView.toUpperCase()).toList();
    base.sort((a, b) {
      final cmp = a.creditNoteNumber.compareTo(b.creditNoteNumber);
      return _sortAscending ? cmp : -cmp;
    });
    return base;
  }

  bool get _allSelected =>
      _filteredRows.isNotEmpty && _selectedIndices.length == _filteredRows.length;
  bool get _someSelected =>
      _selectedIndices.isNotEmpty && _selectedIndices.length < _filteredRows.length;
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
          id: 'location',
          label: 'Location',
          orderIndex: 1,
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

  static const _customizeOptions = [
    'Spreadsheet Template',
    'Change Template',
    'Edit Template',
    'Update Logo & Address',
    'Manage Custom Fields',
    'Terms & Conditions',
  ];

  void _showCustomizeMenu(BuildContext context) {
    if (_customizeOverlay != null) {
      _closeCustomizeMenu();
      return;
    }
    final overlay = Overlay.of(context);
    _customizeOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeCustomizeMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _customizeLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              child: Container(
                width: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _customizeOptions.map((opt) {
                    return _CustomizeMenuOption(
                      label: opt,
                      onTap: _closeCustomizeMenu,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_customizeOverlay!);
    setState(() {}); // trigger rebuild so _customizeOverlay != null keeps button visible
  }

  void _closeCustomizeMenu() {
    _customizeOverlay?.remove();
    setState(() => _customizeOverlay = null);
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
                        context.go(AppRoutes.creditNotesCreate, extra: row.customerName);
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
                          setState(() {
                            _rows.remove(rowIndex);
                            _detailIndex = null;
                            _selectedIndices.clear();
                          });
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
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        final row = _filteredRows[_detailIndex!];
                        row.status = 'VOID';
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Void it', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEEEEE),
                      foregroundColor: AppTheme.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        final row = _filteredRows[_detailIndex!];
                        row.status = 'DRAFT';
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Convert to Draft', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEEEEE),
                      foregroundColor: AppTheme.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _columnWidths = _CnColumnWidths.defaults(clip: true);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _downloadOverlay?.remove();
    _compactBulkOverlay?.remove();
    _pdfPrintOverlay?.remove();
    _customizeOverlay?.remove();
    _moreActionOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Positioned.fill(child: _buildSplitView())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _selectedIndices.isNotEmpty
                        ? _buildBulkToolbar()
                        : _buildToolbar(context),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Expanded(child: _buildFullTable()),
                  ],
                ),
              // Dropdown overlay
              if (_dropdownOpen)
                Positioned(
                  top: _detailIndex != null ? 94 : 60,
                  left: _detailIndex != null ? 30 : 24,
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
                        constraints: const BoxConstraints(maxHeight: 520),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── FAVORITES header ─────────────────────────
                                GestureDetector(
                                  onTap: () => setState(() =>
                                      _favoritesExpanded = !_favoritesExpanded),
                                  child: _DropdownSectionHeader(
                                    label: 'FAVORITES',
                                    count: _starredViews.length,
                                    countColor: AppTheme.primaryBlue,
                                    expanded: _favoritesExpanded,
                                  ),
                                ),
                                // ── Starred items ─────────────────────────────
                                if (_favoritesExpanded && _starredViews.isNotEmpty)
                                  ..._viewOptions
                                      .where((opt) => _starredViews.contains(opt))
                                      .map(
                                        (opt) => _ViewFilterOption(
                                          label: opt,
                                          selected: opt == _selectedView,
                                          starred: true,
                                          onStarTap: () => setState(() => _starredViews.remove(opt)),
                                          onTap: () => setState(() {
                                            _selectedView = opt;
                                            _dropdownOpen = false;
                                            _detailIndex = null;
                                            _selectedIndices.clear();
                                          }),
                                        ),
                                      ),
                                // ── DEFAULT FILTERS header (non-collapsible) ──
                                _DropdownSectionHeader(
                                  label: 'DEFAULT FILTERS',
                                  count: _viewOptions.length,
                                  countColor: AppTheme.accentGreen,
                                  expanded: true,
                                ),
                                // ── All 9 view options always visible ─────────
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
                                    onTap: () => setState(() {
                                      _selectedView = opt;
                                      _dropdownOpen = false;
                                      _detailIndex = null;
                                      _selectedIndices.clear();
                                    }),
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
              if (_columnMenuOpen)
                Positioned(
                  top: 90,
                  left: 14,
                  child: Material(
                    elevation: 0,
                    color: AppTheme.backgroundColor.withValues(alpha: 0),
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
                            onTap: _openColumnCustomizer,
                          ),
                          _ColumnMenuOption(
                            label: _textMode == 'clip' ? 'Clip Text' : 'Wrap Text',
                            icon: _textMode == 'clip' ? LucideIcons.minus : LucideIcons.alignLeft,
                            selected: false,
                            onTap: () => setState(() {
                              _textMode = _textMode == 'clip' ? 'wrap' : 'clip';
                              _columnWidths = _CnColumnWidths.defaults(clip: _textMode == 'clip');
                              _columnMenuOpen = false;
                            }),
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
          GestureDetector(
            onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedView == 'All' ? 'All Credit Notes' : _selectedView,
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
          const Spacer(),
          ZButton.primary(
            label: 'New',
            icon: LucideIcons.plus,
            onPressed: () => context.go(AppRoutes.creditNotesCreate),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.moreHorizontal, size: 18),
              onPressed: () {},
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
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
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
                    _dropdownOpen = false;
                    _columnMenuOpen = !_columnMenuOpen;
                  }),
                  columns: _visibleColumns,
                  clipText: _textMode == 'clip',
                  columnWidths: _columnWidths,
                  onColumnResize: _resizeColumn,
                  sortAscending: _sortAscending,
                  onSort: () => setState(() {
                    _sortAscending = !_sortAscending;
                    _detailIndex = null;
                  }),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredRows.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderLight),
                    itemBuilder: (context, index) => _CnTableRow(
                      row: _filteredRows[index],
                      selected: _selectedIndices.contains(index),
                      hasSelection: _selectedIndices.isNotEmpty,
                      onChanged: (v) => _toggleRow(index, v),
                      onTap: () => setState(() => _detailIndex = index),
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
                        bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
                  ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _dropdownOpen = !_dropdownOpen),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedView == 'All'
                            ? 'All Credit Notes'
                            : _selectedView,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _dropdownOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 16,
                        color: AppTheme.primaryBlueDark,
                      ),
                    ],
                  ),
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
                    child: const Icon(LucideIcons.plus,
                        size: 18, color: AppTheme.backgroundColor),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(LucideIcons.moreHorizontal,
                      size: 16, color: AppTheme.textPrimary),
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
              itemBuilder: (context, index) => _CnCompactItem(
                row: _filteredRows[index],
                selected: index == _detailIndex,
                checked: _selectedIndices.contains(index),
                onCheckChanged: (v) => _toggleRow(index, v),
                onTap: () => setState(() => _detailIndex = index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    final row = _filteredRows[_detailIndex!];
    return Container(
      color: AppTheme.bgLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.only(left: 20, right: 8),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Location: ${row.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                  onTap: () {},
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: AppTheme.borderLight,
                ),
                GestureDetector(
                  onTap: () => setState(() => _detailIndex = null),
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
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
            ),
            child: Row(
              children: [
                if (row.status.toUpperCase() != 'VOID') ...[
                  _DetailActionBtn(
                      icon: LucideIcons.pencil,
                      label: 'Edit',
                      onTap: () => context.go(
                        '${AppRoutes.creditNotesEdit}/${row.creditNoteNumber}',
                        extra: row.customerName,
                      )),
                  const _DetailActionDivider(),
                  _DetailActionBtn(
                      icon: LucideIcons.mail, label: 'Email', onTap: () {}),
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
                  _DetailActionBtn(
                      icon: LucideIcons.fileUp,
                      label: 'Apply to Invoices',
                      onTap: () {}),
                  const _DetailActionDivider(),
                  _DetailActionBtn(
                      icon: LucideIcons.rotateCcw,
                      label: 'Refund',
                      onTap: () {}),
                  const _DetailActionDivider(),
                ] else ...[
                  _DetailActionBtn(
                      icon: LucideIcons.rotateCw,
                      label: 'Convert to Draft',
                      onTap: () => _showConvertDraftDialog(context)),
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
                              const Icon(LucideIcons.sparkles, color: Colors.purple, size: 16),
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
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    onPressed: () {},
                                    child: const Text('Send Credit Note', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.textPrimary,
                                      side: const BorderSide(color: AppTheme.borderLight),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        row.status = 'OPEN';
                                      });
                                    },
                                    child: const Text('Convert to Open', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      MouseRegion(
                        onEnter: (_) => setState(() => _pdfHovered = true),
                        onExit: (_) => setState(() => _pdfHovered = false),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _CnDocumentPreview(row: row),
                            // Customize button — visible only on hover or when dropdown is open
                            if (_pdfHovered || _customizeOverlay != null)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: CompositedTransformTarget(
                                  link: _customizeLink,
                                  child: GestureDetector(
                                    onTap: () => _showCustomizeMenu(context),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentGreen,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.settings2,
                                              size: 14, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text(
                                            'Customize',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(LucideIcons.chevronDown,
                                              size: 13, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "PDF Template : 'Spreadsheet Template' ",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF444444),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Change',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ],
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
                                    style: TextStyle(fontSize: 13, color: Color(0xFF111111)),
                                  ),
                                  TextSpan(
                                    text: row.invoiceNumber,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue),
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
            bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                : Colors.transparent,
            border: Border.all(color: AppTheme.borderLight),
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

  const _MoreActionMenuOption({
    required this.label,
    required this.onTap,
  });

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

class _CustomizeMenuOption extends StatefulWidget {
  const _CustomizeMenuOption({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_CustomizeMenuOption> createState() => _CustomizeMenuOptionState();
}

class _CustomizeMenuOptionState extends State<_CustomizeMenuOption> {
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
      color: const Color(0xFFF5F6FA),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: countColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewFilterOption extends StatefulWidget {
  final String label;
  final bool selected;
  final bool starred;
  final VoidCallback onTap;
  final VoidCallback onStarTap;
  const _ViewFilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onStarTap,
    this.starred = false,
  });

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
                    : Colors.transparent,
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
                        ? Colors.white
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              // Toggleable star
              GestureDetector(
                onTap: widget.onStarTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Icon(
                    widget.starred ? Icons.star : Icons.star_border,
                    size: 16,
                    color: widget.selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : widget.starred
                            ? const Color(0xFFE8A838)   // orange when starred
                            : AppTheme.borderLight,      // grey when not starred
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
                    ? Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3))
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
  final bool sortAscending;
  final VoidCallback onSort;

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
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!hasSelection)
            SizedBox(
              width: 28,
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
            width: 32,
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
              width: columnWidths[column.id] ?? _CnColumnWidths.forId(column.id, clip: clipText),
              label: column.label.toUpperCase(),
              sorted: column.id == 'creditNoteNumber',
              sortAscending: sortAscending,
              clipText: true,
              onResize: (delta) => onColumnResize(column.id, delta),
              onSort: column.id == 'creditNoteNumber' ? onSort : null,
            ),
        ],
      ),
    );
  }
}

class _CnTableRow extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final isClip = clipText;
    final rowContent = Row(
      crossAxisAlignment:
          isClip ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!hasSelection) const SizedBox(width: 28),
        SizedBox(
          height: isClip ? 48 : null,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 32,
              child: Checkbox(
                value: selected,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppTheme.primaryBlue,
                side:
                    const BorderSide(color: AppTheme.borderLight, width: 1.5),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
        for (final column in columns)
          _CnBodyCell(
            width: columnWidths[column.id] ?? _CnColumnWidths.forId(column.id, clip: isClip),
            clip: isClip,
            child: _buildCell(column.id, isClip),
          ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Clip mode: fixed 48 px row. Wrap mode: grows with content (min 48).
        height: isClip ? 48 : null,
        constraints: isClip ? null : const BoxConstraints(minHeight: 48),
        color: selected
            ? AppTheme.primaryBlue.withValues(alpha: 0.07)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isClip ? 0 : 10,
        ),
        child: rowContent,
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN': return AppTheme.primaryBlue;
      case 'CLOSED': return AppTheme.textSecondary;
      case 'DRAFT': return const Color(0xFFE67E22);
      case 'VOID': return const Color(0xFF666666);
      case 'PENDING APPROVAL': return const Color(0xFF9B59B6);
      default: return AppTheme.primaryBlue;
    }
  }

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
                      widget.sortAscending ? LucideIcons.chevronUp : LucideIcons.chevronDown,
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
                onHorizontalDragUpdate: (d) => widget.onResize?.call(d.delta.dx),
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

class _CreditNoteRow {
  _CreditNoteRow({
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
                      color: AppTheme.borderLight, width: 1.5),
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
  const _DetailHeaderIconButton({
    required this.icon,
    required this.onTap,
  });

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
          child: Icon(
            widget.icon,
            size: 16,
            color: AppTheme.textSecondary,
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
      margin: const EdgeInsets.symmetric(horizontal: 5),
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
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                : AppTheme.backgroundColor.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 13, color: AppTheme.textSecondary),
              if (widget.icon != null && widget.label != null)
                const SizedBox(width: 5),
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 3),
                Icon(widget.trailingIcon,
                    size: 11, color: AppTheme.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Credit note document preview ────────────────────────────────────────────

class _CnDocumentPreview extends StatelessWidget {
  const _CnDocumentPreview({required this.row});
  final _CreditNoteRow row;

  static const Color _border = Color(0xFFCCCCCC);
  static const Color _outerBorder = Color(0xFFBBBBBB);
  static const Color _outermost = Color(0xFFDDDDDD);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Outermost border with padding ──────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _outermost, width: 1.0),
          ),
          padding: const EdgeInsets.all(60),
          child: Container(
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
                      bottom: BorderSide(color: _border, width: 0.8)),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo placeholder
                    Container(
                      width: 110,
                      height: 44,
                      color: const Color(0xFF1A1A2E),
                      alignment: Alignment.center,
                      child: const Text(
                        'Logo',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 11),
                      ),
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
                          Text('PERINTHALMANNA',
                              style: TextStyle(fontSize: 10)),
                          Text('MALAPPURAM Kerala 679322',
                              style: TextStyle(fontSize: 10)),
                          Text('India', style: TextStyle(fontSize: 10)),
                          SizedBox(height: 3),
                          Text('GSTIN 32AACCZ4912F1ZL',
                              style: TextStyle(fontSize: 10)),
                          Text('8086355500',
                              style: TextStyle(fontSize: 10)),
                          Text('zabnixprivatelimited@gmail.com',
                              style: TextStyle(fontSize: 10)),
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
                  verticalInside: const BorderSide(color: _border, width: 0.8),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _tableRow('#', row.creditNoteNumber,
                      'Place Of Supply', 'Kerala (32)'),
                  _tableRow('Credit Date', row.date, '', ''),
                  _tableRow('Invoice#', row.invoiceNumber, '', ''),
                  _tableRow('Invoice Date', row.issueDate, '', ''),
                ],
              ),

              // ── Bill To ────────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: _border, width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: const Color(0xFFF5F5F5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: const Text(
                        'Bill To',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
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
                          const Text(
                            'THARAVADU STARLEX, Mysuru - Ooty Rd, near Moulana hospital',
                            style: TextStyle(fontSize: 10),
                          ),
                          const Text('PERINTHALMANNA',
                              style: TextStyle(fontSize: 10)),
                          const Text('PERINTHALMANNA',
                              style: TextStyle(fontSize: 10)),
                          const Text('679322',
                              style: TextStyle(fontSize: 10)),
                          const Text('India',
                              style: TextStyle(fontSize: 10)),
                          const SizedBox(height: 3),
                          const Text('GSTIN 32ABACS3075R1ZX',
                              style: TextStyle(fontSize: 10)),
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
                    decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                    children: [
                      _tableHeaderCell('#', align: TextAlign.center),
                      _tableHeaderCell('Item & Description'),
                      _tableHeaderCell('HSN/SAC'),
                      _tableHeaderCell('Qty', align: TextAlign.right),
                      _tableHeaderCell('Rate', align: TextAlign.right),
                      _tableHeaderCell('Amount', align: TextAlign.right),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableDataCell('1', align: TextAlign.center),
                      _tableDataCell('ITEM 11'),
                      _tableDataCell('30045037'),
                      _tableDataCell('10.00\nbox', align: TextAlign.right),
                      _tableDataCell('45.00', align: TextAlign.right),
                      _tableDataCell('450.00', align: TextAlign.right),
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
                              'Indian Rupee Five Hundred Four Only',
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
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                            child: Column(
                              children: [
                                _summaryRow('Sub Total', '450.00'),
                                _summaryRow('CGST6 (6%)', '27.00'),
                                _summaryRow('SGST6 (6%)', '27.00'),
                                const SizedBox(height: 8),
                                _summaryRow('Total', '₹504.00', isBold: true),
                                _summaryRow('Credits Remaining', '₹504.00', isBold: true),
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
      ),

        // ── Corner status ribbon — on outermost border corner ─────
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
                        color: (row.status.toUpperCase() == 'VOID' || row.status.toUpperCase() == 'DRAFT')
                            ? const Color(0xFF7F8C8D)
                            : row.status.toUpperCase() == 'CLOSED'
                                ? AppTheme.textSecondary
                                : row.status.toUpperCase() == 'PENDING APPROVAL'
                                    ? const Color(0xFF9B59B6)
                                    : AppTheme.primaryBlue,
                        alignment: Alignment.center,
                        child: Text(
                          row.status.toUpperCase() == 'PENDING APPROVAL'
                              ? 'Pending'
                              : row.status.substring(0, 1).toUpperCase() +
                                  row.status.substring(1).toLowerCase(),
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
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF111111),
        ),
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
        fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF111111));

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
