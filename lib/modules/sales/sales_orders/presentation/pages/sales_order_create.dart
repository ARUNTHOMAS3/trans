// ignore_for_file: unused_element, duplicate_ignore
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_adaptive_menu.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:intl/intl.dart' as intl;
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/manage_tds_tcs_rates_dialog.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/address_dialog.dart';

import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/items_stock_providers.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_item_model.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/pricelists/branch_pricelist/providers/branch_pricelist_provider.dart';
import 'package:zerpai_erp/modules/pricelists/branch_pricelist/models/branch_pricelist_model.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/sales_order_item_row.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/item_quick_edit_dialog.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import '../widgets/advanced_customer_search_dialog.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import '../widgets/sales_order_preferences_dialog.dart';
import 'package:zerpai_erp/modules/sales/customers/presentation/sales_customer_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/po_item_details_sidebar_widget.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/customer_sidebar.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/shared/services/sequences_api_service.dart';

// ─── Colour constants ────────────────────────────────────────────────────────
const _kBorder = Color(0xFFE5E7EB);
const _kLabelGrey = Color(0xFF6B7280);
const _kBodyText = Color(0xFF111827);
const _kBlue = Color(0xFF2563EB);
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
  final bool isClone;

  const SalesOrderCreateScreen({
    super.key,
    this.initialOrder,
    this.initialOrderId,
    this.initialCustomerId,
    this.cloneId,
    this.isClone = false,
  });

  @override
  ConsumerState<SalesOrderCreateScreen> createState() =>
      _SalesOrderCreateScreenState();
}

// class SalesOrderItemRow moved to shared file

