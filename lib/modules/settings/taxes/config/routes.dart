import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/settings/taxes/direct_taxes/presentation/pages/direct_taxes_create_page.dart';
import 'package:zerpai_erp/modules/settings/taxes/e_invoicing/presentation/pages/e_invoicing_page.dart';
import 'package:zerpai_erp/modules/settings/taxes/e_way_bills/presentation/pages/e_way_bills_page.dart';
import 'package:zerpai_erp/modules/settings/taxes/presentation/pages/settings_tax_create_page.dart';
import 'package:zerpai_erp/modules/settings/taxes/presentation/pages/settings_tax_import_page.dart';
import 'package:zerpai_erp/modules/settings/taxes/presentation/pages/settings_taxes_overview_page.dart';

List<GoRoute> buildSettingsTaxesRoutes() {
  return [
    GoRoute(
      path: 'settings/taxes',
      name: AppRoutes.settingsTaxes,
      builder: (context, state) => const SettingsTaxesOverviewPage(),
    ),
    GoRoute(
      path: 'settings/taxes/new',
      name: AppRoutes.settingsTaxCreate,
      builder: (context, state) => const SettingsTaxCreatePage(),
    ),
    GoRoute(
      path: 'settings/taxes/import',
      name: AppRoutes.settingsTaxImport,
      builder: (context, state) => const SettingsTaxImportPage(),
    ),
    GoRoute(
      path: 'settings/taxes/groups/import',
      name: AppRoutes.settingsTaxGroupImport,
      builder: (context, state) =>
          SettingsTaxImportPage(importKind: TaxImportKind.taxGroup),
    ),
    GoRoute(
      path: 'settings/direct-taxes',
      name: AppRoutes.settingsDirectTaxes,
      builder: (context, state) => const DirectTaxesCreatePage(),
    ),
    GoRoute(
      path: 'settings/eway-bills',
      name: AppRoutes.settingsEwayBills,
      builder: (context, state) => const EWayBillsPage(),
    ),
    GoRoute(
      path: 'settings/einvoicing',
      name: AppRoutes.settingsEinvoicing,
      builder: (context, state) => const EInvoicingPage(),
    ),
  ];
}
