// ignore_for_file: unused_element, unnecessary_type_check, unnecessary_null_comparison, unused_local_variable
import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/z_adaptive_menu.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/address_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/edit_quantity_dialog.dart';
import 'package:zerpai_erp/modules/purchases/bills/providers/purchases_bills_provider.dart';
import 'package:zerpai_erp/modules/purchases/bills/repositories/purchases_bills_repository.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/vendor_sidebar.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository_impl.dart';
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
import 'package:zerpai_erp/shared/widgets/dialogs/item_quick_edit_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/advanced_vendor_search_dialog.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/items_stock_providers.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/modules/pricelists/branch_pricelist/providers/branch_pricelist_provider.dart';
import 'package:zerpai_erp/modules/pricelists/branch_pricelist/models/branch_pricelist_model.dart';
import 'package:hive/hive.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/models/purchases_purchase_receives_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/providers/purchase_receives_provider.dart';
import 'package:zerpai_erp/shared/providers/lookup_providers.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/purchases_vendors_vendor_create.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/manage_tds_tcs_rates_dialog.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/providers/purchases_purchase_orders_provider.dart' hide warehousesProvider;
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';




// ── Zoho-style Colors ────────────────────────────────────────────────────────
const Color _bgWhite = Color(0xFFFFFFFF);
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
  String? warehouseName;
  String? itemId;
  String? itemName;
  String? purchaseOrderId;
  String? purchaseOrderNumber;
  String? purchaseReceiveId;
  String? purchaseReceiveNumber;
  String? purchaseReceiveItemId;
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
  final TextEditingController quantityCtrl = TextEditingController();
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
  String itcEligibility = 'Eligible For ITC';
  final LayerLink itcLayerLink = LayerLink();
  final LayerLink reportingTagsLink = LayerLink();
  Map<String, String> reportingTags = {
    'adgf': 'None',
    'schedule': 'None',
    'demo_tag': 'None',
  };
  List<Map<String, String>>? savedBatchData;
  bool hasBatchData = false;
  int batchCount = 0;
  String? discountAccountId;

  _BillLineItemRow({this.isLandedCost = false, String? defaultWarehouse}) : warehouseName = defaultWarehouse;

  _BillLineItemRow clone() {
    final newRow = _BillLineItemRow(isLandedCost: isLandedCost, defaultWarehouse: warehouseName);
    newRow.discountAccountId = discountAccountId;
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
    newRow.itcEligibility = itcEligibility;
    newRow.reportingTags = Map<String, String>.from(reportingTags);
    newRow.savedBatchData = savedBatchData != null
        ? savedBatchData!.map((e) => Map<String, String>.from(e)).toList()
        : null;
    newRow.hasBatchData = hasBatchData;
    newRow.batchCount = batchCount;
    newRow.purchaseOrderId = purchaseOrderId;
    newRow.purchaseOrderNumber = purchaseOrderNumber;
    newRow.purchaseReceiveId = purchaseReceiveId;
    newRow.purchaseReceiveNumber = purchaseReceiveNumber;
    newRow.purchaseReceiveItemId = purchaseReceiveItemId;
    return newRow;
  }

  double get quantity {
    return double.tryParse(quantityCtrl.text.trim()) ?? 0;
  }

  double get freeQuantity {
    return double.tryParse(freeQtyCtrl.text.trim()) ?? 0;
  }

  double get rate => double.tryParse(rateCtrl.text) ?? 0;
  double get discountValue => double.tryParse(discountCtrl.text) ?? 0;

  double get amount {
    double base = quantity * rate;
    if (discountType == '%') {
      return base - (base * discountValue / 100);
    }
    return base - discountValue;
  }

  String? _formatToIsoDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      final trimmed = dateStr.trim();
      var parts = trimmed.split('-');
      if (parts.length != 3) {
        parts = trimmed.split('/');
      }
      if (parts.length == 3) {
        // If it starts with a 4-digit year, it's already YYYY-MM-DD
        if (parts[0].length == 4) {
          return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
        }
        // If it ends with a 4-digit year, it's DD-MM-YYYY or MM-DD-YYYY
        if (parts[2].length == 4) {
          return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }
    } catch (_) {}
    return dateStr;
  }

  PurchasesBillLineItem toModel({String? warehouseId, bool isUnregistered = false}) {
    final batchesList = savedBatchData?.map((batch) {
      final qty = double.tryParse(batch['qtyOut'] ?? '') ?? 0;
      final foc = double.tryParse(batch['foc'] ?? '') ?? 0;
      final mrpVal = double.tryParse(batch['mrp'] ?? '') ?? 0;
      final ptrVal = double.tryParse(batch['prate'] ?? '') ?? 0;

      return {
        'batchId': batch['batchId'] != null && batch['batchId']!.isNotEmpty
            ? batch['batchId']
            : null,
        'binId': batch['binId'] != null && batch['binId']!.isNotEmpty
            ? batch['binId']
            : null,
        'warehouseId': warehouseId,
        'quantity': qty,
        'focQuantity': foc,
        'purchaseRate': ptrVal,
        'mrp': mrpVal,
        'expiryDate': _formatToIsoDate(batch['expDate']),
        'manufactureDate': _formatToIsoDate(batch['mfgDate']),
        'manufactureBatchNo':
            batch['mfgBatch'] != null && batch['mfgBatch']!.isNotEmpty
            ? batch['mfgBatch']
            : null,
        'isDirectBill': true,
      };
    }).toList();

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
      freeQuantity: freeQuantity,
      accountId: accountId,
      accountName: accountName,
      quantity: quantity,
      rate: rate,
      taxId: (isUnregistered || taxId == 'non_taxable' || taxId == 'out_of_scope' || taxId == 'non_gst') ? null : taxId,
      taxName: (isUnregistered || taxId == 'non_taxable' || taxId == 'out_of_scope' || taxId == 'non_gst') ? null : taxName,
      customerId: customerId,
      customerName: customerName,
      discount: discountValue,
      discountType: discountType,
      amount: amount,
      isLandedCost: isLandedCost,
      batches: batchesList,
      purchaseReceiveItemId: purchaseReceiveItemId,
      discountAccountId: discountAccountId,
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
  final String? editBillId;
  final String? cloneBillId;
  final String? poId;
  final String? receiveId;
  const PurchasesBillCreateScreen({super.key, this.editBillId, this.cloneBillId, this.poId, this.receiveId});

  @override
  ConsumerState<PurchasesBillCreateScreen> createState() =>
      _PurchasesBillCreateScreenState();
}

