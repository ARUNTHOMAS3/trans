class AccountNode {
  final String id;
  final String systemAccountName;
  final String userAccountName;
  final String name; // Alias for userAccountName for UI consistency
  final String? code;
  final String? description;
  final String? accountNumber;
  final String? ifsc;
  final String currency;
  final bool showInZerpaiExpense;
  final bool addToWatchlist;
  final String
  accountGroup; // Assets | Liabilities | Income | Expenses | Equity
  final String accountType; // Detailed type like 'Bank', 'Cash', etc.
  final String? parentId;
  final String? parentName;
  final bool isSystem;
  final bool isDeletable;
  final bool isActive;
  final List<AccountNode> children;
  final int transactionCount;

  // Audit Fields (matching SQL Schema)
  final String? createdBy;
  final String? modifiedBy;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final bool isDeleted;
  final double? balance;
  final String? balanceType;

  const AccountNode({
    required this.id,
    required this.systemAccountName,
    required this.userAccountName,
    required this.name,
    this.code,
    this.description,
    this.accountNumber,
    this.ifsc,
    this.currency = 'INR',
    this.showInZerpaiExpense = false,
    this.addToWatchlist = false,
    required this.accountGroup,
    required this.accountType,
    this.parentId,
    this.parentName,
    required this.isSystem,
    required this.isDeletable,
    required this.isActive,
    this.children = const [],
    this.createdBy,
    this.modifiedBy,
    this.createdAt,
    this.modifiedAt,
    this.isDeleted = false,
    this.balance,
    this.balanceType,
    this.transactionCount = 0,
  });

  factory AccountNode.fromJson(Map<String, dynamic> json) {
    // Robust name resolution: pick the first non-empty string from candidates
    final nameCandidates = [
      json['userAccountName'],
      json['name'],
      json['user_account_name'],
      json['systemAccountName'],
      json['system_account_name'],
      json['account_name'],
    ];

    String? foundName;
    for (var candidate in nameCandidates) {
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        foundName = candidate.toString().trim();
        break;
      }
    }

    final userAccName = foundName ?? 'Unnamed Account';

    // Robust code resolution
    String? rawCode =
        (json['code'] ?? json['account_code'] ?? json['accountCode'])
            ?.toString();
    final accCode = (rawCode != null && rawCode.trim().isNotEmpty)
        ? rawCode.trim()
        : null;

    // Date parsing
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return AccountNode(
      id: json['id']?.toString() ?? '',
      systemAccountName:
          (json['systemAccountName'] ?? json['system_account_name'])
              ?.toString() ??
          userAccName,
      userAccountName: userAccName,
      name: userAccName,
      code: accCode,
      description: json['description']?.toString(),
      accountNumber: (json['accountNumber'] ?? json['account_number'])
          ?.toString(),
      ifsc: (json['ifsc'] ?? json['ifsc_code'])?.toString(),
      currency: json['currency']?.toString() ?? 'INR',
      showInZerpaiExpense:
          json['showInZerpaiExpense'] == true ||
          json['show_in_zerpai_expense'] == true,
      addToWatchlist:
          json['addToWatchlist'] == true || json['add_to_watchlist'] == true,
      accountGroup:
          (json['accountGroup'] ?? json['account_group'])?.toString() ??
          'Expenses',
      accountType:
          (json['accountType'] ?? json['account_type'])?.toString() ??
          'Expense',
      parentId: (json['parentId'] ?? json['parent_id'])?.toString(),
      parentName: (json['parentName'] ?? json['parent_name'])?.toString(),
      isSystem: json['isSystem'] == true || json['is_system'] == true,
      isDeletable:
          json['isDeletable'] != false && json['is_deletable'] != false,
      isActive: json['isActive'] != false && json['is_active'] != false,
      children:
          (json['children'] as List?)
              ?.map((e) => AccountNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: (json['createdBy'] ?? json['created_by'])?.toString(),
      modifiedBy: (json['modifiedBy'] ?? json['modified_by'])?.toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      modifiedAt: parseDate(json['modifiedAt'] ?? json['modified_at']),
      isDeleted: json['isDeleted'] == true || json['is_deleted'] == true,
      balance: (json['balance'] ?? json['closing_balance']) != null
          ? double.tryParse(
              (json['balance'] ?? json['closing_balance']).toString(),
            )
          : null,
      balanceType:
          json['balanceType'] ??
          json['balance_type'] ??
          json['closing_balance_type'],
      transactionCount:
          json['transactionCount'] ?? json['transaction_count'] ?? 0,
    );
  }

  AccountNode copyWith({
    String? id,
    String? systemAccountName,
    String? userAccountName,
    String? name,
    String? code,
    String? description,
    String? accountNumber,
    String? ifsc,
    String? currency,
    bool? showInZerpaiExpense,
    bool? addToWatchlist,
    String? accountGroup,
    String? accountType,
    String? parentId,
    String? parentName,
    bool? isSystem,
    bool? isDeletable,
    bool? isActive,
    List<AccountNode>? children,
    String? createdBy,
    String? modifiedBy,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDeleted,
    double? balance,
    String? balanceType,
    int? transactionCount,
  }) {
    return AccountNode(
      id: id ?? this.id,
      systemAccountName: systemAccountName ?? this.systemAccountName,
      userAccountName: userAccountName ?? this.userAccountName,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      currency: currency ?? this.currency,
      showInZerpaiExpense: showInZerpaiExpense ?? this.showInZerpaiExpense,
      addToWatchlist: addToWatchlist ?? this.addToWatchlist,
      accountGroup: accountGroup ?? this.accountGroup,
      accountType: accountType ?? this.accountType,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      isSystem: isSystem ?? this.isSystem,
      isDeletable: isDeletable ?? this.isDeletable,
      isActive: isActive ?? this.isActive,
      children: children ?? this.children,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      balance: balance ?? this.balance,
      balanceType: balanceType ?? this.balanceType,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }

  /// Converts model to JSON using snake_case keys matching the DB schema
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'system_account_name': systemAccountName,
      'user_account_name': userAccountName,
      'account_code': code,
      'description': description,
      'account_number': accountNumber,
      'ifsc': ifsc,
      'currency': currency,
      'show_in_zerpai_expense': showInZerpaiExpense,
      'add_to_watchlist': addToWatchlist,
      'account_group': accountGroup,
      'account_type': accountType,
      'parent_id': parentId,
      'is_system': isSystem,
      'is_deletable': isDeletable,
      'is_active': isActive,
      'created_by': createdBy,
      'modified_by': modifiedBy,
      'created_at': createdAt?.toIso8601String(),
      'modified_at': modifiedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'balance': balance,
      'balance_type': balanceType,
      'transaction_count': transactionCount,
    };
  }

  static AccountNode dummy() {
    return AccountNode(
      id: 'dummy-id',
      systemAccountName: 'Loading Account Name',
      userAccountName: 'Loading Account Name',
      name: 'Loading Account Name',
      code: 'ACC-000',
      accountGroup: 'Assets',
      accountType: 'Bank',
      isSystem: false,
      isDeletable: true,
      isActive: true,
      balance: 10000.0,
      balanceType: 'Dr',
    );
  }

  static List<AccountNode> dummyList([int count = 10]) {
    return List.generate(count, (index) => dummy().copyWith(id: 'dummy-$index'));
  }
}
