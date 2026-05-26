import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/accountant/bulk_update/presentation/pages/accountant_bulk_update_screen.dart';
import 'package:zerpai_erp/modules/accountant/opening_balances/presentation/pages/accountant_opening_balances_screen.dart';
import 'package:zerpai_erp/modules/accountant/opening_balances/presentation/pages/accountant_opening_balances_update_screen.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_settings_screen.dart';
import 'package:zerpai_erp/modules/accountant/transaction_locking/presentation/pages/accountant_transaction_locking_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_account_transactions.dart';

List<RouteBase> buildAccountantStandaloneRoutes({
  required bool Function(String moduleKey, {String action})
  hasStoredModuleAction,
  required String fallbackRouteSystemId,
}) {
  return [
    GoRoute(
      path: 'accountant/bulk-update',
      name: AppRoutes.accountantBulkUpdate,
      redirect: (context, state) {
        if (!hasStoredModuleAction('bulk_update', action: 'view')) {
          final orgSystemId =
              state.pathParameters['orgSystemId'] ?? fallbackRouteSystemId;
          return '/$orgSystemId/home';
        }
        return null;
      },
      builder: (context, state) => const AccountantBulkUpdateScreen(),
    ),
    GoRoute(
      path: 'accountant/transaction-locking',
      name: AppRoutes.accountantTransactionLocking,
      redirect: (context, state) {
        if (!hasStoredModuleAction('transaction_locking', action: 'view')) {
          final orgSystemId =
              state.pathParameters['orgSystemId'] ?? fallbackRouteSystemId;
          return '/$orgSystemId/home';
        }
        return null;
      },
      builder: (context, state) => const AccountantTransactionLockingScreen(),
    ),
    GoRoute(
      path: 'accountant/opening-balances',
      name: AppRoutes.accountantOpeningBalances,
      redirect: (context, state) {
        if (!hasStoredModuleAction('opening_balances', action: 'view')) {
          final orgSystemId =
              state.pathParameters['orgSystemId'] ?? fallbackRouteSystemId;
          return '/$orgSystemId/home';
        }
        return null;
      },
      builder: (context, state) => const OpeningBalancesScreen(),
    ),
    GoRoute(
      path: 'accountant/opening-balances/update',
      name: AppRoutes.accountantOpeningBalancesUpdate,
      redirect: (context, state) {
        if (!hasStoredModuleAction('opening_balances', action: 'edit')) {
          final orgSystemId =
              state.pathParameters['orgSystemId'] ?? fallbackRouteSystemId;
          return '/$orgSystemId/home';
        }
        return null;
      },
      builder: (context, state) => const OpeningBalancesUpdateScreen(),
    ),
    GoRoute(
      path: 'accountant/settings',
      name: AppRoutes.accountantSettings,
      builder: (context, state) => const AccountantSettingsScreen(),
    ),
    GoRoute(
      path: 'accountant/transactions-report',
      name: AppRoutes.accountantTransactionsReport,
      builder: (context, state) {
        final String accountId = state.uri.queryParameters['accountId'] ?? '';
        final String accountName =
            state.uri.queryParameters['accountName'] ?? '';
        return AccountTransactionsReportPage(
          accountId: accountId.isNotEmpty ? accountId : null,
          accountName: accountName.isNotEmpty ? accountName : null,
        );
      },
    ),
  ];
}
