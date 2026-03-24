import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';

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
import 'package:zerpai_erp/modules/sales/presentation/widgets/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'widgets/advanced_customer_search_dialog.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_simple_list_dialog.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';

import 'widgets/custom_date_picker.dart';
import 'widgets/sales_order_preferences_dialog.dart';

// ─── Colour constants ────────────────────────────────────────────────────────
const _kBorder = Color(0xFFE5E7EB);
const _kLabelGrey = Color(0xFF6B7280);
const _kBodyText = Color(0xFF111827);
const _kBlue = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg = Color(0xFFF9FAFB);
const _kWhite = Colors.white;

class SalesOrderCreateScreen extends ConsumerStatefulWidget {
  const SalesOrderCreateScreen({super.key});

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
  OverlayEntry? _warehouseOverlay;
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

  bool _isAutoGenerateSO = true;
  String _soPrefix = 'SO-';
  String _soNextNumber = '00028';

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

    shippingCtrl.addListener(_calculateTotals);
    adjustmentCtrl.addListener(_calculateTotals);

    _addItemRow();
    _loadPaymentTerms();
    _loadSalespersons();
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

  Future<void> _openSelectedCustomerDetailsSidebar() async {
    final customerId = _selectedCustomerId;
    if (customerId == null || _isLoadingCustomerDetails) return;

    setState(() => _isLoadingCustomerDetails = true);

    try {
      final api = ref.read(salesOrderApiServiceProvider);
      final customer = await api.getCustomerById(customerId);
      final currencies = await ref.read(currenciesProvider(null).future);
      final currencyLabel = _resolveCurrencyLabel(customer.currencyId, currencies);
      if (!mounted) return;

      setState(() {
        _selectedCustomer = customer;
      });
      _showCustomerDetailsSidebar(customer, currencyLabel: currencyLabel);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load customer details: $e')),
      );
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

  void _addItemRow() {
    final row = SalesOrderItemRow(
      quantityCtrl: TextEditingController(text: '1'),
      rateCtrl: TextEditingController(text: '0'),
      discountCtrl: TextEditingController(text: '0'),
      fQtyCtrl: TextEditingController(text: '0'),
      mrpCtrl: TextEditingController(text: '0'),
      descriptionCtrl: TextEditingController(),
    );

    void onAnyChange() {
      final customers = ref.read(salesCustomersProvider).asData?.value ?? [];
      final customer = customers.firstWhere(
        (c) => c.id == _selectedCustomerId,
        orElse: () => customers.first,
      );
      final priceLists =
          ref.read(filteredPriceListsProvider).asData?.value ?? [];
      _updateRowRate(row, customer, priceLists);
      _calculateTotals();
    }

    row.quantityCtrl.addListener(onAnyChange);
    row.rateCtrl.addListener(_calculateTotals);
    row.discountCtrl.addListener(_calculateTotals);
    row.fQtyCtrl.addListener(_calculateTotals);
    row.mrpCtrl.addListener(_calculateTotals);

    setState(() => rows.add(row));
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

    return ZerpaiLayout(
      pageTitle: 'New Sales Order',
      actions: [
        IconButton(
          icon: const Icon(
            LucideIcons.settings,
            color: Color(0xFF3B82F6),
            size: 14,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(LucideIcons.x, color: Color(0xFF6B7280), size: 16),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/sales/orders');
            }
          },
        ),
      ],
      enableBodyScroll: true,
      footer: _buildFooter(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(
              customersAsync,
              priceListsAsync,
              currenciesAsync,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: _buildItemsTable(
                  itemsState.items,
                  customersAsync,
                  priceListsAsync,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: _buildSummaryAndNotes(itemsState.items),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    AsyncValue<List<SalesCustomer>> customersAsync,
    AsyncValue<List<PriceList>> priceListsAsync,
    AsyncValue<List<CurrencyOption>> currenciesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Section: Customer Name & Details with grey background
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          // We can use transform to push it out into the padding area to simulate full-width background bleed if needed:
          transform: Matrix4.translationValues(-24, -24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              customersAsync.when(
                data: (customers) => Column(
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
                            width: 420,
                            child: FormDropdown<String>(
                              value: _selectedCustomerId,
                              items: customers.map((c) => c.id).toList(),
                              hint: 'Select or add a customer',
                              displayStringForValue: (id) => customers
                                  .firstWhere((c) => c.id == id)
                                  .displayName,
                              itemHeight: 56,
                              showSettings: true,
                              settingsLabel: 'New Customer',
                              settingsIcon: LucideIcons.plus,
                              onSettingsTap: () {
                                // Logic to add new customer
                                context.push('/sales/customers/create');
                              },
                              itemBuilder: (id, isSelected, isHovered) {
                                final customer = customers.firstWhere(
                                  (c) => c.id == id,
                                );
                                final initials = customer.displayName.isNotEmpty
                                    ? customer.displayName[0].toUpperCase()
                                    : '?';

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEBF5FF)
                                        : (isHovered
                                              ? const Color(0xFFF9FAFB)
                                              : Colors.transparent),
                                    border: isSelected
                                        ? const Border(
                                            left: BorderSide(
                                              color: Color(0xFF2563EB),
                                              width: 3,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isSelected
                                            ? Colors.white
                                            : const Color(0xFFE5E7EB),
                                        child: Text(
                                          initials,
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF6B7280),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  customer.displayName,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF2563EB,
                                                          )
                                                        : const Color(
                                                            0xFF111827,
                                                          ),
                                                  ),
                                                ),
                                                if (customer.customerNumber !=
                                                    null) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '| ${customer.customerNumber}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isSelected
                                                          ? const Color(
                                                              0xFF3B82F6,
                                                            )
                                                          : const Color(
                                                              0xFF6B7280,
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  LucideIcons.fileText,
                                                  size: 10,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  customer.email ??
                                                      customer.displayName,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF9CA3AF),
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
                              },
                              onChanged: (val) {
                                setState(() {
                                  _customerDetailsSidebarOverlay?.remove();
                                  _customerDetailsSidebarOverlay = null;
                                  _selectedCustomerId = val;
                                  final customers =
                                      customersAsync.asData?.value ?? [];
                                  final customer = customers.firstWhere(
                                    (c) => c.id == val,
                                    orElse: () => customers.first,
                                  );
                                  _selectedCustomer = customer;
                                  final priceLists =
                                      priceListsAsync.asData?.value ?? [];

                                  for (var row in rows) {
                                    if (row.itemId.isNotEmpty &&
                                        row.item != null) {
                                      _updateRowRate(row, customer, priceLists);
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Green Search Button
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981), // Emerald-500
                              borderRadius: BorderRadius.circular(4),
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
                                      error: (_, __) => 'Currency unavailable',
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
                        child: _buildCustomerAddressSection(_selectedCustomer!),
                      ),
                  ],
                ),
                loading: () => const SharedFieldLayout(
                  label: 'Customer Name',
                  labelWidth: 180,
                  child: Skeleton(height: 44, width: 420),
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
                    value: placeOfSupply ?? _selectedCustomer?.placeOfSupply,
                    items: const [
                      '[KL] - Kerala',
                      '[TN] - Tamil Nadu',
                      '[KA] - Karnataka',
                    ], // Simplified options
                    onChanged: (v) => setState(() => placeOfSupply = v),
                  ),
                ),
              ],
            ],
          ),
        ),

        // This offset compensates for the Matrix translation above
        Transform.translate(
          offset: const Offset(0, -24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        items: const ['Default Transaction Series'],
                        onChanged: (v) {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: salesOrderNumberCtrl,
                        hintText: 'SO-00000',
                        suffixWidget: Tooltip(
                          message:
                              'Click here to enable or disable auto-generation of Sales Order numbers.',
                          preferBelow: false,
                          verticalOffset: 12,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: const ShapeDecoration(
                            color: Color(0xFF1F2937),
                            shape: TooltipShapeBorder(),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.5,
                          ),
                          child: InkWell(
                            onTap: _showSalesOrderPreferencesDialog,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),
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
                maxWidth: 450,
                tooltip:
                    'Use this field to record any transaction numbers related to this transaction such as purchase order numbers.',
                child: CustomTextField(controller: referenceCtrl),
              ),

              // Sales Order Date
              SharedFieldLayout(
                label: 'Sales Order Date',
                required: true,
                labelWidth: 180,
                maxWidth: 450,
                child: CustomDateField(
                  value: salesOrderDate,
                  onSelected: (d) => setState(() => salesOrderDate = d),
                ),
              ),

              // Expected Shipment Date
              SharedFieldLayout(
                label: 'Expected Shipment Date',
                labelWidth: 180,
                maxWidth: 450,
                child: CustomDateField(
                  value: expectedShipmentDate ?? DateTime.now(),
                  onSelected: (d) => setState(() => expectedShipmentDate = d),
                ),
              ),

              // Payment Terms
              SharedFieldLayout(
                label: 'Payment Terms',
                labelWidth: 180,
                maxWidth: 450,
                child: FormDropdown<String>(
                  value: paymentTerms,
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
                  onChanged: (v) => setState(() => paymentTerms = v),
                ),
              ),

              const SizedBox(height: 24),

              // Delivery Method
              SharedFieldLayout(
                label: 'Delivery Method',
                labelWidth: 180,
                maxWidth: 600,
                child: FormDropdown<String>(
                  value: deliveryMethod,
                  hint: 'Select a delivery method or type to add',
                  items: const ['None', 'FedEx', 'UPS', 'DHL', 'Post'],
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
                      width: 180,
                      child: FormDropdown<String>(
                        value: warehouse,
                        items: const ['Main Warehouse', 'Secondary Warehouse'],
                        hint: 'Select Warehouse',
                        onChanged: (v) => setState(() => warehouse = v),
                      ),
                    ),
                    const SizedBox(width: 32),
                    const Text(
                      'Price List',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 180,
                      child: priceListsAsync.when(
                        data: (priceLists) => FormDropdown<String>(
                          value: priceListId,
                          items: priceLists.map((p) => p.id).toList(),
                          displayStringForValue: (id) =>
                              priceLists.firstWhere((p) => p.id == id).name,
                          hint: 'Select Price List',
                          onChanged: (v) {
                            setState(() {
                              priceListId = v;
                              final customers =
                                  customersAsync.asData?.value ?? [];
                              final customer = customers.firstWhere(
                                (c) => c.id == _selectedCustomerId,
                                orElse: () => customers.first,
                              );
                              for (var row in rows) {
                                if (row.itemId.isNotEmpty && row.item != null) {
                                  _updateRowRate(row, customer, priceLists);
                                }
                              }
                            });
                          },
                        ),
                        loading: () => const Skeleton(height: 40, width: 180),
                        error: (_, __) => const SizedBox(),
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
    final taxRates = itemsState.taxRates;

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
                      const Expanded(
                        flex: 14,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: _TH('ITEMS DETAILS'),
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
                          child: _TH('QUANTITY', right: true),
                        ),
                      ),
                      if (_saleType == 'Business') ...[
                        _vLine(),
                        const Expanded(
                          flex: 3,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
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
                              Icon(
                                LucideIcons.layoutGrid,
                                size: 14,
                                color: _kLabelGrey,
                              ),
                            ],
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
                          child: _TH('DISCOUNT', right: true),
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
                          child: _TH(
                            'TAX',
                            tooltip:
                                'Applicable tax for the items. You can select a tax rate from the list.',
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          separatorBuilder: (_, __) => Row(
            children: [
              const Expanded(child: Divider(height: 1, color: _kBorder)),
              const SizedBox(width: 60),
            ],
          ),
          itemBuilder: (ctx, idx) => _buildItemRow(
            idx,
            products,
            customersAsync,
            priceListsAsync,
            taxRates,
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
      ],
    );
  }

  Widget _buildItemRow(
    int idx,
    List<Item> products,
    AsyncValue<List<SalesCustomer>> customersAsync,
    AsyncValue<List<PriceList>> priceListsAsync,
    List<TaxRate> taxRates,
  ) {
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

    return Row(
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
                    const SizedBox(
                      width: 40,
                      child: Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Icon(
                            LucideIcons.gripVertical,
                            size: 16,
                            color: Color(0xFFD1D5DB),
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
                                          hint:
                                              'Type or click to select an item.',
                                          hideBorderDefault: true,
                                          items: products
                                              .map((p) => p.id!)
                                              .toList(),
                                          displayStringForValue: (id) =>
                                              products
                                                  .firstWhere((p) => p.id == id)
                                                  .productName,
                                          onChanged: (v) {
                                            if (v == null) return;
                                            final p = products.firstWhere(
                                              (e) => e.id == v,
                                            );
                                            setState(() {
                                              row.itemId = v;
                                              row.item = p;
                                              if (row.rateCtrl.text == '0' ||
                                                  row.rateCtrl.text.isEmpty) {
                                                row.rateCtrl.text =
                                                    (p.sellingPrice ?? 0)
                                                        .toString();
                                              }
                                              if (row.mrpCtrl.text == '0' ||
                                                  row.mrpCtrl.text.isEmpty) {
                                                row.mrpCtrl.text = (p.mrp ?? 0)
                                                    .toString();
                                              }
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
                              height: 36,
                              hideBorderDefault: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              contentCase: ContentCase.none,
                              textAlign: TextAlign.right,
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
                            height: 36,
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
                              height: 36,
                              hideBorderDefault: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              contentCase: ContentCase.none,
                              textAlign: TextAlign.right,
                              onChanged: (_) => _calculateTotals(),
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
                          height: 36,
                          hideBorderDefault: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          contentCase: ContentCase.none,
                          textAlign: TextAlign.right,
                          padding: const EdgeInsets.only(left: 12, right: 0),
                          suffixSeparator: true,
                          suffixWidget: _buildDiscountTypeSelector(row),
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
                          height: 36,
                          hideBorderDefault: true,
                          hint: 'Tax',
                          items: taxRates.map((t) => t.id).toList(),
                          displayStringForValue: (id) =>
                              taxRates
                                  .where((t) => t.id == id)
                                  .firstOrNull
                                  ?.taxName ??
                              'Select Tax',
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
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (idx > 0)
                InkWell(
                  onTap: () {
                    setState(() {
                      rows.removeAt(idx);
                    });
                    _calculateTotals();
                  },
                  child: const Icon(LucideIcons.x, size: 16, color: Colors.red),
                ),
            ],
          ),
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
            width: 44,
            height: 44,
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
                  _buildIconAction(
                    LucideIcons.moreHorizontal,
                    size: 14,
                    onTap: () {
                      context.push('/items/create', extra: item);
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildIconAction(
                    LucideIcons.x,
                    size: 14,
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
              if (_showAdditionalInfo) ...[
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
              if (_showAdditionalInfo) ...[
                const SizedBox(height: 8),
                _buildDescriptionField(row.descriptionCtrl),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportingTags(SalesOrderItemRow row) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              onTap: () {
                // TODO: Implement Reporting Tags Overlay
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.tag,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Reporting Tags',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            CompositedTransformTarget(
              link: row.warehouseLink,
              child: InkWell(
                onTap: () => _toggleWarehouseOverlay(row),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.home,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Warehouse',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronDown,
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
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: color?.withValues(alpha: 0.3) ?? const Color(0xFFD3D3D3),
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size, color: color ?? const Color(0xFF808080)),
      ),
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
            // Left Column: Buttons + Notes
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Buttons Row
                  Row(
                    children: [
                      _buildAddRowButton(),
                      const SizedBox(width: 12),
                      _buildBulkAddButton(products),
                    ],
                  ),
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
            const SizedBox(width: 48),
            // Right Column: Totals
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
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
                    _summaryRadioRow(),
                    const SizedBox(height: 16),
                    _summaryInputRow(
                      'Adjustment',
                      adjustmentCtrl,
                      isAdjustment: true,
                      tooltip:
                          'Add any other +ve or -ve charges that need to be applied to adjust the total amount of the transaction Eg. +10 or -10.',
                    ),
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
          ],
        ),
        const SizedBox(height: 48),
        // Bottom Row: Terms & Attachment
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
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
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              flex: 4,
              child: Column(
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
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddRowButton() {
    return CompositedTransformTarget(
      link: _addRowLink,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _addItemRow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.plusCircle,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add New Row',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              color: Color(0xFFD1D5DB),
              thickness: 1,
              indent: 8,
              endIndent: 8,
            ),
            InkWell(
              onTap: _toggleAddRowOverlay,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
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
                child: InkWell(
                  onTap: () {
                    // Implement Add New Header logic
                    setState(() {
                      rows.add(
                        SalesOrderItemRow(
                          quantityCtrl: TextEditingController(text: '0'),
                          rateCtrl: TextEditingController(text: '0'),
                          discountCtrl: TextEditingController(text: '0'),
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
                selectedItems.forEach((item, quantity) {
                  rows.add(
                    SalesOrderItemRow(
                      quantityCtrl: TextEditingController(
                        text: quantity.toString(),
                      ),
                      rateCtrl: TextEditingController(
                        text: (item.sellingPrice ?? 0).toString(),
                      ),
                      discountCtrl: TextEditingController(text: '0'),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plusCircle, size: 18, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text(
              'Add Items in Bulk',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
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
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    // Handle direct upload
                  },
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
        const SizedBox(height: 8),
        const Text(
          'You can upload a maximum of 10 files, 5MB each',
          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
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
                    _buildUploadItem('Attach From Cloud', false),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCloudIcon(
                            LucideIcons.folder,
                            const Color(0xFF6B7280),
                          ),
                          _buildCloudIcon(
                            FontAwesomeIcons.evernote,
                            const Color(0xFF10B981),
                          ),
                          _buildCloudIcon(
                            FontAwesomeIcons.googleDrive,
                            const Color(0xFFFBBF24),
                          ),
                          _buildCloudIcon(
                            FontAwesomeIcons.box,
                            const Color(0xFF3B82F6),
                          ),
                          _buildCloudIcon(
                            FontAwesomeIcons.dropbox,
                            const Color(0xFF2563EB),
                          ),
                          _buildCloudIcon(
                            LucideIcons.cloud,
                            const Color(0xFF0EA5E9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
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
          onTap: () {
            _uploadOverlay?.remove();
            _uploadOverlay = null;
            if (mounted) setState(() {});
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : (isHovered ? const Color(0xFFF9FAFB) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        );
      },
    );
  }

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
    String? tooltip,
  }) {
    return Row(
      children: [
        Expanded(
          child: isAdjustment
              ? CustomPaint(
                  painter: _DashedBorderPainter(color: const Color(0xFFD1D5DB)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kBodyText,
                      ),
                    ),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kBodyText,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          height: 44,
          child: CustomTextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        if (tooltip != null)
          Tooltip(
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
          )
        else
          const Icon(Icons.help_outline, size: 16, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 24),
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
  }

  Widget _summaryRadioRow() {
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
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 44,
            child: FormDropdown<String>(
              value: _selectedTdsId,
              hint: 'Select a Tax',
              items: const [],
              displayStringForValue: (v) => v,
              onChanged: (v) => setState(() => _selectedTdsId = v),
            ),
          ),
        ),
        const SizedBox(width: 24),
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
            child: const Text('Save as Draft'),
          ),
          const SizedBox(width: 12),
          // Split Button: Save and Send
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981), // Emerald-500
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _saveSalesOrder(status: 'sent'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Save and Send',
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
          ),
        )
        .toList();

    final order = SalesOrder(
      id: '',
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
    );

    try {
      await ref
          .read(salesOrderControllerProvider.notifier)
          .createSalesOrder(order);
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/sales/orders');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            color: showHighlight ? Colors.white : _kBodyText.withValues(alpha: 0.8),
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
              width: 320, // Increased width to accommodate both links
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
                showDropshipping: true,
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
    bool showDropshipping = false,
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
              if (showDropshipping) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () =>
                      _showAddressDialog(title: 'Drop Shipping Address'),
                  child: const Text(
                    '+ Dropshipping Address',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
        final isDropshipping = title.contains('Drop Shipping');
        final c = _selectedCustomer;
        final initialAddress = {
          'companyName': isDropshipping ? '' : c?.companyName,
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
              if (isDropshipping) {
                _selectedCustomer = _selectedCustomer?.copyWith(
                  companyName: val['companyName'],
                  shippingAddressStreet1: val['street1'],
                  shippingAddressStreet2: val['street2'],
                  shippingAddressCity: val['city'],
                  shippingAddressStateId: val['state'],
                  shippingAddressZip: val['zip'],
                  shippingAddressCountryId: val['country'],
                  shippingAddressPhone: val['phone'],
                );
              } else if (isBilling) {
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
                                  LucideIcons.chevronUp,
                                  size: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 4),
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
                                final newRow = SalesOrderItemRow(
                                  quantityCtrl: TextEditingController(
                                    text: '1',
                                  ),
                                  rateCtrl: TextEditingController(text: '0'),
                                  discountCtrl: TextEditingController(
                                    text: '0',
                                  ),
                                );
                                if (row.item != null) {
                                  newRow.itemId = row.itemId;
                                  newRow.item = row.item;
                                  newRow.rateCtrl.text = row.rateCtrl.text;
                                  newRow.quantityCtrl.text =
                                      row.quantityCtrl.text;
                                  newRow.discountCtrl.text =
                                      row.discountCtrl.text;
                                  newRow.mrpCtrl.text = row.mrpCtrl.text;
                                  newRow.fQtyCtrl.text = row.fQtyCtrl.text;
                                }
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
                                  SalesOrderItemRow(
                                    quantityCtrl: TextEditingController(
                                      text: '1',
                                    ),
                                    rateCtrl: TextEditingController(text: '0'),
                                    discountCtrl: TextEditingController(
                                      text: '0',
                                    ),
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

    final hsnCtrl = TextEditingController(
      text: row.item?.hsnCode ?? '',
    );
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

  void _toggleWarehouseOverlay(SalesOrderItemRow row) {
    if (_warehouseOverlay != null) {
      _warehouseOverlay?.remove();
      _warehouseOverlay = null;
      setState(() {});
      return;
    }

    _warehouseOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _warehouseOverlay?.remove();
                _warehouseOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: row.warehouseLink,
            showWhenUnlinked: false,
            offset: const Offset(-20, 24),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
                color: Colors.white,
                child: const Center(child: Text('Warehouse Popup')),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_warehouseOverlay!);
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    final dialogTitle = widget.title == 'Drop Shipping Address'
        ? 'Drop Shipping Address'
        : widget.title.contains('BILLING')
        ? 'Billing Address'
        : widget.title.contains('SHIPPING')
        ? 'Shipping Address'
        : widget.title;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
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
                              height: 36,
                              value: _selectedCountry,
                              hint: 'Select',
                              isLoading: countriesAsync.isLoading,
                              items: countries,
                              displayStringForValue: (c) => c['name'] ?? '',
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
                                        height: 36,
                                        value: _selectedState,
                                        hint: 'Select or type to add',
                                        isLoading: statesAsync.isLoading,
                                        items: states,
                                        displayStringForValue: (s) =>
                                            s['name'] ?? '',
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
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFFD1D5DB),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: DropdownButton<String>(
                                          value: _phoneCode,
                                          underline: const SizedBox(),
                                          isDense: true,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _kBodyText,
                                          ),
                                          items: _phoneCodes
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c,
                                                  child: Text(c),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) =>
                                              setState(() => _phoneCode = v!),
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
                                text: dialogTitle == 'Drop Shipping Address'
                                    ? 'This address will be used only in the current transaction.'
                                    : 'Changes made here will be updated for this customer.',
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
                      height: 40,
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

    if (isSelected) {
      bg = const Color(0xFF3B82F6);
      title = Colors.white;
      subtitle = Colors.white70;
      check = Colors.white;
    } else if (isHovered) {
      bg = const Color(0xFFEFF6FF);
      title = const Color(0xFF1D4ED8);
      subtitle = const Color(0xFF1D4ED8);
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
              color: isActive
                  ? const Color(0xFF2563EB)
                  : Colors.transparent,
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

  Widget _detailRow({
    required String label,
    required Widget value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 165,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
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
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
                                bottom: entry.key == contacts.length - 1 ? 0 : 10,
                              ),
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
                                    _contactDisplayName(entry.value),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if ((entry.value.email ?? '').trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      entry.value.email!.trim(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                  if ((entry.value.mobilePhone ?? '').trim().isNotEmpty ||
                                      (entry.value.workPhone ?? '').trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      (entry.value.mobilePhone ?? '').trim().isNotEmpty
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
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final customerCode = (c.customerNumber ?? '').isNotEmpty
        ? c.customerNumber!
        : c.displayName;
    final customerName = c.displayName.isNotEmpty ? c.displayName : customerCode;
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
            child: _activeTabIndex == 0 ? _buildDetailsTab() : _buildActivityTab(),
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
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
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
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

