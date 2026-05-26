/// Generic lookup utilities for ERP data mappings.
class LookupUtils {
  /// Finds a display name for a given [id] within a [list] of maps.
  ///
  /// - [list]: The source list of maps (e.g., categories, taxes, terms).
  /// - [id]: The ID to look up.
  /// - [idField]: The key name for the ID (default: 'id').
  /// - [nameField]: The key name for the display value (default: 'name').
  /// - [fallback]: String to return if not found (default: '-').
  static String getNameById(
    List<Map<String, dynamic>> list,
    String? id, {
    String idField = 'id',
    String nameField = 'name',
    String fallback = '-',
  }) {
    if (id == null || id.isEmpty) return fallback;
    try {
      final item = list.firstWhere((element) => element[idField] == id);
      final candidates = <String?>[
        item[nameField]?.toString().trim(),
        item['name']?.toString().trim(),
        item['display_name']?.toString().trim(),
        item['label']?.toString().trim(),
        item['account_name']?.toString().trim(),
        item['user_account_name']?.toString().trim(),
        item['system_account_name']?.toString().trim(),
      ];
      for (final value in candidates) {
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}
