import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart'
    as chart_accounts;
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';

class ExpenseAccountLookupModel {
  const ExpenseAccountLookupModel({
    required this.id,
    this.userAccountName,
    this.systemAccountName,
    this.accountCode,
    this.accountGroup,
    this.accountType,
    this.children = const <ExpenseAccountLookupModel>[],
  });

  final String id;
  final String? userAccountName;
  final String? systemAccountName;
  final String? accountCode;
  final String? accountGroup;
  final String? accountType;
  final List<ExpenseAccountLookupModel> children;

  String get displayName {
    final userName = userAccountName?.trim();
    if (userName != null && userName.isNotEmpty) {
      return userName;
    }
    final systemName = systemAccountName?.trim();
    if (systemName != null && systemName.isNotEmpty) {
      return systemName;
    }
    return '';
  }

  bool get hasChildren => children.isNotEmpty;

  factory ExpenseAccountLookupModel.fromJson(Map<String, dynamic> json) {
    return ExpenseAccountLookupModel(
      id: (json['id'] ?? '').toString(),
      userAccountName: (json['user_account_name'] ?? json['userAccountName'])
          ?.toString(),
      systemAccountName:
          (json['system_account_name'] ?? json['systemAccountName'])
              ?.toString(),
      accountCode: (json['account_code'] ?? json['accountCode'])?.toString(),
      accountGroup: (json['account_group'] ?? json['accountGroup'])?.toString(),
      accountType: (json['account_type'] ?? json['accountType'])?.toString(),
      children: (json['children'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ExpenseAccountLookupModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_account_name': userAccountName,
      'system_account_name': systemAccountName,
      'account_code': accountCode,
      'account_group': accountGroup,
      'account_type': accountType,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  ExpenseAccountLookupModel copyWith({
    String? id,
    String? userAccountName,
    String? systemAccountName,
    String? accountCode,
    String? accountGroup,
    String? accountType,
    List<ExpenseAccountLookupModel>? children,
  }) {
    return ExpenseAccountLookupModel(
      id: id ?? this.id,
      userAccountName: userAccountName ?? this.userAccountName,
      systemAccountName: systemAccountName ?? this.systemAccountName,
      accountCode: accountCode ?? this.accountCode,
      accountGroup: accountGroup ?? this.accountGroup,
      accountType: accountType ?? this.accountType,
      children: children ?? this.children,
    );
  }

  AccountNode toAccountNode() {
    return AccountNode(
      id: id,
      name: displayName,
      selectable: true,
      children: children.map((child) => child.toAccountNode()).toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAccountLookupModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CustomerLookupModel {
  const CustomerLookupModel({
    required this.id,
    required this.displayName,
    this.customerNumber,
    this.firstName,
    this.companyName,
    this.email,
    this.gstTreatment,
    this.placeOfSupply,
  });

  final String id;
  final String displayName;
  final String? customerNumber;
  final String? firstName;
  final String? companyName;
  final String? email;
  final String? gstTreatment;
  final String? placeOfSupply;

  factory CustomerLookupModel.fromJson(Map<String, dynamic> json) {
    return CustomerLookupModel(
      id: (json['id'] ?? '').toString(),
      displayName:
          (json['display_name'] ?? json['displayName'] ?? json['name'] ?? '')
              .toString(),
      customerNumber: (json['customer_number'] ?? json['customerNumber'])
          ?.toString(),
      firstName: (json['first_name'] ?? json['firstName'])?.toString(),
      companyName: (json['company_name'] ?? json['companyName'])?.toString(),
      email: (json['email'] ?? json['email_address'])?.toString(),
      gstTreatment: (json['gst_treatment'] ?? json['gstTreatment'])?.toString(),
      placeOfSupply: (json['place_of_supply'] ?? json['placeOfSupply'])
          ?.toString(),
    );
  }

  factory CustomerLookupModel.fromSalesCustomer(SalesCustomer customer) {
    return CustomerLookupModel(
      id: customer.id,
      displayName: customer.displayName,
      customerNumber: customer.customerNumber,
      firstName: customer.firstName,
      companyName: customer.companyName,
      email: customer.email,
      gstTreatment: customer.gstTreatment,
      placeOfSupply: customer.placeOfSupply,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'display_name': displayName,
      'customer_number': customerNumber,
      'first_name': firstName,
      'company_name': companyName,
      'email': email,
      'gst_treatment': gstTreatment,
      'place_of_supply': placeOfSupply,
    };
  }

  CustomerLookupModel copyWith({
    String? id,
    String? displayName,
    String? customerNumber,
    String? firstName,
    String? companyName,
    String? email,
    String? gstTreatment,
    String? placeOfSupply,
  }) {
    return CustomerLookupModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      customerNumber: customerNumber ?? this.customerNumber,
      firstName: firstName ?? this.firstName,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      gstTreatment: gstTreatment ?? this.gstTreatment,
      placeOfSupply: placeOfSupply ?? this.placeOfSupply,
    );
  }

  SalesCustomer toSalesCustomer() {
    return SalesCustomer(
      id: id,
      displayName: displayName,
      customerNumber: customerNumber,
      firstName: firstName,
      companyName: companyName,
      email: email,
      gstTreatment: gstTreatment,
      placeOfSupply: placeOfSupply,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerLookupModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class VendorLookupModel {
  const VendorLookupModel({
    required this.id,
    required this.displayName,
    this.firstName,
    this.companyName,
    this.vendorNumber,
    this.gstTreatment,
    this.sourceOfSupply,
  });

  final String id;
  final String displayName;
  final String? firstName;
  final String? companyName;
  final String? vendorNumber;
  final String? gstTreatment;
  final String? sourceOfSupply;

  factory VendorLookupModel.fromJson(Map<String, dynamic> json) {
    return VendorLookupModel(
      id: (json['id'] ?? '').toString(),
      displayName:
          (json['display_name'] ?? json['displayName'] ?? json['name'] ?? '')
              .toString(),
      firstName: (json['first_name'] ?? json['firstName'])?.toString(),
      companyName: (json['company_name'] ?? json['companyName'])?.toString(),
      vendorNumber: (json['vendor_number'] ?? json['vendorNumber'])?.toString(),
      gstTreatment: (json['gst_treatment'] ?? json['gstTreatment'])?.toString(),
      sourceOfSupply: (json['source_of_supply'] ?? json['sourceOfSupply'])
          ?.toString(),
    );
  }

  factory VendorLookupModel.fromVendor(Vendor vendor) {
    return VendorLookupModel(
      id: vendor.id,
      displayName: vendor.displayName,
      firstName: vendor.firstName,
      companyName: vendor.companyName,
      vendorNumber: vendor.vendorNumber,
      gstTreatment: vendor.gstTreatment,
      sourceOfSupply: vendor.sourceOfSupply,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'display_name': displayName,
      'first_name': firstName,
      'company_name': companyName,
      'vendor_number': vendorNumber,
      'gst_treatment': gstTreatment,
      'source_of_supply': sourceOfSupply,
    };
  }

  VendorLookupModel copyWith({
    String? id,
    String? displayName,
    String? firstName,
    String? companyName,
    String? vendorNumber,
    String? gstTreatment,
    String? sourceOfSupply,
  }) {
    return VendorLookupModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      companyName: companyName ?? this.companyName,
      vendorNumber: vendorNumber ?? this.vendorNumber,
      gstTreatment: gstTreatment ?? this.gstTreatment,
      sourceOfSupply: sourceOfSupply ?? this.sourceOfSupply,
    );
  }

  Vendor toVendor() {
    return Vendor(
      id: id,
      displayName: displayName,
      firstName: firstName,
      companyName: companyName,
      vendorNumber: vendorNumber,
      gstTreatment: gstTreatment,
      sourceOfSupply: sourceOfSupply,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorLookupModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CurrencyLookupModel {
  const CurrencyLookupModel({
    required this.id,
    required this.code,
    required this.name,
    this.symbol,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String name;
  final String? symbol;
  final bool isActive;

  String get displayLabel => '$code - $name';

  factory CurrencyLookupModel.fromJson(Map<String, dynamic> json) {
    return CurrencyLookupModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      symbol: json['symbol']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'symbol': symbol,
      'is_active': isActive,
    };
  }

  CurrencyLookupModel copyWith({
    String? id,
    String? code,
    String? name,
    String? symbol,
    bool? isActive,
  }) {
    return CurrencyLookupModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      isActive: isActive ?? this.isActive,
    );
  }
}

class GstTreatmentLookupModel {
  const GstTreatmentLookupModel({
    required this.id,
    required this.code,
    required this.label,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String label;
  final int sortOrder;
  final bool isActive;

  factory GstTreatmentLookupModel.fromJson(Map<String, dynamic> json) {
    return GstTreatmentLookupModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? json['name'] ?? '').toString(),
      sortOrder:
          (json['sort_order'] as num?)?.toInt() ??
          int.tryParse((json['sort_order'] ?? '0').toString()) ??
          0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'label': label,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  GstTreatmentLookupModel copyWith({
    String? id,
    String? code,
    String? label,
    int? sortOrder,
    bool? isActive,
  }) {
    return GstTreatmentLookupModel(
      id: id ?? this.id,
      code: code ?? this.code,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

class StateLookupModel {
  const StateLookupModel({
    required this.id,
    required this.name,
    required this.code,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String code;
  final bool isActive;

  /// Display label for UI dropdowns: "[KL] - Kerala" or "Kerala" if code absent.
  String get displayLabel {
    final trimmedCode = code.trim();
    return trimmedCode.isNotEmpty ? '[$trimmedCode] - $name' : name;
  }

  factory StateLookupModel.fromJson(Map<String, dynamic> json) {
    return StateLookupModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? json['state_code'] ?? '').toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'code': code,
      'is_active': isActive,
    };
  }

  StateLookupModel copyWith({
    String? id,
    String? name,
    String? code,
    bool? isActive,
  }) {
    return StateLookupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
    );
  }
}

class RecurringExpenseTaxOption {
  const RecurringExpenseTaxOption({
    required this.id,
    required this.label,
    this.rate,
    this.description,
    this.isHeader = false,
    this.section = sectionUngrouped,
    this.taxType,
  });

  static const String sectionUngrouped = 'ungrouped';
  static const String sectionTaxRate = 'tax_rate';
  static const String sectionTaxGroup = 'tax_group';

  final String id;
  final String label;
  final double? rate;
  final String? description;
  final bool isHeader;
  final String section;
  final String? taxType;

  bool get isSelectable => !isHeader;
  bool get isUngrouped => !isHeader && section == sectionUngrouped;
  bool get isTaxRate => !isHeader && section == sectionTaxRate;
  bool get isTaxGroup => !isHeader && section == sectionTaxGroup;

  String get displayLabel {
    if (isHeader) {
      return label;
    }
    if (rate == null) {
      return label;
    }
    return '$label [${_formatTaxRate(rate!)}%]';
  }

  String get searchLabel => isHeader ? '' : displayLabel;

  static String _formatTaxRate(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}

typedef RecurringExpenseCustomerOption = CustomerLookupModel;
typedef RecurringExpenseVendorOption = VendorLookupModel;

List<AccountNode> mapRecurringExpenseAccountNodes(
  Iterable<ExpenseAccountLookupModel> accounts,
) {
  return accounts.map((account) => account.toAccountNode()).toList();
}

List<AccountNode> buildRecurringExpenseGroupedAccountNodes(
  Iterable<ExpenseAccountLookupModel> accounts,
) {
  final Map<String, _GroupedAccountNodeBuilder> typeBuilders =
      <String, _GroupedAccountNodeBuilder>{};

  for (final account in accounts) {
    final typeLabel = _normalizedAccountLabel(
      account.accountType,
      fallback: account.accountGroup,
      defaultValue: 'Accounts',
    );
    final groupLabel = _normalizedAccountLabel(
      account.accountGroup,
      fallback: account.accountType,
      defaultValue: 'Ungrouped',
    );

    final typeBuilder = typeBuilders.putIfAbsent(
      typeLabel,
      () => _GroupedAccountNodeBuilder(label: typeLabel),
    );
    final normalizedGroup = groupLabel.trim().toLowerCase();
    final normalizedType = typeLabel.trim().toLowerCase();

    if (normalizedGroup == normalizedType || normalizedGroup == 'expenses') {
      typeBuilder.accounts.add(_mapAccountBranch(account));
      continue;
    }

    final groupBuilder = typeBuilder.children.putIfAbsent(
      groupLabel,
      () => _GroupedAccountNodeBuilder(label: groupLabel),
    );
    groupBuilder.accounts.add(_mapAccountBranch(account));
  }

  return typeBuilders.values.map((builder) => builder.toAccountNode()).toList();
}

List<AccountNode> buildRecurringPaidThroughAccountNodes(
  Iterable<chart_accounts.AccountNode> roots,
) {
  final List<chart_accounts.AccountNode> allAccounts =
      <chart_accounts.AccountNode>[];

  void collect(Iterable<chart_accounts.AccountNode> nodes) {
    for (final node in nodes) {
      allAccounts.add(node);
      if (node.children.isNotEmpty) {
        collect(node.children);
      }
    }
  }

  collect(roots);

  final Map<String, List<chart_accounts.AccountNode>> groupedByType =
      <String, List<chart_accounts.AccountNode>>{};

  for (final account in allAccounts) {
    final typeLabel = _normalizedAccountLabel(
      account.accountType,
      fallback: account.accountGroup,
      defaultValue: 'Accounts',
    );
    groupedByType
        .putIfAbsent(typeLabel, () => <chart_accounts.AccountNode>[])
        .add(account);
  }

  final List<AccountNode> groupedNodes = <AccountNode>[];
  for (final entry in groupedByType.entries) {
    final String typeLabel = entry.key;
    final List<chart_accounts.AccountNode> typeAccounts = entry.value;
    final Set<String> typeAccountIds = typeAccounts
        .map((acc) => acc.id)
        .toSet();
    final List<chart_accounts.AccountNode> rootNodes = typeAccounts
        .where(
          (account) =>
              account.parentId == null ||
              !typeAccountIds.contains(account.parentId),
        )
        .toList();

    groupedNodes.add(
      AccountNode(
        id: '__account_type__${_normalizeAccountNodeKey(typeLabel)}',
        name: typeLabel,
        selectable: false,
        children: rootNodes
            .map((root) => _mapPaidThroughAccountBranch(root, typeAccounts))
            .toList(),
      ),
    );
  }

  return groupedNodes;
}

String _normalizedAccountLabel(
  String? primary, {
  String? fallback,
  required String defaultValue,
}) {
  final trimmedPrimary = primary?.trim();
  if (trimmedPrimary != null && trimmedPrimary.isNotEmpty) {
    return trimmedPrimary;
  }
  final trimmedFallback = fallback?.trim();
  if (trimmedFallback != null && trimmedFallback.isNotEmpty) {
    return trimmedFallback;
  }
  return defaultValue;
}

AccountNode _mapAccountBranch(ExpenseAccountLookupModel account) {
  return AccountNode(
    id: account.id,
    name: account.displayName,
    selectable: true,
    children: account.children.map(_mapAccountBranch).toList(),
  );
}

AccountNode _mapPaidThroughAccountBranch(
  chart_accounts.AccountNode account,
  List<chart_accounts.AccountNode> typeAccounts,
) {
  final List<chart_accounts.AccountNode> childAccounts = typeAccounts
      .where((candidate) => candidate.parentId == account.id)
      .toList();

  return AccountNode(
    id: account.id,
    name: _resolveChartAccountDisplayName(account),
    selectable: true,
    children: childAccounts
        .map((child) => _mapPaidThroughAccountBranch(child, typeAccounts))
        .toList(),
  );
}

String _resolveChartAccountDisplayName(chart_accounts.AccountNode account) {
  final String userName = account.userAccountName.trim();
  if (userName.isNotEmpty) {
    return userName;
  }

  final String systemName = account.systemAccountName.trim();
  if (systemName.isNotEmpty) {
    return systemName;
  }

  return account.name.trim();
}

String _normalizeAccountNodeKey(String label) {
  return label.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

class _GroupedAccountNodeBuilder {
  _GroupedAccountNodeBuilder({required this.label});

  final String label;
  final Map<String, _GroupedAccountNodeBuilder> children =
      <String, _GroupedAccountNodeBuilder>{};
  final List<AccountNode> accounts = <AccountNode>[];

  AccountNode toAccountNode() {
    return AccountNode(
      id: '__account_group__${label.toLowerCase().replaceAll(' ', '_')}',
      name: label,
      selectable: false,
      children: <AccountNode>[
        ...children.values.map((child) => child.toAccountNode()),
        ...accounts,
      ],
    );
  }
}

List<CustomerLookupModel> mapRecurringExpenseCustomerOptions(
  Iterable<dynamic> customers,
) {
  return customers
      .cast<SalesCustomer>()
      .map(CustomerLookupModel.fromSalesCustomer)
      .toList();
}

List<VendorLookupModel> mapRecurringExpenseVendorOptions(
  Iterable<dynamic> vendors,
) {
  return vendors.cast<Vendor>().map(VendorLookupModel.fromVendor).toList();
}
