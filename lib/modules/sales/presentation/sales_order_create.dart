import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:intl/intl.dart' as intl;
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import '../controllers/sales_order_controller.dart';
import '../models/sales_order_model.dart';
import '../models/sales_order_item_model.dart';
import '../models/sales_customer_model.dart';
import '../../items/pricelist/providers/pricelist_provider.dart';
import '../../items/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/sales/presentation/widgets/sales_order_item_row.dart';
import 'widgets/sales_item_quick_edit_dialog.dart';
import 'package:zerpai_erp/modules/sales/presentation/widgets/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'widgets/advanced_customer_search_dialog.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_simple_list_dialog.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'widgets/sales_order_preferences_dialog.dart';
import 'sales_customer_create.dart';

// ─── Colour constants ────────────────────────────────────────────────────────
const _kBorder = Color(0xFFE5E7EB);
const _kLabelGrey = Color(0xFF6B7280);
const _kBodyText = Color(0xFF111827);
const _kBlue = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg = Color(0xFFF9FAFB);
const _kWhite = Colors.white;
const _kDropdownHeight = 32.0;

class SalesOrderCreateScreen extends ConsumerStatefulWidget {
  final SalesOrder? initialOrder;
  final String? initialOrderId;

  /// Deep-link support: pre-select a customer by ID.
  final String? initialCustomerId;

  /// Deep-link support: clone an existing sales order by ID.
  final String? cloneId;

  const SalesOrderCreateScreen({
    super.key,
    this.initialOrder,
    this.initialOrderId,
    this.initialCustomerId,
    this.cloneId,
  });

  @override
  ConsumerState<SalesOrderCreateScreen> createState() =>
      _SalesOrderCreateScreenState();
}

// class SalesOrderItemRow moved to shared file

