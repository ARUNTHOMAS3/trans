import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchases_purchase_orders_order_model.dart';
import '../providers/purchases_purchase_orders_provider.dart';
import '../../../items/items/models/item_model.dart';
import '../../../inventory/providers/stock_provider.dart';
import '../../../items/items/controllers/items_controller.dart';
import '../../../items/pricelist/models/pricelist_model.dart';
import '../../../items/pricelist/providers/pricelist_provider.dart';
import '../../../accountant/models/accountant_chart_of_accounts_account_model.dart';
import '../../../accountant/providers/accountant_chart_of_accounts_provider.dart';

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
  });

  double get subTotal =>
      items.where((i) => !i.isHeader).fold(0.0, (sum, item) => sum + item.amount);

  double get discountValue {
    if (discountLevel == 'item') return 0.0;
    if (discountType == 'percentage') {
      return subTotal * (discount / 100);
    }
    return discount;
  }

  double get taxAmount {
    return items.where((i) => !i.isHeader).fold(0.0, (sum, item) => sum + item.taxAmount);
  }

  double get total => subTotal - discountValue + taxAmount + adjustment;

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
    );
  }
}

class PurchaseOrderNotifier extends StateNotifier<PurchaseOrderState> {
  final Ref _ref;

  PurchaseOrderNotifier(this._ref)
    : super(PurchaseOrderState(orderDate: DateTime.now())) {
    // Add one empty row by default
    addItemRow();
    _loadSettings();
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
    if (state.isNumberingAuto) {
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

  void addItemRow({int? index, PurchaseOrderItem? item}) {
    final List<PurchaseOrderItem> newItems = List.from(state.items);
    final newItem = item ??
        PurchaseOrderItem(productId: '', quantity: 1.0, rate: 0.0, amount: 0.0);
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
    if (state.items.length <= 1) return; // Keep at least one
    final newItems = List<PurchaseOrderItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: newItems);
  }

  void updateItem(int index, PurchaseOrderItem item) {
    final newItems = List<PurchaseOrderItem>.from(state.items);
    newItems[index] = _recalculateItem(item, state.discountLevel);
    state = state.copyWith(items: newItems);
  }

  Future<void> selectProductForItem(int index, Item product, String warehouseId) async {
    final newItems = List<PurchaseOrderItem>.from(state.items);
    
    // Fetch stock
    double? availableStock;
    double? stockOnHand;
    try {
      final stockArg = (productId: product.id ?? '', warehouseId: warehouseId);
      final stock = await _ref.read(productStockInWarehouseProvider(stockArg).future);
      availableStock = stock?.availableQuantity;
      stockOnHand = stock?.quantityOnHand;
    } catch (e) {
      // ignore
    }

    // Determine initial rate and price list
    double initialRate = product.costPrice ?? 0.0;
    String? selectedPriceListId;

    try {
      final activePriceLists = _ref.read(activePriceListsProvider);
      final purchasePriceLists = activePriceLists.where((pl) => pl.transactionType == 'purchase' || pl.transactionType == 'Purchase');
      
      for (final pl in purchasePriceLists) {
        // Check if this price list has a specific rate for this item
        if (pl.priceListType == 'individual_items') {
          final override = pl.itemRates?.firstWhere((r) => r.itemId == product.id, orElse: () => const PriceListItemRate(itemId: ''));
          if (override != null && override.itemId.isNotEmpty) {
            initialRate = pl.calculatePrice(product.id ?? '', product.costPrice ?? 0.0);
            selectedPriceListId = pl.id;
            break; 
          }
        } else if (pl.priceListType == 'all_items') {
          // If it's all items, we might want to apply it, but usually individual ones are prioritized.
          // For now, let's just take the first one that modifies the price or is the first choice.
          initialRate = pl.calculatePrice(product.id ?? '', product.costPrice ?? 0.0);
          selectedPriceListId = pl.id;
          break;
        }
      }
    } catch (e) {
      // ignore
    }

    // Fetch tax info
    String? taxName;
    double taxRate = 0.0;
    if (product.intraStateTaxId != null) {
      try {
        final itemsController = _ref.read(itemsControllerProvider);
        final tax = itemsController.taxRates.firstWhere((t) => t.id == product.intraStateTaxId);
        taxName = tax.taxName;
        taxRate = tax.taxRate;
      } catch (e) {
        taxName = product.intraStateTaxId;
      }
    }

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
        final account = allAccounts.firstWhere((a) => a.id == product.purchaseAccountId);
        accountName = account.name;
      } catch (e) {
        accountName = product.purchaseAccountId;
      }
    }

    newItems[index] = PurchaseOrderItem(
      productId: product.id ?? '',
      productName: product.productName,
      description: product.purchaseDescription,
      itemCode: product.itemCode,
      hsnCode: product.hsnCode,
      accountId: product.purchaseAccountId,
      accountName: accountName,
      quantity: 1.0,
      rate: initialRate,
      amount: initialRate,
      taxId: product.intraStateTaxId,
      taxName: taxName,
      taxRate: taxRate,
      taxAmount: initialRate * (taxRate / 100),
      productType: product.type,
      availableStock: availableStock,
      stockOnHand: stockOnHand,
      priceListId: selectedPriceListId,
    );

    state = state.copyWith(items: newItems);
  }

  Future<void> _refreshItemsStock(String warehouseId) async {
    final updatedItems = await Future.wait(state.items.map((item) async {
      if (item.productId.isEmpty) return item;
      try {
        final stockArg = (productId: item.productId, warehouseId: warehouseId);
        final stock = await _ref.read(productStockInWarehouseProvider(stockArg).future);
        return item.copyWith(
          availableStock: stock?.availableQuantity,
          stockOnHand: stock?.quantityOnHand,
        );
      } catch (e) {
        return item;
      }
    }));
    state = state.copyWith(items: updatedItems);
  }

  PurchaseOrderItem _recalculateItem(PurchaseOrderItem item, String level) {
    double base = item.quantity * item.rate;
    double net = base;
    if (level == 'item') {
      if (item.discountType == 'percentage') {
        net = base - (base * (item.discount / 100));
      } else {
        net = base - item.discount;
      }
    }
    double taxAmount = net * (item.taxRate / 100);
    return item.copyWith(amount: net, taxAmount: taxAmount);
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
  }) {
    final oldLevel = state.discountLevel;
    final oldWarehouse = state.warehouseId;
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
    );

    if (discountLevel != null && discountLevel != oldLevel) {
      final newItems =
          state.items.map((i) => _recalculateItem(i, discountLevel)).toList();
      state = state.copyWith(items: newItems);
    }

    if (warehouseId != null && warehouseId != oldWarehouse) {
      _refreshItemsStock(warehouseId);
    }
  }

  void addItemsInBulk(List<PurchaseOrderItem> newItems) {
    state = state.copyWith(
      items: [
        ...state.items.where((i) => i.productId.isNotEmpty), // keep filled ones
        ...newItems,
      ],
    );
    if (state.items.isEmpty) addItemRow(); // ensure at least one
  }
}

final purchaseOrderFormNotifierProvider =
    StateNotifierProvider<PurchaseOrderNotifier, PurchaseOrderState>((ref) {
      return PurchaseOrderNotifier(ref);
    });
