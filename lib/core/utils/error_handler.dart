import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

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

  static String getFriendlyMessage(dynamic error) {
    if (error is DioException) {
      if (error.error is Map<String, dynamic>) {
        final errorMap = error.error as Map<String, dynamic>;
        final rawMessage = errorMap['message']?.toString();
        return _mapBackendMessage(rawMessage) ??
            rawMessage ??
            'Something went wrong. Please try again.';
      }

      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        final message = data['message'] ?? data['error'];
        if (message != null) {
          final rawMessage = message is List
              ? message.join(', ')
              : message.toString();
          return _mapBackendMessage(rawMessage) ?? rawMessage;
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your internet.';
        case DioExceptionType.connectionError:
          return 'No internet connection.';
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          if (status == 400) return 'Invalid request. Please check your data.';
          if (status == 401) return 'Unauthorized. Please login again.';
          if (status == 403) {
            return 'You do not have permission for this action.';
          }
          if (status == 404) return 'Resource not found.';
          if (status == 500) {
            return 'Server error. Our team is looking into it.';
          }
          return 'Server returned an error ($status).';
        default:
          return 'Network error. Please try again.';
      }
    }

    final errorMessage = error.toString();
    final mappedMessage = _mapBackendMessage(errorMessage);
    if (mappedMessage != null) {
      return mappedMessage;
    }

    if (errorMessage.contains('Exception:')) {
      return errorMessage.replaceFirst('Exception:', '').trim();
    }

    return 'An unexpected error occurred.';
  }

  static void showNotFoundPage(BuildContext context, {String? requestedRoute}) {
    context.go('/not-found', extra: {'requestedRoute': requestedRoute});
  }

  static void showUnauthorizedPage(
    BuildContext context, {
    String? requiredPermission,
  }) {
    context.go('/unauthorized', extra: {'requiredPermission': requiredPermission});
  }

  static void showMaintenancePage(
    BuildContext context, {
    String? message,
    DateTime? estimatedCompletion,
  }) {
    context.go('/maintenance', extra: {
      'message': message,
      'estimatedCompletion': estimatedCompletion,
    });
  }

  static void showErrorPage(
    BuildContext context, {
    String? errorMessage,
    String? errorCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    context.go('/error', extra: {
      'errorMessage': errorMessage,
      'errorCode': errorCode,
      'error': error,
      'stackTrace': stackTrace,
    });
  }

  static void handleNavigationError(BuildContext context, String route) {
    debugPrint('Navigation error: Route "$route" not found');
    showNotFoundPage(context, requestedRoute: route);
  }

  static void handleApiError(
    BuildContext context,
    int statusCode, {
    String? message,
  }) {
    switch (statusCode) {
      case 401:
        context.go('/login');
        break;
      case 403:
        showUnauthorizedPage(context, requiredPermission: message);
        break;
      case 404:
        showNotFoundPage(context);
        break;
      case 500:
      case 502:
      case 503:
        showMaintenancePage(context, message: message);
        break;
      default:
        showErrorPage(
          context,
          errorMessage: message ?? 'An unexpected error occurred',
          errorCode: statusCode.toString(),
        );
    }
  }

  static void handleException(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    String? userMessage,
  }) {
    debugPrint('Exception caught: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }

    showErrorPage(
      context,
      errorMessage:
          userMessage ?? 'An unexpected error occurred. Please try again.',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ZerpaiToast.error(context, message);
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ZerpaiToast.success(context, message);
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    ZerpaiToast.info(context, message);
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelText),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
