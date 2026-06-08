import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';
import 'package:zerpai_erp/core/errors/app_exceptions.dart';

class ProductsApiService {
  final ApiClient _apiClient = ApiClient();
  static final Set<String> _missingProductTxnEndpoints = <String>{};
  static const Set<String> _removedProductKeys = <String>{
    'rack_id',
  };

  Map<String, dynamic> _sanitizeProductPayload(Map<String, dynamic> input) {
    final payload = Map<String, dynamic>.from(input);
    for (final key in _removedProductKeys) {
      payload.remove(key);
    }
    return payload;
  }

  dynamic _unwrapEnvelope(dynamic payload) {
    if (payload is Map && payload.containsKey('data')) {
      return payload['data'];
    }
    return payload;
  }

  Map<String, dynamic> _asMap(dynamic payload) {
    final unwrapped = _unwrapEnvelope(payload);
    if (unwrapped is Map) {
      return Map<String, dynamic>.from(unwrapped);
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic payload) {
    final unwrapped = _unwrapEnvelope(payload);
    if (unwrapped is List) {
      return List<dynamic>.from(unwrapped);
    }
    return const <dynamic>[];
  }

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
        final data = _asList(response.data);
        return data
            .map((json) => Item.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
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
        final responseData = _unwrapEnvelope(response.data);
        debugPrint(
          '[getProductsCursor] response type: ${responseData.runtimeType}',
        );

        // Handle new cursor-format: {items: [...], next_cursor: ...}
        if (responseData is Map && responseData.containsKey('items')) {
          final responseMap = Map<String, dynamic>.from(responseData);
          final List<dynamic> data = List<dynamic>.from(
            responseMap['items'] as List? ?? const [],
          );
          debugPrint('[getProductsCursor] cursor-format: ${data.length} items');
          return {
            'items': data
                .map(
                  (json) => Item.fromJson(
                    Map<String, dynamic>.from(json as Map),
                  ),
                )
                .toList(),
            'next_cursor': responseMap['next_cursor']?.toString(),
          };
        }

        // Handle legacy plain-array format (fallback safety)
        if (responseData is List) {
          debugPrint(
            '[getProductsCursor] plain-list fallback: ${responseData.length} items',
          );
          final List<dynamic> data = List<dynamic>.from(responseData);
          return {
            'items': data
                .map(
                  (json) => Item.fromJson(
                    Map<String, dynamic>.from(json as Map),
                  ),
                )
                .toList(),
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
        final payload = response.data;
        List<dynamic> rows;
        if (payload is List) {
          rows = payload;
        } else if (payload is Map<String, dynamic>) {
          final dataNode = payload['data'];
          if (dataNode is List) {
            rows = dataNode;
          } else {
            rows = const <dynamic>[];
          }
        } else {
          rows = const <dynamic>[];
        }
        return rows
            .whereType<Map<String, dynamic>>()
            .map((json) => Item.fromJson(json))
            .toList();
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
        final payload = _asMap(response.data);
        final count = payload['count'];
        if (count is int) return count;
        return int.tryParse(count?.toString() ?? '') ?? 0;
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
      final data = _sanitizeProductPayload(item.toJson());
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
      final data = _sanitizeProductPayload(item.toJson());
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
    for (final key in _removedProductKeys) {
      changesMap.remove(key);
    }
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
        final payload = response.data;
        List<dynamic> rows;
        if (payload is List) {
          rows = payload;
        } else if (payload is Map<String, dynamic>) {
          final dataNode = payload['data'];
          if (dataNode is List) {
            rows = dataNode;
          } else {
            rows = const <dynamic>[];
          }
        } else {
          rows = const <dynamic>[];
        }
        return rows.whereType<Map<String, dynamic>>().toList();
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
      final sanitized = _sanitizeProductPayload(productData);
      final response = await _apiClient.post('/products', data: sanitized);

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
      final sanitized = _sanitizeProductPayload(productData);
      final response = await _apiClient.put('/products/$id', data: sanitized);

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

  Future<List<WarehouseStockRow>> getProductWarehouseStocks(
    String productId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/products/$productId/warehouse-stocks',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = _extractWarehouseStockRows(response.data);
        return data
            .map(
              (json) => WarehouseStockRow.fromJson(
                Map<String, dynamic>.from(json as Map),
              ),
            )
            .toList();
      }

      throw ApiException(
        'Failed to load warehouse stocks',
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
      throw ApiException('Error loading warehouse stocks: $e');
    }
  }

  Future<List<WarehouseStockRow>> updateProductWarehouseStocks(
    String productId,
    List<WarehouseStockRow> rows,
  ) async {
    try {
      final response = await _apiClient.put(
        '/products/$productId/warehouse-stocks',
        data: {'rows': rows.map((row) => row.toJson()).toList()},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = _extractWarehouseStockRows(response.data);
        return data
            .map(
              (json) => WarehouseStockRow.fromJson(
                Map<String, dynamic>.from(json as Map),
              ),
            )
            .toList();
      }

      throw ApiException(
        'Failed to update warehouse stocks',
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
      throw ApiException('Error updating warehouse stocks: $e');
    }
  }

  Future<List<WarehouseStockRow>> adjustProductWarehousePhysicalStock(
    String productId, {
    required String warehouseId,
    required double countedStock,
    required String reason,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/products/$productId/warehouse-stocks/physical-adjustments',
        data: {
          'warehouse_id': warehouseId,
          'counted_stock': countedStock,
          'reason': reason,
          'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = _extractWarehouseStockRows(response.data);
        return data
            .map(
              (json) => WarehouseStockRow.fromJson(
                Map<String, dynamic>.from(json as Map),
              ),
            )
            .toList();
      }

      throw ApiException(
        'Failed to adjust physical stock',
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
      throw ApiException('Error adjusting physical stock: $e');
    }
  }

  List<dynamic> _extractWarehouseStockRows(dynamic payload) {
    if (payload is List) {
      return payload;
    }
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) {
        return data;
      }
    }
    throw ApiException('Unexpected warehouse stock response format');
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

  Future<List<ItemHistoryEntry>> getProductHistory(String id) async {
    try {
      final response = await _apiClient.get('/products/$id/history');
      if (response.statusCode == 200) {
        final payload = response.data;
        final List<dynamic> data;
        if (payload is List) {
          data = payload;
        } else if (payload is Map<String, dynamic> && payload['data'] is List) {
          data = payload['data'] as List<dynamic>;
        } else {
          return [];
        }

        return data
            .whereType<Map>()
            .map(
              (entry) =>
                  ItemHistoryEntry.fromJson(Map<String, dynamic>.from(entry)),
            )
            .toList();
      }
      throw ApiException(
        'Failed to load product history',
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
      throw ApiException('Error loading product history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProductBatches(
    String id, {
    String? warehouseId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if ((warehouseId ?? '').trim().isNotEmpty) {
        queryParameters['warehouse_id'] = warehouseId!.trim();
      }
      final response = await _apiClient.get(
        '/products/$id/batches',
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
      if (response.statusCode == 200) {
        final payload = response.data;
        if (payload is List) {
          return payload
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList();
        }
        if (payload is Map<String, dynamic>) {
          final dataNode = payload['data'];
          if (dataNode is List) {
            return dataNode
                .whereType<Map>()
                .map((entry) => Map<String, dynamic>.from(entry))
                .toList();
          }
        }
      }
      return [];
    } on DioException catch (e) {
      throw ApiException(
        _formatDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching product batches: $e');
    }
  }

  Future<List<TransactionData>> getProductStockTransactions(String id) async {
    try {
      double parseNum(dynamic value) {
        if (value is num) return value.toDouble();
        return double.tryParse((value ?? '0').toString()) ?? 0.0;
      }

      DateTime? parseDate(dynamic raw) {
        final text = (raw ?? '').toString().trim();
        if (text.isEmpty) return null;
        return DateTime.tryParse(text);
      }

      String formatDate(dynamic raw) {
        final parsed = parseDate(raw);
        if (parsed == null) return (raw ?? '').toString().trim();
        final day = parsed.day.toString().padLeft(2, '0');
        final month = parsed.month.toString().padLeft(2, '0');
        final year = parsed.year.toString();
        return '$day-$month-$year';
      }

      String cleanDisplayReference(dynamic value) {
        final text = (value ?? '').toString().trim();
        if (text.isEmpty) return '';
        final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        );
        if (uuidRegex.hasMatch(text)) return '';
        return text;
      }

      List<Map<String, dynamic>> extractRows(dynamic payload) {
        if (payload is List) {
          return payload
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (payload is Map<String, dynamic>) {
          final candidates = <dynamic>[
            payload['data'],
            payload['items'],
            payload['rows'],
            payload['results'],
            payload['salesOrders'],
            payload['sales_orders'],
            payload['purchaseOrders'],
            payload['purchase_orders'],
            payload['invoices'],
            payload['deliveryChallans'],
            payload['delivery_challans'],
            payload['creditNotes'],
            payload['credit_notes'],
            payload['vendorCredits'],
            payload['vendor_credits'],
            payload['bills'],
          ];
          for (final nested in candidates) {
            if (nested is List) {
              return nested
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            }
            if (nested is Map<String, dynamic>) {
              final nestedListCandidates = <dynamic>[
                nested['data'],
                nested['items'],
                nested['rows'],
                nested['results'],
                nested['list'],
              ];
              for (final inner in nestedListCandidates) {
                if (inner is List) {
                  return inner
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();
                }
              }
            }
          }
        }
        return const <Map<String, dynamic>>[];
      }

      bool hasProductInLines(Map<String, dynamic> row) {
        final dynamic lines =
            row['line_items'] ??
            row['lineItems'] ??
            row['items'] ??
            row['product_items'] ??
            row['productItems'];
        if (lines is! List) return false;
        for (final line in lines.whereType<Map>()) {
          final map = Map<String, dynamic>.from(line);
          final candidate = (map['product_id'] ??
                  map['productId'] ??
                  (map['product'] is Map ? (map['product'] as Map)['id'] : null) ??
                  map['item_id'] ??
                  map['itemId'] ??
                  map['id'] ??
                  map['product_code'] ??
                  map['item_code'] ??
                  map['sku'])
              .toString()
              .trim();
          if (candidate == id) return true;
        }
        return false;
      }

      bool rowMatchesProduct(Map<String, dynamic> row) {
        final direct = (row['product_id'] ??
                row['productId'] ??
                row['item_id'] ??
                row['itemId'] ??
                row['product_code'] ??
                row['item_code'] ??
                row['sku'])
            ?.toString()
            .trim();
        if ((direct ?? '').isNotEmpty) return direct == id;
        final lineMatch = hasProductInLines(row);
        if (lineMatch) return true;
        // Some list endpoints return header-only rows; rely on backend filtering
        // when no product key exists in the payload.
        return true;
      }

      double extractLineQty(Map<String, dynamic> row) {
        final dynamic lines =
            row['line_items'] ??
            row['lineItems'] ??
            row['items'] ??
            row['product_items'] ??
            row['productItems'];
        if (lines is! List) {
          return parseNum(
            row['quantity'] ??
                row['qty'] ??
                row['quantity_sold'] ??
                row['quantity_purchased'] ??
                row['quantity_adjusted'],
          );
        }
        var total = 0.0;
        for (final line in lines.whereType<Map>()) {
          final map = Map<String, dynamic>.from(line);
          final candidate = (map['product_id'] ??
                  map['productId'] ??
                  map['item_id'] ??
                  map['itemId'] ??
                  map['id'])
              .toString()
              .trim();
          if (candidate != id) continue;
          total += parseNum(
            map['quantity'] ??
                map['qty'] ??
                map['quantity_sold'] ??
                map['quantity_purchased'] ??
                map['quantity_adjusted'],
          );
        }
        return total;
      }

      Future<List<Map<String, dynamic>>> fetchEndpoint(
        String path,
        String docType,
      ) async {
        if (_missingProductTxnEndpoints.contains(path)) {
          return const [];
        }
        try {
          final response = await _apiClient.get(
            path,
            queryParameters: <String, dynamic>{
              'product_id': id,
              'productId': id,
              'limit': 200,
              'page': 1,
            },
          );
          if ((response.statusCode ?? 500) >= 400) return const [];
          final rows = extractRows(response.data);
          return rows
              .where(rowMatchesProduct)
              .map((row) => <String, dynamic>{...row, '__docType': docType})
              .toList();
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            _missingProductTxnEndpoints.add(path);
            return const [];
          }
          return const [];
        } catch (_) {
          return const [];
        }
      }

      TransactionData mapRow(Map<String, dynamic> row) {
        final docType = (row['__docType'] ?? '').toString();
        final qty = extractLineQty(row);
        final price = parseNum(
          row['rate'] ??
              row['price'] ??
              row['cost_price'] ??
              row['selling_price'] ??
              row['unit_price'],
        );
        final total = parseNum(row['total'] ?? row['amount'] ?? (qty * price));

        final rawDate =
            row['date'] ??
            row['transaction_date'] ??
            row['invoice_date'] ??
            row['order_date'] ??
            row['challan_date'] ??
            row['credit_note_date'] ??
            row['purchase_date'] ??
            row['bill_date'] ??
            row['adjustment_date'] ??
            row['created_at'];

        final docNo = cleanDisplayReference(
          row['reference_number'] ??
              row['order_number'] ??
              row['invoice_number'] ??
              row['challan_number'] ??
              row['credit_note_number'] ??
              row['purchase_order_number'] ??
              row['bill_number'] ??
              row['adjustment_number'] ??
              row['id'],
        );

        return TransactionData(
          date: formatDate(rawDate),
          documentNumber: docNo,
          customerName:
              (row['customer_name'] ?? row['customerName'] ?? row['customer'] ?? '')
                  .toString(),
          vendorName:
              (row['vendor_name'] ?? row['vendorName'] ?? row['vendor'] ?? '')
                  .toString(),
          locationName:
              (row['warehouse_name'] ?? row['location_name'] ?? '').toString(),
          sourceLocation:
              (row['source_location_name'] ?? row['source_warehouse_name'] ?? '')
                  .toString(),
          destinationLocation:
              (row['destination_location_name'] ??
                      row['destination_warehouse_name'] ??
                      '')
                  .toString(),
          reason: (row['reason_name'] ?? row['reason'] ?? '').toString(),
          description: (row['notes'] ?? row['description'] ?? '').toString(),
          transactionSubType: (row['sub_type'] ?? row['type'] ?? '').toString(),
          quantitySold: qty,
          price: price,
          total: total,
          status: (row['status'] ?? 'draft').toString(),
          documentType: docType,
          reference: (row['id'] ?? row['reference_number'])?.toString(),
          journalAccountId:
              (row['account_id'] ??
                      row['journal_account_id'] ??
                      row['ledger_account_id'])
                  ?.toString(),
          journalAccountName:
              (row['account_name'] ??
                      row['journal_account_name'] ??
                      row['ledger_account_name'] ??
                      row['user_account_name'] ??
                      row['system_account_name'])
                  ?.toString(),
        );
      }

      final endpointRows = await Future.wait<List<Map<String, dynamic>>>([
        fetchEndpoint('/sales-orders', 'salesOrders'),
        fetchEndpoint('/invoices', 'invoices'),
        fetchEndpoint('/delivery-challans', 'deliveryChallans'),
        fetchEndpoint('/credit-notes', 'creditNotes'),
        fetchEndpoint('/purchase-orders', 'purchaseOrders'),
        fetchEndpoint('/bills', 'bills'),
        fetchEndpoint('/vendor-credits', 'vendorCredits'),
        fetchEndpoint('/inventory-adjustments', 'inventoryAdjustments'),
      ]);

      final mapped = endpointRows
          .expand((rows) => rows)
          .map(mapRow)
          .toList();

      mapped.sort((a, b) {
        DateTime parseForSort(TransactionData tx) {
          final parsed = parseDate(tx.date);
          if (parsed != null) return parsed;
          final parts = tx.date.split('-');
          if (parts.length == 3) {
            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final year = int.tryParse(parts[2]);
            if (day != null && month != null && year != null) {
              return DateTime(year, month, day);
            }
          }
          return DateTime.fromMillisecondsSinceEpoch(0);
        }

        final bDate = parseForSort(b);
        final aDate = parseForSort(a);
        final dateCmp = bDate.compareTo(aDate);
        if (dateCmp != 0) return dateCmp;
        return (b.reference ?? '').compareTo(a.reference ?? '');
      });

      return mapped;
    } on DioException catch (e) {
      throw ApiException(
        _formatDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching product stock transactions: $e');
    }
  }

  // =====================================
  // PRICE LISTS
  // =====================================

  Future<List<Map<String, dynamic>>> getAssociatedPriceLists(
    String productId,
  ) async {
    try {
      final response = await _apiClient.get('/price-lists/product/$productId');
      if (response.statusCode == 200) {
        final payload = response.data;
        if (payload is List) {
          return payload
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (payload is Map<String, dynamic>) {
          final nested = payload['data'];
          if (nested is List) {
            return nested
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching associated price lists: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllPriceLists() async {
    try {
      final response = await _apiClient.get('/price-lists');
      if (response.statusCode == 200) {
        final payload = response.data;
        if (payload is List) {
          return payload
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (payload is Map<String, dynamic>) {
          final nested = payload['data'];
          if (nested is List) {
            return nested
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching all price lists: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> associatePriceList({
    required String productId,
    required String priceListId,
    double? customRate,
    double? discountPercentage,
  }) async {
    try {
      final response = await _apiClient.post(
        '/price-lists/associate',
        data: {
          'product_id': productId,
          'price_list_id': priceListId,
          if (customRate != null) 'custom_rate': customRate,
          if (discountPercentage != null)
            'discount_percentage': discountPercentage,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final payload = response.data;
        if (payload is Map<String, dynamic>) {
          if (payload['data'] is Map<String, dynamic>) {
            return payload['data'] as Map<String, dynamic>;
          }
          return payload;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error associating price list: $e');
      return null;
    }
  }
}
