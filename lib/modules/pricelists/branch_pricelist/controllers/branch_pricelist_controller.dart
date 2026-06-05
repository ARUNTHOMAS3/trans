import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/branch_pricelist_model.dart';
import '../services/branch_pricelist_service.dart';

class BranchPriceListNotifier extends StateNotifier<AsyncValue<List<BranchPriceList>>> {
  final BranchPriceListService _service;

  BranchPriceListNotifier(this._service, {required bool isAuthenticated})
      : super(const AsyncValue.loading()) {
    if (isAuthenticated) fetchBranchPriceLists();
  }

  Future<void> fetchBranchPriceLists() async {
    state = const AsyncValue.loading();
    try {
      final priceLists = await _service.getAllBranchPriceLists();
      state = AsyncValue.data(priceLists);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> bulkDeleteBranchPriceLists(List<String> ids) async {
    try {
      for (final id in ids) {
        await _service.deleteBranchPriceList(id);
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

  Future<void> bulkActivateBranchPriceLists(List<String> ids) async {
    try {
      final current = state.valueOrNull;
      if (current != null) {
        for (final id in ids) {
          final matchIndex = current.indexWhere((pl) => pl.id == id);
          if (matchIndex == -1) continue;
          final match = current[matchIndex];
          await _service.updateBranchPriceList(match.copyWith(status: 'active'));
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

  Future<void> bulkDeactivateBranchPriceLists(List<String> ids) async {
    try {
      for (final id in ids) {
        await _service.deactivateBranchPriceList(id);
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

  Future<void> createBranchPriceList(BranchPriceList priceList) async {
    try {
      final createdPriceList = await _service.createBranchPriceList(priceList);
      state.whenData((priceLists) {
        state = AsyncValue.data([...priceLists, createdPriceList]);
      });
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> updateBranchPriceList(BranchPriceList priceList) async {
    try {
      final updatedPriceList = await _service.updateBranchPriceList(priceList);
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

  Future<void> deleteBranchPriceList(String id) async {
    try {
      await _service.deleteBranchPriceList(id);
      state.whenData((priceLists) {
        final updatedLists = priceLists.where((pl) => pl.id != id).toList();
        state = AsyncValue.data(updatedLists);
      });
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> deactivateBranchPriceList(String id) async {
    try {
      await _service.deactivateBranchPriceList(id);
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

  Future<BranchPriceList?> fetchBranchPriceListById(String id) async {
    try {
      return await _service.getBranchPriceListById(id);
    } catch (e) {
      return null;
    }
  }
}







