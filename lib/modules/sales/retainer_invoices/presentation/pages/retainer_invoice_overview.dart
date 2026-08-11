import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/providers/retainer_invoices_provider.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/models/retainer_invoices_model.dart'
    as provider_model;
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';

import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/document/zerpai_document_view.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class RetainerInvoice {
  final String id;
  final String customerName;
  final String date;
  final double amount;
  final double balanceDue;
  final String status;
  final String drawStatus;
  final String companyName;
  final List<String> companyAddress;
  final String companyGstin;
  final String companyPhone;
  final String companyEmail;
  final List<String> billToAddress;
  final List<RetainerInvoiceItem> items;

  const RetainerInvoice({
    required this.id,
    required this.customerName,
    required this.date,
    required this.amount,
    required this.balanceDue,
    required this.status,
    required this.drawStatus,
    required this.companyName,
    required this.companyAddress,
    required this.companyGstin,
    required this.companyPhone,
    required this.companyEmail,
    required this.billToAddress,
    required this.items,
  });
}

class RetainerInvoiceItem {
  final int index;
  final String description;
  final double amount;

  const RetainerInvoiceItem({
    required this.index,
    required this.description,
    required this.amount,
  });
}

class FilterItem {
  final String label;
  const FilterItem(this.label);
}

// ─── Mock Data ───────────────────────────────────────────────────────────────

const List<RetainerInvoice> _mockInvoices = [
  RetainerInvoice(
    id: '4',
    customerName: 'Oscorp Industries',
    date: '11-06-2026',
    amount: 41300.00,
    balanceDue: 0.0,
    status: 'SENT',
    drawStatus: 'PAID',
    companyName: 'ZABNIX PRIVATE LIMITED',
    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],
    companyGstin: '32AACCZ4912F1ZL',
    companyPhone: '8086355500',
    companyEmail: 'zabnixprivatelimited@gmail.com',
    billToAddress: ['ap@oscorp.com', 'Oscorp HQ'],
    items: [
      RetainerInvoiceItem(
        index: 1,
        description: 'Biochemical research consultation',
        amount: 35000.00,
      ),
    ],
  ),
  RetainerInvoice(
    id: '3',
    customerName: 'Stark Industries',
    date: '08-06-2026',
    amount: 134400.00,
    balanceDue: 134400.00,
    status: 'DRAFT',
    drawStatus: 'AWAITING PAYMENT',
    companyName: 'ZABNIX PRIVATE LIMITED',
    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],
    companyGstin: '32AACCZ4912F1ZL',
    companyPhone: '8086355500',
    companyEmail: 'zabnixprivatelimited@gmail.com',
    billToAddress: ['finance@stark.com', 'Stark Tower, NY'],
    items: [
      RetainerInvoiceItem(
        index: 1,
        description: 'Raw material supply line allocation',
        amount: 120000.00,
      ),
    ],
  ),
  RetainerInvoice(
    id: '2',
    customerName: 'Wayne Enterprises',
    date: '01-06-2026',
    amount: 53100.00,
    balanceDue: 25000.00,
    status: 'PARTIALLY PAID',
    drawStatus: 'PAID',
    companyName: 'ZABNIX PRIVATE LIMITED',
    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],
    companyGstin: '32AACCZ4912F1ZL',
    companyPhone: '8086355500',
    companyEmail: 'zabnixprivatelimited@gmail.com',
    billToAddress: ['accounts@wayne.com', 'Wayne Tower, Gotham'],
    items: [
      RetainerInvoiceItem(
        index: 1,
        description: 'High-grade equipment manufacturing services',
        amount: 45000.00,
      ),
    ],
  ),
  RetainerInvoice(
    id: '1',
    customerName: 'Acme Corporation',
    date: '24-05-2026',
    amount: 17700.00,
    balanceDue: 0.0,
    status: 'PAID',
    drawStatus: 'PAID',
    companyName: 'ZABNIX PRIVATE LIMITED',
    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],
    companyGstin: '32AACCZ4912F1ZL',
    companyPhone: '8086355500',
    companyEmail: 'zabnixprivatelimited@gmail.com',
    billToAddress: ['billing@acme.com', 'Acme HQ'],
    items: [
      RetainerInvoiceItem(
        index: 1,
        description:
            'Advance retainer for project consultation and design setup',
        amount: 15000.00,
      ),
    ],
  ),
  RetainerInvoice(
    id: '5',
    customerName: 'LexCorp',
    date: '29-04-2026',
    amount: 80000.00,
    balanceDue: 0.0,
    status: 'VOID',
    drawStatus: 'PAID',
    companyName: 'ZABNIX PRIVATE LIMITED',
    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],
    companyGstin: '32AACCZ4912F1ZL',
    companyPhone: '8086355500',
    companyEmail: 'zabnixprivatelimited@gmail.com',
    billToAddress: ['billing@lexcorp.com', 'LexCorp Metropolis'],
    items: [
      RetainerInvoiceItem(
        index: 1,
        description: 'Cancelled project retainer',
        amount: 80000.00,
      ),
    ],
  ),
];

// ─── Screen Widget ────────────────────────────────────────────────────────────

// ─── Provider → Local model mapper ──────────────────────────────────────────

RetainerInvoice _fromProviderInvoice(provider_model.RetainerInvoice src) {
  final df = DateFormat('dd-MM-yyyy');
  String statusLabel;
  switch (src.status) {
    case provider_model.RetainerStatus.draft:
      statusLabel = 'DRAFT';
      break;
    case provider_model.RetainerStatus.sent:
      statusLabel = 'SENT';
      break;
    case provider_model.RetainerStatus.paid:
      statusLabel = 'PAID';
      break;
    case provider_model.RetainerStatus.partiallyPaid:
      statusLabel = 'PARTIALLY PAID';
      break;
    case provider_model.RetainerStatus.voided:
      statusLabel = 'VOID';
      break;
    case provider_model.RetainerStatus.closed:
      statusLabel = 'CLOSED';
      break;
  }
  final drawStatus = src.amountUsed > 0 ? 'PAID' : 'AWAITING PAYMENT';
  return RetainerInvoice(
    id: src.id,
    customerName: src.customerName,
    date: df.format(src.date),
    amount: src.totalAmount,
    balanceDue: src.amountRemaining,
    status: statusLabel,
    drawStatus: drawStatus,
    companyName: 'ZABNIX PRIVATE LIMITED',
    companyAddress: const [
      'PERINTHALMANNA',
      'MALAPPURAM Kerala 679322',
      'India',
    ],
    companyGstin: '32AACCZ4912F1ZL',
    companyPhone: '8086355500',
    companyEmail: 'zabnixprivatelimited@gmail.com',
    billToAddress: [
      src.customerEmail ?? '',
      src.customerName,
    ],
    items: [
      RetainerInvoiceItem(
        index: 1,
        description: src.notes.isNotEmpty ? src.notes : 'Retainer service',
        amount: src.amount,
      ),
    ],
  );
}

class RetainerInvoiceOverviewScreen extends ConsumerStatefulWidget {
  final String? invoiceId;
  const RetainerInvoiceOverviewScreen({super.key, this.invoiceId});

  @override
  ConsumerState<RetainerInvoiceOverviewScreen> createState() =>
      _RetainerInvoiceOverviewScreenState();
}

// ─── State ────────────────────────────────────────────────────────────────────

