// PATH: lib/modules/purchases/payments_made/repositories/purchases_payments_made_repository.dart

import '../models/purchases_payments_made_model.dart';

abstract class PaymentsMadeRepository {
  Future<List<PaymentMade>> getPaymentsMade({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
    String? vendorId,
  });

  Future<PaymentMade?> getPaymentMade(String id);

  Future<PaymentMade> createPaymentMade(PaymentMade paymentMade);

  Future<PaymentMade?> updatePaymentMade(
    String id,
    PaymentMade paymentMade,
  );

  Future<bool> deletePaymentMade(String id);

  Future<int> getTotalCount();
  Future<Map<String, dynamic>> getPaymentMadeSettings();
  Future<void> updatePaymentMadeSettings(Map<String, dynamic> settings);
  Future<Map<String, dynamic>> getNextPaymentMadeNumber();
}
