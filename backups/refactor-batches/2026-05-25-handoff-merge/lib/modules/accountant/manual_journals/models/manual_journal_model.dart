enum ManualJournalStatus { draft, posted, cancelled }

ManualJournalStatus manualJournalStatusFromApi(String? value) {
  final normalized = (value ?? 'draft').trim().toLowerCase();
  switch (normalized) {
    case 'draft':
      return ManualJournalStatus.draft;
    case 'posted':
    case 'published':
      return ManualJournalStatus.posted;
    case 'cancelled':
    case 'void_status':
      return ManualJournalStatus.cancelled;
    default:
      return ManualJournalStatus.draft;
  }
}

String manualJournalStatusToApi(ManualJournalStatus status) => status.name;

class ManualJournal {
  final String id;
  final String? orgId;
  final String? branchId;
  final String? userId;
  final DateTime journalDate;
  final String journalNumber;
  final String? fiscalYearId;
  final String? referenceNumber;
  final String? notes;
  final String currency;
  final bool is13thMonthAdjustment;
  final String reportingMethod;
  final List<ManualJournalItem> items;
  final ManualJournalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? recurringJournalId;

  ManualJournal({
    required this.id,
    this.orgId,
    this.branchId,
    this.userId,
    required this.journalDate,
    required this.journalNumber,
    this.fiscalYearId,
    this.referenceNumber,
    this.notes,
    this.currency = 'INR',
    this.is13thMonthAdjustment = false,
    this.reportingMethod = 'accrual_and_cash',
    required this.items,
    this.status = ManualJournalStatus.draft,
    required this.createdAt,
    required this.updatedAt,
    this.recurringJournalId,
  });

  double get totalDebit => items.fold(0.0, (sum, item) => sum + item.debit);
  double get totalCredit => items.fold(0.0, (sum, item) => sum + item.credit);

