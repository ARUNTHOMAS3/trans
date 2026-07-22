import '../models/branch_pricelist_model.dart';
import '../repositories/branch_pricelist_repository.dart';

class BranchPriceListService {
  final BranchPriceListRepository _repository;

  BranchPriceListService(this._repository);

  Future<List<BranchPriceList>> getAllBranchPriceLists() async {
    return await _repository.getBranchPriceLists();
  }

  Future<BranchPriceList> getBranchPriceListById(String id) async {
    return await _repository.getBranchPriceList(id);
  }

  Future<BranchPriceList> createBranchPriceList(
    BranchPriceList priceList,
  ) async {
    return await _repository.createBranchPriceList(priceList);
  }

  Future<BranchPriceList> updateBranchPriceList(
    BranchPriceList priceList,
  ) async {
    return await _repository.updateBranchPriceList(priceList);
  }

  Future<void> deleteBranchPriceList(String id) async {
    return await _repository.deleteBranchPriceList(id);
  }

  Future<void> deactivateBranchPriceList(String id) async {
    return await _repository.deactivateBranchPriceList(id);
  }

  /// Validate branch price list data before saving
  bool validateBranchPriceList(BranchPriceList priceList) {
    if (priceList.name.isEmpty) {
      return false;
    }

    if (priceList.pricingScheme.isEmpty) {
      return false;
    }

    // Additional validation based on pricing scheme
    if (priceList.pricingScheme == 'markup' ||
        priceList.pricingScheme == 'markdown') {
      try {
        final String safeDetails = priceList.details ?? '';
        final value = double.tryParse(safeDetails.replaceAll('%', ''));
        if (value == null || value < 0) {
          return false;
        }
      } catch (e) {
        return false;
      }
    }

    return true;
  }
}
