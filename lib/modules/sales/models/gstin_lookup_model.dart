class GstinLookupResult {
  final String gstin;
  final String legalName;
  final String tradeName;
  final String status;
  final String taxpayerType;
  final List<GstinAddress> addresses;

  const GstinLookupResult({
    required this.gstin,
    required this.legalName,
    required this.tradeName,
    required this.status,
    required this.taxpayerType,
    required this.addresses,
  });

  factory GstinLookupResult.fromJson(Map<String, dynamic> json) {
    final data = _pickMap(json, const ['data', 'result']) ?? json;

    final gstin = _pickString(data, [
      'gstin',
      'gstin_number',
      'gstinId',
      'gstinNumber',
    ]);
    final legalName = _pickString(data, [
      'legal_name',
      'legalName',
      'lgnm',
      'company_name',
      'companyName',
    ]);
    final tradeName = _pickString(data, [
      'trade_name',
      'tradeName',
      'tradeNam',
      'trade',
      'business_trade_name',
      'businessTradeName',
    ]);
    final status = _pickString(data, ['status', 'gstin_status', 'sts']);
    final taxpayerType = _pickString(data, [
      'taxpayer_type',
      'taxpayerType',
      'ctb',
      'taxType',
    ]);

    final addresses = <GstinAddress>[];

    final primary = _pickMap(data, const ['pradr']);
    if (primary != null) {
      addresses.add(GstinAddress.fromMap(primary));
    }

    final additional = _pickList(data, const ['adadr', 'addresses']);
    if (additional != null) {
      for (final item in additional) {
        if (item is Map<String, dynamic>) {
          addresses.add(GstinAddress.fromMap(item));
        }
      }
    }

    return GstinLookupResult(
      gstin: gstin,
      legalName: legalName,
      tradeName: tradeName,
      status: status,
      taxpayerType: taxpayerType,
      addresses: addresses,
    );
  }

  static Map<String, dynamic>? _pickMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) return value;
    }
    return null;
  }

  static List<dynamic>? _pickList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) return value;
    }
    return null;
  }

  static String _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return '';
  }
}

class GstinAddress {
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String pinCode;
  final String country;

  const GstinAddress({
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.country,
  });

  factory GstinAddress.fromMap(Map<String, dynamic> map) {
    final addr = map['addr'];
    if (addr is Map<String, dynamic>) {
      return GstinAddress.fromMap(addr);
    }

    final line1Parts = <String>[
      _value(map, 'bno'),
      _value(map, 'bnm'),
      _value(map, 'st'),
      _value(map, 'loc'),
      _value(map, 'flno'),
    ]..removeWhere((e) => e.isEmpty);

    final line2Parts = <String>[_value(map, 'stcd'), _value(map, 'dst')]
      ..removeWhere((e) => e.isEmpty);

    return GstinAddress(
      line1: _value(map, 'line1', fallback: line1Parts.join(', ')),
      line2: _value(map, 'line2', fallback: line2Parts.join(', ')),
      city: _value(map, 'city', fallback: _value(map, 'dst')),
      state: _value(map, 'state', fallback: _value(map, 'stcd')),
      pinCode: _value(map, 'pin', fallback: _value(map, 'pncd')),
      country: _value(map, 'country', fallback: 'India'),
    );
  }

  String get displayLabel {
    final parts = <String>[
      if (line1.isNotEmpty) line1,
      if (line2.isNotEmpty) line2,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (pinCode.isNotEmpty) pinCode,
    ];
    return parts.isEmpty ? 'Address not available' : parts.join(', ');
  }

  static String _value(
    Map<String, dynamic> map,
    String key, {
    String fallback = '',
  }) {
    final value = map[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