class _SalesOrderCreateScreenState
    extends ConsumerState<SalesOrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomerId;
  SalesCustomer? _selectedCustomer;

  late final TextEditingController salesOrderNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;
  late final TextEditingController termsCtrl;
  late final TextEditingController shippingCtrl;
  late final TextEditingController adjustmentCtrl;
  final FocusNode _adjustmentLabelFocusNode = FocusNode();

  DateTime salesOrderDate = DateTime.now();
  DateTime? expectedShipmentDate;
  String? paymentTerms;
  String? deliveryMethod;
  String? salesperson;
  String? warehouse;
  String? priceListId;
  String? placeOfSupply;

  List<SalesOrderItemRow> rows = [];

  double subTotal = 0.0;
  double taxTotal = 0.0;
  double total = 0.0;
  double _roundOff = 0.0;
  String _tdsTcsType = 'TDS';
  String? _selectedTdsId;
  List<Map<String, dynamic>> _tdsList = [];

  bool _showBulkUpdateToolbar = false;
  List<Map<String, dynamic>> _paymentTermsList = [];
  List<Map<String, dynamic>> _salespersonList = [];

  final Set<int> _selectedRows = {};
  final _scanCtrl = TextEditingController();
  final _scanFocusNode = FocusNode();
  final _gstTaxLink = LayerLink();
  OverlayEntry? _gstTaxOverlay;
  final _gstinLink = LayerLink();
  OverlayEntry? _gstinOverlay;

  final _bulkActionsLink = LayerLink();
  final _settingsLink = LayerLink();
  OverlayEntry? _settingsOverlay;

  String _saleType = 'Retail'; // Default
  bool _showAdditionalInfo = false;
  bool _showAvailableStock = false;
  bool _showRecentTransactions = false;
  bool _showPriceList = false;
  OverlayEntry? _rowActionsOverlay;
  OverlayEntry? _hsnOverlay;
  OverlayEntry? _itemDetailsSidebarOverlay;
  OverlayEntry? _customerDetailsSidebarOverlay;
  bool _isLoadingCustomerDetails = false;
  SalesOrderItemRow? _activeHsnRow;
  OverlayEntry? _discountOverlay;
  SalesOrderItemRow? _activeDiscountRow;
  final _addRowLink = LayerLink();
  OverlayEntry? _addRowOverlay;
  final _uploadLink = LayerLink();
  OverlayEntry? _uploadOverlay;
  bool _isUploadButtonHovered = false;
  final _salesOrderDateKey = GlobalKey();
  final _expectedShipmentDateKey = GlobalKey();
  bool _isAdjustmentLabelHovered = false;

  bool _isAutoGenerateSO = true;
  String _soPrefix = 'SO-';
  String _soNextNumber = '00028';

  bool _showSearchItemDetails = false;
  String _itemDetailsSearchQuery = '';
  final TextEditingController _itemDetailsSearchCtrl = TextEditingController();

  late TextEditingController adjustmentLabelCtrl;
  bool _isHydratingInitialOrder = false;

  bool get _isEditMode =>
      widget.initialOrder != null ||
      (widget.initialOrderId != null && widget.initialOrderId!.isNotEmpty);

  String? get _editingOrderId {
    final directId = widget.initialOrder?.id;
    if (directId != null && directId.isNotEmpty) {
      return directId;
    }
    final routeId = widget.initialOrderId;
    if (routeId != null && routeId.isNotEmpty) {
      return routeId;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    salesOrderNumberCtrl = TextEditingController(
      text: '$_soPrefix$_soNextNumber',
    );
    salesperson = 'ALTHAF';
    // paymentTerms = 'Net 360'; // Loaded dynamically in _loadPaymentTerms
    warehouse = 'Main Warehouse';

    referenceCtrl = TextEditingController();
    notesCtrl = TextEditingController();
    termsCtrl = TextEditingController();
    shippingCtrl = TextEditingController(text: '0');
    adjustmentCtrl = TextEditingController(text: '0');
    adjustmentLabelCtrl = TextEditingController(text: 'Adjustment');
    _adjustmentLabelFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    shippingCtrl.addListener(_calculateTotals);
    adjustmentCtrl.addListener(_calculateTotals);

    if (widget.initialOrder != null) {
      _hydrateFromInitialOrder(widget.initialOrder!);
    } else if (widget.initialOrderId != null &&
        widget.initialOrderId!.isNotEmpty) {
      _loadInitialOrder(widget.initialOrderId!);
    } else {
      rows.add(_createItemRow());
    }
    _loadPaymentTerms();
    _loadSalespersons();
    _loadTdsList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsControllerProvider.notifier).loadLookupData();
    });
  }

  Future<void> _loadInitialOrder(String orderId) async {
    setState(() => _isHydratingInitialOrder = true);
    try {
      final order = await ref
          .read(salesOrderApiServiceProvider)
          .getSalesOrderById(orderId);
      if (!mounted) return;
      setState(() {
        rows.clear();
        _hydrateFromInitialOrder(order);
        _isHydratingInitialOrder = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (rows.isEmpty) {
          rows.add(_createItemRow());
        }
        _isHydratingInitialOrder = false;
      });
      ZerpaiToast.error(context, 'Failed to load sales order: $e');
    }
  }

  void _hydrateFromInitialOrder(SalesOrder order) {
    _selectedCustomerId = order.customerId;
    _selectedCustomer = order.customer;
    salesOrderNumberCtrl.text = order.saleNumber;
    referenceCtrl.text = order.reference ?? '';
    notesCtrl.text = order.customerNotes ?? '';
    termsCtrl.text = order.termsAndConditions ?? '';
    shippingCtrl.text = order.shippingCharges.toStringAsFixed(2);
    adjustmentCtrl.text = order.adjustment.toStringAsFixed(2);
    salesOrderDate = order.saleDate;
    expectedShipmentDate = order.expectedShipmentDate;
    paymentTerms = order.paymentTerms;
    deliveryMethod = order.deliveryMethod;
    salesperson = order.salesperson;

    final initialItems = order.items ?? const <SalesOrderItem>[];
    if (initialItems.isEmpty) {
      rows.add(_createItemRow());
    } else {
      rows.addAll(initialItems.map(_createItemRowFromOrderItem));
    }

    taxTotal = order.taxTotal;
    subTotal = order.subTotal;
    total = order.total;
  }

  Future<void> _loadTdsList() async {
    try {
      final lookupsService = LookupsApiService();
      final rates = await lookupsService.getTdsRates();
      if (mounted) setState(() => _tdsList = rates);
    } catch (e) {
      debugPrint('Error loading TDS rates: $e');
    }
  }

  Future<void> _loadSalespersons() async {
    try {
      final lookupsService = LookupsApiService();
      final persons = await lookupsService.getSalespersons();
      if (mounted) {
        setState(() {
          _salespersonList = persons;
          // If salesperson is not set, we don't necessarily want to force one
          // but we can set a default if needed.
          if (persons.isNotEmpty && salesperson == null) {
            // Check for ALTHAF as requested in screenshot
            final althaf = persons.firstWhere(
              (p) => p['name']?.toString().toUpperCase() == 'ALTHAF',
              orElse: () => persons.first,
            );
            salesperson =
                althaf['id']?.toString() ?? althaf['name']?.toString();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading salespersons: $e');
    }
  }

  Future<void> _loadPaymentTerms() async {
    try {
      final lookupsService = LookupsApiService();
      final terms = await lookupsService.getPaymentTerms();
      if (mounted) {
        setState(() {
          _paymentTermsList = terms;
          if (terms.isNotEmpty && paymentTerms == null) {
            // Set default to Net 30 if available
            final net30 = terms.firstWhere(
              (t) => t['term_name'] == 'Net 30',
              orElse: () => terms.first,
            );
            paymentTerms = net30['id']?.toString();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading payment terms: $e');
    }
  }

  void _showConfigurePaymentTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => ManagePaymentTermsDialog(
        items: _paymentTermsList,
        selectedId: paymentTerms,
        onSelect: (selected) {
          setState(() {
            paymentTerms = selected['id']?.toString();
          });
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncPaymentTerms(items);
          _loadPaymentTerms(); // Refresh local list
          return updated;
        },
        onDeleteCheck: (item) async {
          final lookupsService = LookupsApiService();
          final usage = await lookupsService.checkLookupUsage(
            'payment-terms',
            item['id'].toString(),
          );
          if (usage['inUse'] == true) {
            return usage['message']?.toString() ?? 'This term is in use.';
          }
          return null;
        },
      ),
    );
  }

  void _showSalesOrderPreferencesDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SalesOrderPreferencesDialog(
        currentPrefix: _soPrefix,
        currentNextNumber: _soNextNumber,
        isAutoGenerate: _isAutoGenerateSO,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _isAutoGenerateSO = result['isAutoGenerate'] ?? true;
        _soPrefix = result['prefix'] ?? '';
        _soNextNumber = result['nextNumber'] ?? '';
        if (_isAutoGenerateSO) {
          salesOrderNumberCtrl.text = '$_soPrefix$_soNextNumber';
        }
      });
    }
  }

  SalesOrderItemRow _createItemRow({
    String quantity = '1',
    String rate = '0',
    String discount = '0',
    String fQty = '0',
    String mrp = '0',
    String description = '',
    String itemId = '',
    Item? item,
    String discountType = '%',
    String? taxId,
    bool isHeader = false,
  }) {
    final row = SalesOrderItemRow(
      quantityCtrl: TextEditingController(text: quantity),
      rateCtrl: TextEditingController(text: rate),
      discountCtrl: TextEditingController(text: discount),
      fQtyCtrl: TextEditingController(text: fQty),
      mrpCtrl: TextEditingController(text: mrp),
      descriptionCtrl: TextEditingController(text: description),
      itemId: itemId,
      item: item,
      discountType: discountType,
      taxId: taxId,
      isHeader: isHeader,
    );

    void onAnyChange() {
      final customers = ref.read(salesCustomersProvider).asData?.value ?? [];
      if (customers.isNotEmpty && _selectedCustomerId != null) {
        final customer = customers.firstWhere(
          (c) => c.id == _selectedCustomerId,
          orElse: () => customers.first,
        );
        final priceLists =
            ref.read(filteredPriceListsProvider).asData?.value ?? [];
        _updateRowRate(row, customer, priceLists);
      }
      _calculateTotals();
    }

    row.quantityCtrl.addListener(onAnyChange);
    row.rateCtrl.addListener(_calculateTotals);
    row.discountCtrl.addListener(_calculateTotals);
    row.fQtyCtrl.addListener(_calculateTotals);
    row.mrpCtrl.addListener(_calculateTotals);

    row.rateFocus.addListener(() {
      if (!row.rateFocus.hasFocus) {
        _handleRateCalculation(row);
      }
    });

    return row;
  }

  SalesOrderItemRow _createItemRowFromOrderItem(SalesOrderItem item) {
    return _createItemRow(
      quantity: item.quantity.toString(),
      rate: item.rate.toString(),
      discount: item.discount.toString(),
      description: item.description ?? '',
      itemId: item.itemId,
      item: item.item,
      discountType: item.discountType == 'value' ? 'Value' : item.discountType,
      taxId: item.taxId,
    );
  }

  void _showManageSalespersonsDialog() {
    showDialog(
      context: context,
      builder: (context) => ManageSimpleListDialog(
        title: 'Manage Salespersons',
        singularLabel: 'Salesperson',
        headerLabel: 'Salesperson Name',
        items: _salespersonList,
        selectedId: salesperson,
        labelKey: 'name',
        onSelect: (item) {
          setState(() {
            salesperson = item['id']?.toString() ?? item['name']?.toString();
          });
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncSalespersons(items);
          setState(() {
            _salespersonList = updated;
          });
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null) return null;
          final lookupsService = LookupsApiService();
          final result = await lookupsService.checkLookupUsage(
            'salespersons',
            item['id'],
          );
          if (result['inUse'] == true) {
            return result['message'] ??
                'This salesperson is in use and cannot be deleted.';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    salesOrderNumberCtrl.dispose();
    referenceCtrl.dispose();
    notesCtrl.dispose();
    termsCtrl.dispose();
    shippingCtrl.dispose();
    adjustmentCtrl.dispose();
    adjustmentLabelCtrl.dispose();
    _adjustmentLabelFocusNode.dispose();
    _scanCtrl.dispose();
    _scanFocusNode.dispose();
    for (var row in rows) {
      row.dispose();
    }
    _itemDetailsSidebarOverlay?.remove();
    _customerDetailsSidebarOverlay?.remove();
    _uploadOverlay?.remove();
    super.dispose();
  }

  void _showCustomerDetailsSidebar(
    SalesCustomer customer, {
    String? currencyLabel,
  }) {
    _customerDetailsSidebarOverlay?.remove();
    _customerDetailsSidebarOverlay = null;

    _customerDetailsSidebarOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () {
              _customerDetailsSidebarOverlay?.remove();
              _customerDetailsSidebarOverlay = null;
            },
            child: Container(color: Colors.black.withValues(alpha: 0.05)),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: _CustomerDetailsSidebar(
                customer: customer,
                currencyLabel: currencyLabel,
                onClose: () {
                  _customerDetailsSidebarOverlay?.remove();
                  _customerDetailsSidebarOverlay = null;
                },
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_customerDetailsSidebarOverlay!);
  }

  String _resolveCurrencyLabel(
    String? currencyId,
    List<CurrencyOption> currencies,
  ) {
    final raw = (currencyId ?? '').trim();
    if (raw.isEmpty) {
      return 'INR - Indian Rupee';
    }

    for (final currency in currencies) {
      if (currency.id == raw) {
        return currency.label.isNotEmpty
            ? currency.label
            : '${currency.code} - ${currency.name}';
      }
    }

    for (final currency in currencies) {
      if (currency.code.toUpperCase() == raw.toUpperCase()) {
        return currency.label.isNotEmpty
            ? currency.label
            : '${currency.code} - ${currency.name}';
      }
    }

    return raw;
  }

  void _showNewCustomerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 200,
        ).copyWith(top: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SalesCustomerCreateScreen(
            showLayout: false,
            onSaveSuccess: (newCustomer) {
              Navigator.of(dialogContext).pop();
              setState(() {
                _selectedCustomer = newCustomer;
                _selectedCustomerId = newCustomer.id;
                // Refresh customer list to include the new one
                // ignore: unused_result
                ref.refresh(salesCustomersProvider);
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDropdownItem(
    SalesCustomer customer,
    bool isSelected,
    bool isHovered,
  ) {
    final customerNumber = (customer.customerNumber ?? '').trim();
    final email = (customer.email ?? '').trim();
    final companyName = (customer.companyName ?? '').trim();
    final firstName = (customer.firstName ?? '').trim();

    final topLine = customerNumber.isEmpty
        ? customer.displayName
        : '${customer.displayName} | $customerNumber';

    final List<String> bottomParts = [];
    if (email.isNotEmpty) bottomParts.add(email);
    if (companyName.isNotEmpty) bottomParts.add(companyName);
    final bottomLine = bottomParts.join(' | ');

    final initialSource = firstName.isNotEmpty
        ? firstName
        : (customer.displayName.isNotEmpty ? customer.displayName : '?');
    final initial = initialSource.substring(0, 1).toUpperCase();

    final backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
    final primaryTextColor = isHovered ? Colors.white : _kBodyText;
    final secondaryTextColor = isHovered
        ? Colors.white.withValues(alpha: 0.85)
        : _kLabelGrey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              textAlign: TextAlign.center,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1,
                color: isHovered ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                if (bottomLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    bottomLine,
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

  Future<void> _openSelectedCustomerDetailsSidebar() async {
    final customerId = _selectedCustomerId;
    if (customerId == null || _isLoadingCustomerDetails) return;

    setState(() => _isLoadingCustomerDetails = true);

    try {
      final api = ref.read(salesOrderApiServiceProvider);
      final customer = await api.getCustomerById(customerId);
      final currencies = await ref.read(currenciesProvider(null).future);
      final currencyLabel = _resolveCurrencyLabel(
        customer.currencyId,
        currencies,
      );
      if (!mounted) return;

      setState(() {
        _selectedCustomer = customer;
      });
      _showCustomerDetailsSidebar(customer, currencyLabel: currencyLabel);
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to load customer details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCustomerDetails = false);
      }
    }
  }

  void _showItemDetailsSidebar(SalesOrderItemRow row) {
    if (_itemDetailsSidebarOverlay != null) {
      _itemDetailsSidebarOverlay!.remove();
      _itemDetailsSidebarOverlay = null;
    }

    _itemDetailsSidebarOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () {
              _itemDetailsSidebarOverlay?.remove();
              _itemDetailsSidebarOverlay = null;
            },
            child: Container(color: Colors.black.withValues(alpha: 0.01)),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: _ItemDetailsSidebar(
                row: row,
                customerName: _selectedCustomer?.displayName ?? 'CUS-1',
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

  void _updateRowRate(
    SalesOrderItemRow row,
    SalesCustomer? customer,
    List<PriceList> priceLists,
  ) {
    if (customer == null || row.item == null) return;

    final priceListId = customer.priceList;
    if (priceListId == null || priceListId == 'Select') {
      return;
    }

    final matchingPls = priceLists.where((p) => p.id == priceListId);
    if (matchingPls.isEmpty) return;
    final pl = matchingPls.first;

    final qty = double.tryParse(row.quantityCtrl.text) ?? 1;
    final newRate = pl.calculatePrice(
      row.itemId,
      (row.item!.sellingPrice ?? 0).toDouble(),
      quantity: qty,
    );

    // Update rate if it changed
    if (row.rateCtrl.text != newRate.toString()) {
      row.rateCtrl.text = newRate.toString();
    }
  }

  void _handleRateCalculation(SalesOrderItemRow row) {
    final text = row.rateCtrl.text.trim();
    if (text.isEmpty) return;

    // Only try to parse if it contains operators
    if (text.contains(RegExp(r'[+\-*/()]'))) {
      final double? result = _evaluateExpression(text);
      if (result != null) {
        row.rateCtrl.text = result % 1 == 0
            ? result.toInt().toString()
            : result.toStringAsFixed(2);
        _calculateTotals();
      }
    }
  }

  double? _evaluateExpression(String input) {
    try {
      return _MathParser(input.replaceAll(' ', '')).parse();
    } catch (_) {
      return null;
    }
  }

  void _calculateTotals() {

    double st = 0;
    for (var row in rows) {
      if (row.itemId.isNotEmpty) {
        final q = double.tryParse(row.quantityCtrl.text) ?? 0;
        final r = double.tryParse(row.rateCtrl.text) ?? 0;
        final d = double.tryParse(row.discountCtrl.text) ?? 0;
        final discAmt = row.discountType == '%' ? (q * r * d / 100) : d;
        final cost = (row.item?.costPrice ?? 0).toDouble();

        row.profit = (r - cost) * q;
        st += (q * r) - discAmt;
      }
    }

    final shipping = double.tryParse(shippingCtrl.text) ?? 0.0;
    final adjustment = double.tryParse(adjustmentCtrl.text) ?? 0.0;

    // Sample tax calculation (2.5% CGST + 2.5% SGST as per screenshot)
    double cgst = (st * 0.025);
    double sgst = (st * 0.025);
    double currentTaxTotal = cgst + sgst;

    double rawTotal = st + currentTaxTotal + shipping + adjustment;
    double roundedTotal = rawTotal.roundToDouble();
    double ro = roundedTotal - rawTotal;

    setState(() {
      subTotal = st;
      taxTotal = currentTaxTotal;
      _roundOff = ro;
      total = roundedTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final itemsState = ref.watch(itemsControllerProvider);
    final priceListsAsync = ref.watch(filteredPriceListsProvider);
    final currenciesAsync = ref.watch(currenciesProvider(null));
    final bodyHorizontalPadding = MediaQuery.sizeOf(context).width < 1000
        ? 16.0
        : 40.0;

    if (_isHydratingInitialOrder) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: DetailContentSkeleton(),
      );
    }

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      footer: _buildFooter(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildHeaderSection(
              customersAsync,
              priceListsAsync,
              currenciesAsync,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: bodyHorizontalPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: _buildItemsTable(
                    itemsState.items,
                    customersAsync,
                    priceListsAsync,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: bodyHorizontalPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: _buildSummaryAndNotes(itemsState.items),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _footerBanner(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(LucideIcons.shoppingCart, size: 24, color: _kBodyText),
          const SizedBox(width: 12),
          Text(
            _isEditMode ? 'Edit Sales Order' : 'New Sales Order',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _kBodyText,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              LucideIcons.settings,
              color: Color(0xFF3B82F6),
              size: 18,
            ),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: _kBorder),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(LucideIcons.x, color: Color(0xFF6B7280), size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/sales/orders');
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    AsyncValue<List<SalesCustomer>> customersAsync,
    AsyncValue<List<PriceList>> priceListsAsync,
    AsyncValue<List<CurrencyOption>> currenciesAsync,
  ) {
    final warehouseList = ref.watch(warehousesProvider).value ?? <Warehouse>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Section: Customer Name & Details
        Container(
          decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              customersAsync.when(
                data: (customers) {
                  final SalesCustomer? selectedCustomerFromList =
                      _selectedCustomerId == null
                      ? _selectedCustomer
                      : customers
                                .where((c) => c.id == _selectedCustomerId)
                                .firstOrNull ??
                            _selectedCustomer;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SharedFieldLayout(
                        label: 'Customer Name',
                        required: true,
                        labelWidth: 180,
                        maxWidth: null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Search dropdown
                            SizedBox(
                              width: 550,
                              child: FormDropdown<SalesCustomer>(
                                value: selectedCustomerFromList,
                                height: _kDropdownHeight,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                                showRightBorder: false,
                                items: customers,
                                hint: 'Select or add a customer',
                                displayStringForValue: (c) => c.displayName,
                                itemHeight: 56,
                                showSettings: true,
                                settingsLabel: 'New Customer',
                                settingsIcon: LucideIcons.plus,
                                onSettingsTap: _showNewCustomerDialog,
                                itemBuilder:
                                    (customer, isSelected, isHovered) =>
                                        _buildCustomerDropdownItem(
                                          customer,
                                          isSelected,
                                          isHovered,
                                        ),
                                onChanged: (val) {
                                  if (val == null) return;
                                  setState(() {
                                    _customerDetailsSidebarOverlay?.remove();
                                    _customerDetailsSidebarOverlay = null;
                                    _selectedCustomer = val;
                                    _selectedCustomerId = val.id;
                                    final priceLists =
                                        priceListsAsync.asData?.value ?? [];

                                    for (var row in rows) {
                                      if (row.itemId.isNotEmpty &&
                                          row.item != null) {
                                        _updateRowRate(row, val, priceLists);
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                            Container(
                              height: 32,
                              width: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981), // Emerald-500
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  LucideIcons.search,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () => customersAsync.whenData(
                                  (customers) =>
                                      _showAdvancedCustomerSearch(customers),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Currency Pill
                            if (_selectedCustomer != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
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
                                      currenciesAsync.when(
                                        data: (currencies) =>
                                            _resolveCurrencyLabel(
                                              _selectedCustomer?.currencyId,
                                              currencies,
                                            ),
                                        loading: () => 'Loading currency...',
                                        error: (_, __) =>
                                            'Currency unavailable',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            // Customer Details Button
                            if (_selectedCustomer != null)
                              Material(
                                color: const Color(0xFF475569), // Slate-600
                                borderRadius: BorderRadius.circular(6),
                                child: InkWell(
                                  onTap: _isLoadingCustomerDetails
                                      ? null
                                      : _openSelectedCustomerDetailsSidebar,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isLoadingCustomerDetails) ...[
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Text(
                                          "${_selectedCustomer?.displayName}'s Details",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          LucideIcons.chevronRight,
                                          size: 16,
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
                      if (_selectedCustomer != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 204, bottom: 20),
                          child: _buildCustomerAddressSection(
                            _selectedCustomer!,
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const SharedFieldLayout(
                  label: 'Customer Name',
                  labelWidth: 180,
                  child: Skeleton(height: 32, width: 420),
                ),
                error: (err, _) => SharedFieldLayout(
                  label: 'Customer Name',
                  labelWidth: 180,
                  child: Text('Error: $err'),
                ),
              ),

              if (_selectedCustomer != null) ...[
                const SizedBox(height: 16),
                // Place of Supply
                SharedFieldLayout(
                  label: 'Place of Supply',
                  required: true,
                  labelWidth: 180,
                  maxWidth: 450,
                  child: FormDropdown<String>(
                    height: _kDropdownHeight,
                    value: placeOfSupply ?? _selectedCustomer?.placeOfSupply,
                    items: const [
                      '[KL] - Kerala',
                      '[TN] - Tamil Nadu',
                      '[KA] - Karnataka',
                    ], // Simplified options
                    itemBuilder: (item, isSelected, isHovered) =>
                        _dropdownItemBuilder(item, isSelected, isHovered),
                    onChanged: (v) => setState(() => placeOfSupply = v),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Sales Order#
              SharedFieldLayout(
                label: 'Sales Order#',
                required: true,
                labelWidth: 180,
                maxWidth: 600,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: FormDropdown<String>(
                        value: 'Default Transaction Series',
                        height: _kDropdownHeight,
                        items: const ['Default Transaction Series'],
                        itemBuilder: (item, isSelected, isHovered) =>
                            _dropdownItemBuilder(item, isSelected, isHovered),
                        onChanged: (v) {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: salesOrderNumberCtrl,
                        height: 32,
                        hintText: 'SO-00000',
                        suffixWidget: ZTooltip(
                          message:
                              'Click here to enable or disable auto-generation of Sales Order numbers.',
                          child: InkWell(
                            onTap: _showSalesOrderPreferencesDialog,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 2),
                              child: Icon(
                                LucideIcons.settings,
                                color: Color(0xFF3B82F6),
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Reference#
              SharedFieldLayout(
                label: 'Reference#',
                labelWidth: 180,
                maxWidth: 600,
                child: CustomTextField(controller: referenceCtrl, height: 32),
              ),

              // Sales Order Date
              SharedFieldLayout(
                label: 'Sales Order Date',
                required: true,
                labelWidth: 180,
                maxWidth: 600,
                child: CustomTextField(
                  key: _salesOrderDateKey,
                  controller: TextEditingController(
                    text: intl.DateFormat('dd-MM-yyyy').format(salesOrderDate),
                  ),
                  height: 32,
                  readOnly: true,
                  onTap: () async {
                    final picked = await ZerpaiDatePicker.show(
                      context,
                      initialDate: salesOrderDate,
                      targetKey: _salesOrderDateKey,
                    );
                    if (picked != null) {
                      setState(() => salesOrderDate = picked);
                    }
                  },
                  suffixWidget: const Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: _kLabelGrey,
                  ),
                ),
              ),

              // Expected Shipment Date
              SharedFieldLayout(
                label: 'Expected Shipment Date',
                labelWidth: 180,
                maxWidth: 600,
                child: CustomTextField(
                  key: _expectedShipmentDateKey,
                  controller: TextEditingController(
                    text: expectedShipmentDate == null
                        ? ''
                        : intl.DateFormat(
                            'dd-MM-yyyy',
                          ).format(expectedShipmentDate!),
                  ),
                  height: 32,
                  readOnly: true,
                  onTap: () async {
                    final picked = await ZerpaiDatePicker.show(
                      context,
                      initialDate: expectedShipmentDate ?? DateTime.now(),
                      targetKey: _expectedShipmentDateKey,
                    );
                    if (picked != null) {
                      setState(() => expectedShipmentDate = picked);
                    }
                  },
                  suffixWidget: const Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: _kLabelGrey,
                  ),
                ),
              ),

              // Payment Terms
              SharedFieldLayout(
                label: 'Payment Terms',
                labelWidth: 180,
                maxWidth: 600,
                child: FormDropdown<String>(
                  value: paymentTerms,
                  height: _kDropdownHeight,
                  items: _paymentTermsList
                      .map((t) => t['id'] as String)
                      .toList(),
                  showSettings: true,
                  settingsLabel: 'Configure Terms',
                  onSettingsTap: _showConfigurePaymentTermsDialog,
                  displayStringForValue: (id) {
                    final term = _paymentTermsList.firstWhere(
                      (t) => t['id'] == id,
                      orElse: () => {'term_name': id},
                    );
                    return term['term_name'] ?? id;
                  },
                  itemBuilder: (id, isSelected, isHovered) {
                    final term = _paymentTermsList.firstWhere(
                      (t) => t['id'] == id,
                      orElse: () => {'term_name': id},
                    );
                    return _dropdownItemBuilder(
                      term['term_name'] ?? id,
                      isSelected,
                      isHovered,
                    );
                  },
                  onChanged: (v) => setState(() => paymentTerms = v),
                ),
              ),

              const SizedBox(height: 12),

              const SizedBox(height: 24),

              // Delivery Method
              SharedFieldLayout(
                label: 'Delivery Method',
                labelWidth: 180,
                maxWidth: 600,
                child: FormDropdown<String>(
                  value: deliveryMethod,
                  height: _kDropdownHeight,
                  hint: 'Select a delivery method or type to add',
                  items: const ['None', 'FedEx', 'UPS', 'DHL', 'Post'],
                  itemBuilder: (item, isSelected, isHovered) =>
                      _dropdownItemBuilder(item, isSelected, isHovered),
                  onChanged: (v) => setState(() => deliveryMethod = v),
                ),
              ),

              // Salesperson
              SharedFieldLayout(
                label: 'Salesperson',
                labelWidth: 180,
                maxWidth: 600,
                child: FormDropdown<String>(
                  value: salesperson,
                  height: _kDropdownHeight,
                  allowClear: true,
                  showSettings: true,
                  settingsLabel: 'Manage Salespersons',
                  onSettingsTap: _showManageSalespersonsDialog,
                  items: _salespersonList
                      .map(
                        (p) =>
                            p['id']?.toString() ?? p['name']?.toString() ?? '',
                      )
                      .toList(),
                  displayStringForValue: (val) {
                    final person = _salespersonList.firstWhere(
                      (p) =>
                          (p['id']?.toString() ?? p['name']?.toString()) == val,
                      orElse: () => {'name': val},
                    );
                    return person['name']?.toString() ?? val;
                  },
                  itemBuilder: (id, isSelected, isHovered) {
                    final sp = _salespersonList.firstWhere(
                      (s) => s['id'] == id,
                      orElse: () => {'salesperson_name': id},
                    );
                    return _dropdownItemBuilder(
                      sp['salesperson_name'] ?? id,
                      isSelected,
                      isHovered,
                    );
                  },
                  onChanged: (v) => setState(() => salesperson = v),
                ),
              ),

              const SizedBox(height: 16),

              // Warehouse and Price List Row
              SharedFieldLayout(
                label: 'Warehouse',
                labelWidth: 180,
                child: Row(
                  children: [
                    SizedBox(
                      width: 320,
                      child: FormDropdown<Warehouse>(
                        value: warehouseList.isEmpty
                            ? null
                            : warehouseList.firstWhere(
                                (w) => w.name == warehouse,
                                orElse: () => warehouseList.first,
                              ),
                        height: _kDropdownHeight,
                        items: warehouseList,
                        hint: 'Select Warehouse',
                        displayStringForValue: (w) => w.name,
                        searchStringForValue: (w) => w.name,
                        showSearch: warehouseList.length > 5,
                        itemBuilder: (w, isSelected, isHovered) =>
                            _dropdownItemBuilder(w.name, isSelected, isHovered),
                        onChanged: (w) => setState(() => warehouse = w?.name),
                      ),
                    ),
                    const SizedBox(width: 48),
                    const SizedBox(
                      width: 120,
                      child: Text(
                        'Price List',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kLabelGrey,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: priceListsAsync.when(
                        data: (priceLists) => FormDropdown<String>(
                          value: priceListId,
                          height: _kDropdownHeight,
                          items: priceLists.map((p) => p.id).toList(),
                          displayStringForValue: (id) =>
                              priceLists.firstWhere((p) => p.id == id).name,
                          hint: 'Select Price List',
                          itemBuilder: (id, isSelected, isHovered) =>
                              _dropdownItemBuilder(
                                priceLists.firstWhere((p) => p.id == id).name,
                                isSelected,
                                isHovered,
                              ),
                          onChanged: (v) {
                            setState(() {
                              priceListId = v;
                              final customers =
                                  customersAsync.asData?.value ?? [];
                              final customer = customers.firstWhere(
                                (c) => c.id == _selectedCustomerId,
                                orElse: () => _selectedCustomer!,
                              );
                              for (var row in rows) {
                                if (row.itemId.isNotEmpty && row.item != null) {
                                  _updateRowRate(row, customer, priceLists);
                                }
                              }
                            });
                          },
                        ),
                        loading: () => const Skeleton(height: 32, width: 320),
                        error: (_, __) =>
                            const Text('Error loading price lists'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(
    List<Item>? products,
    AsyncValue<List<SalesCustomer>> customersAsync,
    AsyncValue<List<PriceList>> priceListsAsync,
  ) {
    if (products == null) return const SizedBox();

    final itemsState = ref.watch(itemsControllerProvider);
    // Only GST groups (GST0, GST5, GST12… — intra-state combined rates)
    final taxRates = itemsState.taxGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table Title Row
        if (!_showBulkUpdateToolbar)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Item Table',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kBodyText,
                        ),
                      ),
                      const Spacer(),
                      CompositedTransformTarget(
                        link: _bulkActionsLink,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showBulkUpdateToolbar = true;
                            });
                          },
                          icon: const Icon(
                            LucideIcons.checkCircle,
                            size: 16,
                            color: _kBlue,
                          ),
                          label: const Text(
                            'Bulk Actions',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CompositedTransformTarget(
                        link: _settingsLink,
                        child: InkWell(
                          onTap: _toggleSettingsOverlay,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _kBorder),
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
              const SizedBox(width: 60),
            ],
          )
        else
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
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      _buildBulkButton(
                        'Update Reporting Tags',
                        onTap: () {}, // Placeholder
                      ),
                      const SizedBox(width: 10),
                      _buildBulkButton(
                        'Update Account',
                        onTap: () {}, // Placeholder
                      ),
                      const SizedBox(width: 10),
                      _buildBulkButton(
                        'Update Discount',
                        onTap: () {}, // Placeholder
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.blue.shade600,
                        onPressed: () {
                          setState(() {
                            _showBulkUpdateToolbar = false;
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

        // Column headers
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: _kWhite,
                  border: Border(
                    left: BorderSide(color: _kBorder),
                    right: BorderSide(color: _kBorder),
                    bottom: BorderSide(color: _kBorder),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      if (_showBulkUpdateToolbar)
                        SizedBox(
                          width: 40,
                          child: Center(
                            child: Transform.scale(
                              scale: 0.85,
                              child: Checkbox(
                                value:
                                    _selectedRows.length == rows.length &&
                                    rows.isNotEmpty,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      for (int i = 0; i < rows.length; i++) {
                                        _selectedRows.add(i);
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
                                activeColor: _kBlue,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 40), // Space for drag handle
                      Expanded(
                        flex: 14,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: _buildHeaderSearchField(
                            label: 'ITEMS DETAILS',
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
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: _TH('QUANTITY', right: true),
                        ),
                      ),
                      if (_saleType == 'Business') ...[
                        _vLine(),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: _TH('F.QTY', right: true),
                          ),
                        ),
                      ],
                      _vLine(),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const _TH('RATE'),
                              const SizedBox(width: 4),
                              ZTooltip(
                                message:
                                    'You can perform basic calculations directly in this field using parentheses ( ) and arithmetic operators: + - / *',
                                child: SvgPicture.string(
                                  '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2"/><line x1="8" x2="16" y1="6" y2="6"/><line x1="16" x2="16" y1="14" y2="18"/><path d="M16 10h.01"/><path d="M12 10h.01"/><path d="M8 10h.01"/><path d="M12 14h.01"/><path d="M8 14h.01"/><path d="M12 18h.01"/><path d="M8 18h.01"/></svg>',
                                  width: 14,
                                  height: 14,
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
                      _vLine(),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: _TH('DISCOUNT', right: true),
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
                          child: _TH(
                            'TAX',
                            tooltip:
                                'Applicable tax for the items. You can select a tax rate from the list.',
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
                          child: _TH('AMOUNT', right: true),
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

        // Rows
        Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = rows.removeAt(oldIndex);
                rows.insert(newIndex, item);
              });
            },
            itemBuilder: (ctx, idx) {
              final row = rows[idx];
              // Apply search filter
              if (_itemDetailsSearchQuery.isNotEmpty) {
                final itemName = (row.item?.productName ?? row.descriptionCtrl.text).toLowerCase();
                if (!itemName.contains(_itemDetailsSearchQuery.toLowerCase())) {
                  return SizedBox(key: ValueKey(row));
                }
              }
              
              return _buildItemRow(
                idx,
                products,
                customersAsync,
                priceListsAsync,
                taxRates,
                key: ValueKey(row),
              );
            },
          ),
        ),

        // Table Bottom Border
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  border: Border(
                    left: BorderSide(color: _kBorder),
                    right: BorderSide(color: _kBorder),
                    bottom: BorderSide(color: _kBorder),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),
        const SizedBox(height: 16),
        // ── Add Row Buttons (Below Table) ──
        Row(
          children: [
            _buildAddRowButton(),
            const SizedBox(width: 12),
            _buildBulkAddButton(products),
          ],
        ),
      ],
    );
  }

  Widget _buildItemRow(
    int idx,
    List<Item> products,
    AsyncValue<List<SalesCustomer>> customersAsync,
    AsyncValue<List<PriceList>> priceListsAsync,
    List<TaxRate> taxRates, {
    Key? key,
  }) {
    final row = rows[idx];
    final q = double.tryParse(row.quantityCtrl.text) ?? 0;
    final r = double.tryParse(row.rateCtrl.text) ?? 0;
    final d = double.tryParse(row.discountCtrl.text) ?? 0;

    double rowBase = q * r;
    double rowDiscounted = rowBase;
    if (row.discountType == '%') {
      rowDiscounted = rowBase * (1 - d / 100);
    } else {
      rowDiscounted = rowBase - d;
    }

    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: _kWhite,
              border: Border(
                left: BorderSide(color: _kBorder),
                right: BorderSide(color: _kBorder),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showBulkUpdateToolbar)
                    SizedBox(
                      width: 40,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Transform.scale(
                          scale: 0.85,
                          child: Checkbox(
                            value: _selectedRows.contains(idx),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedRows.add(idx);
                                } else {
                                  _selectedRows.remove(idx);
                                }
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            activeColor: _kBlue,
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
                            index: idx,
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
                  if (row.isHeader)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: TextField(
                          controller: row.descriptionCtrl,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Type a header...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // ITEM DETAILS
                    Expanded(
                      flex: 14,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            row.itemId.isEmpty
                                ? Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.image,
                                          size: 20,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FormDropdown<String>(
                                          value: null,
                                          height: 32,
                                          hint:
                                              'Type or click to select an item.',
                                          hideBorderDefault: true,
                                          items: products
                                              .where((p) => !rows.any((r) => r.itemId == p.id))
                                              .map((p) => p.id!)
                                              .toList(),
                                          displayStringForValue: (id) =>
                                              products
                                                  .firstWhere((p) => p.id == id)
                                                  .productName,
                                          itemBuilder:
                                              (id, isSelected, isHovered) =>
                                                  _dropdownItemBuilder(
                                                    products
                                                        .firstWhere(
                                                          (p) => p.id == id,
                                                        )
                                                        .productName,
                                                    isSelected,
                                                    isHovered,
                                                  ),
                                          onChanged: (v) {
                                            if (v == null) return;
                                            final p = products.firstWhere(
                                              (e) => e.id == v,
                                            );
                                            setState(() {
                                              row.itemId = v;
                                              row.item = p;
                                              final r = p.sellingPrice ?? 0;
                                              row.rateCtrl.text = r == 0 ? '' : r.toString();
                                              if (row.mrpCtrl.text == '0' ||
                                                  row.mrpCtrl.text.isEmpty) {
                                                row.mrpCtrl.text = (p.mrp ?? 0)
                                                    .toString();
                                              }
                                              row.taxId ??=
                                                  p.intraStateTaxId ??
                                                  p.interStateTaxId;
                                            });
                                            _calculateTotals();
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                : _buildSelectedItemView(row, products),
                            if (_showAdditionalInfo) _buildReportingTags(row),
                          ],
                        ),
                      ),
                    ),
                    _vLine(),
                    // QUANTITY
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CustomTextField(
                              controller: row.quantityCtrl,
                              height: 32,
                              hideBorderDefault: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              contentCase: ContentCase.none,
                              textAlign: TextAlign.right,
                              onTap: () =>
                                  row.quantityCtrl.selection = TextSelection(
                                    baseOffset: 0,
                                    extentOffset: row.quantityCtrl.text.length,
                                  ),
                              onChanged: (_) => _calculateTotals(),
                            ),
                            if (_showAvailableStock &&
                                row.itemId.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Available for Sale:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF4B5563),
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const Text(
                                '-10 pcs',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(
                                    LucideIcons.home,
                                    size: 11,
                                    color: Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      warehouse ?? 'ZABNIX PRIVATE LIMITED',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_saleType == 'Business') ...[
                      _vLine(),
                      // F.QTY
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: CustomTextField(
                            controller: row.fQtyCtrl,
                            height: 32,
                            hideBorderDefault: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            contentCase: ContentCase.none,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                    _vLine(),
                    // RATE
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CustomTextField(
                              controller: row.rateCtrl,
                              focusNode: row.rateFocus,
                              height: 32,
                              hintText: '0',
                              hideBorderDefault: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              contentCase: ContentCase.none,
                              textAlign: TextAlign.right,
                              onTap: () =>
                                  row.rateCtrl.selection = TextSelection(
                                    baseOffset: 0,
                                    extentOffset: row.rateCtrl.text.length,
                                  ),
                              onChanged: (_) => _calculateTotals(),
                              onSubmitted: (_) => _handleRateCalculation(row),
                            ),
                            if (row.itemId.isNotEmpty) ...[
                              if (_showPriceList) ...[
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 32,
                                  child: FormDropdown<String>(
                                    value: null,
                                    height: 32,
                                    hint: 'Apply Price List',
                                    items: const [],
                                    itemBuilder:
                                        (item, isSelected, isHovered) =>
                                            _dropdownItemBuilder(
                                              item,
                                              isSelected,
                                              isHovered,
                                            ),
                                    onChanged: (v) {},
                                  ),
                                ),
                              ],
                              if (_showRecentTransactions) ...[
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () {
                                    _showItemDetailsSidebar(row);
                                  },
                                  child: const Text(
                                    'Recent Transactions',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    _vLine(),
                    // DISCOUNT
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: CustomTextField(
                          controller: row.discountCtrl,
                          height: 32,
                          hideBorderDefault: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          contentCase: ContentCase.none,
                          textAlign: TextAlign.right,
                          padding: const EdgeInsets.only(left: 12, right: 0),
                          suffixSeparator: true,
                          suffixWidget: _buildDiscountTypeSelector(row),
                          onTap: () =>
                              row.discountCtrl.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: row.discountCtrl.text.length,
                              ),
                          onChanged: (_) => _calculateTotals(),
                        ),
                      ),
                    ),
                    _vLine(),
                    // TAX
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: FormDropdown<String>(
                          value: row.taxId,
                          height: 32,
                          hideBorderDefault: true,
                          hint: 'Tax',
                          items: taxRates.map((t) => t.id).toList(),
                          displayStringForValue: (id) =>
                              taxRates
                                  .where((t) => t.id == id)
                                  .firstOrNull
                                  ?.taxName ??
                              'Select Tax',
                          itemBuilder: (id, isSelected, isHovered) =>
                              _dropdownItemBuilder(
                                taxRates
                                        .where((t) => t.id == id)
                                        .firstOrNull
                                        ?.taxName ??
                                    'Select Tax',
                                isSelected,
                                isHovered,
                              ),
                          onChanged: (v) {
                            setState(() => row.taxId = v);
                            _calculateTotals();
                          },
                        ),
                      ),
                    ),
                    _vLine(),
                    // AMOUNT
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '₹${rowDiscounted.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kBodyText,
                                ),
                              ),
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
        ),
        // ACTIONS (Outside border)
        Container(
          width: 60,
          padding: const EdgeInsets.only(left: 12, top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CompositedTransformTarget(
                link: row.moreActionsLink,
                child: InkWell(
                  onTap: () => _toggleRowActionsOverlay(row),
                  child: const Icon(
                    LucideIcons.moreVertical,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (rows.length > 1)
                InkWell(
                  onTap: () {
                    setState(() {
                      rows.removeAt(idx);
                      _calculateTotals();
                    });
                  },
                  child: const Icon(LucideIcons.x, size: 18, color: Colors.red),
                ),
            ],
          ),
        ),
      ],
    ),
    if (idx < rows.length - 1)
      Row(
        children: [
          const Expanded(child: Divider(height: 1, color: _kBorder)),
          const SizedBox(width: 60),
        ],
      ),
  ],
);
}

  Widget _buildSelectedItemView(SalesOrderItemRow row, List<Item> products) {
    final item = row.item;
    if (item == null) return const SizedBox();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        if (_showAdditionalInfo) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(
              LucideIcons.image,
              size: 24,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kBodyText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                            builder: (ctx) => SalesItemQuickEditDialog(
                              item: item,
                              onUpdated: (newItem) {
                                setState(() {
                                  row.item = newItem;
                                  row.rateCtrl.text =
                                      newItem.sellingPrice?.toString() ?? '0';
                                  row.mrpCtrl.text =
                                      newItem.mrp?.toString() ?? '0';
                                });
                                _calculateTotals();
                              },
                            ),
                          );
                        }
                      },
                      itemBuilder: (ctx) => [
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
                      ],
                      child: _buildIconAction(
                        LucideIcons.moreHorizontal,
                        size: 10,
                        onTap: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildIconAction(
                    LucideIcons.x,
                    size: 10,
                    onTap: () {
                      setState(() {
                        row.itemId = '';
                        row.item = null;
                        row.rateCtrl.text = '0';
                        row.mrpCtrl.text = '0';
                        row.fQtyCtrl.text = '0';
                      });
                      _calculateTotals();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDescriptionField(row.descriptionCtrl),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.type == 'goods' ? _kBlue : _kGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      item.type == 'goods' ? 'GOODS' : 'SERVICE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.type == 'goods' ? 'HSN ' : 'SAC ',
                    style: const TextStyle(fontSize: 12, color: _kBodyText),
                  ),
                  CompositedTransformTarget(
                    link: row.hsnLink,
                    child: Row(
                      children: [
                        Text(
                          (item.type == 'goods'
                                  ? item.hsnCode
                                  : item.hsnCode) ??
                              '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _toggleHsnOverlay(row),
                          child: const Icon(
                            LucideIcons.pencil,
                            size: 12,
                            color: _kBlue,
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
    );
  }

  OverlayEntry? _reportingTagsOverlay;
  // ignore: unused_field
  final LayerLink _reportingTagsLink = LayerLink();

  void _toggleReportingTagsOverlay(SalesOrderItemRow row) {
    if (_reportingTagsOverlay != null) {
      _reportingTagsOverlay?.remove();
      _reportingTagsOverlay = null;
      setState(() {});
      return;
    }

    _reportingTagsOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _reportingTagsOverlay?.remove();
                _reportingTagsOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            width: 500,
            child: CompositedTransformFollower(
              link: row.reportingTagsLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 30),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: const Text(
                          'Reporting Tags',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ADGF',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF374151),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormDropdown<String>(
                                        items: const ['None'],
                                        value: 'None',
                                        onChanged: (_) {},
                                        hint: 'None',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'shedule',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF374151),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormDropdown<String>(
                                        items: const ['None'],
                                        value: 'None',
                                        onChanged: (_) {},
                                        hint: 'None',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'demo adavced reporting tag',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF374151),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormDropdown<String>(
                                        items: const ['None'],
                                        value: 'None',
                                        onChanged: (_) {},
                                        hint: 'None',
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _reportingTagsOverlay?.remove();
                                _reportingTagsOverlay = null;
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
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
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                _reportingTagsOverlay?.remove();
                                _reportingTagsOverlay = null;
                                setState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                                foregroundColor: const Color(0xFF374151),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                backgroundColor: const Color(0xFFF9FAFB),
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
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_reportingTagsOverlay!);
    setState(() {});
  }

  Widget _buildReportingTags(SalesOrderItemRow row) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            CompositedTransformTarget(
              link: row.reportingTagsLink,
              child: InkWell(
                onTap: () => _toggleReportingTagsOverlay(row),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#22C55E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13.172 2a2 2 0 0 1 1.414.586l6.71 6.71a2.4 2.4 0 0 1 0 3.408l-4.592 4.592a2.4 2.4 0 0 1-3.408 0l-6.71-6.71A2 2 0 0 1 6 9.172V3a1 1 0 0 1 1-1z"/><path d="M2 7v6.172a2 2 0 0 0 .586 1.414l6.71 6.71a2.4 2.4 0 0 0 3.191.193"/><circle cx="10.5" cy="6.5" r=".5" fill="#22C55E"/></svg>',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Reporting Tags',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: Color(0xFF9CA3AF),
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

  Widget _buildBulkButton(String label, {required VoidCallback onTap}) {
    return Container(
      height: 28,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: Colors.white,
          foregroundColor: _kBlue,
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: content,
    );
  }

  Widget _buildDescriptionField(TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLines: 2,
      style: const TextStyle(fontSize: 13, color: _kBodyText),
      decoration: InputDecoration(
        hintText: 'Add a description to your item',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.all(12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSummaryAndNotes(List<Item>? products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Notes
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 140), // Space to align notes lower
                  const Text(
                    'Customer Notes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _kBodyText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: CustomTextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      height: 80,
                      hintText:
                          'Enter any notes to be displayed in your transaction',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Column: Totals
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 392),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Sub Total', subTotal),
                        const SizedBox(height: 16),
                        _summaryInputRow(
                          'Shipping Charges',
                          shippingCtrl,
                          tooltip: 'Amount spent on shipping the goods.',
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 16),
                        if (_tdsTcsType == 'TDS') ...[
                          _summaryRadioRow(),
                          const SizedBox(height: 16),
                          _summaryInputRow(
                            'Adjustment',
                            adjustmentCtrl,
                            labelCtrl: adjustmentLabelCtrl,
                            isAdjustment: true,
                            tooltip:
                                'Add any other +ve or -ve charges that need to be applied to adjust the total amount of the transaction Eg. +10 or -10.',
                          ),
                        ] else ...[
                          _summaryInputRow(
                            'Adjustment',
                            adjustmentCtrl,
                            labelCtrl: adjustmentLabelCtrl,
                            isAdjustment: true,
                            tooltip:
                                'Add any other +ve or -ve charges that need to be applied to adjust the total amount of the transaction Eg. +10 or -10.',
                          ),
                          const SizedBox(height: 16),
                          _summaryRadioRow(),
                        ],
                        const SizedBox(height: 16),
                        _summaryRow('Round Off', _roundOff),
                        const SizedBox(height: 24),
                        _summaryRow(
                          'Total ( ₹ )',
                          total,
                          isBold: true,
                          fontSize: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _footerBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        border: Border(
          top: BorderSide(color: Color(0xFFDBEAFE)),
          bottom: BorderSide(color: Color(0xFFDBEAFE)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: _termsAndFileRow(),
        ),
      ),
    );
  }

  Widget _termsAndFileRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1100;

        final termsSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _kBodyText,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: termsCtrl,
              maxLines: 4,
              height: 120,
              hintText:
                  'Enter the terms and conditions of your business to be displayed in your transaction',
            ),
          ],
        );

        final uploadSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attach File(s) to Sales Order',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _kBodyText,
              ),
            ),
            const SizedBox(height: 12),
            _buildFileUploadSection(),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              termsSection,
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFDBEAFE)),
              const SizedBox(height: 20),
              uploadSection,
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: termsSection),
              const SizedBox(width: 24),
              Container(
                width: 1,
                color: const Color(0xFFDBEAFE),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: uploadSection),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddRowButton() {
    return CompositedTransformTarget(
      link: _addRowLink,
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
            InkWell(
              onTap: () {
                setState(() {
                  rows.add(_createItemRow());
                });
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
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
            InkWell(
              onTap: _toggleAddRowOverlay,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
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
    );
  }

  void _toggleAddRowOverlay() {
    if (_addRowOverlay != null) {
      _addRowOverlay?.remove();
      _addRowOverlay = null;
      setState(() {});
      return;
    }

    _addRowOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _addRowOverlay?.remove();
                _addRowOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _addRowLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 44), // Drops below the button
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 140, // Enough width for the text
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: InkWell(
                  onTap: () {
                    // Implement Add New Header logic
                    setState(() {
                      rows.add(
                        _createItemRow(
                          quantity: '0',
                          rate: '0',
                          discount: '0',
                          isHeader: true,
                        ),
                      );
                    });
                    _addRowOverlay?.remove();
                    _addRowOverlay = null;
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6), // Blue background
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Add New Header',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
    Overlay.of(context).insert(_addRowOverlay!);
    setState(() {});
  }

  Widget _buildBulkAddButton(List<Item>? products) {
    return InkWell(
      onTap: () {
        if (products == null) return;
        showDialog(
          context: context,
          builder: (context) => BulkItemsDialog(
            products: products,
            onItemsSelected: (selectedItems) {
              setState(() {
                // Remove empty rows before adding bulk items
                rows.removeWhere((r) => r.itemId.isEmpty && !r.isHeader);

                selectedItems.forEach((item, quantity) {
                  rows.add(
                    _createItemRow(
                      quantity: quantity.toString(),
                      rate: (item.sellingPrice ?? 0) == 0
                          ? ''
                          : (item.sellingPrice ?? 0).toString(),
                      discount: '0',
                      itemId: item.id ?? '',
                      item: item,
                    ),
                  );
                });
                _calculateTotals();
              });
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF2563EB)),
            SizedBox(width: 6),
            Text(
              'Add Items in Bulk',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _uploadLink,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isUploadButtonHovered = true),
            onExit: (_) => setState(() => _isUploadButtonHovered = false),
            child: CustomPaint(
              foregroundPainter: _DashedBorderPainter(
                color: (_isUploadButtonHovered || _uploadOverlay != null)
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFD1D5DB),
              ),
              child: Container(
                height: 36,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
        const SizedBox(height: 8),
        const Text(
          'You can upload a maximum of 10 files, 5MB each',
          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Future<void> _pickUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (!mounted || result == null) return;
      final count = result.files.length;
      if (count > 0) {
        ZerpaiToast.success(
          context,
          '$count file${count == 1 ? '' : 's'} selected',
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

  // ignore: unused_element
  Widget _buildCloudIcon(IconData icon, Color color) {
    return InkWell(
      onTap: () {
        _uploadOverlay?.remove();
        _uploadOverlay = null;
        if (mounted) setState(() {});
      },
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _summaryRow(
    String label,
    double value, {
    bool isBold = false,
    double fontSize = 13,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: fontSize,
              color: _kBodyText,
            ),
          ),
        ),
        Text(
          value.abs().toStringAsFixed(2),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: fontSize,
            color: _kBodyText,
          ),
        ),
      ],
    );
  }

  Widget _summaryInputRow(
    String label,
    TextEditingController ctrl, {
    bool isAdjustment = false,
    TextEditingController? labelCtrl,
    String? tooltip,
  }) {
    Widget tooltipIcon() {
      if (tooltip != null) {
        return Tooltip(
          message: tooltip,
          preferBelow: false,
          verticalOffset: 12,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const ShapeDecoration(
            color: Color(0xFF1F2937),
            shape: TooltipShapeBorder(),
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.5,
          ),
          child: const Icon(
            Icons.help_outline,
            size: 16,
            color: Color(0xFF9CA3AF),
          ),
        );
      }
      return const Icon(Icons.help_outline, size: 16, color: Color(0xFF9CA3AF));
    }

    Widget labelWidget() {
      if (isAdjustment && labelCtrl != null) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isAdjustmentLabelHovered = true),
          onExit: (_) => setState(() => _isAdjustmentLabelHovered = false),
          child: CustomPaint(
            foregroundPainter: _DashedBorderPainter(
              color:
                  (_adjustmentLabelFocusNode.hasFocus ||
                      _isAdjustmentLabelHovered)
                  ? _kBlue
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
                controller: labelCtrl,
                focusNode: _adjustmentLabelFocusNode,
                style: const TextStyle(fontSize: 13, color: _kBodyText),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 9,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _kBodyText,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isAdjustment && labelCtrl != null) ...[
                    labelWidget(),
                    const Spacer(),
                  ] else
                    Expanded(child: labelWidget()),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    height: 32,
                    child: CustomTextField(
                      controller: ctrl,
                      height: 32,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  tooltipIcon(),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  (double.tryParse(ctrl.text) ?? 0).toStringAsFixed(2),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _kBodyText,
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            if (isAdjustment && labelCtrl != null) ...[
              labelWidget(),
              const Spacer(),
            ] else
              Expanded(child: labelWidget()),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              height: 32,
              child: CustomTextField(
                controller: ctrl,
                height: 32,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(width: 8),
            tooltipIcon(),
            const SizedBox(width: 12),
            Text(
              (double.tryParse(ctrl.text) ?? 0).toStringAsFixed(2),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _kBodyText,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryRadioRow() {
    final taxDropdown = SizedBox(
      height: 32,
      child: FormDropdown<String>(
        value: _selectedTdsId,
        height: 32,
        hint: 'Select a Tax',
        items: _tdsList.map((t) => t['id'] as String).toList(),
        displayStringForValue: (id) =>
            _tdsList.firstWhere(
                  (t) => t['id'] == id,
                  orElse: () => {'tax_name': id},
                )['tax_name']
                as String,
        itemBuilder: (id, isSelected, isHovered) {
          final term = _tdsList.firstWhere(
            (t) => t['id'] == id,
            orElse: () => {'tax_name': id},
          );
          return _dropdownItemBuilder(
            term['tax_name'] ?? id,
            isSelected,
            isHovered,
          );
        },
        onChanged: (v) => setState(() => _selectedTdsId = v),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _radioOption('TDS'),
                  const SizedBox(width: 4),
                  _radioOption('TCS'),
                  const Spacer(),
                  const Text(
                    '- 0.00',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _kBodyText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              taxDropdown,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _radioOption('TDS'),
                  const SizedBox(width: 4),
                  _radioOption('TCS'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: taxDropdown),
            const SizedBox(width: 12),
            const Text(
              '- 0.00',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _kBodyText,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _radioOption(String value) {
    return InkWell(
      onTap: () => setState(() => _tdsTcsType = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _tdsTcsType == value ? _kBlue : const Color(0xFFD1D5DB),
                width: 1.5,
              ),
            ),
            child: _tdsTcsType == value
                ? Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _kBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _kBodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          // Left: Main Actions
          ElevatedButton(
            onPressed: () => _saveSalesOrder(status: 'draft'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9FAFB),
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(_isEditMode ? 'Update Draft' : 'Save as Draft'),
          ),
          const SizedBox(width: 12),
          // Split Button: Save and Send
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981), // Emerald-500
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _saveSalesOrder(
                    status: widget.initialOrder?.status ?? 'sent',
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _isEditMode ? 'Update' : 'Save and Send',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                InkWell(
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/sales/orders');
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              backgroundColor: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const Spacer(),
          // Right: Status info
          Row(
            children: [
              const Icon(
                LucideIcons.settings,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              const Text(
                'Inventory Tracking',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Amount: ₹ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    'Total Quantity: ${rows.where((r) => r.itemId.isNotEmpty).fold<double>(0, (sum, row) => sum + (double.tryParse(row.quantityCtrl.text) ?? 0)).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveSalesOrder({required String status}) async {
    if (_selectedCustomerId == null) return;
    final items = rows
        .where((r) => r.itemId.isNotEmpty)
        .map(
          (r) => SalesOrderItem(
            itemId: r.itemId,
            quantity: double.tryParse(r.quantityCtrl.text) ?? 0,
            rate: double.tryParse(r.rateCtrl.text) ?? 0,
            discount: double.tryParse(r.discountCtrl.text) ?? 0,
            discountType: r.discountType == 'Value' ? 'value' : '%',
            taxId: r.taxId,
          ),
        )
        .toList();

    final order = SalesOrder(
      id: _editingOrderId ?? '',
      customerId: _selectedCustomerId!,
      saleNumber: salesOrderNumberCtrl.text,
      reference: referenceCtrl.text,
      saleDate: salesOrderDate,
      expectedShipmentDate: expectedShipmentDate,
      paymentTerms: paymentTerms,
      deliveryMethod: deliveryMethod,
      salesperson: salesperson,
      status: status,
      documentType: 'order',
      items: items,
      subTotal: subTotal,
      taxTotal: taxTotal,
      discountTotal: 0,
      shippingCharges: double.tryParse(shippingCtrl.text) ?? 0,
      adjustment: double.tryParse(adjustmentCtrl.text) ?? 0,
      total: total,
      customerNotes: notesCtrl.text,
      termsAndConditions: termsCtrl.text,
    );

    try {
      final controller = ref.read(salesOrderControllerProvider.notifier);
      if (_isEditMode && _editingOrderId != null) {
        await controller.updateSalesOrder(_editingOrderId!, order);
      } else {
        await controller.createSalesOrder(order);
      }
      if (mounted) {
        ZerpaiToast.success(
          context,
          _isEditMode ? 'Sales order updated' : 'Sales order created',
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/sales/orders');
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error: $e');
      }
    }
  }

  void _toggleSettingsOverlay() {
    if (_settingsOverlay != null) {
      _settingsOverlay?.remove();
      _settingsOverlay = null;
      setState(() {});
      return;
    }

    String? hovered;
    _settingsOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _settingsOverlay?.remove();
                _settingsOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _settingsLink,
            showWhenUnlinked: false,
            offset: const Offset(-200, 24),
            child: Material(
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(8),
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSettingsOverlayItem(
                          label: _showAvailableStock
                              ? 'Hide Available stock for sale'
                              : 'Show Available stock for sale',
                          showHighlight: hovered == 'stock',
                          onHover: (v) => setOverlayState(
                            () => hovered = v ? 'stock' : null,
                          ),
                          onTap: () {
                            setState(
                              () => _showAvailableStock = !_showAvailableStock,
                            );
                            _settingsOverlay?.remove();
                            _settingsOverlay = null;
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 4),
                        _buildSettingsOverlayItem(
                          label: _showRecentTransactions
                              ? 'Hide Recent Transaction'
                              : 'Show Recent Transaction',
                          showHighlight: hovered == 'history',
                          onHover: (v) => setOverlayState(
                            () => hovered = v ? 'history' : null,
                          ),
                          onTap: () {
                            setState(() {
                              _showRecentTransactions =
                                  !_showRecentTransactions;
                            });
                            _settingsOverlay?.remove();
                            _settingsOverlay = null;
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 4),
                        _buildSettingsOverlayItem(
                          label: _showPriceList
                              ? 'Hide PriceList'
                              : 'Show PriceList',
                          showHighlight: hovered == 'pricelist',
                          onHover: (v) => setOverlayState(
                            () => hovered = v ? 'pricelist' : null,
                          ),
                          onTap: () {
                            setState(() {
                              _showPriceList = !_showPriceList;
                            });
                            _settingsOverlay?.remove();
                            _settingsOverlay = null;
                            setState(() {});
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_settingsOverlay!);
    setState(() {});
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
          color: showHighlight ? _kBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: showHighlight ? FontWeight.w600 : FontWeight.w500,
            color: showHighlight
                ? Colors.white
                : _kBodyText.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  // ── Address Section ──────────────────────────────────────────────────────
  Widget _buildCustomerAddressSection(SalesCustomer c) {
    // Check if billing address exists
    final hasBilling = [
      c.billingAddressStreet1,
      c.billingAddressStreet2,
      c.billingAddressCity,
      c.billingAddressZip,
      c.billingAddressCountryId,
    ].any((v) => v != null && v.isNotEmpty);

    // Check if shipping address exists
    final hasShipping = [
      c.shippingAddressStreet1,
      c.shippingAddressStreet2,
      c.shippingAddressCity,
      c.shippingAddressZip,
      c.shippingAddressCountryId,
    ].any((v) => v != null && v.isNotEmpty);

    final gst = c.gstTreatment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Addresses row ──────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Billing
            SizedBox(
              width: 240,
              child: _buildAddressColumn(
                label: 'BILLING ADDRESS',
                hasAddress: hasBilling,
                attention: c.companyName ?? c.displayName,
                street1: c.billingAddressStreet1,
                street2: c.billingAddressStreet2,
                city: c.billingAddressCity,
                state: c.billingAddressStateId,
                zip: c.billingAddressZip,
                country: c.billingAddressCountryId,
                phone: c.billingAddressPhone,
              ),
            ),
            const SizedBox(width: 32),
            // Shipping
            SizedBox(
              width: 240,
              child: _buildAddressColumn(
                label: 'SHIPPING ADDRESS',
                hasAddress: hasShipping,
                attention: c.companyName ?? c.displayName,
                street1: c.shippingAddressStreet1,
                street2: c.shippingAddressStreet2,
                city: c.shippingAddressCity,
                state: c.shippingAddressStateId,
                zip: c.shippingAddressZip,
                country: c.shippingAddressCountryId,
                phone: c.shippingAddressPhone,
              ),
            ),
          ],
        ),

        // ── GST Treatment & GSTIN ──────────────────────────────────────────
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'GST Treatment: ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                if (gst != null && gst.isNotEmpty) ...[
                  Text(
                    gst,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CompositedTransformTarget(
                    link: _gstTaxLink,
                    child: InkWell(
                      onTap: () => _toggleGstTaxOverlay(gst),
                      child: const Icon(
                        LucideIcons.pencil,
                        size: 11,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ] else
                  GestureDetector(
                    onTap: () => _toggleGstTaxOverlay(''),
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
            if (c.gstin != null && c.gstin!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'GSTIN: ',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    c.gstin!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CompositedTransformTarget(
                    link: _gstinLink,
                    child: InkWell(
                      onTap: () => _toggleGstinOverlay(c.gstin ?? ''),
                      child: const Icon(
                        LucideIcons.pencil,
                        size: 11,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAddressColumn({
    required String label,
    required bool hasAddress,
    String? attention,
    String? street1,
    String? street2,
    String? city,
    String? state,
    String? zip,
    String? country,
    String? phone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _showAddressDialog(title: label),
              child: const Icon(
                LucideIcons.pencil,
                size: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (!hasAddress)
          Row(
            children: [
              GestureDetector(
                onTap: () => _showAddressDialog(title: label),
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
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (attention != null && attention.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    attention,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (street1 != null && street1.isNotEmpty)
                Text(
                  street1,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              if (street2 != null && street2.isNotEmpty)
                Text(
                  street2,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              if ((city != null && city.isNotEmpty) ||
                  (state != null && state.isNotEmpty) ||
                  (zip != null && zip.isNotEmpty))
                Text(
                  '${city ?? ''}${city != null && (state != null || zip != null) ? ', ' : ''}${state ?? ''} ${zip ?? ''}'
                      .trim(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              if (country != null && country.isNotEmpty)
                Text(
                  country,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              if (phone != null && phone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Phone: $phone',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4B5563),
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  void _showAddressDialog({required String title}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Address Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) {
        final isBilling = title.contains('BILLING');
        final c = _selectedCustomer;
        final initialAddress = {
          'companyName': c?.companyName,
          'attention': '',
          'street1': isBilling
              ? c?.billingAddressStreet1
              : c?.shippingAddressStreet1,
          'street2': isBilling
              ? c?.billingAddressStreet2
              : c?.shippingAddressStreet2,
          'city': isBilling ? c?.billingAddressCity : c?.shippingAddressCity,
          'zip': isBilling ? c?.billingAddressZip : c?.shippingAddressZip,
          'phone': isBilling ? c?.billingAddressPhone : c?.shippingAddressPhone,
        };

        return _AddressDialog(
          title: title,
          initialAddress: initialAddress,
          onSave: (val) {
            setState(() {
              if (isBilling) {
                _selectedCustomer = _selectedCustomer?.copyWith(
                  billingAddressStreet1: val['street1'],
                  billingAddressStreet2: val['street2'],
                  billingAddressCity: val['city'],
                  billingAddressStateId: val['state'],
                  billingAddressZip: val['zip'],
                  billingAddressCountryId: val['country'],
                  billingAddressPhone: val['phone'],
                );
              } else {
                _selectedCustomer = _selectedCustomer?.copyWith(
                  shippingAddressStreet1: val['street1'],
                  shippingAddressStreet2: val['street2'],
                  shippingAddressCity: val['city'],
                  shippingAddressStateId: val['state'],
                  shippingAddressZip: val['zip'],
                  shippingAddressCountryId: val['country'],
                  shippingAddressPhone: val['phone'],
                );
              }
            });
          },
        );
      },
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  void _toggleGstTaxOverlay(String initialGst) {
    if (_gstTaxOverlay != null) {
      _gstTaxOverlay?.remove();
      _gstTaxOverlay = null;
      setState(() {});
      return;
    }

    _gstTaxOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _gstTaxOverlay?.remove();
                _gstTaxOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _gstTaxLink,
            showWhenUnlinked: false,
            offset: const Offset(-330, 20),
            child: Material(
              color: Colors.transparent,
              child: _TaxPreferenceDialog(
                initialGst: initialGst,
                onUpdate: (newGst) {
                  setState(() {
                    _selectedCustomer = _selectedCustomer?.copyWith(
                      gstTreatment: newGst,
                    );
                  });
                  _gstTaxOverlay?.remove();
                  _gstTaxOverlay = null;
                },
                onClose: () {
                  _gstTaxOverlay?.remove();
                  _gstTaxOverlay = null;
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_gstTaxOverlay!);
    setState(() {});
  }

  void _toggleGstinOverlay(String currentGstin) {
    if (_gstinOverlay != null) {
      _gstinOverlay?.remove();
      _gstinOverlay = null;
      setState(() {});
      return;
    }

    _gstinOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _gstinOverlay?.remove();
                _gstinOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _gstinLink,
            showWhenUnlinked: false,
            offset: const Offset(-250, 20),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: CustomPaint(
                      size: const Size(14, 8),
                      painter: _ArrowPainter(),
                    ),
                  ),
                  Container(
                    width: 320,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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
                        // GSTIN List Item
                        InkWell(
                          onTap: () {
                            _gstinOverlay?.remove();
                            _gstinOverlay = null;
                            setState(() {});
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currentGstin.isNotEmpty
                                        ? "$currentGstin - Kerala[KL]"
                                        : "32ABACS3075R1ZX - Kerala[KL]",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1F2937),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  LucideIcons.chevronDown,
                                  size: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bottom Actions
                        InkWell(
                          onTap: () {
                            _gstinOverlay?.remove();
                            _gstinOverlay = null;
                            setState(() {});
                            _showManageTaxInfoDialog();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: const Color(0xFFF0F7FF),
                            child: const Row(
                              children: [
                                Text(
                                  'Manage Tax Informations',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  LucideIcons.settings,
                                  size: 16,
                                  color: Color(0xFF2563EB),
                                ),
                              ],
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
        ],
      ),
    );
    Overlay.of(context).insert(_gstinOverlay!);
    setState(() {});
  }

  Widget _buildDiscountTypeSelector(SalesOrderItemRow row) {
    return CompositedTransformTarget(
      link: row.discountLink,
      child: InkWell(
        onTap: () => _toggleDiscountOverlay(row),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        child: SizedBox(
          width: 48,
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                row.discountType,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1F2937), // _kBodyText
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: Color(0xFF1F2937),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDiscountOverlay(SalesOrderItemRow row) {
    if (_discountOverlay != null) {
      _discountOverlay?.remove();
      _discountOverlay = null;
      _activeDiscountRow = null;
      setState(() {});
      if (_activeDiscountRow == row) return;
    }

    _activeDiscountRow = row;

    _discountOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _discountOverlay?.remove();
                _discountOverlay = null;
                _activeDiscountRow = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: row.discountLink,
            showWhenUnlinked: false,
            offset: const Offset(-8, 44),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 58,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ['%', '₹'].map((s) {
                    final isSelected = s == row.discountType;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          row.discountType = s;
                        });
                        _calculateTotals();
                        _discountOverlay?.remove();
                        _discountOverlay = null;
                        _activeDiscountRow = null;
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: double.infinity,
                        height: 38,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.85)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF374151),
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_discountOverlay!);
    setState(() {});
  }

  void _toggleRowActionsOverlay(SalesOrderItemRow row) {
    if (_rowActionsOverlay != null) {
      _rowActionsOverlay?.remove();
      _rowActionsOverlay = null;
      setState(() {});
      return;
    }

    String? hoveredItem;
    _rowActionsOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _rowActionsOverlay?.remove();
                _rowActionsOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: row.moreActionsLink,
            showWhenUnlinked: false,
            offset: const Offset(-200, 24),
            child: Material(
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(8),
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSettingsOverlayItem(
                          label: _showAdditionalInfo
                              ? 'Hide Additional Information'
                              : 'Show Additional Information',
                          showHighlight: hoveredItem == 'additional',
                          onHover: (v) => setOverlayState(
                            () => hoveredItem = v ? 'additional' : null,
                          ),
                          onTap: () {
                            setState(
                              () => _showAdditionalInfo = !_showAdditionalInfo,
                            );
                            _rowActionsOverlay?.remove();
                            _rowActionsOverlay = null;
                            setState(() {});
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
                            final idx = rows.indexOf(row);
                            if (idx != -1) {
                              setState(() {
                                final newRow = _createItemRow(
                                  quantity: row.quantityCtrl.text,
                                  rate: row.rateCtrl.text,
                                  discount: row.discountCtrl.text,
                                  fQty: row.fQtyCtrl.text,
                                  mrp: row.mrpCtrl.text,
                                  description: row.descriptionCtrl.text,
                                  itemId: row.itemId,
                                  item: row.item,
                                  discountType: row.discountType,
                                  taxId: row.taxId,
                                );
                                rows.insert(idx + 1, newRow);
                              });
                              _calculateTotals();
                            }
                            _rowActionsOverlay?.remove();
                            _rowActionsOverlay = null;
                          },
                        ),
                        const Divider(height: 17, color: Color(0xFFE5E7EB)),
                        _buildSettingsOverlayItem(
                          label: 'Insert New Row',
                          showHighlight: hoveredItem == 'insert',
                          onHover: (v) => setOverlayState(
                            () => hoveredItem = v ? 'insert' : null,
                          ),
                          onTap: () {
                            final idx = rows.indexOf(row);
                            if (idx != -1) {
                              setState(() {
                                rows.insert(
                                  idx + 1,
                                  _createItemRow(
                                    quantity: '1',
                                    rate: '0',
                                    discount: '0',
                                  ),
                                );
                              });
                            }
                            _rowActionsOverlay?.remove();
                            _rowActionsOverlay = null;
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
                            _rowActionsOverlay?.remove();
                            _rowActionsOverlay = null;
                          },
                        ),
                        const SizedBox(height: 4),
                        _buildSettingsOverlayItem(
                          label: 'Insert New Header',
                          showHighlight: hoveredItem == 'header',
                          onHover: (v) => setOverlayState(
                            () => hoveredItem = v ? 'header' : null,
                          ),
                          onTap: () {
                            _rowActionsOverlay?.remove();
                            _rowActionsOverlay = null;
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_rowActionsOverlay!);
    setState(() {});
  }

  void _toggleHsnOverlay(SalesOrderItemRow row) {
    if (_hsnOverlay != null) {
      _hsnOverlay?.remove();
      _hsnOverlay = null;
      _activeHsnRow = null;
      setState(() {});
      if (_activeHsnRow == row) return;
    }

    final hsnCtrl = TextEditingController(text: row.item?.hsnCode ?? '');
    _activeHsnRow = row;

    _hsnOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _hsnOverlay?.remove();
                _hsnOverlay = null;
                _activeHsnRow = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: row.hsnLink,
            showWhenUnlinked: false,
            offset: const Offset(-20, 24),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: CustomPaint(
                      size: const Size(12, 8),
                      painter: _TrianglePainter(color: Colors.white),
                    ),
                  ),
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder),
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
                        const Text(
                          'HSN Code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: hsnCtrl,
                          hintText: 'Enter HSN Code',
                          suffixWidget: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              LucideIcons.search,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          forceUppercase: false,
                          contentCase: ContentCase.none,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  if (row.item != null) {
                                    final isGoods =
                                        row.item!.type.toLowerCase() == 'goods';
                                    if (isGoods) {
                                      row.item = row.item!.copyWith(
                                        hsnCode: hsnCtrl.text,
                                      );
                                    } else {
                                      row.item = row.item!.copyWith(
                                        hsnCode: hsnCtrl.text,
                                      );
                                    }
                                  }
                                });
                                _hsnOverlay?.remove();
                                _hsnOverlay = null;
                                _activeHsnRow = null;
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                _hsnOverlay?.remove();
                                _hsnOverlay = null;
                                _activeHsnRow = null;
                                setState(() {});
                              },
                              child: const Text('Close'),
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
        ],
      ),
    );
    Overlay.of(context).insert(_hsnOverlay!);
    setState(() {});
  }

  void _showAdvancedCustomerSearch(List<SalesCustomer> customers) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Advanced Customer Search',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) => AdvancedCustomerSearchDialog(
        customers: customers,
        onSelect: (c) {
          setState(() {
            _customerDetailsSidebarOverlay?.remove();
            _customerDetailsSidebarOverlay = null;
            _selectedCustomerId = c.id;
            _selectedCustomer = c;

            // Trigger rate update for all rows when customer changes
            final priceLists =
                ref.read(filteredPriceListsProvider).asData?.value ?? [];
            for (var row in rows) {
              if (row.itemId.isNotEmpty && row.item != null) {
                _updateRowRate(row, c, priceLists);
              }
            }
          });
        },
      ),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  void _showManageTaxInfoDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Manage Tax Informations',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) => const _ManageTaxInfoDialog(),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
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
          _TH(label),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggle,
            child: const Icon(
              LucideIcons.search,
              size: 13,
              color: _kLabelGrey,
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
        border: Border.all(color: _kBorder),
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
              style: const TextStyle(fontSize: 11, color: _kBodyText),
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
            child: const Icon(LucideIcons.x, size: 12, color: _kLabelGrey),
          ),
        ],
      ),
    );
  }
}

Widget _dropdownItemBuilder(String label, bool isSelected, bool isHovered) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isHovered
          ? const Color(0xFF3B82F6)
          : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              color: isHovered
                  ? Colors.white
                  : (isSelected
                        ? const Color(0xFF1F2937)
                        : const Color(0xFF1F2937)),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isSelected)
          Icon(
            Icons.check,
            size: 16,
            color: isHovered ? Colors.white : const Color(0xFF1F2937),
          ),
      ],
    ),
  );
}

class _ManageTaxInfoDialog extends ConsumerStatefulWidget {
  const _ManageTaxInfoDialog();

  @override
  ConsumerState<_ManageTaxInfoDialog> createState() =>
      _ManageTaxInfoDialogState();
}

class _ManageTaxInfoDialogState extends ConsumerState<_ManageTaxInfoDialog> {
  bool _adding = false;

  // Form Controllers
  final _gstinCtrl = TextEditingController();
  final _legalNameCtrl = TextEditingController();
  final _tradeNameCtrl = TextEditingController();

  _GstTreatmentOption? _selectedTreatment;
  String? _selectedPlaceOfSupply;

  final _gstOptions = const [
    _GstTreatmentOption(
      'Registered Business - Regular',
      'Business that is registered under GST',
    ),
    _GstTreatmentOption(
      'Registered Business - Composition',
      'Business that is registered under the Composition Scheme in GST',
    ),
    _GstTreatmentOption(
      'Unregistered Business',
      'Business that has not been registered under GST',
    ),
    _GstTreatmentOption('Consumer', 'A customer who is a regular consumer'),
    _GstTreatmentOption(
      'Overseas',
      'Persons with whom you do import or export of supplies outside India',
    ),
    _GstTreatmentOption(
      'Special Economic Zone',
      'Business (Unit) that is located in a Special Economic Zone (SEZ) of India or a SEZ Developer',
    ),
    _GstTreatmentOption(
      'Deemed Export',
      'Supply of goods to an Export Oriented Unit or against Advanced Authorization/Export Promotion Capital Goods.',
    ),
    _GstTreatmentOption(
      'Tax Deductor',
      'Departments of the State/Central government, governmental agencies or local authorities',
    ),
    _GstTreatmentOption(
      'SEZ Developer',
      'A person/organisation who owns at least 26% of the equity in creating business units in a Special Economic Zone (SEZ)',
    ),
    _GstTreatmentOption(
      'Input Service Distributor',
      'Input Service Distributor (ISD) is an office that receives tax invoices for services used by the company in different states under the same PAN.',
    ),
  ];

  @override
  void dispose() {
    _gstinCtrl.dispose();
    _legalNameCtrl.dispose();
    _tradeNameCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDec({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: _kBlue),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: _adding ? 600 : 700,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      if (_adding)
                        IconButton(
                          onPressed: () => setState(() => _adding = false),
                          icon: const Icon(Icons.arrow_back, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (_adding) const SizedBox(width: 8),
                      Text(
                        _adding
                            ? 'Add Tax Information'
                            : 'Manage Tax Informations',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                // Content
                if (!_adding) _buildListView() else _buildFormView(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => setState(() => _adding = true),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Add New Tax Information',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Table header
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Row(
              children: [
                Expanded(child: _TH('GSTIN')),
                Expanded(child: _TH('PLACE OF SUPPLY')),
                Expanded(child: _TH('BUSINESS LEGAL NAME')),
                Expanded(child: _TH('BUSINESS TRADE NAME')),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // Data row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '32ABACS3075R1ZX',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '(Primary Tax Information)',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Kerala',
                    style: TextStyle(fontSize: 13, color: Color(0xFF111827)),
                  ),
                ),
                const Expanded(child: SizedBox()),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('GST Treatment'),
                    FormDropdown<_GstTreatmentOption>(
                      height: 38,
                      value: _selectedTreatment,
                      items: _gstOptions,
                      hint: 'Select a GST treatment',
                      displayStringForValue: (v) => v.label,
                      itemBuilder: (opt, isSelected, isHovered) =>
                          _dropdownItemBuilder(
                            opt.label,
                            isSelected,
                            isHovered,
                          ),
                      onChanged: (v) => setState(() => _selectedTreatment = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('GSTIN'),
                    TextField(
                      controller: _gstinCtrl,
                      decoration: _inputDec(hint: 'Enter your GSTIN'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _label('Place of Supply'),
          Builder(
            builder: (context) {
              final statesAsync = ref.watch(statesProvider('IN'));
              final states = statesAsync.value ?? [];
              return FormDropdown<String>(
                height: 38,
                value: _selectedPlaceOfSupply,
                items: states.map((s) => s['name'] ?? '').toList(),
                hint: 'Select Place of Supply',
                onChanged: (v) => setState(() => _selectedPlaceOfSupply = v),
              );
            },
          ),
          const SizedBox(height: 20),
          _label('Business Legal Name'),
          TextField(
            controller: _legalNameCtrl,
            decoration: _inputDec(hint: 'Enter Business Legal Name'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),
          _label('Business Trade Name'),
          TextField(
            controller: _tradeNameCtrl,
            decoration: _inputDec(hint: 'Enter Business Trade Name'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  // Logic to save would go here
                  setState(() => _adding = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => setState(() => _adding = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    var path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      Rect.fromLTWH(0, 0, size.width, size.height),
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

// ─── Helper widgets ──────────────────────────────────────────────────────────
class _TH extends StatelessWidget {
  final String text;
  final bool right;
  final String? tooltip;
  const _TH(this.text, {this.right = false, this.tooltip});

  @override
  Widget build(BuildContext context) {
    Widget content = Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _kLabelGrey,
        letterSpacing: 0.4,
      ),
    );

    if (tooltip != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          content,
          const SizedBox(width: 4),
          Tooltip(
            message: tooltip!,
            preferBelow: false,
            verticalOffset: 12,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const ShapeDecoration(
              color: Color(0xFF1F2937),
              shape: TooltipShapeBorder(),
            ),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.4,
            ),
            child: const Icon(
              Icons.help_outline,
              size: 13,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      );
    }

    return content;
  }
}

Widget _vLine() =>
    const VerticalDivider(width: 1, color: _kBorder, thickness: 1);

// ─────────────────────────────────────────────────────────────────────────────
// Address Dialog — top-aligned popup matching the screenshot
// ─────────────────────────────────────────────────────────────────────────────
class _AddressDialog extends ConsumerStatefulWidget {
  final String title;
  final Map<String, dynamic> initialAddress;
  final ValueChanged<Map<String, dynamic>> onSave;

  const _AddressDialog({
    required this.title,
    required this.initialAddress,
    required this.onSave,
  });

  @override
  ConsumerState<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends ConsumerState<_AddressDialog> {
  final _companyNameCtrl = TextEditingController();
  final _attentionCtrl = TextEditingController();
  final _street1Ctrl = TextEditingController();
  final _street2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _faxCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  Map<String, String>? _selectedCountry;
  Map<String, String>? _selectedState;
  String _phoneCode = '+91';

  static const _phoneCodes = [
    '+91',
    '+1',
    '+44',
    '+971',
    '+61',
    '+1-CA',
    '+65',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialAddress;
    _companyNameCtrl.text = init['companyName'] ?? '';
    _attentionCtrl.text = init['attention'] ?? '';
    _street1Ctrl.text = init['street1'] ?? '';
    _street2Ctrl.text = init['street2'] ?? '';
    _cityCtrl.text = init['city'] ?? '';
    _pinCtrl.text = init['zip'] ?? '';
    _phoneCtrl.text = init['phone'] ?? '';
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _attentionCtrl.dispose();
    _street1Ctrl.dispose();
    _street2Ctrl.dispose();
    _cityCtrl.dispose();
    _pinCtrl.dispose();
    _faxCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDec({String? hint, bool multiline = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: multiline ? 10 : 9,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: _kBlue),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _kBodyText,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dialogTitle = widget.title.contains('BILLING')
        ? 'Billing Address'
        : widget.title.contains('SHIPPING')
        ? 'Shipping Address'
        : widget.title;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxHeight: 680),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  child: Row(
                    children: [
                      Text(
                        dialogTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _kBodyText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dialogTitle == 'Drop Shipping Address') ...[
                          _label('Company Name'),
                          TextField(
                            controller: _companyNameCtrl,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _kBodyText,
                            ),
                            decoration: _inputDec(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _label('Attention'),
                        TextField(
                          controller: _attentionCtrl,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kBodyText,
                          ),
                          decoration: _inputDec(),
                        ),
                        const SizedBox(height: 16),
                        _label('Country/Region'),
                        Builder(
                          builder: (context) {
                            final countriesAsync = ref.watch(
                              countriesProvider(null),
                            );
                            final countries = countriesAsync.value ?? [];
                            return FormDropdown<Map<String, String>>(
                              height: 32,
                              value: _selectedCountry,
                              hint: 'Select',
                              isLoading: countriesAsync.isLoading,
                              items: countries,
                              displayStringForValue: (c) => c['name'] ?? '',
                              itemBuilder: (c, isSelected, isHovered) =>
                                  _dropdownItemBuilder(
                                    c['name'] ?? '',
                                    isSelected,
                                    isHovered,
                                  ),
                              onChanged: (v) =>
                                  setState(() => _selectedCountry = v),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _label('Address'),
                        TextField(
                          controller: _street1Ctrl,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kBodyText,
                          ),
                          maxLines: 2,
                          minLines: 2,
                          decoration: _inputDec(
                            hint: 'Street 1',
                            multiline: true,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _street2Ctrl,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kBodyText,
                          ),
                          maxLines: 2,
                          minLines: 2,
                          decoration: _inputDec(
                            hint: 'Street 2',
                            multiline: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label('City'),
                        TextField(
                          controller: _cityCtrl,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kBodyText,
                          ),
                          decoration: _inputDec(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('State'),
                                  Builder(
                                    builder: (context) {
                                      final countryId =
                                          _selectedCountry?['id'] ?? '';
                                      final statesAsync = ref.watch(
                                        statesProvider(countryId),
                                      );
                                      final states = statesAsync.value ?? [];
                                      return FormDropdown<Map<String, String>>(
                                        height: 32,
                                        value: _selectedState,
                                        hint: 'Select or type to add',
                                        isLoading: statesAsync.isLoading,
                                        items: states,
                                        displayStringForValue: (s) =>
                                            s['name'] ?? '',
                                        itemBuilder:
                                            (s, isSelected, isHovered) =>
                                                _dropdownItemBuilder(
                                                  s['name'] ?? '',
                                                  isSelected,
                                                  isHovered,
                                                ),
                                        onChanged: (v) =>
                                            setState(() => _selectedState = v),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Pin Code'),
                                  TextField(
                                    controller: _pinCtrl,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kBodyText,
                                    ),
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDec(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Phone'),
                                  Row(
                                    children: [
                                      Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFD1D5DB),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _phoneCode,
                                            isDense: true,
                                            alignment: Alignment.center,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Inter',
                                              color: _kBodyText,
                                            ),
                                            items: _phoneCodes
                                                .map(
                                                  (c) => DropdownMenuItem(
                                                    value: c,
                                                    alignment: Alignment.center,
                                                    child: Text(c),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (v) =>
                                                setState(() => _phoneCode = v!),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: _phoneCtrl,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _kBodyText,
                                          ),
                                          keyboardType: TextInputType.phone,
                                          decoration: _inputDec(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Fax Number'),
                                  TextField(
                                    controller: _faxCtrl,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kBodyText,
                                    ),
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDec(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12),
                            children: [
                              const TextSpan(
                                text: 'Note: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _kBodyText,
                                ),
                              ),
                              TextSpan(
                                text:
                                    'Changes made here will be updated for this customer.',
                                style: const TextStyle(color: _kLabelGrey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () {
                          widget.onSave({
                            'companyName': _companyNameCtrl.text,
                            'street1': _street1Ctrl.text,
                            'street2': _street2Ctrl.text,
                            'city': _cityCtrl.text,
                            'zip': _pinCtrl.text,
                            'phone': _phoneCtrl.text,
                            'country': _selectedCountry?['id'],
                            'state': _selectedState?['id'],
                          });
                          Navigator.of(context).pop();
                        },
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kBodyText,
                          side: const BorderSide(color: _kBorder),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 13),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tax Preference Dialog — small flyout matching the screenshot
// ─────────────────────────────────────────────────────────────────────────────
class _GstTreatmentOption {
  final String label;
  final String description;
  const _GstTreatmentOption(this.label, this.description);
}

class _TaxPreferenceDialog extends StatefulWidget {
  final String initialGst;
  final ValueChanged<String>? onUpdate;
  final VoidCallback? onClose;

  const _TaxPreferenceDialog({
    required this.initialGst,
    this.onUpdate,
    this.onClose,
  });

  @override
  State<_TaxPreferenceDialog> createState() => _TaxPreferenceDialogState();
}

class _TaxPreferenceDialogState extends State<_TaxPreferenceDialog> {
  late _GstTreatmentOption _gst;

  final _options = const [
    _GstTreatmentOption(
      'Registered Business - Regular',
      'Business that is registered under GST',
    ),
    _GstTreatmentOption(
      'Registered Business - Composition',
      'Business that is registered under the Composition Scheme in GST',
    ),
    _GstTreatmentOption(
      'Unregistered Business',
      'Business that has not been registered under GST',
    ),
    _GstTreatmentOption('Consumer', 'A customer who is a regular consumer'),
    _GstTreatmentOption(
      'Overseas',
      'Persons with whom you do import or export of supplies outside India',
    ),
    _GstTreatmentOption(
      'Special Economic Zone',
      'Business (Unit) that is located in a Special Economic Zone (SEZ) of India or a SEZ Developer',
    ),
    _GstTreatmentOption(
      'Deemed Export',
      'Supply of goods to an Export Oriented Unit or against Advanced Authorization/Export Promotion Capital Goods.',
    ),
    _GstTreatmentOption(
      'Tax Deductor',
      'Departments of the State/Central government, governmental agencies or local authorities',
    ),
    _GstTreatmentOption(
      'SEZ Developer',
      'A person/organisation who owns at least 26% of the equity in creating business units in a Special Economic Zone (SEZ)',
    ),
    _GstTreatmentOption(
      'Input Service Distributor',
      'Input Service Distributor (ISD) is an office that receives tax invoices for services used by the company in different states under the same PAN.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _gst = _options.firstWhere(
      (o) => o.label == widget.initialGst,
      orElse: () => _options.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 34),
          child: CustomPaint(size: const Size(14, 8), painter: _ArrowPainter()),
        ),
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    const Text(
                      'Configure Tax Preferences',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kBodyText,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GST Treatment',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kBodyText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: FormDropdown<_GstTreatmentOption>(
                        value: _gst,
                        items: _options,
                        displayStringForValue: (v) => v.label,
                        searchStringForValue: (v) =>
                            '${v.label} ${v.description}',
                        itemBuilder: (item, isSelected, isHovered) =>
                            _buildGstTreatmentRow(item, isSelected, isHovered),
                        onChanged: (v) => setState(() => _gst = v!),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () {
                        if (widget.onUpdate != null) {
                          widget.onUpdate!(_gst.label);
                        } else {
                          Navigator.pop(context, _gst.label);
                        }
                      },
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kBodyText,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Cancel',
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

  Widget _buildGstTreatmentRow(
    _GstTreatmentOption option,
    bool isSelected,
    bool isHovered,
  ) {
    Color bg = Colors.transparent;
    Color title = const Color(0xFF111827);
    Color subtitle = const Color(0xFF6B7280);
    Color check = const Color(0xFF2563EB);

    if (isHovered) {
      bg = const Color(0xFF3B82F6);
      title = Colors.white;
      subtitle = Colors.white.withValues(alpha: 0.8);
      check = Colors.white;
    } else if (isSelected) {
      bg = const Color(0xFFF3F4F6);
      title = const Color(0xFF1F2937);
      subtitle = const Color(0xFF4B5563);
      check = const Color(0xFF1F2937);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: subtitle),
                ),
              ],
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Icon(Icons.check, size: 16, color: check),
            ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawShadow(path.shift(const Offset(0, 1)), Colors.black, 4, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer Details Sidebar — slides from right as shown in screenshot
// ─────────────────────────────────────────────────────────────────────────────
class _CustomerDetailsSidebar extends StatefulWidget {
  final SalesCustomer customer;
  final String? currencyLabel;
  final VoidCallback onClose;

  const _CustomerDetailsSidebar({
    required this.customer,
    this.currencyLabel,
    required this.onClose,
  });

  @override
  State<_CustomerDetailsSidebar> createState() =>
      _CustomerDetailsSidebarState();
}

class _CustomerDetailsSidebarState extends State<_CustomerDetailsSidebar> {
  int _activeTabIndex = 0;
  bool _isContactPersonsExpanded = false;
  bool _isAddressExpanded = false;

  String _inr(double? value) {
    final amount = value ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  Widget _tabItem(String label, int index) {
    final isActive = _activeTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _detailRow({required String label, required Widget value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 165,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool showRightBorder = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          border: showRightBorder
              ? const Border(right: BorderSide(color: Color(0xFFE5E7EB)))
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF020617),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _contactDisplayName(CustomerContact contact) {
    final parts = <String>[];
    final values = [contact.salutation, contact.firstName, contact.lastName];
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) parts.add(text);
    }

    if (parts.isNotEmpty) return parts.join(' ');
    if ((contact.email ?? '').trim().isNotEmpty) return contact.email!.trim();
    return 'Unnamed Contact';
  }

  Widget _buildContactPersonsSection(List<CustomerContact> contacts) {
    final badge = contacts.isNotEmpty ? '${contacts.length}' : null;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isContactPersonsExpanded = !_isContactPersonsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    'Contact Persons',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _isContactPersonsExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 16,
                    color: const Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ),
          if (_isContactPersonsExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: contacts.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No contact persons found for this customer.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : Column(
                      children: contacts
                          .asMap()
                          .entries
                          .map(
                            (entry) => Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(
                                bottom: entry.key == contacts.length - 1
                                    ? 0
                                    : 10,
                              ),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _contactDisplayName(entry.value),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if ((entry.value.email ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      entry.value.email!.trim(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                  if ((entry.value.mobilePhone ?? '')
                                          .trim()
                                          .isNotEmpty ||
                                      (entry.value.workPhone ?? '')
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      (entry.value.mobilePhone ?? '')
                                              .trim()
                                              .isNotEmpty
                                          ? entry.value.mobilePhone!.trim()
                                          : entry.value.workPhone!.trim(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required String title,
    required List<String> lines,
    String? phone,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
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
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          if (lines.isEmpty)
            const Text(
              'No address found.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            )
          else
            Text(
              lines.join('\n'),
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF0F172A),
              ),
            ),
          if ((phone ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              phone!.trim(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressSection(SalesCustomer customer) {
    final billingLines = <String>[
      if ((customer.billingAddressStreet1 ?? '').trim().isNotEmpty)
        customer.billingAddressStreet1!.trim(),
      if ((customer.billingAddressStreet2 ?? '').trim().isNotEmpty)
        customer.billingAddressStreet2!.trim(),
      if ((customer.billingAddressCity ?? '').trim().isNotEmpty)
        customer.billingAddressCity!.trim(),
      [
        customer.billingAddressStateId?.trim() ?? '',
        customer.billingAddressZip?.trim() ?? '',
      ].where((value) => value.isNotEmpty).join(', '),
      if ((customer.billingAddressCountryId ?? '').trim().isNotEmpty)
        customer.billingAddressCountryId!.trim(),
    ].where((value) => value.trim().isNotEmpty).toList();

    final shippingLines = <String>[
      if ((customer.shippingAddressStreet1 ?? '').trim().isNotEmpty)
        customer.shippingAddressStreet1!.trim(),
      if ((customer.shippingAddressStreet2 ?? '').trim().isNotEmpty)
        customer.shippingAddressStreet2!.trim(),
      if ((customer.shippingAddressCity ?? '').trim().isNotEmpty)
        customer.shippingAddressCity!.trim(),
      [
        customer.shippingAddressStateId?.trim() ?? '',
        customer.shippingAddressZip?.trim() ?? '',
      ].where((value) => value.isNotEmpty).join(', '),
      if ((customer.shippingAddressCountryId ?? '').trim().isNotEmpty)
        customer.shippingAddressCountryId!.trim(),
    ].where((value) => value.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isAddressExpanded = !_isAddressExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Text(
                    'Address',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isAddressExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 16,
                    color: const Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ),
          if (_isAddressExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  _buildAddressCard(
                    title: 'Billing Address',
                    lines: billingLines,
                    phone: customer.billingAddressPhone,
                  ),
                  const SizedBox(height: 10),
                  _buildAddressCard(
                    title: 'Shipping Address',
                    lines: shippingLines,
                    phone: customer.shippingAddressPhone,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final c = widget.customer;
    final hasFacebook = (c.facebookHandle ?? '').trim().isNotEmpty;
    final hasX = (c.twitterHandle ?? '').trim().isNotEmpty;
    final portalEnabled = c.enablePortal ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                _summaryTile(
                  icon: LucideIcons.alertTriangle,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Outstanding Receivables',
                  value: _inr(c.receivables),
                  showRightBorder: true,
                ),
                _summaryTile(
                  icon: LucideIcons.badgeCheck,
                  iconColor: const Color(0xFF10B981),
                  label: 'Unused Credits',
                  value: _inr(0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Text(
                    'Contact Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                  child: Column(
                    children: [
                      _detailRow(
                        label: 'Customer Type',
                        value: Text(
                          c.customerType ?? 'Business',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Currency',
                        value: Text(
                          (widget.currencyLabel ?? '').isNotEmpty
                              ? widget.currencyLabel!
                              : (c.currencyId ?? 'INR'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Credit Limit',
                        value: Text(
                          _inr(c.creditLimit),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Payment Terms',
                        value: Text(
                          (c.paymentTerms ?? '').isNotEmpty
                              ? c.paymentTerms!
                              : 'Net 30',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Portal Status',
                        value: Text(
                          portalEnabled ? 'Enabled' : 'Disabled',
                          style: TextStyle(
                            fontSize: 14,
                            color: portalEnabled
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      _detailRow(
                        label: 'Customer Language',
                        value: const Row(
                          children: [
                            Text('English', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 6),
                            Icon(
                              LucideIcons.info,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                      _detailRow(
                        label: 'Social Networks',
                        value: Row(
                          children: [
                            if (hasFacebook)
                              const FaIcon(
                                FontAwesomeIcons.facebook,
                                size: 15,
                                color: Color(0xFF1877F2),
                              ),
                            if (hasFacebook && hasX) const SizedBox(width: 10),
                            if (hasX)
                              const FaIcon(
                                FontAwesomeIcons.xTwitter,
                                size: 15,
                                color: Color(0xFF020617),
                              ),
                            if (!hasFacebook && !hasX)
                              const Text('-', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      _detailRow(
                        label: 'Price List',
                        value: Text(
                          (c.priceList ?? '').isNotEmpty
                              ? c.priceList!
                              : 'Pricelist',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'GST Treatment',
                        value: Text(
                          c.gstTreatment ?? 'Unregistered Business',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Place of Supply',
                        value: Text(
                          (c.placeOfSupply ?? '').isNotEmpty
                              ? c.placeOfSupply!
                              : '-',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      _detailRow(
                        label: 'Tax Preference',
                        value: Text(
                          c.taxPreference ?? 'Taxable',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildContactPersonsSection(c.contactPersons ?? const []),
          _buildAddressSection(c),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return const Center(
      child: Text(
        'No activity found.',
        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final customerCode = (c.customerNumber ?? '').isNotEmpty
        ? c.customerNumber!
        : c.displayName;
    final customerName = c.displayName.isNotEmpty
        ? c.displayName
        : customerCode;
    final initial = c.displayName.isNotEmpty
        ? c.displayName[0].toUpperCase()
        : 'C';

    return Container(
      width: 500,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: const Border(left: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(-6, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customerName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF020617),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.externalLink,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.fileText,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      customerCode,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mail,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (c.email ?? '').isNotEmpty ? c.email! : 'No email',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                _tabItem('Details', 0),
                const SizedBox(width: 24),
                _tabItem('Activity Log', 1),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: _activeTabIndex == 0
                ? _buildDetailsTab()
                : _buildActivityTab(),
          ),
        ],
      ),
    );
  }
}

class _ItemDetailsSidebar extends StatefulWidget {
  final SalesOrderItemRow row;
  final VoidCallback onClose;
  final String? customerName;

  const _ItemDetailsSidebar({
    required this.row,
    required this.onClose,
    this.customerName,
  });

  @override
  State<_ItemDetailsSidebar> createState() => _ItemDetailsSidebarState();
}

class _ItemDetailsSidebarState extends State<_ItemDetailsSidebar> {
  int _activeTabIndex = 2; // Default to TRANSACTIONS as per screenshot

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
                            const Text(
                              'BATCH TRACK 2',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
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
                        const Text(
                          'pcs • OTHER BRANDS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
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
    if (_activeTabIndex != 2) return const SizedBox();

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
                'Show only ${widget.customerName ?? 'customer'}\'s transactions',
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
}

class TooltipShapeBorder extends ShapeBorder {
  final double arrowWidth;
  final double arrowHeight;
  final double borderRadius;

  const TooltipShapeBorder({
    this.arrowWidth = 12.0,
    this.arrowHeight = 8.0,
    this.borderRadius = 8.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(bottom: arrowHeight);

  @override
  Path getInnerPath(Rect rect, {ui.TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {ui.TextDirection? textDirection}) {
    // Leave room for the arrow at the bottom
    final normalizedRect = Rect.fromLTRB(
      rect.left,
      rect.top,
      rect.right,
      rect.bottom - arrowHeight,
    );

    final double x = normalizedRect.bottomCenter.dx;
    final double y = normalizedRect.bottomCenter.dy;

    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(normalizedRect, Radius.circular(borderRadius)),
      )
      ..moveTo(x - arrowWidth / 2, y)
      ..lineTo(x, y + arrowHeight)
      ..lineTo(x + arrowWidth / 2, y)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {ui.TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF0088FF) : Colors.transparent,
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
    );
  }
}

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