class _SalesOrderCreateScreenState
    extends ConsumerState<SalesOrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  OverlayEntry? _taxOverlay;

  String? _selectedCustomerId;
  SalesCustomer? _selectedCustomer;
  AccountNode? _selectedPopupAccount;
  int? _hoveredRowIndex;

  bool get _isCustomerUnregistered {
    final customerFromList = _selectedCustomerId == null
        ? null
        : ref
            .read(salesCustomersProvider)
            .asData
            ?.value
            .where((c) => c.id == _selectedCustomerId)
            .firstOrNull;
    final activeCustomer = _selectedCustomer ?? customerFromList;
    return activeCustomer != null &&
        (activeCustomer.gstTreatment == null ||
            activeCustomer.gstTreatment!.toLowerCase().contains('unregistered') ||
            activeCustomer.gstTreatment! == 'Unregistered Business');
  }

  late final TextEditingController salesOrderNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;
  late final TextEditingController termsCtrl;
  late final TextEditingController shippingCtrl;
  late final TextEditingController adjustmentCtrl;
  final FocusNode _adjustmentLabelFocusNode = FocusNode();

  DateTime salesOrderDate = DateTime.now();
  DateTime? expectedShipmentDate;
  bool _isExpectedShipmentHovered = false;
  String? paymentTerms;
  String? deliveryMethod;
  String? salesperson;
  String? warehouse;
  String _selectedStockView = 'Available for Sale';
  String _selectedStockType = 'Physical';
  String? priceListId;
  String? placeOfSupply;

  List<SalesOrderItemRow> rows = [];

  double subTotal = 0.0;
  double taxTotal = 0.0;
  double total = 0.0;
  double _roundOff = 0.0;
  List<Map<String, dynamic>> taxLines = [];
  String _tdsTcsType = 'none';
  String? _selectedTdsTcsId;
  double _tdsTcsRate = 0.0;
  List<Map<String, dynamic>> _tdsRatesList = [];
  List<Map<String, dynamic>> _tdsSectionsList = [];
  List<Map<String, dynamic>> _tcsRatesList = [];
  List<Map<String, dynamic>> _tcsNaturesList = [];
  bool _isLoadingTdsRates = false;
  final LayerLink _tdsLink = LayerLink();
  bool _isTdsOpen = false;
  OverlayEntry? _tdsOverlay;

  bool _showBulkUpdateToolbar = false;
  List<Map<String, dynamic>> _paymentTermsList = [];
  String? _defaultPaymentTermId;
  List<Map<String, dynamic>> _salespersonList = [];
  List<Map<String, dynamic>> _carriersList = [];

  final Set<int> _selectedRows = {};
  final _scanCtrl = TextEditingController();
  final _scanFocusNode = FocusNode();
  final _gstTaxLink = LayerLink();
  OverlayEntry? _gstTaxOverlay;
  final _gstinLink = LayerLink();
  OverlayEntry? _gstinOverlay;
  OverlayEntry? _addressDropdownOverlay;
  final LayerLink _billingAddressLink = LayerLink();
  final LayerLink _shippingAddressLink = LayerLink();

  final _bulkActionsLink = LayerLink();
  final _settingsLink = LayerLink();
  OverlayEntry? _settingsOverlay;

  String _saleType = 'Retail'; // Default
  bool _showAdditionalInfo = true;
  bool _showAvailableStock = true;
  bool _showRecentTransactions = true;
  bool _showPriceList = true;
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
  List<PlatformFile> _attachedFiles = [];
  OverlayEntry? _attachmentListOverlay;
  final LayerLink _attachmentBadgeLink = LayerLink();
  final _salesOrderDateKey = GlobalKey();
  final _expectedShipmentDateKey = GlobalKey();
  bool _isAdjustmentLabelHovered = false;

  bool _isAutoGenerateSO = true;
  String _soPrefix = 'SO-';
  String _soNextNumber = '00001';

  bool _showSearchItemDetails = false;
  String _itemDetailsSearchQuery = '';
  final TextEditingController _itemDetailsSearchCtrl = TextEditingController();

  late TextEditingController adjustmentLabelCtrl;
  double get _tdsTcsAmount {
    if (_tdsTcsType == 'none' || _selectedTdsTcsId == null) return 0.0;
    return subTotal * _tdsTcsRate / 100;
  }

  bool _isHydratingInitialOrder = false;

  String? _normalizePlaceOfSupply(String? val) {
    if (val == null) return null;
    final lowercase = val.toLowerCase();
    if (lowercase.contains('kerala') || lowercase.contains('[kl]') || lowercase == 'kl') {
      return '[KL] - Kerala';
    }
    if (lowercase.contains('tamil nadu') || lowercase.contains('[tn]') || lowercase == 'tn') {
      return '[TN] - Tamil Nadu';
    }
    if (lowercase.contains('karnataka') || lowercase.contains('[ka]') || lowercase == 'ka') {
      return '[KA] - Karnataka';
    }
    return null;
  }

  bool get _isEditMode =>
      !widget.isClone &&
      (widget.initialOrder != null ||
       (widget.initialOrderId != null && widget.initialOrderId!.isNotEmpty));

  String? get _editingOrderId {
    if (widget.isClone) return null;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(warehousesProvider);
      ref.invalidate(salesCustomersProvider);
      ref.invalidate(priceListNotifierProvider);
      ref.invalidate(branchPriceListNotifierProvider);
    });
    salesOrderNumberCtrl = TextEditingController(
      text: '$_soPrefix$_soNextNumber',
    );
    salesperson = null;
    // paymentTerms = 'Net 360'; // Loaded dynamically in _loadPaymentTerms
    warehouse = '';

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
      _hydrateFromInitialOrder(widget.initialOrder!, isClone: widget.isClone);
      if (widget.isClone) {
        _loadNextSalesOrderNumber();
      }
    } else if (widget.initialOrderId != null &&
        widget.initialOrderId!.isNotEmpty) {
      _loadInitialOrder(widget.initialOrderId!);
    } else if (widget.cloneId != null && widget.cloneId!.isNotEmpty) {
      _loadInitialOrder(widget.cloneId!, isClone: true);
    } else {
      rows.add(_createItemRow());
      _loadNextSalesOrderNumber();
    }
    _loadPaymentTerms();
    _loadCarriers();
    _loadSalespersons();
    _loadTdsRates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsControllerProvider.notifier).loadLookupData();
    });
  }

  Future<void> _loadNextSalesOrderNumber() async {
    if (_isEditMode) return;
    try {
      final nextNo = await ref
          .read(sequencesApiServiceProvider)
          .getNextNumber('sale');
      if (mounted) {
        setState(() {
          salesOrderNumberCtrl.text = nextNo;
        });
      }
    } catch (e) {
      debugPrint('Error loading next SO number: $e');
    }
  }

  Future<void> _loadInitialOrder(String orderId, {bool isClone = false}) async {
    setState(() => _isHydratingInitialOrder = true);
    try {
      final order = await ref
          .read(salesOrderApiServiceProvider)
          .getSalesOrderById(orderId);

      // Load attachments
      final supabase = Supabase.instance.client;
      final attachmentsData = await supabase
          .from('sales_order_attachments')
          .select()
          .eq('sales_order_id', orderId);

      if (!mounted) return;

      setState(() {
        rows.clear();
        _hydrateFromInitialOrder(order, isClone: isClone);

        if (!isClone) {
          _attachedFiles = (attachmentsData as List).map<PlatformFile>((row) {
            final sizeVal = row['file_size'];
            int parsedSize = 0;
            if (sizeVal is int) {
              parsedSize = sizeVal;
            } else if (sizeVal is String) {
              parsedSize = int.tryParse(sizeVal) ?? 0;
            }
            return PlatformFile(name: row['file_name'] ?? '', size: parsedSize);
          }).toList();
        }

        _isHydratingInitialOrder = false;
      });

      if (isClone) {
        _loadNextSalesOrderNumber();
      }
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

  void _hydrateFromInitialOrder(SalesOrder order, {bool isClone = false}) {
    _selectedCustomerId = order.customerId;
    _selectedCustomer = order.customer;
    salesOrderNumberCtrl.text = isClone ? '' : order.saleNumber;
    referenceCtrl.text = isClone ? '' : (order.reference ?? '');
    notesCtrl.text = order.customerNotes ?? '';
    termsCtrl.text = order.termsAndConditions ?? '';
    shippingCtrl.text = order.shippingCharges.toStringAsFixed(2);
    adjustmentCtrl.text = order.adjustment.toStringAsFixed(2);
    salesOrderDate = isClone ? DateTime.now() : order.saleDate;
    expectedShipmentDate = isClone ? null : order.expectedShipmentDate;
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

    final rawType = (order.tdsTcsType ?? 'none').toLowerCase();
    _tdsTcsType = (rawType == 'tds' || rawType == 'tcs') ? rawType : 'none';
    _selectedTdsTcsId = order.tdsTcsTaxId;
    if (_tdsTcsType != 'none' && _selectedTdsTcsId != null) {
      _loadTdsRates().then((_) {
        if (!mounted) return;
        final isTcs = _tdsTcsType == 'tcs';
        final list = isTcs ? _tcsRatesList : _tdsRatesList;
        final rate = list.firstWhere((r) => r['id'] == _selectedTdsTcsId, orElse: () => <String, dynamic>{});
        if (rate.isNotEmpty) {
          setState(() {
            _tdsTcsRate = double.tryParse((isTcs ? rate['rate'] : rate['base_rate'])?.toString() ?? '0') ?? 0.0;
          });
        }
      });
    }
  }

  Future<void> _loadTdsRates() async {
    if (_isLoadingTdsRates) return;
    _isLoadingTdsRates = true;
    try {
      final lookupsService = LookupsApiService();
      final List<Map<String, dynamic>> tdsRates = await lookupsService.getTdsRates();
      final List<Map<String, dynamic>> tdsSections = await lookupsService.getTdsSections();
      final List<Map<String, dynamic>> tcsRates = await lookupsService.getTcsRates();
      final List<Map<String, dynamic>> tcsNatures = await lookupsService.getTcsNatures();
      if (mounted) {
        setState(() {
          _tdsRatesList = tdsRates;
          _tdsSectionsList = tdsSections;
          _tcsRatesList = tcsRates;
          _tcsNaturesList = tcsNatures;
        });
      }
    } catch (e) {
      debugPrint('Error loading TDS/TCS rates: $e');
    } finally {
      _isLoadingTdsRates = false;
    }
  }

  Future<void> _loadSalespersons() async {
    try {
      final lookupsService = LookupsApiService();
      final persons = await lookupsService.getSalespersons();
      if (mounted) {
        setState(() {
          _salespersonList = persons;
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
      final dbDefaultId = await lookupsService.getDefaultPaymentTermId();
      if (mounted) {
        setState(() {
          _paymentTermsList = terms;
          _defaultPaymentTermId = dbDefaultId;
          if (paymentTerms == null && terms.isNotEmpty) {
            final hasDefault = terms.any((t) => t['id']?.toString() == dbDefaultId);
            if (hasDefault) {
              paymentTerms = dbDefaultId;
            } else {
              final net30 = terms.firstWhere(
                (t) => t['term_name'] == 'Net 30',
                orElse: () => terms.first,
              );
              paymentTerms = net30['id']?.toString();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading payment terms: $e');
    }
  }

  Future<void> _loadCarriers() async {
    try {
      final lookupsService = LookupsApiService();
      final carriers = await lookupsService.getShipmentPreferences();
      if (mounted) {
        setState(() {
          _carriersList = carriers;
        });
      }
    } catch (e) {
      debugPrint('Error loading carriers: $e');
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
    final warehouseList = ref.read(warehousesProvider).valueOrNull ?? <Warehouse>[];
    final selectedWarehouse = warehouseList.isEmpty
        ? null
        : warehouseList.firstWhere(
            (w) => w.name == warehouse,
            orElse: () => warehouseList.first,
          );
    final displayedWarehouseName =
        selectedWarehouse?.name ?? warehouse ?? '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SalesOrderPreferencesDialog(
        currentPrefix: _soPrefix,
        currentNextNumber: () {
          String currentText = salesOrderNumberCtrl.text.trim();
          if (_soPrefix.isNotEmpty && currentText.startsWith(_soPrefix)) {
            return currentText.substring(_soPrefix.length);
          }
          final match = RegExp(r'\d+$').firstMatch(currentText);
          return match != null ? match.group(0)! : _soNextNumber;
        }(),
        isAutoGenerate: _isAutoGenerateSO,
        warehouseName: displayedWarehouseName,
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

  List<PriceList> _getCombinedPriceListsForBranch(String selectedBranchId) {
    final globalPriceLists = ref.read(activeSalesPriceListsAsyncProvider).valueOrNull ?? <PriceList>[];
    final branchPriceLists = ref.read(branchPriceListNotifierProvider).valueOrNull ?? <BranchPriceList>[];

    final filteredBranchLists = branchPriceLists
        .where((pl) =>
            pl.status == 'active' &&
            pl.transactionType.toLowerCase() == 'sales' &&
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

  List<PriceList> _getCombinedPriceLists() {
    final warehouseList = ref.read(warehousesProvider).valueOrNull ?? <Warehouse>[];
    final selectedWh = warehouseList.firstWhere(
      (w) => w.name == warehouse,
      orElse: () => warehouseList.isNotEmpty ? warehouseList.first : Warehouse(id: '', name: ''),
    );
    final activeEntityId = (Hive.box('config').get('selected_entity_id') as String?)?.trim();
    final selectedBranchId = selectedWh.entityId ?? selectedWh.branchId ?? activeEntityId ?? '';
    return _getCombinedPriceListsForBranch(selectedBranchId);
  }

  AsyncValue<List<PriceList>> get _combinedPriceListsAsync {
    final globalPriceListsAsync = ref.watch(activeSalesPriceListsAsyncProvider);
    final branchPriceListsAsync = ref.watch(branchPriceListNotifierProvider);

    if (globalPriceListsAsync.isLoading || branchPriceListsAsync.isLoading) {
      return const AsyncValue.loading();
    }
    if (globalPriceListsAsync.hasError) {
      return AsyncValue.error(globalPriceListsAsync.error!, globalPriceListsAsync.stackTrace!);
    }

    final globalLists = globalPriceListsAsync.valueOrNull ?? [];
    final branchLists = branchPriceListsAsync.valueOrNull ?? [];

    final warehouseList = ref.watch(warehousesProvider).valueOrNull ?? <Warehouse>[];
    final selectedWh = warehouseList.firstWhere(
      (w) => w.name == warehouse,
      orElse: () => warehouseList.isNotEmpty ? warehouseList.first : Warehouse(id: '', name: ''),
    );
    final activeEntityId = (Hive.box('config').get('selected_entity_id') as String?)?.trim();
    final selectedBranchId = selectedWh.entityId ?? selectedWh.branchId ?? activeEntityId ?? '';

    final filteredBranchLists = branchLists
        .where((pl) =>
            pl.status == 'active' &&
            pl.transactionType.toLowerCase() == 'sales' &&
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

    return AsyncValue.data(<PriceList>[
      ...globalLists,
      ...filteredBranchLists,
    ]);
  }


  SalesOrderItemRow _createItemRow({
    String quantity = '',
    String rate = '',
    String discount = '',
    String fQty = '0',
    String mrp = '0',
    String description = '',
    String itemId = '',
    Item? item,
    String discountType = '%',
    String? taxId,
    String? hsnCode,
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
    row.hsnCode = hsnCode ?? item?.hsnCode;

    void onAnyChange() {
      final customers = ref.read(salesCustomersProvider).asData?.value ?? [];
      if (customers.isNotEmpty && _selectedCustomerId != null) {
        final customer = customers.firstWhere(
          (c) => c.id == _selectedCustomerId,
          orElse: () => customers.first,
        );
        final priceLists = _getCombinedPriceLists();
        _updateRowRate(row, customer.priceList, priceLists);
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
    final row = _createItemRow(
      quantity: item.quantity.toString(),
      rate: item.rate.toString(),
      discount: item.discount.toString(),
      description: item.description ?? '',
      itemId: item.itemId,
      item: item.item,
      discountType: item.discountType == 'value' ? 'Value' : item.discountType,
      taxId: item.taxId,
    );
    row.hsnCode = item.hsnCode ?? item.item?.hsnCode;
    row.warehouseId = item.warehouseId;
    return row;
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
              child: CustomerDetailsSidebar(
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
              _calculateTotals();
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

  void _showItemDetailsSidebar(
    SalesOrderItemRow row, {
    int initialTabIndex = 0,
  }) {
    if (row.itemId.isNotEmpty) {
      POItemDetailsSidebar.show(
        context,
        PurchaseOrderItem(
          productId: row.itemId,
          productName: row.item?.productName ?? '',
          itemCode: row.item?.itemCode,
          productType: row.item?.type ?? 'goods',
          rate: double.tryParse(row.rateCtrl.text) ?? 0.0,
          quantity: double.tryParse(row.quantityCtrl.text) ?? 0.0,
          amount: (double.tryParse(row.rateCtrl.text) ?? 0.0) * (double.tryParse(row.quantityCtrl.text) ?? 0.0),
          accountName: row.accountName,
        ),
        initialTabIndex: initialTabIndex,
      );
    }
  }

  void _updateRowRate(
    SalesOrderItemRow row,
    String? appliedPriceListId,
    List<PriceList> priceLists,
  ) {
    if (row.item == null) return;

    row.priceListId = appliedPriceListId;
    final priceListId = appliedPriceListId;
    if (priceListId == null || priceListId == 'Select') {
      final fallbackRate = (row.item!.sellingPrice ?? 0).toDouble();
      row.rateCtrl.text = fallbackRate == 0
          ? '0'
          : fallbackRate.toStringAsFixed(2);
      return;
    }

    final matchingPls = priceLists.where((p) => p.id == priceListId);
    if (matchingPls.isEmpty) {
      final fallbackRate = (row.item!.sellingPrice ?? 0).toDouble();
      row.rateCtrl.text = fallbackRate == 0
          ? '0'
          : fallbackRate.toStringAsFixed(2);
      return;
    }
    final pl = matchingPls.first;
    final itemIncluded =
        pl.priceListType != 'individual_items' ||
        (pl.itemRates?.any((r) =>
            r.itemId == row.itemId ||
            r.itemId == row.item?.productName ||
            (r.itemName != null &&
                row.item != null &&
                r.itemName!.toLowerCase() == row.item!.productName.toLowerCase())) ??
            false);
    if (!itemIncluded) {
      final fallbackRate = (row.item!.sellingPrice ?? 0).toDouble();
      row.rateCtrl.text = fallbackRate == 0
          ? '0'
          : fallbackRate.toStringAsFixed(2);
      return;
    }

    final qty = double.tryParse(row.quantityCtrl.text) ?? 1;
    final newRate = pl.calculatePrice(
      row.itemId,
      (row.item!.sellingPrice ?? 0).toDouble(),
      quantity: qty,
      productName: row.item?.productName,
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
    final itemsState = ref.read(itemsControllerProvider);
    final taxRates = [...itemsState.taxGroups, ...itemsState.taxRates];
    final Map<double, double> localTaxGroups = {};

    for (var row in rows) {
      if (row.itemId.isNotEmpty) {
        final q = double.tryParse(row.quantityCtrl.text) ?? 0;
        final r = double.tryParse(row.rateCtrl.text) ?? 0;
        final d = double.tryParse(row.discountCtrl.text) ?? 0;
        final discAmt = row.discountType == '%' ? (q * r * d / 100) : d;
        final cost = (row.item?.costPrice ?? 0).toDouble();

        row.profit = (r - cost) * q;
        final rowSubtotal = (q * r) - discAmt;
        st += rowSubtotal;

        double rowTaxRate = 0.0;
        if (!_isCustomerUnregistered &&
            _selectedCustomerId != null &&
            row.taxId != null &&
            row.taxId != 'non_taxable' &&
            row.taxId != 'out_of_scope' &&
            row.taxId != 'non_gst') {
          final taxGroup = taxRates.where((t) => t.id == row.taxId).firstOrNull;
          if (taxGroup != null) {
            rowTaxRate = taxGroup.taxRate.toDouble();
          }
        }

        if (rowTaxRate > 0) {
          localTaxGroups[rowTaxRate] = (localTaxGroups[rowTaxRate] ?? 0.0) + rowSubtotal;
        }
      }
    }

    final shipping = double.tryParse(shippingCtrl.text) ?? 0.0;
    final adjustment = double.tryParse(adjustmentCtrl.text) ?? 0.0;

    double currentTaxTotal = 0.0;
    final customerFromList = _selectedCustomerId == null
        ? null
        : ref
            .read(salesCustomersProvider)
            .asData
            ?.value
            .where((c) => c.id == _selectedCustomerId)
            .firstOrNull;
    final pos = (placeOfSupply ??
            _selectedCustomer?.placeOfSupply ??
            customerFromList?.placeOfSupply ??
            '')
        .trim()
        .toLowerCase();
    final isKerala = pos.contains('[kl]') || pos.contains('kerala');
    final List<Map<String, dynamic>> calculatedTaxLines = [];

    if (_selectedCustomerId != null && _selectedCustomerId!.isNotEmpty) {
      localTaxGroups.forEach((rate, taxableAmount) {
        final totalTaxForRate = taxableAmount * (rate / 100);
        currentTaxTotal += totalTaxForRate;

        if (isKerala) {
          final halfRate = rate / 2;
          final rateStr = halfRate % 1 == 0 ? halfRate.toInt().toString() : halfRate.toString();
          calculatedTaxLines.add({
            'label': 'CGST$rateStr [$rateStr%]',
            'amount': totalTaxForRate / 2,
          });
          calculatedTaxLines.add({
            'label': 'SGST$rateStr [$rateStr%]',
            'amount': totalTaxForRate / 2,
          });
        } else {
          final rateStr = rate % 1 == 0 ? rate.toInt().toString() : rate.toString();
          calculatedTaxLines.add({
            'label': 'IGST$rateStr [$rateStr%]',
            'amount': totalTaxForRate,
          });
        }
      });
    }

    final tdsTcsVal = st * _tdsTcsRate / 100;
    double rawTotal = st + currentTaxTotal + shipping + adjustment;
    if (_tdsTcsType == 'tds') {
      rawTotal -= tdsTcsVal;
    } else if (_tdsTcsType == 'tcs') {
      rawTotal += tdsTcsVal;
    }
    double roundedTotal = rawTotal.roundToDouble();
    double ro = roundedTotal - rawTotal;

    setState(() {
      subTotal = st;
      taxTotal = currentTaxTotal;
      _roundOff = ro;
      total = roundedTotal;
      taxLines = calculatedTaxLines;
    });
  }

  void _closeTaxOverlay() {
    _taxOverlay?.remove();
    _taxOverlay = null;
  }

  void _showTaxPopover(BuildContext context, int index, SalesOrderItemRow row) {
    _closeTaxOverlay();

    _taxOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeTaxOverlay,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: row.taxLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 42),
            child: Material(
              color: Colors.transparent,
              child: TapRegion(
                onTapOutside: (_) => _closeTaxOverlay(),
                child: _TaxSelectionPopover(
                  selectedTaxId: row.taxId,
                  onTaxSelected: (tax) {
                    setState(() {
                      row.taxId = tax.id;
                    });
                    _calculateTotals();
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

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final itemsState = ref.watch(itemsControllerProvider);
    final priceListsAsync = _combinedPriceListsAsync;
    final currenciesAsync = ref.watch(currenciesProvider(null));

    ref.listen<AsyncValue<List<Warehouse>>>(warehousesProvider, (
      previous,
      next,
    ) {
      next.whenData((warehouses) {
        final defaultWh = warehouses.isEmpty
            ? null
            : warehouses.firstWhere(
                (w) => w.isDefaultForBranch,
                orElse: () => warehouses.first,
              );
        final hasCurrentWh = warehouses.any((w) => w.name == warehouse);
        if (defaultWh != null && (warehouse == '' || !hasCurrentWh)) {
          setState(() {
            warehouse = defaultWh.name;
          });
        }
      });
    });

    final accountsState = ref.watch(chartOfAccountsProvider);
    final List<AccountNode> availableAccounts = [];
    void collect(List<AccountNode> nodes) {
      for (final node in nodes) {
        availableAccounts.add(node);
        collect(node.children);
      }
    }

    collect(accountsState.roots);

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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1270.0,
                      child: _buildItemsTable(
                        itemsState.items,
                        customersAsync,
                        priceListsAsync,
                        availableAccounts,
                      ),
                    ),
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
    final warehouseList = ref.watch(warehousesProvider).valueOrNull ?? <Warehouse>[];
    final defaultWh = warehouseList.isEmpty
        ? null
        : warehouseList.firstWhere(
            (w) => w.isDefaultForBranch,
            orElse: () => warehouseList.first,
          );
    final hasCurrentWh = warehouseList.any((w) => w.name == warehouse);
    if (defaultWh != null && (warehouse == '' || !hasCurrentWh)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (warehouse == '' || !hasCurrentWh)) {
          setState(() {
            warehouse = defaultWh.name;
          });
        }
      });
    }
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
                        key: const ValueKey('layout_customer_name'),
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
                                key: const ValueKey('so_customer_name'),
                                enabled: !_isEditMode,
                                value: selectedCustomerFromList,
                                height: _kDropdownHeight,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                                showRightBorder: true,
                                items: customers,
                                allowClear: !_isEditMode,
                                hint: 'Select or add a customer',
                                displayStringForValue: (c) => c.displayName,
                                itemHeight: 56,
                                showSettings: true,
                                settingsLabel: 'New Customer',
                                settingsIcon: LucideIcons.plus,
                                onSettingsTap: _isEditMode
                                    ? null
                                    : _showNewCustomerDialog,
                                itemBuilder:
                                    (customer, isSelected, isHovered) =>
                                        _buildCustomerDropdownItem(
                                          customer,
                                          isSelected,
                                          isHovered,
                                        ),
                                onChanged: (val) {
                                  if (val == null) {
                                    setState(() {
                                      _customerDetailsSidebarOverlay?.remove();
                                      _customerDetailsSidebarOverlay = null;
                                      _selectedCustomer = null;
                                      _selectedCustomerId = null;
                                    });
                                    _calculateTotals();
                                    return;
                                  }
                                  setState(() {
                                    _customerDetailsSidebarOverlay?.remove();
                                    _customerDetailsSidebarOverlay = null;
                                    _selectedCustomer = val;
                                    _selectedCustomerId = val.id;
                                    final priceLists =
                                        priceListsAsync.asData?.value ?? [];

                                    if (val.paymentTerms != null && val.paymentTerms!.isNotEmpty) {
                                      final matchingTerm = _paymentTermsList.firstWhere(
                                        (t) => t['term_name'] == val.paymentTerms || t['id'] == val.paymentTerms,
                                        orElse: () => <String, dynamic>{},
                                      );
                                      if (matchingTerm.isNotEmpty) {
                                        paymentTerms = matchingTerm['id']?.toString();
                                      } else {
                                        paymentTerms = _defaultPaymentTermId;
                                      }
                                    } else {
                                      paymentTerms = _defaultPaymentTermId;
                                    }
                                    if (paymentTerms == null && _paymentTermsList.isNotEmpty) {
                                      final net30 = _paymentTermsList.firstWhere(
                                        (t) => t['term_name'] == 'Net 30',
                                        orElse: () => _paymentTermsList.first,
                                      );
                                      paymentTerms = net30['id']?.toString();
                                    }

                                    for (var row in rows) {
                                      if (row.itemId.isNotEmpty &&
                                          row.item != null) {
                                        _updateRowRate(
                                          row,
                                          val.priceList,
                                          priceLists,
                                        );
                                      }
                                    }
                                  });
                                  _calculateTotals();
                                },
                              ),
                            ),
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: _isEditMode
                                    ? const Color(0xFFD1D5DB)
                                    : const Color(
                                        0xFF10B981,
                                      ), // Emerald-500 vs Gray-300
                                borderRadius: const BorderRadius.only(
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
                                onPressed: _isEditMode
                                    ? null
                                    : () => customersAsync.whenData(
                                        (customers) =>
                                            _showAdvancedCustomerSearch(
                                              customers,
                                            ),
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
                                          "${selectedCustomerFromList?.displayName}'s Details",
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
                      if (selectedCustomerFromList != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 204, bottom: 20),
                          child: _buildCustomerAddressSection(
                            selectedCustomerFromList,
                          ),
                        ),
                      if (selectedCustomerFromList != null) ...[
                        const SizedBox(height: 16),
                        // Place of Supply
                        SharedFieldLayout(
                          key: const ValueKey('layout_place_of_supply'),
                          label: 'Place of Supply',
                          required: true,
                          labelWidth: 180,
                          maxWidth: 450,
                          child: FormDropdown<String>(
                            key: const ValueKey('so_place_of_supply'),
                            enabled: !_isEditMode,
                            height: _kDropdownHeight,
                            value: _normalizePlaceOfSupply(
                              placeOfSupply ??
                              selectedCustomerFromList.placeOfSupply,
                            ),
                            items: const [
                              '[KL] - Kerala',
                              '[TN] - Tamil Nadu',
                              '[KA] - Karnataka',
                            ], // Simplified options
                            itemBuilder: (item, isSelected, isHovered) =>
                                _dropdownItemBuilder(
                                  item,
                                  isSelected,
                                  isHovered,
                                ),
                            onChanged: (v) {
                              setState(() {
                                placeOfSupply = v;
                              });
                              _calculateTotals();
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                key: const ValueKey('layout_sales_order_number'),
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
                key: const ValueKey('layout_reference'),
                label: 'Reference#',
                labelWidth: 180,
                maxWidth: 600,
                child: CustomTextField(controller: referenceCtrl, height: 32),
              ),

              // Sales Order Date
              SharedFieldLayout(
                key: const ValueKey('layout_sales_order_date'),
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
                key: const ValueKey('layout_expected_shipment_date'),
                label: 'Expected Shipment Date',
                labelWidth: 180,
                maxWidth: 600,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isExpectedShipmentHovered = true),
                  onExit: (_) => setState(() => _isExpectedShipmentHovered = false),
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
                      final today = DateTime.now();
                      final startOfToday = DateTime(today.year, today.month, today.day);
                      final initial = expectedShipmentDate ?? startOfToday;
                      final picked = await ZerpaiDatePicker.show(
                        context,
                        initialDate: initial.isBefore(startOfToday) ? startOfToday : initial,
                        firstDate: startOfToday,
                        targetKey: _expectedShipmentDateKey,
                      );
                      if (picked != null) {
                        setState(() => expectedShipmentDate = picked);
                      }
                    },
                    suffixWidget: expectedShipmentDate == null
                        ? const Icon(
                            LucideIcons.calendar,
                            size: 16,
                            color: _kLabelGrey,
                          )
                        : (_isExpectedShipmentHovered
                            ? InkWell(
                                onTap: () {
                                  setState(() => expectedShipmentDate = null);
                                },
                                child: const Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              )
                            : const Icon(
                                LucideIcons.calendar,
                                size: 16,
                                color: _kLabelGrey,
                              )),
                  ),
                ),
              ),

              // Payment Terms
              SharedFieldLayout(
                key: const ValueKey('layout_payment_terms'),
                label: 'Payment Terms',
                labelWidth: 180,
                maxWidth: 600,
                child: FormDropdown<String>(
                  key: const ValueKey('so_payment_terms'),
                  value: paymentTerms,
                  height: _kDropdownHeight,
                  allowClear: true,
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

              // Delivery Method
              SharedFieldLayout(
                key: const ValueKey('layout_delivery_method'),
                label: 'Delivery Method',
                labelWidth: 180,
                maxWidth: 600,
                child: FormDropdown<String>(
                  key: const ValueKey('so_delivery_method'),
                  value: deliveryMethod,
                  height: _kDropdownHeight,
                  allowClear: true,
                  allowCustomValue: true,
                  hint: 'Select a delivery method or type to add',
                  items: _carriersList
                      .map((c) => c['name']?.toString() ?? '')
                      .where((n) => n.isNotEmpty)
                      .toList(),
                  itemBuilder: (item, isSelected, isHovered) =>
                      _dropdownItemBuilder(item, isSelected, isHovered),
                  onChanged: (v) => setState(() => deliveryMethod = v),
                ),
              ),

              // Salesperson
              SharedFieldLayout(
                key: const ValueKey('layout_salesperson'),
                label: 'Salesperson',
                labelWidth: 180,
                maxWidth: 600,
                child: FormDropdown<String>(
                  key: const ValueKey('so_salesperson'),
                  value: salesperson,
                  height: _kDropdownHeight,
                  allowClear: true,
                  items: _salespersonList
                      .map((p) => p['id']?.toString() ?? '')
                      .where((id) => id.isNotEmpty)
                      .toList(),
                  displayStringForValue: (val) {
                    final person = _salespersonList.firstWhere(
                      (p) => p['id']?.toString() == val,
                      orElse: () => <String, dynamic>{},
                    );
                    return person['full_name']?.toString() ?? val;
                  },
                  itemBuilder: (id, isSelected, isHovered) {
                    final sp = _salespersonList.firstWhere(
                      (s) => s['id']?.toString() == id,
                      orElse: () => <String, dynamic>{},
                    );
                    return _dropdownItemBuilder(
                      sp['full_name']?.toString() ?? id,
                      isSelected,
                      isHovered,
                    );
                  },
                  onChanged: (v) => setState(() => salesperson = v),
                ),
              ),

              // Warehouse and Price List Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),
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
                              color: _kLabelGrey,
                              fontWeight: FontWeight.w500,
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
                            // 1. Warehouse Dropdown
                            SizedBox(
                              width: 240,
                              child: FormDropdown<Warehouse>(
                                value: warehouseList.isEmpty
                                    ? null
                                    : warehouseList.firstWhere(
                                        (w) => w.name == warehouse,
                                        orElse: () => warehouseList.first,
                                      ),
                                height: 36,
                                textStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: warehouse != null && warehouse!.isNotEmpty
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: warehouse != null && warehouse!.isNotEmpty
                                      ? _kBodyText
                                      : _kLabelGrey,
                                ),
                                items: warehouseList,
                                hint: 'Select Warehouse',
                                displayStringForValue: (w) => w.name,
                                searchStringForValue: (w) => w.name,
                                showSearch: warehouseList.length > 5,
                                hideBorderDefault: true,
                                borderRadius: BorderRadius.circular(6),
                                itemBuilder: (w, isSelected, isHovered) =>
                                    _buildStandardLookupRow(w.name, isSelected, isHovered),
                                onChanged: (w) {
                                  setState(() {
                                    warehouse = w?.name;
                                    final activeEntityId = (Hive.box('config').get('selected_entity_id') as String?)?.trim();
                                    final selectedBranchId = w?.entityId ?? w?.branchId ?? activeEntityId ?? '';
                                    final newPriceLists = _getCombinedPriceListsForBranch(selectedBranchId);
                                    if (priceListId != null) {
                                      final hasPl = newPriceLists.any((pl) => pl.id == priceListId);
                                      if (!hasPl) {
                                        priceListId = null;
                                        for (var row in rows) {
                                          row.priceListId = null;
                                          _updateRowRate(row, null, newPriceLists);
                                        }
                                      } else {
                                        for (var row in rows) {
                                          _updateRowRate(row, row.priceListId ?? priceListId, newPriceLists);
                                        }
                                      }
                                    } else {
                                      for (var row in rows) {
                                        _updateRowRate(row, row.priceListId, newPriceLists);
                                      }
                                    }
                                  });
                                  _calculateTotals();
                                },
                              ),
                            ),

                            const SizedBox(width: 8),
                            Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                            const SizedBox(width: 8),

                            // 2. Price List Dropdown
                            SizedBox(
                              width: 240,
                              child: priceListsAsync.when(
                                data: (priceLists) {
                                  final salesPriceLists = priceLists
                                      .where(
                                        (p) =>
                                            p.transactionType.toLowerCase() == 'sales',
                                      )
                                      .toList();
                                  return FormDropdown<String>(
                                    key: const ValueKey('so_main_price_list'),
                                    allowClear: true,
                                    value: priceListId,
                                    height: 36,
                                    textStyle: TextStyle(
                                      fontSize: 13,
                                      fontWeight: priceListId != null && priceListId!.isNotEmpty
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: priceListId != null && priceListId!.isNotEmpty
                                          ? _kBodyText
                                          : _kLabelGrey,
                                    ),
                                    items: salesPriceLists.map((p) => p.id).toList(),
                                    displayStringForValue: (id) =>
                                        salesPriceLists
                                            .where((p) => p.id == id)
                                            .firstOrNull
                                            ?.name ??
                                        'Select Price List',
                                    hint: 'Select Price List',
                                    hideBorderDefault: true,
                                    borderRadius: BorderRadius.circular(6),
                                    prefixWidget: const Icon(
                                      LucideIcons.clipboard,
                                      size: 16,
                                      color: Color(0xFF6B7280),
                                    ),
                                    itemBuilder: (id, isSelected, isHovered) =>
                                        _buildStandardLookupRow(
                                          salesPriceLists
                                                  .where((p) => p.id == id)
                                                  .firstOrNull
                                                  ?.name ??
                                              'Select Price List',
                                          isSelected,
                                          isHovered,
                                        ),
                                    onChanged: (v) {
                                      setState(() {
                                        priceListId = v;
                                        for (var row in rows) {
                                          if (row.itemId.isNotEmpty &&
                                              row.item != null) {
                                            row.priceListId = v;
                                            _updateRowRate(row, v, priceLists);
                                          }
                                        }
                                      });
                                    },
                                  );
                                },
                                loading: () => const Skeleton(height: 32, width: 240),
                                error: (_, __) =>
                                    const Text('Error loading price lists'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateAccountDialog(List<AccountNode> availableAccounts) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
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
                        onPressed: () => context.pop(),
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
                          child: FormDropdown<AccountNode>(
                            height: 32,
                            value: _selectedPopupAccount,
                            items: _buildNestedAccountsList(availableAccounts),
                            isItemEnabled: (v) => !v.id.startsWith('header_'),
                            displayStringForValue: (v) => v.id.startsWith('header_') ? v.accountType : v.name,
                            hint: 'Select an account',
                            onChanged: (v) {
                              if (v != null && v.id.startsWith('header_')) return;
                              setModalState(() {
                                _selectedPopupAccount = v;
                              });
                            },
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                          setState(() {
                            for (int i = 0; i < rows.length; i++) {
                              final row = rows[i];
                              if (row.itemId.isNotEmpty && !row.isHeader) {
                                row.accountId = _selectedPopupAccount?.id;
                                row.accountName = _selectedPopupAccount?.name;
                              }
                            }
                            _showBulkUpdateToolbar = false;
                            _selectedPopupAccount = null;
                          });
                          context.pop();
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

  Widget _buildUpdateDiscountDialog() {
    String discountType = '%';
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
            height: 350,
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
                        onPressed: () => context.pop(),
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
                        const Text(
                          'Choose how to apply the bulk discount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ZerpaiRadioGroup<String>(
                          options: const ['%', 'Value'],
                          current: discountType,
                          labelBuilder: (val) => val == '%'
                              ? 'Percentage Discount (%)'
                              : 'Flat Discount (₹)',
                          onChanged: (v) {
                            setModalState(() {
                              discountType = v;
                            });
                          },
                          activeColor: const Color(0xFF2563EB),
                          orientation: Axis.vertical,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
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
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          hintText: '0',
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 40,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        color: Color(0xFFF9FAFB),
                                      ),
                                      child: Text(
                                        discountType == '%' ? '%' : '₹',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
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
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            for (var row in rows) {
                              if (row.itemId.isNotEmpty && !row.isHeader) {
                                row.discountCtrl.text = controller.text;
                                row.discountType = discountType;
                              }
                            }
                            _showBulkUpdateToolbar = false;
                          });
                          context.pop();
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
                        onPressed: () => context.pop(),
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

  Widget _buildItemsTable(
    List<Item>? products,
    AsyncValue<List<SalesCustomer>> customersAsync,
    AsyncValue<List<PriceList>> priceListsAsync,
    List<AccountNode> availableAccounts,
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
                      if (_showBulkUpdateToolbar) ...[
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
                        ),
                        _vLine(),
                      ] else
                        const SizedBox(width: 40),
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
                        flex: 5,
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
                        flex: 6,
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
                final itemName =
                    (row.item?.productName ?? row.descriptionCtrl.text)
                        .toLowerCase();
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
                availableAccounts,
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
                  color: Color(0xFFF3F4F6),
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
    List<TaxRate> taxRates,
    List<AccountNode> availableAccounts, {
    Key? key,
  }) {
    final row = rows[idx];
    final priceLists = priceListsAsync.valueOrNull ?? [];
    final applicablePriceLists = priceLists.where((pl) {
      if (pl.transactionType.toLowerCase() != 'sales') return false;
      if (pl.id == row.priceListId) return true;
      if (pl.priceListType == 'all_items') return true;
      if (pl.priceListType == 'individual_items') {
        return pl.itemRates?.any((r) =>
            r.itemId == row.itemId ||
            r.itemId == row.item?.productName ||
            (r.itemName != null &&
                row.item != null &&
                r.itemName!.toLowerCase() == row.item!.productName.toLowerCase())) ??
            false;
      }
      return false;
    }).toList();

    final currentPriceListId = row.priceListId;
    final currentPriceList = priceLists
        .where((pl) => pl.id == currentPriceListId)
        .firstOrNull;
    bool notIncluded = false;
    if (currentPriceList != null && row.itemId.isNotEmpty) {
      if (currentPriceList.priceListType == 'individual_items') {
        notIncluded =
            !(currentPriceList.itemRates?.any((r) =>
                r.itemId == row.itemId ||
                r.itemId == row.item?.productName ||
                (r.itemName != null &&
                    row.item != null &&
                    r.itemName!.toLowerCase() == row.item!.productName.toLowerCase())) ??
                false);
      }
    } else if (currentPriceListId != null && row.itemId.isNotEmpty) {
      notIncluded = true;
    }
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

    return MouseRegion(
      key: key,
      onEnter: (_) => setState(() => _hoveredRowIndex = idx),
      onExit: (_) {
        if (_rowActionsOverlay == null) {
          setState(() => _hoveredRowIndex = null);
        }
      },
      child: Column(
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
                      if (_showBulkUpdateToolbar) ...[
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
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                activeColor: _kBlue,
                              ),
                            ),
                          ),
                        ),
                        _vLine(),
                      ] else
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
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Icon(
                                              LucideIcons.image,
                                              size: 20,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: FormDropdown<Item>(
                                              value: null,
                                              height: 32,
                                              hint:
                                                  'Type or click to select an item.',
                                              hideBorderDefault: true,
                                              items: products.take(20).toList(),
                                              displayStringForValue: (item) =>
                                                  item.productName,
                                              itemBuilder:
                                                  (
                                                    item,
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
                                                    child: _dropdownItemBuilder(
                                                      item.productName,
                                                      isSelected,
                                                      isHovered,
                                                      sublabel:
                                                          item.sellingPrice !=
                                                              null
                                                          ? 'Selling Price: ₹${item.sellingPrice!.toStringAsFixed(2)}'
                                                          : null,
                                                    ),
                                                  ),
                                              onSearch: (query) async {
                                                if (query.length < 3) return [];
                                                return await ref
                                                    .read(
                                                      itemsControllerProvider
                                                          .notifier,
                                                    )
                                                    .searchProductsNoState(
                                                      query,
                                                    );
                                              },
                                              onChanged: (p) {
                                                if (p == null) return;
                                                final dupIdx = rows.indexWhere((r) => r.itemId == p.id);
                                                if (dupIdx != -1) {
                                                  ZerpaiToast.error(
                                                    context,
                                                    "Item '${p.productName}' is already selected in row ${dupIdx + 1}.",
                                                  );
                                                  return;
                                                }
                                                setState(() {
                                                  row.itemId = p.id!;
                                                  row.item = p;
                                                  row.hsnCode = p.hsnCode;
                                                  row.accountId =
                                                      p.salesAccountId;
                                                  row.accountName =
                                                      p.salesAccountName;
                                                  final defaultRate =
                                                      (p.sellingPrice ?? 0).toDouble();
                                                  row.rateCtrl.text =
                                                      defaultRate == 0
                                                      ? '0'
                                                      : defaultRate
                                                            .toStringAsFixed(2);
                                                  if (row.mrpCtrl.text == '0' ||
                                                      row
                                                          .mrpCtrl
                                                          .text
                                                          .isEmpty) {
                                                    row.mrpCtrl.text =
                                                        (p.mrp ?? 0).toString();
                                                  }
                                                  row.taxId ??=
                                                      p.intraStateTaxId ??
                                                      p.interStateTaxId;
                                                  if (idx == rows.length - 1) {
                                                    rows.add(_createItemRow());
                                                  }
                                                });
                                                final activePriceListId =
                                                    row.priceListId ??
                                                    priceListId;
                                                final lists =
                                                    priceListsAsync.valueOrNull ??
                                                    const <PriceList>[];
                                                _updateRowRate(
                                                  row,
                                                  activePriceListId,
                                                  lists,
                                                );
                                                _calculateTotals();
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    : _buildSelectedItemView(row, products),
                              ],
                            ),
                          ),
                        ),
                        _vLine(),
                        // QUANTITY
                        Expanded(
                          flex: 5,
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
                                  hintText: '0',
                                  height: 32,
                                  hideBorderDefault: true,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  contentCase: ContentCase.none,
                                  textAlign: TextAlign.right,
                                  onTap: () => row.quantityCtrl.selection =
                                      TextSelection(
                                        baseOffset: 0,
                                        extentOffset:
                                            row.quantityCtrl.text.length,
                                      ),
                                  onChanged: (_) => _calculateTotals(),
                                ),
                                if (_showAvailableStock &&
                                    row.itemId.isNotEmpty) ...[
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final stocksAsync = ref.watch(itemWarehouseStocksProvider(row.itemId));
                                      return stocksAsync.when(
                                        loading: () => const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Loading...',
                                            style: TextStyle(fontSize: 10, color: Color(0xFF4B5563)),
                                          ),
                                        ),
                                        error: (e, _) => const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Error',
                                            style: TextStyle(fontSize: 10, color: Color(0xFF4B5563)),
                                          ),
                                        ),
                                        data: (stocks) {
                                          final stockRow = stocks
                                              .where((s) => s.name == (warehouse ?? ''))
                                              .firstOrNull ??
                                              stocks.firstOrNull;
                                          double stockVal = 0.0;
                                          if (stockRow != null) {
                                            final numbers = _selectedStockType == 'Accounting'
                                                ? stockRow.accounting
                                                : stockRow.physical;
                                            stockVal = _selectedStockView == 'Stock on Hand'
                                                ? numbers.onHand
                                                : numbers.available;
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(text: '$_selectedStockView: '),
                                                  TextSpan(
                                                    text: '${stockVal.toInt()} pcs',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF4B5563),
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 2),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          LucideIcons.home,
                                          size: 12,
                                          color: Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: WarehouseHoverPopover(
                                            warehouseName: warehouse ?? '',
                                            selectedView: _selectedStockView,
                                            selectedStockType: _selectedStockType,
                                            productId: row.itemId,
                                            onViewChanged: (v) {
                                              setState(() {
                                                _selectedStockView = v;
                                              });
                                            },
                                            onStockTypeChanged: (t) {
                                              setState(() {
                                                _selectedStockType = t;
                                              });
                                            },
                                            onWarehouseChanged: (newName) {
                                              setState(() {
                                                warehouse = newName;
                                              });
                                            },
                                            child: Text(
                                              (warehouse ?? '')
                                                  .toUpperCase(),
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
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
                          flex: 5,
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
                                  onSubmitted: (_) =>
                                      _handleRateCalculation(row),
                                ),
                                if (row.itemId.isNotEmpty) ...[
                                  if (_showPriceList) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        if (notIncluded) ...[
                                          ZTooltip(
                                            message:
                                                "This item has not been included in the selected price list. So, the item's default rate has been used.",
                                            child: const Icon(
                                              LucideIcons.alertCircle,
                                              size: 14,
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
                                                final pl =
                                                    applicablePriceLists
                                                        .where(
                                                          (pl) =>
                                                              pl.id ==
                                                              row.priceListId,
                                                        )
                                                        .firstOrNull;
                                                if (pl != null) {
                                                  _showValueTooltip(
                                                    context,
                                                    pl.name,
                                                    row.priceListLink,
                                                  );
                                                }
                                              },
                                              onExit: (_) {
                                                _hideValueTooltip();
                                              },
                                              child: FormDropdown<PriceList>(
                                                key: ValueKey('row_${row.itemId}_price_list'),
                                                allowClear: true,
                                                value: applicablePriceLists
                                                    .where(
                                                      (pl) =>
                                                          pl.id ==
                                                          row.priceListId,
                                                    )
                                                    .firstOrNull,
                                                height: 32,
                                                hint: 'Apply Price List',
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                menuWidth: 250,
                                                items: applicablePriceLists,
                                                displayStringForValue: (v) =>
                                                    v.name,
                                                itemBuilder:
                                                    (
                                                      item,
                                                      isSelected,
                                                      isHovered,
                                                    ) => _dropdownItemBuilder(
                                                      item.name,
                                                      isSelected,
                                                      isHovered,
                                                    ),
                                                onChanged: (v) {
                                                  if (v != null) {
                                                    final baseRate =
                                                        row
                                                            .item
                                                            ?.sellingPrice ??
                                                        0;
                                                    final rate = v
                                                        .calculatePrice(
                                                          row.itemId,
                                                          baseRate,
                                                          productName: row.item?.productName,
                                                        );
                                                    setState(() {
                                                      row.priceListId = v.id;
                                                      row.rateCtrl.text = rate
                                                          .toStringAsFixed(2);
                                                      // Apply discount from price list if available
                                                      final discount = v.getItemDiscount(
                                                        row.itemId,
                                                        productName: row.item?.productName,
                                                      );
                                                      if (discount != null) {
                                                        row.discountCtrl.text = discount.toStringAsFixed(2);
                                                      }
                                                      _calculateTotals();
                                                    });
                                                  } else {
                                                    setState(() {
                                                      row.priceListId = null;
                                                      final baseRate =
                                                          row.item?.sellingPrice ?? 0;
                                                      row.rateCtrl.text =
                                                          baseRate.toStringAsFixed(2);
                                                      row.discountCtrl.text = '0';
                                                      _calculateTotals();
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (_showRecentTransactions) ...[
                                    const SizedBox(height: 2),
                                    GestureDetector(
                                      onTap: () {
                                        _showItemDetailsSidebar(
                                          row,
                                          initialTabIndex: 2,
                                        );
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
                              hintText: '0',
                              height: 32,
                              hideBorderDefault: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              contentCase: ContentCase.none,
                              textAlign: TextAlign.right,
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 0,
                              ),
                              suffixSeparator: false,
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
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: CompositedTransformTarget(
                                link: row.taxLink,
                                child: GestureDetector(
                                  onTap: _isCustomerUnregistered
                                      ? null
                                      : () {
                                          _showTaxPopover(context, idx, row);
                                        },
                                  child: () {
                                    bool isHovered = false;
                                    return StatefulBuilder(
                                      builder: (context, setOverlayState) {
                                        return MouseRegion(
                                          onEnter: (_) => setOverlayState(() => isHovered = true),
                                          onExit: (_) => setOverlayState(() => isHovered = false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: (!_isCustomerUnregistered && isHovered)
                                                    ? const Color(0xFF0088FF)
                                                    : Colors.transparent,
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                              color: Colors.white,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    (_isCustomerUnregistered || row.taxId == null)
                                                        ? 'Select Tax'
                                                        : (row.taxId == 'non_taxable'
                                                              ? 'Non-Taxable'
                                                              : (row.taxId == 'out_of_scope'
                                                                  ? 'Out of Scope'
                                                                  : (row.taxId == 'non_gst'
                                                                      ? 'Non-GST Supply'
                                                                      : () {
                                                                          final t = taxRates
                                                                              .where((x) => x.id == row.taxId)
                                                                              .firstOrNull;
                                                                          return t != null
                                                                              ? '${t.taxName} [${t.taxRate}%]'
                                                                              : 'Select Tax';
                                                                        }()))),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: (_isCustomerUnregistered || row.taxId == null)
                                                          ? _kLabelGrey
                                                          : _kBodyText,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (!_isCustomerUnregistered && row.taxId != null && isHovered)
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        row.taxId = null;
                                                        _calculateTotals();
                                                      });
                                                    },
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                      child: Icon(
                                                        Icons.close,
                                                        size: 14,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  )
                                                else if (!_isCustomerUnregistered)
                                                  const Icon(
                                                    Icons.arrow_drop_down,
                                                    color: _kLabelGrey,
                                                    size: 18,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }(),
                                ),
                              ),
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
              child: (!row.isHeader && _hoveredRowIndex == idx)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CompositedTransformTarget(
                          link: row.moreActionsLink,
                          child: InkWell(
                            onTap: () => _toggleRowActionsOverlay(row, products),
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
                            child: const Icon(
                              LucideIcons.x,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ],
        ),
        if (_showAdditionalInfo && !row.isHeader)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(right: 60), // Align with columns
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              border: Border(
                left: BorderSide(color: _kBorder),
                right: BorderSide(color: _kBorder),
              ),
            ),
            child: _buildReportingTags(row, availableAccounts),
          ),
        if (idx < rows.length - 1)
          Row(
            children: [
              const Expanded(child: Divider(height: 1, color: _kBorder)),
              const SizedBox(width: 60),
            ],
          ),
      ],
    ),
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
                            builder: (ctx) => ItemQuickEditDialog(
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
                        } else if (v == 'details') {
                          _showItemDetailsSidebar(row, initialTabIndex: 0);
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
                      color: item.type == 'goods' ? _kBlue : const Color(0xFFF97316),
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
                    item.type == 'goods' ? 'HSN Code ' : 'SAC Code ',
                    style: const TextStyle(fontSize: 12, color: _kBodyText),
                  ),
                  CompositedTransformTarget(
                    link: row.hsnLink,
                    child: Row(
                      children: [
                        Text(
                          row.hsnCode ?? '',
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
  OverlayEntry? _accountsOverlay;
  OverlayEntry? _valueTooltipOverlay;
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

  Widget _buildReportingTags(
    SalesOrderItemRow row,
    List<AccountNode> availableAccounts,
  ) {
    String? accountName = row.accountName;
    if (accountName == null && row.accountId != null) {
      final acc = availableAccounts
          .where((a) => a.id == row.accountId)
          .firstOrNull;
      if (acc != null) {
        accountName = acc.name;
        row.accountName = acc.name; // Cache it
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: row.accountsLink,
          child: InkWell(
            onTap: () => _toggleAccountsOverlay(row, availableAccounts),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.building,
                    size: 14,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    accountName ?? 'Select an account',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('|', style: TextStyle(color: Color(0xFFD1D5DB))),
        const SizedBox(width: 8),
        CompositedTransformTarget(
          link: row.reportingTagsLink,
          child: InkWell(
            onTap: () => _toggleReportingTagsOverlay(row),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.tag, size: 14, color: Color(0xFF22C55E)),
                  SizedBox(width: 6),
                  Text(
                    'Reporting Tags',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleAccountsOverlay(
    SalesOrderItemRow row,
    List<AccountNode> availableAccounts,
  ) {
    if (_accountsOverlay != null) {
      _accountsOverlay?.remove();
      _accountsOverlay = null;
      setState(() {});
      return;
    }

    _accountsOverlay = ZAdaptiveMenu.show(
      context: context,
      link: row.accountsLink,
      width: 320,
      alignLeft: true,
      padding: EdgeInsets.zero,
      borderRadius: 8,
      onClose: () {
        _accountsOverlay?.remove();
        _accountsOverlay = null;
        setState(() {});
      },
      builder: (context) => _AccountSelectionPopover(
        accounts: availableAccounts,
        selectedAccountId: row.accountId,
        onSelected: (acc) {
          setState(() {
            row.accountId = acc.id;
            row.accountName = acc.name;
          });
          _accountsOverlay?.remove();
          _accountsOverlay = null;
          setState(() {});
        },
      ),
    );
    setState(() {});
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
    return _HoverableSalesDescription(controller: controller);
  }

  Widget _buildSummaryAndNotes(List<Item>? products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
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
                  constraints: const BoxConstraints(maxWidth: 600),
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
            const SizedBox(width: 250),
            // Right Column: Totals
            ConstrainedBox(
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
                    ...taxLines.map((line) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _summaryRow(line['label'] as String, line['amount'] as double),
                        const SizedBox(height: 16),
                      ],
                    )).toList(),
                    if (_tdsTcsType == 'tcs') ...[
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
                    ] else ...[
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
            Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
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
        Row(
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
  }

  Widget _buildAttachmentBadge() {
    return CompositedTransformTarget(
      link: _attachmentBadgeLink,
      child: InkWell(
        onTap: _toggleAttachmentListOverlay,
        child: Container(
          height: 36,
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
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
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
          _calculateTotals();
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
                child: Radio<String>(value: 'tds', activeColor: _kBlue),
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
                child: Radio<String>(value: 'tcs', activeColor: _kBlue),
              ),
              const SizedBox(width: 8),
              const Text('TCS', style: TextStyle(fontSize: 13)),
            ],
          ),
          const Spacer(),
          if (_tdsTcsType != 'none') ...[
            SizedBox(
              width: 180,
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayText,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF111827),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ],
                                  ),
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
            Text(
              "${_tdsTcsType == 'tds' ? '-' : '+'} $displayAmount",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF111827),
              ),
            ),
          ] else ...[
            const Text(
              '0.00',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTdsMenu(BuildContext ctx, Offset? offset) {
    if (_tdsOverlay != null) {
      _tdsOverlay!.remove();
      _tdsOverlay = null;
      setState(() => _isTdsOpen = false);
      return;
    }

    final isTcs = _tdsTcsType == 'tcs';
    final overlayState = Overlay.of(ctx);
    final renderBox = ctx.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    setState(() => _isTdsOpen = true);

    _tdsOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                _tdsOverlay?.remove();
                _tdsOverlay = null;
                setState(() => _isTdsOpen = false);
              },
              behavior: HitTestBehavior.translucent,
              child: Container(),
            ),
            CompositedTransformFollower(
              link: _tdsLink,
              showWhenUnlinked: false,
              offset: Offset(size.width - 320, 36),
              child: Material(
                color: Colors.transparent,
                child: _TdsSelectionPopover(
                  isTcs: isTcs,
                  tdsRates: isTcs ? _tcsRatesList : _tdsRatesList,
                  tdsSections: isTcs ? _tcsNaturesList : _tdsSectionsList,
                  selectedTdsId: _selectedTdsTcsId,
                  onSelected: (rate) {
                    setState(() {
                      _selectedTdsTcsId = rate['id']?.toString();
                      final valStr = (isTcs ? rate['rate'] : rate['base_rate'])?.toString() ?? '0.0';
                      _tdsTcsRate = double.tryParse(valStr) ?? 0.0;
                    });
                    _calculateTotals();
                    _tdsOverlay?.remove();
                    _tdsOverlay = null;
                    setState(() => _isTdsOpen = false);
                  },
                  onManageTds: () {
                    _tdsOverlay?.remove();
                    _tdsOverlay = null;
                    setState(() => _isTdsOpen = false);

                    if (isTcs) {
                      _showManageTcsRatesDialog();
                    } else {
                      _showManageTdsRatesDialog();
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_tdsOverlay!);
  }

  void _showManageTdsRatesDialog() {
    showDialog(
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
          _calculateTotals();
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
              module: 'sales',
            );
          }
          return null;
        },
      ),
    );
  }

  void _showManageTcsRatesDialog() {
    showDialog(
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
          _calculateTotals();
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
              module: 'sales',
            );
          }
          return null;
        },
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
                    status: widget.initialOrder?.status ?? 'confirmed',
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _isEditMode ? 'Update' : 'Save and Confirm',
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
        ],
      ),
    );
  }

  void _saveSalesOrder({required String status}) async {
    if (_selectedCustomerId == null) {
      ZerpaiToast.error(context, 'Please select a customer');
      return;
    }
    if (salesOrderNumberCtrl.text.isEmpty) {
      ZerpaiToast.error(context, 'Please enter Sales Order#');
      return;
    }
    final customerFromList = ref
        .read(salesCustomersProvider)
        .asData
        ?.value
        .where((c) => c.id == _selectedCustomerId)
        .firstOrNull;
    final effectivePlaceOfSupply = _normalizePlaceOfSupply(
      placeOfSupply ??
      _selectedCustomer?.placeOfSupply ??
      customerFromList?.placeOfSupply,
    );
    if (effectivePlaceOfSupply == null) {
      ZerpaiToast.error(context, 'Please select Place of Supply');
      return;
    }

    // Check items
    bool itemsValid = true;
    bool hsnValid = true;
    bool accountValid = true;
    bool hasItems = false;

    for (var row in rows) {
      if (row.itemId.isNotEmpty) {
        hasItems = true;
        final qty = double.tryParse(row.quantityCtrl.text) ?? 0;
        final rate = double.tryParse(row.rateCtrl.text) ?? 0;
        if (qty <= 0 || rate <= 0) {
          itemsValid = false;
        }
        if (row.hsnCode == null || row.hsnCode!.isEmpty) {
          hsnValid = false;
        }
        if (row.accountId == null || row.accountId!.isEmpty) {
          accountValid = false;
        }
      }
    }

    if (!hasItems) {
      ZerpaiToast.error(context, 'Please add at least one item');
      return;
    }
    if (!itemsValid) {
      ZerpaiToast.error(
        context,
        'Please fill rate and quantity for all selected items',
      );
      return;
    }
    if (!hsnValid) {
      ZerpaiToast.error(context, 'Please select HSN code for all items');
      return;
    }
    if (!accountValid) {
      ZerpaiToast.error(context, 'Please select an account for all items');
      return;
    }

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
            hsnCode: r.hsnCode,
            accountId: r.accountId,
            priceListId: r.priceListId,
          ),
        )
        .toList();

    final warehouseList = ref.read(warehousesProvider).valueOrNull ?? <Warehouse>[];
    String? selectedWarehouseId;
    if (warehouse != null) {
      final match = warehouseList.where((w) => w.name == warehouse);
      if (match.isNotEmpty) {
        selectedWarehouseId = match.first.id;
      }
    }

    final order = SalesOrder(
      id: _editingOrderId ?? '',
      customerId: _selectedCustomerId!,
      saleNumber: salesOrderNumberCtrl.text,
      reference: referenceCtrl.text,
      saleDate: salesOrderDate,
      expectedShipmentDate: expectedShipmentDate,
      paymentTerms: paymentTerms,
      tdsTcsType: _tdsTcsType,
      tdsTcsTaxId: _selectedTdsTcsId,
      tdsTcsAmount: _tdsTcsAmount,
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
      placeOfSupply: effectivePlaceOfSupply,
      warehouseId: selectedWarehouseId,
      paymentTermId: paymentTerms,
      priceListId: priceListId,
    );

    try {
      if (deliveryMethod != null && deliveryMethod!.isNotEmpty) {
        final exists = _carriersList.any(
          (c) => c['name']?.toString().toLowerCase() == deliveryMethod!.toLowerCase(),
        );
        if (!exists && deliveryMethod != 'None') {
          try {
            final lookupsService = LookupsApiService();
            await lookupsService.syncShipmentPreferences([
              {'name': deliveryMethod, 'is_active': true},
            ]);
            // Reload carriers list so it's fresh
            _loadCarriers();
          } catch (e) {
            debugPrint('Error syncing delivery method: $e');
          }
        }
      }

      final controller = ref.read(salesOrderControllerProvider.notifier);
      SalesOrder? savedOrder;
      if (_isEditMode && _editingOrderId != null) {
        savedOrder = await controller.updateSalesOrder(_editingOrderId!, order);
      } else {
        savedOrder = await controller.createSalesOrder(order);
        // Increment sequence only on successful creation
        await ref
            .read(sequencesApiServiceProvider)
            .incrementSequence('sale', usedNumber: salesOrderNumberCtrl.text);
      }

      if (savedOrder != null) {
        final supabase = Supabase.instance.client;
        try {
          // Clean up old demand pool entries for this sales order to prevent duplicate rows on update
          await supabase
              .from('demand_pool')
              .delete()
              .eq('sales_order_id', savedOrder.id);

          final entityId = ref.read(entityProvider).entityId;
          final finalWarehouseId = selectedWarehouseId ?? warehouseList.firstOrNull?.id;

          if (finalWarehouseId != null) {
            final List<Map<String, dynamic>> demandPoolInserts = [];

            for (var row in rows) {
              if (row.itemId.isNotEmpty) {
                final qty = double.tryParse(row.quantityCtrl.text) ?? 0;
                if (qty <= 0) continue;

                try {
                  final stocks = await ref.read(itemWarehouseStocksProvider(row.itemId).future);
                  final stockRow = stocks.where((s) => s.name == (warehouse ?? '')).firstOrNull ?? stocks.firstOrNull;
                  double availableQty = 0.0;
                  if (stockRow != null) {
                    final numbers = _selectedStockType == 'Accounting'
                        ? stockRow.accounting
                        : stockRow.physical;
                    availableQty = _selectedStockView == 'Stock on Hand'
                        ? numbers.onHand
                        : numbers.available;
                  }

                  if (qty > availableQty) {
                    final remainingQty = qty - availableQty;
                    demandPoolInserts.add({
                      'entity_id': entityId,
                      'product_id': row.itemId,
                      'warehouse_id': finalWarehouseId,
                      'required_qty': remainingQty,
                      'pending_qty': remainingQty,
                      'planned_qty': 0,
                      'ordered_qty': 0,
                      'received_qty': 0,
                      'status': 'OPEN',
                      'sales_order_id': savedOrder.id,
                    });
                  }
                } catch (stockError) {
                  debugPrint('Error fetching stocks for item ${row.itemId}: $stockError');
                }
              }
            }

            if (demandPoolInserts.isNotEmpty) {
              await supabase.from('demand_pool').insert(demandPoolInserts);
            }
          } else {
            debugPrint('Skipped demand pool sync: warehouse ID is null.');
          }
        } catch (dbError) {
          debugPrint('Error syncing demand pool entries: $dbError');
        }
      }

      if (savedOrder != null && _attachedFiles.isNotEmpty) {
        await _saveAttachments(savedOrder.id);
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

  Future<void> _saveAttachments(String salesOrderId) async {
    try {
      final supabase = Supabase.instance.client;
      final apiClient = ApiClient();
      var entityId = ref.read(entityProvider).entityId;
      if (entityId == null) {
        final user = ref.read(authUserProvider);
        entityId = user?.orgEntityId;
      }
      if (entityId == null) return;

      for (var file in _attachedFiles) {
        if (file.bytes == null) {
          debugPrint('Skipping file ${file.name} because bytes are null');
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
            'prefix': 'sales_orders',
          },
        );

        final fileKey = response.data['fileKey'] ?? 'sales_orders/${file.name}';

        await supabase.from('sales_order_attachments').insert({
          'sales_order_id': salesOrderId,
          'file_name': file.name,
          'file_path': fileKey,
          'file_size': file.size,
          'file_type': file.extension,
          'source': 'upload',
          'entity_id': entityId,
        });
      }
    } catch (e) {
      debugPrint('Error saving attachments: $e');
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to save attachments: $e');
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

    final countries = ref.watch(countriesProvider(null)).valueOrNull ?? [];

    // Resolve billing country
    final billingCountryMap = countries.firstWhere(
      (item) =>
          item['id'] == c.billingAddressCountryId ||
          item['shortCode'] == c.billingAddressCountryId,
      orElse: () => <String, String>{},
    );
    final billingCountryName =
        billingCountryMap['name'] ?? c.billingAddressCountryId;

    // Resolve shipping country
    final shippingCountryMap = countries.firstWhere(
      (item) =>
          item['id'] == c.shippingAddressCountryId ||
          item['shortCode'] == c.shippingAddressCountryId,
      orElse: () => <String, String>{},
    );
    final shippingCountryName =
        shippingCountryMap['name'] ?? c.shippingAddressCountryId;

    // Resolve billing state
    final billingStates =
        (c.billingAddressCountryId != null &&
            c.billingAddressCountryId!.isNotEmpty)
        ? (ref.watch(statesProvider(c.billingAddressCountryId!)).valueOrNull ?? [])
        : [];
    final billingStateMap = billingStates
        .where(
          (item) =>
              item['id'] == c.billingAddressStateId ||
              item['code'] == c.billingAddressStateId,
        )
        .firstOrNull;
    final billingStateName = billingStateMap != null
        ? billingStateMap['name']
        : c.billingAddressStateId;

    // Resolve shipping state
    final shippingStates =
        (c.shippingAddressCountryId != null &&
            c.shippingAddressCountryId!.isNotEmpty)
        ? (ref.watch(statesProvider(c.shippingAddressCountryId!)).valueOrNull ?? [])
        : [];
    final shippingStateMap = shippingStates
        .where(
          (item) =>
              item['id'] == c.shippingAddressStateId ||
              item['code'] == c.shippingAddressStateId,
        )
        .firstOrNull;
    final shippingStateName = shippingStateMap != null
        ? shippingStateMap['name']
        : c.shippingAddressStateId;

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
                link: _billingAddressLink,
                attention: c.companyName ?? c.displayName,
                street1: c.billingAddressStreet1,
                street2: c.billingAddressStreet2,
                city: c.billingAddressCity,
                state: billingStateName,
                zip: c.billingAddressZip,
                country: billingCountryName,
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
                link: _shippingAddressLink,
                attention: c.companyName ?? c.displayName,
                street1: c.shippingAddressStreet1,
                street2: c.shippingAddressStreet2,
                city: c.shippingAddressCity,
                state: shippingStateName,
                zip: c.shippingAddressZip,
                country: shippingCountryName,
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
    required LayerLink link,
    String? attention,
    String? street1,
    String? street2,
    String? city,
    String? state,
    String? zip,
    String? country,
    String? phone,
  }) {
    final lines = <String>[
      if (street1 != null && street1.isNotEmpty) street1,
      if (street2 != null && street2.isNotEmpty) street2,
      [city ?? '', state ?? '', zip ?? ''].where((s) => s.isNotEmpty).join(', '),
      if (country != null && country.isNotEmpty) country,
      if (phone != null && phone.isNotEmpty) 'Phone: $phone',
    ];

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
            CompositedTransformTarget(
              link: link,
              child: InkWell(
                onTap: () {
                  final c = _selectedCustomer;
                  if (c != null) {
                    _showAddressDropdownList(
                      customer: c,
                      isBilling: label.contains('BILLING'),
                      link: link,
                    );
                  }
                },
                child: const Icon(
                  LucideIcons.pencil,
                  size: 11,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (!hasAddress)
          Row(
            children: [
              GestureDetector(
                onTap: () => _showAddressDialog(
                  isBilling: label.contains('BILLING'),
                  isAdditional: false,
                ),
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
              ...lines.map(
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
          ),
      ],
    );
  }

  void _closeAddressDropdownOverlay() {
    _addressDropdownOverlay?.remove();
    _addressDropdownOverlay = null;
  }

  Map<String, dynamic> _normalizeAddress(Map<String, dynamic> address) {
    return {
      'attention': address['attention']?.toString() ?? '',
      'street1': (address['street1'] ?? address['street'] ?? '').toString(),
      'street2': (address['street2'] ?? address['place'] ?? '').toString(),
      'city': address['city']?.toString() ?? '',
      'state': address['state']?.toString() ?? '',
      'zip': (address['zip'] ?? address['pincode'] ?? '').toString(),
      'country': (address['country'] ?? address['countryRegion'] ?? address['country_region'] ?? '').toString(),
      'phone': address['phone']?.toString() ?? '',
      if (address['id'] != null) 'id': address['id'].toString(),
    };
  }

  bool _areAddressesEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    String norm(dynamic val) => (val?.toString() ?? '').trim().toLowerCase();
    
    final streetA = norm(a['street1'] ?? a['street']);
    final streetB = norm(b['street1'] ?? b['street']);
    if (streetA != streetB) return false;
    
    final placeA = norm(a['street2'] ?? a['place'] ?? a['street_2']);
    final placeB = norm(b['street2'] ?? b['place'] ?? b['street_2']);
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

  List<Map<String, dynamic>> _getAllCustomerAddresses(SalesCustomer customer) {
    final list = <Map<String, dynamic>>[];
    
    final hasBilling = [
      customer.billingAddressStreet1,
      customer.billingAddressStreet2,
      customer.billingAddressCity,
      customer.billingAddressZip,
      customer.billingAddressCountryId,
      customer.billingAddressStateId,
    ].any((v) => v != null && v.toString().isNotEmpty);
    if (hasBilling) {
      list.add({
        'attention': customer.companyName ?? customer.displayName,
        'street1': customer.billingAddressStreet1 ?? '',
        'street2': customer.billingAddressStreet2 ?? '',
        'city': customer.billingAddressCity ?? '',
        'state': customer.billingAddressStateId ?? '',
        'zip': customer.billingAddressZip ?? '',
        'country': customer.billingAddressCountryId ?? '',
        'phone': customer.billingAddressPhone ?? '',
        'is_default_billing': true,
        'address_type': 'billing',
      });
    }

    final hasShipping = [
      customer.shippingAddressStreet1,
      customer.shippingAddressStreet2,
      customer.shippingAddressCity,
      customer.shippingAddressZip,
      customer.shippingAddressCountryId,
      customer.shippingAddressStateId,
    ].any((v) => v != null && v.toString().isNotEmpty);
    if (hasShipping) {
      list.add({
        'attention': customer.companyName ?? customer.displayName,
        'street1': customer.shippingAddressStreet1 ?? '',
        'street2': customer.shippingAddressStreet2 ?? '',
        'city': customer.shippingAddressCity ?? '',
        'state': customer.shippingAddressStateId ?? '',
        'zip': customer.shippingAddressZip ?? '',
        'country': customer.shippingAddressCountryId ?? '',
        'phone': customer.shippingAddressPhone ?? '',
        'is_default_shipping': true,
        'address_type': 'shipping',
      });
    }

    return list;
  }

  Future<void> _updateCustomerAddress({
    required SalesCustomer customer,
    required Map<String, dynamic> address,
    required bool isBilling,
  }) async {
    final normalizedAddr = _normalizeAddress(address);
    
    final countriesList = ref.read(countriesProvider(null)).valueOrNull ?? [];
    
    String? billingCountry = isBilling ? normalizedAddr['country'] : customer.billingAddressCountryId;
    String? shippingCountry = !isBilling ? normalizedAddr['country'] : customer.shippingAddressCountryId;

    final billingCountryObj = countriesList.firstWhere(
      (item) => item['id'] == billingCountry ||
                item['name']?.toLowerCase() == billingCountry?.toLowerCase() ||
                item['shortCode']?.toLowerCase() == billingCountry?.toLowerCase(),
      orElse: () => <String, String>{},
    );
    final billingCountryUuid = billingCountryObj['id'] ?? billingCountry;

    final shippingCountryObj = countriesList.firstWhere(
      (item) => item['id'] == shippingCountry ||
                item['name']?.toLowerCase() == shippingCountry?.toLowerCase() ||
                item['shortCode']?.toLowerCase() == shippingCountry?.toLowerCase(),
      orElse: () => <String, String>{},
    );
    final shippingCountryUuid = shippingCountryObj['id'] ?? shippingCountry;

    final billingStates = (billingCountryUuid != null && billingCountryUuid.isNotEmpty)
        ? (ref.read(statesProvider(billingCountryUuid)).valueOrNull ?? [])
        : [];
    String? billingState = isBilling ? normalizedAddr['state'] : customer.billingAddressStateId;
    final billingStateObj = billingStates.firstWhere(
      (item) => item['id'] == billingState ||
                item['name']?.toLowerCase() == billingState?.toLowerCase() ||
                item['code']?.toLowerCase() == billingState?.toLowerCase(),
      orElse: () => <String, String>{},
    );
    final billingStateUuid = billingStateObj['id'] ?? billingState;

    final shippingStates = (shippingCountryUuid != null && shippingCountryUuid.isNotEmpty)
        ? (ref.read(statesProvider(shippingCountryUuid)).valueOrNull ?? [])
        : [];
    String? shippingState = !isBilling ? normalizedAddr['state'] : customer.shippingAddressStateId;
    final shippingStateObj = shippingStates.firstWhere(
      (item) => item['id'] == shippingState ||
                item['name']?.toLowerCase() == shippingState?.toLowerCase() ||
                item['code']?.toLowerCase() == shippingState?.toLowerCase(),
      orElse: () => <String, String>{},
    );
    final shippingStateUuid = shippingStateObj['id'] ?? shippingState;

    final billingAddressPayload = {
      'street1': isBilling ? normalizedAddr['street1'] : customer.billingAddressStreet1,
      'place': isBilling ? normalizedAddr['street2'] : customer.billingAddressStreet2,
      'city': isBilling ? normalizedAddr['city'] : customer.billingAddressCity,
      'stateId': isBilling ? normalizedAddr['state'] : billingStateUuid,
      'zip': isBilling ? normalizedAddr['zip'] : customer.billingAddressZip,
      'countryId': isBilling ? normalizedAddr['country'] : billingCountryUuid,
      'phone': isBilling ? normalizedAddr['phone'] : customer.billingAddressPhone,
    };

    final shippingAddressPayload = {
      'street1': !isBilling ? normalizedAddr['street1'] : customer.shippingAddressStreet1,
      'place': !isBilling ? normalizedAddr['street2'] : customer.shippingAddressStreet2,
      'city': !isBilling ? normalizedAddr['city'] : customer.shippingAddressCity,
      'stateId': !isBilling ? normalizedAddr['state'] : shippingStateUuid,
      'zip': !isBilling ? normalizedAddr['zip'] : customer.shippingAddressZip,
      'countryId': !isBilling ? normalizedAddr['country'] : shippingCountryUuid,
      'phone': !isBilling ? normalizedAddr['phone'] : customer.shippingAddressPhone,
    };

    setState(() {
      if (isBilling) {
        _selectedCustomer = _selectedCustomer?.copyWith(
          billingAddressStreet1: normalizedAddr['street1'],
          billingAddressStreet2: normalizedAddr['street2'],
          billingAddressCity: normalizedAddr['city'],
          billingAddressStateId: normalizedAddr['state'],
          billingAddressZip: normalizedAddr['zip'],
          billingAddressCountryId: normalizedAddr['country'],
          billingAddressPhone: normalizedAddr['phone'],
        );
      } else {
        _selectedCustomer = _selectedCustomer?.copyWith(
          shippingAddressStreet1: normalizedAddr['street1'],
          shippingAddressStreet2: normalizedAddr['street2'],
          shippingAddressCity: normalizedAddr['city'],
          shippingAddressStateId: normalizedAddr['state'],
          shippingAddressZip: normalizedAddr['zip'],
          shippingAddressCountryId: normalizedAddr['country'],
          shippingAddressPhone: normalizedAddr['phone'],
        );
      }
    });

    await ref.read(salesOrderControllerProvider.notifier).updateCustomer(
      customer.id,
      {
        'billingAddress': billingAddressPayload,
        'shippingAddress': shippingAddressPayload,
      },
    );
  }

  void _showAddressDropdownList({
    required SalesCustomer customer,
    required bool isBilling,
    required LayerLink link,
  }) {
    _closeAddressDropdownOverlay();
    final allAddresses = _getAllCustomerAddresses(customer);
    if (allAddresses.isEmpty) return;

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
                                  customer: customer,
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
                              _showAddressDialog(
                                isBilling: isBilling,
                                isAdditional: true,
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

  Widget _buildAddressDropdownItem({
    required SalesCustomer customer,
    required Map<String, dynamic> address,
    required bool isBilling,
  }) {
    final attention = address['attention'] as String? ?? '';
    final street1 = address['street1'] as String? ?? '';
    final street2 = address['street2'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final state = address['state'] as String? ?? '';
    final zip = address['zip'] as String? ?? '';
    final country = address['country'] as String? ?? '';
    final phone = address['phone'] as String? ?? '';

    final countries = ref.read(countriesProvider(null)).valueOrNull ?? [];
    final countryMap = countries.firstWhere(
      (item) => item['id'] == country || item['shortCode'] == country,
      orElse: () => <String, String>{},
    );
    final countryName = countryMap['name'] ?? country;

    final states = (country.isNotEmpty)
        ? (ref.read(statesProvider(country)).valueOrNull ?? [])
        : [];
    final stateMap = states
        .where((item) => item['id'] == state || item['code'] == state)
        .firstOrNull;
    final stateName = stateMap != null ? stateMap['name'] : state;

    final bool isAddrBilling = address['is_default_billing'] == true ||
        address['address_type'] == 'billing';
    final bool isAddrShipping = address['is_default_shipping'] == true ||
        address['address_type'] == 'shipping';

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

    final activeAddress = {
      'attention': customer.companyName ?? customer.displayName,
      'street1': isBilling ? customer.billingAddressStreet1 ?? '' : customer.shippingAddressStreet1 ?? '',
      'street2': isBilling ? customer.billingAddressStreet2 ?? '' : customer.shippingAddressStreet2 ?? '',
      'city': isBilling ? customer.billingAddressCity ?? '' : customer.shippingAddressCity ?? '',
      'state': isBilling ? customer.billingAddressStateId ?? '' : customer.shippingAddressStateId ?? '',
      'zip': isBilling ? customer.billingAddressZip ?? '' : customer.shippingAddressZip ?? '',
      'country': isBilling ? customer.billingAddressCountryId ?? '' : customer.shippingAddressCountryId ?? '',
      'phone': isBilling ? customer.billingAddressPhone ?? '' : customer.shippingAddressPhone ?? '',
    };
    final isSelected = _areAddressesEqual(activeAddress, address) &&
        (isBilling ? isAddrBilling : isAddrShipping);

    final lines = <String>[
      if (street1.isNotEmpty) street1,
      if (street2.isNotEmpty) street2,
      [city, stateName, zip].where((s) => s.isNotEmpty).join(', '),
      if (countryName.isNotEmpty) countryName,
      if (phone.isNotEmpty) 'Phone: $phone',
    ];

    bool isHovered = false;
    return StatefulBuilder(
      builder: (ctx, setSt) {
        return MouseRegion(
          onEnter: (_) => setSt(() => isHovered = true),
          onExit: (_) => setSt(() => isHovered = false),
          child: GestureDetector(
            onTap: () async {
              _closeAddressDropdownOverlay();
              
              try {
                await _updateCustomerAddress(
                  customer: customer,
                  address: address,
                  isBilling: isBilling,
                );
                if (mounted) {
                  ZerpaiToast.success(context, 'Customer address updated');
                }
              } catch (e) {
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
                                _showAddressDialog(
                                  isBilling: isBilling,
                                  initialAddress: address,
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

  void _showAddressDialog({
    required bool isBilling,
    Map<String, dynamic>? initialAddress,
    bool isAdditional = false,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Address Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, _, __) {
        final c = _selectedCustomer;
        
        final hasBilling = [
          c?.billingAddressStreet1,
          c?.billingAddressStreet2,
          c?.billingAddressCity,
          c?.billingAddressZip,
          c?.billingAddressCountryId,
          c?.billingAddressStateId,
        ].any((v) => v != null && v.toString().isNotEmpty);

        final hasShipping = [
          c?.shippingAddressStreet1,
          c?.shippingAddressStreet2,
          c?.shippingAddressCity,
          c?.shippingAddressZip,
          c?.shippingAddressCountryId,
          c?.shippingAddressStateId,
        ].any((v) => v != null && v.toString().isNotEmpty);

        final hasAnyAddress = hasBilling || hasShipping;

        final String dialogTitle;
        if (initialAddress != null) {
          dialogTitle = isBilling ? 'Billing Address' : 'Shipping Address';
        } else {
          if (isAdditional && hasAnyAddress) {
            dialogTitle = 'New Additional Address';
          } else {
            dialogTitle = isBilling ? 'New Billing Address' : 'New Shipping Address';
          }
        }
            
        final Map<String, dynamic> existingAddress = initialAddress ?? {
          'companyName': c?.companyName,
          'attention': '',
          'street1': '',
          'street2': '',
          'city': '',
          'zip': '',
          'phone': '',
          'country': '',
          'state': '',
        };

        return AddressDialog(
          title: dialogTitle,
          initialAddress: existingAddress,
          onSave: (val) async {
            if (c == null) return;
            
            final street1 = val['street1'] as String?;
            final street2 = val['street2'] as String?;
            final city = val['city'] as String?;
            final state = val['state'] as String?; // UUID
            final stateName = val['stateName'] as String?; // Name
            final zip = val['zip'] as String?;
            final country = val['country'] as String?; // UUID
            final countryName = val['countryName'] as String?; // Name
            final phone = val['phone'] as String?;

            final saveAsBilling = initialAddress != null
                ? (initialAddress['address_type'] == 'billing' || initialAddress['is_default_billing'] == true)
                : isBilling;

            // Resolve billing & shipping country UUIDs
            final countriesList = ref.read(countriesProvider(null)).valueOrNull ?? [];
            final billingCountryObj = countriesList.firstWhere(
              (item) => item['id'] == c.billingAddressCountryId ||
                        item['name']?.toLowerCase() == c.billingAddressCountryId?.toLowerCase() ||
                        item['shortCode']?.toLowerCase() == c.billingAddressCountryId?.toLowerCase(),
              orElse: () => <String, String>{},
            );
            final billingCountryUuid = billingCountryObj['id'] ?? c.billingAddressCountryId;

            final shippingCountryObj = countriesList.firstWhere(
              (item) => item['id'] == c.shippingAddressCountryId ||
                        item['name']?.toLowerCase() == c.shippingAddressCountryId?.toLowerCase() ||
                        item['shortCode']?.toLowerCase() == c.shippingAddressCountryId?.toLowerCase(),
              orElse: () => <String, String>{},
            );
            final shippingCountryUuid = shippingCountryObj['id'] ?? c.shippingAddressCountryId;

            // Resolve billing & shipping state UUIDs
            final billingStates = (billingCountryUuid != null && billingCountryUuid.isNotEmpty)
                ? (ref.read(statesProvider(billingCountryUuid)).valueOrNull ?? [])
                : [];
            final billingStateObj = billingStates.firstWhere(
              (item) => item['id'] == c.billingAddressStateId ||
                        item['name']?.toLowerCase() == c.billingAddressStateId?.toLowerCase() ||
                        item['code']?.toLowerCase() == c.billingAddressStateId?.toLowerCase(),
              orElse: () => <String, String>{},
            );
            final billingStateUuid = billingStateObj['id'] ?? c.billingAddressStateId;

            final shippingStates = (shippingCountryUuid != null && shippingCountryUuid.isNotEmpty)
                ? (ref.read(statesProvider(shippingCountryUuid)).valueOrNull ?? [])
                : [];
            final shippingStateObj = shippingStates.firstWhere(
              (item) => item['id'] == c.shippingAddressStateId ||
                        item['name']?.toLowerCase() == c.shippingAddressStateId?.toLowerCase() ||
                        item['code']?.toLowerCase() == c.shippingAddressStateId?.toLowerCase(),
              orElse: () => <String, String>{},
            );
            final shippingStateUuid = shippingStateObj['id'] ?? c.shippingAddressStateId;

            setState(() {
              if (saveAsBilling) {
                _selectedCustomer = _selectedCustomer?.copyWith(
                  billingAddressStreet1: street1,
                  billingAddressStreet2: street2,
                  billingAddressCity: city,
                  billingAddressStateId: stateName, // Use name string locally for UI
                  billingAddressZip: zip,
                  billingAddressCountryId: countryName, // Use name string locally for UI
                  billingAddressPhone: phone,
                );
              } else {
                _selectedCustomer = _selectedCustomer?.copyWith(
                  shippingAddressStreet1: street1,
                  shippingAddressStreet2: street2,
                  shippingAddressCity: city,
                  shippingAddressStateId: stateName, // Use name string locally for UI
                  shippingAddressZip: zip,
                  shippingAddressCountryId: countryName, // Use name string locally for UI
                  shippingAddressPhone: phone,
                );
              }
            });

            try {
              final billingAddressPayload = {
                'street1': saveAsBilling ? street1 : c.billingAddressStreet1,
                'place': saveAsBilling ? street2 : c.billingAddressStreet2,
                'city': saveAsBilling ? city : c.billingAddressCity,
                'stateId': saveAsBilling ? state : billingStateUuid, // UUID
                'zip': saveAsBilling ? zip : c.billingAddressZip,
                'countryId': saveAsBilling ? country : billingCountryUuid, // UUID
                'phone': saveAsBilling ? phone : c.billingAddressPhone,
              };

              final shippingAddressPayload = {
                'street1': !saveAsBilling ? street1 : c.shippingAddressStreet1,
                'place': !saveAsBilling ? street2 : c.shippingAddressStreet2,
                'city': !saveAsBilling ? city : c.shippingAddressCity,
                'stateId': !saveAsBilling ? state : shippingStateUuid, // UUID
                'zip': !saveAsBilling ? zip : c.shippingAddressZip,
                'countryId': !saveAsBilling ? country : shippingCountryUuid, // UUID
                'phone': !saveAsBilling ? phone : c.shippingAddressPhone,
              };

              await ref.read(salesOrderControllerProvider.notifier).updateCustomer(
                c.id,
                {
                  'billingAddress': billingAddressPayload,
                  'shippingAddress': shippingAddressPayload,
                },
              );
              if (mounted) {
                ZerpaiToast.success(context, 'Customer address updated in database');
              }
            } catch (e) {
              if (mounted) {
                ZerpaiToast.error(context, 'Failed to update address in database: $e');
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
            offset: const Offset(-333, 20),
            child: Material(
              color: Colors.transparent,
              child: _ConfigureTaxPreferencesDialog(
                initialGst: initialGst,
                initialGstin: _selectedCustomer?.gstin ?? '',
                onUpdate: (newGst, newGstin, isPermanent) async {
                  setState(() {
                    _selectedCustomer = _selectedCustomer?.copyWith(
                      gstTreatment: newGst,
                      gstin: newGstin,
                    );
                  });
                  if (isPermanent && _selectedCustomer != null) {
                    try {
                      await ref.read(salesOrderControllerProvider.notifier).updateCustomer(
                        _selectedCustomer!.id,
                        {
                          'gstTreatment': newGst,
                          'gstin': newGstin,
                        },
                      );
                      if (context.mounted) {
                        ZerpaiToast.success(context, 'Tax preference updated in database');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ZerpaiToast.error(context, 'Failed to update database: $e');
                      }
                    }
                  }
                  _gstTaxOverlay?.remove();
                  _gstTaxOverlay = null;
                },
                onCancel: () {
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
            offset: const Offset(-277, 20),
            child: Material(
              color: Colors.transparent,
              child: _GstinPopover(
                gstin: currentGstin,
                onUpdate: (newGstin) async {
                  setState(() {
                    _selectedCustomer = _selectedCustomer?.copyWith(
                      gstin: newGstin,
                    );
                  });
                  if (_selectedCustomer != null) {
                    try {
                      await ref.read(salesOrderControllerProvider.notifier).updateCustomer(
                        _selectedCustomer!.id,
                        {
                          'gstin': newGstin,
                        },
                      );
                      if (context.mounted) {
                        ZerpaiToast.success(context, 'GSTIN updated in database');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ZerpaiToast.error(context, 'Failed to update database: $e');
                      }
                    }
                  }
                  _gstinOverlay?.remove();
                  _gstinOverlay = null;
                  setState(() {});
                },
                onCancel: () {
                  _gstinOverlay?.remove();
                  _gstinOverlay = null;
                  setState(() {});
                },
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
                    bool isHovered = false;
                    return StatefulBuilder(
                      builder: (context, setStateItem) {
                        return MouseRegion(
                          onEnter: (_) => setStateItem(() => isHovered = true),
                          onExit: (_) => setStateItem(() => isHovered = false),
                          child: InkWell(
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
                                color: isHovered
                                    ? const Color(0xFF3B82F6)
                                    : isSelected
                                        ? const Color(0xFFF3F4F6)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                s,
                                style: TextStyle(
                                  color: isHovered
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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

  void _toggleRowActionsOverlay(SalesOrderItemRow row, List<Item>? products) {
    if (_rowActionsOverlay != null) {
      _rowActionsOverlay?.remove();
      _rowActionsOverlay = null;
      setState(() => _hoveredRowIndex = null);
      return;
    }

    String? hoveredItem;
    _rowActionsOverlay = ZAdaptiveMenu.show(
      context: context,
      link: row.moreActionsLink,
      width: 220,
      alignLeft: false,
      onClose: () {
        _rowActionsOverlay?.remove();
        _rowActionsOverlay = null;
        setState(() => _hoveredRowIndex = null);
      },
      builder: (context) => StatefulBuilder(
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
                        hsnCode: row.hsnCode,
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
                          quantity: '',
                          rate: '',
                          discount: '',
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
                  if (products == null) return;
                  showDialog(
                    context: context,
                    builder: (context) => BulkItemsDialog(
                      products: products,
                      onItemsSelected: (selectedItems) {
                        setState(() {
                          int insertIdx = rows.indexOf(row) + 1;
                          selectedItems.forEach((item, quantity) {
                            rows.insert(
                              insertIdx,
                              _createItemRow(
                                quantity: quantity.toString(),
                                rate: (item.sellingPrice ?? 0) == 0
                                    ? ''
                                    : (item.sellingPrice ?? 0)
                                          .toString(),
                                discount: '0',
                                itemId: item.id ?? '',
                                item: item,
                              ),
                            );
                            insertIdx++;
                          });
                          _calculateTotals();
                        });
                      },
                    ),
                  );
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
                  final idx = rows.indexOf(row);
                  if (idx != -1) {
                    setState(() {
                      rows.insert(
                        idx + 1,
                        _createItemRow(
                          quantity: '0',
                          rate: '0',
                          discount: '0',
                          isHeader: true,
                        ),
                      );
                    });
                  }
                  _rowActionsOverlay?.remove();
                  _rowActionsOverlay = null;
                },
              ),
            ],
          );
        },
      ),
    );
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

    final hsnCtrl = TextEditingController(text: row.hsnCode ?? '');
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
                          suffixWidget: InkWell(
                            onTap: () async {
                              final result = await showDialog<HsnSacCode>(
                                context: context,
                                useSafeArea: false,
                                builder: (context) => HsnSacSearchModal(
                                  type: 'HSN',
                                  initialQuery: hsnCtrl.text,
                                ),
                              );
                              if (result != null) {
                                hsnCtrl.text = result.code;
                                setState(() {
                                  row.hsnCode = result.code;
                                  if (row.item != null) {
                                    row.item = row.item!.copyWith(
                                      hsnCode: result.code,
                                    );
                                  }
                                });
                                _hsnOverlay?.remove();
                                _hsnOverlay = null;
                                _activeHsnRow = null;
                                setState(() {});
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(
                                LucideIcons.search,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
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
                                if (hsnCtrl.text.isEmpty) {
                                  ZerpaiToast.error(
                                    context,
                                    'Please enter HSN Code',
                                  );
                                  return;
                                }
                                setState(() {
                                  row.hsnCode = hsnCtrl.text;
                                  if (row.item != null) {
                                    row.item = row.item!.copyWith(
                                      hsnCode: hsnCtrl.text,
                                    );
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
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
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
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
            final priceLists = _getCombinedPriceLists();
            for (var row in rows) {
              if (row.itemId.isNotEmpty && row.item != null) {
                _updateRowRate(row, c.priceList, priceLists);
              }
            }
          });
          _calculateTotals();
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
            child: const Icon(LucideIcons.search, size: 13, color: _kLabelGrey),
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

  List<AccountNode> _buildNestedAccountsList(List<AccountNode> accounts) {
    final List<AccountNode> nested = [];
    final Map<String, List<AccountNode>> grouped = {};
    for (var acc in accounts) {
      grouped.putIfAbsent(acc.accountType, () => []).add(acc);
    }

    for (var entry in grouped.entries) {
      final type = entry.key;
      final typeAccounts = entry.value;
      nested.add(AccountNode(
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

      void addNode(AccountNode node) {
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

  int _getAccountDepth(AccountNode node, List<AccountNode> accounts) {
    int depth = 0;
    AccountNode? current = node;
    final accountMap = {for (var a in accounts) a.id: a};
    while (current?.parentId != null && accountMap.containsKey(current!.parentId)) {
      depth++;
      current = accountMap[current.parentId];
    }
    return depth;
  }

  Widget _buildStandardLookupRow(
    String label,
    bool isSelected,
    bool isHovered, {
    String? sublabel,
    double indentation = 0.0,
  }) {
    return _dropdownItemBuilder(
      label,
      isSelected,
      isHovered,
      sublabel: sublabel,
      indentation: indentation,
    );
  }
}

Widget _dropdownItemBuilder(
  String label,
  bool isSelected,
  bool isHovered, {
  String? sublabel,
  double indentation = 0.0,
}) {
  return Container(
    padding: EdgeInsets.only(
      left: 12 + indentation,
      right: 12,
      top: 6,
      bottom: 6,
    ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
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
              if (sublabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Inter',
                    color: isHovered ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
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

class _HoverableSalesDescription extends StatefulWidget {
  final TextEditingController controller;
  const _HoverableSalesDescription({required this.controller});
  @override
  State<_HoverableSalesDescription> createState() => _HoverableSalesDescriptionState();
}

class _HoverableSalesDescriptionState extends State<_HoverableSalesDescription> {
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
                  ? const Color(0xFF0088FF) // Selected/Focused blue
                  : (_hovered
                      ? const Color(0xFF2196F3) // Hovered blue
                      : const Color(0xFFE5E7EB)), // Inactive grey
              width: _focused ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: TextField(
            controller: widget.controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: 'Add a description to your item',
              hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
            ),
          ),
        ),
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
        padding: EdgeInsets.zero,
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
              final states = statesAsync.valueOrNull ?? [];
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
// _AddressDialog removed in favor of shared AddressDialog widget.

// ─────────────────────────────────────────────────────────────────────────────
// Tax Preference Dialog — small flyout matching the screenshot
// ─────────────────────────────────────────────────────────────────────────────
class _GstTreatmentOption {
  final String label;
  final String description;
  const _GstTreatmentOption(this.label, this.description);
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
                        color: Color(0xFF6B7280),
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
          const Divider(height: 1),
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
  State<_AccountSelectionPopover> createState() =>
      _AccountSelectionPopoverState();
}

class _AccountSelectionPopoverState extends State<_AccountSelectionPopover> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  Map<String, List<AccountNode>> get _grouped {
    final Map<String, List<AccountNode>> grouped = {};
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
    return Column(
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
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: Color(0xFF6B7280),
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
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Items
                  ...() {
                    final List<Widget> items = [];
                    final groupAccounts = entry.value;
                    final accountMap = {for (var a in groupAccounts) a.id: a};
                    
                    final rootNodes = groupAccounts.where((a) => a.parentId == null || !accountMap.containsKey(a.parentId)).toList();
                    
                    void addNode(AccountNode node, int depth) {
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
        const Divider(height: 1),
      ],
    );
  }
}

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
              if (widget.isSelected) Icon(Icons.check, size: 14, color: text),
            ],
          ),
        ),
      ),
    );
  }
}

class _TdsSelectionPopover extends StatefulWidget {
  final bool isTcs;
  final List<Map<String, dynamic>> tdsRates;
  final List<Map<String, dynamic>> tdsSections;
  final String? selectedTdsId;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final VoidCallback onManageTds;

  const _TdsSelectionPopover({
    required this.isTcs,
    required this.tdsRates,
    required this.tdsSections,
    required this.selectedTdsId,
    required this.onSelected,
    required this.onManageTds,
  });

  @override
  State<_TdsSelectionPopover> createState() => _TdsSelectionPopoverState();
}

class _TdsSelectionPopoverState extends State<_TdsSelectionPopover> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Filter rates based on search query
    final filteredRates = widget.tdsRates.where((rate) {
      final name = (rate['tax_name'] ?? '').toString().toLowerCase();
      final code = (rate['tax_code'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: widget.isTcs ? 'Search TCS rates...' : 'Search TDS rates...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search, size: 14, color: Color(0xFF9CA3AF)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
                    borderSide: const BorderSide(color: Color(0xFF0088FF)),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.tdsSections.expand((section) {
                  final sectionId = section['id']?.toString() ?? '';
                  final sectionCode = section['section_code'] ?? section['nature_name'] ?? '';
                  final sectionDesc = section['description'] ?? section['nature_desc'] ?? '';
                  final sectionRates = filteredRates.where((r) =>
                    (widget.isTcs ? r['tcs_nature_id'] : r['tds_section_id'])?.toString() == sectionId
                  ).toList();

                  if (sectionRates.isEmpty) return const <Widget>[];

                  return [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: const Color(0xFFF9FAFB),
                      child: Text(
                        "$sectionCode - $sectionDesc",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    ...sectionRates.map((rate) {
                      final isSelected = rate['id']?.toString() == widget.selectedTdsId;
                      final taxName = rate['tax_name'] ?? '';
                      final val = double.tryParse(
                        (widget.isTcs ? rate['rate'] : rate['base_rate'])?.toString() ?? '0',
                      );
                      final displayLabel = val == null
                          ? taxName
                          : "$taxName (${val == val.toInt() ? val.toInt() : val}%)";

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

class _ConfigureTaxPreferencesDialog extends StatefulWidget {
  final String initialGst;
  final String initialGstin;
  final Function(String, String, bool) onUpdate;
  final VoidCallback onCancel;

  const _ConfigureTaxPreferencesDialog({
    required this.initialGst,
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
    _selectedTreatment = widget.initialGst;
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 34),
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
                            'Use these settings for all future transactions of this customer.',
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 30),
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


