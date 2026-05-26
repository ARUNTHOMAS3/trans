import '../models/inventory_package_model.dart';

abstract class InventoryPackageRepository {
  Future<List<InventoryPackage>> getPackages({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  });

  Future<InventoryPackage?> getPackage(String id);

  Future<InventoryPackage> createPackage(Map<String, dynamic> data);

  Future<InventoryPackage?> updatePackage(String id, Map<String, dynamic> data);

  Future<bool> deletePackage(String id);

  Future<Map<String, dynamic>> getNextNumber();

  Future<void> updateNextNumberSettings({
    required String prefix,
    required int nextNumber,
    bool isAuto = true,
  });
}
