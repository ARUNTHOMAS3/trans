import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchases_purchase_orders_order_model.dart';
import '../providers/purchases_purchase_orders_provider.dart' hide warehousesProvider;
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../items/items/models/item_model.dart';
import '../../../items/items/models/tax_rate_model.dart';
import '../../../inventory/providers/stock_provider.dart';
import '../../../items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';

class PurchaseOrderState {
  final List<PurchaseOrderItem> items;
  final String orderNumber;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String? referenceNumber;
  final String? vendorId;
  final String? paymentTerms;
  final String? shipmentPreference;
  final String deliveryType; // 'warehouse' | 'customer'
  final String? deliveryWarehouseId;
  final String? deliveryCustomerId;
  final String? warehouseId; // Independent main warehouse
  final String? deliveryAddressName; // Editable name in the address card
  final double discount;
  final String discountType; // 'percentage' | 'fixed'
  final String? tdsTcsType; // 'tds' | 'tcs' | 'none'
  final String? tdsTcsId;
  final double adjustment;
  final String? notes;
  final String? termsAndConditions;
  final String destinationOfSupply;
  final String discountLevel; // 'transaction' | 'item'
  final String? discountAccountId;
  final String? discountAccountName;
  final bool isReverseCharge;
  final bool isSaving;
  final bool isNumberingAuto;
  final String poPrefix;
  final int poNextNumber;
  final int poPadding;
  final String taxType; // 'exclusive' | 'inclusive'
  final double tdsTcsRate;

  PurchaseOrderState({
    this.items = const [],
    this.orderNumber = '',
    required this.orderDate,
    this.expectedDeliveryDate,
    this.referenceNumber,
    this.vendorId,
    this.paymentTerms,
    this.shipmentPreference,
    this.deliveryType = 'warehouse',
    this.deliveryWarehouseId,
    this.deliveryCustomerId,
    this.warehouseId,
    this.deliveryAddressName,
    this.discount = 0.0,
    this.discountType = 'percentage',
    this.tdsTcsType = 'tds',
    this.tdsTcsId,
    this.adjustment = 0.0,
    this.notes,
    this.termsAndConditions,
    this.destinationOfSupply = '',
    this.discountLevel = 'transaction',
    this.discountAccountId,
    this.discountAccountName,
    this.isReverseCharge = false,
    this.isSaving = false,
    this.isNumberingAuto = true,
    this.poPrefix = 'PO-',
    this.poNextNumber = 1,
    this.poPadding = 5,
    this.taxType = 'exclusive',
    this.tdsTcsRate = 0.0,
  });

  double get subTotal => items
      .where((i) => !i.isHeader)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get discountValue {
    if (discountLevel == 'item') {
      double totalItemDiscount = 0.0;
      for (final item in items.where((i) => !i.isHeader)) {
        if (item.discount > 0) {
          if (item.discountType == 'percentage') {
            totalItemDiscount += (item.rate * item.quantity) * (item.discount / 100);
          } else {
            totalItemDiscount += item.discount;
          }
        }
      }
      return totalItemDiscount;
    }
    double manualDiscount = 0.0;
    if (discountType == 'percentage') {
      manualDiscount = subTotal * (discount / 100);
    } else {
      manualDiscount = discount;
    }
    return manualDiscount;
  }

  double get taxAmount {
    return items
        .where((i) => !i.isHeader)
        .fold(0.0, (sum, item) => sum + item.taxAmount);
  }

  double get tdsTcsAmount {
    final double effectiveDiscount = discountLevel == 'item' ? 0.0 : discountValue;
    return (subTotal - effectiveDiscount) * (tdsTcsRate / 100);
  }

  double get total {
    final double effectiveDiscount = discountLevel == 'item' ? 0.0 : discountValue;
    final baseVal = taxType == 'inclusive'
        ? subTotal - effectiveDiscount + adjustment
        : subTotal - effectiveDiscount + taxAmount + adjustment;
    if (tdsTcsType == 'tds' || tdsTcsType == 'tcs') {
      return baseVal - tdsTcsAmount;
    }
    return baseVal;
  }

