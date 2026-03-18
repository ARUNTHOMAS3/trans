import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/items_stock_models.dart';
import '../../repositories/items_repository_provider.dart';

// Provider for serial numbers related to a specific item
final itemSerialsProvider =
    AsyncNotifierProvider.family<ItemSerialsNotifier, List<SerialData>, String>(
      ItemSerialsNotifier.new,
    );

class ItemSerialsNotifier
    extends FamilyAsyncNotifier<List<SerialData>, String> {
  @override
  Future<List<SerialData>> build(String arg) async {
    final repository = ref.watch(itemRepositoryProvider);
    return repository.getItemSerials(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => build(arg));
  }
}

// Provider for batch data
final itemBatchesProvider =
    AsyncNotifierProvider.family<ItemBatchesNotifier, List<BatchData>, String>(
      ItemBatchesNotifier.new,
    );

class ItemBatchesNotifier extends FamilyAsyncNotifier<List<BatchData>, String> {
  @override
  Future<List<BatchData>> build(String arg) async {
    final repository = ref.watch(itemRepositoryProvider);
    return repository.getItemBatches(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => build(arg));
  }
}

// Provider for stock transactions
final stockTransactionsProvider =
    AsyncNotifierProvider.family<
      StockTransactionsNotifier,
      List<TransactionData>,
      String
    >(StockTransactionsNotifier.new);

class StockTransactionsNotifier
    extends FamilyAsyncNotifier<List<TransactionData>, String> {
  @override
  Future<List<TransactionData>> build(String arg) async {
    final repository = ref.watch(itemRepositoryProvider);
    return repository.getItemStockTransactions(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => build(arg));
  }
}

final itemWarehouseStocksProvider =
    AsyncNotifierProvider.family<
      ItemWarehouseStocksNotifier,
      List<WarehouseStockRow>,
      String
    >(ItemWarehouseStocksNotifier.new);

class ItemWarehouseStocksNotifier
    extends FamilyAsyncNotifier<List<WarehouseStockRow>, String> {
  @override
  Future<List<WarehouseStockRow>> build(String arg) async {
    final repository = ref.watch(itemRepositoryProvider);
    return repository.getItemWarehouseStocks(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => build(arg));
  }
}

final itemHistoryProvider =
    AsyncNotifierProvider.family<
      ItemHistoryNotifier,
      List<ItemHistoryEntry>,
      String
    >(ItemHistoryNotifier.new);

class ItemHistoryNotifier
    extends FamilyAsyncNotifier<List<ItemHistoryEntry>, String> {
  @override
  Future<List<ItemHistoryEntry>> build(String arg) async {
    final repository = ref.watch(itemRepositoryProvider);
    return repository.getItemHistory(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => build(arg));
  }
}
