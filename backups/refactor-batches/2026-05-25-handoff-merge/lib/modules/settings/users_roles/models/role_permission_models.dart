class PermissionRowMeta {
  final String label;
  final String key;
  final List<String> actions;
  final List<String> overrides;
  final String? tooltip;
  final String? infoTooltip; // The "i" icon tooltip
  final Map<String, String>? overrideTooltips;
  final bool isSettingsList; // For Settings & Compliance section
  final List<PermissionRowMeta>?
  subRows; // For nested checkboxes like Vendor's Bank account

  PermissionRowMeta({
    required this.label,
    required this.key,
    this.actions = const ['view', 'create', 'edit', 'delete'],
    this.overrides = const [],
    this.tooltip,
    this.infoTooltip,
    this.overrideTooltips,
    this.isSettingsList = false,
    this.subRows,
  });
}

class PermissionSectionMeta {
  final String title;
  final List<PermissionRowMeta> rows;
  PermissionSectionMeta({required this.title, required this.rows});
}
