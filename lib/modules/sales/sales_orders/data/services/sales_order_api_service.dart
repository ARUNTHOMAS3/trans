// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:zerpai_erp/shared/services/api_client.dart';
// import '../models/sales_order_model.dart';
// import '../models/sales_customer_model.dart';
// import '../models/sales_payment_model.dart';
// import '../models/sales_eway_bill_model.dart';
// import '../models/sales_payment_link_model.dart';

// class SalesOrderApiService {
//   final ApiClient _apiClient = ApiClient();

//   // CUSTOMERS
//   Future<List<SalesCustomer>> getCustomers({String? search, int? limit}) async {
//     try {
//       final response = await _apiClient.get('/sales/customers');
//       if (response.statusCode == 200) {
//         final List<dynamic> data = response.data as List;
//         return data.map((json) => SalesCustomer.fromJson(json)).toList();
//       }
//       throw Exception('Failed to load customers');
//     } catch (e) {
//       throw Exception('Error fetching customers: $e');
//     }
//   }

//   Future<SalesCustomer> createCustomer(SalesCustomer customer) async {
//     try {
//       final response = await _apiClient.post(
//         '/sales/customers',
//         data: customer.toJson(),
//       );
//       if (response.statusCode == 201 || response.statusCode == 200) {
//         return SalesCustomer.fromJson(response.data);
//       }
//       throw Exception('Failed to create customer');
//     } catch (e) {
//       throw Exception('Error creating customer: $e');
//     }
//   }

//   // SALES ORDERS / INVOICES / QUOTES (Generic)
//   Future<List<SalesOrder>> getSalesByType(String type) async {
//     try {
//       final response = await _apiClient.get(
//         '/sales',
//         queryParameters: {'type': type},
//       );
//       if (response.statusCode == 200) {
//         final List<dynamic> data = response.data as List;
//         return data.map((json) => SalesOrder.fromJson(json)).toList();
//       }
//       throw Exception('Failed to load $type');
//     } catch (e) {
//       throw Exception('Error fetching $type: $e');
//     }
//   }

//   Future<List<SalesOrder>> getSalesOrders() async {
//     return getSalesByType('order');
//   }

//   // PAYMENTS
//   Future<List<SalesPayment>> getPayments() async {
//     try {
//       final response = await _apiClient.get('/sales/payments');
//       if (response.statusCode == 200) {
//         final List<dynamic> data = response.data as List;
//         return data.map((json) => SalesPayment.fromJson(json)).toList();
//       }
//       throw Exception('Failed to load payments');
//     } catch (e) {
//       throw Exception('Error fetching payments: $e');
//     }
//   }

//   Future<SalesPayment> createPayment(SalesPayment payment) async {
//     try {
//       final response = await _apiClient.post(
//         '/sales/payments',
//         data: payment.toJson(),
//       );
//       if (response.statusCode == 201 || response.statusCode == 200) {
//         return SalesPayment.fromJson(response.data);
//       }
//       throw Exception('Failed to create payment');
//     } catch (e) {
//       throw Exception('Error creating payment: $e');
//     }
//   }

//   Future<SalesOrder> getSalesOrderById(String id) async {
//     try {
//       final response = await _apiClient.get('/sales/$id');
//       if (response.statusCode == 200) {
//         return SalesOrder.fromJson(response.data);
//       }
//       throw Exception('Sales order not found');
//     } catch (e) {
//       throw Exception('Error fetching sales order: $e');
//     }
//   }

//   Future<SalesOrder> createSalesOrder(SalesOrder sale) async {
//     try {
//       final payload = sale.toJson();
//       debugPrint('🚀 Sending sales order payload: $payload');
//       final response = await _apiClient.post('/sales', data: payload);
//       if (response.statusCode == 201 || response.statusCode == 200) {
//         return SalesOrder.fromJson(response.data);
//       }
//       throw Exception('Failed to create sales order');
//     } catch (e) {
//       if (e is DioException) {
//         debugPrint(
//           '❌ createSalesOrder error response: ${e.response?.statusCode} -> ${e.response?.data}',
//         );
//       }
//       throw Exception('Error creating sales order: $e');
//     }
//   }

