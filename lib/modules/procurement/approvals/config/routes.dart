import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/procurement/approvals/presentation/pages/procurement_approvals_overview.dart';
import 'package:zerpai_erp/modules/procurement/approvals/presentation/pages/procurement_approvals_report.dart';

List<GoRoute> buildProcurementApprovalRoutes() {
  return [
    GoRoute(
      path: 'purchases/procurement/approvals',
      name: AppRoutes.procurementApprovals,
      builder: (context, state) => const ProcurementApprovalsReportPage(),
      routes: [
        GoRoute(
          path: 'overview',
          name: AppRoutes.procurementApprovalsOverview,
          builder: (context, state) => ProcurementApprovalsOverviewPage(
            initialRef: state.uri.queryParameters['ref'],
          ),
        ),
      ],
    ),
  ];
}
