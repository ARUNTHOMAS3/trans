import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

String resolveOrgSystemId(BuildContext context) {
  final routeOrgId = GoRouterState.of(context)
      .pathParameters['orgSystemId']
      ?.trim();
  if (routeOrgId != null && routeOrgId.isNotEmpty) return routeOrgId;

  final location = GoRouter.of(context).routeInformationProvider.value.uri
      .toString();
  final match = RegExp(r'^/(\d{10,20})(/|$)').firstMatch(location);
  final parsed = match?.group(1)?.trim();
  if (parsed != null && parsed.isNotEmpty) return parsed;

  return '';
}
