import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_adaptive_menu.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zerpai_erp/shared/services/sequences_api_service.dart';

import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_item_model.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/customers/presentation/widgets/customer_sidebar.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/items_stock_providers.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/sales_order_item_row.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/sales_item_quick_edit_dialog.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/widgets/advanced_customer_search_dialog.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/modules/sales/customers/presentation/pages/sales_customer_create.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/manage_tds_tcs_rates_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';
import 'package:zerpai_erp/shared/providers/lookup_providers.dart';
import 'package:zerpai_erp/modules/inventory/picklists/providers/inventory_picklists_provider.dart';
import 'package:zerpai_erp/modules/inventory/packages/models/inventory_package_model.dart';
import 'package:zerpai_erp/modules/inventory/packages/providers/inventory_packages_provider.dart';
import 'package:zerpai_erp/modules/auth/providers/user_provider.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';

// ─── Colour constants ────────────────────────────────────────────────────────
const _kBorder = Color(0xFFE5E7EB);
const _kLabelGrey = Color(0xFF6B7280);
const _kBodyText = Color(0xFF111827);
const _kBlue = Color(0xFF2563EB);
const _kGreen = Color(0xFF16A34A);
const _kBg = Color(0xFFF9FAFB);
const _kWhite = Colors.white;
const _kDropdownHeight = 32.0;

String _normalizeDateForUi(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  try {
    if (value.contains('-') && value.length >= 10) {
      final parsed = DateTime.tryParse(value.substring(0, 10));
      if (parsed != null) {
        return intl.DateFormat('dd-MM-yyyy').format(parsed);
      }
    }
    return intl.DateFormat(
      'dd-MM-yyyy',
    ).format(intl.DateFormat('dd-MM-yyyy').parse(value));
  } catch (_) {
    return value;
  }
}

String _getGstTreatmentLabel(String? value) {
  if (value == null) return '';
  const map = {
    'registered_business': 'Registered Business',
    'unregistered_business': 'Unregistered Business',
    'consumer': 'Consumer',
    'overseas': 'Overseas',
    'special_economic_zone': 'Special Economic Zone',
    'sez_developer': 'SEZ Developer',
    'deemed_export': 'Deemed Export',
  };
  return map[value] ?? value;
}

class SalesInvoiceCreateScreen extends ConsumerStatefulWidget {
  final SalesOrder? initialOrder;
  final String? initialOrderId;

  /// Deep-link support: pre-select a customer by ID.
  final String? initialCustomerId;

  /// Deep-link support: clone an existing sales order by ID.
  final String? cloneId;
  final String? fromOrderId;

  const SalesInvoiceCreateScreen({
    super.key,
    this.initialOrder,
    this.initialOrderId,
    this.initialCustomerId,
    this.cloneId,
    this.fromOrderId,
  });

  @override
  ConsumerState<SalesInvoiceCreateScreen> createState() =>
      _SalesInvoiceCreateScreenState();
}

// class SalesOrderItemRow moved to shared file

