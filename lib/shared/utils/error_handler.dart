import 'package:dio/dio.dart';

class ErrorHandler {
  static String getFriendlyMessage(dynamic e) {
    if (e is DioException) {
      // Check if ApiClient enhanced the error
      if (e.error is Map<String, dynamic>) {
        final errorMap = e.error as Map<String, dynamic>;
        return errorMap['message'] ?? 'Something went wrong. Please try again.';
      }

      // Check response data directly
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        final msg = data['message'] ?? data['error'];
        if (msg != null) {
          if (msg is List) return msg.join(', ');
          return msg.toString();
        }
      }

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your internet.';
        case DioExceptionType.connectionError:
          return 'No internet connection.';
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          if (status == 400) return 'Invalid request. Please check your data.';
          if (status == 401) return 'Unauthorized. Please login again.';
          if (status == 403) return 'You do not have permission for this action.';
          if (status == 404) return 'Resource not found.';
          if (status == 500) return 'Server error. Our team is looking into it.';
          return 'Server returned an error ($status).';
        default:
          return 'Network error. Please try again.';
      }
    }

    final errorMessage = e.toString();
    if (errorMessage.contains('Exception:')) {
      return errorMessage.replaceFirst('Exception:', '').trim();
    }
    
    return 'An unexpected error occurred.';
  }
}
