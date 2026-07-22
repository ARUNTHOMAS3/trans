import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_general_ledger_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_inventory_valuation_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_profit_and_loss_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_sales_by_customer_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_trial_balance_screen.dart';

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
      path: 'reports/sales-by-customer',
      name: AppRoutes.salesByCustomer,
      builder: (context, state) => const SalesByCustomerScreen(),
    ),
    GoRoute(
      path: 'reports/inventory-valuation',
      name: AppRoutes.inventoryValuation,
      builder: (context, state) => const InventoryValuationScreen(),
    ),
  ];
}