  PurchaseOrderState copyWith({
    List<PurchaseOrderItem>? items,
    String? orderNumber,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    String? referenceNumber,
    String? vendorId,
    String? paymentTerms,
    String? shipmentPreference,
    String? deliveryType,
    String? deliveryWarehouseId,
    String? deliveryCustomerId,
    String? warehouseId,
    String? deliveryAddressName,
    bool clearDeliveryAddressName = false,
    double? discount,
    String? discountType,
    String? tdsTcsType,
    String? tdsTcsId,
    double? adjustment,
    String? notes,
    String? termsAndConditions,
    String? destinationOfSupply,
    String? discountLevel,
    String? discountAccountId,
    String? discountAccountName,
    bool? isReverseCharge,
    bool? isSaving,
    bool? isNumberingAuto,
    String? poPrefix,
    int? poNextNumber,
    int? poPadding,
    String? taxType,
    double? tdsTcsRate,
  }) {
    return PurchaseOrderState(
      items: items ?? this.items,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      vendorId: vendorId ?? this.vendorId,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      shipmentPreference: shipmentPreference ?? this.shipmentPreference,
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryWarehouseId: deliveryWarehouseId ?? this.deliveryWarehouseId,
      deliveryCustomerId: deliveryCustomerId ?? this.deliveryCustomerId,
      warehouseId: warehouseId ?? this.warehouseId,
      deliveryAddressName: clearDeliveryAddressName
          ? null
          : (deliveryAddressName ?? this.deliveryAddressName),
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      tdsTcsType: tdsTcsType ?? this.tdsTcsType,
      tdsTcsId: tdsTcsId ?? this.tdsTcsId,
      adjustment: adjustment ?? this.adjustment,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      destinationOfSupply: destinationOfSupply ?? this.destinationOfSupply,
      discountLevel: discountLevel ?? this.discountLevel,
      discountAccountId: discountAccountId ?? this.discountAccountId,
      discountAccountName: discountAccountName ?? this.discountAccountName,
      isReverseCharge: isReverseCharge ?? this.isReverseCharge,
      isSaving: isSaving ?? this.isSaving,
      isNumberingAuto: isNumberingAuto ?? this.isNumberingAuto,
      poPrefix: poPrefix ?? this.poPrefix,
      poNextNumber: poNextNumber ?? this.poNextNumber,
      poPadding: poPadding ?? this.poPadding,
      taxType: taxType ?? this.taxType,
      tdsTcsRate: tdsTcsRate ?? this.tdsTcsRate,
    );
  }
}

class PurchaseOrderNotifier extends StateNotifier<PurchaseOrderState> {
  final Ref _ref;

  PurchaseOrderNotifier(this._ref, {required bool isAuthenticated})
      : super(PurchaseOrderState(orderDate: DateTime.now())) {
    addItemRow();
    if (isAuthenticated) {
      _loadSettings();
      _listenToVendors();
    }
  }

  void _listenToVendors() {
    _ref.listen<VendorState>(vendorProvider, (previous, next) {
      if (state.vendorId != null &&
          state.vendorId!.isNotEmpty &&
          state.destinationOfSupply.isEmpty) {
        final vendor = next.vendors.firstWhere(
          (v) => v.id == state.vendorId,
          orElse: () => Vendor(id: '', displayName: ''),
        );
        if (vendor.id.isNotEmpty &&
            vendor.sourceOfSupply != null &&
            vendor.sourceOfSupply!.isNotEmpty) {
          updateField(destinationOfSupply: vendor.sourceOfSupply);
        }
      }
    });
  }

