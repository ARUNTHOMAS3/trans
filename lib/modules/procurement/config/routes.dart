import 'package:go_router/go_router.dart';

List<GoRoute> buildProcurementRoutes() {
  return [
    ...buildProcurementPurchaseRequestRoutes(),
    ...buildProcurementApprovalRoutes(),
  ];
}

List<GoRoute> buildProcurementPurchaseRequestRoutes() => [];
List<GoRoute> buildProcurementApprovalRoutes() => [];
