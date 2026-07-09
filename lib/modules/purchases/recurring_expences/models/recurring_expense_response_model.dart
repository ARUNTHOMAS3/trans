import 'recurring_expense_details_model.dart';
import 'recurring_expense_model.dart';

class RecurringExpenseResponse {
  final List<RecurringExpense> items;
  final RecurringExpenseDetails? details;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final String? message;

  const RecurringExpenseResponse({
    this.items = const <RecurringExpense>[],
    this.details,
    this.total = 0,
    this.page = 1,
    this.limit = 100,
    this.totalPages = 1,
    this.message,
  });

  factory RecurringExpenseResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'] ?? json['items'] ?? json;
    final Map<String, dynamic>? meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : null;
    final List<dynamic> rawItems = rawData is List<dynamic>
        ? rawData
        : (rawData is Map<String, dynamic>
              ? (rawData['items'] as List<dynamic>? ?? const <dynamic>[])
              : const <dynamic>[]);
    final detailsRaw = rawData is Map<String, dynamic>
        ? rawData['details'] ?? rawData['item']
        : null;
    final int total =
        (meta?['total'] as num?)?.toInt() ??
        (json['total'] as num?)?.toInt() ??
        rawItems.length;
    final int page =
        (meta?['page'] as num?)?.toInt() ??
        (json['page'] as num?)?.toInt() ??
        1;
    final int limit =
        (meta?['limit'] as num?)?.toInt() ??
        (json['limit'] as num?)?.toInt() ??
        rawItems.length;
    final int safeLimit = limit > 0
        ? limit
        : rawItems.length > 0
        ? rawItems.length
        : 1;
    final int computedTotalPages = total <= 0
        ? 1
        : ((total + safeLimit - 1) ~/ safeLimit);

    return RecurringExpenseResponse(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(RecurringExpense.fromJson)
          .toList(),
      details: detailsRaw is Map<String, dynamic>
          ? RecurringExpenseDetails.fromJson(detailsRaw)
          : null,
      total: total,
      page: page,
      limit: safeLimit,
      totalPages:
          (meta?['totalPages'] as num?)?.toInt() ??
          (meta?['total_pages'] as num?)?.toInt() ??
          (json['totalPages'] as num?)?.toInt() ??
          (json['total_pages'] as num?)?.toInt() ??
          computedTotalPages,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'items': items.map((RecurringExpense item) => item.toJson()).toList(),
      if (details != null) 'details': details!.toJson(),
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
      if (message != null) 'message': message,
    };
  }

  RecurringExpenseResponse copyWith({
    List<RecurringExpense>? items,
    RecurringExpenseDetails? details,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    String? message,
  }) {
    return RecurringExpenseResponse(
      items: items ?? this.items,
      details: details ?? this.details,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      message: message ?? this.message,
    );
  }
}
