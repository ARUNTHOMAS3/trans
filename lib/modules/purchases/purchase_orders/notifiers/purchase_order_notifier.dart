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
  final String? warehouseId;
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
    this.tdsTcsType = 'none',
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
    if (discountLevel == 'item') return 0.0;
    if (discountType == 'percentage') {
      return subTotal * (discount / 100);
    }
    return discount;
  }

  double get taxAmount {
    if (isReverseCharge) return 0.0;
    return items
        .where((i) => !i.isHeader)
        .fold(0.0, (sum, item) => sum + item.taxAmount);
  }

  double get tdsTcsAmount => (subTotal - discountValue) * (tdsTcsRate / 100);

  double get total {
    final base = taxType == 'inclusive'
        ? subTotal - discountValue + adjustment
        : subTotal - discountValue + taxAmount + adjustment;
    if (tdsTcsType == 'tds' || tdsTcsType == 'tcs') {
      return base - tdsTcsAmount;
    }
    return base;
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

  void hydrate(PurchaseOrder order, {bool isClone = false}) {
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

    final List<PurchaseOrderItem> hydratedItems = isClone
        ? order.items
            .map((item) => PurchaseOrderItem(
                  productId: item.productId,
                  productName: item.productName,
                  hsnCode: item.hsnCode,
                  itemCode: item.itemCode,
                  description: item.description,
                  accountId: item.accountId,
                  accountName: item.accountName,
                  discountAccountId: item.discountAccountId,
                  discountAccountName: item.discountAccountName,
                  quantity: item.quantity,
                  cancelledQuantity: 0.0,
                  rate: item.rate,
                  taxId: item.taxId,
                  taxName: item.taxName,
                  taxRate: item.taxRate,
                  taxAmount: item.taxAmount,
                  discount: item.discount,
                  discountType: item.discountType,
                  amount: item.amount,
                  productType: item.productType,
                  availableStock: item.availableStock,
                  stockOnHand: item.stockOnHand,
                  priceListId: item.priceListId,
                  pricelist: item.pricelist,
                  warehouseId: item.warehouseId,
                  warehouseName: item.warehouseName,
                  isHeader: item.isHeader,
                  headerText: item.headerText,
                ))
            .toList()
        : order.items;

    state = PurchaseOrderState(
      items: hydratedItems,
      orderNumber: isClone ? '' : order.orderNumber,
      orderDate: isClone ? DateTime.now() : order.orderDate,
      expectedDeliveryDate: isClone ? null : order.expectedDeliveryDate,
      referenceNumber: isClone ? null : order.referenceNumber,
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
      isNumberingAuto: isClone ? state.isNumberingAuto : false,
      taxType: order.taxType,
    );

    if (isClone) {
      _loadSettings();
    }
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
    state = state.copyWith(items: newItems);
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
    state = state.copyWith(items: newItems);
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
    state = state.copyWith(items: newItems);
  }

  void reorderItems(int oldIndex, int newIndex) {
    final newItems = List<PurchaseOrderItem>.from(state.items);
    final item = newItems.removeAt(oldIndex);
    newItems.insert(newIndex, item);
    state = state.copyWith(items: newItems);
  }

  void updateItem(int index, PurchaseOrderItem item) {
    final newItems = List<PurchaseOrderItem>.from(state.items);
    newItems[index] = _recalculateItem(item, state.discountLevel);
    state = state.copyWith(items: newItems);
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
    String warehouseId,
  ) async {
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
    String? selectedPriceListId;

    // Fetch tax info
    bool isInterstate = false;
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
          final srcKL = selectedVendor.sourceOfSupply!.toLowerCase().contains('kerala');
          final destKL = state.destinationOfSupply.toLowerCase().contains('kerala');
          isInterstate = !srcKL && !destKL;
        }
      } catch (_) {}
    }

    final resolvedTax = _resolvePurchaseTax(product, isInterstate: isInterstate);
    final String? taxName = resolvedTax?.taxName ??
        (isInterstate
            ? product.interStateTaxName
            : product.intraStateTaxName);
    final double taxRate = resolvedTax?.taxRate ?? 0.0;

    // Find account name
    String? accountName;
    if (product.inventoryAccountId != null) {
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
          (a) => a.id == product.inventoryAccountId,
        );
        accountName = account.name;
      } catch (e) {
        accountName = product.inventoryAccountId;
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
      accountId: product.inventoryAccountId,
      accountName: accountName,
      quantity: 0.0,
      rate: initialRate,
      amount: 0.0,
      taxId: isInterstate ? product.interStateTaxId : product.intraStateTaxId,
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

    state = state.copyWith(items: newItems);

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

  PurchaseOrderItem _recalculateItem(PurchaseOrderItem item, String level) {
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
    double net = base;
    if (level == 'item') {
      if (item.discountType == 'percentage') {
        net = base - (base * (item.discount / 100));
      } else {
        net = base - item.discount;
      }
    }

    final double activeTaxRate = isUnregistered ? 0.0 : item.taxRate;
    double taxAmount = state.isReverseCharge
        ? 0.0
        : (state.taxType == 'inclusive'
            ? net * activeTaxRate / (100 + activeTaxRate)
            : net * (activeTaxRate / 100));

    double amountValue = net;

    return item.copyWith(
      amount: amountValue,
      taxAmount: taxAmount,
      taxRate: activeTaxRate,
      taxId: isUnregistered ? null : item.taxId,
      taxName: isUnregistered ? null : item.taxName,
    );
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
    final oldIsReverseCharge = state.isReverseCharge;
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
        (isReverseCharge != null && isReverseCharge != oldIsReverseCharge) ||
        (discountLevel != null && discountLevel != oldLevel) ||
        (taxType != null && taxType != oldTaxType) ||
        (vendorId != null && vendorId != oldVendorId) ||
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
          return _recalculateItem(i, state.discountLevel);
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
              final srcKL = selectedVendor.sourceOfSupply!.toLowerCase().contains('kerala');
              final destKL = state.destinationOfSupply.toLowerCase().contains('kerala');
              isInterstate = !srcKL && !destKL;
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

        final updatedItem = i.copyWith(
          taxId: isUnregistered
              ? null
              : (isInterstate
                  ? product.interStateTaxId
                  : product.intraStateTaxId),
          taxName: taxName,
          taxRate: taxRate,
        );
        return _recalculateItem(updatedItem, state.discountLevel);
      }).toList();
      state = state.copyWith(items: newItems);
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
      state = state.copyWith(items: newItems);

      _refreshItemsStock(warehouseId);
    }
  }

  /// Adds [newItems] to the item table.
  ///
  /// By default a product already on the order is updated in place rather than
  /// duplicated — right when picking from an item catalogue. Pass
  /// [mergeByProduct] false when each incoming line is its own document line
  /// (purchase request lines, where the same product can legitimately arrive
  /// from two different requests and must stay two rows).
  void addItemsInBulk(
    List<PurchaseOrderItem> newItems, {
    bool mergeByProduct = true,
  }) {
    final List<PurchaseOrderItem> resolvedItems = [];
    final itemsState = _ref.read(itemsControllerProvider);
    final accountsState = _ref.read(chartOfAccountsProvider);

    List<AccountNode> allAccounts = [];
    void collect(List<AccountNode> nodes) {
      for (final n in nodes) {
        allAccounts.add(n);
        collect(n.children);
      }
    }
    collect(accountsState.roots);

    for (var item in newItems) {
      if (item.productId.isEmpty) {
        resolvedItems.add(item);
        continue;
      }

      Item? product;
      try {
        product = itemsState.items.firstWhere((p) => p.id == item.productId);
      } catch (_) {}

      String? accountId = item.accountId;
      String? accountName = item.accountName;
      if ((accountId == null || accountId.isEmpty) && product != null) {
        accountId = product.inventoryAccountId;
        if (accountId != null && accountId.isNotEmpty) {
          try {
            final acc = allAccounts.firstWhere((a) => a.id == accountId);
            accountName = acc.name;
          } catch (_) {
            accountName = accountId;
          }
        }
      }

      String? taxId = item.taxId;
      String? taxName = item.taxName;
      double taxRate = item.taxRate;
      if ((taxId == null || taxId.isEmpty) && product != null) {
        bool isInterstate = false;
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
              final srcKL = selectedVendor.sourceOfSupply!.toLowerCase().contains('kerala');
              final destKL = state.destinationOfSupply.toLowerCase().contains('kerala');
              isInterstate = !srcKL && !destKL;
            }
          } catch (_) {}
        }

        final resolvedTax = _resolvePurchaseTax(product, isInterstate: isInterstate);
        taxId = isInterstate ? product.interStateTaxId : product.intraStateTaxId;
        taxName = resolvedTax?.taxName ?? (isInterstate ? product.interStateTaxName : product.intraStateTaxName);
        taxRate = resolvedTax?.taxRate ?? 0.0;
      }

      resolvedItems.add(
        item.copyWith(
          accountId: accountId,
          accountName: accountName,
          taxId: taxId,
          taxName: taxName,
          taxRate: taxRate,
        ),
      );
    }

    final recalculatedNewItems = resolvedItems
        .map((i) => _recalculateItem(i, state.discountLevel))
        .toList();

    final List<PurchaseOrderItem> currentItems = state.items
        .where((i) => i.productId.isNotEmpty)
        .toList();

    for (final newItem in recalculatedNewItems) {
      final existingIndex = mergeByProduct
          ? currentItems.indexWhere((i) => i.productId == newItem.productId)
          : -1;
      if (existingIndex != -1) {
        final existingItem = currentItems[existingIndex];
        currentItems[existingIndex] = _recalculateItem(
          existingItem.copyWith(
            quantity: newItem.quantity,
            rate: newItem.rate,
            amount: newItem.rate * newItem.quantity,
            priceListId: newItem.priceListId,
            taxId: newItem.taxId,
            taxName: newItem.taxName,
            taxRate: newItem.taxRate,
            taxAmount: newItem.taxAmount,
            accountId: newItem.accountId,
            accountName: newItem.accountName,
          ),
          state.discountLevel,
        );
      } else {
        currentItems.add(newItem);
      }
    }

    state = state.copyWith(items: currentItems);
    if (state.items.isEmpty) addItemRow(); // ensure at least one
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
            final srcKL = selectedVendor.sourceOfSupply!.toLowerCase().contains('kerala');
            final destKL = state.destinationOfSupply.toLowerCase().contains('kerala');
            activeInterstate = !srcKL && !destKL;
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
