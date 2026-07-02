import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/presentation/pages/procurement_purchase_request_overview.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/presentation/pages/procurement_requested_items_page.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/presentation/pages/purchase_requests_create.dart';

List<GoRoute> buildProcurementPurchaseRequestRoutes() {
  return [
    GoRoute(
      path: 'purchases/procurement/purchase-requests',
      name: AppRoutes.procurementPurchaseRequests,
      builder: (context, state) => const ProcurementPurchaseRequestsListPage(),
      routes: [
        GoRoute(
          path: 'create',
          name: AppRoutes.procurementPurchaseRequestsCreate,
          builder: (context, state) => ProcurementPurchaseRequestsCreatePage(
            editId: state.uri.queryParameters['id'],
          ),
        ),
        GoRoute(
          path: 'requested-items',
          name: AppRoutes.procurementRequestedItems,
          builder: (context, state) => const ProcurementRequestedItemsPage(),
        ),
        GoRoute(
          path: ':id',
          name: AppRoutes.procurementPurchaseRequestOverview,
          builder: (context, state) => ProcurementPurchaseRequestOverviewPage(
            id: state.pathParameters['id'] ?? '',
          ),
        ),
      ],
    ),
  ];
}
