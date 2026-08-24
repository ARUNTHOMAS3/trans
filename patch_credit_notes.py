import os

path = r'lib\app\routing\app_router.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update imports for credit notes if missing
old_cn_import = "import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_create_page.dart';"
if old_cn_import not in content:
    content = content.replace(
        "import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_overview_page.dart';",
        "import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_overview_page.dart';\n" + old_cn_import
    )

# 2. Replace credit notes routing block
old_cn_route_start = "path: 'sales/credit-notes',"
old_cn_route_block = """              path: 'sales/credit-notes',
              name: AppRoutes.salesCreditNotes,
              builder: (context, state) => const CreditNotesOverviewPage(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesCreditNotesCreate,
                  builder: (context, state) => CreditNoteAddPage(
                    initialCustomer: state.uri.queryParameters['customerId'],
                    creditNoteId:
                        state.uri.queryParameters['cloneId'] ??
                        state.uri.queryParameters['fromInvoiceId'],
                  ),
                ),"""

new_cn_route_block = """              path: 'sales/credit-notes',
              name: AppRoutes.salesCreditNotes,
              builder: (context, state) {
                // Mirrors sales returns: the sidebar lands on the report (list)
                // page, while ?view=overview  or a deep-link to a specific
                // note  opens the split overview.
                final viewParam = state.uri.queryParameters['view'];
                final creditNote = state.uri.queryParameters['cn'] ??
                    state.uri.queryParameters['creditNoteNumber'];
                if ((creditNote != null && creditNote.isNotEmpty) ||
                    viewParam == 'overview') {
                  return CreditNotesOverviewPage(
                    key: state.pageKey,
                    initialCreditNoteNumber: creditNote,
                  );
                }
                return CreditNotesReportPage(key: state.pageKey);
              },
              routes: [
                GoRoute(
                  path: 'report',
                  name: AppRoutes.salesCreditNotesReport,
                  builder: (context, state) =>
                      CreditNotesReportPage(key: state.pageKey),
                ),
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesCreditNotesCreate,
                  builder: (context, state) => CreditNoteCreatePage(
                    initialCustomer: state.uri.queryParameters['customerId'],
                    creditNoteId:
                        state.uri.queryParameters['cloneId'] ??
                        state.uri.queryParameters['fromInvoiceId'],
                  ),
                ),"""

if old_cn_route_block in content:
    content = content.replace(old_cn_route_block, new_cn_route_block)
    print("Replaced CN route block.")
else:
    print("Could not find exact CN route block to replace.")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
