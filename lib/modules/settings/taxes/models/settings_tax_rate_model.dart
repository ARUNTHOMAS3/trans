/// UI model for the settings tax workspace.
///
/// Persistence is intentionally not implied here: this handoff currently has
/// no settings API contract. The provider is a local adapter until the
/// schema-backed settings repository is connected.
class SettingsTaxRate {
  const SettingsTaxRate({
    required this.id,
    required this.name,
    required this.type,
    required this.rate,
    required this.isActive,
    this.isTaxGroup = false,
  });

  final String id;
  final String name;
  final String type;
  final double rate;
  final bool isActive;
  final bool isTaxGroup;

  SettingsTaxRate copyWith({
    String? id,
    String? name,
    String? type,
    double? rate,
    bool? isActive,
    bool? isTaxGroup,
  }) => SettingsTaxRate(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        rate: rate ?? this.rate,
        isActive: isActive ?? this.isActive,
        isTaxGroup: isTaxGroup ?? this.isTaxGroup,
      );
}