//   Future<void> deleteSalesOrder(String id) async {
//     try {
//       final response = await _apiClient.delete('/sales/$id');
//       if (response.statusCode != 200 && response.statusCode != 204) {
//         throw Exception('Failed to delete sales order');
//       }
//     } catch (e) {
//       throw Exception('Error deleting sales order: $e');
//     }
//   }

//   // E-WAY BILLS
//   Future<List<SalesEWayBill>> getEWayBills() async {
//     try {
//       final response = await _apiClient.get('/sales/eway-bills');
//       if (response.statusCode == 200) {
//         final List<dynamic> data = response.data as List;
//         return data.map((json) => SalesEWayBill.fromJson(json)).toList();
//       }
//       throw Exception('Failed to load e-way bills');
//     } catch (e) {
//       throw Exception('Error fetching e-way bills: $e');
//     }
//   }

//   Future<SalesEWayBill> createEWayBill(SalesEWayBill bill) async {
//     try {
//       final response = await _apiClient.post(
//         '/sales/eway-bills',
//         data: bill.toJson(),
//       );
//       if (response.statusCode == 201 || response.statusCode == 200) {
//         return SalesEWayBill.fromJson(response.data);
//       }
//       throw Exception('Failed to create e-way bill');
//     } catch (e) {
//       throw Exception('Error creating e-way bill: $e');
//     }
//   }

//   // PAYMENT LINKS
//   Future<List<SalesPaymentLink>> getPaymentLinks() async {
//     try {
//       final response = await _apiClient.get('/sales/payment-links');
//       if (response.statusCode == 200) {
//         final List<dynamic> data = response.data as List;
//         return data.map((json) => SalesPaymentLink.fromJson(json)).toList();
//       }
//       throw Exception('Failed to load payment links');
//     } catch (e) {
//       throw Exception('Error fetching payment links: $e');
//     }
//   }

//   Future<SalesPaymentLink> createPaymentLink(SalesPaymentLink link) async {
//     try {
//       final response = await _apiClient.post(
//         '/sales/payment-links',
//         data: link.toJson(),
//       );
//       if (response.statusCode == 201 || response.statusCode == 200) {
//         return SalesPaymentLink.fromJson(response.data);
//       }
//       throw Exception('Failed to create payment link');
//     } catch (e) {
//       throw Exception('Error creating payment link: $e');
//     }
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/sales_order_model.dart';
import '../../../customers/data/models/sales_customer_model.dart';
import '../../../customers/data/models/sales_customer_detail_context_model.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/data/models/sales_payment_model.dart';
import '../../../eway_bills/data/models/sales_eway_bill_model.dart';
import '../../../payment_links/data/models/sales_payment_link_model.dart';
import '../../../../purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';

class SalesOrderApiService {
  final ApiClient _apiClient = ApiClient();

