import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/customers/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/payments/models/sales_payment_model.dart';
import 'package:zerpai_erp/modules/sales/eway_bills/models/sales_eway_bill_model.dart';
import 'package:zerpai_erp/modules/sales/payment_links/models/sales_payment_link_model.dart';
import 'package:zerpai_erp/modules/sales/shared/services/sales_order_api_service.dart';
import 'package:zerpai_erp/modules/inventory/providers/stock_provider.dart';

final salesOrderApiServiceProvider = Provider((ref) => SalesOrderApiService());

final salesOrderControllerProvider =
    StateNotifierProvider<SalesOrderController, AsyncValue<List<SalesOrder>>>((
      ref,
    ) {
      return SalesOrderController(ref.watch(salesOrderApiServiceProvider), ref);
    });

final salesCustomersProvider = FutureProvider<List<SalesCustomer>>((ref) async {
  final apiService = ref.watch(salesOrderApiServiceProvider);
  return apiService.getCustomers();
});

final salesQuotesProvider = FutureProvider<List<SalesOrder>>((ref) {
  return ref.watch(salesOrderApiServiceProvider).getSalesByType('quote');
});

final salesInvoicesProvider = FutureProvider<List<SalesOrder>>((ref) {
  return ref.watch(salesOrderApiServiceProvider).getSalesByType('invoice');
});

final salesPaymentsProvider = FutureProvider<List<SalesPayment>>((ref) {
  return ref.watch(salesOrderApiServiceProvider).getPayments();
});

final salesCreditNotesProvider = FutureProvider<List<SalesOrder>>((ref) {
  return ref.watch(salesOrderApiServiceProvider).getSalesByType('credit_note');
});

final salesChallansProvider = FutureProvider<List<SalesOrder>>((ref) {
  return ref.watch(salesOrderApiServiceProvider).getSalesByType('challan');
});

final salesRetainerInvoicesProvider = FutureProvider<List<SalesOrder>>((ref) {
  return ref
      .watch(salesOrderApiServiceProvider)
      .getSalesByType('retainer_invoice');
});

final salesRecurringInvoicesProvider = FutureProvider<List<SalesOrder>>((ref) {
  return ref
      .watch(salesOrderApiServiceProvider)
      .getSalesByType('recurring_invoice');
});

final salesEWayBillsProvider = FutureProvider<List<SalesEWayBill>>((ref) {
  return ref.watch(salesOrderApiServiceProvider).getEWayBills();
});

final salesPaymentLinksProvider = FutureProvider<List<SalesPaymentLink>>((ref) {
  return ref.watch(salesOrderApiServiceProvider).getPaymentLinks();
});

final salesOrdersByCustomerProvider = FutureProvider.family<List<SalesOrder>, String>((ref, customerId) async {
  final orders = ref.watch(salesOrderControllerProvider);
  return orders.maybeWhen(
    data: (list) => list.where((o) => o.customerId == customerId).toList(),
    orElse: () => [],
  );
});

final allSalesOrderItemsProvider = FutureProvider<List<WarehouseStockData>>((ref) async {
  final salesOrdersAsync = ref.watch(salesOrderControllerProvider);
  return salesOrdersAsync.maybeWhen(
    data: (orders) {
      final List<WarehouseStockData> items = [];
      for (var order in orders) {
        if (order.items != null) {
          for (var item in order.items!) {
            items.add(WarehouseStockData(
              warehouseId: '', // Sales items don't have a specific warehouse until picked
              productId: item.itemId,
              productCode: item.item?.itemCode ?? '',
              productName: item.item?.productName ?? '',
              customerId: order.customerId,
              stock: 0,
              quantityToPick: item.quantity,
              salesOrderId: order.id,
            ));
          }
        }
      }
      return items;
    },
    orElse: () => [],
  );
});

class SalesOrderController extends StateNotifier<AsyncValue<List<SalesOrder>>> {
  final SalesOrderApiService _apiService;
  final Ref ref;

  SalesOrderController(this._apiService, this.ref)
    : super(const AsyncValue.loading()) {
    loadSalesOrders();
  }

  Future<void> loadSalesOrders() async {
    state = const AsyncValue.loading();
    try {
      final sales = await _apiService.getSalesOrders();
      state = AsyncValue.data(sales);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<SalesOrder?> createSalesOrder(SalesOrder sale) async {
    try {
      final newSale = await _apiService.createSalesOrder(sale);
      await loadSalesOrders(); // Refresh list
      return newSale;
    } catch (e) {
      debugPrint('Error creating sales order: $e');
      rethrow;
    }
  }

  Future<SalesOrder?> updateSalesOrder(String id, SalesOrder sale) async {
    try {
      final updatedSale = await _apiService.updateSalesOrder(id, sale);
      await loadSalesOrders();
      return updatedSale;
    } catch (e) {
      debugPrint('Error updating sales order: $e');
      rethrow;
    }
  }

  Future<SalesOrder?> markAsConfirmed(String id) async {
    try {
      final current = state.value?.firstWhere((s) => s.id == id);
      if (current == null) return null;
      final updated = await _apiService.updateSalesOrder(
        id,
        SalesOrder(
          id: current.id,
          customerId: current.customerId,
          saleNumber: current.saleNumber,
          saleDate: current.saleDate,
          status: 'confirmed',
          subTotal: current.subTotal,
          taxTotal: current.taxTotal,
          discountTotal: current.discountTotal,
          shippingCharges: current.shippingCharges,
          adjustment: current.adjustment,
          total: current.total,
          documentType: current.documentType,
          reference: current.reference,
          paymentTerms: current.paymentTerms,
          deliveryMethod: current.deliveryMethod,
          salesperson: current.salesperson,
          expectedShipmentDate: current.expectedShipmentDate,
          customerNotes: current.customerNotes,
          termsAndConditions: current.termsAndConditions,
          customer: current.customer,
          items: current.items,
          createdAt: current.createdAt,
        ),
      );
      await loadSalesOrders();
      return updated;
    } catch (e) {
      debugPrint('Error marking as confirmed: $e');
      rethrow;
    }
  }

  Future<void> deleteSalesOrder(String id) async {
    try {
      await _apiService.deleteSalesOrder(id);
      await loadSalesOrders(); // Refresh list
    } catch (e) {
      debugPrint('Error deleting sales order: $e');
      rethrow;
    }
  }

  Future<SalesCustomer> createCustomer(SalesCustomer customer) async {
    try {
      final newCustomer = await _apiService.createCustomer(customer);
      // Refresh the customers provider so the UI updates
      ref.invalidate(salesCustomersProvider);
      return newCustomer;
    } catch (e) {
      debugPrint('Error creating customer: $e');
      rethrow;
    }
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      await _apiService.updateCustomer(id, data);
      // Refresh the customers provider so the UI updates
      ref.invalidate(salesCustomersProvider);
    } catch (e) {
      debugPrint('Error updating customer: $e');
      rethrow;
    }
  }
  Future<SalesOrder?> getSalesOrderById(String id) async {
    try {
      return await _apiService.getSalesOrderById(id);
    } catch (e) {
      debugPrint('Error fetching sales order items: $e');
      rethrow;
    }
  }

  Future<SalesCustomer> getCustomerById(String id) async {
    try {
      return await _apiService.getCustomerById(id);
    } catch (e) {
      debugPrint('Error fetching customer: $e');
      rethrow;
    }
  }
}
