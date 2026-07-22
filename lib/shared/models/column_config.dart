class ColumnConfig {
  final String id;
  final String label;
  bool isVisible;
  int orderIndex;
  bool isLocked;
  bool isPinned;

  ColumnConfig({
    required this.id,
    required this.label,
    this.isVisible = true,
    this.orderIndex = 0,
    this.isLocked = false,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'isVisible': isVisible,
    'orderIndex': orderIndex,
    'isLocked': isLocked,
    'isPinned': isPinned,
  };

  factory ColumnConfig.fromJson(Map<String, dynamic> json) => ColumnConfig(
    id: json['id'],
    label: json['label'],
    isVisible: json['isVisible'] ?? true,
    orderIndex: json['orderIndex'] ?? 0,
    isLocked: json['isLocked'] ?? false,
    isPinned: json['isPinned'] ?? false,
  );
}
