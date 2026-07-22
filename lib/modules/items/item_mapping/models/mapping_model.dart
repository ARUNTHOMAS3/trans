class ItemMappingRecord {
  final String id;
  final String sourceItemCode;
  final String targetItemCode;
  final String? notes;
  final bool isActive;

  const ItemMappingRecord({
    required this.id,
    required this.sourceItemCode,
    required this.targetItemCode,
    this.notes,
    this.isActive = true,
  });
}