class _PurchasesBillCreateScreenState
    extends ConsumerState<PurchasesBillCreateScreen>
    with TickerProviderStateMixin {
  static const double _fieldHeight = 32;

  final TextInputFormatter _numericInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty || RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
          return newValue;
        }
        return oldValue;
      });

  bool get _isKeralaPlaceOfSupply {
    final srcKL = _sourceOfSupply?.toLowerCase().contains('kerala') ?? false;
    final destKL = _destinationOfSupply?.toLowerCase().contains('kerala') ?? false;
    return srcKL && destKL;
  }

  // ─── Form state ────────────────────────────────────────────────────────────
  Vendor? _selectedVendor;
  List<PurchaseOrder> _openPurchaseOrders = [];
  List<Map<String, dynamic>> _poReceivesList = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _poBillsList = [];
  // ignore: unused_field
  bool _vendorDropdownOpen = false;

  final TextEditingController _vendorSearchCtrl = TextEditingController();

  final LayerLink _vendorLayerLink = LayerLink();
  OverlayEntry? _vendorOverlayEntry;

  final LayerLink _billingAddressLink = LayerLink();
  final LayerLink _shippingAddressLink = LayerLink();
  OverlayEntry? _addressDropdownOverlay;

  final TextEditingController _billNumberCtrl = TextEditingController();
  final TextEditingController _orderNumberCtrl = TextEditingController();
  final TextEditingController _billDateCtrl = TextEditingController();
  final TextEditingController _dueDateCtrl = TextEditingController();
  final TextEditingController _invoiceTotalCtrl = TextEditingController();
  String? _paymentTerms;
  String? _existingBillSourceType;
  String? _existingBillSourceId;
  bool _reverseCharge = false;
  OverlayEntry? _itemOverlayEntry;
  OverlayEntry? _hsnOverlayEntry;
  OverlayEntry? _sidebarOverlayEntry;
  OverlayEntry? _itemDetailsSidebarOverlay;
  OverlayEntry? _addRowDropdownOverlay;
  final LayerLink _addRowDropdownLink = LayerLink();
  // ignore: unused_field
  bool _isContactPersonsExpanded = true;
  // ignore: unused_field
  bool _isAddressExpanded = false;
  // ignore: unused_field
  String _activeSidebarTab = 'Details';
  // ignore: unused_field
  bool _hasAddress = false;
  int? _hoveredRowIndex;
  int? _activeMenuRowIndex;
  int _highlightedIndex = -1;
  final TextEditingController _subjectCtrl = TextEditingController();
  Map<String, dynamic>? _customBillingAddress;

  String? _warehouse;
  String _discountType = 'At Transaction Level';
  bool _isDiscountBeforeTax = true;
  String _transactionDiscountType = '%';
  OverlayEntry? _transactionDiscountTypeOverlay;
  final LayerLink _transactionDiscountTypeLink = LayerLink();
  bool _isAdjustmentLabelHovered = false;
  final FocusNode _adjustmentLabelFocusNode = FocusNode();
  final LayerLink _totalTaxAmountLink = LayerLink();
  OverlayEntry? _taxAmountOverlay;
  final LayerLink _gstTaxLink = LayerLink();
  OverlayEntry? _gstTaxOverlay;
  final LayerLink _gstinLink = LayerLink();
  OverlayEntry? _gstinOverlay;
  String? _sourceOfSupply;
  String? _destinationOfSupply;
  String? _discountAccountId;
  // ignore: unused_field
  String? _orgDefaultState;

  final List<String> _statesList = [];
  final Map<String, String> _stateIdMap = {};
  final List<String> _gstTreatments = [];

  @override
  void dispose() {
    _transactionDiscountTypeOverlay?.remove();
    _transactionDiscountTypeOverlay = null;
    _vendorOverlayEntry?.remove();
    _vendorOverlayEntry = null;
    _addressDropdownOverlay?.remove();
    _addressDropdownOverlay = null;
    _itemOverlayEntry?.remove();
    _itemOverlayEntry = null;
    _hsnOverlayEntry?.remove();
    _hsnOverlayEntry = null;
    _sidebarOverlayEntry?.remove();
    _sidebarOverlayEntry = null;
    _itemDetailsSidebarOverlay?.remove();
    _itemDetailsSidebarOverlay = null;
    _addRowDropdownOverlay?.remove();
    _addRowDropdownOverlay = null;
    _moreOverlayEntry?.remove();
    _moreOverlayEntry = null;
    _uploadOverlay?.remove();
    _uploadOverlay = null;
    _attachmentListOverlay?.remove();
    _attachmentListOverlay = null;
    _taxOverlayEntry?.remove();
    _taxOverlayEntry = null;
    _customerOverlayEntry?.remove();
    _customerOverlayEntry = null;

    _vendorSearchCtrl.dispose();
    _billNumberCtrl.dispose();
    _orderNumberCtrl.dispose();
    _billDateCtrl.dispose();
    _dueDateCtrl.dispose();
    _invoiceTotalCtrl.dispose();
    _subjectCtrl.dispose();
    _adjustmentLabelCtrl.dispose();
    _adjustmentAmountCtrl.dispose();
    _discountPercentCtrl.dispose();
    _totalsTaxSearchCtrl.dispose();
    _totalsTaxSearchFocus.dispose();
    _notesCtrl.dispose();
    _itemDetailsSearchCtrl.dispose();
    _adjustmentLabelFocusNode.dispose();
    _taxAmountOverlay?.remove();
    _taxAmountOverlay = null;
    _gstTaxOverlay?.remove();
    _gstTaxOverlay = null;
    _gstinOverlay?.remove();
    _gstinOverlay = null;
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
    text: '',
  );
  final TextEditingController _discountPercentCtrl = TextEditingController(
    text: '',
  );
  OverlayEntry? _moreOverlayEntry;
  String _tdsTcsType = 'none'; // 'tds' | 'tcs' | 'none'
  String? _selectedTdsTcsId;
  double _tdsTcsRate = 0.0;
  List<Map<String, dynamic>> _tdsRatesList = [];
  List<Map<String, dynamic>> _tdsSectionsList = [];
  List<Map<String, dynamic>> _tdsGroupsList = [];
  List<Map<String, dynamic>> _tcsRatesList = [];
  List<Map<String, dynamic>> _tcsNaturesList = [];
  bool _isLoadingTdsRates = false;
  Future<void>? _loadTdsFuture;
  bool _isTdsOpen = false;
  final LayerLink _tdsLink = LayerLink();
  OverlayEntry? _tdsOverlay;

  bool _bulkMode = false;
  final Set<int> _selectedRows = <int>{};
  bool _showStockInfo = true;
  bool _showRecentTransactions = true;
  bool _showPriceList = true;
  final Set<int> _hiddenDetails = <int>{};
  OverlayEntry? _discountOverlay;
  int? _activeDiscountRowIndex;
  OverlayEntry? _accountOverlay;
  int? _activeAccountRowIndex;
  OverlayEntry? _itemMenuOverlay;

  // Search/pricing variables
  bool _showSearchItemDetails = false;
  String _itemDetailsSearchQuery = '';
  final TextEditingController _itemDetailsSearchCtrl = TextEditingController();
  String? _selectedPriceListId;
  coa.AccountNode? _selectedPopupAccount;
  String _stockView = 'availableForSale'; // 'stockOnHand' | 'availableForSale'
  String _stockType = 'Physical'; // 'Physical' | 'Accounting'

  final TextEditingController _totalsTaxSearchCtrl = TextEditingController();
  final FocusNode _totalsTaxSearchFocus = FocusNode();

  final TextEditingController _notesCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingData = false;
  late Future<void> _lookupsFuture;

  final LayerLink _uploadLink = LayerLink();
  final LayerLink _attachmentBadgeLink = LayerLink();
  OverlayEntry? _attachmentListOverlay;
  OverlayEntry? _uploadOverlay;
  List<PlatformFile> _attachedFiles = [];
  bool _isUploadButtonHovered = false;

  // ─── Payment Terms options ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _paymentTermsList = [];
  String? _defaultPaymentTermId;

  OverlayEntry? _taxOverlayEntry;
  int _highlightedTaxIndex = -1;
  _BillLineItemRow? _activeTaxPopoverRow;
  OverlayEntry? _customerOverlayEntry;
  int _highlightedCustomerIndex = -1;
  OverlayEntry? _reportingTagsOverlay;

  // ─────────────────────────────────────────── Lifecycle ────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(warehousesProvider);
      ref.invalidate(vendorProvider);
      ref.invalidate(priceListNotifierProvider);
      ref.invalidate(branchPriceListNotifierProvider);
    });
    _adjustmentLabelFocusNode.addListener(_onAdjustmentLabelFocusChanged);
    _lineItems.add(_BillLineItemRow());
    // Set today as due date default
    _dueDateCtrl.text = DateFormat(
      'dd-MM-yyyy',
    ).format(DateTime.now().add(const Duration(days: 360)));
    
    _initData();
  }

  void _initData() {
    _isLoadingData = widget.editBillId != null ||
        widget.cloneBillId != null ||
        widget.poId != null ||
        widget.receiveId != null;

    final lookupsCompleter = Completer<void>();
    _lookupsFuture = lookupsCompleter.future;

    Future.microtask(() async {
      try {
        final future = Future.wait([
          ref.read(vendorProvider.notifier).loadVendors(),
          ref.read(itemsControllerProvider.notifier).loadLookupData(),
          _loadPaymentTerms(),
          _loadLookups(),
          _loadTdsRates(),
        ]);
        lookupsCompleter.complete(future.then((_) => null));

        if (widget.editBillId != null || widget.cloneBillId != null) {
          await _loadBillForEdit();
        } else if (widget.poId != null) {
          await _loadPoForConvert();
        } else if (widget.receiveId != null) {
          await _loadReceiveForConvert();
        } else {
          await _lookupsFuture;
        }
      } catch (e) {
        debugPrint('Error loading page details: $e');
        if (!lookupsCompleter.isCompleted) {
          lookupsCompleter.completeError(e);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingData = false;
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(PurchasesBillCreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editBillId != widget.editBillId ||
        oldWidget.cloneBillId != widget.cloneBillId ||
        oldWidget.poId != widget.poId ||
        oldWidget.receiveId != widget.receiveId) {
      _resetState();
      _initData();
    }
  }

  void _resetState() {
    // Remove overlays
    _transactionDiscountTypeOverlay?.remove();
    _transactionDiscountTypeOverlay = null;
    _vendorOverlayEntry?.remove();
    _vendorOverlayEntry = null;
    _addressDropdownOverlay?.remove();
    _addressDropdownOverlay = null;
    _itemOverlayEntry?.remove();
    _itemOverlayEntry = null;
    _hsnOverlayEntry?.remove();
    _hsnOverlayEntry = null;
    _sidebarOverlayEntry?.remove();
    _sidebarOverlayEntry = null;
    _itemDetailsSidebarOverlay?.remove();
    _itemDetailsSidebarOverlay = null;
    _addRowDropdownOverlay?.remove();
    _addRowDropdownOverlay = null;
    _moreOverlayEntry?.remove();
    _moreOverlayEntry = null;
    _uploadOverlay?.remove();
    _uploadOverlay = null;
    _attachmentListOverlay?.remove();
    _attachmentListOverlay = null;
    _taxOverlayEntry?.remove();
    _taxOverlayEntry = null;
    _customerOverlayEntry?.remove();
    _customerOverlayEntry = null;
    _taxAmountOverlay?.remove();
    _taxAmountOverlay = null;
    _gstTaxOverlay?.remove();
    _gstTaxOverlay = null;
    _gstinOverlay?.remove();
    _gstinOverlay = null;

    // Reset controllers
    _vendorSearchCtrl.clear();
    _billNumberCtrl.clear();
    _orderNumberCtrl.clear();
    _billDateCtrl.clear();
    _invoiceTotalCtrl.clear();
    _subjectCtrl.clear();
    _adjustmentLabelCtrl.text = 'Adjustment';
    _adjustmentAmountCtrl.text = '';
    _discountPercentCtrl.text = '';
    _totalsTaxSearchCtrl.clear();
    _notesCtrl.clear();
    _itemDetailsSearchCtrl.clear();

    _dueDateCtrl.text = DateFormat(
      'dd-MM-yyyy',
    ).format(DateTime.now().add(const Duration(days: 360)));

    // Reset state variables
    _selectedVendor = null;
    _openPurchaseOrders = [];
    _poReceivesList = [];
    _poBillsList = [];
    _vendorDropdownOpen = false;
    _paymentTerms = null;
    _existingBillSourceType = null;
    _existingBillSourceId = null;
    _reverseCharge = false;
    _isContactPersonsExpanded = true;
    _isAddressExpanded = false;
    _activeSidebarTab = 'Details';
    _hoveredRowIndex = null;
    _activeMenuRowIndex = null;
    _highlightedIndex = -1;
    _customBillingAddress = null;
    _hasAddress = false;
    _warehouse = null;
    _discountType = 'At Transaction Level';
    _isDiscountBeforeTax = true;
    _transactionDiscountType = '%';
    _sourceOfSupply = null;
    _destinationOfSupply = null;
    _discountAccountId = null;

    // Reset Totals
    _discountPercent = 0;
    _adjustment = 0;
    _tdsTcsType = 'none';
    _selectedTdsTcsId = null;
    _tdsTcsRate = 0.0;
    _bulkMode = false;
    _selectedRows.clear();
    _showSearchItemDetails = false;
    _itemDetailsSearchQuery = '';
    _selectedPriceListId = null;
    _selectedPopupAccount = null;
    _stockView = 'availableForSale';
    _stockType = 'Physical';
    _attachedFiles = [];

    // Clear and reset line items
    for (var row in _lineItems) {
      row.dispose();
    }
    _lineItems.clear();
    _lineItems.add(_BillLineItemRow());
  }


  void _onAdjustmentLabelFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _updateAllStockAvailableValues() {
    for (final row in _lineItems) {
      if (row.itemId != null && row.itemId!.isNotEmpty) {
        final whName = row.warehouseName ?? _warehouse ?? '';
        if (whName.isNotEmpty) {
          ref.read(itemWarehouseStocksProvider(row.itemId!).future).then((stocks) {
            WarehouseStockRow? whRow;
            for (final s in stocks) {
              if (s.name == whName) {
                whRow = s;
                break;
              }
            }
            if (whRow != null) {
              final numbers = _stockType == 'Accounting' ? whRow.accounting : whRow.physical;
              final isSOH = _stockView == 'stockOnHand';
              setState(() {
                row.stockAvailable = isSOH ? numbers.onHand : numbers.available;
              });
            } else {
              setState(() {
                row.stockAvailable = 0.0;
              });
            }
          }).catchError((_) {});
        }
      }
    }
  }

  Future<void> _loadBillForEdit() async {
    final billId = widget.editBillId ?? widget.cloneBillId;
    if (billId == null) return;
    setState(() {
      _isLoading = true;
      _isLoadingData = true;
    });
    try {
      final bill = await ref
          .read(purchasesBillsRepositoryProvider)
          .getBill(billId);

      await _lookupsFuture;

      final vendors = ref.read(vendorProvider).vendors;
      final billVendorName = bill.vendorName;
      Vendor? foundVendor = vendors.where((v) {
        if (bill.vendorId.isNotEmpty && v.id == bill.vendorId) return true;
        if (billVendorName.isNotEmpty && v.displayName.toLowerCase() == billVendorName.toLowerCase()) return true;
        return false;
      }).firstOrNull;

      if (foundVendor == null && bill.vendorId.isNotEmpty) {
        try {
          final repo = ref.read(vendorRepositoryProvider);
          foundVendor = await repo.getVendorById(bill.vendorId);
        } catch (_) {}
      }

      final Vendor matchingVendor = foundVendor ?? Vendor(id: bill.vendorId, displayName: billVendorName, companyName: '');

      final isClone = widget.cloneBillId != null;

      setState(() {
        _existingBillSourceType = bill.sourceType;
        _existingBillSourceId = bill.sourceId;
        _selectedVendor = matchingVendor;
        _billNumberCtrl.text = isClone ? '' : (bill.billNumber ?? '');
        _orderNumberCtrl.text = bill.orderNumber ?? '';
        if (bill.billDate != null) {
          _billDateCtrl.text = DateFormat('dd-MM-yyyy').format(bill.billDate!);
        }
        if (bill.dueDate != null) {
          _dueDateCtrl.text = DateFormat('dd-MM-yyyy').format(bill.dueDate!);
        }
        
        if (bill.paymentTerms != null) {
          final matchingTerm = _paymentTermsList.firstWhere(
            (t) => t['term_name'] == bill.paymentTerms || t['id'] == bill.paymentTerms,
            orElse: () => <String, dynamic>{},
          );
          if (matchingTerm.isNotEmpty) {
            _paymentTerms = matchingTerm['id'];
          }
        }

        _reverseCharge = bill.isReverseCharge;
        _subjectCtrl.text = bill.subject ?? '';
        _notesCtrl.text = bill.notes ?? '';
        _adjustmentLabelCtrl.text = bill.adjustmentLabel ?? 'Adjustment';
        _adjustmentAmountCtrl.text = bill.adjustment == 0 ? '' : bill.adjustment.toStringAsFixed(2);
        _adjustment = bill.adjustment;
        _discountPercentCtrl.text = bill.discountPercent == 0 ? '' : bill.discountPercent.toString();
        _discountPercent = bill.discountPercent;
        _invoiceTotalCtrl.text = bill.invoiceTotal > 0 ? bill.invoiceTotal.toStringAsFixed(2) : '';
        // Reconstruct TDS/TCS type, ID, and rate
        if (bill.tdsTotal > 0) {
          _tdsTcsType = 'tds';
          final double computedRate = bill.tdsTotal / (bill.subTotal - bill.discountAmount) * 100;
          final matchedRate = _tdsRatesList.firstWhere(
            (r) => ((double.tryParse(r['base_rate']?.toString() ?? '0') ?? 0.0) - computedRate).abs() < 0.01,
            orElse: () => <String, dynamic>{},
          );
          if (matchedRate.isNotEmpty) {
            _selectedTdsTcsId = matchedRate['id']?.toString();
            _tdsTcsRate = double.tryParse(matchedRate['base_rate']?.toString() ?? '0') ?? 0.0;
          } else {
            _selectedTdsTcsId = null;
            _tdsTcsRate = computedRate;
          }
        } else if (bill.tcsTotal > 0) {
          _tdsTcsType = 'tcs';
          final double computedRate = bill.tcsTotal / (bill.subTotal - bill.discountAmount) * 100;
          final matchedRate = _tcsRatesList.firstWhere(
            (r) => ((double.tryParse(r['rate']?.toString() ?? '0') ?? 0.0) - computedRate).abs() < 0.01,
            orElse: () => <String, dynamic>{},
          );
          if (matchedRate.isNotEmpty) {
            _selectedTdsTcsId = matchedRate['id']?.toString();
            _tdsTcsRate = double.tryParse(matchedRate['rate']?.toString() ?? '0') ?? 0.0;
          } else {
            _selectedTdsTcsId = null;
            _tdsTcsRate = computedRate;
          }
        } else {
          _tdsTcsType = 'tds';
          _selectedTdsTcsId = null;
          _tdsTcsRate = 0.0;
        }


        // Fetch billing address and source of supply from the vendor
        final String? vendorSource = matchingVendor.sourceOfSupply;
        final String? billingState = matchingVendor.billingAddress?['state']?.toString();
        final String resolvedState =
            (vendorSource != null && vendorSource.isNotEmpty)
            ? vendorSource
            : ((billingState != null && billingState.isNotEmpty)
                  ? billingState
                  : '[KL] - Kerala');

        _sourceOfSupply = bill.sourceOfSupply ?? bill.placeOfSupply ?? resolvedState;
        _destinationOfSupply = bill.destinationToSupply ?? bill.placeOfSupply ?? resolvedState;

        if (bill.warehouseName != null) {
          _warehouse = bill.warehouseName;
        }

        _lineItems.clear();
        final itemsState = ref.read(itemsControllerProvider);

        for (final item in bill.lineItems) {
          final row = _BillLineItemRow(isLandedCost: item.isLandedCost);
          row.itemId = item.itemId;
          row.itemName = item.itemName;
          row.purchaseReceiveItemId = item.purchaseReceiveItemId;
          row.itemNameCtrl.text = item.itemName ?? '';
          row.hsnCode = item.hsnCode;
          row.hsnCtrl.text = item.hsnCode ?? '';
          row.descriptionCtrl.text = item.description ?? '';
          row.batchCtrl.text = item.batch ?? '';
          row.unitPackCtrl.text = item.unitPack ?? '';
          row.expiry = item.expiry;
          if (item.expiry != null) {
            row.expiryCtrl.text = DateFormat('dd-MM-yyyy').format(item.expiry!);
          }
          row.mrpCtrl.text = item.mrp.toStringAsFixed(2);
          row.ptrCtrl.text = item.ptr.toStringAsFixed(2);
          row.freeQtyCtrl.text = item.freeQuantity.toString();
          row.accountId = item.accountId;
          row.accountName = item.accountName;
          row.quantityCtrl.text = item.quantity.toString();
          row.rateCtrl.text = item.rate.toStringAsFixed(2);
          row.taxId = item.taxId;
          row.taxName = item.taxName;
          row.customerId = item.customerId;
          row.customerName = item.customerName;
          row.discountCtrl.text = item.discount.toString();
          row.discountType = item.discountType;
          row.itemType = item.productType;

          final taxId = item.taxId;
          final matchedTax = itemsState.taxGroups
              .where((tg) => tg.id == taxId)
              .firstOrNull;
          row.taxRate = matchedTax?.taxRate ?? 0.0;

          final List<Map<String, String>> batchDataList = [];
          if (item.batches != null) {
            for (final b in item.batches!) {
              final Map<String, dynamic> bMap = Map<String, dynamic>.from(b as Map);
              final batchMaster = bMap['batch'] != null ? Map<String, dynamic>.from(bMap['batch'] as Map) : null;

              final batchNo = batchMaster?['batch_no']?.toString() ?? bMap['manufacture_batch_no']?.toString() ?? '';

              String expDate = '';
              try {
                if (bMap['expiry_date'] != null) {
                  expDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(bMap['expiry_date']));
                } else if (batchMaster?['expiry_date'] != null) {
                  expDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(batchMaster!['expiry_date']));
                }
              } catch (_) {}

              String mfgDate = '';
              try {
                if (bMap['manufacture_date'] != null) {
                  mfgDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(bMap['manufacture_date']));
                }
              } catch (_) {}

              batchDataList.add({
                'batchId': bMap['batch_id']?.toString() ?? '',
                'binId': bMap['bin_id']?.toString() ?? '',
                'qtyOut': bMap['quantity']?.toString() ?? '0',
                'foc': bMap['foc_quantity']?.toString() ?? '0',
                'prate': bMap['purchase_rate']?.toString() ?? '0.00',
                'mrp': bMap['mrp']?.toString() ?? '0.00',
                'expDate': expDate,
                'mfgDate': mfgDate,
                'mfgBatch': batchNo,
              });
            }
          }

          row.savedBatchData = batchDataList;
          row.hasBatchData = batchDataList.isNotEmpty;
          row.batchCount = batchDataList.length;

          if (row.hasBatchData) {
            final totalQty = batchDataList.fold<double>(
              0.0,
              (sum, b) => sum + (double.tryParse(b['qtyOut'] ?? '') ?? 0.0),
            );
            final totalFoc = batchDataList.fold<double>(
              0.0,
              (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
            );
            row.quantityCtrl.text = (totalQty + totalFoc).toInt().toString();
          }

          _lineItems.add(row);
        }
      });

      // --- Resolve PO/Receive associations from purchaseReceiveItemId ---
      // Collect all purchaseReceiveItemIds from loaded bill items
      final rxItemIds = <String>[];
      final rxItemIdToRowIndices = <String, List<int>>{};
      for (int i = 0; i < bill.lineItems.length; i++) {
        final rxItemId = bill.lineItems[i].purchaseReceiveItemId;
        if (rxItemId != null && rxItemId.isNotEmpty) {
          rxItemIds.add(rxItemId);
          rxItemIdToRowIndices.putIfAbsent(rxItemId, () => []).add(i);
        }
      }

      if (rxItemIds.isNotEmpty) {
        try {
          final supabase = Supabase.instance.client;
          // Batch lookup: purchase_receive_items → purchase_receive_id
          final rxItemsResp = await supabase
              .from('purchase_receive_items')
              .select('id, purchase_receive_id')
              .inFilter('id', rxItemIds);

          final rxItemToReceiveId = <String, String>{};
          final receiveIds = <String>{};
          if (rxItemsResp is List) {
            for (final ri in rxItemsResp) {
              final riId = ri['id']?.toString() ?? '';
              final prId = ri['purchase_receive_id']?.toString() ?? '';
              if (riId.isNotEmpty && prId.isNotEmpty) {
                rxItemToReceiveId[riId] = prId;
                receiveIds.add(prId);
              }
            }
          }

          // Batch lookup: purchase_receives → purchase_order_id, purchase_receive_number, purchase_order_number
          if (receiveIds.isNotEmpty) {
            final rxResp = await supabase
                .from('purchase_receives')
                .select('id, purchase_order_id, purchase_receive_number, purchase_order_number')
                .inFilter('id', receiveIds.toList());

            final receiveToPoId = <String, String>{};
            final receiveToRxNum = <String, String>{};
            final receiveToPoNum = <String, String>{};
            if (rxResp is List) {
              for (final rx in rxResp) {
                final rxId = rx['id']?.toString() ?? '';
                final poId = rx['purchase_order_id']?.toString() ?? '';
                final rxNum = rx['purchase_receive_number']?.toString() ?? '';
                final poNum = rx['purchase_order_number']?.toString() ?? '';
                if (rxId.isNotEmpty) {
                  if (poId.isNotEmpty) receiveToPoId[rxId] = poId;
                  if (rxNum.isNotEmpty) receiveToRxNum[rxId] = rxNum;
                  if (poNum.isNotEmpty) receiveToPoNum[rxId] = poNum;
                }
              }
            }

            // Assign resolved IDs to line item rows
            if (mounted) {
              setState(() {
                for (final entry in rxItemIdToRowIndices.entries) {
                  final rxItemId = entry.key;
                  final indices = entry.value;
                  final receiveId = rxItemToReceiveId[rxItemId];
                  if (receiveId == null) continue;
                  final poId = receiveToPoId[receiveId];
                  final rxNum = receiveToRxNum[receiveId];
                  final poNum = receiveToPoNum[receiveId];
                  for (final idx in indices) {
                    if (idx < _lineItems.length) {
                      _lineItems[idx].purchaseOrderId = poId;
                      _lineItems[idx].purchaseOrderNumber = poNum;
                      _lineItems[idx].purchaseReceiveId = receiveId;
                      _lineItems[idx].purchaseReceiveNumber = rxNum;
                    }
                  }
                }
              });
            }
          }
        } catch (e) {
          debugPrint('Error resolving PO/receive from bill items: $e');
        }
      }
      // --- End PO/Receive resolution ---

      if (mounted) {
        setState(() {
          if (_lineItems.isEmpty) {
            _lineItems.add(_BillLineItemRow());
          }
          _loadOpenPurchaseOrders();
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load bill for editing', error: e, module: 'purchases');
      ZerpaiToast.error(context, 'Failed to load bill data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReceiveForConvert() async {
    final receiveIdParam = widget.receiveId;
    if (receiveIdParam == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingData = true;
      });
    }
    try {
      final rxRepository = ref.read(purchaseReceiveRepositoryProvider);
      final receiveIds = receiveIdParam.split(',').where((id) => id.isNotEmpty).toList();
      if (receiveIds.isEmpty) return;

      final rxList = <PurchaseReceive>[];
      for (final rId in receiveIds) {
        final rx = await rxRepository.getPurchaseReceive(rId);
        if (rx != null) rxList.add(rx);
      }
      if (rxList.isEmpty) return;

      final rx = rxList.first;

      // Collect all receive item IDs across all receives being loaded
      final allRxItemIds = rxList
          .expand((rx) => rx.items.map((i) => i.id))
          .whereType<String>()
          .toList();

      // Query bill_items that reference these receive items
      final Map<String, double> billedQtyByRxItem = {};
      if (allRxItemIds.isNotEmpty) {
        try {
          final supabase = Supabase.instance.client;
          final existingBillItems = await supabase
              .from('bill_items')
              .select('purchase_receive_item_id, quantity, bills(status, is_delete)')
              .filter('purchase_receive_item_id', 'in', allRxItemIds);

          if (existingBillItems is List) {
            for (final bi in (existingBillItems as List<dynamic>)) {
              final bill = bi['bills'] as Map<dynamic, dynamic>?;
              if (bill != null && (bill['is_delete'] == true || bill['status'] == 'void')) {
                continue; // ignore void or deleted bills
              }
              final rxItemId = bi['purchase_receive_item_id']?.toString() ?? '';
              final qty = double.tryParse(bi['quantity']?.toString() ?? '0') ?? 0;
              billedQtyByRxItem[rxItemId] = (billedQtyByRxItem[rxItemId] ?? 0) + qty;
            }
          }
        } catch (e) {
          AppLogger.error('Failed to query existing bill items for receive quantity calculation', error: e, module: 'purchases');
        }
      }

      await _lookupsFuture;

      PurchaseOrder? po;
      if (rx.purchaseOrderId != null && rx.purchaseOrderId!.isNotEmpty) {
        try {
          final poRepository = ref.read(purchaseOrderRepositoryProvider);
          po = await poRepository.getPurchaseOrder(rx.purchaseOrderId!);
        } catch (_) {}
      }

      final vendors = ref.read(vendorProvider).vendors;
      final rxVendorId = rx.vendorId ?? po?.vendorId;
      final rxVendorName = rx.vendorName ?? po?.vendorName;

      Vendor? foundVendor;
      if (rxVendorId != null && rxVendorId.isNotEmpty) {
        try {
          final repo = ref.read(vendorRepositoryProvider);
          foundVendor = await repo.getVendorById(rxVendorId);
        } catch (_) {}
      }

      if (foundVendor == null && rxVendorName != null && rxVendorName.isNotEmpty) {
        final match = vendors.where((v) => v.displayName.toLowerCase() == rxVendorName.toLowerCase()).firstOrNull;
        if (match != null) {
          try {
            final repo = ref.read(vendorRepositoryProvider);
            foundVendor = await repo.getVendorById(match.id);
          } catch (_) {}
        }
      }

      final Vendor matchingVendor = foundVendor ?? Vendor(id: rxVendorId ?? '', displayName: rxVendorName ?? '', companyName: '');

      if (!mounted) return;
      setState(() {
        _selectedVendor = matchingVendor;
        if (matchingVendor.paymentTerms != null && matchingVendor.paymentTerms!.isNotEmpty) {
          _paymentTerms = matchingVendor.paymentTerms;
        }
        _hasAddress = matchingVendor.billingAddress != null &&
            matchingVendor.billingAddress!.values.any(
              (val) => val != null && val.toString().trim().isNotEmpty,
            );
        _customBillingAddress = null;
        _orderNumberCtrl.text = rx.purchaseOrderNumber ?? po?.orderNumber ?? '';
        _notesCtrl.text = rx.notes ?? po?.notes ?? '';
        _subjectCtrl.text = po?.referenceNumber ?? '';

        _billNumberCtrl.text = rx.billNo ?? '';
        _billDateCtrl.text = rx.billDate != null ? DateFormat('dd-MM-yyyy').format(rx.billDate!) : '';
        _invoiceTotalCtrl.text = rx.invoiceTotal > 0 ? rx.invoiceTotal.toStringAsFixed(2) : '';

        final String? vendorSource = matchingVendor.sourceOfSupply;
        final String? billingState = matchingVendor.billingAddress?['state']?.toString();
        final String resolvedSource =
            (vendorSource != null && vendorSource.isNotEmpty)
            ? _resolveStateName(vendorSource)
            : ((billingState != null && billingState.isNotEmpty)
                  ? _resolveStateName(billingState)
                  : '[KL] - Kerala');

        final String resolvedDest = resolvedSource;

        _sourceOfSupply = resolvedSource;
        _destinationOfSupply = resolvedDest;

        final rxWarehouseId = rx.warehouseId;
        if (rxWarehouseId != null) {
          final warehouses = ref.read(warehousesProvider).valueOrNull ?? <Warehouse>[];
          final match = warehouses.firstWhere(
            (w) => w.id == rxWarehouseId,
            orElse: () => Warehouse(id: rxWarehouseId, name: ''),
          );
          if (match.name.isNotEmpty) {
            _warehouse = match.name;
          }
        } else if (po?.warehouseName != null) {
          _warehouse = po!.warehouseName;
        }

        final poVal = po;
        if (poVal != null && poVal.paymentTerms != null) {
          final terms = poVal.paymentTerms;
          final matchingTerm = _paymentTermsList.firstWhere(
            (t) => t['term_name'] == terms || t['id'] == terms,
            orElse: () => <String, dynamic>{},
          );
          if (matchingTerm.isNotEmpty) {
            _paymentTerms = matchingTerm['id'];
          }
        }

        if (po != null) {
          _discountType = po.discountLevel == 'transaction' ? 'At Transaction Level' : 'At Line Item Level';
          _discountPercentCtrl.text = po.discount == 0 ? '' : po.discount.toString();
          _discountPercent = po.discount;
          _transactionDiscountType = po.discountType == 'percentage' ? '%' : '₹';
          _reverseCharge = po.isReverseCharge;
          _adjustment = po.adjustment;
          _adjustmentAmountCtrl.text = po.adjustment == 0 ? '' : po.adjustment.toStringAsFixed(2);

          _tdsTcsType = po.tdsTcsType ?? 'none';
          _selectedTdsTcsId = po.tdsTcsId;
          _tdsTcsRate = 0.0;
          if (_tdsTcsType != 'none' && _selectedTdsTcsId != null) {
            final isTcs = _tdsTcsType == 'tcs';
            final matchedRate = isTcs
                ? _tcsRatesList.firstWhere(
                    (r) => r['id']?.toString() == _selectedTdsTcsId,
                    orElse: () => <String, dynamic>{},
                  )
                : _tdsRatesList.firstWhere(
                    (r) => r['id']?.toString() == _selectedTdsTcsId,
                    orElse: () => <String, dynamic>{},
                  );
            if (matchedRate.isNotEmpty) {
              _tdsTcsRate = double.tryParse(
                (isTcs ? matchedRate['rate'] : matchedRate['base_rate'])?.toString() ?? '0',
              ) ?? 0.0;
            }
          } else if (_tdsTcsType == 'tcs' && _selectedTdsTcsId != null) {
            final matchedRate = _tcsRatesList.firstWhere(
              (r) => r['id']?.toString() == _selectedTdsTcsId,
              orElse: () => <String, dynamic>{},
            );
            if (matchedRate.isNotEmpty) {
              _tdsTcsRate = double.tryParse(matchedRate['rate']?.toString() ?? '0') ?? 0.0;
            }
          }
        }

        _lineItems.clear();
        for (final currentRx in rxList) {
          final matchedRxItemIds = <String?>{};
          if (po != null) {
            for (final poItem in po.items) {
              if (poItem.isHeader) continue;

              var rxItems = currentRx.items.where((i) =>
                i.itemId == poItem.productId &&
                !matchedRxItemIds.contains(i.id) &&
                (i.ordered - poItem.quantity).abs() < 0.001 &&
                (i.description ?? '').trim() == (poItem.description ?? '').trim()
              ).toList();
              if (rxItems.isEmpty) {
                rxItems = currentRx.items.where((i) => i.itemId == poItem.productId && !matchedRxItemIds.contains(i.id)).toList();
              }
              if (rxItems.isEmpty) continue;
              final rxItem = rxItems.first;
              matchedRxItemIds.add(rxItem.id);

              final row = _BillLineItemRow();
              row.purchaseReceiveId = currentRx.id;
              row.purchaseReceiveNumber = currentRx.purchaseReceiveNumber;
              row.purchaseReceiveItemId = rxItem.id;
              row.purchaseOrderId = po.id;
              row.purchaseOrderNumber = po.orderNumber;
              row.itemId = poItem.productId;
              row.itemName = poItem.productName;
              row.itemNameCtrl.text = poItem.productName ?? '';
              row.hsnCode = poItem.hsnCode;
              row.hsnCtrl.text = poItem.hsnCode ?? '';
              row.descriptionCtrl.text = poItem.description ?? '';
              row.accountId = poItem.accountId;
              row.accountName = poItem.accountName;

              final double totalRxQty = rxItem.quantityToReceive;
              final double alreadyBilled = billedQtyByRxItem[rxItem.id] ?? 0.0;
              double remaining = totalRxQty - alreadyBilled;
              if (remaining < 0) remaining = 0;

              row.quantityCtrl.text = remaining.toInt().toString();
              row.rateCtrl.text = poItem.rate.toStringAsFixed(2);
              row.taxId = poItem.taxId;
              row.taxName = poItem.taxName;
              row.taxRate = poItem.taxRate;
              row.discountCtrl.text = poItem.discount.toString();
              row.discountType = poItem.discountType == 'percentage' ? '%' : '₹';
              row.priceListId = poItem.priceListId;
              row.itemType = poItem.productType;
              row.showAdditionalInfo = true;

              if (rxItem.batches.isNotEmpty) {
                double deductRemaining = alreadyBilled;
                row.savedBatchData = rxItem.batches.map((b) {
                  final double originalQty = b.quantity.toDouble();
                  double adjustedQty = originalQty;
                  if (deductRemaining > 0) {
                    if (adjustedQty >= deductRemaining) {
                      adjustedQty -= deductRemaining;
                      deductRemaining = 0;
                    } else {
                      deductRemaining -= adjustedQty;
                      adjustedQty = 0;
                    }
                  }
                  return {
                    'batchId': b.batchNo,
                    'qtyOut': adjustedQty.toString(),
                    'foc': b.foc.toString(),
                    'mrp': b.mrp.toString(),
                    'prate': b.ptr.toString(),
                    'expDate': b.expiryDate != null ? DateFormat('dd-MM-yyyy').format(b.expiryDate!) : '',
                    'mfgDate': b.manufactureDate != null ? DateFormat('dd-MM-yyyy').format(b.manufactureDate!) : '',
                    'mfgBatch': b.manufactureBatch,
                    'unitPack': b.unitPack,
                    'binId': b.binId ?? '',
                  };
                }).toList();
                row.hasBatchData = true;
                row.batchCount = rxItem.batches.length;

                final totalQty = row.savedBatchData!.fold<double>(
                  0.0,
                  (sum, b) => sum + (double.tryParse(b['qtyOut'] ?? '') ?? 0.0),
                );
                final totalFoc = row.savedBatchData!.fold<double>(
                  0.0,
                  (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
                );
                row.quantityCtrl.text = (totalQty + totalFoc).toInt().toString();
              }

              _lineItems.add(row);
            }
          } else {
            for (final rxItem in currentRx.items) {
              final row = _BillLineItemRow();
              row.purchaseReceiveId = currentRx.id;
              row.purchaseReceiveNumber = currentRx.purchaseReceiveNumber;
              row.purchaseReceiveItemId = rxItem.id;
              row.purchaseOrderId = currentRx.purchaseOrderId;
              row.purchaseOrderNumber = currentRx.purchaseOrderNumber;
              row.itemId = rxItem.itemId;
              row.itemName = rxItem.itemName;
              row.itemNameCtrl.text = rxItem.itemName;
              row.descriptionCtrl.text = rxItem.description ?? '';

              final double totalRxQty = rxItem.quantityToReceive;
              final double alreadyBilled = billedQtyByRxItem[rxItem.id] ?? 0.0;
              double remaining = totalRxQty - alreadyBilled;
              if (remaining < 0) remaining = 0;

              row.quantityCtrl.text = remaining.toInt().toString();
              row.rateCtrl.text = '0.00';
              row.discountCtrl.text = '0';
              row.discountType = '%';
              row.showAdditionalInfo = true;

              if (rxItem.batches.isNotEmpty) {
                double deductRemaining = alreadyBilled;
                row.savedBatchData = rxItem.batches.map((b) {
                  final double originalQty = b.quantity.toDouble();
                  double adjustedQty = originalQty;
                  if (deductRemaining > 0) {
                    if (adjustedQty >= deductRemaining) {
                      adjustedQty -= deductRemaining;
                      deductRemaining = 0;
                    } else {
                      deductRemaining -= adjustedQty;
                      adjustedQty = 0;
                    }
                  }
                  return {
                    'batchId': b.batchNo,
                    'qtyOut': adjustedQty.toString(),
                    'foc': b.foc.toString(),
                    'mrp': b.mrp.toString(),
                    'prate': b.ptr.toString(),
                    'expDate': b.expiryDate != null ? DateFormat('dd-MM-yyyy').format(b.expiryDate!) : '',
                    'mfgDate': b.manufactureDate != null ? DateFormat('dd-MM-yyyy').format(b.manufactureDate!) : '',
                    'mfgBatch': b.manufactureBatch,
                    'unitPack': b.unitPack,
                    'binId': b.binId ?? '',
                  };
                }).toList();
                row.hasBatchData = true;
                row.batchCount = rxItem.batches.length;

                final totalQty = row.savedBatchData!.fold<double>(
                  0.0,
                  (sum, b) => sum + (double.tryParse(b['qtyOut'] ?? '') ?? 0.0),
                );
                final totalFoc = row.savedBatchData!.fold<double>(
                  0.0,
                  (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
                );
                row.quantityCtrl.text = (totalQty + totalFoc).toInt().toString();
              }

              _lineItems.add(row);
            }
          }
        }

        if (_lineItems.isEmpty) {
          _lineItems.add(_BillLineItemRow());
        }
        _updateOrderNumbersFromRows();
        _loadOpenPurchaseOrders();
      });
    } catch (e) {
      AppLogger.error('Failed to load purchase receive for billing', error: e, module: 'purchases');
      if (context.mounted) {
        ZerpaiToast.error(context, 'Failed to load Receive data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPoForConvert() async {
    final poId = widget.poId;
    if (poId == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingData = true;
      });
    }
    try {
      final repository = ref.read(purchaseOrderRepositoryProvider);
      final po = await repository.getPurchaseOrder(poId);

      await _lookupsFuture;

      if (po == null) return;

      // Query existing bills linked to this PO to compute remaining unbilled quantities
      final Map<String, double> billedQtyByProduct = {};
      try {
        final supabase = Supabase.instance.client;
        final existingBills = await supabase
            .from('bills')
            .select('id, status, is_delete, bill_items(product_id, quantity)')
            .eq('order_number', po.orderNumber)
            .eq('is_delete', false)
            .neq('status', 'void');

        if (existingBills != null) {
          for (final bill in (existingBills as List<dynamic>)) {
            final items = bill['bill_items'] as List<dynamic>? ?? [];
            for (final item in items) {
              final prodId = item['product_id']?.toString() ?? '';
              final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
              billedQtyByProduct[prodId] = (billedQtyByProduct[prodId] ?? 0) + qty;
            }
          }
        }
      } catch (e) {
        AppLogger.error('Failed to query existing bills for PO quantity calculation', error: e, module: 'purchases');
      }

      final vendors = ref.read(vendorProvider).vendors;
      final poVendorId = po.vendorId;
      final poVendorName = po.vendorName;
      Vendor? foundVendor;
      if (poVendorId.isNotEmpty) {
        try {
          final repo = ref.read(vendorRepositoryProvider);
          foundVendor = await repo.getVendorById(poVendorId);
        } catch (_) {}
      }

      if (foundVendor == null && poVendorName != null && poVendorName.isNotEmpty) {
        final match = vendors.where((v) => v.displayName.toLowerCase() == poVendorName.toLowerCase()).firstOrNull;
        if (match != null) {
          try {
            final repo = ref.read(vendorRepositoryProvider);
            foundVendor = await repo.getVendorById(match.id);
          } catch (_) {}
        }
      }

      final Vendor matchingVendor = foundVendor ?? Vendor(id: poVendorId, displayName: poVendorName ?? '', companyName: '');

      if (!mounted) return;
      setState(() {
        _selectedVendor = matchingVendor;
        _hasAddress = matchingVendor.billingAddress != null &&
            matchingVendor.billingAddress!.values.any(
              (val) => val != null && val.toString().trim().isNotEmpty,
            );
        _customBillingAddress = null;
        _orderNumberCtrl.text = po.orderNumber;
        _billNumberCtrl.text = po.referenceNumber ?? '';
        _billDateCtrl.text = DateFormat('dd-MM-yyyy').format(po.orderDate);
        // Invoice total is intentionally NOT auto-loaded for PO-based bills;
        // it auto-loads only for purchase-receive-based bills.
        _notesCtrl.text = po.notes ?? '';
        _subjectCtrl.text = po.referenceNumber ?? '';

        final String? vendorSource = matchingVendor.sourceOfSupply;
        final String? billingState = matchingVendor.billingAddress?['state']?.toString();
        final String resolvedSource =
            (vendorSource != null && vendorSource.isNotEmpty)
            ? _resolveStateName(vendorSource)
            : ((billingState != null && billingState.isNotEmpty)
                  ? _resolveStateName(billingState)
                  : '[KL] - Kerala');

        final String resolvedDest = resolvedSource;

        _sourceOfSupply = resolvedSource;
        _destinationOfSupply = resolvedDest;

        if (po.warehouseName != null) {
          _warehouse = po.warehouseName;
        }

        final terms = po.paymentTerms;
        if (terms != null) {
          final matchingTerm = _paymentTermsList.firstWhere(
            (t) => t['term_name'] == terms || t['id'] == terms,
            orElse: () => <String, dynamic>{},
          );
          if (matchingTerm.isNotEmpty) {
            _paymentTerms = matchingTerm['id'];
          }
        }

        _updateDueDateFromPaymentTerms();

        _discountType = po.discountLevel == 'transaction' ? 'At Transaction Level' : 'At Line Item Level';
        _discountPercentCtrl.text = po.discount == 0 ? '' : po.discount.toString();
        _discountPercent = po.discount;
        _transactionDiscountType = po.discountType == 'percentage' ? '%' : '₹';
        _reverseCharge = po.isReverseCharge;
        _adjustment = po.adjustment;
        _adjustmentAmountCtrl.text = po.adjustment == 0 ? '' : po.adjustment.toStringAsFixed(2);

        _tdsTcsType = po.tdsTcsType ?? 'none';
        _selectedTdsTcsId = po.tdsTcsId;
        _tdsTcsRate = 0.0;
        if (_tdsTcsType != 'none' && _selectedTdsTcsId != null) {
          final isTcs = _tdsTcsType == 'tcs';
          final matchedRate = isTcs
              ? _tcsRatesList.firstWhere(
                  (r) => r['id']?.toString() == _selectedTdsTcsId,
                  orElse: () => <String, dynamic>{},
                )
              : _tdsRatesList.firstWhere(
                  (r) => r['id']?.toString() == _selectedTdsTcsId,
                  orElse: () => <String, dynamic>{},
                );
          if (matchedRate.isNotEmpty) {
            _tdsTcsRate = double.tryParse(
              (isTcs ? matchedRate['rate'] : matchedRate['base_rate'])?.toString() ?? '0',
            ) ?? 0.0;
          }
        }

        _lineItems.clear();
        for (final item in po.items) {
          if (item.isHeader) continue;
          final row = _BillLineItemRow();
          row.purchaseOrderId = po.id;
          row.purchaseOrderNumber = po.orderNumber;
          row.itemId = item.productId;
          row.itemName = item.productName;
          row.itemNameCtrl.text = item.productName ?? '';
          row.hsnCode = item.hsnCode;
          row.hsnCtrl.text = item.hsnCode ?? '';
          row.descriptionCtrl.text = item.description ?? '';
          row.accountId = item.accountId;
          row.accountName = item.accountName;

          final double orderedQty = item.quantity;
          final double alreadyBilled = billedQtyByProduct[item.productId] ?? 0.0;
          double remaining = orderedQty - alreadyBilled;
          if (remaining < 0) remaining = 0;

          // FIFO deduction for duplicate product entries
          if (alreadyBilled > 0) {
            final consumed = orderedQty - remaining;
            billedQtyByProduct[item.productId] = alreadyBilled - consumed;
          }

          row.quantityCtrl.text = remaining.toInt().toString();
          row.rateCtrl.text = item.rate.toStringAsFixed(2);
          row.taxId = item.taxId;
          row.taxName = item.taxName;
          row.taxRate = item.taxRate;
          row.discountCtrl.text = item.discount.toString();
          row.discountType = item.discountType == 'percentage' ? '%' : '₹';
          row.priceListId = item.priceListId;
          row.itemType = item.productType;
          row.showAdditionalInfo = true;

          _lineItems.add(row);
        }

        if (_lineItems.isEmpty) {
          _lineItems.add(_BillLineItemRow());
        }
        _updateOrderNumbersFromRows();
        _loadOpenPurchaseOrders();
      });
    } catch (e) {
      AppLogger.error('Failed to load purchase order for billing', error: e, module: 'purchases');
      if (context.mounted) {
        ZerpaiToast.error(context, 'Failed to load PO data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadOpenPurchaseOrders() async {
    final vendorId = _selectedVendor?.id;
    if (vendorId == null) {
      if (mounted) {
        setState(() {
          _openPurchaseOrders = [];
          _poReceivesList = [];
          _poBillsList = [];
        });
      }
      return;
    }
    try {
      final repository = ref.read(purchaseOrderRepositoryProvider);
      final allOrders = await repository.getPurchaseOrders(
        vendorId: vendorId,
        status: 'Issued',
      );

      List<Map<String, dynamic>> receives = [];
      List<Map<String, dynamic>> bills = [];
      List<PurchaseOrder> detailedOrders = [];

      if (allOrders.isNotEmpty) {
        final poIds = allOrders.map((o) => o.id).whereType<String>().toList();
        final poNumbers = allOrders.map((o) => o.orderNumber).toList();

        final supabase = Supabase.instance.client;

        final receivesResp = await supabase
            .from('purchase_receives')
            .select('id, purchase_receive_number, received_date, status, purchase_order_id, bill_no, purchase_receive_items(id, item_id, quantity_to_receive)')
            .filter('purchase_order_id', 'in', poIds)
            .eq('is_delete', false)
            .order('created_at', ascending: true);

        final billsResp = await supabase
            .from('bills')
            .select('id, bill_number, bill_date, status, grand_total, order_number, bill_items(product_id, quantity)')
            .filter('order_number', 'in', poNumbers)
            .order('created_at', ascending: true);

        receives = (receivesResp as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        bills = (billsResp as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

        detailedOrders = await Future.wait(
          allOrders.map((o) async {
            if (o.id == null) return o;
            try {
              final detailed = await repository.getPurchaseOrder(o.id!);
              return detailed ?? o;
            } catch (_) {
              return o;
            }
          }),
        );
      }

      if (mounted) {
        setState(() {
          _openPurchaseOrders = detailedOrders;
          _poReceivesList = receives;
          _poBillsList = bills;
        });
      }
    } catch (e) {
      debugPrint('Error loading open purchase orders: $e');
    }
  }

  double _getUnreceivedQuantity(PurchaseOrder order) {
    final orderId = order.id;
    if (orderId == null) return 0.0;

    // Total Ordered Quantity
    final totalOrdered = order.items.fold(0.0, (sum, item) => sum + (item.isHeader ? 0.0 : item.quantity));

    // Total Received Quantity from active, received transactions
    final poReceives = _poReceivesList.where((rx) =>
        rx['purchase_order_id'] == orderId &&
        rx['status']?.toString().toLowerCase() == 'received').toList();

    double totalReceived = 0.0;
    for (final rx in poReceives) {
      final rxItems = rx['purchase_receive_items'] as List<dynamic>? ?? [];
      for (final item in rxItems) {
        final qty = double.tryParse(item['quantity_to_receive']?.toString() ?? '0.0') ?? 0.0;
        totalReceived += qty;
      }
    }

    final unreceived = totalOrdered - totalReceived;
    return unreceived > 0 ? unreceived : 0.0;
  }



  Future<List<Map<String, String>>> _fetchBatchesForReceive(String rxItemId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('purchase_receive_items')
          .select('id, purchase_receive_item_batches(*)')
          .eq('id', rxItemId)
          .maybeSingle();

      if (response != null) {
        final batches = response['purchase_receive_item_batches'] as List<dynamic>? ?? [];
        return batches.map((b) {
          final Map<String, dynamic> bMap = Map<String, dynamic>.from(b as Map);
          return {
            'batchId': bMap['batch_id']?.toString() ?? bMap['batch_no']?.toString() ?? '',
            'binId': bMap['bin_id']?.toString() ?? '',
            'qtyOut': bMap['quantity']?.toString() ?? '0',
            'foc': bMap['foc_quantity']?.toString() ?? '0',
            'mrp': bMap['mrp']?.toString() ?? '0.00',
            'prate': bMap['purchase_rate']?.toString() ?? '0.00',
            'expDate': bMap['expiry_date'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(bMap['expiry_date'])) : '',
            'mfgDate': bMap['manufacture_date'] != null ? DateFormat('dd-MM-yyyy').format(DateTime.parse(bMap['manufacture_date'])) : '',
            'mfgBatch': bMap['manufacture_batch_no']?.toString() ?? '',
            'unitPack': bMap['unit_pack']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching receive batches: $e');
    }
    return [];
  }



  Future<void> _openEditQuantityDialog(_BillLineItemRow row) async {

    final result = await showDialog<QuantitySplitResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return EditQuantityDialog(
          itemName: row.itemName ?? '',
          productId: row.itemId ?? '',
          currentUnreceivedAllocated: row.purchaseReceiveId == null
              ? row.quantity
              : 0.0,
          initialPurchaseReceiveId: row.purchaseReceiveId,
          initialPurchaseReceiveNumber: row.purchaseReceiveNumber,
          initialPurchaseReceiveQty: row.quantity,
          initialPurchaseReceiveItemId: row.purchaseReceiveItemId,
          description: row.descriptionCtrl.text,
          poId: row.purchaseOrderId,
          poNum: (row.purchaseOrderNumber != null && row.purchaseOrderNumber!.isNotEmpty)
              ? row.purchaseOrderNumber!
              : _orderNumberCtrl.text,
          vendorId: _selectedVendor?.id,
          billId: widget.editBillId,
        );
      },
    );

    if (result != null && mounted) {
      final newRows = <_BillLineItemRow>[];

      // 1. Unreceived portion
      if (result.unreceivedQuantity > 0) {
        final r = row.clone();
        r.purchaseOrderId = row.purchaseOrderId;
        r.purchaseOrderNumber = row.purchaseOrderNumber;
        r.purchaseReceiveId = null;
        r.purchaseReceiveNumber = null;
        r.quantityCtrl.text = result.unreceivedQuantity.toInt().toString();
        newRows.add(r);
      }

      // 2. Receive portions
      for (final split in result.receiveSplits) {
        final r = row.clone();
        r.purchaseOrderId = row.purchaseOrderId;
        r.purchaseOrderNumber = row.purchaseOrderNumber;
        r.purchaseReceiveId = split.receive['id']?.toString();
        r.purchaseReceiveNumber = split.receive['purchase_receive_number']?.toString();
        r.purchaseReceiveItemId = split.receiveItemId;
        r.quantityCtrl.text = split.quantity.toInt().toString();

        final batches = await _fetchBatchesForReceive(
          split.receiveItemId,
        );
        if (batches.isNotEmpty) {
          r.savedBatchData = batches;
          r.hasBatchData = true;
          r.batchCount = batches.length;
        }
        newRows.add(r);
      }

      if (newRows.isNotEmpty) {
        setState(() {
          final idx = _lineItems.indexOf(row);
          if (idx != -1) {
            _lineItems.removeAt(idx);
            for (int i = 0; i < newRows.length; i++) {
              _lineItems.insert(idx + i, newRows[i]);
            }
          }
        });
      }
    }
  }

  Widget _buildPendingOrdersBanner() {
    if (_selectedVendor == null || _openPurchaseOrders.isEmpty) {
      return const SizedBox();
    }

    final count = _openPurchaseOrders.length;
    final linkText = count == 1
        ? '1 Open Purchase Order'
        : '$count Open Purchase Orders';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5), // Soft Pink/Red (matching sales implementation)
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFFFEE2E2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.info,
              size: 15,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),
            const Text(
              'Include ',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _showPendingOrdersDialog,
                child: Text(
                  linkText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isReceiveAlreadyLoaded(String rxId) {
    return _lineItems.any((row) => row.purchaseReceiveId == rxId);
  }

  bool _isPoUnreceivedAlreadyLoaded(String poId) {
    return _lineItems.any((row) => row.purchaseOrderId == poId && row.purchaseReceiveId == null);
  }

  void _updateOrderNumbersFromRows() {
    final uniquePoNumbers = _lineItems
        .map((row) => row.purchaseOrderNumber?.trim())
        .whereType<String>()
        .where((no) => no.isNotEmpty)
        .toSet();
    _orderNumberCtrl.text = uniquePoNumbers.join(', ');
  }

  void _showPendingOrdersDialog() {
    final List<String> selectedReceiveIds = [];
    final List<String> selectedUnreceivedPoIds = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Gather all available options across all open POs
            final allRxIds = <String>[];
            final allPoIdsForUnreceived = <String>[];
            for (final order in _openPurchaseOrders) {
              final rxList = _poReceivesList.where((rx) =>
                  rx['purchase_order_id'] == order.id
              ).toList();
              for (final rx in rxList) {
                if (rx['id'] != null) {
                  allRxIds.add(rx['id'].toString());
                }
              }
              if (_getUnreceivedQuantity(order) > 0 && order.id != null) {
                allPoIdsForUnreceived.add(order.id!);
              }
            }

            final unloadedRxIds = allRxIds.where((id) => !_isReceiveAlreadyLoaded(id)).toList();
            final unloadedPoIdsForUnreceived = allPoIdsForUnreceived.where((id) => !_isPoUnreceivedAlreadyLoaded(id)).toList();

            final bool allChecked = (unloadedRxIds.isNotEmpty || unloadedPoIdsForUnreceived.isNotEmpty) &&
                selectedReceiveIds.length == unloadedRxIds.length &&
                selectedUnreceivedPoIds.length == unloadedPoIdsForUnreceived.length;

            return Dialog(
              alignment: Alignment.topCenter,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: const EdgeInsets.only(top: 0, left: 16, right: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Open Purchase Orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF2563EB),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.x,
                                size: 14,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: _borderColor),
                    const SizedBox(height: 8),
                    if (_openPurchaseOrders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No open purchase orders found for this vendor.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      )
                    else ...[
                      Flexible(
                        child: SingleChildScrollView(
                          child: Table(
                            columnWidths: const {
                              0: FixedColumnWidth(36.0), // Checkbox column
                              1: FlexColumnWidth(6.5),   // Purchase Order Details
                              2: FlexColumnWidth(2.5),   // Warehouse column
                              3: FlexColumnWidth(2.0),   // Date column
                              4: FlexColumnWidth(2.0),   // Amount column
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.top,
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _borderColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: allChecked,
                                          activeColor: const Color(0xFF2563EB),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFD1D5DB),
                                            width: 1.5,
                                          ),
                                          onChanged: (unloadedRxIds.isEmpty && unloadedPoIdsForUnreceived.isEmpty)
                                              ? null
                                              : (val) {
                                                  if (val == true) {
                                                    setDialogState(() {
                                                      selectedReceiveIds.clear();
                                                      selectedReceiveIds.addAll(unloadedRxIds);
                                                      selectedUnreceivedPoIds.clear();
                                                      selectedUnreceivedPoIds.addAll(unloadedPoIdsForUnreceived);
                                                    });
                                                  } else {
                                                    setDialogState(() {
                                                      selectedReceiveIds.clear();
                                                      selectedUnreceivedPoIds.clear();
                                                    });
                                                  }
                                                },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'PURCHASE ORDER DETAILS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'WAREHOUSE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'DATE',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4B5563),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          LucideIcons.arrowDown,
                                          size: 12,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      'AMOUNT',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4B5563),
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              ..._openPurchaseOrders.map((order) {
                                final dateStr = DateFormat(
                                  'dd-MM-yyyy',
                                ).format(order.orderDate);
                                final locationStr = order.warehouseName ?? '—';
                                final amountFormatter =
                                    NumberFormat.currency(
                                      locale: 'en_IN',
                                      symbol: '₹',
                                      decimalDigits: 2,
                                    );
                                final amountStr = amountFormatter.format(
                                  order.total,
                                );

                                // Fetch ALL receives for this PO (even billed ones)
                                final rxList = _poReceivesList.where((rx) =>
                                    rx['purchase_order_id'] == order.id
                                ).toList();
                                final unreceivedQty = _getUnreceivedQuantity(order);

                                // Selectable options for checking the main PO checkbox
                                final selectableRxIds = rxList
                                    .map((rx) => rx['id'].toString())
                                    .toList();
                                final bool hasUnreceived = unreceivedQty > 0;
                                
                                // Only count options that are NOT already loaded in the items table
                                final unloadedSelectableRxIds = selectableRxIds.where((id) => !_isReceiveAlreadyLoaded(id)).toList();
                                final bool isUnreceivedUnloaded = hasUnreceived && order.id != null && !_isPoUnreceivedAlreadyLoaded(order.id!);
                                final int totalUnloadedChildren = unloadedSelectableRxIds.length + (isUnreceivedUnloaded ? 1 : 0);

                                int selectedChildrenCount = 0;
                                for (final id in unloadedSelectableRxIds) {
                                  if (selectedReceiveIds.contains(id)) {
                                    selectedChildrenCount++;
                                  }
                                }
                                if (isUnreceivedUnloaded && selectedUnreceivedPoIds.contains(order.id)) {
                                  selectedChildrenCount++;
                                }

                                final bool? poCheckedState = totalUnloadedChildren == 0
                                    ? false
                                    : (selectedChildrenCount == totalUnloadedChildren
                                        ? true
                                        : (selectedChildrenCount == 0 ? false : null));

                                return TableRow(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: _borderColor),
                                    ),
                                  ),
                                  children: [
                                    // Column 0: Main PO Checkbox
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: poCheckedState,
                                            tristate: true,
                                            activeColor: const Color(0xFF2563EB),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFD1D5DB),
                                              width: 1.5,
                                            ),
                                            onChanged: totalUnloadedChildren == 0 ? null : (val) {
                                              if (val == true) {
                                                if (totalUnloadedChildren == 0) {
                                                  ZerpaiToast.error(
                                                    context,
                                                    'Purchase Order ${order.orderNumber} is already loaded in the items table.',
                                                  );
                                                  return;
                                                }
                                                setDialogState(() {
                                                  for (final id in unloadedSelectableRxIds) {
                                                    if (!selectedReceiveIds.contains(id)) {
                                                      selectedReceiveIds.add(id);
                                                    }
                                                  }
                                                  if (isUnreceivedUnloaded && order.id != null) {
                                                    if (!selectedUnreceivedPoIds.contains(order.id)) {
                                                      selectedUnreceivedPoIds.add(order.id!);
                                                    }
                                                  }
                                                });
                                              } else {
                                                setDialogState(() {
                                                  for (final id in selectableRxIds) {
                                                    selectedReceiveIds.remove(id);
                                                  }
                                                  if (order.id != null) {
                                                    selectedUnreceivedPoIds.remove(order.id);
                                                  }
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Column 1: Details
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.orderNumber,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                          if (order.referenceNumber != null &&
                                              order.referenceNumber!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              order.referenceNumber!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],

                                          // Render child Receives
                                          ...rxList.map((rx) {
                                            final rxId = rx['id']?.toString() ?? '';
                                            final isRxChecked = selectedReceiveIds.contains(rxId);
                                            final rxNumber = rx['purchase_receive_number'] ?? '';
                                            final label = rxNumber.toString();

                                            return Padding(
                                              padding: const EdgeInsets.only(left: 16, top: 6),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: Checkbox(
                                                      value: isRxChecked,
                                                      activeColor: const Color(0xFF2563EB),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(2),
                                                      ),
                                                      side: const BorderSide(
                                                        color: Color(0xFFD1D5DB),
                                                        width: 1.2,
                                                      ),
                                                      onChanged: (val) {
                                                        if (val == true) {
                                                          if (_isReceiveAlreadyLoaded(rxId)) {
                                                            ZerpaiToast.error(
                                                              context,
                                                              'Purchase Receive $rxNumber is already loaded in the items table.',
                                                            );
                                                            return;
                                                          }
                                                        }
                                                        setDialogState(() {
                                                          if (val == true) {
                                                            selectedReceiveIds.add(rxId);
                                                          } else {
                                                            selectedReceiveIds.remove(rxId);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        final isRxChecked = selectedReceiveIds.contains(rxId);
                                                        if (!isRxChecked) {
                                                          if (_isReceiveAlreadyLoaded(rxId)) {
                                                            ZerpaiToast.error(
                                                              context,
                                                              'Purchase Receive $rxNumber is already loaded in the items table.',
                                                            );
                                                            return;
                                                          }
                                                        }
                                                        setDialogState(() {
                                                          if (selectedReceiveIds.contains(rxId)) {
                                                            selectedReceiveIds.remove(rxId);
                                                          } else {
                                                            selectedReceiveIds.add(rxId);
                                                          }
                                                        });
                                                      },
                                                      child: MouseRegion(
                                                        cursor: SystemMouseCursors.click,
                                                        child: Text(
                                                          label,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF2563EB),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),

                                          // Render unreceived quantity option
                                          if (unreceivedQty > 0) ...[
                                            Padding(
                                              padding: const EdgeInsets.only(left: 16, top: 6),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: Checkbox(
                                                      value: selectedUnreceivedPoIds.contains(order.id),
                                                      activeColor: const Color(0xFF2563EB),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(2),
                                                      ),
                                                      side: const BorderSide(
                                                        color: Color(0xFFD1D5DB),
                                                        width: 1.2,
                                                      ),
                                                      onChanged: (val) {
                                                        if (val == true) {
                                                          if (_isPoUnreceivedAlreadyLoaded(order.id!)) {
                                                            ZerpaiToast.error(
                                                              context,
                                                              'Unreceived quantity for Purchase Order ${order.orderNumber} is already loaded in the items table.',
                                                            );
                                                            return;
                                                          }
                                                        }
                                                        setDialogState(() {
                                                          if (val == true) {
                                                            if (order.id != null) {
                                                              selectedUnreceivedPoIds.add(order.id!);
                                                            }
                                                          } else {
                                                            selectedUnreceivedPoIds.remove(order.id);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        final isChecked = selectedUnreceivedPoIds.contains(order.id);
                                                        if (!isChecked) {
                                                          if (_isPoUnreceivedAlreadyLoaded(order.id!)) {
                                                            ZerpaiToast.error(
                                                              context,
                                                              'Unreceived quantity for Purchase Order ${order.orderNumber} is already loaded in the items table.',
                                                            );
                                                            return;
                                                          }
                                                        }
                                                        setDialogState(() {
                                                          if (selectedUnreceivedPoIds.contains(order.id)) {
                                                            selectedUnreceivedPoIds.remove(order.id);
                                                          } else {
                                                            if (order.id != null) {
                                                              selectedUnreceivedPoIds.add(order.id!);
                                                            }
                                                          }
                                                        });
                                                      },
                                                      child: MouseRegion(
                                                        cursor: SystemMouseCursors.click,
                                                        child: Text(
                                                          'Quantity yet to receive : ${unreceivedQty.toStringAsFixed(2)}',
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            fontSize: 12.5,
                                                            color: Color(0xFF374151),
                                                          ),
                                                        ),
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
                                    // Column 2: Warehouse
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        locationStr,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                    // Column 3: Date
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                    // Column 4: Amount
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        amountStr,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF374151),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: (selectedReceiveIds.isEmpty && selectedUnreceivedPoIds.isEmpty)
                                ? null
                                : () {
                                    Navigator.pop(dialogContext);
                                    _addItemsFromSelectedOptions(
                                      selectedReceiveIds,
                                      selectedUnreceivedPoIds,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF54B999),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0x8054B999),
                              disabledForegroundColor: const Color(0xCCFFFFFF),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF4B5563),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
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
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addItemsFromSelectedOptions(
    List<String> selectedReceiveIds,
    List<String> selectedUnreceivedPoIds,
  ) async {
    if (selectedReceiveIds.isEmpty && selectedUnreceivedPoIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final poRepository = ref.read(purchaseOrderRepositoryProvider);
      final rxRepository = ref.read(purchaseReceiveRepositoryProvider);

      final Set<String> poNumbers = {};
      final Set<String> refNumbers = {};
      final Set<String> notes = {};
      String? firstWarehouse;
      String? firstBillNo;
      DateTime? firstBillDate;
      double? firstInvoiceTotal;
      String? firstPaymentTerms;
      String? firstDiscountLevel;
      double? firstDiscount;
      String? firstDiscountType;
      bool? firstReverseCharge;
      double? firstAdjustment;
      String? firstTdsTcsType;
      String? firstTdsTcsId;
      String? firstBillingAddressId;
      String? firstSourceOfSupply;
      String? firstDestinationOfSupply;

      if (mounted) {
        setState(() {
          if (_lineItems.length == 1 &&
              (_lineItems.first.itemId == null || _lineItems.first.itemId!.isEmpty)) {
            _lineItems.clear();
          }
        });
      }

      int addedCount = 0;

      // 1. Process selected Purchase Receives
      for (final rxId in selectedReceiveIds) {
        final rx = await rxRepository.getPurchaseReceive(rxId);
        if (rx == null) continue;

        PurchaseOrder? po;
        if (rx.purchaseOrderId != null && rx.purchaseOrderId!.isNotEmpty) {
          po = await poRepository.getPurchaseOrder(rx.purchaseOrderId!);
        }

        firstBillNo ??= rx.billNo;
        firstBillDate ??= rx.billDate;
        if (rx.invoiceTotal > 0) {
          firstInvoiceTotal ??= rx.invoiceTotal;
        }

        if (po != null) {
          firstBillNo ??= po.referenceNumber;
          firstBillDate ??= po.orderDate;
        }

        if (rx.purchaseOrderNumber != null) {
          poNumbers.add(rx.purchaseOrderNumber!);
        } else if (po != null) {
          poNumbers.add(po.orderNumber);
        }

        if (po != null && po.referenceNumber != null && po.referenceNumber!.isNotEmpty) {
          refNumbers.add(po.referenceNumber!);
        }
        if (rx.notes != null && rx.notes!.isNotEmpty) {
          notes.add(rx.notes!);
        } else if (po != null && po.notes != null && po.notes!.isNotEmpty) {
          notes.add(po.notes!);
        }

        if (po != null) {
          firstWarehouse ??= po.warehouseName;
          firstPaymentTerms ??= po.paymentTerms;
          firstDiscountLevel ??= po.discountLevel;
          firstDiscount ??= po.discount;
          firstDiscountType ??= po.discountType;
          firstReverseCharge ??= po.isReverseCharge;
          firstAdjustment ??= po.adjustment;
          firstTdsTcsType ??= po.tdsTcsType;
          firstTdsTcsId ??= po.tdsTcsId;
          firstBillingAddressId ??= po.billingAddressId;
          firstSourceOfSupply ??= po.sourceOfSupply;
          firstDestinationOfSupply ??= po.destinationToSupply;
        }

        if (po != null) {
          final matchedRxItemIds = <String?>{};
          for (final poItem in po.items) {
            if (poItem.isHeader) continue;

            var rxItems = rx.items.where((i) =>
              i.itemId == poItem.productId &&
              !matchedRxItemIds.contains(i.id) &&
              (i.ordered - poItem.quantity).abs() < 0.001 &&
              (i.description ?? '').trim() == (poItem.description ?? '').trim()
            ).toList();
            if (rxItems.isEmpty) {
              rxItems = rx.items.where((i) => i.itemId == poItem.productId && !matchedRxItemIds.contains(i.id)).toList();
            }
            if (rxItems.isEmpty) continue;
            final rxItem = rxItems.first;
            matchedRxItemIds.add(rxItem.id);

            final row = _BillLineItemRow();
            row.purchaseReceiveId = rx.id;
            row.purchaseReceiveNumber = rx.purchaseReceiveNumber;
            row.purchaseReceiveItemId = rxItem.id;
            row.purchaseOrderId = po.id;
            row.purchaseOrderNumber = po.orderNumber;
            row.itemId = poItem.productId;
            row.itemName = poItem.productName;
            row.itemNameCtrl.text = poItem.productName ?? '';
            row.hsnCode = poItem.hsnCode;
            row.hsnCtrl.text = poItem.hsnCode ?? '';
            row.descriptionCtrl.text = poItem.description ?? '';
            row.accountId = poItem.accountId;
            row.accountName = poItem.accountName;
            row.quantityCtrl.text = rxItem.quantityToReceive.toInt().toString();
            row.rateCtrl.text = poItem.rate.toStringAsFixed(2);
            row.taxId = poItem.taxId;
            row.taxName = poItem.taxName;
            row.taxRate = poItem.taxRate;
            row.discountCtrl.text = poItem.discount.toString();
            row.discountType = poItem.discountType == 'percentage' ? '%' : '₹';
            row.priceListId = poItem.priceListId;
            row.itemType = poItem.productType;
            row.showAdditionalInfo = true;

            if (rxItem.batches.isNotEmpty) {
              row.savedBatchData = rxItem.batches.map((b) {
                return {
                  'batchId': b.batchNo,
                  'qtyOut': b.quantity.toString(),
                  'foc': b.foc.toString(),
                  'mrp': b.mrp.toString(),
                  'prate': b.ptr.toString(),
                  'expDate': b.expiryDate != null ? DateFormat('dd-MM-yyyy').format(b.expiryDate!) : '',
                  'mfgDate': b.manufactureDate != null ? DateFormat('dd-MM-yyyy').format(b.manufactureDate!) : '',
                  'mfgBatch': b.manufactureBatch,
                  'unitPack': b.unitPack,
                  'binId': b.binId ?? '',
                };
              }).toList();
              row.hasBatchData = true;
              row.batchCount = rxItem.batches.length;

              final totalQty = row.savedBatchData!.fold<double>(
                0.0,
                (sum, b) => sum + (double.tryParse(b['qtyOut'] ?? '') ?? 0.0),
              );
              final totalFoc = row.savedBatchData!.fold<double>(
                0.0,
                (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
              );
              row.quantityCtrl.text = (totalQty + totalFoc).toInt().toString();
            }

            if (mounted) {
              setState(() {
                _lineItems.add(row);
              });
            }
            addedCount++;
          }
        } else {
          for (final rxItem in rx.items) {
            final row = _BillLineItemRow();
            row.purchaseReceiveId = rx.id;
            row.purchaseReceiveNumber = rx.purchaseReceiveNumber;
            row.purchaseReceiveItemId = rxItem.id;
            row.purchaseOrderId = rx.purchaseOrderId;
            row.purchaseOrderNumber = rx.purchaseOrderNumber;
            row.itemId = rxItem.itemId;
            row.itemName = rxItem.itemName;
            row.itemNameCtrl.text = rxItem.itemName;
            row.descriptionCtrl.text = rxItem.description ?? '';
            row.quantityCtrl.text = rxItem.quantityToReceive.toInt().toString();
            row.rateCtrl.text = '0.00';
            row.discountCtrl.text = '0';
            row.discountType = '%';
            row.showAdditionalInfo = true;

            if (rxItem.batches.isNotEmpty) {
              row.savedBatchData = rxItem.batches.map((b) {
                return {
                  'batchId': b.batchNo,
                  'qtyOut': b.quantity.toString(),
                  'foc': b.foc.toString(),
                  'mrp': b.mrp.toString(),
                  'prate': b.ptr.toString(),
                  'expDate': b.expiryDate != null ? DateFormat('dd-MM-yyyy').format(b.expiryDate!) : '',
                  'mfgDate': b.manufactureDate != null ? DateFormat('dd-MM-yyyy').format(b.manufactureDate!) : '',
                  'mfgBatch': b.manufactureBatch,
                  'unitPack': b.unitPack,
                  'binId': b.binId ?? '',
                };
              }).toList();
              row.hasBatchData = true;
              row.batchCount = rxItem.batches.length;

              final totalQty = row.savedBatchData!.fold<double>(
                0.0,
                (sum, b) => sum + (double.tryParse(b['qtyOut'] ?? '') ?? 0.0),
              );
              final totalFoc = row.savedBatchData!.fold<double>(
                0.0,
                (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
              );
              row.quantityCtrl.text = (totalQty + totalFoc).toInt().toString();
            }

            if (mounted) {
              setState(() {
                _lineItems.add(row);
              });
            }
            addedCount++;
          }
        }
      }

      // 2. Process selected PO unreceived quantities
      for (final poId in selectedUnreceivedPoIds) {
        final po = await poRepository.getPurchaseOrder(poId);
        if (po == null) continue;

        firstBillNo ??= po.referenceNumber;
        firstBillDate ??= po.orderDate;

        poNumbers.add(po.orderNumber);
        if (po.referenceNumber != null && po.referenceNumber!.isNotEmpty) {
          refNumbers.add(po.referenceNumber!);
        }
        if (po.notes != null && po.notes!.isNotEmpty) {
          notes.add(po.notes!);
        }

        firstWarehouse ??= po.warehouseName;
        firstPaymentTerms ??= po.paymentTerms;
        firstDiscountLevel ??= po.discountLevel;
        firstDiscount ??= po.discount;
        firstDiscountType ??= po.discountType;
        firstReverseCharge ??= po.isReverseCharge;
        firstAdjustment ??= po.adjustment;
        firstTdsTcsType ??= po.tdsTcsType;
        firstTdsTcsId ??= po.tdsTcsId;
        firstBillingAddressId ??= po.billingAddressId;
        firstSourceOfSupply ??= po.sourceOfSupply;
        firstDestinationOfSupply ??= po.destinationToSupply;

        final poReceives = _poReceivesList.where((rx) =>
            rx['purchase_order_id'] == poId &&
            rx['status']?.toString().toLowerCase() == 'received').toList();

        final Map<String, double> productReceivedQty = {};
        for (final rx in poReceives) {
          final rxItems = rx['purchase_receive_items'] as List<dynamic>? ?? [];
          for (final item in rxItems) {
            final productId = item['item_id']?.toString();
            if (productId != null) {
              final qty = double.tryParse(item['quantity_to_receive']?.toString() ?? '0.0') ?? 0.0;
              productReceivedQty[productId] = (productReceivedQty[productId] ?? 0.0) + qty;
            }
          }
        }

        for (final poItem in po.items) {
          if (poItem.isHeader) continue;

          final orderedQty = poItem.quantity;
          final receivedQty = productReceivedQty[poItem.productId] ?? 0.0;
          final remainingQty = orderedQty - receivedQty;

          if (remainingQty > 0) {
            final row = _BillLineItemRow();
            row.purchaseOrderId = po.id;
            row.purchaseOrderNumber = po.orderNumber;
            row.itemId = poItem.productId;
            row.itemName = poItem.productName;
            row.itemNameCtrl.text = poItem.productName ?? '';
            row.hsnCode = poItem.hsnCode;
            row.hsnCtrl.text = poItem.hsnCode ?? '';
            row.descriptionCtrl.text = poItem.description ?? '';
            row.accountId = poItem.accountId;
            row.accountName = poItem.accountName;
            row.quantityCtrl.text = remainingQty.toInt().toString();
            row.rateCtrl.text = poItem.rate.toStringAsFixed(2);
            row.taxId = poItem.taxId;
            row.taxName = poItem.taxName;
            row.taxRate = poItem.taxRate;
            row.discountCtrl.text = poItem.discount.toString();
            row.discountType = poItem.discountType == 'percentage' ? '%' : '₹';
            row.priceListId = poItem.priceListId;
            row.itemType = poItem.productType;
            row.showAdditionalInfo = true;

            if (mounted) {
              setState(() {
                _lineItems.add(row);
              });
            }
            addedCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _updateOrderNumbersFromRows();

          if (_billNumberCtrl.text.isEmpty && firstBillNo != null) {
            _billNumberCtrl.text = firstBillNo;
          }
          if (_billDateCtrl.text.isEmpty && firstBillDate != null) {
            _billDateCtrl.text = DateFormat('dd-MM-yyyy').format(firstBillDate);
          }
          if (_invoiceTotalCtrl.text.isEmpty && firstInvoiceTotal != null) {
            _invoiceTotalCtrl.text = firstInvoiceTotal.toStringAsFixed(2);
          }

          if (notes.isNotEmpty && _notesCtrl.text.trim().isEmpty) {
            _notesCtrl.text = notes.join('\n');
          }
          if (refNumbers.isNotEmpty && _subjectCtrl.text.trim().isEmpty) {
            _subjectCtrl.text = refNumbers.join(', ');
          }

          if (firstWarehouse != null && _warehouse == null) {
            _warehouse = firstWarehouse;
          }

          if (firstPaymentTerms != null && _paymentTerms == null) {
            final matchingTerm = _paymentTermsList.firstWhere(
              (t) => t['term_name'] == firstPaymentTerms || t['id'] == firstPaymentTerms,
              orElse: () => <String, dynamic>{},
            );
            if (matchingTerm.isNotEmpty) {
              _paymentTerms = matchingTerm['id'];
            }
          }

          _updateDueDateFromPaymentTerms();

          if (firstDiscountLevel != null) {
            _discountType = firstDiscountLevel == 'transaction' ? 'At Transaction Level' : 'At Line Item Level';
          }
          if (firstDiscount != null) {
            _discountPercentCtrl.text = firstDiscount == 0 ? '' : firstDiscount.toString();
            _discountPercent = firstDiscount;
          }
          if (firstDiscountType != null) {
            _transactionDiscountType = firstDiscountType == 'percentage' ? '%' : '₹';
          }
          if (firstReverseCharge != null) {
            _reverseCharge = firstReverseCharge;
          }
          if (firstAdjustment != null) {
            _adjustment = firstAdjustment;
            _adjustmentAmountCtrl.text = firstAdjustment == 0 ? '' : firstAdjustment.toStringAsFixed(2);
          }

          if (firstTdsTcsType != null) {
            _tdsTcsType = firstTdsTcsType;
          }
          if (firstTdsTcsId != null) {
            _selectedTdsTcsId = firstTdsTcsId;
            _tdsTcsRate = 0.0;
            if (_tdsTcsType != 'none' && _selectedTdsTcsId != null) {
              final isTcs = _tdsTcsType == 'tcs';
              final matchedRate = isTcs
                  ? _tcsRatesList.firstWhere(
                      (r) => r['id']?.toString() == _selectedTdsTcsId,
                      orElse: () => <String, dynamic>{},
                    )
                  : _tdsRatesList.firstWhere(
                      (r) => r['id']?.toString() == _selectedTdsTcsId,
                      orElse: () => <String, dynamic>{},
                    );
              if (matchedRate.isNotEmpty) {
                _tdsTcsRate = double.tryParse(
                  (isTcs ? matchedRate['rate'] : matchedRate['base_rate'])?.toString() ?? '0',
                ) ?? 0.0;
              }
            }
          }

          if (firstBillingAddressId != null && _selectedVendor != null) {
            final allAddrs = _getAllVendorAddresses(_selectedVendor!);
            final match = allAddrs.firstWhere(
              (a) => a['id']?.toString() == firstBillingAddressId,
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              _customBillingAddress = match;
              _hasAddress = true;
            }
          }

          if (firstSourceOfSupply != null && firstSourceOfSupply.isNotEmpty) {
            _sourceOfSupply = _resolveStateName(firstSourceOfSupply);
          }
          if (firstDestinationOfSupply != null && firstDestinationOfSupply.isNotEmpty) {
            _destinationOfSupply = _resolveStateName(firstDestinationOfSupply);
          }

          _updateAllRowTaxes();
        });

        final sourceListStr = poNumbers.join(', ');
        if (addedCount > 0) {
          ZerpaiToast.success(
            context,
            'Added $addedCount items from selected options of: $sourceListStr',
          );
        } else {
          ZerpaiToast.info(
            context,
            'No items found in selected options of: $sourceListStr',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(
          context,
          'Failed to load details for selected options: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  Future<void> _loadLookups() async {
    try {
      final lookupsService = LookupsApiService();
      final user = ref.read(authUserProvider);
      final orgId = user?.orgId ?? '';

      final results = await Future.wait<dynamic>([
        lookupsService.getStates('IN'),
        lookupsService.getGstTreatments(),
        if (orgId.isNotEmpty)
          ref.read(apiClientProvider).get('/lookups/org/$orgId', useCache: true)
        else
          Future.value(null),
      ]);

      final statesData = results[0];
      final gstData = results[1];
      final Response? orgRes = results[2] != null
          ? (results[2] as Response)
          : null;

      if (!mounted) return;

      final List<String> loadedStates = [];
      final Map<String, String> loadedStateIdMap = {};
      if (statesData is List) {
        for (final s in statesData) {
          if (s is Map) {
            final id = s['id']?.toString() ?? '';
            final code = s['code']?.toString() ?? '';
            final name = s['name']?.toString() ?? '';
            if (code.isNotEmpty && name.isNotEmpty) {
              final formatted = '[$code] - $name';
              loadedStates.add(formatted);
              if (id.isNotEmpty) {
                loadedStateIdMap[id] = formatted;
              }
            }
          }
        }
      }

      final List<String> loadedGst = [];
      if (gstData is List) {
        for (final g in gstData) {
          if (g is Map) {
            final label = g['label']?.toString() ?? '';
            if (label.isNotEmpty) {
              loadedGst.add(label);
            }
          }
        }
      }

      String? defaultState;

      if (orgRes != null && orgRes.success && orgRes.data is Map) {
        final orgMap = orgRes.data as Map<String, dynamic>;
        final orgState = (orgMap['state_name'] ?? orgMap['state'] ?? '')
            .toString()
            .trim();

        if (orgState.isNotEmpty) {
          for (final s in loadedStates) {
            if (s.toLowerCase().contains(orgState.toLowerCase())) {
              defaultState = s;
              break;
            }
          }
        }
      }

      setState(() {
        _statesList.clear();
        _statesList.addAll(loadedStates);

        _stateIdMap.clear();
        _stateIdMap.addAll(loadedStateIdMap);

        _gstTreatments.clear();
        _gstTreatments.addAll(loadedGst);

        _orgDefaultState = defaultState;

        if (_sourceOfSupply == null && defaultState != null) {
          _sourceOfSupply = defaultState;
        }
        if (_destinationOfSupply == null && defaultState != null) {
          _destinationOfSupply = defaultState;
        }
      });
    } catch (e) {
      AppLogger.error('Error loading lookups', error: e, module: 'purchases');
    }
  }

  Future<void> _loadTdsRates() async {
    if (_isLoadingTdsRates) {
      await _loadTdsFuture;
      return;
    }
    _isLoadingTdsRates = true;
    _loadTdsFuture = _performLoadTdsRates();
    await _loadTdsFuture;
    _isLoadingTdsRates = false;
  }

  Future<void> _performLoadTdsRates() async {
    try {
      final lookupsService = LookupsApiService();
      final rates = await lookupsService.getTdsRates();
      final sections = await lookupsService.getTdsSections();
      final tcsRates = await lookupsService.getTcsRates();
      final tcsNatures = await lookupsService.getTcsNatures();
      final groups = await lookupsService.getTdsGroups();
      if (mounted) {
        setState(() {
          _tdsRatesList = rates;
          _tdsSectionsList = sections;
          _tcsRatesList = tcsRates;
          _tcsNaturesList = tcsNatures;
          _tdsGroupsList = groups;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error loading TDS/TCS rates',
        error: e,
        module: 'purchases',
      );
    }
  }


  List<shared.AccountNode> _mapExpenseNodes(List<coa.AccountNode> nodes) {
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
      final grp = account.accountGroup.toLowerCase();
      final typ = account.accountType.toLowerCase();
      if (grp.contains('expense') || typ.contains('expense')) {
        byId.putIfAbsent(account.id, () => account);
      }
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

    final List<shared.AccountNode> flattened = [];
    for (final type in sortedTypes) {
      flattened.add(
        shared.AccountNode(
          id: '__account_type__$type',
          name: type,
          selectable: false,
        ),
      );
      final children = grouped[type]!
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      flattened.addAll(children);
    }

    return flattened;
  }

  Future<void> _loadPaymentTerms() async {
    try {
      final lookupsService = LookupsApiService();
      final terms = await lookupsService.getPaymentTerms();
      final dbDefaultId = await lookupsService.getDefaultPaymentTermId();
      if (mounted) {
        setState(() {
          _paymentTermsList = terms;
          _defaultPaymentTermId = dbDefaultId;
          if (_paymentTerms == null && terms.isNotEmpty) {
            final hasDefault = terms.any((t) => t['id']?.toString() == dbDefaultId);
            if (hasDefault) {
              _paymentTerms = dbDefaultId;
            } else {
              final net30 = terms.firstWhere(
                (t) => t['term_name'] == 'Net 30',
                orElse: () => terms.first,
              );
              _paymentTerms = net30['id'];
            }
            _updateDueDateFromPaymentTerms();
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

  Future<void> _showNewVendorDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.only(
          top: 0,
          bottom: 24,
          left: 40,
          right: 40,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const PurchasesVendorsVendorCreateScreen(isDialog: true),
          ),
        ),
      ),
    );
    if (!mounted) return;
    ref.read(vendorProvider.notifier).loadVendors();
  }

  Widget _buildVendorDropdownItem(Vendor v, bool isSelected, bool isHovered) {
    final firstName = (v.firstName ?? '').trim();
    final initialSource = firstName.isNotEmpty
        ? firstName
        : (v.displayName.isNotEmpty ? v.displayName : '?');
    final initial = initialSource.substring(0, 1).toUpperCase();

    final backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
    final primaryTextColor = isHovered ? Colors.white : _textPrimary;
    final secondaryTextColor = isHovered
        ? Colors.white.withValues(alpha: 0.85)
        : _hintColor;

    final topLine = v.vendorNumber != null && v.vendorNumber!.isNotEmpty
        ? '${v.displayName} | ${v.vendorNumber}'
        : v.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHovered
                  ? Colors.white.withValues(alpha: 0.25)
                  : const Color(0xFFE5E7EB),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isHovered ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: primaryTextColor,
                  ),
                ),
                if (v.companyName != null && v.companyName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    v.companyName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
    if (_transactionDiscountType == '%') {
      return _subTotal * (_discountPercent / 100);
    } else {
      return _discountPercent; // flat value
    }
  }

  double get _taxAmount {
    double total = 0;
    for (final row in _lineItems) {
      final rate = row.taxRate;
      if (rate <= 0) continue;
      double taxableAmount = row.amount;
      if (_isDiscountBeforeTax &&
          _subTotal > 0 &&
          _discountType == 'At Transaction Level') {
        final proportion = row.amount / _subTotal;
        taxableAmount = row.amount - (proportion * _discountAmount);
      }
      total += (taxableAmount * rate / 100);
    }
    return total;
  }

  double get _tdsTcsAmount {
    if (_tdsTcsType == 'none' || _selectedTdsTcsId == null) return 0.0;
    return (_subTotal - _discountAmount) * (_tdsTcsRate / 100);
  }

  double get _total {
    final taxSign = _tdsTcsType == 'tds' ? -1.0 : (_tdsTcsType == 'tcs' ? 1.0 : 0.0);
    final tdsTcsVal = _tdsTcsAmount;
    final activeTax = _reverseCharge ? 0.0 : _taxAmount;
    if (_discountType == 'At Line Item Level') {
      return _subTotal + activeTax + (taxSign * tdsTcsVal) + _adjustment;
    }
    return _subTotal -
        _discountAmount +
        activeTax +
        (taxSign * tdsTcsVal) +
        _adjustment;
  }


  bool get _isSaveAsOpenEnabled {
    final activeRows = _lineItems
        .where((r) => r.itemId != null && r.itemId!.isNotEmpty)
        .toList();
    if (activeRows.isEmpty) return true;
    for (final row in activeRows) {
      if (row.hasBatchData) {
        final q = double.tryParse(row.quantityCtrl.text.trim()) ?? 0.0;
        final totalQtyOut =
            row.savedBatchData?.fold<double>(
              0.0,
              (sum, b) => sum + (double.tryParse(b['qtyOut'] ?? '') ?? 0.0),
            ) ??
            0.0;
        final totalFoc =
            row.savedBatchData?.fold<double>(
              0.0,
              (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
            ) ??
            0.0;
        final totalBatchQty = totalQtyOut + totalFoc;
        if ((totalBatchQty - q).abs() > 0.0001) {
          return false;
        }
      }
    }
    return true;
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

  String _resolveStateName(String? input) {
    if (input == null || input.isEmpty) return '[KL] - Kerala';
    if (_stateIdMap.containsKey(input)) {
      return _stateIdMap[input]!;
    }
    for (final entry in _stateIdMap.entries) {
      if (entry.value.toLowerCase().contains(input.toLowerCase())) {
        return entry.value;
      }
      final cleanEntry = entry.value.replaceAll(RegExp(r'\[.*\]\s*-\s*'), '').trim().toLowerCase();
      final cleanInput = input.replaceAll(RegExp(r'\[.*\]\s*-\s*'), '').trim().toLowerCase();
      if (cleanInput.contains(cleanEntry) || cleanEntry.contains(cleanInput)) {
        return entry.value;
      }
    }
    return input;
  }

  void _selectVendor(Vendor? v) {
    if (!mounted) return;
    setState(() {
      _selectedVendor = v;
      _billNumberCtrl.clear();
      _orderNumberCtrl.clear();
      _billDateCtrl.clear();
      _dueDateCtrl.clear();
      _invoiceTotalCtrl.clear();
      _notesCtrl.clear();
      _subjectCtrl.clear();
      _selectedTdsTcsId = null;
      _tdsTcsRate = 0.0;
      _tdsTcsType = 'none';
      if (v != null && v.tdsRateId != null && v.tdsRateId!.isNotEmpty) {
        _tdsTcsType = 'tds';
        _selectedTdsTcsId = v.tdsRateId;
        final matchedRate = _tdsRatesList.firstWhere(
          (r) => r['id']?.toString() == v.tdsRateId,
          orElse: () => <String, dynamic>{},
        );
        if (matchedRate.isNotEmpty) {
          _tdsTcsRate = double.tryParse(matchedRate['base_rate']?.toString() ?? '0') ?? 0.0;
        }
      }
      _adjustmentAmountCtrl.text = '';
      _adjustment = 0.0;
      _discountPercentCtrl.text = '';
      _discountPercent = 0.0;
      _discountType = 'At Transaction Level';
      _transactionDiscountType = '%';
      for (var row in _lineItems) {
        row.dispose();
      }
      _lineItems = [_BillLineItemRow(defaultWarehouse: _warehouse)];
      _attachedFiles.clear();

      if (v != null) {
        String? resolvedTerms = _defaultPaymentTermId;
        if (v.paymentTerms != null && v.paymentTerms!.isNotEmpty) {
          final matchingTerm = _paymentTermsList.firstWhere(
            (t) => t['term_name'] == v.paymentTerms || t['id'] == v.paymentTerms,
            orElse: () => <String, dynamic>{},
          );
          if (matchingTerm.isNotEmpty) {
            resolvedTerms = matchingTerm['id']?.toString();
          }
        }
        if (resolvedTerms == null && _paymentTermsList.isNotEmpty) {
          final net30 = _paymentTermsList.firstWhere(
            (t) => t['term_name'] == 'Net 30',
            orElse: () => _paymentTermsList.first,
          );
          resolvedTerms = net30['id']?.toString();
        }
        _paymentTerms = resolvedTerms;
        _updateDueDateFromPaymentTerms();
        final String? vendorSource = v.sourceOfSupply;
        final String? billingState = v.billingAddress?['state']?.toString();
        final String resolvedState =
            (vendorSource != null && vendorSource.isNotEmpty)
            ? _resolveStateName(vendorSource)
            : ((billingState != null && billingState.isNotEmpty)
                  ? _resolveStateName(billingState)
                  : '[KL] - Kerala');

        _sourceOfSupply = resolvedState;
        _destinationOfSupply = resolvedState;

        _hasAddress = v.billingAddress != null &&
            v.billingAddress!.values.any(
              (val) => val != null && val.toString().trim().isNotEmpty,
            );
        _customBillingAddress = null;
      } else {
        _paymentTerms = null;
        _sourceOfSupply = null;
        _destinationOfSupply = null;
        _hasAddress = false;
        _customBillingAddress = null;
      }
      _updateAllRowTaxes();
      _loadOpenPurchaseOrders();
    });
  }

  void _updateDueDateFromPaymentTerms() {
    if (_paymentTerms == null) return;
    final term = _paymentTermsList.firstWhere(
      (t) => t['id'] == _paymentTerms,
      orElse: () => <String, dynamic>{},
    );
    if (term.isNotEmpty) {
      final days = int.tryParse(term['number_of_days']?.toString() ?? '0') ?? 0;
      final billDate = _parseUiDate(_billDateCtrl.text) ?? DateTime.now();
      final newDueDate = billDate.add(Duration(days: days));
      _dueDateCtrl.text = DateFormat('dd-MM-yyyy').format(newDueDate);
    }
  }

  void _showValidationError(String message) {
    ZerpaiToast.error(context, message);
  }

  Future<void> _saveBill({required String status}) async {
    if (_isLoading) return;

    if (_selectedVendor == null) {
      _showValidationError('Please select a vendor.');
      return;
    }

    if (_billNumberCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a bill number.');
      return;
    }

    if (_billDateCtrl.text.trim().isEmpty) {
      _showValidationError('Please select a bill date.');
      return;
    }

    if (_invoiceTotalCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter an invoice total.');
      return;
    }
    final parsedInvoiceTotal = double.tryParse(_invoiceTotalCtrl.text.trim()) ?? 0.0;
    if (parsedInvoiceTotal <= 0.0) {
      _showValidationError('Please enter a valid invoice total greater than zero.');
      return;
    }
    if ((parsedInvoiceTotal - _total).abs() >= 0.01) {
      _showValidationError('invoice total amount mismatch with the total amount');
      return;
    }

    final validRows = _lineItems
        .where((r) => r.itemId != null && r.itemId!.isNotEmpty)
        .toList();

    if (validRows.isEmpty) {
      _showValidationError('Please select at least one item.');
      return;
    }

    for (int i = 0; i < _lineItems.length; i++) {
      final row = _lineItems[i];
      if (row.itemId == null || row.itemId!.isEmpty) continue;

      if (row.hsnCode == null || row.hsnCode!.trim().isEmpty) {
        _showValidationError(
          'Please select an HSN code for item: ${row.itemName ?? 'Selected Item'}.',
        );
        return;
      }
      if (row.accountId == null || row.accountId!.trim().isEmpty) {
        _showValidationError(
          'Please select an account for item: ${row.itemName ?? 'Selected Item'}.',
        );
        return;
      }
      if (!row.hasBatchData ||
          row.savedBatchData == null ||
          row.savedBatchData!.isEmpty) {
        _showValidationError(
          'Please select a batch for item: ${row.itemName ?? 'Selected Item'}.',
        );
        return;
      }

      final textQty = double.tryParse(row.quantityCtrl.text.trim()) ?? 0.0;
      final batchQty = row.savedBatchData?.fold<double>(
            0.0,
            (sum, b) => sum + (double.tryParse(b['qtyOut'] ?? '') ?? 0.0),
          ) ??
          0.0;
      final batchFoc = row.savedBatchData?.fold<double>(
            0.0,
            (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
          ) ??
          0.0;

      if ((textQty - (batchQty + batchFoc)).abs() > 0.001) {
        _showValidationError('in row ${i + 1} quantity and batch quantity mismatch');
        return;
      }
    }

    final warehouses = ref.read(warehousesProvider).valueOrNull ?? [];
    final matchingWarehouse = warehouses.firstWhere(
      (w) =>
          w.name.trim().toLowerCase() ==
          (_warehouse ?? '').trim().toLowerCase(),
      orElse: () => Warehouse(id: '', name: ''),
    );
    final String? whId = matchingWarehouse.id.isNotEmpty
        ? matchingWarehouse.id
        : null;
    final String? whName = matchingWarehouse.name.isNotEmpty
        ? matchingWarehouse.name
        : null;

    final billDate = _parseUiDate(_billDateCtrl.text) ?? DateTime.now();
    final dueDate = _parseUiDate(_dueDateCtrl.text);
    final placeOfSupply = _destinationOfSupply ?? _sourceOfSupply;

    final bool isUnregistered =
        _selectedVendor != null &&
        _selectedVendor!.gstTreatment?.toLowerCase() == 'unregistered business';

    final lineItems = validRows
        .map((r) => r.toModel(warehouseId: whId, isUnregistered: isUnregistered))
        .toList();

    String? billingAddressId;
    if (_customBillingAddress != null) {
      billingAddressId = _customBillingAddress!['id']?.toString();
    } else if (_selectedVendor != null && _selectedVendor!.vendorAddresses != null) {
      final billingAddr = _selectedVendor!.vendorAddresses!.firstWhere(
        (a) => (a['is_default_billing'] == true || a['isDefaultBilling'] == true || a['address_type'] == 'billing' || a['addressType'] == 'billing'),
        orElse: () => <String, dynamic>{},
      );
      if (billingAddr.isNotEmpty) {
        billingAddressId = billingAddr['id']?.toString();
      }
    }

    if (billingAddressId == null || billingAddressId.isEmpty) {
      _showValidationError('Billing address is mandatory.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bill = PurchasesBill(
        id: widget.editBillId ?? '',
        billNumber: _billNumberCtrl.text.trim(),
        vendorId: _selectedVendor!.id,
        vendorName: _selectedVendor!.displayName,
        vendorNumber: _selectedVendor!.vendorNumber,
        placeOfSupply: placeOfSupply,
        sourceOfSupply: _sourceOfSupply,
        destinationToSupply: _destinationOfSupply,
        billingAddress: billingAddressId,
        orderNumber: _orderNumberCtrl.text.trim().isEmpty
            ? null
            : _orderNumberCtrl.text.trim(),
        billDate: billDate,
        dueDate: dueDate,
        paymentTerms: _paymentTerms,
        isReverseCharge: _reverseCharge,
        subject: _subjectCtrl.text.trim().isEmpty
            ? null
            : _subjectCtrl.text.trim(),
        warehouseId: whId,
        warehouseName: whName,
        taxLevel: 'item',
        lineItems: lineItems,
        subTotal: _subTotal,
        discountPercent: _discountPercent,
        discountAmount: _discountAmount,
        tdsOrTcs: _tdsTcsType,
        taxId: null,
        taxName: null,
        taxAmount: isUnregistered ? 0.0 : _taxAmount,
        tdsTotal: _tdsTcsType == 'tds' ? _tdsTcsAmount : 0.0,
        tcsTotal: _tdsTcsType == 'tcs' ? _tdsTcsAmount : 0.0,

        adjustmentLabel: _adjustmentLabelCtrl.text.trim().isEmpty
            ? 'Adjustment'
            : _adjustmentLabelCtrl.text.trim(),
        adjustment: _adjustment,
        total: _total,
        invoiceTotal: parsedInvoiceTotal,
        notes: _notesCtrl.text,
        sourceType: widget.poId != null
            ? 'purchase_order'
            : (widget.receiveId != null ? 'purchase_receive' : _existingBillSourceType),
        sourceId: widget.poId ?? widget.receiveId ?? _existingBillSourceId,
        status: status,
        discountAccountId: _discountAccountId,
      );

      final PurchasesBill savedBill;
      if (widget.editBillId != null) {
        savedBill = await ref
            .read(billsProvider.notifier)
            .updateBill(widget.editBillId!, bill);
      } else {
        savedBill = await ref
            .read(billsProvider.notifier)
            .createBill(bill);
      }

      if (_attachedFiles.isNotEmpty) {
        await _saveAttachments(savedBill.id);
      }

      if (mounted) {
        ref.read(apiClientProvider).clearCache('purchase-orders');
        if (widget.poId != null) {
          ref.invalidate(purchaseOrderProvider(widget.poId!));
        }
        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));

        context.go(AppRoutes.bills);
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
        _activeTaxPopoverRow = null;
      });
    }
  }

  void _showTaxPopover(
    BuildContext context,
    _BillLineItemRow row,
    ItemsState itemsState,
  ) {
    _removeTaxOverlay();
    setState(() {
      _activeTaxPopoverRow = row;
    });

    _taxOverlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeTaxOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: row.taxLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: Offset.zero,
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _removeTaxOverlay(),
                child: _TaxSelectionPopover(
                  selectedTaxId: row.taxId,
                  onTaxSelected: (tax) {
                    setState(() {
                      row.taxId = tax.id;
                      row.taxName = tax.taxName;
                      row.taxRate = tax.taxRate;
                    });
                    _removeTaxOverlay();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_taxOverlayEntry!);
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

  void _closeTransactionDiscountTypeOverlay() {
    _transactionDiscountTypeOverlay?.remove();
    _transactionDiscountTypeOverlay = null;
  }

  void _showTransactionDiscountTypeOverlay() {
    _closeTransactionDiscountTypeOverlay();
    final overlay = Overlay.of(context);

    _transactionDiscountTypeOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeTransactionDiscountTypeOverlay,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 45,
            child: CompositedTransformFollower(
              link: _transactionDiscountTypeLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DiscountTypeOverlayItem(
                      label: '%',
                      isSelected: _transactionDiscountType == '%',
                      onTap: () {
                        setState(() {
                          _transactionDiscountType = '%';
                        });
                        _closeTransactionDiscountTypeOverlay();
                      },
                    ),
                    _DiscountTypeOverlayItem(
                      label: '₹',
                      isSelected: _transactionDiscountType == '₹',
                      onTap: () {
                        setState(() {
                          _transactionDiscountType = '₹';
                        });
                        _closeTransactionDiscountTypeOverlay();
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

    overlay.insert(_transactionDiscountTypeOverlay!);
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
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeHsnOverlay,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              width: 320,
              child: CompositedTransformFollower(
                link: row.hsnLayerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: const Offset(-20, 2),
                child: Material(
                  color: Colors.transparent,
                  child: TapRegion(
                    onTapOutside: (_) => _removeHsnOverlay(),
                    child: _HSNCodeEditPopover(
                      initialHsnCode: row.hsnCode ?? '',
                      isService: row.itemType == 'service',
                      onCancel: _removeHsnOverlay,
                      onSave: (hsn) {
                        setState(() {
                          row.hsnCode = hsn;
                          row.hsnCtrl.text = hsn;
                        });
                        _removeHsnOverlay();
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

  void _updateRowRate(_BillLineItemRow row, String? appliedPriceListId, List<PriceList> priceLists) {
    if (row.itemId == null || row.itemId!.isEmpty) return;
    row.priceListId = appliedPriceListId;
    final itemsState = ref.read(itemsControllerProvider);
    final prod = itemsState.items
        .where((item) => item.id == row.itemId)
        .firstOrNull;
    final baseCost = prod?.costPrice ?? 0.0;
    final qty = double.tryParse(row.quantityCtrl.text) ?? 1.0;
    
    final pl = priceLists.where((p) => p.id == appliedPriceListId).firstOrNull;
    if (pl != null) {
      final newRate = pl.calculatePrice(
        row.itemId!,
        baseCost,
        quantity: qty,
      );
      row.rateCtrl.text = newRate.toStringAsFixed(2);
      row.priceListId = pl.id;
    } else {
      row.rateCtrl.text = baseCost.toStringAsFixed(2);
      row.priceListId = null;
    }
  }

  List<PriceList> _getCombinedPriceListsForBranch(String selectedBranchId) {
    final globalPriceLists = ref.read(activePriceListsProvider);
    final branchPriceLists = ref.read(branchPriceListNotifierProvider).valueOrNull ?? <BranchPriceList>[];

    final globalPurchaseLists = globalPriceLists
        .where((pl) => pl.transactionType.toLowerCase() == 'purchase')
        .toList();

    final filteredBranchLists = branchPriceLists
        .where((pl) =>
            pl.status == 'active' &&
            pl.transactionType.toLowerCase() == 'purchase' &&
            (pl.associatedBranches?.contains(selectedBranchId) ?? false))
        .map((b) => PriceList(
              id: b.id,
              name: b.name,
              description: b.description,
              currency: b.currency,
              pricingScheme: b.pricingScheme,
              priceListType: b.priceListType,
              details: b.details,
              roundOffPreference: b.roundOffPreference,
              status: b.status,
              transactionType: b.transactionType,
              isDiscountEnabled: b.isDiscountEnabled,
              percentageType: b.percentageType,
              percentageValue: b.percentageValue,
              itemRates: b.itemRates
                  ?.map((r) => PriceListItemRate(
                        itemId: r.itemId,
                        itemName: r.itemName,
                        sku: r.sku,
                        salesRate: r.salesRate,
                        customRate: r.customRate,
                        discountPercentage: r.discountPercentage,
                        volumeRanges: r.volumeRanges
                            ?.map((vr) => PriceListVolumeRange(
                                  startQuantity: vr.startQuantity,
                                  endQuantity: vr.endQuantity,
                                  customRate: vr.customRate,
                                  discountPercentage: vr.discountPercentage,
                                ))
                            .toList(),
                      ))
                  .toList(),
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
            ))
        .toList();

    return <PriceList>[
      ...globalPurchaseLists,
      ...filteredBranchLists,
    ];
  }

  List<PriceList> _getCombinedPriceLists() {
    final warehouseList = ref.read(warehousesProvider).valueOrNull ?? <Warehouse>[];
    final selectedWh = warehouseList.firstWhere(
      (w) => w.name == _warehouse,
      orElse: () => warehouseList.isNotEmpty ? warehouseList.first : Warehouse(id: '', name: ''),
    );
    final activeEntityId = (Hive.box('config').get('selected_entity_id') as String?)?.trim();
    final selectedBranchId = selectedWh.entityId ?? selectedWh.branchId ?? activeEntityId ?? '';
    return _getCombinedPriceListsForBranch(selectedBranchId);
  }

  List<PriceList> _watchCombinedPriceLists() {
    final globalPriceLists = ref.watch(activePriceListsProvider)
        .where((pl) => pl.transactionType.toLowerCase() == 'purchase')
        .toList();
    final branchPriceListsAsync = ref.watch(branchPriceListNotifierProvider);
    final branchPriceLists = branchPriceListsAsync.valueOrNull ?? <BranchPriceList>[];

    final warehouseList = ref.watch(warehousesProvider).valueOrNull ?? <Warehouse>[];
    final selectedWh = warehouseList.firstWhere(
      (w) => w.name == _warehouse,
      orElse: () => warehouseList.isNotEmpty ? warehouseList.first : Warehouse(id: '', name: ''),
    );
    final activeEntityId = (Hive.box('config').get('selected_entity_id') as String?)?.trim();
    final selectedBranchId = selectedWh.entityId ?? selectedWh.branchId ?? activeEntityId ?? '';

    final filteredBranchLists = branchPriceLists
        .where((pl) =>
            pl.status == 'active' &&
            pl.transactionType.toLowerCase() == 'purchase' &&
            (pl.associatedBranches?.contains(selectedBranchId) ?? false))
        .map((b) => PriceList(
              id: b.id,
              name: b.name,
              description: b.description,
              currency: b.currency,
              pricingScheme: b.pricingScheme,
              priceListType: b.priceListType,
              details: b.details,
              roundOffPreference: b.roundOffPreference,
              status: b.status,
              transactionType: b.transactionType,
              isDiscountEnabled: b.isDiscountEnabled,
              percentageType: b.percentageType,
              percentageValue: b.percentageValue,
              itemRates: b.itemRates
                  ?.map((r) => PriceListItemRate(
                        itemId: r.itemId,
                        itemName: r.itemName,
                        sku: r.sku,
                        salesRate: r.salesRate,
                        customRate: r.customRate,
                        discountPercentage: r.discountPercentage,
                        volumeRanges: r.volumeRanges
                            ?.map((vr) => PriceListVolumeRange(
                                  startQuantity: vr.startQuantity,
                                  endQuantity: vr.endQuantity,
                                  customRate: vr.customRate,
                                  discountPercentage: vr.discountPercentage,
                                ))
                            .toList(),
                      ))
                  .toList(),
              createdAt: b.createdAt,
              updatedAt: b.updatedAt,
            ))
        .toList();

    return <PriceList>[
      ...globalPriceLists,
      ...filteredBranchLists,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(vendorProvider);
    final itemsState = ref.watch(itemsControllerProvider);
    final accountsRoots = ref.watch(chartOfAccountsProvider).roots;
    final activePriceLists = _watchCombinedPriceLists();

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      footer: _buildFooter(),
      child: Skeletonizer(
        enabled: _isLoadingData,
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
                padding: const EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainFields(),
                    const SizedBox(height: 8),
                    _buildReverseChargeRow(),
                    const SizedBox(height: 16),
                    _buildSubjectRow(),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                    ),
                    // ── Warehouse / Discount / Pricing Ribbon ──────────────
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 1300),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Warehouse',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _labelColor,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. Warehouse
                                  SizedBox(
                                    width: 240,
                                    child: _buildWarehouseDropdown(),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                                  const SizedBox(width: 8),
                                  // 2. Discount Type
                                  SizedBox(
                                    width: 220,
                                    child: _buildDiscountTypeDropdown(),
                                  ),
                                  // 4. Price List
                                  const SizedBox(width: 8),
                                  Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 200,
                                    child: _buildPriceListDropdown(activePriceLists),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
          Text(
            widget.editBillId != null ? 'Edit Bill' : 'New Bill',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              if (widget.poId != null && widget.poId!.isNotEmpty) {
                context.go('/purchases/purchase-orders/${widget.poId}');
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
    if (_selectedVendor == null) return const SizedBox.shrink();
    final vendor = _selectedVendor!;
    final hasAddressesInDb = (vendor.billingAddress != null && vendor.billingAddress!.isNotEmpty) ||
        (vendor.shippingAddress != null && vendor.shippingAddress!.isNotEmpty) ||
        (vendor.vendorAddresses != null && vendor.vendorAddresses!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Indented section for addresses and GST
        Padding(
          padding: const EdgeInsets.only(left: 236),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Billing & Shipping Address side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddressBlock(
                    title: 'BILLING ADDRESS',
                    address: _customBillingAddress ?? vendor.billingAddress,
                    showPencil: hasAddressesInDb,
                    link: _billingAddressLink,
                    onEdit: () => _showAddressDropdownList(
                      vendor: vendor,
                      isBilling: true,
                      link: _billingAddressLink,
                    ),
                    onNewAddress: () => _showAddressModal(
                      vendor: vendor,
                      isBilling: true,
                      customTitle: hasAddressesInDb ? 'Additional Address' : 'New Billing Address',
                      isNewAddress: true,
                    ),
                  ),
                  const SizedBox(width: 64),
                  _buildAddressBlock(
                    title: 'SHIPPING ADDRESS',
                    address: vendor.shippingAddress,
                    showPencil: hasAddressesInDb,
                    link: _shippingAddressLink,
                    onEdit: () => _showAddressDropdownList(
                      vendor: vendor,
                      isBilling: false,
                      link: _shippingAddressLink,
                    ),
                    onNewAddress: () => _showAddressModal(
                      vendor: vendor,
                      isBilling: false,
                      customTitle: hasAddressesInDb ? 'Additional Address' : 'New Shipping Address',
                      isNewAddress: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildGstTreatmentRow(),
              _buildGstinRow(),
            ],
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
    final vendors = vendorState.vendors;
    final hasVendor = _selectedVendor != null;
    return SizedBox(
      width: 550,
      child: FormDropdown<Vendor>(
        height: 32,
        itemHeight: 56.0,
        value: _selectedVendor,
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: hasVendor ? FontWeight.bold : FontWeight.normal,
          color: hasVendor ? _textPrimary : _hintColor,
        ),
        items: vendors,
        hint: 'Select a Vendor',
        showSearch: true,
        allowClear: hasVendor,
        menuWidth: 550,
        onChanged: (v) => _selectVendor(v),
        showSettings: true,
        settingsLabel: 'New Vendor',
        settingsIcon: LucideIcons.plus,
        onSettingsTap: _showNewVendorDialog,
        displayStringForValue: (v) => v.displayName,
        itemBuilder: (v, isSelected, isHovered) =>
            _buildVendorDropdownItem(v, isSelected, isHovered),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        showRightBorder: true,
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
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
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
                      _selectedVendor!.gstTreatment ??
                      'Unregistered Business',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          CompositedTransformTarget(
            link: _gstTaxLink,
            child: InkWell(
              onTap: () =>
                  _toggleGstTaxOverlay(_selectedVendor!.gstTreatment ?? ''),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.pencil,
                  size: 11,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGstinRow() {
    if (_selectedVendor == null) return const SizedBox.shrink();
    final gstin = _selectedVendor!.gstin;
    if (gstin == null || gstin.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: _textMuted,
                fontFamily: 'Inter',
              ),
              children: [
                const TextSpan(text: 'GSTIN: '),
                TextSpan(
                  text: gstin,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          CompositedTransformTarget(
            link: _gstinLink,
            child: InkWell(
              onTap: () => _toggleGstinOverlay(gstin),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.pencil,
                  size: 11,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBlock({
    required String title,
    required Map<String, dynamic>? address,
    required VoidCallback onEdit,
    required VoidCallback onNewAddress,
    required bool showPencil,
    required LayerLink link,
  }) {
    final hasAddress = address != null && address.isNotEmpty;
    final lines = <String>[];
    if (hasAddress) {
      final attention = address['attention'] as String? ?? '';
      final street1 = address['street1'] as String? ?? 
                      address['street'] as String? ?? 
                      address['address_street'] as String? ?? 
                      address['addressStreet'] as String? ?? '';
      final street2 = address['street2'] as String? ?? 
                      address['place'] as String? ?? 
                      address['address_place'] as String? ?? 
                      address['addressPlace'] as String? ?? '';
      final city = address['city'] as String? ?? '';
      final state = address['state'] as String? ?? '';
      final zip = address['zip'] as String? ?? 
                  address['pincode'] as String? ?? 
                  address['zipCode'] as String? ?? '';
      final country = address['country'] as String? ?? 
                      address['countryRegion'] as String? ?? 
                      address['country_region'] as String? ?? '';
      final phone = address['phone'] as String? ?? '';
      final fax = address['fax'] as String? ?? '';

      if (attention.isNotEmpty) lines.add(attention);
      if (street1.isNotEmpty) lines.add(street1);
      if (street2.isNotEmpty) lines.add(street2);
      if (city.isNotEmpty) lines.add(city);
      final stateZip = [
        state,
        zip,
      ].where((s) => s.isNotEmpty).join(' ');
      if (stateZip.isNotEmpty) lines.add(stateZip);
      if (country.isNotEmpty) lines.add(country);
      if (phone.isNotEmpty) lines.add('Phone: $phone');
      if (fax.isNotEmpty) lines.add('Fax Number: $fax');
    }

    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              if (showPencil) ...[
                const SizedBox(width: 4),
                CompositedTransformTarget(
                  link: link,
                  child: InkWell(
                    onTap: onEdit,
                    child: const Icon(
                      LucideIcons.pencil,
                      size: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (hasAddress)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address['attention'] != null &&
                    (address['attention'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      address['attention'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ...lines
                    .where(
                      (l) => l != address['attention'],
                    ) // Skip attention if already added
                    .map(
                      (l) => Text(
                        l,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4B5563),
                          height: 1.5,
                        ),
                      ),
                    ),
              ],
            )
          else
            GestureDetector(
              onTap: onNewAddress,
              child: const Text(
                'New Address',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleGstTaxOverlay(String currentTreatment) {
    if (_gstTaxOverlay != null) {
      _closeGstTaxOverlay();
      return;
    }

    final overlay = Overlay.of(context);
    _gstTaxOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeGstTaxOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _gstTaxLink,
            showWhenUnlinked: false,
            offset: const Offset(-30, 20),
            child: Material(
              color: Colors.transparent,
              child: _ConfigureTaxPreferencesDialog(
                initialTreatment: currentTreatment,
                initialGstin: _selectedVendor?.gstin ?? '',
                onUpdate: (val, gstin, isPermanent) async {
                  if (_selectedVendor != null) {
                    final updatedVendor = _selectedVendor!.copyWith(
                      gstTreatment: val,
                      gstin: gstin,
                    );
                    if (isPermanent) {
                      await ref
                          .read(vendorProvider.notifier)
                          .updateVendor(_selectedVendor!.id, updatedVendor);
                    } else {
                      ref
                          .read(vendorProvider.notifier)
                          .updateVendorLocally(_selectedVendor!.id, updatedVendor);
                    }
                    setState(() {
                      _selectedVendor = updatedVendor;
                    });
                  }
                  _closeGstTaxOverlay();
                },
                onCancel: _closeGstTaxOverlay,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_gstTaxOverlay!);
  }

  void _closeGstTaxOverlay() {
    _gstTaxOverlay?.remove();
    _gstTaxOverlay = null;
  }

  void _toggleGstinOverlay(String activeGstin) {
    if (_gstinOverlay != null) {
      _closeGstinOverlay();
      return;
    }

    final overlay = Overlay.of(context);
    _gstinOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeGstinOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _gstinLink,
            showWhenUnlinked: false,
            offset: const Offset(-30, 20),
            child: Material(
              color: Colors.transparent,
              child: _GstinPopover(
                gstin: activeGstin,
                onUpdate: (newGstin) {
                  if (_selectedVendor != null) {
                    setState(() {
                      _selectedVendor = _selectedVendor!.copyWith(
                        gstin: newGstin,
                      );
                    });
                  }
                  _closeGstinOverlay();
                },
                onCancel: _closeGstinOverlay,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_gstinOverlay!);
  }

  void _closeGstinOverlay() {
    _gstinOverlay?.remove();
    _gstinOverlay = null;
  }

  void _showAddressDropdownList({
    required Vendor vendor,
    required bool isBilling,
    required LayerLink link,
  }) {
    _closeAddressDropdownOverlay();
    final allAddresses = _getAllVendorAddresses(vendor);
    
    _addressDropdownOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeAddressDropdownOverlay,
          child: Stack(
            children: [
              const Positioned.fill(
                child: SizedBox.expand(),
              ),
              CompositedTransformFollower(
                link: link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 4),
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                    child: Container(
                      width: 340,
                      constraints: const BoxConstraints(maxHeight: 320),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: allAddresses.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final addr = allAddresses[i];
                                return _buildAddressDropdownItem(
                                  vendor: vendor,
                                  address: addr,
                                  isBilling: isBilling,
                                );
                              },
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          InkWell(
                            onTap: () {
                              _closeAddressDropdownOverlay();
                              _showAddressModal(
                                vendor: vendor,
                                isBilling: isBilling,
                                customTitle: isBilling ? 'Billing Address' : 'Shipping Address',
                                isNewAddress: true,
                              );
                            },
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              color: Colors.white,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.plus, size: 14, color: Color(0xFF2563EB)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add New Address',
                                    style: TextStyle(
                                      fontSize: 12,
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
                ),
              ),
            ],
          ),
        );
      },
    );
    Overlay.of(context).insert(_addressDropdownOverlay!);
  }

  void _closeAddressDropdownOverlay() {
    _addressDropdownOverlay?.remove();
    _addressDropdownOverlay = null;
  }

  Map<String, dynamic> _normalizeAddress(Map<String, dynamic> address) {
    return {
      'attention': address['attention']?.toString() ?? '',
      'street1': (address['street1'] ?? address['street'] ?? address['address_street'] ?? address['addressStreet'] ?? '').toString(),
      'street2': (address['street2'] ?? address['place'] ?? address['address_place'] ?? address['addressPlace'] ?? '').toString(),
      'city': address['city']?.toString() ?? '',
      'state': address['state']?.toString() ?? '',
      'zip': (address['zip'] ?? address['pincode'] ?? address['zipCode'] ?? '').toString(),
      'country': (address['country'] ?? address['countryRegion'] ?? address['country_region'] ?? '').toString(),
      'phone': address['phone']?.toString() ?? '',
      'fax': address['fax']?.toString() ?? '',
      if (address['id'] != null) 'id': address['id'].toString(),
    };
  }

  bool _areAddressesEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    String norm(dynamic val) => (val?.toString() ?? '').trim().toLowerCase();
    
    final streetA = norm(a['street1'] ?? a['street'] ?? a['address_street']);
    final streetB = norm(b['street1'] ?? b['street'] ?? b['address_street']);
    if (streetA != streetB) return false;
    
    final placeA = norm(a['street2'] ?? a['place'] ?? a['address_place'] ?? a['street_2']);
    final placeB = norm(b['street2'] ?? b['place'] ?? b['address_place'] ?? b['street_2']);
    if (placeA != placeB) return false;
    
    if (norm(a['city']) != norm(b['city'])) return false;
    if (norm(a['state']) != norm(b['state'])) return false;
    
    final zipA = norm(a['zip'] ?? a['pincode']);
    final zipB = norm(b['zip'] ?? b['pincode']);
    if (zipA != zipB) return false;
    
    final countryA = norm(a['country'] ?? a['countryRegion'] ?? a['country_region']);
    final countryB = norm(b['country'] ?? b['countryRegion'] ?? b['country_region']);
    if (countryA != countryB) return false;
    
    if (norm(a['phone']) != norm(b['phone'])) return false;
    if (norm(a['attention']) != norm(b['attention'])) return false;
    
    return true;
  }

  Widget _buildAddressDropdownItem({
    required Vendor vendor,
    required Map<String, dynamic> address,
    required bool isBilling,
  }) {
    final attention = address['attention'] as String? ?? '';
    final street1 = address['street1'] as String? ?? 
                    address['street'] as String? ?? 
                    address['address_street'] as String? ?? 
                    address['addressStreet'] as String? ?? '';
    final street2 = address['street2'] as String? ?? 
                    address['place'] as String? ?? 
                    address['address_place'] as String? ?? 
                    address['addressPlace'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final state = address['state'] as String? ?? '';
    final zip = address['zip'] as String? ?? 
                address['pincode'] as String? ?? 
                address['zipCode'] as String? ?? '';
    final country = address['country'] as String? ?? 
                    address['countryRegion'] as String? ?? 
                    address['country_region'] as String? ?? '';
    final phone = address['phone'] as String? ?? '';

    final activeAddress = isBilling ? vendor.billingAddress : vendor.shippingAddress;
    final isSelected = activeAddress != null && _areAddressesEqual(activeAddress, address);

    final lines = <String>[
      if (street1.isNotEmpty) street1,
      if (street2.isNotEmpty) street2,
      [city, state, zip].where((s) => s.isNotEmpty).join(', '),
      if (country.isNotEmpty) country,
      if (phone.isNotEmpty) 'Phone: $phone',
    ];

    final bool isAddrBilling = address['is_default_billing'] == true ||
        address['isDefaultBilling'] == true ||
        address['address_type'] == 'billing' ||
        address['addressType'] == 'billing';
    final bool isAddrShipping = address['is_default_shipping'] == true ||
        address['isDefaultShipping'] == true ||
        address['address_type'] == 'shipping' ||
        address['addressType'] == 'shipping';

    bool canEdit = true;
    if (isBilling) {
      if (isAddrShipping && !isAddrBilling) {
        canEdit = false;
      }
    } else {
      if (isAddrBilling && !isAddrShipping) {
        canEdit = false;
      }
    }

    bool isHovered = false;
    return StatefulBuilder(
      builder: (ctx, setSt) {
        return MouseRegion(
          onEnter: (_) => setSt(() => isHovered = true),
          onExit: (_) => setSt(() => isHovered = false),
          child: GestureDetector(
            onTap: () async {
              _closeAddressDropdownOverlay();
              final updatedAddresses = _updateVendorAddressesDefaultFlags(
                vendor: vendor,
                selectedAddr: address,
                isBilling: isBilling,
              );
              final normalizedAddr = _normalizeAddress(address);
              final updated = isBilling
                  ? vendor.copyWith(
                      billingAddress: normalizedAddr,
                      vendorAddresses: updatedAddresses,
                    )
                  : vendor.copyWith(
                      shippingAddress: normalizedAddr,
                      vendorAddresses: updatedAddresses,
                    );
              
              setState(() {
                _selectedVendor = updated;
                if (isBilling) {
                  _customBillingAddress = null;
                  _hasAddress = true;
                  final String? billingState = normalizedAddr['state']?.toString();
                  if (billingState != null && billingState.isNotEmpty) {
                    _sourceOfSupply = _resolveStateName(billingState);
                    _destinationOfSupply = _resolveStateName(billingState);
                  }
                }
              });

              try {
                ref
                    .read(vendorProvider.notifier)
                    .updateVendorLocally(vendor.id, updated);
                await ref
                    .read(vendorProvider.notifier)
                    .updateVendor(vendor.id, updated);
                if (mounted) {
                  ZerpaiToast.success(context, 'Vendor address updated');
                }
              } catch (e) {
                setState(() {
                  _selectedVendor = vendor;
                });
                ref
                    .read(vendorProvider.notifier)
                    .updateVendorLocally(vendor.id, vendor);
                if (mounted) {
                  ZerpaiToast.error(context, 'Failed to update address: $e');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHovered
                    ? const Color(0xFF3B82F6)
                    : (isSelected ? const Color(0xFFEFF6FF) : Colors.white),
                border: Border.all(
                  color: isHovered
                      ? const Color(0xFF3B82F6)
                      : (isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB)),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          attention.isNotEmpty
                              ? attention
                              : (isBilling ? 'Billing Address' : 'Shipping Address'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isHovered ? Colors.white : (isSelected ? const Color(0xFF2563EB) : const Color(0xFF1F2937)),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHovered && canEdit)
                            GestureDetector(
                              onTap: () {
                                _closeAddressDropdownOverlay();
                                _showAddressModal(
                                  vendor: vendor,
                                  isBilling: isBilling,
                                  initialAddress: address,
                                  customTitle: isBilling ? 'Billing Address' : 'Shipping Address',
                                );
                              },
                              child: Icon(
                                LucideIcons.pencil,
                                size: 13,
                                color: isHovered ? Colors.white : const Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...lines.map(
                    (l) => Text(
                      l,
                      style: TextStyle(
                        fontSize: 11,
                        color: isHovered ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _updateVendorAddressesDefaultFlags({
    required Vendor vendor,
    required Map<String, dynamic> selectedAddr,
    required bool isBilling,
  }) {
    final currentList = vendor.vendorAddresses ?? [];
    bool found = false;
    final newList = currentList.map((addr) {
      final isMatch = _areAddressesEqual(addr, selectedAddr);
      final updatedAddr = Map<String, dynamic>.from(addr);
      
      if (isMatch) {
        found = true;
        if (isBilling) {
          updatedAddr['is_default_billing'] = true;
          updatedAddr['isDefaultBilling'] = true;
        } else {
          updatedAddr['is_default_shipping'] = true;
          updatedAddr['isDefaultShipping'] = true;
        }
      } else {
        if (isBilling) {
          updatedAddr['is_default_billing'] = false;
          updatedAddr['isDefaultBilling'] = false;
        } else {
          updatedAddr['is_default_shipping'] = false;
          updatedAddr['isDefaultShipping'] = false;
        }
      }

      final billingFlag = updatedAddr['is_default_billing'] == true || updatedAddr['isDefaultBilling'] == true;
      final shippingFlag = updatedAddr['is_default_shipping'] == true || updatedAddr['isDefaultShipping'] == true;
      if (billingFlag && shippingFlag) {
        updatedAddr['address_type'] = isBilling ? 'billing' : 'shipping';
        updatedAddr['addressType'] = isBilling ? 'billing' : 'shipping';
      } else if (billingFlag) {
        updatedAddr['address_type'] = 'billing';
        updatedAddr['addressType'] = 'billing';
      } else if (shippingFlag) {
        updatedAddr['address_type'] = 'shipping';
        updatedAddr['addressType'] = 'shipping';
      } else {
        updatedAddr['address_type'] = 'additional';
        updatedAddr['addressType'] = 'additional';
      }

      return updatedAddr;
    }).toList();

    if (!found) {
      final newAddr = {
        ...selectedAddr,
        'is_default_billing': isBilling,
        'isDefaultBilling': isBilling,
        'is_default_shipping': !isBilling,
        'isDefaultShipping': !isBilling,
        'address_type': isBilling ? 'billing' : 'shipping',
        'addressType': isBilling ? 'billing' : 'shipping',
      };
      newList.add(newAddr);
    }
    return newList;
  }

  List<Map<String, dynamic>> _getAllVendorAddresses(Vendor vendor) {
    final list = <Map<String, dynamic>>[];
    if (vendor.vendorAddresses != null && vendor.vendorAddresses!.isNotEmpty) {
      for (final addr in vendor.vendorAddresses!) {
        final mapped = Map<String, dynamic>.from(addr);
        if (mapped['is_default_billing'] == null && mapped['isDefaultBilling'] != null) {
          mapped['is_default_billing'] = mapped['isDefaultBilling'];
        }
        if (mapped['is_default_shipping'] == null && mapped['isDefaultShipping'] != null) {
          mapped['is_default_shipping'] = mapped['isDefaultShipping'];
        }
        if (mapped['isDefaultBilling'] == null && mapped['is_default_billing'] != null) {
          mapped['isDefaultBilling'] = mapped['is_default_billing'];
        }
        if (mapped['isDefaultShipping'] == null && mapped['is_default_shipping'] != null) {
          mapped['isDefaultShipping'] = mapped['is_default_shipping'];
        }
        list.add(mapped);
      }
    } else {
      if (vendor.billingAddress != null && vendor.billingAddress!.isNotEmpty) {
        final Map<String, dynamic> billing = Map<String, dynamic>.from(vendor.billingAddress!);
        billing['is_default_billing'] = true;
        billing['isDefaultBilling'] = true;
        billing['address_type'] = 'billing';
        list.add(billing);
      }
      if (vendor.shippingAddress != null && vendor.shippingAddress!.isNotEmpty) {
        final Map<String, dynamic> shipping = Map<String, dynamic>.from(vendor.shippingAddress!);
        shipping['is_default_shipping'] = true;
        shipping['isDefaultShipping'] = true;
        shipping['address_type'] = 'shipping';
        list.add(shipping);
      }
    }

    final uniqueList = <Map<String, dynamic>>[];
    for (final addr in list) {
      bool exists = false;
      for (final existing in uniqueList) {
        if (_areAddressesEqual(addr, existing)) {
          exists = true;
          if (addr['is_default_billing'] == true || addr['isDefaultBilling'] == true) {
            existing['is_default_billing'] = true;
            existing['isDefaultBilling'] = true;
          }
          if (addr['is_default_shipping'] == true || addr['isDefaultShipping'] == true) {
            existing['is_default_shipping'] = true;
            existing['isDefaultShipping'] = true;
          }
          break;
        }
      }
      if (!exists) {
        uniqueList.add(addr);
      }
    }
    return uniqueList;
  }

  void _showAddressModal({
    Vendor? vendor,
    bool isBilling = true,
    String? customTitle,
    Map<String, dynamic>? initialAddress,
    bool isNewAddress = false,
  }) {
    Map<String, dynamic> existingAddress = {};
    if (initialAddress != null) {
      existingAddress = initialAddress;
    } else if (isNewAddress) {
      existingAddress = {};
    } else if (vendor != null) {
      existingAddress = isBilling
          ? (vendor.billingAddress ?? {})
          : (vendor.shippingAddress ?? {});
    }

    String dialogTitle = customTitle ?? 'New address';
    if (customTitle == null && vendor != null) {
      dialogTitle = isBilling ? 'Billing Address' : 'Shipping Address';
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Address Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) {
        return AddressDialog(
          title: dialogTitle,
          initialAddress: existingAddress,
          onSave: (val) async {
            final isFirstBilling = vendor != null && isBilling && 
                (vendor.billingAddress == null || vendor.billingAddress!.isEmpty);
            final isFirstShipping = vendor != null && !isBilling && 
                (vendor.shippingAddress == null || vendor.shippingAddress!.isEmpty);

            final data = <String, dynamic>{
              'attention': val['attention'] ?? '',
              'street1': val['street1'] ?? '',
              'street2': val['street2'] ?? '',
              'city': val['city'] ?? '',
              'state': val['stateName'] ?? val['state'] ?? '',
              'zip': val['zip'] ?? '',
              'country': val['countryName'] ?? val['country'] ?? '',
              'phone': val['phone'] ?? '',
              'phoneCode': val['phoneCode'] ?? '+91',
              'fax': val['fax'] ?? '',
              'is_default_billing': isFirstBilling,
              'isDefaultBilling': isFirstBilling,
              'is_default_shipping': isFirstShipping,
              'isDefaultShipping': isFirstShipping,
            };

            if (vendor != null) {
              Vendor updated;
              if (isNewAddress) {
                final Map<String, dynamic> newAddr = {
                  ...data,
                  'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                };
                final currentList = vendor.vendorAddresses ?? [];
                final newList = [...currentList, newAddr];
                final tempVendor = vendor.copyWith(vendorAddresses: newList);
                
                final updatedAddresses = _updateVendorAddressesDefaultFlags(
                  vendor: tempVendor,
                  selectedAddr: newAddr,
                  isBilling: isBilling,
                );
                
                updated = isBilling
                    ? tempVendor.copyWith(
                        billingAddress: _normalizeAddress(newAddr),
                        vendorAddresses: updatedAddresses,
                      )
                    : tempVendor.copyWith(
                        shippingAddress: _normalizeAddress(newAddr),
                        vendorAddresses: updatedAddresses,
                      );
              } else if (initialAddress != null) {
                final currentList = vendor.vendorAddresses ?? [];
                final newList = currentList.map((addr) {
                  if (_areAddressesEqual(addr, initialAddress)) {
                    return {
                      ...addr,
                      ...data,
                    };
                  }
                  return addr;
                }).toList();
                
                final tempVendor = vendor.copyWith(vendorAddresses: newList);
                final updatedAddresses = _updateVendorAddressesDefaultFlags(
                  vendor: tempVendor,
                  selectedAddr: data,
                  isBilling: isBilling,
                );
                
                updated = isBilling
                    ? tempVendor.copyWith(
                        billingAddress: _normalizeAddress(data),
                        vendorAddresses: updatedAddresses,
                      )
                    : tempVendor.copyWith(
                        shippingAddress: _normalizeAddress(data),
                        vendorAddresses: updatedAddresses,
                      );
              } else {
                final updatedAddresses = _updateVendorAddressesDefaultFlags(
                  vendor: vendor,
                  selectedAddr: data,
                  isBilling: isBilling,
                );
                updated = isBilling
                    ? vendor.copyWith(
                        billingAddress: _normalizeAddress(data),
                        vendorAddresses: updatedAddresses,
                      )
                    : vendor.copyWith(
                        shippingAddress: _normalizeAddress(data),
                        vendorAddresses: updatedAddresses,
                      );
              }

              setState(() {
                _selectedVendor = updated;
                if (isBilling) {
                  _customBillingAddress = null;
                  _hasAddress = true;
                  final String? billingState = updated.billingAddress?['state']?.toString();
                  if (billingState != null && billingState.isNotEmpty) {
                    _sourceOfSupply = _resolveStateName(billingState);
                    _destinationOfSupply = _resolveStateName(billingState);
                  }
                }
              });

              try {
                ref
                    .read(vendorProvider.notifier)
                    .updateVendorLocally(vendor.id, updated);
                await ref
                    .read(vendorProvider.notifier)
                    .updateVendor(vendor.id, updated);
                if (context.mounted) {
                  ZerpaiToast.success(context, 'Vendor address updated in database');
                }
              } catch (e) {
                setState(() {
                  _selectedVendor = vendor;
                });
                ref
                    .read(vendorProvider.notifier)
                    .updateVendorLocally(vendor.id, vendor);
                if (context.mounted) {
                  ZerpaiToast.error(context, 'Failed to update address in database: $e');
                }
              }
            }
          },
        );
      },
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
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
    final hasVal = value != null && value.isNotEmpty;
    return FormDropdown<String>(
      value: value,
      items: items,
      textStyle: TextStyle(
        fontSize: 13,
        fontWeight: hasVal ? FontWeight.bold : FontWeight.normal,
        color: hasVal ? _textPrimary : _hintColor,
      ),
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

  Future<void> _openBatchDialogForBillRow(_BillLineItemRow row) async {
    final itemId = row.itemId?.trim();
    if (itemId == null || itemId.isEmpty) {
      _showValidationError('Please select an item first.');
      return;
    }

    final initialBatches = <BatchInfo>[];
    if (row.savedBatchData != null) {
      for (final b in row.savedBatchData!) {
        final qty = double.tryParse(b['qtyOut'] ?? '') ?? 0.0;
        final foc = double.tryParse(b['foc'] ?? '') ?? 0.0;
        final mrpVal = double.tryParse(b['mrp'] ?? '') ?? 0.0;
        final ptrVal = double.tryParse(b['prate'] ?? '') ?? 0.0;

        DateTime? parseDate(String? value) {
          if (value == null || value.trim().isEmpty) return null;
          final cleanValue = value.trim();
          try {
            return DateFormat('dd-MM-yyyy').parseStrict(cleanValue);
          } catch (_) {}
          try {
            return DateTime.parse(cleanValue);
          } catch (_) {}
          return null;
        }

        final expDate = parseDate(b['expDate']);
        final mfgDate = parseDate(b['mfgDate']);

        initialBatches.add(
          BatchInfo(
            batchNo: b['batchId'] ?? '',
            unitPack: b['unitPack'] ?? '',
            mrp: mrpVal,
            ptr: ptrVal,
            quantity: qty,
            foc: foc,
            manufactureBatch: b['mfgBatch'] ?? '',
            manufactureDate: mfgDate,
            expiryDate: expDate,
            binId: b['binId'],
          ),
        );
      }
    }

    final batchOptions = <String>{
      ...initialBatches.map((b) => b.batchNo.trim()).where((v) => v.isNotEmpty),
    };

    final batchDetails = <Map<String, dynamic>>[];
    try {
      final dbBatches = await ref.read(
        batchLookupProvider(itemId).future,
      );
      final dbBatchNumbers = dbBatches.map((b) => b['batch_no']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      batchOptions.addAll(dbBatchNumbers);
      batchDetails.addAll(dbBatches);
    } catch (_) {
      // keep existing local options if remote lookup fails
    }

    final warehouses = ref.read(warehousesProvider).valueOrNull ?? [];
    final matchingWarehouse = warehouses.firstWhere(
      (w) =>
          w.name.trim().toLowerCase() ==
          (_warehouse ?? '').trim().toLowerCase(),
      orElse: () => Warehouse(id: '', name: ''),
    );
    final String? whId = matchingWarehouse.id.isNotEmpty
        ? matchingWarehouse.id
        : null;

    List<Map<String, dynamic>> bins = [];
    if (whId != null && whId.isNotEmpty) {
      try {
        final binsList = await ref.read(binsLookupProvider(whId).future);
        bins = binsList.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SelectBatchDialog(
        itemName: row.itemName ?? '',
        productId: itemId,
        batchOptions: batchOptions.toList()..sort(),
        batchDetails: batchDetails,
        initialBatches: initialBatches,
        bins: bins,
        ordered: double.tryParse(row.quantityCtrl.text.trim()) ?? 1.0,
        maxQuantity: double.infinity,
        warehouseName: _warehouse ?? '',
        initialDamageEnabled: false,
        onTopError: _showValidationError,
        readOnly: row.purchaseReceiveId != null,
        onSave: (newBatches) {
          setState(() {
            row.savedBatchData = newBatches.map((b) {
              return {
                'batchId': b.batchNo,
                'qtyOut': b.quantity.toString(),
                'foc': b.foc.toString(),
                'mrp': b.mrp.toString(),
                'prate': b.ptr.toString(),
                'expDate': b.expiryDate != null
                    ? DateFormat('dd-MM-yyyy').format(b.expiryDate!)
                    : '',
                'mfgDate': b.manufactureDate != null
                    ? DateFormat('dd-MM-yyyy').format(b.manufactureDate!)
                    : '',
                'mfgBatch': b.manufactureBatch,
                'unitPack': b.unitPack,
                'binId': b.binId ?? '',
              };
            }).toList();

            row.hasBatchData = newBatches.isNotEmpty;
            row.batchCount = newBatches.length;

            final totalQty = newBatches.fold<double>(
              0.0,
              (sum, b) => sum + b.quantity,
            );
            final totalFoc = newBatches.fold<double>(
              0.0,
              (sum, b) => sum + b.foc,
            );

            if (totalFoc > 0) {
              row.quantityCtrl.text = (totalQty + totalFoc).toInt().toString();
            } else {
              row.quantityCtrl.text = totalQty.toInt().toString();
            }
          });
        },
      ),
    );
  }

  void _showAdvancedVendorSearchModal() {
    final vendors = ref.read(vendorProvider).vendors;
    showDialog(
      context: context,
      builder: (ctx) => AdvancedVendorSearchDialog(
        vendors: vendors,
        onSelect: (v) => _selectVendor(v),
      ),
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

  void _showVendorDetailsSidebar() async {
    _removeVendorOverlay();
    _removeItemOverlay();
    _removeMoreOverlay();

    if (_selectedVendor == null) return;

    final originalVendor = _selectedVendor!;
    Vendor displayVendor = originalVendor;

    try {
      final repo = ref.read(vendorRepositoryProvider);
      final fetched = await repo.getVendorById(originalVendor.id);
      if (fetched != null) {
        displayVendor = fetched;
      }
    } catch (e) {
      debugPrint('Error fetching full vendor details: $e');
    }

    if (!mounted) return;

    final overlay = Overlay.of(context);
    _sidebarOverlayEntry = OverlayEntry(
      builder: (context) => VendorSidebar(
        vendor: displayVendor,
        onClose: _closeVendorDetailsSidebar,
        paymentTermsList: _paymentTermsList,
      ),
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
                                            _selectVendor(v);
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
          maxWidth: 924,
          child: Row(
            children: [
              SizedBox(
                width: 396,
                child: _zDateField(
                  controller: _billDateCtrl,
                  targetKey: GlobalKey(),
                  value: _parseUiDate(_billDateCtrl.text),
                  onSelected: (date) {
                    setState(() {
                      _updateDueDateFromPaymentTerms();
                    });
                  },
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 110,
                child: RichText(
                  text: const TextSpan(
                    text: 'Invoice Total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                      fontFamily: 'Inter',
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: _zField(
                  _invoiceTotalCtrl,
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
              ),
            ],
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
                  value: _parseUiDate(_dueDateCtrl.text),
                  onSelected: (date) {},
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: 110,
                child: Text(
                  'Payment Terms',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _labelColor,
                    fontFamily: 'Inter',
                  ),
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
        onChanged: (val) {
          setState(() {
            _paymentTerms = val;
            _updateDueDateFromPaymentTerms();
          });
        },
      ),
    );
  }

  // ─────────────────────────────────────────── Reverse Charge ───────────────

  Widget _buildReverseChargeRow() {
    return _zFormRow(
      label: '',
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Checkbox(
              value: _reverseCharge,
              onChanged: (val) => setState(() => _reverseCharge = val ?? false),
              activeColor: _linkBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'This transaction is applicable for reverse charge',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF374151), // Gray-700
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
    final List<coa.AccountNode> availableAccounts = [];
    void collect(List<coa.AccountNode> nodes) {
      for (final node in nodes) {
        availableAccounts.add(node);
        if (node.children.isNotEmpty) {
          collect(node.children);
        }
      }
    }

    collect(accountsRoots);

    final mappedNodes = availableAccounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Table Title Row (outside the border) ──
        if (!_bulkMode)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                              if (val == 'stock')
                                _showStockInfo = !_showStockInfo;
                              if (val == 'recent')
                                _showRecentTransactions =
                                    !_showRecentTransactions;
                              if (val == 'pricelist')
                                _showPriceList = !_showPriceList;
                              if (val == 'hide_all') {
                                final allHidden = _lineItems.asMap().keys.every(
                                  (i) => _hiddenDetails.contains(i),
                                );
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
                            final allHidden = _lineItems.asMap().keys.every(
                              (i) => _hiddenDetails.contains(i),
                            );
                            return [
                              PopupMenuItem(
                                value: 'stock',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  _showStockInfo
                                      ? 'Hide Available Stock'
                                      : 'Show Available Stock',
                                  _showStockInfo,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'recent',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  _showRecentTransactions
                                      ? 'Hide Recent Transactions'
                                      : 'Show Recent Transactions',
                                  _showRecentTransactions,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'pricelist',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  _showPriceList
                                      ? 'Hide Price List'
                                      : 'Show Price List',
                                  _showPriceList,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'hide_all',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _HoverableToggleMenuItem(
                                  allHidden
                                      ? 'Show All Additional Information'
                                      : 'Hide All Additional Information',
                                  !allHidden,
                                ),
                              ),
                            ];
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _borderColor),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.settings,
                                  size: 16,
                                  color: Color(0xFF4B5563),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: Color(0xFF4B5563),
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
              const SizedBox(width: 60), // Align with action column
            ],
          )
        else
          // ── Bulk Update Toolbar ──
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                            builder: (context) =>
                                _buildUpdateAccountDialog(availableAccounts),
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
                                value:
                                    _selectedRows.length ==
                                        _lineItems
                                            .where((r) => !r.isLandedCost)
                                            .length &&
                                    _lineItems.isNotEmpty,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedRows.clear();
                                      for (
                                        int i = 0;
                                        i < _lineItems.length;
                                        i++
                                      ) {
                                        if (!_lineItems[i].isLandedCost) {
                                          _selectedRows.add(i);
                                        }
                                      }
                                    } else {
                                      _selectedRows.clear();
                                    }
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
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
                                _showSearchItemDetails =
                                    !_showSearchItemDetails;
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                                message:
                                    'You can perform basic calculations directly in this field using parentheses ( ) and arithmetic operators: + - / *',
                                child: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2"/><line x1="8" x2="16" y1="6" y2="6"/><line x1="16" x2="16" y1="14" y2="18"/><path d="M16 10h.01"/><path d="M12 10h.01"/><path d="M8 10h.01"/><path d="M12 14h.01"/><path d="M8 14h.01"/><path d="M12 18h.01"/><path d="M8 18h.01"/></svg>',
                                  width: 13,
                                  height: 13,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF0088FF),
                                    BlendMode.srcIn,
                                  ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
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
                                Icon(
                                  Icons.info_outline,
                                  size: 12,
                                  color: _hintColor.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      _vLine(),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _reverseCharge
                                      ? 'TAX ( REVERSE CHARGE )'
                                      : 'TAX',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ZTooltip(
                                message:
                                    'Applicable tax for the items. You can select a tax rate from the list.',
                                child: const Icon(
                                  LucideIcons.helpCircle,
                                  size: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _vLine(),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                return SizedBox(
                  key: ValueKey('landed_placeholder_${rowItem.hashCode}'),
                );
              }
              if (_itemDetailsSearchQuery.isNotEmpty) {
                final name = (rowItem.itemName ?? '').toLowerCase();
                if (!name.contains(_itemDetailsSearchQuery.toLowerCase())) {
                  return SizedBox(
                    key: ValueKey('bill_row_hidden_${rowItem.hashCode}'),
                  );
                }
              }
              return _buildLineItemRow(i, rowItem, itemsState, mappedNodes);
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
          _buildLandedCostHeaderRow(),
          ..._lineItems.asMap().entries.where((e) => e.value.isLandedCost).map((
            entry,
          ) {
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
                            Icon(
                              Icons.add_circle_outline,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Add New Row',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: const Color(0xFFE5E7EB),
                    ),
                    GestureDetector(
                      onTap: _toggleAddRowDropdown,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _lineItems.add(_BillLineItemRow(isLandedCost: true));
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Add Landed Cost',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ZTooltip(
                        message:
                            'You can add landed cost from a different vendor in the details page',
                        direction: ZTooltipDirection.right,
                        child: const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        _buildPendingOrdersBanner(),
      ],
    );
  }

  void _updateAllRowTaxes() {
    final itemsState = ref.read(itemsControllerProvider);
    for (var row in _lineItems) {
      if (row.itemId != null) {
        final item = itemsState.items.firstWhere(
          (i) => i.id == row.itemId,
          orElse: () =>
              Item(productName: '', itemCode: '', type: 'goods', unitId: ''),
        );
        _updateRowTaxForProduct(row, item, itemsState);
      }
    }
  }

  void _updateRowTaxForProduct(
    _BillLineItemRow row,
    Item item,
    ItemsState itemsState,
  ) {
    if (_selectedVendor != null &&
        _selectedVendor!.gstTreatment?.toLowerCase() ==
            'unregistered business') {
      row.taxId = 'non_taxable';
      row.taxName = 'Non-Taxable';
      row.taxRate = 0.0;
      return;
    }

    final srcKL = _sourceOfSupply?.toLowerCase().contains('kerala') ?? false;
    final destKL = _destinationOfSupply?.toLowerCase().contains('kerala') ?? false;
    final isIntra = srcKL && destKL;
    final taxId = isIntra ? item.intraStateTaxId : item.interStateTaxId;
    final taxName = isIntra ? item.intraStateTaxName : item.interStateTaxName;

    final matchedTax = itemsState.taxGroups
        .where((tg) => tg.id == taxId)
        .firstOrNull;

    row.taxId = taxId;
    row.taxName = matchedTax?.taxName ?? taxName ?? 'No Tax';
    row.taxRate = matchedTax?.taxRate ?? 0.0;
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        'LANDED COST DETAILS',
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                    flex: 4,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                            message:
                                'You can perform basic calculations directly in this field using parentheses ( ) and arithmetic operators: + - / *',
                            child: SvgPicture.string(
                              '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2"/><line x1="8" x2="16" y1="6" y2="6"/><line x1="16" x2="16" y1="14" y2="18"/><path d="M16 10h.01"/><path d="M12 10h.01"/><path d="M8 10h.01"/><path d="M12 14h.01"/><path d="M8 14h.01"/><path d="M12 18h.01"/><path d="M8 18h.01"/></svg>',
                              width: 13,
                              height: 13,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF0088FF),
                                BlendMode.srcIn,
                              ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                            Icon(
                              Icons.info_outline,
                              size: 12,
                              color: _hintColor.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  _vLine(),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _reverseCharge
                                  ? 'TAX ( REVERSE CHARGE )'
                                  : 'TAX',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ZTooltip(
                            message:
                                'Applicable tax for the items. You can select a tax rate from the list.',
                            child: const Icon(
                              LucideIcons.helpCircle,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _vLine(),
                  const Expanded(
                    flex: 6,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
            child: const Icon(
              LucideIcons.x,
              size: 12,
              color: Color(0xFF6B7280),
            ),
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
    final warehouseList = ref.watch(warehousesProvider).valueOrNull ?? <Warehouse>[];
    final items = warehouseList.map((w) => w.name).toSet().toList();
    final hasCurrentWh = items.contains(_warehouse);
    if ((_warehouse == null || !hasCurrentWh) && warehouseList.isNotEmpty) {
      final defaultWh = warehouseList.firstWhere(
        (w) => w.isDefaultForBranch,
        orElse: () => warehouseList.first,
      );
      _warehouse = defaultWh.name;
    }
    final hasWh = _warehouse != null && _warehouse!.isNotEmpty;
    return FormDropdown<String>(
      value: _warehouse,
      items: items,
      textStyle: TextStyle(
        fontSize: 13,
        fontWeight: hasWh ? FontWeight.bold : FontWeight.normal,
        color: hasWh ? _textPrimary : _hintColor,
      ),
      displayStringForValue: (w) => w,
      hint: 'Select Warehouse',
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _warehouse = val;
            final activeEntityId = (Hive.box('config').get('selected_entity_id') as String?)?.trim();
            final selectedWh = warehouseList.firstWhere(
              (w) => w.name == val,
              orElse: () => warehouseList.isNotEmpty ? warehouseList.first : Warehouse(id: '', name: ''),
            );
            final selectedBranchId = selectedWh.entityId ?? selectedWh.branchId ?? activeEntityId ?? '';
            final newPriceLists = _getCombinedPriceListsForBranch(selectedBranchId);
            if (_selectedPriceListId != null) {
              final hasPl = newPriceLists.any((pl) => pl.id == _selectedPriceListId);
              if (!hasPl) {
                _selectedPriceListId = null;
                for (var row in _lineItems) {
                  row.priceListId = null;
                  _updateRowRate(row, null, newPriceLists);
                }
              } else {
                for (var row in _lineItems) {
                  _updateRowRate(row, row.priceListId ?? _selectedPriceListId, newPriceLists);
                }
              }
            } else {
              for (var row in _lineItems) {
                _updateRowRate(row, row.priceListId, newPriceLists);
              }
            }
            for (final r in _lineItems) {
              if (r.warehouseName == null && r.itemId != null) {
                ref.read(itemWarehouseStocksProvider(r.itemId!).future).then((stocks) {
                  WarehouseStockRow? whRow;
                  for (final s in stocks) {
                    if (s.name.toLowerCase() == val.toLowerCase()) {
                      whRow = s;
                      break;
                    }
                  }
                  if (whRow != null) {
                    final nonNullWh = whRow;
                    setState(() {
                      if (r.warehouseName == null) {
                        final numbers = _stockType == 'Accounting'
                            ? nonNullWh.accounting
                            : nonNullWh.physical;
                        final isSOH = _stockView == 'stockOnHand';
                        r.stockAvailable = isSOH
                            ? numbers.onHand
                            : numbers.available;
                      }
                    });
                  }
                }).catchError((_) {});
              }
            }
          });
        }
      },
      height: 32,
      borderRadius: BorderRadius.circular(6),
      hideBorderDefault: true,
    );
  }

  /// Builds only the discount type dropdown.
  Widget _buildDiscountTypeDropdown() {
    return FormDropdown<String>(
      height: 32,
      value: _discountType,
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: _textPrimary,
      ),
      items: const ['At Transaction Level', 'At Line Item Level'],
      displayStringForValue: (v) => v,
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _discountType = val;
          });
        }
      },
      borderRadius: BorderRadius.circular(6),
      hideBorderDefault: true,
      prefixWidget: const Icon(
        LucideIcons.percent,
        size: 16,
        color: Color(0xFF6B7280),
      ),
      itemBuilder: (item, isSelected, isHovered) =>
          _buildStandardLookupRow(item, isSelected, isHovered),
    );
  }

  String? _getDefaultDiscountAccountId() {
    try {
      final accountsRoots = ref.read(chartOfAccountsProvider).roots;
      final expenseAccounts = _mapExpenseNodes(accountsRoots);
      final match = expenseAccounts.firstWhere(
        (a) => a.name.toLowerCase().contains('purchase discount') || a.name.toLowerCase().contains('purchase discounts'),
      );
      return match.id;
    } catch (_) {
      return null;
    }
  }

  Widget _buildRowDiscountAccountDropdown(_BillLineItemRow row) {
    final accountsRoots = ref.watch(chartOfAccountsProvider).roots;
    final expenseAccounts = _mapExpenseNodes(accountsRoots);

    if (row.discountAccountId == null) {
      final defaultId = _getDefaultDiscountAccountId();
      if (defaultId != null) {
        row.discountAccountId = defaultId;
      }
    }

    shared.AccountNode? currentVal;
    if (row.discountAccountId != null) {
      for (final a in expenseAccounts) {
        if (a.id == row.discountAccountId) {
          currentVal = a;
          break;
        }
      }
    }

    final hasAcc = currentVal != null && currentVal.id.isNotEmpty;
    return FormDropdown<shared.AccountNode>(
      height: 32,
      value: currentVal,
      textStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: hasAcc ? _textPrimary : _hintColor,
      ),
      items: expenseAccounts,
      hint: 'Discount Account',
      displayStringForValue: (a) => a.name,
      onChanged: (v) {
        if (v != null && !v.id.startsWith('__account_type__')) {
          setState(() {
            row.discountAccountId = v.id;
          });
        }
      },
      borderRadius: BorderRadius.circular(4),
      hideBorderDefault: true,
      fillColor: Colors.transparent,
      border: Border.all(color: Colors.transparent),
      prefixWidget: const Icon(
        LucideIcons.shoppingBag,
        size: 16,
        color: Color(0xFF6B7280),
      ),
      isItemEnabled: (account) => !account.id.startsWith('__account_type__'),
      itemBuilder: (account, isSelected, isHovered) {
        final isHeader = account.id.startsWith('__account_type__');
        if (isHeader) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Text(
              account.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          );
        }
        return _buildStandardLookupRow(
          account.name,
          isSelected,
          isHovered,
          indentation: 12.0,
        );
      },
    );
  }

  /// Builds the discount account dropdown shown when "At Line Item Level" is selected.
  Widget _buildDiscountAccountDropdown() {
    final accountsRoots = ref.watch(chartOfAccountsProvider).roots;
    final expenseAccounts = _mapExpenseNodes(accountsRoots);

    if (_discountAccountId == null) {
      final defaultId = _getDefaultDiscountAccountId();
      if (defaultId != null) {
        _discountAccountId = defaultId;
      }
    }

    shared.AccountNode? currentVal;
    if (_discountAccountId != null) {
      for (final a in expenseAccounts) {
        if (a.id == _discountAccountId) {
          currentVal = a;
          break;
        }
      }
    }

    final hasAcc = currentVal != null && currentVal.id.isNotEmpty;
    return FormDropdown<shared.AccountNode>(
      height: 32,
      value: currentVal,
      textStyle: TextStyle(
        fontSize: 13,
        fontWeight: hasAcc ? FontWeight.bold : FontWeight.normal,
        color: hasAcc ? _textPrimary : _hintColor,
      ),
      items: expenseAccounts,
      hint: 'Discount Account',
      displayStringForValue: (a) => a.name,
      onChanged: (v) {
        if (v != null && !v.id.startsWith('__account_type__')) {
          setState(() {
            _discountAccountId = v.id;
          });
        }
      },
      borderRadius: BorderRadius.circular(6),
      hideBorderDefault: true,
      prefixWidget: const Icon(
        LucideIcons.shoppingBag,
        size: 16,
        color: Color(0xFF6B7280),
      ),
      isItemEnabled: (account) => !account.id.startsWith('__account_type__'),
      itemBuilder: (account, isSelected, isHovered) {
        final isHeader = account.id.startsWith('__account_type__');
        if (isHeader) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Text(
              account.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          );
        }
        return _buildStandardLookupRow(
          account.name,
          isSelected,
          isHovered,
          indentation: 12.0,
        );
      },
    );
  }

  Widget _buildPriceListDropdown(List<PriceList> activePriceLists) {
    final selectedPL = activePriceLists
        .where((pl) => pl.id == _selectedPriceListId)
        .firstOrNull;
    final hasPL = selectedPL != null;
    return FormDropdown<PriceList>(
      height: 32,
      value: selectedPL,
      textStyle: TextStyle(
        fontSize: 13,
        fontWeight: hasPL ? FontWeight.bold : FontWeight.normal,
        color: hasPL ? _textPrimary : _hintColor,
      ),
      items: activePriceLists,
      hint: 'Apply Price List',
      allowClear: true,
      displayStringForValue: (pl) => pl.name,
      borderRadius: BorderRadius.circular(6),
      hideBorderDefault: true,
      prefixWidget: const Icon(
        LucideIcons.clipboard,
        size: 16,
        color: Color(0xFF6B7280),
      ),
      itemBuilder: (pl, isSelected, isHovered) =>
          _buildStandardLookupRow(pl.name, isSelected, isHovered),
      onChanged: (pl) {
        final itemsState = ref.read(itemsControllerProvider);
        if (pl != null) {
          setState(() {
            _selectedPriceListId = pl.id;
            for (var row in _lineItems) {
              if (row.itemId != null && row.itemId!.isNotEmpty) {
                final prod = itemsState.items
                    .where((item) => item.id == row.itemId)
                    .firstOrNull;
                final baseCost = prod?.costPrice ?? 0.0;
                final qty = double.tryParse(row.quantityCtrl.text) ?? 1.0;
                final newRate = pl.calculatePrice(
                  row.itemId!,
                  baseCost,
                  quantity: qty,
                );
                row.rateCtrl.text = newRate.toStringAsFixed(2);
                row.priceListId = pl.id;
              }
            }
          });
        } else {
          setState(() {
            _selectedPriceListId = null;
            for (var row in _lineItems) {
              row.priceListId = null;
            }
          });
        }
      },
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
                                  row.warehouseName = _warehouse;
                                  row.purchaseOrderId = null;
                                  row.purchaseOrderNumber = null;
                                  row.purchaseReceiveId = null;
                                  row.purchaseReceiveNumber = null;
                                  _updateOrderNumbersFromRows();

                                  final whName = row.warehouseName ?? _warehouse ?? '';
                                  if (whName.isNotEmpty) {
                                    ref.read(itemWarehouseStocksProvider(item.id ?? '').future).then((stocks) {
                                      WarehouseStockRow? whRow;
                                      for (final s in stocks) {
                                        if (s.name.toLowerCase() == whName.toLowerCase()) {
                                          whRow = s;
                                          break;
                                        }
                                      }
                                      if (whRow != null) {
                                        final nonNullWh = whRow;
                                        setState(() {
                                          if (row.itemId == item.id) {
                                            final numbers = _stockType == 'Accounting'
                                                ? nonNullWh.accounting
                                                : nonNullWh.physical;
                                            final isSOH = _stockView == 'stockOnHand';
                                            row.stockAvailable = isSOH
                                                ? numbers.onHand
                                                : numbers.available;
                                          }
                                        });
                                      }
                                    }).catchError((_) {});
                                  }

                                  if (item.costPrice != null) {
                                    row.rateCtrl.text = item.costPrice!
                                        .toStringAsFixed(2);
                                  }
                                  if (item.ptr != null) {
                                    row.ptrCtrl.text = item.ptr!
                                        .toStringAsFixed(2);
                                  }

                                  final itemsState = ref.read(
                                    itemsControllerProvider,
                                  );
                                  _updateRowTaxForProduct(
                                    row,
                                    item,
                                    itemsState,
                                  );

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
                          height: 32,
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
                          height: 32,
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
                                  child: Text(
                                    customer.displayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal,
                                      color: isHighlighted
                                          ? Colors.white
                                          : isSelected
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF1F2937),
                                    ),
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

    _moreOverlayEntry = ZAdaptiveMenu.show(
      context: context,
      link: row.moreLayerLink,
      onClose: _removeMoreOverlay,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
        );
      },
    );
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
    List<coa.AccountNode> mappedNodes,
  ) {
    final allItems = itemsState.items;
    final activePriceLists = ref
        .watch(activePriceListsProvider)
        .where((pl) => pl.transactionType.toLowerCase() == 'purchase')
        .toList();

    return MouseRegion(
      key: ValueKey(row),
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() {
        if (_hoveredRowIndex == index) _hoveredRowIndex = null;
      }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgWhite,
                    border: Border(
                      left: const BorderSide(color: _borderColor),
                      right: const BorderSide(color: _borderColor),
                      bottom: _hiddenDetails.contains(index)
                          ? const BorderSide(color: _borderColor)
                          : BorderSide.none,
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
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                  activeColor: const Color(0xFF2563EB),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          border: Border.all(
                                            color: _borderColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                          hint:
                                              'Type or click to select an item.',
                                          hideBorderDefault: true,
                                          itemEstimatedHeight: 48,
                                          maxVisibleItems: 5,
                                          menuWidth: 420,
                                          items: row.isLandedCost
                                              ? allItems
                                                  .where((i) => i.type == 'service')
                                                  .take(20)
                                                  .toList()
                                              : allItems.take(20).toList(),
                                          displayStringForValue: (i) =>
                                              i.productName,
                                          onSearch: (query) async {
                                            if (query.length < 2) return [];
                                            final results = await ref
                                                .read(
                                                  itemsControllerProvider
                                                      .notifier,
                                                )
                                                .searchProductsNoState(query);
                                            if (row.isLandedCost) {
                                              return results
                                                  .where((i) => i.type == 'service')
                                                  .toList();
                                            }
                                            return results;
                                          },
                                          itemBuilder:
                                              (
                                                i,
                                                isSelected,
                                                isHovered,
                                              ) => Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: isHovered || isSelected
                                                          ? Colors.transparent
                                                          : const Color(0xFFE5E7EB),
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                ),
                                                child: _buildStandardLookupRow(
                                                  i.productName,
                                                  isSelected,
                                                  isHovered,
                                                  sublabel: i.costPrice != null
                                                      ? 'Purchase Rate: ₹${i.costPrice!.toStringAsFixed(2)}'
                                                      : null,
                                                ),
                                              ),
                                          onChanged: (i) async {
                                            if (i == null) return;
                                            final dupIdx = _lineItems.indexWhere((r) => r.itemId == i.id);
                                            if (dupIdx != -1) {
                                              ZerpaiToast.error(
                                                context,
                                                "Item '${i.productName}' is already selected in row ${dupIdx + 1}.",
                                              );
                                              return;
                                            }
                                            setState(() {
                                              row.itemId = i.id;
                                              row.itemName = i.productName;
                                              row.itemNameCtrl.text =
                                                  i.productName;
                                              row.itemCode = i.itemCode;
                                              row.itemType = i.type;
                                              row.hsnCode = i.hsnCode;
                                              row.hsnCtrl.text =
                                                  i.hsnCode ?? '';
                                              row.rateCtrl.text =
                                                  (i.costPrice ?? 0.0)
                                                      .toStringAsFixed(2);
                                              row.discountCtrl.text = '0.00';
                                              row.descriptionCtrl.text =
                                                  i.purchaseDescription ?? '';
                                              row.purchaseOrderId = null;
                                              row.purchaseOrderNumber = null;
                                              row.purchaseReceiveId = null;
                                              row.purchaseReceiveNumber = null;
                                              _updateOrderNumbersFromRows();
                                              _updateRowTaxForProduct(
                                                row,
                                                i,
                                                itemsState,
                                              );
                                            });

                                            if (_selectedPriceListId != null) {
                                              final pl = activePriceLists
                                                  .where(
                                                    (p) =>
                                                        p.id ==
                                                        _selectedPriceListId,
                                                  )
                                                  .firstOrNull;
                                              if (pl != null) {
                                                final newRate = pl
                                                    .calculatePrice(
                                                      i.id ?? '',
                                                      i.costPrice ?? 0.0,
                                                      quantity: 1.0,
                                                    );
                                                setState(() {
                                                  row.rateCtrl.text = newRate
                                                      .toStringAsFixed(2);
                                                  row.priceListId =
                                                      _selectedPriceListId;
                                                });
                                              }
                                            }
                                            final index = _lineItems.indexOf(row);
                                            if (index == _lineItems.length - 1) {
                                              setState(() {
                                                _lineItems.add(_BillLineItemRow());
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                : _richItemDisplay(
                                    row,
                                    itemsState,
                                    activePriceLists,
                                  ),
                          ),
                        ),
                        _vLine(),
                        // ACCOUNT
                        _accountCell(row, mappedNodes, index),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      border: Border(
                        left: BorderSide(color: _borderColor),
                        right: BorderSide(color: _borderColor),
                        top: BorderSide(color: _borderColor),
                      ),
                    ),
                    child: _itemExpandedProperties(index, row, mappedNodes),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
        ],
      ),
    );
  }

  OverlayEntry? _valueTooltipOverlay;

  Widget _richItemDisplay(
    _BillLineItemRow row,
    ItemsState itemsState,
    List<PriceList> activePriceLists,
  ) {
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
              child:
                  selectedItem.primaryImageUrl != null &&
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
                  : const Icon(LucideIcons.image, size: 16, color: _hintColor),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(hoverColor: Colors.transparent),
                        child: PopupMenuButton<String>(
                          tooltip: 'Show more actions',
                          padding: EdgeInsets.zero,
                          offset: const Offset(0, 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (v) {
                            if (v == 'edit') {
                              showDialog(
                                context: context,
                                builder: (ctx) => ItemQuickEditDialog(
                                  item: selectedItem,
                                  onUpdated: (newItem) {
                                    setState(() {
                                      row.itemId = newItem.id;
                                      row.itemName = newItem.productName;
                                      row.itemNameCtrl.text =
                                          newItem.productName;
                                      row.rateCtrl.text =
                                          newItem.costPrice?.toString() ?? '0';
                                    });
                                  },
                                ),
                              );
                            }
                            if (v == 'details') {
                              _showItemDetailsSidebar(row, initialTabIndex: 0);
                            }
                          },
                          itemBuilder: (ctx) {
                            return [
                              PopupMenuItem<String>(
                                value: 'edit',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _MenuHoverItem(
                                  icon: LucideIcons.pencil,
                                  label: 'Edit Item',
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'details',
                                padding: EdgeInsets.zero,
                                height: 40,
                                child: _MenuHoverItem(
                                  icon: LucideIcons.shoppingBag,
                                  label: 'View Item Details',
                                ),
                              ),
                            ];
                          },
                          child: _buildIconAction(
                            LucideIcons.moreHorizontal,
                            size: 10,
                            onTap: null,
                          ),
                        ),
                      ),
                      if (!((widget.poId != null || widget.receiveId != null) && (row.purchaseOrderId != null || row.purchaseReceiveId != null))) ...[
                        const SizedBox(width: 4),
                        _buildIconAction(
                          LucideIcons.x,
                          size: 10,
                          color: Colors.black,
                          onTap: () {
                            setState(() {
                              row.itemId = null;
                              row.itemName = null;
                              row.itemNameCtrl.clear();
                              row.itemCode = null;
                              row.itemType = null;
                              row.hsnCode = null;
                              row.hsnCtrl.clear();
                              row.rateCtrl.text = '0.00';
                              row.discountCtrl.text = '0';
                              row.descriptionCtrl.clear();
                              row.quantityCtrl.text = '';
                              row.taxId = null;
                              row.taxName = null;
                              row.taxRate = 0;
                              row.priceListId = null;
                              row.purchaseOrderId = null;
                              row.purchaseOrderNumber = null;
                              row.purchaseReceiveId = null;
                              row.purchaseReceiveNumber = null;
                              _updateOrderNumbersFromRows();
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _HoverableDescriptionContainer(
          child: TextField(
            controller: row.descriptionCtrl,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 12, color: _textPrimary),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: 'Add a description to your item',
              hintStyle: TextStyle(fontSize: 12, color: _hintColor),
              filled: true,
              fillColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _infoChip(
              (row.itemType ?? 'goods').toUpperCase(),
              row.itemType == 'service'
                  ? const Color(0xFFF97316)
                  : const Color(0xFF0088FF),
              Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              row.itemType == 'service'
                  ? 'SAC Code: '
                  : 'HSN Code: ',
              style: const TextStyle(fontSize: 12, color: _hintColor),
            ),
            CompositedTransformTarget(
              link: row.hsnLayerLink,
              child: GestureDetector(
                onTap: () => _showHsnEditOverlay(row),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 12,
                      color: Color(0xFF0088FF),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      (row.hsnCode != null && row.hsnCode!.isNotEmpty)
                          ? row.hsnCode!
                          : 'Update',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0088FF),
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

  Widget _accountCell(_BillLineItemRow row, List<coa.AccountNode> mappedNodes, int index) {
    return Expanded(
      flex: 5,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: CompositedTransformTarget(
            link: row.accountLink,
            child: Builder(
              builder: (btnContext) {
                return GestureDetector(
                  onTap: () {
                    final renderBox = btnContext.findRenderObject() as RenderBox?;
                    final offset = renderBox?.localToGlobal(Offset.zero);
                    _showAccountMenu(
                      context,
                      index,
                      row,
                      mappedNodes,
                      link: row.accountLink,
                      buttonOffset: offset,
                    );
                  },
                  child: () {
                    bool isHovered = false;
                    return StatefulBuilder(
                      builder: (context, setOverlayState) {
                        return MouseRegion(
                          onEnter: (_) => setOverlayState(() => isHovered = true),
                          onExit: (_) => setOverlayState(() => isHovered = false),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (isHovered || _activeAccountRowIndex == index)
                                    ? const Color(0xFF0088FF)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: () {
                                    final displayAccountName =
                                        (row.accountName != null &&
                                            row.accountName!.isNotEmpty)
                                        ? row.accountName!
                                        : (row.accountId != null &&
                                                      row
                                                          .accountId!
                                                          .isNotEmpty
                                                  ? mappedNodes
                                                        .where(
                                                          (a) =>
                                                              a.id ==
                                                              row.accountId,
                                                        )
                                                        .firstOrNull
                                                        ?.name
                                                  : null) ??
                                              'Select Account';
                                    final isPlaceholder =
                                        displayAccountName ==
                                        'Select Account';
                                    return Text(
                                      displayAccountName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isPlaceholder
                                            ? _hintColor
                                            : _textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }(),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: _hintColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _qtyCell(_BillLineItemRow row) {
    final q = double.tryParse(row.quantityCtrl.text.trim()) ?? 0.0;
    final totalQtyOut =
        row.savedBatchData?.fold<double>(
          0.0,
          (sum, b) => sum + (double.tryParse(b['qtyOut'] ?? '') ?? 0.0),
        ) ??
        0.0;
    final totalFoc =
        row.savedBatchData?.fold<double>(
          0.0,
          (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
        ) ??
        0.0;
    final hasFocValue = totalFoc > 0;

    return Expanded(
      flex: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: _gridField(
                    row.quantityCtrl,
                    focusNode: row.qtyFocus,
                    hint: '0',
                    textAlign: TextAlign.right,
                    valueFontWeight: FontWeight.w400,
                    inputFormatters: [
                      _numericInputFormatter,
                    ],
                    onChanged: (v) {
                      setState(() {});
                    },
                  ),
                ),
                if (widget.editBillId != null &&
                    widget.editBillId!.isNotEmpty &&
                    (row.purchaseOrderId != null || _orderNumberCtrl.text.trim().isNotEmpty) &&
                    row.itemId != null &&
                    row.itemId!.isNotEmpty &&
                    !row.isLandedCost) ...[
                  const SizedBox(width: 4),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openEditQuantityDialog(row),
                      child: const Icon(
                        LucideIcons.fileEdit,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (row.itemId != null &&
                row.itemId!.isNotEmpty &&
                row.hasBatchData &&
                hasFocValue) ...[
              const SizedBox(height: 4),
              Text(
                '${totalQtyOut.toInt()} pcs + ${totalFoc.toInt()} foc',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ],
            if (row.itemId != null && row.itemId!.isNotEmpty && _showStockInfo) ...[
              const SizedBox(height: 4),
              Consumer(
                builder: (context, ref, _) {
                  final whName = row.warehouseName ?? _warehouse ?? '';
                  final isSOH = _stockView == 'stockOnHand';
                  final stocksAsync = ref.watch(itemWarehouseStocksProvider(row.itemId!));
                  return stocksAsync.when(
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isSOH ? 'Stock on Hand:' : 'Available for Sale:'} Loading...',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _textPrimary,
                          ),
                        ),
                        if (whName.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                LucideIcons.home,
                                size: 12,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  whName.toUpperCase(),
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    error: (e, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isSOH ? 'Stock on Hand:' : 'Available for Sale:'} 0 pcs',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 10,
                            color: _textPrimary,
                          ),
                        ),
                        if (whName.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                LucideIcons.home,
                                size: 12,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  whName.toUpperCase(),
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    data: (stocks) {
                      final whRow = stocks
                          .where((s) => s.name.toLowerCase() == whName.toLowerCase())
                          .firstOrNull ??
                          stocks.firstOrNull;
                      double stockValue = 0.0;
                      if (whRow != null) {
                        final numbers = _stockType == 'Accounting'
                            ? whRow.accounting
                            : whRow.physical;
                        stockValue = isSOH ? numbers.onHand : numbers.available;
                        row.stockAvailable = stockValue;
                      } else {
                        row.stockAvailable = 0.0;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isSOH ? 'Stock on Hand:' : 'Available for Sale:'} ${stockValue.toStringAsFixed(0)} pcs',
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 10,
                              color: _textPrimary,
                            ),
                          ),
                          if (whName.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  LucideIcons.home,
                                  size: 12,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: WarehouseHoverPopover(
                                    productId: row.itemId,
                                    warehouseName: whName,
                                    selectedView: _stockView == 'stockOnHand'
                                        ? 'Stock on Hand'
                                        : 'Available for Sale',
                                    selectedStockType: _stockType,
                                    onViewChanged: (v) {
                                      setState(() {
                                        _stockView = v == 'Stock on Hand'
                                            ? 'stockOnHand'
                                            : 'availableForSale';
                                        _updateAllStockAvailableValues();
                                      });
                                    },
                                    onStockTypeChanged: (t) {
                                      setState(() {
                                        _stockType = t;
                                        _updateAllStockAvailableValues();
                                      });
                                    },
                                    onWarehouseChanged: (newName) {
                                      setState(() {
                                        row.warehouseName = newName;
                                        final match = stocks
                                            .where((s) => s.name.toLowerCase() == newName.toLowerCase())
                                            .firstOrNull;
                                        if (match != null) {
                                          final numbers = _stockType == 'Accounting'
                                              ? match.accounting
                                              : match.physical;
                                          row.stockAvailable = isSOH ? numbers.onHand : numbers.available;
                                        } else {
                                          row.stockAvailable = 0.0;
                                        }
                                      });
                                    },
                                    child: Text(
                                      whName.toUpperCase(),
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (q > 0) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () => _openBatchDialogForBillRow(row),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!row.hasBatchData) ...[
                                        const Icon(
                                          LucideIcons.alertTriangle,
                                          size: 10,
                                          color: Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        row.hasBatchData
                                            ? '${(totalQtyOut + totalFoc).toInt()} pcs taken from\n${row.batchCount} ${row.batchCount <= 1 ? "batch" : "batches"}.'
                                            : 'Select Batch',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF2563EB),
                                          fontFamily: 'Inter',
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rateCell(_BillLineItemRow row, List<PriceList> activePriceLists) {
    final currentPriceList = activePriceLists
        .where((pl) => pl.id == row.priceListId)
        .firstOrNull;
    bool notIncluded = false;
    if (currentPriceList != null && row.itemId != null) {
      if (currentPriceList.priceListType ==
          'individual_items') {
        notIncluded =
            !(currentPriceList.itemRates?.any(
                  (r) => r.itemId == row.itemId,
                ) ??
                false);
      }
    } else if (row.priceListId != null) {
      notIncluded = true;
    }
    final showWarning = notIncluded && _showPriceList && activePriceLists.isNotEmpty;

    return Expanded(
      flex: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactNumberField(
              row.rateCtrl,
              focusNode: row.rateFocus,
              isTransparentBorder: false,
              textAlign: TextAlign.right,
              inputFormatters: [
                _numericInputFormatter,
              ],
              onSubmitted: (_) => _handleRateCalculation(row),
              onChanged: (v) {
                setState(() {});
              },
            ),
            if (row.itemId != null) ...[
              if (_showPriceList || _showRecentTransactions)
                const SizedBox(height: 4),
              if (_showPriceList && activePriceLists.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (notIncluded) ...[
                      ZTooltip(
                        message:
                            "This item has not been included in the selected price list. So, the item's default rate has been used.",
                        direction: ZTooltipDirection.bottom,
                        child: const Icon(
                          LucideIcons.alertCircle,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: CompositedTransformTarget(
                        link: row.priceListLink,
                        child: MouseRegion(
                          onEnter: (_) {
                            if (row.priceListId != null) {
                              final pl = activePriceLists
                                  .where((p) => p.id == row.priceListId)
                                  .firstOrNull;
                              if (pl != null) {
                                _showValueTooltip(
                                  context,
                                  pl.name,
                                  row.priceListLink,
                                );
                              }
                            }
                          },
                          onExit: (_) => _hideValueTooltip(),
                          child: FormDropdown<PriceList>(
                            height: 32,
                            value: activePriceLists
                                .where((pl) => pl.id == row.priceListId)
                                .firstOrNull,
                            items: activePriceLists
                                .where((pl) =>
                                    pl.priceListType == 'all_items' ||
                                    (pl.priceListType == 'individual_items' &&
                                     pl.itemRates != null &&
                                     pl.itemRates!.any((r) => r.itemId == row.itemId)))
                                .toList(),
                            hint: 'Apply Price List',
                            allowClear: true,
                            displayStringForValue: (pl) => pl.name,
                            textStyle: const TextStyle(
                              fontSize: 11,
                              color: _textPrimary,
                              fontFamily: 'Inter',
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _borderColor),
                            onChanged: (pl) {
                              if (pl != null) {
                                setState(() {
                                  row.priceListId = pl.id;
                                  final itemsState = ref.read(itemsControllerProvider);
                                  final originalProduct = itemsState.items.where((i) => i.id == row.itemId).firstOrNull;
                                  final baseRate = originalProduct?.costPrice ?? (double.tryParse(row.rateCtrl.text) ?? 0.0);
                                  final newRate = pl.calculatePrice(
                                    row.itemId ?? '',
                                    baseRate,
                                    quantity:
                                        double.tryParse(
                                          row.quantityCtrl.text,
                                        ) ??
                                        1.0,
                                  );
                                  row.rateCtrl.text = newRate
                                      .toStringAsFixed(2);
                                });
                              } else {
                                setState(() {
                                  row.priceListId = null;
                                  final itemsState = ref.read(itemsControllerProvider);
                                  final originalProduct = itemsState.items.where((i) => i.id == row.itemId).firstOrNull;
                                  final defaultRate = originalProduct?.costPrice ?? 0.0;
                                  row.rateCtrl.text = defaultRate.toStringAsFixed(2);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_showRecentTransactions) ...[
                const SizedBox(height: 4),
                Builder(
                  builder: (innerContext) => GestureDetector(
                    onTap: () {
                      _showItemDetailsSidebar(row, initialTabIndex: 2);
                    },
                    child: const Text(
                      'Recent Transactions',
                      style: TextStyle(fontSize: 10, color: Color(0xFF0088FF)),
                    ),
                  ),
                ),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              child: InCellWrapper(
                focusNode: row.discountFocus,
                isDropdownOpen: _activeDiscountRowIndex == _lineItems.indexOf(row),
                isTransparentBorder: true,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: row.discountCtrl,
                        focusNode: row.discountFocus,
                        onChanged: (v) {
                          setState(() {});
                        },
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.left,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                      ),
                    ),
                    CompositedTransformTarget(
                      link: row.discountTypeLink,
                      child: GestureDetector(
                        onTap: () => _showDiscountMenu(
                          context,
                          _lineItems.indexOf(row),
                          row,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        color: Colors.transparent,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              row.discountType == '%' ? '%' : '₹',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textPrimary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 14,
                              color: _hintColor,
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
        ],
      ),
    ),
  );
}

  Widget _taxCell(_BillLineItemRow row, ItemsState itemsState) {
    final bool isUnregistered =
        _selectedVendor != null &&
        _selectedVendor!.gstTreatment?.toLowerCase() == 'unregistered business';

    return Expanded(
      flex: 5,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CompositedTransformTarget(
                link: row.taxLayerLink,
                child: GestureDetector(
                  onTap: isUnregistered
                      ? null
                      : () => _showTaxPopover(context, row, itemsState),
                  child: _TaxCellDropdown(
                    row: row,
                    isUnregistered: isUnregistered,
                    isSelected: _activeTaxPopoverRow == row,
                  ),
                ),
              ),
              if (row.itemId != null) ...[
                const SizedBox(height: 4),
                CompositedTransformTarget(
                  link: row.itcLayerLink,
                  child: GestureDetector(
                    onTap: () => _showItcOverlay(row),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            row.itcEligibility,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0088FF),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit,
                          size: 11,
                          color: Color(0xFF0088FF),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _customerCell(_BillLineItemRow row) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final customers = customersAsync.valueOrNull ?? const <SalesCustomer>[];

    return Expanded(
      flex: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: FormDropdown<SalesCustomer>(
          height: 32,
          value: customers.where((c) => c.id == row.customerId).firstOrNull,
          items: customers,
          hint: 'Select Customer',
          allowClear: true,
          hideBorderDefault: true,
          menuWidth: 420,
          displayStringForValue: (c) => c.displayName,
          onChanged: (val) {
            setState(() {
              if (val != null) {
                row.customerId = val.id;
                row.customerName = val.displayName;
              } else {
                row.customerId = null;
                row.customerName = null;
              }
            });
          },
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
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
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
      ),
    );
  }

  Widget _actionsCell(int index, _BillLineItemRow row, ItemsState itemsState) {
    final isRowHovered = _hoveredRowIndex == index || _activeMenuRowIndex == index;
    return SizedBox(
      width: 60,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: isRowHovered
            ? Row(
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
                        child: Icon(
                          LucideIcons.moreVertical,
                          size: 16,
                          color: _hintColor,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_lineItems.length > 1) {
                        row.dispose();
                        setState(() {
                          _lineItems.removeAt(index);
                          _hoveredRowIndex = null;
                          _updateOrderNumbersFromRows();
                        });
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.x, size: 14, color: _dangerRed),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  void _closeReportingTagsOverlay() {
    _reportingTagsOverlay?.remove();
    _reportingTagsOverlay = null;
  }

  void _toggleReportingTagsOverlay(
    BuildContext context,
    dynamic row,
    LayerLink link,
  ) {
    if (_reportingTagsOverlay != null) {
      _closeReportingTagsOverlay();
      return;
    }

    final Map<String, String> localTags = Map<String, String>.from(
      row.reportingTags,
    );

    _reportingTagsOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeReportingTagsOverlay,
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.transparent)),
              CompositedTransformFollower(
                link: link,
                showWhenUnlinked: false,
                offset: const Offset(0, 32),
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      return Container(
                        width: 320,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Reporting Tags',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                InkWell(
                                  onTap: _closeReportingTagsOverlay,
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'ADGF',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            FormDropdown<String>(
                              value: localTags['adgf'],
                              items: const ['None', 'Option 1', 'Option 2'],
                              hint: 'None',
                              height: 32,
                              onChanged: (val) {
                                if (val != null) {
                                  setOverlayState(() {
                                    localTags['adgf'] = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Schedule',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            FormDropdown<String>(
                              value: localTags['schedule'],
                              items: const ['None', 'Option 1', 'Option 2'],
                              hint: 'None',
                              height: 32,
                              onChanged: (val) {
                                if (val != null) {
                                  setOverlayState(() {
                                    localTags['schedule'] = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Demo advanced reporting tag',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            FormDropdown<String>(
                              value: localTags['demo_tag'],
                              items: const ['None', 'Option 1', 'Option 2'],
                              hint: 'None',
                              height: 32,
                              onChanged: (val) {
                                if (val != null) {
                                  setOverlayState(() {
                                    localTags['demo_tag'] = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ZButton.secondary(
                                  label: 'Cancel',
                                  onPressed: _closeReportingTagsOverlay,
                                ),
                                const SizedBox(width: 8),
                                ZButton.primary(
                                  label: 'Update',
                                  onPressed: () {
                                    setState(() {
                                      row.reportingTags['adgf'] =
                                          localTags['adgf']!;
                                      row.reportingTags['schedule'] =
                                          localTags['schedule']!;
                                      row.reportingTags['demo_tag'] =
                                          localTags['demo_tag']!;
                                    });
                                    _closeReportingTagsOverlay();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_reportingTagsOverlay!);
  }

  Widget _itemExpandedProperties(
    int index,
    _BillLineItemRow row,
    List<coa.AccountNode> accounts,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_discountType == 'At Line Item Level') ...[
          SizedBox(
            width: 200,
            child: _buildRowDiscountAccountDropdown(row),
          ),
          const SizedBox(width: 16),
        ],
        _propertyButton(
          link: row.reportingTagsLink,
          iconWidget: SvgPicture.string(
            '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#22C55E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13.172 2a2 2 0 0 1 1.414.586l6.71 6.71a2.4 2.4 0 0 1 0 3.408l-4.592 4.592a2.4 2.4 0 0 1-3.408 0l-6.71-6.71A2 2 0 0 1 6 9.172V3a1 1 0 0 1 1-1z"/><path d="M2 7v6.172a2 2 0 0 0 .586 1.414l6.71 6.71a2.4 2.4 0 0 0 3.191.193"/><circle cx="10.5" cy="6.5" r=".5" fill="#22C55E"/></svg>',
            width: 16,
            height: 16,
          ),
          label: 'Reporting Tags',
          onTap: () =>
              _toggleReportingTagsOverlay(context, row, row.reportingTagsLink),
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

  Widget _buildUpdateAccountDialog(List<coa.AccountNode> availableAccounts) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: StatefulBuilder(
        builder: (context, dialogSetState) {
          return Container(
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
                        icon: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
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
                          child: FormDropdown<coa.AccountNode>(
                            height: 32,
                            value: _selectedPopupAccount,
                            items: _buildNestedAccountsList(availableAccounts),
                            isItemEnabled: (v) => !v.id.startsWith('header_'),
                            displayStringForValue: (v) => v.id.startsWith('header_') ? v.accountType : v.name,
                            hint: 'Select an account',
                            onChanged: (v) {
                              if (v != null && v.id.startsWith('header_')) return;
                              dialogSetState(() {
                                _selectedPopupAccount = v;
                              });
                              setState(() {
                                _selectedPopupAccount = v;
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _fieldBorder),
                            itemBuilder: (account, isSelected, isHovered) {
                              if (account.id.startsWith('header_')) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    account.accountType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                );
                              }
                              final depth = _getAccountDepth(account, availableAccounts);
                              final name = depth == 0
                                  ? (account.systemAccountName.isNotEmpty
                                      ? account.systemAccountName
                                      : account.name)
                                  : account.name;
                              return _buildStandardLookupRow(
                                name,
                                isSelected,
                                isHovered,
                                indentation: 20.0 + (depth * 16.0),
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
                            if (row.itemId != null &&
                                (!_bulkMode ||
                                    _selectedRows.isEmpty ||
                                    _selectedRows.contains(i))) {
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
          );
        },
      ),
    );
  }

  List<coa.AccountNode> _buildNestedAccountsList(List<coa.AccountNode> accounts) {
    final List<coa.AccountNode> nested = [];
    final Map<String, List<coa.AccountNode>> grouped = {};
    for (var acc in accounts) {
      grouped.putIfAbsent(acc.accountType, () => []).add(acc);
    }

    for (var entry in grouped.entries) {
      final type = entry.key;
      final typeAccounts = entry.value;
      nested.add(coa.AccountNode(
        id: 'header_$type',
        systemAccountName: type,
        userAccountName: type,
        name: type,
        accountGroup: 'Expenses',
        accountType: type,
        isSystem: false,
        isDeletable: false,
        isActive: false,
        parentId: null,
      ));

      final accountMap = {for (var a in typeAccounts) a.id: a};
      final rootNodes = typeAccounts
          .where((a) => a.parentId == null || !accountMap.containsKey(a.parentId))
          .toList();

      void addNode(coa.AccountNode node) {
        nested.add(node);
        final children = typeAccounts.where((a) => a.parentId == node.id).toList();
        for (var child in children) {
          addNode(child);
        }
      }

      for (var root in rootNodes) {
        addNode(root);
      }
    }
    return nested;
  }

  int _getAccountDepth(coa.AccountNode node, List<coa.AccountNode> accounts) {
    int depth = 0;
    coa.AccountNode? current = node;
    final accountMap = {for (var a in accounts) a.id: a};
    while (current?.parentId != null && accountMap.containsKey(current!.parentId)) {
      depth++;
      current = accountMap[current.parentId];
    }
    return depth;
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
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
                              child: _zRadio(
                                'Percentage (%)',
                                'percentage',
                                discountType,
                                (v) => setModalState(() => discountType = v),
                              ),
                            ),
                            Expanded(
                              child: _zRadio(
                                'Flat (₹)',
                                'fixed',
                                discountType,
                                (v) => setModalState(() => discountType = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    hintText: '0',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  color: Color(0xFFF9FAFB),
                                ),
                                child: Text(
                                  discountType == 'percentage' ? '%' : '₹',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
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
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final discVal = double.tryParse(controller.text) ?? 0;
                          final typeStr = discountType == 'percentage'
                              ? '%'
                              : '₹';
                          for (int i = 0; i < _lineItems.length; i++) {
                            final row = _lineItems[i];
                            if (row.itemId != null &&
                                (!_bulkMode ||
                                    _selectedRows.isEmpty ||
                                    _selectedRows.contains(i))) {
                              setState(() {
                                row.discountCtrl.text = discVal.toStringAsFixed(
                                  2,
                                );
                                row.discountType = typeStr;
                              });
                            }
                          }
                          setState(() {
                            _bulkMode = false;
                            _selectedRows.clear();
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Text('Update'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
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
    setState(() {
      _activeDiscountRowIndex = index;
    });

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
                  selectedType: row.discountType == '%'
                      ? 'percentage'
                      : 'fixed',
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
    if (_discountOverlay != null) {
      _discountOverlay!.remove();
      _discountOverlay = null;
      setState(() {
        _activeDiscountRowIndex = null;
      });
    }
  }

  void _closeAccountOverlay() {
    if (_accountOverlay != null) {
      _accountOverlay!.remove();
      _accountOverlay = null;
      setState(() {
        _activeAccountRowIndex = null;
      });
    }
  }

  void _showAccountMenu(
    BuildContext context,
    int index,
    _BillLineItemRow row,
    List<coa.AccountNode> accounts, {
    LayerLink? link,
    Offset? buttonOffset,
  }) {
    _closeAccountOverlay();
    setState(() {
      _activeAccountRowIndex = index;
    });

    final overlay = Overlay.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    bool showAbove = false;
    if (buttonOffset != null) {
      if (buttonOffset.dy + 400 > screenHeight && buttonOffset.dy > 400) {
        showAbove = true;
      }
    }

    _accountOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeAccountOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: link ?? row.accountLink,
            showWhenUnlinked: false,
            targetAnchor: showAbove ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor: showAbove ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset.zero,
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeAccountOverlay(),
                child: _AccountSelectionPopover(
                  accounts: accounts,
                  selectedAccountId: row.accountId,
                  onSelected: (acc) {
                    setState(() {
                      row.accountId = acc.id;
                      row.accountName = acc.name;
                    });
                    _closeAccountOverlay();
                  },
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
    return Container(width: 1, color: _borderColor);
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

  void _closeItemMenu() {
    if (_itemMenuOverlay != null) {
      _itemMenuOverlay!.remove();
      _itemMenuOverlay = null;
      setState(() {
        _activeMenuRowIndex = null;
      });
    }
  }

  void _showItemMenu(
    BuildContext context,
    int index,
    _BillLineItemRow row,
    LayerLink link,
    ItemsState itemsState,
  ) {
    final allItems = itemsState.items;
    _closeItemMenu();

    setState(() {
      _activeMenuRowIndex = index;
    });

    _itemMenuOverlay = ZAdaptiveMenu.show(
      context: context,
      link: link,
      onClose: _closeItemMenu,
      width: 180,
      gap: 4,
      borderColor: _borderColor,
      builder: (ctx) {
        String? hoveredItem;
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final isHidden = _hiddenDetails.contains(index);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSettingsOverlayItem(
                  label: isHidden
                      ? 'Show Additional Information'
                      : 'Hide Additional Information',
                  showHighlight: hoveredItem == 'toggle_info',
                  onHover: (v) => setOverlayState(
                    () => hoveredItem = v ? 'toggle_info' : null,
                  ),
                  onTap: () {
                    setState(() {
                      if (_hiddenDetails.contains(index)) {
                        _hiddenDetails.remove(index);
                      } else {
                        _hiddenDetails.add(index);
                      }
                    });
                    _closeItemMenu();
                  },
                ),
                const SizedBox(height: 4),
                _buildSettingsOverlayItem(
                  label: 'Clone',
                  showHighlight: hoveredItem == 'clone',
                  onHover: (v) => setOverlayState(
                    () => hoveredItem = v ? 'clone' : null,
                  ),
                  onTap: () {
                    setState(() {
                      _lineItems.insert(index + 1, row.clone());
                    });
                    _closeItemMenu();
                  },
                ),
                const SizedBox(height: 4),
                _buildSettingsOverlayItem(
                  label: 'Insert New Row',
                  showHighlight: hoveredItem == 'insert_row',
                  onHover: (v) => setOverlayState(
                    () => hoveredItem = v ? 'insert_row' : null,
                  ),
                  onTap: () {
                    setState(() {
                      _lineItems.insert(
                        index + 1,
                        _BillLineItemRow(),
                      );
                    });
                    _closeItemMenu();
                  },
                ),
                const SizedBox(height: 4),
                _buildSettingsOverlayItem(
                  label: 'Insert Items in Bulk',
                  showHighlight: hoveredItem == 'bulk',
                  onHover: (v) => setOverlayState(
                    () => hoveredItem = v ? 'bulk' : null,
                  ),
                  onTap: () {
                    _closeItemMenu();
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
                              newRow.itemNameCtrl.text =
                                  item.productName;
                              newRow.hsnCode = item.hsnCode;
                              newRow.hsnCtrl.text =
                                  item.hsnCode ?? '';
                              newRow.itemCode = item.itemCode;
                              newRow.rateCtrl.text =
                                  (item.costPrice ?? 0.0)
                                      .toStringAsFixed(2);
                              newRow.quantityCtrl.text = quantity
                                  .toString();
                              newRow.taxId = item.intraStateTaxId;
                              newRow.taxName =
                                  item.intraStateTaxName;
                              final matchedTax = itemsState
                                  .taxGroups
                                  .where(
                                    (tg) =>
                                        tg.id ==
                                        item.intraStateTaxId,
                                  )
                                  .firstOrNull;
                              newRow.taxRate =
                                  matchedTax?.taxRate ?? 0.0;
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
        );
      },
    );
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
                height: 32,
                child: FormDropdown<String>(
                  value: row.batchCtrl.text.isEmpty ? null : row.batchCtrl.text,
                  items: batches.map((b) => b.batchReference).toList(),
                  hint: 'Batch#',
                  height: 32,
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
              height: 32,
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
                  fontWeight: FontWeight.bold,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox.shrink(),
        const Spacer(),
        SizedBox(width: 440, child: _buildTotalsPanel()),
        const SizedBox(width: 96),
      ],
    );
  }

  Widget _buildTotalsPanel() {
    final totalQty = _lineItems
        .where((i) => i.itemId != null)
        .fold(0.0, (sum, i) => sum + i.quantity);
    final qtyStr = totalQty % 1 == 0
        ? totalQty.toInt().toString()
        : totalQty.toStringAsFixed(2);
    final hasSelectedTax = _lineItems.any(
      (row) => row.itemId != null && row.taxId != null && row.taxRate > 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub Total + Total Quantity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sub Total',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _labelColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total Quantity : $qtyStr',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                (_discountType == 'At Line Item Level'
                        ? _grossAmount
                        : _subTotal)
                    .toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // If discount is applied before tax, show discount row first, then divider
          if (_discountType == 'At Transaction Level' && _isDiscountBeforeTax) ...[
            _discountRow(),
            if (_discountAmount > 0) _buildTransactionDiscountAccountField(),
            const SizedBox(height: 8),
            const Divider(height: 24, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 8),
          ],
          // Per-tax breakdown rows (Conditional based on hasSelectedTax)
          if (hasSelectedTax) ..._buildTaxBreakdownRows(),
          // Total Tax Amount with editable field + pencil (Conditional based on hasSelectedTax)
          if (hasSelectedTax) ...[
            _buildTotalTaxRow(),
            const SizedBox(height: 12),
          ],
          // If discount is applied after tax, show discount row here
          if (_discountType == 'At Transaction Level' && !_isDiscountBeforeTax) ...[
            _discountRow(),
            if (_discountAmount > 0) _buildTransactionDiscountAccountField(),
            const SizedBox(height: 12),
          ],
          // TDS / TCS dynamically swapped based on _tdsTcsType
          if (_tdsTcsType == 'tcs') ...[
            _adjustmentRow(),
            const SizedBox(height: 12),
            _tdsTcsRow(),
          ] else ...[
            _tdsTcsRow(),
            const SizedBox(height: 12),
            _adjustmentRow(),
          ],

          const Divider(height: 32),
          // Total
          _totalLine(
            'Total',
            _total.toStringAsFixed(2),
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaxBreakdownRows() {
    if (_selectedVendor == null) {
      return [];
    }
    final Map<double, double> rateToTax = {};
    for (final row in _lineItems) {
      if (row.itemId != null && row.taxRate > 0) {
        double taxableAmount = row.amount;
        if (_isDiscountBeforeTax &&
            _subTotal > 0 &&
            _discountType == 'At Transaction Level') {
          final proportion = row.amount / _subTotal;
          taxableAmount = row.amount - (proportion * _discountAmount);
        }
        final tax = taxableAmount * row.taxRate / 100;
        rateToTax.update(row.taxRate, (v) => v + tax, ifAbsent: () => tax);
      }
    }

    final sortedRates = rateToTax.keys.toList()..sort();
    final widgets = <Widget>[];

    for (final rate in sortedRates) {
      final tax = rateToTax[rate] ?? 0;
      final rateStr = rate % 1 == 0 ? rate.toInt().toString() : rate.toString();

      if (_isKeralaPlaceOfSupply) {
        final half = rate / 2;
        final halfAmt = tax / 2;
        final halfStr = half % 1 == 0
            ? half.toInt().toString()
            : half.toStringAsFixed(1);

        widgets.add(
          Row(
            children: [
              Text(
                'CGST$halfStr [$halfStr%]',
                style: const TextStyle(fontSize: 13, color: _labelColor),
              ),
              const Spacer(),
              Text(
                halfAmt.toStringAsFixed(2),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          Row(
            children: [
              Text(
                'SGST$halfStr [$halfStr%]',
                style: const TextStyle(fontSize: 13, color: _labelColor),
              ),
              const Spacer(),
              Text(
                halfAmt.toStringAsFixed(2),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 12));
      } else {
        widgets.add(
          Row(
            children: [
              Text(
                'IGST$rateStr [$rateStr%]',
                style: const TextStyle(fontSize: 13, color: _labelColor),
              ),
              const Spacer(),
              Text(
                tax.toStringAsFixed(2),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  Widget _buildTotalTaxRow() {
    return Row(
      children: [
        const Text(
          'Total Tax Amount',
          style: TextStyle(fontSize: 13, color: _labelColor),
        ),
        const Spacer(),
        Container(
          width: 130,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: _fieldBorder),
            borderRadius: BorderRadius.circular(4),
            color: _bgWhite,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey(_taxAmount),
                  initialValue: _taxAmount.toStringAsFixed(2),
                  readOnly: true,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              Container(width: 1, height: 32, color: _fieldBorder),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  _selectedVendor?.currency ?? 'INR',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        CompositedTransformTarget(
          link: _totalTaxAmountLink,
          child: GestureDetector(
            onTap: () => _showTaxAmountEditPopover(context),
            child: const Icon(
              Icons.edit_outlined,
              size: 14,
              color: Color(0xFF0088FF),
            ),
          ),
        ),
      ],
    );
  }

  void _showTaxAmountEditPopover(BuildContext context) {
    if (_selectedVendor == null) return;
    _closeTaxAmountOverlay();

    final Map<String, ({String name, double rate, double amount})>
    initialTaxes = {};
    for (final row in _lineItems.where(
      (i) => i.itemId != null && i.taxRate > 0,
    )) {
      final key = row.taxId ?? row.taxName ?? '';
      if (key.isEmpty) continue;

      double taxableAmount = row.amount;
      if (_isDiscountBeforeTax &&
          _subTotal > 0 &&
          _discountType == 'At Transaction Level') {
        final proportion = row.amount / _subTotal;
        taxableAmount = row.amount - (proportion * _discountAmount);
      }
      final tax = taxableAmount * row.taxRate / 100;

      if (_isKeralaPlaceOfSupply) {
        final half = row.taxRate / 2;
        final halfAmt = tax / 2;
        final halfStr = half % 1 == 0
            ? half.toInt().toString()
            : half.toStringAsFixed(1);

        // Add CGST
        final cgstKey = '${key}_CGST';
        if (initialTaxes.containsKey(cgstKey)) {
          final e = initialTaxes[cgstKey]!;
          initialTaxes[cgstKey] = (
            name: e.name,
            rate: e.rate,
            amount: e.amount + halfAmt,
          );
        } else {
          initialTaxes[cgstKey] = (
            name: 'CGST$halfStr',
            rate: half,
            amount: halfAmt,
          );
        }

        // Add SGST
        final sgstKey = '${key}_SGST';
        if (initialTaxes.containsKey(sgstKey)) {
          final e = initialTaxes[sgstKey]!;
          initialTaxes[sgstKey] = (
            name: e.name,
            rate: e.rate,
            amount: e.amount + halfAmt,
          );
        } else {
          initialTaxes[sgstKey] = (
            name: 'SGST$halfStr',
            rate: half,
            amount: halfAmt,
          );
        }
      } else {
        final rateStr = row.taxRate % 1 == 0
            ? row.taxRate.toInt().toString()
            : row.taxRate.toString();
        if (initialTaxes.containsKey(key)) {
          final e = initialTaxes[key]!;
          initialTaxes[key] = (
            name: e.name,
            rate: e.rate,
            amount: e.amount + tax,
          );
        } else {
          initialTaxes[key] = (
            name: 'IGST$rateStr',
            rate: row.taxRate,
            amount: tax,
          );
        }
      }
    }

    _taxAmountOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeTaxAmountOverlay,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: _totalTaxAmountLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(-150, 10),
            child: Material(
              color: Colors.transparent,
              child: _TaxAmountEditPopover(
                initialTaxes: initialTaxes,
                onCancel: _closeTaxAmountOverlay,
                onSave: (editedAmounts) {
                  _closeTaxAmountOverlay();
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_taxAmountOverlay!);
  }

  void _closeTaxAmountOverlay() {
    _taxAmountOverlay?.remove();
    _taxAmountOverlay = null;
  }

  Widget _discountRow() {
    final hasSelectedTax = _lineItems.any(
      (row) => row.itemId != null && row.taxId != null && row.taxRate > 0,
    );
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Discount',
              style: TextStyle(fontSize: 13, color: _labelColor),
            ),
            if (hasSelectedTax) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDiscountBeforeTax = !_isDiscountBeforeTax;
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    _isDiscountBeforeTax
                        ? 'Apply after tax'
                        : 'Apply before tax',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0088FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
        Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: _fieldBorder),
            borderRadius: BorderRadius.circular(4),
            color: _bgWhite,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                child: TextField(
                  controller: _discountPercentCtrl,
                  onChanged: (v) {
                    setState(() {
                      _discountPercent = double.tryParse(v) ?? 0;
                    });
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: '0',
                  ),
                ),
              ),
              Container(width: 1, height: 32, color: _fieldBorder),
              CompositedTransformTarget(
                link: _transactionDiscountTypeLink,
                child: GestureDetector(
                  onTap: _showTransactionDiscountTypeOverlay,
                  child: SizedBox(
                    width: 45,
                    height: 32,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _transactionDiscountType,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 80,
          child: Text(
            _discountAmount == 0
                ? '0.00'
                : '-${_discountAmount.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDiscountAccountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Discount Account*',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: _fieldBorder),
                    borderRadius: BorderRadius.circular(4),
                    color: _bgWhite,
                  ),
                  child: _buildDiscountAccountDropdown(),
                ),
                const SizedBox(height: 4),
                const SizedBox(
                  width: 200,
                  child: Text(
                    'You can create a new account with type as Expense or Other Expense.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _tdsTcsRow() {
    final isTcs = _tdsTcsType == 'tcs';
    final selectedRate = isTcs
        ? _tcsRatesList.firstWhere(
            (r) => r['id'] == _selectedTdsTcsId,
            orElse: () => <String, dynamic>{},
          )
        : _tdsRatesList.firstWhere(
            (r) => r['id'] == _selectedTdsTcsId,
            orElse: () => <String, dynamic>{},
          );
    String displayText = 'Select a Tax';
    if (selectedRate.isNotEmpty) {
      final taxName = selectedRate['tax_name'] ?? '';
      final d = double.tryParse(
        (isTcs ? selectedRate['rate'] : selectedRate['base_rate'])?.toString() ?? '0',
      );
      final baseRateStr = (d == null) 
          ? '' 
          : (d == d.toInt() ? '${d.toInt()}%' : '$d%');
      displayText = "$taxName [$baseRateStr]";
    }

    final calculatedAmount = _tdsTcsAmount;
    final displayAmount = calculatedAmount.toStringAsFixed(2);

    return RadioGroup<String>(
      groupValue: _tdsTcsType,
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _tdsTcsType = val;
            _selectedTdsTcsId = null;
            _tdsTcsRate = 0.0;
          });
        }
      },
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: Radio<String>(value: 'tds', activeColor: _primaryBlue),
              ),
              const SizedBox(width: 8),
              const Text('TDS', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: Radio<String>(value: 'tcs', activeColor: _primaryBlue),
              ),
              const SizedBox(width: 8),
              const Text('TCS', style: TextStyle(fontSize: 13)),
            ],
          ),

          const Spacer(),
          if (_tdsTcsType != 'none') ...[
            SizedBox(
              width: 160,
              child: CompositedTransformTarget(
                link: _tdsLink,
                child: Builder(
                  builder: (btnContext) {
                    return GestureDetector(
                      onTap: () async {
                        if (_tdsTcsType == 'tcs' ? _tcsRatesList.isEmpty : _tdsRatesList.isEmpty) {
                          await _loadTdsRates();
                        }
                        if (!context.mounted) return;
                        final renderBox = btnContext.findRenderObject() as RenderBox?;
                        final offset = renderBox?.localToGlobal(Offset.zero);
                        _showTdsMenu(context, offset);
                      },
                      child: () {
                        bool isHovered = false;
                        return StatefulBuilder(
                          builder: (context, setStateDropdown) {
                            return MouseRegion(
                              onEnter: (_) => setStateDropdown(() => isHovered = true),
                              onExit: (_) => setStateDropdown(() => isHovered = false),
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: (isHovered || _isTdsOpen)
                                        ? const Color(0xFF0088FF)
                                        : const Color(0xFFD1D5DB),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayText,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: selectedRate.isNotEmpty
                                              ? const Color(0xFF111827)
                                              : _hintColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (selectedRate.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedTdsTcsId = null;
                                            _tdsTcsRate = 0.0;
                                          });
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: _hintColor,
                                          ),
                                        ),
                                      ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      size: 16,
                                      color: _hintColor,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }(),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: Text(
                _tdsTcsType == 'tds' ? '-$displayAmount' : displayAmount,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ] else
            const SizedBox(width: 252),
        ],
      ),
    );
  }

  void _showTdsMenu(
    BuildContext context,
    Offset? buttonOffset,
  ) {
    _closeTdsOverlay();
    setState(() {
      _isTdsOpen = true;
    });

    final overlay = Overlay.of(context);

    final screenHeight = MediaQuery.of(context).size.height;
    bool showAbove = false;
    if (buttonOffset != null) {
      const double popoverHeight = 360.0;
      final double spaceBelow = screenHeight - (buttonOffset.dy + 32) - 16;
      final double spaceAbove = buttonOffset.dy - 16;
      if (spaceBelow < popoverHeight && spaceAbove > spaceBelow) {
        showAbove = true;
      }
    }

    _tdsOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeTdsOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _tdsLink,
            showWhenUnlinked: false,
            targetAnchor: showAbove ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor: showAbove ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset.zero,
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeTdsOverlay(),
                child: _TdsSelectionPopover(
                  isTcs: _tdsTcsType == 'tcs',
                  tdsRates: _tdsTcsType == 'tcs' ? _tcsRatesList : _tdsRatesList,
                  tdsSections: _tdsTcsType == 'tcs' ? _tcsNaturesList : _tdsSectionsList,
                  tdsGroups: _tdsGroupsList,
                  selectedTdsId: _selectedTdsTcsId,
                  onSelected: (rate) {
                    final isTcs = _tdsTcsType == 'tcs';
                    setState(() {
                      _selectedTdsTcsId = rate['id']?.toString() ?? '';
                      _tdsTcsRate = double.tryParse((isTcs ? rate['rate'] : rate['base_rate'])?.toString() ?? '0') ?? 0.0;
                    });
                    _closeTdsOverlay();
                  },
                  onManageTds: () {
                    _closeTdsOverlay();
                    if (_tdsTcsType == 'tcs') {
                      _showManageTcsRatesDialog();
                    } else {
                      _showManageTdsRatesDialog();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_tdsOverlay!);
  }

  void _closeTdsOverlay() {
    if (_tdsOverlay != null) {
      _tdsOverlay!.remove();
      _tdsOverlay = null;
      setState(() {
        _isTdsOpen = false;
      });
    }
  }

  void _showManageTdsRatesDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ManageTdsTcsRatesDialog(
        title: 'Manage TDS Rates',
        isTcs: false,
        items: _tdsRatesList,
        sections: _tdsSectionsList,
        selectedId: _selectedTdsTcsId,
        onSelect: (value) {
          setState(() {
            _selectedTdsTcsId = value['id']?.toString() ?? '';
            _tdsTcsRate = double.tryParse(value['base_rate']?.toString() ?? '0') ?? 0.0;
          });
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncTdsRates(items);
          if (mounted) {
            setState(() {
              _tdsRatesList = updated;
            });
          }
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }
          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'tds-rates',
              item['id'].toString(),
            );
            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This TDS rate is in use and cannot be deleted.';
            }
          } catch (e) {
            AppLogger.error(
              'Error checking TDS rate usage',
              error: e,
              module: 'purchases',
            );
          }
          return null;
        },
      ),
    );
    await _performLoadTdsRates();
  }

  void _showManageTcsRatesDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ManageTdsTcsRatesDialog(
        title: 'Manage TCS Rates',
        isTcs: true,
        items: _tcsRatesList,
        sections: _tcsNaturesList,
        selectedId: _selectedTdsTcsId,
        onSelect: (value) {
          setState(() {
            _selectedTdsTcsId = value['id']?.toString() ?? '';
            _tdsTcsRate = double.tryParse(value['rate']?.toString() ?? '0') ?? 0.0;
          });
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncTcsRates(items);
          if (mounted) {
            setState(() {
              _tcsRatesList = updated;
            });
          }
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }
          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'tcs-rates',
              item['id'].toString(),
            );
            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This TCS rate is in use and cannot be deleted.';
            }
          } catch (e) {
            AppLogger.error(
              'Error checking TCS rate usage',
              error: e,
              module: 'purchases',
            );
          }
          return null;
        },
      ),
    );
    await _performLoadTdsRates();
  }


  Widget _adjustmentRow() {
    return Row(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isAdjustmentLabelHovered = true),
          onExit: (_) => setState(() => _isAdjustmentLabelHovered = false),
          child: CustomPaint(
            foregroundPainter: _DashedBorderPainter(
              color:
                  (_adjustmentLabelFocusNode.hasFocus ||
                      _isAdjustmentLabelHovered)
                  ? const Color(0xFF0088FF)
                  : const Color(0xFFCBD5E1),
              isFocused: _adjustmentLabelFocusNode.hasFocus,
              isHovered: _isAdjustmentLabelHovered,
            ),
            child: Container(
              width: 140,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: _adjustmentLabelCtrl,
                focusNode: _adjustmentLabelFocusNode,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 110,
          child: _zField(
            _adjustmentAmountCtrl,
            hint: '0.00',
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onChanged: (val) {
              setState(() {
                _adjustment = double.tryParse(val) ?? 0;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        const SizedBox(
          width: 18,
          child: ZTooltip(
            message: "Add any other +ve or -ve charges that need to be applied to adjust the total amount of the transaction Eg. +10 or -10.",
            direction: ZTooltipDirection.bottom,
            child: Icon(LucideIcons.helpCircle, size: 14, color: _textMuted),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            _adjustment == 0 ? '0.00' : _adjustment.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _totalLine(
    String label,
    String val, {
    bool isBold = false,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: _labelColor,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
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
                children: [
                  CompositedTransformTarget(
                    link: _uploadLink,
                    child: MouseRegion(
                      onEnter: (_) =>
                          setState(() => _isUploadButtonHovered = true),
                      onExit: (_) =>
                          setState(() => _isUploadButtonHovered = false),
                      child: CustomPaint(
                        foregroundPainter: _DashedBorderPainter(
                          color:
                              (_isUploadButtonHovered || _uploadOverlay != null)
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFD1D5DB),
                        ),
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _pickUploadFiles,
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
                                onTap: _toggleUploadOverlay,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Icon(
                                    _uploadOverlay != null
                                        ? LucideIcons.chevronUp
                                        : LucideIcons.chevronDown,
                                    size: 16,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_attachedFiles.isNotEmpty) _buildAttachmentBadge(),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'You can upload a maximum of 10 files, 5MB each',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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

  Widget _buildAttachmentBadge() {
    return CompositedTransformTarget(
      link: _attachmentBadgeLink,
      child: InkWell(
        onTap: _toggleAttachmentListOverlay,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.paperclip, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '${_attachedFiles.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAttachmentListOverlay() {
    if (_attachmentListOverlay != null) {
      _attachmentListOverlay?.remove();
      _attachmentListOverlay = null;
      setState(() {});
      return;
    }

    _attachmentListOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _attachmentListOverlay?.remove();
                _attachmentListOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _attachmentBadgeLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _attachedFiles
                          .map((file) => _buildAttachmentListItem(file))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_attachmentListOverlay!);
    setState(() {});
  }

  Widget _buildAttachmentListItem(PlatformFile file) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setItemState) {
        return MouseRegion(
          onEnter: (_) => setItemState(() => isHovered = true),
          onExit: (_) => setItemState(() => isHovered = false),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.file,
                  size: 16,
                  color: isHovered ? Colors.white : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered
                              ? Colors.white
                              : const Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'File Size: ${(file.size / 1024).toStringAsFixed(2)} KB',
                        style: TextStyle(
                          fontSize: 11,
                          color: isHovered
                              ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isHovered)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _attachedFiles.remove(file);
                        if (_attachedFiles.isEmpty) {
                          _attachmentListOverlay?.remove();
                          _attachmentListOverlay = null;
                        }
                      });
                      _attachmentListOverlay?.markNeedsBuild();
                    },
                    child: const Icon(
                      LucideIcons.trash,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null) return;

      setState(() {
        final totalFiles = _attachedFiles.length + result.files.length;
        if (totalFiles > 10) {
          ZerpaiToast.error(
            context,
            'You can only attach a maximum of 10 files',
          );
          return;
        }

        // Check file size (5MB = 5 * 1024 * 1024 bytes)
        final oversizedFiles = result.files
            .where((f) => f.size > 5 * 1024 * 1024)
            .toList();
        if (oversizedFiles.isNotEmpty) {
          ZerpaiToast.error(
            context,
            'File size should be less than or equal to 5MB',
          );
          return;
        }

        _attachedFiles = [..._attachedFiles, ...result.files];
      });

      final count = _attachedFiles.length;
      if (count > 0) {
        ZerpaiToast.success(
          context,
          '$count file${count == 1 ? '' : 's'} attached',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to pick files: $e');
    }
  }

  void _toggleUploadOverlay() {
    if (_uploadOverlay != null) {
      _uploadOverlay?.remove();
      _uploadOverlay = null;
      if (mounted) setState(() {});
      return;
    }

    _uploadOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _uploadOverlay?.remove();
                _uploadOverlay = null;
                if (mounted) setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _uploadLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -8),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    _buildUploadItem('Attach From Desktop', true),
                    _buildUploadItem('Attach From Documents', false),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_uploadOverlay!);
    if (mounted) setState(() {});
  }

  Widget _buildUploadItem(String label, bool isSelected) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setOverlayState) {
        return InkWell(
          onHover: (v) => setOverlayState(() => isHovered = v),
          onTap: () async {
            _uploadOverlay?.remove();
            _uploadOverlay = null;
            if (mounted) setState(() {});
            await _pickUploadFiles();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : (isHovered ? const Color(0xFFEFF6FF) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isHovered
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF374151)),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveAttachments(String billId) async {
    try {
      final supabase = Supabase.instance.client;
      final apiClient = ApiClient();
      final user = ref.read(authUserProvider);

      for (var file in _attachedFiles) {
        if (file.bytes == null) {
          AppLogger.warning(
            'Skipping file ${file.name} because bytes are null',
            module: 'purchases',
          );
          continue;
        }

        final base64Data = base64Encode(file.bytes!);

        // Upload to Cloudflare R2 via backend
        final response = await apiClient.post(
          '/lookups/uploads',
          data: {
            'fileName': file.name,
            'fileData': base64Data,
            'mimeType': 'application/octet-stream',
            'prefix': 'bills',
          },
        );

        final fileKey = response.data['fileKey'] ?? 'bills/${file.name}';

        await supabase.from('bill_attachments').insert({
          'bill_id': billId,
          'file_name': file.name,
          'original_file_name': file.name,
          'file_url': fileKey,
          'file_type': file.extension,
          'file_size': file.size,
          'uploaded_by': user?.id,
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error saving bill attachments',
        error: e,
        module: 'purchases',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to save attachments: $e');
      }
    }
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
          OutlinedButton(
            onPressed: _isLoading ? null : () => _saveBill(status: 'draft'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Save as Draft',
              style: TextStyle(color: _textPrimary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (_isLoading || !_isSaveAsOpenEnabled)
                ? null
                : () => _saveBill(status: 'open'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSaveAsOpenEnabled
                  ? _primaryGreen
                  : const Color(0xFFE5E7EB),
              foregroundColor: _isSaveAsOpenEnabled
                  ? Colors.white
                  : const Color(0xFF9CA3AF),
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
          OutlinedButton(
            onPressed: () {
              if (widget.poId != null && widget.poId!.isNotEmpty) {
                context.go('/purchases/purchase-orders/${widget.poId}');
              } else {
                context.go(AppRoutes.bills);
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
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
    TextAlign textAlign = TextAlign.left,
    String? hintText,
    bool isTransparentBorder = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return SizedBox(
      height: 32,
      child: InCellWrapper(
        focusNode: focusNode,
        isTransparentBorder: isTransparentBorder,
        child: Row(
          children: [
            if (prefixIcon != null) ...[prefixIcon, const SizedBox(width: 4)],
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: inputFormatters,
                textAlign: textAlign,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: hintText,
                  hintStyle: hintText != null
                      ? const TextStyle(color: _hintColor, fontSize: 12)
                      : null,
                ),
              ),
            ),
          ],
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
    Color text = const Color(0xFF111827);
    Color subtext = const Color(0xFF6B7280);

    if (isHovered) {
      text = Colors.white;
      subtext = Colors.white70;
    } else if (isSelected) {
      text = const Color(0xFF111827);
      subtext = const Color(0xFF6B7280);
    }

    return Container(
      padding: EdgeInsets.only(
        left: 12 + indentation,
        right: 12,
        top: 8,
        bottom: 8,
      ),
      color: Colors.transparent,
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
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
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
    List<TextInputFormatter>? inputFormatters,
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
                inputFormatters: inputFormatters,
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

  void _showItemDetailsSidebar(
    _BillLineItemRow row, {
    int initialTabIndex = 0,
  }) {
    if (_itemDetailsSidebarOverlay != null) {
      _itemDetailsSidebarOverlay!.remove();
      _itemDetailsSidebarOverlay = null;
    }

    final selectedVendor = _selectedVendor;

    _itemDetailsSidebarOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () {
              _itemDetailsSidebarOverlay?.remove();
              _itemDetailsSidebarOverlay = null;
            },
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: _ItemDetailsSidebar(
                row: row,
                initialTabIndex: initialTabIndex,
                vendorName: selectedVendor != null
                    ? selectedVendor.displayName
                    : null,
                onClose: () {
                  _itemDetailsSidebarOverlay?.remove();
                  _itemDetailsSidebarOverlay = null;
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_itemDetailsSidebarOverlay!);
  }

  OverlayEntry? _itcOverlayEntry;

  void _removeItcOverlay() {
    _itcOverlayEntry?.remove();
    _itcOverlayEntry = null;
  }

  void _showItcOverlay(_BillLineItemRow row) {
    _removeItcOverlay();
    String tempSelection = row.itcEligibility;

    _itcOverlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: row.itcLayerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomCenter,
          followerAnchor: Alignment.topCenter,
          offset: const Offset(0, 8),
          child: Align(
            alignment: Alignment.topCenter,
            child: TapRegion(
              onTapOutside: (_) => _removeItcOverlay(),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    return Container(
                      width: 280,
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Input Tax Credit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeItcOverlay(),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                          const SizedBox(height: 8),
                          _buildItcRadioOption(
                            label: 'Eligible For ITC',
                            value: 'Eligible For ITC',
                            groupValue: tempSelection,
                            onChanged: (val) {
                              if (val != null) {
                                setOverlayState(() {
                                  tempSelection = val;
                                });
                              }
                            },
                          ),
                          _buildItcRadioOption(
                            label: 'Ineligible - As per Section 17 (5)',
                            value: 'Ineligible - As per Section 17 (5)',
                            groupValue: tempSelection,
                            onChanged: (val) {
                              if (val != null) {
                                setOverlayState(() {
                                  tempSelection = val;
                                });
                              }
                            },
                          ),
                          _buildItcRadioOption(
                            label: 'Ineligible - Others',
                            value: 'Ineligible - Others',
                            groupValue: tempSelection,
                            onChanged: (val) {
                              if (val != null) {
                                setOverlayState(() {
                                  tempSelection = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    row.itcEligibility = tempSelection;
                                  });
                                  _removeItcOverlay();
                                },
                                child: const Text(
                                  'OK',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_itcOverlayEntry!);
  }

  Widget _buildItcRadioOption({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => onChanged(value),
        child: Row(
          children: [
            Transform.scale(
              scale: 0.85,
              child: RadioGroup<String>(
                groupValue: groupValue,
                onChanged: onChanged,
                child: Radio<String>(
                  value: value,
                  activeColor: const Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _gridField(
    TextEditingController ctrl, {
    String hint = '',
    TextAlign textAlign = TextAlign.start,
    FontWeight valueFontWeight = FontWeight.w600,
    required Function(String) onChanged,
    Function(String)? onSubmitted,
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    final fn = focusNode ?? FocusNode();
    return _HoverableField(
      builder: (isHovered) {
        return ListenableBuilder(
          listenable: fn,
          builder: (context, _) {
            final isActive = isHovered || fn.hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF0088FF)
                      : Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      focusNode: fn,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      inputFormatters: inputFormatters,
                      textAlign: textAlign,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: valueFontWeight,
                        color: _textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hintText: hint,
                        hintStyle: TextStyle(
                          color: _hintColor.withValues(alpha: 0.6),
                        ),
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
            );
          },
        );
      },
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
  final bool isTransparentBorder;

  const InCellWrapper({
    super.key,
    required this.child,
    this.focusNode,
    this.isDropdownOpen = false,
    this.isTransparentBorder = false,
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
                ? widget.isTransparentBorder
                      ? Border.all(color: Colors.transparent, width: 0)
                      : Border.all(
                          color: const Color(0xFF0088FF),
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

class _CellDropdownWrapper extends StatefulWidget {
  final Widget child;

  const _CellDropdownWrapper({required this.child});

  @override
  State<_CellDropdownWrapper> createState() => _CellDropdownWrapperState();
}

class _CellDropdownWrapperState extends State<_CellDropdownWrapper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _hovered ? const Color(0xFF3B82F6) : Colors.transparent,
            width: _hovered ? 1.5 : 1.0,
          ),
        ),
        child: widget.child,
      ),
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

  const _TaxSelectionPopover({this.selectedTaxId, required this.onTaxSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(itemsControllerProvider);
    final taxes = itemsState.taxGroups;

    // Create dummy objects for special options
    final nonTaxable = TaxRate(
      id: 'non_taxable',
      taxName: 'Non-Taxable',
      taxRate: 0,
    );
    final outOfScope = TaxRate(
      id: 'out_of_scope',
      taxName: 'Out of Scope',
      taxRate: 0,
    );
    final nonGst = TaxRate(
      id: 'non_gst',
      taxName: 'Non-GST Supply',
      taxRate: 0,
    );

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
                    description:
                        "Supplies on which you don't charge any GST or include them in the returns.",
                    isSelected: selectedTaxId == 'out_of_scope',
                    onTap: () => onTaxSelected(outOfScope),
                  ),
                  _SpecialPopoverListItem(
                    title: "Non-GST Supply",
                    description:
                        "Supplies which do not come under GST such as petroleum products and liquor.",
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
                  ...([...taxes]..sort((a, b) => a.taxRate.compareTo(b.taxRate))).map((tax) {
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
  State<_SpecialPopoverListItem> createState() =>
      _SpecialPopoverListItemState();
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
                style: TextStyle(
                  fontSize: 13,
                  color: text,
                  fontWeight: FontWeight.w500,
                ),
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
  final List<coa.AccountNode> accounts;
  final String? selectedAccountId;
  final ValueChanged<coa.AccountNode> onSelected;

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

  Map<String, List<coa.AccountNode>> get _grouped {
    final Map<String, List<coa.AccountNode>> grouped = {};
    for (var acc in widget.accounts) {
      if (_search.isNotEmpty &&
          !acc.name.toLowerCase().contains(_search.toLowerCase())) {
        continue;
      }
      final type = acc.accountType;
      grouped.putIfAbsent(type, () => []).add(acc);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    return Container(
      width: 320,
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
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Select an account',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 36,
                  ),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: Color(0xFFD1D5DB),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: Color(0xFFD1D5DB),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
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
                          color: _textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...() {
                      final List<Widget> items = [];
                      final groupAccounts = entry.value;
                      final accountMap = {for (var a in groupAccounts) a.id: a};
                      
                      // Find root nodes (either parentId is null, or parent is not in this group)
                      final rootNodes = groupAccounts.where((a) => a.parentId == null || !accountMap.containsKey(a.parentId)).toList();
                      
                      void addNode(coa.AccountNode node, int depth) {
                        final isSelected = node.id == widget.selectedAccountId;
                        items.add(
                          _PopoverListItem(
                            label: node.systemAccountName.isNotEmpty
                                ? node.systemAccountName
                                : node.userAccountName,
                            indent: depth,
                            isSelected: isSelected,
                            onTap: () => widget.onSelected(node),
                          )
                        );
                        
                        // Add children
                        final children = groupAccounts.where((a) => a.parentId == node.id).toList();
                        for (var child in children) {
                          addNode(child, depth + 1);
                        }
                      }
                      
                      for (var root in rootNodes) {
                        addNode(root, 0);
                      }
                      
                      return items;
                    }(),
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
      width: 60,
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
          _DiscountPopoverListItem(
            label: '%',
            isSelected: selectedType == 'percentage',
            onTap: () => onSelected('percentage'),
          ),
          _DiscountPopoverListItem(
            label: '₹',
            isSelected: selectedType == 'fixed',
            onTap: () => onSelected('fixed'),
          ),
        ],
      ),
    );
  }
}

class _DiscountPopoverListItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DiscountPopoverListItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DiscountPopoverListItem> createState() => _DiscountPopoverListItemState();
}

class _DiscountPopoverListItemState extends State<_DiscountPopoverListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hover
        ? const Color(0xFF3B82F6)
        : widget.isSelected
            ? const Color(0xFFF3F4F6)
            : Colors.transparent;
    final text = _hover
        ? Colors.white
        : const Color(0xFF111827);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  color: text,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Popover List Item ──────────────────────────────────────────────────────
class _PopoverListItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int indent;

  const _PopoverListItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.indent = 0,
  });

  @override
  State<_PopoverListItem> createState() => _PopoverListItemState();
}

class _PopoverListItemState extends State<_PopoverListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hover
        ? const Color(0xFF3B82F6)
        : widget.isSelected
            ? const Color(0xFFF3F4F6)
            : Colors.transparent;
    final text = _hover ? Colors.white : const Color(0xFF111827);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: EdgeInsets.only(
            left: 32.0 + (widget.indent * 16.0),
            right: 12,
            top: 8,
            bottom: 8,
          ),
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
  final bool isService;
  final VoidCallback onCancel;
  final Function(String) onSave;

  const _HSNCodeEditPopover({
    required this.initialHsnCode,
    this.isService = false,
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
      builder: (context) =>
          HsnSacSearchModal(type: widget.isService ? 'SAC' : 'HSN', initialQuery: _ctrl.text),
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
          padding: const EdgeInsets.only(left: 172),
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
                child: Text(
                  widget.isService ? 'SAC Code' : 'HSN Code',
                  style: const TextStyle(
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
                    hintText: widget.isService ? 'Enter SAC Code' : 'Enter HSN Code',
                    hintStyle: const TextStyle(color: _hintColor, fontSize: 13),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
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
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 13),
                      ),
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
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
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
                                        border: Border.all(
                                          color: const Color(0xFFD1D5DB),
                                        ),
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
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
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
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0088FF),
                                    ),
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
                                              border: Border.all(
                                                color: const Color(0xFFD1D5DB),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: const Icon(
                                                      Icons.remove,
                                                      size: 14,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ),
                                                const VerticalDivider(
                                                  width: 1,
                                                  color: Color(0xFFE5E7EB),
                                                ),
                                                Container(
                                                  width: 32,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '$count',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF111827),
                                                    ),
                                                  ),
                                                ),
                                                const VerticalDivider(
                                                  width: 1,
                                                  color: Color(0xFFE5E7EB),
                                                ),
                                                GestureDetector(
                                                  onTap: () => setState(
                                                    () =>
                                                        _counts[id] = count + 1,
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
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
                              return {'item': i, 'quantity': qty};
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
                    child: const Text(
                      'Add Items',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 13, color: Color(0xFF111827)),
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

class _ItemDetailsSidebar extends ConsumerStatefulWidget {
  final _BillLineItemRow row;
  final VoidCallback onClose;
  final String? vendorName;
  final int initialTabIndex;

  const _ItemDetailsSidebar({
    required this.row,
    required this.onClose,
    this.vendorName,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<_ItemDetailsSidebar> createState() =>
      _ItemDetailsSidebarState();
}

class _ItemDetailsSidebarState extends ConsumerState<_ItemDetailsSidebar> {
  late int _activeTabIndex;
  String _stockView = 'Physical Stock';

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(left: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                const Text(
                  'Item Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFFEF4444),
                  ),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Item Info Card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      color: Color(0xFF9CA3AF),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inventory Items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.row.itemName ?? "Select Item",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.row.itemType ?? 'goods'} • ${widget.row.itemCode ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _tabItem('ITEM DETAILS', 0),
                const SizedBox(width: 24),
                _tabItem('STOCK LOCATIONS', 1),
                const SizedBox(width: 24),
                _tabItem('TRANSACTIONS', 2),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab Content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: Color(0xFF2563EB), width: 2),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_activeTabIndex == 0) {
      return _buildItemDetailsTab();
    } else if (_activeTabIndex == 1) {
      return _buildStockLocationsTab();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Sales Orders',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
              const Spacer(),
              const Text(
                'Status: ',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const Text(
                'All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: true,
                  onChanged: (v) {},
                  activeColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Show only ${widget.vendorName ?? 'vendor'}\'s transactions',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
            ],
          ),
          const Expanded(
            child: Center(
              child: Text(
                'No Sales Orders recorded yet.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailsTab() {
    final itemId = widget.row.itemId;
    final itemAsync = itemId != null
        ? ref.watch(itemDetailByIdProvider(itemId))
        : const AsyncValue<Item?>.data(null);
    return itemAsync.when(
      loading: () => const FormSkeleton(),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error: $e'),
      ),
      data: (item) {
        final toBeShippedVal = item?.toBeShipped?.toStringAsFixed(2) ?? '0.00';
        final toBeReceivedVal = item?.toBeReceived?.toStringAsFixed(2) ?? '0.00';
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoBox('To Be Shipped', toBeShippedVal, Icons.local_shipping_outlined),
                  _infoBox('To Be Received', toBeReceivedVal, Icons.arrow_downward),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Sales Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              _detailRow('Price', '₹${widget.row.rate.toStringAsFixed(2)}'),
              _detailRow('Account', widget.row.accountName ?? item?.salesAccountName ?? '-'),
              const SizedBox(height: 24),
              const Text(
                'Purchase Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              _detailRow('Price', '₹${widget.row.rate.toStringAsFixed(2)}'),
              _detailRow('Account', widget.row.accountName ?? item?.purchaseAccountName ?? '-'),
            ],
          ),
        );
      },
    );
  }

  Widget _infoBox(String title, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockLocationsTab() {
    final stockAsync = ref.watch(
      itemWarehouseStocksProvider(widget.row.itemId ?? ''),
    );
    return stockAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: TableSkeleton(rows: 6, columns: 3, showHeader: false),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stocks) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MenuAnchor(
                style: const MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.white),
                  surfaceTintColor: WidgetStatePropertyAll(Colors.white),
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
                        Text(
                          _stockView,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: Color(0xFF111827),
                        ),
                      ],
                    ),
                  );
                },
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => setState(() => _stockView = 'Physical Stock'),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                          return const Color(0xFF0088FF);
                        }
                        return Colors.white;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                          return Colors.white;
                        }
                        return const Color(0xFF111827);
                      }),
                    ),
                    child: const Text('Physical Stock'),
                  ),
                  MenuItemButton(
                    onPressed: () => setState(() => _stockView = 'Accounting Stock'),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                          return const Color(0xFF0088FF);
                        }
                        return Colors.white;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                          return Colors.white;
                        }
                        return const Color(0xFF111827);
                      }),
                    ),
                    child: const Text('Accounting Stock'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                    children: [
                      _tableHeaderCell('LOCATION NAME'),
                      _tableHeaderCell('STOCK ON HAND'),
                      _tableHeaderCell('COMMITTED STOCK'),
                      _tableHeaderCell('AVAILABLE FOR SALE'),
                    ],
                  ),
                  ...stocks.map((wh) {
                    final numbers = _stockView == 'Accounting Stock'
                        ? wh.accounting
                        : wh.physical;
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  wh.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _tableCell(numbers.onHand.toStringAsFixed(2)),
                        _tableCell(numbers.committed.toStringAsFixed(2)),
                        _tableCell(numbers.available.toStringAsFixed(2)),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
      ),
    );
  }
}

class _MenuHoverItem extends StatefulWidget {
  final IconData icon;
  final String label;

  const _MenuHoverItem({required this.icon, required this.label});

  @override
  State<_MenuHoverItem> createState() => _MenuHoverItemState();
}

class _MenuHoverItemState extends State<_MenuHoverItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: _isHovered ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  color: _isHovered ? Colors.white : const Color(0xFF1F2937),
                  fontWeight: _isHovered ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildIconAction(
  IconData icon, {
  double size = 16,
  VoidCallback? onTap,
  Color? color,
}) {
  final content = Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      border: Border.all(
        color: color?.withValues(alpha: 0.3) ?? const Color(0xFFD3D3D3),
      ),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: size, color: color ?? const Color(0xFF808080)),
  );

  if (onTap == null) return content;

  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(onTap: onTap, child: content),
  );
}

class _HoverableDescriptionContainer extends StatefulWidget {
  final Widget child;
  const _HoverableDescriptionContainer({required this.child});
  @override
  State<_HoverableDescriptionContainer> createState() =>
      _HoverableDescriptionContainerState();
}

class _HoverableDescriptionContainerState
    extends State<_HoverableDescriptionContainer> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _focused
                  ? const Color(0xFF0088FF)
                  : (_hovered
                      ? const Color(0xFF2196F3)
                      : const Color(0xFFE5E7EB)),
              width: _focused ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: widget.child,
        ),
      ),
    );
  }
}

class _TaxAmountEditPopover extends StatefulWidget {
  final Map<String, ({String name, double rate, double amount})> initialTaxes;
  final Function(Map<String, double>) onSave;
  final VoidCallback onCancel;

  const _TaxAmountEditPopover({
    required this.initialTaxes,
    required this.onSave,
    required this.onCancel,
  });

  @override
  _TaxAmountEditPopoverState createState() => _TaxAmountEditPopoverState();
}

class _TaxAmountEditPopoverState extends State<_TaxAmountEditPopover> {
  late Map<String, double> _editedAmounts;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _editedAmounts = {};
    widget.initialTaxes.forEach((key, value) {
      _editedAmounts[key] = value.amount;
    });
    _calculateTotal();
  }

  void _calculateTotal() {
    double sum = 0;
    _editedAmounts.forEach((key, value) {
      sum += value;
    });
    setState(() {
      _total = sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Update Taxes Amount ( in )',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              GestureDetector(
                onTap: widget.onCancel,
                child: const Icon(Icons.close, size: 18, color: Colors.red),
              ),
            ],
          ),
          const Divider(height: 24),
          ...widget.initialTaxes.entries.map((entry) {
            final key = entry.key;
            final tax = entry.value;
            final ctrl = TextEditingController(
              text: _editedAmounts[key]?.toStringAsFixed(2) ?? '0.00',
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tax.name} [${tax.rate % 1 == 0 ? tax.rate.toInt().toString() : tax.rate.toStringAsFixed(1)}%]',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 32,
                    child: TextFormField(
                      controller: ctrl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) {
                        final amt = double.tryParse(v) ?? 0;
                        _editedAmounts[key] = amt;
                        _calculateTotal();
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Color(0xFF0088FF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tax Amount',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                _total.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSave(_editedAmounts),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Update',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final bool isFocused;
  final bool isHovered;

  const _DashedBorderPainter({
    this.color = const Color(0xFFCBD5E1),
    this.isFocused = false,
    this.isHovered = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      const Radius.circular(6),
    );

    if (isFocused) {
      // Draw glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(rrect, glowPaint);

      // Draw solid border
      final solidPaint = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rrect, solidPaint);
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dash = 4.0;
    const gap = 3.0;

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isFocused != isFocused ||
      oldDelegate.isHovered != isHovered;
}

class _ConfigureTaxPreferencesDialog extends StatefulWidget {
  final String initialTreatment;
  final String initialGstin;
  final Function(String, String, bool) onUpdate;
  final VoidCallback onCancel;

  const _ConfigureTaxPreferencesDialog({
    required this.initialTreatment,
    required this.initialGstin,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  State<_ConfigureTaxPreferencesDialog> createState() =>
      _ConfigureTaxPreferencesDialogState();
}

class _ConfigureTaxPreferencesDialogState
    extends State<_ConfigureTaxPreferencesDialog> {
  late String _selectedTreatment;
  late TextEditingController _gstinCtrl;
  bool _makePermanent = false;

  final List<Map<String, String>> _treatments = [
    {
      'label': 'Registered Business - Regular',
      'desc': 'Business that is registered under GST',
    },
    {
      'label': 'Registered Business - Composition',
      'desc': 'Business that is registered under the Composition Scheme in GST',
    },
    {
      'label': 'Unregistered Business',
      'desc': 'Business that has not been registered under GST',
    },
    {
      'label': 'Consumer',
      'desc':
          'Individual or business that is not registered and consumes goods/services',
    },
    {'label': 'Overseas', 'desc': 'Business located outside India'},
    {
      'label': 'Special Economic Zone (SEZ)',
      'desc': 'Business located in a SEZ unit or developer',
    },
    {
      'label': 'Deemed Export',
      'desc':
          'Business involved in supply of goods to certain notified purposes',
    },
  ];

  bool get _isRegistered {
    return _selectedTreatment == 'Registered Business - Regular' ||
        _selectedTreatment == 'Registered Business - Composition' ||
        _selectedTreatment == 'Special Economic Zone (SEZ)' ||
        _selectedTreatment == 'Deemed Export';
  }

  @override
  void initState() {
    super.initState();
    _selectedTreatment = widget.initialTreatment;
    _gstinCtrl = TextEditingController(text: widget.initialGstin);
  }

  @override
  void dispose() {
    _gstinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: CustomPaint(
            size: const Size(14, 8),
            painter: _TrianglePainter(
              color: Colors.white,
              isUp: true,
              hasBorder: true,
            ),
          ),
        ),
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDDDDD)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Configure Tax Preferences',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancel,
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GST Treatment',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormDropdown<Map<String, String>>(
                      height: 32,
                      value: _treatments.firstWhere(
                        (t) => t['label'] == _selectedTreatment,
                        orElse: () => _treatments[2],
                      ),
                      items: _treatments,
                      showSearch: false,
                      fillColor: Colors.white,
                      displayStringForValue: (v) => v['label']!,
                      itemBuilder: (item, isSelected, isHovered) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: isHovered
                              ? const Color(0xFF3B82F6)
                              : (isSelected
                                    ? const Color(0xFFF3F4F6)
                                    : Colors.transparent),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isHovered
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['desc']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isHovered
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : const Color(0xFF6B7280),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTreatment = val['label']!;
                          });
                        }
                      },
                    ),
                    if (_isRegistered) ...[
                      const SizedBox(height: 20),
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'GSTIN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.redAccent,
                                fontFamily: 'Inter',
                              ),
                            ),
                            TextSpan(
                              text: '*',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: CustomTextField(
                          controller: _gstinCtrl,
                          hintText: 'Enter GSTIN',
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Get Taxpayer details',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Make it permanent?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _makePermanent,
                            onChanged: (val) =>
                                setState(() => _makePermanent = val!),
                            activeColor: AppTheme.primaryBlue,
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Use these settings for all future transactions of this vendor.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          widget.onUpdate(_selectedTreatment, _gstinCtrl.text.trim(), _makePermanent),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF19A05E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontFamily: 'Inter',
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
    );
  }

}

class _GstinPopover extends StatefulWidget {
  final String gstin;
  final Function(String) onUpdate;
  final VoidCallback onCancel;

  const _GstinPopover({
    required this.gstin,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  State<_GstinPopover> createState() => _GstinPopoverState();
}

class _GstinPopoverState extends State<_GstinPopover> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.gstin);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Derive state based on first 2 digits of GSTIN (Standard GSTIN state codes)
    String stateName = "Unknown State";
    if (widget.gstin.length >= 2) {
      final code = widget.gstin.substring(0, 2);
      if (code == "27")
        stateName = "Maharashtra (27)";
      else if (code == "29")
        stateName = "Karnataka (29)";
      else if (code == "33")
        stateName = "Tamil Nadu (33)";
      else if (code == "09")
        stateName = "Uttar Pradesh (09)";
      else if (code == "19")
        stateName = "West Bengal (19)";
      else if (code == "07")
        stateName = "Delhi (07)";
      else if (code == "24")
        stateName = "Gujarat (24)";
      else if (code == "36")
        stateName = "Telangana (36)";
      else if (code == "37")
        stateName = "Andhra Pradesh (37)";
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: CustomPaint(
            size: const Size(14, 8),
            painter: _TrianglePainter(
              color: Colors.white,
              isUp: true,
              hasBorder: true,
            ),
          ),
        ),
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDDDDD)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GSTIN Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancel,
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          stateName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'GSTIN / UIN',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 32,
                      child: CustomTextField(
                        controller: _ctrl,
                        hintText: 'Enter GSTIN',
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => widget.onUpdate(_ctrl.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF19A05E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Inter',
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
    );
  }
}

class _DiscountTypeOverlayItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DiscountTypeOverlayItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DiscountTypeOverlayItem> createState() =>
      _DiscountTypeOverlayItemState();
}

class _DiscountTypeOverlayItemState extends State<_DiscountTypeOverlayItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _isHovered
        ? const Color(0xFF0088FF)
        : widget.isSelected
        ? const Color(0xFFF3F4F6)
        : Colors.transparent;
    final textColor = _isHovered ? Colors.white : const Color(0xFF1F2937);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: 32,
          alignment: Alignment.center,
          color: bg,
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: (_isHovered || widget.isSelected)
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaxCellDropdown extends StatefulWidget {
  final _BillLineItemRow row;
  final bool isUnregistered;
  final bool isSelected;

  const _TaxCellDropdown({
    required this.row,
    required this.isUnregistered,
    required this.isSelected,
  });

  @override
  State<_TaxCellDropdown> createState() => _TaxCellDropdownState();
}

class _TaxCellDropdownState extends State<_TaxCellDropdown> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final showBlueBorder = _isHovered || widget.isSelected;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: showBlueBorder
                ? const Color(0xFF0088FF)
                : Colors.transparent,
            width: showBlueBorder ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.isUnregistered
                    ? 'Non-Taxable'
                    : (widget.row.taxId == null || widget.row.taxName == null)
                    ? 'Select Tax'
                    : (widget.row.taxId == 'non_taxable' ||
                          widget.row.taxId == 'out_of_scope' ||
                          widget.row.taxId == 'non_gst')
                    ? widget.row.taxName!
                    : widget.row.taxName!.contains('[')
                    ? widget.row.taxName!
                    : '${widget.row.taxName} [${widget.row.taxRate}%]',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isUnregistered
                      ? _textMuted
                      : widget.row.taxId == null
                      ? _hintColor
                      : _textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: widget.isUnregistered
                  ? _textMuted.withValues(alpha: 0.5)
                  : _textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverBorderContainer extends StatefulWidget {
  final Widget child;
  const _HoverBorderContainer({required this.child});

  @override
  State<_HoverBorderContainer> createState() => _HoverBorderContainerState();
}

class _HoverBorderContainerState extends State<_HoverBorderContainer> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _hovered ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 1,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _TdsSelectionPopover extends StatefulWidget {
  final bool isTcs;
  final List<Map<String, dynamic>> tdsRates;
  final List<Map<String, dynamic>> tdsSections;
  final List<Map<String, dynamic>> tdsGroups;
  final String? selectedTdsId;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final VoidCallback onManageTds;

  const _TdsSelectionPopover({
    this.isTcs = false,
    required this.tdsRates,
    required this.tdsSections,
    required this.tdsGroups,
    this.selectedTdsId,
    required this.onSelected,
    required this.onManageTds,
  });

  @override
  State<_TdsSelectionPopover> createState() => _TdsSelectionPopoverState();
}

class _TdsSelectionPopoverState extends State<_TdsSelectionPopover> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    if (widget.isTcs) {
      return grouped;
    } else {
      final Set<String> groupedRateIds = {};
      for (var group in widget.tdsGroups) {
        final groupName = group['group_name']?.toString() ?? 'Others';
        final itemsList = group['tds_group_items'] as List<dynamic>? ?? [];
        final List<Map<String, dynamic>> ratesInGroup = [];

        for (var item in itemsList) {
          final rateId = item['tds_rate_id']?.toString();
          if (rateId != null) {
            final match = widget.tdsRates.firstWhere(
              (r) => r['id']?.toString() == rateId,
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              final taxName = match['tax_name']?.toString() ?? '';
              if (_search.isEmpty || taxName.toLowerCase().contains(_search.toLowerCase())) {
                ratesInGroup.add(match);
              }
              groupedRateIds.add(rateId);
            }
          }
        }
        if (ratesInGroup.isNotEmpty) {
          grouped[groupName] = ratesInGroup;
        }
      }

      // Add remaining individual rates that are not in any group
      final List<Map<String, dynamic>> individualRates = [];
      for (var rate in widget.tdsRates) {
        final rateId = rate['id']?.toString();
        if (rateId != null && !groupedRateIds.contains(rateId)) {
          final taxName = rate['tax_name']?.toString() ?? '';
          if (_search.isEmpty || taxName.toLowerCase().contains(_search.toLowerCase())) {
            individualRates.add(rate);
          }
        }
      }
      if (individualRates.isNotEmpty) {
        grouped['Individual Rates'] = individualRates;
      }
    }
    return grouped;
  }

  String _formatBaseRate(dynamic rate) {
    if (rate == null) return '';
    final d = double.tryParse(rate.toString());
    if (d == null) return rate.toString();
    if (d == d.toInt()) return '${d.toInt()}%';
    return '$d%';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    return Container(
      width: 320,
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
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.isTcs ? 'Search TCS Rate' : 'Search TDS Rate',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: widget.isTcs
                    ? widget.tdsRates.where((rate) {
                        final taxName = rate['tax_name']?.toString() ?? '';
                        return _search.isEmpty || taxName.toLowerCase().contains(_search.toLowerCase());
                      }).map((rate) {
                        final isSelected = rate['id'] == widget.selectedTdsId;
                        final baseRateStr = _formatBaseRate(rate['rate']);
                        final displayLabel = "${rate['tax_name']} [$baseRateStr]";
                        return _TdsPopoverListItem(
                          label: displayLabel,
                          indent: 0,
                          isSelected: isSelected,
                          onTap: () => widget.onSelected(rate),
                        );
                      }).toList()
                    : groups.entries.expand((entry) {
                        return [
                          // Group Header
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
                                color: Color(0xFF111827),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Items
                          ...entry.value.map((rate) {
                            final isSelected = rate['id'] == widget.selectedTdsId;
                            final baseRateStr = _formatBaseRate(rate['base_rate']);
                            final displayLabel = "${rate['tax_name']} [$baseRateStr]";
                            return _TdsPopoverListItem(
                              label: displayLabel,
                              indent: 1,
                              isSelected: isSelected,
                              onTap: () => widget.onSelected(rate),
                            );
                          }),
                        ];
                      }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: widget.onManageTds,
            hoverColor: const Color(0xFFF3F4F6),
            child: SizedBox(
              height: 36,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings,
                      size: 14,
                      color: Color(0xFF0088FF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isTcs ? 'Manage TCS' : 'Manage TDS',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0088FF),
                          fontWeight: FontWeight.w500,
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
}

class _TdsPopoverListItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int indent;

  const _TdsPopoverListItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.indent = 0,
  });

  @override
  State<_TdsPopoverListItem> createState() => _TdsPopoverListItemState();
}

class _TdsPopoverListItemState extends State<_TdsPopoverListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? const Color(0xFFF3F4F6)
        : _hover
            ? const Color(0xFF3B82F6)
            : Colors.transparent;
    final text = _hover ? Colors.white : const Color(0xFF111827);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: EdgeInsets.only(
            left: 12.0 + (widget.indent * 16.0),
            right: 12,
            top: 8,
            bottom: 8,
          ),
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


