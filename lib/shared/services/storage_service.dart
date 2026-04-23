import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/api_client.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  StorageService._internal();

  Future<List<String>> uploadProductImages(List<PlatformFile> files) async {
    final urls = <String>[];

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      if (file.bytes == null) continue;

      try {
        final fileName =
            'product_${DateTime.now().millisecondsSinceEpoch}_$i.${file.extension ?? 'jpg'}';
        final url = await _uploadViaBackend(
          fileName: fileName,
          fileBytes: file.bytes!,
          mimeType: 'image/${file.extension ?? 'jpeg'}',
          prefix: 'products',
        );
        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        debugPrint('Error uploading product image: $e');
      }
    }

    return urls;
  }

  Future<String?> uploadLocationLogo(PlatformFile file) async {
    if (file.bytes == null) return null;

    return _uploadViaBackend(
      fileName:
          'logo_${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? 'jpg'}',
      fileBytes: file.bytes!,
      mimeType: 'image/${file.extension ?? 'jpeg'}',
      prefix: 'branch-logos',
    );
  }

  Future<String?> uploadLicenseDocument(PlatformFile file) async {
    if (file.bytes == null) return null;

    final ext = file.extension?.toLowerCase();
    String contentType = 'application/octet-stream';
    if (ext == 'pdf') {
      contentType = 'application/pdf';
    } else if (ext == 'jpg' || ext == 'jpeg') {
      contentType = 'image/jpeg';
    } else if (ext == 'png') {
      contentType = 'image/png';
    }

    try {
      return await _uploadViaBackend(
        fileName: '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
        fileBytes: file.bytes!,
        mimeType: contentType,
        prefix: 'licenses',
      );
    } catch (e) {
      debugPrint('Error uploading license document: $e');
      return null;
    }
  }

  Future<void> deleteProductImage(String url) async {
    try {
      await ApiClient().delete(
        'lookups/uploads',
        data: {'fileUrl': url},
      );
    } on DioException catch (e) {
      debugPrint('Error deleting file: ${e.error ?? e.message}');
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  Future<String?> _uploadViaBackend({
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    required String prefix,
  }) async {
    final response = await ApiClient().post(
      'lookups/uploads',
      data: {
        'fileName': fileName,
        'fileData': base64Encode(fileBytes),
        'mimeType': mimeType,
        'prefix': prefix,
      },
    );

    final data = response.data;
    if (data is Map && data['fileUrl'] != null) {
      return data['fileUrl'].toString();
    }

    return null;
  }

  // ── Cloudflare Image Resizing ─────────────────────────────────────────────

  static String transformImageUrl(
    String originalUrl, {
    int width = 800,
    int quality = 90,
    String fit = 'contain',
  }) {
    if (originalUrl.isEmpty) return originalUrl;
    try {
      final uri = Uri.parse(originalUrl);
      final options = 'width=$width,quality=$quality,fit=$fit';
      final newPath = '/cdn-cgi/image/$options${uri.path}';
      return uri.replace(path: newPath).toString();
    } catch (_) {
      return originalUrl;
    }
  }

  static String thumbnailUrl(String originalUrl) {
    return transformImageUrl(
      originalUrl,
      width: 150,
      quality: 75,
      fit: 'contain',
    );
  }
}
