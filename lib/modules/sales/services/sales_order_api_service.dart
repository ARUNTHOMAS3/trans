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
//   Future<List<SalesCustomer>> getCustomers() async {
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
import '../models/sales_customer_model.dart';
import '../models/sales_customer_detail_context_model.dart';
import '../models/sales_payment_model.dart';
import '../models/sales_eway_bill_model.dart';
import '../models/sales_payment_link_model.dart';

class SalesOrderApiService {
  final ApiClient _apiClient = ApiClient();

  // CUSTOMERS
  Future<List<SalesCustomer>> getCustomers() async {
    try {
      final response = await _apiClient.get('/sales/customers');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
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
  Future<List<SalesOrder>> getSalesByType(String type) async {
    try {
      final response = await _apiClient.get(
        '/sales',
        queryParameters: {'type': type},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
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
        final List<dynamic> data = response.data as List;
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
        return SalesOrder.fromJson(response.data);
      }
      throw Exception('Sales order not found');
    } catch (e) {
      throw Exception('Error fetching sales order: $e');
    }
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
}
