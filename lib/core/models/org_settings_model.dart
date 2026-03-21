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
  final String fiscalYear;
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
    this.fiscalYear = 'April - March',
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
        baseCurrency:
            json['base_currency']?.toString().isNotEmpty == true
                ? json['base_currency'].toString()
                : 'INR',
        fiscalYear: json['fiscal_year']?.toString() ?? 'April - March',
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
    String? fiscalYear,
    String? timezone,
    String? dateFormat,
    String? dateSeparator,
    String? companyIdLabel,
    String? companyIdValue,
    String? paymentStubAddress,
    bool? hasSeparatePaymentStubAddress,
  }) =>
      OrgSettings(
        id: id,
        systemId: systemId,
        name: name ?? this.name,
        logoUrl: logoUrl ?? this.logoUrl,
        industry: industry ?? this.industry,
        baseCurrency: baseCurrency ?? this.baseCurrency,
        fiscalYear: fiscalYear ?? this.fiscalYear,
        timezone: timezone ?? this.timezone,
        dateFormat: dateFormat ?? this.dateFormat,
        dateSeparator: dateSeparator ?? this.dateSeparator,
        companyIdLabel: companyIdLabel ?? this.companyIdLabel,
        companyIdValue: companyIdValue ?? this.companyIdValue,
        paymentStubAddress: paymentStubAddress ?? this.paymentStubAddress,
        hasSeparatePaymentStubAddress:
            hasSeparatePaymentStubAddress ??
            this.hasSeparatePaymentStubAddress,
      );
}
