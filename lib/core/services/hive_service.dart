// FILE: lib/shared/services/hive_service.dart
// Centralized Hive service for offline data caching (PRD Section 12.2)

import 'package:hive_flutter/hive_flutter.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_payment_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_eway_bill_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_model.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_model.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_transfer_model.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  // Box getters - Boxes are typed as per initialization in main.dart
  Box<Item> get productsBox => Hive.box<Item>('products');
  Box<SalesCustomer> get customersBox => Hive.box<SalesCustomer>('customers');
  Box<SalesOrder> get posDraftsBox => Hive.box<SalesOrder>('pos_drafts');
  Box<SalesOrder> get salesOrdersBox => Hive.box<SalesOrder>('sales_orders');
  Box<SalesPayment> get paymentsBox => Hive.box<SalesPayment>('payments');
  Box<SalesEWayBill> get ewayBillsBox => Hive.box<SalesEWayBill>('eway_bills');
  Box<Vendor> get vendorsBox => Hive.box<Vendor>('vendors');
  Box<PurchaseOrder> get purchaseOrdersBox => Hive.box<PurchaseOrder>('purchase_orders');
  Box<PurchasesBill> get billsBox => Hive.box<PurchasesBill>('bills');
  Box<Stock> get stockBox => Hive.box<Stock>('stock');
  Box<InventoryAdjustment> get adjustmentsBox =>
      Hive.box<InventoryAdjustment>('adjustments');
  Box<StockTransfer> get transfersBox => Hive.box<StockTransfer>('transfers');
  Box<AccountNode> get accountsBox => Hive.box<AccountNode>('Accountant');
  Box<BatchData> get stockBatchesBox => Hive.box<BatchData>('stock_batches');
  Box<SerialData> get stockSerialsBox => Hive.box<SerialData>('stock_serials');
  Box<TransactionData> get stockTransactionsBox =>
      Hive.box<TransactionData>('stock_transactions');
  Box get configBox => Hive.box('config');

  static const int batchSizeThreshold = 50;

  // ==================== PRODUCTS ====================

  /// Save products to local cache with performance optimization
  Future<void> saveProducts(List<Item> products) async {
    final stopwatch = Stopwatch()..start();

    try {
      await productsBox.clear();

      // Batch processing for better performance
      if (products.length > batchSizeThreshold) {
        await _saveProductsInBatches(products);
      } else {
        for (var product in products) {
          if (product.id == null) continue;
          await productsBox.put(product.id, product);
        }
      }

      stopwatch.stop();
      AppLogger.performance(
        'saveProducts',
        stopwatch.elapsed,
        metrics: {
          'count': products.length,
          'batchMode': products.length > batchSizeThreshold,
        },
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to save products to cache',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Optimized batch saving for large datasets
  Future<void> _saveProductsInBatches(List<Item> products) async {
    final batches = _splitIntoBatches(products, batchSizeThreshold);

    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];
      final batchMap = <String, Item>{};

      for (var product in batch) {
        if (product.id != null) {
          batchMap[product.id!] = product;
        }
      }

      await productsBox.putAll(batchMap);
      AppLogger.debug(
        'Saved batch ${i + 1}/${batches.length}',
        module: 'hive_service',
      );
    }
  }

  /// Split list into batches for efficient processing
  List<List<T>> _splitIntoBatches<T>(List<T> list, int batchSize) {
    final batches = <List<T>>[];
    for (int i = 0; i < list.length; i += batchSize) {
      final end = (i + batchSize < list.length) ? i + batchSize : list.length;
      batches.add(list.sublist(i, end));
    }
    return batches;
  }

  /// Save products to local cache (using JSON maps - for API compatibility)
  Future<void> saveProductsJson(List<Map<String, dynamic>> productsJson) async {
    await productsBox.clear();
    for (var productJson in productsJson) {
      final id = productJson['id']?.toString();
      if (id == null) continue;
      // Convert JSON to Item object for storage
      final item = Item.fromJson(productJson);
      await productsBox.put(id, item);
    }
  }

  /// Get all cached products as Item objects
  List<Item> getProducts() {
    return productsBox.values.toList();
  }

  /// Get all cached products as JSON maps
  List<Map<String, dynamic>> getProductsJson() {
    return productsBox.values.map((item) => item.toJson()).toList();
  }

  /// Get single product by ID as Item object
  Item? getProduct(String id) {
    return productsBox.get(id);
  }

  /// Get single product by ID as JSON map
  Map<String, dynamic>? getProductJson(String id) {
    final item = productsBox.get(id);
    return item?.toJson();
  }

  /// Save single product (Item object)
  Future<void> saveProduct(Item product) async {
    if (product.id == null) return;
    await productsBox.put(product.id, product);
  }

  /// Save single product from JSON
  Future<void> saveProductJson(Map<String, dynamic> productJson) async {
    final id = productJson['id']?.toString();
    if (id == null) return;
    final item = Item.fromJson(productJson);
    await productsBox.put(id, item);
  }

  /// Delete product from cache
  Future<void> deleteProduct(String id) async {
    await productsBox.delete(id);
  }

  // ==================== CUSTOMERS ====================

  /// Save customers to local cache
  Future<void> saveCustomers(List<SalesCustomer> customers) async {
    await customersBox.clear();
    for (var customer in customers) {
      await customersBox.put(customer.id, customer);
    }
  }

  /// Get all cached customers
  List<SalesCustomer> getCustomers() {
    return customersBox.values.toList();
  }

  /// Get single customer by ID
  SalesCustomer? getCustomer(String id) {
    return customersBox.get(id);
  }

  /// Save single customer
  Future<void> saveCustomer(SalesCustomer customer) async {
    await customersBox.put(customer.id, customer);
  }

  // ==================== SALES ORDERS ====================

  /// Save sales orders to local cache
  Future<void> saveSalesOrders(List<SalesOrder> orders) async {
    await salesOrdersBox.clear();
    for (var order in orders) {
      await salesOrdersBox.put(order.id, order);
    }
  }

  /// Get all cached sales orders
  List<SalesOrder> getSalesOrders() {
    return salesOrdersBox.values.toList();
  }

  /// Get single sales order by ID
  SalesOrder? getSalesOrder(String id) {
    return salesOrdersBox.get(id);
  }

  /// Save single sales order
  Future<void> saveSalesOrder(SalesOrder order) async {
    await salesOrdersBox.put(order.id, order);
  }

  /// Delete sales order from cache
  Future<void> deleteSalesOrder(String id) async {
    await salesOrdersBox.delete(id);
  }

  // ==================== PAYMENTS ====================

  /// Save payments to local cache
  Future<void> savePayments(List<SalesPayment> payments) async {
    await paymentsBox.clear();
    for (var payment in payments) {
      await paymentsBox.put(payment.id ?? '', payment);
    }
  }

  /// Get all cached payments
  List<SalesPayment> getPayments() {
    return paymentsBox.values.toList();
  }

  /// Get single payment by ID
  SalesPayment? getPayment(String id) {
    return paymentsBox.get(id);
  }

  /// Save single payment
  Future<void> savePayment(SalesPayment payment) async {
    if (payment.id != null) {
      await paymentsBox.put(payment.id!, payment);
    }
  }

  /// Delete payment from cache
  Future<void> deletePayment(String id) async {
    await paymentsBox.delete(id);
  }

  // ==================== EWAY BILLS ====================

  /// Save E-way bills to local cache
  Future<void> saveEwayBills(List<SalesEWayBill> ewayBills) async {
    await ewayBillsBox.clear();
    for (var ewayBill in ewayBills) {
      await ewayBillsBox.put(ewayBill.id ?? '', ewayBill);
    }
  }

  /// Get all cached E-way bills
  List<SalesEWayBill> getEwayBills() {
    return ewayBillsBox.values.toList();
  }

  /// Get single E-way bill by ID
  SalesEWayBill? getEwayBill(String id) {
    return ewayBillsBox.get(id);
  }

  /// Save single E-way bill
  Future<void> saveEwayBill(SalesEWayBill ewayBill) async {
    if (ewayBill.id != null) {
      await ewayBillsBox.put(ewayBill.id!, ewayBill);
    }
  }

  /// Delete E-way bill from cache
  Future<void> deleteEwayBill(String id) async {
    await ewayBillsBox.delete(id);
  }

  // ==================== VENDORS ====================

  /// Save vendors to local cache
  Future<void> saveVendors(List<Vendor> vendors) async {
    await vendorsBox.clear();
    for (var vendor in vendors) {
      await vendorsBox.put(vendor.id, vendor);
    }
  }

  /// Get all cached vendors
  List<Vendor> getVendors() {
    return vendorsBox.values.toList();
  }

  /// Get single vendor by ID
  Vendor? getVendor(String id) {
    return vendorsBox.get(id);
  }

  /// Save single vendor
  Future<void> saveVendor(Vendor vendor) async {
    await vendorsBox.put(vendor.id, vendor);
  }

  /// Delete vendor from cache
  Future<void> deleteVendor(String id) async {
    await vendorsBox.delete(id);
  }

  // ==================== PURCHASE ORDERS ====================

  /// Save purchase orders to local cache
  Future<void> savePurchaseOrders(List<PurchaseOrder> orders) async {
    await purchaseOrdersBox.clear();
    for (var order in orders) {
      await purchaseOrdersBox.put(order.id, order);
    }
  }

  /// Get all cached purchase orders
  List<PurchaseOrder> getPurchaseOrders() {
    return purchaseOrdersBox.values.toList();
  }

  /// Get single purchase order by ID
  PurchaseOrder? getPurchaseOrder(String id) {
    return purchaseOrdersBox.get(id);
  }

  /// Save single purchase order
  Future<void> savePurchaseOrder(PurchaseOrder order) async {
    await purchaseOrdersBox.put(order.id, order);
  }

  /// Delete purchase order from cache
  Future<void> deletePurchaseOrder(String id) async {
    await purchaseOrdersBox.delete(id);
  }

  // ==================== PURCHASE BILLS ====================

  /// Save purchase bills to local cache
  Future<void> saveBills(List<PurchasesBill> bills) async {
    await billsBox.clear();
    for (var bill in bills) {
      await billsBox.put(bill.id, bill);
    }
  }

  /// Get all cached purchase bills
  List<PurchasesBill> getBills() {
    return billsBox.values.toList();
  }

  /// Get single purchase bill by ID
  PurchasesBill? getBill(String id) {
    return billsBox.get(id);
  }

  /// Save single purchase bill
  Future<void> saveBill(PurchasesBill bill) async {
    await billsBox.put(bill.id, bill);
  }

  /// Delete purchase bill from cache
  Future<void> deleteBill(String id) async {
    await billsBox.delete(id);
  }

  // ==================== STOCK ====================

  /// Save stock items to local cache
  Future<void> saveStockItems(List<Stock> stockItems) async {
    await stockBox.clear();
    for (var item in stockItems) {
      await stockBox.put(item.id, item);
    }
  }

  /// Get all cached stock items
  List<Stock> getStockItems() {
    return stockBox.values.toList();
  }

  /// Get single stock item by ID
  Stock? getStockItem(String id) {
    return stockBox.get(id);
  }

  /// Save single stock item
  Future<void> saveStockItem(Stock stockItem) async {
    await stockBox.put(stockItem.id, stockItem);
  }

  // ==================== INVENTORY ADJUSTMENTS ====================

  /// Save adjustments to local cache
  Future<void> saveAdjustments(List<InventoryAdjustment> adjustments) async {
    await adjustmentsBox.clear();
    for (var adjustment in adjustments) {
      await adjustmentsBox.put(adjustment.id, adjustment);
    }
  }

  /// Get all cached adjustments
  List<InventoryAdjustment> getAdjustments() {
    return adjustmentsBox.values.toList();
  }

  /// Get single adjustment by ID
  InventoryAdjustment? getAdjustment(String id) {
    return adjustmentsBox.get(id);
  }

  /// Save single adjustment
  Future<void> saveAdjustment(InventoryAdjustment adjustment) async {
    await adjustmentsBox.put(adjustment.id, adjustment);
  }

  /// Delete adjustment from cache
  Future<void> deleteAdjustment(String id) async {
    await adjustmentsBox.delete(id);
  }

  // ==================== STOCK TRANSFERS ====================

  /// Save transfers to local cache
  Future<void> saveTransfers(List<StockTransfer> transfers) async {
    await transfersBox.clear();
    for (var transfer in transfers) {
      await transfersBox.put(transfer.id, transfer);
    }
  }

  /// Get all cached transfers
  List<StockTransfer> getTransfers() {
    return transfersBox.values.toList();
  }

  /// Get single transfer by ID
  StockTransfer? getTransfer(String id) {
    return transfersBox.get(id);
  }

  /// Save single transfer
  Future<void> saveTransfer(StockTransfer transfer) async {
    await transfersBox.put(transfer.id, transfer);
  }

  /// Delete transfer from cache
  Future<void> deleteTransfer(String id) async {
    await transfersBox.delete(id);
  }

  // ==================== ACCOUNTS ====================

  /// Save accounts to local cache
  Future<void> saveAccounts(List<AccountNode> accounts) async {
    await accountsBox.clear();
    // Flatten the tree structure for storage
    final flatAccounts = <AccountNode>[];

    void flatten(List<AccountNode> nodes) {
      for (var node in nodes) {
        flatAccounts.add(
          node.copyWith(children: const []),
        ); // Store without children
        if (node.children.isNotEmpty) {
          flatten(node.children);
        }
      }
    }

    flatten(accounts);

    // Save flattened accounts
    for (var account in flatAccounts) {
      await accountsBox.put(account.id, account);
    }
  }

  /// Get all cached accounts (returns flat list)
  List<AccountNode> getAccounts() {
    return accountsBox.values.toList();
  }

  /// Get single account by ID
  AccountNode? getAccount(String id) {
    return accountsBox.get(id);
  }

  /// Save single account
  Future<void> saveAccount(AccountNode account) async {
    await accountsBox.put(account.id, account);
  }

  /// Delete account from cache
  Future<void> deleteAccount(String id) async {
    await accountsBox.delete(id);
  }

  // ==================== POS DRAFTS ====================

  /// Save POS draft
  Future<void> savePOSDraft(String draftId, SalesOrder draft) async {
    await posDraftsBox.put(draftId, draft);
  }

  /// Get all POS drafts
  List<SalesOrder> getPOSDrafts() {
    return posDraftsBox.values.toList();
  }

  /// Delete POS draft
  Future<void> deletePOSDraft(String draftId) async {
    await posDraftsBox.delete(draftId);
  }

  // ==================== CONFIG ====================

  /// Save config value
  Future<void> saveConfig(String key, dynamic value) async {
    await configBox.put(key, value);
  }

  /// Get config value
  dynamic getConfig(String key, {dynamic defaultValue}) {
    return configBox.get(key, defaultValue: defaultValue);
  }

  /// Get last sync timestamp for a resource
  DateTime? getLastSyncTime(String resource) {
    final timestamp = configBox.get('last_sync_$resource');
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime(String resource) async {
    await configBox.put(
      'last_sync_$resource',
      DateTime.now().toIso8601String(),
    );
  }

  // ==================== UTILITIES ====================

  /// Clear all cached data (use with caution)
  Future<void> clearAllCache() async {
    await productsBox.clear();
    await customersBox.clear();
    await posDraftsBox.clear();
    await salesOrdersBox.clear();
    await paymentsBox.clear();
    await ewayBillsBox.clear();
    await vendorsBox.clear();
    await purchaseOrdersBox.clear();
    await billsBox.clear();
    await stockBox.clear();
    await adjustmentsBox.clear();
    await transfersBox.clear();
    await accountsBox.clear();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'products': productsBox.length,
      'customers': customersBox.length,
      'pos_drafts': posDraftsBox.length,
      'sales_orders': salesOrdersBox.length,
      'payments': paymentsBox.length,
      'eway_bills': ewayBillsBox.length,
      'vendors': vendorsBox.length,
      'purchase_orders': purchaseOrdersBox.length,
      'bills': billsBox.length,
      'stock': stockBox.length,
      'adjustments': adjustmentsBox.length,
      'transfers': transfersBox.length,
      'Accountant': accountsBox.length,
      'stock_batches': stockBatchesBox.length,
      'stock_serials': stockSerialsBox.length,
      'stock_transactions': stockTransactionsBox.length,
      'config': configBox.length,
    };
  }

  // ==================== STOCK DATA CACHING ====================

  Future<void> saveItemSerials(String itemId, List<SerialData> serials) async {
    final Map<String, SerialData> map = {};
    for (var i = 0; i < serials.length; i++) {
      map['${itemId}_$i'] = serials[i];
    }
    await stockSerialsBox.putAll(map);
  }

  Future<void> saveItemBatches(String itemId, List<BatchData> batches) async {
    final Map<String, BatchData> map = {};
    for (var i = 0; i < batches.length; i++) {
      map['${itemId}_$i'] = batches[i];
    }
    await stockBatchesBox.putAll(map);
  }

  Future<void> saveItemStockTransactions(
    String itemId,
    List<TransactionData> transactions,
  ) async {
    final Map<String, TransactionData> map = {};
    for (var i = 0; i < transactions.length; i++) {
      map['${itemId}_$i'] = transactions[i];
    }
    await stockTransactionsBox.putAll(map);
  }

  List<SerialData> getItemSerials(String itemId) {
    return stockSerialsBox.values
        .where(
          (s) => stockSerialsBox.keys.any(
            (k) =>
                k.toString().startsWith(itemId) && stockSerialsBox.get(k) == s,
          ),
        )
        .toList();
  }
}
