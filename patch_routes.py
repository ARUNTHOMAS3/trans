import os

path = r'lib\app\routing\app_router.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import_stmt = "import 'package:zerpai_erp/modules/sales/sales_return/presentation/pages/sales_return_report_page.dart';\n"
if 'sales_return_report_page.dart' not in content:
    idx = content.find("import 'package:zerpai_erp/modules/sales/sales_return/presentation/pages/sales_return_overview_page.dart';")
    if idx != -1:
        content = content[:idx] + import_stmt + content[idx:]

old_route = """              builder: (context, state) => const SalesReturnsOverviewPage(),
              routes: ["""

new_route = """              builder: (context, state) {
                final viewParam = state.uri.queryParameters['view'];
                final rma = state.uri.queryParameters['rma'] ??
                    state.uri.queryParameters['rmaNumber'];
                // Deep-link to a specific RMA (or ?view=overview) opens the
                // overview; the sidebar lands on the report (list) page.
                if ((rma != null && rma.isNotEmpty) ||
                    viewParam == 'overview') {
                  return SalesReturnsOverviewPage(initialRmaNumber: rma);
                }
                return const SalesReturnsReportPage();
              },
              routes: [
                GoRoute(
                  path: 'report',
                  name: AppRoutes.salesReturnsReport,
                  builder: (context, state) => const SalesReturnsReportPage(),
                ),"""

if old_route in content:
    content = content.replace(old_route, new_route)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched successfully")
else:
    print("Could not find old_route")

