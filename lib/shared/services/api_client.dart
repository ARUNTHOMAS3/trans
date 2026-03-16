import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ------------------------------
/// CACHE MODEL
/// ------------------------------
class CachedResponse {
  final dynamic data;
  final DateTime timestamp;
  final int statusCode;

  CachedResponse({
    required this.data,
    required this.timestamp,
    required this.statusCode,
  });

  bool get isExpired => DateTime.now().difference(timestamp).inSeconds > 30;
}

/// ------------------------------
/// RESPONSE EXTENSIONS
/// ------------------------------
extension ResponseStandardizer on Response {
  bool get success {
    if (extra.containsKey('success')) {
      return extra['success'] == true;
    }
    return statusCode != null && statusCode! >= 200 && statusCode! < 300;
  }

  String? get message {
    final msg =
        extra['message'] ?? (data is Map ? (data as Map)['message'] : null);

    if (msg is List) return msg.join(', ');
    return msg?.toString();
  }
}

/// ------------------------------
/// PROVIDERS
/// ------------------------------
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);

/// ------------------------------
/// API CLIENT
/// ------------------------------
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  final Map<String, CachedResponse> _responseCache = {};

  /// ------------------------------
  /// CACHE HELPERS
  /// ------------------------------
  void _cleanupExpiredCache() {
    _responseCache.removeWhere((_, cached) => cached.isExpired);
  }

  CachedResponse? _getCachedResponse(String key) {
    _cleanupExpiredCache();
    return _responseCache[key];
  }

  void _cacheResponse(String key, dynamic data, int statusCode) {
    _responseCache[key] = CachedResponse(
      data: data,
      timestamp: DateTime.now(),
      statusCode: statusCode,
    );
  }

  void clearCache([String? path]) {
    if (path != null) {
      _responseCache.removeWhere((key, _) => key.contains(path));
    } else {
      _responseCache.clear();
    }
    if (kDebugMode) debugPrint('🗑️ Cache cleared');
  }

  String _generateCacheKey(
    String method,
    String url, [
    Map<String, dynamic>? query,
  ]) {
    final buffer = StringBuffer()..write('$method:$url');
    if (query != null && query.isNotEmpty) {
      final sorted = query.keys.toList()..sort();
      buffer.write('?${sorted.map((k) => '$k=${query[k]}').join('&')}');
    }
    return buffer.toString();
  }

  /// ------------------------------
  /// CONSTRUCTOR
  /// ------------------------------
  ApiClient._internal() {
    String rawBaseUrl;

    if (kReleaseMode) {
      rawBaseUrl = 'https://zabnix-backend.vercel.app';
    } else if (kDebugMode && kIsWeb) {
      rawBaseUrl = 'http://localhost:3001';
    } else {
      rawBaseUrl = const String.fromEnvironment('API_BASE_URL');
      if (rawBaseUrl.isEmpty) {
        rawBaseUrl =
            dotenv.maybeGet('API_BASE_URL') ??
            'https://zabnix-backend.vercel.app';
      }
    }

    rawBaseUrl = rawBaseUrl.trim().replaceFirst(RegExp(r'/$'), '');

    String baseUrl;
    if (rawBaseUrl.contains('/api/v1')) {
      baseUrl = rawBaseUrl.endsWith('/') ? rawBaseUrl : '$rawBaseUrl/';
    } else {
      baseUrl = '$rawBaseUrl/api/v1/';
    }

    if (kDebugMode) {
      debugPrint('🌐 API Base URL: $baseUrl');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-Request-ID'] = DateTime.now()
              .millisecondsSinceEpoch
              .toString();

          if (kDebugMode) {
            debugPrint('🚀 ${options.method} ${options.uri}');
            if (options.data != null) debugPrint('Body: ${options.data}');
          }

          handler.next(options);
        },

        onResponse: (response, handler) {
          final data = response.data;

          if (data is Map) {
            // Format 1: Standard wrapper with data and meta
            if (data.containsKey('data') && data.containsKey('meta')) {
              response.extra['meta'] = data['meta'];
              response.extra['message'] = data['message'];
              response.data = data['data'];
            }
            // Format 2: Success/Data wrapper
            else if (data.containsKey('success')) {
              if (data['success'] == true) {
                response.extra['success'] = true;
                response.extra['message'] = data['message'];
                response.data = data['data'];
              } else {
                return handler.reject(
                  DioException(
                    requestOptions: response.requestOptions,
                    response: response,
                    error: data['message'] ?? 'API failed',
                    type: DioExceptionType.badResponse,
                  ),
                );
              }
            }
          }

          handler.next(response);
        },

        onError: (error, handler) {
          String message = 'Unknown error';
          String code = 'UNKNOWN';

          if (error.response?.data is Map<String, dynamic>) {
            final data = error.response!.data as Map<String, dynamic>;

            final msg = data['message'] ?? data['error'] ?? data['errors'];

            if (msg is List) {
              message = msg.join(', ');
            } else if (msg is Map) {
              message = msg.values.join(', ');
            } else {
              message = msg?.toString() ?? message;
            }

            code = data['error_code'] ?? data['code'] ?? code;
          } else {
            switch (error.type) {
              case DioExceptionType.connectionTimeout:
                message = 'Connection timeout';
                code = 'TIMEOUT';
                break;
              case DioExceptionType.badCertificate:
                message = 'SSL error';
                code = 'SSL_ERROR';
                break;
              case DioExceptionType.receiveTimeout:
                message = 'Server timeout';
                code = 'SERVER_TIMEOUT';
                break;
              case DioExceptionType.cancel:
                message = 'Request cancelled';
                code = 'CANCELLED';
                break;
              default:
                message = 'Network error';
                code = 'NETWORK_ERROR';
            }
          }

          final enhanced = DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: {
              'message': message,
              'code': code,
              'time': DateTime.now().toIso8601String(),
              'url': error.requestOptions.uri.toString(),
            },
          );

          if (kDebugMode) {
            debugPrint('❌ $message ($code)');
          }

          handler.next(enhanced);
        },
      ),
    );
  }

  Dio get dio => _dio;

  String _normalizePath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  /// ------------------------------
  /// METHODS
  /// ------------------------------
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool useCache = true,
  }) async {
    final normalizedPath = _normalizePath(path);
    final key = _generateCacheKey('GET', normalizedPath, queryParameters);

    if (useCache) {
      final cached = _getCachedResponse(key);
      if (cached != null) {
        if (kDebugMode) debugPrint('⚡ Cache Hit: $normalizedPath');
        return Response(
          data: cached.data,
          statusCode: cached.statusCode,
          requestOptions: RequestOptions(path: normalizedPath),
        );
      }
    }

    final response = await _dio.get(
      normalizedPath,
      queryParameters: queryParameters,
    );

    if (useCache && response.statusCode == 200) {
      _cacheResponse(key, response.data, response.statusCode!);
    }

    return response;
  }

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(_normalizePath(path), data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(_normalizePath(path), data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(_normalizePath(path), data: data);

  Future<Response> delete(String path, {dynamic data}) =>
      _dio.delete(_normalizePath(path), data: data);
}
