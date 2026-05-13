import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ReportDateRange {
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  ReportDateRange({
    required this.startDate,
    required this.endDate,
    required this.label,
  });
}

class ReportUtils {
  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');

  /// Parse the startDate, endDate and basis from the current GoRouterState
  /// Falls back to 'This Month' and 'Accrual' basis if not provided
  static Map<String, dynamic> parseReportParams(
    BuildContext context,
    GoRouterState state,
  ) {
    // Defaults: Start of current month to end of current month
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startOfThisMonth = DateTime(now.year, now.month, 1);

    final startParam = state.uri.queryParameters['startDate'];
    final endParam = state.uri.queryParameters['endDate'];
    final basisParam = state.uri.queryParameters['basis'] ?? 'Accrual';

    DateTime startDate = startOfThisMonth;
    DateTime endDate = today;

    if (startParam != null && startParam.isNotEmpty) {
      try {
        startDate = _apiFormat.parse(startParam);
      } catch (e) {
        // Fallback on error
      }
    }

    if (endParam != null && endParam.isNotEmpty) {
      try {
        endDate = _apiFormat.parse(endParam);
        // Set to end of day
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
      } catch (e) {
        // Fallback on error
      }
    }

    return {'startDate': startDate, 'endDate': endDate, 'basis': basisParam};
  }

  /// Get the API formatted date string for a DateTime
  static String formatApiDate(DateTime date) {
    return _apiFormat.format(date);
  }

  /// Update the URL with new report parameters
  static void updateReportParams(
    BuildContext context, {
    required DateTime startDate,
    required DateTime endDate,
    required String basis,
    String? additionalParamKey,
    String? additionalParamValue,
  }) {
    final state = GoRouterState.of(context);
    final routeName = state.name ?? state.uri.path;

    final queryParams = {
      ...state.uri.queryParameters,
      'startDate': formatApiDate(startDate),
      'endDate': formatApiDate(endDate),
      'basis': basis,
    };

    if (additionalParamKey != null && additionalParamValue != null) {
      queryParams[additionalParamKey] = additionalParamValue;
    }

    context.goNamed(
      routeName,
      pathParameters: state.pathParameters,
      queryParameters: queryParams,
    );
  }
}
