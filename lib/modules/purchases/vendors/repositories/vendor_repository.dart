import '../models/purchases_vendors_vendor_model.dart';

abstract class VendorRepository {
  Future<List<Vendor>> getAllVendors({int page = 1, int limit = 100, String? search});
  Future<Vendor?> getVendorById(String id);
  Future<Vendor> createVendor(Vendor vendor);
  Future<Vendor> updateVendor(String id, Vendor vendor);
  Future<void> deleteVendor(String id);
}