import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';
import 'package:zerpai_erp/core/errors/app_exceptions.dart';

class ProductsApiService {
  final ApiClient _apiClient = ApiClient();

  String _formatDioError(DioException e) {
    final data = e.response?.data;
    final status = e.response?.statusCode;

    String joinConstraints(Map<dynamic, dynamic>? constraints) {
      if (constraints == null) return '';
      return constraints.values.map((c) => c.toString()).join(', ');
    }

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is List) {
        final details = message
            .map((m) {
              if (m is Map<String, dynamic>) {
                final field = m['field'];
                final constraints = m['constraints'] as Map<dynamic, dynamic>?;
                final value = m['value'];
                final constraintText = joinConstraints(constraints);
                final fieldLabel = field != null ? '$field: ' : '';
                final valueLabel = value != null ? ' (value: $value)' : '';
                return '$fieldLabel$constraintText$valueLabel'.trim();
              }
              return m.toString();
            })
            .join('; ');
        final prefix = data['error'] ?? 'Validation failed';
        return status != null
            ? '$prefix (HTTP $status): $details'
            : '$prefix: $details';
      }

      if (message is String && message.isNotEmpty) {
        return status != null ? 'HTTP $status: $message' : message;
      }
    }

    final fallback = e.message ?? 'Request failed';
    return status != null ? 'HTTP $status: $fallback' : fallback;
  }

  Future<List<Item>> getProducts({int? limit, int? offset}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _apiClient.get(
        '/products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => Item.fromJson(json)).toList();
      }

      throw ApiException(
        'Failed to load products',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        _formatDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching products: $e');
    }
  }

  Future<Map<String, dynamic>> getProductsCursor({
    int? limit,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _apiClient.get(
        '/products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        debugPrint(
          '[getProductsCursor] response type: ${responseData.runtimeType}',
        );

        // Handle new cursor-format: {items: [...], next_cursor: ...}
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('items')) {
          final List<dynamic> data = responseData['items'] as List;
          debugPrint('[getProductsCursor] cursor-format: ${data.length} items');
          return {
            'items': data.map((json) => Item.fromJson(json)).toList(),
            'next_cursor': responseData['next_cursor'],
          };
        }

        // Handle legacy plain-array format (fallback safety)
        if (responseData is List) {
          debugPrint(
            '[getProductsCursor] plain-list fallback: ${responseData.length} items',
          );
          final List<dynamic> data = responseData;
          return {
            'items': data.map((json) => Item.fromJson(json)).toList(),
            'next_cursor': null,
          };
        }

        debugPrint(
          '[getProductsCursor] unexpected response shape: $responseData',
        );
        throw ApiException('Unexpected response shape from /products');
      }

      throw ApiException(
        'Failed to load products via cursor',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      debugPrint(
        '[getProductsCursor] DioError: ${e.response?.statusCode} ${e.response?.data}',
      );
      throw ApiException(
        _formatDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('[getProductsCursor] Error: $e');
      throw ApiException('Error fetching cursor products: $e');
    }
  }

  Future<List<Item>> searchProducts(String query, {int limit = 30}) async {
    try {
      final response = await _apiClient.get(
        '/products/search',
        queryParameters: {'q': query, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => Item.fromJson(json)).toList();
      }

      throw ApiException(
        'Failed to search products',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        _formatDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error searching products: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBulkStock({
    required String outletId,
    required List<String> productIds,
  }) async {
    try {
      if (outletId.isEmpty || productIds.isEmpty) return [];

      final response = await _apiClient.post(
        '/outlet_inventory/bulk',
        data: {'outlet_id': outletId, 'product_ids': productIds},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['stocks'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      debugPrint('Error fetching bulk stock: $e');
      return [];
    }
  }

  Future<int> getProductsCount() async {
    try {
      final response = await _apiClient.get('/products/count');
      if (response.statusCode == 200) {
        return response.data['count'] as int;
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching products count: $e');
      return 0;
    }
  }

  Future<Item> getProductById(String id) async {
    try {
      final response = await _apiClient.get('/products/$id');

      if (response.statusCode == 200) {
        return Item.fromJson(response.data);
      }

      throw ApiException('Product not found', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw ApiException(
        _formatDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching product: $e');
    }
  }

  Future<Item> createProduct(Item item) async {
    try {
      final data = item.toJson();
      data.remove('id');
      data.remove('stock_on_hand');
      data.remove('opening_stock');
      data.remove('opening_stock_value');

      data['track_serial_number'] = item.trackSerialNumber;
      debugPrint('Sending product payload: $data');
      final response = await _apiClient.post('/products', data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Item.fromJson(response.data);
      }

      throw ApiException(
        'Failed to create product',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      debugPrint(
        'createProduct error response: ${e.response?.statusCode} -> $data',
      );
      throw ApiException(
        _formatDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error creating product: $e');
    }
  }

  Future<Item> updateProduct(String id, Item item) async {
    try {
      final data = item.toJson();
      data.remove('id');
      data.remove('stock_on_hand');
      data.remove('opening_stock');
      data.remove('opening_stock_value');

      data['track_serial_number'] = item.trackSerialNumber;
      data.removeWhere((key, value) => value == null);

      final response = await _apiClient.put('/products/$id', data: data);

      if (response.statusCode == 200) {
        return Item.fromJson(response.data);
      }

      throw Exception('Failed to update product');
    } on DioException catch (e) {
      final data = e.response?.data;
      debugPrint(
        'updateProduct error response: ${e.response?.statusCode} -> $data',
      );
      throw Exception('Error updating product: ${_formatDioError(e)}');
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  Future<int> updateProductsBulk(
    List<String> ids,
    Map<String, dynamic> changes,
  ) async {
    if (ids.isEmpty) return 0;

    final payload = <String, dynamic>{
      'ids': ids,
      'changes': Map<String, dynamic>.from(changes),
    };

    final changesMap = payload['changes'] as Map<String, dynamic>;
    changesMap.removeWhere((_, value) => value == null);

    try {
      final response = await _apiClient.put('/products/bulk', data: payload);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['count'] is int) {
          return data['count'] as int;
        }
        if (data is List) {
          return data.length;
        }
        return 0;
      }

      throw Exception('Failed to update products in bulk');
    } on DioException catch (e) {
      final data = e.response?.data;
      debugPrint(
        'updateProductsBulk error response: ${e.response?.statusCode} -> $data',
      );
      throw Exception('Error updating products: ${_formatDioError(e)}');
    } catch (e) {
      throw Exception('Error updating products: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await _apiClient.delete('/products/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProducts({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _apiClient.get(
        '/products',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.cast<Map<String, dynamic>>();
      }

      throw Exception('Failed to load products');
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchProductById(String id) async {
    try {
      final response = await _apiClient.get('/products/$id');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching product $id: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createProductFromMap(
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await _apiClient.post('/products', data: productData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Failed to create product');
    } on DioException catch (e) {
      throw Exception('Error creating product: ${_formatDioError(e)}');
    }
  }

  Future<Map<String, dynamic>> updateProductFromMap(
    String id,
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await _apiClient.put('/products/$id', data: productData);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Failed to update product');
    } on DioException catch (e) {
      throw Exception('Error updating product: ${_formatDioError(e)}');
    }
  }

  Future<Map<String, dynamic>> createCompositeProduct(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiClient.post(
        '/products/composite',
        data: payload,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create composite product');
    } on DioException catch (e) {
      throw Exception(
        'Error creating composite product: ${_formatDioError(e)}',
      );
    }
  }

  Future<List<CompositeItem>> getCompositeProducts() async {
    try {
      final response = await _apiClient.get('/products/composite');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => CompositeItem.fromJson(json)).toList();
      }

      throw ApiException(
        'Failed to load composite products',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        _formatDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching composite products: $e');
    }
  }

  Future<int> updateCompositeProductsBulk(
    List<String> ids,
    Map<String, dynamic> changes,
  ) async {
    if (ids.isEmpty) return 0;

    final payload = <String, dynamic>{
      'ids': ids,
      'changes': Map<String, dynamic>.from(changes),
    };

    try {
      final response = await _apiClient.put(
        '/products/composite/bulk',
        data: payload,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['count'] is int) {
          return data['count'] as int;
        }
        if (data is List) {
          return data.length;
        }
        return ids.length;
      }

      throw Exception('Failed to update composite products in bulk');
    } on DioException catch (e) {
      throw Exception(
        'Error updating composite products: ${_formatDioError(e)}',
      );
    } catch (e) {
      throw Exception('Error updating composite products: $e');
    }
  }

  Future<int> deleteCompositeProductsBulk(List<String> ids) async {
    if (ids.isEmpty) return 0;

    final payload = <String, dynamic>{'ids': ids};

    try {
      final response = await _apiClient.delete(
        '/products/composite/bulk',
        data: payload,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['count'] is int) {
          return data['count'] as int;
        }
        if (data is List) {
          return data.length;
        }
        return ids.length;
      }

      throw Exception('Failed to delete composite products in bulk');
    } on DioException catch (e) {
      throw Exception(
        'Error deleting composite products: ${_formatDioError(e)}',
      );
    } catch (e) {
      throw Exception('Error deleting composite products: $e');
    }
  }

  Future<void> updateOpeningStock(
    String productId,
    double openingStock,
    double openingStockValue,
  ) async {
    try {
      final response = await _apiClient.put(
        '/products/$productId/opening_stock',
        data: {
          'opening_stock': openingStock,
          'opening_stock_value': openingStockValue,
        },
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update opening stock',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        _formatDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error updating opening stock: $e');
    }
  }

  Future<Map<String, dynamic>> getProductQuickStats(String id) async {
    try {
      final response = await _apiClient.get('/products/$id/quick-stats');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(
        'Quick stats not found',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ApiException(
        _formatDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching product quick stats: $e');
    }
  }
}
