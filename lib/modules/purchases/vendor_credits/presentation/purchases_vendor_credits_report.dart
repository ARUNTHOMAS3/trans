import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/models/vendor_credit_models.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/providers/vendor_credits_providers.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/purchases/payments_made/presentation/pages/purchases_payments_made_create.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/presentation/purchases_vendor_credits_overview.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';

class VendorCreditsOverviewPage extends ConsumerStatefulWidget {
  final String? initialCreditNoteNumber;
  final bool showRefundMode;
  const VendorCreditsOverviewPage({
    super.key,
    this.initialCreditNoteNumber,
    this.showRefundMode = false,
  });

  @override
  ConsumerState<VendorCreditsOverviewPage> createState() =>
      _VendorCreditsOverviewPageState();
}

final _inFmt = NumberFormat('#,##,##0.00', 'en_IN');
const List<String> _vcBulkUpdateFields = <String>[
  'Order Number',
  'Date',
  'Billing Address',
  'Notes',
];

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
  bool _showRefundView = false;
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
  final _columnSettingsKey = GlobalKey();
  final ScrollController _hScrollController = ScrollController();
  final LayerLink _filterDropdownLink = LayerLink();
  final LayerLink _pdfPrintLink = LayerLink();
  final LayerLink _detailAttachmentLink = LayerLink();
  OverlayEntry? _pdfPrintOverlay;
  OverlayEntry? _detailAttachmentOverlay;

  bool _tabExpanded = true;
  bool _showDetailHistorySidebar = false;
  final ScrollController _detailScrollController = ScrollController();
  final GlobalKey _journalKey = GlobalKey();
  final Set<int> _selectedIndices = {};
  bool _isLoading = true;
  String? _loadError;
  List<_VendorCreditRow> _rows = const [];

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

  void _clearSelection() {
    _closePdfPrintMenu();
    setState(() => _selectedIndices.clear());
  }

  Future<void> _deleteSelectedRows() async {
    final filteredRows = _filteredRows;
    final selectedIds = _selectedIndices
        .where((index) => index >= 0 && index < filteredRows.length)
        .map((index) => filteredRows[index].id)
        .toSet();
    if (selectedIds.isEmpty) {
      _clearSelection();
      return;
    }

    _closePdfPrintMenu();

    final confirm = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Vendor Credits',
      message: 'Are you sure you want to delete the selected ${selectedIds.length} vendor credits? This action cannot be undone.',
      confirmLabel: 'Delete',
      variant: ZerpaiConfirmationVariant.danger,
    );

    if (!confirm) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final supabase = Supabase.instance.client;
      for (final id in selectedIds) {
        if (id.isNotEmpty) {
          // Delete attachments first
          try {
            await supabase.from('vendor_credits_attachments').delete().eq('vendor_credit_id', id);
          } catch (_) {
            // Ignore if table doesn't exist or no permissions
          }
          
          // Find item IDs to delete their batches
          List<dynamic> itemIds = [];
          try {
            final itemsResp = await supabase
                .from('vendor_credit_items')
                .select('id')
                .eq('vendor_credit_id', id);
            itemIds = (itemsResp as List).map((row) => row['id']).toList();
          } catch (_) {}

          if (itemIds.isNotEmpty) {
            try {
              await supabase
                  .from('vendor_credit_item_batches')
                  .delete()
                  .inFilter('vendor_credit_item_id', itemIds);
            } catch (_) {}
          }
          
          // Delete items
          try {
            await supabase.from('vendor_credit_items').delete().eq('vendor_credit_id', id);
          } catch (_) {
            // Ignore
          }

          // Delete main record
          await supabase.from('vendor_credits').delete().eq('id', id);
        }
      }
    } catch (e) {
      // Ignore error for now
    }

    if (mounted) {
      setState(() {
        _rows = _rows.where((row) => !selectedIds.contains(row.id)).toList();
        _selectedIndices.clear();
        if (_detailIndex != null && _detailIndex! >= _filteredRows.length) {
          _detailIndex = null;
        }
        _isLoading = false;
      });
    }
  }

  void _showBulkUpdateDialog(BuildContext context) {
    _closePdfPrintMenu();
    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Bulk Update Vendor Credit',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      pageBuilder: (dialogContext, _, __) {
        final selectedRows = _selectedIndices
            .where((index) => index >= 0 && index < _filteredRows.length)
            .map((index) => _filteredRows[index])
            .toList();
        final selectedVendorNames = selectedRows
            .map((row) => row.vendorName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList(growable: false);
        final selectedBillingAddresses = selectedRows
            .expand((row) => row.billingAddresses)
            .map((address) => address.trim())
            .where((address) => address.isNotEmpty)
            .toSet()
            .toList(growable: false);
        return _VcBulkUpdateDialog(
          selectedVendorName: selectedVendorNames.length == 1
              ? selectedVendorNames.first
              : selectedVendorNames.isEmpty
              ? 'Vendor'
              : 'Multiple Vendors',
          billingAddresses: selectedBillingAddresses,
          onClose: () => Navigator.of(dialogContext).pop(),
          onApply: (field, value) {
            final selectedIds = _selectedIndices
                .where((index) => index >= 0 && index < _filteredRows.length)
                .map((index) => _filteredRows[index].id)
                .toSet();
            if (selectedIds.isEmpty) {
              Navigator.of(dialogContext).pop();
              return;
            }

            setState(() {
              _rows = _rows.map((row) {
                if (!selectedIds.contains(row.id)) return row;
                switch (field) {
                  case 'Order Number':
                    return _VendorCreditRow(
                      id: row.id,
                      date: row.date,
                      creditNoteNumber: row.creditNoteNumber,
                      referenceNumber: value,
                      vendorId: row.vendorId,
                      vendorName: row.vendorName,
                      billingAddresses: row.billingAddresses,
                      status: row.status,
                      amount: row.amount,
                      balance: row.balance,
                    );
                  case 'Date':
                    return _VendorCreditRow(
                      id: row.id,
                      date: value,
                      creditNoteNumber: row.creditNoteNumber,
                      referenceNumber: row.referenceNumber,
                      vendorId: row.vendorId,
                      vendorName: row.vendorName,
                      billingAddresses: row.billingAddresses,
                      status: row.status,
                      amount: row.amount,
                      balance: row.balance,
                    );
                  default:
                    return row;
                }
              }).toList();
            });
            Navigator.of(dialogContext).pop();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  /* final List<_VendorCreditRow> _rows = [
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
  ]; */

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatCurrency(double amount) => '₹${_inFmt.format(amount)}';

  double _balanceForStatus(String status, double totalAmount) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'closed' || normalized == 'void') {
      return 0;
    }
    return totalAmount;
  }

  void _syncDetailSelection() {
    if (widget.initialCreditNoteNumber == null) {
      if (_detailIndex != null && _detailIndex! >= _rows.length) {
        _detailIndex = null;
      }
      return;
    }

    final index = _rows.indexWhere(
      (r) => r.creditNoteNumber == widget.initialCreditNoteNumber,
    );
    _detailIndex = index == -1 ? null : index;
  }

  Future<void> _loadSavedVendorCredits() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final entityId = ref.read(entityProvider).entityId;
      if (entityId == null || entityId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _rows = const [];
          _selectedIndices.clear();
          _detailIndex = null;
          _isLoading = false;
        });
        return;
      }

      final supabase = Supabase.instance.client;
      final creditRows = await supabase
          .from('vendor_credits')
          .select(
            'id, vendor_id, vendor_credit_number, reference_number, '
            'vendor_credit_date, status, total_amount',
          )
          .eq('entity_id', entityId)
          .order('vendor_credit_date', ascending: false);

      final vendorIds = (creditRows as List)
          .map((row) => row['vendor_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      final vendorNames = <String, String>{};
      final vendorBillingAddresses = <String, List<String>>{};
      if (vendorIds.isNotEmpty) {
        var vendors = ref.read(vendorProvider).vendors;
        final missingVendorIds = vendorIds
            .where((id) => !vendors.any((vendor) => vendor.id == id))
            .toList(growable: false);
        if (vendors.isEmpty || missingVendorIds.isNotEmpty) {
          await ref.read(vendorProvider.notifier).loadVendors();
          vendors = ref.read(vendorProvider).vendors;
        }

        for (final vendor in vendors) {
          if (!vendorIds.contains(vendor.id)) continue;
          vendorNames[vendor.id] = vendor.displayName;
          vendorBillingAddresses[vendor.id] =
              _vendorBillingAddressesFromVendor(vendor);
        }
      }

      final rows = creditRows
          .map((raw) {
            final row = Map<String, dynamic>.from(raw as Map);
            final totalAmount = _toDouble(row['total_amount']);
            final status = row['status']?.toString() ?? 'draft';
            final balance = _balanceForStatus(status, totalAmount);
            final date = DateTime.tryParse(
              row['vendor_credit_date']?.toString() ?? '',
            );
            return _VendorCreditRow(
              id: row['id']?.toString() ?? '',
              date: date == null ? '' : DateFormat('dd-MM-yyyy').format(date),
              creditNoteNumber: row['vendor_credit_number']?.toString() ?? '',
              referenceNumber: row['reference_number']?.toString() ?? '',
              vendorId: row['vendor_id']?.toString() ?? '',
              vendorName:
                  vendorNames[row['vendor_id']?.toString() ?? ''] ??
                  'Unknown Vendor',
              billingAddresses:
                  vendorBillingAddresses[row['vendor_id']?.toString() ?? ''] ??
                  const <String>[],
              status: status,
              amount: _formatCurrency(totalAmount),
              balance: _formatCurrency(balance),
            );
          })
          .where((row) => row.creditNoteNumber.trim().isNotEmpty)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _selectedIndices.removeWhere((index) => index >= rows.length);
        _syncDetailSelection();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _rows = const [];
        _selectedIndices.clear();
        _detailIndex = null;
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

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
    _showRefundView = widget.showRefundMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSavedVendorCredits();
    });
  }

  @override
  void didUpdateWidget(VendorCreditsOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showRefundMode != widget.showRefundMode) {
      setState(() => _showRefundView = widget.showRefundMode);
    }
    if (oldWidget.initialCreditNoteNumber != widget.initialCreditNoteNumber) {
      setState(_syncDetailSelection);
    }
  }

  @override
  void dispose() {
    _pdfPrintOverlay?.remove();
    _detailAttachmentOverlay?.remove();
    _hScrollController.dispose();
    _detailScrollController.dispose();
    super.dispose();
  }

  void _closeDetailAttachmentOverlay() {
    _detailAttachmentOverlay?.remove();
    _detailAttachmentOverlay = null;
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleDetailAttachmentOverlay(_VendorCreditRow rawRow) {
    if (_detailAttachmentOverlay != null) {
      _closeDetailAttachmentOverlay();
      return;
    }

    _detailAttachmentOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDetailAttachmentOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _detailAttachmentLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(-8, 4),
            child: Material(
              color: Colors.transparent,
              child: _VendorCreditAttachmentOverlayContent(
                vendorCreditId: rawRow.id,
                entityId: ref.read(entityProvider).entityId,
                onClose: _closeDetailAttachmentOverlay,
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_detailAttachmentOverlay!);
    setState(() {});
  }

  // ── PDF/Print helpers ──────────────────────────────────────────────────────

  Future<Uint8List> _generatePdfBytes(
    VendorCreditDetail creditNote,
    OrgSettings? orgSettings,
  ) async {
    // Delegate to the shared generator in VendorCreditDetailPage via static
    // helper defined below in this file.
    return _buildVcPdfBytes(creditNote, orgSettings);
  }

  Future<void> _exportPdf(
    VendorCreditDetail creditNote,
    OrgSettings? orgSettings,
  ) async {
    try {
      final bytes = await _generatePdfBytes(creditNote, orgSettings);
      try {
        await Printing.sharePdf(
          bytes: bytes,
          filename: '${creditNote.creditNoteNumber}.pdf',
        );
      } catch (_) {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: creditNote.creditNoteNumber,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to generate vendor credit PDF.');
    }
  }

  Future<void> _printCredit(
    VendorCreditDetail creditNote,
    OrgSettings? orgSettings,
  ) async {
    try {
      final bytes = await _generatePdfBytes(creditNote, orgSettings);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: creditNote.creditNoteNumber,
      );
    } catch (_) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to print vendor credit.');
    }
  }

  void _showPdfPrintMenu(
    BuildContext context, {
    VendorCreditDetail? creditNote,
    OrgSettings? orgSettings,
  }) {
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
                      onTap: creditNote != null
                          ? () {
                              _closePdfPrintMenu();
                              _exportPdf(creditNote, orgSettings);
                            }
                          : _closePdfPrintMenu,
                    ),
                    _DownloadMenuOption(
                      icon: LucideIcons.printer,
                      label: 'Print',
                      onTap: creditNote != null
                          ? () {
                              _closePdfPrintMenu();
                              _printCredit(creditNote, orgSettings);
                            }
                          : _closePdfPrintMenu,
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

  // ── Status-change helpers ──────────────────────────────────────────────────

  Future<void> _updateVcStatus(
    _VendorCreditRow rawRow,
    String newStatus,
  ) async {
    try {
      await Supabase.instance.client
          .from('vendor_credits')
          .update({'status': newStatus})
          .eq('id', rawRow.id);

      if (!mounted) return;
      setState(() {
        final idx = _rows.indexWhere((r) => r.id == rawRow.id);
        if (idx != -1) {
          _rows = List.of(_rows)
            ..[idx] = _VendorCreditRow(
              id: rawRow.id,
              date: rawRow.date,
              creditNoteNumber: rawRow.creditNoteNumber,
              referenceNumber: rawRow.referenceNumber,
              vendorId: rawRow.vendorId,
              vendorName: rawRow.vendorName,
              billingAddresses: rawRow.billingAddresses,
              status: newStatus,
              amount: rawRow.amount,
              balance: rawRow.balance,
            );
        }
      });
      // Invalidate detail provider so the open detail re-fetches.
      ref.invalidate(vendorCreditDetailProvider(rawRow.creditNoteNumber));
      ZerpaiToast.success(context, 'Status updated to $newStatus.');
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to update status: $e');
    }
  }

  Future<void> _voidCredit(_VendorCreditRow rawRow) async {
    final confirm = await showZerpaiConfirmationDialog(
      context,
      title: 'Void Vendor Credit',
      message:
          'Are you sure you want to void ${rawRow.creditNoteNumber}? This cannot be undone.',
      confirmLabel: 'Void',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirm) return;
    await _updateVcStatus(rawRow, 'void');
  }

  Future<void> _closeCredit(_VendorCreditRow rawRow) async {
    final confirm = await showZerpaiConfirmationDialog(
      context,
      title: 'Close Vendor Credit',
      message: 'Mark ${rawRow.creditNoteNumber} as Closed?',
      confirmLabel: 'Close',
      variant: ZerpaiConfirmationVariant.warning,
    );
    if (!confirm) return;
    await _updateVcStatus(rawRow, 'closed');
  }

  Future<void> _cloneCredit(
    BuildContext context,
    _VendorCreditRow rawRow,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      // Fetch full row to clone
      final rows = await supabase
          .from('vendor_credits')
          .select()
          .eq('id', rawRow.id)
          .limit(1);
      if (rows.isEmpty) {
        if (!mounted) return;
        ZerpaiToast.error(context, 'Original record not found.');
        return;
      }

      final original = Map<String, dynamic>.from(rows.first as Map);
      original.remove('id');
      original.remove('created_at');
      original.remove('updated_at');

      // Generate a new credit number: append -COPY or increment suffix
      final baseName =
          (original['vendor_credit_number'] as String? ?? '').replaceAll(
            RegExp(r'-COPY\d*$'),
            '',
          );
      original['vendor_credit_number'] = '$baseName-COPY';
      original['status'] = 'draft';

      await supabase.from('vendor_credits').insert(original);

      if (!mounted) return;
      ZerpaiToast.success(context, 'Cloned as ${original['vendor_credit_number']}.');
      _loadSavedVendorCredits();
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Clone failed: $e');
    }
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

  List<String> _vendorBillingAddressesFromVendor(Vendor vendor) {
    final addresses = <String>[];

    String joinAddressParts(Map<String, dynamic>? source) {
      if (source == null) return '';
      final lines = <String>[
        source['attention']?.toString().trim() ?? '',
        source['street1']?.toString().trim() ?? '',
        source['street2']?.toString().trim() ?? '',
      ].where((value) => value.isNotEmpty).toList();

      final locality = [
        source['city']?.toString().trim() ?? '',
        source['state']?.toString().trim() ?? '',
        source['zip']?.toString().trim() ?? '',
      ].where((value) => value.isNotEmpty).join(', ');
      if (locality.isNotEmpty) lines.add(locality);

      final country = source['country']?.toString().trim() ?? '';
      if (country.isNotEmpty) lines.add(country);

      final phone = source['phone']?.toString().trim() ?? '';
      if (phone.isNotEmpty) lines.add(phone);

      final fax = source['fax']?.toString().trim() ?? '';
      if (fax.isNotEmpty) lines.add('Fax Number : $fax');

      return lines.join('\n').trim();
    }

    final primaryAddress = joinAddressParts(vendor.billingAddress);
    if (primaryAddress.isNotEmpty) {
      addresses.add(primaryAddress);
    }

    final rawVendorAddresses = vendor.vendorAddresses ?? const [];
    for (final address in rawVendorAddresses) {
      final normalized = joinAddressParts({
        'attention': address['attention'] ?? address['billing_attention'],
        'street1':
            address['street1'] ??
            address['street'] ??
            address['billing_address_street'] ??
            address['billingAddressStreet'],
        'street2':
            address['street2'] ??
            address['place'] ??
            address['billing_address_place'] ??
            address['billingAddressPlace'],
        'city': address['city'] ?? address['billing_city'],
        'state': address['state'] ?? address['billing_state'],
        'zip':
            address['zip'] ??
            address['pincode'] ??
            address['billing_pincode'],
        'country':
            address['country'] ??
            address['country_region'] ??
            address['billing_country_region'],
        'phone': address['phone'] ?? address['billing_phone'],
        'fax': address['fax'] ?? address['billing_fax'],
      });
      if (normalized.isNotEmpty) {
        addresses.add(normalized);
      }
    }

    return addresses.toSet().toList(growable: false);
  }

  void _resetColumnWidths() {
    setState(() {
      _colWidths = {
        'date': _VcColumnWidths.date,
        'creditNoteNumber': _VcColumnWidths.creditNoteNumber,
        'referenceNumber': _VcColumnWidths.referenceNumber,
        'vendorName': _VcColumnWidths.vendorName,
        'status': _VcColumnWidths.status,
        'amount': _VcColumnWidths.amount,
        'balance': _VcColumnWidths.balance,
      };
    });
  }

  ButtonStyle _vendorCreditMoreMenuItemStyle({bool isActive = false}) {
    return ButtonStyle(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (isActive) return AppTheme.bgDisabled;
        if (states.contains(WidgetState.hovered)) return AppTheme.primaryBlue;
        return Colors.white;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return Colors.white;
        return AppTheme.textPrimary;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return Colors.white;
        return AppTheme.primaryBlue;
      }),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(220, 40)),
      alignment: Alignment.centerLeft,
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildSortMenuItem(String label, String column) {
    final active = _sortColumn == column;
    return MenuItemButton(
      style: _vendorCreditMoreMenuItemStyle(isActive: active),
      leadingIcon: active
          ? Icon(
              _sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
              size: 16,
            )
          : const SizedBox(width: 16, height: 16),
      onPressed: () {
        setState(() {
          if (_sortColumn == column) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = column;
            _sortAscending = true;
          }
        });
      },
      child: Text(label),
    );
  }

  List<Widget> _buildMoreMenuChildren() {
    return [
      SubmenuButton(
        style: _vendorCreditMoreMenuItemStyle(),
        menuStyle: ZTableMoreMenu.submenuMenuStyle(),
        alignmentOffset: const Offset(4, 0),
        leadingIcon: const Icon(LucideIcons.arrowUpDown, size: 16),
        menuChildren: [
          _buildSortMenuItem('Credit Note#', 'creditNoteNumber'),
          _buildSortMenuItem('Date', 'date'),
          _buildSortMenuItem('Amount', 'amount'),
          _buildSortMenuItem('Balance', 'balance'),
        ],
        child: const Text('Sort by'),
      ),
      SubmenuButton(
        style: _vendorCreditMoreMenuItemStyle(),
        menuStyle: ZTableMoreMenu.submenuMenuStyle(),
        alignmentOffset: const Offset(4, 0),
        leadingIcon: const Icon(LucideIcons.upload, size: 16),
        menuChildren: [
          MenuItemButton(
            style: _vendorCreditMoreMenuItemStyle(),
            onPressed: () {},
            child: const Text('Export Vendor Credits'),
          ),
          MenuItemButton(
            style: _vendorCreditMoreMenuItemStyle(),
            onPressed: () {},
            child: const Text('Export Current View'),
          ),
        ],
        child: const Text('Export'),
      ),
      MenuItemButton(
        style: _vendorCreditMoreMenuItemStyle(),
        leadingIcon: const Icon(LucideIcons.columns, size: 16),
        onPressed: _openColumnCustomizer,
        child: const Text('Customize Columns'),
      ),
      MenuItemButton(
        style: _vendorCreditMoreMenuItemStyle(),
        leadingIcon: const Icon(LucideIcons.refreshCw, size: 16),
        onPressed: _loadSavedVendorCredits,
        child: const Text('Refresh List'),
      ),
      MenuItemButton(
        style: _vendorCreditMoreMenuItemStyle(),
        leadingIcon: const Icon(LucideIcons.rotateCcw, size: 16),
        onPressed: _resetColumnWidths,
        child: const Text('Reset Column Width'),
      ),
    ];
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
    if (_isLoading && _rows.isEmpty) {
      return const ZerpaiLayout(
        pageTitle: '',
        enableBodyScroll: false,
        useTopPadding: false,
        useHorizontalPadding: false,
        child: _VendorCreditsOverviewSkeleton(),
      );
    }

    if (_loadError != null && _rows.isEmpty) {
      return ZerpaiLayout(
        pageTitle: '',
        enableBodyScroll: false,
        useTopPadding: false,
        useHorizontalPadding: false,
        child: Center(
          child: Text(
            'Failed to load vendor credits: $_loadError',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

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
                    _selectedIndices.isNotEmpty
                        ? _buildSelectionToolbar(context)
                        : _buildToolbar(context),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _hScrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
                maxHeight: constraints.maxHeight,
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
                                    if (_detailScrollController.hasClients)
                                      _detailScrollController.jumpTo(0);
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
          );
        },
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
                ZTableMoreMenu(
                  width: 40,
                  height: 36,
                  iconSize: 18,
                  menuChildren: _buildMoreMenuChildren(),
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
                    if (_detailScrollController.hasClients)
                      _detailScrollController.jumpTo(0);
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
    final creditNoteAsync = ref.watch(
      vendorCreditDetailProvider(rawRow.creditNoteNumber),
    );

    return creditNoteAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Failed to load vendor credit: $error',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
      data: (creditNote) {
        if (creditNote == null) {
          return const Center(
            child: Text(
              'Vendor credit not found',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        if (_showRefundView) {
          return _VendorCreditRefundInlineView(
            creditNote: creditNote,
            onCancel: () => setState(() => _showRefundView = false),
            onSaved: () {
              setState(() => _showRefundView = false);
              ref.invalidate(
                vendorCreditDetailProvider(creditNote.creditNoteNumber),
              );
              _loadSavedVendorCredits();
            },
          );
        }

        return Container(
          color: AppTheme.backgroundColor,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 64,
                      padding: const EdgeInsets.only(left: 20, right: 8),
                      decoration: const BoxDecoration(
                        color: AppTheme.backgroundColor,
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.borderLight,
                            width: 1,
                          ),
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
                          CompositedTransformTarget(
                            link: _detailAttachmentLink,
                            child: _DetailHeaderIconButton(
                              icon: LucideIcons.paperclip,
                              onTap: () => _toggleDetailAttachmentOverlay(
                                rawRow,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _DetailHeaderIconButton(
                            icon: LucideIcons.messageSquare,
                            onTap: () => setState(
                              () => _showDetailHistorySidebar =
                                  !_showDetailHistorySidebar,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            color: AppTheme.borderLight,
                          ),
                          GestureDetector(
                            onTap: () {
                              _closeDetailAttachmentOverlay();
                              setState(() {
                                _detailIndex = null;
                                _showDetailHistorySidebar = false;
                              });
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
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: const BoxDecoration(
                        color: AppTheme.bgLight,
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.borderLight,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _DetailActionBtn(
                            icon: LucideIcons.pencil,
                            label: 'Edit',
                            onTap: () => context.push(
                              '${AppRoutes.vendorCreditsCreate}?id=${rawRow.id}',
                            ),
                          ),
                          CompositedTransformTarget(
                            link: _pdfPrintLink,
                            child: _DetailActionBtn(
                              icon: LucideIcons.fileText,
                              label: 'PDF/Print',
                              trailingIcon: LucideIcons.chevronDown,
                              onTap: () => _showPdfPrintMenu(
                                context,
                                creditNote: creditNote,
                                orgSettings: ref.read(orgSettingsProvider).asData?.value,
                              ),
                            ),
                          ),
                          const _DetailActionDivider(),
                          if (creditNote.appliedBillNumber?.trim().isEmpty ??
                              true) ...[
                            _DetailActionBtn(
                              icon: LucideIcons.clipboardCheck,
                              label: 'Apply to Bills',
                              onTap: () async {
                                final applied = await showDialog<bool>(
                                  context: context,
                                  useRootNavigator: true,
                                  useSafeArea: false,
                                  builder: (_) => ApplyToBillsDialog(
                                    creditNote: creditNote,
                                  ),
                                );
                                if (applied == true) {
                                  ref.invalidate(
                                    vendorCreditDetailProvider(
                                      rawRow.creditNoteNumber,
                                    ),
                                  );
                                  if (mounted) {
                                    setState(() => _tabExpanded = true);
                                  }
                                }
                              },
                            ),
                            const _DetailActionDivider(),
                          ],
                          _DetailMoreBtn(
                            onRefund: () => setState(() => _showRefundView = true),
                            onVoid: () => _voidCredit(rawRow),
                            onClone: () => _cloneCredit(context, rawRow),
                            onClose: () => _closeCredit(rawRow),
                            onViewJournal: () {
                              final ctx = _journalKey.currentContext;
                              if (ctx != null) {
                                Scrollable.ensureVisible(
                                  ctx,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            onDelete: () {
                              setState(() {
                                _rows.removeWhere((r) => r.id == rawRow.id);
                                _detailIndex = null;
                                _showDetailHistorySidebar = false;
                              });
                              context.go(AppRoutes.vendorCredits);
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: _buildCreditAppliedSection(creditNote),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _detailScrollController,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _VendorCreditRefundHistorySection(
                                  vendorCreditId: creditNote.id,
                                ),
                                const SizedBox(height: 16),
                                _buildAssociatedBillRow(creditNote),
                                const SizedBox(height: 16),
                                _VcPdfPreview(creditNote: creditNote),
                                const SizedBox(height: 24),
                                _VcJournalSection(
                                  key: _journalKey,
                                  creditNote: creditNote,
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
              if (_showDetailHistorySidebar)
                _VendorCreditHistorySidebar(
                  rawRow: rawRow,
                  creditNote: creditNote,
                  entityId: ref.read(entityProvider).entityId,
                  orgId: ref.read(entityProvider).orgId,
                  onClose: () => setState(
                    () => _showDetailHistorySidebar = false,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreditAppliedSection(VendorCreditDetail creditNote) {
    final appliedBill = creditNote.appliedBillNumber?.trim();
    if (appliedBill == null || appliedBill.isEmpty) {
      return const SizedBox.shrink();
    }
    final appliedDate = creditNote.appliedBillDate ?? creditNote.date;
    final appliedAmount = creditNote.appliedBillAmount ?? creditNote.total;
    final dateText = DateFormat('dd-MM-yyyy').format(appliedDate);
    final amountCredited = '₹${_inFmt.format(appliedAmount)}';

    return GestureDetector(
      onTap: () => setState(() => _tabExpanded = !_tabExpanded),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Credit Applied Bills',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '1',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _tabExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            if (_tabExpanded) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Bill#',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Amount Credited',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFEFF2F6),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        appliedBill.startsWith('+') ? appliedBill : '+$appliedBill',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        amountCredited,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssociatedBillRow(VendorCreditDetail creditNote) {
    return const SizedBox.shrink();
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ZButton.primary(
                label: 'New',
                icon: LucideIcons.plus,
                onPressed: () => context.go(AppRoutes.vendorCreditsCreate),
              ),
              const SizedBox(width: 12),
              ZTableMoreMenu(
                width: 40,
                height: 36,
                iconSize: 18,
                menuChildren: _buildMoreMenuChildren(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionToolbar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            _VcSelectionActionButton(
              label: 'Bulk Update',
              onTap: () => _showBulkUpdateDialog(context),
            ),
            const SizedBox(width: 8),
            CompositedTransformTarget(
              link: _pdfPrintLink,
              child: _VcSelectionIconButton(
                icon: LucideIcons.printer,
                onTap: () => _showPdfPrintMenu(context),
              ),
            ),
            const SizedBox(width: 8),
            _VcSelectionActionButton(
              label: 'Delete',
              onTap: _deleteSelectedRows,
            ),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: AppTheme.borderLight,
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(999),
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
            const SizedBox(width: 10),
            const Text(
              'Selected',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: _clearSelection,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Esc',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      LucideIcons.x,
                      size: 16,
                      color: AppTheme.errorRed,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                  onChanged: (v) =>
                      widget.onSelectAll(widget.allSelected ? false : true),
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
                                    ? AppTheme.primaryBlue.withValues(
                                        alpha: 0.55,
                                      )
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
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: _hovered ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
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
  const _DownloadMenuOption({
    required this.label,
    required this.onTap,
    this.icon,
  });
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

class _VcSelectionActionButton extends StatefulWidget {
  const _VcSelectionActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_VcSelectionActionButton> createState() =>
      _VcSelectionActionButtonState();
}

class _VcSelectionActionButtonState extends State<_VcSelectionActionButton> {
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
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF8FAFC) : Colors.white,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _VcSelectionIconButton extends StatefulWidget {
  const _VcSelectionIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_VcSelectionIconButton> createState() => _VcSelectionIconButtonState();
}

class _VcSelectionIconButtonState extends State<_VcSelectionIconButton> {
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
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF8FAFC) : Colors.white,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(widget.icon, size: 15, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}

class _VcBulkUpdateDialog extends StatefulWidget {
  const _VcBulkUpdateDialog({
    required this.selectedVendorName,
    required this.billingAddresses,
    required this.onClose,
    required this.onApply,
  });

  final String selectedVendorName;
  final List<String> billingAddresses;
  final VoidCallback onClose;
  final void Function(String field, String value) onApply;

  @override
  State<_VcBulkUpdateDialog> createState() => _VcBulkUpdateDialogState();
}

class _VcBulkUpdateDialogState extends State<_VcBulkUpdateDialog> {
  final TextEditingController _valueController = TextEditingController();
  final GlobalKey _dateFieldKey = GlobalKey();
  String? _selectedField;
  String? _selectedAddress;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Widget _buildDropdownItem(String item, bool isSelected, bool isHovered) {
    final background = isHovered
        ? AppTheme.primaryBlue
        : isSelected
        ? const Color(0xFFF1F1F3)
        : Colors.white;
    final foreground = isHovered ? Colors.white : AppTheme.textPrimary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          item,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: foreground,
          ),
        ),
      ),
    );
  }

  List<String> get _resolvedAddresses => widget.billingAddresses;

  String get _effectiveAddress =>
      _selectedAddress ??
      (_resolvedAddresses.isNotEmpty ? _resolvedAddresses.first : '');

  List<String> get _effectiveAddressLines => _effectiveAddress
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  Future<void> _pickDate() async {
    final initial = _parseDate(_valueController.text) ?? DateTime.now();
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initial,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      targetKey: _dateFieldKey,
    );
    if (picked == null) return;
    setState(() {
      _valueController.text = DateFormat('dd-MM-yyyy').format(picked);
    });
  }

  DateTime? _parseDate(String value) {
    try {
      return DateFormat('dd-MM-yyyy').parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  Widget _buildFieldContent() {
    switch (_selectedField) {
      case 'Date':
        return Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: 300,
            child: _buildDateField(),
          ),
        );
      case 'Billing Address':
        return _buildBillingAddressContent();
      case 'Notes':
        return Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: 300,
            child: _buildNotesField(),
          ),
        );
      case 'Order Number':
      default:
        return Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: 300,
            child: _buildTextField(),
          ),
        );
    }
  }

  Widget _buildTextField({String? hintText}) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _valueController,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppTheme.primaryBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return KeyedSubtree(
      key: _dateFieldKey,
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(6),
        child: IgnorePointer(
          child: TextField(
            controller: _valueController,
            readOnly: true,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'dd-MM-yyyy',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              suffixIcon: const Icon(
                LucideIcons.calendar,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.primaryBlue),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return SizedBox(
      height: 84,
      child: TextField(
        controller: _valueController,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppTheme.primaryBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildBillingAddressContent() {
    final hasSelectedAddress = _effectiveAddressLines.isNotEmpty;
    Widget buildAddressMenuAnchor(Widget child) {
      return MenuAnchor(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(6),
          shadowColor: WidgetStatePropertyAll(
            Colors.black.withValues(alpha: 0.12),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppTheme.borderLight),
            ),
          ),
        ),
        menuChildren: _resolvedAddresses.isEmpty
            ? [
                const MenuItemButton(
                  onPressed: null,
                  child: SizedBox(
                    width: 320,
                    child: Text(
                      'No billing addresses found for the selected vendor.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ]
            : _resolvedAddresses.map((address) {
                final isSelected = _effectiveAddress == address;
                return MenuItemButton(
                  style: ButtonStyle(
                    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                    minimumSize: const WidgetStatePropertyAll(Size(332, 0)),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return AppTheme.primaryBlue;
                      }
                      if (isSelected) return const Color(0xFFF1F1F3);
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.white;
                      }
                      return AppTheme.textPrimary;
                    }),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryBlue.withValues(alpha: 0.35)
                              : AppTheme.borderLight,
                        ),
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedAddress = address;
                      _valueController.text = address;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      address,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
        builder: (context, controller, _) => GestureDetector(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: child,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'VENDOR CREDIT ADDRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              if (hasSelectedAddress) ...[
                const SizedBox(width: 6),
                buildAddressMenuAnchor(
                  const Icon(
                    LucideIcons.pencil,
                    size: 13,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'Vendor Name: ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                widget.selectedVendorName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (!hasSelectedAddress)
                buildAddressMenuAnchor(
                  const Text(
                    'Choose existing address',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (hasSelectedAddress) ...[
            const SizedBox(height: 12),
            ..._effectiveAddressLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 600,
              maxWidth: 600,
              minHeight: 296.01,
            ),
            child: Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 57,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bulk Update Vendor Credit',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: widget.onClose,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Choose a field from the dropdown and update with new information.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 298,
                                child: FormDropdown<String>(
                                  value: _selectedField,
                                  items: _vcBulkUpdateFields,
                                  hint: 'Select a field',
                                  menuWidth: 298,
                                  menuMaxHeight: 204,
                                  showSearch: true,
                                  showSearchIcon: true,
                                  borderRadius: BorderRadius.circular(6),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedField = value;
                                      _valueController.clear();
                                    });
                                  },
                                  displayStringForValue: (value) => value,
                                  searchStringForValue: (value) => value,
                                  itemBuilder: _buildDropdownItem,
                                ),
                              ),
                              if (_selectedField != 'Billing Address') ...[
                                const SizedBox(width: 34),
                                Expanded(child: _buildFieldContent()),
                              ],
                            ],
                          ),
                          if (_selectedField == 'Billing Address') ...[
                            const SizedBox(height: 18),
                            _buildFieldContent(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Note: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF667085),
                              ),
                            ),
                            TextSpan(
                              text:
                                  'All the selected vendor credit will be updated with the new\ninformation and you cannot undo this action.',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF667085),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Container(
                  height: 76,
                  padding: const EdgeInsets.fromLTRB(22, 25, 22, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            final field = _selectedField?.trim() ?? '';
                            final value = field == 'Billing Address'
                                ? _effectiveAddress.trim()
                                : _valueController.text.trim();
                            if (field.isEmpty || value.isEmpty) return;
                            widget.onApply(field, value);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22B573),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: widget.onClose,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.textPrimary,
                            elevation: 0,
                            side: const BorderSide(
                              color: AppTheme.borderLight,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
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
                Icon(
                  widget.trailingIcon,
                  size: 11,
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

class _VendorCreditAttachmentOverlayContent extends StatefulWidget {
  const _VendorCreditAttachmentOverlayContent({
    required this.vendorCreditId,
    required this.entityId,
    required this.onClose,
  });

  final String vendorCreditId;
  final String? entityId;
  final VoidCallback onClose;

  @override
  State<_VendorCreditAttachmentOverlayContent> createState() =>
      _VendorCreditAttachmentOverlayContentState();
}

class _VendorCreditAttachmentOverlayContentState
    extends State<_VendorCreditAttachmentOverlayContent> {
  bool _isLoading = true;
  bool _isUploading = false;
  List<Map<String, dynamic>> _attachments = const [];

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    try {
      final res = await Supabase.instance.client
          .from('vendor_credits_attachments')
          .select(
            'id,file_name,original_file_name,file_path,file_url,file_size,file_type,uploaded_at',
          )
          .eq('vendor_credits_id', widget.vendorCreditId)
          .order('uploaded_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _attachments = (res as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attachments = const [];
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(dynamic size) {
    final parsed = double.tryParse(size?.toString() ?? '0') ?? 0;
    if (parsed <= 0) return 'File Size: 0 KB';
    if (parsed / 1024 > 1024) {
      return 'File Size: ${(parsed / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return 'File Size: ${(parsed / 1024).toStringAsFixed(1)} KB';
  }

  Future<void> _insertVendorCreditAttachmentRows({
    required SupabaseClient supabase,
    required List<Map<String, dynamic>> files,
  }) async {
    if (files.isEmpty) return;
    final uploadedBy = supabase.auth.currentUser?.id;
    const attachmentForeignKey = 'vendor_credits_id';
    final variants = <List<Map<String, dynamic>>>[
      files
          .map(
            (file) => <String, dynamic>{
              attachmentForeignKey: widget.vendorCreditId,
              'file_name': file['file_name'],
              'file_path': file['file_path'],
              'original_file_name': file['original_file_name'],
              'file_size': file['file_size'],
              'file_type': file['file_type'],
              'remarks': file['remarks'],
            },
          )
          .toList(growable: false),
      files
          .map(
            (file) => <String, dynamic>{
              attachmentForeignKey: widget.vendorCreditId,
              'file_name': file['file_name'],
              'file_url': file['file_path'],
              'original_file_name': file['original_file_name'],
              'file_size': file['file_size'],
              'file_type': file['file_type'],
              'remarks': file['remarks'],
            },
          )
          .toList(growable: false),
      files
          .map(
            (file) => <String, dynamic>{
              attachmentForeignKey: widget.vendorCreditId,
              'entity_id': widget.entityId,
              'uploaded_by': uploadedBy,
              'file_name': file['file_name'],
              'file_path': file['file_path'],
              'original_file_name': file['original_file_name'],
              'file_size': file['file_size'],
              'file_type': file['file_type'],
              'remarks': file['remarks'],
            },
          )
          .toList(growable: false),
      files
          .map(
            (file) => <String, dynamic>{
              attachmentForeignKey: widget.vendorCreditId,
              'entity_id': widget.entityId,
              'uploaded_by': uploadedBy,
              'file_name': file['file_name'],
              'file_url': file['file_path'],
              'original_file_name': file['original_file_name'],
              'file_size': file['file_size'],
              'file_type': file['file_type'],
              'remarks': file['remarks'],
            },
          )
          .toList(growable: false),
    ];

    Object? lastError;
    for (final payload in variants) {
      try {
        await supabase.from('vendor_credits_attachments').insert(payload);
        return;
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? Exception('Failed to save vendor credit attachments.');
  }

  Future<void> _uploadAttachments() async {
    if (_isUploading) return;
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty || !mounted) return;

      final totalCount = _attachments.length + picked.files.length;
      if (totalCount > 5) {
        ZerpaiToast.error(context, 'You can upload a maximum of 5 files.');
        return;
      }

      for (final file in picked.files) {
        if (file.size > 10 * 1024 * 1024) {
          ZerpaiToast.error(context, '${file.name} exceeds the 10MB limit.');
          return;
        }
      }

      setState(() => _isUploading = true);

      final storage = StorageService();
      final supabase = Supabase.instance.client;
      final rows = <Map<String, dynamic>>[];
      for (final file in picked.files) {
        final uploadedPath = await storage.uploadPaymentAttachment(file);
        if (uploadedPath == null || uploadedPath.isEmpty) {
          throw Exception('Failed to upload attachment: ${file.name}');
        }
        rows.add(<String, dynamic>{
          'file_name': file.name,
          'file_path': uploadedPath,
          'original_file_name': file.name,
          'file_size': file.size,
          'file_type': file.extension?.toLowerCase(),
          'remarks': null,
        });
      }

      await _insertVendorCreditAttachmentRows(
        supabase: supabase,
        files: rows,
      );
      await _loadAttachments();
      if (!mounted) return;
      ZerpaiToast.success(context, 'Attachments uploaded successfully');
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to upload attachments: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildUploadBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: DottedBorder(
        color: const Color(0xFFD7DEE8),
        dashPattern: const [4, 3],
        radius: const Radius.circular(6),
        borderType: BorderType.RRect,
        strokeWidth: 1,
        child: InkWell(
          onTap: _isUploading ? null : _uploadAttachments,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 52,
            width: double.infinity,
            color: Colors.white,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUploading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    LucideIcons.upload,
                    size: 16,
                    color: Color(0xFF3B82F6),
                  ),
                const SizedBox(width: 8),
                Text(
                  _isUploading ? 'Uploading...' : 'Upload your Files',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5B6472),
                  ),
                ),
                if (!_isUploading) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: Color(0xFF7B8794),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -5,
          right: 88,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
            ),
          ),
        ),
        Container(
          width: 314,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                child: Row(
                  children: [
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          color: Color(0xFFFF4D4F),
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEF1F5)),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_attachments.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Text(
                    'No Files Attached',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F3F5),
                ),
                _buildUploadBox(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 11),
                  child: Text(
                    'You can upload a maximum of 5 files, 10MB each',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ] else ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    itemCount: _attachments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final att = _attachments[index];
                      final name = att['original_file_name']
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                          ? att['original_file_name'].toString().trim()
                          : att['file_name']?.toString() ?? 'Unnamed';
                      final fileType =
                          att['file_type']?.toString().toLowerCase() ?? '';
                      final isPdf =
                          fileType == 'pdf' ||
                          name.toLowerCase().endsWith('.pdf');
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8EDF3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isPdf
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFE8F1FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Icon(
                                  LucideIcons.fileText,
                                  color: isPdf
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF3B82F6),
                                  size: 17,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatFileSize(att['file_size']),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F3F5),
                ),
                _buildUploadBox(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 11),
                  child: Text(
                    'You can upload a maximum of 5 files, 10MB each',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _VcHistoryEvent {
  const _VcHistoryEvent({
    required this.username,
    required this.time,
    required this.content,
    required this.icon,
  });

  final String username;
  final DateTime time;
  final String content;
  final IconData icon;
}

class _VendorCreditHistorySidebar extends StatefulWidget {
  const _VendorCreditHistorySidebar({
    required this.rawRow,
    required this.creditNote,
    required this.entityId,
    required this.orgId,
    required this.onClose,
  });

  final _VendorCreditRow rawRow;
  final VendorCreditDetail creditNote;
  final String? entityId;
  final String? orgId;
  final VoidCallback onClose;

  @override
  State<_VendorCreditHistorySidebar> createState() =>
      _VendorCreditHistorySidebarState();
}

class _VendorCreditHistorySidebarState
    extends State<_VendorCreditHistorySidebar> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _attachments = const [];
  List<Map<String, dynamic>> _comments = const [];
  late final TextEditingController _commentController;
  bool _isSavingComment = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _loadSidebarData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSidebarData() async {
    await Future.wait([_loadAttachments(), _loadComments()]);
  }

  Future<void> _loadAttachments() async {
    try {
      final res = await Supabase.instance.client
          .from('vendor_credits_attachments')
          .select('id,uploaded_at,file_name,original_file_name')
          .eq('vendor_credits_id', widget.rawRow.id);
      if (!mounted) return;
      setState(() {
        _attachments = (res as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attachments = const [];
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      final res = await Supabase.instance.client
          .from('audit_logs')
          .select('id,action,actor_name,new_values,created_at')
          .eq('table_name', 'vendor_credits')
          .eq('record_id', widget.rawRow.id)
          .inFilter('action', const ['COMMENT', 'REFUND'])
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _comments = (res as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _comments = const [];
        _isLoading = false;
      });
    }
  }

  String get _currentActorName {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'system';
  }

  Future<void> _saveComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _isSavingComment) return;
    final entityId = widget.entityId?.trim();
    if (entityId == null || entityId.isEmpty) {
      ZerpaiToast.error(context, 'Entity is not selected.');
      return;
    }

    try {
      setState(() => _isSavingComment = true);
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      await supabase.from('audit_logs').insert({
        'table_name': 'vendor_credits',
        'record_id': widget.rawRow.id,
        'action': 'COMMENT',
        'old_values': null,
        'new_values': {
          'comment': comment,
          'credit_note_number': widget.creditNote.creditNoteNumber,
        },
        'user_id':
            user?.id ?? '00000000-0000-0000-0000-000000000000',
        'org_id':
            widget.orgId?.trim().isNotEmpty == true
            ? widget.orgId!.trim()
            : '00000000-0000-0000-0000-000000000000',
        'entity_id': entityId,
        'actor_name': _currentActorName,
        'schema_name': 'public',
        'record_pk': widget.creditNote.creditNoteNumber,
        'changed_columns': const ['comment'],
        'source': 'ui',
        'module_name': 'vendor_credits',
      });
      _commentController.clear();
      await _loadComments();
      if (!mounted) return;
      ZerpaiToast.success(context, 'Comment added successfully');
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to add comment: $e');
    } finally {
      if (mounted) {
        setState(() => _isSavingComment = false);
      }
    }
  }

  List<_VcHistoryEvent> get _events {
    final events = <_VcHistoryEvent>[
      _VcHistoryEvent(
        username: widget.creditNote.vendorName.isNotEmpty
            ? widget.creditNote.vendorName
            : 'system',
        time: widget.creditNote.date,
        content:
            'Vendor Credit ${widget.creditNote.creditNoteNumber} created for ${widget.rawRow.amount}.',
        icon: LucideIcons.fileSpreadsheet,
      ),
    ];

    for (final attachment in _attachments) {
      final uploadedAt = DateTime.tryParse(
        attachment['uploaded_at']?.toString() ?? '',
      );
      final fileName =
          attachment['original_file_name']?.toString().trim().isNotEmpty == true
          ? attachment['original_file_name'].toString().trim()
          : attachment['file_name']?.toString() ?? 'Attachment';
      events.add(
        _VcHistoryEvent(
          username: widget.creditNote.vendorName.isNotEmpty
              ? widget.creditNote.vendorName
              : 'system',
          time: uploadedAt ?? widget.creditNote.date,
          content: '$fileName attached to vendor credit.',
          icon: LucideIcons.paperclip,
        ),
      );
    }

    for (final comment in _comments) {
      final action = comment['action']?.toString();
      final newValues = comment['new_values'];
      if (action == 'REFUND' && newValues is Map) {
        final amount = double.tryParse(
          newValues['refund_amount']?.toString() ?? '',
        );
        final refundNumber = newValues['refund_number']?.toString();
        final refundDate = newValues['refund_date']?.toString();
        final paymentMode = newValues['payment_mode']?.toString();
        final depositTo = newValues['deposit_to']?.toString();
        final createdAt = DateTime.tryParse(
          comment['created_at']?.toString() ?? '',
        );
        final actorName = comment['actor_name']?.toString().trim();
        final refundLabel = refundNumber?.isNotEmpty == true
            ? 'Refund #$refundNumber'
            : 'Refund';
        final amountLabel = amount == null ? '' : ' for ₹${amount.toStringAsFixed(2)}';
        final viaLabel = paymentMode?.isNotEmpty == true
            ? ' via $paymentMode'
            : '';
        final depositLabel = depositTo?.isNotEmpty == true
            ? ' to $depositTo'
            : '';
        events.add(
          _VcHistoryEvent(
            username: actorName?.isNotEmpty == true ? actorName! : 'system',
            time: createdAt ?? widget.creditNote.date,
            content: '$refundLabel recorded$amountLabel$viaLabel$depositLabel'
                '${refundDate?.isNotEmpty == true ? ' on $refundDate' : ''}.',
            icon: LucideIcons.undo2,
          ),
        );
        continue;
      }

      String content = '';
      if (newValues is Map) {
        content = newValues['comment']?.toString().trim() ?? '';
      }
      if (content.isEmpty) continue;

      final createdAt = DateTime.tryParse(
        comment['created_at']?.toString() ?? '',
      );
      final actorName = comment['actor_name']?.toString().trim();
      events.add(
        _VcHistoryEvent(
          username: actorName?.isNotEmpty == true ? actorName! : 'system',
          time: createdAt ?? widget.creditNote.date,
          content: content,
          icon: LucideIcons.messageSquare,
        ),
      );
    }

    events.sort((a, b) => b.time.compareTo(a.time));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    return Container(
      width: 360,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                const Text(
                  'Comments & History',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.x,
                      color: Color(0xFFFF4D4F),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE9EDF3)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFD9E1EC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5F7FA),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE8EDF3),
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'B',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 18),
                                    Text(
                                      'I',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontStyle: FontStyle.italic,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 18),
                                    Text(
                                      'U',
                                      style: TextStyle(
                                        fontSize: 15,
                                        decoration: TextDecoration.underline,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  8,
                                ),
                                child: TextField(
                                  controller: _commentController,
                                  maxLines: 3,
                                  minLines: 3,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    isCollapsed: true,
                                    border: InputBorder.none,
                                    hintText: 'Type your comment here...',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF98A2B3),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Color(0xFFE8EDF3),
                                    ),
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: _commentController.text.trim().isEmpty ||
                                            _isSavingComment
                                        ? null
                                        : _saveComment,
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(0, 30),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      foregroundColor: const Color(0xFF98A2B3),
                                      disabledForegroundColor: const Color(
                                        0xFF98A2B3,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(3),
                                        side: const BorderSide(
                                          color: Color(0xFFD9E1EC),
                                        ),
                                      ),
                                    ),
                                    child: _isSavingComment
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Add Comment',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Text(
                              'ALL COMMENTS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF667085),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${events.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE9EDF3),
                        ),
                        const SizedBox(height: 16),
                        for (final e in events) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  e.icon == LucideIcons.messageSquare
                                      ? LucideIcons.user
                                      : LucideIcons.fileText,
                                  size: 12,
                                  color: const Color(0xFFF4B400),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            e.username,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          DateFormat(
                                            'dd-MM-yyyy hh:mm a',
                                          ).format(e.time),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF98A2B3),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8FB),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        e.content,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.55,
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
                      ],
                    ),
                  ),
          ),
        ],
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
    required this.onClose,
    required this.onViewJournal,
    required this.onDelete,
  });

  final VoidCallback onRefund;
  final VoidCallback onVoid;
  final VoidCallback onClone;
  final VoidCallback onClose;
  final VoidCallback onViewJournal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(4),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.borderLight),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
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
        _MoreMenuItem(label: 'Close', onTap: onClose),
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
  const _MoreMenuItem({required this.label, required this.onTap, this.color});

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
    required this.vendorId,
    required this.vendorName,
    required this.billingAddresses,
    required this.status,
    required this.amount,
    required this.balance,
  });

  final String id;
  final String date;
  final String creditNoteNumber;
  final String referenceNumber;
  final String vendorId;
  final String vendorName;
  final List<String> billingAddresses;
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
                        const SizedBox(height: 30),
                        const _PdfOrgLogo(width: 200, height: 80),
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
          child: _VcCornerRibbon(
            label: creditNote.status,
            color: _ribbonColor(creditNote.status),
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

class _VcCornerRibbon extends StatelessWidget {
  const _VcCornerRibbon({required this.label, required this.color});

  final String label;
  final Color color;

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
            painter: _VcCornerFoldPainter(color: color),
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

class _VcCornerFoldPainter extends CustomPainter {
  _VcCornerFoldPainter({required this.color});

  final Color color;

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
  bool shouldRepaint(covariant _VcCornerFoldPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ── Journal Section ───────────────────────────────────────────────────────────

class _VcJournalSection extends StatelessWidget {
  const _VcJournalSection({super.key, required this.creditNote});
  final VendorCreditDetail creditNote;

  static const Color _colHeaderColor = Color(0xFF8A94A6);
  static const Color _dividerColor = Color(0xFFE5E7EB);

  Future<List<Map<String, dynamic>>> _fetchVendorCreditJournals(String vcId) async {
    final supabase = Supabase.instance.client;
    try {
      final res = await supabase
          .from('journal_entry_lines')
          .select('*, account:accounts(user_account_name, system_account_name)')
          .eq('source_id', vcId)
          .eq('source_type', 'VENDOR_CREDIT');
      if (res.isNotEmpty) {
        return List<Map<String, dynamic>>.from(res);
      }
    } catch (_) {}

    try {
      final header = await supabase
          .from('journal_entries')
          .select('id')
          .eq('source_document_id', vcId)
          .eq('source_document_type', 'vendor_credits')
          .maybeSingle();
      if (header != null && header['id'] != null) {
        final res2 = await supabase
            .from('journal_entry_lines')
            .select('*, account:accounts(user_account_name, system_account_name)')
            .eq('journal_entry_id', header['id']);
        if (res2.isNotEmpty) {
          return List<Map<String, dynamic>>.from(res2);
        }
      }
    } catch (_) {}

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final fmt = _inFmt;
    final orgName = creditNote.sourceOfSupply.trim().isNotEmpty
        ? creditNote.sourceOfSupply.trim()
        : 'ZABNIX PRIVATE LIMITED';

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchVendorCreditJournals(creditNote.id),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> txs = [];
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.isNotEmpty) {
          txs = snapshot.data!;
        } else {
          // Standard fallback entries matching exact transaction
          txs = [
            {
              'account': {'user_account_name': 'Discount'},
              'debit': 0.0,
              'credit': creditNote.total,
            },
            {
              'account': {'system_account_name': 'Accounts Payable'},
              'debit': creditNote.total,
              'credit': 0.0,
            },
          ];
        }

        double totalDebit = 0;
        double totalCredit = 0;
        for (final tx in txs) {
          totalDebit += double.tryParse(tx['debit']?.toString() ?? '0') ?? 0;
          totalCredit += double.tryParse(tx['credit']?.toString() ?? '0') ?? 0;
        }

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
                          bottom: BorderSide(color: AppTheme.primaryBlue, width: 2),
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
                            horizontal: 7,
                            vertical: 2,
                          ),
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
                    ...txs.map((tx) {
                      final accountName = tx['account']?['user_account_name'] ??
                          tx['account']?['system_account_name'] ??
                          'Accounts Payable';
                      final debit = double.tryParse(tx['debit']?.toString() ?? '0') ?? 0;
                      final credit = double.tryParse(tx['credit']?.toString() ?? '0') ?? 0;

                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: _dividerColor, width: 0.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                accountName,
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
                                fmt.format(debit),
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
                                fmt.format(credit),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

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
      },
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
    child: const Text(
      'LOGO',
      style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.8),
    ),
  );
}

// ── Shared PDF generator (used by both overview + report pages) ──────────────

Future<Uint8List> _buildVcPdfBytes(
  VendorCreditDetail creditNote,
  OrgSettings? orgSettings,
) async {
  final doc = pw.Document();
  pw.ThemeData pdfTheme;
  try {
    final regularData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    pdfTheme = pw.ThemeData.withFont(
      base: pw.Font.ttf(regularData),
      bold: pw.Font.ttf(boldData),
    );
  } catch (_) {
    pdfTheme = pw.ThemeData.withFont();
  }

  pw.MemoryImage? logoImage;
  final logoUrl = orgSettings?.logoUrl;
  if (logoUrl != null && logoUrl.trim().isNotEmpty) {
    try {
      final res = await Dio().get<List<int>>(
        logoUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = res.data;
      if (data != null && data.isNotEmpty) {
        logoImage = pw.MemoryImage(Uint8List.fromList(data));
      }
    } catch (_) {}
  }

  final fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final itemRows = creditNote.items
      .map(
        (item) => [
          item.name,
          item.description.trim().isEmpty ? '-' : item.description.trim(),
          item.quantity.toStringAsFixed(2),
          fmt.format(item.rate),
          item.taxRate,
          fmt.format(item.amount),
        ],
      )
      .toList(growable: false);

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        theme: pdfTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
      ),
      build: (ctx) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 120,
                      height: 54,
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Container(
                      width: 120,
                      height: 54,
                      color: PdfColor.fromHex('#101820'),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'LOGO',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    orgSettings?.name.trim().isNotEmpty == true
                        ? orgSettings!.name.trim()
                        : 'YOUR COMPANY NAME',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    (orgSettings?.paymentStubAddress?.trim().isNotEmpty == true)
                        ? orgSettings!.paymentStubAddress!.trim()
                        : 'Address Line 1\nCity, State PIN',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      lineSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'VENDOR CREDIT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Credit Note# ${creditNote.creditNoteNumber}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VENDOR ADDRESS',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    creditNote.vendorName,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1463B8'),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    creditNote.billingAddress.trim().isEmpty
                        ? '-'
                        : creditNote.billingAddress.trim(),
                    style: const pw.TextStyle(
                      fontSize: 10.5,
                      color: PdfColors.grey700,
                      lineSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _vcPdfMeta('Credit Date', DateFormat('dd-MM-yyyy').format(creditNote.date)),
                _vcPdfMeta('Reference#', creditNote.referenceNumber),
                _vcPdfMeta('Source of Supply', creditNote.sourceOfSupply),
                _vcPdfMeta('Destination', creditNote.destinationOfSupply),
                _vcPdfMeta('Status', creditNote.status),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellStyle: const pw.TextStyle(fontSize: 9.5),
          cellAlignments: const {
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
          },
          headers: const ['Item', 'Description', 'Qty', 'Rate', 'Tax', 'Amount'],
          data: itemRows,
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
          headerPadding: const pw.EdgeInsets.all(8),
          cellPadding: const pw.EdgeInsets.all(8),
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          children: [
            pw.Spacer(),
            pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _vcPdfTotal('Sub Total', fmt.format(creditNote.subtotal)),
                  _vcPdfTotal('Tax', fmt.format(creditNote.taxAmount)),
                  _vcPdfTotal('Shipping', fmt.format(creditNote.shipping)),
                  _vcPdfTotal('Adjustment', fmt.format(creditNote.adjustment)),
                  pw.Divider(color: PdfColors.grey400),
                  _vcPdfTotal('Total', fmt.format(creditNote.total), bold: true),
                  _vcPdfTotal('Balance', fmt.format(creditNote.balance), bold: true),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _vcPdfMeta(String label, String value) {
  final v = value.trim().isEmpty ? '-' : value.trim();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.TextSpan(
            text: v,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _vcPdfTotal(String label, String value, {bool bold = false}) {
  final style = pw.TextStyle(
    fontSize: 10.5,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.Text(value, style: style, textAlign: pw.TextAlign.right),
      ],
    ),
  );
}

// ── Refund History Section ───────────────────────────────────────────────────

class _VendorCreditRefundHistorySection extends StatefulWidget {
  const _VendorCreditRefundHistorySection({required this.vendorCreditId});

  final String vendorCreditId;

  @override
  State<_VendorCreditRefundHistorySection> createState() =>
      _VendorCreditRefundHistorySectionState();
}

class _VendorCreditRefundHistorySectionState
    extends State<_VendorCreditRefundHistorySection> {
  bool _isExpanded = true;

  Future<List<_VendorCreditRefundHistoryRow>> _loadRefunds() async {
    final rows = await Supabase.instance.client
        .from('audit_logs')
        .select('new_values')
        .eq('table_name', 'vendor_credits')
        .eq('record_id', widget.vendorCreditId)
        .eq('action', 'REFUND')
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) {
          final values = row['new_values'];
          if (values is! Map) return null;
          final amount = double.tryParse(
            values['refund_amount']?.toString() ?? '',
          );
          if (amount == null || amount <= 0) return null;
          return _VendorCreditRefundHistoryRow(
            date: values['refund_date']?.toString() ?? '',
            paymentMode: values['payment_mode']?.toString() ?? '',
            amount: amount,
          );
        })
        .whereType<_VendorCreditRefundHistoryRow>()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_VendorCreditRefundHistoryRow>>(
      future: _loadRefunds(),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <_VendorCreditRefundHistoryRow>[];
        if (rows.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                hoverColor: Colors.transparent,
                child: SizedBox(
                  height: 62,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Refund History',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textBody,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 15,
                                  height: 15,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${rows.length}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_isExpanded)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 104,
                                height: 3,
                                color: AppTheme.primaryBlue,
                              ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          _isExpanded
                              ? LucideIcons.chevronDown
                              : LucideIcons.chevronRight,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isExpanded) ...[
                const Divider(height: 1, color: AppTheme.borderLight),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          SizedBox(
                            width: 180,
                            child: Text('Date', style: _refundHeaderStyle),
                          ),
                          SizedBox(
                            width: 180,
                            child: Text(
                              'Payment Mode',
                              style: _refundHeaderStyle,
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: Text(
                              'Amount Refunded',
                              style: _refundHeaderStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...rows.map(
                        (row) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppTheme.borderLight),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 180,
                                child: Text(
                                  row.date.isEmpty ? '-' : row.date,
                                  style: _refundValueStyle,
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: Text(
                                  row.paymentMode.isEmpty
                                      ? '-'
                                      : row.paymentMode,
                                  style: _refundValueStyle,
                                ),
                              ),
                              SizedBox(
                                width: 160,
                                child: Text(
                                  '₹${_inFmt.format(row.amount)}',
                                  style: _refundAmountStyle,
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
            ],
          ),
        );
      },
    );
  }
}

const _refundHeaderStyle = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
  color: AppTheme.textSecondary,
);

const _refundValueStyle = TextStyle(
  fontSize: 12.5,
  color: AppTheme.textPrimary,
);

const _refundAmountStyle = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
  color: AppTheme.textPrimary,
);

class _VendorCreditRefundHistoryRow {
  const _VendorCreditRefundHistoryRow({
    required this.date,
    required this.paymentMode,
    required this.amount,
  });

  final String date;
  final String paymentMode;
  final double amount;
}

// ── Inline Refund View ────────────────────────────────────────────────────────

class _VendorCreditRefundInlineView extends ConsumerStatefulWidget {
  final VendorCreditDetail creditNote;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  const _VendorCreditRefundInlineView({
    required this.creditNote,
    required this.onCancel,
    required this.onSaved,
  });

  @override
  ConsumerState<_VendorCreditRefundInlineView> createState() =>
      __VendorCreditRefundInlineViewState();
}

class __VendorCreditRefundInlineViewState
    extends ConsumerState<_VendorCreditRefundInlineView> {
  final GlobalKey _datePickerKey = GlobalKey();

  late final TextEditingController _refundedOnController;
  late final TextEditingController _referenceController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  String _paymentMode = 'Cash';
  PaidThroughItem? _depositTo;
  DateTime _refundedOnDate = DateTime.now();
  bool _isSaving = false;

  List<String> _paymentModes = [
    'Cash',
    'Cheque',
    'Credit Card',
    'Debit Card',
    'Netbanking',
    'UPI',
  ];

  List<PaidThroughItem> _buildPaidThroughOptions(List<AccountNode> roots) {
    final List<PaidThroughItem> options = [];

    final List<AccountNode> allAccounts = [];
    void flatten(List<AccountNode> nodes) {
      for (final node in nodes) {
        allAccounts.add(node);
        if (node.children.isNotEmpty) {
          flatten(node.children);
        }
      }
    }

    flatten(roots);

    final Map<String, AccountNode> accountMap = {
      for (final acc in allAccounts) acc.id: acc,
    };

    final Set<String> parentIds = {};
    for (final acc in allAccounts) {
      if (acc.parentId != null && acc.parentId!.isNotEmpty) {
        parentIds.add(acc.parentId!);
      }
    }

    final Set<String> processedIds = {};

    for (final parentId in parentIds) {
      final parentNode = accountMap[parentId];
      if (parentNode == null) continue;

      options.add(
        PaidThroughItem(parentNode.systemAccountName, isHeader: true),
      );
      processedIds.add(parentId);

      final children = allAccounts
          .where((acc) => acc.parentId == parentId)
          .toList();
      for (final child in children) {
        options.add(
          PaidThroughItem(
            child.systemAccountName,
            id: child.id,
            isBullet: true,
          ),
        );
        processedIds.add(child.id);
      }
    }

    for (final acc in allAccounts) {
      if (processedIds.contains(acc.id)) continue;

      final String nameLower = acc.systemAccountName.toLowerCase();
      if (nameLower == 'assets' ||
          nameLower == 'liabilities' ||
          nameLower == 'income' ||
          nameLower == 'expenses' ||
          nameLower == 'equity') {
        continue;
      }

      options.add(
        PaidThroughItem(
          acc.systemAccountName,
          id: acc.id,
          isHeader: false,
          isBullet: false,
        ),
      );
    }

    if (options.isEmpty) {
      return const [
        PaidThroughItem('Cash', isHeader: true),
        PaidThroughItem('Petty Cash', isBullet: true),
        PaidThroughItem('Undeposited Funds', isBullet: true),
        PaidThroughItem('Bank', isHeader: true),
        PaidThroughItem('Bank Account', isBullet: true),
      ];
    }

    return options;
  }

  Future<void> _loadPaymentModesFromDb() async {
    final entityId = ref.read(entityProvider).entityId ?? '';
    if (entityId.isEmpty) return;

    try {
      final supabase = Supabase.instance.client;
      var response = await supabase
          .from('payment_made_payment_mode')
          .select('name, is_default')
          .eq('entity_id', entityId)
          .eq('is_deleted', false)
          .order('name');

      if (response.isEmpty) {
        final List<String> seedDefaults = [
          'Cash',
          'Cheque',
          'Credit Card',
          'Debit Card',
          'Netbanking',
          'UPI',
        ];
        final seedRows = seedDefaults
            .map(
              (mode) => {
                'entity_id': entityId,
                'name': mode,
                'is_default': mode.toLowerCase() == 'cash',
                'is_deleted': false,
              },
            )
            .toList();

        await supabase.from('payment_made_payment_mode').insert(seedRows);

        response = await supabase
            .from('payment_made_payment_mode')
            .select('name, is_default')
            .eq('entity_id', entityId)
            .eq('is_deleted', false)
            .order('name');
      }

      if (response.isNotEmpty) {
        final List<String> loadedModes = List<String>.from(
          response.map((e) => e['name'] as String),
        );
        String defaultMode = _paymentMode;
        for (final row in response) {
          if (row['is_default'] == true && row['name'] != null) {
            defaultMode = row['name'] as String;
            break;
          }
        }
        if (mounted) {
          setState(() {
            _paymentModes = loadedModes;
            if (_paymentModes.contains(defaultMode)) {
              _paymentMode = defaultMode;
            } else if (_paymentModes.isNotEmpty) {
              _paymentMode = _paymentModes.first;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _showConfigurePaymentModeDialog() async {
    final entityId = ref.read(entityProvider).entityId ?? '';
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ConfigurePaymentModeDialog(
        entityId: entityId,
        initialModes: _paymentModes,
        onSave: (updatedModes) {
          if (updatedModes.isNotEmpty) {
            setState(() {
              _paymentModes = updatedModes;
              if (!_paymentModes.contains(_paymentMode)) {
                _paymentMode = _paymentModes.first;
              }
            });
            _loadPaymentModesFromDb();
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _refundedOnController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(_refundedOnDate),
    );
    _referenceController = TextEditingController();
    final balanceAmount = widget.creditNote.balance > 0
        ? widget.creditNote.balance
        : (widget.creditNote.total > 0 ? widget.creditNote.total : 950.0);
    _amountController = TextEditingController(
      text: balanceAmount.toStringAsFixed(0),
    );
    _descriptionController = TextEditingController();
    _loadPaymentModesFromDb();
  }

  @override
  void dispose() {
    _refundedOnController.dispose();
    _referenceController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _refundedOnDate,
      targetKey: _datePickerKey,
    );
    if (picked != null) {
      setState(() {
        _refundedOnDate = picked;
        _refundedOnController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _handleSave() async {
    if (_refundedOnController.text.trim().isEmpty) {
      ZerpaiToast.error(context, 'Please select the refund date.');
      return;
    }

    final rawAmount = double.tryParse(_amountController.text.trim());
    if (rawAmount == null || rawAmount <= 0) {
      ZerpaiToast.error(context, 'Please enter a valid refund amount.');
      return;
    }

    if (_depositTo == null || _depositTo!.isHeader) {
      ZerpaiToast.error(context, 'Please select an account to deposit the refund.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final creditRows = await supabase
          .from('vendor_credits')
          .select('id, entity_id')
          .eq('id', widget.creditNote.id)
          .limit(1);
      if (creditRows.isEmpty) {
        ZerpaiToast.error(context, 'Vendor credit not found for refund save.');
        return;
      }

      final creditRow = Map<String, dynamic>.from(creditRows.first as Map);
      final entityId = creditRow['entity_id']?.toString().trim() ?? '';
      if (entityId.isEmpty) {
        ZerpaiToast.error(context, 'Entity is not selected.');
        return;
      }

      final existingRefunds = await supabase
          .from('audit_logs')
          .select('id')
          .eq('table_name', 'vendor_credits')
          .eq('record_id', widget.creditNote.id)
          .eq('action', 'REFUND');
      final user = supabase.auth.currentUser;
      final refundNumber = (existingRefunds as List).length + 1;

      await supabase.from('audit_logs').insert({
        'table_name': 'vendor_credits',
        'record_id': widget.creditNote.id,
        'action': 'REFUND',
        'old_values': null,
        'new_values': {
          'refund_date': _refundedOnController.text.trim(),
          'refund_number': refundNumber.toString(),
          'payment_mode': _paymentMode,
          'deposit_to': _depositTo!.label,
          'deposit_to_account_id': _depositTo!.id,
          'refund_amount': rawAmount,
          'reference_number': _referenceController.text.trim(),
          'description': _descriptionController.text.trim(),
        },
        'user_id':
            user?.id ?? '00000000-0000-0000-0000-000000000000',
        'org_id': '00000000-0000-0000-0000-000000000000',
        'entity_id': entityId,
        'actor_name': user?.email?.split('@').first ?? 'system',
        'schema_name': 'public',
        'record_pk': widget.creditNote.creditNoteNumber,
        'changed_columns': const ['status'],
        'source': 'ui',
        'module_name': 'vendor_credits',
      });

      await supabase
          .from('vendor_credits')
          .update({
            'status': 'closed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('vendor_credit_number', widget.creditNote.creditNoteNumber);

      if (!mounted) return;
      ZerpaiToast.success(
        context,
        'Refund recorded for ${widget.creditNote.creditNoteNumber}.',
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to save refund: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '₹$intPart.${parts[1]}';
  }

  Widget _buildFormRow({
    required String label,
    bool isRequired = false,
    required Widget field,
    Widget? extraRight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isRequired
                      ? AppTheme.errorRed
                      : AppTheme.textPrimary,
                ),
                children: [
                  if (isRequired)
                    const TextSpan(
                      text: '*',
                      style: TextStyle(
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: 360, child: field),
          if (extraRight != null) ...[
            const SizedBox(width: 16),
            extraRight,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceAmount = widget.creditNote.balance > 0
        ? widget.creditNote.balance
        : (widget.creditNote.total > 0 ? widget.creditNote.total : 950.0);
    final titleText = 'Refund (${widget.creditNote.creditNoteNumber})';

    final accountsState = ref.watch(chartOfAccountsProvider);
    final depositOptions = _buildPaidThroughOptions(accountsState.roots);

    if (_depositTo == null && depositOptions.isNotEmpty) {
      for (final opt in depositOptions) {
        if (!opt.isHeader &&
            (opt.label == 'Petty Cash' ||
                opt.label == 'Undeposited Funds' ||
                opt.label.contains('Cash'))) {
          _depositTo = opt;
          break;
        }
      }
      if (_depositTo == null) {
        final firstValid = depositOptions.firstWhere(
          (opt) => !opt.isHeader,
          orElse: () => depositOptions.first,
        );
        _depositTo = firstValid;
      }
    }

    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 32),

            _buildFormRow(
              label: 'Refunded On',
              isRequired: true,
              field: GestureDetector(
                key: _datePickerKey,
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: _refundedOnController,
                    hintText: 'dd-MM-yyyy',
                    suffixWidget: const Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            _buildFormRow(
              label: 'Payment Mode',
              field: FormDropdown<String>(
                value: _paymentMode,
                items: _paymentModes,
                height: 36,
                showSearch: true,
                forceDownward: true,
                showSettings: true,
                settingsLabel: 'Configure Payment Mode',
                settingsIcon: Icons.add_circle_outline,
                onSettingsTap: _showConfigurePaymentModeDialog,
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMode = val);
                },
                displayStringForValue: (val) => val,
                itemBuilder: (item, isSelected, isHovered) {
                  final Color bg = isHovered
                      ? AppTheme.primaryBlue
                      : (isSelected
                            ? const Color(0xFFF3F4F6)
                            : Colors.transparent);
                  final Color textColor = isHovered
                      ? Colors.white
                      : AppTheme.textPrimary;

                  return Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    color: bg,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            LucideIcons.check,
                            size: 16,
                            color: isHovered
                                ? Colors.white
                                : AppTheme.primaryBlue,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            _buildFormRow(
              label: 'Reference#',
              field: CustomTextField(
                controller: _referenceController,
              ),
            ),

            _buildFormRow(
              label: 'Amount',
              isRequired: true,
              field: CustomTextField(
                controller: _amountController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                prefixWidget: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Text(
                    'INR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              extraRight: Text(
                'Balance : ${_fmt(balanceAmount)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),

            _buildFormRow(
              label: 'Deposit To',
              isRequired: true,
              field: FormDropdown<PaidThroughItem>(
                value: _depositTo,
                items: depositOptions,
                height: 36,
                showSearch: true,
                forceDownward: true,
                isItemEnabled: (item) => !item.isHeader,
                onChanged: (val) {
                  if (val != null && !val.isHeader) {
                    setState(() => _depositTo = val);
                  }
                },
                displayStringForValue: (v) => v.label,
                searchStringForValue: (v) => v.label,
                itemBuilder: (item, isSelected, isHovered) {
                  if (item.isHeader) {
                    return Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.transparent,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }

                  final Color bg = isHovered
                      ? AppTheme.primaryBlue
                      : (isSelected
                            ? const Color(0xFFF3F4F6)
                            : Colors.transparent);
                  final Color textColor = isHovered
                      ? Colors.white
                      : (isSelected
                            ? AppTheme.textPrimary
                            : (item.isBullet
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary));
                  final String displayLabel = item.isBullet
                      ? '• ${item.label}'
                      : item.label;

                  return Container(
                    height: 36,
                    padding: EdgeInsets.only(
                      left: item.isBullet ? 24 : 12,
                      right: 12,
                    ),
                    color: bg,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            LucideIcons.check,
                            size: 16,
                            color: isHovered
                                ? Colors.white
                                : AppTheme.primaryBlue,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            _buildFormRow(
              label: 'Description',
              field: CustomTextField(
                controller: _descriptionController,
                maxLines: 3,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.borderLight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
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
    );
  }
}


