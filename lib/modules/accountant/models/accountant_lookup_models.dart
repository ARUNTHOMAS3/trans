class Currency {
  final String id;
  final String code;
  final String name;
  final String? symbol;
  final int decimals;
  final String? format;
  final bool isActive;

  const Currency({
    required this.id,
    required this.code,
    required this.name,
    this.symbol,
    this.decimals = 2,
    this.format,
    this.isActive = true,
  });

  String get label => '$code - $name';

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString(),
      decimals: json['decimals'] is int ? json['decimals'] : 2,
      format: json['format']?.toString(),
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'symbol': symbol,
    'decimals': decimals,
    'format': format,
    'is_active': isActive,
  };
}

class CountryCode {
  final String id;
  final String name;
  final String? fullLabel;
  final String? phoneCode;
  final String? shortCode;
  final String? currencyCode;
  final bool isActive;

  const CountryCode({
    required this.id,
    required this.name,
    this.fullLabel,
    this.phoneCode,
    this.shortCode,
    this.currencyCode,
    this.isActive = true,
  });

  factory CountryCode.fromJson(Map<String, dynamic> json) {
    return CountryCode(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fullLabel: json['full_label']?.toString(),
      phoneCode: json['phone_code']?.toString(),
      shortCode: json['short_code']?.toString(),
      currencyCode: json['currency_code']?.toString(),
      isActive: json['isActive'] != false,
    );
  }
}
