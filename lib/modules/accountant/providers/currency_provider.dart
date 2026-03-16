import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accountant_lookup_models.dart';
import '../repositories/accountant_repository.dart';

final currenciesProvider = FutureProvider<List<Currency>>((ref) async {
  final repository = ref.watch(accountantRepositoryProvider);
  return repository.getCurrencies();
});

final defaultCurrencyProvider = Provider<AsyncValue<Currency>>((ref) {
  final currencies = ref.watch(currenciesProvider);
  return currencies.whenData((list) {
    if (list.isEmpty) {
      return const Currency(
        id: '999',
        code: 'INR',
        name: 'Indian Rupee',
        symbol: '₹',
      );
    }
    // Try to find INR as default, otherwise first
    return list.firstWhere((c) => c.code == 'INR', orElse: () => list.first);
  });
});
