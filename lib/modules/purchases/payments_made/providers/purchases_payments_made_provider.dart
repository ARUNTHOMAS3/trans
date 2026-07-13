// PATH: lib/modules/purchases/payments_made/providers/purchases_payments_made_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchases_payments_made_model.dart';
import '../repositories/purchases_payments_made_repository_impl.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

final paymentsMadeRepositoryProvider = Provider<PaymentsMadeRepositoryImpl>(
  (ref) => PaymentsMadeRepositoryImpl(ref.read(apiClientProvider)),
);

final paymentsMadesProvider =
    FutureProvider.family<List<PaymentMade>, PaymentMadeFilter>((
      ref,
      filter,
    ) async {
      final repository = ref.read(paymentsMadeRepositoryProvider);
      return repository.getPaymentsMade(
        page: filter.page,
        limit: filter.limit,
        search: filter.search,
        status: filter.status,
        vendorId: filter.vendorId,
      );
    });

final paymentMadeProvider = FutureProvider.family<PaymentMade?, String>((
  ref,
  id,
) async {
  final repository = ref.read(paymentsMadeRepositoryProvider);
  return repository.getPaymentMade(id);
});

final createPaymentMadeProvider =
    FutureProvider.family<PaymentMade, PaymentMade>((
      ref,
      paymentMade,
    ) async {
      final repository = ref.read(paymentsMadeRepositoryProvider);
      return repository.createPaymentMade(paymentMade);
    });

final updatePaymentMadeProvider =
    FutureProvider.family<PaymentMade?, PaymentMadeUpdateRequest>((
      ref,
      request,
    ) async {
      final repository = ref.read(paymentsMadeRepositoryProvider);
      return repository.updatePaymentMade(request.id, request.paymentMade);
    });

final deletePaymentMadeProvider = FutureProvider.family<bool, String>((
  ref,
  id,
) async {
  final repository = ref.read(paymentsMadeRepositoryProvider);
  return repository.deletePaymentMade(id);
});

final pmNextNumberProvider = FutureProvider<String>((ref) async {
  final repository = ref.read(paymentsMadeRepositoryProvider);
  final result = await repository.getNextPaymentMadeNumber();
  return result['formatted'] as String? ?? 'PM-00001';
});

final pmSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(paymentsMadeRepositoryProvider);
  return repository.getPaymentMadeSettings();
});

// Models for provider parameters
class PaymentMadeFilter {
  final int page;
  final int limit;
  final String? vendorId;
  final String? search;
  final String? status;

  PaymentMadeFilter({
    this.page = 1,
    this.limit = 100,
    this.vendorId,
    this.search,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMadeFilter &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          limit == other.limit &&
          vendorId == other.vendorId &&
          search == other.search &&
          status == other.status;

  @override
  int get hashCode =>
      page.hashCode ^
      limit.hashCode ^
      vendorId.hashCode ^
      search.hashCode ^
      status.hashCode;
}

class PaymentMadeUpdateRequest {
  final String id;
  final PaymentMade paymentMade;

  PaymentMadeUpdateRequest(this.id, this.paymentMade);
}
