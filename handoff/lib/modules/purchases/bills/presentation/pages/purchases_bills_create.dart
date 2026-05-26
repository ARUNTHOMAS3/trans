// ignore_for_file: unused_element, unused_element_parameter, unused_field, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:zerpai_erp/modules/purchases/bills/providers/purchases_bills_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_state.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart'
    as coa;
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/shared/models/account_node.dart' as shared;
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/items_stock_providers.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:flutter_svg/flutter_svg.dart';


// ── Zoho-style Colors ────────────────────────────────────────────────────────
const Color _bgWhite = Color(0xFFFFFFFF);
const Color _sectionBg = Color(0xFFF9FAFB);
const Color _borderColor = Color(0xFFE5E7EB);
const Color _textPrimary = Color(0xFF111827);
const Color _textMuted = Color(0xFF6B7280);
const Color _primaryBlue = Color(0xFF2563EB);
const Color _linkBlue = Color(0xFF3B82F6);
const Color _primaryGreen = Color(0xFF059669);
const Color _dangerRed = Color(0xFFEF4444);
const Color _fieldBorder = Color(0xFFD1D5DB);
const Color _labelColor = Color(0xFF374151);
const Color _hintColor = Color(0xFF9CA3AF);
const Color _cardBg = Color(0xFFFFFFFF);

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
  double taxRate = 0; // Add taxRate double field
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

  // Price list / account popover links
  String? priceListId;
  final LayerLink priceListLink = LayerLink();
  final LayerLink accountLink = LayerLink();
  final LayerLink discountTypeLink = LayerLink();

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
    newRow.taxRate = taxRate;
    newRow.customerId = customerId;
    newRow.customerName = customerName;
    newRow.discountCtrl.text = discountCtrl.text;
    newRow.discountType = discountType;
    newRow.showAdditionalInfo = showAdditionalInfo;
    newRow.priceListId = priceListId;
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
  static const double _fieldHeight = 32;

  bool get _isKeralaPlaceOfSupply {
    final pos = (_destinationOfSupply ?? _sourceOfSupply ?? '').toLowerCase();
    return pos.contains('[kl]') || pos.contains('kerala');
  }

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
  OverlayEntry? _addRowDropdownOverlay;
  final LayerLink _addRowDropdownLink = LayerLink();
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
    _vendorOverlayEntry?.remove();
    _vendorOverlayEntry = null;
    _itemOverlayEntry?.remove();
    _itemOverlayEntry = null;
    _hsnOverlayEntry?.remove();
    _hsnOverlayEntry = null;
    _sidebarOverlayEntry?.remove();
    _sidebarOverlayEntry = null;
    _addRowDropdownOverlay?.remove();
    _addRowDropdownOverlay = null;
    _moreOverlayEntry?.remove();
    _moreOverlayEntry = null;
    _taxOverlayEntry?.remove();
    _taxOverlayEntry = null;
    _customerOverlayEntry?.remove();
    _customerOverlayEntry = null;

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
    _itemDetailsSearchCtrl.dispose();
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
  bool _bulkMode = false;
  final Set<int> _selectedRows = <int>{};
  bool _showStockInfo = false;
  bool _showRecentTransactions = false;
  bool _showPriceList = false;
  final Set<int> _hiddenDetails = <int>{};
  OverlayEntry? _discountOverlay;
  OverlayEntry? _accountOverlay;
  OverlayEntry? _itemMenuOverlay;

  // Search/pricing variables
  bool _showSearchItemDetails = false;
  String _itemDetailsSearchQuery = '';
  final TextEditingController _itemDetailsSearchCtrl = TextEditingController();
  String? _selectedPriceListId;
  shared.AccountNode? _selectedPopupAccount;
  String _stockView = 'availableForSale'; // 'stockOnHand' | 'availableForSale'

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
    // Item-level GST amount (sum of line taxes). Display split handled in UI.
    double total = 0;
    for (final row in _lineItems) {
      final rate = row.taxRate;
      if (rate <= 0) continue;
      total += (row.amount * rate / 100);
    }
    return total;
  }

  double get _total {
    if (_discountType == 'At Line Item Level') {
      return _subTotal + _taxAmount + _adjustment;
    }
    return _subTotal - _discountAmount + _taxAmount + _adjustment;
  }

  DateTime? _parseUiDate(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    try {
      return DateFormat('dd-MM-yyyy').parseStrict(v);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveBill({required String status}) async {
    if (_selectedVendor == null) {
      AppLogger.error('Cannot save bill: vendor missing', module: 'purchases');
      return;
    }

    final billDate = _parseUiDate(_billDateCtrl.text) ?? DateTime.now();
    final dueDate = _parseUiDate(_dueDateCtrl.text);
    final placeOfSupply = _destinationOfSupply ?? _sourceOfSupply;

    final lineItems = _lineItems
        .where((r) => r.itemId != null && (r.itemId ?? '').isNotEmpty)
        .map((r) => r.toModel())
        .toList();

    if (_billNumberCtrl.text.trim().isEmpty) {
      AppLogger.error('Cannot save bill: bill number missing', module: 'purchases');
      return;
    }
    if (lineItems.isEmpty) {
      AppLogger.error('Cannot save bill: no line items', module: 'purchases');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bill = PurchasesBill(
        id: '',
        billNumber: _billNumberCtrl.text.trim(),
        vendorId: _selectedVendor!.id,
        vendorName: _selectedVendor!.displayName,
        vendorNumber: _selectedVendor!.vendorNumber,
        placeOfSupply: placeOfSupply,
        orderNumber: _orderNumberCtrl.text.trim().isEmpty
            ? null
            : _orderNumberCtrl.text.trim(),
        billDate: billDate,
        dueDate: dueDate,
        paymentTerms: _paymentTerms,
        isReverseCharge: _reverseCharge,
        subject: _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
        taxLevel: 'item',
        lineItems: lineItems,
        subTotal: _subTotal,
        discountPercent: _discountPercent,
        discountAmount: _discountAmount,
        tdsOrTcs: _isTdsSelected ? 'tds' : 'tcs',
        taxId: null,
        taxName: null,
        taxAmount: _taxAmount,
        adjustmentLabel: _adjustmentLabelCtrl.text.trim().isEmpty
            ? 'Adjustment'
            : _adjustmentLabelCtrl.text.trim(),
        adjustment: _adjustment,
        total: _total,
        notes: _notesCtrl.text,
        status: status,
      );

      await ref.read(billsProvider.notifier).createBill(bill);

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.bills);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to save bill', error: e, module: 'purchases');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      footer: _buildFooter(),
      child: GestureDetector(
        onTap: _removeItemOverlay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            _buildHeader(),
            const SizedBox(height: 8),
            // ── FORM SECTION (Vendor + Info) ────────────────────────────
            _buildFormSection(vendorState),
            // ── Document Fields + Item Table + Totals ────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainFields(),
                  const SizedBox(height: 8),
                  _buildReverseChargeRow(),
                  const SizedBox(height: 16),
                  _buildSubjectRow(),
                  const SizedBox(height: 16),
                  // ── Warehouse / Discount / Pricing ─────────────────────
                  _zFormRow(
                    label: 'Warehouse',
                    child: SizedBox(
                      width: 300,
                      child: _buildWarehouseDropdown(),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ),
                  _zFormRow(
                    label: 'Discount',
                    child: SizedBox(
                      width: 300,
                      child: _buildDiscountDropdown(),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ),
                  const SizedBox(height: 16),
                  // ── Item Table ─────────────────────────────────────────
                  _buildItemTable(itemsState, accountsRoots),
                  const SizedBox(height: 16),
                  // ── Totals + Notes ─────────────────────────────────────
                  _buildTotalsSection(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // ── Notes/Terms/Attachments Banner ──────────────────────────
            _buildNotesTermsAndAttachments(),
            // ── Additional Fields Info ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Additional Fields: Start adding custom fields for your bills by going to Settings ⇒ Purchases ⇒ Bills.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _hintColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Header ───────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
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
              child: Icon(LucideIcons.x, size: 20, color: _hintColor),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────── Vendor Row ───────────────────

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM SECTION (Vendor + Address + GST + Supply — gray background)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFormSection(VendorState vendorState) {
    final hasVendor = _selectedVendor != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            border: Border.symmetric(
              horizontal: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildVendorSelectionRow(vendorState),
              ),
              if (hasVendor) _vendorInfoSection(),
            ],
          ),
        ),
        if (!hasVendor) const SizedBox(height: 20),
      ],
    );
  }

  // Vendor row: label + input constrained to left half only,
  Widget _buildVendorSelectionRow(VendorState vendorState) {
    final hasVendor = _selectedVendor != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _zFormRow(
            label: 'Vendor Name',
            isRequired: true,
            maxWidth: 850,
            gap: 12,
            child: Row(
              children: [
                _buildVendorDropdown(vendorState),
                _buildVendorSearchButton(),
                if (hasVendor) ...[
                  const SizedBox(width: 8),
                  // INR badge
                  Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.circleDollarSign,
                          size: 14,
                          color: Color(0xFF374151),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedVendor?.currency ?? 'INR',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Vendor card button on the right
        if (hasVendor)
          GestureDetector(
            onTap: _showVendorDetailsSidebar,
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedVendor!.displayName.length > 20
                        ? '${_selectedVendor!.displayName.substring(0, 20)}...'
                        : _selectedVendor!.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VENDOR INFO SECTION (Address, GST, Supply)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _vendorInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Indented section for addresses and GST
        Padding(
          padding: const EdgeInsets.only(left: 32 + 176),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildVendorAddressSection(), _buildGstTreatmentRow()],
          ),
        ),
        const SizedBox(height: 24),
        // Supply Details aligned with general form
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(children: [_buildSupplyRows()]),
        ),
      ],
    );
  }

  Widget _buildVendorDropdown(VendorState vendorState) {
    return SizedBox(
      width: 550,
      child: CompositedTransformTarget(
        link: _vendorLayerLink,
        child: GestureDetector(
          onTap: () {
            if (_vendorDropdownOpen) {
              _removeVendorOverlay();
            } else {
              _showVendorOverlay(vendorState, 550);
            }
          },
          child: Container(
            height: _fieldHeight,
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(
                color: _vendorDropdownOpen ? _primaryBlue : _borderColor,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _selectedVendor?.displayName ?? 'Select or add a vendor',
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
                      child: Icon(Icons.close, size: 16, color: _dangerRed),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVendorSearchButton() {
    return GestureDetector(
      onTap: _showAdvancedVendorSearchModal,
      child: Container(
        height: _fieldHeight,
        width: 32,
        decoration: const BoxDecoration(
          color: _primaryGreen,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: const Icon(LucideIcons.search, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildGstTreatmentRow() {
    if (_selectedVendor == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Row(
        children: [
          const SizedBox(width: 204),
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

  Widget _buildVendorAddressSection() {
    if (_selectedVendor == null) return const SizedBox.shrink();
    final address = _customBillingAddress ?? _selectedVendor!.billingAddress;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 204),
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
        _zFormRow(
          label: 'Source of Supply',
          isRequired: true,
          maxWidth: 760,
          child: SizedBox(
            width: 400,
            child: _buildStatesDropdown(
              _sourceOfSupply,
              (val) => setState(() => _sourceOfSupply = val),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _zFormRow(
          label: 'Destination of Supply',
          isRequired: true,
          maxWidth: 760,
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
              icon: const Icon(Icons.close, size: 20, color: _dangerRed),
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
                        icon: const Icon(Icons.close, color: _dangerRed),
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
            icon: const Icon(Icons.close, color: _dangerRed),
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
        _zFormRow(
          label: 'Bill#',
          isRequired: true,
          maxWidth: 600,
          child: SizedBox(width: 300, child: _zField(_billNumberCtrl)),
        ),
        const SizedBox(height: 16),
        _zFormRow(
          label: 'Order Number',
          maxWidth: 600,
          child: SizedBox(width: 300, child: _zField(_orderNumberCtrl)),
        ),
        const SizedBox(height: 16),
        _zFormRow(
          label: 'Bill Date',
          isRequired: true,
          maxWidth: 600,
          child: SizedBox(
            width: 300,
            child: _zDateField(
              controller: _billDateCtrl,
              targetKey: GlobalKey(),
              value: DateTime.tryParse(_billDateCtrl.text),
              onSelected: (date) {},
            ),
          ),
        ),
        const SizedBox(height: 16),
        _zFormRow(
          label: 'Due Date',
          maxWidth: 924,
          child: Row(
            children: [
              SizedBox(
                width: 396,
                child: _zDateField(
                  controller: _dueDateCtrl,
                  targetKey: GlobalKey(),
                  value: DateTime.tryParse(_dueDateCtrl.text),
                  onSelected: (date) {},
                ),
              ),
              const SizedBox(width: 32),
              const Text(
                'Payment Terms',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _labelColor,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: _buildPaymentTermsDropdown()),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.only(left: 204),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Checkbox(
              value: _reverseCharge,
              onChanged: (val) => setState(() => _reverseCharge = val ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              side: const BorderSide(color: _fieldBorder, width: 1.5),
            ),
          ),
          const SizedBox(width: 8),
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
      ),
    );
  }

  // ─────────────────────────────────────────── Items Toolbar ──────────────

  // ─────────────────────────────────────────── Subject ─────────────────────

  Widget _buildSubjectRow() {
    return _zFormRow(
      label: 'Subject',
      crossStart: true,
      maxWidth: 600,
      child: SizedBox(
        width: 300,
        height: 80,
        child: _HoverableField(
          builder: (isHovered) => TextField(
            controller: _subjectCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Enter a subject within 250 characters',
              hintStyle: const TextStyle(color: _hintColor),
              contentPadding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isHovered ? _linkBlue : _fieldBorder,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _linkBlue, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              filled: true,
              fillColor: _bgWhite,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Item Table ──────────────────

  Widget _buildItemTable(
    ItemsState itemsState,
    List<coa.AccountNode> accountsRoots,
  ) {
    final mappedNodes = _mapNodes(accountsRoots);
    final allItems = itemsState.items;
    final availableAccounts = mappedNodes;

    final activePriceLists = ref.watch(activePriceListsProvider)
        .where((pl) => pl.transactionType.toLowerCase() == 'purchase')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Table Title Row (outside the border) ──
        if (!_bulkMode)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
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
                      // Bulk Actions button
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _bulkMode = true;
                            _selectedRows.clear();
                          });
                        },
                        icon: const Icon(
                          LucideIcons.checkCircle,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        label: const Text(
                          'Bulk Actions',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Settings popup
                      Theme(
                        data: Theme.of(context).copyWith(
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 250),
                          offset: const Offset(0, 32),
                          elevation: 8,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val == 'stock') _showStockInfo = !_showStockInfo;
                              if (val == 'recent') _showRecentTransactions = !_showRecentTransactions;
                              if (val == 'pricelist') _showPriceList = !_showPriceList;
                              if (val == 'hide_all') {
                                final allHidden = _lineItems.asMap().keys.every((i) => _hiddenDetails.contains(i));
                                if (allHidden) {
                                  _hiddenDetails.clear();
                                } else {
                                  for (int i = 0; i < _lineItems.length; i++) {
                                    _hiddenDetails.add(i);
                                  }
                                }
                              }
                            });
                          },
                          itemBuilder: (_) {
                            final allHidden = _lineItems.asMap().keys.every((i) => _hiddenDetails.contains(i));
                            return [
                              PopupMenuItem(
                                value: 'stock',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  _showStockInfo ? 'Hide Available Stock' : 'Show Available Stock',
                                  _showStockInfo,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'recent',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  _showRecentTransactions ? 'Hide Recent Transactions' : 'Show Recent Transactions',
                                  _showRecentTransactions,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'pricelist',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  _showPriceList ? 'Hide Price List' : 'Show Price List',
                                  _showPriceList,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'hide_all',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  allHidden ? 'Show All Additional Information' : 'Hide All Additional Information',
                                  !allHidden,
                                ),
                              ),
                            ];
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _borderColor),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.settings, size: 16, color: Color(0xFF4B5563)),
                                Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF4B5563)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 60), // Align with action column
            ],
          )
        else
          // ── Bulk Update Toolbar ──
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      _buildBulkButton(
                        'Update Account',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => _buildUpdateAccountDialog(availableAccounts),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildBulkButton(
                        'Update Discount',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => _buildUpdateDiscountDialog(),
                          );
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.blue.shade600,
                        onPressed: () {
                          setState(() {
                            _bulkMode = false;
                            _selectedRows.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),

        // ── Column Headers ──
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: _borderColor),
                    right: BorderSide(color: _borderColor),
                    bottom: BorderSide(color: _borderColor),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      if (_bulkMode)
                        SizedBox(
                          width: 40,
                          child: Center(
                            child: Transform.scale(
                              scale: 0.85,
                              child: Checkbox(
                                value: _selectedRows.length == _lineItems.where((r) => !r.isLandedCost).length && _lineItems.isNotEmpty,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedRows.clear();
                                      for (int i = 0; i < _lineItems.length; i++) {
                                        if (!_lineItems[i].isLandedCost) {
                                          _selectedRows.add(i);
                                        }
                                      }
                                    } else {
                                      _selectedRows.clear();
                                    }
                                  });
                                },
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                activeColor: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 40),
                      Expanded(
                        flex: 10,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: _buildHeaderSearchField(
                            label: 'ITEM DETAILS',
                            controller: _itemDetailsSearchCtrl,
                            hintText: 'Search items...',
                            onChanged: (val) {
                              setState(() => _itemDetailsSearchQuery = val);
                            },
                            isSearchVisible: _showSearchItemDetails,
                            onToggle: () {
                              setState(() {
                                _showSearchItemDetails = !_showSearchItemDetails;
                                if (!_showSearchItemDetails) {
                                  _itemDetailsSearchCtrl.clear();
                                  _itemDetailsSearchQuery = '';
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      _vLine(),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: const Text(
                            'ACCOUNT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      _vLine(),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: const Text(
                            'QUANTITY',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      _vLine(),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'RATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ZTooltip(
                                message: 'You can perform basic calculations directly in this field using parentheses ( ) and arithmetic operators: + - / *',
                                child: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2"/><line x1="8" x2="16" y1="6" y2="6"/><line x1="16" x2="16" y1="14" y2="18"/><path d="M16 10h.01"/><path d="M12 10h.01"/><path d="M8 10h.01"/><path d="M12 14h.01"/><path d="M8 14h.01"/><path d="M12 18h.01"/><path d="M8 18h.01"/></svg>',
                                  width: 13,
                                  height: 13,
                                  colorFilter: const ColorFilter.mode(Color(0xFF0088FF), BlendMode.srcIn),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_discountType == 'At Line Item Level') ...[
                        _vLine(),
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'DISCOUNT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.info_outline, size: 12, color: _hintColor.withValues(alpha: 0.7)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      _vLine(),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Text(
                                'TAX',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ZTooltip(
                                message: 'Applicable tax for the items. You can select a tax rate from the list.',
                                child: const Icon(LucideIcons.helpCircle, size: 14, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _vLine(),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: const Text(
                            'CUSTOMER DETAILS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      _vLine(),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: const Text(
                            'AMOUNT',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),

        // ── Item Rows ──
        Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lineItems.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              setState(() {
                final item = _lineItems.removeAt(oldIndex);
                _lineItems.insert(newIndex, item);
              });
            },
            itemBuilder: (ctx, i) {
              final rowItem = _lineItems[i];
              if (rowItem.isLandedCost) {
                return SizedBox(key: ValueKey('landed_placeholder_${rowItem.hashCode}'));
              }
              if (_itemDetailsSearchQuery.isNotEmpty) {
                final name = (rowItem.itemName ?? '').toLowerCase();
                if (!name.contains(_itemDetailsSearchQuery.toLowerCase())) {
                  return SizedBox(key: ValueKey('bill_row_hidden_${rowItem.hashCode}'));
                }
              }
              return _buildLineItemRow(
                i,
                rowItem,
                itemsState,
                mappedNodes,
              );
            },
          ),
        ),

        // ── Table Bottom Border ──
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  border: Border(
                    left: BorderSide(color: _borderColor),
                    right: BorderSide(color: _borderColor),
                    bottom: BorderSide(color: _borderColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),

        // ── Landed Costs Group ─────────────────────────────────────────
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

        const SizedBox(height: 16),
        // ── Add Row Buttons (Below Table) ──
        Row(
          children: [
            CompositedTransformTarget(
              link: _addRowDropdownLink,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _lineItems.add(_BillLineItemRow());
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF2563EB)),
                            SizedBox(width: 6),
                            Text(
                              'Add New Row',
                              style: TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                    GestureDetector(
                      onTap: _toggleAddRowDropdown,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLandedCostHeaderRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                left: BorderSide(color: _borderColor),
                right: BorderSide(color: _borderColor),
                bottom: BorderSide(color: _borderColor),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    flex: 10,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        'LANDED COSTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  _vLine(),
                  const Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        'ACCOUNT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  _vLine(),
                  const Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        'QUANTITY',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  _vLine(),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'RATE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ZTooltip(
                            message: 'You can perform basic calculations directly in this field using parentheses ( ) and arithmetic operators: + - / *',
                            child: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2"/><line x1="8" x2="16" y1="6" y2="6"/><line x1="16" x2="16" y1="14" y2="18"/><path d="M16 10h.01"/><path d="M12 10h.01"/><path d="M8 10h.01"/><path d="M12 14h.01"/><path d="M8 14h.01"/><path d="M12 18h.01"/><path d="M8 18h.01"/></svg>',
                              width: 13,
                              height: 13,
                              colorFilter: const ColorFilter.mode(Color(0xFF0088FF), BlendMode.srcIn),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_discountType == 'At Line Item Level') ...[
                    _vLine(),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'DISCOUNT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.info_outline, size: 12, color: _hintColor.withValues(alpha: 0.7)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  _vLine(),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Text(
                            'TAX',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ZTooltip(
                            message: 'Applicable tax for the items. You can select a tax rate from the list.',
                            child: const Icon(LucideIcons.helpCircle, size: 14, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _vLine(),
                  const Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        'CUSTOMER DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  _vLine(),
                  const Expanded(
                    flex: 4,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        'AMOUNT',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 60),
      ],
    );
  }

  Widget _buildHeaderSearchField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
    required bool isSearchVisible,
    required VoidCallback onToggle,
    TextAlign textAlign = TextAlign.start,
  }) {
    if (!isSearchVisible) {
      return Row(
        mainAxisAlignment: textAlign == TextAlign.center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggle,
            child: const Icon(
              LucideIcons.search,
              size: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 12, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              style: const TextStyle(fontSize: 11, color: _textPrimary),
              textAlign: textAlign,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              controller.clear();
              onChanged('');
              onToggle();
            },
            child: const Icon(LucideIcons.x, size: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkButton(String label, {required VoidCallback onTap}) {
    return Container(
      height: 28,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: Colors.white,
          foregroundColor: _primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
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
    final allItems = itemsState.items;
    final activePriceLists = ref.watch(activePriceListsProvider)
        .where((pl) => pl.transactionType.toLowerCase() == 'purchase')
        .toList();

    return Column(
      key: ValueKey(row),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: _bgWhite,
                  border: Border(
                    left: BorderSide(color: _borderColor),
                    right: BorderSide(color: _borderColor),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 40px left checkbox or drag handle
                      if (_bulkMode)
                        SizedBox(
                          width: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.scale(
                              scale: 0.85,
                              child: Checkbox(
                                value: _selectedRows.contains(index),
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selectedRows.add(index);
                                  } else {
                                    _selectedRows.remove(index);
                                  }
                                }),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                activeColor: const Color(0xFF2563EB),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ReorderableDragStartListener(
                                index: index,
                                child: const MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: Icon(
                                    LucideIcons.gripVertical,
                                    size: 16,
                                    color: Color(0xFFD1D5DB),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      _vLine(),
                      // ITEM DETAILS (flex: 10)
                      Expanded(
                        flex: 10,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: row.itemId == null
                              ? Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        border: Border.all(color: _borderColor),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        LucideIcons.image,
                                        size: 20,
                                        color: _hintColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FormDropdown<Item>(
                                        value: null,
                                        height: 32,
                                        hint: 'Type or click to select an item.',
                                        hideBorderDefault: true,
                                        items: allItems.take(20).toList(),
                                        displayStringForValue: (i) => i.productName,
                                        onSearch: (query) async {
                                          if (query.length < 2) return [];
                                          return await ref
                                              .read(itemsControllerProvider.notifier)
                                              .searchProductsNoState(query);
                                        },
                                        itemBuilder: (i, isSelected, isHovered) =>
                                            _buildStandardLookupRow(
                                              i.productName,
                                              isSelected,
                                              isHovered,
                                              sublabel: i.costPrice != null
                                                  ? 'Purchase Rate: ₹${i.costPrice!.toStringAsFixed(2)}'
                                                  : null,
                                            ),
                                        onChanged: (i) async {
                                          if (i == null) return;
                                          setState(() {
                                            row.itemId = i.id;
                                            row.itemName = i.productName;
                                            row.itemNameCtrl.text = i.productName;
                                            row.itemCode = i.itemCode;
                                            row.itemType = i.type;
                                            row.hsnCode = i.hsnCode;
                                            row.hsnCtrl.text = i.hsnCode ?? '';
                                            row.rateCtrl.text = (i.costPrice ?? 0.0).toStringAsFixed(2);
                                            row.discountCtrl.text = '0.00';
                                            row.descriptionCtrl.text = i.purchaseDescription ?? '';
                                            row.taxId = i.intraStateTaxId;
                                            row.taxName = i.intraStateTaxName;
                                            final matchedTax = itemsState.taxGroups.where((tg) => tg.id == i.intraStateTaxId).firstOrNull;
                                            row.taxRate = matchedTax?.taxRate ?? 0.0;
                                          });

                                          if (_selectedPriceListId != null) {
                                            final pl = activePriceLists.where((p) => p.id == _selectedPriceListId).firstOrNull;
                                            if (pl != null) {
                                              final newRate = pl.calculatePrice(i.id ?? '', i.costPrice ?? 0.0, quantity: 1.0);
                                              setState(() {
                                                row.rateCtrl.text = newRate.toStringAsFixed(2);
                                                row.priceListId = _selectedPriceListId;
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : _richItemDisplay(row, itemsState, activePriceLists),
                        ),
                      ),
                      _vLine(),
                      // ACCOUNT
                      _accountCell(row, mappedNodes),
                      _vLine(),
                      // QUANTITY
                      _qtyCell(row),
                      _vLine(),
                      // RATE
                      _rateCell(row, activePriceLists),
                      if (_discountType == 'At Line Item Level') ...[
                        _vLine(),
                        // DISCOUNT
                        _discountCell(row),
                      ],
                      _vLine(),
                      // TAX
                      _taxCell(row, itemsState),
                      _vLine(),
                      // CUSTOMER DETAILS
                      _customerCell(row),
                      _vLine(),
                      // AMOUNT
                      _amountCell(row),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            _actionsCell(index, row, itemsState),
          ],
        ),
        if (!_hiddenDetails.contains(index))
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    border: Border(
                      left: BorderSide(color: _borderColor),
                      right: BorderSide(color: _borderColor),
                      top: BorderSide(color: _borderColor),
                    ),
                  ),
                  child: _itemExpandedProperties(
                    index,
                    row,
                    mappedNodes,
                  ),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
      ],
    );
  }

  OverlayEntry? _valueTooltipOverlay;

  Widget _richItemDisplay(_BillLineItemRow row, ItemsState itemsState, List<PriceList> activePriceLists) {
    final selectedItem = itemsState.items.firstWhere(
      (i) => i.id == row.itemId,
      orElse: () => Item(
        productName: row.itemName ?? '',
        itemCode: row.itemCode ?? '',
        type: row.itemType ?? 'goods',
        unitId: '',
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                border: Border.all(color: _borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: selectedItem.primaryImageUrl != null &&
                      selectedItem.primaryImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        selectedItem.primaryImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          LucideIcons.image,
                          size: 16,
                          color: _hintColor,
                        ),
                      ),
                    )
                  : const Icon(
                      LucideIcons.image,
                      size: 16,
                      color: _hintColor,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          row.itemName ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (row.itemCode != null) ...[
          Row(
            children: [
              Text(
                'SKU: ${row.itemCode}',
                style: const TextStyle(
                  fontSize: 11,
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
                    fontSize: 9,
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
              fontSize: 12,
              color: Color(0xFF4B5563),
            ),
            decoration: const InputDecoration(
              hintText: 'Add a description to your item',
              hintStyle: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'HSN Code: ',
              style: TextStyle(
                fontSize: 12,
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
                        (row.hsnCode != null && row.hsnCode!.isNotEmpty)
                            ? row.hsnCode!
                            : 'Select',
                        style: const TextStyle(
                          fontSize: 11,
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
    );
  }

  Widget _accountCell(_BillLineItemRow row, List<shared.AccountNode> mappedNodes) {
    return Expanded(
      flex: 5,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CompositedTransformTarget(
            link: row.accountLink,
            child: GestureDetector(
              onTap: () {
                _showAccountMenu(
                  context,
                  _lineItems.indexOf(row),
                  row,
                  mappedNodes,
                  link: row.accountLink,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: () {
                        final displayAccountName = (row.accountName != null && row.accountName!.isNotEmpty)
                            ? row.accountName!
                            : (row.accountId != null && row.accountId!.isNotEmpty
                                ? mappedNodes.where((a) => a.id == row.accountId).firstOrNull?.name
                                : null) ?? 'Select Account';
                        final isPlaceholder = displayAccountName == 'Select Account';
                        return Text(
                          displayAccountName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isPlaceholder ? _hintColor : _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      }(),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 16, color: _hintColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _qtyCell(_BillLineItemRow row) {
    return Expanded(
      flex: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactNumberField(
              row.quantityCtrl,
              focusNode: row.qtyFocus,
              onChanged: (v) {
                setState(() {});
              },
            ),
            if (row.itemId != null && _showStockInfo) ...[
              const SizedBox(height: 4),
              Text(
                'Avl: ${row.stockAvailable ?? 0.0}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 10, color: _textPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rateCell(_BillLineItemRow row, List<PriceList> activePriceLists) {
    return Expanded(
      flex: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactNumberField(
              row.rateCtrl,
              focusNode: row.rateFocus,
              onSubmitted: (_) => _handleRateCalculation(row),
              onChanged: (v) {
                setState(() {});
              },
            ),
            if (row.itemId != null) ...[
              if (_showPriceList || _showRecentTransactions)
                const SizedBox(height: 4),
              if (_showPriceList && activePriceLists.isNotEmpty)
                Builder(
                  builder: (context) {
                    final currentPriceList = activePriceLists.where((pl) => pl.id == row.priceListId).firstOrNull;
                    bool notIncluded = false;
                    if (currentPriceList != null && row.itemId != null) {
                      if (currentPriceList.priceListType == 'individual_items') {
                        notIncluded = !(currentPriceList.itemRates?.any((r) => r.itemId == row.itemId) ?? false);
                      }
                    } else if (row.priceListId != null) {
                      notIncluded = true;
                    }

                    return Transform.translate(
                      offset: Offset(0, 0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          if (notIncluded)
                            Transform.translate(
                              offset: const Offset(-24, 0),
                              child: ZTooltip(
                                message: "This item has not been included in the selected price list. So, the item's default rate has been used.",
                                child: const Icon(LucideIcons.alertCircle, size: 16, color: Colors.orange),
                              ),
                            ),
                          CompositedTransformTarget(
                            link: row.priceListLink,
                            child: MouseRegion(
                              onEnter: (_) {
                                if (row.priceListId != null) {
                                  final pl = activePriceLists.where((p) => p.id == row.priceListId).firstOrNull;
                                  if (pl != null) {
                                    _showValueTooltip(context, pl.name, row.priceListLink);
                                  }
                                }
                              },
                              onExit: (_) => _hideValueTooltip(),
                              child: SizedBox(
                                width: 120,
                                child: PopupMenuButton<PriceList>(
                                  tooltip: '',
                                  padding: EdgeInsets.zero,
                                  child: Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: _borderColor),
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            row.priceListId != null
                                                ? activePriceLists.where((pl) => pl.id == row.priceListId).firstOrNull?.name ?? 'Apply Price List'
                                                : 'Apply Price List',
                                            style: const TextStyle(fontSize: 11, color: _textPrimary, fontFamily: 'Inter'),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down, size: 16, color: _hintColor),
                                      ],
                                    ),
                                  ),
                                  onSelected: (pl) {
                                    setState(() {
                                      row.priceListId = pl.id;
                                      final newRate = pl.calculatePrice(
                                        row.itemId ?? '',
                                        double.tryParse(row.rateCtrl.text) ?? 0.0,
                                        quantity: double.tryParse(row.quantityCtrl.text) ?? 1.0,
                                      );
                                      row.rateCtrl.text = newRate.toStringAsFixed(2);
                                    });
                                  },
                                  itemBuilder: (context) => activePriceLists
                                      .map(
                                        (pl) => PopupMenuItem(
                                          value: pl,
                                          child: Text(pl.name, style: const TextStyle(fontSize: 12)),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _discountCell(_BillLineItemRow row) {
    return Expanded(
      flex: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildCompactNumberField(
                    row.discountCtrl,
                    focusNode: row.discountFocus,
                    onChanged: (v) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: _fieldBorder),
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFF9FAFB),
                  ),
                  child: CompositedTransformTarget(
                    link: row.discountTypeLink,
                    child: GestureDetector(
                      onTap: () => _showDiscountMenu(context, _lineItems.indexOf(row), row),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              row.discountType == '%' ? '%' : '₹',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down, size: 14, color: _hintColor),
                          ],
                        ),
                      ),
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

  Widget _taxCell(_BillLineItemRow row, ItemsState itemsState) {
    return Expanded(
      flex: 5,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CompositedTransformTarget(
            link: row.taxLayerLink,
            child: GestureDetector(
              onTap: () {
                final List<String> options = [
                  ..._standardTaxOptions,
                  ...itemsState.taxGroups.map((tg) {
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
                  onSelected: (val) {
                    setState(() {
                      row.taxName = val;
                      final matched = itemsState.taxGroups.where((tg) {
                        final rateStr = tg.taxRate % 1 == 0
                            ? tg.taxRate.toInt().toString()
                            : tg.taxRate.toString();
                        return '${tg.taxName} [$rateStr%]' == val;
                      }).firstOrNull;
                      row.taxRate = matched?.taxRate ?? 0;
                      row.taxId = matched?.id;
                    });
                  },
                  width: 140,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.taxName ?? 'Select Tax',
                        style: TextStyle(
                          fontSize: 13,
                          color: row.taxName == null ? _hintColor : _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 16, color: _hintColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _customerCell(_BillLineItemRow row) {
    return Expanded(
      flex: 5,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CompositedTransformTarget(
            link: row.customerLayerLink,
            child: GestureDetector(
              onTap: () {
                final customersAsync = ref.read(salesCustomersProvider);
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
                    width: 160,
                  );
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.customerName ?? 'Select Customer',
                        style: TextStyle(
                          fontSize: 13,
                          color: row.customerName == null ? _hintColor : _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 16, color: _hintColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountCell(_BillLineItemRow row) {
    return Expanded(
      flex: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            row.amount.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionsCell(int index, _BillLineItemRow row, ItemsState itemsState) {
    return SizedBox(
      width: 60,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CompositedTransformTarget(
              link: row.moreLayerLink,
              child: GestureDetector(
                onTap: () => _showItemMenu(
                  context,
                  index,
                  row,
                  row.moreLayerLink,
                  itemsState,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(LucideIcons.moreVertical, size: 16, color: _hintColor),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (_lineItems.length > 1) {
                  row.dispose();
                  setState(() {
                    _lineItems.removeAt(index);
                  });
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(LucideIcons.x, size: 14, color: _dangerRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemExpandedProperties(
    int index,
    _BillLineItemRow row,
    List<shared.AccountNode> accounts,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _propertyButton(
          iconWidget: SvgPicture.string(
            '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#22C55E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13.172 2a2 2 0 0 1 1.414.586l6.71 6.71a2.4 2.4 0 0 1 0 3.408l-4.592 4.592a2.4 2.4 0 0 1-3.408 0l-6.71-6.71A2 2 0 0 1 6 9.172V3a1 1 0 0 1 1-1z"/><path d="M2 7v6.172a2 2 0 0 0 .586 1.414l6.71 6.71a2.4 2.4 0 0 0 3.191.193"/><circle cx="10.5" cy="6.5" r=".5" fill="#22C55E"/></svg>',
            width: 16,
            height: 16,
          ),
          label: 'Reporting Tags',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _propertyButton({
    LayerLink? link,
    IconData? icon,
    Widget? iconWidget,
    required String label,
    String? value,
    Color color = const Color(0xFF6B7280),
    required VoidCallback onTap,
  }) {
    Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null)
              iconWidget
            else if (icon != null)
              Icon(icon, size: 16, color: color)
            else
              const SizedBox.shrink(),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _textPrimary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 4),
              Text(
                '($value)',
                style: const TextStyle(
                  fontSize: 12,
                  color: _linkBlue,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: _hintColor),
          ],
        ),
      ),
    );

    if (link != null) {
      return CompositedTransformTarget(link: link, child: content);
    }
    return content;
  }

  Widget _buildUpdateAccountDialog(List<shared.AccountNode> availableAccounts) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: Container(
        width: 600,
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Select Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFFEF4444)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormDropdown<shared.AccountNode>(
                        height: 32,
                        value: _selectedPopupAccount,
                        items: availableAccounts,
                        displayStringForValue: (v) => v.name,
                        hint: 'Select an account',
                        onChanged: (v) {
                          setState(() {
                            _selectedPopupAccount = v;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _fieldBorder),
                        itemBuilder: (account, isSelected, isHovered) {
                          return _buildStandardLookupRow(
                            account.name,
                            isSelected,
                            isHovered,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      for (int i = 0; i < _lineItems.length; i++) {
                        final row = _lineItems[i];
                        if (row.itemId != null && (!_bulkMode || _selectedRows.isEmpty || _selectedRows.contains(i))) {
                          setState(() {
                            row.accountId = _selectedPopupAccount?.id;
                            row.accountName = _selectedPopupAccount?.name;
                          });
                        }
                      }
                      Navigator.pop(context);
                      setState(() {
                        _bulkMode = false;
                        _selectedRows.clear();
                        _selectedPopupAccount = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
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
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
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
    );
  }

  Widget _buildUpdateDiscountDialog() {
    String discountType = 'percentage';
    final controller = TextEditingController();

    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            width: 600,
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                  child: Row(
                    children: [
                      const Text(
                        'Bulk Update Line Items',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827), fontFamily: 'Inter'),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFFEF4444)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _zRadio('Percentage (%)', 'percentage', discountType, (v) => setModalState(() => discountType = v)),
                            ),
                            Expanded(
                              child: _zRadio('Flat (₹)', 'fixed', discountType, (v) => setModalState(() => discountType = v)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                    hintText: '0',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
                                  color: Color(0xFFF9FAFB),
                                ),
                                child: Text(discountType == 'percentage' ? '%' : '₹', style: const TextStyle(color: Color(0xFF6B7280))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final discVal = double.tryParse(controller.text) ?? 0;
                          final typeStr = discountType == 'percentage' ? '%' : '₹';
                          for (int i = 0; i < _lineItems.length; i++) {
                            final row = _lineItems[i];
                            if (row.itemId != null && (!_bulkMode || _selectedRows.isEmpty || _selectedRows.contains(i))) {
                              setState(() {
                                row.discountCtrl.text = discVal.toStringAsFixed(2);
                                row.discountType = typeStr;
                              });
                            }
                          }
                          setState(() { _bulkMode = false; _selectedRows.clear(); });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Update'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Cancel'),
                      ),
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

  void _showDiscountMenu(
    BuildContext context,
    int index,
    _BillLineItemRow row, {
    LayerLink? link,
  }) {
    _closeDiscountOverlay();

    _discountOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeDiscountOverlay,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: link ?? row.discountTypeLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 42),
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeDiscountOverlay(),
                child: _DiscountTypePopover(
                  selectedType: row.discountType == '%' ? 'percentage' : 'fixed',
                  onSelected: (type) {
                    setState(() {
                      row.discountType = type == 'percentage' ? '%' : '₹';
                    });
                    _closeDiscountOverlay();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_discountOverlay!);
  }

  void _closeDiscountOverlay() {
    _discountOverlay?.remove();
    _discountOverlay = null;
  }

  void _showAccountMenu(
    BuildContext context,
    int index,
    _BillLineItemRow row,
    List<shared.AccountNode> accounts, {
    LayerLink? link,
  }) {
    _accountOverlay?.remove();
    _accountOverlay = null;

    final overlay = Overlay.of(context);

    _accountOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _accountOverlay?.remove();
                _accountOverlay = null;
              },
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: link ?? row.accountLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 32),
            child: Material(
              color: Colors.transparent,
              child: _AccountSelectionPopover(
                accounts: accounts,
                selectedAccountId: row.accountId,
                onSelected: (acc) {
                  setState(() {
                    row.accountId = acc.id;
                    row.accountName = acc.name;
                  });
                  _accountOverlay?.remove();
                  _accountOverlay = null;
                },
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_accountOverlay!);
  }

  void _showValueTooltip(BuildContext context, String message, LayerLink link) {
    if (_valueTooltipOverlay != null) {
      _valueTooltipOverlay?.remove();
      _valueTooltipOverlay = null;
    }

    _valueTooltipOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            child: CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_valueTooltipOverlay!);
    setState(() {});
  }

  void _hideValueTooltip() {
    if (_valueTooltipOverlay != null) {
      _valueTooltipOverlay?.remove();
      _valueTooltipOverlay = null;
      setState(() {});
    }
  }

  Widget _zRadio(
    String label,
    String value,
    String groupValue,
    Function(String) onChanged,
  ) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _primaryBlue : const Color(0xFFAAAAAA),
                width: 1.5,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: _primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: _labelColor)),
        ],
      ),
    );
  }

  Widget _vLine() {
    return Container(
      width: 1,
      color: _borderColor,
    );
  }

  double? _evaluateExpression(String expr) {
    try {
      final parser = _MathParser(expr);
      return parser.parse();
    } catch (_) {
      return null;
    }
  }

  void _handleRateCalculation(_BillLineItemRow row) {
    final text = row.rateCtrl.text;
    if (text.isEmpty) return;
    try {
      final parsed = _evaluateExpression(text);
      if (parsed != null) {
        row.rateCtrl.text = parsed.toStringAsFixed(2);
      }
    } catch (_) {}
  }

  void _showItemMenu(
    BuildContext context,
    int index,
    _BillLineItemRow row,
    LayerLink link,
    ItemsState itemsState,
  ) {
    final allItems = itemsState.items;
    _itemMenuOverlay?.remove();
    _itemMenuOverlay = null;

    _itemMenuOverlay = OverlayEntry(
      builder: (ctx) {
        String? hoveredItem;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _itemMenuOverlay?.remove();
                  _itemMenuOverlay = null;
                },
                behavior: HitTestBehavior.translucent,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: StatefulBuilder(
                      builder: (context, setOverlayState) {
                        final isHidden = _hiddenDetails.contains(index);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSettingsOverlayItem(
                              label: isHidden ? 'Show Additional Information' : 'Hide Additional Information',
                              showHighlight: hoveredItem == 'toggle_info',
                              onHover: (v) => setOverlayState(() => hoveredItem = v ? 'toggle_info' : null),
                              onTap: () {
                                setState(() {
                                  if (_hiddenDetails.contains(index)) {
                                    _hiddenDetails.remove(index);
                                  } else {
                                    _hiddenDetails.add(index);
                                  }
                                });
                                _itemMenuOverlay?.remove();
                                _itemMenuOverlay = null;
                              },
                            ),
                            const SizedBox(height: 4),
                            _buildSettingsOverlayItem(
                              label: 'Clone',
                              showHighlight: hoveredItem == 'clone',
                              onHover: (v) => setOverlayState(() => hoveredItem = v ? 'clone' : null),
                              onTap: () {
                                setState(() {
                                  _lineItems.insert(index + 1, row.clone());
                                });
                                _itemMenuOverlay?.remove();
                                _itemMenuOverlay = null;
                              },
                            ),
                            const SizedBox(height: 4),
                            _buildSettingsOverlayItem(
                              label: 'Insert New Row',
                              showHighlight: hoveredItem == 'insert_row',
                              onHover: (v) => setOverlayState(() => hoveredItem = v ? 'insert_row' : null),
                              onTap: () {
                                setState(() {
                                  _lineItems.insert(index + 1, _BillLineItemRow());
                                });
                                _itemMenuOverlay?.remove();
                                _itemMenuOverlay = null;
                              },
                            ),
                            const SizedBox(height: 4),
                            _buildSettingsOverlayItem(
                              label: 'Insert Items in Bulk',
                              showHighlight: hoveredItem == 'bulk',
                              onHover: (v) => setOverlayState(() => hoveredItem = v ? 'bulk' : null),
                              onTap: () {
                                _itemMenuOverlay?.remove();
                                _itemMenuOverlay = null;
                                showDialog(
                                  context: context,
                                  builder: (context) => BulkItemsDialog(
                                    products: allItems,
                                    onItemsSelected: (selectedItems) {
                                      setState(() {
                                        selectedItems.forEach((item, quantity) {
                                          final newRow = _BillLineItemRow();
                                          newRow.itemId = item.id;
                                          newRow.itemName = item.productName;
                                          newRow.itemNameCtrl.text = item.productName;
                                          newRow.hsnCode = item.hsnCode;
                                          newRow.hsnCtrl.text = item.hsnCode ?? '';
                                          newRow.itemCode = item.itemCode;
                                          newRow.rateCtrl.text = (item.costPrice ?? 0.0).toStringAsFixed(2);
                                          newRow.quantityCtrl.text = quantity.toString();
                                          newRow.taxId = item.intraStateTaxId;
                                          newRow.taxName = item.intraStateTaxName;
                                          final matchedTax = itemsState.taxGroups.where((tg) => tg.id == item.intraStateTaxId).firstOrNull;
                                          newRow.taxRate = matchedTax?.taxRate ?? 0.0;
                                          _lineItems.insert(index + 1, newRow);
                                        });
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_itemMenuOverlay!);
  }

  Widget _buildSettingsOverlayItem({
    required String label,
    required bool showHighlight,
    required ValueChanged<bool> onHover,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onHover: onHover,
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: showHighlight ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: showHighlight
                ? Colors.white
                : const Color(0xFF1F2937).withValues(alpha: 0.8),
          ),
        ),
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
    final Map<double, double> rateToTax = {};
    for (final row in _lineItems) {
      if (row.taxRate <= 0) continue;
      final tax = row.amount * row.taxRate / 100;
      rateToTax.update(row.taxRate, (v) => v + tax, ifAbsent: () => tax);
    }
    final sortedRates = rateToTax.keys.toList()..sort();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox.shrink(),
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
              if (sortedRates.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...sortedRates.expand((rate) {
                  final tax = rateToTax[rate] ?? 0;
                  final rateLabel = rate % 1 == 0
                      ? rate.toInt().toString()
                      : rate.toString();
                  if (_isKeralaPlaceOfSupply) {
                    final halfRate = rate / 2;
                    final halfRateLabel = halfRate % 1 == 0
                        ? halfRate.toInt().toString()
                        : halfRate.toString();
                    final halfTax = tax / 2;
                    return [
                      _buildTotalRow('CGST$halfRateLabel [$halfRateLabel%]', halfTax),
                      const SizedBox(height: 6),
                      _buildTotalRow('SGST$halfRateLabel [$halfRateLabel%]', halfTax),
                      const SizedBox(height: 6),
                    ];
                  }
                  return [
                    _buildTotalRow('IGST$rateLabel [$rateLabel%]', tax),
                    const SizedBox(height: 6),
                  ];
                }).toList(),
              ],
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
              color: amount < 0 ? _dangerRed : _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(
    String hintText, [
    bool hasDropdown = false,
  ]) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: _hintColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        borderSide: const BorderSide(color: _primaryBlue),
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: hasDropdown
          ? const Icon(LucideIcons.chevronDown, size: 16, color: _textMuted)
          : null,
    );
  }

  Widget _buildNotesTermsAndAttachments() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFDBEAFE)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 1100;

          final notesSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: _getInputDecoration(
                    'Enter any notes for this bill',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'It will not be shown in PDF',
                style: TextStyle(fontSize: 12, color: _textMuted),
              ),
            ],
          );

          final attachSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attach File(s) to Bill',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {},
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.upload,
                                  size: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Upload File',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          color: Color(0xFFE5E7EB),
                          thickness: 1,
                          indent: 6,
                          endIndent: 6,
                        ),
                        InkWell(
                          onTap: () {},
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              LucideIcons.chevronDown,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'You can upload a maximum of 5 files, 10MB each',
                style: TextStyle(fontSize: 11, color: _textMuted),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                notesSection,
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFDBEAFE)),
                const SizedBox(height: 20),
                attachSection,
              ],
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: notesSection),
                const SizedBox(width: 24),
                Container(
                  width: 1,
                  color: const Color(0xFFDBEAFE),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: attachSection),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      decoration: const BoxDecoration(
        color: _bgWhite,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => _saveBill(status: 'draft'),
            child: const Text(
              'Save as Draft',
              style: TextStyle(color: _textPrimary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _saveBill(status: 'open'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save as Open',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.bills);
              }
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: _textPrimary, fontSize: 13),
            ),
          ),
          const Spacer(),
          // Right side
          const Text(
            "PDF Template: 'Standard Template'",
            style: TextStyle(fontSize: 12, color: _textMuted),
          ),
          const SizedBox(width: 4),
          const Text(
            'Change',
            style: TextStyle(fontSize: 12, color: _primaryBlue),
          ),
        ],
      ),
    );
  }

  void _toggleAddRowDropdown() {
    if (_addRowDropdownOverlay != null) {
      _addRowDropdownOverlay!.remove();
      _addRowDropdownOverlay = null;
      return;
    }
    _addRowDropdownOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _addRowDropdownOverlay?.remove();
                _addRowDropdownOverlay = null;
              },
              behavior: HitTestBehavior.translucent,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _addRowDropdownLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    setState(
                      () =>
                          _lineItems.add(_BillLineItemRow(isLandedCost: true)),
                    );
                    _addRowDropdownOverlay?.remove();
                    _addRowDropdownOverlay = null;
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add Landed Cost',
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
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_addRowDropdownOverlay!);
  }



  Widget _buildBulkActionButton(String label) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _primaryBlue,
        side: const BorderSide(color: _primaryBlue),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
    void Function(String)? onSubmitted,
    Widget? prefixIcon,
  }) {
    return InCellWrapper(
      focusNode: focusNode,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
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

  Widget _buildStandardLookupRow(
    String label,
    bool isSelected,
    bool isHovered, {
    String? sublabel,
    double indentation = 0.0,
  }) {
    Color bg = Colors.transparent;
    Color text = const Color(0xFF111827);
    Color subtext = const Color(0xFF6B7280);
    Color check = const Color(0xFF2563EB);

    if (isHovered) {
      bg = const Color(0xFF0088FF);
      text = Colors.white;
      subtext = Colors.white70;
      check = Colors.white;
    } else if (isSelected) {
      bg = const Color(0xFFEFF6FF);
      text = const Color(0xFF2563EB);
      subtext = const Color(0xFF2563EB).withValues(alpha: 0.7);
      check = const Color(0xFF2563EB);
    }

    return Container(
      padding: EdgeInsets.only(left: 12 + indentation, right: 12, top: 8, bottom: 8),
      color: bg,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(fontSize: 12, color: subtext),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check, size: 16, color: check),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM PRIMITIVES (Zoho-style)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _zFormRow({
    required String label,
    required Widget child,
    bool isRequired = false,
    bool crossStart = false,
    double maxWidth = 600,
    double gap = 24,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        crossAxisAlignment: crossStart
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isRequired ? _dangerRed : _labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isRequired)
                    const TextSpan(
                      text: '*',
                      style: TextStyle(
                        color: _dangerRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: gap),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _zField(
    TextEditingController ctrl, {
    String hint = '',
    Function(String)? onChanged,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    TextAlign textAlign = TextAlign.start,
  }) {
    return _HoverableField(
      builder: (isHovered) => Container(
        height: 32,
        decoration: BoxDecoration(
          color: _bgWhite,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isHovered ? _linkBlue : _fieldBorder,
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                onChanged: onChanged,
                onTap: onTap,
                keyboardType: keyboardType,
                textAlign: textAlign,
                readOnly: readOnly || (onTap != null && onChanged == null),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle: const TextStyle(color: _hintColor),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (suffixIcon != null) ...[const SizedBox(width: 8), suffixIcon],
          ],
        ),
      ),
    );
  }

  Widget _zDateField({
    required TextEditingController controller,
    required GlobalKey targetKey,
    required DateTime? value,
    required ValueChanged<DateTime> onSelected,
    String hint = 'dd-MM-yyyy',
  }) {
    return KeyedSubtree(
      key: targetKey,
      child: _zField(
        controller,
        hint: hint,
        readOnly: true,
        onTap: () async {
          final selected = await ZerpaiDatePicker.show(
            context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            targetKey: targetKey,
          );
          if (selected != null) {
            controller.text = DateFormat('dd-MM-yyyy').format(selected);
            onSelected(selected);
          }
        },
        suffixIcon: const Icon(
          LucideIcons.calendar,
          size: 16,
          color: _hintColor,
        ),
      ),
    );
  }
}

class _HoverableField extends StatefulWidget {
  final Widget Function(bool isActive) builder;
  const _HoverableField({required this.builder});
  @override
  State<_HoverableField> createState() => _HoverableFieldState();
}

class _HoverableFieldState extends State<_HoverableField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.builder(_isHovered),
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

// ─── Math Expression Parser ──────────────────────────────────────────────────
class _MathParser {
  _MathParser(this.input);
  final String input;
  int pos = -1, ch = -1;

  void nextChar() {
    ch = (++pos < input.length) ? input.codeUnitAt(pos) : -1;
  }

  bool eat(int charToEat) {
    while (ch == 32) nextChar(); // skip spaces
    if (ch == charToEat) {
      nextChar();
      return true;
    }
    return false;
  }

  double parse() {
    nextChar();
    double x = parseExpression();
    if (pos < input.length) throw Exception("Unexpected: ${input[pos]}");
    return x;
  }

  double parseExpression() {
    double x = parseTerm();
    for (;;) {
      if (eat(43)) {
        x += parseTerm(); // +
      } else if (eat(45)) {
        x -= parseTerm(); // -
      } else {
        return x;
      }
    }
  }

  double parseTerm() {
    double x = parseFactor();
    for (;;) {
      if (eat(42)) {
        x *= parseFactor(); // *
      } else if (eat(47)) {
        x /= parseFactor(); // /
      } else {
        return x;
      }
    }
  }

  double parseFactor() {
    if (eat(43)) return parseFactor(); // +
    if (eat(45)) return -parseFactor(); // -
    double x;
    int startPos = pos;
    if (eat(40)) {
      // (
      x = parseExpression();
      eat(41); // )
    } else if ((ch >= 48 && ch <= 57) || ch == 46) {
      // numbers
      while ((ch >= 48 && ch <= 57) || ch == 46) nextChar();
      x = double.parse(input.substring(startPos, pos));
    } else {
      throw Exception(
        "Unexpected: ${ch == -1 ? 'EOF' : String.fromCharCode(ch)}",
      );
    }
    return x;
  }
}

// ─── Triangle/Caret Painter ─────────────────────────────────────────────────
class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool isUp;
  final bool hasBorder;
  _TrianglePainter({
    required this.color,
    this.isUp = false,
    this.hasBorder = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (isUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width / 2, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);

    if (hasBorder) {
      final borderPaint = Paint()
        ..color = const Color(0xFFDDDDDD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Tax Selection Popover ──────────────────────────────────────────────────
class _TaxSelectionPopover extends ConsumerWidget {
  final String? selectedTaxId;
  final ValueChanged<TaxRate> onTaxSelected;

  const _TaxSelectionPopover({
    this.selectedTaxId,
    required this.onTaxSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(itemsControllerProvider);
    final taxes = itemsState.taxGroups;

    // Create dummy objects for special options
    final nonTaxable = TaxRate(id: 'non_taxable', taxName: 'Non-Taxable', taxRate: 0);
    final outOfScope = TaxRate(id: 'out_of_scope', taxName: 'Out of Scope', taxRate: 0);
    final nonGst = TaxRate(id: 'non_gst', taxName: 'Non-GST Supply', taxRate: 0);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _SpecialPopoverListItem(
                    title: "Non-Taxable",
                    isSelected: selectedTaxId == 'non_taxable',
                    onTap: () => onTaxSelected(nonTaxable),
                  ),
                  _SpecialPopoverListItem(
                    title: "Out of Scope",
                    description: "Supplies on which you don't charge any GST or include them in the returns.",
                    isSelected: selectedTaxId == 'out_of_scope',
                    onTap: () => onTaxSelected(outOfScope),
                  ),
                  _SpecialPopoverListItem(
                    title: "Non-GST Supply",
                    description: "Supplies which do not come under GST such as petroleum products and liquor.",
                    isSelected: selectedTaxId == 'non_gst',
                    onTap: () => onTaxSelected(nonGst),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Tax Group',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  ...taxes.map((tax) {
                    final isSelected = tax.id == selectedTaxId;
                    final displayLabel = '${tax.taxName} [${tax.taxRate}%]';

                    return _PopoverListItem(
                      label: displayLabel,
                      isSelected: isSelected,
                      onTap: () => onTaxSelected(tax),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialPopoverListItem extends StatefulWidget {
  final String title;
  final String? description;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpecialPopoverListItem({
    required this.title,
    this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SpecialPopoverListItem> createState() => _SpecialPopoverListItemState();
}

class _SpecialPopoverListItemState extends State<_SpecialPopoverListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected || _hover
        ? const Color(0xFF3B82F6)
        : Colors.transparent;
    final text = widget.isSelected || _hover
        ? Colors.white
        : const Color(0xFF333333);
    final descColor = widget.isSelected || _hover
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF666666);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(fontSize: 13, color: text, fontWeight: FontWeight.w500),
              ),
              if (widget.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.description!,
                  style: TextStyle(fontSize: 11, color: descColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Account Selection Popover ──────────────────────────────────────────────
class _AccountSelectionPopover extends StatefulWidget {
  final List<shared.AccountNode> accounts;
  final String? selectedAccountId;
  final ValueChanged<shared.AccountNode> onSelected;

  const _AccountSelectionPopover({
    required this.accounts,
    this.selectedAccountId,
    required this.onSelected,
  });

  @override
  State<_AccountSelectionPopover> createState() =>
      _AccountSelectionPopoverState();
}

class _AccountSelectionPopoverState extends State<_AccountSelectionPopover> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  Map<String, List<shared.AccountNode>> get _grouped {
    final Map<String, List<shared.AccountNode>> grouped = {};
    for (var categoryNode in widget.accounts) {
      final filteredChildren = categoryNode.children.where((acc) {
        if (_search.isEmpty) return true;
        return acc.name.toLowerCase().contains(_search.toLowerCase());
      }).toList();

      if (filteredChildren.isNotEmpty) {
        grouped[categoryNode.name] = filteredChildren;
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    return Container(
      width: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Select an account',
                      prefixIcon: Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: groups.entries.expand((entry) {
                  return [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...entry.value.map((acc) {
                      final isSelected = acc.id == widget.selectedAccountId;
                      return _PopoverListItem(
                        label: acc.name,
                        isSelected: isSelected,
                        onTap: () => widget.onSelected(acc),
                      );
                    }),
                  ];
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Discount Type Popover ──────────────────────────────────────────────────
class _DiscountTypePopover extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onSelected;

  const _DiscountTypePopover({
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PopoverListItem(
            label: 'Percentage (%)',
            isSelected: selectedType == 'percentage',
            onTap: () => onSelected('percentage'),
          ),
          _PopoverListItem(
            label: 'Fixed Amount (₹)',
            isSelected: selectedType == 'fixed',
            onTap: () => onSelected('fixed'),
          ),
        ],
      ),
    );
  }
}

// ─── Popover List Item ──────────────────────────────────────────────────────
class _PopoverListItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PopoverListItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PopoverListItem> createState() => _PopoverListItemState();
}

class _PopoverListItemState extends State<_PopoverListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected || _hover
        ? const Color(0xFF3B82F6)
        : Colors.transparent;
    final text = widget.isSelected || _hover
        ? Colors.white
        : const Color(0xFF333333);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(fontSize: 13, color: text),
                ),
              ),
              if (widget.isSelected) Icon(Icons.check, size: 14, color: text),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hoverable Toggle Menu Item ─────────────────────────────────────────────
class _HoverableToggleMenuItem extends StatefulWidget {
  final String label;
  final bool value;
  const _HoverableToggleMenuItem(this.label, this.value);

  @override
  State<_HoverableToggleMenuItem> createState() =>
      _HoverableToggleMenuItemState();
}

class _HoverableToggleMenuItemState extends State<_HoverableToggleMenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _hover ? FontWeight.w600 : FontWeight.w500,
                  color: _hover ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
            if (widget.value)
              Icon(Icons.check, size: 14, color: _hover ? Colors.white : const Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }
}

// ─── Hoverable Menu Item ────────────────────────────────────────────────────
class _HoverableMenuItem extends StatefulWidget {
  final String label;
  const _HoverableMenuItem(this.label);

  @override
  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<_HoverableMenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: _hover ? FontWeight.w600 : FontWeight.w500,
            color: _hover ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

// ─── HSN Code Edit Popover ──────────────────────────────────────────────────
class _HSNCodeEditPopover extends StatefulWidget {
  final String initialHsnCode;
  final VoidCallback onCancel;
  final Function(String) onSave;

  const _HSNCodeEditPopover({
    required this.initialHsnCode,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<_HSNCodeEditPopover> createState() => _HSNCodeEditPopoverState();
}

class _HSNCodeEditPopoverState extends State<_HSNCodeEditPopover> {
  late TextEditingController _ctrl;

  static const _hintColor = Color(0xFF8E8E93);
  static const _textPrimary = Color(0xFF1C1C1E);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialHsnCode);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openHsnSearch() async {
    final result = await showDialog<HsnSacCode>(
      context: context,
      useSafeArea: false,
      builder: (context) => HsnSacSearchModal(
        type: 'HSN',
        initialQuery: _ctrl.text,
      ),
    );

    if (result != null) {
      setState(() {
        _ctrl.text = result.code;
        widget.onSave(result.code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 252),
          child: CustomPaint(
            size: const Size(16, 8),
            painter: _TrianglePainter(color: Colors.white, isUp: true),
          ),
        ),
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: const Text(
                  'HSN Code',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    hintText: 'Enter HSN Code',
                    hintStyle: const TextStyle(
                      color: _hintColor,
                      fontSize: 13,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
                      onPressed: _openHsnSearch,
                      splashRadius: 16,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (v) => widget.onSave(v.trim()),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => widget.onSave(_ctrl.text.trim()),
                      child: const Text('Save', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        foregroundColor: _textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Bulk Add Modal ─────────────────────────────────────────────────────────
class _BulkAddModal extends StatefulWidget {
  final List<Item> items;
  final Function(List<Map<String, dynamic>>) onAdd;
  const _BulkAddModal({required this.items, required this.onAdd});
  @override
  State<_BulkAddModal> createState() => _BulkAddModalState();
}

class _BulkAddModalState extends State<_BulkAddModal> {
  final Map<String, int> _counts = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _selectedCategory = 'All';

  List<String> get _categories {
    final cats = <String>{'All'};
    for (final item in widget.items) {
      if (item.type.isNotEmpty) {
        final t = item.type;
        cats.add(t[0].toUpperCase() + t.substring(1));
      }
    }
    return cats.toList();
  }

  List<Item> get _filtered => widget.items.where((i) {
    final matchSearch =
        _search.isEmpty ||
        i.productName.toLowerCase().contains(_search.toLowerCase()) ||
        i.itemCode.toLowerCase().contains(_search.toLowerCase());
    final matchCat =
        _selectedCategory == 'All' ||
        i.type.toLowerCase() == _selectedCategory.toLowerCase();
    return matchSearch && matchCat;
  }).toList();

  List<Item> get _selectedItems =>
      widget.items.where((i) => (_counts[i.id ?? ''] ?? 0) > 0).toList();

  int get _totalQty => _counts.values.fold(0, (a, b) => a + b);
  int get _selectedCount => _counts.values.where((v) => v > 0).length;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleItem(String id) {
    setState(() {
      if ((_counts[id] ?? 0) > 0) {
        _counts.remove(id);
      } else {
        _counts[id] = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: SizedBox(
        width: 960,
        height: 620,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 12, 14),
              child: Row(
                children: [
                  const Text(
                    'Add Items in Bulk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFFEF4444)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  PopupMenuButton<String>(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    color: Colors.white,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFD1D5DB)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.filter_alt_outlined,
                                            size: 18,
                                            color: Color(0xFF0088FF),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Category',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 16,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ],
                                      ),
                                    ),
                                    itemBuilder: (_) => _categories
                                        .map(
                                          (c) => PopupMenuItem(
                                            value: c,
                                            child: Text(
                                              c,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onSelected: (v) =>
                                        setState(() => _selectedCategory = v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _searchCtrl,
                                onChanged: (v) => setState(() => _search = v),
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText:
                                      'Type to search or scan the barcode of the item',
                                  hintStyle: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(color: Color(0xFF0088FF)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final item = _filtered[i];
                              final id = item.id ?? '';
                              final isSelected = (_counts[id] ?? 0) > 0;
                              return InkWell(
                                onTap: () => _toggleItem(id),
                                child: Container(
                                  color: isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : null,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: const Color(0xFF111827),
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Purchase Rate: ₹${(item.costPrice ?? 0.0).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.check_circle_outline,
                                        size: 20,
                                        color: isSelected
                                            ? const Color(0xFF22C55E)
                                            : const Color(0xFFD1D5DB),
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
                  Container(width: 1, color: const Color(0xFFE5E7EB)),
                  Expanded(
                    flex: 45,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              const Text(
                                'Selected Items',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_selectedCount',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Total Quantity: $_totalQty',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        Expanded(
                          child: _selectedItems.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'Click the item names from the left pane to select them',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _selectedItems.length,
                                  itemBuilder: (_, i) {
                                    final item = _selectedItems[i];
                                    final id = item.id ?? '';
                                    final count = _counts[id] ?? 1;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.productName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 28,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: const Color(0xFFD1D5DB)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () => setState(() {
                                                    final nv = count - 1;
                                                    if (nv <= 0) {
                                                      _counts.remove(id);
                                                    } else {
                                                      _counts[id] = nv;
                                                    }
                                                  }),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    child: const Icon(
                                                      Icons.remove,
                                                      size: 14,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ),
                                                const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
                                                Container(
                                                  width: 32,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '$count',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: Color(0xFF111827),
                                                    ),
                                                  ),
                                                ),
                                                const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
                                                GestureDetector(
                                                  onTap: () => setState(() => _counts[id] = count + 1),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    child: const Icon(
                                                      Icons.add,
                                                      size: 14,
                                                      color: Color(0xFF6B7280),
                                                    ),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _selectedItems.isEmpty
                        ? null
                        : () {
                            final result = _selectedItems.map((i) {
                              final qty = (_counts[i.id ?? ''] ?? 1).toDouble();
                              return {
                                'item': i,
                                'quantity': qty,
                              };
                            }).toList();
                            widget.onAdd(result);
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Add Items', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, color: Color(0xFF111827))),
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
