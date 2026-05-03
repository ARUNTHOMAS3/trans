import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_state.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart'
    as coa;
import 'package:zerpai_erp/modules/accountant/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/shared/models/account_node.dart' as shared;
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/sales/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/items_stock_providers.dart';

// ─── Line Item Row Helper ───────────────────────────────────────────────────

class _BillLineItemRow {
  final bool isLandedCost;
  String? itemId;
  String? itemName;
  final TextEditingController itemNameCtrl = TextEditingController();
  String? hsnCode;
  final TextEditingController descriptionCtrl = TextEditingController();
  double? stockAvailable;
  String? itemType; // 'goods' or 'service'
  String? itemImageUrl;
  String? batch;
  final TextEditingController batchCtrl = TextEditingController();
  String? unitPack;
  final TextEditingController unitPackCtrl = TextEditingController();
  DateTime? expiry;
  final TextEditingController expiryCtrl = TextEditingController();
  final TextEditingController mrpCtrl = TextEditingController(text: '0.00');
  final TextEditingController ptrCtrl = TextEditingController(text: '0.00');
  final TextEditingController freeQtyCtrl = TextEditingController(text: '0.00');
  String? accountId;
  String? accountName;
  final TextEditingController quantityCtrl = TextEditingController(
    text: '1.00',
  );
  final TextEditingController rateCtrl = TextEditingController(text: '0.00');
  String? taxId;
  String? taxName;
  String? customerId;
  String? customerName;
  final TextEditingController discountCtrl = TextEditingController(text: '0');
  String discountType = '%'; // '%' or '₹'
  bool isDropdownOpen = false;
  bool isMoreDropdownOpen = false;
  bool showAdditionalInfo = false;
  final LayerLink layerLink = LayerLink();
  final LayerLink taxLayerLink = LayerLink();
  final LayerLink moreLayerLink = LayerLink();
  final FocusNode searchFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();
  final FocusNode expiryFocus = FocusNode();
  final FocusNode unitPackFocus = FocusNode();
  final FocusNode mrpFocus = FocusNode();
  final FocusNode ptrFocus = FocusNode();
  final FocusNode accountFocus = FocusNode();
  final FocusNode batchFocus = FocusNode();
  final FocusNode qtyFocus = FocusNode();
  final FocusNode freeQtyFocus = FocusNode();
  final FocusNode rateFocus = FocusNode();
  final FocusNode discountFocus = FocusNode();
  final FocusNode taxSearchFocus = FocusNode();
  final TextEditingController taxSearchCtrl = TextEditingController();
  String? itemCode;
  final LayerLink hsnLayerLink = LayerLink();
  final FocusNode hsnFocus = FocusNode();
  final TextEditingController hsnCtrl = TextEditingController();
  final LayerLink customerLayerLink = LayerLink();
  final FocusNode customerSearchFocus = FocusNode();
  final TextEditingController customerSearchCtrl = TextEditingController();

  _BillLineItemRow({this.isLandedCost = false});

  _BillLineItemRow clone() {
    final newRow = _BillLineItemRow(isLandedCost: isLandedCost);
    newRow.itemId = itemId;
    newRow.itemName = itemName;
    newRow.itemNameCtrl.text = itemNameCtrl.text;
    newRow.hsnCode = hsnCode;
    newRow.hsnCtrl.text = hsnCtrl.text;
    newRow.itemCode = itemCode;
    newRow.descriptionCtrl.text = descriptionCtrl.text;
    newRow.stockAvailable = stockAvailable;
    newRow.itemType = itemType;
    newRow.itemImageUrl = itemImageUrl;
    newRow.batchCtrl.text = batchCtrl.text;
    newRow.unitPackCtrl.text = unitPackCtrl.text;
    newRow.expiry = expiry;
    newRow.expiryCtrl.text = expiryCtrl.text;
    newRow.mrpCtrl.text = mrpCtrl.text;
    newRow.ptrCtrl.text = ptrCtrl.text;
    newRow.freeQtyCtrl.text = freeQtyCtrl.text;
    newRow.accountId = accountId;
    newRow.accountName = accountName;
    newRow.quantityCtrl.text = quantityCtrl.text;
    newRow.rateCtrl.text = rateCtrl.text;
    newRow.taxId = taxId;
    newRow.taxName = taxName;
    newRow.customerId = customerId;
    newRow.customerName = customerName;
    newRow.discountCtrl.text = discountCtrl.text;
    newRow.discountType = discountType;
    newRow.showAdditionalInfo = showAdditionalInfo;
    return newRow;
  }

  double get quantity => double.tryParse(quantityCtrl.text) ?? 1;
  double get rate => double.tryParse(rateCtrl.text) ?? 0;
  double get discountValue => double.tryParse(discountCtrl.text) ?? 0;

  double get amount {
    double base = quantity * rate;
    if (discountType == '%') {
      return base - (base * discountValue / 100);
    }
    return base - discountValue;
  }

  PurchasesBillLineItem toModel() {
    return PurchasesBillLineItem(
      itemId: itemId,
      itemName: itemNameCtrl.text.trim().isEmpty
          ? null
          : itemNameCtrl.text.trim(),
      hsnCode: hsnCode,
      description: descriptionCtrl.text.trim().isEmpty
          ? null
          : descriptionCtrl.text.trim(),
      batch: batchCtrl.text.trim().isEmpty ? null : batchCtrl.text.trim(),
      unitPack: unitPackCtrl.text.trim().isEmpty
          ? null
          : unitPackCtrl.text.trim(),
      expiry: expiry,
      mrp: double.tryParse(mrpCtrl.text) ?? 0,
      ptr: double.tryParse(ptrCtrl.text) ?? 0,
      freeQuantity: double.tryParse(freeQtyCtrl.text) ?? 0,
      accountId: accountId,
      accountName: accountName,
      quantity: quantity,
      rate: rate,
      taxId: taxId,
      taxName: taxName,
      customerId: customerId,
      customerName: customerName,
      discount: discountValue,
      discountType: discountType,
      amount: amount,
      isLandedCost: isLandedCost,
    );
  }

  void dispose() {
    itemNameCtrl.dispose();
    descriptionCtrl.dispose();
    batchCtrl.dispose();
    unitPackCtrl.dispose();
    expiryCtrl.dispose();
    mrpCtrl.dispose();
    ptrCtrl.dispose();
    freeQtyCtrl.dispose();
    quantityCtrl.dispose();
    rateCtrl.dispose();
    discountCtrl.dispose();
    taxSearchCtrl.dispose();
    taxSearchFocus.dispose();
    customerSearchFocus.dispose();
    customerSearchCtrl.dispose();
    hsnFocus.dispose();
    hsnCtrl.dispose();
    searchFocus.dispose();
    batchFocus.dispose();
    qtyFocus.dispose();
    freeQtyFocus.dispose();
    rateFocus.dispose();
    discountFocus.dispose();
    descriptionFocus.dispose();
    expiryFocus.dispose();
    unitPackFocus.dispose();
    mrpFocus.dispose();
    ptrFocus.dispose();
    accountFocus.dispose();
  }
}

class PurchasesBillCreateScreen extends ConsumerStatefulWidget {
  const PurchasesBillCreateScreen({super.key});

  @override
  ConsumerState<PurchasesBillCreateScreen> createState() =>
      _PurchasesBillCreateScreenState();
}