  // CUSTOMERS
  Future<List<SalesCustomer>> getCustomers({String? search, int? limit}) async {
    try {
      final queryParameters = {
        if (search != null && search.isNotEmpty) 'search': search,
        if (limit != null) 'limit': limit,
      };
      final response = await _apiClient.get('/sales/customers', queryParameters: queryParameters);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
        return data.map((json) => SalesCustomer.fromJson(json)).toList();
      }
      throw Exception('Failed to load customers');
    } catch (e) {
      throw Exception('Error fetching customers: $e');
    }
  }

  Future<SalesCustomer> getCustomerById(String id) async {
    try {
      final response = await _apiClient.get('/sales/customers/$id');
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('statusCode') &&
              (responseData['statusCode'] is int) &&
              (responseData['statusCode'] as int) >= 400) {
            throw Exception(responseData['message'] ?? 'Customer not found');
          }
          if (responseData.containsKey('data')) {
            if (responseData['data'] == null) {
              throw Exception('Customer not found');
            }
            return SalesCustomer.fromJson(responseData['data']);
          }
          if (responseData.containsKey('id')) {
            return SalesCustomer.fromJson(responseData);
          }
          throw Exception('Invalid customer payload');
        }
        throw Exception('Invalid customer response');
      }
      throw Exception('Failed to load customer');
    } catch (e) {
      if (e is DioException) {
        debugPrint(
          '❌ getCustomerById error: ${e.response?.statusCode} -> ${e.response?.data}',
        );
      }
      throw Exception('Error fetching customer by id: $e');
    }
  }

  Future<SalesCustomerDetailContext> getCustomerDetailContext(String id) async {
    try {
      final response = await _apiClient.get('/sales/customers/$id/detail-context');
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('statusCode') &&
              (responseData['statusCode'] is int) &&
              (responseData['statusCode'] as int) >= 400) {
            throw Exception(responseData['message'] ?? 'Customer detail context not found');
          }
          if (responseData.containsKey('data') &&
              responseData['data'] is Map<String, dynamic>) {
            return SalesCustomerDetailContext.fromJson(
              responseData['data'] as Map<String, dynamic>,
            );
          }
          return SalesCustomerDetailContext.fromJson(responseData);
        }
        throw Exception('Invalid customer detail context response');
      }
      throw Exception('Failed to load customer detail context');
    } catch (e) {
      if (e is DioException) {
        debugPrint(
          '❌ getCustomerDetailContext error: ${e.response?.statusCode} -> ${e.response?.data}',
        );
      }
      throw Exception('Error fetching customer detail context: $e');
    }
  }

  Future<SalesCustomer> createCustomer(SalesCustomer customer) async {
    try {
      final response = await _apiClient.post(
        '/sales/customers',
        data: customer.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('statusCode') &&
            (responseData['statusCode'] is int) &&
            (responseData['statusCode'] as int) >= 400) {
          throw Exception(responseData['message'] ?? 'Failed to create customer');
        }
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          return SalesCustomer.fromJson(responseData['data']);
        }
        return SalesCustomer.fromJson(responseData);
      }
      throw Exception('Failed to create customer');
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Error creating customer: ${e.toString()}');
    }
  }

  Future<SalesCustomer> updateCustomer(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.put(
        '/sales/customers/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('statusCode') &&
            (responseData['statusCode'] is int) &&
            (responseData['statusCode'] as int) >= 400) {
          throw Exception(responseData['message'] ?? 'Failed to update customer');
        }
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          return SalesCustomer.fromJson(responseData['data']);
        }
        return SalesCustomer.fromJson(responseData);
      }
      throw Exception('Failed to update customer');
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Error updating customer: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> bulkUpdateCustomers(
    List<String> customerIds,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _apiClient.post(
        '/sales/customers/bulk-update',
        data: {
          'customerIds': customerIds,
          'updateData': updateData,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('statusCode') &&
            (responseData['statusCode'] is int) &&
            (responseData['statusCode'] as int) >= 400) {
          throw Exception(responseData['message'] ?? 'Failed to bulk update');
        }
        if (responseData is Map<String, dynamic> &&
            responseData['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(responseData['data']);
        }
        if (responseData is Map<String, dynamic>) {
          return responseData;
        }
      }
      throw Exception('Failed to bulk update customers');
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Error bulk updating customers: ${e.toString()}');
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _apiClient.delete('/sales/customers/$id');
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Error deleting customer: ${e.toString()}');
    }
  }

  Future<SalesCustomer> markCustomerInactive(String id) async {
    try {
      final response = await _apiClient.put(
        '/sales/customers/$id',
        data: {'status': 'inactive', 'is_active': false},
      );
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          return SalesCustomer.fromJson(responseData['data']);
        }
        return SalesCustomer.fromJson(responseData);
      }
      throw Exception('Failed to mark customer inactive');
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Error marking customer inactive: ${e.toString()}');
    }
  }

  // SALES ORDERS / INVOICES / QUOTES (Generic)
  Future<List<SalesOrder>> getSalesByType(String type, {String? search, int? limit}) async {
    try {
      final response = await _apiClient.get(
        '/sales',
        queryParameters: {
          'type': type,
          if (search != null && search.isNotEmpty) 'search': search,
          if (limit != null) 'limit': limit,
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
        return data.map((json) => SalesOrder.fromJson(json)).toList();
      }
      throw Exception('Failed to load $type');
    } catch (e) {
      throw Exception('Error fetching $type: $e');
    }
  }

  Future<List<SalesOrder>> getSalesOrders() async {
    return getSalesByType('order');
  }

  Future<List<SalesOrder>> getSalesOrdersByCustomer(String customerId) async {
    try {
      final response = await _apiClient.get('/sales/customer/$customerId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
        return data.map((json) => SalesOrder.fromJson(json)).toList();
      }
      throw Exception('Failed to load customer sales orders');
    } catch (e) {
      throw Exception('Error fetching customer sales orders: $e');
    }
  }

  // PAYMENTS
  Future<List<SalesPayment>> getPayments() async {
    try {
      final response = await _apiClient.get('/sales/payments');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => SalesPayment.fromJson(json)).toList();
      }
      throw Exception('Failed to load payments');
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  Future<SalesPayment> createPayment(SalesPayment payment) async {
    try {
      final response = await _apiClient.post(
        '/sales/payments',
        data: payment.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return SalesPayment.fromJson(response.data);
      }
      throw Exception('Failed to create payment');
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  Future<SalesOrder> getSalesOrderById(String id) async {
    try {
      final response = await _apiClient.get('/sales/$id');
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final payload = responseData['data'];
          if (payload is Map<String, dynamic>) {
            return SalesOrder.fromJson(payload);
          }
          return SalesOrder.fromJson(responseData);
        }
        throw Exception('Invalid sales order response');
      }
      throw Exception('Sales order not found');
    } catch (e) {
      throw Exception('Error fetching sales order: $e');
    }
  }

  Future<Map<String, dynamic>> getInvoiceById(String id) async {
    try {
      final response = await _apiClient.get('/sales/invoices/$id');
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final payload = responseData['data'];
          if (payload is Map<String, dynamic>) {
            return payload;
          }
          return responseData;
        }
        throw Exception('Invalid sales invoice response');
      }
      throw Exception('Sales invoice not found');
    } catch (e) {
      throw Exception('Error fetching sales invoice: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    try {
      final response = await _apiClient.get('/sales/invoices');
      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> data = responseData is List
            ? responseData
            : (responseData is Map<String, dynamic> &&
                    responseData['data'] is List)
                ? responseData['data'] as List
                : <dynamic>[];
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      throw Exception('Failed to load invoices');
    } catch (e) {
      throw Exception('Error fetching invoices: $e');
    }
  }

  Future<List<SalesOrder>> getSalesInvoices() async {
    final invoices = await getInvoices();
    return invoices
        .map(_mapInvoiceToSalesOrderJson)
        .map(SalesOrder.fromJson)
        .toList();
  }

  Map<String, dynamic> _mapInvoiceToSalesOrderJson(
    Map<String, dynamic> invoice,
  ) {
    final customer = invoice['customer'];
    final customerMap = customer is Map
        ? Map<String, dynamic>.from(customer)
        : null;
    return {
      ...invoice,
      'sale_number': invoice['invoice_number'] ?? invoice['sale_number'],
      'sale_date': invoice['invoice_date'] ?? invoice['sale_date'],
      'sub_total': invoice['subtotal'] ?? invoice['sub_total'] ?? 0,
      'total': invoice['grand_total'] ?? invoice['total'] ?? 0,
      'tax_total': invoice['tax_total'] ?? 0,
      'discount_total': invoice['discount_total'] ?? 0,
      'document_type': invoice['document_type'] ?? 'invoice',
      'customer': customerMap,
      'customer_name': customerMap?['display_name'],
      'sales_order_id': invoice['sales_order_id'],
    };
  }

  Future<SalesOrder> createSalesOrder(SalesOrder sale) async {
    try {
      final payload = sale.toJson();
      debugPrint('🚀 Sending sales order payload: $payload');
      final response = await _apiClient.post('/sales', data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return SalesOrder.fromJson(response.data);
      }
      throw Exception('Failed to create sales order');
    } catch (e) {
      if (e is DioException) {
        debugPrint(
          '❌ createSalesOrder error response: ${e.response?.statusCode} -> ${e.response?.data}',
        );
      }
      throw Exception('Error creating sales order: $e');
    }
  }

  Future<SalesOrder> updateSalesOrder(String id, SalesOrder sale) async {
    try {
      final payload = sale.toJson();
      debugPrint('🚀 Updating sales order payload: $payload');
      final response = await _apiClient.put('/sales/$id', data: payload);
      if (response.statusCode == 200) {
        return SalesOrder.fromJson(response.data);
      }
      throw Exception('Failed to update sales order');
    } catch (e) {
      if (e is DioException) {
        debugPrint(
          '❌ updateSalesOrder error response: ${e.response?.statusCode} -> ${e.response?.data}',
        );
      }
      throw Exception('Error updating sales order: $e');
    }
  }

  Future<void> deleteSalesOrder(String id) async {
    try {
      final response = await _apiClient.delete('/sales/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete sales order');
      }
    } catch (e) {
      throw Exception('Error deleting sales order: $e');
    }
  }

  // E-WAY BILLS
  Future<List<SalesEWayBill>> getEWayBills() async {
    try {
      final response = await _apiClient.get('/sales/eway-bills');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => SalesEWayBill.fromJson(json)).toList();
      }
      throw Exception('Failed to load e-way bills');
    } catch (e) {
      throw Exception('Error fetching e-way bills: $e');
    }
  }

  Future<SalesEWayBill> createEWayBill(SalesEWayBill bill) async {
    try {
      final response = await _apiClient.post(
        '/sales/eway-bills',
        data: bill.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return SalesEWayBill.fromJson(response.data);
      }
      throw Exception('Failed to create e-way bill');
    } catch (e) {
      throw Exception('Error creating e-way bill: $e');
    }
  }

  // PAYMENT LINKS
  Future<List<SalesPaymentLink>> getPaymentLinks() async {
    try {
      final response = await _apiClient.get('/sales/payment-links');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => SalesPaymentLink.fromJson(json)).toList();
      }
      throw Exception('Failed to load payment links');
    } catch (e) {
      throw Exception('Error fetching payment links: $e');
    }
  }

  Future<SalesPaymentLink> createPaymentLink(SalesPaymentLink link) async {
    try {
      final response = await _apiClient.post(
        '/sales/payment-links',
        data: link.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return SalesPaymentLink.fromJson(response.data);
      }
      throw Exception('Failed to create payment link');
    } catch (e) {
      throw Exception('Error creating payment link: $e');
    }
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.post('/sales/invoices', data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            return data;
          }
          return responseData;
        }
        return <String, dynamic>{};
      }
      throw Exception('Failed to create invoice');
    } catch (e) {
      throw Exception('Error creating invoice: $e');
    }
  }

  Future<Map<String, dynamic>> updateInvoice(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.put('/sales/invoices/$id', data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final data = responseData['data'];
          if (data is Map<String, dynamic>) {
            return data;
          }
          return responseData;
        }
        return <String, dynamic>{};
      }
      throw Exception('Failed to update invoice');
    } catch (e) {
      throw Exception('Error updating invoice: $e');
    }
  }

  Future<List<PurchaseOrder>> getAwaitingPoApprovals() async {
    try {
      final response = await _apiClient.get('/sales/awaiting-po-approvals');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
        return data.map((json) => PurchaseOrder.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load awaiting PO approvals');
    } catch (e) {
      throw Exception('Error fetching awaiting PO approvals: $e');
    }
  }

  Future<void> approvePurchaseOrders(List<String> poIds) async {
    try {
      final response = await _apiClient.post(
        '/sales/awaiting-po-approvals/approve',
        data: {'poIds': poIds},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to approve purchase orders');
      }
    } catch (e) {
      throw Exception('Error approving purchase orders: $e');
    }
  }
}

