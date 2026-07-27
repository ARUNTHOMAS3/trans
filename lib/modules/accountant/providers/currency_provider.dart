import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import '../models/accountant_lookup_models.dart';
import '../repositories/accountant_repository.dart';

final currenciesProvider = FutureProvider<List<Currency>>((ref) async {
  final repository = ref.watch(accountantRepositoryProvider);
  return repository.getCurrencies();
});

/// Returns the organization's configured base currency from persisted rows.
final defaultCurrencyProvider = Provider<AsyncValue<Currency?>>((ref) {
  final currencies = ref.watch(currenciesProvider);
  final orgCurrencyCode = ref.watch(orgCurrencyCodeProvider);

  return currencies.whenData((list) {
    if (list.isEmpty || orgCurrencyCode == null) {
      return null;
    }
    return list
        .where((currency) => currency.code == orgCurrencyCode)
        .firstOrNull;
  });
});
