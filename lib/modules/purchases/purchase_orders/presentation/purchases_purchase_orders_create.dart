import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/providers/purchases_purchase_orders_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/items/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/modules/sales/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/accountant/providers/accountant_chart_of_accounts_provider.dart';

import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/items/items/presentation/widgets/item_details_sidebar.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import '../notifiers/purchase_order_notifier.dart';
import 'package:zerpai_erp/modules/inventory/providers/stock_provider.dart';

// ── Zoho-style Colors ────────────────────────────────────────────────────────
const _bgWhite = Color(0xFFFFFFFF);
const _borderCol = Color(0xFFE8E8E8);
const _fieldBorder = Color(0xFFCCCCCC);
const _labelColor = Color(0xFF333333);
const _requiredLabel = Color(0xFFE04646);
const _hintColor = Color(0xFF999999);
const _textPrimary = Color(0xFF333333);
const _linkBlue = Color(0xFF2A95BF);
const _greenBtn = Color(0xFF19A05E);
const _dangerRed = Color(0xFFD32F2F);

// ── Extension ────────────────────────────────────────────────────────────────

// ── Row Controller ───────────────────────────────────────────────────────────
class _ItemRowController {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final FocusNode rateFocus = FocusNode();
  final LayerLink nameLink = LayerLink();
  final LayerLink taxLink = LayerLink();
  final LayerLink accountLink = LayerLink();
  final LayerLink discountLink = LayerLink();
  final LayerLink discountTypeLink = LayerLink();
  final LayerLink itemDiscountAccountLink = LayerLink();
  final LayerLink warehouseSelectionLink = LayerLink();
  final LayerLink hsnLink = LayerLink();
  final LayerLink itemMenuLink = LayerLink();

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    rateCtrl.dispose();
    discountCtrl.dispose();
    descCtrl.dispose();
    rateFocus.dispose();
  }
}

