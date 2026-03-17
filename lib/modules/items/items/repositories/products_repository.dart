import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/modules/items/items/services/products_api_service.dart';
import 'package:zerpai_erp/core/services/hive_service.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';

class ProductsRepository {
  final ProductsApiService _apiService;
  final HiveService _hiveService;

  ProductsRepository({ProductsApiService? apiService, HiveService? hiveService})
    : _apiService = apiService ?? ProductsApiService(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch products - Online-first with offline fallback
  Future<List<Item>> getProducts({bool forceRefresh = false}) async {
    try {
      // Online-first: Fetch from API
      final products = await _apiService.getProducts();

      // Cache to Hive for offline access
      await _hiveService.saveProducts(products);

      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('products');

      return products;
    } catch (e) {
      // Offline fallback: Return cached data
      debugPrint('⚠️ API fetch failed, using cached products: $e');

      final cachedItems = _hiveService.getProducts();

      if (cachedItems.isEmpty) {
        rethrow;
      }

      return cachedItems;
    }
  }

  /// Get single product by ID
  Future<Item?> getProduct(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getProduct(id);
    if (cached != null) {
      return cached;
    }

    // Not in cache, fetch from API
    try {
      final product = await _apiService.getProductById(id);
      await _hiveService.saveProduct(product);
      return product;
    } catch (e) {
      debugPrint('⚠️ Failed to fetch product $id: $e');
      return null;
    }
  }

  /// Create new product
  Future<Item> createProduct(Item item) async {
    try {
      // Save to API
      final createdProduct = await _apiService.createProduct(item);

      // Cache locally
      await _hiveService.saveProduct(createdProduct);

      return createdProduct;
    } catch (e) {
      debugPrint('❌ Failed to create product: $e');
      rethrow;
    }
  }

  /// Update existing product
  Future<Item> updateProduct(String id, Item item) async {
    try {
      // Update API
      final updatedProduct = await _apiService.updateProduct(id, item);

      // Update cache
      await _hiveService.saveProduct(updatedProduct);

      return updatedProduct;
    } catch (e) {
      debugPrint('❌ Failed to update product $id: $e');
      rethrow;
    }
  }

  /// Delete product
  Future<void> deleteProduct(String id) async {
    try {
      // Delete from API
      await _apiService.deleteProduct(id);

      // Remove from cache
      await _hiveService.deleteProduct(id);
    } catch (e) {
      debugPrint('❌ Failed to delete product $id: $e');
      rethrow;
    }
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('products');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('products');
    final stats = _hiveService.getCacheStats();

    return {
      'cached_products': stats['products'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }

  /// Clear product cache
  Future<void> clearCache() async {
    final box = _hiveService.productsBox;
    await box.clear();
  }
}