class _RetainerInvoiceOverviewScreenState
    extends ConsumerState<RetainerInvoiceOverviewScreen> {
  late RetainerInvoice _selectedInvoice;
  String _selectedFilter = 'All';

  String get _orgId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  // Filter dropdown (MenuAnchor)
  final MenuController _filterMenuController = MenuController();
  // Bulk Actions dropdown (MenuAnchor)
  final MenuController _bulkMenuController = MenuController();
  // PDF/Print dropdown (MenuAnchor)
  final MenuController _pdfPrintMenuController = MenuController();
  // Record Payment dropdown (MenuAnchor)
  final MenuController _recordPaymentMenuController = MenuController();
  // Right action bar more dropdown (MenuAnchor)
  final MenuController _rightMoreMenuController = MenuController();
  // Customize dropdown (MenuAnchor)
  final MenuController _customizeMenuController = MenuController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _starredValues = {
    'All',
    'Draft',
    'Pending Approval',
    'Approved',
  };
  bool _favoritesExpanded = true;
  bool _defaultFiltersExpanded = true;

  // More-menu overlay (three-dot in left header)
  final LayerLink _moreLink = LayerLink();
  OverlayEntry? _moreMenuOverlayEntry;
  bool _isMoreMenuOpen = false;
  String? _activeSubMenu;

  final LayerLink _attachmentLink = LayerLink();
  OverlayEntry? _attachmentOverlayEntry;
  bool _isAttachmentPopoverOpen = false;
  bool _showCommentsPanel = false;
  String? _customerPan;
  final TextEditingController _panTextController = TextEditingController();
  final LayerLink _panLayerLink = LayerLink();
  OverlayEntry? _panOverlayEntry;
  bool _isPanOverlayOpen = false;

  // Row checkbox selection
  final Set<String> _checkedIds = {};
  String? _hoveredId;

  // Template chooser panel
  bool _showTemplatePanel = false;
  String _selectedTemplate = 'Standard Template';
  // bool _isInvoiceHovered = false;
  String _templateSearchQuery = '';
  final TextEditingController _templateSearchController =
      TextEditingController();

  bool _showRecordPaymentPage = false;
  bool _showCustomerDetailsPanel = false;
  String _customerDetailTab = 'Details'; // 'Details' | 'Activity Log'
  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _paymentReferenceController =
      TextEditingController();
  final TextEditingController _paymentNotesController = TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();
  final TextEditingController _paymentNumberController = TextEditingController(
    text: '305',
  );
  final GlobalKey _paymentDateKey = GlobalKey();
  String _paymentMode = 'Cash';
  String _paymentDepositTo = 'Petty Cash';
  String _paymentLocation = 'ZABNIX PRIVATE LIMITED';
  String _paymentTransactionSeries = 'Default Transaction Series';
  DateTime _paymentDateVal = DateTime.now();
  final TextEditingController _bankChargesController = TextEditingController();
  List<PlatformFile> _uploadedFiles = [];
  List<Map<String, dynamic>> _invoiceAttachments = [];
  bool _isLoadingInvoiceAttachments = false;
  bool _isUploadingInvoiceAttachments = false;

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  final List<FilterItem> _allFilters = [
    const FilterItem('All'),
    const FilterItem('Draft'),
    const FilterItem('Pending Approval'),
    const FilterItem('Approved'),
    const FilterItem('Overdue'),
    const FilterItem('Sent'),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  // Live list built from provider (populated in didChangeDependencies)
  List<RetainerInvoice> _liveInvoices = _mockInvoices;

  @override
  void initState() {
    super.initState();
    // Initial selection will be refined in didChangeDependencies once
    // the ref is available.
    _selectedInvoice = _mockInvoices.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromProvider();
  }

  @override
  void didUpdateWidget(covariant RetainerInvoiceOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.invoiceId != oldWidget.invoiceId) {
      _syncFromProvider();
    }
  }

  void _syncFromProvider() {
    final previousInvoiceId = _selectedInvoice.id;
    final providerState = ref.read(retainerInvoicesProvider);
    if (providerState.invoices.isNotEmpty) {
      _liveInvoices =
          providerState.invoices.map(_fromProviderInvoice).toList();
    } else {
      _liveInvoices = _mockInvoices;
    }

    final targetId = widget.invoiceId;
    if (targetId != null) {
      _selectedInvoice = _liveInvoices.firstWhere(
        (i) => i.id == targetId,
        orElse: () => _liveInvoices.first,
      );
    } else {
      _selectedInvoice = _liveInvoices.first;
    }

    _paymentAmountController.text =
        _selectedInvoice.balanceDue.toStringAsFixed(2);
    _paymentDateController.text = _selectedInvoice.date;
    try {
      _paymentDateVal = DateFormat('dd-MM-yyyy').parse(_selectedInvoice.date);
    } catch (_) {
      _paymentDateVal = DateTime.now();
    }

    if (previousInvoiceId != _selectedInvoice.id) {
      _invoiceAttachments = [];
      _loadInvoiceAttachments();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _templateSearchController.dispose();
    _paymentAmountController.dispose();
    _paymentReferenceController.dispose();
    _paymentNotesController.dispose();
    _paymentDateController.dispose();
    _paymentNumberController.dispose();
    _bankChargesController.dispose();
    _closeMoreMenu();
    _closeAttachmentPopover();
    _closePanOverlay();
    _panTextController.dispose();
    super.dispose();
  }

  void _showPanOverlay() {
    if (_isPanOverlayOpen) return;

    _panTextController.text = _customerPan ?? '';

    _panOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closePanOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              width: 300,
              child: CompositedTransformFollower(
                link: _panLayerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: const Offset(0, 4),
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  12,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Add PAN',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _closePanOverlay,
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          LucideIcons.x,
                                          size: 16,
                                          color: Color(0xFFD32F2F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: AppTheme.borderColor,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    CustomTextField(
                                      controller: _panTextController,
                                      height: 36,
                                      hintText: 'Enter PAN',
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(
                                            LucideIcons.info,
                                            size: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This PAN will be updated in contact and further transactions.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: AppTheme.borderColor,
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.successGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        minimumSize: const Size(64, 32),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _customerPan = _panTextController.text
                                              .trim();
                                        });
                                        _closePanOverlay();
                                      },
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                      Positioned(
                        top: 1,
                        left: 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: CustomPaint(
                            size: const Size(14, 8),
                            painter: _PopoverArrowPainter(
                              color: Colors.white,
                              borderColor: AppTheme.borderColor,
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
      },
    );

    Overlay.of(context).insert(_panOverlayEntry!);
    setState(() {
      _isPanOverlayOpen = true;
    });
  }

  void _closePanOverlay() {
    if (!_isPanOverlayOpen) return;
    _panOverlayEntry?.remove();
    _panOverlayEntry = null;
    setState(() {
      _isPanOverlayOpen = false;
    });
  }

  void _togglePanOverlay() {
    if (_isPanOverlayOpen) {
      _closePanOverlay();
    } else {
      _showPanOverlay();
    }
  }



  Widget _buildRecordPaymentForm(NumberFormat currencyFormat) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Customer detail fields (red-boxed section) ──────────────────
          Container(
            color: AppTheme.selectionActiveBg,
            padding: const EdgeInsets.fromLTRB(56, 24, 56, 24),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Row 1 — Customer Name
                      _buildPaymentFormRow(
                        label: 'Customer Name',
                        required: true,
                        child: CustomTextField(
                          controller: TextEditingController(
                            text: _selectedInvoice.customerName,
                          ),
                          height: 36,
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Row 2 — Payment #
                      _buildPaymentFormRow(
                        label: 'Payment #',
                        required: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _paymentNumberController,
                                keyboardType: TextInputType.number,
                                height: 36,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                final result =
                                    await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) =>
                                          _ConfigurePaymentNumberPreferencesDialog(
                                            currentLocation: _paymentLocation,
                                            currentSeries:
                                                _paymentTransactionSeries,
                                          ),
                                    );
                                if (result != null) {
                                  setState(() {
                                    final prefix = result['prefix'] as String;
                                    final nextNum =
                                        result['nextNumber'] as String;
                                    _paymentNumberController.text =
                                        "$prefix$nextNum";
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  LucideIcons.settings,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Row 3 — Transaction Series
                      _buildPaymentFormRow(
                        label: 'Transaction Series',
                        required: true,
                        child: FormDropdown<String>(
                          value: _paymentTransactionSeries,
                          items: const [
                            'Default Transaction Series',
                            'SERIES 1',
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => _paymentTransactionSeries = val);
                          },
                          height: 36,
                          showSearch: false,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Row 4 — Location
                      _buildPaymentFormRow(
                        label: 'Location',
                        required: false,
                        child: FormDropdown<String>(
                          value: _paymentLocation,
                          items: const ['ZABNIX PRIVATE LIMITED'],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => _paymentLocation = val);
                          },
                          height: 36,
                          showSearch: false,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_showCustomerDetailsPanel)
                  Positioned(
                    top: 16,
                    right: 12,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showCustomerDetailsPanel = true),
                      child: Container(
                        height: 36,
                        constraints: const BoxConstraints(maxWidth: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D3748),
                          borderRadius: BorderRadius.all(
                            Radius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.panelRightOpen,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "${_selectedInvoice.customerName}'s Details",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
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
          ),

          // ── Bottom section fields ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 24, 56, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount & Bank Charges row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPaymentFormRow(
                            label: 'Amount Received (INR)',
                            child: CustomTextField(
                              controller: _paymentAmountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              height: 36,
                              textAlign: TextAlign.end,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 160),
                            child: CompositedTransformTarget(
                              link: _panLayerLink,
                              child: GestureDetector(
                                onTap: _togglePanOverlay,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Text(
                                    _customerPan == null ||
                                            _customerPan!.isEmpty
                                        ? 'PAN: Add PAN'
                                        : 'PAN: $_customerPan',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      child: _buildPaymentFormRow(
                        label: 'Bank Charges (if any)',
                        child: CustomTextField(
                          controller: _bankChargesController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          height: 36,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Payment Date & Payment Mode row
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentFormRow(
                        label: 'Payment Date',
                        required: true,
                        child: Container(
                          key: _paymentDateKey,
                          child: CustomTextField(
                            controller: _paymentDateController,
                            readOnly: true,
                            height: 36,
                            suffixWidget: const Icon(
                              LucideIcons.calendar,
                              size: 15,
                              color: AppTheme.textSecondary,
                            ),
                            onTap: () async {
                              final picked = await ZerpaiDatePicker.show(
                                context,
                                initialDate: _paymentDateVal,
                                targetKey: _paymentDateKey,
                              );
                              if (picked == null) return;
                              setState(() {
                                _paymentDateVal = picked;
                                _paymentDateController.text = DateFormat(
                                  'dd-MM-yyyy',
                                ).format(picked);
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      child: _buildPaymentFormRow(
                        label: 'Payment Mode',
                        child: FormDropdown<String>(
                          value: _paymentMode,
                          items: const [
                            'Cash',
                            'Bank Transfer',
                            'UPI',
                            'Cheque',
                            'Credit Card',
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => _paymentMode = val);
                          },
                          height: 36,
                          showSearch: false,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Deposit To & Reference# row
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentFormRow(
                        label: 'Deposit To',
                        required: true,
                        child: FormDropdown<String>(
                          value: _paymentDepositTo,
                          items: const [
                            'Petty Cash',
                            'Undeposited Funds',
                            'Bank Account',
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => _paymentDepositTo = val);
                          },
                          height: 36,
                          showSearch: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      child: _buildPaymentFormRow(
                        label: 'Reference#',
                        child: CustomTextField(
                          controller: _paymentReferenceController,
                          height: 36,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Notes
                _buildPaymentFormRow(
                  label: 'Notes',
                  crossAxisAlignment: CrossAxisAlignment.start,
                  child: CustomTextField(
                    controller: _paymentNotesController,
                    minHeight: 80,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppTheme.borderColor),
                const SizedBox(height: 24),

                // Attachments
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FileUploadButton(
                      files: _uploadedFiles,
                      onFilesChanged: (updated) => setState(() {
                        _uploadedFiles = updated;
                      }),
                      height: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You can upload a maximum of 5 files, 5MB each',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppTheme.borderColor),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showRecordPaymentPage = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Record Payment',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showRecordPaymentPage = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.borderColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentFormRow({
    required String label,
    required Widget child,
    bool required = false,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        SizedBox(
          width: 160,
          child: Padding(
            padding: EdgeInsets.only(
              top: crossAxisAlignment == CrossAxisAlignment.start ? 8 : 0,
            ),
            child: RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 13,
                  color: required ? AppTheme.errorRed : AppTheme.textPrimary,
                ),
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 320.0, child: child),
          ),
        ),
      ],
    );
  }



  bool get _hasPersistedInvoiceId =>
      _uuidPattern.hasMatch(_selectedInvoice.id.trim());

  void _showAttachmentSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : null,
      ),
    );
  }

  String _attachmentMimeType(PlatformFile file) {
    final ext = file.extension?.toLowerCase() ?? '';
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _loadInvoiceAttachments() async {
    if (!_hasPersistedInvoiceId) {
      if (!mounted) return;
      setState(() {
        _invoiceAttachments = [];
        _isLoadingInvoiceAttachments = false;
      });
      _attachmentOverlayEntry?.markNeedsBuild();
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingInvoiceAttachments = true;
      });
    }

    try {
      final supabase = Supabase.instance.client;
      final result = await supabase
          .from('retainer_invoice_attachments')
          .select(
            'id,file_name,original_file_name,file_path,file_type,file_size,created_at',
          )
          .eq('retainer_invoice_id', _selectedInvoice.id)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _invoiceAttachments = (result as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        _showAttachmentSnackBar(
          'Failed to load attachments: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInvoiceAttachments = false;
        });
      }
      _attachmentOverlayEntry?.markNeedsBuild();
    }
  }

  Future<void> _pickAttachmentFiles() async {
    if (!_hasPersistedInvoiceId) {
      _showAttachmentSnackBar(
        'Save a valid retainer invoice before uploading attachments.',
        isError: true,
      );
      return;
    }

    final remaining = 5 - _invoiceAttachments.length;
    if (remaining <= 0) {
      _showAttachmentSnackBar('Maximum 5 files allowed', isError: true);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final List<PlatformFile> validFiles = [];
    for (final file in result.files.take(remaining)) {
      if (file.size <= 10 * 1024 * 1024) {
        validFiles.add(file);
      } else {
        _showAttachmentSnackBar(
          '${file.name} exceeds 10MB size limit',
          isError: true,
        );
      }
    }

    if (validFiles.isEmpty) return;

    if (mounted) {
      setState(() {
        _isUploadingInvoiceAttachments = true;
      });
    }

    try {
      final supabase = Supabase.instance.client;
      final apiClient = ApiClient();
      final uploadedBy = ref.read(authUserProvider)?.id.trim();
      var uploadedCount = 0;

      for (final file in validFiles) {
        if (file.bytes == null) continue;

        final response = await apiClient.post(
          '/lookups/uploads',
          data: {
            'fileName': file.name,
            'fileData': base64Encode(file.bytes!),
            'mimeType': _attachmentMimeType(file),
            'prefix': 'retainer_invoices',
          },
        );

        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        final fileKey =
            data['fileKey']?.toString() ?? 'retainer_invoices/${file.name}';

        await supabase.from('retainer_invoice_attachments').insert({
          'retainer_invoice_id': _selectedInvoice.id,
          'file_name': file.name,
          'original_file_name': file.name,
          'file_path': fileKey,
          'file_type': file.extension ?? 'bin',
          'file_size': file.size,
          if (uploadedBy != null && uploadedBy.isNotEmpty)
            'uploaded_by': uploadedBy,
        });
        uploadedCount++;
      }

      await _loadInvoiceAttachments();
      if (uploadedCount > 0) {
        _showAttachmentSnackBar('Attachments uploaded successfully');
      }
    } catch (e) {
      _showAttachmentSnackBar(
        'Failed to upload attachments: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingInvoiceAttachments = false;
        });
      }
      _attachmentOverlayEntry?.markNeedsBuild();
    }
  }

  Future<void> _removeAttachmentFile(int index) async {
    if (index < 0 || index >= _invoiceAttachments.length) return;

    final attachment = _invoiceAttachments[index];
    final attachmentId = attachment['id']?.toString();
    final filePath = attachment['file_path']?.toString();
    if (attachmentId == null || attachmentId.isEmpty) return;

    try {
      final apiClient = ApiClient();
      if (filePath != null && filePath.isNotEmpty) {
        await apiClient.delete(
          '/lookups/uploads',
          data: {'fileKey': filePath},
        );
      }

      await Supabase.instance.client
          .from('retainer_invoice_attachments')
          .delete()
          .eq('id', attachmentId);

      await _loadInvoiceAttachments();
      _showAttachmentSnackBar('Attachment deleted successfully');
    } catch (e) {
      _showAttachmentSnackBar(
        'Failed to delete attachment: $e',
        isError: true,
      );
    }
  }

  String _formatFileSize(dynamic size) {
    final bytes = size is num ? size.toInt() : int.tryParse('$size') ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _toggleAttachmentPopover() {
    if (_isAttachmentPopoverOpen) {
      _closeAttachmentPopover();
    } else {
      _openAttachmentPopover();
    }
  }

  void _openAttachmentPopover() {
    _closeAttachmentPopover();
    _attachmentOverlayEntry = _createAttachmentOverlayEntry();
    Overlay.of(context).insert(_attachmentOverlayEntry!);
    setState(() => _isAttachmentPopoverOpen = true);
    _loadInvoiceAttachments();
  }

  void _closeAttachmentPopover() {
    _attachmentOverlayEntry?.remove();
    _attachmentOverlayEntry = null;
    if (mounted && _isAttachmentPopoverOpen) {
      setState(() => _isAttachmentPopoverOpen = false);
    }
  }

  OverlayEntry _createAttachmentOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeAttachmentPopover,
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.transparent)),
              CompositedTransformFollower(
                link: _attachmentLink,
                showWhenUnlinked: false,
                offset: const Offset(-244, 32),
                child: Material(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 272,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 42,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Attachments',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: _closeAttachmentPopover,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      LucideIcons.x,
                                      size: 13,
                                      color: Colors.red.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingInvoiceAttachments)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        else if (_invoiceAttachments.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No Files Attached',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: SingleChildScrollView(
                              child: Column(
                                children: _invoiceAttachments.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final file = entry.value;
                                  final fileName =
                                      file['original_file_name']?.toString() ??
                                      file['file_name']?.toString() ??
                                      'Attachment';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          LucideIcons.fileText,
                                          size: 14,
                                          color: AppTheme.primaryBlue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            fileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatFileSize(file['file_size']),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              _removeAttachmentFile(index),
                                          child: const Icon(
                                            LucideIcons.trash2,
                                            size: 13,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: InkWell(
                            onTap: _isUploadingInvoiceAttachments
                                ? null
                                : _pickAttachmentFiles,
                            borderRadius: BorderRadius.circular(5),
                            child: CustomPaint(
                              painter: _DashedBorderPainter(
                                color: AppTheme.borderColor,
                                radius: 5,
                              ),
                              child: SizedBox(
                                height: 52,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isUploadingInvoiceAttachments)
                                      const SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        LucideIcons.upload,
                                        size: 15,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isUploadingInvoiceAttachments
                                          ? 'Uploading...'
                                          : 'Upload your Files',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      LucideIcons.chevronDown,
                                      size: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Center(
                            child: Text(
                              'You can upload a maximum of 5 files, 10MB each',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.textSecondary,
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
      },
    );
  }

  Widget _buildCommentsHistoryPanel(NumberFormat currencyFormat) {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        child: Container(
          width: 360,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 14, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Comments & History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _showCommentsPanel = false),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Colors.red.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCommentComposer(),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Text(
                            'ALL COMMENTS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.borderColor),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              LucideIcons.fileText,
                              size: 13,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Flexible(
                                      child: Text(
                                        'zabnixprivatelimited',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${_selectedInvoice.date} 07:40 PM',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Retainer Invoice created for '
                                    '${currencyFormat.format(_selectedInvoice.amount)}',
                                    style: const TextStyle(
                                      fontSize: 12,
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

  Widget _buildCommentComposer() {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 34,
            color: const Color(0xFFF4F6F8),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Row(
              children: [
                Text(
                  'B',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(width: 22),
                Text(
                  'I',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(width: 22),
                Text(
                  'U',
                  style: TextStyle(
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 0, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Add Comment',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppTheme.accentGreen;
      case 'PENDING APPROVAL':
        return AppTheme.warningOrange;
      case 'SENT':
        return AppTheme.primaryBlue;
      case 'OVERDUE':
        return AppTheme.errorRed;
      case 'DRAFT':
      default:
        return Colors.blueGrey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SplitListDetailLayout(
            leftWidth: 320,
            leftHeader: _buildLeftHeader(),
            leftBody: _buildLeftList(currencyFormat),
            rightHeader: _buildRightHeader(),
            rightBody: _buildRightBody(currencyFormat),
          ),
          if (_showCommentsPanel) _buildCommentsHistoryPanel(currencyFormat),
        ],
      ),
    );
  }

  // ── Filter Dropdown ────────────────────────────────────────────────────────

  Widget _buildFilterDropdownContent() {
    final query = _searchQuery.toLowerCase();
    final favList = _allFilters
        .where((f) => _starredValues.contains(f.label))
        .where((f) => f.label.toLowerCase().contains(query))
        .toList();
    final defaultList = _allFilters
        .where((f) => f.label.toLowerCase().contains(query))
        .toList();

    return StatefulBuilder(
      builder: (context, setMenu) {
        return Container(
          width: 270,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          LucideIcons.search,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                            setMenu(() {});
                          },
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search views...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            setMenu(() {});
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              LucideIcons.x,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Scrollable sections
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // FAVORITES
                      _filterSectionHeader(
                        title: 'FAVORITES',
                        count: favList.length,
                        isExpanded: _favoritesExpanded,
                        onTap: () => setState(
                          () => _favoritesExpanded = !_favoritesExpanded,
                        ),
                      ),
                      if (_favoritesExpanded)
                        ...favList.map(
                          (f) =>
                              _filterOptionRow(label: f.label, isStarred: true),
                        ),

                      // DEFAULT FILTERS
                      _filterSectionHeader(
                        title: 'DEFAULT FILTERS',
                        count: defaultList.length,
                        isExpanded: _defaultFiltersExpanded,
                        onTap: () => setState(
                          () => _defaultFiltersExpanded =
                              !_defaultFiltersExpanded,
                        ),
                      ),
                      if (_defaultFiltersExpanded)
                        ...defaultList.map(
                          (f) => _filterOptionRow(
                            label: f.label,
                            isStarred: _starredValues.contains(f.label),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterSectionHeader({
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        color: const Color(0xFFF9FAFB),
        child: Row(
          children: [
            Icon(
              isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              size: 13,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.successGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterOptionRow({required String label, required bool isStarred}) {
    final isSelected = _selectedFilter == label;
    return _FilterOptionRow(
      label: label,
      isStarred: isStarred,
      isSelected: isSelected,
      onTap: () {
        setState(() => _selectedFilter = label);
        _filterMenuController.close();
      },
      onStarTap: () {
        setState(() {
          if (_starredValues.contains(label)) {
            _starredValues.remove(label);
          } else {
            _starredValues.add(label);
          }
        });
      },
    );
  }

  // ── More Menu (left header three-dot) ──────────────────────────────────────

  void _toggleMoreMenu() {
    if (_isMoreMenuOpen) {
      _closeMoreMenu();
    } else {
      _openMoreMenu();
    }
  }

  void _openMoreMenu() {
    _moreMenuOverlayEntry = _createMoreMenuOverlayEntry();
    Overlay.of(context).insert(_moreMenuOverlayEntry!);
    setState(() {
      _isMoreMenuOpen = true;
      _activeSubMenu = null;
    });
  }

  void _closeMoreMenu() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    if (mounted) {
      setState(() {
        _isMoreMenuOpen = false;
        _activeSubMenu = null;
      });
    }
  }

  OverlayEntry _createMoreMenuOverlayEntry() {
    String? hoveredSubMenuItem;
    return OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setStateOverlay) {
          Widget? subMenuWidget;
          if (_activeSubMenu == 'Sort by') {
            subMenuWidget = _buildSortBySubMenu(
              setStateOverlay,
              hoveredSubMenuItem,
              (val) => setStateOverlay(() => hoveredSubMenuItem = val),
            );
          } else if (_activeSubMenu == 'Export') {
            subMenuWidget = _buildExportSubMenu(
              setStateOverlay,
              hoveredSubMenuItem,
              (val) => setStateOverlay(() => hoveredSubMenuItem = val),
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeMoreMenu,
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: Colors.transparent)),
                CompositedTransformFollower(
                  link: _moreLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                        child: Container(
                          width: 220,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MainMenuItemWidget(
                                icon: LucideIcons.arrowUpDown,
                                label: 'Sort by',
                                hasSubMenu: true,
                                isActive: _activeSubMenu == 'Sort by',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = 'Sort by';
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: () {},
                              ),
                              _MainMenuItemWidget(
                                icon: LucideIcons.download,
                                label: 'Import Retainer Invoices',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = null;
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: _closeMoreMenu,
                              ),
                              _MainMenuItemWidget(
                                icon: LucideIcons.upload,
                                label: 'Export',
                                hasSubMenu: true,
                                isActive: _activeSubMenu == 'Export',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = 'Export';
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: () {},
                              ),
                              const Divider(
                                height: 8,
                                color: Color(0xFFD0D0D0),
                              ),
                              _MainMenuItemWidget(
                                icon: LucideIcons.settings,
                                label: 'Preferences',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = null;
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: _closeMoreMenu,
                              ),
                              _MainMenuItemWidget(
                                icon: LucideIcons.sliders,
                                label: 'Manage Custom Fields',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = null;
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: _closeMoreMenu,
                              ),
                              const Divider(
                                height: 8,
                                color: Color(0xFFD0D0D0),
                              ),
                              _MainMenuItemWidget(
                                icon: LucideIcons.refreshCw,
                                label: 'Refresh List',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = null;
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: _closeMoreMenu,
                              ),
                              _MainMenuItemWidget(
                                icon: LucideIcons.columns,
                                label: 'Reset Column Width',
                                onHover: () => setStateOverlay(() {
                                  _activeSubMenu = null;
                                  hoveredSubMenuItem = null;
                                }),
                                onTap: _closeMoreMenu,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (subMenuWidget != null) ...[
                        const SizedBox(width: 4),
                        Padding(
                          padding: EdgeInsets.only(
                            top: _activeSubMenu == 'Export' ? 76 : 4,
                          ),
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: subMenuWidget,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBySubMenu(
    StateSetter setStateOverlay,
    String? hoveredItem,
    Function(String?) setHovered,
  ) {
    final sortOptions = [
      'Date',
      'Retainer Invoice Number',
      'Reference#',
      'Customer Name',
      'Total',
      'Balance',
      'Issued Date',
      'Created Time',
      'Last Modified Time',
    ];

    return Container(
      width: 200,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortOptions.map((opt) {
          final isSelected = opt == 'Created Time';
          final isHovered = hoveredItem == opt;
          return MouseRegion(
            onEnter: (_) => setHovered(opt),
            onExit: (_) => setHovered(null),
            child: InkWell(
              onTap: () => _closeMoreMenu(),
              child: Container(
                height: 36,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                ),
                color: isHovered
                    ? AppTheme.primaryBlue
                    : (isSelected
                          ? const Color(0xFFE2E8F0)
                          : Colors.transparent),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 12,
                          color: isHovered
                              ? Colors.white
                              : (isSelected
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textPrimary),
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected ||
                        (isHovered && opt == 'Retainer Invoice Number'))
                      Icon(
                        isSelected
                            ? LucideIcons.arrowDown
                            : LucideIcons.arrowUp,
                        size: 12,
                        color: isHovered ? Colors.white : AppTheme.primaryBlue,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExportSubMenu(
    StateSetter setStateOverlay,
    String? hoveredItem,
    Function(String?) setHovered,
  ) {
    final exportOptions = ['Export Retainer Invoices', 'Export Current View'];

    return Container(
      width: 180,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: exportOptions.map((opt) {
          final isHovered = hoveredItem == opt;
          return MouseRegion(
            onEnter: (_) => setHovered(opt),
            onExit: (_) => setHovered(null),
            child: InkWell(
              onTap: () => _closeMoreMenu(),
              child: Container(
                height: 36,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                ),
                color: isHovered ? AppTheme.primaryBlue : Colors.transparent,
                alignment: Alignment.centerLeft,
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 12,
                    color: isHovered ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Left Header ────────────────────────────────────────────────────────────

  Widget _buildLeftHeader() {
    // Bulk-actions bar when ≥1 row is checkbox-selected
    if (_checkedIds.isNotEmpty) {
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: _checkedIds.length == _liveInvoices.length,
                tristate: false,
                activeColor: AppTheme.primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (_) {
                  setState(() {
                    if (_checkedIds.length == _liveInvoices.length) {
                      _checkedIds.clear();
                    } else {
                      _checkedIds
                        ..clear()
                        ..addAll(_liveInvoices.map((e) => e.id));
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: AppTheme.space8),
            MenuAnchor(
              controller: _bulkMenuController,
              style: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.white),
                surfaceTintColor: WidgetStatePropertyAll(Colors.white),
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                elevation: WidgetStatePropertyAll(8),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    side: BorderSide(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ),
              builder: (context, controller, child) {
                return InkWell(
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Bulk Actions',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          controller.isOpen
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
              menuChildren: [
                _BulkActionMenuItem(
                  label: 'Export as PDF',
                  onTap: () {
                    _bulkMenuController.close();
                  },
                ),
                _BulkActionMenuItem(
                  label: 'Print',
                  onTap: () {
                    _bulkMenuController.close();
                  },
                ),
                _BulkActionMenuItem(
                  label: 'Delete',
                  onTap: () {
                    _bulkMenuController.close();
                  },
                ),
              ],
            ),
            const SizedBox(width: AppTheme.space12),
            Container(width: 1, height: 20, color: AppTheme.borderColor),
            const SizedBox(width: AppTheme.space12),
            Text(
              '${_checkedIds.length} Selected',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => setState(() => _checkedIds.clear()),
              child: const Icon(
                LucideIcons.x,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Normal header with MenuAnchor filter dropdown
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          MenuAnchor(
            controller: _filterMenuController,
            style: const MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: WidgetStatePropertyAll(Colors.white),
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              elevation: WidgetStatePropertyAll(8),
            ),
            builder: (context, controller, child) {
              final isOpen = controller.isOpen;
              return InkWell(
                onTap: () => isOpen ? controller.close() : controller.open(),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFilter == 'All'
                            ? 'All Retainer Invo...'
                            : _selectedFilter,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Icon(
                        isOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 14,
                        color: AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [_buildFilterDropdownContent()],
          ),
          const Spacer(),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
              onPressed: () {
                final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
                context.go('/$orgId${AppRoutes.salesRetainerInvoicesCreate}');
              },
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          CompositedTransformTarget(
            link: _moreLink,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(4),
                color: _isMoreMenuOpen ? AppTheme.bgHover : Colors.white,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  LucideIcons.moreHorizontal,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                onPressed: _toggleMoreMenu,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Left List ──────────────────────────────────────────────────────────────

  Widget _buildLeftList(NumberFormat currencyFormat) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        itemCount: _liveInvoices.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppTheme.borderColor),
        itemBuilder: (context, index) {
          final inv = _liveInvoices[index];
          final isDetailSelected = inv.id == _selectedInvoice.id;
          final isChecked = _checkedIds.contains(inv.id);
          // final isHovered = _hoveredId == inv.id;

          Color rowBg = Colors.transparent;
          if (isChecked) {
            rowBg = AppTheme.primaryBlue.withValues(alpha: 0.06);
          } else if (isDetailSelected) {
            rowBg = AppTheme.selectionActiveBg;
          }

          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredId = inv.id),
            onExit: (_) => setState(() {
              if (_hoveredId == inv.id) _hoveredId = null;
            }),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedInvoice = inv;
                  _showRecordPaymentPage = false;
                  _showCustomerDetailsPanel = false;
                  _paymentAmountController.text = inv.balanceDue
                      .toStringAsFixed(2);
                  _paymentDateController.text = inv.date;
                  try {
                    _paymentDateVal = DateFormat('dd-MM-yyyy').parse(inv.date);
                  } catch (_) {
                    _paymentDateVal = DateTime.now();
                  }
                });
              },
              child: Container(
                color: rowBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space8,
                  vertical: AppTheme.space12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox column — always 28 px wide to avoid layout jump
                    SizedBox(
                      width: 28,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: AppTheme.primaryBlue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(
                            color: Color(0xFFB0B8C1),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _checkedIds.add(inv.id);
                              } else {
                                _checkedIds.remove(inv.id);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    // Invoice content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  inv.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                currencyFormat.format(inv.amount),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  inv.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.space4),
                              const Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space4),
                              Text(
                                inv.date,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            inv.status,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
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
        },
      ),
    );
  }

  // ── Right Header ───────────────────────────────────────────────────────────

  Widget? _buildRightHeader() {
    if (_showRecordPaymentPage) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: breadcrumb + id | utility icons
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          color: Colors.white,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Location: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _selectedInvoice.companyName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedInvoice.id,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              CompositedTransformTarget(
                link: _attachmentLink,
                child: _buildIconButton(
                  LucideIcons.paperclip,
                  onTap: _toggleAttachmentPopover,
                  isActive: _isAttachmentPopoverOpen,
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              _buildIconButton(
                LucideIcons.messageSquare,
                onTap: () =>
                    setState(() => _showCommentsPanel = !_showCommentsPanel),
                isActive: _showCommentsPanel,
              ),
              const SizedBox(width: AppTheme.space8),
              _buildIconButton(LucideIcons.x, color: Colors.red.shade600),
            ],
          ),
        ),
        // Row 2: action tabs
        if (!_showRecordPaymentPage)
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
                top: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                _buildFlatActionTab(
                  LucideIcons.pencil,
                  'Edit',
                  onTap: () {
                    context.go('/$_orgId${AppRoutes.salesRetainerInvoicesCreate}?id=${_selectedInvoice.id}');
                  },
                ),
                _buildTabSeparator(),
                _buildFlatActionTab(LucideIcons.mail, 'Send Email'),
                _buildTabSeparator(),
                MenuAnchor(
                  controller: _pdfPrintMenuController,
                  style: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.white),
                    surfaceTintColor: WidgetStatePropertyAll(Colors.white),
                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    elevation: WidgetStatePropertyAll(8),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        side: BorderSide(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                  builder: (context, controller, child) {
                    return InkWell(
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.fileText,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: AppTheme.space6),
                          const Text(
                            'PDF/Print',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space2),
                          Icon(
                            controller.isOpen
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    );
                  },
                  menuChildren: [
                    _BulkActionMenuItem(
                      label: 'PDF',
                      icon: LucideIcons.fileText,
                      onTap: () {
                        _pdfPrintMenuController.close();
                      },
                    ),
                    _BulkActionMenuItem(
                      label: 'Print',
                      icon: LucideIcons.printer,
                      onTap: () {
                        _pdfPrintMenuController.close();
                      },
                    ),
                  ],
                ),
                _buildTabSeparator(),
                MenuAnchor(
                  controller: _recordPaymentMenuController,
                  style: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.white),
                    surfaceTintColor: WidgetStatePropertyAll(Colors.white),
                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    elevation: WidgetStatePropertyAll(8),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        side: BorderSide(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                  builder: (context, controller, child) {
                    return InkWell(
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.creditCard,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: AppTheme.space6),
                          const Text(
                            'Record Payment',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space2),
                          Icon(
                            controller.isOpen
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    );
                  },
                  menuChildren: [
                    _BulkActionMenuItem(
                      label: 'Record Payment',
                      icon: LucideIcons.creditCard,
                      onTap: () {
                        _recordPaymentMenuController.close();
                        setState(() => _showRecordPaymentPage = true);
                      },
                    ),
                  ],
                ),
                _buildTabSeparator(),
                // Three-dot anchored to action bar for the more-menu
                MenuAnchor(
                  controller: _rightMoreMenuController,
                  style: const MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.white),
                    surfaceTintColor: WidgetStatePropertyAll(Colors.white),
                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    elevation: WidgetStatePropertyAll(8),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        side: BorderSide(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                  builder: (context, controller, child) {
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: controller.isOpen
                                ? const Color(0xFFE9EDF0)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            LucideIcons.moreHorizontal,
                            size: 16,
                            color: controller.isOpen
                                ? AppTheme.primaryBlue
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                  menuChildren: [
                    _BulkActionMenuItem(
                      label: 'Mark As Sent',
                      icon: LucideIcons.mail,
                      onTap: () {
                        _rightMoreMenuController.close();
                      },
                    ),
                    _BulkActionMenuItem(
                      label: 'Clone',
                      icon: LucideIcons.copy,
                      onTap: () {
                        _rightMoreMenuController.close();
                      },
                    ),
                    _BulkActionMenuItem(
                      label: 'Void',
                      icon: LucideIcons.ban,
                      onTap: () {
                        _rightMoreMenuController.close();
                      },
                    ),
                    _BulkActionMenuItem(
                      label: 'Delete',
                      icon: LucideIcons.trash2,
                      onTap: () {
                        _rightMoreMenuController.close();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFlatActionTab(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: AppTheme.space6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTabSeparator() {
    return Container(
      height: 20,
      width: 1,
      color: AppTheme.borderColor.withValues(alpha: 0.6),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
    );
  }

  Widget _buildIconButton(
    IconData icon, {
    Color? color,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
          color: isActive ? const Color(0xFFE9EDF0) : Colors.white,
        ),
        child: Center(
          child: Icon(
            icon,
            size: 14,
            color: isActive
                ? AppTheme.primaryBlue
                : color ?? AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Right Body ─────────────────────────────────────────────────────────────

  Widget _buildRightBody(NumberFormat currencyFormat) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              if (_showRecordPaymentPage) ...[
                Container(
                  width: double.infinity,
                  height: 50,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Payment for ${_selectedInvoice.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
              ],
              Expanded(
                child: SingleChildScrollView(
                  padding: _showRecordPaymentPage
                      ? EdgeInsets.zero
                      : const EdgeInsets.all(AppTheme.space32),
                  child: _showRecordPaymentPage
                      ? _buildRecordPaymentForm(currencyFormat)
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Retainer Draw Status : ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _selectedInvoice.drawStatus
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              MouseRegion(
                                onEnter: (_) {}, // setState(() => _isInvoiceHovered = true),
                                onExit: (_) {}, // setState(() => _isInvoiceHovered = false),
                                child: Container(
                                  width: 720,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(
                                          AppTheme.space40,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const SizedBox(height: 40),
                                                      Container(
                                                        width: 140,
                                                        height: 50,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        alignment:
                                                            Alignment.center,
                                                        child: const Text(
                                                          'MATRIX',
                                                          style: TextStyle(
                                                            color: Colors.green,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            letterSpacing: 2,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height:
                                                            AppTheme.space16,
                                                      ),
                                                      Text(
                                                        _selectedInvoice
                                                            .companyName,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                      ..._selectedInvoice
                                                          .companyAddress
                                                          .map(
                                                            (line) => Text(
                                                              line,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color: AppTheme
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          ),
                                                      Text(
                                                        'GSTIN ${_selectedInvoice.companyGstin}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      Text(
                                                        _selectedInvoice
                                                            .companyPhone,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      Text(
                                                        _selectedInvoice
                                                            .companyEmail,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.blue,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    const Text(
                                                      'RETAINER INVOICE',
                                                      style: TextStyle(
                                                        fontSize: 22,
                                                        letterSpacing: 0.5,
                                                        color: AppTheme
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: AppTheme.space8,
                                                    ),
                                                    Text(
                                                      'Retainer# ${_selectedInvoice.id}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: AppTheme.space24,
                                                    ),
                                                    const Text(
                                                      'Balance Due',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                    Text(
                                                      currencyFormat.format(
                                                        _selectedInvoice
                                                            .balanceDue,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppTheme
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: AppTheme.space40,
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'Bill To',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: AppTheme.space4,
                                                      ),
                                                      Text(
                                                        _selectedInvoice
                                                            .customerName,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      ..._selectedInvoice
                                                          .billToAddress
                                                          .map(
                                                            (line) => Text(
                                                              line,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color: AppTheme
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                          ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Text(
                                                          'Retainer Date :',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: AppTheme
                                                                .textSecondary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width:
                                                              AppTheme.space20,
                                                        ),
                                                        Text(
                                                          _selectedInvoice.date,
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: AppTheme
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: AppTheme.space40,
                                            ),
                                            _buildItemsTable(currencyFormat),
                                            const SizedBox(
                                              height: AppTheme.space20,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  'Sub Total',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(width: 80),
                                                Text(
                                                  currencyFormat.format(
                                                    _selectedInvoice.amount,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        child: ZerpaiDocumentCornerRibbon(
                                          label: _selectedInvoice.status,
                                          color: _getStatusColor(
                                            _selectedInvoice.status,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: AnimatedOpacity(
                                          opacity: 1.0,
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          child: IgnorePointer(
                                            ignoring: false,
                                            child: MenuAnchor(
                                              controller:
                                                  _customizeMenuController,
                                              onClose: () => setState(() {}),
                                              style: const MenuStyle(
                                                alignment: AlignmentDirectional
                                                    .bottomEnd,
                                                minimumSize:
                                                    WidgetStatePropertyAll(
                                                      Size(200, 0),
                                                    ),
                                                backgroundColor:
                                                    WidgetStatePropertyAll(
                                                      Colors.white,
                                                    ),
                                                surfaceTintColor:
                                                    WidgetStatePropertyAll(
                                                      Colors.white,
                                                    ),
                                                padding: WidgetStatePropertyAll(
                                                  EdgeInsets.zero,
                                                ),
                                                elevation:
                                                    WidgetStatePropertyAll(8),
                                                shape: WidgetStatePropertyAll(
                                                  RoundedRectangleBorder(
                                                    side: BorderSide(
                                                      color:
                                                          AppTheme.borderColor,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                          Radius.circular(4),
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              builder: (context, controller, child) {
                                                return InkWell(
                                                  onTap: () {
                                                    if (controller.isOpen) {
                                                      controller.close();
                                                    } else {
                                                      controller.open();
                                                    }
                                                    setState(() {});
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppTheme.successGreen,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          LucideIcons.settings,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        const Text(
                                                          'Customize',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Icon(
                                                          controller.isOpen
                                                              ? LucideIcons
                                                                    .chevronUp
                                                              : LucideIcons
                                                                    .chevronDown,
                                                          size: 12,
                                                          color: Colors.white,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              menuChildren: [
                                                _BulkActionMenuItem(
                                                  label: 'Standard Template',
                                                  width: 200,
                                                  onTap: () {
                                                    setState(
                                                      () => _selectedTemplate =
                                                          'Standard Template',
                                                    );
                                                    _customizeMenuController
                                                        .close();
                                                  },
                                                ),
                                                _BulkActionMenuItem(
                                                  label: 'Change Template',
                                                  width: 200,
                                                  onTap: () {
                                                    setState(
                                                      () => _showTemplatePanel =
                                                          true,
                                                    );
                                                    _customizeMenuController
                                                        .close();
                                                  },
                                                ),
                                                _BulkActionMenuItem(
                                                  label: 'Edit Template',
                                                  width: 200,
                                                  onTap: () {
                                                    _customizeMenuController
                                                        .close();
                                                  },
                                                ),
                                                _BulkActionMenuItem(
                                                  label:
                                                      'Update Logo & Address',
                                                  width: 200,
                                                  onTap: () {
                                                    _customizeMenuController
                                                        .close();
                                                  },
                                                ),
                                                _BulkActionMenuItem(
                                                  label: 'Manage Custom Fields',
                                                  width: 185,
                                                  onTap: () {
                                                    _customizeMenuController
                                                        .close();
                                                  },
                                                ),
                                                _BulkActionMenuItem(
                                                  label: 'Terms & Conditions',
                                                  width: 185,
                                                  onTap: () {
                                                    _customizeMenuController
                                                        .close();
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
                              // PDF Template bar below invoice card
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 800,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "PDF Template : ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      "'$_selectedTemplate'",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _showTemplatePanel = true,
                                      ),
                                      child: const Text(
                                        'Change',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTheme.space32),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        // Choose Template panel
        if (_showTemplatePanel)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: _buildChooseTemplatePanel(),
          ),

        // Customer Details side panel
        if (_showRecordPaymentPage && _showCustomerDetailsPanel)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: _buildCustomerDetailsPanel(),
          ),
      ],
    );
  }

  // ── Customer Details Side Panel ────────────────────────────────────────────

  Widget _buildCustomerDetailsPanel() {
    final inv = _selectedInvoice;
    final initials = inv.customerName
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(left: BorderSide(color: AppTheme.borderColor)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TOP HEADER ─────────────────────────────────────────────────
            Container(
              color: const Color(0xFFF7F8FA),
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // View in module tooltip row + close
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'View in Customers module',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            setState(() => _showCustomerDetailsPanel = false),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.x,
                            size: 15,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Avatar + name row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circle avatar
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                inv.customerName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.externalLink,
                              size: 12,
                              color: AppTheme.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Sub-icons row (lock, comment)
                  Row(
                    children: [
                      _buildPanelIconBtn(LucideIcons.lock),
                      const SizedBox(width: 8),
                      _buildPanelIconBtn(LucideIcons.messageSquare),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tabs: Details / Activity Log
                  Row(
                    children: [
                      _buildPanelTab('Details'),
                      const SizedBox(width: 20),
                      _buildPanelTab('Activity Log'),
                    ],
                  ),
                ],
              ),
            ),

            // ── BODY ───────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stat cards row
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: LucideIcons.alertTriangle,
                                iconColor: const Color(0xFFD97706),
                                label: 'Outstanding Receivables',
                                value: '\u20B90.00',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                icon: LucideIcons.checkCircle,
                                iconColor: const Color(0xFF0E9F6E),
                                label: 'Unused Credits',
                                value: '\u20B90.00',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Contact Details section
                    _buildPanelSection(
                      title: 'Contact Details',
                      child: Column(
                        children: [
                          _buildKVRow('Customer Type', 'Individual'),
                          _buildKVRow(
                            'Currency',
                            'INR',
                            valueColor: AppTheme.primaryBlue,
                          ),
                          _buildKVRow('Credit Limit', '\u20B90.00'),
                          _buildKVRow('Payment Terms', 'Net 360'),
                          _buildKVRow('Portal Status', 'Disabled'),
                          _buildKVRow(
                            'Customer Language',
                            'English',
                            showInfo: true,
                          ),
                          _buildKVRow('Price List', 'Pricelist'),
                          _buildKVRow('GST Treatment', 'Unregistered Business'),
                          _buildKVRow('Place of Supply', 'Kerala'),
                          _buildKVRow('Tax Preference', 'Taxable'),
                        ],
                      ),
                    ),

                    // Contact Persons accordion
                    _buildPanelAccordion('Contact Persons', '1'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelTab(String label) {
    final isActive = _customerDetailTab == label;
    return GestureDetector(
      onTap: () => setState(() => _customerDetailTab = label),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 60,
            color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildPanelIconBtn(IconData icon) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Icon(icon, size: 13, color: AppTheme.textSecondary),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        child,
        const Divider(height: 1, color: AppTheme.borderColor),
      ],
    );
  }

  Widget _buildKVRow(
    String label,
    String value, {
    Color? valueColor,
    bool showInfo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (showInfo) ...[
                  const SizedBox(width: 3),
                  const Icon(
                    LucideIcons.info,
                    size: 11,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelAccordion(String title, String badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.chevronRight,
            size: 14,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(NumberFormat currencyFormat) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF2D3748),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space8,
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '#',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'Amount',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._selectedInvoice.items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space12,
              vertical: AppTheme.space8,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    item.index.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    currencyFormat.format(item.amount),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Choose Template Panel ──────────────────────────────────────────────────

  Widget _buildChooseTemplatePanel() {
    final templates = [
      'Standard Template',
      'Modern Template',
      'Minimal Template',
    ];
    final filtered = _templateSearchQuery.isEmpty
        ? templates
        : templates
              .where(
                (t) => t.toLowerCase().contains(
                  _templateSearchQuery.toLowerCase(),
                ),
              )
              .toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 270,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(left: BorderSide(color: AppTheme.borderColor)),
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 12,
              offset: Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Choose Template',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => setState(() => _showTemplatePanel = false),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        LucideIcons.search,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _templateSearchController,
                        onChanged: (val) =>
                            setState(() => _templateSearchQuery = val),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search Template',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Template cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  return _buildTemplateCard(filtered[i]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(String templateName) {
    final isSelected = templateName == _selectedTemplate;
    return GestureDetector(
      onTap: () => setState(() => _selectedTemplate = templateName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            // Thumbnail
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.borderColor,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // Mini invoice preview
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 12,
                              color: const Color(0xFF2D3748),
                            ),
                            const Spacer(),
                            Container(
                              width: 50,
                              height: 8,
                              color: const Color(0xFFE2E8F0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 6,
                          color: const Color(0xFFE2E8F0),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 40,
                          height: 5,
                          color: const Color(0xFFE2E8F0),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 50,
                          height: 5,
                          color: const Color(0xFFE2E8F0),
                        ),
                        const Spacer(),
                        Container(
                          height: 16,
                          color: const Color(0xFF2D3748),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                color: const Color(0xFF2D3748),
                              ),
                              Expanded(
                                child: Container(
                                  color: const Color(0xFF2D3748),
                                ),
                              ),
                              Container(
                                width: 30,
                                color: const Color(0xFF2D3748),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 40,
                                  height: 5,
                                  color: const Color(0xFFE2E8F0),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 50,
                                  height: 5,
                                  color: const Color(0xFFE2E8F0),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 45,
                                  height: 5,
                                  color: const Color(0xFFCBD5E0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // SELECTED badge
                  if (isSelected)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 7, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'SELECTED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Label
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(
                templateName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _FilterOptionRow ─────────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashWidth = 4.0;
      const dashSpace = 3.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _FilterOptionRow extends StatefulWidget {
  final String label;
  final bool isStarred;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onStarTap;

  const _FilterOptionRow({
    required this.label,
    required this.isStarred,
    required this.isSelected,
    required this.onTap,
    required this.onStarTap,
  });

  @override
  State<_FilterOptionRow> createState() => _FilterOptionRowState();
}

class _FilterOptionRowState extends State<_FilterOptionRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovered
        ? AppTheme.primaryBlue
        : (widget.isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.08)
              : Colors.transparent);
    final textColor = _isHovered
        ? Colors.white
        : (widget.isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary);
    final starColor = _isHovered
        ? Colors.white
        : (widget.isStarred
              ? const Color(0xFFF59E0B)
              : const Color(0xFFD1D5DB));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: bg,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onStarTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    widget.isStarred ? Icons.star : Icons.star_border,
                    size: 16,
                    color: starColor,
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

// ─── _BulkActionMenuItem ──────────────────────────────────────────────────────

class _BulkActionMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double width;

  const _BulkActionMenuItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.width = 160,
  });

  @override
  State<_BulkActionMenuItem> createState() => _BulkActionMenuItemState();
}

class _BulkActionMenuItemState extends State<_BulkActionMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovered ? AppTheme.primaryBlue : Colors.transparent;
    final textColor = _isHovered ? Colors.white : AppTheme.textPrimary;
    final iconColor = _isHovered ? Colors.white : AppTheme.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: bg,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: iconColor),
                const SizedBox(width: AppTheme.space10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textColor,
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

class _MainMenuItemWidget extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool hasSubMenu;
  final bool isActive;
  final VoidCallback onHover;
  final VoidCallback onTap;

  const _MainMenuItemWidget({
    required this.icon,
    required this.label,
    this.hasSubMenu = false,
    this.isActive = false,
    required this.onHover,
    required this.onTap,
  });

  @override
  State<_MainMenuItemWidget> createState() => _MainMenuItemWidgetState();
}

class _MainMenuItemWidgetState extends State<_MainMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isBlue = widget.isActive || _isHovered;
    final bg = isBlue ? AppTheme.primaryBlue : Colors.transparent;
    final textColor = isBlue ? Colors.white : AppTheme.textPrimary;
    final iconColor = isBlue ? Colors.white : AppTheme.textSecondary;

    return MouseRegion(
      onEnter: (_) {
        widget.onHover();
        setState(() => _isHovered = true);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
          color: bg,
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: iconColor),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              if (widget.hasSubMenu)
                Icon(LucideIcons.chevronRight, size: 14, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigurePaymentNumberPreferencesDialog extends StatefulWidget {
  final String currentLocation;
  final String currentSeries;

  const _ConfigurePaymentNumberPreferencesDialog({
    required this.currentLocation,
    required this.currentSeries,
  });

  @override
  State<_ConfigurePaymentNumberPreferencesDialog> createState() =>
      __ConfigurePaymentNumberPreferencesDialogState();
}

class __ConfigurePaymentNumberPreferencesDialogState
    extends State<_ConfigurePaymentNumberPreferencesDialog> {
  bool _autoGenerate = true;
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _nextNumberController = TextEditingController(
    text: '308',
  );
  final TextEditingController _manualPrefixController = TextEditingController();
  final TextEditingController _manualPaymentNumberController =
      TextEditingController();
  bool _restartFiscalYear = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _nextNumberController.dispose();
    _manualPrefixController.dispose();
    _manualPaymentNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40.0, 0.0, 40.0, 24.0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      child: Container(
        width: 580,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Configure Payment Number Preferences',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),

            // Metadata: Location & Associated Series
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.currentLocation,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Associated Series',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.currentSeries,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),

            // Form Body
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auto-generating payment numbers can save your time. Would you like to change your current setting?',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option 1: Auto-generate
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _autoGenerate,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _autoGenerate = val);
                        },
                      ),
                      const Text(
                        'Auto-generate payment numbers',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.helpCircle,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),

                  // Fields for Auto-generate
                  if (_autoGenerate) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 32,
                        top: 8,
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prefix',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomTextField(
                                  controller: _prefixController,
                                  height: 32,
                                  suffixWidget: Builder(
                                    builder: (iconContext) {
                                      return InkWell(
                                        onTap: () async {
                                          final RenderBox button =
                                              iconContext.findRenderObject()
                                                  as RenderBox;
                                          final RenderBox overlay =
                                              Navigator.of(context)
                                                      .overlay!
                                                      .context
                                                      .findRenderObject()
                                                  as RenderBox;
                                          final RelativeRect position =
                                              RelativeRect.fromRect(
                                                Rect.fromPoints(
                                                  button.localToGlobal(
                                                    button.size.bottomLeft(
                                                      Offset.zero,
                                                    ),
                                                    ancestor: overlay,
                                                  ),
                                                  button.localToGlobal(
                                                    button.size.bottomRight(
                                                      Offset.zero,
                                                    ),
                                                    ancestor: overlay,
                                                  ),
                                                ),
                                                Offset.zero & overlay.size,
                                              );

                                          final val = await showMenu<String>(
                                            context: context,
                                            position: position,
                                            color: Colors.white,
                                            surfaceTintColor:
                                                Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              side: const BorderSide(
                                                color: AppTheme.borderColor,
                                              ),
                                            ),
                                            items: [
                                              PopupMenuItem<String>(
                                                enabled: false,
                                                padding: EdgeInsets.zero,
                                                height: 30,
                                                child: Container(
                                                  height: 30,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                      ),
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    'PLACEHOLDER',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'Fiscal Year Start',
                                                padding: EdgeInsets.zero,
                                                height: 36,
                                                child: _HoverableMenuItem(
                                                  text: 'Fiscal Year Start',
                                                  hasSubmenu: true,
                                                  submenuItems: const [
                                                    'YY',
                                                    'YYYY',
                                                  ],
                                                  onSubmenuSelected: (format) {
                                                    Navigator.of(context).pop(
                                                      '{Fiscal Year Start-$format}',
                                                    );
                                                  },
                                                ),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'Fiscal Year End',
                                                padding: EdgeInsets.zero,
                                                height: 36,
                                                child: const _HoverableMenuItem(
                                                  text: 'Fiscal Year End',
                                                ),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'Transaction Year',
                                                padding: EdgeInsets.zero,
                                                height: 36,
                                                child: const _HoverableMenuItem(
                                                  text: 'Transaction Year',
                                                ),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'Transaction Date',
                                                padding: EdgeInsets.zero,
                                                height: 36,
                                                child: const _HoverableMenuItem(
                                                  text: 'Transaction Date',
                                                ),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'Transaction Month',
                                                padding: EdgeInsets.zero,
                                                height: 36,
                                                child: const _HoverableMenuItem(
                                                  text: 'Transaction Month',
                                                ),
                                              ),
                                            ],
                                          );
                                          if (val != null) {
                                            setState(() {
                                              _prefixController.text += val;
                                            });
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(7),
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.add,
                                              size: 9,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next Number',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomTextField(
                                  controller: _nextNumberController,
                                  height: 32,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _restartFiscalYear,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => _restartFiscalYear = val);
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Restart numbering for payments at the start of each fiscal year.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Option 2: Manual
                  Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: _autoGenerate,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _autoGenerate = val);
                        },
                      ),
                      const Text(
                        'Add payment number manually for this payment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (!_autoGenerate) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 32,
                        top: 8,
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prefix',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomTextField(
                                  controller: _manualPrefixController,
                                  height: 32,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Number',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomTextField(
                                  controller: _manualPaymentNumberController,
                                  height: 32,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop({
                            'autoGenerate': _autoGenerate,
                            'prefix': _autoGenerate
                                ? _prefixController.text
                                : _manualPrefixController.text,
                            'nextNumber': _autoGenerate
                                ? _nextNumberController.text
                                : _manualPaymentNumberController.text,
                            'restartFiscalYear': _restartFiscalYear,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 13),
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
    );
  }
}

class _HoverableMenuItem extends StatefulWidget {
  final String text;
  final bool hasSubmenu;
  final List<String> submenuItems;
  final ValueChanged<String>? onSubmenuSelected;

  const _HoverableMenuItem({
    required this.text,
    this.hasSubmenu = false,
    this.submenuItems = const [],
    this.onSubmenuSelected,
  });

  @override
  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<_HoverableMenuItem> {
  bool _isHovered = false;
  OverlayEntry? _submenuOverlay;
  final LayerLink _layerLink = LayerLink();
  bool _isHoveringSubmenu = false;

  void _showSubmenu() {
    if (_submenuOverlay != null) return;

    final overlay = Overlay.of(context);
    _submenuOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideSubmenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(4, 0),
              child: Material(
                elevation: 6,
                color: Colors.transparent,
                child: MouseRegion(
                  onEnter: (_) {
                    _isHoveringSubmenu = true;
                  },
                  onExit: (_) {
                    _isHoveringSubmenu = false;
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (!_isHovered && !_isHoveringSubmenu) {
                        _hideSubmenu();
                      }
                    });
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.submenuItems.map((item) {
                        return _SubmenuItem(
                          text: item,
                          onTap: () {
                            _hideSubmenu();
                            widget.onSubmenuSelected?.call(item);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_submenuOverlay!);
  }

  void _hideSubmenu() {
    _submenuOverlay?.remove();
    _submenuOverlay = null;
  }

  @override
  void dispose() {
    _hideSubmenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        if (widget.hasSubmenu) {
          _showSubmenu();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        if (widget.hasSubmenu) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (!_isHovered && !_isHoveringSubmenu) {
              _hideSubmenu();
            }
          });
        }
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        color: _isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 12,
                  color: _isHovered ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
            if (widget.hasSubmenu)
              Icon(
                Icons.chevron_right,
                size: 14,
                color: _isHovered ? Colors.white : AppTheme.textSecondary,
              ),
          ],
        ),
      ),
    );

    if (widget.hasSubmenu) {
      content = CompositedTransformTarget(link: _layerLink, child: content);
    }

    return content;
  }
}

class _SubmenuItem extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _SubmenuItem({required this.text, required this.onTap});

  @override
  State<_SubmenuItem> createState() => _SubmenuItemState();
}

class _SubmenuItemState extends State<_SubmenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          color: _isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 12,
              color: _isHovered ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PopoverArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _PopoverArrowPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