// ── Address line helper ───────────────────────────────────────────────────────
class _AddrLine {
  final String text;
  final bool isBold;
  final bool isCity; // shown in reddish color inside the popover
  final bool isPhone; // shown in dark/label color
  const _AddrLine(
    this.text, {
    this.isBold = false,
    this.isCity = false,
    this.isPhone = false,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class PurchaseOrderCreateScreen extends ConsumerStatefulWidget {
  const PurchaseOrderCreateScreen({super.key});
  @override
  ConsumerState<PurchaseOrderCreateScreen> createState() => _POCreateState();
}

class _POCreateState extends ConsumerState<PurchaseOrderCreateScreen> {
  final _poNumberCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _orderDateCtrl = TextEditingController();
  final _deliveryDateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _adjustmentCtrl = TextEditingController();
  final _deliveryNameCtrl = TextEditingController(); // Editable warehouse name
  final GlobalKey _orderDateFieldKey = GlobalKey();
  final GlobalKey _deliveryDateFieldKey = GlobalKey();

  OverlayEntry? _gstOverlay;
  OverlayEntry? _poOverlay;
  OverlayEntry? _vendorSidebarOverlay;
  OverlayEntry? _deliveryOverlay; // "Change destination" popover
  OverlayEntry? _taxOverlay;
  OverlayEntry? _accountOverlay;
  OverlayEntry? _discountOverlay;
  OverlayEntry? _warehouseOverlay;
  OverlayEntry? _hsnOverlay;
  OverlayEntry? _addRowDropdownOverlay;
  final LayerLink _addRowDropdownLink = LayerLink();
  OverlayEntry? _itemMenuOverlay;
  final LayerLink _gstLink = LayerLink();
  final LayerLink _poLink = LayerLink();
  final LayerLink _deliveryChangeLink = LayerLink();
  final List<_ItemRowController> _rowControllers = [];
  final Set<int> _hiddenDetails = {};
  final Map<int, TextEditingController> _headerTextControllers = {};
  bool _bulkMode = false;
  final Set<int> _selectedRows = {};
  String _stockView = 'availableForSale'; // 'stockOnHand' | 'availableForSale'
  bool _showStockInfo = true;
  bool _showRecentTransactions = true;
  bool _showPriceList = true;
  
  // Lookup lists
  List<Map<String, dynamic>> _paymentTermsList = [];
  List<Map<String, dynamic>> _shipmentPreferencesList = [];
  List<Map<String, dynamic>> _countriesList = [];
  List<String> _sourceOfSupplyList = [];
  List<String> _phoneCodesList = [];
  Map<String, String> _phoneCodeToLabel = {};

  Future<void> _loadPaymentTerms() async {
    try {
      final lookupsService = LookupsApiService();
      final terms = await lookupsService.getPaymentTerms();
      if (mounted) {
        setState(() {
          _paymentTermsList = terms;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading payment terms', error: e, module: 'purchases');
    }
  }

  Future<void> _loadShipmentPreferences() async {
    try {
      final lookupsService = LookupsApiService();
      final preferences = await lookupsService.getShipmentPreferences();
      if (mounted) {
        setState(() {
          _shipmentPreferencesList = preferences;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading shipment preferences', error: e, module: 'purchases');
    }
  }

  Future<void> _handleSave(
    PurchaseOrderState poState, {
    String status = 'Draft',
  }) async {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    // Basic validation
    if (poState.vendorId == null || poState.vendorId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a vendor')));
      return;
    }

    if (poState.items.every((i) => i.productId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    notifier.updateField(isSaving: true);

    try {
      final lookupsService = LookupsApiService();

      // 1. Sync Shipment Preference if it's new
      if (poState.shipmentPreference != null &&
          poState.shipmentPreference!.isNotEmpty) {
        final exists = _shipmentPreferencesList.any(
          (p) =>
              p['name']?.toString().toLowerCase() ==
              poState.shipmentPreference!.toLowerCase(),
        );

        if (!exists) {
          AppLogger.info('Saving new global shipment preference', data: {'value': poState.shipmentPreference}, module: 'purchases');
          await lookupsService.syncShipmentPreferences([
            {'name': poState.shipmentPreference, 'is_active': true},
          ]);
          await _loadShipmentPreferences();
        }
      }

      // 2. Prepare PO Model
      final po = PurchaseOrder(
        orderNumber: poState.orderNumber,
        orderDate: poState.orderDate,
        expectedDeliveryDate: poState.expectedDeliveryDate,
        referenceNumber: poState.referenceNumber,
        vendorId: poState.vendorId!,
        paymentTerms: poState.paymentTerms,
        shipmentPreference: poState.shipmentPreference,
        deliveryType: poState.deliveryType,
        deliveryWarehouseId: poState.deliveryWarehouseId,
        deliveryCustomerId: poState.deliveryCustomerId,
        warehouseId: poState.warehouseId,
        subTotal: poState.subTotal,
        taxAmount: poState.taxAmount,
        discount: poState.discount,
        discountType: poState.discountType,
        tdsTcsType: poState.tdsTcsType ?? 'none',
        tdsTcsId: poState.tdsTcsId,
        adjustment: poState.adjustment,
        total: poState.total,
        status: status,
        notes: _notesCtrl.text,
        termsAndConditions: _termsCtrl.text,
        isReverseCharge: poState.isReverseCharge,
        discountLevel: poState.discountLevel,
        items: poState.items.where((i) => i.productId.isNotEmpty).toList(),
      );

      // 3. Save to Backend
      final repository = ref.read(purchaseOrderRepositoryProvider);
      await repository.createPurchaseOrder(po);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase Order saved successfully'),
            backgroundColor: _greenBtn,
          ),
        );
        context.pop(); // Go back to list
      }
    } catch (e) {
      AppLogger.error('Error saving purchase order', error: e, module: 'purchases');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PO: $e'),
            backgroundColor: _dangerRed,
          ),
        );
      }
    } finally {
      notifier.updateField(isSaving: false);
    }
  }

  Future<void> _showConfigurePaymentTermsDialog(
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => ManagePaymentTermsDialog(
        items: _paymentTermsList,
        selectedId: poState.paymentTerms,
        onSelect: (term) {
          notifier.updateField(paymentTerms: term['id']);
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncPaymentTerms(items);

          if (mounted) {
            setState(() {
              _paymentTermsList = updated;
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
              'payment-terms',
              item['id'].toString(),
            );

            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This payment term is in use and cannot be deleted.';
            }
          } catch (e) {
            AppLogger.error('Error checking payment term usage', error: e, module: 'purchases');
          }
          return null;
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _orderDateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _discountCtrl.text = '0';
    _adjustmentCtrl.text = '0';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load vendors on init
      ref.read(vendorProvider.notifier).loadVendors();
      _loadCountries();
      _loadPhoneCodes();
      _loadSourceOfSupply();
      _loadPaymentTerms();
      _loadShipmentPreferences();
      final s = ref.read(purchaseOrderFormNotifierProvider);
      for (int i = 0; i < s.items.length; i++) {
        final item = s.items[i];
        _addRowController(
          initialName: item.productName,
          initialQty: item.quantity,
          initialRate: item.rate,
          initialDiscount: item.discount,
          initialDesc: item.description,
        );
      }
    });
  }

  _ItemRowController _makeRowController({
    String? initialName,
    double? initialQty,
    double? initialRate,
    double? initialDiscount,
    String? initialDesc,
  }) {
    final ctrl = _ItemRowController();
    if (initialName != null) ctrl.nameCtrl.text = initialName;
    if (initialDesc != null) ctrl.descCtrl.text = initialDesc;
    if (initialQty != null) {
      ctrl.qtyCtrl.text = initialQty.toStringAsFixed(
        initialQty % 1 == 0 ? 0 : 2,
      );
    }
    if (initialRate != null) {
      ctrl.rateCtrl.text = initialRate.toStringAsFixed(2);
    }
    if (initialDiscount != null) {
      ctrl.discountCtrl.text = initialDiscount.toStringAsFixed(2);
    }
    ctrl.rateFocus.addListener(() {
      if (!ctrl.rateFocus.hasFocus) {
        _handleRateCalculation(ctrl);
      }
    });
    return ctrl;
  }

  void _addRowController({
    int? index,
    String? initialName,
    double? initialQty,
    double? initialRate,
    double? initialDiscount,
    String? initialDesc,
  }) {
    final ctrl = _makeRowController(
      initialName: initialName,
      initialQty: initialQty,
      initialRate: initialRate,
      initialDiscount: initialDiscount,
      initialDesc: initialDesc,
    );
    if (index != null && index <= _rowControllers.length) {
      setState(() => _rowControllers.insert(index, ctrl));
    } else {
      setState(() => _rowControllers.add(ctrl));
    }
  }

  void _handleRateCalculation(_ItemRowController ctrl) {
    final text = ctrl.rateCtrl.text.trim();
    if (text.isEmpty) return;

    // Only try to parse if it contains operators
    if (text.contains(RegExp(r'[+\-*/()]'))) {
      final double? result = _evaluateExpression(text);
      if (result != null) {
        ctrl.rateCtrl.text = result.toStringAsFixed(2);
        // Find index to update notifier
        final index = _rowControllers.indexOf(ctrl);
        if (index != -1) {
          final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
          final poState = ref.read(purchaseOrderFormNotifierProvider);
          if (index < poState.items.length) {
            notifier.updateItem(
              index,
              poState.items[index].copyWith(rate: result),
            );
          }
        }
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

  @override
  void dispose() {
    _poNumberCtrl.dispose();
    _refCtrl.dispose();
    _orderDateCtrl.dispose();
    _deliveryDateCtrl.dispose();
    _notesCtrl.dispose();
    _termsCtrl.dispose();
    _discountCtrl.dispose();
    _adjustmentCtrl.dispose();
    _deliveryNameCtrl.dispose();
    for (var c in _rowControllers) {
      c.dispose();
    }
    _closeGstOverlay();
    _closePoOverlay();
    _closeVendorSidebar();
    _closeDeliveryOverlay();
    super.dispose();
  }

  void _toggleAddRowDropdown(dynamic notifier) {
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
                  border: Border.all(color: _borderCol),
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
                    notifier.addHeaderRow();
                    setState(() => _rowControllers.add(_makeRowController()));
                    _addRowDropdownOverlay?.remove();
                    _addRowDropdownOverlay = null;
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline, size: 14, color: _linkBlue),
                        SizedBox(width: 8),
                        Text(
                          'Add New Header',
                          style: TextStyle(
                            fontSize: 13,
                            color: _linkBlue,
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

  void _showItemMenu(
    BuildContext context,
    int index,
    PurchaseOrderItem item,
    LayerLink link,
  ) {
    _itemMenuOverlay?.remove();
    _itemMenuOverlay = null;

    _itemMenuOverlay = OverlayEntry(
      builder: (ctx) => Stack(
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
                  border: Border.all(color: _borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Edit Item — blue outlined button
                      InkWell(
                        onTap: () {
                          _itemMenuOverlay?.remove();
                          _itemMenuOverlay = null;
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF0088FF)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 14, color: Color(0xFF0088FF)),
                              SizedBox(width: 8),
                              Text(
                                'Edit Item',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF0088FF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // View Item Details — plain
                      InkWell(
                        onTap: () {
                          _itemMenuOverlay?.remove();
                          _itemMenuOverlay = null;
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.store_outlined, size: 14, color: _labelColor),
                              SizedBox(width: 8),
                              Text(
                                'View Item Details',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _labelColor,
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
    Overlay.of(context).insert(_itemMenuOverlay!);
  }

  void _closeGstOverlay() {
    _gstOverlay?.remove();
    _gstOverlay = null;
  }

  void _closePoOverlay() {
    _poOverlay?.remove();
    _poOverlay = null;
  }

  void _closeVendorSidebar() {
    _vendorSidebarOverlay?.remove();
    _vendorSidebarOverlay = null;
  }

  void _closeDeliveryOverlay() {
    _deliveryOverlay?.remove();
    _deliveryOverlay = null;
  }

  Future<void> _loadPhoneCodes() async {
    // Basic codes - in a real app, load from countries list
    setState(() {
      _phoneCodesList = ['+91', '+1', '+44', '+971', '+65'];
      _phoneCodeToLabel = {
        '+91': 'India',
        '+1': 'USA',
        '+44': 'UK',
        '+971': 'UAE',
        '+65': 'Singapore',
      };
    });
  }

  Future<void> _loadCountries() async {
    try {
      final lookupsService = LookupsApiService();
      final countries = await lookupsService.getCountries();
      if (mounted) {
        setState(() {
          countries.sort((a, b) {
            if (a['name'] == 'India') return -1;
            if (b['name'] == 'India') return 1;
            return (a['name'] as String).compareTo(b['name'] as String);
          });
          _countriesList = countries;
          final codes = countries
              .map((c) => c['phone_code']?.toString())
              .where((c) => c != null && c.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();

          if (codes.isNotEmpty) {
            codes.sort((a, b) {
              if (a == '+91') return -1;
              if (b == '+91') return 1;
              return a.compareTo(b);
            });
            _phoneCodesList = codes;
          }

          final labels = <String, String>{};
          for (var c in countries) {
            final code = c['phone_code']?.toString();
            final name = c['name']?.toString();
            if (code != null && name != null) {
              labels[code] = name;
            }
          }
          _phoneCodeToLabel = labels;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading countries/phone codes', error: e, module: 'purchases');
    }
  }

  Future<void> _loadSourceOfSupply() async {
    try {
      final lookupsService = LookupsApiService();
      final states = await lookupsService.getStates('IN'); // India
      if (mounted && states.isNotEmpty) {
        setState(() {
          _sourceOfSupplyList = states.map((s) {
            final code = s['code']?.toString() ?? '';
            final name = s['name']?.toString() ?? '';
            return '[$code] - $name';
          }).toList();
        });
      }
    } catch (e) {
      AppLogger.error('Error loading source of supply states', error: e, module: 'purchases');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final poState = ref.watch(purchaseOrderFormNotifierProvider);
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    final vendorState = ref.watch(vendorProvider);
    final vendors = vendorState.vendors;
    final customers = ref.watch(salesCustomersProvider).value ?? [];
    final warehouses = ref.watch(warehousesProvider).value ?? [];
    final itemsState = ref.watch(itemsControllerProvider);
    final allItems = itemsState.items;

    final accountsState = ref.watch(chartOfAccountsProvider);
    final List<AccountNode> availableAccounts = [];
    void collect(List<AccountNode> nodes) {
      for (final node in nodes) {
        availableAccounts.add(node);
        collect(node.children);
      }
    }

    collect(accountsState.roots);

    final orderDateText = DateFormat('dd-MM-yyyy').format(poState.orderDate);
    if (_orderDateCtrl.text != orderDateText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _orderDateCtrl.text = orderDateText;
      });
    }

    final deliveryDateText = poState.expectedDeliveryDate != null
        ? DateFormat('dd-MM-yyyy').format(poState.expectedDeliveryDate!)
        : '';
    if (_deliveryDateCtrl.text != deliveryDateText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _deliveryDateCtrl.text = deliveryDateText;
      });
    }

    // Initial load sync for Order Number controller
    if (_poNumberCtrl.text != poState.orderNumber) {
      // Use post frame to avoid build loops
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _poNumberCtrl.text = poState.orderNumber;
      });
    }

    // Set default warehouse when data is loaded
    ref.listen<AsyncValue<List<WarehouseModel>>>(warehousesProvider, (
      prev,
      next,
    ) {
      if (next.hasValue && next.value!.isNotEmpty) {
        final currentPoState = ref.read(purchaseOrderFormNotifierProvider);
        if (currentPoState.deliveryType == 'warehouse' &&
            (currentPoState.deliveryWarehouseId == null ||
                currentPoState.deliveryWarehouseId!.isEmpty)) {
          final firstWh = next.value!.first;
          ref
              .read(purchaseOrderFormNotifierProvider.notifier)
              .updateField(
                deliveryWarehouseId: firstWh.id,
                deliveryAddressName: firstWh.name,
              );
          // Small delay to ensure controller is available if needed
          Future.microtask(() {
            _deliveryNameCtrl.text = firstWh.name;
          });
        }
      }
    });

    // Also check for already loaded state
    final warehouseState = ref.watch(warehousesProvider);
    if (!warehouseState.isLoading &&
        !warehouseState.hasError &&
        warehouseState.value != null &&
        warehouseState.value!.isNotEmpty) {
      final currentPoState = ref.read(purchaseOrderFormNotifierProvider);
      if (currentPoState.deliveryType == 'warehouse' &&
          (currentPoState.deliveryWarehouseId == null ||
              currentPoState.deliveryWarehouseId!.isEmpty)) {
        final firstWh = warehouseState.value!.first;
        // We shouldn't do side effects directly in build, so we'll use a post-frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(purchaseOrderFormNotifierProvider.notifier)
                .updateField(
                  deliveryWarehouseId: firstWh.id,
                  deliveryAddressName: firstWh.name,
                );
            _deliveryNameCtrl.text = firstWh.name;
          }
        });
      }
    }

    return ZerpaiLayout(
      pageTitle: 'New Purchase Order',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      footer: _stickyFooter(poState),
      endDrawer: const ItemDetailsSidebar(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── FORM SECTION ──
          _buildFormSection(vendors, customers, warehouses, poState),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // ── WAREHOUSE ──
                _zFormRow(
                  label: 'Warehouse',
                  child: SizedBox(
                    width: 320,
                    child: FormDropdown<String>(
                      height: 36,
                      value: poState.warehouseId,
                      items: warehouses.map((w) => w.id).toList(),
                      displayStringForValue: (id) => warehouses
                          .firstWhere(
                            (w) => w.id == id,
                            orElse: () => WarehouseModel(
                              id: '',
                              name: 'Not selected',
                              countryRegion: '',
                            ),
                          )
                          .name,
                      hint: 'Select Warehouse',
                      onChanged: (id) => notifier.updateField(warehouseId: id),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _fieldBorder),
                      itemBuilder: (id, isSelected, isHovered) =>
                          _buildStandardLookupRow(
                            warehouses
                                .firstWhere(
                                  (w) => w.id == id,
                                  orElse: () => WarehouseModel(
                                    id: '',
                                    name: '',
                                    countryRegion: '',
                                  ),
                                )
                                .name,
                            isSelected,
                            isHovered,
                          ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),
                // ── DISCOUNT TYPE SELECTION ──
                _zFormRow(
                  label: 'Discount',
                  child: Row(
                    children: [
                      SizedBox(
                        width: 180,
                        child: FormDropdown<String>(
                          height: 36,
                          value: poState.discountLevel,
                          items: const ['transaction', 'item'],
                          displayStringForValue: (v) => v == 'transaction'
                              ? 'At Transaction Level'
                              : 'At Line Item Level',
                          onChanged: (v) =>
                              notifier.updateField(discountLevel: v),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _fieldBorder),
                          itemBuilder: (id, isSelected, isHovered) =>
                              _buildStandardLookupRow(
                                id == 'transaction'
                                  ? 'At Transaction Level'
                                  : 'At Line Item Level',
                                isSelected,
                                isHovered,
                              ),
                        ),
                      ),
                      if (poState.discountLevel == 'item') ...[
                        const SizedBox(width: 12),
                        Container(width: 1, height: 24, color: _borderCol),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 280,
                          child: FormDropdown<AccountNode>(
                            height: 36,
                            value: availableAccounts.firstWhere(
                              (a) => a.id == poState.discountAccountId,
                              orElse: () => const AccountNode(
                                id: '',
                                systemAccountName: '',
                                userAccountName: '',
                                name: '',
                                accountGroup: '',
                                accountType: '',
                                isSystem: false,
                                isDeletable: true,
                                isActive: true,
                              ),
                            ),
                            items: availableAccounts.where((node) {
                              final group = node.accountGroup.toLowerCase();
                              return group.contains('expense') || group.contains('cost of goods sold');
                            }).toList(),
                            displayStringForValue: (a) => a.name.isEmpty ? 'Select Discount Account' : a.name,
                            onChanged: (v) => notifier.updateField(discountAccountId: v?.id),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _fieldBorder),
                            itemBuilder: (account, isSelected, isHovered) =>
                                _buildStandardLookupRow(
                                  account.name,
                                  isSelected,
                                  isHovered,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                ),
                const SizedBox(height: 16),
                // ── ITEM TABLE ──
                _itemTableSection(allItems, availableAccounts, poState),
                const SizedBox(height: 16),
                // ── NOTES (left) + TOTALS (right) — Zoho style ──
                _notesAndTotals(allItems, poState),
                const SizedBox(height: 24),
                // ── TERMS & CONDITIONS + FILE UPLOAD ──
                _termsAndFileRow(),
                const SizedBox(height: 32),
                // ── ADDITIONAL FIELDS INFO ──
                Text(
                  'Additional Fields: Start adding custom fields for your purchase orders by going to Settings ⇒ Purchases ⇒ Purchase Orders.',
                  style: TextStyle(fontSize: 12, color: _hintColor),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM SECTION (Zoho-style flat layout)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFormSection(
    List<Vendor> vendors,
    List<SalesCustomer> customers,
    List<WarehouseModel> warehouses,
    PurchaseOrderState poState,
  ) {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    final selectedVendor = vendors.firstWhere(
      (v) => v.id == poState.vendorId,
      orElse: () => Vendor(id: '', displayName: ''),
    );
    final hasVendor = selectedVendor.id.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasVendor)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F8FE), // Zoho brand light blue background
              border: Border.symmetric(
                horizontal: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildVendorSelectionRow(
                    selectedVendor,
                    vendors,
                    hasVendor,
                    notifier,
                  ),
                ),
                _vendorInfoSection(selectedVendor, poState, notifier),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildVendorSelectionRow(
                selectedVendor,
                vendors,
                hasVendor,
                notifier,
              ),
            ),
          ),
        if (!hasVendor) const SizedBox(height: 20),
        // ── Rest of the top form fields ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Delivery Address ──
              _zFormRow(
                label: 'Delivery Address',
                isRequired: true,
                crossStart: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _zRadio(
                          'Warehouses',
                          'warehouse',
                          poState.deliveryType,
                          (v) => notifier.updateField(deliveryType: v),
                        ),
                        const SizedBox(width: 16),
                        _zRadio(
                          'Customer',
                          'customer',
                          poState.deliveryType,
                          (v) => notifier.updateField(deliveryType: v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _deliverySection(warehouses, customers, poState),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Purchase Order# ──
              _zFormRow(
                label: 'Purchase Order#',
                isRequired: true,
                child: Row(
                  children: [
                    SizedBox(
                      width: 180,
                      child: FormDropdown<String>(
                        height: 36,
                        value: 'Default Transaction Series',
                        items: const ['Default Transaction Series'],
                        onChanged: (v) {},
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _fieldBorder),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 140,
                      child: _zField(
                        _poNumberCtrl,
                        hint: poState.isNumberingAuto ? 'PO-00023' : '',
                        readOnly: poState.isNumberingAuto,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 30,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.settings_outlined,
                          size: 16,
                          color: _linkBlue,
                        ),
                        onPressed: () =>
                            _showNumberingPreferences(poState, notifier),
                        splashRadius: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── Reference ──
              _zFormRow(
                label: 'Reference#',
                child: SizedBox(width: 320, child: _zField(_refCtrl)),
              ),
              const SizedBox(height: 12),
              // ── Date ──
              _zFormRow(
                label: 'Date',
                isRequired: true,
                child: SizedBox(
                  width: 320,
                  child: _zDateField(
                    controller: _orderDateCtrl,
                    targetKey: _orderDateFieldKey,
                    value: poState.orderDate,
                    onSelected: (date) => notifier.updateField(orderDate: date),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Delivery Date + Payment Terms ──
              _zFormRow(
                label: 'Delivery Date',
                child: Row(
                  children: [
                    SizedBox(
                      width: 320,
                      child: _zDateField(
                        controller: _deliveryDateCtrl,
                        targetKey: _deliveryDateFieldKey,
                        value: poState.expectedDeliveryDate,
                        hint: 'dd-MM-yyyy',
                        onSelected: (date) =>
                            notifier.updateField(expectedDeliveryDate: date),
                      ),
                    ),
                    const SizedBox(width: 48),
                    Text(
                      'Payment Terms',
                      style: TextStyle(fontSize: 13, color: _labelColor),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 220,
                      child: FormDropdown<String>(
                        height: 36,
                        value: poState.paymentTerms,
                        items: _paymentTermsList
                            .map((t) => t['id'] as String)
                            .toList(),
                        hint: 'Select Terms',
                        showSettings: true,
                        settingsLabel: 'Configure Terms',
                        onSettingsTap: () =>
                            _showConfigurePaymentTermsDialog(poState, notifier),
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
                            orElse: () => {'term_name': ''},
                          );
                          return _buildStandardLookupRow(
                            term['term_name'] ?? '',
                            isSelected,
                            isHovered,
                          );
                        },
                        onChanged: (v) => notifier.updateField(paymentTerms: v),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _fieldBorder),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── Shipment Preference ──
              _zFormRow(
                label: 'Shipment Preference',
                child: SizedBox(
                  width: 320,
                  child: FormDropdown<String>(
                    height: 36,
                    value: poState.shipmentPreference,
                    items: _shipmentPreferencesList
                        .map((p) => p['name'] as String)
                        .toList(),
                    hint: 'Choose the shipment preference or type to add',
                    allowCustomValue: true,
                    iconSize: 12,
                    onChanged: (v) =>
                        notifier.updateField(shipmentPreference: v),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _fieldBorder),
                    itemBuilder: (item, isSelected, isHovered) =>
                        _buildStandardLookupRow(item, isSelected, isHovered),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _reverseChargeCheckbox(poState, notifier),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  void _showNumberingPreferences(
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isAuto = poState.isNumberingAuto;
        final prefixCtrl = TextEditingController(text: poState.poPrefix);
        final nextNumCtrl = TextEditingController(
          text: poState.poNextNumber.toString().padLeft(poState.poPadding, '0'),
        );
        bool restartMonthly = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Container(
                width: 700,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Configure Purchase Order# Preferences',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: _linkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Associated Series
                          const Text(
                            'Associated Series',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Default Transaction Series',
                            style: TextStyle(fontSize: 13, color: _textPrimary),
                          ),
                          const SizedBox(height: 24),

                          // Description
                          Text(
                            isAuto
                                ? 'Your purchase order numbers are set on auto-generate mode to save your time. Are you sure about changing this setting?'
                                : 'You have selected manual purchase order numbering. Do you want us to auto-generate it for you?',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _labelColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Options
                          Row(
                            children: [
                              _zRadio(
                                'Continue auto-generating purchase order numbers',
                                'auto',
                                isAuto ? 'auto' : 'manual',
                                (v) => setState(() => isAuto = true),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: _hintColor,
                              ),
                            ],
                          ),
                          if (isAuto) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Prefix',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _hintColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 160,
                                        child: _zField(
                                          prefixCtrl,
                                          suffixIcon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 16,
                                            color: _linkBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Next Number',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _hintColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 280,
                                        child: _zField(nextNumCtrl),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Checkbox(
                                      value: restartMonthly,
                                      onChanged: (v) =>
                                          setState(() => restartMonthly = v!),
                                      side: const BorderSide(
                                        color: Color(0xFFCCCCCC),
                                      ),
                                      activeColor: _greenBtn,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Restart numbering for purchase orders at the start of each fiscal year.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _labelColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _zRadio(
                            'Enter purchase order numbers manually',
                            'manual',
                            isAuto ? 'auto' : 'manual',
                            (v) => setState(() => isAuto = false),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              final rawNextNum = nextNumCtrl.text;
                              final parsedNum = int.tryParse(rawNextNum) ?? 1;
                              final padding = rawNextNum.length;

                              notifier.saveSettings(
                                isAuto: isAuto,
                                prefix: prefixCtrl.text,
                                nextNumber: parsedNum,
                                padding: padding,
                              );
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _greenBtn,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFDDDDDD)),
                              foregroundColor: _textPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
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
            );
          },
        );
      },
    );
  }

  Widget _buildVendorSelectionRow(
    Vendor selectedVendor,
    List<Vendor> vendors,
    bool hasVendor,
    PurchaseOrderNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _zFormRow(
            label: 'Vendor Name',
            isRequired: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 320,
                  child: FormDropdown<Vendor>(
                    height: 36,
                    value: selectedVendor.id.isEmpty ? null : selectedVendor,
                    items: vendors,
                    hint: 'Select a Vendor',
                    showSearch: true,
                    allowClear: hasVendor,
                    menuWidth: 480,
                    onChanged: (v) =>
                        notifier.updateField(vendorId: v?.id ?? ''),
                    displayStringForValue: (v) => v.displayName,
                    itemBuilder: (v, isSelected, isHovered) =>
                        _buildVendorDropdownItem(v, isSelected, isHovered),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _fieldBorder),
                  ),
                ),
                const SizedBox(width: 8),
                _searchBtn(() => _showAdvancedSearch(vendors, notifier)),
                if (hasVendor) ...[
                  const SizedBox(width: 8),
                  // INR badge
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: _fieldBorder),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: _greenBtn),
                        const SizedBox(width: 6),
                        Text(
                          selectedVendor.currency ?? 'INR',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
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
            onTap: () => _showVendorSidebar(selectedVendor),
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C5F7C),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedVendor.displayName.length > 20
                        ? '${selectedVendor.displayName.substring(0, 20)}...'
                        : selectedVendor.displayName,
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

  void _showAdvancedSearch(
    List<Vendor> vendors,
    PurchaseOrderNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _AdvancedVendorSearchDialog(
        vendors: vendors,
        onSelect: (v) {
          notifier.updateField(vendorId: v.id);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showTaxPreferencesDialog(Vendor vendor) {
    _closeGstOverlay();
    final overlay = Overlay.of(context);
    _gstOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeGstOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _gstLink,
            showWhenUnlinked: false,
            offset: const Offset(-360, 18), // Adjust to align arrow with pencil
            child: Material(
              color: Colors.transparent,
              child: _ConfigureTaxPreferencesDialog(
                initialTreatment:
                    vendor.gstTreatment ?? 'Unregistered Business',
                onUpdate: (val, isPermanent) {
                  final updatedVendor = vendor.copyWith(gstTreatment: val);
                  ref
                      .read(vendorProvider.notifier)
                      .updateVendor(vendor.id, updatedVendor);
                  _closeGstOverlay();
                },
                onCancel: _closeGstOverlay,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_gstOverlay!);
  }

  void _showOpenPurchaseOrdersPopover(BuildContext context) {
    _closePoOverlay();
    final overlay = Overlay.of(context);
    _poOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closePoOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _poLink,
            showWhenUnlinked: false,
            offset: const Offset(-20, 20),
            child: const Material(
              color: Colors.transparent,
              child: _OpenPurchaseOrdersPopover(
                orders: [], // Empty state
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_poOverlay!);
  }

  void _showVendorSidebar(Vendor vendor) {
    _closeVendorSidebar();
    final overlay = Overlay.of(context);
    _vendorSidebarOverlay = OverlayEntry(
      builder: (ctx) =>
          _VendorSidebar(vendor: vendor, onClose: _closeVendorSidebar),
    );
    overlay.insert(_vendorSidebarOverlay!);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VENDOR INFO SECTION (Billing/Shipping, GST, Supply)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _vendorInfoSection(
    Vendor vendor,
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Indented section for addresses and GST
        Padding(
          padding: const EdgeInsets.only(left: 32 + 176),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Open Purchase Orders link
              CompositedTransformTarget(
                link: _poLink,
                child: GestureDetector(
                  onTap: () => _showOpenPurchaseOrdersPopover(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Open Purchase Orders',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF555555),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Billing & Shipping Address side by side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddressBlock(
                    title: 'BILLING ADDRESS',
                    address: vendor.billingAddress,
                    onEdit: () =>
                        _showAddressModal(vendor: vendor, isBilling: true),
                    onNewAddress: () =>
                        _showAddressModal(vendor: vendor, isBilling: true),
                  ),
                  const SizedBox(width: 64),
                  _buildAddressBlock(
                    title: 'SHIPPING ADDRESS',
                    address: vendor.shippingAddress,
                    onEdit: () =>
                        _showAddressModal(vendor: vendor, isBilling: false),
                    onNewAddress: () =>
                        _showAddressModal(vendor: vendor, isBilling: false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // GST Treatment
              _buildGstRow(vendor),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Supply Details aligned with general form
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(
            children: [
              _zFormRow(
                label: 'Source of Supply',
                isRequired: true,
                child: SizedBox(
                  width: 320,
                  child: FormDropdown<String>(
                    value:
                        vendor.sourceOfSupply != null &&
                            vendor.sourceOfSupply!.isNotEmpty
                        ? vendor.sourceOfSupply!
                        : (_sourceOfSupplyList.isNotEmpty
                              ? _sourceOfSupplyList.first
                              : ''),
                    items: _sourceOfSupplyList,
                    showSearch: true,
                    onChanged: (val) {
                      if (val == null) return;
                      final updatedVendor = vendor.copyWith(
                        sourceOfSupply: val,
                      );
                      ref
                          .read(vendorProvider.notifier)
                          .updateVendor(vendor.id, updatedVendor);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _zFormRow(
                label: 'Destination of Supply',
                isRequired: true,
                child: SizedBox(
                  width: 320,
                  child: FormDropdown<String>(
                    height: 36,
                    value: poState.destinationOfSupply.isNotEmpty
                        ? poState.destinationOfSupply
                        : '[KL] - Kerala',
                    items: _sourceOfSupplyList,
                    showSearch: true,
                    onChanged: (val) =>
                        notifier.updateField(destinationOfSupply: val ?? ''),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _fieldBorder),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressBlock({
    required String title,
    required Map<String, dynamic>? address,
    required VoidCallback onEdit,
    required VoidCallback onNewAddress,
  }) {
    final hasAddress = address != null && address.isNotEmpty;
    final lines = <String>[];
    if (hasAddress) {
      if (address['attention'] != null &&
          (address['attention'] as String).isNotEmpty)
        lines.add(address['attention']);
      if (address['street1'] != null &&
          (address['street1'] as String).isNotEmpty)
        lines.add(address['street1']);
      if (address['street2'] != null &&
          (address['street2'] as String).isNotEmpty)
        lines.add(address['street2']);
      if (address['city'] != null && (address['city'] as String).isNotEmpty)
        lines.add(address['city']);
      final stateZip = [
        address['state'],
        address['zip'],
      ].where((s) => s != null && s.toString().isNotEmpty).join(' ');
      if (stateZip.isNotEmpty) lines.add(stateZip);
      if (address['country'] != null &&
          (address['country'] as String).isNotEmpty)
        lines.add(address['country']);
      if (address['phone'] != null && (address['phone'] as String).isNotEmpty)
        lines.add('Phone: ${address['phone']}');
      if (address['fax'] != null && (address['fax'] as String).isNotEmpty)
        lines.add('Fax Number: ${address['fax']}');
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _linkBlue,
                  letterSpacing: 0.5,
                ),
              ),
              if (hasAddress) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(Icons.edit_outlined, size: 14, color: _linkBlue),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (hasAddress)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (l) => Text(
                      l,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                        height: 1.6,
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            GestureDetector(
              onTap: onNewAddress,
              child: const Text(
                'New Address',
                style: TextStyle(
                  fontSize: 12,
                  color: _linkBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGstRow(Vendor vendor) {
    final gstTreatment = vendor.gstTreatment ?? 'Unregistered Business';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'GST Treatment: ',
              style: TextStyle(fontSize: 13, color: _labelColor),
            ),
            Text(
              gstTreatment,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(width: 4),
            CompositedTransformTarget(
              link: _gstLink,
              child: GestureDetector(
                onTap: () => _showTaxPreferencesDialog(vendor),
                child: Icon(Icons.edit_outlined, size: 14, color: _linkBlue),
              ),
            ),
          ],
        ),
        if (vendor.gstin != null && vendor.gstin!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'GSTIN: ',
                style: TextStyle(fontSize: 12, color: _labelColor),
              ),
              Text(
                vendor.gstin!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _linkBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit_outlined, size: 12, color: _linkBlue),
            ],
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELIVERY ADDRESS SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _deliverySection(
    List<WarehouseModel> warehouses,
    List<SalesCustomer> customers,
    PurchaseOrderState poState,
  ) {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    if (poState.deliveryType == 'warehouse') {
      final warehouseAsync = ref.watch(warehousesProvider);
      final liveWarehouses = warehouseAsync.value ?? warehouses;
      final wh = liveWarehouses.firstWhere(
        (w) => w.id == poState.deliveryWarehouseId,
        orElse: () => WarehouseModel(id: '', name: '', countryRegion: ''),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: warehouseAsync.isLoading
                ? Container(
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: _fieldBorder),
                      borderRadius: BorderRadius.circular(3),
                      color: _bgWhite,
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: const Text(
                      'Loading warehouses...',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    ),
                  )
                : warehouseAsync.hasError
                ? Container(
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.red.withValues(alpha: 0.05),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Error loading data: ${warehouseAsync.error}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : FormDropdown<WarehouseModel>(
                    height: 36,
                    value: wh.id.isEmpty ? null : wh,
                    items: liveWarehouses,
                    hint: liveWarehouses.isEmpty
                        ? 'No warehouses found'
                        : 'Select Warehouse',
                    showSearch: true,
                    displayStringForValue: (w) => w.name,
                    searchStringForValue: (w) =>
                        '${w.name} ${w.city ?? ''} ${w.state ?? ''} ${w.addressStreet1 ?? ''}',
                    itemBuilder: (w, isSelected, isHovered) =>
                        _buildWarehouseDropdownItem(w, isSelected, isHovered),
                    onChanged: (w) {
                      notifier.updateField(
                        deliveryWarehouseId: w?.id ?? '',
                        deliveryAddressName: w?.name ?? '',
                      );
                      _deliveryNameCtrl.text = w?.name ?? '';
                    },
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _fieldBorder),
                  ),
          ),
          if (wh.id.isNotEmpty) ...[
            const SizedBox(height: 14),
            _warehouseAddressCard(wh, notifier, liveWarehouses, poState),
          ],
        ],
      );
    } else {
      final cust = customers.firstWhere(
        (c) => c.id == poState.deliveryCustomerId,
        orElse: () => SalesCustomer(id: '', displayName: ''),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 320,
            child: FormDropdown<SalesCustomer>(
              value: cust.id.isEmpty ? null : cust,
              items: customers,
              hint: 'Select Customer',
              showSearch: true,
              displayStringForValue: (c) => c.displayName,
              onChanged: (c) =>
                  notifier.updateField(deliveryCustomerId: c?.id ?? ''),
            ),
          ),
          if (cust.id.isNotEmpty) ...[
            const SizedBox(height: 10),
            _customerAddressCard(cust, notifier),
          ],
        ],
      );
    }
  }

  // ─── Warehouse address card (Image 1 style) ────────────────────────────────
  Widget _warehouseAddressCard(
    WarehouseModel wh,
    PurchaseOrderNotifier notifier,
    List<WarehouseModel> allWarehouses,
    PurchaseOrderState poState,
  ) {
    const addrColor = Color(0xFF1A73C8); // blue for city / country lines
    const addrDark = Color(0xFF1A3A5C); // darker for bold city

    final displayName = poState.deliveryAddressName ?? wh.name;
    if (_deliveryNameCtrl.text != displayName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _deliveryNameCtrl.text = displayName;
      });
    }

    final lines = <_AddrLine>[
      if (wh.city != null && wh.city!.isNotEmpty)
        _AddrLine(wh.city!, isBold: true),
      if ((wh.addressStreet1 ?? '').isNotEmpty || (wh.state ?? '').isNotEmpty)
        _AddrLine(
          [
            wh.addressStreet1,
            wh.state,
          ].where((s) => s != null && s.isNotEmpty).join(', '),
        ),
      if (wh.countryRegion.isNotEmpty || (wh.zipCode ?? '').isNotEmpty)
        _AddrLine(
          '${wh.countryRegion}'
          '${(wh.zipCode ?? '').isNotEmpty ? " , ${wh.zipCode}" : ""}',
        ),
      if ((wh.phone ?? '').isNotEmpty) _AddrLine(wh.phone!, isPhone: true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editable bold name field
        SizedBox(
          width: 320,
          child: _HoverableField(
            builder: (isHovered) => TextFormField(
              controller: _deliveryNameCtrl,
              onChanged: (v) => notifier.updateField(deliveryAddressName: v),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(
                    color: isHovered ? _linkBlue : _fieldBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: _linkBlue, width: 1.5),
                ),
                fillColor: _bgWhite,
                filled: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Styled address lines
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              line.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: line.isPhone
                    ? _labelColor
                    : (line.isBold ? addrDark : addrColor),
                fontWeight: line.isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // "Change destination" link → opens popover
        CompositedTransformTarget(
          link: _deliveryChangeLink,
          child: GestureDetector(
            onTap: () => _showDeliveryPopover(allWarehouses, poState, notifier),
            child: const Text(
              'Change destination to deliver',
              style: TextStyle(
                color: _linkBlue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Customer address card ──────────────────────────────────────────────────
  Widget _customerAddressCard(
    SalesCustomer cust,
    PurchaseOrderNotifier notifier,
  ) {
    const addrColor = Color(0xFF1A73C8);
    const addrDark = Color(0xFF1A3A5C);
    final lines = <_AddrLine>[
      if ((cust.shippingAddressStreet1 ?? '').isNotEmpty)
        _AddrLine(cust.shippingAddressStreet1!, isBold: true),
      if ((cust.shippingAddressCity ?? '').isNotEmpty)
        _AddrLine(cust.shippingAddressCity!),
      if ((cust.shippingAddressStateId ?? '').isNotEmpty)
        _AddrLine(cust.shippingAddressStateId!),
      if ((cust.shippingAddressZip ?? '').isNotEmpty)
        _AddrLine(cust.shippingAddressZip!),
      if ((cust.phone ?? '').isNotEmpty) _AddrLine(cust.phone!, isPhone: true),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: _HoverableField(
            builder: (isHovered) => TextFormField(
              initialValue: cust.displayName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(
                    color: isHovered ? _linkBlue : _fieldBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: _linkBlue, width: 1.5),
                ),
                fillColor: _bgWhite,
                filled: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              line.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: line.isPhone
                    ? _labelColor
                    : (line.isBold ? addrDark : addrColor),
                fontWeight: line.isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            notifier.updateField(
              deliveryType: 'warehouse',
              deliveryCustomerId: '',
            );
          },
          child: const Text(
            'Change destination to deliver',
            style: TextStyle(
              color: _linkBlue,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── "Change destination" popover ──────────────────────────────────────────
  void _showDeliveryPopover(
    List<WarehouseModel> warehouses,
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) {
    _closeDeliveryOverlay();
    final searchCtrl = TextEditingController();
    final searchNotifier = ValueNotifier<String>('');
    searchCtrl.addListener(
      () => searchNotifier.value = searchCtrl.text.toLowerCase(),
    );

    _deliveryOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeDeliveryOverlay,
          child: Stack(
            children: [
              const SizedBox.expand(),
              CompositedTransformFollower(
                link: _deliveryChangeLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 4),
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(6),
                    color: _bgWhite,
                    child: Container(
                      width: 320,
                      constraints: const BoxConstraints(maxHeight: 400),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              controller: searchCtrl,
                              autofocus: true,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFAAAAAA),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 16,
                                  color: Color(0xFFAAAAAA),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 32,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                    color: _linkBlue,
                                    width: 1.5,
                                  ),
                                ),
                                fillColor: _bgWhite,
                                filled: true,
                              ),
                            ),
                          ),
                          // List
                          Flexible(
                            child: ValueListenableBuilder<String>(
                              valueListenable: searchNotifier,
                              builder: (_, query, __) {
                                final filtered = query.isEmpty
                                    ? warehouses
                                    : warehouses
                                          .where(
                                            (w) =>
                                                w.name.toLowerCase().contains(
                                                  query,
                                                ) ||
                                                (w.city ?? '')
                                                    .toLowerCase()
                                                    .contains(query) ||
                                                (w.state ?? '')
                                                    .toLowerCase()
                                                    .contains(query),
                                          )
                                          .toList();
                                if (filtered.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No warehouses found',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) {
                                    final w = filtered[i];
                                    return _deliveryPopoverItem(
                                      w,
                                      w.id == poState.deliveryWarehouseId,
                                      notifier,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                          // + New Address
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: GestureDetector(
                              onTap: _closeDeliveryOverlay,
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 15,
                                    color: _linkBlue,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'New Address',
                                    style: TextStyle(
                                      color: _linkBlue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                          // Link repeated at bottom
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                notifier.updateField(
                                  deliveryType: 'customer',
                                  deliveryWarehouseId: '',
                                  clearDeliveryAddressName: true,
                                );
                                _closeDeliveryOverlay();
                              },
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Change destination to deliver',
                                  style: TextStyle(
                                    color: _linkBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
              ),
            ],
          ),
        );
      },
    );
    Overlay.of(context).insert(_deliveryOverlay!);
  }

  // ─── Single item in delivery popover ───────────────────────────────────────
  Widget _deliveryPopoverItem(
    WarehouseModel w,
    bool isSelected,
    PurchaseOrderNotifier notifier,
  ) {
    const selBg = Color(0xFF1A73C8);
    const normBg = Color(0xFFF5F5F5);
    const cityCol = Color(0xFFBF4040); // reddish for city / country+zip
    const darkCol = Color(0xFF222222); // dark for street/state, phone

    final lines = <_AddrLine>[
      if (w.attention != null && w.attention!.isNotEmpty)
        _AddrLine(w.attention!),
      if (w.city != null && w.city!.isNotEmpty)
        _AddrLine(w.city!, isCity: true),
      if ((w.addressStreet1 ?? '').isNotEmpty || (w.state ?? '').isNotEmpty)
        _AddrLine(
          [
            w.addressStreet1,
            w.state,
          ].where((s) => s != null && s.isNotEmpty).join(', '),
        ),
      if (w.countryRegion.isNotEmpty || (w.zipCode ?? '').isNotEmpty)
        _AddrLine(
          '${w.countryRegion}${(w.zipCode ?? '').isNotEmpty ? " , ${w.zipCode}" : ""}',
          isCity: true,
        ),
      if ((w.phone ?? '').isNotEmpty) _AddrLine(w.phone!),
    ];

    bool hov = false;
    return StatefulBuilder(
      builder: (ctx, setSt) {
        return MouseRegion(
          onEnter: (_) => setSt(() => hov = true),
          onExit: (_) => setSt(() => hov = false),
          child: GestureDetector(
            onTap: () {
              notifier.updateField(
                deliveryWarehouseId: w.id,
                deliveryAddressName: w.name,
              );
              _deliveryNameCtrl.text = w.name;
              _closeDeliveryOverlay();
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? selBg
                    : (hov ? const Color(0xFFE8F0FE) : normBg),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines
                          .map(
                            (line) => Text(
                              line.text,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: isSelected
                                    ? Colors.white
                                    : (line.isCity ? cityCol : darkCol),
                                fontWeight: line.isBold
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (!isSelected) ...[
                    GestureDetector(
                      onTap: () {
                        _closeDeliveryOverlay();
                        _showAddressModal(wh: w);
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REVERSE CHARGE CHECKBOX
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _reverseChargeCheckbox(
    PurchaseOrderState poState,
    PurchaseOrderNotifier notifier,
  ) {
    return _zFormRow(
      label: '',
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Checkbox(
              value: poState.isReverseCharge,
              onChanged: (v) => notifier.updateField(isReverseCharge: v),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ITEM TABLE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _itemTableSection(
    List<Item> allItems,
    List<AccountNode> availableAccounts,
    PurchaseOrderState poState,
  ) {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: _bgWhite,
            border: Border.all(color: _borderCol),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxWidth: 1150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header — Title + Bulk Actions ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Item Table',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const Spacer(),

                    // (Table settings was here - moved after Bulk Actions)

                    Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        elevation: 8,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onSelected: (val) {
                          if (val == 'bulk_update') {
                            setState(() {
                              _bulkMode = true;
                              _selectedRows.clear();
                            });
                          } else if (val == 'hide_all') {
                            final poState = ref.read(purchaseOrderFormNotifierProvider);
                            final allHidden = poState.items.asMap().keys.every((i) => _hiddenDetails.contains(i));
                            setState(() {
                              if (allHidden) {
                                _hiddenDetails.clear();
                              } else {
                                for (int i = 0; i < poState.items.length; i++) {
                                  _hiddenDetails.add(i);
                                }
                              }
                            });
                          }
                        },
                        itemBuilder: (_) {
                          final poState = ref.read(purchaseOrderFormNotifierProvider);
                          final allHidden = poState.items.asMap().keys.every((i) => _hiddenDetails.contains(i));
                          return [
                            const PopupMenuItem(
                              value: 'bulk_update',
                              padding: EdgeInsets.zero,
                              height: 40,
                              child: _HoverableMenuItem('Bulk Update Line Items'),
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
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: _linkBlue,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Bulk Actions',
                              style: TextStyle(
                                color: _linkBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── TABLE SETTINGS (moved after Bulk Actions) ──
                    Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        elevation: 8,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val == 'stock') _showStockInfo = !_showStockInfo;
                            if (val == 'recent') _showRecentTransactions = !_showRecentTransactions;
                            if (val == 'pricelist') _showPriceList = !_showPriceList;
                          });
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'stock',
                            padding: EdgeInsets.zero,
                            height: 40,
                            child: _HoverableToggleMenuItem(
                              _showStockInfo ? 'Hide Available stock for sale' : 'Show Available stock for sale',
                              _showStockInfo,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'recent',
                            padding: EdgeInsets.zero,
                            height: 40,
                            child: _HoverableToggleMenuItem(
                              _showRecentTransactions ? 'Hide Recent Transaction' : 'Show Recent Transaction',
                              _showRecentTransactions,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'pricelist',
                            padding: EdgeInsets.zero,
                            height: 40,
                            child: _HoverableToggleMenuItem(
                              _showPriceList ? 'Hide PriceList' : 'Show PriceList',
                              _showPriceList,
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: _fieldBorder),
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.settings_outlined, size: 16, color: _textPrimary),
                              Icon(Icons.arrow_drop_down, size: 14, color: _hintColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Bulk mode banner ──
              if (_bulkMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FF),
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('Update Reporting Tags'),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() {
                          _bulkMode = false;
                          _selectedRows.clear();
                        }),
                        child: const Icon(Icons.close, size: 18, color: _labelColor),
                      ),
                    ],
                  ),
                ),
              // ── Column headers ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.symmetric(
                    horizontal: BorderSide(color: _borderCol),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 40,
                child: Row(
                  children: [
                    if (_bulkMode)
                      SizedBox(
                        width: 28,
                        child: Checkbox(
                          value: _selectedRows.length == ref.watch(purchaseOrderFormNotifierProvider).items.length,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selectedRows.addAll(List.generate(ref.read(purchaseOrderFormNotifierProvider).items.length, (i) => i));
                            } else {
                              _selectedRows.clear();
                            }
                          }),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    const SizedBox(width: 24), // drag handle space
                    const Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'ITEM DETAILS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                    ),
                                        _headerDivider(),
                    const Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'QUANTITY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                    ),
                    _headerDivider(),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'RATE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            ZTooltip(
                              message: 'You can perform basic calculations directly in this field using parentheses ( ) and arithmetic operators: + - / *',
                              child: SvgPicture.string(
                                '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="16" height="20" x="4" y="2" rx="2"/><line x1="8" x2="16" y1="6" y2="6"/><line x1="16" x2="16" y1="14" y2="18"/><path d="M16 10h.01"/><path d="M12 10h.01"/><path d="M8 10h.01"/><path d="M12 14h.01"/><path d="M8 14h.01"/><path d="M12 18h.01"/><path d="M8 18h.01"/></svg>',
                                width: 16,
                                height: 16,
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
                    
                    if (poState.discountLevel == 'item') ...[
                      _headerDivider(),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'DISCOUNT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
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
                    _headerDivider(),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'TAX',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
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
                    _headerDivider(),
                    const SizedBox(
                      width: 100,
                      child: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          'AMOUNT',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 60), // actions space
                  ],
                ),
              ),
              // ── Item rows ──
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: poState.items.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: _borderCol),
                itemBuilder: (_, i) => _buildItemRow(
                  i,
                  allItems,
                  availableAccounts,
                  poState,
                  poState.items[i],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── Add Row Buttons (Outside Table) ──
        Row(
          children: [
            // Split button: left = Add New Row, right chevron = dropdown
            CompositedTransformTarget(
              link: _addRowDropdownLink,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main action
                    GestureDetector(
                      onTap: () {
                        _addRowController(
                          initialQty: 1.0,
                          initialRate: 0.0,
                          initialDiscount: 0.0,
                        );
                        notifier.addItemRow();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline, size: 14, color: _linkBlue),
                            SizedBox(width: 6),
                            Text(
                              'Add New Row',
                              style: TextStyle(
                                fontSize: 12,
                                color: _linkBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Divider
                    Container(width: 1, height: 20, color: _linkBlue.withValues(alpha: 0.3)),
                    // Chevron dropdown trigger
                    GestureDetector(
                      onTap: () => _toggleAddRowDropdown(notifier),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.keyboard_arrow_down, size: 16, color: _linkBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _tableActionBtn(
              icon: Icons.add_circle_outline,
              label: 'Add Items in Bulk',
              onTap: () => _showBulkAddModal(allItems),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerDivider() {
    return Container(width: 1, height: 40, color: _borderCol);
  }

  Widget _buildItemRow(
    int index,
    List<Item> allItems,
    List<AccountNode> availableAccounts,
    PurchaseOrderState poState,
    PurchaseOrderItem item,
  ) {
    // Ensure controller exists for this index (no setState during build)
    while (_rowControllers.length <= index) {
      _rowControllers.add(_makeRowController(
        initialQty: item.quantity,
        initialRate: item.rate,
        initialDiscount: item.discount,
      ));
    }
    final ctrl = _rowControllers[index];
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    final activePriceLists = ref.watch(activePriceListsProvider);

    // Header row
    if (item.isHeader) {
      _headerTextControllers.putIfAbsent(
        index,
        () => TextEditingController(text: item.headerText ?? ''),
      );
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _headerTextControllers[index],
                onChanged: (v) => notifier.updateHeaderText(index, v),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Add New Header',
                  hintStyle: const TextStyle(color: _hintColor, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: const BorderSide(color: _fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                    borderSide: const BorderSide(color: _fieldBorder),
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
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _rowControllers[index].dispose();
                _headerTextControllers.remove(index);
                setState(() {
                  _rowControllers.removeAt(index);
                });
                notifier.removeItemRow(index);
              },
              child: const Icon(Icons.close, size: 16, color: _dangerRed),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ClipRect(
          child: Container(
            constraints: BoxConstraints(minHeight: item.productId.isEmpty ? 54 : 120),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bulk checkbox (only in bulk mode)
                  if (_bulkMode)
                    SizedBox(
                      width: 28,
                      child: Center(
                        child: Checkbox(
                          value: _selectedRows.contains(index),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selectedRows.add(index);
                            } else {
                              _selectedRows.remove(index);
                            }
                          }),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 14,
                      ),
                      child: item.productId.isEmpty
                          // ── Empty state: search dropdown ──
                          ? Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    border: Border.all(color: _borderCol),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 16,
                                    color: _hintColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _plainDropdown<Item>(
                                    value: null,
                                    items: allItems,
                                    hint: 'Type or click to select an item.',
                                    onChanged: (i) {
                                      if (i == null) return;
                                      ctrl.nameCtrl.text = i.productName;
                                      ctrl.qtyCtrl.text = '1.00';
                                      ctrl.rateCtrl.text = (i.costPrice ?? 0.0)
                                          .toStringAsFixed(2);
                                      ctrl.discountCtrl.text = '0.00';
                                      ctrl.descCtrl.text =
                                          i.purchaseDescription ?? '';
                                      notifier.selectProductForItem(
                                        index,
                                        i,
                                        poState.warehouseId ?? '',
                                      );
                                    },
                                    displayStringMapper: (i) => i.productName,
                                  ),
                                ),
                              ],
                            )
                          // ── Selected state: rich card ──
                          : Builder(
                              builder: (context) {
                                final selectedItem = allItems.firstWhere(
                                  (i) => i.id == item.productId,
                                  orElse: () => Item(
                                    productName: item.productName ?? '',
                                    itemCode: item.itemCode ?? '',
                                    type: item.productType ?? 'goods',
                                    unitId: '',
                                  ),
                                );
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Drag handle (inside card)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10, right: 6),
                                      child: Icon(
                                        Icons.drag_indicator,
                                        size: 16,
                                        color: _hintColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    // Image placeholder
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        border: Border.all(color: _borderCol),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child:
                                          selectedItem.primaryImageUrl !=
                                                  null &&
                                              selectedItem
                                                  .primaryImageUrl!
                                                  .isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: Image.network(
                                                selectedItem.primaryImageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                      Icons.image_outlined,
                                                      size: 20,
                                                      color: _hintColor,
                                                    ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image_outlined,
                                              size: 20,
                                              color: _hintColor,
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Name row
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.productName ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: _textPrimary,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // 3-dot menu
                                              CompositedTransformTarget(
                                                link: _rowControllers[index].itemMenuLink,
                                                child: GestureDetector(
                                                  onTap: () => _showItemMenu(
                                                    context,
                                                    index,
                                                    item,
                                                    _rowControllers[index].itemMenuLink,
                                                  ),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(4),
                                                    child: Icon(
                                                      Icons.more_horiz,
                                                      size: 16,
                                                      color: _hintColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              // X close
                                              GestureDetector(
                                                onTap: () {
                                                  notifier.removeItemRow(index);
                                                  if (index < _rowControllers.length) {
                                                    _rowControllers[index].dispose();
                                                    setState(() => _rowControllers.removeAt(index));
                                                  }
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Icon(
                                                    Icons.cancel_outlined,
                                                    size: 16,
                                                    color: _hintColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (!_hiddenDetails.contains(index)) ...[
                                            const SizedBox(height: 4),
                                            // Description
                                            Container(
                                              height: 72,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: _borderCol,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: TextField(
                                                controller: ctrl.descCtrl,
                                                maxLines: null,
                                                expands: true,
                                                textAlignVertical:
                                                    TextAlignVertical.top,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _textPrimary,
                                                ),
                                                decoration: const InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 6,
                                                      ),
                                                  border: InputBorder.none,
                                                  hintText:
                                                      'Add a description to your item',
                                                  hintStyle: TextStyle(
                                                    fontSize: 12,
                                                    color: _hintColor,
                                                  ),
                                                ),
                                                onChanged: (v) =>
                                                    notifier.updateItem(
                                                      index,
                                                      item.copyWith(
                                                        description: v,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          // SKU/HSN info
                                          Row(
                                            children: [
                                              _infoChip(
                                                (item.productType ?? 'goods')
                                                    .toUpperCase(),
                                                item.productType == 'service'
                                                    ? const Color(0xFF7C3AED)
                                                    : const Color(0xFF0088FF),
                                                Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'HSN Code: ',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: _hintColor,
                                                ),
                                              ),
                                              CompositedTransformTarget(
                                                link: _rowControllers[index].hsnLink,
                                                child: GestureDetector(
                                                  onTap: () => _showHsnEditDialog(
                                                    context,
                                                    index,
                                                    item,
                                                    _rowControllers[index].hsnLink,
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.edit_outlined,
                                                        size: 12,
                                                        color: Color(0xFF0088FF),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        item.hsnCode != null &&
                                                                item.hsnCode!
                                                                    .isNotEmpty
                                                            ? item.hsnCode!
                                                            : 'Update',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(
                                                            0xFF0088FF,
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
                                  ],
                                );
                              },
                            ),
                    ),
                  ),
                  _cellDivider(),
                  // Quantity
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _gridField(
                            ctrl.qtyCtrl,
                            hint: '1.00',
                            textAlign: TextAlign.right,
                            onChanged: (v) {
                              final q = double.tryParse(v) ?? 0;
                              notifier.updateItem(
                                index,
                                item.copyWith(quantity: q),
                              );
                            },
                          ),
                          if (item.productId.isNotEmpty && _showStockInfo) ...[
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                final warehouses =
                                    ref.watch(warehousesProvider).value ?? [];
                                final wh = warehouses.firstWhere(
                                  (w) => w.id == (poState.warehouseId ?? ''),
                                  orElse: () => warehouses.isNotEmpty
                                      ? warehouses.first
                                      : WarehouseModel(
                                          id: '',
                                          name: '',
                                          countryRegion: '',
                                        ),
                                );
                                final isSOH = _stockView == 'stockOnHand';
                                final stockValue = isSOH
                                    ? item.stockOnHand
                                    : item.availableStock;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isSOH
                                          ? 'Stock on Hand:'
                                          : 'Available for Sale:',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: _hintColor,
                                      ),
                                    ),
                                    Text(
                                      '${stockValue?.toStringAsFixed(0) ?? '0'} pcs',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: _textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (wh.name.isNotEmpty)
                                        CompositedTransformTarget(
                                          link: _rowControllers[index].warehouseSelectionLink,
                                          child: GestureDetector(
                                            onTap: () => _showWarehouseStockDialog(
                                              context,
                                              item,
                                              warehouses,
                                              _rowControllers[index].warehouseSelectionLink,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.warehouse_outlined,
                                                  size: 11,
                                                  color: Color(0xFF0088FF),
                                                ),
                                                const SizedBox(width: 2),
                                                SizedBox(
                                                  width: 72,
                                                  child: Text(
                                                    wh.name,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF0088FF),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _cellDivider(),
                  // Rate
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _gridField(
                            ctrl.rateCtrl,
                            focusNode: ctrl.rateFocus,
                            onSubmitted: (_) =>
                                _handleRateCalculation(ctrl),
                            hint: '0.00',
                            textAlign: TextAlign.right,
                            onChanged: (v) {
                              final r = double.tryParse(v) ?? 0;
                              notifier.updateItem(
                                index,
                                item.copyWith(rate: r),
                              );
                            },
                          ),
                          if (item.productId.isNotEmpty) ...[
                            if (_showPriceList || _showRecentTransactions)
                              const SizedBox(height: 4),
                            if (_showPriceList && activePriceLists.isNotEmpty)
                              PopupMenuButton<PriceList>(
                                padding: EdgeInsets.zero,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _borderCol),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Apply Price List',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 13,
                                        color: _hintColor,
                                      ),
                                    ],
                                  ),
                                ),
                                onSelected: (pl) {
                                  final newRate = pl.calculatePrice(
                                    item.productId,
                                    item.rate,
                                    quantity: item.quantity,
                                  );
                                  ctrl.rateCtrl.text = newRate.toStringAsFixed(
                                    2,
                                  );
                                  notifier.updateItem(
                                    index,
                                    item.copyWith(
                                      rate: newRate,
                                      priceListId: pl.id,
                                    ),
                                  );
                                },
                                itemBuilder: (context) => activePriceLists
                                    .where(
                                      (pl) => pl.transactionType == 'purchase',
                                    )
                                    .map(
                                      (pl) => PopupMenuItem(
                                        value: pl,
                                        child: Text(
                                          pl.name,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            if (_showRecentTransactions)
                              Builder(
                                builder: (innerContext) => GestureDetector(
                                  onTap: () {
                                    // Find the full item object to pass to the sidebar
                                    final selectedProduct = allItems.firstWhere(
                                      (p) => p.id == item.productId,
                                      orElse: () => Item(
                                        id: item.productId,
                                        productName: item.productName ?? '',
                                        type: item.productType ?? 'goods',
                                        unitId: '',
                                        itemCode: item.itemCode ?? '',
                                      ),
                                    );
                                    ref.read(itemDetailsSidebarProvider.notifier).state = selectedProduct;
                                    Scaffold.of(innerContext).openEndDrawer();
                                  },
                                  child: const Text(
                                    'Recent Transactions',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF0088FF),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (poState.discountLevel == 'item') ...[
                    _cellDivider(),
                    // Discount
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _gridField(
                                    ctrl.discountCtrl,
                                    hint: '0',
                                    textAlign: TextAlign.right,
                                    onChanged: (v) {
                                      final d = double.tryParse(v) ?? 0;
                                      notifier.updateItem(
                                        index,
                                        item.copyWith(discount: d),
                                      );
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
                                    link: ctrl.discountTypeLink,
                                    child: GestureDetector(
                                      onTap: () => _showDiscountMenu(context, index, item),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              item.discountType == 'percentage'
                                                  ? '%'
                                                  : '₹',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: _textPrimary,
                                                fontWeight: FontWeight.w500,
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
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  _cellDivider(),
                  // Tax
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CompositedTransformTarget(
                          link: ctrl.taxLink,
                          child: GestureDetector(
                            onTap: () {
                              final taxes =
                                  ref.read(itemsControllerProvider).taxRates;
                              _showTaxPopover(context, index, item, taxes);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: _fieldBorder),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.taxName ?? 'Select Tax',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: item.taxName == null
                                            ? _hintColor
                                            : _textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                          ),
                        ),
                      ),
                    ),
                  ),
                  _cellDivider(),
                  // Amount
                  SizedBox(
                    width: 100,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          item.amount.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Actions
                  SizedBox(
                    width: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CompositedTransformTarget(
                          link: _rowControllers[index].itemMenuLink,
                          child: GestureDetector(
                            onTap: () => _showItemMenu(
                              context,
                              index,
                              item,
                              _rowControllers[index].itemMenuLink,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: _hintColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            if (poState.items.length > 1) {
                              _rowControllers[index].dispose();
                              setState(() {
                                _rowControllers.removeAt(index);
                              });
                              notifier.removeItemRow(index);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: _dangerRed,
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
        if (!_hiddenDetails.contains(index))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border(top: BorderSide(color: _borderCol)),
            ),
            child: _itemExpandedProperties(index, item, availableAccounts, poState),
          ),
      ],
    );
  }

  void _closeTaxOverlay() {
    _taxOverlay?.remove();
    _taxOverlay = null;
  }

  void _closeWarehouseOverlay() {
    _warehouseOverlay?.remove();
    _warehouseOverlay = null;
  }

  void _closeHsnOverlay() {
    _hsnOverlay?.remove();
    _hsnOverlay = null;
  }

  void _showDiscountMenu(
    BuildContext context,
    int index,
    PurchaseOrderItem item, {
    LayerLink? link,
  }) {
    _closeDiscountOverlay();
    final ctrl = _rowControllers[index];
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    _discountOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeDiscountOverlay,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: link ?? ctrl.discountTypeLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 42),
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeDiscountOverlay(),
                child: _DiscountTypePopover(
                  selectedType: item.discountType,
                  onSelected: (type) {
                    notifier.updateItem(
                      index,
                      item.copyWith(discountType: type),
                    );
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


  void _showTaxPopover(
    BuildContext context,
    int index,
    PurchaseOrderItem item,
    List<TaxRate> taxes,
  ) {
    _closeTaxOverlay();
    final ctrl = _rowControllers[index];
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    _taxOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeTaxOverlay,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: ctrl.taxLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 42),
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeTaxOverlay(),
                child: _TaxSelectionPopover(
                  selectedTaxId: item.taxId,
                  taxes: taxes,
                  onTaxSelected: (tax) {
                    notifier.updateItem(
                      index,
                      item.copyWith(
                        taxId: tax.id,
                        taxName: tax.taxName,
                        taxRate: tax.taxRate,
                      ),
                    );
                    _closeTaxOverlay();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_taxOverlay!);
  }


  // ── Warehouse Stock Dialog ────────────────────────────────────────────────────
  void _showWarehouseStockDialog(
    BuildContext context,
    PurchaseOrderItem item,
    List<WarehouseModel> warehouses,
    LayerLink link,
  ) {
    _closeWarehouseOverlay();
    final poState = ref.read(purchaseOrderFormNotifierProvider);

    // Use RenderBox to get absolute trigger position, then clamp to screen
    const double popoverWidth = 680;
    const double margin = 8;
    final renderBox = context.findRenderObject() as RenderBox?;
    final triggerGlobal = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final triggerSize = renderBox?.size ?? Size.zero;
    final screenWidth = MediaQuery.of(context).size.width;

    // Right-align with trigger, clamped so it never overflows either edge
    double left = triggerGlobal.dx + triggerSize.width - popoverWidth;
    left = left.clamp(margin, screenWidth - popoverWidth - margin);
    final double top = triggerGlobal.dy + triggerSize.height + 6;

    _warehouseOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeWarehouseOverlay,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: left,
            top: top,
            width: popoverWidth,
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeWarehouseOverlay(),
                child: _WarehouseStockDialog(
                  item: item,
                  warehouses: warehouses,
                  selectedWarehouseId: poState.warehouseId,
                  initialStockView: _stockView,
                  onClose: _closeWarehouseOverlay,
                  onWarehouseSelected: (whId) {
                    ref
                        .read(purchaseOrderFormNotifierProvider.notifier)
                        .updateField(warehouseId: whId);
                  },
                  onViewChanged: (view) {
                    setState(() => _stockView = view);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_warehouseOverlay!);
  }

  // ── HSN Edit Dialog ──────────────────────────────────────────────────────────
  void _showHsnEditDialog(
    BuildContext context,
    int index,
    PurchaseOrderItem item,
    LayerLink link,
  ) {
    _closeHsnOverlay();
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

    _hsnOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeHsnOverlay,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
              offset: const Offset(-100, 20),
              child: Material(
                color: Colors.transparent,
                child: TapRegion(
                  onTapOutside: (_) => _closeHsnOverlay(),
                  child: _HSNCodeEditPopover(
                    initialHsnCode: item.hsnCode ?? '',
                    onCancel: _closeHsnOverlay,
                    onSave: (hsn) {
                      notifier.updateItem(index, item.copyWith(hsnCode: hsn));
                      _closeHsnOverlay();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_hsnOverlay!);
  }

  // ── Totals Section ──────────────────────────────────────────────────────────
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
    required Function(String) onChanged,
    Function(String)? onSubmitted,
    FocusNode? focusNode,
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
              child: TextField(
                controller: ctrl,
                focusNode: fn,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textAlign: textAlign,
                style: const TextStyle(fontSize: 13, color: _textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: _hintColor.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _plainDropdown<T>({
    required T? value,
    required List<T> items,
    required String hint,
    required Function(T?) onChanged,
    required String Function(T) displayStringMapper,
  }) {
    return FormDropdown<T>(
      value: value,
      items: items,
      hint: hint,
      onChanged: onChanged,
      displayStringForValue: displayStringMapper,
      border: Border.all(color: Colors.transparent),
      fillColor: Colors.white,
      padding: EdgeInsets.zero,
    );
  }

  Widget _cellDivider() {
    return Container(width: 1, color: _borderCol);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPORTING TAGS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _itemExpandedProperties(
    int index,
    PurchaseOrderItem item,
    List<AccountNode> accounts,
    PurchaseOrderState poState,
  ) {
    final ctrl = _rowControllers[index];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Account
        _propertyButton(
          link: ctrl.accountLink,
          iconWidget: SvgPicture.string(
            '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#6B7280" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 12h4"/><path d="M10 8h4"/><path d="M14 21v-3a2 2 0 0 0-4 0v3"/><path d="M6 10H4a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-2"/><path d="M6 21V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v16"/></svg>',
            width: 16,
            height: 16,
          ),
          label: item.accountName ?? 'Select an account',
          onTap: () {
            _showAccountMenu(context, index, item, accounts, link: ctrl.accountLink);
          },
        ),
        _propertySeparator(),
        // Reporting Tags
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
              Icon(icon, size: 16, color: color),
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
      return CompositedTransformTarget(
        link: link,
        child: content,
      );
    }
    return content;
  }

  Widget _propertySeparator() {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _fieldBorder,
    );
  }

  void _showAccountMenu(
    BuildContext context,
    int index,
    PurchaseOrderItem item,
    List<AccountNode> accounts, {
    LayerLink? link,
  }) {
    _accountOverlay?.remove();
    _accountOverlay = null;

    final overlay = Overlay.of(context);
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);

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
            link: link ?? _rowControllers[index].accountLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 32),
            child: Material(
              color: Colors.transparent,
              child: _AccountSelectionPopover(
                accounts: accounts,
                selectedAccountId: item.accountId,
                onSelected: (acc) {
                  notifier.updateItem(
                    index,
                    item.copyWith(accountId: acc.id, accountName: acc.name),
                  );
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


  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES (left) + TOTALS (right) — Zoho style
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _notesAndTotals(List<Item> allItems, PurchaseOrderState poState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT — Notes + GST breakdown
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _notesSection(),
              if (poState.items.any((i) => i.productId.isNotEmpty)) ...[
                const SizedBox(height: 16),
                Text(
                  'Total Quantity: ${poState.items.fold(0.0, (sum, i) => sum + i.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildGstDetails(poState),
              ],
            ],
          ),
        ),
        const SizedBox(width: 32),
        // RIGHT — Totals panel
        SizedBox(
          width: 360,
          child: _buildTotalsPanel(poState),
        ),
      ],
    );
  }

  Widget _buildTotalsPanel(PurchaseOrderState poState) {
    final totalQty = poState.items
        .where((i) => !i.isHeader)
        .fold(0.0, (sum, i) => sum + i.quantity);
    final qtyStr = totalQty % 1 == 0
        ? totalQty.toInt().toString()
        : totalQty.toStringAsFixed(2);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: _borderCol),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
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
                poState.subTotal.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Per-tax breakdown rows
          ..._buildTaxBreakdownRows(poState),
          // Total Tax Amount with editable field + pencil
          _buildTotalTaxRow(poState),
          if (poState.discountLevel == 'transaction') ...[
            const SizedBox(height: 12),
            _discountRow(poState),
          ],
          const SizedBox(height: 12),
          // TDS / TCS
          _tdsTcsRow(poState),
          const SizedBox(height: 12),
          // Adjustment
          _adjustmentRow(),
          const Divider(height: 32),
          // Total
          _totalLine(
            'Total',
            poState.total.toStringAsFixed(2),
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaxBreakdownRows(PurchaseOrderState poState) {
    final Map<String, ({String name, double rate, double amount})> groups = {};
    for (final item in poState.items.where((i) => !i.isHeader && i.taxAmount > 0)) {
      final key = item.taxId ?? item.taxName ?? '';
      if (key.isEmpty) continue;
      if (groups.containsKey(key)) {
        final e = groups[key]!;
        groups[key] = (name: e.name, rate: e.rate, amount: e.amount + item.taxAmount);
      } else {
        groups[key] = (
          name: item.taxName ?? 'Tax',
          rate: item.taxRate,
          amount: item.taxAmount,
        );
      }
    }

    final widgets = <Widget>[];
    for (final tax in groups.values) {
      final half = tax.rate / 2;
      final halfAmt = tax.amount / 2;
      final halfStr = half % 1 == 0 ? half.toInt().toString() : half.toStringAsFixed(1);

      widgets.add(Row(
        children: [
          Text(
            'CGST$halfStr [$halfStr%]',
            style: const TextStyle(fontSize: 13, color: _labelColor),
          ),
          const Spacer(),
          Text(halfAmt.toStringAsFixed(2), style: const TextStyle(fontSize: 13)),
        ],
      ));
      widgets.add(const SizedBox(height: 8));
      widgets.add(Row(
        children: [
          Text(
            'SGST$halfStr [$halfStr%]',
            style: const TextStyle(fontSize: 13, color: _labelColor),
          ),
          const Spacer(),
          Text(halfAmt.toStringAsFixed(2), style: const TextStyle(fontSize: 13)),
        ],
      ));
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  Widget _buildTotalTaxRow(PurchaseOrderState poState) {
    return Row(
      children: [
        const Text(
          'Total Tax Amount',
          style: TextStyle(fontSize: 13, color: _labelColor),
        ),
        const Spacer(),
        SizedBox(
          width: 80,
          height: 32,
          child: TextFormField(
            initialValue: poState.taxAmount.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: const BorderSide(color: _fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(3),
                borderSide: const BorderSide(color: _linkBlue),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF0088FF)),
      ],
    );
  }

  Widget _discountRow(PurchaseOrderState s) {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    return Row(
      children: [
        const Text(
          'Discount',
          style: TextStyle(fontSize: 13, color: _labelColor),
        ),
        const Spacer(),
        SizedBox(
          width: 60,
          child: _zField(
            _discountCtrl,
            onChanged: (v) =>
                notifier.updateField(discount: double.tryParse(v) ?? 0),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: _fieldBorder),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              _toggleBtn(
                '%',
                s.discountType == 'percentage',
                () => notifier.updateField(discountType: 'percentage'),
              ),
              Container(width: 1, color: _fieldBorder),
              _toggleBtn(
                '₹',
                s.discountType == 'fixed',
                () => notifier.updateField(discountType: 'fixed'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          s.discountValue.toStringAsFixed(2),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _tdsTcsRow(PurchaseOrderState s) {
    return Row(
      children: [
        _zRadio('TDS', 'tds', s.tdsTcsType ?? 'none', (_) {}),
        const SizedBox(width: 8),
        _zRadio('TCS', 'tcs', s.tdsTcsType ?? 'none', (_) {}),
        const SizedBox(width: 8),
        Expanded(
          child: FormDropdown<String>(
            value: null,
            items: const ['TDS - 1%', 'TDS - 2%', 'TCS - 0.1%'],
            hint: 'Select a Tax',
            onChanged: (v) {},
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '- 0.00',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _adjustmentRow() {
    final notifier = ref.read(purchaseOrderFormNotifierProvider.notifier);
    return Row(
      children: [
        CustomPaint(
          painter: const _DashedBorderPainter(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text(
              'Adjustment',
              style: TextStyle(fontSize: 13, color: _labelColor),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 80,
          child: _zField(
            _adjustmentCtrl,
            onChanged: (v) =>
                notifier.updateField(adjustment: double.tryParse(v) ?? 0),
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.help_outline, size: 14, color: _hintColor),
        const SizedBox(width: 16),
        SizedBox(
          width: 50,
          child: Text(
            (double.tryParse(_adjustmentCtrl.text) ?? 0.0).toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildGstDetails(PurchaseOrderState poState) {
    // Basic GST calculation (9% CGST + 9% SGST = 18% Total)
    final taxableAmount = poState.subTotal;
    final cgst = taxableAmount * 0.09;
    final sgst = taxableAmount * 0.09;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (taxableAmount > 0) ...[
          const Text(
            'GST Details:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'CGST (9%): ${cgst.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: _hintColor),
          ),
          Text(
            'SGST (9%): ${sgst.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: _hintColor),
          ),
        ] else
          Text(
            'No GST details available',
            style: TextStyle(fontSize: 12, color: _hintColor),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _notesSection() {
    return SizedBox(
      width: 450,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _labelColor,
            ),
          ),
          const SizedBox(height: 8),
          _HoverableField(
            builder: (isHovered) => TextField(
              controller: _notesCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Will be displayed on purchase order',
                hintStyle: TextStyle(color: _hintColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isHovered ? _linkBlue : _fieldBorder,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: _linkBlue, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TERMS & CONDITIONS + FILE UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _termsAndFileRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Terms
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _labelColor,
                ),
              ),
              const SizedBox(height: 8),
              _HoverableField(
                builder: (isHovered) => TextField(
                  controller: _termsCtrl,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'Enter the terms and conditions of your business to be displayed in your transaction',
                    hintStyle: TextStyle(color: _hintColor),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isHovered ? _linkBlue : _fieldBorder,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: _linkBlue, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // File Upload
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attach File(s) to Purchase Order',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _labelColor,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.upload_file, size: 16, color: _linkBlue),
              label: Text(
                'Upload File',
                style: TextStyle(color: _linkBlue, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _fieldBorder),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You can upload a maximum of 10 files, 10MB each',
              style: TextStyle(fontSize: 11, color: _hintColor),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STICKY FOOTER (Zoho style)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _stickyFooter(PurchaseOrderState poState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      decoration: BoxDecoration(
        color: _bgWhite,
        border: Border(top: BorderSide(color: _borderCol)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => _handleSave(poState, status: 'Draft'),
            child: const Text(
              'Save as Draft',
              style: TextStyle(color: _textPrimary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _handleSave(poState, status: 'Confirmed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenBtn,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: poState.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save and Send',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _textPrimary, fontSize: 13),
            ),
          ),
          const Spacer(),
          // Right side — Inventory Tracking + PDF template
          Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: _greenBtn),
              const SizedBox(width: 4),
              Text(
                'Inventory Tracking',
                style: TextStyle(fontSize: 12, color: _linkBlue),
              ),
              const SizedBox(width: 16),
              Text(
                "| PDF Template: 'Standard Template'",
                style: TextStyle(fontSize: 12, color: _hintColor),
              ),
              const SizedBox(width: 4),
              Text('Change', style: TextStyle(fontSize: 12, color: _linkBlue)),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERLAYS
  // ═══════════════════════════════════════════════════════════════════════════
  void _showBulkAddModal(List<Item> items) {
    showDialog(
      context: context,
      builder: (ctx) => _BulkAddModal(
        items: items,
        onAdd: (selected) {
          ref
              .read(purchaseOrderFormNotifierProvider.notifier)
              .addItemsInBulk(selected);
          for (var item in selected) {
            _addRowController(
              initialName: item.productName,
              initialQty: item.quantity,
              initialRate: item.rate,
              initialDiscount: item.discount,
            );
          }
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UNIFIED ADDRESS MODAL
  // ═══════════════════════════════════════════════════════════════════════════
  void _showAddressModal({
    WarehouseModel? wh,
    SalesCustomer? cust,
    Vendor? vendor,
    bool isBilling = true,
  }) {
    // Determine the source address data
    Map<String, dynamic> existingAddress = {};
    if (wh != null) {
      existingAddress = {
        'attention': wh.attention ?? '',
        'street1': wh.addressStreet1 ?? '',
        'street2': wh.addressStreet2 ?? '',
        'city': wh.city ?? '',
        'state': wh.state ?? '',
        'zip': wh.zipCode ?? '',
        'country': wh.countryRegion,
        'phone': wh.phone ?? '',
      };
    } else if (cust != null) {
      existingAddress = {
        'street1': cust.shippingAddressStreet1 ?? '',
        'street2': cust.shippingAddressStreet2 ?? '',
        'city': cust.shippingAddressCity ?? '',
        'state': cust.shippingAddressStateId ?? '',
        'zip': cust.shippingAddressZip ?? '',
        'phone': cust.phone ?? '',
      };
    } else if (vendor != null) {
      existingAddress = isBilling
          ? (vendor.billingAddress ?? {})
          : (vendor.shippingAddress ?? {});
    }

    String attentionValue = existingAddress['attention'] ?? '';
    String street1Value = existingAddress['street1'] ?? '';
    String street2Value = existingAddress['street2'] ?? '';
    String cityValue = existingAddress['city'] ?? '';
    String? countryValue = existingAddress['country'] ?? 'India';
    String? stateValue = existingAddress['state'] ?? '';
    String pinCodeValue = existingAddress['zip'] ?? '';
    String phoneCodeValue = existingAddress['phoneCode'] ?? '+91';
    String phoneValue =
        existingAddress['phone']?.toString().split(' ').last ?? '';
    String faxValue = existingAddress['fax'] ?? '';

    List<Map<String, dynamic>> localStates = [];
    bool isLoadingStates = false;

    // Stable controllers to avoid cursor reset
    final attCtrl = TextEditingController(text: attentionValue);
    final s1Ctrl = TextEditingController(text: street1Value);
    final s2Ctrl = TextEditingController(text: street2Value);
    final cityCtrl = TextEditingController(text: cityValue);
    final pinCtrl = TextEditingController(text: pinCodeValue);
    final phoneCtrl = TextEditingController(text: phoneValue);
    final faxCtrl = TextEditingController(text: faxValue);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> fetchStates(String countryName) async {
            final country = _countriesList.firstWhere(
              (c) => c['name'] == countryName,
              orElse: () => <String, dynamic>{},
            );
            final countryCode = country['short_code'] ?? 'IN';

            setDialogState(() => isLoadingStates = true);
            try {
              final lookupsService = LookupsApiService();
              final states = await lookupsService.getStates(countryCode);
              setDialogState(() {
                localStates = states;
                isLoadingStates = false;
              });
            } catch (e) {
              setDialogState(() => isLoadingStates = false);
            }
          }

          if (localStates.isEmpty && !isLoadingStates && countryValue != null) {
            fetchStates(countryValue!);
          }

          String dialogTitle = 'Edit Address';
          if (wh != null)
            dialogTitle = 'Edit Warehouse Address';
          else if (cust != null)
            dialogTitle = 'Edit Shipping Address';
          else if (vendor != null)
            dialogTitle = isBilling ? 'Billing Address' : 'Shipping Address';

          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            alignment: Alignment.topCenter,
            insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dialogTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _addressLabel('Attention'),
                          _zField(attCtrl),
                          const SizedBox(height: 14),

                          _addressLabel('Country/Region'),
                          FormDropdown<String>(
                            value: countryValue,
                            items: _countriesList
                                .map((c) => c['name'] as String)
                                .toList(),
                            hint: 'Select',
                            showSearch: true,
                            showSearchIcon: true,
                            onChanged: (v) {
                              if (v == null) return;
                              setDialogState(() {
                                countryValue = v;
                                stateValue = null;
                                localStates = [];
                              });
                              fetchStates(v);
                            },
                            itemBuilder: (item, isSelected, isHovered) =>
                                _buildStandardLookupRow(
                                  item,
                                  isSelected,
                                  isHovered,
                                ),
                          ),
                          const SizedBox(height: 14),

                          _addressLabel('Address'),
                          _zField(s1Ctrl, hint: 'Street 1'),
                          const SizedBox(height: 10),
                          _zField(s2Ctrl, hint: 'Street 2'),
                          const SizedBox(height: 14),

                          _addressLabel('City'),
                          _zField(cityCtrl),
                          const SizedBox(height: 14),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _addressLabel('State'),
                                    FormDropdown<String>(
                                      value: stateValue,
                                      isLoading: isLoadingStates,
                                      items: localStates
                                          .map((s) => s['name'] as String)
                                          .toList(),
                                      hint: 'Select or type to add',
                                      allowCustomValue: true,
                                      showSearch: true,
                                      onChanged: (v) =>
                                          setDialogState(() => stateValue = v),
                                      itemBuilder:
                                          (item, isSelected, isHovered) =>
                                              _buildStandardLookupRow(
                                                item,
                                                isSelected,
                                                isHovered,
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _addressLabel('Pin Code'),
                                    _zField(pinCtrl),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _addressLabel('Phone'),
                                    _buildPhoneRow(
                                      code: phoneCodeValue,
                                      onCodeChanged: (v) => setDialogState(
                                        () => phoneCodeValue = v,
                                      ),
                                      controller: phoneCtrl,
                                      onChanged: (v) {},
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _addressLabel('Fax Number'),
                                    _zField(faxCtrl),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            'Note: Changes made here will be updated for this customer.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE5E7EB)),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final data = <String, dynamic>{
                              'attention': attCtrl.text.trim(),
                              'street1': s1Ctrl.text.trim(),
                              'street2': s2Ctrl.text.trim(),
                              'city': cityCtrl.text.trim(),
                              'state': stateValue ?? '',
                              'zip': pinCtrl.text.trim(),
                              'country': countryValue ?? '',
                              'phone':
                                  '$phoneCodeValue ${phoneCtrl.text.trim()}',
                              'phoneCode': phoneCodeValue,
                              'fax': faxCtrl.text.trim(),
                            };

                            if (vendor != null) {
                              final updated = isBilling
                                  ? vendor.copyWith(billingAddress: data)
                                  : vendor.copyWith(shippingAddress: data);
                              ref
                                  .read(vendorProvider.notifier)
                                  .updateVendor(vendor.id, updated);
                            } else if (wh != null) {
                              // Update warehouse logically in local state if supported
                              // or trigger warehouse update API
                            } else if (cust != null) {
                              // Update customer logic
                            }

                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFF374151)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _addressLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.normal,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildStandardLookupRow(
    String label,
    bool isSelected,
    bool isHovered, {
    String? sublabel,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          if (isSelected) Icon(Icons.check, size: 14, color: check),
        ],
      ),
    );
  }

  Widget _buildPhoneRow({
    required String code,
    required ValueChanged<String> onCodeChanged,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 75,
          child: FormDropdown<String>(
            value: code,
            items: _phoneCodesList,
            menuWidth: 240,
            displayStringForValue: (v) => v,
            searchStringForValue: (v) => v,
            showSearch: true,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            itemBuilder: (item, isSelected, isHovered) =>
                _buildPhonePrefixRow(item, isSelected, isHovered),
            onChanged: (v) => onCodeChanged(v ?? '+91'),
          ),
        ),
        Expanded(
          child: _zField(
            controller,
            onChanged: onChanged,
            // Custom border to align with prefix
          ),
        ),
      ],
    );
  }

  Widget _buildPhonePrefixRow(String code, bool isSelected, bool isHovered) {
    String name = _phoneCodeToLabel[code] ?? '';
    Color bg = Colors.transparent;
    Color textColor = const Color(0xFF1F2937);
    Color nameColor = const Color(0xFF6B7280);

    if (isSelected) {
      bg = const Color(0xFF3B82F6);
      textColor = Colors.white;
      nameColor = Colors.white70;
    } else if (isHovered) {
      bg = const Color(0xFFF3F4F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: bg,
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              code,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: nameColor),
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
  }) {
    return Row(
      crossAxisAlignment: crossStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isRequired ? _requiredLabel : _labelColor,
                    fontWeight: isRequired
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (isRequired)
                  const TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: _requiredLabel,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(child: child),
      ],
    );
  }

  Widget _zField(
    TextEditingController ctrl, {
    String hint = '',
    Function(String)? onChanged,
    VoidCallback? onTap,
    bool readOnly = false,
    Widget? suffixIcon,
    TextAlign textAlign = TextAlign.start,
  }) {
    return _HoverableField(
      builder: (isHovered) => SizedBox(
        height: 36,
        child: TextField(
          controller: ctrl,
          onChanged: onChanged,
          onTap: onTap,
          textAlign: textAlign,
          readOnly: readOnly || (onTap != null && onChanged == null),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: _hintColor),
            contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _bgWhite,
          ),
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
          Icons.calendar_today_outlined,
          size: 16,
          color: _hintColor,
        ),
      ),
    );
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
                color: isSelected ? _linkBlue : const Color(0xFFAAAAAA),
                width: 1.5,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: _linkBlue,
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

  Widget _searchBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _greenBtn,
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Icon(Icons.search, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _tableActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasDropdown = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: _linkBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _linkBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 16, color: _linkBlue),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(
    String label,
    bool isActive,
    VoidCallback onTap, {
    bool small = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: small ? 28 : null,
        height: small ? 24 : 30,
        padding: small
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _linkBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(small ? 2 : 0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : _labelColor,
            fontSize: small ? 10 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WAREHOUSE DROPDOWN HELPER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWarehouseDropdownItem(
    WarehouseModel w,
    bool isSelected,
    bool isHovered,
  ) {
    final subtitle = [
      w.city,
      w.state,
      w.countryRegion,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isHovered
          ? const Color(0xFF2563EB)
          : (isSelected ? const Color(0xFFEFF6FF) : Colors.transparent),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isHovered
                  ? Colors.white.withValues(alpha: 0.2)
                  : (isSelected
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.warehouse_outlined,
              size: 16,
              color: isHovered
                  ? Colors.white
                  : (isSelected ? _greenBtn : _hintColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  w.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isHovered
                        ? Colors.white
                        : (isSelected ? _linkBlue : _textPrimary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isHovered
                          ? Colors.white.withValues(alpha: 0.8)
                          : _hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 14,
              color: isHovered ? Colors.white : _linkBlue,
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VENDOR DROPDOWN HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildVendorDropdownItem(Vendor v, bool isSelected, bool isHovered) {
    final List<Color> avatarColors = [
      const Color(0xFFE57373),
      const Color(0xFFF06292),
      const Color(0xFFBA68C8),
      const Color(0xFF9575CD),
      const Color(0xFF7986CB),
      const Color(0xFF64B5F6),
      const Color(0xFF4FC3F7),
      const Color(0xFF4DD0E1),
      const Color(0xFF4DB6AC),
      const Color(0xFF81C784),
      const Color(0xFFAED581),
      const Color(0xFFFFD54F),
    ];
    final colorIdx = v.displayName.isNotEmpty
        ? v.displayName.codeUnitAt(0) % avatarColors.length
        : 0;
    final letter = v.displayName.isNotEmpty
        ? v.displayName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isHovered
          ? const Color(0xFF2563EB)
          : (isSelected ? const Color(0xFFEFF6FF) : Colors.transparent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isHovered
                  ? Colors.white
                  : avatarColors[colorIdx].withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHovered
                    ? const Color(0xFF2563EB)
                    : avatarColors[colorIdx],
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        v.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isHovered
                              ? Colors.white
                              : (isSelected ? _linkBlue : _textPrimary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (v.vendorNumber != null &&
                        v.vendorNumber!.isNotEmpty) ...[
                      Text(
                        ' | ',
                        style: TextStyle(
                          color: isHovered
                              ? Colors.white.withValues(alpha: 0.6)
                              : _hintColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        v.vendorNumber!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isHovered
                              ? Colors.white.withValues(alpha: 0.6)
                              : _hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
                if (v.companyName != null && v.companyName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      v.companyName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isHovered
                            ? Colors.white.withValues(alpha: 0.7)
                            : _hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// ═════════════════════════════════════════════════════════════════════════════
// BULK ADD MODAL
// ═════════════════════════════════════════════════════════════════════════════
class _BulkAddModal extends StatefulWidget {
  final List<Item> items;
  final Function(List<PurchaseOrderItem>) onAdd;
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
        final matchSearch = _search.isEmpty ||
            i.productName.toLowerCase().contains(_search.toLowerCase()) ||
            i.itemCode.toLowerCase().contains(_search.toLowerCase());
        final matchCat = _selectedCategory == 'All' ||
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
            // ── Header ──
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
                    icon: const Icon(Icons.close, size: 18, color: _dangerRed),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderCol),
            // ── Two-pane body ──
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left pane ──
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
                              // Category filter
                              Row(
                                children: [
                                  PopupMenuButton<String>(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    color: Colors.white,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: _fieldBorder),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.filter_alt_outlined,
                                              size: 18, color: Color(0xFF0088FF)),
                                          const SizedBox(width: 4),
                                          Text('Category',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: _textPrimary)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.keyboard_arrow_down,
                                              size: 16, color: _hintColor),
                                        ],
                                      ),
                                    ),
                                    itemBuilder: (_) => _categories
                                        .map((c) => PopupMenuItem(
                                            value: c,
                                            child: Text(c,
                                                style: const TextStyle(
                                                    fontSize: 13))))
                                        .toList(),
                                    onSelected: (v) =>
                                        setState(() => _selectedCategory = v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Search
                              TextField(
                                controller: _searchCtrl,
                                onChanged: (v) =>
                                    setState(() => _search = v),
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText:
                                      'Type to search or scan the barcode of the item',
                                  hintStyle: const TextStyle(
                                      fontSize: 12, color: _hintColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide:
                                        const BorderSide(color: _fieldBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide:
                                        const BorderSide(color: _fieldBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF0088FF)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Item list
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
                                      horizontal: 16, vertical: 10),
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
                                                color: _textPrimary,
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
                                                  color: _hintColor),
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
                  // Vertical divider
                  Container(width: 1, color: _borderCol),
                  // ── Right pane ──
                  Expanded(
                    flex: 45,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              const Text('Selected Items',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _textPrimary)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('$_selectedCount',
                                    style: const TextStyle(
                                        fontSize: 12, 
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary)),
                              ),
                              const Spacer(),
                              Text('Total Quantity: $_totalQty',
                                  style: const TextStyle(
                                      fontSize: 12, color: _hintColor)),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: _borderCol),
                        Expanded(
                          child: _selectedItems.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'Click the item names from the left pane to select them',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13, color: _hintColor),
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
                                          horizontal: 16, vertical: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(item.productName,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: _textPrimary)),
                                          ),
                                          Container(
                                            height: 28,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: _fieldBorder),
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
                                                const VerticalDivider(width: 1, color: _borderCol),
                                                Container(
                                                  width: 32,
                                                  alignment: Alignment.center,
                                                  child: Text('$count',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: _textPrimary)),
                                                ),
                                                const VerticalDivider(width: 1, color: _borderCol),
                                                GestureDetector(
                                                  onTap: () => setState(
                                                      () => _counts[id] = count + 1),
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
            // ── Footer ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _borderCol))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _selectedItems.isEmpty
                        ? null
                        : () {
                            final result = _selectedItems.map((i) {
                              final qty =
                                  (_counts[i.id ?? ''] ?? 1).toDouble();
                              return PurchaseOrderItem(
                                productId: i.id ?? '',
                                productName: i.productName,
                                quantity: qty,
                                rate: i.costPrice ?? 0.0,
                                amount: qty * (i.costPrice ?? 0.0),
                              );
                            }).toList();
                            widget.onAdd(result);
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenBtn,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Add Items',
                        style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style:
                            TextStyle(fontSize: 13, color: _textPrimary)),
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

// ═════════════════════════════════════════════════════════════════════════════
// ADVANCED VENDOR SEARCH DIALOG
// ═════════════════════════════════════════════════════════════════════════════
class _AdvancedVendorSearchDialog extends StatefulWidget {
  final List<Vendor> vendors;
  final Function(Vendor) onSelect;

  const _AdvancedVendorSearchDialog({
    required this.vendors,
    required this.onSelect,
  });

  @override
  State<_AdvancedVendorSearchDialog> createState() =>
      _AdvancedVendorSearchDialogState();
}

class _AdvancedVendorSearchDialogState
    extends State<_AdvancedVendorSearchDialog> {
  String _selectedCategory = 'Vendor Number';
  final TextEditingController _searchCtrl = TextEditingController();
  List<Vendor> _filteredVendors = [];
  int _hoveredIndex = -1;

  final List<String> _categories = [
    'Vendor Number',
    'Display Name',
    'Company Name',
    'First Name',
    'Last Name',
    'Email',
    'Phone',
  ];

  @override
  void initState() {
    super.initState();
    _filteredVendors = widget.vendors;
  }

  void _onSearch() {
    setState(() {
      final query = _searchCtrl.text.toLowerCase();
      if (query.isEmpty) {
        _filteredVendors = widget.vendors;
        return;
      }

      _filteredVendors = widget.vendors.where((v) {
        switch (_selectedCategory) {
          case 'Vendor Number':
            return (v.vendorNumber ?? '').toLowerCase().contains(query);
          case 'Display Name':
            return v.displayName.toLowerCase().contains(query);
          case 'Company Name':
            return (v.companyName ?? '').toLowerCase().contains(query);
          case 'First Name':
            return (v.firstName ?? '').toLowerCase().contains(query);
          case 'Last Name':
            return (v.lastName ?? '').toLowerCase().contains(query);
          case 'Email':
            return (v.email ?? '').toLowerCase().contains(query);
          case 'Phone':
            return (v.phone ?? '').toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 800,
        height: 600,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Advanced Vendor Search',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFEF4444)),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Filter Area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Category Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCCCCCC)),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      color: const Color(0xFFF9FAFB),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF6B7280),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                        ),
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val!),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  // Search Input
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => _onSearch(),
                        onSubmitted: (_) => _onSearch(),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Color(0xFF1D4ED8),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Search Button
                  GestureDetector(
                    onTap: _onSearch,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Search',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFFF9FAFB),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'VENDOR NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'EMAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'COMPANY NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
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
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Body
            Expanded(
              child: ListView.separated(
                itemCount: _filteredVendors.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (ctx, index) {
                  final v = _filteredVendors[index];
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = -1),
                    child: GestureDetector(
                      onTap: () => widget.onSelect(v),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        color: _hoveredIndex == index
                            ? const Color(0xFFEFF6FF)
                            : Colors.white,
                        child: Row(
                          children: [
                            // Vendor Name & Number
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.displayName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                  if (v.vendorNumber != null)
                                    Text(
                                      v.vendorNumber!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Email
                            Expanded(
                              flex: 2,
                              child: Text(
                                v.email ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                            // Company Name
                            Expanded(
                              flex: 2,
                              child: Text(
                                v.companyName ?? '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                            // Phone
                            Expanded(
                              flex: 2,
                              child: Text(
                                v.phone ?? v.mobilePhone ?? '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Pagination Footer
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          size: 16,
                          color: Color(0xFF999999),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '1 - ${_filteredVendors.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Color(0xFF999999),
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
    );
  }
}

class _ConfigureTaxPreferencesDialog extends StatefulWidget {
  final String initialTreatment;
  final Function(String, bool) onUpdate;
  final VoidCallback onCancel;

  const _ConfigureTaxPreferencesDialog({
    required this.initialTreatment,
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

  @override
  void initState() {
    super.initState();
    _selectedTreatment = widget.initialTreatment;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
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
            borderRadius: BorderRadius.circular(4),
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
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    ),
                    const SizedBox(height: 8),
                    FormDropdown<Map<String, String>>(
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
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : (isHovered
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
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['desc']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _selectedTreatment = val['label']!);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Make it permanent?',
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
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
                            activeColor: const Color(0xFF22C55E),
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
                          widget.onUpdate(_selectedTreatment, _makePermanent),
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
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                        style: TextStyle(color: Color(0xFF333333)),
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

class _OpenPurchaseOrdersPopover extends StatelessWidget {
  final List<Map<String, String>> orders;

  const _OpenPurchaseOrdersPopover({required this.orders});

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
              color: const Color(0xFF3481F4),
              isUp: true,
            ),
          ),
        ),
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3481F4), width: 1.5),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Recent Orders',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              if (orders.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: const Text(
                    'There are no Purchase Orders',
                    style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (ctx, idx) {
                    final o = orders[idx];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: idx < orders.length - 1
                            ? const Border(
                                bottom: BorderSide(color: Color(0xFFEEEEEE)),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o['po']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                o['date']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                o['amount']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                o['status']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF3481F4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

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

// ── Dashed Border Painter ─────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFFCCCCCC);
    const dashWidth = 4.0;
    const dashSpace = 3.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(3),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// VENDOR DETAILS SIDEBAR
// ═════════════════════════════════════════════════════════════════════════════
class _VendorSidebar extends StatefulWidget {
  final Vendor vendor;
  final VoidCallback onClose;

  const _VendorSidebar({required this.vendor, required this.onClose});

  @override
  State<_VendorSidebar> createState() => _VendorSidebarState();
}

class _VendorSidebarState extends State<_VendorSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isContactPersonsOpen = false;
  bool _isAddressOpen = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    _controller.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _handleClose,
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        SlideTransition(
          position: _offsetAnimation,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 450,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(-2, 0),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    _buildHeader(),
                    const Divider(height: 1),
                    _buildTabs(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFinancialSummary(),
                            const SizedBox(height: 24),
                            _buildContactDetails(),
                            const SizedBox(height: 24),
                            _buildCollapsibleSection(
                              title: 'Contact Persons',
                              count: widget.vendor.contactPersons?.length ?? 0,
                              isOpen: _isContactPersonsOpen,
                              onToggle: () => setState(
                                () => _isContactPersonsOpen =
                                    !_isContactPersonsOpen,
                              ),
                              child: _buildContactPersonsList(),
                            ),
                            const SizedBox(height: 16),
                            _buildCollapsibleSection(
                              title: 'Address',
                              isOpen: _isAddressOpen,
                              onToggle: () => setState(
                                () => _isAddressOpen = !_isAddressOpen,
                              ),
                              child: _buildAddressSection(),
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
  }

  Widget _buildHeader() {
    final initials = widget.vendor.displayName.isNotEmpty
        ? widget.vendor.displayName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  widget.vendor.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _handleClose,
            child: const Icon(Icons.close, size: 20, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabItem('Details', true),
          _buildTabItem('Activity Log', false),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isActive
            ? const Border(
                bottom: BorderSide(color: Color(0xFF3B82F6), width: 2),
              )
            : null,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Outstanding Payables',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹0.00',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Icon(Icons.adjust, size: 16, color: Colors.green),
                const SizedBox(height: 8),
                const Text(
                  'Unused Credits',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹0.00',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Currency', widget.vendor.currency ?? 'INR'),
          _buildDetailRow(
            'Payment Terms',
            widget.vendor.paymentTerms ?? 'Net 360',
          ),
          _buildDetailRow(
            'Portal Status',
            widget.vendor.enablePortal == true ? 'Enabled' : 'Disabled',
          ),
          _buildDetailRow(
            'Vendor Language',
            widget.vendor.vendorLanguage ?? 'English',
          ),
          _buildDetailRow(
            'GST Treatment',
            widget.vendor.gstTreatment ?? 'Unregistered Business',
          ),
          _buildDetailRow(
            'Source of Supply',
            widget.vendor.sourceOfSupply ?? 'Kerala',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    int? count,
    required bool isOpen,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
        if (isOpen) child,
      ],
    );
  }

  Widget _buildContactPersonsList() {
    final list = widget.vendor.contactPersons ?? [];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: list.isEmpty
          ? const Center(
              child: Text(
                'No contact persons',
                style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            )
          : Column(
              children: list.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p['firstName']?[0].toUpperCase() ?? '?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (p['email'] != null)
                            Text(
                              p['email'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddressBlock('Billing Address', widget.vendor.billingAddress),
          const SizedBox(height: 24),
          _buildAddressBlock('Shipping Address', widget.vendor.shippingAddress),
        ],
      ),
    );
  }

  Widget _buildAddressBlock(String title, Map<String, dynamic>? address) {
    String content = 'No address provided';
    if (address != null) {
      final List<String> lines = [];
      if (address['attention'] != null &&
          address['attention'].toString().trim().isNotEmpty)
        lines.add(address['attention']);
      if (address['street1'] != null &&
          address['street1'].toString().trim().isNotEmpty)
        lines.add(address['street1']);
      if (address['street2'] != null &&
          address['street2'].toString().trim().isNotEmpty)
        lines.add(address['street2']);
      final cityStateZip = [
        address['city'],
        address['state'],
        address['zip'],
      ].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
      if (cityStateZip.isNotEmpty) lines.add(cityStateZip);
      if (address['country'] != null &&
          address['country'].toString().trim().isNotEmpty)
        lines.add(address['country']);

      if (lines.isNotEmpty) {
        content = lines.join('\n');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            height: 1.5,
          ),
        ),
      ],
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

// ─── Hover-aware field wrapper ───────────────────────────────────────────────
// Tracks mouse hover and exposes `isActive` to the builder so fields can
// switch their border/fill color on hover (in addition to Flutter's native
// focus handling inside InputDecoration.focusedBorder).
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

// ── Warehouse Stock Dialog ────────────────────────────────────────────────────

class _WarehouseStockDialog extends ConsumerStatefulWidget {
  final PurchaseOrderItem item;
  final List<WarehouseModel> warehouses;
  final String? selectedWarehouseId;
  final String initialStockView; // 'stockOnHand' | 'availableForSale'
  final void Function(String warehouseId) onWarehouseSelected;
  final void Function(String view) onViewChanged;
  final VoidCallback onClose;

  const _WarehouseStockDialog({
    required this.item,
    required this.warehouses,
    required this.selectedWarehouseId,
    required this.initialStockView,
    required this.onWarehouseSelected,
    required this.onViewChanged,
    required this.onClose,
  });

  @override
  ConsumerState<_WarehouseStockDialog> createState() =>
      _WarehouseStockDialogState();
}

class _WarehouseStockDialogState extends ConsumerState<_WarehouseStockDialog> {
  String _viewMode = 'physical'; // 'physical' | 'accounting'
  late String _stockView; // 'stockOnHand' | 'availableForSale'
  String? _selectedWarehouseId;

  static const _blue = Color(0xFF0088FF);
  static const _textDark = Color(0xFF1F2937);
  static const _textGrey = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _headerBg = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _selectedWarehouseId = widget.selectedWarehouseId;
    _stockView = widget.initialStockView;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Warehouse Locations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'View: ',
                        style: TextStyle(fontSize: 12, color: _textGrey),
                      ),
                      // View dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: _blue),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.white,
                        ),
                        height: 32,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _stockView,
                            isDense: true,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textDark,
                              fontWeight: FontWeight.w500,
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: _blue,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'stockOnHand',
                                child: Text('Stock on Hand'),
                              ),
                              DropdownMenuItem(
                                value: 'availableForSale',
                                child: Text('Available for Sale'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _stockView = v);
                              widget.onViewChanged(v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Toggle buttons
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _blue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            _buildToggle('Accounting Stock', 'accounting'),
                            _buildToggle(
                              'Physical Stock',
                              'physical',
                              isRight: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(
                          Icons.close,
                          size: 22,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _border),

                // ── Table ───────────────────────────────────────────────────────
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Table header
                      Container(
                        decoration: const BoxDecoration(
                          color: _headerBg,
                          border: Border(bottom: BorderSide(color: _border)),
                        ),
                        child: Column(
                          children: [
                            // Spanning sub-header
                            Row(
                              children: [
                                const SizedBox(width: 260),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        left: BorderSide(color: _border),
                                        bottom: BorderSide(color: _border),
                                      ),
                                    ),
                                    child: Text(
                                      _viewMode == 'physical'
                                          ? 'Physical Stock'
                                          : 'Accounting Stock',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _textGrey,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Column labels
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 244,
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Warehouse Name',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _textGrey,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.search,
                                          size: 14,
                                          color: _textGrey,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _headerCell('Stock on Hand'),
                                  _headerCell('Committed Stock'),
                                  _headerCell(
                                    'Available for Sale',
                                    icon: Icons.visibility_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Warehouse rows
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: widget.warehouses.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: _border),
                          itemBuilder: (_, idx) {
                            final wh = widget.warehouses[idx];
                            return _WarehouseStockRow(
                              warehouse: wh,
                              productId: widget.item.productId,
                              isSelected: _selectedWarehouseId == wh.id,
                              onSelect: () {
                                setState(() => _selectedWarehouseId = wh.id);
                                widget.onWarehouseSelected(wh.id);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Footer legend ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendRow(
                        'Stock on Hand',
                        ': This is calculated based on Receives and Shipments.',
                      ),
                      const SizedBox(height: 4),
                      _legendRow(
                        'Committed Stock',
                        ': Stock that is committed to sales order(s) but not yet shipped',
                      ),
                      const SizedBox(height: 4),
                      _legendRow(
                        'Available for Sale',
                        ': Stock on Hand – Committed Stock',
                      ),
                    ],
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildToggle(String label, String mode, {bool isRight = false}) {
    final selected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _blue : Colors.white,
          borderRadius: isRight
              ? const BorderRadius.horizontal(right: Radius.circular(3))
              : const BorderRadius.horizontal(left: Radius.circular(3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _blue,
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String label, {IconData? icon}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textGrey,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 3),
            Icon(icon, size: 12, color: _textGrey),
          ],
        ],
      ),
    );
  }

  Widget _legendRow(String bold, String normal) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: _textGrey),
        children: [
          TextSpan(
            text: bold,
            style: const TextStyle(color: _blue, fontWeight: FontWeight.w500),
          ),
          TextSpan(text: normal),
        ],
      ),
    );
  }
}

// ── Warehouse Stock Row ───────────────────────────────────────────────────────

class _WarehouseStockRow extends ConsumerWidget {
  final WarehouseModel warehouse;
  final String productId;
  final bool isSelected;
  final VoidCallback onSelect;

  const _WarehouseStockRow({
    required this.warehouse,
    required this.productId,
    required this.isSelected,
    required this.onSelect,
  });

  static const _blue = Color(0xFF0088FF);
  static const _textDark = Color(0xFF1F2937);
  static const _textGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockByWarehouseProvider(warehouse.id));
    final stock = stockAsync.valueOrNull
        ?.where((s) => s.productId == productId)
        .firstOrNull;

    String fmt(double? v) => v != null ? v.toStringAsFixed(2) : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Radio + name
          GestureDetector(
            onTap: onSelect,
            child: SizedBox(
              width: 244,
              child: Row(
                children: [
                  // Custom radio circle
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _blue : const Color(0xFFD1D5DB),
                        width: isSelected ? 5 : 1,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      warehouse.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? _blue : _textDark,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.star,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Stock values
          if (stockAsync.isLoading)
            const Expanded(
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
            )
          else ...[
            _valueCell(fmt(stock?.quantityOnHand)),
            _valueCell(fmt(null)),
            _valueCell(
              fmt(stock?.availableQuantity),
              bold: true,
              color: (stock?.availableQuantity ?? 0) > 0
                  ? _textDark
                  : _textGrey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _valueCell(String text, {bool bold = false, Color? color}) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: color ?? _textDark,
        ),
      ),
    );
  }
}

class _TaxSelectionPopover extends StatelessWidget {
  final String? selectedTaxId;
  final List<TaxRate> taxes;
  final ValueChanged<TaxRate> onTaxSelected;

  const _TaxSelectionPopover({
    this.selectedTaxId,
    required this.taxes,
    required this.onTaxSelected,
  });

  @override
  Widget build(BuildContext context) {
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Tax',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: taxes.length,
                itemBuilder: (context, i) {
                  final tax = taxes[i];
                  final isSelected = tax.id == selectedTaxId;
                  final displayLabel = '${tax.taxName} [${tax.taxRate}%]';

                  return _PopoverListItem(
                    label: displayLabel,
                    isSelected: isSelected,
                    onTap: () => onTaxSelected(tax),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _AccountSelectionPopover extends StatefulWidget {
  final List<AccountNode> accounts;
  final String? selectedAccountId;
  final ValueChanged<AccountNode> onSelected;

  const _AccountSelectionPopover({
    required this.accounts,
    this.selectedAccountId,
    required this.onSelected,
  });

  @override
  State<_AccountSelectionPopover> createState() => _AccountSelectionPopoverState();
}

class _AccountSelectionPopoverState extends State<_AccountSelectionPopover> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  Map<String, List<AccountNode>> get _grouped {
    final Map<String, List<AccountNode>> grouped = {};
    for (var acc in widget.accounts) {
      if (_search.isNotEmpty && !acc.name.toLowerCase().contains(_search.toLowerCase())) {
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
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Select an account',
                      prefixIcon: const Icon(Icons.search, size: 16, color: _hintColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                GestureDetector(
                  onTap: () {}, // Handle close from outside usually
                  child: const Icon(Icons.close, size: 14, color: _hintColor),
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
                    // Group Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _hintColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Items
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
          const Divider(height: 1),
        ],
      ),
    );
  }
}

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
    final bg = widget.isSelected || _hover ? const Color(0xFF0088FF) : Colors.transparent;
    final text = widget.isSelected || _hover ? Colors.white : const Color(0xFF333333);

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
              if (widget.isSelected)
                Icon(Icons.check, size: 14, color: text),
            ],
          ),
        ),
      ),
    );
  }
}

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
        color: _hover ? const Color(0xFF0088FF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            color: _hover ? Colors.white : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

class _HoverableToggleMenuItem extends StatefulWidget {
  final String label;
  final bool value;
  const _HoverableToggleMenuItem(this.label, this.value);

  @override
  State<_HoverableToggleMenuItem> createState() => _HoverableToggleMenuItemState();
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
        color: _hover ? const Color(0xFF0088FF) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              widget.value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: _hover ? Colors.white : (widget.value ? const Color(0xFF2563EB) : const Color(0xFF8E8E93)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _hover ? Colors.white : const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  static const _blueColor = Color(0xFF0088FF);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Triangle/Caret
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
                child: Row(
                  children: [
                    Expanded(
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
                            borderSide: const BorderSide(color: _blueColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: _blueColor),
                          ),
                          hintText: 'Enter HSN code',
                          hintStyle: const TextStyle(
                            color: _hintColor,
                            fontSize: 13,
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onSubmitted: (v) => widget.onSave(v.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.search, color: _blueColor, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE5E5EA)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 13, color: _textPrimary),
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


