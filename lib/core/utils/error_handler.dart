// PATH: lib/core/utils/error_handler.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/not_found_page.dart';
import '../pages/unauthorized_page.dart';
import '../pages/maintenance_page.dart';
import '../pages/error_page.dart';

class ErrorHandler {
  /// Show 404 Not Found page
  static void showNotFoundPage(BuildContext context, {String? requestedRoute}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NotFoundPage(requestedRoute: requestedRoute),
      ),
    );
  }

  /// Show 403 Unauthorized page
  static void showUnauthorizedPage(
    BuildContext context, {
    String? requiredPermission,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UnauthorizedPage(requiredPermission: requiredPermission),
      ),
    );
  }

  /// Show maintenance page
  static void showMaintenancePage(
    BuildContext context, {
    String? message,
    DateTime? estimatedCompletion,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenancePage(
          message: message,
          estimatedCompletion: estimatedCompletion,
        ),
      ),
    );
  }

  /// Show generic error page
  static void showErrorPage(
    BuildContext context, {
    String? errorMessage,
    String? errorCode,
    Object? error,
    StackTrace? stackTrace,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ErrorPage(
          errorMessage: errorMessage,
          errorCode: errorCode,
          error: error,
          stackTrace: stackTrace,
        ),
      ),
    );
  }

  /// Handle navigation errors
  static void handleNavigationError(BuildContext context, String route) {
    // Log the error (in production, send to error tracking service)
    debugPrint('Navigation error: Route "$route" not found');

    showNotFoundPage(context, requestedRoute: route);
  }

  /// Handle API errors
  static void handleApiError(
    BuildContext context,
    int statusCode, {
    String? message,
  }) {
    switch (statusCode) {
      case 401:
        // Unauthorized - redirect to login
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

  /// Handle general exceptions
  static void handleException(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    String? userMessage,
  }) {
    // Log the error
    debugPrint('Exception caught: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }

    // Show user-friendly error message
    showErrorPage(
      context,
      errorMessage:
          userMessage ?? 'An unexpected error occurred. Please try again.',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Show snack bar with error message
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show snack bar with success message
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Show snack bar with warning message
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  /// Show confirmation dialog
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

  /// Show info dialog
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
