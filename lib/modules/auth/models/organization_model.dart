class Address {
  final String street;
  final String city;
  final String state;
  final String country;
  final String postalCode;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        street: json['street'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? '',
        postalCode: json['postalCode'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'state': state,
        'country': country,
        'postalCode': postalCode,
      };
}

class Organization {
  final String id;
  final String name;
  final String? legalName;
  final String? gstin;
  final String? pan;
  final String? phone;
  final String? email;
  final String? website;
  final Address address;
  final String currency;
  final String timezone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// UUID referencing states.id — populated from the new state_id column added
  /// by the Smart-Tax SQL migration. Null when not yet configured.
  final String? stateId;

  Organization({
    required this.id,
    required this.name,
    this.legalName,
    this.gstin,
    this.pan,
    this.phone,
    this.email,
    this.website,
    required this.address,
    required this.currency,
    required this.timezone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.stateId,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return Organization(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      legalName: json['legalName'] as String?,
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      address: Address.fromJson(
        (json['address'] as Map<String, dynamic>?) ??
            <String, dynamic>{'street': '', 'city': '', 'state': '', 'country': '', 'postalCode': ''},
      ),
      currency: json['currency'] as String? ?? 'INR',
      timezone: json['timezone'] as String? ?? 'UTC',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      stateId: json['stateId'] as String? ?? json['state_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'legalName': legalName,
        'gstin': gstin,
        'pan': pan,
        'phone': phone,
        'email': email,
        'website': website,
        'address': address.toJson(),
        'currency': currency,
        'timezone': timezone,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'stateId': stateId,
      };
}