  double get totalAmount => totalDebit;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orgId': orgId,
      'org_id': orgId,
      'branchId': branchId,
      'branch_id': branchId,
      'userId': userId,
      'user_id': userId,
      'createdBy': userId,
      'created_by': userId,
      'journalDate': journalDate.toIso8601String(),
      'journal_date': journalDate.toIso8601String(),
      'journalNumber': journalNumber,
      'journal_number': journalNumber,
      'fiscalYearId': fiscalYearId,
      'fiscal_year_id': fiscalYearId,
      'referenceNumber': referenceNumber,
      'reference_number': referenceNumber,
      'notes': notes,
      'currency': currency,
      'currency_code': currency,
      'is13thMonthAdjustment': is13thMonthAdjustment,
      'is_13th_month_adjustment': is13thMonthAdjustment,
      'reportingMethod': reportingMethod,
      'reporting_method': reportingMethod,
      'items': items.map((x) => x.toJson()).toList(),
      'status': manualJournalStatusToApi(status),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'recurring_journal_id': recurringJournalId,
    };
  }

  factory ManualJournal.fromJson(Map<String, dynamic> json) {
    return ManualJournal(
      id: json['id'] as String? ?? '',
      orgId: (json['org_id'] ?? json['orgId']) as String?,
      branchId: (json['branch_id'] ?? json['branchId']) as String?,
      userId:
          (json['user_id'] ??
                  json['userId'] ??
                  json['created_by'] ??
                  json['createdBy'])
              as String?,
      journalDate: DateTime.parse(
        (json['journal_date'] ??
                json['journalDate'] ??
                DateTime.now().toIso8601String())
            as String,
      ),
      journalNumber:
          (json['journal_number'] ?? json['journalNumber'] ?? '') as String,
      fiscalYearId: (json['fiscal_year_id'] ?? json['fiscalYearId']) as String?,
      referenceNumber:
          (json['reference_number'] ?? json['referenceNumber']) as String?,
      notes: json['notes'] as String?,
      currency: (json['currency_code'] ?? json['currency']) as String? ?? 'INR',
      is13thMonthAdjustment:
          (json['is_13th_month_adjustment'] ?? json['is13thMonthAdjustment'])
              as bool? ??
          false,
      reportingMethod:
          (json['reporting_method'] ?? json['reportingMethod']) as String? ??
          'accrual_and_cash',
      items:
          (json['items'] as List?)
              ?.map(
                (x) => ManualJournalItem.fromJson(x as Map<String, dynamic>),
              )
              .toList() ??
          [],
      status: manualJournalStatusFromApi(json['status'] as String?),
      createdAt: DateTime.parse(
        (json['created_at'] ??
                json['createdAt'] ??
                DateTime.now().toIso8601String())
            as String,
      ),
      updatedAt: DateTime.parse(
        (json['updated_at'] ??
                json['updatedAt'] ??
                DateTime.now().toIso8601String())
            as String,
      ),
      recurringJournalId:
          (json['recurring_journal_id'] ?? json['recurringJournalId'])
              as String?,
    );
  }

  static ManualJournal dummy() {
    return ManualJournal(
      id: 'dummy',
      journalDate: DateTime.now(),
      journalNumber: 'MJ-000',
      items: [],
      status: ManualJournalStatus.posted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static List<ManualJournal> dummyList(int count) {
    return List.generate(count, (_) => dummy());
  }
}

class ManualJournalItem {
  final String id;
  final String accountId;
  final String accountName;
  final String? description;
  final String? contactId;
  final String? contactType;
  final String? contactName;
  final String? projectId;
  final String? projectName;
  final String? reportingTags;
  final double debit;
  final double credit;
  final int? sortOrder;

  ManualJournalItem({
    required this.id,
    required this.accountId,
    required this.accountName,
    this.description,
    this.contactId,
    this.contactType,
    this.contactName,
    this.projectId,
    this.projectName,
    this.reportingTags,
    required this.debit,
    required this.credit,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'account_id': accountId,
      'accountName': accountName,
      'description': description,
      'contactId': contactId,
      'contact_id': contactId,
      'contactType': contactType,
      'contact_type': contactType,
      'contactName': contactName,
      'projectId': projectId,
      'projectName': projectName,
      'reportingTags': reportingTags,
      'debit': debit,
      'credit': credit,
      'sort_order': sortOrder,
    };
  }

  factory ManualJournalItem.fromJson(Map<String, dynamic> json) {
    return ManualJournalItem(
      id: json['id'] as String? ?? '',
      accountId: (json['account_id'] ?? json['accountId']) as String? ?? '',
      accountName:
          (json['account_name'] ?? json['accountName']) as String? ?? '',
      description: json['description'] as String?,
      contactId: (json['contact_id'] ?? json['contactId']) as String?,
      contactType: (json['contact_type'] ?? json['contactType']) as String?,
      contactName: (json['contact_name'] ?? json['contactName']) as String?,
      projectId: (json['project_id'] ?? json['projectId']) as String?,
      projectName: (json['project_name'] ?? json['projectName']) as String?,
      reportingTags: json['reportingTags'] as String?,
      debit: double.tryParse(json['debit']?.toString() ?? '0') ?? 0.0,
      credit: double.tryParse(json['credit']?.toString() ?? '0') ?? 0.0,
      sortOrder: json['sort_order'] as int?,
    );
  }
}

class ManualJournalTemplate {
  final String id;
  final String templateName;
  final String? referenceNumber;
  final String? notes;
  final String reportingMethod;
  final String currency;
  final bool enterAmount;
  final bool isActive;
  final List<ManualJournalTemplateItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ManualJournalTemplate({
    required this.id,
    required this.templateName,
    this.referenceNumber,
    this.notes,
    this.reportingMethod = 'accrual_and_cash',
    this.currency = 'INR',
    this.enterAmount = false,
    this.isActive = true,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateName': templateName,
      'template_name': templateName,
      'referenceNumber': referenceNumber,
      'reference_number': referenceNumber,
      'notes': notes,
      'reportingMethod': reportingMethod,
      'reporting_method': reportingMethod,
      'currency': currency,
      'currency_code': currency,
      'enterAmount': enterAmount,
      'enter_amount': enterAmount,
      'isActive': isActive,
      'is_active': isActive,
      'items': items.map((x) => x.toJson()).toList(),
    };
  }

  factory ManualJournalTemplate.fromJson(Map<String, dynamic> json) {
    return ManualJournalTemplate(
      id: json['id'] as String? ?? '',
      templateName:
          (json['template_name'] ?? json['templateName'] ?? '') as String,
      referenceNumber:
          (json['reference_number'] ?? json['referenceNumber']) as String?,
      notes: json['notes'] as String?,
      reportingMethod:
          (json['reporting_method'] ?? json['reportingMethod']) as String? ??
          'accrual_and_cash',
      currency: (json['currency_code'] ?? json['currency']) as String? ?? 'INR',
      enterAmount:
          (json['enter_amount'] ?? json['enterAmount'] ?? false) as bool,
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      items:
          (json['items'] as List?)
              ?.map(
                (x) => ManualJournalTemplateItem.fromJson(
                  x as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

class ManualJournalTemplateItem {
  final String? id;
  final String accountId;
  final String accountName;
  final String? description;
  final String? contactId;
  final String? contactType;
  final String? contactName;
  final String? projectId;
  final String? reportingTags;
  final String? type; // 'debit' or 'credit' or null
  final double debit;
  final double credit;
  final int? sortOrder;

  ManualJournalTemplateItem({
    this.id,
    required this.accountId,
    required this.accountName,
    this.description,
    this.contactId,
    this.contactType,
    this.contactName,
    this.projectId,
    this.reportingTags,
    this.type,
    this.debit = 0,
    this.credit = 0,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'account_id': accountId,
      'accountName': accountName,
      'description': description,
      'contactId': contactId,
      'contact_id': contactId,
      'contactType': contactType,
      'contact_type': contactType,
      'contactName': contactName,
      'projectId': projectId,
      'project_id': projectId,
      'reportingTags': reportingTags,
      'type': type,
      'debit': debit,
      'credit': credit,
      'sort_order': sortOrder,
    };
  }

  factory ManualJournalTemplateItem.fromJson(Map<String, dynamic> json) {
    return ManualJournalTemplateItem(
      id: json['id'] as String?,
      accountId: (json['account_id'] ?? json['accountId'] ?? '') as String,
      accountName:
          (json['account_name'] ??
                  json['accountName'] ??
                  json['account']?['user_account_name'] ??
                  json['account']?['system_account_name'] ??
                  '')
              as String,
      description: json['description'] as String?,
      contactId: (json['contact_id'] ?? json['contactId']) as String?,
      contactType: (json['contact_type'] ?? json['contactType']) as String?,
      contactName: (json['contact_name'] ?? json['contactName']) as String?,
      projectId: (json['project_id'] ?? json['projectId']) as String?,
      reportingTags:
          (json['reporting_tags'] ?? json['reportingTags']) as String?,
      type: json['type'] as String?,
      debit: double.tryParse(json['debit']?.toString() ?? '0') ?? 0.0,
      credit: double.tryParse(json['credit']?.toString() ?? '0') ?? 0.0,
      sortOrder:
          (json['sort_order'] ?? json['sortOrder'] ?? json['sortOrder'])
              as int?,
    );
  }
}
