class RecurringExpenseRequest {
  final int page;
  final int limit;
  final String? profileName;
  final String? status;
  final String? notes;
  final String? vendorId;
  final String? customerId;
  final String? expenseAccountId;
  final String? gstTreatment;
  final String? sourceOfSupply;
  final String? destinationOfSupply;
  final String? taxId;
  final String? entityId;
  final String? startDateFrom;
  final String? startDateTo;
  final String? endDateFrom;
  final String? endDateTo;
  final double? amountFrom;
  final double? amountTo;
  final String? sortField;
  final String? sortDirection;

  const RecurringExpenseRequest({
    this.page = 1,
    this.limit = 100,
    this.profileName,
    this.status,
    this.notes,
    this.vendorId,
    this.customerId,
    this.expenseAccountId,
    this.gstTreatment,
    this.sourceOfSupply,
    this.destinationOfSupply,
    this.taxId,
    this.entityId,
    this.startDateFrom,
    this.startDateTo,
    this.endDateFrom,
    this.endDateTo,
    this.amountFrom,
    this.amountTo,
    this.sortField,
    this.sortDirection,
  });

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      'page': page,
      'limit': limit,
      if (profileName != null && profileName!.isNotEmpty)
        'profile_name': profileName,
      if (status != null && status!.isNotEmpty) 'status': status,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (vendorId != null && vendorId!.isNotEmpty) 'vendor_id': vendorId,
      if (customerId != null && customerId!.isNotEmpty)
        'customer_id': customerId,
      if (expenseAccountId != null && expenseAccountId!.isNotEmpty)
        'expense_account_id': expenseAccountId,
      if (gstTreatment != null && gstTreatment!.isNotEmpty)
        'gst_treatment': gstTreatment,
      if (sourceOfSupply != null && sourceOfSupply!.isNotEmpty)
        'source_of_supply': sourceOfSupply,
      if (destinationOfSupply != null && destinationOfSupply!.isNotEmpty)
        'destination_of_supply': destinationOfSupply,
      if (taxId != null && taxId!.isNotEmpty) 'tax_id': taxId,
      if (entityId != null && entityId!.isNotEmpty) 'entity_id': entityId,
      if (startDateFrom != null && startDateFrom!.isNotEmpty)
        'start_date_from': startDateFrom,
      if (startDateTo != null && startDateTo!.isNotEmpty)
        'start_date_to': startDateTo,
      if (endDateFrom != null && endDateFrom!.isNotEmpty)
        'end_date_from': endDateFrom,
      if (endDateTo != null && endDateTo!.isNotEmpty) 'end_date_to': endDateTo,
      if (amountFrom != null) 'amount_from': amountFrom,
      if (amountTo != null) 'amount_to': amountTo,
      if (sortField != null && sortField!.isNotEmpty) 'sort_field': sortField,
      if (sortDirection != null && sortDirection!.isNotEmpty)
        'sort_direction': sortDirection,
    };
  }

  RecurringExpenseRequest copyWith({
    int? page,
    int? limit,
    String? profileName,
    String? status,
    String? notes,
    String? vendorId,
    String? customerId,
    String? expenseAccountId,
    String? gstTreatment,
    String? sourceOfSupply,
    String? destinationOfSupply,
    String? taxId,
    String? entityId,
    String? startDateFrom,
    String? startDateTo,
    String? endDateFrom,
    String? endDateTo,
    double? amountFrom,
    double? amountTo,
    String? sortField,
    String? sortDirection,
  }) {
    return RecurringExpenseRequest(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      profileName: profileName ?? this.profileName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      vendorId: vendorId ?? this.vendorId,
      customerId: customerId ?? this.customerId,
      expenseAccountId: expenseAccountId ?? this.expenseAccountId,
      gstTreatment: gstTreatment ?? this.gstTreatment,
      sourceOfSupply: sourceOfSupply ?? this.sourceOfSupply,
      destinationOfSupply: destinationOfSupply ?? this.destinationOfSupply,
      taxId: taxId ?? this.taxId,
      entityId: entityId ?? this.entityId,
      startDateFrom: startDateFrom ?? this.startDateFrom,
      startDateTo: startDateTo ?? this.startDateTo,
      endDateFrom: endDateFrom ?? this.endDateFrom,
      endDateTo: endDateTo ?? this.endDateTo,
      amountFrom: amountFrom ?? this.amountFrom,
      amountTo: amountTo ?? this.amountTo,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RecurringExpenseRequest &&
            runtimeType == other.runtimeType &&
            page == other.page &&
            limit == other.limit &&
            profileName == other.profileName &&
            status == other.status &&
            notes == other.notes &&
            vendorId == other.vendorId &&
            customerId == other.customerId &&
            expenseAccountId == other.expenseAccountId &&
            gstTreatment == other.gstTreatment &&
            sourceOfSupply == other.sourceOfSupply &&
            destinationOfSupply == other.destinationOfSupply &&
            taxId == other.taxId &&
            entityId == other.entityId &&
            startDateFrom == other.startDateFrom &&
            startDateTo == other.startDateTo &&
            endDateFrom == other.endDateFrom &&
            endDateTo == other.endDateTo &&
            amountFrom == other.amountFrom &&
            amountTo == other.amountTo &&
            sortField == other.sortField &&
            sortDirection == other.sortDirection;
  }

  @override
  int get hashCode => Object.hashAll([
    page,
    limit,
    profileName,
    status,
    notes,
    vendorId,
    customerId,
    expenseAccountId,
    gstTreatment,
    sourceOfSupply,
    destinationOfSupply,
    taxId,
    entityId,
    startDateFrom,
    startDateTo,
    endDateFrom,
    endDateTo,
    amountFrom,
    amountTo,
    sortField,
    sortDirection,
  ]);
}
