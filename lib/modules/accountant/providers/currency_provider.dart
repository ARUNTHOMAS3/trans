import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import '../models/accountant_lookup_models.dart';
import '../repositories/accountant_repository.dart';

final currenciesProvider = FutureProvider<List<Currency>>((ref) async {
  final repository = ref.watch(accountantRepositoryProvider);
  return repository.getCurrencies();
});

/// Returns the org's base currency, resolved from org settings.
/// Falls back to INR if org settings haven't loaded yet or currency not found.
final defaultCurrencyProvider = Provider<AsyncValue<Currency>>((ref) {
  final currencies = ref.watch(currenciesProvider);
  final orgCurrencyCode = ref.watch(orgCurrencyCodeProvider);

  return currencies.whenData((list) {
    if (list.isEmpty) {
      return const Currency(
        id: '999',
        code: 'INR',
        name: 'Indian Rupee',
        symbol: '₹',
      );
    }
    return list.firstWhere(
      (c) => c.code == orgCurrencyCode,
      orElse: () =>
          list.firstWhere((c) => c.code == 'INR', orElse: () => list.first),
    );
  });
});
