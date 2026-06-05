import '../models/pricelist_model.dart';
import '../repositories/pricelist_repository.dart';

class PriceListService {
  final PriceListRepository _repository;

  PriceListService(this._repository);

  Future<List<PriceList>> getAllPriceLists() async {
    return await _repository.getPriceLists();
  }

  Future<PriceList> getPriceListById(String id) async {
    return await _repository.getPriceList(id);
  }

  Future<PriceList> createPriceList(PriceList priceList) async {
    return await _repository.createPriceList(priceList);
  }

  Future<PriceList> updatePriceList(PriceList priceList) async {
    return await _repository.updatePriceList(priceList);
  }

  Future<void> deletePriceList(String id) async {
    return await _repository.deletePriceList(id);
  }

  Future<void> deactivatePriceList(String id) async {
    return await _repository.deactivatePriceList(id);
  }

  /// Validate price list data before saving
  bool validatePriceList(PriceList priceList) {
    if (priceList.name.isEmpty) {
      return false;
    }
    
    if (priceList.pricingScheme.isEmpty) {
      return false;
    }
    
    // Additional validation based on pricing scheme
    if (priceList.pricingScheme == 'markup' || priceList.pricingScheme == 'markdown') {
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
