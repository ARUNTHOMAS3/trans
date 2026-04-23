// FILE: lib/core/errors/app_exceptions.dart
// Standardized exception classes (PRD Section 10.1)

/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(this.message, {this.code, this.originalError, this.stackTrace});

  @override
  String toString() {
    final codeText = code != null ? '[$code] ' : '';
    return '$runtimeType: $codeText$message';
  }

  /// Get user-friendly error message
  String get userMessage => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'Network error. Please check your internet connection and try again.';
}

/// API-related exceptions
class ApiException extends AppException {
  final int? statusCode;

  ApiException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage {
    if (statusCode == 404) {
      return 'The requested resource was not found.';
    } else if (statusCode == 401 || statusCode == 403) {
      return 'You do not have permission to perform this action.';
    } else if (statusCode != null && statusCode! >= 500) {
      return 'Server error. Please try again later.';
    }
    return message;
  }
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      final firstError = fieldErrors!.values.first;
      return firstError;
    }
    return message;
  }
}

/// Cache/Storage exceptions
class CacheException extends AppException {
  CacheException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'Local storage error. Please clear app data and try again.';
}

/// Authentication exceptions
class AuthException extends AppException {
  AuthException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Authentication failed. Please log in again.';
}

/// Data sync exceptions
class SyncException extends AppException {
  final String? resource;

  SyncException(
    super.message, {
    this.resource,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'Failed to sync ${resource ?? 'data'}. Changes will be saved locally.';
}

/// Business logic exceptions
class BusinessException extends AppException {
  BusinessException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => message; // Business errors are already user-friendly
}

/// Not found exceptions
class NotFoundException extends AppException {
  final String? resourceType;
  final String? resourceId;

  NotFoundException(
    super.message, {
    this.resourceType,
    this.resourceId,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage {
    if (resourceType != null) {
      return '$resourceType not found.';
    }
    return message;
  }
}

/// Timeout exceptions
class TimeoutException extends AppException {
  final Duration? timeout;

  TimeoutException(
    super.message, {
    this.timeout,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'Request timed out. Please check your connection and try again.';
}

/// Permission exceptions
class PermissionException extends AppException {
  final String? permission;

  PermissionException(
    super.message, {
    this.permission,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'You do not have permission to ${permission ?? 'perform this action'}.';
}

/// Conflict exceptions (e.g., duplicate data)
class ConflictException extends AppException {
  final String? conflictingField;

  ConflictException(
    super.message, {
    this.conflictingField,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage {
    if (conflictingField != null) {
      return 'A record with this $conflictingField already exists.';
    }
    return message;
  }
}
