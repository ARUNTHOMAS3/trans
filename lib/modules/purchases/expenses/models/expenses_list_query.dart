class ExpensesListQuery {
  static const int defaultLimit = 100;
  static const int maxLimit = 200;

  const ExpensesListQuery({
    this.page = 1,
    this.limit = defaultLimit,
    this.search,
    this.status,
    this.expenseMode,
    this.vendorId,
    this.customerId,
    this.isItemized,
    this.favoriteFilter,
    this.sortBy = 'date',
    this.sortAscending = false,
  });

  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? expenseMode;
  final String? vendorId;
  final String? customerId;
  final bool? isItemized;
  final String? favoriteFilter;
  final String sortBy;
  final bool sortAscending;

  ExpensesListQuery copyWith({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? expenseMode,
    String? vendorId,
    String? customerId,
    bool? isItemized,
    String? favoriteFilter,
    String? sortBy,
    bool? sortAscending,
  }) {
    return ExpensesListQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
      expenseMode: expenseMode ?? this.expenseMode,
      vendorId: vendorId ?? this.vendorId,
      customerId: customerId ?? this.customerId,
      isItemized: isItemized ?? this.isItemized,
      favoriteFilter: favoriteFilter ?? this.favoriteFilter,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  String get prefetchKey => [
    limit.clamp(1, maxLimit),
    search?.trim() ?? '',
    status?.trim() ?? '',
    expenseMode?.trim() ?? '',
    vendorId?.trim() ?? '',
    customerId?.trim() ?? '',
    isItemized?.toString() ?? '',
    favoriteFilter?.trim() ?? '',
    sortBy.trim(),
    sortAscending.toString(),
  ].join('|');

  Map<String, dynamic> toQueryParameters() => <String, dynamic>{
    'page': page < 1 ? 1 : page,
    'limit': limit.clamp(1, maxLimit),
    if (search != null && search!.trim().isNotEmpty) 'search': search,
    if (status != null && status!.trim().isNotEmpty) 'status': status,
    if (expenseMode != null && expenseMode!.trim().isNotEmpty)
      'expense_mode': expenseMode,
    if (vendorId != null && vendorId!.trim().isNotEmpty) 'vendor_id': vendorId,
    if (customerId != null && customerId!.trim().isNotEmpty)
      'customer_id': customerId,
    if (isItemized != null) 'is_itemized': isItemized,
    if (favoriteFilter != null && favoriteFilter!.trim().isNotEmpty)
      'favorite_filter': favoriteFilter,
    'sort_by': sortBy,
    'sort_direction': sortAscending ? 'asc' : 'desc',
  };
}
