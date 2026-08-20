// FILE: lib/core/api/dio_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    if (_instance == null) {
      _instance = Dio(
        BaseOptions(
          baseUrl: _getBaseUrl(),
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // Add interceptors for logging in debug mode
      if (kDebugMode) {
        _instance!.interceptors.add(
          LogInterceptor(
            requestBody: true,
            responseBody: true,
            logPrint: (obj) => debugPrint(obj.toString()),
          ),
        );
      }

      // Add error interceptor
      _instance!.interceptors.add(
        InterceptorsWrapper(
          onError: (DioException e, ErrorInterceptorHandler handler) {
            debugPrint('API Error: ${e.message}');
            debugPrint('Error URL: ${e.requestOptions.uri}');
            debugPrint('Error Response: ${e.response?.data}');
            handler.next(e);
          },
        ),
      );
    }
    return _instance!;
  }

  static String _getBaseUrl() {
    String rawUrl;
    const envDefinedBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envDefinedBaseUrl.isNotEmpty) {
      rawUrl = envDefinedBaseUrl;
    } else if (const bool.fromEnvironment('dart.vm.product')) {
      rawUrl = 'https://d18ibzmbsnopg4.cloudfront.net';
    } else {
      rawUrl = 'http://127.0.0.1:3001';
    }

    rawUrl = rawUrl.trim().replaceFirst(RegExp(r'/$'), '');

    if (rawUrl.contains('/api/v1')) {
      return rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
    }
    return '$rawUrl/api/v1/';
  }
}

// Provider for Riverpod
final dioProvider = Provider<Dio>((ref) => DioClient.instance);