  Future<void> _loadSettings() async {
    final repository = _ref.read(purchaseOrderRepositoryProvider);
    final settings = await repository.getPurchaseOrderSettings();
    state = state.copyWith(
      isNumberingAuto: settings['isAuto'] as bool? ?? true,
      poPrefix: settings['prefix'] as String? ?? 'PO-',
      poNextNumber: settings['next_number'] ?? settings['nextNumber'] ?? 1,
      poPadding: settings['padding'] as int? ?? 5,
    );
    if (state.orderNumber.isEmpty && state.isNumberingAuto) {
      final next = await repository.getNextPurchaseOrderNumber();
      state = state.copyWith(orderNumber: next['formatted'] as String? ?? '');
    }
  }

  Future<void> saveSettings({
    required bool isAuto,
    required String prefix,
    required int nextNumber,
    int padding = 5,
  }) async {
    final repository = _ref.read(purchaseOrderRepositoryProvider);
    await repository.updatePurchaseOrderSettings({
      'isAuto': isAuto,
      'prefix': prefix,
      'nextNumber': nextNumber,
      'padding': padding,
    });

    state = state.copyWith(
      isNumberingAuto: isAuto,
      poPrefix: prefix,
      poNextNumber: nextNumber,
      poPadding: padding,
    );

    if (isAuto) {
      final next = await repository.getNextPurchaseOrderNumber();
      state = state.copyWith(orderNumber: next['formatted'] as String? ?? '');
    } else {
      state = state.copyWith(orderNumber: '');
    }
  }

  void reset() {
    state = PurchaseOrderState(orderDate: DateTime.now());
    addItemRow();
    _loadSettings();
  }

  void hydrate(PurchaseOrder order) {
    String destinationOfSupply = '';
    try {
      final vendorsState = _ref.read(vendorProvider);
      final vendor = vendorsState.vendors.firstWhere(
        (v) => v.id == order.vendorId,
        orElse: () => Vendor(id: '', displayName: ''),
      );
      if (vendor.id.isNotEmpty && vendor.sourceOfSupply != null) {
        destinationOfSupply = vendor.sourceOfSupply!;
      }
    } catch (_) {}

    state = PurchaseOrderState(
      items: order.items,
      orderNumber: order.orderNumber,
      orderDate: order.orderDate,
      expectedDeliveryDate: order.expectedDeliveryDate,
      referenceNumber: order.referenceNumber,
      vendorId: order.vendorId,
      paymentTerms: order.paymentTerms,
      shipmentPreference: order.shipmentPreference,
      deliveryType: order.deliveryType,
      deliveryWarehouseId: order.deliveryWarehouseId,
      deliveryCustomerId: order.deliveryCustomerId,
      warehouseId: order.warehouseId,
      discount: order.discount,
      discountType: order.discountType,
      tdsTcsType: order.tdsTcsType,
      tdsTcsId: order.tdsTcsId,
      adjustment: order.adjustment,
      notes: order.notes,
      termsAndConditions: order.termsAndConditions,
      destinationOfSupply: destinationOfSupply,
      discountLevel: order.discountLevel,
      discountAccountId: order.discountAccountId,
      discountAccountName: order.discountAccountName,
      isReverseCharge: order.isReverseCharge,
      isNumberingAuto: false,
      taxType: order.taxType,
    );
  }

  void addItemRow({int? index, PurchaseOrderItem? item}) {
    final List<PurchaseOrderItem> newItems = List.from(state.items);

    String? defaultWarehouseId = state.warehouseId;
    String? defaultWarehouseName;
    if (defaultWarehouseId != null && defaultWarehouseId.isNotEmpty) {
      try {
        final warehouses = _ref.read(warehousesProvider).value ?? [];
        final wh = warehouses.firstWhere((w) => w.id == defaultWarehouseId);
        defaultWarehouseName = wh.name;
      } catch (_) {}
    }

    final newItem = item ??
        PurchaseOrderItem(
          productId: '',
          quantity: 0.0,
          rate: 0.0,
          amount: 0.0,
          warehouseId: defaultWarehouseId,
          warehouseName: defaultWarehouseName,
        );
    if (index != null && index >= 0 && index <= newItems.length) {
      newItems.insert(index, newItem);
    } else {
      newItems.add(newItem);
    }
    state = state.copyWith(items: _recalculateAllItems(newItems));
  }

