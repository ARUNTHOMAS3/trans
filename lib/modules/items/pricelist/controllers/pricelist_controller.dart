import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pricelist_model.dart';
import '../services/pricelist_service.dart';

class PriceListNotifier extends StateNotifier<AsyncValue<List<PriceList>>> {
  final PriceListService _service;

  PriceListNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchPriceLists();
  }

  Future<void> fetchPriceLists() async {
    state = const AsyncValue.loading();
    try {
      final priceLists = await _service.getAllPriceLists();
      state = AsyncValue.data(priceLists);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> bulkDeletePriceLists(List<String> ids) async {
    try {
      for (final id in ids) {
        await _service.deletePriceList(id);
      }
      state.whenData((priceLists) {
        state = AsyncValue.data(
          priceLists.where((pl) => !ids.contains(pl.id)).toList(),
        );
      });
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> bulkActivatePriceLists(List<String> ids) async {
    try {
      final current = state.valueOrNull;
      if (current != null) {
        for (final id in ids) {
          final matchIndex = current.indexWhere((pl) => pl.id == id);
          if (matchIndex == -1) continue;
          final match = current[matchIndex];
          await _service.updatePriceList(match.copyWith(status: 'active'));
        }
      }

      state.whenData((priceLists) {
        state = AsyncValue.data(
          priceLists
              .map(
                (pl) =>
                    ids.contains(pl.id) ? pl.copyWith(status: 'active') : pl,
              )
              .toList(),
        );
      });
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> bulkDeactivatePriceLists(List<String> ids) async {
    try {
      for (final id in ids) {
        await _service.deactivatePriceList(id);
      }
      state.whenData((priceLists) {
        state = AsyncValue.data(
          priceLists
              .map(
                (pl) =>
                    ids.contains(pl.id) ? pl.copyWith(status: 'inactive') : pl,
              )
              .toList(),
        );
      });
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> createPriceList(PriceList priceList) async {
    try {
      final createdPriceList = await _service.createPriceList(priceList);
      state.whenData((priceLists) {
        state = AsyncValue.data([...priceLists, createdPriceList]);
      });
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> updatePriceList(PriceList priceList) async {
    try {
      final updatedPriceList = await _service.updatePriceList(priceList);
      state.whenData((priceLists) {
        final updatedLists = priceLists.map((pl) {
          if (pl.id == updatedPriceList.id) {
            return updatedPriceList;
          }
          return pl;
        }).toList();
        state = AsyncValue.data(updatedLists);
      });
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> deletePriceList(String id) async {
    try {
      await _service.deletePriceList(id);
      state.whenData((priceLists) {
        final updatedLists = priceLists.where((pl) => pl.id != id).toList();
        state = AsyncValue.data(updatedLists);
      });
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> deactivatePriceList(String id) async {
    try {
      await _service.deactivatePriceList(id);
      state.whenData((priceLists) {
        final updatedLists = priceLists.map((pl) {
          if (pl.id == id) {
            return pl.copyWith(status: 'inactive');
          }
          return pl;
        }).toList();
        state = AsyncValue.data(updatedLists);
      });
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<PriceList?> fetchPriceListById(String id) async {
    try {
      return await _service.getPriceListById(id);
    } catch (e) {
      return null;
    }
  }
}

/// Provider for the search query state
