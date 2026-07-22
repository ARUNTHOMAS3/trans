import 'package:zerpai_erp/app/navigation/navigation_registry.dart';

class Breadcrumbs {
  Breadcrumbs._();

  static List<String> fromRoute(String route) {
    for (final module in NavigationRegistry.modules) {
      for (final item in module.items) {
        if (route.startsWith(item.listRoute)) {
          return [module.label, item.label];
        }
      }
    }
    return [];
  }
}