  void addHeaderRow({int? index}) {
    final newItems = List<PurchaseOrderItem>.from(state.items);
    final headerItem = PurchaseOrderItem(
      productId: '__header__',
      quantity: 0,
      rate: 0,
      amount: 0,
      isHeader: true,
      headerText: '',
    );
    if (index != null && index >= 0 && index <= newItems.length) {
      newItems.insert(index, headerItem);
    } else {
      newItems.add(headerItem);
    }
    state = state.copyWith(items: newItems);
  }

  void updateHeaderText(int index, String text) {
    final newItems = List<PurchaseOrderItem>.from(state.items);
    newItems[index] = newItems[index].copyWith(headerText: text);
    state = state.copyWith(items: newItems);
  }

  void removeItemRow(int index) {
    if (state.items.length <= 1) {
      clearItemRow(index);
      return;
    }
    final newItems = List<PurchaseOrderItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: _recalculateAllItems(newItems));
  }

  void clearItemRow(int index) {
    final newItems = List<PurchaseOrderItem>.from(state.items);
    newItems[index] = PurchaseOrderItem(
      productId: '',
      quantity: 0.0,
      rate: 0.0,
      amount: 0.0,
      discount: 0.0,
      description: '',
    );
    state = state.copyWith(items: _recalculateAllItems(newItems));
  }

  void reorderItems(int oldIndex, int newIndex) {
    final newItems = List<PurchaseOrderItem>.from(state.items);
    final item = newItems.removeAt(oldIndex);
    newItems.insert(newIndex, item);
    state = state.copyWith(items: newItems);
  }

  void updateItem(int index, PurchaseOrderItem item) {
    final newItems = List<PurchaseOrderItem>.from(state.items);
    newItems[index] = item;
    state = state.copyWith(items: _recalculateAllItems(newItems));
  }

  Future<void> updateItemWarehouse(
      int index, String warehouseId, String warehouseName) async {
    final item = state.items[index];
    if (item.productId.isEmpty) {
      final updated = item.copyWith(
        warehouseId: warehouseId,
        warehouseName: warehouseName,
      );
      updateItem(index, updated);
      return;
    }

    double? availableStock;
    double? stockOnHand;
    try {
      final stockArg = (productId: item.productId, warehouseId: warehouseId);
      final stock = await _ref.read(
        productStockInWarehouseProvider(stockArg).future,
      );
      availableStock = stock?.availableQuantity;
      stockOnHand = stock?.quantityOnHand;
    } catch (_) {}

    final updated = item.copyWith(
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      availableStock: availableStock,
      stockOnHand: stockOnHand,
    );
    updateItem(index, updated);
  }

  Future<void> selectProductForItem(
    int index,
    Item product,
    String warehouseId, {
    String? priceListId,
  }) async {
    final newItems = List<PurchaseOrderItem>.from(state.items);

    // Fetch stock
    double? availableStock;
    double? stockOnHand;
    try {
      final stockArg = (productId: product.id ?? '', warehouseId: warehouseId);
      final stock = await _ref.read(
        productStockInWarehouseProvider(stockArg).future,
      );
      availableStock = stock?.availableQuantity;
      stockOnHand = stock?.quantityOnHand;
    } catch (e) {
      // ignore
    }

    // Determine initial rate and price list
    double initialRate = product.costPrice ?? 0.0;
    String? selectedPriceListId = priceListId;
    double initialDiscount = 0.0;

    try {
      final activePriceLists = _ref.read(activePriceListsProvider);
      
      PriceList? targetPriceList;
      if (priceListId != null) {
        targetPriceList = activePriceLists.firstWhere(
          (pl) => pl.id == priceListId,
          orElse: () => PriceList.dummy(),
        );
      }

      final listsToSearch = targetPriceList != null && targetPriceList.id != 'dummy-id'
          ? [targetPriceList]
          : const <PriceList>[];

      for (final pl in listsToSearch) {
        // Check if this price list has a specific rate for this item
        if (pl.priceListType == 'individual_items') {
          final override = pl.itemRates?.firstWhere(
            (r) => r.itemId == product.id,
            orElse: () => const PriceListItemRate(itemId: ''),
          );
          if (override != null && override.itemId.isNotEmpty) {
            initialRate = pl.calculatePrice(
              product.id ?? '',
              product.costPrice ?? 0.0,
            );
            selectedPriceListId = pl.id;
            if (override.discountPercentage != null) {
              initialDiscount = override.discountPercentage!;
            }
            break;
          }
        } else if (pl.priceListType == 'all_items') {
          initialRate = pl.calculatePrice(
            product.id ?? '',
            product.costPrice ?? 0.0,
          );
          selectedPriceListId = pl.id;
          break;
        }
      }
    } catch (e) {
      // ignore
    }

    // Fetch tax info
    bool isUnregistered = false;
    bool isInterstate = false;
    if (state.vendorId != null && state.vendorId!.isNotEmpty) {
      try {
        final vendorsState = _ref.read(vendorProvider);
        final selectedVendor = vendorsState.vendors.firstWhere(
          (v) => v.id == state.vendorId,
          orElse: () => Vendor(id: '', displayName: ''),
        );
        isUnregistered = selectedVendor.id.isNotEmpty &&
            (selectedVendor.gstTreatment == null ||
                selectedVendor.gstTreatment!
                    .toLowerCase()
                    .contains('unregistered') ||
                selectedVendor.gstTreatment! == 'Unregistered Business');
        if (selectedVendor.id.isNotEmpty &&
            selectedVendor.sourceOfSupply != null &&
            selectedVendor.sourceOfSupply!.isNotEmpty &&
            state.destinationOfSupply.isNotEmpty) {
          isInterstate = selectedVendor.sourceOfSupply!.toLowerCase().trim() !=
              state.destinationOfSupply.toLowerCase().trim();
        }
      } catch (_) {}
    }

    final resolvedTax = isUnregistered
        ? null
        : _resolvePurchaseTax(product, isInterstate: isInterstate);
    final String? taxName = isUnregistered
        ? null
        : (resolvedTax?.taxName ??
            (isInterstate
                ? product.interStateTaxName
                : product.intraStateTaxName));
    final double taxRate = isUnregistered ? 0.0 : (resolvedTax?.taxRate ?? 0.0);

    // Find account name
    String? accountName;
    if (product.purchaseAccountId != null) {
      try {
        final accountsState = _ref.read(chartOfAccountsProvider);
        List<AccountNode> allAccounts = [];
        void collect(List<AccountNode> nodes) {
          for (final n in nodes) {
            allAccounts.add(n);
            collect(n.children);
          }
        }

        collect(accountsState.roots);
        final account = allAccounts.firstWhere(
          (a) => a.id == product.purchaseAccountId,
        );
        accountName = account.name;
      } catch (e) {
        accountName = product.purchaseAccountId;
      }
    }

    String? warehouseName;
    try {
      final warehouses = _ref.read(warehousesProvider).value ?? [];
      final wh = warehouses.firstWhere((w) => w.id == warehouseId);
      warehouseName = wh.name;
    } catch (_) {}

    newItems[index] = PurchaseOrderItem(
      productId: product.id ?? '',
      productName: product.productName,
      description: product.purchaseDescription,
      itemCode: product.itemCode,
      hsnCode: product.hsnCode,
      accountId: product.purchaseAccountId,
      accountName: accountName,
      quantity: 0.0,
      rate: initialRate,
      discount: initialDiscount,
      discountType: 'percentage',
      amount: 0.0,
      taxId: isUnregistered
          ? null
          : (isInterstate ? product.interStateTaxId : product.intraStateTaxId),
      taxName: taxName,
      taxRate: taxRate,
      taxAmount: 0.0,
      productType: product.type,
      availableStock: availableStock,
      stockOnHand: stockOnHand,
      priceListId: selectedPriceListId,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
    );

    state = state.copyWith(items: _recalculateAllItems(newItems));

    if (index == newItems.length - 1) {
      addItemRow();
    }
  }

  Future<void> _refreshItemsStock(String defaultWarehouseId) async {
    final updatedItems = await Future.wait(
      state.items.map((item) async {
        if (item.productId.isEmpty) return item;
        final itemWh = item.warehouseId ?? defaultWarehouseId;
        try {
          final stockArg = (
            productId: item.productId,
            warehouseId: itemWh,
          );
          final stock = await _ref.read(
            productStockInWarehouseProvider(stockArg).future,
          );
          return item.copyWith(
            availableStock: stock?.availableQuantity,
            stockOnHand: stock?.quantityOnHand,
          );
        } catch (e) {
          return item;
        }
      }),
    );
    state = state.copyWith(items: updatedItems);
  }

  PurchaseOrderItem _recalculateItem(PurchaseOrderItem item, String level, {double? currentSubTotal}) {
    bool isUnregistered = false;
    if (state.vendorId != null && state.vendorId!.isNotEmpty) {
      try {
        final vendorsState = _ref.read(vendorProvider);
        final selectedVendor = vendorsState.vendors.firstWhere(
          (v) => v.id == state.vendorId,
          orElse: () => Vendor(id: '', displayName: ''),
        );
        isUnregistered = selectedVendor.id.isNotEmpty &&
            (selectedVendor.gstTreatment == null ||
                selectedVendor.gstTreatment!
                    .toLowerCase()
                    .contains('unregistered') ||
                selectedVendor.gstTreatment! == 'Unregistered Business');
      } catch (_) {}
    }

    double base = item.quantity * item.rate;
    double itemDiscount = 0.0;

    if (level == 'item') {
      if (item.discountType == 'percentage') {
        itemDiscount = base * (item.discount / 100);
      } else {
        itemDiscount = item.discount;
      }
    } else {
      // level == 'transaction'
      // 1. Pricelist discount is ignored when discount level is transaction
      double itemPricelistDiscount = 0.0;
      // 2. Global transaction discount apportioned
      double itemManualDiscount = 0.0;
      if (state.discount > 0) {
        final double effectiveSubTotal = currentSubTotal ?? state.subTotal;
        if (state.discountType == 'percentage') {
          itemManualDiscount = base * (state.discount / 100);
        } else {
          if (effectiveSubTotal > 0) {
            itemManualDiscount = state.discount * base / effectiveSubTotal;
          }
        }
      }
      itemDiscount = itemPricelistDiscount + itemManualDiscount;
    }

    double net = base - itemDiscount;

    final double activeTaxRate = isUnregistered ? 0.0 : item.taxRate;
    double taxAmount = state.taxType == 'inclusive'
        ? net * activeTaxRate / (100 + activeTaxRate)
        : net * (activeTaxRate / 100);

    double amountValue = level == 'item' ? net : base;

    return item.copyWith(
      amount: amountValue,
      taxAmount: taxAmount,
      taxRate: activeTaxRate,
      taxId: isUnregistered ? null : item.taxId,
      taxName: isUnregistered ? null : item.taxName,
    );
  }

  List<PurchaseOrderItem> _recalculateAllItems(List<PurchaseOrderItem> itemsList, {String? customLevel}) {
    final level = customLevel ?? state.discountLevel;
    final tempSubTotal = itemsList
        .where((i) => !i.isHeader)
        .fold(0.0, (sum, item) => sum + (item.quantity * item.rate));

    return itemsList.map((item) {
      if (item.productId.isEmpty || item.isHeader) return item;
      return _recalculateItem(item, level, currentSubTotal: tempSubTotal);
    }).toList();
  }

  void updateField({
    String? orderNumber,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    String? referenceNumber,
    String? vendorId,
    String? paymentTerms,
    String? shipmentPreference,
    String? deliveryType,
    String? deliveryWarehouseId,
    String? deliveryCustomerId,
    String? warehouseId,
    String? deliveryAddressName,
    bool clearDeliveryAddressName = false,
    double? discount,
    String? discountType,
    String? tdsTcsType,
    String? tdsTcsId,
    double? adjustment,
    String? notes,
    String? termsAndConditions,
    String? destinationOfSupply,
    String? discountLevel,
    String? discountAccountId,
    String? discountAccountName,
    bool? isReverseCharge,
    bool? isSaving,
    bool? isNumberingAuto,
    String? poPrefix,
    int? poNextNumber,
    int? poPadding,
    String? taxType,
    double? tdsTcsRate,
    bool forceRecalculateTaxes = false,
  }) {
    final oldLevel = state.discountLevel;
    final oldWarehouse = state.warehouseId;
    final oldTaxType = state.taxType;
    final oldVendorId = state.vendorId;
    final oldDestinationOfSupply = state.destinationOfSupply;
    final oldDiscount = state.discount;
    final oldDiscountType = state.discountType;

    state = state.copyWith(
      orderNumber: orderNumber,
      orderDate: orderDate,
      expectedDeliveryDate: expectedDeliveryDate,
      referenceNumber: referenceNumber,
      vendorId: vendorId,
      paymentTerms: paymentTerms,
      shipmentPreference: shipmentPreference,
      deliveryType: deliveryType,
      deliveryWarehouseId: deliveryWarehouseId,
      deliveryCustomerId: deliveryCustomerId,
      warehouseId: warehouseId,
      deliveryAddressName: deliveryAddressName,
      clearDeliveryAddressName: clearDeliveryAddressName,
      discount: discount,
      discountType: discountType,
      tdsTcsType: tdsTcsType,
      tdsTcsId: tdsTcsId,
      adjustment: adjustment,
      notes: notes,
      termsAndConditions: termsAndConditions,
      destinationOfSupply: destinationOfSupply,
      discountLevel: discountLevel,
      discountAccountId: discountAccountId,
      discountAccountName: discountAccountName,
      isReverseCharge: isReverseCharge,
      isSaving: isSaving,
      isNumberingAuto: isNumberingAuto,
      poPrefix: poPrefix,
      poNextNumber: poNextNumber,
      poPadding: poPadding,
      taxType: taxType,
      tdsTcsRate: tdsTcsRate,
    );

    if (forceRecalculateTaxes ||
        (discountLevel != null && discountLevel != oldLevel) ||
        (taxType != null && taxType != oldTaxType) ||
        (vendorId != null && vendorId != oldVendorId) ||
        (discount != null && discount != oldDiscount) ||
        (discountType != null && discountType != oldDiscountType) ||
        (destinationOfSupply != null &&
            destinationOfSupply != oldDestinationOfSupply)) {
      final itemsState = _ref.read(itemsControllerProvider);
      final newItems = state.items.map((i) {
        if (i.productId.isEmpty || i.isHeader) return i;

        Item? product;
        try {
          product = itemsState.items.firstWhere((p) => p.id == i.productId);
        } catch (_) {}
        if (product == null) {
          return i;
        }

        bool isUnregistered = false;
        bool isInterstate = false;
        if (state.vendorId != null && state.vendorId!.isNotEmpty) {
          try {
            final vendorsState = _ref.read(vendorProvider);
            final selectedVendor = vendorsState.vendors.firstWhere(
              (v) => v.id == state.vendorId,
              orElse: () => Vendor(id: '', displayName: ''),
            );
            isUnregistered = selectedVendor.id.isNotEmpty &&
                (selectedVendor.gstTreatment == null ||
                    selectedVendor.gstTreatment!
                        .toLowerCase()
                        .contains('unregistered') ||
                    selectedVendor.gstTreatment! == 'Unregistered Business');
            if (selectedVendor.id.isNotEmpty &&
                selectedVendor.sourceOfSupply != null &&
                selectedVendor.sourceOfSupply!.isNotEmpty &&
                state.destinationOfSupply.isNotEmpty) {
              isInterstate =
                  selectedVendor.sourceOfSupply!.toLowerCase().trim() !=
                      state.destinationOfSupply.toLowerCase().trim();
            }
          } catch (_) {}
        }

        final resolvedTax = isUnregistered
            ? null
            : _resolvePurchaseTax(product, isInterstate: isInterstate);
        final String? taxName = isUnregistered
            ? null
            : (resolvedTax?.taxName ??
                (isInterstate
                    ? product.interStateTaxName
                    : product.intraStateTaxName));
        final double taxRate =
            isUnregistered ? 0.0 : (resolvedTax?.taxRate ?? 0.0);

        return i.copyWith(
          taxId: isUnregistered
              ? null
              : (isInterstate
                  ? product.interStateTaxId
                  : product.intraStateTaxId),
          taxName: taxName,
          taxRate: taxRate,
        );
      }).toList();
      state = state.copyWith(items: _recalculateAllItems(newItems));
    }

    if (warehouseId != null && warehouseId != oldWarehouse) {
      String? defaultWarehouseName;
      try {
        final warehouses = _ref.read(warehousesProvider).value ?? [];
        final wh = warehouses.firstWhere((w) => w.id == warehouseId);
        defaultWarehouseName = wh.name;
      } catch (_) {}

      final newItems = state.items.map((item) {
        if (item.warehouseId == null ||
            item.warehouseId == oldWarehouse ||
            item.warehouseId!.isEmpty) {
          return item.copyWith(
            warehouseId: warehouseId,
            warehouseName: defaultWarehouseName,
          );
        }
        return item;
      }).toList();
      state = state.copyWith(items: _recalculateAllItems(newItems));

      _refreshItemsStock(warehouseId);
    }
  }

  void addItemsInBulk(List<PurchaseOrderItem> newItemsList) {
    final combinedItems = [
      ...state.items.where((i) => i.productId.isNotEmpty),
      ...newItemsList,
    ];
    state = state.copyWith(items: _recalculateAllItems(combinedItems));
    if (state.items.isEmpty) addItemRow();
  }

  TaxRate? _resolvePurchaseTax(Item product, {bool? isInterstate}) {
    bool activeInterstate = isInterstate ?? false;
    if (isInterstate == null) {
      if (state.vendorId != null && state.vendorId!.isNotEmpty) {
        try {
          final vendorsState = _ref.read(vendorProvider);
          final selectedVendor = vendorsState.vendors.firstWhere(
            (v) => v.id == state.vendorId,
            orElse: () => Vendor(id: '', displayName: ''),
          );
          if (selectedVendor.id.isNotEmpty &&
              selectedVendor.sourceOfSupply != null &&
              selectedVendor.sourceOfSupply!.isNotEmpty &&
              state.destinationOfSupply.isNotEmpty) {
            activeInterstate =
                selectedVendor.sourceOfSupply!.toLowerCase().trim() !=
                    state.destinationOfSupply.toLowerCase().trim();
          }
        } catch (_) {}
      }
    }

    final taxId =
        activeInterstate ? product.interStateTaxId : product.intraStateTaxId;
    if (taxId == null || taxId.isEmpty) {
      return null;
    }

    final itemsState = _ref.read(itemsControllerProvider);

    for (final tax in itemsState.taxGroups) {
      if (tax.id == taxId) {
        return tax;
      }
    }

    for (final tax in itemsState.taxRates) {
      if (tax.id == taxId) {
        return tax;
      }
    }

    return null;
  }
}

final purchaseOrderFormNotifierProvider =
    StateNotifierProvider<PurchaseOrderNotifier, PurchaseOrderState>((ref) {
  return PurchaseOrderNotifier(
    ref,
    isAuthenticated: ref.watch(isAuthenticatedProvider),
  );
});
