class AccountMetadata {
  final Map<String, List<String>> groupToTypes;
  final Map<String, String> categoryDefinitions;
  final Map<String, String> typeDefinitions;
  final Map<String, List<String>> typeExamples;
  final List<String> zerpaiExpenseSupportedTypes;
  /// Type → allowed parent types. If a type is absent, same-type nesting applies.
  final Map<String, List<String>> parentTypeRelationships;
  /// Account types / system names for which "Make as sub-account" is hidden.
  final List<String> nonSubAccountableTypes;
  /// System account names whose parent is immutable (e.g. GST components).
  final List<String> systemLockedParents;
  /// Account types that can never appear as a parent in the dropdown.
  final List<String> restrictedParentTypes;

  const AccountMetadata({
    this.groupToTypes = const {},
    this.categoryDefinitions = const {},
    this.typeDefinitions = const {},
    this.typeExamples = const {},
    this.zerpaiExpenseSupportedTypes = const [],
    this.parentTypeRelationships = const {},
    this.nonSubAccountableTypes = const [],
    this.systemLockedParents = const [],
    this.restrictedParentTypes = const [],
  });

  factory AccountMetadata.fromJson(Map<String, dynamic> json) {
    return AccountMetadata(
      groupToTypes:
          (json['groupToTypes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          ) ??
          const {},
      categoryDefinitions: Map<String, String>.from(
        json['categoryDefinitions'] ?? {},
      ),
      typeDefinitions: Map<String, String>.from(json['typeDefinitions'] ?? {}),
      typeExamples:
          (json['typeExamples'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          ) ??
          const {},
      zerpaiExpenseSupportedTypes: List<String>.from(
        json['zerpaiExpenseSupportedTypes'] ?? [],
      ),
      parentTypeRelationships:
          (json['parentTypeRelationships'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          ) ??
          const {},
      nonSubAccountableTypes: List<String>.from(
        json['nonSubAccountableTypes'] ?? [],
      ),
      systemLockedParents: List<String>.from(
        json['systemLockedParents'] ?? [],
      ),
      restrictedParentTypes: List<String>.from(
        json['restrictedParentTypes'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupToTypes': groupToTypes,
      'categoryDefinitions': categoryDefinitions,
      'typeDefinitions': typeDefinitions,
      'typeExamples': typeExamples,
      'zerpaiExpenseSupportedTypes': zerpaiExpenseSupportedTypes,
      'parentTypeRelationships': parentTypeRelationships,
      'nonSubAccountableTypes': nonSubAccountableTypes,
      'systemLockedParents': systemLockedParents,
      'restrictedParentTypes': restrictedParentTypes,
    };
  }
}