class _SalesInvoiceCreateScreenState
    extends ConsumerState<SalesInvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceDateKey = GlobalKey();
  final _dueDateKey = GlobalKey();

  List<PlatformFile> _attachedFiles = [];
  OverlayEntry? _attachmentListOverlay;
  final LayerLink _attachmentBadgeLink = LayerLink();
  OverlayEntry? _taxOverlay;
  List<Map<String, dynamic>> taxLines = [];

  String? _selectedCustomerId;
  SalesCustomer? _selectedCustomer;
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
  List<SalesOrder> _confirmedCustomerOrders = [];
  InventoryPackage? _selectedPackage;
  // ignore: unused_field
  List<String> _warehouseBins = [];
  String? _loadedWarehouseId;
  String? _selectedSalesOrderId;

  bool _showSearchItemDetails = false;
  final TextEditingController _itemDetailsSearchCtrl = TextEditingController();
  String _itemDetailsSearchQuery = '';

  late final TextEditingController invoiceNumberCtrl;
  late final TextEditingController orderNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;
  late final TextEditingController termsCtrl;
  late final TextEditingController shippingCtrl;
  late final TextEditingController adjustmentCtrl;
  final FocusNode _adjustmentLabelFocusNode = FocusNode();

  DateTime invoiceDate = DateTime.now();
  DateTime? dueDate;
  String? terms;
  String? deliveryMethod;
  String? salesperson;
  final TextEditingController subjectCtrl = TextEditingController();
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
  List<Map<String, dynamic>> _termsList = [];
  List<Map<String, dynamic>> _salespersonList = [];

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

  bool _isAutoGenerateInvoice = true;
  String _invoicePrefix = 'INV-';
  String _invoiceNextNumber = '00001';

  String _saleType = 'Retail'; // Default
  bool _showAdditionalInfo = true;
  bool _showAvailableStock = true;
  bool _showRecentTransactions = true;
  bool _showPriceList = true;
  OverlayEntry? _rowActionsOverlay;
  AccountNode? _selectedPopupAccount;
  OverlayEntry? _accountsOverlay;
  OverlayEntry? _hsnOverlay;
  OverlayEntry? _itemDetailsSidebarOverlay;
  OverlayEntry? _customerDetailsSidebarOverlay;
  OverlayEntry? _valueTooltipOverlay;
  bool _isLoadingCustomerDetails = false;
  SalesOrderItemRow? _activeHsnRow;
  OverlayEntry? _discountOverlay;
  SalesOrderItemRow? _activeDiscountRow;
  final _addRowLink = LayerLink();
  OverlayEntry? _addRowOverlay;
  final _uploadLink = LayerLink();
  OverlayEntry? _uploadOverlay;
  bool _isUploadButtonHovered = false;
  bool _isAdjustmentLabelHovered = false;

  late TextEditingController adjustmentLabelCtrl;
  bool _isHydratingInitialOrder = false;

  double get _tdsTcsAmount {
    if (_tdsTcsType == 'none' || _selectedTdsTcsId == null) return 0.0;
    return subTotal * _tdsTcsRate / 100;
  }

  bool get _isEditMode =>
      widget.initialOrder != null ||
      (widget.initialOrderId != null && widget.initialOrderId!.isNotEmpty);

  bool get _isSaveAndSendEnabled {
    if (_selectedCustomerId == null) return false;
    if (salesperson == null || salesperson!.trim().isEmpty) return false;

    final activeRows = rows.where((r) => r.itemId.isNotEmpty).toList();
    if (activeRows.isEmpty) return false;

    for (final row in activeRows) {
      final hsn = row.hsnCode ?? row.item?.hsnCode;
      if (hsn == null || hsn.trim().isEmpty) return false;

      if (row.accountId == null || row.accountId!.trim().isEmpty) return false;

      final qty = double.tryParse(row.quantityCtrl.text) ?? 0;
      if (qty <= 0) return false;

      final rate = double.tryParse(row.rateCtrl.text) ?? 0;
      if (rate <= 0) return false;

      if (!row.hasBatchData || row.batchDataList.isEmpty) return false;

      final totalQtyOut = row.batchDataList.fold<double>(
        0.0,
        (sum, b) => sum + (double.tryParse(b['qtyOut'] ?? '') ?? 0.0),
      );
      final totalFoc = row.batchDataList.fold<double>(
        0.0,
        (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
      );
      final expectedQty = totalQtyOut + totalFoc;
      if ((expectedQty - qty).abs() > 0.0001) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    invoiceNumberCtrl = TextEditingController(
      text: 'INV-${intl.DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}',
    );
    // terms = 'Net 360'; // Loaded dynamically in _loadPaymentTerms
    warehouse = '';

    orderNumberCtrl = TextEditingController();
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
    } else if (widget.cloneId != null &&
        widget.cloneId!.isNotEmpty) {
      _loadCloneOrder(widget.cloneId!);
    } else if (widget.fromOrderId != null &&
        widget.fromOrderId!.isNotEmpty) {
      _loadInitialOrder(widget.fromOrderId!);
    } else {
      rows.add(_createItemRow());
      _loadNextInvoiceNumber();
    }
    if (widget.initialCustomerId != null &&
        widget.initialCustomerId!.isNotEmpty) {
      _selectedCustomerId = widget.initialCustomerId;
      _loadConfirmedCustomerOrders();
    }
    _loadPaymentTerms();
    _loadSalespersons();
    _loadTdsRates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsControllerProvider.notifier).loadLookupData();
    });
  }

  Future<void> _loadInitialOrder(String orderId) async {
    setState(() => _isHydratingInitialOrder = true);
    try {
      final api = ref.read(salesOrderApiServiceProvider);
      final SalesOrder order;
      if (widget.initialOrderId != null && widget.initialOrderId == orderId) {
        final raw = await api.getInvoiceById(orderId);
        order = SalesOrder.fromJson(raw);
      } else {
        order = await api.getSalesOrderById(orderId);
      }
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
      ZerpaiToast.error(context, 'Failed to load: $e');
    }
  }

  Future<void> _loadCloneOrder(String cloneId) async {
    setState(() => _isHydratingInitialOrder = true);
    try {
      final api = ref.read(salesOrderApiServiceProvider);
      final raw = await api.getInvoiceById(cloneId);
      final order = SalesOrder.fromJson(raw);
      if (!mounted) return;
      setState(() {
        rows.clear();
        _hydrateFromInitialOrder(order);
        _selectedSalesOrderId = null; // Clear original ID to avoid linking clone as salesOrderId
        _isHydratingInitialOrder = false;
      });
      await _loadNextInvoiceNumber();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (rows.isEmpty) {
          rows.add(_createItemRow());
        }
        _isHydratingInitialOrder = false;
      });
      ZerpaiToast.error(context, 'Failed to load clone invoice: $e');
    }
  }


  void _hydrateFromInitialOrder(SalesOrder order) {
    _selectedCustomerId = order.customerId;
    _selectedCustomer = order.customer;
    _selectedSalesOrderId = order.id;
    invoiceNumberCtrl.text = order.saleNumber;
    orderNumberCtrl.text = order.reference ?? '';
    referenceCtrl.text = order.reference ?? '';
    notesCtrl.text = order.customerNotes ?? '';
    termsCtrl.text = order.termsAndConditions ?? '';
    shippingCtrl.text = order.shippingCharges.toStringAsFixed(2);
    adjustmentCtrl.text = order.adjustment.toStringAsFixed(2);
    invoiceDate = order.saleDate;
    dueDate = order.expectedShipmentDate;
    terms = order.paymentTerms;
    deliveryMethod = order.deliveryMethod;
    salesperson = order.salesperson;
    placeOfSupply = order.placeOfSupply;
    _resolveSalespersonUuid();

    final initialItems = (order.items ?? const <SalesOrderItem>[])
        .where((item) => true)
        .toList();
    if (initialItems.isEmpty) {
      rows.add(_createItemRow());
    } else {
      rows.addAll(initialItems.map(_createItemRowFromOrderItem));
    }

    taxTotal = order.taxTotal;
    subTotal = order.subTotal;
    total = order.total;

    if (order.tdsTotal > 0) {
      _tdsTcsType = 'tds';
      _loadTdsRates().then((_) {
        if (!mounted) return;
        final base = subTotal;
        if (base > 0) {
          final targetRate = (order.tdsTotal / base) * 100;
          Map<String, dynamic>? closestRate;
          double minDiff = 999.0;
          for (final rate in _tdsRatesList) {
            final rateVal = double.tryParse(rate['base_rate']?.toString() ?? '0') ?? 0.0;
            final diff = (rateVal - targetRate).abs();
            if (diff < minDiff) {
              minDiff = diff;
              closestRate = rate;
            }
          }
          if (closestRate != null && minDiff < 0.1) {
            setState(() {
              _selectedTdsTcsId = closestRate!['id']?.toString();
              _tdsTcsRate = double.tryParse(closestRate['base_rate']?.toString() ?? '0') ?? 0.0;
            });
          }
        }
      });
    } else if (order.tcsTotal > 0) {
      _tdsTcsType = 'tcs';
      _loadTdsRates().then((_) {
        if (!mounted) return;
        final base = subTotal;
        if (base > 0) {
          final targetRate = (order.tcsTotal / base) * 100;
          Map<String, dynamic>? closestRate;
          double minDiff = 999.0;
          for (final rate in _tcsRatesList) {
            final rateVal = double.tryParse(rate['rate']?.toString() ?? '0') ?? 0.0;
            final diff = (rateVal - targetRate).abs();
            if (diff < minDiff) {
              minDiff = diff;
              closestRate = rate;
            }
          }
          if (closestRate != null && minDiff < 0.1) {
            setState(() {
              _selectedTdsTcsId = closestRate!['id']?.toString();
              _tdsTcsRate = double.tryParse(closestRate['rate']?.toString() ?? '0') ?? 0.0;
            });
          }
        }
      });
    }

    _loadConfirmedCustomerOrders();
  }

  Future<void> _loadConfirmedCustomerOrders() async {
    final customerId = _selectedCustomerId;
    if (customerId == null) {
      if (mounted) {
        setState(() {
          _confirmedCustomerOrders = [];
        });
      }
      return;
    }

    try {
      Future(() => ref.read(inventoryPackagesProvider.notifier).fetchPackages());
      final api = ref.read(salesOrderApiServiceProvider);
      final allOrders = await api.getSalesOrdersByCustomer(customerId);
      final confirmedOrders = allOrders
          .where((o) => o.status.toLowerCase() == 'confirmed')
          .toList();

      if (mounted) {
        setState(() {
          _confirmedCustomerOrders = confirmedOrders;
        });
      }
    } catch (e) {
      debugPrint('Error loading customer sales orders: $e');
    }
  }

  Future<void> _loadWarehouseBins(String warehouseId) async {
    if (_loadedWarehouseId == warehouseId) return;
    _loadedWarehouseId = warehouseId;
    try {
      final repo = ref.read(inventoryPicklistRepositoryProvider);
      final bins = await repo.getWarehouseBins(warehouseId: warehouseId);
      if (!mounted) return;
      setState(() {
        _warehouseBins = bins
            .map((b) => (b['id'] ?? b['binCode'] ?? '').toString())
            .where((code) => code.isNotEmpty)
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading warehouse bins: $e');
    }
  }

  void _addItemsFromPackage(InventoryPackage package) {
    if (package.items.isEmpty) return;

    final allItems = ref.read(itemsControllerProvider).items;

    setState(() {
      if (rows.length == 1 && rows.first.itemId.isEmpty) {
        rows.clear();
      }

      for (final pkgItem in package.items) {
        final matchedItem = allItems.firstWhere(
          (it) => it.id == pkgItem.productId,
          orElse: () => Item(
            id: pkgItem.productId ?? '',
            type: 'goods',
            productName: pkgItem.itemName ?? 'Unknown Item',
            itemCode: 'ITEM-UNKNOWN',
            unitId: 'unit-uuid',
            sellingPrice: 0,
            costPrice: 0,
            isTrackInventory: true,
            trackBatches: true,
            trackBinLocation: true,
          ),
        );

        final newRow = _createItemRow(
          quantity: pkgItem.quantity.toString(),
          rate: matchedItem.sellingPrice.toString(),
          itemId: pkgItem.productId ?? '',
          item: matchedItem,
        );

        if (pkgItem.batchNo != null && pkgItem.batchNo!.isNotEmpty) {
          newRow.hasBatchData = true;
          newRow.batchCount = 1;
          newRow.batchDataList = [
            {
              'batchRef': pkgItem.batchNo!,
              'batchNo': pkgItem.batchNo!,
              'qtyOut': pkgItem.quantity.toInt().toString(),
              'binLocation': pkgItem.binLocation ?? '',
              'unitPack': '',
              'mrp': '0.00',
              'prate': '0.00',
              'expDate': '',
              'mfgDate': '',
              'mfgBatch': '',
              'foc': '0',
            },
          ];
        }

        rows.add(newRow);
      }

      _calculateTotals();
    });

    ZerpaiToast.success(
      context,
      'Added items from Package: ${package.packageNumber}',
    );
  }

  void _showPendingOrdersDialog() {
    final List<SalesOrder> selectedOrders = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                          'Confirmed Sales Orders',
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
                    const Divider(color: _kBorder),
                    const SizedBox(height: 8),
                    if (_confirmedCustomerOrders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No pending sales orders found for this customer.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      )
                    else ...[
                      Flexible(
                        child: SingleChildScrollView(
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1), // Checkbox
                              1: FlexColumnWidth(4), // Sales Order Details
                              2: FlexColumnWidth(4), // Location
                              3: FlexColumnWidth(3), // Date
                              4: FlexColumnWidth(3), // Amount
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _kBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value:
                                              _confirmedCustomerOrders
                                                  .isNotEmpty &&
                                              selectedOrders.length ==
                                                  _confirmedCustomerOrders
                                                      .length,
                                          activeColor: const Color(0xFF2563EB),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFD1D5DB),
                                            width: 1.5,
                                          ),
                                          onChanged: (val) {
                                            setDialogState(() {
                                              if (val == true) {
                                                selectedOrders.clear();
                                                selectedOrders.addAll(
                                                  _confirmedCustomerOrders,
                                                );
                                              } else {
                                                selectedOrders.clear();
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'SALES ORDER DETAILS',
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
                                      'LOCATION',
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
                                      'DATE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4B5563),
                                      ),
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
                              ..._confirmedCustomerOrders.map((order) {
                                final dateStr = intl.DateFormat(
                                  'dd-MM-yyyy',
                                ).format(order.saleDate);
                                final isChecked = selectedOrders.contains(
                                  order,
                                );
                                final locationStr =
                                    order.customer?.companyName ??
                                    order.customer?.displayName ??
                                    _selectedCustomer?.companyName ??
                                    _selectedCustomer?.displayName ??
                                    '—';
                                final amountFormatter =
                                    intl.NumberFormat.currency(
                                      locale: 'en_IN',
                                      symbol: '₹',
                                      decimalDigits: 2,
                                    );
                                final amountStr = amountFormatter.format(
                                  order.total,
                                );

                                return TableRow(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: _kBorder),
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: isChecked,
                                            activeColor: const Color(
                                              0xFF2563EB,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFD1D5DB),
                                              width: 1.5,
                                            ),
                                            onChanged: (val) {
                                              setDialogState(() {
                                                if (val == true) {
                                                  selectedOrders.add(order);
                                                } else {
                                                  selectedOrders.remove(order);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order.saleNumber,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                          if (order.reference != null &&
                                              order.reference!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              order.reference!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        locationStr,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF4B5563),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
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
                            onPressed: selectedOrders.isEmpty
                                ? null
                                : () {
                                    Navigator.pop(dialogContext);
                                    _addItemsFromMultipleSalesOrders(
                                      selectedOrders,
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

  void _addItemsFromMultipleSalesOrders(List<SalesOrder> orders) {
    if (orders.isEmpty) return;

    setState(() {
      if (rows.length == 1 && rows.first.itemId.isEmpty) {
        rows.clear();
      }

      _selectedSalesOrderId = orders.first.id;

      for (final order in orders) {
        final initialItems = (order.items ?? const <SalesOrderItem>[])
            .where((item) => true)
            .toList();
        rows.addAll(initialItems.map(_createItemRowFromOrderItem));

        if (orderNumberCtrl.text.isEmpty) {
          orderNumberCtrl.text = order.saleNumber;
        } else if (!orderNumberCtrl.text.contains(order.saleNumber)) {
          orderNumberCtrl.text += ', ${order.saleNumber}';
        }
      }

      _calculateTotals();
    });

    final orderNumbers = orders.map((o) => o.saleNumber).join(', ');
    ZerpaiToast.success(
      context,
      'Added items from Sales Orders: $orderNumbers',
    );
  }

  Widget _buildPendingOrdersBanner() {
    if (_selectedCustomerId == null || _confirmedCustomerOrders.isEmpty) {
      return const SizedBox();
    }

    final count = _confirmedCustomerOrders.length;
    final linkText = count == 1
        ? '1 Confirmed Sales Order'
        : '$count Confirmed Sales Orders';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5), // Soft Pink/Red
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFFFEE2E2),
          ), // Soft Pink Border
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.info,
              size: 15,
              color: Color(0xFFEF4444), // Red info icon
            ),
            const SizedBox(width: 8),
            const Text(
              'Include ',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151), // Neutral color for neutral text
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
                    color: Color(0xFF2563EB), // Blue clickable text
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      final users = await ref.read(allUsersProvider.future);
      if (mounted) {
        setState(() {
          _salespersonList = users
              .map(
                (u) => <String, dynamic>{
                  'id': u.fullName,
                  'name': u.fullName,
                  'salesperson_name': u.fullName,
                },
              )
              .toList();

          if (salesperson != null && salesperson!.isNotEmpty) {
            try {
              final matchedUser = users.firstWhere(
                (u) => u.id == salesperson || u.fullName.toLowerCase() == salesperson!.toLowerCase(),
              );
              salesperson = matchedUser.fullName;
            } catch (_) {}
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading salespersons: $e');
    }
  }

  void _resolveSalespersonUuid() {
    if (salesperson == null || salesperson!.isEmpty) return;
    ref.read(allUsersProvider.future).then((users) {
      if (mounted) {
        setState(() {
          try {
            final matchedUser = users.firstWhere(
              (u) => u.id == salesperson || u.fullName.toLowerCase() == salesperson!.toLowerCase(),
            );
            salesperson = matchedUser.fullName;
          } catch (_) {}
        });
      }
    }).catchError((_) {});
  }

  Future<void> _loadNextInvoiceNumber() async {
    if (_isEditMode) return;
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('invoice_master')
          .select('invoice_number')
          .ilike('invoice_number', 'INV-%')
          .order('invoice_number', ascending: false)
          .limit(1)
          .maybeSingle();

      String nextNo = 'INV-00001';
      if (res != null && res['invoice_number'] != null) {
        final currentNo = res['invoice_number'].toString();
        final match = RegExp(r'^([a-zA-Z0-9_-]*?)(\d+)$').firstMatch(currentNo);
        if (match != null) {
          final prefix = match.group(1) ?? 'INV-';
          final numStr = match.group(2) ?? '00000';
          final currentVal = int.tryParse(numStr) ?? 0;
          final newVal = currentVal + 1;
          final paddedNum = newVal.toString().padLeft(numStr.length, '0');
          nextNo = '$prefix$paddedNum';
        }
      } else {
        nextNo = await ref
            .read(sequencesApiServiceProvider)
            .getNextNumber('inv');
      }

      if (mounted) {
        setState(() {
          invoiceNumberCtrl.text = nextNo;
          final match = RegExp(r'^([a-zA-Z0-9_-]*?)(\d+)$').firstMatch(nextNo);
          if (match != null) {
            _invoicePrefix = match.group(1) ?? 'INV-';
            _invoiceNextNumber = match.group(2) ?? '00001';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading next invoice number: $e');
    }
  }

  void _showSalesInvoicePreferencesDialog() async {
    final warehouseList = ref.read(warehousesProvider).value ?? <Warehouse>[];
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
      builder: (context) => _SalesInvoicePreferencesDialog(
        currentPrefix: _invoicePrefix == 'INVOICE-' ? 'INV-' : _invoicePrefix,
        currentNextNumber: () {
          String currentText = invoiceNumberCtrl.text.trim();
          final prefix = _invoicePrefix == 'INVOICE-' ? 'INV-' : _invoicePrefix;
          if (prefix.isNotEmpty && currentText.startsWith(prefix)) {
            return currentText.substring(prefix.length);
          }
          final match = RegExp(r'\d+$').firstMatch(currentText);
          return match != null ? match.group(0)! : _invoiceNextNumber;
        }(),
        isAutoGenerate: _isAutoGenerateInvoice,
        warehouseName: displayedWarehouseName,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _isAutoGenerateInvoice = result['isAutoGenerate'] ?? true;
        _invoicePrefix = result['prefix'] ?? '';
        if (_invoicePrefix == 'INVOICE-') {
          _invoicePrefix = 'INV-';
        }
        _invoiceNextNumber = result['nextNumber'] ?? '';
        if (_isAutoGenerateInvoice) {
          invoiceNumberCtrl.text = '$_invoicePrefix$_invoiceNextNumber';
        }
      });
    }
  }

  Future<void> _loadPaymentTerms() async {
    try {
      final lookupsService = LookupsApiService();
      final fetchedTerms = await lookupsService.getPaymentTerms();
      if (mounted) {
        setState(() {
          _termsList = fetchedTerms;
          if (fetchedTerms.isNotEmpty && terms == null) {
            // Set default to Net 30 if available
            final net30 = fetchedTerms.firstWhere(
              (t) => t['term_name'] == 'Net 30',
              orElse: () => fetchedTerms.first,
            );
            terms = net30['id']?.toString();
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
        items: _termsList,
        selectedId: terms,
        onSelect: (selected) {
          setState(() {
            terms = selected['id']?.toString();
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

  SalesOrderItemRow _createItemRow({
    String quantity = '',
    String rate = '0',
    String discount = '0',
    String fQty = '0',
    String mrp = '0',
    String description = '',
    String itemId = '',
    Item? item,
    String discountType = '%',
    String? taxId,
    String? hsnCode,
    String? priceListId,
    String? accountId,
    String? accountName,
    String? warehouseId,
    bool isHeader = false,
  }) {
    final resolvedAccountId = accountId ?? item?.salesAccountId;
    final resolvedAccountName = accountName ?? item?.salesAccountName;
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
      priceListId: priceListId,
      accountId: resolvedAccountId,
      accountName: resolvedAccountName,
      warehouseId: warehouseId,
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
        final priceLists =
            ref.read(activeSalesPriceListsAsyncProvider).asData?.value ?? [];
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
      item: item.item?.copyWith(hsnCode: item.hsnCode),
      discountType: item.discountType == 'value' ? 'Value' : item.discountType,
      taxId: item.taxId,
      hsnCode: item.hsnCode,
      priceListId: item.priceListId,
      accountId: item.accountId,
      warehouseId: item.warehouseId,
    );

    if (item.batches != null && item.batches!.isNotEmpty) {
      row.hasBatchData = true;
      row.batchCount = item.batches!.length;
      row.batchDataList = item.batches!.map<Map<String, String>>((b) {
        final batchObj = b['batch'] as Map<String, dynamic>?;
        final binObj = b['bin'] as Map<String, dynamic>?;
        final bNo = (batchObj?['batch_no'] ?? b['batch_no'] ?? b['batch_reference'] ?? '').toString();
        final binLoc = (binObj?['bin_code'] ?? b['bin_code'] ?? b['bin_location'] ?? '').toString();
        
        String expD = '';
        final rawExp = b['expiry_date'] ?? batchObj?['expiry_date'];
        if (rawExp != null) {
          expD = _normalizeDateForUi(rawExp.toString());
        }

        return {
          'batchId': (b['batch_id'] ?? '').toString(),
          'layerId': (b['batch_stock_layer_id'] ?? '').toString(),
          'binId': (b['bin_id'] ?? '').toString(),
          'binLocation': binLoc,
          'batchNo': bNo,
          'batchRef': bNo,
          'qtyOut': (b['quantity'] ?? '').toString(),
          'foc': (b['foc_quantity'] ?? '').toString(),
          'mrp': (b['mrp'] ?? '').toString(),
          'prate': (b['purchase_rate'] ?? b['ptr'] ?? b['purchaseRate'] ?? '').toString(),
          'expDate': expD,
          'mfgDate': '',
          'mfgBatch': (b['manufacturer_batch'] ?? '').toString(),
        };
      }).toList();
    }

    return row;
  }

  Future<void> _showSelectBatchesDialog(SalesOrderItemRow row) async {
    final warehouseList = ref.read(warehousesProvider).value ?? <Warehouse>[];
    final selectedWhObj = warehouseList.firstWhere(
      (w) =>
          w.name.trim().toLowerCase() == (warehouse ?? '').trim().toLowerCase(),
      orElse: () => warehouseList.isNotEmpty
          ? warehouseList.first
          : Warehouse(
              id: 'cbd212aa-0a75-430f-b1e7-fb32fdb94b0d',
              name: 'Central Logistics Hub',
            ),
    );
    final warehouseId = selectedWhObj.id;

    final result = await showDialog<_InvoiceBatchDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _InvoiceSelectBatchesDialog(
        itemName: row.item?.productName ?? '',
        productId: row.itemId,
        warehouseName: selectedWhObj.name,
        warehouseId: warehouseId,
        branchId: selectedWhObj.branchId,
        totalQuantity: double.tryParse(row.quantityCtrl.text) ?? 1.0,
        savedBatchData: row.batchDataList,
        isFromPackage: _selectedPackage != null,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      row.hasBatchData = true;
      row.batchCount = result.batchCount;
      row.batchDataList = result.batchDataList ?? [];
      final totalFoc = row.batchDataList.fold<double>(
        0.0,
        (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
      );
      if (totalFoc > 0) {
        row.quantityCtrl.text = result.totalIncludingFoc.toInt().toString();
      } else {
        row.quantityCtrl.text = result.appliedQuantity.toInt().toString();
      }
      _calculateTotals();
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
  void dispose() {
    invoiceNumberCtrl.dispose();
    orderNumberCtrl.dispose();
    notesCtrl.dispose();
    termsCtrl.dispose();
    shippingCtrl.dispose();
    adjustmentCtrl.dispose();
    adjustmentLabelCtrl.dispose();
    subjectCtrl.dispose();
    _adjustmentLabelFocusNode.dispose();
    _scanCtrl.dispose();
    _scanFocusNode.dispose();
    for (var row in rows) {
      row.dispose();
    }
    _itemDetailsSidebarOverlay?.remove();
    _customerDetailsSidebarOverlay?.remove();
    _uploadOverlay?.remove();
    _taxOverlay?.remove();
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
                _selectedSalesOrderId = null;
                // Refresh customer list to include the new one
                // ignore: unused_result
                ref.refresh(salesCustomersProvider);
              });
              _calculateTotals();
              _loadConfirmedCustomerOrders();
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
    int initialTabIndex = 2,
  }) {
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
                initialTabIndex: initialTabIndex,
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
        (pl.itemRates?.any((r) => r.itemId == row.itemId) ?? false);
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
    double currentTaxTotal = 0;
    final Map<double, double> localTaxGroups = {};

    final itemsState = ref.read(itemsControllerProvider);
    final taxRates = itemsState.taxGroups;

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

    final shipping = double.tryParse(shippingCtrl.text) ?? 0.0;
    final adjustment = double.tryParse(adjustmentCtrl.text) ?? 0.0;
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

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final itemsState = ref.watch(itemsControllerProvider);
    final priceListsAsync = ref.watch(activeSalesPriceListsAsyncProvider);
    final currenciesAsync = ref.watch(currenciesProvider(null));

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
                    availableAccounts,
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
            _isEditMode ? 'Edit Invoice' : 'New Invoice',
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
                context.go('/sales/invoices');
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
    final packagesState = ref.watch(inventoryPackagesProvider);
    if (warehouseList.isNotEmpty) {
      final defaultWh = warehouseList.firstWhere(
        (w) => w.isDefaultForBranch,
        orElse: () => warehouseList.first,
      );
      if (defaultWh.name != warehouse && warehouse == '') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              warehouse = defaultWh.name;
            });
            _loadWarehouseBins(defaultWh.id);
          }
        });
      } else {
        final selectedWh = warehouseList.firstWhere(
          (w) => w.name == warehouse,
          orElse: () => warehouseList.first,
        );
        if (_loadedWarehouseId != selectedWh.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadWarehouseBins(selectedWh.id);
          });
        }
      }
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

                  if (_selectedCustomerId != null &&
                      _selectedCustomer == null &&
                      selectedCustomerFromList != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedCustomer = selectedCustomerFromList;
                        });
                      }
                    });
                  }

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
                                enabled: !_isEditMode,
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
                                showSettings: !_isEditMode,
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
                                    _selectedSalesOrderId = null;
                                    priceListId = val.priceList;
                                    placeOfSupply = val.placeOfSupply;
                                    final priceLists =
                                        priceListsAsync.asData?.value ?? [];

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
                                  _loadConfirmedCustomerOrders();
                                },
                              ),
                            ),
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: _isEditMode ? Colors.grey.shade400 : const Color(0xFF10B981), // Emerald-500 or Grey
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
                                onPressed: _isEditMode ? null : () => customersAsync.whenData(
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
                    enabled: !_isEditMode,
                    height: _kDropdownHeight,
                    value: placeOfSupply ?? _selectedCustomer?.placeOfSupply,
                    items: const [
                      '[KL] - Kerala',
                      '[TN] - Tamil Nadu',
                      '[KA] - Karnataka',
                    ], // Simplified options
                    itemBuilder: (item, isSelected, isHovered) =>
                        _dropdownItemBuilder(item, isSelected, isHovered),
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
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Reference#
              SharedFieldLayout(
                label: 'Reference#',
                labelWidth: 180,
                maxWidth: 523,
                child: CustomTextField(controller: referenceCtrl, height: 32),
              ),
              const SizedBox(height: 16),

              // Invoice#
              SharedFieldLayout(
                label: 'Invoice#',
                required: true,
                labelWidth: 180,
                maxWidth: 770,
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
                        controller: invoiceNumberCtrl,
                        height: 32,
                        hintText: 'INV-00000',
                        readOnly: _isAutoGenerateInvoice,
                        suffixWidget: ZTooltip(
                          message: 'Auto-generation settings',
                          child: InkWell(
                            onTap: _showSalesInvoicePreferencesDialog,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(
                                LucideIcons.settings,
                                size: 16,
                                color: _kBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Order Number
              SharedFieldLayout(
                label: 'Order Number',
                labelWidth: 180,
                maxWidth: 523,
                child: CustomTextField(controller: orderNumberCtrl, height: 32),
              ),

              // Invoice Date, Terms, Due Date
              SharedFieldLayout(
                label: 'Invoice Date',
                required: true,
                labelWidth: 180,
                maxWidth: 1021,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: CustomTextField(
                        key: _invoiceDateKey,
                        controller: TextEditingController(
                          text: intl.DateFormat(
                            'dd MMM yyyy',
                          ).format(invoiceDate),
                        ),
                        height: 32,
                        readOnly: true,
                        onTap: () async {
                          final picked = await ZerpaiDatePicker.show(
                            context,
                            initialDate: invoiceDate,
                            targetKey: _invoiceDateKey,
                          );
                          if (picked != null) {
                            setState(() => invoiceDate = picked);
                          }
                        },
                        suffixWidget: const Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: _kLabelGrey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Text(
                      'Terms',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kLabelGrey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FormDropdown<String>(
                        value: terms,
                        height: _kDropdownHeight,
                        items: _termsList
                            .map((t) => t['id'] as String)
                            .toList(),
                        showSettings: true,
                        settingsLabel: 'Configure Terms',
                        onSettingsTap: _showConfigurePaymentTermsDialog,
                        displayStringForValue: (id) {
                          final term = _termsList.firstWhere(
                            (t) => t['id'] == id,
                            orElse: () => {'term_name': id},
                          );
                          return term['term_name'] ?? id;
                        },
                        itemBuilder: (id, isSelected, isHovered) {
                          final term = _termsList.firstWhere(
                            (t) => t['id'] == id,
                            orElse: () => {'term_name': id},
                          );
                          return _dropdownItemBuilder(
                            term['term_name'] ?? id,
                            isSelected,
                            isHovered,
                          );
                        },
                        onChanged: (v) => setState(() => terms = v),
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Text(
                      'Due Date',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kLabelGrey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        key: _dueDateKey,
                        controller: TextEditingController(
                          text: dueDate != null
                              ? intl.DateFormat('dd MMM yyyy').format(dueDate!)
                              : '',
                        ),
                        height: 32,
                        readOnly: true,
                        onTap: () async {
                          final picked = await ZerpaiDatePicker.show(
                            context,
                            initialDate: dueDate ?? DateTime.now(),
                            targetKey: _dueDateKey,
                          );
                          if (picked != null) {
                            setState(() => dueDate = picked);
                          }
                        },
                        suffixWidget: const Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: _kLabelGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Salesperson
              SharedFieldLayout(
                label: 'Salesperson',
                required: true,
                labelWidth: 180,
                maxWidth: 523,
                child: FormDropdown<String>(
                  value: salesperson,
                  height: _kDropdownHeight,
                  allowClear: true,
                  maxVisibleItems: _salespersonList.length > 4
                      ? 4
                      : (_salespersonList.isEmpty
                            ? 1
                            : _salespersonList.length),
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
                      (s) =>
                          (s['id']?.toString() ?? s['name']?.toString()) == id,
                      orElse: () => {'name': id},
                    );
                    return _dropdownItemBuilder(
                      sp['name']?.toString() ?? id,
                      isSelected,
                      isHovered,
                    );
                  },
                  onChanged: (v) => setState(() => salesperson = v),
                ),
              ),

              // Subject
              SharedFieldLayout(
                label: 'Subject',
                labelWidth: 180,
                maxWidth: 523,
                child: CustomTextField(
                  controller: subjectCtrl,
                  height: 32,
                  suffixWidget: ZTooltip(
                    message: 'Let your customer know what this invoice is for',
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.help_outline,
                        size: 14,
                        color: _kLabelGrey,
                      ),
                    ),
                  ),
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
                                    _selectedPackage = null;
                                  });
                                  if (w != null) {
                                    _loadWarehouseBins(w.id);
                                  } else {
                                    setState(() {
                                      _warehouseBins = [];
                                      _loadedWarehouseId = null;
                                    });
                                  }
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

              // Packages Dropdown Row
              if (_selectedCustomerId != null && warehouse != null) ...[
                const SizedBox(height: 16),
                SharedFieldLayout(
                  label: 'Packages',
                  labelWidth: 180,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 320,
                        child: packagesState.isLoading
                            ? const Skeleton(height: 32, width: 320)
                            : (() {
                                final packagesList = packagesState.packages;
                                final filteredPackages = packagesList.where((
                                  pkg,
                                ) {
                                  return pkg.customerId == _selectedCustomerId;
                                }).toList();

                                return FormDropdown<InventoryPackage>(
                                  value: _selectedPackage,
                                  height: _kDropdownHeight,
                                  items: filteredPackages,
                                  hint: 'Select Package',
                                  displayStringForValue: (pkg) =>
                                      pkg.packageNumber,
                                  searchStringForValue: (pkg) =>
                                      pkg.packageNumber,
                                  showSearch: filteredPackages.length > 5,
                                  itemBuilder: (pkg, isSelected, isHovered) =>
                                      _dropdownItemBuilder(
                                        pkg.packageNumber,
                                        isSelected,
                                        isHovered,
                                      ),
                                  onChanged: (pkg) {
                                    setState(() {
                                      _selectedPackage = pkg;
                                      if (pkg != null) {
                                        _addItemsFromPackage(pkg);
                                      }
                                    });
                                  },
                                );
                              })(),
                      ),
                    ],
                  ),
                ),
              ],

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
                      _vLine(),
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
                      const Expanded(
                        flex: 5,
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
                decoration: BoxDecoration(
                  color: _showAdditionalInfo
                      ? const Color(0xFFF3F4F6)
                      : _kWhite,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  border: const Border(
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
        _buildPendingOrdersBanner(),
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
          _TH(label),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              style: const TextStyle(fontSize: 11, color: Color(0xFF111827)),
              textAlign: textAlign,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          InkWell(
            onTap: onToggle,
            child: const Icon(
              LucideIcons.x,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
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
    final priceLists = priceListsAsync.value ?? [];
    final applicablePriceLists = priceLists.where((pl) {
      if (pl.transactionType.toLowerCase() != 'sales') return false;
      if (pl.id == row.priceListId) return true;
      if (pl.priceListType == 'all_items') return true;
      if (pl.priceListType == 'individual_items') {
        return pl.itemRates?.any((r) => r.itemId == row.itemId) ?? false;
      }
      return false;
    }).toList();

    final currentPriceListId = row.priceListId ?? priceListId;
    final currentPriceList = priceLists
        .where((pl) => pl.id == currentPriceListId)
        .firstOrNull;
    bool notIncluded = false;
    if (currentPriceList != null && row.itemId.isNotEmpty) {
      if (currentPriceList.priceListType == 'individual_items') {
        notIncluded =
            !(currentPriceList.itemRates?.any((r) => r.itemId == row.itemId) ??
                false);
      }
    } else if (currentPriceListId != null && row.itemId.isNotEmpty) {
      notIncluded = true;
    }

    final q = double.tryParse(row.quantityCtrl.text) ?? 0;
    final r = double.tryParse(row.rateCtrl.text) ?? 0;
    final d = double.tryParse(row.discountCtrl.text) ?? 0;

    final totalQtyOut = row.batchDataList.fold<double>(
      0.0,
      (sum, b) => sum + (double.tryParse(b['qtyOut'] ?? '') ?? 0.0),
    );
    final totalFoc = row.batchDataList.fold<double>(
      0.0,
      (sum, b) => sum + (double.tryParse(b['foc'] ?? '') ?? 0.0),
    );
    final hasFocValue = totalFoc > 0;

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
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
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
                      _vLine(),
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
                                            child: FormDropdown<String>(
                                              value: null,
                                              height: 32,
                                              hint:
                                                  'Type or click to select an item.',
                                              hideBorderDefault: true,
                                              items: products
                                                  .map((p) => p.id!)
                                                  .toList(),
                                              displayStringForValue: (id) =>
                                                  products
                                                      .firstWhere(
                                                        (p) => p.id == id,
                                                      )
                                                      .productName,
                                              itemBuilder:
                                                  (id, isSelected, isHovered) {
                                                    final p = products
                                                        .firstWhere(
                                                          (p) => p.id == id,
                                                        );
                                                    return Container(
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
                                                        p.productName,
                                                        isSelected,
                                                        isHovered,
                                                        sublabel:
                                                            p.sellingPrice != null
                                                            ? 'Selling Price: ₹${p.sellingPrice!.toStringAsFixed(2)}'
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                              onChanged: (v) {
                                                if (v == null) return;
                                                final dupIdx = rows.indexWhere((r) => r.itemId == v);
                                                if (dupIdx != -1) {
                                                  ZerpaiToast.error(
                                                    context,
                                                    "Item '${products.firstWhere((e) => e.id == v).productName}' is already selected in row ${dupIdx + 1}.",
                                                  );
                                                  return;
                                                }
                                                final p = products.firstWhere(
                                                  (e) => e.id == v,
                                                );
                                                setState(() {
                                                  row.itemId = v;
                                                  row.item = p;
                                                  row.accountId = p.salesAccountId;
                                                  row.accountName = p.salesAccountName;
                                                  final r = (p.sellingPrice ?? 0.0).toDouble();
                                                  row.rateCtrl.text = r == 0
                                                      ? '0'
                                                      : r.toStringAsFixed(2);
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
                                if (row.itemId.isNotEmpty && row.hasBatchData && hasFocValue) ...[
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
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
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
                                            productId: row.itemId,
                                            warehouseName: warehouse ?? '',
                                            selectedView: _selectedStockView,
                                            selectedStockType: _selectedStockType,
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
                                              textAlign: TextAlign.right,
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
                                  if (row.itemId.isNotEmpty &&
                                      (double.tryParse(row.quantityCtrl.text) ?? 0.0) > 0) ...[
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: InkWell(
                                        onTap: () =>
                                            _showSelectBatchesDialog(row),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
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
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF2563EB),
                                                fontFamily: 'Inter',
                                                decoration:
                                                    TextDecoration.underline,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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
                                  keyboardType: TextInputType.text,
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
                                    Transform.translate(
                                      offset: Offset(notIncluded ? -4 : 0, 0),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.centerLeft,
                                        children: [
                                          if (notIncluded)
                                            Transform.translate(
                                              offset: const Offset(-22, 0),
                                              child: ZTooltip(
                                                message:
                                                    "This item has not been included in the selected price list. So, the item's default rate has been used.",
                                                child: const Icon(
                                                  LucideIcons.alertCircle,
                                                  size: 14,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ),
                                          CompositedTransformTarget(
                                            link: row.priceListLink,
                                            child: SizedBox(
                                              width: 120,
                                              height: 32,
                                              child: MouseRegion(
                                                onEnter: (_) {
                                                  final pl = applicablePriceLists
                                                      .where(
                                                        (pl) =>
                                                            pl.id ==
                                                            (row.priceListId ??
                                                                priceListId),
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
                                                  value: applicablePriceLists
                                                      .where(
                                                        (pl) =>
                                                            pl.id ==
                                                            (row.priceListId ??
                                                                priceListId),
                                                      )
                                                      .firstOrNull,
                                                  height: 32,
                                                  hint: 'Apply Price List',
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 10,
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
                                                          );
                                                      setState(() {
                                                        row.priceListId = v.id;
                                                        row.rateCtrl.text = rate
                                                            .toStringAsFixed(2);
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
                                                        : _getTaxDisplayLabel(row.taxId, taxRates),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: row.accountsLink,
              child: InkWell(
                onTap: () => _toggleAccountsOverlay(row, availableAccounts),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.string(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#22C55E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M13.172 2a2 2 0 0 1 1.414.586l6.71 6.71a2.4 2.4 0 0 1 0 3.408l-4.592 4.592a2.4 2.4 0 0 1-3.408 0l-6.71-6.71A2 2 0 0 1 6 9.172V3a1 1 0 0 1 1-1z"/><path d="M2 7v6.172a2 2 0 0 0 .586 1.414l6.71 6.71a2.4 2.4 0 0 0 3.191.193"/><circle cx="10.5" cy="6.5" r=".5" fill="#22C55E"/></svg>',
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 6),
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
            ),
          ],
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
                        onPressed: () => Navigator.of(context).pop(),
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
                          Navigator.of(context).pop();
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
                        onPressed: () => Navigator.of(context).pop(),
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
                          Navigator.of(context).pop();
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
                        onPressed: () => Navigator.of(context).pop(),
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
              'Attach File(s) to Invoice',
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.upload,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Upload File',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            if (_attachedFiles.isNotEmpty)
                              const SizedBox(width: 12),
                            if (_attachedFiles.isNotEmpty)
                              _buildAttachmentBadge(),
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

  Widget _buildAttachmentBadge() {
    return CompositedTransformTarget(
      link: _attachmentBadgeLink,
      child: InkWell(
        onTap: _toggleAttachmentListOverlay,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.file, size: 12, color: Colors.white),
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
                  : (isHovered ? const Color(0xFF3B82F6) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isHovered ? Colors.white : const Color(0xFF374151)),
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
            onPressed: () => _saveSalesInvoice(status: 'draft'),
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
              color: _isSaveAndSendEnabled ? const Color(0xFF10B981) : const Color(0xFFE5E7EB), // Emerald-500 or Disabled Grey
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _isSaveAndSendEnabled
                      ? () => _saveSalesInvoice(
                            status: widget.initialOrder?.status ?? 'sent',
                          )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _isEditMode ? 'Update' : 'Save and Send',
                      style: TextStyle(
                        color: _isSaveAndSendEnabled ? Colors.white : const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: _isSaveAndSendEnabled ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFD1D5DB),
                ),
                InkWell(
                  onTap: _isSaveAndSendEnabled ? () {} : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: _isSaveAndSendEnabled ? Colors.white : const Color(0xFF9CA3AF),
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
                context.go('/sales/invoices');
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

  void _saveSalesInvoice({required String status}) async {
    if (_selectedCustomerId == null) {
      ZerpaiToast.error(context, 'Please select a customer');
      return;
    }
    if (salesperson == null || salesperson!.isEmpty) {
      ZerpaiToast.error(context, 'Please select a salesperson');
      return;
    }

    // Validate that every row has batch data, HSN code, and Account selected
    for (final row in rows.where((r) => r.itemId.isNotEmpty)) {
      final hsn = row.hsnCode ?? row.item?.hsnCode;
      if (hsn == null || hsn.trim().isEmpty) {
        ZerpaiToast.error(
          context,
          'Please select HSN code for item: ${row.item?.productName ?? "selected item"}',
        );
        return;
      }
      if (row.accountId == null || row.accountId!.trim().isEmpty) {
        ZerpaiToast.error(
          context,
          'Please select account for item: ${row.item?.productName ?? "selected item"}',
        );
        return;
      }
      if (!row.hasBatchData || row.batchDataList.isEmpty) {
        ZerpaiToast.error(
          context,
          'Please select batch for item: ${row.item?.productName ?? "selected item"}',
        );
        return;
      }
    }

    // Show elegant loading progress overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      final warehouseList = ref.read(warehousesProvider).value ?? <Warehouse>[];
      final selectedWhObj = warehouseList.firstWhere(
        (w) =>
            w.name.trim().toLowerCase() ==
            (warehouse ?? '').trim().toLowerCase(),
        orElse: () => warehouseList.isNotEmpty
            ? warehouseList.first
            : Warehouse(
                id: 'cbd212aa-0a75-430f-b1e7-fb32fdb94b0d',
                name: 'Central Logistics Hub',
              ),
      );
      final warehouseId = selectedWhObj.id;

      final usersList = ref.read(allUsersProvider).value ?? <User>[];
      User? selectedUserObj;
      try {
        selectedUserObj = usersList.firstWhere(
          (u) =>
              u.fullName.trim().toLowerCase() ==
              (salesperson ?? '').trim().toLowerCase(),
        );
      } catch (_) {
        if (usersList.isNotEmpty) {
          selectedUserObj = usersList.first;
        }
      }
      final salespersonId = selectedUserObj?.id;

      final itemsState = ref.read(itemsControllerProvider);

      final List<Map<String, dynamic>> itemsPayloadList = [];

      for (final row in rows.where((r) => r.itemId.isNotEmpty)) {
        final productId = row.itemId;
        final quantity = double.tryParse(row.quantityCtrl.text) ?? 0.0;
        final rate = double.tryParse(row.rateCtrl.text) ?? 0.0;
        final discount = double.tryParse(row.discountCtrl.text) ?? 0.0;
        final discountType = row.discountType == 'Value' ? 'value' : '%';
        final discountValue = discount;

        final taxRateObj = itemsState.taxGroups.firstWhere(
          (t) => t.id == row.taxId,
          orElse: () => itemsState.taxRates.firstWhere(
            (t) => t.id == row.taxId,
            orElse: () => TaxRate(id: '', taxName: '', taxRate: 0.0),
          ),
        );
        final taxPercentage = taxRateObj.taxRate;

        // Calculate line amounts
        final double rawAmount = quantity * rate;
        final double discountAmt = discountType == '%'
            ? (rawAmount * discount / 100)
            : discount;
        final double taxableAmount = rawAmount - discountAmt;
        final double taxAmount = taxableAmount * (taxPercentage / 100);
        final double lineTotal = taxableAmount + taxAmount;
        final double focQuantity = double.tryParse(row.fQtyCtrl.text) ?? 0.0;

        final List<Map<String, dynamic>> itemBatches = [];

        if (row.batchDataList.isNotEmpty) {
          for (final bData in row.batchDataList) {
            String bId = bData['batchId'] ?? '';
            String lId = bData['layerId'] ?? '';
            String bnId = bData['binId'] ?? '';

            final bNo =
                bData['batchNo']?.trim() ?? bData['batchRef']?.trim() ?? '';
            final binLoc = bData['binLocation']?.trim() ?? '';

            if (bId.isEmpty || lId.isEmpty || bnId.isEmpty) {
              final batches = await ref.read(
                batchLookupProvider(productId).future,
              );
              final bins = await ref
                  .read(inventoryPicklistRepositoryProvider)
                  .getWarehouseBins(
                    warehouseId: warehouseId,
                    productId: productId,
                  );

              if (bId.isEmpty && bNo.isNotEmpty && batches.isNotEmpty) {
                final match = batches.firstWhere(
                  (b) => b['batch_no']?.toString().trim() == bNo,
                  orElse: () => <String, String>{},
                );
                if (match.isNotEmpty) {
                  bId =
                      match['id']?.toString() ??
                      match['batchId']?.toString() ??
                      '';
                  lId =
                      match['layer_id']?.toString() ??
                      match['layerId']?.toString() ??
                      '';
                }
              }
              if (bnId.isEmpty && binLoc.isNotEmpty && bins.isNotEmpty) {
                final match = bins.firstWhere(
                  (b) =>
                      (b['binCode'] ?? b['bin_code'])?.toString().trim() ==
                      binLoc,
                  orElse: () => <String, String>{},
                );
                if (match.isNotEmpty) {
                  bnId = match['id']?.toString() ?? match['binId']?.toString() ?? '';
                }
              }
            }

            itemBatches.add({
              'batchId': bId.isEmpty ? null : bId,
              'layerId': lId.isEmpty ? null : lId,
              'warehouseId': warehouseId,
              'binId': bnId.isEmpty ? null : bnId,
              'quantity': double.tryParse(bData['qtyOut'] ?? '') ?? quantity,
              'focQuantity': double.tryParse(bData['foc'] ?? '') ?? focQuantity,
              'purchaseRate': double.tryParse(bData['prate'] ?? '') ?? 0.0,
              'salesRate':
                  double.tryParse(bData['salesRate'] ?? bData['ptr'] ?? '') ??
                  rate,
              'mrp': double.tryParse(bData['mrp'] ?? '') ?? 0.0,
              'expiryDate': bData['expDate']?.isNotEmpty == true
                  ? bData['expDate']
                  : null,
              'manufacturerBatch': bData['mfgBatch']?.isNotEmpty == true
                  ? bData['mfgBatch']
                  : null,
            });
          }
        } else {
          final trackBatches = row.item?.trackBatches ?? false;
          final trackBinLocation = row.item?.trackBinLocation ?? false;

          if (trackBatches || trackBinLocation) {
            final batches = await ref.read(
              batchLookupProvider(productId).future,
            );
            final bins = await ref
                .read(inventoryPicklistRepositoryProvider)
                .getWarehouseBins(
                  warehouseId: warehouseId,
                  productId: productId,
                );

            String? bId;
            String? lId;
            String? bnId;
            double? prate;
            String? expD;

            if (batches.isNotEmpty) {
              final match = batches.first;
              bId = match['id']?.toString() ?? match['batchId']?.toString();
              lId =
                  match['layer_id']?.toString() ?? match['layerId']?.toString();
              prate = double.tryParse(
                match['prate']?.toString() ?? match['ptr']?.toString() ?? '',
              );
              expD = match['expiry_date']?.toString();
            }

            if (bins.isNotEmpty) {
              final match = bins.first;
              bnId = match['id'] ?? match['binId'];
            }

            itemBatches.add({
              'batchId': (bId == null || bId.isEmpty) ? null : bId,
              'layerId': (lId == null || lId.isEmpty) ? null : lId,
              'warehouseId': warehouseId,
              'binId': (bnId == null || bnId.isEmpty) ? null : bnId,
              'quantity': quantity,
              'focQuantity': focQuantity,
              'purchaseRate': prate ?? 0.0,
              'salesRate': rate,
              'mrp': rate,
              'expiryDate': expD,
              'manufacturerBatch': null,
            });
          }
        }

        itemsPayloadList.add({
          'productId': productId,
          'description': row.descriptionCtrl.text,
          'quantity': quantity,
          'rate': rate,
          'discountType': discountType,
          'discountValue': discountValue,
          'taxId': row.taxId,
          'taxPercentage': taxPercentage,
          'taxableAmount': taxableAmount,
          'taxAmount': taxAmount,
          'lineTotal': lineTotal,
          'focQuantity': focQuantity,
          'hsnCode': row.hsnCode ?? row.item?.hsnCode,
          'accounts': row.accountId,
          'batches': itemBatches,
        });
      }

      final payload = {
        'customerId': _selectedCustomerId,
        'invoiceNumber': invoiceNumberCtrl.text,
        'invoiceDate': intl.DateFormat('yyyy-MM-dd').format(invoiceDate),
        'dueDate': dueDate != null
            ? intl.DateFormat('yyyy-MM-dd').format(dueDate!)
            : null,
        'paymentTerms': terms,
        'salespersonId': salespersonId,
        'warehouseId': warehouseId,
        'placeOfSupply': placeOfSupply ?? _selectedCustomer?.placeOfSupply,
        'shippingCharges': double.tryParse(shippingCtrl.text) ?? 0.0,
        'adjustmentAmount': double.tryParse(adjustmentCtrl.text) ?? 0.0,
        'roundOff': _roundOff,
        'subtotal': subTotal,
        'taxTotal': taxTotal,
        'tdsTotal': _tdsTcsType == 'tds' ? _tdsTcsAmount : 0.0,
        'tcsTotal': _tdsTcsType == 'tcs' ? _tdsTcsAmount : 0.0,
        'grandTotal': total,
        'subject': referenceCtrl.text.isNotEmpty
            ? referenceCtrl.text
            : orderNumberCtrl.text,
        'customerNotes': notesCtrl.text,
        'termsConditions': termsCtrl.text,
        'status': status,
        'inventoryFlowType': _selectedPackage != null
            ? 'PACKAGE_BEFORE_INVOICE'
            : 'DIRECT_INVOICE',
        if (_selectedPackage != null) 'packageId': _selectedPackage!.id,
        if (widget.initialOrderId != null || widget.fromOrderId != null || _selectedSalesOrderId != null)
          'salesOrderId': widget.initialOrderId ?? widget.fromOrderId ?? _selectedSalesOrderId,
        'items': itemsPayloadList,
      };

      final api = ref.read(salesOrderApiServiceProvider);
      final savedInvoice = widget.initialOrderId != null
          ? await api.updateInvoice(widget.initialOrderId!, payload)
          : await api.createInvoice(payload);

      final invoiceId = savedInvoice['id']?.toString();
      if (invoiceId != null && _attachedFiles.isNotEmpty) {
        await _saveAttachments(invoiceId);
      }

      if (_isAutoGenerateInvoice) {
        await ref
            .read(sequencesApiServiceProvider)
            .incrementSequence('invoice', usedNumber: invoiceNumberCtrl.text);
      }

      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading overlay
        ZerpaiToast.success(
          context,
          _isEditMode ? 'Sales invoice updated' : 'Sales invoice created',
        );
        ref.invalidate(salesInvoicesProvider);
        context.go('/sales/invoices');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading overlay
        ZerpaiToast.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _saveAttachments(String invoiceId) async {
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
            'prefix': 'invoices',
          },
        );

        final fileKey = response.data['fileKey'] ?? 'invoices/${file.name}';

        await supabase.from('invoice_attachments').insert({
          'invoice_id': invoiceId,
          'file_name': file.name,
          'file_path': fileKey,
          'file_size': file.size.toString(),
          'uploaded_by': supabase.auth.currentUser?.id,
          'created_at': DateTime.now().toUtc().toIso8601String(),
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

    final countries = ref.watch(countriesProvider(null)).value ?? [];

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
        ? (ref.watch(statesProvider(c.billingAddressCountryId!)).value ?? [])
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
        ? (ref.watch(statesProvider(c.shippingAddressCountryId!)).value ?? [])
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
                    _getGstTreatmentLabel(gst),
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
    
    final hasBilling = (customer.billingAddressStreet1 != null && customer.billingAddressStreet1!.isNotEmpty) ||
        (customer.billingAddressCity != null && customer.billingAddressCity!.isNotEmpty);
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

    final hasShipping = (customer.shippingAddressStreet1 != null && customer.shippingAddressStreet1!.isNotEmpty) ||
        (customer.shippingAddressCity != null && customer.shippingAddressCity!.isNotEmpty);
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
                              _showAddressDialog(title: isBilling ? 'BILLING ADDRESS' : 'SHIPPING ADDRESS');
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
    final isSelected = _areAddressesEqual(activeAddress, address);

    final lines = <String>[
      if (street1.isNotEmpty) street1,
      if (street2.isNotEmpty) street2,
      [city, state, zip].where((s) => s.isNotEmpty).join(', '),
      if (country.isNotEmpty) country,
      if (phone.isNotEmpty) 'Phone: $phone',
    ];

    bool isHovered = false;
    return StatefulBuilder(
      builder: (ctx, setSt) {
        return MouseRegion(
          onEnter: (_) => setSt(() => isHovered = true),
          onExit: (_) => setSt(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              _closeAddressDropdownOverlay();
              final normalizedAddr = _normalizeAddress(address);
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
              ZerpaiToast.success(context, 'Address updated locally');
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
                          if (isHovered)
                            GestureDetector(
                              onTap: () {
                                _closeAddressDropdownOverlay();
                                _showAddressDialog(title: isBilling ? 'BILLING ADDRESS' : 'SHIPPING ADDRESS');
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
            offset: const Offset(-333, 20),
            child: Material(
              color: Colors.transparent,
              child: _TaxPreferenceDialog(
                initialGst: initialGst,
                onUpdate: (newGst, isPermanent) async {
                  setState(() {
                    _selectedCustomer = _selectedCustomer?.copyWith(
                      gstTreatment: newGst,
                    );
                  });
                  if (isPermanent && _selectedCustomer != null) {
                    try {
                      await ref.read(salesOrderControllerProvider.notifier).updateCustomer(
                        _selectedCustomer!.id,
                        {
                          'gstTreatment': newGst,
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
            offset: const Offset(-277, 20),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
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
                    return StatefulBuilder(
                      builder: (context, setStateItem) {
                        bool isHovered = false;
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
                                color: (isHovered || isSelected)
                                    ? const Color(0xFF3B82F6)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                s,
                                style: TextStyle(
                                  color: (isHovered || isSelected)
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                  fontSize: 15,
                                  fontWeight: (isHovered || isSelected)
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

    final hsnCtrl = TextEditingController(
      text: row.hsnCode ?? row.item?.hsnCode ?? '',
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
                                setState(() {
                                  row.hsnCode = hsnCtrl.text;
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
            _selectedSalesOrderId = null;
            priceListId = c.priceList;

            // Trigger rate update for all rows when customer changes
            final priceLists =
                ref.read(activeSalesPriceListsAsyncProvider).asData?.value ?? [];
            for (var row in rows) {
              if (row.itemId.isNotEmpty && row.item != null) {
                _updateRowRate(row, c.priceList, priceLists);
              }
            }
          });
          _calculateTotals();
          _loadConfirmedCustomerOrders();
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

  String _getTaxDisplayLabel(String? taxId, List<TaxRate> taxRates) {
    if (taxId == null) return 'Select Tax';
    if (taxId == 'non_taxable') return 'Non-Taxable';
    if (taxId == 'out_of_scope') return 'Out of Scope';
    if (taxId == 'non_gst') return 'Non-GST Supply';
    final t = taxRates.where((x) => x.id == taxId).firstOrNull;
    if (t != null) {
      return '${t.taxName} [${t.taxRate}%]';
    }
    return 'Select Tax';
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
  final void Function(String, bool)? onUpdate;
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
  bool _makePermanent = false;

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
                    const Text(
                      'Make it permanent?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kBodyText,
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
                            activeColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Use these settings for all future transactions of this customer.',
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
                          widget.onUpdate!(_gst.label, _makePermanent);
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



class _ItemDetailsSidebar extends ConsumerStatefulWidget {
  final SalesOrderItemRow row;
  final VoidCallback onClose;
  final String? customerName;
  final int initialTabIndex;

  const _ItemDetailsSidebar({
    required this.row,
    required this.onClose,
    this.customerName,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<_ItemDetailsSidebar> createState() =>
      _ItemDetailsSidebarState();
}

class _ItemDetailsSidebarState extends ConsumerState<_ItemDetailsSidebar> {
  late int _activeTabIndex;

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
                                widget.row.item?.productName ?? "Select Item",
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
                          '${widget.row.item?.unitName ?? 'pcs'} • ${widget.row.item?.brandName ?? 'OTHER BRANDS'}',
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

  Widget _buildItemDetailsTab() {
    final itemAsync = widget.row.itemId.isNotEmpty
        ? ref.watch(itemDetailByIdProvider(widget.row.itemId))
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
              _detailRow(
                'Price',
                '₹${widget.row.item?.sellingPrice?.toStringAsFixed(2) ?? '0.00'}',
              ),
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
              _detailRow(
                'Price',
                '₹${widget.row.item?.costPrice?.toStringAsFixed(2) ?? '0.00'}',
              ),
              _detailRow(
                'Account',
                widget.row.accountName ?? item?.purchaseAccountName ?? '-',
              ),
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
      itemWarehouseStocksProvider(widget.row.itemId),
    );
    return stockAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stocks) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Physical Stock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
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
                    final isSelected = wh.id == widget.row.warehouseId;
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
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ],
                            ],
                          ),
                        ),
                        _tableCell(wh.physical.onHand.toStringAsFixed(2)),
                        _tableCell(wh.physical.committed.toStringAsFixed(2)),
                        _tableCell(wh.physical.available.toStringAsFixed(2)),
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
                      color: Color(0xFF6B7280),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              GestureDetector(
                onTap: () {}, // Handled by overlay removal usually
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Color(0xFF6B7280),
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

class _SalesInvoicePreferencesDialog extends StatefulWidget {
  final String currentPrefix;
  final String currentNextNumber;
  final bool isAutoGenerate;
  final String? warehouseName;

  const _SalesInvoicePreferencesDialog({
    required this.currentPrefix,
    required this.currentNextNumber,
    required this.isAutoGenerate,
    this.warehouseName,
  });

  @override
  State<_SalesInvoicePreferencesDialog> createState() =>
      __SalesInvoicePreferencesDialogState();
}

class __SalesInvoicePreferencesDialogState
    extends State<_SalesInvoicePreferencesDialog> {
  late bool _isAutoGenerate;
  late TextEditingController _prefixController;
  late TextEditingController _nextNumberController;

  @override
  void initState() {
    super.initState();
    _isAutoGenerate = widget.isAutoGenerate;
    _prefixController = TextEditingController(text: widget.currentPrefix);
    _nextNumberController = TextEditingController(
      text: widget.currentNextNumber,
    );
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _nextNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        top: 0,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Configure Invoice# Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    LucideIcons.x,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Warehouse & Associated Series side-by-side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Warehouse',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.warehouseName ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Associated Series',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Default Transaction Series',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Warning/Info Text
            const Text(
              'Your invoice numbers are set on auto-generate mode to save your time. Are you sure about changing this setting?',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Radio Options
            RadioGroup<bool>(
              groupValue: _isAutoGenerate,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _isAutoGenerate = val);
                }
              },
              child: Column(
                children: [
                  // Option 1: Auto-generate
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: Radio<bool>(
                          value: true,
                          activeColor: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Continue auto-generating invoice numbers',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ZTooltip(
                                  message:
                                      'The edited prefix and next number will be updated in the transaction number series associated with your invoice.',
                                  child: Icon(
                                    LucideIcons.helpCircle,
                                    size: 14,
                                    color: Colors.blue.shade400,
                                  ),
                                ),
                              ],
                            ),
                            if (_isAutoGenerate) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Prefix',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: _prefixController,
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFD1D5DB),
                                              ),
                                            ),
                                            isDense: true,
                                          ),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Next Number',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: _nextNumberController,
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFD1D5DB),
                                              ),
                                            ),
                                            isDense: true,
                                          ),
                                          style: const TextStyle(fontSize: 13),
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
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Option 2: Manual
                  const Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Radio<bool>(
                          value: false,
                          activeColor: Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Enter invoice numbers manually',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'isAutoGenerate': _isAutoGenerate,
                      'prefix': _prefixController.text,
                      'nextNumber': _nextNumberController.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
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
                    style: TextStyle(fontWeight: FontWeight.w600),
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

// ─── Dialog Colour constants ───────────────────────────────────────────────
const _dlgTextPrimary = Color(0xFF1F2937);
const _dlgTextSecondary = Color(0xFF4B5563);
const _dlgBorderCol = Color(0xFFE5E7EB);
const _dlgFocusBorder = Colors.blue;
const _dlgDangerRed = Color(0xFFEF4444);
const _dlgGreenBtn = Color(0xFF16A34A);

class _InvoiceBatchRowController {
  final TextEditingController binLocationCtrl = TextEditingController();
  final TextEditingController batchRefCtrl = TextEditingController();
  final TextEditingController batchNoCtrl = TextEditingController();
  final TextEditingController unitPackCtrl = TextEditingController();
  final TextEditingController mrpCtrl = TextEditingController();
  final TextEditingController ptrCtrl = TextEditingController();
  final TextEditingController qtyOutCtrl = TextEditingController();
  final TextEditingController focCtrl = TextEditingController();
  final TextEditingController expDateCtrl = TextEditingController();
  final TextEditingController mfgDateCtrl = TextEditingController();
  final TextEditingController mfgBatchCtrl = TextEditingController();
  final GlobalKey expKey = GlobalKey();
  final GlobalKey mfgKey = GlobalKey();
  DateTime? expDate;
  DateTime? mfgDate;
  String? batchId;
  String? layerId;
  String? binId;

  void dispose() {
    binLocationCtrl.dispose();
    batchRefCtrl.dispose();
    batchNoCtrl.dispose();
    unitPackCtrl.dispose();
    mrpCtrl.dispose();
    ptrCtrl.dispose();
    qtyOutCtrl.dispose();
    focCtrl.dispose();
    expDateCtrl.dispose();
    mfgDateCtrl.dispose();
    mfgBatchCtrl.dispose();
  }
}

class _InvoiceBatchDialogResult {
  final bool overwriteLineItem;
  final int batchCount;
  final double appliedQuantity;
  final double totalIncludingFoc;
  final List<Map<String, String>>? batchDataList;

  const _InvoiceBatchDialogResult({
    required this.overwriteLineItem,
    required this.batchCount,
    required this.appliedQuantity,
    required this.totalIncludingFoc,
    this.batchDataList,
  });
}

class _InvoiceSelectBatchesDialog extends ConsumerStatefulWidget {
  final String itemName;
  final String productId;
  final String warehouseName;
  final String warehouseId;
  final String? branchId;
  final double totalQuantity;
  final List<Map<String, String>>? savedBatchData;
  final bool isFromPackage;

  _InvoiceSelectBatchesDialog({
    required this.itemName,
    required this.productId,
    required this.warehouseName,
    required this.warehouseId,
    this.branchId,
    required this.totalQuantity,
    this.savedBatchData,
    required this.isFromPackage,
  });

  @override
  ConsumerState<_InvoiceSelectBatchesDialog> createState() =>
      _InvoiceSelectBatchesDialogState();
}

class _InvoiceSelectBatchesDialogState
    extends ConsumerState<_InvoiceSelectBatchesDialog> {
  static const double _batchDropdownHeight = 38;
  static const double _batchTextFieldHeight = 38;
  final List<_InvoiceBatchRowController> _rows = [];
  final Set<int> _hoveredFocRows = <int>{};
  final Set<int> _hoveredBatchRows = <int>{};
  List<String> _binLocations = [];
  List<Map<String, String>> _binsData = [];
  bool _overwriteLineItem = false;
  bool _showMfgDetails = false;
  bool _showFocColumn = false;
  static const String _quantityMismatchMessage =
      'There\'s a mismatch between the quantity entered in the line item and the total quantity across all batches. Click the checkbox to overwrite the quantity in the line item.';

  double _calculateBatchItemEstimatedHeight(
    List<Map<String, dynamic>> batches,
  ) {
    if (batches.isEmpty) return 38;
    double maxLen = 0;
    for (final b in batches) {
      final batchNo = b['batch_no']?.toString() ?? '-';
      final balance = b['balance']?.toString() ?? '0';
      final expDate = b['expiry_date']?.toString() ?? '-';
      final mrp = b['mrp']?.toString() ?? '0.00';
      final ptr = b['prate']?.toString() ?? '0.00';
      final len =
          '$batchNo | Bal: $balance | Exp: $expDate | MRP: $mrp | prate: $ptr'
              .length
              .toDouble();
      if (len > maxLen) {
        maxLen = len;
      }
    }
    if (maxLen > 40) {
      return 52;
    }
    return 38;
  }

  double _calculateBinItemEstimatedHeight(List<String> bins) {
    if (bins.isEmpty) return 38;
    double maxLen = 0;
    for (final b in bins) {
      final len = b.length.toDouble();
      if (len > maxLen) {
        maxLen = len;
      }
    }
    if (maxLen > 22) {
      return 52;
    }
    return 38;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.savedBatchData != null && widget.savedBatchData!.isNotEmpty) {
      for (var batchData in widget.savedBatchData!) {
        final row = _InvoiceBatchRowController();
        row.binLocationCtrl.text = batchData['binLocation'] ?? '';
        row.batchRefCtrl.text = batchData['batchRef'] ?? '';
        row.batchNoCtrl.text = batchData['batchNo'] ?? '';
        row.batchId = batchData['batchId'];
        row.layerId = batchData['layerId'];
        row.binId = batchData['binId'];
        row.unitPackCtrl.text = batchData['unitPack'] ?? '';
        row.mrpCtrl.text = batchData['mrp'] ?? '';
        row.ptrCtrl.text = batchData['prate'] ?? '';
        row.expDateCtrl.text = batchData['expDate'] ?? '';
        if (row.expDateCtrl.text.isNotEmpty) {
          try {
            row.expDate = intl.DateFormat(
              'dd-MM-yyyy',
            ).parse(row.expDateCtrl.text);
          } catch (_) {}
        }
        row.mfgDateCtrl.text = batchData['mfgDate'] ?? '';
        if (row.mfgDateCtrl.text.isNotEmpty) {
          try {
            row.mfgDate = intl.DateFormat(
              'dd-MM-yyyy',
            ).parse(row.mfgDateCtrl.text);
          } catch (_) {}
        }
        row.mfgBatchCtrl.text = batchData['mfgBatch'] ?? '';
        row.qtyOutCtrl.text =
            batchData['qtyOut'] ?? widget.totalQuantity.toInt().toString();
        row.focCtrl.text = batchData['foc'] ?? '';

        if (row.focCtrl.text.isNotEmpty &&
            (double.tryParse(row.focCtrl.text) ?? 0) > 0) {
          _showFocColumn = true;
        }
        if (row.mfgDateCtrl.text.isNotEmpty ||
            row.mfgBatchCtrl.text.isNotEmpty) {
          _showMfgDetails = true;
        }

        _rows.add(row);
      }
    } else {
      final firstRow = _InvoiceBatchRowController();
      firstRow.qtyOutCtrl.text = widget.totalQuantity.toInt().toString();
      _rows.add(firstRow);
    }
  }



  Future<void> _loadBins() async {
    if (widget.warehouseId.isEmpty) {
      debugPrint('⚠️ Warehouse ID is empty in _loadBins (Invoice)');
      return;
    }
    try {
      debugPrint(
        '🔄 Loading bins for Invoice - Warehouse: ${widget.warehouseId}, Product: ${widget.productId}',
      );
      final repository = ref.read(inventoryPicklistRepositoryProvider);
      final bins = await repository.getWarehouseBins(
        warehouseId: widget.warehouseId,
        productId: widget.productId,
      );

      debugPrint('📦 Found ${bins.length} bins from repository for Invoice');

      if (mounted) {
        setState(() {
          _binsData = bins;
          _binLocations = bins
              .map((b) => (b['binCode'] ?? b['bin_code'] ?? '').toString())
              .where((c) => c.isNotEmpty)
              .toList();
        });
        debugPrint('✅ Set _binLocations (Invoice): $_binLocations');
      }
    } catch (e) {
      debugPrint('❌ Error loading bins in Invoice: $e');
    }
  }

  Future<void> _loadInitialData() async {
    await _loadBins();
    if (!widget.isFromPackage) {
      if (mounted) {
        setState(() {
          for (final row in _rows) {
            if (row.binLocationCtrl.text.isNotEmpty) {
              final foundBin = _binsData.firstWhere(
                (b) => b['binCode'] == row.binLocationCtrl.text.trim(),
                orElse: () => <String, String>{},
              );
              row.binId = foundBin['id'];
            }
          }
        });
      }
      return;
    }
    try {
      final batches = await ref.read(
        batchLookupProvider(widget.productId).future,
      );
      if (mounted) {
        setState(() {
          if ((widget.savedBatchData == null ||
                  widget.savedBatchData!.isEmpty) &&
              _rows.isNotEmpty) {
            final row = _rows.first;

            if (_binLocations.isNotEmpty && row.binLocationCtrl.text.isEmpty) {
              row.binLocationCtrl.text = _binLocations.first;
            }
            if (row.binLocationCtrl.text.isNotEmpty) {
              final foundBin = _binsData.firstWhere(
                (b) => b['binCode'] == row.binLocationCtrl.text.trim(),
                orElse: () => <String, String>{},
              );
              row.binId = foundBin['id'];
            }

            // Do not auto-populate batches.first on load, start empty
          } else if (widget.savedBatchData != null &&
              widget.savedBatchData!.isNotEmpty &&
              _rows.isNotEmpty) {
            for (final row in _rows) {
              if (_binLocations.isNotEmpty &&
                  row.binLocationCtrl.text.isEmpty) {
                row.binLocationCtrl.text = _binLocations.first;
              }
              if (row.binLocationCtrl.text.isNotEmpty) {
                final foundBin = _binsData.firstWhere(
                  (b) => b['binCode'] == row.binLocationCtrl.text.trim(),
                  orElse: () => <String, String>{},
                );
                row.binId = foundBin['id'];
              }
              if (batches.isNotEmpty) {
                final batchRef = row.batchRefCtrl.text.trim();
                if (batchRef.isNotEmpty) {
                  final match = batches.firstWhere(
                    (b) => b['batch_no']?.toString().trim() == batchRef,
                    orElse: () => <String, String>{},
                  );
                  if (match.isNotEmpty) {
                    row.batchId =
                        match['id']?.toString() ?? match['batchId']?.toString();
                    row.layerId =
                        match['layer_id']?.toString() ??
                        match['layerId']?.toString();
                    if (row.unitPackCtrl.text.isEmpty) {
                      row.unitPackCtrl.text =
                          match['unit_pack']?.toString() ?? '';
                    }
                    if (row.expDateCtrl.text.isEmpty) {
                      row.expDateCtrl.text = _normalizeDateForUi(
                        match['expiry_date']?.toString() ?? '',
                      );
                      try {
                        row.expDate = intl.DateFormat(
                          'dd-MM-yyyy',
                        ).parse(row.expDateCtrl.text);
                      } catch (_) {}
                    }
                    if (row.mfgDateCtrl.text.isEmpty) {
                      row.mfgDateCtrl.text = _normalizeDateForUi(
                        match['mfg_date']?.toString() ??
                            match['manufactured_date']?.toString() ??
                            '',
                      );
                      try {
                        row.mfgDate = intl.DateFormat(
                          'dd-MM-yyyy',
                        ).parse(row.mfgDateCtrl.text);
                      } catch (_) {}
                    }
                    if (row.mfgBatchCtrl.text.isEmpty) {
                      row.mfgBatchCtrl.text =
                          match['mfg_batch']?.toString() ??
                          match['manufacturer_batch']?.toString() ??
                          '';
                    }
                    if (row.mrpCtrl.text.isEmpty ||
                        row.mrpCtrl.text == '0.00' ||
                        row.mrpCtrl.text == '0') {
                      final prices = match['prices'] as List?;
                      if (prices != null && prices.isNotEmpty) {
                        row.mrpCtrl.text =
                            (prices[0]['mrp'] as num?)
                                ?.toDouble()
                                .toStringAsFixed(2) ??
                            '0.00';
                      } else {
                        row.mrpCtrl.text =
                            (match['mrp'] as num?)?.toDouble().toStringAsFixed(
                              2,
                            ) ??
                            '0.00';
                      }
                    }
                    if (row.ptrCtrl.text.isEmpty ||
                        row.ptrCtrl.text == '0.00' ||
                        row.ptrCtrl.text == '0') {
                      final prices = match['prices'] as List?;
                      if (prices != null && prices.isNotEmpty) {
                        row.ptrCtrl.text =
                            ((prices[0]['ptr'] ??
                                        prices[0]['prate'] ??
                                        prices[0]['purchase_rate'])
                                    as num?)
                                ?.toDouble()
                                .toStringAsFixed(2) ??
                            '0.00';
                      } else {
                        row.ptrCtrl.text =
                            ((match['ptr'] ??
                                        match['prate'] ??
                                        match['purchase_rate'])
                                    as num?)
                                ?.toDouble()
                                .toStringAsFixed(2) ??
                            '0.00';
                      }
                    }
                    if (row.mfgDateCtrl.text.isNotEmpty ||
                        row.mfgBatchCtrl.text.isNotEmpty) {
                      _showMfgDetails = true;
                    }
                  }
                }
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading initial batch data for pre-fill: $e');
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  double get _totalQuantityOnlyOut => _rows.fold<double>(
    0,
    (sum, r) => sum + (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0),
  );

  double get _totalAppliedIncludingFoc => _rows.fold<double>(
    0,
    (sum, r) =>
        sum +
        (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0) +
        (double.tryParse(r.focCtrl.text.trim()) ?? 0),
  );

  double get _quantityToBeAdded =>
      (widget.totalQuantity - _totalQuantityOnlyOut).clamp(
        0,
        widget.totalQuantity,
      );

  bool get _hasQuantityMismatch =>
      (_totalQuantityOnlyOut - widget.totalQuantity).abs() > 0.0001;

  int get _batchCount {
    final refs = _rows
        .where((r) => (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0) > 0)
        .map((r) => r.batchRefCtrl.text.trim())
        .where((ref) => ref.isNotEmpty)
        .toSet();
    return refs.length;
  }

  void _addRow() {
    setState(() {
      _rows.add(_InvoiceBatchRowController());
    });
  }

  void _removeRow(int index) {
    setState(() {
      if (_rows.length == 1) {
        _rows[index].batchRefCtrl.clear();
        _rows[index].qtyOutCtrl.clear();
      } else {
        _rows[index].dispose();
        _rows.removeAt(index);
      }
    });
  }

  Widget _headerCell(
    String text,
    int flex, {
    TextAlign alignment = TextAlign.center,
  }) {
    final isRequired = text.contains('*');
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          textAlign: alignment,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isRequired ? const Color(0xFFD32F2F) : _dlgTextPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required int flex,
    required String hint,
    bool isNumber = false,
    bool readOnly = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : null,
            inputFormatters: isNumber
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : [],
            textAlign: isNumber ? TextAlign.right : TextAlign.left,
            textAlignVertical: TextAlignVertical.center,
            strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
            style: TextStyle(
              fontSize: 13,
              color: readOnly ? _dlgTextSecondary : _dlgTextPrimary,
              fontFamily: 'Inter',
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: false,
              hintText: hint,
              hintStyle: const TextStyle(
                color: _dlgTextSecondary,
                fontSize: 13,
              ),
              filled: true,
              fillColor: readOnly ? const Color(0xFFF9FAFB) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              constraints: const BoxConstraints(
                minHeight: _batchTextFieldHeight,
                maxHeight: _batchTextFieldHeight,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? const Color(0xFFE5E7EB) : _dlgBorderCol,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? const Color(0xFFE5E7EB) : _dlgFocusBorder,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required TextEditingController controller,
    required GlobalKey anchorKey,
    required int flex,
    required DateTime? currentDate,
    required ValueChanged<DateTime?> onDateChanged,
    bool readOnly = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: _batchTextFieldHeight,
          child: TextField(
            key: anchorKey,
            controller: controller,
            readOnly: true,
            textAlignVertical: TextAlignVertical.center,
            strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
            style: TextStyle(
              fontSize: 13,
              color: readOnly ? _dlgTextSecondary : _dlgTextPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              isDense: false,
              hintText: '',
              hintStyle: const TextStyle(
                color: _dlgTextSecondary,
                fontSize: 13,
              ),
              filled: true,
              fillColor: readOnly ? const Color(0xFFF9FAFB) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              constraints: const BoxConstraints(
                minHeight: _batchTextFieldHeight,
                maxHeight: _batchTextFieldHeight,
              ),
              suffixIcon: Icon(
                LucideIcons.calendar,
                size: 14,
                color: readOnly ? const Color(0xFFD1D5DB) : _dlgTextSecondary,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 32,
                maxWidth: 32,
                minHeight: _batchTextFieldHeight,
                maxHeight: _batchTextFieldHeight,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? const Color(0xFFE5E7EB) : _dlgBorderCol,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? const Color(0xFFE5E7EB) : _dlgFocusBorder,
                  width: 1.4,
                ),
              ),
            ),
            onTap: () async {
              if (readOnly) return;
              final picked = await ZerpaiDatePicker.show(
                context,
                initialDate: currentDate ?? DateTime.now(),
                targetKey: anchorKey,
              );
              if (picked != null) {
                onDateChanged(picked);
                controller.text = intl.DateFormat('dd-MM-yyyy').format(picked);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFocInput(_InvoiceBatchRowController row, int index) {
    final isHovered = _hoveredFocRows.contains(index);
    return Expanded(
      flex: 15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredFocRows.add(index)),
          onExit: (_) => setState(() => _hoveredFocRows.remove(index)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: _batchTextFieldHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isHovered ? _dlgFocusBorder : _dlgBorderCol,
                width: isHovered ? 1.4 : 1,
              ),
            ),
            child: TextField(
              controller: row.focCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.right,
              textAlignVertical: TextAlignVertical.center,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
              style: const TextStyle(
                fontSize: 13,
                color: _dlgTextPrimary,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                isDense: false,
                hintText: '0',
                hintStyle: const TextStyle(
                  color: _dlgTextSecondary,
                  fontSize: 13,
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                constraints: const BoxConstraints(
                  minHeight: _batchTextFieldHeight,
                  maxHeight: _batchTextFieldHeight,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      child: SizedBox(
        width: _showMfgDetails
            ? (_showFocColumn ? 1480 : 1320)
            : (_showFocColumn ? 1320 : 1160),
        height: MediaQuery.of(context).size.height * 0.86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Select Batches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _dlgTextPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: _dlgDangerRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _dlgBorderCol),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.home,
                    size: 16,
                    color: _dlgTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Location : ${widget.warehouseName.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _dlgTextPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'BATCH DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dlgTextPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      'Item: ${widget.itemName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _dlgTextSecondary,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Total Quantity : ${widget.totalQuantity.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _dlgTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('|', style: TextStyle(color: _dlgTextSecondary)),
                  const SizedBox(width: 8),
                  Text(
                    'Quantity to be added : ${_quantityToBeAdded.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _dlgTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: _showMfgDetails,
                      onChanged: (val) =>
                          setState(() => _showMfgDetails = val ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: _dlgGreenBtn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Manufacture Details',
                    style: TextStyle(fontSize: 13, color: _dlgTextPrimary),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: _showFocColumn,
                      onChanged: (val) =>
                          setState(() => _showFocColumn = val ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: _dlgGreenBtn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FOC',
                    style: TextStyle(fontSize: 13, color: _dlgTextPrimary),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: _overwriteLineItem,
                      onChanged: (val) => setState(() {
                        _overwriteLineItem = val ?? false;
                      }),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: _dlgGreenBtn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overwrite the line item with ${_totalQuantityOnlyOut.toInt()} quantities',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _dlgTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _dlgBorderCol),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(bottom: BorderSide(color: _dlgBorderCol)),
              ),
              child: Row(
                children: [
                  _headerCell('BIN LOCATION*', 15),
                  _headerCell('BATCH NO*', 15),
                  _headerCell('PACK SIZE*', 15),
                  _headerCell('MRP*', 15),
                  _headerCell('PURCHASE RATE*', 15),
                  _headerCell('EXPIRY DATE*', 15),
                  if (_showMfgDetails) ...[
                    _headerCell('MANUFACTURED DATE', 15),
                    _headerCell('MANUFACTURER BATCH', 15),
                  ],
                  _headerCell('QUANTITY OUT*', 15),
                  if (_showFocColumn) _headerCell('FOC', 15),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  final isRowHovered = _hoveredBatchRows.contains(index);
                  return Column(
                    children: [
                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => _hoveredBatchRows.add(index)),
                        onExit: (_) =>
                            setState(() => _hoveredBatchRows.remove(index)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 15,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: _InvoiceBinHoverBox(
                                    isEnabled:
                                        row.binLocationCtrl.text.isNotEmpty,
                                    message: row.binLocationCtrl.text,
                                    child: SizedBox(
                                      height: _batchDropdownHeight,
                                      child: FormDropdown<String>(
                                        height: _batchDropdownHeight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _dlgBorderCol,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        value:
                                            _binLocations.contains(
                                              row.binLocationCtrl.text.trim(),
                                            )
                                            ? row.binLocationCtrl.text.trim()
                                            : null,
                                        items: _binLocations,
                                        hint: 'Select Bin',
                                        showSearch: true,
                                        maxVisibleItems: 8,
                                        menuMaxHeight: 400,
                                        menuWidth: 160,
                                        itemEstimatedHeight:
                                            _calculateBinItemEstimatedHeight(
                                              _binLocations,
                                            ),
                                        displayStringForValue: (v) => v,
                                        searchStringForValue: (v) => v,
                                        itemBuilder:
                                            (
                                              item,
                                              isSelected,
                                              isHovered,
                                            ) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              color: isHovered
                                                  ? const Color(0xFF3B82F6)
                                                  : (isSelected
                                                        ? const Color(
                                                            0xFFF3F4F6,
                                                          )
                                                        : Colors.transparent),
                                              child: Text(
                                                item,
                                                softWrap: true,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isHovered
                                                      ? Colors.white
                                                      : const Color(0xFF1F2937),
                                                ),
                                              ),
                                            ),
                                        onChanged: (val) {
                                          setState(() {
                                            row.binLocationCtrl.text =
                                                val ?? '';
                                            if (val != null) {
                                              final foundBin = _binsData
                                                  .firstWhere(
                                                    (b) =>
                                                        (b['binCode'] ??
                                                            b['bin_code']) ==
                                                        val.trim(),
                                                    orElse: () =>
                                                        <String, String>{},
                                                  );
                                              row.binId =
                                                  foundBin['id'] ??
                                                  foundBin['binId'];
                                            } else {
                                              row.binId = null;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 15,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: SizedBox(
                                    height: _batchDropdownHeight,
                                    child: Consumer(
                                      builder: (context, ref, _) {
                                        final batchesAsync = ref.watch(
                                          batchLookupProvider(widget.productId),
                                        );
                                        final batches =
                                            batchesAsync.value ?? [];

                                        return FormDropdown<
                                          Map<String, dynamic>
                                        >(
                                          height: _batchDropdownHeight,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: _dlgBorderCol,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          value:
                                              batches
                                                  .firstWhere(
                                                    (b) =>
                                                        b['batch_no']
                                                            ?.toString()
                                                            .trim() ==
                                                        row.batchRefCtrl.text
                                                            .trim(),
                                                    orElse: () =>
                                                        <String, String>{},
                                                  )
                                                  .isEmpty
                                              ? null
                                              : batches.firstWhere(
                                                  (b) =>
                                                      b['batch_no']
                                                          ?.toString()
                                                          .trim() ==
                                                      row.batchRefCtrl.text
                                                          .trim(),
                                                ),
                                          items: batches,
                                          hint: 'Select Batch',
                                          showSearch: true,
                                          menuMaxHeight: 400,
                                          menuWidth: 260,
                                          itemEstimatedHeight:
                                              _calculateBatchItemEstimatedHeight(
                                                batches,
                                              ),
                                          itemBuilder:
                                              (item, isSelected, isHovered) {
                                                final batchNo =
                                                    item['batch_no']
                                                        ?.toString() ??
                                                    '-';
                                                final balance =
                                                    item['balance']
                                                        ?.toString() ??
                                                    '0';
                                                final expDate =
                                                    item['expiry_date']
                                                        ?.toString() ??
                                                    '-';
                                                final mrp =
                                                    item['mrp']?.toString() ??
                                                    '0.00';
                                                final ptr =
                                                    item['prate']?.toString() ??
                                                    '0.00';

                                                final displayText =
                                                    '$batchNo | Bal: $balance | Exp: $expDate | MRP: $mrp | prate: $ptr';

                                                return Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  color: isHovered
                                                      ? const Color(0xFF3B82F6)
                                                      : (isSelected
                                                            ? const Color(
                                                                0xFFF3F4F6,
                                                              )
                                                            : Colors
                                                                  .transparent),
                                                  child: Text(
                                                    displayText,
                                                    softWrap: true,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isHovered
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF1F2937,
                                                            ),
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                );
                                              },
                                          displayStringForValue: (v) =>
                                              v['batch_no']?.toString() ?? '',
                                          searchStringForValue: (v) =>
                                              v['batch_no']?.toString() ?? '',
                                          onChanged: (v) {
                                            setState(() {
                                              if (v != null) {
                                                final batchNo = v['batch_no']
                                                    ?.toString()
                                                    .trim();
                                                row.batchRefCtrl.text =
                                                    batchNo ?? '';
                                                row.batchNoCtrl.text =
                                                    batchNo ?? '';

                                                row.batchId =
                                                    v['id']?.toString() ??
                                                    v['batchId']?.toString();
                                                row.layerId =
                                                    v['layer_id']?.toString() ??
                                                    v['layerId']?.toString();

                                                row.unitPackCtrl.text =
                                                    v['unit_pack']
                                                        ?.toString() ??
                                                    '';

                                                final rawExp =
                                                    v['expiry_date']
                                                        ?.toString() ??
                                                    '';
                                                row.expDateCtrl.text =
                                                    _normalizeDateForUi(rawExp);
                                                if (row
                                                    .expDateCtrl
                                                    .text
                                                    .isNotEmpty) {
                                                  try {
                                                    row.expDate =
                                                        intl.DateFormat(
                                                          'dd-MM-yyyy',
                                                        ).parse(
                                                          row.expDateCtrl.text,
                                                        );
                                                  } catch (_) {}
                                                }

                                                final rawMfgDate =
                                                    v['mfg_date']?.toString() ??
                                                    v['manufactured_date']
                                                        ?.toString() ??
                                                    '';
                                                row.mfgDateCtrl.text =
                                                    _normalizeDateForUi(
                                                      rawMfgDate,
                                                    );
                                                if (row
                                                    .mfgDateCtrl
                                                    .text
                                                    .isNotEmpty) {
                                                  try {
                                                    row.mfgDate =
                                                        intl.DateFormat(
                                                          'dd-MM-yyyy',
                                                        ).parse(
                                                          row.mfgDateCtrl.text,
                                                        );
                                                  } catch (_) {}
                                                }
                                                row.mfgBatchCtrl.text =
                                                    v['mfg_batch']
                                                        ?.toString() ??
                                                    v['manufacturer_batch']
                                                        ?.toString() ??
                                                    '';
                                                if (row
                                                        .mfgDateCtrl
                                                        .text
                                                        .isNotEmpty ||
                                                    row
                                                        .mfgBatchCtrl
                                                        .text
                                                        .isNotEmpty) {
                                                  _showMfgDetails = true;
                                                }

                                                final prices =
                                                    v['prices'] as List?;
                                                if (prices != null &&
                                                    prices.isNotEmpty) {
                                                  final p = prices[0];
                                                  row.mrpCtrl.text =
                                                      (p['mrp'] as num?)
                                                          ?.toDouble()
                                                          .toStringAsFixed(2) ??
                                                      '0.00';
                                                  row.ptrCtrl.text =
                                                      ((p['ptr'] ??
                                                                  p['prate'] ??
                                                                  p['purchase_rate'])
                                                              as num?)
                                                          ?.toDouble()
                                                          .toStringAsFixed(2) ??
                                                      '0.00';
                                                } else {
                                                  row.mrpCtrl.text =
                                                      (v['mrp'] as num?)
                                                          ?.toDouble()
                                                          .toStringAsFixed(2) ??
                                                      '0.00';
                                                  row.ptrCtrl.text =
                                                      ((v['ptr'] ??
                                                                  v['prate'] ??
                                                                  v['purchase_rate'])
                                                              as num?)
                                                          ?.toDouble()
                                                          .toStringAsFixed(2) ??
                                                      '0.00';
                                                }
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              _buildInput(
                                controller: row.unitPackCtrl,
                                flex: 15,
                                hint: 'Pack',
                                isNumber: true,
                                readOnly: true,
                              ),
                              _buildInput(
                                controller: row.mrpCtrl,
                                flex: 15,
                                hint: '0',
                                isNumber: true,
                                readOnly: true,
                              ),
                              _buildInput(
                                controller: row.ptrCtrl,
                                flex: 15,
                                hint: '0',
                                isNumber: true,
                                readOnly: true,
                              ),
                              _buildDatePicker(
                                controller: row.expDateCtrl,
                                anchorKey: row.expKey,
                                flex: 15,
                                currentDate: row.expDate,
                                onDateChanged: (d) =>
                                    setState(() => row.expDate = d),
                                readOnly: true,
                              ),
                              if (_showMfgDetails) ...[
                                _buildDatePicker(
                                  controller: row.mfgDateCtrl,
                                  anchorKey: row.mfgKey,
                                  flex: 15,
                                  currentDate: row.mfgDate,
                                  onDateChanged: (d) =>
                                      setState(() => row.mfgDate = d),
                                  readOnly: true,
                                ),
                                _buildInput(
                                  controller: row.mfgBatchCtrl,
                                  flex: 15,
                                  hint: 'Mfg Batch',
                                  readOnly: true,
                                ),
                              ],
                              _buildInput(
                                controller: row.qtyOutCtrl,
                                flex: 15,
                                hint: '0',
                                isNumber: true,
                              ),
                              if (_showFocColumn) _buildFocInput(row, index),
                              SizedBox(
                                width: 24,
                                child: AnimatedOpacity(
                                  opacity: isRowHovered ? 1 : 0,
                                  duration: const Duration(milliseconds: 120),
                                  child: IconButton(
                                    onPressed: () => _removeRow(index),
                                    tooltip: 'Remove row',
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      LucideIcons.x,
                                      size: 15,
                                      color: _dlgDangerRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < _rows.length - 1)
                        const Divider(height: 1, color: _dlgBorderCol),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: _addRow,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.plusCircle,
                          size: 14,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'New Row',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Batches added: ${_rows.length}/100',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _dlgTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _dlgBorderCol),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      for (var i = 0; i < _rows.length; i++) {
                        final row = _rows[i];
                        if (row.binLocationCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please select Bin Location in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.batchRefCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please select Batch Reference in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.batchNoCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please enter Batch No in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.unitPackCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please enter Pack Size in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.mrpCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please enter MRP in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.expDateCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please select Expiry Date in Row ${i + 1}.',
                          );
                          return;
                        }

                        final qtyOut =
                            double.tryParse(row.qtyOutCtrl.text.trim()) ?? 0;
                        final foc =
                            double.tryParse(row.focCtrl.text.trim()) ?? 0;
                        if (qtyOut <= 0 && foc <= 0) {
                          ZerpaiToast.error(
                            context,
                            'Either Quantity Out or FOC must be filled in Row ${i + 1}.',
                          );
                          return;
                        }
                      }

                      final seenPairs = <String>{};
                      for (var i = 0; i < _rows.length; i++) {
                        final row = _rows[i];
                        final bin = row.binLocationCtrl.text.trim();
                        final batch = row.batchNoCtrl.text.trim();
                        if (bin.isNotEmpty && batch.isNotEmpty) {
                          final pair = '$bin|$batch';
                          if (seenPairs.contains(pair)) {
                            ZerpaiToast.error(
                              context,
                              'Same Bin Location and Batch No can\'t be used multiple times.',
                            );
                            return;
                          }
                          seenPairs.add(pair);
                        }
                      }

                      if (_hasQuantityMismatch && !_overwriteLineItem) {
                        ZerpaiToast.error(context, _quantityMismatchMessage);
                        return;
                      }

                      final batchDataList = _rows
                          .map(
                            (row) => {
                              'binLocation': row.binLocationCtrl.text,
                              'batchRef': row.batchRefCtrl.text,
                              'batchNo': row.batchNoCtrl.text,
                              'unitPack': row.unitPackCtrl.text,
                              'mrp': row.mrpCtrl.text,
                              'prate': row.ptrCtrl.text,
                              'expDate': row.expDateCtrl.text,
                              'mfgDate': row.mfgDateCtrl.text,
                              'mfgBatch': row.mfgBatchCtrl.text,
                              'qtyOut': row.qtyOutCtrl.text,
                              'foc': row.focCtrl.text,
                              'batchId': row.batchId ?? '',
                              'layerId': row.layerId ?? '',
                              'binId': row.binId ?? '',
                            },
                          )
                          .toList();

                      Navigator.pop(
                        context,
                        _InvoiceBatchDialogResult(
                          overwriteLineItem: _overwriteLineItem,
                          batchCount: _batchCount > 0
                              ? _batchCount
                              : _rows.length,
                          appliedQuantity: _totalQuantityOnlyOut,
                          totalIncludingFoc: _totalAppliedIncludingFoc,
                          batchDataList: batchDataList,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dlgGreenBtn,
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
                      foregroundColor: _dlgTextPrimary,
                      side: const BorderSide(color: _dlgBorderCol),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceBinHoverBox extends StatefulWidget {
  final String message;
  final Widget child;
  final bool isEnabled;

  const _InvoiceBinHoverBox({
    required this.message,
    required this.child,
    this.isEnabled = true,
  });

  @override
  State<_InvoiceBinHoverBox> createState() => _InvoiceBinHoverBoxState();
}

class _InvoiceBinHoverBoxState extends State<_InvoiceBinHoverBox> {
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_entry != null || !widget.isEnabled) return;
    _entry = _createOverlayEntry();
    Overlay.maybeOf(context)?.insert(_entry!);
  }

  void _hideOverlay() {
    _entry?.remove();
    _entry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                  ),
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showOverlay(),
        onExit: (_) => _hideOverlay(),
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
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

