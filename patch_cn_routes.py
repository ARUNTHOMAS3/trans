import os

app_routes_path = r'lib\core\routing\app_routes.dart'
with open(app_routes_path, 'r', encoding='utf-8') as f:
    app_routes = f.read()

if "salesCreditNotesReport" not in app_routes:
    app_routes = app_routes.replace(
        "static const String salesCreditNotes = '/sales/credit-notes';",
        "static const String salesCreditNotes = '/sales/credit-notes';\n  static const String salesCreditNotesReport = 'report';\n  static const String creditNotesReport = salesCreditNotesReport;"
    )
    with open(app_routes_path, 'w', encoding='utf-8') as f:
        f.write(app_routes)

app_router_path = r'lib\app\routing\app_router.dart'
with open(app_router_path, 'r', encoding='utf-8') as f:
    app_router = f.read()

import_stmt = "import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_report_page.dart';"
if "credit_note_report_page.dart" not in app_router:
    app_router = app_router.replace(
        "import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_overview_page.dart';",
        "import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_overview_page.dart';\n" + import_stmt
    )
    with open(app_router_path, 'w', encoding='utf-8') as f:
        f.write(app_router)

print('Patched successfully')
