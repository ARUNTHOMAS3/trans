import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:zerpai_erp/modules/sales/recurring_invoices/providers/recurring_invoices_provider.dart';
import 'package:zerpai_erp/modules/sales/recurring_invoices/models/recurring_invoices_model.dart'
    as provider_model;

import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/document/zerpai_document_view.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class ChildInvoiceUI {
  final String id;
  final String date;
  final double amount;
  final String status;
  final String source;
  const ChildInvoiceUI({
    required this.id,
    required this.date,
    required this.amount,
    required this.status,
    required this.source,
  });
}

class RecurringInvoiceUI {
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
  final String profileName;
  final String billingFrequency;
  final String nextInvoiceDate;
  final int manuallyCreatedInvoices;
  final List<String> billingAddress;
  final List<String> shippingAddress;
  final List<ChildInvoiceUI> childInvoices;
  final String startDate;
  final String endDate;
  final String paymentTerms;
  final String salesperson;

  const RecurringInvoiceUI({
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
    required this.profileName,
    required this.billingFrequency,
    required this.nextInvoiceDate,
    required this.manuallyCreatedInvoices,
    required this.billingAddress,
    required this.shippingAddress,
    required this.childInvoices,
    required this.startDate,
    required this.endDate,
    required this.paymentTerms,
    required this.salesperson,
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

const List<RecurringInvoiceUI> _mockInvoices = [
  RecurringInvoiceUI(
    id: '1',
    customerName: 'althaf m',
    date: '20-06-2026',
    amount: 238.00,
    balanceDue: 0.0,
    status: 'ACTIVE',
    drawStatus: 'ACTIVE',
    companyName: 'ZABNIX PRIVATE LIMITED',
    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],
    companyGstin: '32AACCZ4912F1ZL',
    companyPhone: '8086355500',
    companyEmail: 'zabnixprivatelimited@gmail.com',
    billToAddress: ['althafm', 'vengoor'],
    items: [
      RetainerInvoiceItem(
        index: 1,
        description: 'Recurring Profile: althaf',
        amount: 238.00,
      ),
    ],
    profileName: 'althaf',
    billingFrequency: 'Weekly',
    nextInvoiceDate: '20-06-2026',
    manuallyCreatedInvoices: 1,
    billingAddress: [
      'althafm',
      'malayanakath(h)',
      'vengoor (po)',
      'perinthalmanna',
      'Kerala 679322',
      'India',
      'Phone: +91-9895357101',
    ],
    shippingAddress: [
      'althaf.m',
      'malayanakath(h)',
      'vengoor',
      'PERINTHALMANNA',
      'perinthalmanna',
    ],
    childInvoices: [
      ChildInvoiceUI(
        id: 'INV-000088',
        date: '13-06-2026',
        amount: 238.00,
        status: 'DRAFT',
        source: 'Manually Added',
      ),
    ],
    startDate: '13-06-2026',
    endDate: 'Never Expires',
    paymentTerms: 'Net 360',
    salesperson: 'ALTHAF',
  ),
  RecurringInvoiceUI(
    id: '2',
    customerName: 'Acme Corporation',
    date: '01-07-2026',
    amount: 12000.00,
    balanceDue: 0.0,
    status: 'ACTIVE',
    drawStatus: 'ACTIVE',
    companyName: 'ZABNIX PRIVATE LIMITED',
    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],
    companyGstin: '32AACCZ4912F1ZL',
    companyPhone: '8086355500',
    companyEmail: 'zabnixprivatelimited@gmail.com',
    billToAddress: ['ap@acme.com'],
    items: [
      RetainerInvoiceItem(
        index: 1,
        description: 'Recurring Profile: Acme Profile',
        amount: 12000.00,
      ),
    ],
    profileName: 'Acme Profile',
    billingFrequency: 'Monthly',
    nextInvoiceDate: '01-07-2026',
    manuallyCreatedInvoices: 1,
    billingAddress: ['billing@acme.com', 'Acme HQ'],
    shippingAddress: ['Acme HQ'],
    childInvoices: [],
    startDate: '01-07-2026',
    endDate: 'Never Expires',
    paymentTerms: 'Due on Receipt',
    salesperson: 'Salesperson',
  ),
];

// ─── Screen Widget ────────────────────────────────────────────────────────────

// ─── Provider → Local model mapper ──────────────────────────────────────────

RecurringInvoiceUI _fromProviderInvoice(provider_model.RecurringInvoice src) {
  final df = DateFormat('dd-MM-yyyy');
  String statusLabel;
  switch (src.status) {
    case provider_model.RecurringStatus.draft:
      statusLabel = 'DRAFT';
      break;
    case provider_model.RecurringStatus.active:
      statusLabel = 'ACTIVE';
      break;
    case provider_model.RecurringStatus.stopped:
      statusLabel = 'STOPPED';
      break;
    case provider_model.RecurringStatus.expired:
      statusLabel = 'EXPIRED';
      break;
  }
  final drawStatus = src.status == provider_model.RecurringStatus.active
      ? 'ACTIVE'
      : 'INACTIVE';
  final nextInvDateStr = src.nextInvoiceDate != null
      ? df.format(src.nextInvoiceDate!)
      : '20-06-2026';
  return RecurringInvoiceUI(
    id: src.id,
    customerName: src.customerName,
    date: src.nextInvoiceDate != null ? df.format(src.nextInvoiceDate!) : '',
    amount: src.amount,
    balanceDue: 0.0,
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
    billToAddress: ['', src.customerName],
    items: [
      RetainerInvoiceItem(
        index: 1,
        description: 'Recurring Profile: ${src.profileName}',
        amount: src.amount,
      ),
    ],
    profileName: src.profileName,
    billingFrequency: src.billingFrequency,
    nextInvoiceDate: nextInvDateStr,
    manuallyCreatedInvoices: 1,
    billingAddress: const [
      'althafm',
      'malayanakath(h)',
      'vengoor (po)',
      'perinthalmanna',
      'Kerala 679322',
      'India',
      'Phone: +91-9895357101',
    ],
    shippingAddress: const [
      'althaf.m',
      'malayanakath(h)',
      'vengoor',
      'PERINTHALMANNA',
      'perinthalmanna',
    ],
    childInvoices: [
      ChildInvoiceUI(
        id: 'INV-000088',
        date: '13-06-2026',
        amount: src.amount,
        status: 'DRAFT',
        source: 'Manually Added',
      ),
    ],
    startDate: src.nextInvoiceDate != null
        ? df.format(src.nextInvoiceDate!)
        : '13-06-2026',
    endDate: 'Never Expires',
    paymentTerms: 'Net 360',
    salesperson: 'ALTHAF',
  );
}

class RecurringInvoicesOverviewPage extends ConsumerStatefulWidget {
  final String? invoiceId;
  final bool showPreferencesOverlayOnLoad;
  final bool closePreferencesToPreviousRoute;

  const RecurringInvoicesOverviewPage({
    super.key,
    this.invoiceId,
    this.showPreferencesOverlayOnLoad = false,
    this.closePreferencesToPreviousRoute = false,
  });

  @override
  ConsumerState<RecurringInvoicesOverviewPage> createState() =>
      _RecurringInvoicesOverviewPageState();
}

// ─── State ────────────────────────────────────────────────────────────────────

class _RecurringInvoicesOverviewPageState
    extends ConsumerState<RecurringInvoicesOverviewPage> {
  late RecurringInvoiceUI _selectedInvoice;
  String _selectedFilter = 'All';
  String _activeTab = 'Overview';

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
    'Active',
    'Stopped',
    'Expired',
  };
  bool _favoritesExpanded = true;
  bool _defaultFiltersExpanded = true;
  String _selectedSortOption = 'Created Time';
  bool _sortAscending = false;

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
  bool _isInvoiceHovered = false;

  // Preferences Overlay state
  bool _showPreferencesOverlay = false;
  String _preferencesSelectedOption = 'drafts'; // 'drafts', 'send', 'charge'
  bool _sendDraftNotifications = true;
  bool _applyExcessPaymentsToRecurringInvoices = false;
  bool _applyCreditNotesToRecurringInvoices = true;
  String _paymentSuccessPreference =
      'Send Thank-you Email along with the Invoice';
  String _paymentFailurePreference = 'Send Payment Failure Email Notification';
  bool _suspendRecurringInvoiceOnFailure = false;
  bool _disableAutomaticCardSaving = false;
  String _selectedChildInvoiceFilter = 'All';
  String _templateSearchQuery = '';
  final TextEditingController _templateSearchController =
      TextEditingController();

  static const List<String> _paymentSuccessPreferenceOptions = [
    'Send Thank-you Email along with the Invoice',
    'Send invoice only',
    'Do not send any follow-up email',
  ];

  static const List<String> _paymentFailurePreferenceOptions = [
    'Send Payment Failure Email Notification',
    'Retry and notify customer',
    'Do not notify customer',
  ];

  bool _showRecordPaymentPage = false;
  bool _showChildInvoiceDetail = false;
  ChildInvoiceUI? _selectedChildInvoice;
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

  final List<FilterItem> _allFilters = [
    const FilterItem('All'),
    const FilterItem('Draft'),
    const FilterItem('Active'),
    const FilterItem('Stopped'),
    const FilterItem('Expired'),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  // Live list built from provider (populated in didChangeDependencies)
  List<RecurringInvoiceUI> _liveInvoices = _mockInvoices;

  DateTime? _tryParseUiDate(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return DateFormat('dd-MM-yyyy').parseStrict(value.trim());
    } catch (_) {
      return null;
    }
  }

  bool _defaultSortAscendingFor(String option) {
    switch (option) {
      case 'Date':
      case 'Issued Date':
      case 'Created Time':
      case 'Last Modified Time':
        return false;
      default:
        return true;
    }
  }

  int _compareInvoicesBySortOption(
    RecurringInvoiceUI a,
    RecurringInvoiceUI b,
  ) {
    int cmp;
    switch (_selectedSortOption) {
      case 'Date':
      case 'Issued Date':
      case 'Created Time':
        final aDate = _tryParseUiDate(a.date);
        final bDate = _tryParseUiDate(b.date);
        cmp = (aDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          bDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
        break;
      case 'Recurring Invoice Number':
      case 'Reference#':
        cmp = a.id.toLowerCase().compareTo(b.id.toLowerCase());
        break;
      case 'Customer Name':
        cmp = a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase());
        break;
      case 'Total':
        cmp = a.amount.compareTo(b.amount);
        break;
      case 'Balance':
        cmp = a.balanceDue.compareTo(b.balanceDue);
        break;
      case 'Last Modified Time':
        final aDate = _tryParseUiDate(a.nextInvoiceDate) ?? _tryParseUiDate(a.date);
        final bDate = _tryParseUiDate(b.nextInvoiceDate) ?? _tryParseUiDate(b.date);
        cmp = (aDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          bDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
        break;
      default:
        cmp = a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase());
        break;
    }
    return _sortAscending ? cmp : -cmp;
  }

  List<RecurringInvoiceUI> get _sortedLiveInvoices {
    final invoices = List<RecurringInvoiceUI>.from(_liveInvoices);
    invoices.sort(_compareInvoicesBySortOption);
    return invoices;
  }

  @override
  void initState() {
    super.initState();
    // Initial selection will be refined in didChangeDependencies once
    // the ref is available.
    _selectedInvoice = _mockInvoices.first;
    _showPreferencesOverlay = widget.showPreferencesOverlayOnLoad;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromProviderState(ref.read(recurringInvoicesProvider));
  }

