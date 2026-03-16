import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  StorageService._internal();

  final Dio _dio = Dio();

  String get _accountId => dotenv.env['CLOUDFLARE_ACCOUNT_ID'] ?? '';
  String get _accessKeyId => dotenv.env['CLOUDFLARE_ACCESS_KEY_ID'] ?? '';
  String get _secretAccessKey =>
      dotenv.env['CLOUDFLARE_SECRET_ACCESS_KEY'] ?? '';
  String get _bucketName => dotenv.env['CLOUDFLARE_BUCKET_NAME'] ?? '';
  String get _endpoint =>
      'https://$_accountId.r2.cloudflarestorage.com/$_bucketName';

  Future<List<String>> uploadProductImages(List<PlatformFile> files) async {
    final urls = <String>[];

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      if (file.bytes == null) continue;

      try {
        final fileName =
            'products/${DateTime.now().millisecondsSinceEpoch}_$i.${file.extension}';
        final url = await _uploadToR2(fileName, file.bytes!, file.extension);
        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        debugPrint('Error uploading file: $e');
      }
    }

    return urls;
  }

  Future<String?> _uploadToR2(
    String objectName,
    Uint8List fileBytes,
    String? extension,
  ) async {
    final DateTime now = DateTime.now().toUtc();
    final String dateStr = _formatDate(now); // YYYYMMDD
    final String timestamp = _formatTimestamp(now); // YYYYMMDDTHHMMSSZ
    final String region = 'auto';
    final String service = 's3';

    final String host = '$_accountId.r2.cloudflarestorage.com';
    final String url = 'https://$host/$_bucketName/$objectName';

    // 1. Canonical Request
    final String method = 'PUT';
    final String canonicalUri = '/$_bucketName/$objectName';
    final String canonicalQueryString = '';
    final String payloadHash = sha256.convert(fileBytes).toString();

    final String canonicalHeaders =
        'host:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$timestamp\n';
    final String signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

    final String canonicalRequest =
        '$method\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    // 2. String to Sign
    final String algorithm = 'AWS4-HMAC-SHA256';
    final String credentialScope = '$dateStr/$region/$service/aws4_request';
    final String stringToSign =
        '$algorithm\n$timestamp\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

    // 3. Signing Key
    final List<int> kDate = Hmac(
      sha256,
      utf8.encode('AWS4$_secretAccessKey'),
    ).convert(utf8.encode(dateStr)).bytes;
    final List<int> kRegion = Hmac(
      sha256,
      kDate,
    ).convert(utf8.encode(region)).bytes;
    final List<int> kService = Hmac(
      sha256,
      kRegion,
    ).convert(utf8.encode(service)).bytes;
    final List<int> kSigning = Hmac(
      sha256,
      kService,
    ).convert(utf8.encode('aws4_request')).bytes;

    // 4. Signature
    final String signature = Hmac(
      sha256,
      kSigning,
    ).convert(utf8.encode(stringToSign)).toString();

    // 5. Authorization Header
    final String authorization =
        '$algorithm Credential=$_accessKeyId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    try {
      await _dio.put(
        url,
        data: fileBytes,
        options: Options(
          headers: {
            'Authorization': authorization,
            'x-amz-date': timestamp,
            'x-amz-content-sha256': payloadHash,
            'Content-Type': 'image/$extension',
          },
        ),
      );

      // Return Public URL (or authenticated URL depending on bucket setting)
      // Assuming public access is enabled or using custom domain.
      // If no custom domain, accessing via R2 requires auth or public bucket.
      // For now returning the user-provided endpoint format, assuming public read.
      // Note: R2 usually needs a custom domain for public access without S3 client.
      // The user gave: https://56ed...r2.cloudflarestorage.com
      // We will return that, but usually that requires auth to READ too.
      // If the user setup a custom domain, we should use that.
      // I'll return the full R2 path for now.
      return '$_endpoint/$objectName';
    } catch (e) {
      debugPrint('R2 Upload failed: $e');
      return null;
    }
  }

  Future<void> deleteProductImage(String url) async {
    try {
      // Extract object name from URL
      final uri = Uri.parse(url);
      final objectName = uri.pathSegments
          .sublist(1)
          .join('/'); // Skip bucket name

      final DateTime now = DateTime.now().toUtc();
      final String dateStr = _formatDate(now);
      final String timestamp = _formatTimestamp(now);
      final String region = 'auto';
      final String service = 's3';
      final String host = '$_accountId.r2.cloudflarestorage.com';

      // 1. Canonical Request
      final String method = 'DELETE';
      final String canonicalUri = '/$_bucketName/$objectName';
      final String canonicalQueryString = '';
      final String payloadHash = sha256
          .convert(utf8.encode(''))
          .toString(); // Empty body

      final String canonicalHeaders =
          'host:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$timestamp\n';
      final String signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

      final String canonicalRequest =
          '$method\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

      // 2. String to Sign
      final String algorithm = 'AWS4-HMAC-SHA256';
      final String credentialScope = '$dateStr/$region/$service/aws4_request';
      final String stringToSign =
          '$algorithm\n$timestamp\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

      // 3. Signing Key (Reuse helper if possible, but for now duplicate for safety / independence)
      final List<int> kDate = Hmac(
        sha256,
        utf8.encode('AWS4$_secretAccessKey'),
      ).convert(utf8.encode(dateStr)).bytes;
      final List<int> kRegion = Hmac(
        sha256,
        kDate,
      ).convert(utf8.encode(region)).bytes;
      final List<int> kService = Hmac(
        sha256,
        kRegion,
      ).convert(utf8.encode(service)).bytes;
      final List<int> kSigning = Hmac(
        sha256,
        kService,
      ).convert(utf8.encode('aws4_request')).bytes;

      // 4. Signature
      final String signature = Hmac(
        sha256,
        kSigning,
      ).convert(utf8.encode(stringToSign)).toString();

      // 5. Authorization Header
      final String authorization =
          '$algorithm Credential=$_accessKeyId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

      final requestUrl = 'https://$host/$_bucketName/$objectName';

      await _dio.delete(
        requestUrl,
        options: Options(
          headers: {
            'Authorization': authorization,
            'x-amz-date': timestamp,
            'x-amz-content-sha256': payloadHash,
          },
        ),
      );
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  // ── Cloudflare Image Resizing ─────────────────────────────────────────────

  /// Rewrites [originalUrl] to route through Cloudflare's Image Resizing CDN.
  ///
  /// Inserts `/cdn-cgi/image/<options>/` before the image path so that
  /// Cloudflare's edge servers resize the image on the fly.
  ///
  /// Requirements: the R2 bucket must be served through a Cloudflare Worker or
  /// a custom domain that is proxied (orange-cloud) in Cloudflare DNS, and the
  /// "Image Resizing" feature must be enabled for the zone.
  ///
  /// Usage:
  ///   // Full-quality display
  ///   StorageService.transformImageUrl(url, width: 800, quality: 90)
  ///
  ///   // Thumbnail for list / grid views
  ///   StorageService.thumbnailUrl(url)
  static String transformImageUrl(
    String originalUrl, {
    int width = 800,
    int quality = 90,
    String fit = 'contain',
  }) {
    if (originalUrl.isEmpty) return originalUrl;
    try {
      final uri = Uri.parse(originalUrl);
      // Build /cdn-cgi/image/<options>/<original-path>
      final options = 'width=$width,quality=$quality,fit=$fit';
      final newPath = '/cdn-cgi/image/$options${uri.path}';
      return uri.replace(path: newPath).toString();
    } catch (_) {
      return originalUrl;
    }
  }

  /// Convenience method for thumbnail-sized images (list / grid views).
  /// width=150, quality=75, fit=contain.
  static String thumbnailUrl(String originalUrl) {
    return transformImageUrl(
      originalUrl,
      width: 150,
      quality: 75,
      fit: 'contain',
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";
  }

  String _formatTimestamp(DateTime date) {
    return "${_formatDate(date)}T${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}Z";
  }
}
