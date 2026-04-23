/// Lightweight model for organization profile settings fetched from
/// GET /lookups/org/:orgId. This is the single source of truth for
/// currency, date format, fiscal year, timezone, and company identity.
class OrgSettings {
  final String id;
  final String systemId;
  final String name;
  final String? logoUrl;
  final String? industry;
  final String baseCurrency;
  final int? baseCurrencyDecimals;
  final String? baseCurrencyFormat;
  final String fiscalYear;
  final String organizationLanguage;
  final List<String> communicationLanguages;
  final String timezone;
  final String dateFormat;
  final String dateSeparator;
  final String? companyIdLabel;
  final String? companyIdValue;
  final String? paymentStubAddress;
  final bool hasSeparatePaymentStubAddress;
  final String accentColor;
  final String themeMode;

  const OrgSettings({
    required this.id,
    required this.systemId,
    required this.name,
    this.logoUrl,
    this.industry,
    this.baseCurrency = 'INR',
    this.baseCurrencyDecimals,
    this.baseCurrencyFormat,
    this.fiscalYear = 'April - March',
    this.organizationLanguage = 'English',
    this.communicationLanguages = const <String>['English'],
    this.timezone = '(GMT +5:30) India Standard Time (Asia/Calcutta)',
    this.dateFormat = 'dd MMM yyyy',
    this.dateSeparator = '-',
    this.companyIdLabel,
    this.companyIdValue,
    this.paymentStubAddress,
    this.hasSeparatePaymentStubAddress = false,
    this.accentColor = '#22A95E',
    this.themeMode = 'dark',
  });

  factory OrgSettings.fromJson(Map<String, dynamic> json) => OrgSettings(
    id: json['id']?.toString() ?? '',
    systemId: json['system_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    logoUrl: json['logo_url']?.toString(),
    industry: json['industry']?.toString(),
    baseCurrency: json['base_currency']?.toString().isNotEmpty == true
        ? json['base_currency'].toString()
        : 'INR',
    baseCurrencyDecimals: json['base_currency_decimals'] as int?,
    baseCurrencyFormat: json['base_currency_format']?.toString(),
    fiscalYear: json['fiscal_year']?.toString() ?? 'April - March',
    organizationLanguage:
        json['organization_language']?.toString().isNotEmpty == true
        ? json['organization_language'].toString()
        : 'English',
    communicationLanguages:
        (json['communication_languages'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        const <String>['English'],
    timezone:
        json['timezone']?.toString() ??
        '(GMT +5:30) India Standard Time (Asia/Calcutta)',
    dateFormat: json['date_format']?.toString() ?? 'dd MMM yyyy',
    dateSeparator: json['date_separator']?.toString() ?? '-',
    companyIdLabel: json['company_id_label']?.toString(),
    companyIdValue: json['company_id_value']?.toString(),
    paymentStubAddress: json['payment_stub_address']?.toString(),
    hasSeparatePaymentStubAddress:
        json['has_separate_payment_stub_address'] as bool? ?? false,
    accentColor: json['accent_color']?.toString() ?? '#22A95E',
    themeMode: json['theme_mode']?.toString() ?? 'dark',
  );

  /// Returns a copy with updated fields.
  OrgSettings copyWith({
    String? name,
    String? logoUrl,
    String? industry,
    String? baseCurrency,
    int? baseCurrencyDecimals,
    String? baseCurrencyFormat,
    String? fiscalYear,
    String? organizationLanguage,
    List<String>? communicationLanguages,
    String? timezone,
    String? dateFormat,
    String? dateSeparator,
    String? companyIdLabel,
    String? companyIdValue,
    String? paymentStubAddress,
    bool? hasSeparatePaymentStubAddress,
  }) => OrgSettings(
    id: id,
    systemId: systemId,
    name: name ?? this.name,
    logoUrl: logoUrl ?? this.logoUrl,
    industry: industry ?? this.industry,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    baseCurrencyDecimals: baseCurrencyDecimals ?? this.baseCurrencyDecimals,
    baseCurrencyFormat: baseCurrencyFormat ?? this.baseCurrencyFormat,
    fiscalYear: fiscalYear ?? this.fiscalYear,
    organizationLanguage: organizationLanguage ?? this.organizationLanguage,
    communicationLanguages:
        communicationLanguages ?? this.communicationLanguages,
    timezone: timezone ?? this.timezone,
    dateFormat: dateFormat ?? this.dateFormat,
    dateSeparator: dateSeparator ?? this.dateSeparator,
    companyIdLabel: companyIdLabel ?? this.companyIdLabel,
    companyIdValue: companyIdValue ?? this.companyIdValue,
    paymentStubAddress: paymentStubAddress ?? this.paymentStubAddress,
    hasSeparatePaymentStubAddress:
        hasSeparatePaymentStubAddress ?? this.hasSeparatePaymentStubAddress,
  );

  String? get resolvedCompanyIdLabel {
    final label = companyIdLabel?.trim();
    return (label == null || label.isEmpty) ? null : label;
  }

  String? get resolvedCompanyIdValue {
    final value = companyIdValue?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  String? get companyIdentityLine {
    final label = resolvedCompanyIdLabel;
    final value = resolvedCompanyIdValue;
    if (label == null || value == null) {
      return null;
    }
    return '$label: $value';
  }
}