  @override
  void didUpdateWidget(covariant RecurringInvoicesOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.invoiceId != oldWidget.invoiceId) {
      _syncFromProviderState(ref.read(recurringInvoicesProvider));
    }
    if (widget.showPreferencesOverlayOnLoad !=
        oldWidget.showPreferencesOverlayOnLoad) {
      _showPreferencesOverlay = widget.showPreferencesOverlayOnLoad;
    }
  }

  void _closePreferencesSurface() {
    if (widget.closePreferencesToPreviousRoute && context.canPop()) {
      context.pop();
      return;
    }
    setState(() {
      _showPreferencesOverlay = false;
    });
  }

  void _syncFromProviderState(RecurringInvoicesState providerState) {
    if (providerState.invoices.isNotEmpty) {
      _liveInvoices = providerState.invoices
          .map<RecurringInvoiceUI>(_fromProviderInvoice)
          .toList();
    } else {
      _liveInvoices = _mockInvoices;
    }

    final previousSelectedId = _selectedInvoice.id;
    final targetId = widget.invoiceId ?? previousSelectedId;
    if (targetId != null) {
      _selectedInvoice = _liveInvoices.firstWhere(
        (i) => i.id == targetId,
        orElse: () => _liveInvoices.first,
      );
    } else {
      _selectedInvoice = _liveInvoices.first;
    }

    _paymentAmountController.text = _selectedInvoice.balanceDue.toStringAsFixed(
      2,
    );
    _paymentDateController.text = _selectedInvoice.date;
    try {
      _paymentDateVal = DateFormat('dd-MM-yyyy').parse(_selectedInvoice.date);
    } catch (_) {
      _paymentDateVal = DateTime.now();
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
    // Remove overlays directly — the _close* helpers call setState, which is
    // illegal during dispose (the element is already defunct even though
    // `mounted` is still true) and throws in markNeedsBuild.
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    _attachmentOverlayEntry?.remove();
    _attachmentOverlayEntry = null;
    _panOverlayEntry?.remove();
    _panOverlayEntry = null;
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
                          boldSelected: false,
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
                          boldSelected: false,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_showCustomerDetailsPanel)
                  Positioned(
                    top: 16,
                    right: -56,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showCustomerDetailsPanel = true),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D3748),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${_selectedInvoice.customerName}'s Details",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              LucideIcons.chevronRight,
                              size: 13,
                              color: Colors.white,
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
                          boldSelected: false,
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
                          boldSelected: false,
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

  Future<void> _pickAttachmentFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final remaining = 5 - _uploadedFiles.length;
    if (remaining <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 files allowed')),
        );
      }
      return;
    }

    final List<PlatformFile> validFiles = [];
    for (final file in result.files.take(remaining)) {
      if (file.size <= 10 * 1024 * 1024) {
        validFiles.add(file);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${file.name} exceeds 10MB size limit')),
          );
        }
      }
    }

    if (validFiles.isNotEmpty) {
      setState(() {
        _uploadedFiles = [..._uploadedFiles, ...validFiles];
      });
      _attachmentOverlayEntry?.markNeedsBuild();
    }
  }

  void _removeAttachmentFile(int index) {
    setState(() {
      _uploadedFiles = List<PlatformFile>.from(_uploadedFiles)..removeAt(index);
    });
    _attachmentOverlayEntry?.markNeedsBuild();
  }

  String _formatFileSize(int bytes) {
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
                        if (_uploadedFiles.isEmpty)
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
                                children: _uploadedFiles.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final file = entry.value;
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
                                            file.name,
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
                                          _formatFileSize(file.size),
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
                            onTap: _pickAttachmentFiles,
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
                                    const Icon(
                                      LucideIcons.upload,
                                      size: 15,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Upload your Files',
                                      style: TextStyle(
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
                                    'Recurring Invoice created for '
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

  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(recurringInvoicesProvider);
    _syncFromProviderState(providerState);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SplitListDetailLayout(
            leftWidth: 300,
            leftHeader: _buildLeftHeader(),
            leftBody: _buildLeftList(currencyFormat),
            rightHeader: _buildRightHeader(),
            rightBody: _buildRightBody(currencyFormat),
          ),
          if (_showCommentsPanel) _buildCommentsHistoryPanel(currencyFormat),
          if (_showPreferencesOverlay) _buildPreferencesOverlay(),
          if (_showTemplatePanel)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: _buildChooseTemplatePanel(),
            ),
          if (_showRecordPaymentPage && _showCustomerDetailsPanel)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: _buildCustomerDetailsPanel(),
            ),
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
                      if (favList.isNotEmpty) ...[
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
                            (f) => _filterOptionRow(
                              label: f.label,
                              isStarred: true,
                            ),
                          ),
                      ],

                      // DEFAULT FILTERS
                      if (favList.isNotEmpty)
                        _filterSectionHeader(
                          title: 'DEFAULT FILTERS',
                          count: defaultList.length,
                          isExpanded: _defaultFiltersExpanded,
                          onTap: () => setState(
                            () => _defaultFiltersExpanded =
                                !_defaultFiltersExpanded,
                          ),
                        ),
                      if (favList.isEmpty || _defaultFiltersExpanded)
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
                color: isExpanded
                    ? AppTheme.successGreen
                    : const Color(0xFF9CA3AF),
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
                                label: 'Import Recurring Invoices',
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
                                onTap: () {
                                  _closeMoreMenu();
                                  setState(() {
                                    _showPreferencesOverlay = true;
                                  });
                                },
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
      'Recurring Invoice Number',
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
          final isSelected = opt == _selectedSortOption;
          final isHovered = hoveredItem == opt;
          return MouseRegion(
            onEnter: (_) => setHovered(opt),
            onExit: (_) => setHovered(null),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_selectedSortOption == opt) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _selectedSortOption = opt;
                    _sortAscending = _defaultSortAscendingFor(opt);
                  }
                });
                _closeMoreMenu();
              },
              child: Container(
                height: 36,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                ),
                decoration: BoxDecoration(
                  color: isHovered
                      ? AppTheme.primaryBlue
                      : (isSelected
                            ? const Color(0xFFE2E8F0)
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                ),
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
                    if (isSelected)
                      Icon(
                        _sortAscending
                            ? LucideIcons.arrowUp
                            : LucideIcons.arrowDown,
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
    final exportOptions = ['Export Recurring Invoices', 'Export Current View'];

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
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                ),
                decoration: BoxDecoration(
                  color: isHovered ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
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

  Future<void> _showBulkUpdateDialog() async {
    final selectedInvoices = _liveInvoices
        .where((invoice) => _checkedIds.contains(invoice.id))
        .toList();
    if (selectedInvoices.isEmpty) return;

    _bulkMenuController.close();
    await showDialog<Map<String, String>>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) =>
          _OverviewBulkUpdateDialog(selectedInvoices: selectedInvoices),
    );
  }

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
                value: true,
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
                  label: 'Bulk Update',
                  onTap: () async {
                    await _showBulkUpdateDialog();
                  },
                  width: 140,
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                _BulkActionMenuItem(
                  label: 'Resume',
                  onTap: () {
                    _bulkMenuController.close();
                  },
                  width: 140,
                ),
                _BulkActionMenuItem(
                  label: 'Stop',
                  onTap: () {
                    _bulkMenuController.close();
                  },
                  width: 140,
                ),
                _BulkActionMenuItem(
                  label: 'Delete',
                  onTap: () {
                    _bulkMenuController.close();
                  },
                  width: 140,
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
              child: const Icon(LucideIcons.x, size: 16, color: Colors.red),
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
          Expanded(
            child: MenuAnchor(
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
                        Flexible(
                          child: Text(
                            _selectedFilter == 'All'
                                ? 'All Recurring Inv...'
                                : _selectedFilter,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
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
          ),
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
                final orgId =
                    GoRouterState.of(context).pathParameters['orgSystemId'] ??
                    '6000000000';
                context.go('/$orgId${AppRoutes.salesRecurringInvoicesCreate}');
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
    final sortedInvoices = _sortedLiveInvoices;
    return Container(
      color: Colors.white,
      child: ListView.separated(
        itemCount: sortedInvoices.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: AppTheme.borderColor),
        itemBuilder: (context, index) {
          final inv = sortedInvoices[index];
          final isChecked = _checkedIds.contains(inv.id);
          final isHovered = _hoveredId == inv.id;

          final isSelected = _selectedInvoice.id == inv.id;

          Color rowBg = Colors.transparent;
          if (isHovered) {
            rowBg = const Color(0xFFF3F4F6);
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
                  _showChildInvoiceDetail = false;
                  _selectedChildInvoice = null;
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
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: isChecked,
                            activeColor: AppTheme.primaryBlue,
                            checkColor: Colors.white,
                            fillColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return AppTheme.primaryBlue;
                              }
                              return Colors.white;
                            }),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: const BorderSide(
                              color: Color(0xFF8E99A8),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                inv.profileName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              Text(
                                inv.billingFrequency,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                inv.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: inv.status.toUpperCase() == 'ACTIVE'
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'Next Invoice on ${inv.nextInvoiceDate}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF000000),
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
            ),
          );
        },
      ),
    );
  }

  // ── Right Header ───────────────────────────────────────────────────────────

  Widget? _buildRightHeader() {
    final showChild =
        (_showRecordPaymentPage || _showChildInvoiceDetail) &&
        _selectedChildInvoice != null;
    if (showChild) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: breadcrumb/title + utility icons
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
                      _selectedChildInvoice!.id,
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
                _buildIconButton(
                  LucideIcons.x,
                  color: Colors.red.shade600,
                  onTap: () {
                    setState(() {
                      _showRecordPaymentPage = false;
                      _showChildInvoiceDetail = false;
                    });
                  },
                ),
              ],
            ),
          ),
          // Row 2: action tabs
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
                    context.go(
                      '/$_orgId${AppRoutes.salesRecurringInvoicesCreate}?id=${_selectedInvoice.id}',
                    );
                  },
                ),
                _buildTabSeparator(),
                _buildFlatActionTab(LucideIcons.mail, 'Send Email'),
                _buildTabSeparator(),
                // PDF/Print dropdown
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
                // Record Payment dropdown menu
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
                        setState(() {
                          _showRecordPaymentPage = true;
                          _showChildInvoiceDetail = false;
                          if (_selectedChildInvoice != null) {
                            _paymentAmountController.text =
                                _selectedChildInvoice!.amount.toStringAsFixed(
                                  2,
                                );
                          }
                        });
                      },
                    ),
                  ],
                ),
                _buildTabSeparator(),
                // Three-dot more menu
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
                    return InkWell(
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          LucideIcons.moreHorizontal,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  },
                  menuChildren: [
                    _BulkActionMenuItem(
                      label: 'Mark As Sent',
                      icon: LucideIcons.mail,
                      onTap: () => _rightMoreMenuController.close(),
                    ),
                    _BulkActionMenuItem(
                      label: 'Clone',
                      icon: LucideIcons.copy,
                      onTap: () => _rightMoreMenuController.close(),
                    ),
                    _BulkActionMenuItem(
                      label: 'Stop',
                      icon: LucideIcons.ban,
                      onTap: () => _rightMoreMenuController.close(),
                    ),
                    _BulkActionMenuItem(
                      label: 'Delete',
                      icon: LucideIcons.trash2,
                      onTap: () => _rightMoreMenuController.close(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
        color: Colors.white,
        child: Row(
          children: [
            Text(
              _selectedInvoice.profileName.isNotEmpty
                  ? _selectedInvoice.profileName
                  : _selectedInvoice.customerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            _buildIconButton(
              LucideIcons.pencil,
              onTap: () {
                context.go(
                  '/$_orgId${AppRoutes.salesRecurringInvoicesCreate}?id=${_selectedInvoice.id}',
                );
              },
            ),
            const SizedBox(width: AppTheme.space8),
            OutlinedButton(
              onPressed: () {
                // Trigger manual child invoice generation
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF4F4F4),
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.borderColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Create Invoice',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: AppTheme.space8),
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
                return OutlinedButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F4F4),
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'More',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        controller.isOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 10,
                      ),
                    ],
                  ),
                );
              },
              menuChildren: [
                _BulkActionMenuItem(
                  label: 'Stop',
                  onTap: () => _rightMoreMenuController.close(),
                  width: 140,
                ),
                _BulkActionMenuItem(
                  label: 'Clone',
                  onTap: () => _rightMoreMenuController.close(),
                  width: 140,
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                _BulkActionMenuItem(
                  label: 'Delete',
                  onTap: () => _rightMoreMenuController.close(),
                  width: 140,
                ),
              ],
            ),
            const SizedBox(width: AppTheme.space8),
            InkWell(
              onTap: () {
                context.go('/$_orgId${AppRoutes.salesRecurringInvoices}');
              },
              child: const Icon(LucideIcons.x, size: 22, color: Colors.black),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFlatActionTab(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
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

  Widget _buildRightBody(NumberFormat currencyFormat) {
    if (_showRecordPaymentPage) {
      return _buildRecordPaymentForm(currencyFormat);
    }
    if (_showChildInvoiceDetail) {
      return _buildChildInvoiceDetailView(currencyFormat);
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tabs row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            height: 48,
            child: Row(
              children: [
                _buildTabItem('Overview'),
                const SizedBox(width: 24),
                _buildTabItem('Next Invoice'),
                const SizedBox(width: 24),
                _buildTabItem('Recent Activities'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDADFE7)),
          Expanded(
            child: _activeTab == 'Overview'
                ? _buildOverviewTab(currencyFormat)
                : _activeTab == 'Next Invoice'
                ? _buildNextInvoiceTab()
                : _activeTab == 'Recent Activities'
                ? _buildRecentActivitiesTab()
                : _buildOtherTabsPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String tabName) {
    final isActive = _activeTab == tabName;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabName),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          tabName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
            color: isActive ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(NumberFormat currencyFormat) {
    final inv = _selectedInvoice;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Details & Address)
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFFFAFCF9),
            padding: const EdgeInsets.all(24),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Profile/Customer Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          LucideIcons.user,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        inv.customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Profile Status:',
                    _buildStatusBadge(inv.status),
                  ),
                  _buildDetailRow(
                    'Location:',
                    Text(
                      inv.companyName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  _buildDetailRow(
                    'Start Date:',
                    Text(
                      inv.startDate,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  _buildDetailRow(
                    'End Date:',
                    Text(
                      inv.endDate,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  _buildDetailRow(
                    'Payment Terms:',
                    Text(
                      inv.paymentTerms,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  _buildDetailRow(
                    'Salesperson:',
                    Text(
                      inv.salesperson.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  _buildDetailRow(
                    'Manually Created Invoices:',
                    Text(
                      inv.manuallyCreatedInvoices.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Preference banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 14,
                          color: Color(0xFF3B82F6),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Recurring Invoice preference has been set to \"Create Invoices as Drafts\"",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF1F2937),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ADDRESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Billing Address',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...inv.billingAddress.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: line.startsWith('Phone:')
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF000000),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Shipping Address',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...inv.shippingAddress.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF000000),
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
        const VerticalDivider(width: 1, color: AppTheme.borderColor),
        // Right Column (KPI Cards & Child Invoices Table)
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 3 KPI Boxes
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(color: Color(0xFFFAFAFC)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Invoice Amount',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(inv.amount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFE5E7EB),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Next Invoice Date',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            inv.nextInvoiceDate,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: const Color(0xFFE5E7EB),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Recurring Period',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            inv.billingFrequency,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Child Invoices Section
                      Row(
                        children: [
                          MenuAnchor(
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
                                    Text(
                                      _selectedChildInvoiceFilter == 'All'
                                          ? 'All Child Invoices'
                                          : '${_selectedChildInvoiceFilter} Child Invoices',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      LucideIcons.chevronDown,
                                      size: 15,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ],
                                ),
                              );
                            },
                            menuChildren: [
                              MenuItemButton(
                                onPressed: () => setState(
                                  () => _selectedChildInvoiceFilter = 'All',
                                ),
                                style: _childInvoiceFilterMenuItemStyle(),
                                child: const SizedBox(
                                  width: 180,
                                  child: Text('All'),
                                ),
                              ),
                              MenuItemButton(
                                onPressed: () => setState(
                                  () => _selectedChildInvoiceFilter = 'Unpaid',
                                ),
                                style: _childInvoiceFilterMenuItemStyle(),
                                child: const SizedBox(
                                  width: 180,
                                  child: Text('Unpaid'),
                                ),
                              ),
                              MenuItemButton(
                                onPressed: () => setState(
                                  () => _selectedChildInvoiceFilter = 'Paid',
                                ),
                                style: _childInvoiceFilterMenuItemStyle(),
                                child: const SizedBox(
                                  width: 180,
                                  child: Text('Paid'),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            'Unpaid Invoices : \u20B90.00',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final filteredList = inv.childInvoices.where((
                              child,
                            ) {
                              if (_selectedChildInvoiceFilter == 'Unpaid') {
                                return child.status.toUpperCase() != 'PAID';
                              } else if (_selectedChildInvoiceFilter ==
                                  'Paid') {
                                return child.status.toUpperCase() == 'PAID';
                              }
                              return true;
                            }).toList();

                            if (filteredList.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No child invoices generated yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filteredList.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Color(0xFFE5E7EB),
                                    ),
                                    itemBuilder: (context, index) {
                                      final child = filteredList[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    inv.customerName,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF1F2937),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            _selectedChildInvoice =
                                                                child;
                                                            _showChildInvoiceDetail =
                                                                true;
                                                            _showRecordPaymentPage =
                                                                false;
                                                          });
                                                        },
                                                        child: Text(
                                                          child.id,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Color(
                                                              0xFF3B82F6,
                                                            ),
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        child.date,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(
                                                            0xFF6B7280,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        LucideIcons.info,
                                                        size: 12,
                                                        color: Color(
                                                          0xFF9CA3AF,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        child.source,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(
                                                            0xFF9CA3AF,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  currencyFormat.format(
                                                    child.amount,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  child.status,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _showRecordPaymentPage =
                                                          true;
                                                      _showChildInvoiceDetail =
                                                          false;
                                                      _selectedChildInvoice =
                                                          child;
                                                    });
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF10B981),
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Record Payment',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE5E7EB),
                                ),
                              ],
                            );
                          },
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

  Widget _buildDetailRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFE5E7EB);
    Color text = const Color(0xFF374151);
    if (status.toUpperCase() == 'ACTIVE') {
      bg = const Color(0xFF3B7A12);
      text = Colors.white;
    } else if (status.toUpperCase() == 'STOPPED') {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFF991B1B);
    } else if (status.toUpperCase() == 'EXPIRED') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFF92400E);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: text,
          ),
        ),
      ),
    );
  }

  Widget _buildOtherTabsPlaceholder() {
    return Center(
      child: Text(
        '$_activeTab content',
        style: const TextStyle(fontSize: 16, color: Colors.grey),
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

  ButtonStyle _childInvoiceFilterMenuItemStyle() {
    return ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return AppTheme.primaryBlue;
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return Colors.white;
        }
        return AppTheme.textPrimary;
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      alignment: Alignment.centerLeft,
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
          color: isActive ? const Color(0xFFE9EDF0) : const Color(0xFFF4F4F4),
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
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
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

  Widget _buildPreferencesOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  const Text(
                    'LIMITED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  // Search Bar Visual
                  Container(
                    width: 320,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: 14,
                          color: AppTheme.primaryBlue,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Search settings ( / )',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Close Settings Button
                  InkWell(
                    onTap: _closePreferencesSurface,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Close Settings',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(LucideIcons.x, size: 14, color: Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1020),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          'Recurring Invoices',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Tab (General)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'General',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 50,
                              height: 2,
                              color: AppTheme.primaryBlue,
                            ),
                          ],
                        ),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        const SizedBox(height: 24),
                        // Blue Info Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: 16,
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Recurring Invoices are automatically created based on a configured schedule. Here you can configure the auto-charging option and the process of sending these invoices to your customers.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1E3A8A),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Option 1
                        _buildPreferenceOption(
                          value: 'drafts',
                          title: 'Create Invoices as Drafts',
                          description:
                              'Invoices will be saved as drafts. You can review and send them to your customers for payment.',
                          nestedChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notification Preferences',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _sendDraftNotifications,
                                      activeColor: AppTheme.primaryBlue,
                                      onChanged: (val) {
                                        setState(() {
                                          _sendDraftNotifications =
                                              val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Send email notifications when invoices are created as drafts.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Option 2
                        _buildPreferenceOption(
                          value: 'send',
                          title: 'Create, Push, and Send Invoices',
                          description:
                              'Invoices will be pushed to the IRP and sent to your customers for payment.',
                          nestedChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value:
                                          _applyExcessPaymentsToRecurringInvoices,
                                      activeColor: AppTheme.primaryBlue,
                                      onChanged: (val) {
                                        setState(() {
                                          _applyExcessPaymentsToRecurringInvoices =
                                              val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Apply customer\'s excess payments to their recurring invoices',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value:
                                          _applyCreditNotesToRecurringInvoices,
                                      activeColor: AppTheme.primaryBlue,
                                      onChanged: (val) {
                                        setState(() {
                                          _applyCreditNotesToRecurringInvoices =
                                              val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Apply customer\'s credit notes to their recurring invoices',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Option 3
                        _buildPreferenceOption(
                          value: 'charge',
                          title: 'Create, Charge, Push, and Send Invoices',
                          description:
                              "Your customer's payment method associated with the recurring invoice will be charged automatically. Next, the invoices will be pushed to the IRP and then sent to your customers.",
                          nestedChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'You can configure the retry preferences, and customize the email notification that will be sent to your customers by clicking the corresponding payment method (Credit Card or ACH).',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildPreferenceActionCard(
                                      icon: LucideIcons.thumbsUp,
                                      title: 'On Payment Success',
                                      value: _paymentSuccessPreference,
                                      items: _paymentSuccessPreferenceOptions,
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _paymentSuccessPreference = value;
                                        });
                                      },
                                      links: const ['Credit Card and ACH'],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildPreferenceActionCard(
                                      icon: LucideIcons.thumbsDown,
                                      title: 'On Payment Failure',
                                      value: _paymentFailurePreference,
                                      items: _paymentFailurePreferenceOptions,
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _paymentFailurePreference = value;
                                        });
                                      },
                                      links: const ['Credit Card', 'ACH'],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildPreferenceCheckboxRow(
                                value: _suspendRecurringInvoiceOnFailure,
                                label:
                                    'After failure, suspend the recurring invoice',
                                onChanged: (value) {
                                  setState(() {
                                    _suspendRecurringInvoiceOnFailure =
                                        value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildPreferenceCheckboxRow(
                                value: _disableAutomaticCardSaving,
                                label:
                                    'Disable automatic saving of card details',
                                helperText:
                                    'This option would disable the automatic selection of the option to save card details in the Customer Portal.',
                                onChanged: (value) {
                                  setState(() {
                                    _disableAutomaticCardSaving =
                                        value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildPreferenceCheckboxRow(
                                value: _applyExcessPaymentsToRecurringInvoices,
                                label:
                                    'Apply customer\'s excess payments to their recurring invoices',
                                onChanged: (value) {
                                  setState(() {
                                    _applyExcessPaymentsToRecurringInvoices =
                                        value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildPreferenceCheckboxRow(
                                value: _applyCreditNotesToRecurringInvoices,
                                label:
                                    'Apply customer\'s credit notes to their recurring invoices',
                                onChanged: (value) {
                                  setState(() {
                                    _applyCreditNotesToRecurringInvoices =
                                        value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Note: Since your customer will be autocharged, payment reminder will be disabled.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      LucideIcons.info,
                                      size: 15,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'These changes will not be applicable to recurring invoices that have a different preference at the profile level.',
                                        style: TextStyle(
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
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: AppTheme.borderColor),
                        const SizedBox(height: 20),
                        // Save Button
                        ElevatedButton(
                          onPressed: () {
                            _closePreferencesSurface();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22B378),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }

  Widget _buildPreferenceCheckboxRow({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                activeColor: AppTheme.primaryBlue,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              helperText,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreferenceActionCard({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required List<String> links,
  }) {
    final bool isFailureCard = title == 'On Payment Failure';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF667085)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
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
          const Divider(height: 1, color: AppTheme.borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 36,
                  child: FormDropdown<String>(
                    value: value,
                    items: items,
                    onChanged: onChanged,
                    showSearch: true,
                    menuWidth: 380,
                    itemHeight: 38,
                    itemBuilder: (item, isSelected, isHovered) =>
                        _buildPreferenceDropdownItem(
                          item: item,
                          isSelected: isSelected,
                          isHovered: isHovered,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mailCheck,
                      size: 14,
                      color: Color(0xFF667085),
                    ),
                    const SizedBox(width: 6),
                    for (int index = 0; index < links.length; index++) ...[
                      InkWell(
                        onTap: () => _openPaymentNotificationTemplateDialog(
                          templateType: isFailureCard
                              ? 'Payment Failure Notification'
                              : 'Payment Success Notification',
                          paymentMethod: links[index],
                          subject: isFailureCard
                              ? 'Unable to process payment for %InvoiceNumber%'
                              : 'Payment received for %InvoiceNumber%',
                          body: isFailureCard
                              ? 'Dear %CustomerName%, Payment for the invoice %InvoiceNumber% has been declined. Invoice Date: %InvoiceDate% Due Date: %DueDate% Amount: %Total% Reason for Decline: %PaymentFailureMessage% In case you wish to make a direct payment, please click here'
                              : 'Dear %CustomerName%, Payment for the invoice %InvoiceNumber% has been successfully processed. Invoice Date: %InvoiceDate% Amount: %Total% Thank you for your payment.',
                        ),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            links[index],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      if (index < links.length - 1) ...[
                        const SizedBox(width: 8),
                        const Text(
                          '|',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceDropdownItem({
    required String item,
    required bool isSelected,
    required bool isHovered,
  }) {
    final bool showBlueHover = isHovered;
    final Color backgroundColor = showBlueHover
        ? AppTheme.infoBlue
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
    final Color textColor = showBlueHover ? Colors.white : AppTheme.textPrimary;
    final Color tickColor = showBlueHover ? Colors.white : AppTheme.textPrimary;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
          if (isSelected) Icon(Icons.check, size: 16, color: tickColor),
        ],
      ),
    );
  }

  Future<void> _openPaymentNotificationTemplateDialog({
    required String templateType,
    required String paymentMethod,
    required String subject,
    required String body,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) => _PaymentNotificationTemplateDialog(
        title: '$templateType - Default',
        templateName: 'Default',
        paymentMethod: paymentMethod,
        subject: subject,
        body: body,
      ),
    );
  }

  Widget _buildPreferenceOption({
    required String value,
    required String title,
    required String description,
    Widget? nestedChild,
  }) {
    final isSelected = _preferencesSelectedOption == value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Radio<String>(
                value: value,
                // ignore: deprecated_member_use
                groupValue: _preferencesSelectedOption,
                activeColor: AppTheme.primaryBlue,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  setState(() {
                    _preferencesSelectedOption = val!;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 28, top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              if (isSelected && nestedChild != null) ...[
                const SizedBox(height: 16),
                nestedChild,
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Child Invoice Detail View (shown when Record Payment is clicked) ─────
  Widget _buildChildInvoiceDetailView(NumberFormat currencyFormat) {
    final inv = _selectedInvoice;
    final child = _selectedChildInvoice;
    if (child == null) {
      return const Center(child: Text('No child invoice selected'));
    }

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Credits Available banner
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.copyright,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Credits Available: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    currencyFormat.format(200.00),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Apply Now',
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
            const Divider(height: 1, color: AppTheme.borderColor),

            // What's Next? banner
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  const Text(
                    "WHAT'S NEXT?",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Send this Invoice to your customer or mark it as Sent.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Send Invoice',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F2937),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Mark As Sent',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),

            // TAX INVOICE Document Preview
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isInvoiceHovered = true),
                    onExit: (_) => setState(() => _isInvoiceHovered = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 12,
                            right: 12,
                            child: AnimatedOpacity(
                              opacity:
                                  (_isInvoiceHovered ||
                                      _customizeMenuController.isOpen)
                                  ? 1.0
                                  : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: IgnorePointer(
                                ignoring:
                                    !(_isInvoiceHovered ||
                                        _customizeMenuController.isOpen),
                                child: MenuAnchor(
                                  controller: _customizeMenuController,
                                  onClose: () => setState(() {}),
                                  style: const MenuStyle(
                                    alignment: AlignmentDirectional.bottomEnd,
                                    minimumSize: WidgetStatePropertyAll(
                                      Size(200, 0),
                                    ),
                                    backgroundColor: WidgetStatePropertyAll(
                                      Colors.white,
                                    ),
                                    surfaceTintColor: WidgetStatePropertyAll(
                                      Colors.white,
                                    ),
                                    padding: WidgetStatePropertyAll(
                                      EdgeInsets.zero,
                                    ),
                                    elevation: WidgetStatePropertyAll(8),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        side: BorderSide(
                                          color: AppTheme.borderColor,
                                        ),
                                        borderRadius: BorderRadius.all(
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
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              LucideIcons.settings,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Customize',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              controller.isOpen
                                                  ? LucideIcons.chevronUp
                                                  : LucideIcons.chevronDown,
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
                                        _customizeMenuController.close();
                                      },
                                    ),
                                    _BulkActionMenuItem(
                                      label: 'Change Template',
                                      width: 200,
                                      onTap: () {
                                        setState(
                                          () => _showTemplatePanel = true,
                                        );
                                        _customizeMenuController.close();
                                      },
                                    ),
                                    _BulkActionMenuItem(
                                      label: 'Edit Template',
                                      width: 200,
                                      onTap: () {
                                        _customizeMenuController.close();
                                      },
                                    ),
                                    _BulkActionMenuItem(
                                      label: 'Update Logo & Address',
                                      width: 200,
                                      onTap: () {
                                        _customizeMenuController.close();
                                      },
                                    ),
                                    _BulkActionMenuItem(
                                      label: 'Manage Custom Fields',
                                      width: 185,
                                      onTap: () {
                                        _customizeMenuController.close();
                                      },
                                    ),
                                    _BulkActionMenuItem(
                                      label: 'Terms & Conditions',
                                      width: 185,
                                      onTap: () {
                                        _customizeMenuController.close();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFD1D5DB),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Row 0: Logo block
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          48,
                                          16,
                                          16,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 120,
                                              height: 50,
                                              color: const Color(0xFF101820),
                                              alignment: Alignment.center,
                                              child: const Text(
                                                'LOGO',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    inv.companyName
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  ...inv.companyAddress.map(
                                                    (line) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 2,
                                                          ),
                                                      child: Text(
                                                        line,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'GSTIN ${inv.companyGstin}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                  Text(
                                                    inv.companyPhone,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                  Text(
                                                    inv.companyEmail,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Text(
                                              'TAX INVOICE',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFD1D5DB),
                                      ),

                                      // Row 1: Info block
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: const BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(
                                                    color: Color(0xFFD1D5DB),
                                                  ),
                                                ),
                                              ),
                                              child: Table(
                                                columnWidths: const {
                                                  0: FixedColumnWidth(100),
                                                  1: FlexColumnWidth(),
                                                },
                                                children: [
                                                  _buildInfoRow(
                                                    '#',
                                                    child.id,
                                                    isValBold: true,
                                                  ),
                                                  _buildInfoRow(
                                                    'Invoice Date',
                                                    child.date,
                                                  ),
                                                  _buildInfoRow(
                                                    'Terms',
                                                    inv.paymentTerms,
                                                  ),
                                                  _buildInfoRow(
                                                    'Due Date',
                                                    '05-06-2027',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              child: Table(
                                                columnWidths: const {
                                                  0: FixedColumnWidth(120),
                                                  1: FlexColumnWidth(),
                                                },
                                                children: [
                                                  _buildInfoRow(
                                                    'Place Of Supply',
                                                    'Kerala (32)',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFFD1D5DB),
                                      ),

                                      // Row 2: Bill To / Ship To
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: const BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(
                                                    color: Color(0xFFD1D5DB),
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Bill To',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    inv.customerName,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppTheme.primaryBlue,
                                                    ),
                                                  ),
                                                  ...inv.billingAddress.map(
                                                    (line) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 2,
                                                          ),
                                                      child: Text(
                                                        line,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Ship To',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ...inv.shippingAddress.map(
                                                    (line) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 2,
                                                          ),
                                                      child: Text(
                                                        line,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 52),

                                // Items table header
                                Container(
                                  color: const Color(0xFFF1F5F9),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  child: const Row(
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        child: Text(
                                          '#',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Item & Description',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          'HSN/SAC',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          'Qty',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          'Rate',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          'Amount',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: AppTheme.borderColor,
                                ),

                                // Items rows
                                ...inv.items.map(
                                  (item) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: AppTheme.borderColor,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 30,
                                          child: Text(
                                            '${item.index}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            item.description,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 80,
                                          child: Text(
                                            '342441',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 50,
                                          child: Text(
                                            '1.00',
                                            style: TextStyle(fontSize: 10),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            child.amount.toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 90,
                                          child: Text(
                                            child.amount.toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Totals + Notes
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Total In Words',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Indian Rupee ${_amountToWords(child.amount)} Only',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Notes',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Thanks for your business.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 40),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        children: [
                                          _buildTotalRow(
                                            'Sub Total',
                                            child.amount.toStringAsFixed(2),
                                          ),
                                          _buildTotalRow(
                                            'Total',
                                            '₹${child.amount.toStringAsFixed(2)}',
                                            isBold: true,
                                          ),
                                          _buildTotalRow(
                                            'Balance Due',
                                            '₹${child.amount.toStringAsFixed(2)}',
                                            isBold: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Draft ribbon
                          Positioned(
                            top: 0,
                            left: 0,
                            child: ZerpaiDocumentCornerRibbon(
                              label: child.status,
                              color: child.status.toUpperCase() == 'PAID'
                                  ? AppTheme.successGreen
                                  : child.status.toUpperCase() == 'DRAFT'
                                  ? Colors.blueGrey.shade400
                                  : AppTheme.warningOrange,
                            ),
                          ),
                        ],
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

  String _amountToWords(double amount) {
    final intAmount = amount.toInt();
    if (intAmount == 0) return 'Zero';
    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];
    String convert(int n) {
      if (n < 20) return ones[n];
      if (n < 100)
        return '${tens[n ~/ 10]}${n % 10 > 0 ? ' ${ones[n % 10]}' : ''}';
      if (n < 1000)
        return '${ones[n ~/ 100]} Hundred${n % 100 > 0 ? ' ${convert(n % 100)}' : ''}';
      if (n < 100000)
        return '${convert(n ~/ 1000)} Thousand${n % 1000 > 0 ? ' ${convert(n % 1000)}' : ''}';
      if (n < 10000000)
        return '${convert(n ~/ 100000)} Lakh${n % 100000 > 0 ? ' ${convert(n % 100000)}' : ''}';
      return '${convert(n ~/ 10000000)} Crore${n % 10000000 > 0 ? ' ${convert(n % 10000000)}' : ''}';
    }

    return convert(intAmount);
  }

  Widget _buildNextInvoiceTab() {
    final inv = _selectedInvoice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: MouseRegion(
                        onEnter: (_) =>
                            setState(() => _isInvoiceHovered = true),
                        onExit: (_) =>
                            setState(() => _isInvoiceHovered = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppTheme.borderColor),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 12,
                                right: 12,
                                child: AnimatedOpacity(
                                  opacity:
                                      (_isInvoiceHovered ||
                                          _customizeMenuController.isOpen)
                                      ? 1.0
                                      : 0.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: IgnorePointer(
                                    ignoring:
                                        !(_isInvoiceHovered ||
                                            _customizeMenuController.isOpen),
                                    child: MenuAnchor(
                                      controller: _customizeMenuController,
                                      onClose: () => setState(() {}),
                                      style: const MenuStyle(
                                        alignment:
                                            AlignmentDirectional.bottomEnd,
                                        minimumSize: WidgetStatePropertyAll(
                                          Size(200, 0),
                                        ),
                                        backgroundColor: WidgetStatePropertyAll(
                                          Colors.white,
                                        ),
                                        surfaceTintColor:
                                            WidgetStatePropertyAll(
                                              Colors.white,
                                            ),
                                        padding: WidgetStatePropertyAll(
                                          EdgeInsets.zero,
                                        ),
                                        elevation: WidgetStatePropertyAll(8),
                                        shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: AppTheme.borderColor,
                                            ),
                                            borderRadius: BorderRadius.all(
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.successGreen,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  LucideIcons.settings,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Customize',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  controller.isOpen
                                                      ? LucideIcons.chevronUp
                                                      : LucideIcons.chevronDown,
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
                                            _customizeMenuController.close();
                                          },
                                        ),
                                        _BulkActionMenuItem(
                                          label: 'Change Template',
                                          width: 200,
                                          onTap: () {
                                            setState(
                                              () => _showTemplatePanel = true,
                                            );
                                            _customizeMenuController.close();
                                          },
                                        ),
                                        _BulkActionMenuItem(
                                          label: 'Edit Template',
                                          width: 200,
                                          onTap: () {
                                            _customizeMenuController.close();
                                          },
                                        ),
                                        _BulkActionMenuItem(
                                          label: 'Update Logo & Address',
                                          width: 200,
                                          onTap: () {
                                            _customizeMenuController.close();
                                          },
                                        ),
                                        _BulkActionMenuItem(
                                          label: 'Manage Custom Fields',
                                          width: 185,
                                          onTap: () {
                                            _customizeMenuController.close();
                                          },
                                        ),
                                        _BulkActionMenuItem(
                                          label: 'Terms & Conditions',
                                          width: 185,
                                          onTap: () {
                                            _customizeMenuController.close();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  40,
                                  80,
                                  40,
                                  40,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFD1D5DB),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Row 0: Logo block
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              48,
                                              16,
                                              16,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 120,
                                                  height: 50,
                                                  color: const Color(
                                                    0xFF101820,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    'LOGO',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        inv.companyName
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      ...inv.companyAddress.map(
                                                        (line) => Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                bottom: 2,
                                                              ),
                                                          child: Text(
                                                            line,
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color: AppTheme
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'GSTIN ${inv.companyGstin}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      Text(
                                                        inv.companyPhone,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      Text(
                                                        inv.companyEmail,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Text(
                                                  'TAX INVOICE',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Divider(
                                            height: 1,
                                            color: Color(0xFFD1D5DB),
                                          ),

                                          // Row 1: Info block
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          right: BorderSide(
                                                            color: Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  child: Table(
                                                    columnWidths: const {
                                                      0: FixedColumnWidth(100),
                                                      1: FlexColumnWidth(),
                                                    },
                                                    children: [
                                                      _buildInfoRow(
                                                        '#',
                                                        'Will be generated automatically',
                                                        isValBold: true,
                                                      ),
                                                      _buildInfoRow(
                                                        'Invoice Date',
                                                        inv.date,
                                                      ),
                                                      _buildInfoRow(
                                                        'Terms',
                                                        inv.paymentTerms,
                                                      ),
                                                      _buildInfoRow(
                                                        'Due Date',
                                                        '15-06-2027',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  child: Table(
                                                    columnWidths: const {
                                                      0: FixedColumnWidth(120),
                                                      1: FlexColumnWidth(),
                                                    },
                                                    children: [
                                                      _buildInfoRow(
                                                        'Place Of Supply',
                                                        'Kerala (32)',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(
                                            height: 1,
                                            color: Color(0xFFD1D5DB),
                                          ),

                                          // Row 2: Bill To / Ship To
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          right: BorderSide(
                                                            color: Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'Bill To',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        inv.customerName,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .primaryBlue,
                                                        ),
                                                      ),
                                                      ...inv.billingAddress.map(
                                                        (line) => Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 2,
                                                              ),
                                                          child: Text(
                                                            line,
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color: AppTheme
                                                                  .textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'Ship To',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      ...inv.shippingAddress.map(
                                                        (line) => Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 2,
                                                              ),
                                                          child: Text(
                                                            line,
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color: AppTheme
                                                                  .textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(
                                            height: 1,
                                            color: Color(0xFFD1D5DB),
                                          ),
                                          const SizedBox(height: 60),

                                          // Items table wrapper (less wide)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                // Row 3: Items table header
                                                Container(
                                                  color: const Color(
                                                    0xFFF9FAFB,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 5,
                                                      ),
                                                  child: IntrinsicHeight(
                                                    child: Row(
                                                      children: [
                                                        const SizedBox(
                                                          width: 30,
                                                          child: Text(
                                                            '#',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 1,
                                                          color: const Color(
                                                            0xFFD1D5DB,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const Expanded(
                                                          child: Text(
                                                            'Item & Description',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 1,
                                                          color: const Color(
                                                            0xFFD1D5DB,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const SizedBox(
                                                          width: 80,
                                                          child: Text(
                                                            'HSN/SAC',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 1,
                                                          color: const Color(
                                                            0xFFD1D5DB,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            'Qty',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 1,
                                                          color: const Color(
                                                            0xFFD1D5DB,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const SizedBox(
                                                          width: 80,
                                                          child: Text(
                                                            'Rate',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        ),
                                                        Container(
                                                          width: 1,
                                                          color: const Color(
                                                            0xFFD1D5DB,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        const SizedBox(
                                                          width: 90,
                                                          child: Text(
                                                            'Amount',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const Divider(
                                                  height: 1,
                                                  color: AppTheme.borderColor,
                                                ),

                                                // Items rows
                                                ...inv.items.map(
                                                  (item) => Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 6,
                                                        ),
                                                    decoration:
                                                        const BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(
                                                              color: Color(
                                                                0xFFD1D5DB,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    child: IntrinsicHeight(
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                            width: 30,
                                                            child: Text(
                                                              '${item.index}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 1,
                                                            color: const Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              item.description,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 1,
                                                            color: const Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          const SizedBox(
                                                            width: 80,
                                                            child: Text(
                                                              '342441',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 1,
                                                            color: const Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          const SizedBox(
                                                            width: 50,
                                                            child: Text(
                                                              '1.00',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 1,
                                                            color: const Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          SizedBox(
                                                            width: 80,
                                                            child: Text(
                                                              item.amount
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 1,
                                                            color: const Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          SizedBox(
                                                            width: 90,
                                                            child: Text(
                                                              item.amount
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
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

                                          // Row 5: Footer block
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          right: BorderSide(
                                                            color: Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  child: const Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Total In Words',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        'Indian Rupee Two Hundred Thirty-Eight Only',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 16),
                                                      Text(
                                                        'Notes',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppTheme
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        'Thanks for your business.',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            12,
                                                          ),
                                                      child: Column(
                                                        children: [
                                                          _buildTotalRow(
                                                            'Sub Total',
                                                            inv.amount
                                                                .toStringAsFixed(
                                                                  2,
                                                                ),
                                                          ),
                                                          _buildTotalRow(
                                                            'Total',
                                                            '₹${inv.amount.toStringAsFixed(2)}',
                                                            isBold: true,
                                                          ),
                                                          _buildTotalRow(
                                                            'Balance Due',
                                                            '₹${inv.amount.toStringAsFixed(2)}',
                                                            isBold: true,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Divider(
                                                      height: 1,
                                                      color: Color(0xFFD1D5DB),
                                                    ),
                                                    Container(
                                                      height: 90,
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 12,
                                                          ),
                                                      child: const Text(
                                                        'Authorized Signature',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textSecondary,
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
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: ZerpaiDocumentCornerRibbon(
                                  label: 'Active',
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 850,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            color: const Color(0xFFE2E8F0),
                            child: Text(
                              'Salesperson: ${inv.salesperson}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'PDF Template : ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                "'$_selectedTemplate'",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _showTemplatePanel = true),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '|',
                                style: TextStyle(color: AppTheme.borderColor),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '( View sample PDF )',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
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
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildInfoRow(String label, String value, {bool isValBold = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Text(
                ':',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isValBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesTab() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ListView(
        children: [
          _buildActivityTimelineItem(
            date: '13-06-2026',
            time: '09:21 AM',
            title: 'Invoice created - INV-000088. Saved as draft',
            subtitle: 'by zabnixprivatelimited',
            linkText: 'View the invoice',
            onLinkTap: () {
              // Click action to view the invoice or similar
            },
            isFirst: true,
          ),
          _buildActivityTimelineItem(
            date: '13-06-2026',
            time: '09:21 AM',
            title: 'Recurring Invoice created for ₹238.00',
            subtitle: 'by zabnixprivatelimited',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineItem({
    required String date,
    required String time,
    required String title,
    required String subtitle,
    String? linkText,
    VoidCallback? onLinkTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date & Time Column
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 12),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Timeline indicator (dot + line)
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 1.5,
                  height: 16,
                  color: const Color(0xFF90CAF9),
                )
              else
                const SizedBox(height: 16),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 1.5,
                  color: isLast ? Colors.transparent : const Color(0xFF90CAF9),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (linkText != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onLinkTap,
                          child: Text(
                            linkText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

class _OverviewBulkUpdateDialog extends StatefulWidget {
  final List<RecurringInvoiceUI> selectedInvoices;

  const _OverviewBulkUpdateDialog({required this.selectedInvoices});

  @override
  State<_OverviewBulkUpdateDialog> createState() =>
      _OverviewBulkUpdateDialogState();
}

class _OverviewBulkUpdateDialogState extends State<_OverviewBulkUpdateDialog> {
  String? _selectedField;
  final TextEditingController _valueController = TextEditingController();

  static const List<String> _fields = [
    'Reference#',
    'Billing Address',
    'Shipping Address',
    'Billing and Shipping Address',
    'PDF Template',
    'Payment Terms',
    'Payment Gateways',
    'Sales person',
    'Customer Notes',
    'Terms & Conditions',
    'Preferences',
  ];

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 8, 40, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: 636,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bulk Update Recurring Invoices',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a field from the dropdown and update with new information.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: FormDropdown<String>(
                            value: _selectedField,
                            items: _fields,
                            onChanged: (value) {
                              setState(() {
                                _selectedField = value;
                              });
                            },
                            hint: 'Select a field',
                            showSearch: true,
                            menuWidth: 300,
                            itemHeight: 38,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _valueController,
                          height: 36,
                          hintText: '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Note: All the selected recurring invoices will be updated with the new information and you cannot undo this action.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'field': _selectedField ?? '',
                        'value': _valueController.text.trim(),
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22A95E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
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
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F2937),
                      backgroundColor: const Color(0xFFF3F4F6),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
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
            ),
          ],
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
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
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

class _PaymentNotificationTemplateDialog extends StatefulWidget {
  final String title;
  final String templateName;
  final String paymentMethod;
  final String subject;
  final String body;

  const _PaymentNotificationTemplateDialog({
    required this.title,
    required this.templateName,
    required this.paymentMethod,
    required this.subject,
    required this.body,
  });

  @override
  State<_PaymentNotificationTemplateDialog> createState() =>
      _PaymentNotificationTemplateDialogState();
}

class _PaymentNotificationTemplateDialogState
    extends State<_PaymentNotificationTemplateDialog> {
  late final TextEditingController _templateNameController;
  late final TextEditingController _subjectController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _linkTextController;
  late final TextEditingController _linkUrlController;
  late final TextEditingController _placeholderSearchController;
  late final _PaymentTemplateBodyController _bodyController;
  late final FocusNode _bodyFocusNode;
  final MenuController _moreToolsMenuController = MenuController();
  final MenuController _placeholderMenuController = MenuController();
  TextSelection? _lastBodySelection;
  String? _ccValue;
  String _selectedEditorTextStyle = 'Normal Text';
  int _selectedFontSize = 16;
  String _selectedFontFamily = 'Arial';
  TextAlign _selectedTextAlignment = TextAlign.left;
  _EditorListFormat _selectedListFormat = _EditorListFormat.bulleted;
  _MoreToolsPanel _activeMoreToolsPanel = _MoreToolsPanel.none;
  _ImageInsertTab _selectedImageInsertTab = _ImageInsertTab.upload;
  String? _selectedImageFileName;
  String _placeholderSearchQuery = '';
  static const List<String> _ccOptions = [
    'zabnixprivatelimited<zabnixprivatelimited@gmail.com>',
    'ALTHAF-M<malayanakathalthaf@gmail.com>',
    'Vahid<abdulvahidfathah@gmail.com>',
  ];
  static const List<String> _editorTextStyleOptions = [
    'Normal Text',
    'Heading 1',
    'Heading 2',
    'Heading 3',
    'Heading 4',
    'Heading 5',
    'Heading 6',
  ];
  static const List<int> _fontSizeOptions = [10, 13, 16, 18, 24, 32, 48];
  static const List<String> _fontFamilyOptions = [
    'Calibri',
    'Courier New',
    'Georgia',
    'Serif',
    'Roboto',
    'Times New Roman',
    'Trebuchet MS',
    'Arial',
    'Tahoma',
    'Verdana',
    'Comic Sans MS',
  ];
  static const List<_PlaceholderMenuSection> _placeholderSections = [
    _PlaceholderMenuSection(
      title: 'PAYMENT',
      items: [
        _PlaceholderMenuItem(
          label: 'Add/Update Payment Method',
          token: '%OnlinePayment%',
        ),
      ],
    ),
    _PlaceholderMenuSection(
      title: 'RETRYNOTIFICATION',
      items: [
        _PlaceholderMenuItem(label: 'InvoiceDate', token: '%InvoiceDate%'),
        _PlaceholderMenuItem(label: 'InvoiceNumber', token: '%InvoiceNumber%'),
        _PlaceholderMenuItem(label: 'OverdueDays', token: '%OverdueDays%'),
        _PlaceholderMenuItem(label: 'Total', token: '%Total%'),
        _PlaceholderMenuItem(label: 'User Name', token: '%UserName%'),
        _PlaceholderMenuItem(label: 'Company Name', token: '%CompanyName%'),
        _PlaceholderMenuItem(
          label: 'Next Renewal Date',
          token: '%NextRenewalDate%',
        ),
        _PlaceholderMenuItem(label: 'Online payment', token: '%OnlinePayment%'),
        _PlaceholderMenuItem(
          label: 'Number of days to retry',
          token: '%RetryDays%',
        ),
        _PlaceholderMenuItem(
          label: 'Payment failure message',
          token: '%PaymentFailureMessage%',
        ),
      ],
    ),
    _PlaceholderMenuSection(
      title: 'CUSTOMER',
      items: [
        _PlaceholderMenuItem(label: 'Company Name', token: '%CompanyName%'),
        _PlaceholderMenuItem(label: 'Salutation', token: '%Salutation%'),
        _PlaceholderMenuItem(
          label: 'Customer Balance',
          token: '%CustomerBalance%',
        ),
        _PlaceholderMenuItem(label: 'Website', token: '%Website%'),
        _PlaceholderMenuItem(
          label: 'Outstanding Balance',
          token: '%OutstandingBalance%',
        ),
        _PlaceholderMenuItem(label: 'Customer Name', token: '%CustomerName%'),
        _PlaceholderMenuItem(label: 'FirstName', token: '%FirstName%'),
        _PlaceholderMenuItem(label: 'LastName', token: '%LastName%'),
        _PlaceholderMenuItem(label: 'Department', token: '%Department%'),
        _PlaceholderMenuItem(label: 'Designation', token: '%Designation%'),
        _PlaceholderMenuItem(label: 'Customer Email', token: '%CustomerEmail%'),
        _PlaceholderMenuItem(label: 'Created By', token: '%CreatedBy%'),
        _PlaceholderMenuItem(label: 'Credit Limit', token: '%CreditLimit%'),
        _PlaceholderMenuItem(
          label: 'Customer Number',
          token: '%CustomerNumber%',
        ),
        _PlaceholderMenuItem(label: 'Customer GSTIN', token: '%CustomerGSTIN%'),
      ],
    ),
    _PlaceholderMenuSection(
      title: 'ORGANIZATION',
      items: [
        _PlaceholderMenuItem(label: 'Name', token: '%OrganizationName%'),
        _PlaceholderMenuItem(label: 'User', token: '%OrganizationUser%'),
        _PlaceholderMenuItem(label: 'User Role', token: '%UserRole%'),
        _PlaceholderMenuItem(label: 'Email', token: '%OrganizationEmail%'),
        _PlaceholderMenuItem(label: 'Phone#', token: '%Phone%'),
        _PlaceholderMenuItem(label: 'Fax#', token: '%Fax%'),
        _PlaceholderMenuItem(label: 'Website', token: '%OrganizationWebsite%'),
        _PlaceholderMenuItem(label: 'Label 1', token: '%Label1%'),
        _PlaceholderMenuItem(label: 'Value 1', token: '%Value1%'),
        _PlaceholderMenuItem(label: 'Company GSTIN', token: '%CompanyGSTIN%'),
        _PlaceholderMenuItem(label: 'Portal URL', token: '%PortalURL%'),
      ],
    ),
  ];
  static const List<Color> _textColorOptions = [
    Color(0xFF111827),
    Color(0xFFDC2626),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFF59E0B),
  ];
  static const List<Color> _highlightColorOptions = [
    Color(0xFFFFF59D),
    Color(0xFFFED7AA),
    Color(0xFFBFDBFE),
    Color(0xFFC7F9CC),
    Color(0xFFE9D5FF),
    Color(0xFFFBCFE8),
  ];

  @override
  void initState() {
    super.initState();
    _templateNameController = TextEditingController(text: widget.templateName);
    _subjectController = TextEditingController(text: widget.subject);
    _imageUrlController = TextEditingController();
    _linkTextController = TextEditingController();
    _linkUrlController = TextEditingController();
    _placeholderSearchController = TextEditingController();
    _bodyController = _PaymentTemplateBodyController(text: widget.body);
    _bodyFocusNode = FocusNode();
    _bodyController.addListener(_rememberBodySelection);
  }

  @override
  void dispose() {
    _bodyController.removeListener(_rememberBodySelection);
    _templateNameController.dispose();
    _subjectController.dispose();
    _imageUrlController.dispose();
    _linkTextController.dispose();
    _linkUrlController.dispose();
    _placeholderSearchController.dispose();
    _bodyFocusNode.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 1080,
          maxWidth: 1140,
          minHeight: screenHeight - 32,
          maxHeight: screenHeight - 32,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                          size: 18,
                          color: Colors.red.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDialogFieldRow(
                          label: 'Template Name*',
                          labelColor: AppTheme.errorRed,
                          child: _buildDialogInput(
                            controller: _templateNameController,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDialogFieldRow(
                          label: 'Cc',
                          child: SizedBox(
                            height: 36,
                            child: FormDropdown<String>(
                              value: _ccValue,
                              items: _ccOptions,
                              hint: '',
                              onChanged: (value) {
                                setState(() => _ccValue = value);
                              },
                              showSearch: true,
                              menuWidth: 950,
                              itemHeight: 38,
                              itemBuilder: (item, isSelected, isHovered) =>
                                  _buildDialogDropdownItem(
                                    item: item,
                                    isSelected: isSelected,
                                    isHovered: isHovered,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildLanguageTabs(),
                        const SizedBox(height: 20),
                        _buildDialogFieldRow(
                          label: 'Subject*',
                          labelColor: AppTheme.errorRed,
                          child: _buildDialogInput(
                            controller: _subjectController,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEditorCard(),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22B378),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.textPrimary,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    side: const BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
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

  Widget _buildDialogFieldRow({
    required String label,
    required Widget child,
    Color labelColor = AppTheme.textPrimary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildDialogInput({required TextEditingController controller}) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.infoBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'English (default)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(width: 150, height: 2, color: AppTheme.primaryBlue),
        const Divider(height: 1, color: AppTheme.borderColor),
      ],
    );
  }

  Widget _buildDialogDropdownItem({
    required String item,
    required bool isSelected,
    required bool isHovered,
  }) {
    final Color backgroundColor = isHovered
        ? AppTheme.infoBlue
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
    final Color textColor = isHovered ? Colors.white : AppTheme.textPrimary;
    final Color tickColor = isHovered ? Colors.white : AppTheme.textPrimary;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
          if (isSelected) Icon(Icons.check, size: 16, color: tickColor),
        ],
      ),
    );
  }

  Widget _buildEditorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFF7F8FB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildEditorTextStyleDropdown(),
                _toolbarDivider(),
                _buildToolbarActionButton(
                  onTap: _toggleBold,
                  child: const Text(
                    'B',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
                _buildToolbarActionButton(
                  onTap: _toggleItalic,
                  child: const Text(
                    'I',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
                _buildToolbarActionButton(
                  onTap: _toggleUnderline,
                  child: const Text(
                    'U',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
                _buildToolbarActionButton(
                  onTap: _toggleStrikeThrough,
                  child: const Text(
                    'S',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
                _toolbarDivider(),
                _buildColorToolbarDropdown(
                  labelBuilder: () => const Text(
                    'A',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  colors: _textColorOptions,
                  onColorSelected: _applyTextColor,
                ),
                _buildColorToolbarDropdown(
                  labelBuilder: () => Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  colors: _highlightColorOptions,
                  onColorSelected: _applyHighlightColor,
                ),
                _toolbarDivider(),
                _buildFontSizeDropdown(),
                _toolbarDivider(),
                _buildFontFamilyDropdown(),
                _toolbarDivider(),
                _buildIndentDropdown(),
                _buildTextAlignmentDropdown(),
                _buildListFormatDropdown(),
                _buildMoreToolsDropdown(),
                const SizedBox(width: 24),
                _buildInsertPlaceholderDropdown(),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4E5E7)),
          TextField(
            controller: _bodyController,
            focusNode: _bodyFocusNode,
            maxLines: 16,
            minLines: 16,
            textAlign: _selectedTextAlignment,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: Color(0xFF000000),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.fromLTRB(16, 12, 16, 12),
              hintText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarActionButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: child,
      ),
    );
  }

  Widget _buildEditorTextStyleDropdown() {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
        elevation: WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;
        return InkWell(
          onTap: () => isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                   _selectedEditorTextStyle,
                   style: const TextStyle(
                     fontSize: 14,
                     fontWeight: FontWeight.w600,
                     color: Color(0xFF000000),
                   ),
                 ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF4B5563),
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: _editorTextStyleOptions.map((option) {
        final bool isSelected = option == _selectedEditorTextStyle;
        return MenuItemButton(
          onPressed: () {
            setState(() => _selectedEditorTextStyle = option);
            _applyEditorTextStyle(option);
          },
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(128, 40)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return AppTheme.infoBlue;
              }
              if (isSelected) {
                return const Color(0xFFF3F4F6);
              }
              return Colors.white;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.white;
              }
              return AppTheme.textPrimary;
            }),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          trailingIcon: isSelected
              ? const Icon(Icons.check, size: 16)
              : const SizedBox(width: 16),
          child: Text(
            option,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontSizeDropdown() {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
        elevation: WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;
        return InkWell(
          onTap: () => isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                   '${_selectedFontSize}px',
                   style: const TextStyle(
                     fontSize: 14,
                     fontWeight: FontWeight.w600,
                     color: Color(0xFF000000),
                   ),
                 ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF4B5563),
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: _fontSizeOptions.map((fontSize) {
        final bool isSelected = fontSize == _selectedFontSize;
        return MenuItemButton(
          onPressed: () {
            setState(() => _selectedFontSize = fontSize);
            _applyFontSize(fontSize);
          },
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(74, 38)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return AppTheme.infoBlue;
              }
              if (isSelected) {
                return const Color(0xFFE5E7EB);
              }
              return Colors.white;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.white;
              }
              return AppTheme.textPrimary;
            }),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          child: Text(
            '${fontSize}px',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontFamilyDropdown() {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
        elevation: WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;
        return InkWell(
          onTap: () => isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                   _selectedFontFamily,
                   style: const TextStyle(
                     fontSize: 14,
                     fontWeight: FontWeight.w600,
                     color: Color(0xFF000000),
                   ),
                 ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF4B5563),
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: _fontFamilyOptions.map((fontFamily) {
        final bool isSelected = fontFamily == _selectedFontFamily;
        return MenuItemButton(
          onPressed: () {
            setState(() => _selectedFontFamily = fontFamily);
            _applyFontFamily(fontFamily);
          },
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(156, 38)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return AppTheme.infoBlue;
              }
              if (isSelected) {
                return const Color(0xFFE5E7EB);
              }
              return Colors.white;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.white;
              }
              return AppTheme.textPrimary;
            }),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          child: Text(
            fontFamily,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextAlignmentDropdown() {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
        elevation: WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;
        return InkWell(
          onTap: () => isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _textAlignmentIcon(_selectedTextAlignment),
                  size: 18,
                  color: const Color(0xFF4B5563),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: Color(0xFF4B5563),
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: [
        _buildTextAlignmentMenuItem(
          alignment: TextAlign.left,
          icon: LucideIcons.alignLeft,
        ),
        _buildTextAlignmentMenuItem(
          alignment: TextAlign.right,
          icon: LucideIcons.alignRight,
        ),
        _buildTextAlignmentMenuItem(
          alignment: TextAlign.center,
          icon: LucideIcons.alignCenter,
        ),
        _buildTextAlignmentMenuItem(
          alignment: TextAlign.justify,
          icon: LucideIcons.alignJustify,
        ),
      ],
    );
  }

  Widget _buildIndentDropdown() {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
        elevation: WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;
        return InkWell(
          onTap: () => isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIndentGlyph(
                  increase: false,
                  color: const Color(0xFF4B5563),
                ),
                const SizedBox(width: 1),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 13,
                  color: Color(0xFF4B5563),
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: [
        _buildIndentMenuItem(
          onPressed: _outdentSelection,
          increase: false,
        ),
        _buildIndentMenuItem(
          onPressed: _indentSelection,
          increase: true,
        ),
      ],
    );
  }

  Widget _buildIndentMenuItem({
    required VoidCallback onPressed,
    required bool increase,
  }) {
    return MenuItemButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(36, 36)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.infoBlue;
          }
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.white;
          }
          return AppTheme.textPrimary;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      child: Builder(
        builder: (context) {
          final iconTheme = IconTheme.of(context);
          return _buildIndentGlyph(
            increase: increase,
            color: iconTheme.color ?? AppTheme.textPrimary,
          );
        },
      ),
    );
  }

  Widget _buildIndentGlyph({
    required bool increase,
    required Color color,
  }) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: increase ? 7 : 2,
            top: 3,
            child: Container(width: 7, height: 1.4, color: color),
          ),
          Positioned(
            left: increase ? 7 : 2,
            top: 7,
            child: Container(width: 7, height: 1.4, color: color),
          ),
          Positioned(
            left: increase ? 7 : 2,
            top: 11,
            child: Container(width: 7, height: 1.4, color: color),
          ),
          Positioned(
            left: increase ? 1 : 8,
            top: 4,
            child: Icon(
              increase
                  ? Icons.keyboard_arrow_right_rounded
                  : Icons.keyboard_arrow_left_rounded,
              size: 9,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListFormatDropdown() {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
        elevation: WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;
        return InkWell(
          onTap: () => isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selectedListFormat == _EditorListFormat.numbered
                      ? LucideIcons.listOrdered
                      : LucideIcons.list,
                  size: 18,
                  color: const Color(0xFF4B5563),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: Color(0xFF4B5563),
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: [
        _buildListFormatMenuItem(
          format: _EditorListFormat.bulleted,
          icon: LucideIcons.list,
        ),
        _buildListFormatMenuItem(
          format: _EditorListFormat.numbered,
          icon: LucideIcons.listOrdered,
        ),
      ],
    );
  }

  Widget _buildListFormatMenuItem({
    required _EditorListFormat format,
    required IconData icon,
  }) {
    final bool isSelected = format == _selectedListFormat;
    return MenuItemButton(
      onPressed: () => _applyListFormat(format),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.infoBlue;
          }
          if (isSelected) {
            return const Color(0xFFE5E7EB);
          }
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.white;
          }
          return AppTheme.textPrimary;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      child: Icon(icon, size: 18),
    );
  }

  Widget _buildTextAlignmentMenuItem({
    required TextAlign alignment,
    required IconData icon,
  }) {
    final bool isSelected = alignment == _selectedTextAlignment;
    return MenuItemButton(
      onPressed: () => _applyTextAlignment(alignment),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.infoBlue;
          }
          if (isSelected) {
            return const Color(0xFFE5E7EB);
          }
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.white;
          }
          return AppTheme.textPrimary;
        }),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      child: Icon(icon, size: 18),
    );
  }

  IconData _textAlignmentIcon(TextAlign alignment) {
    switch (alignment) {
      case TextAlign.right:
        return LucideIcons.alignRight;
      case TextAlign.center:
        return LucideIcons.alignCenter;
      case TextAlign.justify:
        return LucideIcons.alignJustify;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.end:
        return LucideIcons.alignLeft;
    }
  }

  Widget _buildInsertPlaceholderDropdown() {
    return MenuAnchor(
      controller: _placeholderMenuController,
      alignmentOffset: const Offset(-290, 8),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: WidgetStatePropertyAll(0),
      ),
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;
        return InkWell(
          onTap: () {
            if (isOpen) {
              _resetPlaceholderSearch();
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Insert Placeholder',
                  style: TextStyle(
                     fontSize: 14,
                     fontWeight: FontWeight.w600,
                     color: Color(0xFF000000),
                   ),
                 ),
                SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF4B5563),
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: [
        Material(
          color: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          shadowColor: const Color(0x14000000),
          child: Container(
            width: 680,
            constraints: const BoxConstraints(maxHeight: 370),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _placeholderSearchController,
                  onChanged: (value) {
                    setState(() {
                      _placeholderSearchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF98A2B3),
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 16,
                      color: Color(0xFF667085),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD6DBE7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD6DBE7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.infoBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildPlaceholderSectionWidgets(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPlaceholderSectionWidgets() {
    final sections = _filteredPlaceholderSections();
    if (sections.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No placeholders found',
            style: TextStyle(fontSize: 13, color: Color(0xFF98A2B3)),
          ),
        ),
      ];
    }

    return [
      for (final section in sections) ...[
        Text(
          section.title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Color(0xFF8A8EA3),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 10,
          children: [
            for (final item in section.items)
              _buildPlaceholderMenuTile(item),
          ],
        ),
        const SizedBox(height: 18),
      ],
    ];
  }

  List<_PlaceholderMenuSection> _filteredPlaceholderSections() {
    if (_placeholderSearchQuery.isEmpty) {
      return _placeholderSections;
    }

    return _placeholderSections
        .map((section) {
          final filteredItems = section.items.where((item) {
            final label = item.label.toLowerCase();
            final token = item.token.toLowerCase();
            return label.contains(_placeholderSearchQuery) ||
                token.contains(_placeholderSearchQuery);
          }).toList();
          return _PlaceholderMenuSection(
            title: section.title,
            items: filteredItems,
          );
        })
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  Widget _buildPlaceholderMenuTile(_PlaceholderMenuItem item) {
    return SizedBox(
      width: 188,
      child: TextButton(
        onPressed: () => _insertPlaceholder(item.token),
        style: ButtonStyle(
          alignment: Alignment.centerLeft,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Colors.white;
            }
            return AppTheme.textPrimary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppTheme.infoBlue;
            }
            return Colors.white;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        child: Text(item.label),
      ),
    );
  }

  void _resetPlaceholderSearch() {
    _placeholderSearchController.clear();
    if (_placeholderSearchQuery.isNotEmpty) {
      setState(() {
        _placeholderSearchQuery = '';
      });
    }
  }

  Widget _buildColorToolbarDropdown({
    required Widget Function() labelBuilder,
    required List<Color> colors,
    required ValueChanged<Color> onColorSelected,
  }) {
    final controller = MenuController();
    return MenuAnchor(
      controller: controller,
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: labelBuilder(),
          ),
        );
      },
      menuChildren: [
        _EditorColorPickerMenu(
          swatches: colors,
          onApply: (color) {
            onColorSelected(color);
            controller.close();
          },
          onCancel: controller.close,
        ),
      ],
    );
  }

  void _insertPlaceholder(String placeholder) {
    _replaceSelectionWithText(placeholder);
    _resetPlaceholderSearch();
    _placeholderMenuController.close();
  }

  void _rememberBodySelection() {
    final selection = _bodyController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      _lastBodySelection = selection;
    }
  }

  TextSelection? _resolvedBodySelection() {
    final selection = _bodyController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      return selection;
    }
    final lastSelection = _lastBodySelection;
    if (lastSelection != null &&
        lastSelection.isValid &&
        !lastSelection.isCollapsed) {
      return lastSelection;
    }
    return null;
  }

  TextSelection? _restoreResolvedBodySelection() {
    final selection = _resolvedBodySelection();
    if (selection == null) {
      return null;
    }
    _bodyController.selection = selection;
    _bodyFocusNode.requestFocus();
    return selection;
  }

  void _applyTextColor(Color color) {
    final selection = _restoreResolvedBodySelection();
    if (selection == null) {
      return;
    }
    _bodyController.addTextColorRange(selection, color);
  }

  void _applyHighlightColor(Color color) {
    final selection = _restoreResolvedBodySelection();
    if (selection == null) {
      return;
    }
    _bodyController.addHighlightColorRange(selection, color);
  }

  void _insertAtCursor(String textToInsert) {
    _replaceSelectionWithText(textToInsert);
  }

  void _toggleBold() => _transformSelection(_toBoldUnicode);

  void _toggleItalic() => _transformSelection(_toItalicUnicode);

  void _toggleUnderline() => _transformSelection(_toUnderlinedUnicode);

  void _toggleStrikeThrough() {
    final selection = _restoreResolvedBodySelection();
    if (selection == null) {
      return;
    }
    _bodyController.addStrikeRange(selection);
  }

  void _applyListFormat(_EditorListFormat format) {
    setState(() {
      _selectedListFormat = format;
    });
    final text = _bodyController.text;
    final selection = _restoreResolvedBodySelection();
    if (selection == null) {
      _insertAtCursor(
        format == _EditorListFormat.numbered ? '1. ' : '• ',
      );
      return;
    }
    final int safeStart = selection.start.clamp(0, text.length);
    final int safeEnd = selection.end.clamp(0, text.length);
    final selectedText = text.substring(safeStart, safeEnd);
    final replacement = _formatSelectedTextAsList(selectedText, format);
    _replaceSelectionWithText(
      replacement,
      cursorOffset: safeStart + replacement.length,
    );
  }

  Widget _buildMoreToolsDropdown() {
    return MenuAnchor(
      controller: _moreToolsMenuController,
      alignmentOffset: const Offset(-50, 8),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: WidgetStatePropertyAll(0),
      ),
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;
        return InkWell(
          onTap: () {
            if (isOpen) {
              setState(() {
                _activeMoreToolsPanel = _MoreToolsPanel.none;
              });
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Icon(
              LucideIcons.moreHorizontal,
              size: 18,
              color: Color(0xFF4B5563),
            ),
          ),
        );
      },
      menuChildren: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              shadowColor: const Color(0x1A000000),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMoreToolsMenuItem(
                      icon: LucideIcons.image,
                      isSelected:
                          _activeMoreToolsPanel == _MoreToolsPanel.image,
                      onPressed: _toggleImageToolsPanel,
                      closeMenuOnTap: false,
                    ),
                    const SizedBox(width: 6),
                    _buildMoreToolsMenuItem(
                      icon: LucideIcons.link,
                      isSelected:
                          _activeMoreToolsPanel == _MoreToolsPanel.link,
                      onPressed: _toggleLinkToolsPanel,
                      closeMenuOnTap: false,
                    ),
                    const SizedBox(width: 6),
                    _buildMoreToolsMenuItem(
                      icon: LucideIcons.squareCode,
                      onPressed: _insertCodeTag,
                    ),
                  ],
                  ),
                ),
              ),
            if (_activeMoreToolsPanel == _MoreToolsPanel.image) ...[
              const SizedBox(height: 10),
              _buildImageInsertPanel(),
            ],
            if (_activeMoreToolsPanel == _MoreToolsPanel.link) ...[
              const SizedBox(height: 10),
              _buildLinkInsertPanel(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMoreToolsMenuItem({
    required IconData icon,
    required VoidCallback onPressed,
    bool closeMenuOnTap = true,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: () {
        onPressed();
        if (closeMenuOnTap) {
          setState(() {
            _activeMoreToolsPanel = _MoreToolsPanel.none;
          });
          _moreToolsMenuController.close();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5E7EB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFD1D5DB) : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 17,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildImageInsertPanel() {
    final isUploadTab = _selectedImageInsertTab == _ImageInsertTab.upload;
    return Container(
      width: 426,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildImageInsertTabButton(
                  label: 'Upload From Desktop',
                  icon: LucideIcons.upload,
                  isSelected: isUploadTab,
                  onTap: () {
                    setState(() {
                      _selectedImageInsertTab = _ImageInsertTab.upload;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildImageInsertTabButton(
                  label: 'Add Image URL',
                  icon: LucideIcons.link,
                  isSelected: !isUploadTab,
                  onTap: () {
                    setState(() {
                      _selectedImageInsertTab = _ImageInsertTab.url;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isUploadTab) _buildImageUploadDropzone() else _buildImageUrlPanel(),
        ],
      ),
    );
  }

  Widget _buildImageInsertTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFE9EDF7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD6DBE7)
                : const Color(0xFFE9EDF7),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF667085)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667085),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadDropzone() {
    return InkWell(
      onTap: _pickImageFromDesktop,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFD7DCEA),
            width: 1.2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: DottedBorder(
          color: const Color(0xFFD7DCEA),
          strokeWidth: 1.2,
          dashPattern: const [4, 3],
          borderType: BorderType.RRect,
          radius: const Radius.circular(8),
          padding: const EdgeInsets.all(1),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4B5563),
                    ),
                    children: const [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            LucideIcons.arrowUpToLine,
                            size: 15,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      TextSpan(text: 'Drag and drop or '),
                      TextSpan(
                        text: 'Upload',
                        style: TextStyle(color: Color(0xFF2563EB)),
                      ),
                      TextSpan(text: ' image'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _selectedImageFileName ?? 'Maximum size: 1 MB',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUrlPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _imageUrlController,
          decoration: InputDecoration(
            hintText: 'Paste image URL',
            hintStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF98A2B3),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD6DBE7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD6DBE7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.infoBlue),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: _insertImageFromUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkInsertPanel() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Link Text',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _linkTextController,
            decoration: _buildMoreToolsInputDecoration(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Link URL',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _linkUrlController,
            decoration: _buildMoreToolsInputDecoration(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: _insertLinkFromPanel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add Link',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  onPressed: _closeMoreToolsPanel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: Color(0xFFD6DBE7)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _buildMoreToolsInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD6DBE7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD6DBE7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.infoBlue),
      ),
    );
  }

  void _indentSelection() {
    final text = _bodyController.text;
    final selection = _restoreResolvedBodySelection();
    if (selection == null) {
      _insertAtCursor('  ');
      return;
    }
    final int safeStart = selection.start.clamp(0, text.length);
    final int safeEnd = selection.end.clamp(0, text.length);
    final selectedText = text.substring(safeStart, safeEnd);
    final replacement = selectedText
        .split('\n')
        .map((line) => line.isEmpty ? line : '  $line')
        .join('\n');
    _replaceSelectionWithText(
      replacement,
      cursorOffset: safeStart + replacement.length,
    );
  }

  void _outdentSelection() {
    final text = _bodyController.text;
    final selection = _restoreResolvedBodySelection();
    if (selection == null) {
      return;
    }
    final int safeStart = selection.start.clamp(0, text.length);
    final int safeEnd = selection.end.clamp(0, text.length);
    final selectedText = text.substring(safeStart, safeEnd);
    final replacement = selectedText
        .split('\n')
        .map((line) {
          if (line.startsWith('  ')) {
            return line.substring(2);
          }
          if (line.startsWith(' ')) {
            return line.substring(1);
          }
          return line;
        })
        .join('\n');
    _replaceSelectionWithText(
      replacement,
      cursorOffset: safeStart + replacement.length,
    );
  }

  void _applyTextAlignment(TextAlign alignment) {
    setState(() {
      _selectedTextAlignment = alignment;
    });
    _bodyFocusNode.requestFocus();
  }

  void _toggleImageToolsPanel() {
    setState(() {
      _activeMoreToolsPanel =
          _activeMoreToolsPanel == _MoreToolsPanel.image
          ? _MoreToolsPanel.none
          : _MoreToolsPanel.image;
    });
  }

  void _toggleLinkToolsPanel() {
    setState(() {
      _activeMoreToolsPanel =
          _activeMoreToolsPanel == _MoreToolsPanel.link
          ? _MoreToolsPanel.none
          : _MoreToolsPanel.link;
    });
  }

  void _closeMoreToolsPanel() {
    setState(() {
      _activeMoreToolsPanel = _MoreToolsPanel.none;
    });
  }

  Future<void> _pickImageFromDesktop() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    final fileName = file.name.trim();
    if (fileName.isEmpty) {
      return;
    }
    setState(() {
      _selectedImageFileName = fileName;
      _activeMoreToolsPanel = _MoreToolsPanel.none;
    });
    _insertAtCursor('<img src="$fileName" alt="$fileName" />');
    _moreToolsMenuController.close();
  }

  void _insertImageFromUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return;
    }
    final fileName = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'image';
    setState(() {
      _activeMoreToolsPanel = _MoreToolsPanel.none;
    });
    _insertAtCursor('<img src="$url" alt="$fileName" />');
    _imageUrlController.clear();
    _moreToolsMenuController.close();
  }

  void _insertLinkFromPanel() {
    final linkText = _linkTextController.text.trim();
    final linkUrl = _linkUrlController.text.trim();
    if (linkText.isEmpty || linkUrl.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(linkUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return;
    }
    _insertAtCursor('<a href="$linkUrl">$linkText</a>');
    _linkTextController.clear();
    _linkUrlController.clear();
    _closeMoreToolsPanel();
    _moreToolsMenuController.close();
  }

  void _insertCodeTag() {
    final normalized = _normalizeEditorBodyForDisplay(_bodyController.text);
    _bodyController.clearAllFormatting();
    _bodyController.value = TextEditingValue(
      text: normalized.text,
      selection: TextSelection.collapsed(offset: normalized.text.length),
    );
    for (final range in normalized.linkRanges) {
      _bodyController.addTextColorTextRange(range, const Color(0xFF2563EB));
    }
    _closeMoreToolsPanel();
    _moreToolsMenuController.close();
  }

  _NormalizedEditorBody _normalizeEditorBodyForDisplay(String input) {
    var output = input;
    output = output.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );
    output = output.replaceAll(
      RegExp(r'</div>\s*<div[^>]*>', caseSensitive: false),
      '\n',
    );
    output = output.replaceAll(
      RegExp(r'<div[^>]*>', caseSensitive: false),
      '',
    );
    output = output.replaceAll(
      RegExp(r'</div>', caseSensitive: false),
      '\n',
    );
    final linkRanges = <TextRange>[];
    final anchorPattern = RegExp(
      r'<a[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );
    final buffer = StringBuffer();
    var lastMatchEnd = 0;
    for (final match in anchorPattern.allMatches(output)) {
      final before = output.substring(lastMatchEnd, match.start);
      buffer.write(_stripEditorHtml(before));
      final linkText = _stripEditorHtml(match.group(1) ?? '');
      final start = buffer.length;
      buffer.write(linkText);
      final end = buffer.length;
      if (end > start) {
        linkRanges.add(TextRange(start: start, end: end));
      }
      lastMatchEnd = match.end;
    }
    buffer.write(_stripEditorHtml(output.substring(lastMatchEnd)));
    final plainText = buffer
        .toString()
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return _formatNormalizedEmailBody(plainText, linkRanges);
  }

  String _stripEditorHtml(String input) {
    var output = input;
    output = output.replaceAll(
      RegExp(r'<span[^>]*>', caseSensitive: false),
      '',
    );
    output = output.replaceAll(
      RegExp(r'</span>', caseSensitive: false),
      '',
    );
    output = output.replaceAll(
      RegExp(r'<code[^>]*>', caseSensitive: false),
      '',
    );
    output = output.replaceAll(
      RegExp(r'</code>', caseSensitive: false),
      '',
    );
    output = output.replaceAll(RegExp(r'<[^>]+>'), '');
    output = output.replaceAll('&nbsp;', ' ');
    output = output.replaceAll('&amp;', '&');
    output = output.replaceAll('&lt;', '<');
    output = output.replaceAll('&gt;', '>');
    return output;
  }

  _NormalizedEditorBody _formatNormalizedEmailBody(
    String input,
    List<TextRange> existingLinkRanges,
  ) {
    final paymentFailurePattern = RegExp(
      r'^(.*?)\s*Invoice Date:\s*(.*?)\s*Due Date:\s*(.*?)\s*Amount:\s*(.*?)\s*Reason for Decline:\s*(.*?)\s*In case you wish to make a direct payment,\s*please click\s*(.*?)$',
      dotAll: true,
    );
    final match = paymentFailurePattern.firstMatch(input);
    if (match == null) {
      return _NormalizedEditorBody(text: input, linkRanges: existingLinkRanges);
    }

    final intro = (match.group(1) ?? '').trim();
    final invoiceDate = (match.group(2) ?? '').trim();
    final dueDate = (match.group(3) ?? '').trim();
    final total = (match.group(4) ?? '').trim();
    final declineReason = (match.group(5) ?? '').trim();
    final linkText = (match.group(6) ?? '').trim();

    final formatted =
        '$intro Invoice Date: $invoiceDate Due Date:\n\n'
        '$dueDate Amount: $total Reason for Decline: $declineReason '
        'In case you wish to make a direct payment,\n'
        'please click $linkText';

    final linkRanges = <TextRange>[];
    if (linkText.isNotEmpty) {
      final linkStart = formatted.lastIndexOf(linkText);
      if (linkStart >= 0) {
        linkRanges.add(
          TextRange(start: linkStart, end: linkStart + linkText.length),
        );
      }
    }

    return _NormalizedEditorBody(text: formatted, linkRanges: linkRanges);
  }

  String _formatSelectedTextAsList(
    String selectedText,
    _EditorListFormat format,
  ) {
    final lines = selectedText.split('\n');
    final formattedLines = <String>[];
    for (var index = 0; index < lines.length; index++) {
      final trimmed = lines[index].trim();
      if (trimmed.isEmpty) {
        formattedLines.add('');
        continue;
      }
      if (format == _EditorListFormat.numbered) {
        formattedLines.add('${index + 1}. $trimmed');
      } else {
        formattedLines.add('• $trimmed');
      }
    }
    return formattedLines.join('\n');
  }

  void _applyFontSize(int fontSize) {
    final selection = _restoreResolvedBodySelection();
    if (selection == null) {
      return;
    }
    _bodyController.addFontSizeRange(selection, fontSize.toDouble());
  }

  void _applyFontFamily(String fontFamily) {
    final selection = _restoreResolvedBodySelection();
    if (selection == null) {
      return;
    }
    _bodyController.addFontFamilyRange(selection, fontFamily);
  }

  void _applyEditorTextStyle(String style) {
    final selection = _restoreResolvedBodySelection();
    if (selection == null) {
      return;
    }
    final preset = _textStylePresetFor(style);
    _bodyController.addTextStyleRange(selection, preset);
  }

  _EditorTextStylePreset _textStylePresetFor(String style) {
    switch (style) {
      case 'Heading 1':
        return const _EditorTextStylePreset(
          fontSize: 32,
          fontWeight: FontWeight.w700,
        );
      case 'Heading 2':
        return const _EditorTextStylePreset(
          fontSize: 28,
          fontWeight: FontWeight.w700,
        );
      case 'Heading 3':
        return const _EditorTextStylePreset(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        );
      case 'Heading 4':
        return const _EditorTextStylePreset(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        );
      case 'Heading 5':
        return const _EditorTextStylePreset(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        );
      case 'Heading 6':
        return const _EditorTextStylePreset(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        );
      case 'Normal Text':
      default:
        return const _EditorTextStylePreset(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        );
    }
  }

  void _transformSelection(String Function(String) transform) {
    final text = _bodyController.text;
    final selection = _restoreResolvedBodySelection();
    final int start = selection?.start ?? text.length;
    final int end = selection?.end ?? text.length;
    final int safeStart = start.clamp(0, text.length);
    final int safeEnd = end.clamp(0, text.length);
    if (safeStart == safeEnd) {
      return;
    }
    final selectedText = text.substring(safeStart, safeEnd);
    final replacement = transform(selectedText);
    _bodyController.value = TextEditingValue(
      text: text.replaceRange(safeStart, safeEnd, replacement),
      selection: TextSelection(
        baseOffset: safeStart,
        extentOffset: safeStart + replacement.length,
      ),
    );
  }

  String _toBoldUnicode(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      buffer.write(_mapBoldRune(rune));
    }
    return buffer.toString();
  }

  String _toItalicUnicode(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      buffer.write(_mapItalicRune(rune));
    }
    return buffer.toString();
  }

  String _toUnderlinedUnicode(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune == 0x0A || rune == 0x0D) {
        buffer.writeCharCode(rune);
        continue;
      }
      buffer.writeCharCode(rune);
      buffer.writeCharCode(0x0332);
    }
    return buffer.toString();
  }

  String _mapBoldRune(int rune) {
    if (rune >= 0x41 && rune <= 0x5A) {
      return String.fromCharCode(0x1D400 + (rune - 0x41));
    }
    if (rune >= 0x61 && rune <= 0x7A) {
      return String.fromCharCode(0x1D41A + (rune - 0x61));
    }
    if (rune >= 0x30 && rune <= 0x39) {
      return String.fromCharCode(0x1D7CE + (rune - 0x30));
    }
    return String.fromCharCode(rune);
  }

  String _mapItalicRune(int rune) {
    if (rune >= 0x41 && rune <= 0x5A) {
      return String.fromCharCode(0x1D434 + (rune - 0x41));
    }
    if (rune >= 0x61 && rune <= 0x7A) {
      return String.fromCharCode(0x1D44E + (rune - 0x61));
    }
    return String.fromCharCode(rune);
  }

  void _replaceSelectionWithText(String replacement, {int? cursorOffset}) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;
    final int safeStart = start.clamp(0, text.length);
    final int safeEnd = end.clamp(0, text.length);
    final replaced = text.replaceRange(safeStart, safeEnd, replacement);

    _bodyController.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(
        offset: cursorOffset ?? (safeStart + replacement.length),
      ),
    );
  }

  Widget _toolbarDivider() {
    return Container(width: 1, height: 18, color: const Color(0xFF000000));
  }
}

class _EditorColorPickerMenu extends StatefulWidget {
  final List<Color> swatches;
  final ValueChanged<Color> onApply;
  final VoidCallback onCancel;

  const _EditorColorPickerMenu({
    required this.swatches,
    required this.onApply,
    required this.onCancel,
  });

  @override
  State<_EditorColorPickerMenu> createState() => _EditorColorPickerMenuState();
}

class _EditorColorPickerMenuState extends State<_EditorColorPickerMenu> {
  late HSVColor _hsvColor;
  late double _opacity;
  late final TextEditingController _hexController;

  Color get _selectedColor =>
      _hsvColor.toColor().withAlpha((_opacity * 255).round());

  @override
  void initState() {
    super.initState();
    final initialColor = widget.swatches.isNotEmpty
        ? widget.swatches.first
        : const Color(0xFF0000EE);
    _hsvColor = HSVColor.fromColor(initialColor);
    _opacity = initialColor.a;
    _hexController = TextEditingController(text: _colorToHex(_selectedColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 296,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSaturationValueArea(),
                  const SizedBox(height: 12),
                  _buildHueBar(),
                  const SizedBox(height: 10),
                  _buildOpacityBar(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildHexInput()),
                      const SizedBox(width: 8),
                      Container(
                        width: 68,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSwatchesToggle(),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => widget.onApply(_selectedColor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22B378),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      backgroundColor: const Color(0xFFF7F8FA),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: const BorderSide(color: AppTheme.borderColor),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaturationValueArea() {
    return GestureDetector(
      onTapDown: (details) => _updateSaturationValue(details.localPosition),
      onPanUpdate: (details) => _updateSaturationValue(details.localPosition),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
          height: 160,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: HSVColor.fromAHSV(1, _hsvColor.hue, 1, 1).toColor(),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white.withAlpha(0)],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (_hsvColor.saturation * 276).clamp(0, 276) - 7,
                top: ((1 - _hsvColor.value) * 160).clamp(0, 160) - 7,
                child: _ColorPickerHandle(color: _selectedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHueBar() {
    return _buildGradientBar(
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ),
      value: _hsvColor.hue / 360,
      onChange: (value) {
        setState(() {
          _hsvColor = _hsvColor.withHue((value * 360).clamp(0, 360));
          _syncHex();
        });
      },
    );
  }

  Widget _buildOpacityBar() {
    return _buildGradientBar(
      gradient: LinearGradient(
        colors: [
          _hsvColor.toColor().withAlpha(0),
          _hsvColor.toColor().withAlpha(255),
        ],
      ),
      value: _opacity,
      onChange: (value) {
        setState(() {
          _opacity = value.clamp(0, 1);
          _syncHex();
        });
      },
    );
  }

  Widget _buildGradientBar({
    required Gradient gradient,
    required double value,
    required ValueChanged<double> onChange,
  }) {
    return GestureDetector(
      onTapDown: (details) => onChange((details.localPosition.dx / 276)),
      onPanUpdate: (details) => onChange((details.localPosition.dx / 276)),
      child: SizedBox(
        height: 14,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 8,
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
            Positioned(
              left: (value.clamp(0, 1) * 276) - 7,
              child: const _ColorPickerHandle(color: Color(0xFF0000EE)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHexInput() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _hexController,
        onChanged: _applyHexInput,
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: AppTheme.infoBlue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: AppTheme.infoBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: AppTheme.infoBlue, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildSwatchesToggle() {
    return Row(
      children: [
        const SizedBox(
          width: 12,
          height: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Swatches',
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
        const SizedBox(width: 2),
        const Icon(
          LucideIcons.chevronRight,
          size: 14,
          color: AppTheme.textSecondary,
        ),
        const Spacer(),
        Wrap(
          spacing: 5,
          children: widget.swatches.take(4).map((color) {
            return InkWell(
              onTap: () => _setColor(color),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _updateSaturationValue(Offset position) {
    setState(() {
      _hsvColor = _hsvColor.withSaturation((position.dx / 276).clamp(0, 1));
      _hsvColor = _hsvColor.withValue((1 - (position.dy / 160)).clamp(0, 1));
      _syncHex();
    });
  }

  void _setColor(Color color) {
    setState(() {
      _hsvColor = HSVColor.fromColor(color);
      _opacity = color.a;
      _syncHex();
    });
  }

  void _applyHexInput(String value) {
    final normalized = value.replaceFirst('#', '').trim();
    if (normalized.length != 6 && normalized.length != 8) {
      return;
    }
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) {
      return;
    }
    final color = normalized.length == 6
        ? Color(0xFF000000 | parsed)
        : Color(((parsed & 0xFF) << 24) | (parsed >> 8));
    setState(() {
      _hsvColor = HSVColor.fromColor(color);
      _opacity = color.a;
    });
  }

  void _syncHex() {
    _hexController.value = TextEditingValue(
      text: _colorToHex(_selectedColor),
      selection: TextSelection.collapsed(
        offset: _colorToHex(_selectedColor).length,
      ),
    );
  }

  String _colorToHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    final alpha = (color.a * 255).round().clamp(0, 255);
    final alphaHex = alpha.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}$alphaHex';
  }
}

class _ColorPickerHandle extends StatelessWidget {
  final Color color;

  const _ColorPickerHandle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _PaymentTemplateBodyController extends TextEditingController {
  final List<TextRange> _strikeRanges = <TextRange>[];
  final List<_EditorTextColorRange> _textColorRanges =
      <_EditorTextColorRange>[];
  final List<_EditorTextColorRange> _highlightColorRanges =
      <_EditorTextColorRange>[];
  final List<_EditorFontSizeRange> _fontSizeRanges = <_EditorFontSizeRange>[];
  final List<_EditorFontFamilyRange> _fontFamilyRanges =
      <_EditorFontFamilyRange>[];
  final List<_EditorTextStyleRange> _textStyleRanges =
      <_EditorTextStyleRange>[];

  _PaymentTemplateBodyController({required String text}) : super(text: text);

  void clearAllFormatting() {
    _strikeRanges.clear();
    _textColorRanges.clear();
    _highlightColorRanges.clear();
    _fontSizeRanges.clear();
    _fontFamilyRanges.clear();
    _textStyleRanges.clear();
    notifyListeners();
  }

  void addStrikeRange(TextSelection selection) {
    final int start = selection.start.clamp(0, text.length);
    final int end = selection.end.clamp(0, text.length);
    if (start == end) {
      return;
    }
    _strikeRanges.add(TextRange(start: start, end: end));
    _mergeStrikeRanges();
    notifyListeners();
  }

  void addTextColorRange(TextSelection selection, Color color) {
    final int start = selection.start.clamp(0, text.length);
    final int end = selection.end.clamp(0, text.length);
    if (start == end) {
      return;
    }
    _textColorRanges.add(
      _EditorTextColorRange(start: start, end: end, color: color),
    );
    notifyListeners();
  }

  void addTextColorTextRange(TextRange range, Color color) {
    final int start = range.start.clamp(0, text.length);
    final int end = range.end.clamp(0, text.length);
    if (start == end) {
      return;
    }
    _textColorRanges.add(
      _EditorTextColorRange(start: start, end: end, color: color),
    );
    notifyListeners();
  }

  void addHighlightColorRange(TextSelection selection, Color color) {
    final int start = selection.start.clamp(0, text.length);
    final int end = selection.end.clamp(0, text.length);
    if (start == end) {
      return;
    }
    _highlightColorRanges.add(
      _EditorTextColorRange(start: start, end: end, color: color),
    );
    notifyListeners();
  }

  void addFontSizeRange(TextSelection selection, double fontSize) {
    final int start = selection.start.clamp(0, text.length);
    final int end = selection.end.clamp(0, text.length);
    if (start == end) {
      return;
    }
    _fontSizeRanges.add(
      _EditorFontSizeRange(start: start, end: end, fontSize: fontSize),
    );
    notifyListeners();
  }

  void addFontFamilyRange(TextSelection selection, String fontFamily) {
    final int start = selection.start.clamp(0, text.length);
    final int end = selection.end.clamp(0, text.length);
    if (start == end) {
      return;
    }
    _fontFamilyRanges.add(
      _EditorFontFamilyRange(start: start, end: end, fontFamily: fontFamily),
    );
    notifyListeners();
  }

  void addTextStyleRange(
    TextSelection selection,
    _EditorTextStylePreset preset,
  ) {
    final int start = selection.start.clamp(0, text.length);
    final int end = selection.end.clamp(0, text.length);
    if (start == end) {
      return;
    }
    _textStyleRanges.add(
      _EditorTextStyleRange(start: start, end: end, preset: preset),
    );
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if ((_strikeRanges.isEmpty &&
            _textColorRanges.isEmpty &&
            _highlightColorRanges.isEmpty &&
            _fontSizeRanges.isEmpty &&
            _fontFamilyRanges.isEmpty &&
            _textStyleRanges.isEmpty) ||
        text.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    final boundaries = <int>{0, text.length};
    for (final range in _strikeRanges) {
      boundaries.add(range.start.clamp(0, text.length));
      boundaries.add(range.end.clamp(0, text.length));
    }
    for (final range in _textColorRanges) {
      boundaries.add(range.start.clamp(0, text.length));
      boundaries.add(range.end.clamp(0, text.length));
    }
    for (final range in _highlightColorRanges) {
      boundaries.add(range.start.clamp(0, text.length));
      boundaries.add(range.end.clamp(0, text.length));
    }
    for (final range in _fontSizeRanges) {
      boundaries.add(range.start.clamp(0, text.length));
      boundaries.add(range.end.clamp(0, text.length));
    }
    for (final range in _fontFamilyRanges) {
      boundaries.add(range.start.clamp(0, text.length));
      boundaries.add(range.end.clamp(0, text.length));
    }
    for (final range in _textStyleRanges) {
      boundaries.add(range.start.clamp(0, text.length));
      boundaries.add(range.end.clamp(0, text.length));
    }
    final sortedBoundaries = boundaries.toList()..sort();
    final children = <TextSpan>[];
    for (var index = 0; index < sortedBoundaries.length - 1; index++) {
      final start = sortedBoundaries[index];
      final end = sortedBoundaries[index + 1];
      if (start == end) {
        continue;
      }
      children.add(
        TextSpan(
          text: text.substring(start, end),
          style: _styleForRange(
            style,
            hasStrike: _hasStrikeInRange(start, end),
            textColor: _textColorForRange(start, end),
            highlightColor: _highlightColorForRange(start, end),
            fontSize: _resolvedFontSizeForRange(start, end),
            fontFamily: _fontFamilyForRange(start, end),
            fontWeight: _fontWeightForRange(start, end),
          ),
        ),
      );
    }

    return TextSpan(style: style, children: children);
  }

  TextStyle? _styleForRange(
    TextStyle? baseStyle, {
    required bool hasStrike,
    required Color? textColor,
    required Color? highlightColor,
    required double? fontSize,
    required String? fontFamily,
    required FontWeight? fontWeight,
  }) {
    if (!hasStrike &&
        textColor == null &&
        highlightColor == null &&
        fontSize == null &&
        fontFamily == null &&
        fontWeight == null) {
      return null;
    }
    return (baseStyle ?? const TextStyle()).copyWith(
      color: textColor ?? baseStyle?.color,
      backgroundColor: highlightColor ?? baseStyle?.backgroundColor,
      fontSize: fontSize ?? baseStyle?.fontSize,
      fontFamily: fontFamily ?? baseStyle?.fontFamily,
      fontWeight: fontWeight ?? baseStyle?.fontWeight,
      decoration: hasStrike
          ? TextDecoration.lineThrough
          : baseStyle?.decoration,
    );
  }

  bool _hasStrikeInRange(int start, int end) {
    return _strikeRanges.any((range) {
      return range.start < end && range.end > start;
    });
  }

  Color? _textColorForRange(int start, int end) {
    for (final range in _textColorRanges.reversed) {
      if (range.start < end && range.end > start) {
        return range.color;
      }
    }
    return null;
  }

  Color? _highlightColorForRange(int start, int end) {
    for (final range in _highlightColorRanges.reversed) {
      if (range.start < end && range.end > start) {
        return range.color;
      }
    }
    return null;
  }

  double? _fontSizeForRange(int start, int end) {
    for (final range in _fontSizeRanges.reversed) {
      if (range.start < end && range.end > start) {
        return range.fontSize;
      }
    }
    return null;
  }

  double? _resolvedFontSizeForRange(int start, int end) {
    return _textStylePresetForRange(start, end)?.fontSize ??
        _fontSizeForRange(start, end);
  }

  String? _fontFamilyForRange(int start, int end) {
    for (final range in _fontFamilyRanges.reversed) {
      if (range.start < end && range.end > start) {
        return range.fontFamily;
      }
    }
    return null;
  }

  FontWeight? _fontWeightForRange(int start, int end) {
    final preset = _textStylePresetForRange(start, end);
    return preset?.fontWeight;
  }

  _EditorTextStylePreset? _textStylePresetForRange(int start, int end) {
    for (final range in _textStyleRanges.reversed) {
      if (range.start < end && range.end > start) {
        return range.preset;
      }
    }
    return null;
  }

  void _mergeStrikeRanges() {
    _strikeRanges.sort((a, b) => a.start.compareTo(b.start));
    for (var index = 1; index < _strikeRanges.length; index++) {
      final previous = _strikeRanges[index - 1];
      final current = _strikeRanges[index];
      if (current.start <= previous.end) {
        _strikeRanges[index - 1] = TextRange(
          start: previous.start,
          end: current.end > previous.end ? current.end : previous.end,
        );
        _strikeRanges.removeAt(index);
        index--;
      }
    }
  }
}

class _EditorTextColorRange {
  final int start;
  final int end;
  final Color color;

  const _EditorTextColorRange({
    required this.start,
    required this.end,
    required this.color,
  });
}

class _EditorFontSizeRange {
  final int start;
  final int end;
  final double fontSize;

  const _EditorFontSizeRange({
    required this.start,
    required this.end,
    required this.fontSize,
  });
}

class _EditorFontFamilyRange {
  final int start;
  final int end;
  final String fontFamily;

  const _EditorFontFamilyRange({
    required this.start,
    required this.end,
    required this.fontFamily,
  });
}

class _EditorTextStylePreset {
  final double fontSize;
  final FontWeight fontWeight;

  const _EditorTextStylePreset({
    required this.fontSize,
    required this.fontWeight,
  });
}

class _EditorTextStyleRange {
  final int start;
  final int end;
  final _EditorTextStylePreset preset;

  const _EditorTextStyleRange({
    required this.start,
    required this.end,
    required this.preset,
  });
}

enum _EditorListFormat { bulleted, numbered }

enum _MoreToolsPanel { none, image, link }

enum _ImageInsertTab { upload, url }

class _NormalizedEditorBody {
  final String text;
  final List<TextRange> linkRanges;

  const _NormalizedEditorBody({
    required this.text,
    required this.linkRanges,
  });
}

class _PlaceholderMenuSection {
  final String title;
  final List<_PlaceholderMenuItem> items;

  const _PlaceholderMenuSection({
    required this.title,
    required this.items,
  });
}

class _PlaceholderMenuItem {
  final String label;
  final String token;

  const _PlaceholderMenuItem({
    required this.label,
    required this.token,
  });
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
                        // ignore: deprecated_member_use
                        groupValue: _autoGenerate,
                        activeColor: AppTheme.primaryBlue,
                        // ignore: deprecated_member_use
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
                        // ignore: deprecated_member_use
                        groupValue: _autoGenerate,
                        activeColor: AppTheme.primaryBlue,
                        // ignore: deprecated_member_use
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
                      if (!mounted) return;
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
            if (!mounted) return;
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
