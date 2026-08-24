import 'package:dio/dio.dart';
import '../models/document_model.dart';

abstract class DocumentsRepository {
  Future<Map<String, dynamic>> getDocuments({
    String? orgId,
    int page = 1,
    int limit = 10,
    String? search,
    String? type,
    String? sort,
    String? order,
    String? folder,
  });
}

class ApiDocumentsRepository implements DocumentsRepository {
  final Dio _dio;

  ApiDocumentsRepository(this._dio);

  @override
  Future<Map<String, dynamic>> getDocuments({
    String? orgId,
    int page = 1,
    int limit = 10,
    String? search,
    String? type,
    String? sort,
    String? order,
    String? folder,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'limit': limit,
    };
    
    if (search != null && search.isNotEmpty) queryParameters['search'] = search;
    if (type != null && type.isNotEmpty && type != 'All') queryParameters['type'] = type;
    if (sort != null && sort.isNotEmpty) queryParameters['sort'] = sort;
    if (order != null && order.isNotEmpty) queryParameters['order'] = order;
    if (folder != null && folder.isNotEmpty && folder != 'All Documents') queryParameters['folder'] = folder;

    final response = await _dio.get(
      'documents',
      queryParameters: queryParameters,
    );
    
    // The Dio interceptor already unwraps `{ data, meta }` 
    // and places `data` in `response.data` and `meta` in `response.extra['meta']`.
    final dataList = (response.data as List<dynamic>?) ?? [];
    final meta = response.extra['meta'] as Map<String, dynamic>? ?? {};

    return {
      'data': dataList.map((e) => DocumentModel.fromJson(e)).toList(),
      'meta': meta,
    };
  }
}
