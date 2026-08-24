import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_general_ledger_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_inventory_valuation_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_profit_and_loss_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_trial_balance_screen.dart';

List<GoRoute> buildStandaloneReportRoutes() {
  return [
    GoRoute(
      path: 'reports/profit-and-loss',
      name: AppRoutes.profitAndLoss,
      builder: (context, state) => const ProfitAndLossScreen(),
    ),
    GoRoute(
      path: 'reports/general-ledger',
      name: AppRoutes.generalLedger,
      builder: (context, state) => const GeneralLedgerScreen(),
    ),
    GoRoute(
      path: 'reports/trial-balance',
      name: AppRoutes.trialBalance,
      builder: (context, state) => const TrialBalanceScreen(),
    ),
    GoRoute(
      path: 'reports/inventory-valuation',
      name: AppRoutes.inventoryValuation,
      builder: (context, state) => const InventoryValuationScreen(),
    ),
    GoRoute(
      path: 'reports/category/:categorySlug/report/:reportSlug',
      builder: (context, state) {
        final category = reportsResolveCategory(
          state.pathParameters['categorySlug'],
        );
        final reportName = reportsReportNameFromSlug(
          state.pathParameters['reportSlug'],
          category: category,
        );
        final reportPage = reportName == null
            ? null
            : buildReportsModuleReportPage(reportName, category: category);

        return reportPage ??
            ReportsCenterScreen(
              initialCategory: category,
              initialSearchQuery: state.uri.queryParameters['q'],
            );
      },
    ),
    GoRoute(
      path: 'reports/category/:categorySlug',
      builder: (context, state) => ReportsCenterScreen(
        initialCategory: reportsResolveCategory(
          state.pathParameters['categorySlug'],
        ),
        initialSearchQuery: state.uri.queryParameters['q'],
      ),
    ),
  ];
}