class _PurchasesBillCreateScreenState
    extends ConsumerState<PurchasesBillCreateScreen>
    with TickerProviderStateMixin {
  static const Color _pageBg = Color(0xFFF5F6FA);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _sectionBg = Color(0xFFF8FAFC);
  static const Color _borderColor = Color(0xFFE1E5EE);
  static const Color _fieldBorder = Color(0xFFD7DCE5);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _textSecondary = Color(
    0xFF64748B,
  ); // Added for consistency
  static const Color _primaryGreen = Color(0xFF22C55E); // Updated
  static const Color _primaryBlue = Color(0xFF3B82F6);
  static const Color _navy = Color(0xFF404452); // Added
  static const Color _danger = Color(0xFFEF4444);
  static const double _fieldHeight = 36; // Re-adjusted based on visual
  static const double _labelFixedWidth = 150; // Updated
  // ─── Form state ────────────────────────────────────────────────────────────
  Vendor? _selectedVendor;
  bool _vendorDropdownOpen = false;
  final TextEditingController _vendorSearchCtrl = TextEditingController();

  final LayerLink _vendorLayerLink = LayerLink();
  OverlayEntry? _vendorOverlayEntry;

  final TextEditingController _billNumberCtrl = TextEditingController();
  final TextEditingController _orderNumberCtrl = TextEditingController();
  final TextEditingController _billDateCtrl = TextEditingController();
  final TextEditingController _dueDateCtrl = TextEditingController();
  String? _paymentTerms;
  bool _reverseCharge = false;
  OverlayEntry? _itemOverlayEntry;
  OverlayEntry? _hsnOverlayEntry;
  OverlayEntry? _sidebarOverlayEntry;
  bool _isContactPersonsExpanded = true;
  bool _isAddressExpanded = false;
  String _activeSidebarTab = 'Details';
  int _highlightedIndex = -1;
  final TextEditingController _subjectCtrl = TextEditingController();
  Map<String, dynamic>? _customBillingAddress;
  bool _hasAddress = false;

  String _warehouse = 'ZABNIX PRIVATE LIMITED';
  String _discountType = 'At Transaction Level';
  String? _sourceOfSupply;
  String? _destinationOfSupply;

  final List<String> _statesList = [
    '[AN] - Andaman and Nicobar Islands',
    '[AP] - Andhra Pradesh',
    '[AR] - Arunachal Pradesh',
    '[AS] - Assam',
    '[BR] - Bihar',
    '[CH] - Chandigarh',
    '[CT] - Chhattisgarh',
    '[DN] - Dadra and Nagar Haveli',
    '[DD] - Daman and Diu',
    '[DL] - Delhi',
    '[GA] - Goa',
    '[GJ] - Gujarat',
    '[HR] - Haryana',
    '[HP] - Himachal Pradesh',
    '[JK] - Jammu and Kashmir',
    '[JH] - Jharkhand',
    '[KA] - Karnataka',
    '[KL] - Kerala',
    '[LD] - Lakshadweep',
    '[MP] - Madhya Pradesh',
    '[MH] - Maharashtra',
    '[MN] - Manipur',
    '[ML] - Meghalaya',
    '[MZ] - Mizoram',
    '[NL] - Nagaland',
    '[OR] - Odisha',
    '[PY] - Puducherry',
    '[PB] - Punjab',
    '[RJ] - Rajasthan',
    '[SK] - Sikkim',
    '[TN] - Tamil Nadu',
    '[TG] - Telangana',
    '[TR] - Tripura',
    '[UP] - Uttar Pradesh',
    '[UT] - Uttarakhand',
    '[WB] - West Bengal',
  ];

  final List<String> _gstTreatments = [
    'Registered Business - Regular',
    'Registered Business - Composition',
    'Unregistered Business',
    'Consumer',
    'Overseas',
    'Special Economic Zone',
    'Deemed Export',
  ];

  @override
  void dispose() {
    _removeVendorOverlay();
    _removeMoreOverlay();
    _vendorSearchCtrl.dispose();
    _billNumberCtrl.dispose();
    _orderNumberCtrl.dispose();
    _billDateCtrl.dispose();
    _dueDateCtrl.dispose();
    _subjectCtrl.dispose();
    _adjustmentLabelCtrl.dispose();
    _adjustmentAmountCtrl.dispose();
    _discountPercentCtrl.dispose();
    _totalsTaxSearchCtrl.dispose();
    _totalsTaxSearchFocus.dispose();
    _notesCtrl.dispose();
    _sidebarOverlayEntry?.remove();
    _sidebarOverlayEntry = null;
    for (var row in _lineItems) {
      row.dispose();
    }
    super.dispose();
  }

  // ─── Line items ────────────────────────────────────────────────────────────
  List<_BillLineItemRow> _lineItems = [];

  // ─── Totals ────────────────────────────────────────────────────────────────
  double _discountPercent = 0;
  double _adjustment = 0;
  final TextEditingController _adjustmentLabelCtrl = TextEditingController(
    text: 'Adjustment',
  );
  final TextEditingController _adjustmentAmountCtrl = TextEditingController(
    text: '0.00',
  );
  final TextEditingController _discountPercentCtrl = TextEditingController(
    text: '0',
  );
  OverlayEntry? _moreOverlayEntry;
  bool _isTdsSelected = true;
  String? _selectedTotalsTax;

  final TextEditingController _totalsTaxSearchCtrl = TextEditingController();
  final FocusNode _totalsTaxSearchFocus = FocusNode();

  // ─── Notes / files ─────────────────────────────────────────────────────────

  final TextEditingController _notesCtrl = TextEditingController();
  bool _isLoading = false;

  // ─── Payment Terms options ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _paymentTermsList = [];

  final List<String> _standardTaxOptions = [
    'Non-Taxable',
    'Out of Scope',
    'Non-GST Supply',
  ];

  OverlayEntry? _taxOverlayEntry;
  int _highlightedTaxIndex = -1;
  OverlayEntry? _customerOverlayEntry;
  int _highlightedCustomerIndex = -1;

  // ─────────────────────────────────────────── Lifecycle ────────────────────

  @override
  void initState() {
    super.initState();
    _lineItems.add(_BillLineItemRow());
    // Set today as due date default
    _dueDateCtrl.text = DateFormat(
      'dd-MM-yyyy',
    ).format(DateTime.now().add(const Duration(days: 360)));
    Future.microtask(() {
      ref.read(vendorProvider.notifier).loadVendors();
      _loadPaymentTerms();
    });
  }

  Future<void> _loadPaymentTerms() async {
    try {
      final lookupsService = LookupsApiService();
      final terms = await lookupsService.getPaymentTerms();
      if (mounted) {
        setState(() {
          _paymentTermsList = terms;
          if (_paymentTerms == null && terms.isNotEmpty) {
            // Default to Net 30 if available
            final net30 = terms.firstWhere(
              (t) => t['term_name'] == 'Net 30',
              orElse: () => terms.first,
            );
            _paymentTerms = net30['id'];
          }
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error loading payment terms',
        error: e,
        module: 'purchases',
      );
    }
  }

  Future<void> _showConfigurePaymentTermsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ManagePaymentTermsDialog(
        items: _paymentTermsList,
        selectedId: _paymentTerms,
        onSelect: (term) {
          setState(() {
            _paymentTerms = term['id'];
          });
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncPaymentTerms(items);

          setState(() {
            if (_paymentTerms != null && _paymentTerms!.startsWith('new_')) {
              final oldTerm = items.firstWhere(
                (it) => it['id'] == _paymentTerms,
                orElse: () => {},
              );
              final termName = oldTerm['term_name'];

              if (termName != null) {
                final newTerm = updated.firstWhere(
                  (it) => it['term_name'] == termName,
                  orElse: () => {},
                );
                if (newTerm.containsKey('id')) {
                  _paymentTerms = newTerm['id'];
                }
              }
            }
            _paymentTermsList = updated;
          });
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }
          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'payment-terms',
              item['id'].toString(),
            );
            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This payment term is in use and cannot be deleted.';
            }
          } catch (e) {
            AppLogger.error(
              'Error checking payment term usage',
              error: e,
              module: 'purchases',
            );
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPaymentTermRow(
    String termName,
    bool isSelected,
    bool isHovered,
  ) {
    Color bg = Colors.transparent;
    Color text = const Color(0xFF111827);

    if (isHovered) {
      bg = const Color(0xFF3B82F6);
      text = Colors.white;
    } else if (isSelected) {
      bg = const Color(0xFFEFF6FF);
      text = const Color(0xFF1D4ED8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: bg,
      child: Row(
        children: [
          Expanded(
            child: Text(
              termName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: text,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 16,
              color: isHovered ? Colors.white : const Color(0xFF2563EB),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────── Computed ────────────────────

  double get _grossAmount =>
      _lineItems.fold(0, (s, r) => s + (r.quantity * r.rate));

  double get _subTotal => _lineItems.fold(0, (s, r) => s + r.amount);

  double get _lineItemDiscountTotal => _grossAmount - _subTotal;

  double get _discountAmount {
    if (_discountType == 'At Line Item Level') return _lineItemDiscountTotal;
    return _subTotal * (_discountPercent / 100);
  }

  double get _taxAmount {
    // Simplified: 0 for now, will be computed via tax API
    return 0;
  }

  double get _total {
    if (_discountType == 'At Line Item Level') {
      return _subTotal + _taxAmount + _adjustment;
    }
    return _subTotal - _discountAmount + _taxAmount + _adjustment;
  }

  // ─────────────────────────────────────────── Build ────────────────────────

  void _removeItemOverlay() {
    _itemOverlayEntry?.remove();
    _itemOverlayEntry = null;
    _removeTaxOverlay();
    _removeCustomerOverlay();
    _removeMoreOverlay();
    _removeHsnOverlay();
    if (mounted) {
      setState(() {
        for (var row in _lineItems) {
          row.isDropdownOpen = false;
        }
      });
    }
  }

  void _removeMoreOverlay() {
    _moreOverlayEntry?.remove();
    _moreOverlayEntry = null;
    if (mounted) {
      setState(() {
        for (var row in _lineItems) {
          row.isMoreDropdownOpen = false;
        }
      });
    }
  }

  void _removeTaxOverlay() {
    _taxOverlayEntry?.remove();
    _taxOverlayEntry = null;
    if (mounted) {
      setState(() {
        _highlightedTaxIndex = -1;
      });
    }
  }

  void _removeCustomerOverlay() {
    _customerOverlayEntry?.remove();
    _customerOverlayEntry = null;
    if (mounted) {
      setState(() {
        _highlightedCustomerIndex = -1;
      });
    }
  }

  void _removeHsnOverlay() {
    _hsnOverlayEntry?.remove();
    _hsnOverlayEntry = null;
  }

  void _showHsnEditOverlay(_BillLineItemRow row) {
    _removeHsnOverlay();
    final overlay = Overlay.of(context);

    _hsnOverlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: row.hsnLayerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomCenter,
          followerAnchor: Alignment.topCenter,
          offset: const Offset(0, 8),
          child: Align(
            alignment: Alignment.topCenter,
            child: TapRegion(
              onTapOutside: (_) => _removeHsnOverlay(),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HSN Code',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: TextField(
                                controller: row.hsnCtrl,
                                focusNode: row.hsnFocus,
                                autofocus: true,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF3B82F6),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.search,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                row.hsnCode = row.hsnCtrl.text;
                              });
                              _removeHsnOverlay();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => _removeHsnOverlay(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF374151),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_hsnOverlayEntry!);
  }

  double _resolveOverlayWidth({
    required double minWidth,
    double? preferredWidth,
  }) {
    final availableWidth = MediaQuery.of(context).size.width - 24;
    final baseWidth = preferredWidth ?? minWidth;
    // Allow dropdowns to be narrower than minWidth if the field is small,
    // but keep a minimum of 200px for searchability.
    return baseWidth.clamp(200.0, availableWidth).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(vendorProvider);
    final itemsState = ref.watch(itemsControllerProvider);
    final accountsRoots = ref.watch(chartOfAccountsProvider).roots;

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: GestureDetector(
        onTap: _removeItemOverlay,
        child: Material(
          color: _pageBg,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  // No horizontal padding here — sections manage their own padding
                  // so the vendor gray section can stretch edge-to-edge
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header (Fixed Gray Top Bar) ─────────────────────
                      _buildHeader(),
                      const Divider(height: 1, color: _borderColor),
                      const SizedBox(height: 32),
                      // ── Main Form Section ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildVendorRow(vendorState),
                            _buildVendorAddressSection(),
                            _buildGstTreatmentRow(),
                            const SizedBox(height: 24),
                            if (_selectedVendor != null) ...[
                              _buildSupplyRows(),
                              const SizedBox(height: 24),
                            ],
                            _buildMainFields(),
                            const SizedBox(height: 24),
                            _buildReverseChargeRow(),
                            const SizedBox(height: 24),
                            _buildSubjectRow(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                      // ── Items and Totals (In a card) ─────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildItemsToolbarRow(),
                              const SizedBox(height: 16),
                              _buildItemTable(itemsState, accountsRoots),
                              const SizedBox(height: 16),
                              _buildTotalsSection(),
                              const SizedBox(height: 24),
                              _buildNotesTermsAndAttachments(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Header ───────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(LucideIcons.fileText, size: 24, color: _textPrimary),
          const SizedBox(width: 12),
          const Text(
            'New Bill',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          const SizedBox(width: 16),
          InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.bills);
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 20, color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────── Vendor Row ───────────────────

  // Vendor row: label + input constrained to left half only,
  // matching the Bill# field width — right half stays empty.
  Widget _buildVendorRow(VendorState vendorState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _labelFixedWidth,
          child: _buildLabel('Vendor Name', required: true),
        ),
        const SizedBox(width: 12),
        _buildVendorDropdown(vendorState),
        const SizedBox(width: 12),
        _buildInrBadge(),
        const Spacer(),
        _buildVendorDetailsButton(),
      ],
    );
  }

  Widget _buildInrBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gps_fixed, size: 14, color: _primaryGreen),
          const SizedBox(width: 6),
          Text(
            'INR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorDetailsButton() {
    if (_selectedVendor == null) return const SizedBox.shrink();
    return ElevatedButton(
      onPressed: _showVendorDetailsSidebar,
      style: ElevatedButton.styleFrom(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${_selectedVendor!.displayName.toUpperCase()}'S DETAILS",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildVendorDropdown(VendorState vendorState) {
    return SizedBox(
      width: 500,
      child: CompositedTransformTarget(
        link: _vendorLayerLink,
        child: GestureDetector(
          onTap: () {
            if (_vendorDropdownOpen) {
              _removeVendorOverlay();
            } else {
              _showVendorOverlay(vendorState, 500);
            }
          },
          child: Container(
            height: _fieldHeight,
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(
                color: _vendorDropdownOpen ? _primaryBlue : _borderColor,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _selectedVendor?.displayName ?? 'Select a Vendor',
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedVendor != null
                            ? _textPrimary
                            : _textMuted,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
                if (_selectedVendor != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVendor = null;
                        _vendorSearchCtrl.clear();
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.close, size: 16, color: _danger),
                    ),
                  ),
                const VerticalDivider(width: 1, color: _borderColor),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: _textMuted,
                  ),
                ),
                GestureDetector(
                  onTap: _showAdvancedVendorSearchModal,
                  child: Container(
                    width: 44,
                    height: _fieldHeight,
                    decoration: const BoxDecoration(
                      color: _primaryGreen,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildGstTreatmentRow() {
    if (_selectedVendor == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Row(
        children: [
          const SizedBox(width: _labelFixedWidth + 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: _textMuted,
                fontFamily: 'Inter',
              ),
              children: [
                const TextSpan(text: 'GST Treatment: '),
                TextSpan(
                  text:
                      _selectedVendor!.gstTreatment ?? 'Unregistered Business',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showTaxPreferencesPopover,
            child: const Icon(
              Icons.edit_outlined,
              size: 14,
              color: _primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelFixedWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label + (isRequired ? '*' : ''),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isRequired ? Colors.red : _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildVendorAddressSection() {
    if (_selectedVendor == null) return const SizedBox.shrink();
    final address = _customBillingAddress ?? _selectedVendor!.billingAddress;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: _labelFixedWidth + 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BILLING ADDRESS',
                style: TextStyle(
                  fontSize: 12,
                  color: _textMuted,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              if (!_hasAddress)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showNewAddressDialog,
                    child: const Text(
                      'New Address',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                )
              else ...[
                if (address != null)
                  Text(
                    "${address['attention'] ?? ''}\n${address['street1'] ?? ''}\n${address['street2'] ?? ''}\n${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['zip'] ?? ''}\n${address['country'] ?? ''}\nPhone: ${address['phone'] ?? ''}",
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _showNewAddressDialog,
                  child: const Text(
                    'Change Address',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showNewAddressDialog() async {
    final attentionCtrl = TextEditingController(
      text: _selectedVendor?.displayName,
    );
    final street1Ctrl = TextEditingController();
    final street2Ctrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final zipCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final faxCtrl = TextEditingController();
    String? selectedCountry = 'India';
    String? selectedState;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Billing Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.blue),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildDialogField('Attention', attentionCtrl),
                _buildDialogDropdown(
                  'Country/Region',
                  ['India', 'USA', 'UK'],
                  selectedCountry,
                  (v) => setDialogState(() => selectedCountry = v),
                ),
                _buildDialogField(
                  'Address',
                  street1Ctrl,
                  hint: 'Street',
                  isMultiline: true,
                ),
                _buildDialogField(
                  '',
                  street2Ctrl,
                  hint: 'Place',
                  isMultiline: true,
                ),
                _buildDialogField('City', cityCtrl),
                Row(
                  children: [
                    Expanded(
                      child: _buildDialogDropdown(
                        'State',
                        _statesList,
                        selectedState,
                        (v) => setDialogState(() => selectedState = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDialogField('Pin Code', zipCtrl)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildDialogField('Phone', phoneCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDialogField('Fax Number', faxCtrl)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Note: Changes made here will be updated for this customer.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _customBillingAddress = {
                            'attention': attentionCtrl.text,
                            'street1': street1Ctrl.text,
                            'street2': street2Ctrl.text,
                            'city': cityCtrl.text,
                            'state': selectedState,
                            'zip': zipCtrl.text,
                            'country': selectedCountry,
                            'phone': phoneCtrl.text,
                          };
                          _hasAddress = true;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
          ],
          TextField(
            controller: ctrl,
            maxLines: isMultiline ? 3 : 1,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          FormDropdown<String>(
            value: value,
            items: items,
            displayStringForValue: (e) => e,
            onChanged: onChanged,
            height: _fieldHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildSupplyRows() {
    if (_selectedVendor == null) return const SizedBox.shrink();
    return Column(
      children: [
        _buildFormRow(
          label: 'Source of Supply',
          isRequired: true,
          child: SizedBox(
            width: 400,
            child: _buildStatesDropdown(
              _sourceOfSupply,
              (val) => setState(() => _sourceOfSupply = val),
            ),
          ),
        ),
        _buildFormRow(
          label: 'Destination of Supply',
          isRequired: true,
          child: SizedBox(
            width: 400,
            child: _buildStatesDropdown(
              _destinationOfSupply,
              (val) => setState(() => _destinationOfSupply = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatesDropdown(String? value, ValueChanged<String?> onChanged) {
    final items = {if (value != null) value, ..._statesList}.toList();
    return FormDropdown<String>(
      value: value,
      items: items,
      displayStringForValue: (s) => s,
      hint: 'Select State',
      onChanged: onChanged,
      height: _fieldHeight,
      border: Border.all(color: _fieldBorder),
      borderRadius: BorderRadius.circular(6),
      fillColor: _cardBg,
    );
  }

  Widget _buildGstTreatmentDropdown(
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    final items = {if (value != null) value, ..._gstTreatments}.toList();
    return FormDropdown<String>(
      value: value,
      items: items,
      displayStringForValue: (t) => t,
      hint: 'Select GST Treatment',
      onChanged: onChanged,
      height: _fieldHeight,
      border: Border.all(color: _fieldBorder),
      borderRadius: BorderRadius.circular(6),
      fillColor: _cardBg,
    );
  }

  void _showTaxPreferencesPopover() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Configure Tax Preferences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: _danger),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GST Treatment',
              style: TextStyle(fontSize: 13, color: _textMuted),
            ),
            const SizedBox(height: 8),
            _buildGstTreatmentDropdown(_selectedVendor?.gstTreatment, (val) {}),
            const SizedBox(height: 16),
            const Text(
              'Make it permanent?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: true,
                  onChanged: (v) {},
                  activeColor: _primaryBlue,
                ),
                const Expanded(
                  child: Text(
                    'Use these settings for all future transactions of this vendor.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedVendorSearchModal() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 900,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Advanced Vendor Search',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: _danger),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _borderColor),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 160,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: _borderColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Vendor Number',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          minimumSize: const Size(100, 40),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table Header
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'DISPLAY NAME',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'EMAIL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'COMPANY NAME',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'PHONE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table Body
                Expanded(
                  child: ListView.separated(
                    itemCount: 8,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: _borderColor),
                    itemBuilder: (context, index) {
                      final isEven = index % 2 == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: isEven
                              ? Colors.white
                              : const Color(0xFFFBFBFB),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VENDOR $index',
                                    style: const TextStyle(
                                      color: _primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'VEN-000${10 + index}',
                                    style: const TextStyle(
                                      color: _textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'vendor@example.com',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'Zerpai Technologies Pvt Ltd',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                '+91 8129542640',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Pagination Footer
                const Divider(height: 1, color: _borderColor),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: () {},
                      ),
                      const Text(
                        '1 - 8',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeVendorOverlay() {
    _vendorOverlayEntry?.remove();
    _vendorOverlayEntry = null;
    if (mounted) {
      setState(() {
        _vendorDropdownOpen = false;
      });
    }
  }

  void _showVendorDetailsSidebar() {
    _removeVendorOverlay();
    _removeItemOverlay();
    _removeMoreOverlay();

    final overlay = Overlay.of(context);
    _sidebarOverlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSidebarState) {
            return Stack(
              children: [
                GestureDetector(
                  onTap: _closeVendorDetailsSidebar,
                  child: Container(color: Colors.black.withValues(alpha: 0.05)),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    elevation: 16,
                    color: Colors.white,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.35,
                      height: MediaQuery.of(context).size.height,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(left: BorderSide(color: _borderColor)),
                      ),
                      child: Column(
                        children: [
                          _buildSidebarHeader(setSidebarState),
                          _buildSidebarTabs(setSidebarState),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _buildSidebarSummaryCards(),
                                  const SizedBox(height: 24),
                                  _buildSidebarContactDetailsSection(),
                                  const SizedBox(height: 24),
                                  _buildSidebarAccordions(setSidebarState),
                                ],
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
      },
    );
    overlay.insert(_sidebarOverlayEntry!);
  }

  void _closeVendorDetailsSidebar() {
    if (_sidebarOverlayEntry != null) {
      _sidebarOverlayEntry!.remove();
      _sidebarOverlayEntry = null;
      if (mounted) setState(() {});
    }
  }

  Widget _buildSidebarHeader(StateSetter setSidebarState) {
    if (_selectedVendor == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFFBFBFB),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _selectedVendor!.displayName.isNotEmpty
                    ? _selectedVendor!.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vendor',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _selectedVendor!.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: _primaryBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _closeVendorDetailsSidebar,
            icon: const Icon(Icons.close, color: _danger),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTabs(StateSetter setSidebarState) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: ['Details', 'Activity Log'].map((tab) {
          final isActive = _activeSidebarTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () {
                setSidebarState(() => _activeSidebarTab = tab);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? _primaryBlue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? _primaryBlue : _textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSidebarSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            label: 'Outstanding Payables',
            value: '₹ 0.00',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.track_changes,
            iconColor: _primaryGreen,
            label: 'Unused Credits',
            value: '₹ 0.00',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContactDetailsSection() {
    if (_selectedVendor == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Contact Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSidebarDetailRow(
                  'Currency',
                  _selectedVendor!.currency ?? 'INR',
                ),
                _buildSidebarDetailRow(
                  'Payment Terms',
                  _selectedVendor!.paymentTerms ?? 'Net 360',
                ),
                _buildSidebarDetailRow(
                  'Portal Status',
                  _selectedVendor!.enablePortal == true
                      ? 'Enabled'
                      : 'Disabled',
                ),
                _buildSidebarDetailRow(
                  'Vendor Language',
                  'English',
                  showInfo: true,
                ),
                _buildSidebarDetailRow(
                  'GST Treatment',
                  _selectedVendor!.gstTreatment ?? 'Unregistered Business',
                ),
                _buildSidebarDetailRow(
                  'Source of Supply',
                  _selectedVendor!.sourceOfSupply ?? 'Kerala',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarDetailRow(
    String label,
    String value, {
    bool showInfo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: _textMuted),
                ),
                if (showInfo) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, size: 14, color: _textMuted),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarAccordions(StateSetter setSidebarState) {
    return Column(
      children: [
        _buildSidebarAccordion(
          title: 'Contact Persons',
          badge: '1',
          isExpanded: _isContactPersonsExpanded,
          onExpansionChanged: (expanded) =>
              setSidebarState(() => _isContactPersonsExpanded = expanded),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _selectedVendor!.displayName.isNotEmpty
                                ? _selectedVendor!.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(1),
                          child: const Icon(
                            Icons.stars,
                            color: _primaryGreen,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedVendor!.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: _textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '-',
                            style: TextStyle(fontSize: 12, color: _textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: _textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedVendor!.phone ?? '+91-08129542640',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
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
        const SizedBox(height: 16),
        _buildSidebarAccordion(
          title: 'Address',
          isExpanded: _isAddressExpanded,
          onExpansionChanged: (expanded) =>
              setSidebarState(() => _isAddressExpanded = expanded),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 14,
                        color: _textMuted,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Billing Address',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedVendor!.billingAddress != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        "${_selectedVendor!.billingAddress!['attention'] ?? ''}\n"
                        "${_selectedVendor!.billingAddress!['street1'] ?? ''}\n"
                        "${_selectedVendor!.billingAddress!['city'] ?? ''}, ${_selectedVendor!.billingAddress!['state'] ?? ''} ${_selectedVendor!.billingAddress!['zip'] ?? ''}\n"
                        "${_selectedVendor!.billingAddress!['country'] ?? ''}\n"
                        "Phone: ${_selectedVendor!.billingAddress!['phone'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Shipping Address',
                    style: TextStyle(fontSize: 12, color: _textMuted),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'No Shipping Address',
                      style: TextStyle(fontSize: 13, color: _textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebarAccordion({
    required String title,
    String? badge,
    required bool isExpanded,
    required void Function(bool) onExpansionChanged,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isExpanded ? _primaryBlue : _borderColor,
          width: isExpanded ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: _textMuted,
            size: 20,
          ),
          children: children,
        ),
      ),
    );
  }

  void _showVendorOverlay(VendorState vendorState, double width) {
    _removeVendorOverlay();
    final overlay = Overlay.of(context);

    _vendorOverlayEntry = OverlayEntry(
      builder: (context) {
        String? hoveredId;
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final allVendors = vendorState.vendors;
            final query = _vendorSearchCtrl.text.toLowerCase();
            final filtered = query.isEmpty
                ? allVendors
                : allVendors
                      .where(
                        (v) =>
                            v.displayName.toLowerCase().contains(query) ||
                            (v.vendorNumber ?? '').toLowerCase().contains(
                              query,
                            ),
                      )
                      .toList();

            return Stack(
              children: [
                GestureDetector(
                  onTap: () => _removeVendorOverlay(),
                  child: Container(color: Colors.transparent),
                ),
                CompositedTransformFollower(
                  link: _vendorLayerLink,
                  showWhenUnlinked: false,
                  targetAnchor: Alignment.bottomLeft,
                  followerAnchor: Alignment.topLeft,
                  offset: const Offset(0, 4),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                      child: Container(
                        width: width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _borderColor),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Search box
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextField(
                                controller: _vendorSearchCtrl,
                                onChanged: (_) => setOverlayState(() {}),
                                autofocus: true,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 16,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: _borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: _borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: _primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Vendor list
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (filtered.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text(
                                          'No vendors found',
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ...filtered.map((v) {
                                      final isSelected =
                                          _selectedVendor?.id == v.id;
                                      final isHovered = hoveredId == v.id;
                                      return MouseRegion(
                                        onEnter: (_) => setOverlayState(
                                          () => hoveredId = v.id,
                                        ),
                                        onExit: (_) => setOverlayState(
                                          () => hoveredId = null,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedVendor = v;
                                              if (v.paymentTerms != null) {
                                                _paymentTerms = v.paymentTerms;
                                              }
                                              // Default supply states logic
                                              final billingState =
                                                  v.billingAddress?['state'];
                                              if (billingState == null ||
                                                  billingState
                                                      .toString()
                                                      .isEmpty) {
                                                _sourceOfSupply =
                                                    '[KL] - Kerala';
                                                _destinationOfSupply =
                                                    '[KL] - Kerala';
                                              } else {
                                                _sourceOfSupply = billingState;
                                                _destinationOfSupply =
                                                    billingState;
                                              }

                                              _hasAddress =
                                                  v.billingAddress != null &&
                                                  v.billingAddress!['street1'] !=
                                                      null;
                                              _customBillingAddress = null;
                                            });
                                            _removeVendorOverlay();
                                          },
                                          child: Container(
                                            color: isSelected || isHovered
                                                ? _primaryBlue
                                                : Colors.transparent,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                // Avatar
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isSelected || isHovered
                                                        ? Colors.white
                                                              .withValues(
                                                                alpha: 0.2,
                                                              )
                                                        : const Color(
                                                            0xFFF3F4F6,
                                                          ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      v.displayName.isNotEmpty
                                                          ? v.displayName[0]
                                                                .toUpperCase()
                                                          : '?',
                                                      style: TextStyle(
                                                        color:
                                                            isSelected ||
                                                                isHovered
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF6B7280,
                                                              ),
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            v.displayName,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  isSelected ||
                                                                      isHovered
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFF111827,
                                                                    ),
                                                            ),
                                                          ),
                                                          if (v.vendorNumber !=
                                                              null) ...[
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '| ${v.vendorNumber}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    isSelected ||
                                                                        isHovered
                                                                    ? Colors
                                                                          .white
                                                                          .withValues(
                                                                            alpha:
                                                                                0.8,
                                                                          )
                                                                    : const Color(
                                                                        0xFF6B7280,
                                                                      ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .email_outlined,
                                                            size: 13,
                                                            color:
                                                                isSelected ||
                                                                    isHovered
                                                                ? Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      )
                                                                : const Color(
                                                                    0xFF9CA3AF,
                                                                  ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              v.email ?? '',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    isSelected ||
                                                                        isHovered
                                                                    ? Colors
                                                                          .white
                                                                          .withValues(
                                                                            alpha:
                                                                                0.8,
                                                                          )
                                                                    : const Color(
                                                                        0xFF6B7280,
                                                                      ),
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    // New Vendor option
                                    InkWell(
                                      onTap: () {
                                        _removeVendorOverlay();
                                        context.push(
                                          AppRoutes.purchasesVendorsCreate,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(
                                                  alpha: 0.1,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                size: 16,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'New Vendor',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
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
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    overlay.insert(_vendorOverlayEntry!);
    setState(() {
      _vendorDropdownOpen = true;
    });
  }

  // ─────────────────────────────────────────── Main Fields ──────────────────

  Widget _buildMainFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: _labelFixedWidth,
              child: _buildLabel('Location'),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 320, child: _buildWarehouseDropdown()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            SizedBox(
              width: _labelFixedWidth,
              child: _buildLabel('Bill#', required: true),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 320, child: _buildTextField(_billNumberCtrl, '')),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            SizedBox(
              width: _labelFixedWidth,
              child: _buildLabel('Order Number'),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 320, child: _buildTextField(_orderNumberCtrl, '')),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            SizedBox(
              width: _labelFixedWidth,
              child: _buildLabel('Bill Date', required: true),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 320,
              child: _buildDateField(_billDateCtrl, 'dd-MM-yyyy'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            SizedBox(width: _labelFixedWidth, child: _buildLabel('Due Date')),
            const SizedBox(width: 12),
            SizedBox(
              width: 320,
              child: _buildDateField(_dueDateCtrl, '04-03-2026'),
            ),
            const SizedBox(width: 40),
            _buildLabel('Payment Terms'),
            const SizedBox(width: 12),
            SizedBox(width: 150, child: _buildPaymentTermsDropdown()),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentTermsDropdown() {
    return SizedBox(
      height: _fieldHeight,
      child: FormDropdown<String>(
        height: _fieldHeight,
        value: _paymentTerms,
        items: _paymentTermsList.map((t) => t['id'] as String).toList(),
        showSettings: true,
        settingsLabel: 'Configure Terms',
        onSettingsTap: _showConfigurePaymentTermsDialog,
        displayStringForValue: (id) {
          final term = _paymentTermsList.firstWhere(
            (t) => t['id'] == id,
            orElse: () => {'term_name': ''},
          );
          return term['term_name'] ?? '';
        },
        searchStringForValue: (id) {
          final term = _paymentTermsList.firstWhere(
            (t) => t['id'] == id,
            orElse: () => {'term_name': ''},
          );
          return term['term_name'] ?? '';
        },
        itemBuilder: (id, isSelected, isHovered) {
          final term = _paymentTermsList.firstWhere(
            (t) => t['id'] == id,
            orElse: () => {'term_name': '', 'number_of_days': 0},
          );
          return _buildPaymentTermRow(
            term['term_name'] ?? '',
            isSelected,
            isHovered,
          );
        },
        onChanged: (val) => setState(() => _paymentTerms = val),
      ),
    );
  }

  // ─────────────────────────────────────────── Reverse Charge ───────────────

  Widget _buildReverseChargeRow() {
    return Row(
      children: [
        const SizedBox(width: _labelFixedWidth + 12),
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: _reverseCharge,
            onChanged: (val) => setState(() => _reverseCharge = val ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: _primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(color: _fieldBorder, width: 1.5),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'This transaction is applicable for reverse charge',
          style: TextStyle(
            fontSize: 13,
            color: _textPrimary,
            fontWeight: FontWeight.w400,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────── Items Toolbar ──────────────

  Widget _buildItemsToolbarRow() {
    return Row(
      children: [
        // Warehouse Location
        SizedBox(
          width: 200,
          child: _buildWarehouseDropdown(),
        ),
        const SizedBox(width: 12),
        // At Transaction Level (discount)
        SizedBox(
          width: 200,
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: _textMuted),
              const SizedBox(width: 6),
              Expanded(child: _buildDiscountDropdown()),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Select Price List placeholder
        SizedBox(
          width: 180,
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined, size: 16, color: _textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: FormDropdown<String>(
                  value: null,
                  items: const [],
                  hint: 'Select Price List',
                  onChanged: (_) {},
                  height: _fieldHeight,
                  border: Border.all(color: _fieldBorder),
                  borderRadius: BorderRadius.circular(6),
                  fillColor: _cardBg,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // ─────────────────────────────────────────── Subject ─────────────────────

  Widget _buildSubjectRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _labelFixedWidth,
          child: Row(
            children: [
              _buildLabel('Subject'),
              const SizedBox(width: 6),
              const Icon(Icons.info_outline, size: 16, color: _textMuted),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 80,
            child: TextField(
              controller: _subjectCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
              decoration: InputDecoration(
                hintText: 'Enter a subject within 250 characters',
                hintStyle: const TextStyle(
                  color: _textMuted,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _fieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 300), // Push to match other fields roughly
      ],
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: _cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _primaryBlue, width: 1),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false, Color? textColor}) {
    final Color effectiveColor = textColor ?? (required ? _danger : _textMuted);
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13,
          color: effectiveColor,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        children: required
            ? const [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: _danger),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return SizedBox(
      height: _fieldHeight,
      child: TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 13),
        decoration: _getInputDecoration(hint),
      ),
    );
  }

  Widget _buildDateField(TextEditingController ctrl, String hint) {
    final fieldKey = GlobalKey();
    return SizedBox(
      height: _fieldHeight,
      child: TextField(
        key: fieldKey,
        controller: ctrl,
        style: const TextStyle(fontSize: 13),
        readOnly: true,
        onTap: () async {
          final picked = await ZerpaiDatePicker.show(
            context,
            initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(),
            targetKey: fieldKey,
          );
          if (picked != null) {
            ctrl.text = DateFormat('dd-MM-yyyy').format(picked);
          }
        },
        decoration: _getInputDecoration(hint),
      ),
    );
  }

  // ─────────────────────────────────────────── Item Table ──────────────────

  Widget _buildItemTable(
    ItemsState itemsState,
    List<coa.AccountNode> accountsRoots,
  ) {
    final mappedNodes = _mapNodes(accountsRoots);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Table Header Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              const Text(
                'Item Table',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: _primaryBlue,
                ),
                label: const Text(
                  'Bulk Actions',
                  style: TextStyle(
                    fontSize: 13,
                    color: _primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Table Container (No horizontal scroll)
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Items Group ---
              _buildItemHeaderRow(),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _lineItems.removeAt(oldIndex);
                    _lineItems.insert(newIndex, item);
                  });
                },
                children: _lineItems
                    .asMap()
                    .entries
                    .where((e) => !e.value.isLandedCost)
                    .map((entry) {
                      return _buildLineItemRow(
                        entry.key,
                        entry.value,
                        itemsState,
                        mappedNodes,
                      );
                    })
                    .toList(),
              ),

              // --- Landed Costs Group ---
              if (_lineItems.any((r) => r.isLandedCost)) ...[
                const SizedBox(height: 16),
                _buildLandedCostHeaderRow(),
                ..._lineItems
                    .asMap()
                    .entries
                    .where((e) => e.value.isLandedCost)
                    .map((entry) {
                      return _buildLineItemRow(
                        entry.key,
                        entry.value,
                        itemsState,
                        mappedNodes,
                      );
                    }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemHeaderRow() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: _sectionBg,
        border: Border(
          top: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('ITEM DETAILS', 400),
          _buildHeaderCell('ACCOUNT', 200),
          _buildHeaderCell('QUANTITY', 100, textAlign: TextAlign.right),
          _buildHeaderCell(
            'RATE',
            130,
            textAlign: TextAlign.right,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'RATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.calculate_outlined, size: 14, color: _textMuted),
              ],
            ),
          ),
          if (_discountType == 'At Line Item Level')
            _buildHeaderCell(
              'DISCOUNT',
              150,
              textAlign: TextAlign.right,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'DISCOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.discount_outlined, size: 14, color: _textMuted),
                ],
              ),
            ),
          _buildHeaderCell('TAX', 150),
          _buildHeaderCell(
            'CUSTOMER DETAILS',
            160,
            child: Row(
              children: [
                const Text(
                  'CUSTOMER DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderCell('AMOUNT', 120, textAlign: TextAlign.right),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String text,
    int flex, {
    TextAlign textAlign = TextAlign.left,
    Widget? child,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 40,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: _borderColor)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: textAlign == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child:
            child ??
            Text(
              text,
              textAlign: textAlign,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _textMuted,
                letterSpacing: 0.3,
              ),
            ),
      ),
    );
  }

  Widget _buildLandedCostHeaderRow() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: _sectionBg,
        border: Border(
          top: BorderSide(color: _borderColor),
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('LANDED COSTS', 400),
          _buildHeaderCell('ACCOUNT', 200),
          _buildHeaderCell('QUANTITY', 100, textAlign: TextAlign.right),
          _buildHeaderCell(
            'RATE',
            130,
            textAlign: TextAlign.right,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'RATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.calculate_outlined, size: 14, color: _textMuted),
              ],
            ),
          ),
          _buildHeaderCell('TAX', 150),
          _buildHeaderCell(
            'CUSTOMER DETAILS',
            160,
            child: const Row(
              children: [
                Text(
                  'CUSTOMER DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderCell('AMOUNT', 120, textAlign: TextAlign.right),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildWarehouseDropdown() {
    final items = {
      _warehouse,
      'ZABNIX PRIVATE LIMITED',
      'MAIN WAREHOUSE',
    }.toList();
    return FormDropdown<String>(
      value: _warehouse,
      items: items,
      displayStringForValue: (w) => w,
      hint: 'Select Warehouse',
      onChanged: (val) {
        if (val != null) setState(() => _warehouse = val);
      },
      height: _fieldHeight,
      border: Border.all(color: _fieldBorder),
      borderRadius: BorderRadius.circular(6),
      fillColor: _cardBg,
    );
  }

  Widget _buildDiscountDropdown() {
    return SizedBox(
      width: double.infinity,
      child: FormDropdown<String>(
        value: _discountType,
        items: const ['At Transaction Level', 'At Line Item Level'],
        onChanged: (val) {
          if (val != null) setState(() => _discountType = val);
        },
        height: _fieldHeight,
        showSearch: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        border: Border.all(color: _fieldBorder),
        borderRadius: BorderRadius.circular(6),
        fillColor: _cardBg,
        displayStringForValue: (val) => val,
        itemBuilder: (item, isSelected, isHovered) {
          final bool active = isHovered || isSelected;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: active ? _primaryBlue : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.discount_outlined,
                  size: 14,
                  color: active ? Colors.white : _textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: active ? Colors.white : _textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, size: 16, color: Colors.white),
              ],
            ),
          );
        },
        listBuilder: (items, itemBuilder) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Text(
                    'Discount Type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _textMuted,
                    ),
                  ),
                ),
                ...items.map((i) => itemBuilder(i)),
              ],
            ),
          );
        },
      ),
    );
  }


  void _showItemSearchOverlay(
    _BillLineItemRow row,
    List<Item> filteredItems,
    double targetWidth,
  ) {
    _itemOverlayEntry?.remove();
    final overlay = Overlay.of(context);
    final double dropdownWidth = targetWidth;

    _itemOverlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: row.layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: TapRegion(
              onTapOutside: (_) => _removeItemOverlay(),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(6),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: Container(
                  width: dropdownWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 350),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: Color(0xFFF3F4F6),
                          ),
                          itemBuilder: (context, i) {
                            final item = filteredItems[i];
                            final isHighlighted = i == _highlightedIndex;
                            final isSelected = item.id == row.itemId;
                            final stock = item.stockOnHand ?? 0.0;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  row.itemId = item.id;
                                  row.itemName = item.productName;
                                  row.itemNameCtrl.text = item.productName;
                                  row.descriptionCtrl.text =
                                      item.purchaseDescription ?? '';
                                  row.hsnCode = item.hsnCode;
                                  row.hsnCtrl.text = item.hsnCode ?? '';
                                  row.itemCode = item.itemCode;
                                  row.stockAvailable = item.stockOnHand;
                                  row.itemType = item.type;
                                  row.itemImageUrl = item.primaryImageUrl;

                                  if (item.costPrice != null) {
                                    row.rateCtrl.text = item.costPrice!
                                        .toStringAsFixed(2);
                                  }
                                  if (item.ptr != null) {
                                    row.ptrCtrl.text = item.ptr!
                                        .toStringAsFixed(2);
                                  }

                                  // Reset and fetch batches immediately
                                  row.batch = null;
                                  row.batchCtrl.clear();
                                  row.expiry = null;
                                  row.expiryCtrl.clear();

                                  if (item.id != null) {
                                    ref.invalidate(
                                      itemBatchesProvider(item.id!),
                                    );
                                    // Pre-fetch batches so they are ready
                                    ref.read(
                                      itemBatchesProvider(item.id!).future,
                                    );
                                  }

                                  _highlightedIndex = -1;
                                });
                                _removeItemOverlay();
                              },
                              onHover: (hovering) {
                                if (hovering && _highlightedIndex != i) {
                                  setState(() {
                                    _highlightedIndex = i;
                                  });
                                  _itemOverlayEntry?.markNeedsBuild();
                                }
                              },
                              hoverColor: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? const Color(0xFF3B82F6)
                                      : isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.productName.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isHighlighted
                                                  ? Colors.white
                                                  : isSelected
                                                  ? const Color(0xFF1D4ED8)
                                                  : const Color(0xFF374151),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Rate: ₹${(item.costPrice ?? 0.0).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isHighlighted
                                                  ? Colors.white.withValues(
                                                      alpha: 0.9,
                                                    )
                                                  : isSelected
                                                  ? const Color(
                                                      0xFF1D4ED8,
                                                    ).withValues(alpha: 0.8)
                                                  : const Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'STOCK',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                            color: isHighlighted
                                                ? Colors.white.withValues(
                                                    alpha: 0.7,
                                                  )
                                                : isSelected
                                                ? const Color(
                                                    0xFF1D4ED8,
                                                  ).withValues(alpha: 0.5)
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                        Text(
                                          stock.toStringAsFixed(2),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isHighlighted
                                                ? Colors.white
                                                : isSelected
                                                ? const Color(0xFF1D4ED8)
                                                : const Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      InkWell(
                        onTap: () {
                          _removeItemOverlay();
                          context.push(AppRoutes.itemsCreate);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add_circle_outline,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Add New Item',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
      },
    );

    overlay.insert(_itemOverlayEntry!);
  }

  String? _getTaxSubtitle(String tax) {
    if (tax == 'Non-GST Supply') {
      return 'Supplies which do not come under GST such as petroleum products and liquor.';
    }
    if (tax == 'Out of Scope') {
      return 'Supplies on which you don\'t charge any GST or include them in the returns.';
    }
    return null;
  }

  void _showTaxOverlay({
    required LayerLink link,
    required TextEditingController searchCtrl,
    required FocusNode focusNode,
    required List<String> options,
    required Function(String) onSelected,
    String? selectedValue,
    double? width,
  }) {
    _removeTaxOverlay();

    final overlay = Overlay.of(context);
    final double effectiveWidth = _resolveOverlayWidth(
      minWidth: 320,
      preferredWidth: width,
    );

    _taxOverlayEntry = OverlayEntry(
      builder: (context) {
        final query = searchCtrl.text.toLowerCase();
        final filteredOptions = options.where((t) {
          return t.toLowerCase().contains(query);
        }).toList();

        return CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: TapRegion(
              onTapOutside: (_) => _removeTaxOverlay(),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(6),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: Container(
                  width: effectiveWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: searchCtrl,
                            focusNode: focusNode,
                            autofocus: true,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search tax...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 16,
                                color: Color(0xFF9CA3AF),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              _taxOverlayEntry?.markNeedsBuild();
                            },
                          ),
                        ),
                      ),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 350),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: filteredOptions.length,
                            itemBuilder: (context, i) {
                              final tax = filteredOptions[i];
                              final subtitle = _getTaxSubtitle(tax);
                              final isHighlighted = _highlightedTaxIndex == i;
                              final isSelected = tax == selectedValue;

                              bool showGroupHeader = false;
                              if (tax.startsWith('GST')) {
                                final firstGst = filteredOptions.firstWhere(
                                  (t) => t.startsWith('GST'),
                                  orElse: () => '',
                                );
                                if (tax == firstGst) {
                                  showGroupHeader = true;
                                }
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (showGroupHeader)
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        4,
                                      ),
                                      child: Text(
                                        'TAX GROUPS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF9CA3AF),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  InkWell(
                                    onTap: () {
                                      onSelected(tax);
                                      searchCtrl.clear();
                                      _removeTaxOverlay();
                                    },
                                    onHover: (hovering) {
                                      if (hovering) {
                                        setState(() {
                                          _highlightedTaxIndex = i;
                                        });
                                        _taxOverlayEntry?.markNeedsBuild();
                                      }
                                    },
                                    hoverColor: Colors.transparent,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isHighlighted
                                            ? const Color(0xFF3B82F6)
                                            : isSelected
                                            ? const Color(0xFFEFF6FF)
                                            : Colors.transparent,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tax,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isHighlighted
                                                  ? Colors.white
                                                  : isSelected
                                                  ? const Color(0xFF1D4ED8)
                                                  : const Color(0xFF374151),
                                            ),
                                          ),
                                          if (subtitle != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              subtitle,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isHighlighted
                                                    ? Colors.white.withValues(
                                                        alpha: 0.9,
                                                      )
                                                    : isSelected
                                                    ? const Color(
                                                        0xFF1D4ED8,
                                                      ).withValues(alpha: 0.8)
                                                    : const Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      InkWell(
                        onTap: () {
                          _removeTaxOverlay();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.add_circle_outline,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Create New Tax',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
      },
    );

    overlay.insert(_taxOverlayEntry!);
  }

  void _showCustomerOverlay({
    required LayerLink link,
    required TextEditingController searchCtrl,
    required FocusNode focusNode,
    required List<SalesCustomer> customers,
    required Function(SalesCustomer) onSelected,
    String? selectedValue,
    double? width,
  }) {
    _removeCustomerOverlay();

    final overlay = Overlay.of(context);
    final double effectiveWidth = _resolveOverlayWidth(
      minWidth: 350,
      preferredWidth: width,
    );

    _customerOverlayEntry = OverlayEntry(
      builder: (context) {
        final query = searchCtrl.text.toLowerCase();
        final filteredCustomers = customers.where((c) {
          return c.displayName.toLowerCase().contains(query);
        }).toList();

        return CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: TapRegion(
              onTapOutside: (_) => _removeCustomerOverlay(),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(6),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: Container(
                  width: effectiveWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: searchCtrl,
                            focusNode: focusNode,
                            autofocus: true,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search customer...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 16,
                                color: Color(0xFF9CA3AF),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              _customerOverlayEntry?.markNeedsBuild();
                            },
                          ),
                        ),
                      ),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 350),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, i) {
                              final customer = filteredCustomers[i];
                              final isHighlighted =
                                  _highlightedCustomerIndex == i;
                              final isSelected = customer.id == selectedValue;

                              return InkWell(
                                onTap: () {
                                  onSelected(customer);
                                  searchCtrl.clear();
                                  _removeCustomerOverlay();
                                },
                                onHover: (hovering) {
                                  if (hovering &&
                                      _highlightedCustomerIndex != i) {
                                    setState(() {
                                      _highlightedCustomerIndex = i;
                                    });
                                    _customerOverlayEntry?.markNeedsBuild();
                                  }
                                },
                                hoverColor: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHighlighted
                                        ? const Color(0xFF3B82F6)
                                        : isSelected
                                        ? const Color(0xFFEFF6FF)
                                        : Colors.transparent,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.displayName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isHighlighted
                                              ? Colors.white
                                              : isSelected
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Code: ${customer.customerNumber}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isHighlighted
                                              ? Colors.white.withValues(
                                                  alpha: 0.9,
                                                )
                                              : isSelected
                                              ? const Color(
                                                  0xFF1D4ED8,
                                                ).withValues(alpha: 0.8)
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
      },
    );

    overlay.insert(_customerOverlayEntry!);
  }

  void _showLineItemMoreOverlay(int index, _BillLineItemRow row) {
    _removeMoreOverlay();
    final overlay = Overlay.of(context);

    _moreOverlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: row.moreLayerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topRight,
            child: TapRegion(
              onTapOutside: (_) => _removeMoreOverlay(),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show Additional Information (Highlighted)
                      InkWell(
                        onTap: () {
                          setState(() {
                            row.showAdditionalInfo = !row.showAdditionalInfo;
                          });
                          _removeMoreOverlay();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            row.showAdditionalInfo
                                ? 'Hide Additional Information'
                                : 'Show Additional Information',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      _buildMoreOption(
                        label: 'Clone',
                        onTap: () {
                          setState(() {
                            _lineItems.insert(index + 1, row.clone());
                          });
                          _removeMoreOverlay();
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      _buildMoreOption(
                        label: 'Insert New Row',
                        onTap: () {
                          setState(() {
                            _lineItems.insert(index + 1, _BillLineItemRow());
                          });
                          _removeMoreOverlay();
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      _buildMoreOption(
                        label: 'Insert Items in Bulk',
                        onTap: () {
                          // Bulk insert logic would go here
                          _removeMoreOverlay();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_moreOverlayEntry!);
    setState(() {
      row.isMoreDropdownOpen = true;
    });
  }

  Widget _buildMoreOption({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildLineItemRow(
    int index,
    _BillLineItemRow row,
    ItemsState itemsState,
    List<shared.AccountNode> mappedNodes,
  ) {
    // Filter by type
    final typeFilteredItems = itemsState.items.where((item) {
      return item.type.toLowerCase() ==
          (row.isLandedCost ? 'service' : 'goods');
    }).toList();

    final query = row.itemNameCtrl.text.toLowerCase();
    final filteredItems = query.isEmpty
        ? typeFilteredItems
        : typeFilteredItems.where((item) {
            return item.productName.toLowerCase().contains(query) ||
                item.itemCode.toLowerCase().contains(query);
          }).toList();

    final bool isExpanded = row.itemId != null || row.showAdditionalInfo;
    final bool showBatch = isExpanded && row.showAdditionalInfo;
    final double expandedHeight = showBatch ? 250 : 165;
    const double compactHeight = 60;
    final double cellHeight = isExpanded ? expandedHeight : compactHeight;

    return Container(
      key: ValueKey(row),
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Details
          _buildGridCell(
            flex: 400,
            cellHeight: cellHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag Indicator and Image
                Row(
                  children: [
                    const Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: Color(0xFFD1D5DB),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: row.itemId != null ? 48 : 36,
                      height: row.itemId != null ? 48 : 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: row.itemImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.network(
                                row.itemImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_outlined,
                                  size: 18,
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.image_outlined,
                              size: 18,
                              color: Color(0xFFD1D5DB),
                            ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header: Name + Icons
                      Row(
                        children: [
                          Expanded(
                            child: CompositedTransformTarget(
                              link: row.layerLink,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return InkWell(
                                    onTap: () {
                                      if (row.isDropdownOpen) {
                                        _removeItemOverlay();
                                        return;
                                      }
                                      _removeItemOverlay();
                                      setState(() {
                                        row.isDropdownOpen = true;
                                        _highlightedIndex = -1;
                                      });
                                      _showItemSearchOverlay(
                                        row,
                                        filteredItems,
                                        constraints.maxWidth,
                                      );
                                    },
                                    child: Text(
                                      row.itemName ??
                                          'Type or click to select an item.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: row.itemId != null
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: row.itemName == null
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF1F2937),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          if (row.itemId != null) ...[
                            IconButton(
                              onPressed: () =>
                                  _showLineItemMoreOverlay(index, row),
                              icon: const Icon(Icons.more_horiz, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  row.itemId = null;
                                  row.itemName = null;
                                  row.itemNameCtrl.clear();
                                  row.itemCode = null;
                                });
                              },
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: const Color(0xFF9CA3AF),
                            ),
                          ],
                        ],
                      ),
                      if (row.itemId != null) ...[
                        // SKU
                        if (row.itemCode != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'SKU: ${row.itemCode}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textMuted,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (row.itemType ?? 'goods').toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Description
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: TextField(
                            controller: row.descriptionCtrl,
                            focusNode: row.descriptionFocus,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4B5563),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Add a description to your item',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // HSN Code + batch toggle
                        Row(
                          children: [
                            const Text(
                              'HSN Code: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: _textMuted,
                                fontFamily: 'Inter',
                              ),
                            ),
                            CompositedTransformTarget(
                              link: row.hsnLayerLink,
                              child: GestureDetector(
                                onTap: () => _showHsnEditOverlay(row),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        row.hsnCode ?? 'Select',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Batch/pharma fields — shown via "Show Additional Information"
                        if (row.showAdditionalInfo) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _buildBatchSelector(row)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildCompactDateField(
                                  context,
                                  row.expiryCtrl,
                                  focusNode: row.expiryFocus,
                                  hint: 'Expiry MM/YY',
                                  onChanged: (v) =>
                                      setState(() => row.expiry = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactTextField(
                                  row.unitPackCtrl,
                                  hint: 'Pack',
                                  focusNode: row.unitPackFocus,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildCompactNumberField(
                                  row.mrpCtrl,
                                  focusNode: row.mrpFocus,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildCompactNumberField(
                                  row.ptrCtrl,
                                  focusNode: row.ptrFocus,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Account
          _buildGridCell(
            flex: 200,
            cellHeight: cellHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            alignment: isExpanded ? Alignment.topCenter : Alignment.center,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InCellWrapper(
                  focusNode: row.accountFocus,
                  child: AccountTreeDropdown(
                    value: row.accountId,
                    nodes: mappedNodes,
                    height: 40,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.transparent),
                    onChanged: (v) {
                      setState(() {
                        row.accountId = v;
                        row.accountName = _findName(mappedNodes, v);
                      });
                    },
                    hint: 'Account',
                  ),
                );
              },
            ),
          ),
          // Quantity
          _buildGridCell(
            flex: 100,
            cellHeight: cellHeight,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                _buildCompactNumberField(
                  row.quantityCtrl,
                  focusNode: row.qtyFocus,
                  onChanged: (_) => setState(() {}),
                ),
                if (isExpanded && row.stockAvailable != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Avl: ${row.stockAvailable}',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ],
            ),
          ),
          // Rate
          _buildGridCell(
            flex: 130,
            cellHeight: cellHeight,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                _buildCompactNumberField(
                  row.rateCtrl,
                  focusNode: row.rateFocus,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: const Icon(
                    Icons.calculate_outlined,
                    size: 14,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Discount
          if (_discountType == 'At Line Item Level')
            _buildGridCell(
              flex: 150,
              cellHeight: cellHeight,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactNumberField(
                          row.discountCtrl,
                          focusNode: row.discountFocus,
                          onChanged: (_) => setState(() {}),
                          prefixIcon: const Icon(
                            Icons.discount_outlined,
                            size: 14,
                            color: _textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildLineItemDiscountTypeSelector(row),
                    ],
                  ),
                ],
              ),
            ),
          // Tax
          _buildGridCell(
            flex: 150,
            cellHeight: cellHeight,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                CompositedTransformTarget(
                  link: row.taxLayerLink,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return InCellWrapper(
                        focusNode: row.taxSearchFocus,
                        child: InkWell(
                          onTap: () {
                            final itemsState = ref.read(
                              itemsControllerProvider,
                            );
                            final taxGroups = itemsState.taxGroups;
                            final List<String> options = [
                              ..._standardTaxOptions,
                              ...taxGroups.map((tg) {
                                final rateStr = tg.taxRate % 1 == 0
                                    ? tg.taxRate.toInt().toString()
                                    : tg.taxRate.toString();
                                return '${tg.taxName} [$rateStr%]';
                              }),
                            ];

                            _showTaxOverlay(
                              link: row.taxLayerLink,
                              searchCtrl: row.taxSearchCtrl,
                              focusNode: row.taxSearchFocus,
                              options: options,
                              selectedValue: row.taxName,
                              onSelected: (val) =>
                                  setState(() => row.taxName = val),
                              width: constraints.maxWidth,
                            );
                          },
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    row.taxName ?? 'Tax',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: row.taxName == null
                                          ? _textMuted
                                          : _textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 14,
                                  color: _textMuted,
                                ),
                              ],
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
          // Customer Details (always visible)
          _buildGridCell(
            flex: 160,
            cellHeight: cellHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            alignment: isExpanded ? Alignment.topCenter : Alignment.center,
            child: CompositedTransformTarget(
              link: row.customerLayerLink,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return InCellWrapper(
                    focusNode: row.customerSearchFocus,
                    child: InkWell(
                      onTap: () {
                        final customersAsync = ref.read(
                          salesCustomersProvider,
                        );
                        customersAsync.whenData((customers) {
                          _showCustomerOverlay(
                            link: row.customerLayerLink,
                            searchCtrl: row.customerSearchCtrl,
                            focusNode: row.customerSearchFocus,
                            customers: customers,
                            selectedValue: row.customerId,
                            onSelected: (val) {
                              setState(() {
                                row.customerId = val.id;
                                row.customerName = val.displayName;
                              });
                            },
                            width: constraints.maxWidth,
                          );
                        });
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.assignment_ind_outlined,
                              size: 14,
                              color: _textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                row.customerName ?? 'Select Customer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: row.customerName == null
                                      ? _textMuted
                                      : _textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 14,
                              color: _textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Amount
          _buildGridCell(
            flex: 120,
            cellHeight: cellHeight,
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: isExpanded ? 24 : 0,
            ),
            alignment: isExpanded ? Alignment.topRight : Alignment.centerRight,
            child: Text(
              row.amount.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 12,
                color: _textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Actions
          Container(
            width: 50,
            height: cellHeight,
            alignment: isExpanded ? Alignment.topCenter : Alignment.center,
            padding: EdgeInsets.only(top: isExpanded ? 24 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CompositedTransformTarget(
                  link: row.moreLayerLink,
                  child: InkWell(
                    onTap: () {
                      if (row.isMoreDropdownOpen) {
                        _removeMoreOverlay();
                      } else {
                        _showLineItemMoreOverlay(index, row);
                      }
                    },
                    child: Icon(
                      Icons.more_vert,
                      size: 14,
                      color: row.isMoreDropdownOpen
                          ? _primaryBlue
                          : _fieldBorder,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: () {
                    if (_lineItems.length > 1) {
                      setState(() => _lineItems.removeAt(index));
                    }
                  },
                  child: const Icon(Icons.close, size: 16, color: _danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchSelector(_BillLineItemRow row) {
    final focusNode = row.batchFocus;
    if (row.itemId == null) {
      return _buildCompactTextField(
        row.batchCtrl,
        hint: 'Batch#',
        focusNode: focusNode,
        onChanged: (_) => setState(() {}),
      );
    }

    return ref
        .watch(itemBatchesProvider(row.itemId!))
        .when(
          data: (batches) {
            final batchMap = {for (var b in batches) b.batchReference: b};
            return InCellWrapper(
              focusNode: focusNode,
              child: SizedBox(
                height: 36,
                child: FormDropdown<String>(
                  value: row.batchCtrl.text.isEmpty ? null : row.batchCtrl.text,
                  items: batches.map((b) => b.batchReference).toList(),
                  hint: 'Batch#',
                  height: 36,
                  border: Border.all(color: Colors.transparent),
                  fillColor: Colors.transparent,
                  allowCustomValue: true,
                  displayStringForValue: (val) => val,
                  onChanged: (val) {
                    setState(() {
                      if (val != null) {
                        row.batch = val;
                        row.batchCtrl.text = val;
                        final batch = batchMap[val];
                        if (batch != null) {
                          row.unitPack = batch.unitPack.toString();
                          row.unitPackCtrl.text = batch.unitPack.toString();
                          row.expiry = DateTime.tryParse(batch.expiryDate);
                          row.expiryCtrl.text = batch.expiryDate;
                        }
                      } else {
                        row.batch = null;
                        row.batchCtrl.clear();
                        row.unitPack = null;
                        row.unitPackCtrl.clear();
                        row.expiry = null;
                        row.expiryCtrl.clear();
                      }
                    });
                  },
                ),
              ),
            );
          },
          loading: () => const Skeletonizer(
            ignoreContainers: true,
            enabled: true,
            child: SizedBox(
              height: 36,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ),
          error: (e, _) => Text("Error: $e"),
        );
  }

  List<shared.AccountNode> _mapNodes(List<coa.AccountNode> nodes) {
    final List<coa.AccountNode> flatAccounts = <coa.AccountNode>[];

    void collect(List<coa.AccountNode> source) {
      for (final account in source) {
        flatAccounts.add(account);
        if (account.children.isNotEmpty) {
          collect(account.children);
        }
      }
    }

    collect(nodes);

    final byId = <String, coa.AccountNode>{};
    for (final account in flatAccounts) {
      byId.putIfAbsent(account.id, () => account);
    }

    final grouped = <String, List<shared.AccountNode>>{};
    final seenWithinType = <String>{};

    String displayNameFor(coa.AccountNode account) {
      final user = account.userAccountName.trim();
      final system = account.systemAccountName.trim();
      final base = user.isNotEmpty
          ? user
          : (system.isNotEmpty ? system : account.name.trim());

      if (user.isNotEmpty &&
          system.isNotEmpty &&
          user.toLowerCase() != system.toLowerCase()) {
        return '$base ($system)';
      }

      return base;
    }

    for (final account in byId.values) {
      final type = account.accountType.trim().isEmpty
          ? 'Other'
          : account.accountType.trim();
      final label = displayNameFor(account);
      final dedupeKey = '$type|${label.toLowerCase()}';
      if (seenWithinType.contains(dedupeKey)) {
        continue;
      }
      seenWithinType.add(dedupeKey);

      grouped
          .putIfAbsent(type, () => <shared.AccountNode>[])
          .add(
            shared.AccountNode(id: account.id, name: label, selectable: true),
          );
    }

    final sortedTypes = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return sortedTypes.map((type) {
      final children = grouped[type]!
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return shared.AccountNode(
        id: '__account_type__$type',
        name: type,
        selectable: false,
        children: children,
      );
    }).toList();
  }

  String? _findName(List<shared.AccountNode> nodes, String? id) {
    if (id == null) return null;
    for (final node in nodes) {
      if (node.id == id) return node.name;
      final found = _findName(node.children, id);
      if (found != null) return found;
    }
    return null;
  }

  Widget _buildLineItemDiscountTypeSelector(_BillLineItemRow row) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 32),
      initialValue: row.discountType,
      constraints: const BoxConstraints(minWidth: 44, maxWidth: 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFF3F4F6)),
      ),
      color: Colors.white,
      elevation: 4,
      onSelected: (val) => setState(() => row.discountType = val),
      child: InCellWrapper(
        child: Container(
          width: 38,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                row.discountType,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: '%',
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          height: 40,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: row.discountType == '%'
                  ? const Color(0xFF3B82F6)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: row.discountType == '%'
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Text(
              '%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: row.discountType == '%'
                    ? Colors.white
                    : const Color(0xFF374151),
              ),
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: '₹',
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          height: 40,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: row.discountType == '₹'
                  ? const Color(0xFF3B82F6)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: row.discountType == '₹'
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Text(
              '₹',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: row.discountType == '₹'
                    ? Colors.white
                    : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left side: Reporting Tags + Add buttons
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reporting Tags chip
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textMuted,
                  side: const BorderSide(color: _fieldBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                icon: const Icon(Icons.label_outline, size: 14),
                label: const Text(
                  'Reporting Tags',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildAddRowButton(),
                  const SizedBox(width: 12),
                  _buildCustomAddButton(
                    label: 'Add Landed Cost',
                    icon: Icons.add_circle,
                    onTap: () => setState(
                      () =>
                          _lineItems.add(_BillLineItemRow(isLandedCost: true)),
                    ),
                    showInfo: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        // Right side: Totals box
        Container(
          width: 420,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Column(
            children: [
              _buildTotalRow(
                'Sub Total',
                _discountType == 'At Line Item Level'
                    ? _grossAmount
                    : _subTotal,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Discount',
                      style: TextStyle(fontSize: 13, color: _textMuted),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _discountPercentCtrl,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _discountPercent = double.tryParse(val) ?? 0;
                              });
                            },
                            style: const TextStyle(fontSize: 13),
                            decoration: _getInputDecoration('0'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 32,
                          height: _fieldHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _sectionBg,
                            border: Border.all(color: _fieldBorder),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '%',
                            style: TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _discountAmount == 0
                          ? '0.00'
                          : '-${_discountAmount.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        RadioGroup<bool>(
                          groupValue: _isTdsSelected,
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _isTdsSelected = val);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<bool>(
                                value: true,
                                activeColor: _primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'TDS',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Radio<bool>(
                                value: false,
                                activeColor: _primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'TCS',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FormDropdown<String>(
                            height: 36,
                            value: _selectedTotalsTax,
                            hint: 'Select a Tax',
                            items: {
                              if (_selectedTotalsTax != null)
                                _selectedTotalsTax!,
                              ..._standardTaxOptions,
                            }.toList(),
                            onChanged: (val) {
                              setState(() => _selectedTotalsTax = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _taxAmount == 0 ? '-0.00' : _taxAmount.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _adjustmentLabelCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: _getInputDecoration('Adjustment'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _adjustmentAmountCtrl,
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _adjustment = double.tryParse(val) ?? 0;
                        });
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: _getInputDecoration('0.00'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 18,
                    child: Icon(
                      Icons.info_outline,
                      size: 14,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text(
                      _adjustment == 0
                          ? '0.00'
                          : _adjustment.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: _borderColor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    _total.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _textMuted)),
          Text(
            amount.abs().toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: amount < 0 ? _danger : _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTermsAndAttachments() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: _getInputDecoration(''),
                ),
                const SizedBox(height: 6),
                const Text(
                  'It will not be shown in PDF',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attach File(s) to Bill',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textPrimary,
                        side: const BorderSide(color: _fieldBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      icon: const Icon(Icons.upload_outlined, size: 16),
                      label: const Text(
                        'Upload File',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: _fieldHeight,
                      width: 32,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        border: Border.all(color: _fieldBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'You can upload a maximum of 5 files, 10MB each',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        border: const Border(top: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              side: const BorderSide(color: _fieldBorder),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('Save as Draft'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save as Open'),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              side: const BorderSide(color: _fieldBorder),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          const Spacer(),
          const Text(
            'PDF Template: ',
            style: TextStyle(fontSize: 12, color: _textMuted),
          ),
          const Text(
            '\'Standard Template\' ',
            style: TextStyle(fontSize: 12, color: _textPrimary),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Change',
              style: TextStyle(fontSize: 12, color: _primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRowButton() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _lineItems.add(_BillLineItemRow())),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFF0F5FF),
            foregroundColor: _primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          icon: const Icon(Icons.add_circle, size: 16),
          label: const Text(
            'Add New Row',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          height: 36,
          width: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5FF),
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: _primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAddButton({
    String? label,
    IconData? icon,
    VoidCallback? onTap,
    bool? showInfo,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFF0F5FF),
        foregroundColor: _primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: Icon(icon ?? Icons.add_circle_outline, size: 16),
      label: Row(
        children: [
          Text(
            label ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (showInfo == true) ...[
            const SizedBox(width: 6),
            const Icon(Icons.info_outline, size: 14, color: _textMuted),
          ],
        ],
      ),
    );
  }

  Widget _buildGridCell({
    required int flex,
    required double cellHeight,
    EdgeInsetsGeometry? padding,
    AlignmentGeometry? alignment,
    required Widget child,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: cellHeight,
        padding: padding ?? EdgeInsets.zero,
        alignment: alignment,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: _borderColor)),
        ),
        child: child,
      ),
    );
  }


  Widget _buildCompactDateField(
    BuildContext context,
    TextEditingController controller, {
    String? hint,
    FocusNode? focusNode,
    void Function(DateTime?)? onChanged,
    Widget? prefixIcon,
  }) {
    final fieldKey = GlobalKey();
    return InCellWrapper(
      focusNode: focusNode,
      child: TextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        readOnly: true,
        style: const TextStyle(fontSize: 12),
        onTap: () async {
          final picked = await ZerpaiDatePicker.show(
            context,
            initialDate: DateTime.now(),
            targetKey: fieldKey,
          );
          if (picked != null) {
            controller.text = DateFormat('MM/yy').format(picked);
            if (onChanged != null) onChanged(picked);
          }
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          prefixIcon: prefixIcon,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCompactTextField(
    TextEditingController controller, {
    String? hint,
    FocusNode? focusNode,
    void Function(String)? onChanged,
    Widget? prefixIcon,
  }) {
    return InCellWrapper(
      focusNode: focusNode,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          prefixIcon: prefixIcon,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildCompactNumberField(
    TextEditingController controller, {
    FocusNode? focusNode,
    void Function(String)? onChanged,
    Widget? prefixIcon,
  }) {
    return InCellWrapper(
      focusNode: focusNode,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        focusNode: focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          prefixIcon: prefixIcon,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class InCellWrapper extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final bool isDropdownOpen;

  const InCellWrapper({
    super.key,
    required this.child,
    this.focusNode,
    this.isDropdownOpen = false,
  });

  @override
  State<InCellWrapper> createState() => _InCellWrapperState();
}

class _InCellWrapperState extends State<InCellWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget buildShell(bool isFocused) {
      final bool isActive = isFocused || widget.isDropdownOpen;

      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          decoration: BoxDecoration(
            color: (isActive || _isHovered) ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: (isActive || _isHovered)
                ? Border.all(
                    color: isActive
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE1E5EE),
                    width: isActive ? 1.5 : 1.0,
                  )
                : Border.all(color: Colors.transparent, width: 0),
          ),
          child: widget.child,
        ),
      );
    }

    final focusNode = widget.focusNode;
    if (focusNode == null) {
      return buildShell(false);
    }

    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        return buildShell(focusNode.hasFocus);
      },
    );
  }
}
