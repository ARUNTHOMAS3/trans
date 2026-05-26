class SalesCustomerDetailContext {
  final List<CustomerTransactionGroup> transactions;
  final List<CustomerActivityEntry> activities;
  final List<CustomerCommentEntry> comments;
  final List<CustomerMailEntry> mails;
  final List<CustomerStatementEntry> statementEntries;

  const SalesCustomerDetailContext({
    this.transactions = const [],
    this.activities = const [],
    this.comments = const [],
    this.mails = const [],
    this.statementEntries = const [],
  });

  factory SalesCustomerDetailContext.fromJson(Map<String, dynamic> json) {
    return SalesCustomerDetailContext(
      transactions: (json['transactions'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomerTransactionGroup.fromJson)
          .toList(),
      activities: (json['activities'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomerActivityEntry.fromJson)
          .toList(),
      comments: (json['comments'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomerCommentEntry.fromJson)
          .toList(),
      mails: (json['mails'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomerMailEntry.fromJson)
          .toList(),
      statementEntries: (json['statementEntries'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomerStatementEntry.fromJson)
          .toList(),
    );
  }
}

class CustomerTransactionGroup {
  final String key;
  final String label;
  final int count;
  final List<CustomerTransactionItem> items;

  const CustomerTransactionGroup({
    required this.key,
    required this.label,
    required this.count,
    this.items = const [],
  });

  factory CustomerTransactionGroup.fromJson(Map<String, dynamic> json) {
    return CustomerTransactionGroup(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomerTransactionItem.fromJson)
          .toList(),
    );
  }
}

class CustomerTransactionItem {
  final String id;
  final String number;
  final String title;
  final String status;
  final double amount;
  final DateTime? date;

  const CustomerTransactionItem({
    required this.id,
    required this.number,
    required this.title,
    required this.status,
    required this.amount,
    this.date,
  });

  factory CustomerTransactionItem.fromJson(Map<String, dynamic> json) {
    return CustomerTransactionItem(
      id: (json['id'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
    );
  }
}

class CustomerActivityEntry {
  final String id;
  final String actor;
  final String action;
  final String description;
  final DateTime? createdAt;

  const CustomerActivityEntry({
    required this.id,
    required this.actor,
    required this.action,
    required this.description,
    this.createdAt,
  });

  factory CustomerActivityEntry.fromJson(Map<String, dynamic> json) {
    return CustomerActivityEntry(
      id: (json['id'] ?? '').toString(),
      actor: (json['actor'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class CustomerCommentEntry {
  final String id;
  final String author;
  final String body;
  final DateTime? createdAt;

  const CustomerCommentEntry({
    required this.id,
    required this.author,
    required this.body,
    this.createdAt,
  });

  factory CustomerCommentEntry.fromJson(Map<String, dynamic> json) {
    return CustomerCommentEntry(
      id: (json['id'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class CustomerMailEntry {
  final String id;
  final String to;
  final String subject;
  final String status;
  final DateTime? sentAt;

  const CustomerMailEntry({
    required this.id,
    required this.to,
    required this.subject,
    required this.status,
    this.sentAt,
  });

  factory CustomerMailEntry.fromJson(Map<String, dynamic> json) {
    return CustomerMailEntry(
      id: (json['id'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString())
          : null,
    );
  }
}

class CustomerStatementEntry {
  final String id;
  final DateTime? date;
  final String type;
  final String number;
  final String? reference;
  final String? status;
  final double debit;
  final double credit;
  final double balance;

  const CustomerStatementEntry({
    required this.id,
    required this.type,
    required this.number,
    required this.debit,
    required this.credit,
    required this.balance,
    this.date,
    this.reference,
    this.status,
  });

  factory CustomerStatementEntry.fromJson(Map<String, dynamic> json) {
    return CustomerStatementEntry(
      id: (json['id'] ?? '').toString(),
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      type: (json['type'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      reference: json['reference']?.toString(),
      status: json['status']?.toString(),
      debit: (json['debit'] as num?)?.toDouble() ?? 0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}
