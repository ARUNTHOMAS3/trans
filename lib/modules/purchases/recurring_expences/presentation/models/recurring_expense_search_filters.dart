class RecurringExpenseSearchFilters {
  final String module;
  final String? scopeFilter;
  final String name;
  final DateTime? startDateFrom;
  final DateTime? startDateTo;
  final DateTime? endDateFrom;
  final DateTime? endDateTo;
  final double? totalFrom;
  final double? totalTo;
  final String? expenseAccount;
  final String? status;
  final String? customerName;
  final String? vendor;
  final String notes;
  final String? tax;
  final String? gstTreatment;
  final String? sourceOfSupply;
  final String? destinationOfSupply;

  const RecurringExpenseSearchFilters({
    this.module = 'Recurring Expenses',
    this.scopeFilter = 'All',
    this.name = '',
    this.startDateFrom,
    this.startDateTo,
    this.endDateFrom,
    this.endDateTo,
    this.totalFrom,
    this.totalTo,
    this.expenseAccount,
    this.status,
    this.customerName,
    this.vendor,
    this.notes = '',
    this.tax,
    this.gstTreatment,
    this.sourceOfSupply,
    this.destinationOfSupply,
  });

  bool get hasActive {
    return module != 'Recurring Expenses' ||
        scopeFilter != 'All' ||
        name.trim().isNotEmpty ||
        startDateFrom != null ||
        startDateTo != null ||
        endDateFrom != null ||
        endDateTo != null ||
        totalFrom != null ||
        totalTo != null ||
        expenseAccount != null ||
        status != null ||
        customerName != null ||
        vendor != null ||
        notes.trim().isNotEmpty ||
        tax != null ||
        gstTreatment != null ||
        sourceOfSupply != null ||
        destinationOfSupply != null;
  }

  Map<String, Object?> toLogData() {
    return {
      'module': module,
      'scopeFilter': scopeFilter,
      'name': name,
      'startDateFrom': startDateFrom?.toIso8601String(),
      'startDateTo': startDateTo?.toIso8601String(),
      'endDateFrom': endDateFrom?.toIso8601String(),
      'endDateTo': endDateTo?.toIso8601String(),
      'totalFrom': totalFrom,
      'totalTo': totalTo,
      'expenseAccount': expenseAccount,
      'status': status,
      'customerName': customerName,
      'vendor': vendor,
      'notes': notes,
      'tax': tax,
      'gstTreatment': gstTreatment,
      'sourceOfSupply': sourceOfSupply,
      'destinationOfSupply': destinationOfSupply,
    };
  }
}
