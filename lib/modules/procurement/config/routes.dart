import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/modules/procurement/approvals/config/routes.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/config/routes.dart';

List<GoRoute> buildProcurementRoutes() {
  return [
    ...buildProcurementPurchaseRequestRoutes(),
    ...buildProcurementApprovalRoutes(),
  ];
}
