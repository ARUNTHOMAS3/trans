import 'package:zerpai_erp/app/navigation/navigation_registry.dart';

class RouteRegistry {
  RouteRegistry._();

  static Map<String, String> routeToLabelMap() {
    final map = <String, String>{};
    for (final module in NavigationRegistry.modules) {
      for (final item in module.items) {
        map[item.listRoute] = item.label;
        map[item.createRoute] = 'New ${item.label}';
      }
    }
    return map;
  }
}
