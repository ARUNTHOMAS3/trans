import 'package:dio/dio.dart';

class ErrorHandler {
  static const String _accountTransactionsSchemaMessage =
      'We could not save the journal because the accounting transaction table is missing required fields. Contact support or update the database schema.';

  static String? _mapBackendMessage(String? message) {
    if (message == null) return null;

    final normalized = message.toLowerCase();
    final isAccountTransactionsInsert =
        normalized.contains('account_transactions') &&
        normalized.contains('failed query: insert into');
    final isSchemaMismatch =
        normalized.contains('contact_id') ||
        normalized.contains('contact_type') ||
        normalized.contains('missing required fields') ||
        normalized.contains('does not exist');

    if (isAccountTransactionsInsert && isSchemaMismatch) {
      return _accountTransactionsSchemaMessage;
    }

    return null;
  }

  static String getFriendlyMessage(dynamic e) {
    if (e is DioException) {
      // Check if ApiClient enhanced the error
      if (e.error is Map<String, dynamic>) {
        final errorMap = e.error as Map<String, dynamic>;
        final rawMessage = errorMap['message']?.toString();
        return _mapBackendMessage(rawMessage) ??
            rawMessage ??
            'Something went wrong. Please try again.';
      }

      // Check response data directly
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        final msg = data['message'] ?? data['error'];
        if (msg != null) {
          final rawMessage = msg is List ? msg.join(', ') : msg.toString();
          return _mapBackendMessage(rawMessage) ?? rawMessage;
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
          if (status == 403)
            return 'You do not have permission for this action.';
          if (status == 404) return 'Resource not found.';
          if (status == 500)
            return 'Server error. Our team is looking into it.';
          return 'Server returned an error ($status).';
        default:
          return 'Network error. Please try again.';
      }
    }

    final errorMessage = e.toString();
    final mappedMessage = _mapBackendMessage(errorMessage);
    if (mappedMessage != null) {
      return mappedMessage;
    }

    if (errorMessage.contains('Exception:')) {
      return errorMessage.replaceFirst('Exception:', '').trim();
    }

    return 'An unexpected error occurred.';
  }
}
