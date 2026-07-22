import 'package:zerpai_erp/app/navigation/navigation_registry.dart';

class NavSearchEntry {
  const NavSearchEntry({
    required this.module,
    required this.label,
    required this.route,
  });

  final String module;
  final String label;
  final String route;
}

class SearchRegistry {
  SearchRegistry._();

  static List<NavSearchEntry> all() {
    final entries = <NavSearchEntry>[];
    for (final module in NavigationRegistry.modules) {
      for (final item in module.items) {
        entries.add(
          NavSearchEntry(
            module: module.label,
            label: item.label,
            route: item.listRoute,
          ),
        );
      }
    }
    return entries;
  }
}
