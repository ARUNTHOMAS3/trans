import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/observability/performance_telemetry.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/presentation/pages/purchase_requests_create.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/presentation/pages/procurement_requested_items_page.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/presentation/pages/procurement_purchase_request_overview.dart';
import 'package:zerpai_erp/modules/procurement/approvals/presentation/pages/procurement_approvals_overview.dart';
import 'package:zerpai_erp/modules/procurement/approvals/presentation/pages/procurement_approvals_report.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zerpai_erp/core/auth/auth_session_expiry_notifier.dart';
import 'package:zerpai_erp/modules/items/items/presentation/pages/items_item_create.dart';
import 'package:zerpai_erp/modules/items/items/presentation/pages/items_item_detail.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/report/items_report_overview.dart';
import 'package:zerpai_erp/modules/items/composite_items/presentation/composite_items_create.dart';
import 'package:zerpai_erp/modules/items/composite_items/presentation/composite_items_overview.dart';
import 'package:zerpai_erp/modules/items/composite_items/presentation/composite_items_list.dart';

import 'package:zerpai_erp/modules/sales/customers/presentation/pages/sales_customer_create.dart';
import 'package:zerpai_erp/modules/sales/customers/presentation/pages/sales_customer_list.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/pages/sales_order_list.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/presentation/pages/sales_order_create.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/invoices/presentation/pages/sales_invoice_create.dart';
import 'package:zerpai_erp/modules/sales/invoices/presentation/pages/sales_invoice_list.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/presentation/pages/retainer_invoice_overview.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/presentation/pages/retainer_invoices_create_page.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/presentation/pages/retainer_invoices_list_page.dart';
import 'package:zerpai_erp/modules/sales/delivery_challans/presentation/pages/sales_delivery_challan_create.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/presentation/report_page.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/presentation/sales_payment_create.dart';

import 'package:zerpai_erp/modules/sales/payment_recieved/presentation/payment_recieves_overview.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_add_page.dart';
import 'package:zerpai_erp/modules/sales/eway_bills/presentation/pages/sales_eway_bill_create.dart';
import 'package:zerpai_erp/modules/sales/quotations/presentation/pages/sales_quotes_create_page.dart';
import 'package:zerpai_erp/modules/sales/quotations/presentation/pages/sales_quotes_report_page.dart';
import 'package:zerpai_erp/modules/sales/documents/presentation/pages/sales_document_detail.dart';
import 'package:zerpai_erp/modules/sales/customers/presentation/pages/sales_customer_overview.dart';
import 'package:zerpai_erp/modules/sales/payment_links/presentation/pages/sales_payment_link_create.dart';

import 'package:zerpai_erp/modules/sales/recurring_invoices/presentation/pages/recurring_invoices_report_page.dart';
import 'package:zerpai_erp/modules/sales/recurring_invoices/presentation/pages/recurring_invoices_create_page.dart';
import 'package:zerpai_erp/modules/sales/recurring_invoices/presentation/pages/recurring_invoices_overview_page.dart';

import 'package:zerpai_erp/modules/sales/sales_return/presentation/pages/sales_return_overview_page.dart';
import 'package:zerpai_erp/modules/sales/sales_return/presentation/pages/sales_return_create_page.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_overview_page.dart';
import 'package:zerpai_erp/modules/inventory/assemblies/presentation/pages/inventory_assemblies_assembly_creation.dart';
import 'package:zerpai_erp/modules/items/item_mapping/presentation/pages/item_mapping_create_page.dart';
import 'package:zerpai_erp/modules/items/item_mapping/presentation/pages/item_mapping_overview_page.dart';
import 'package:zerpai_erp/modules/items/item_mapping/presentation/pages/item_mapping_report_page.dart';
import 'package:zerpai_erp/modules/inventory/assemblies/presentation/pages/inventory_assemblies_assembly_overview.dart';

import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/pages/manual_journal_template_create_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/pages/manual_journal_templates_list_screen.dart';
import 'package:zerpai_erp/modules/accountant/recurring_journals/presentation/pages/recurring_journal_create_screen.dart';
import 'package:zerpai_erp/modules/accountant/recurring_journals/presentation/pages/recurring_journal_overview_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/models/manual_journal_model.dart';
import 'package:zerpai_erp/modules/accountant/recurring_journals/models/recurring_journal_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/presentation/pages/accountant_chart_of_accounts_overview.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/presentation/pages/accountant_chart_of_accounts_creation.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/presentation/items_pricelist_pricelist_overview.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/presentation/items_pricelist_pricelist_create.dart';

import 'package:zerpai_erp/modules/pricelists/branch_pricelist/presentation/branch_pricelist_overview_page.dart';
import 'package:zerpai_erp/modules/pricelists/branch_pricelist/presentation/branch_pricelist_create_page.dart';

import 'package:zerpai_erp/modules/accountant/opening_balances/presentation/pages/accountant_opening_balances_screen.dart';
import 'package:zerpai_erp/modules/accountant/opening_balances/presentation/pages/accountant_opening_balances_update_screen.dart';
import 'package:zerpai_erp/modules/accountant/config/routes.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/activity/presentation/pages/reports_audit_logs_screen.dart';
import 'package:zerpai_erp/modules/reports/sales/presentation/pages/reports_sales_sales_daily.dart';
import 'package:zerpai_erp/modules/home/presentation/home_dashboard_overview.dart';
import 'package:zerpai_erp/modules/reports/config/routes.dart';
import 'package:zerpai_erp/modules/settings/config/routes.dart';
import 'package:zerpai_erp/modules/auth/presentation/auth_auth_login.dart';
import 'package:zerpai_erp/modules/auth/presentation/auth_auth_forgot_password.dart';
import 'package:zerpai_erp/modules/auth/presentation/auth_auth_reset_password.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/modules/auth/services/permission_service.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/pages/vendors_report_page.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/pages/vendors_overview_page.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/pages/vendors_email_page.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/pages/purchases_vendors_vendor_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/presentation/purchases_purchase_returns_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/presentation/purchases_purchase_returns_overview.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/presentation/purchases_purchase_returns_report.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_list.dart';
import 'package:zerpai_erp/modules/purchases/payments_made/presentation/pages/purchases_payments_made_create.dart';
import 'package:zerpai_erp/modules/purchases/payments_made/presentation/pages/purchases_payments_made_list.dart';
import 'package:zerpai_erp/modules/purchases/payments_made/presentation/pages/purchases_payments_made_report.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/presentation/purchases_vendor_credits_create.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/presentation/purchases_vendor_credits_report.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/presentation/vendor_credit_refund_page.dart';
import 'package:zerpai_erp/modules/purchases/bills/presentation/pages/purchases_bills_list.dart';
import 'package:zerpai_erp/modules/purchases/bills/presentation/pages/purchases_bills_create.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/pages/purchases_expenses_create_page.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/pages/purchases_expenses_overview_page.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/pages/purchases_expenses_receipts_inbox_page.dart';
import 'package:zerpai_erp/modules/purchases/expenses/presentation/pages/purchases_expenses_report_page.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/pages/purchases_recurring_expences_create_page.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/pages/purchases_recurring_expences_custom_view_page.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/pages/purchases_recurring_expences_page.dart';
import 'package:zerpai_erp/shared/widgets/placeholder_screen.dart';
import 'package:zerpai_erp/app/layout/zerpai_shell.dart';
import 'package:zerpai_erp/app/pages/error_page.dart';
import 'package:zerpai_erp/app/pages/maintenance_page.dart';
import 'package:zerpai_erp/app/pages/not_found_page.dart';
import 'package:zerpai_erp/app/pages/unauthorized_page.dart';
import 'package:zerpai_erp/modules/inventory/picklists/presentation/pages/inventory_picklists_list.dart';
import 'package:zerpai_erp/modules/inventory/picklists/presentation/pages/inventory_picklists_create.dart';

import 'package:zerpai_erp/modules/inventory/picklists/presentation/pages/inventory_picklists_update.dart';
import 'package:zerpai_erp/modules/inventory/packages/presentation/pages/inventory_packages_list.dart';
import 'package:zerpai_erp/modules/inventory/packages/presentation/pages/inventory_packages_create.dart';
import 'package:zerpai_erp/modules/inventory/shipments/presentation/pages/inventory_shipments_list.dart';
import 'package:zerpai_erp/modules/inventory/shipments/presentation/pages/inventory_shipments_create.dart';
import 'package:zerpai_erp/modules/inventory/shipments/presentation/pages/inventory_shipments_edit.dart';
import 'package:zerpai_erp/modules/inventory/adjustments/presentation/pages/inventory_adjustments_overview_screen.dart';
import 'package:zerpai_erp/modules/inventory/adjustments/presentation/pages/inventory_adjustments_create.dart';
import 'package:zerpai_erp/modules/inventory/transfer_orders/presentation/pages/inventory_transfer_orders_list.dart';
import 'package:zerpai_erp/modules/inventory/transfer_orders/presentation/pages/inventory_transfer_orders_create.dart';
import 'package:zerpai_erp/modules/inventory/move_orders/presentation/pages/inventory_move_orders_list.dart';
import 'package:zerpai_erp/modules/inventory/move_orders/presentation/pages/inventory_move_orders_create.dart';
import 'package:zerpai_erp/modules/inventory/stock_count/models/stock_count_model.dart';
import 'package:zerpai_erp/modules/inventory/stock_count/presentation/pages/recurring_stock_count_report_page.dart';
import 'package:zerpai_erp/modules/inventory/stock_count/presentation/pages/stock_count_create_page.dart';
import 'package:zerpai_erp/modules/inventory/stock_count/presentation/pages/stock_count_overview_page.dart';
import 'package:zerpai_erp/modules/inventory/stock_count/presentation/pages/stock_count_perform_page.dart';
import 'package:zerpai_erp/modules/inventory/stock_count/presentation/pages/stock_count_report_page.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
export 'package:zerpai_erp/core/routing/app_routes.dart';

const String _kFallbackRouteSystemId = '0000000000';
const bool _kEnableAuth = bool.fromEnvironment(
  'ENABLE_AUTH',
  defaultValue: true,
);

bool _hasStoredAuthToken() {
  try {
    final box = Hive.box('config');
    final token = box.get('auth_token') as String?;
    return token != null && token.isNotEmpty;
  } catch (_) {
    return false;
  }
}

int? _readJwtExpFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final map = jsonDecode(decoded);
    if (map is Map<String, dynamic>) {
      final exp = map['exp'];
      if (exp is int) return exp;
      if (exp is num) return exp.toInt();
      return int.tryParse(exp?.toString() ?? '');
    }
  } catch (_) {}
  return null;
}

int? _readStoredAuthExpiresAt() {
  try {
    final box = Hive.box('config');
    final value = box.get('auth_expires_at');
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  } catch (_) {
    return null;
  }
}

bool _isStoredAuthTokenExpired() {
  final box = Hive.box('config');
  final token = (box.get('auth_token') as String?)?.trim() ?? '';
  if (token.isEmpty) return true;
  final expiresAt = _readStoredAuthExpiresAt() ?? _readJwtExpFromToken(token);
  if (expiresAt == null) return true;
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return expiresAt <= nowSeconds;
}

bool _hasStoredAuthSession() {
  if (!_hasStoredAuthToken() || _isStoredAuthTokenExpired()) {
    return false;
  }
  final user = _readStoredUser();
  return user != null && user.isNotEmpty;
}

Map<String, dynamic>? _readStoredUser() {
  try {
    final box = Hive.box('config');
    final raw = box.get('user_data') as String?;
    if (raw == null || raw.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  } catch (_) {
    return null;
  }
}

User? _readStoredUserModel() {
  final data = _readStoredUser();
  if (data == null || data.isEmpty) {
    return null;
  }
  try {
    return User.fromJson(data);
  } catch (_) {
    return null;
  }
}

bool _hasStoredModuleAction(String moduleKey, {String action = 'view'}) {
  final user = _readStoredUserModel();
  if (user == null) {
    return false;
  }
  return PermissionService.hasModuleAction(user, moduleKey, action: action);
}

bool _isStoredAdmin() {
  final user = _readStoredUserModel();
  if (user == null) return false;
  return user.role.trim().toLowerCase() == 'admin';
}

String _storedRouteSystemId() {
  final user = _readStoredUser();
  final routeSystemId = (user?['routeSystemId'] ?? '').toString().trim();
  if (routeSystemId.isNotEmpty) return routeSystemId;

  final orgSystemId = (user?['orgSystemId'] ?? '').toString().trim();
  if (orgSystemId.isNotEmpty) return orgSystemId;

  return _kFallbackRouteSystemId;
}

String? _storedActiveTenantType() {
  final user = _readStoredUser();
  final value = (user?['activeTenantType'] ?? user?['active_tenant_type'] ?? '')
      .toString()
      .trim()
      .toUpperCase();
  if (value == 'ORG' || value == 'BRANCH') {
    return value;
  }
  return null;
}

String? _storedActiveTenantId() {
  final user = _readStoredUser();
  final value = (user?['activeTenantId'] ?? user?['active_tenant_id'] ?? '')
      .toString()
      .trim();
  return value.isEmpty ? null : value;
}

class _ModuleActionRequirement {
  const _ModuleActionRequirement({
    required this.moduleKey,
    required this.action,
  });

  final String moduleKey;
  final String action;
}

class _RoutePermissionRule {
  const _RoutePermissionRule(this.prefix, this.moduleKey);

  final String prefix;
  final String moduleKey;
}

const List<_RoutePermissionRule> _kRoutePermissionRules = [
  _RoutePermissionRule('/settings/users', 'users_roles'),
  _RoutePermissionRule('/settings/roles', 'users_roles'),
  _RoutePermissionRule('/settings/branches', 'branches'),
  _RoutePermissionRule('/settings/warehouses', 'warehouses'),
  _RoutePermissionRule('/settings/zones', 'zones'),
  _RoutePermissionRule('/settings', 'general_prefs'),

  _RoutePermissionRule('/items/composite-items', 'composite_items'),
  _RoutePermissionRule('/items/item-groups', 'item_groups'),
  _RoutePermissionRule('/items/mapping', 'item_mapping'),
  _RoutePermissionRule('/pricelists/price-lists', 'price_list'),
  _RoutePermissionRule('/items', 'item'),

  _RoutePermissionRule('/inventory/assemblies', 'assemblies'),
  _RoutePermissionRule('/inventory/adjustments', 'inventory_adjustments'),
  _RoutePermissionRule('/inventory/picklists', 'picklists'),
  _RoutePermissionRule('/inventory/packages', 'packages'),
  _RoutePermissionRule('/inventory/shipments', 'shipments'),
  _RoutePermissionRule('/inventory/transfer-orders', 'transfer_orders'),
  _RoutePermissionRule('/inventory/stock-counts', 'stock_count'),

  _RoutePermissionRule('/sales/customers', 'customers'),
  _RoutePermissionRule('/sales/quotations', 'quotations'),
  _RoutePermissionRule('/sales/retainer-invoices', 'retainer_invoices'),
  _RoutePermissionRule('/sales/orders', 'sales_orders'),
  _RoutePermissionRule('/sales/invoices', 'invoices'),
  _RoutePermissionRule('/sales/delivery-challans', 'delivery_challans'),
  _RoutePermissionRule('/sales/payments-received', 'customer_payments'),
  _RoutePermissionRule('/sales/returns', 'sales_returns'),
  _RoutePermissionRule('/sales/credit-notes', 'credit_notes'),
  _RoutePermissionRule('/sales/e-way-bills', 'ewaybill_perms'),
  _RoutePermissionRule('/sales/payment-links', 'payment_links'),
  _RoutePermissionRule('/sales/recurring-invoices', 'recurring_invoices'),

  _RoutePermissionRule('/purchases/vendors', 'vendors'),
  _RoutePermissionRule('/purchases/expenses', 'expenses'),
  _RoutePermissionRule('/purchases/recurring-expenses', 'recurring_expenses'),
  _RoutePermissionRule('/purchases/purchase-orders', 'purchase_orders'),
  _RoutePermissionRule('/purchases/purchase-receives', 'purchase_receives'),
  _RoutePermissionRule('/purchases/purchase-returns', 'purchase_returns'),
  _RoutePermissionRule('/purchases/bills', 'bills'),
  _RoutePermissionRule('/purchases/recurring-bills', 'recurring_bills'),
  _RoutePermissionRule('/purchases/payments-made', 'vendor_payments'),
  _RoutePermissionRule('/purchases/vendor-credits', 'vendor_credits'),

  _RoutePermissionRule(
    '/accountant/manual-journals/templates',
    'journal_templates',
  ),
  _RoutePermissionRule(
    '/accountant/manual-journals/journal-template-creation',
    'journal_templates',
  ),
  _RoutePermissionRule('/accountant/manual-journals', 'manual_journals'),
  _RoutePermissionRule('/accountant/recurring-journals', 'recurring_journals'),
  _RoutePermissionRule('/accountant/bulk-update', 'bulk_update'),
  _RoutePermissionRule(
    '/accountant/transaction-locking',
    'transaction_locking',
  ),
  _RoutePermissionRule('/accountant/opening-balances', 'opening_balances'),
  _RoutePermissionRule('/accountant/settings', 'accountant_settings'),
  _RoutePermissionRule(
    '/accountant/transactions-report',
    'journal_entry_lines',
  ),
  _RoutePermissionRule('/accounts/chart-of-accounts', 'chart_of_accounts'),
  _RoutePermissionRule('/accounts/opening-balances', 'opening_balances'),

  _RoutePermissionRule('/reports', 'reports'),
  _RoutePermissionRule('/documents', 'documents'),
  _RoutePermissionRule('/audit-logs', 'audit_logs'),
  _RoutePermissionRule('/home', 'dashboard_charts'),
];

String _stripOrgPrefix(String path) {
  return path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
}

String? _extractOrgSystemId(String path) {
  final match = RegExp(r'^/(\d{10,20})(?:/|$)').firstMatch(path);
  return match?.group(1);
}

String _resolveActionForPath(String normalizedPath) {
  if (normalizedPath.contains('/create') || normalizedPath.endsWith('/new')) {
    return 'create';
  }
  if (normalizedPath.contains('/edit') ||
      normalizedPath.contains('/update') ||
      normalizedPath.endsWith('/journal-template-creation')) {
    return 'edit';
  }
  return 'view';
}

_ModuleActionRequirement? _resolveRoutePermissionRequirement(String fullPath) {
  final normalizedPath = _stripOrgPrefix(fullPath);
  if (normalizedPath.isEmpty || normalizedPath == '/') {
    return null;
  }

  for (final rule in _kRoutePermissionRules) {
    if (normalizedPath == rule.prefix ||
        normalizedPath.startsWith('${rule.prefix}/')) {
      return _ModuleActionRequirement(
        moduleKey: rule.moduleKey,
        action: _resolveActionForPath(normalizedPath),
      );
    }
  }
  return null;
}

bool _isAdminOnlyModule(String moduleKey) =>
    moduleKey == 'users_roles' || moduleKey == 'audit_logs';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  observers: PerformanceMonitoringConfig.enabled
      ? <NavigatorObserver>[ZerpaiNavigatorObserver()]
      : const <NavigatorObserver>[],
  refreshListenable: authSessionExpiryNotifier,
  initialLocation: '/$_kFallbackRouteSystemId/home',
  debugLogDiagnostics: false,
  redirect: (context, state) {
    final path = state.uri.path;
    if (!_kEnableAuth) {
      if (path == '/login' ||
          path == '/forgot-password' ||
          path == '/reset-password') {
        return '/${_storedRouteSystemId()}/home';
      }

      if (RegExp(r'^/\d{10,20}(/|$)').hasMatch(path)) {
        return null;
      }

      final query = state.uri.query.isNotEmpty ? '?${state.uri.query}' : '';
      return '/${_storedRouteSystemId()}${path == '/' ? '/home' : path}$query';
    }

    final isAuthenticated = _hasStoredAuthSession();
    const skipPrefixes = [
      '/login',
      '/forgot-password',
      '/reset-password',
      '/not-found',
      '/unauthorized',
      '/error',
      '/maintenance',
    ];
    final isPublicRoute = skipPrefixes.any(
      (p) => path == p || path.startsWith('$p/'),
    );

    if (isPublicRoute) {
      if (isAuthenticated && (path == '/login' || path == '/forgot-password')) {
        return '/${_storedRouteSystemId()}/home';
      }
      return null;
    }

    if (!isAuthenticated) {
      return AppRoutes.authLogin;
    }

    if (RegExp(r'^/\d{10,20}(/|$)').hasMatch(path)) {
      final requirement = _resolveRoutePermissionRequirement(path);
      if (requirement != null &&
          _isAdminOnlyModule(requirement.moduleKey) &&
          !_isStoredAdmin()) {
        final orgSystemId = _extractOrgSystemId(path) ?? _storedRouteSystemId();
        return '/$orgSystemId/home';
      }
      if (requirement != null &&
          !_hasStoredModuleAction(
            requirement.moduleKey,
            action: requirement.action,
          )) {
        final orgSystemId = _extractOrgSystemId(path) ?? _storedRouteSystemId();
        return '/$orgSystemId/home';
      }
      return null;
    }
    final query = state.uri.query.isNotEmpty ? '?${state.uri.query}' : '';
    return '/${_storedRouteSystemId()}${path == '/' ? '/home' : path}$query';
  },
  errorBuilder: (context, state) =>
      ZerpaiShell(child: ErrorPage(errorMessage: state.error?.toString())),
  routes: [
    GoRoute(
      path: AppRoutes.authLogin,
      name: AppRoutes.authLogin,
      builder: (context, state) => const AuthLoginPage(),
    ),
    GoRoute(
      path: AppRoutes.authForgotPassword,
      name: AppRoutes.authForgotPassword,
      builder: (context, state) => const AuthForgotPasswordPage(),
    ),
    GoRoute(
      path: AppRoutes.authResetPassword,
      name: AppRoutes.authResetPassword,
      builder: (context, state) => const AuthResetPasswordPage(),
    ),

    // Full-screen error routes (outside shell — no sidebar, no org prefix)
    GoRoute(
      path: '/not-found',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return NotFoundPage(
          requestedRoute: extra?['requestedRoute'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/unauthorized',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return UnauthorizedPage(
          requiredPermission: extra?['requiredPermission'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/maintenance',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return MaintenancePage(
          message: extra?['message'] as String?,
          estimatedCompletion: extra?['estimatedCompletion'] as DateTime?,
        );
      },
    ),
    GoRoute(
      path: '/error',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ErrorPage(
          errorMessage: extra?['errorMessage'] as String?,
          errorCode: extra?['errorCode'] as String?,
          error: extra?['error'],
          stackTrace: extra?['stackTrace'] as StackTrace?,
        );
      },
    ),

    // All app routes under /:orgSystemId
    GoRoute(
      path: '/:orgSystemId',
      redirect: (context, state) {
        // Redirect bare /:orgSystemId (no sub-path) to home
        final orgId = state.pathParameters['orgSystemId']!;
        if (state.uri.path == '/$orgId') return '/$orgId/home';
        return null;
      },
      routes: [
        // Full-screen routes (no sidebar) — must be BEFORE ShellRoute so they
        // are matched before the shell's :id wildcard children can grab them.
        GoRoute(
          path: 'procurement/purchase-requests/create',
          name: AppRoutes.procurementPurchaseRequestsCreate,
          pageBuilder: (context, state) {
            final extra = state.extra as DemandPoolPayload?;
            final editId = state.uri.queryParameters['id'];
            return CustomTransitionPage(
              key: state.pageKey,
              fullscreenDialog: true,
              child: ProcurementPurchaseRequestsCreatePage(
                fromDemandPool: extra,
                editId: editId,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) =>
                      FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        ShellRoute(
          builder: (context, state, child) => ZerpaiShell(child: child),
          routes: [
            // Home
            GoRoute(
              path: 'home',
              name: AppRoutes.home,
              builder: (context, state) => const HomeDashboardScreen(),
            ),
            ...buildSettingsRoutes(
              storedActiveTenantType: _storedActiveTenantType,
              storedActiveTenantId: _storedActiveTenantId,
            ),

            // Items
            GoRoute(
              path: 'items/report',
              name: AppRoutes.itemsReport,
              builder: (context, state) => ItemsReportScreen(
                initialFilter: state.uri.queryParameters['filter'],
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'items/create',
              name: AppRoutes.itemsCreate,
              builder: (context, state) {
                final extra = state.extra;
                if (extra is Item) {
                  return ItemCreateScreen(
                    item: extra,
                    initialTab: state.uri.queryParameters['tab'],
                  );
                }
                if (extra is Map && extra['cloneItem'] is Item) {
                  return ItemCreateScreen(
                    item: extra['cloneItem'] as Item,
                    isClone: true,
                    initialTab: state.uri.queryParameters['tab'],
                  );
                }
                return ItemCreateScreen(
                  initialTab: state.uri.queryParameters['tab'],
                );
              },
            ),
            GoRoute(
              path: 'items/edit/:id',
              name: AppRoutes.itemsEdit,
              builder: (context, state) {
                final id = state.pathParameters['id'];
                final extra = state.extra;
                if (extra is Item) {
                  return ItemCreateScreen(
                    itemId: id,
                    item: extra,
                    initialTab: state.uri.queryParameters['tab'],
                  );
                }
                return ItemCreateScreen(
                  itemId: id,
                  initialTab: state.uri.queryParameters['tab'],
                );
              },
            ),
            GoRoute(
              path: 'items/detail/:id',
              name: AppRoutes.itemsDetail,
              builder: (context, state) {
                final id = state.pathParameters['id'];
                return ItemDetailScreen(
                  itemId: id,
                  initialQueryParameters: state.uri.queryParameters,
                );
              },
              routes: [
                GoRoute(
                  path: 'opening-stock',
                  name: AppRoutes.itemsOpeningStock,
                  builder: (context, state) => ItemsOpeningStockScreen(
                    itemId: state.pathParameters['id']!,
                    initialQueryParameters: state.uri.queryParameters,
                  ),
                ),
              ],
            ),
            // compositeItemsCreate must come BEFORE compositeItems to avoid ':id' matching 'create'
            GoRoute(
              path: 'items/composite-items/create',
              name: AppRoutes.compositeItemsCreate,
              builder: (context, state) => CompositeItemsCreatePage(
                itemId: state.uri.queryParameters['editId'],
                isClone: state.uri.queryParameters['clone'] == 'true',
              ),
            ),
            GoRoute(
              path: 'items/composite-items',
              name: AppRoutes.compositeItems,
              builder: (context, state) => const CompositeItemsReportPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: AppRoutes.compositeItemsDetail,
                  builder: (context, state) => CompositeItemsOverview(
                    itemId: state.pathParameters['id']!,
                    initialTab: state.uri.queryParameters['tab'] ?? 'Overview',
                  ),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (context, state) => CompositeItemsCreatePage(
                    itemId: state.pathParameters['id'],
                  ),
                ),
                GoRoute(
                  path: ':id/clone',
                  builder: (context, state) => CompositeItemsCreatePage(
                    itemId: state.pathParameters['id'],
                    isClone: true,
                  ),
                ),
                GoRoute(
                  path: ':id/adjust-stock',
                  builder: (context, state) => CompositeItemsOverview(
                    itemId: state.pathParameters['id']!,
                    isAdjustingStock: true,
                  ),
                ),
              ],
            ),

            // ── Sales ────────────────────────────────────────────────────
            // Deep-link query params (applies across all sales list routes):
            //   ?q=<search>          — pre-fill search field
            //   ?filter=<value>      — pre-select a status filter tab
            //   ?status=<value>      — alias for filter (used by external links)
            // Create-screen deep-link params:
            //   ?customerId=<id>     — pre-select customer
            //   ?cloneId=<id>        — clone an existing document
            //   ?fromOrderId=<id>    — convert a sales order to invoice/challan
            //   ?fromInvoiceId=<id>  — associate invoice when creating payment
            //   ?fromChallanId=<id>  — associate challan when creating e-way bill
            // Detail-screen deep-link params:
            //   ?tab=<name>          — open a specific tab (overview/comments/history)
            GoRoute(
              path: 'sales/customers',
              name: AppRoutes.salesCustomers,
              builder: (context, state) => SalesCustomerListScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesCustomersCreate,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: const ValueKey('sales-customers-create-page'),
                    child: SalesCustomerCreateScreen(
                      key: const ValueKey('sales-customers-create'),
                      initialCustomer: state.extra as SalesCustomer?,
                      initialTab: state.uri.queryParameters['tab'],
                    ),
                  ),
                ),
                GoRoute(
                  path: ':id/edit',
                  name: AppRoutes.salesCustomersEdit,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: ValueKey(
                      'sales-customers-edit-page-${state.pathParameters['id']}',
                    ),
                    child: SalesCustomerCreateScreen(
                      key: ValueKey(
                        'sales-customers-edit-${state.pathParameters['id']}',
                      ),
                      customerId: state.pathParameters['id'],
                      initialTab: state.uri.queryParameters['tab'],
                    ),
                  ),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesCustomersDetail,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: ValueKey(
                      'sales-customers-detail-page-${state.pathParameters['id']}',
                    ),
                    child: SalesCustomerOverviewScreen(
                      key: ValueKey(
                        'sales-customers-detail-${state.pathParameters['id']}',
                      ),
                      id: state.pathParameters['id']!,
                      initialTab: state.uri.queryParameters['tab'],
                    ),
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/quotations',
              name: AppRoutes.salesQuotations,
              builder: (context, state) => const SalesQuotationReportPage(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesQuotationsCreate,
                  builder: (context, state) => const SalesQuoteCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesQuotationsDetail,
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'quotation',
                    initialTab: state.uri.queryParameters['tab'],
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/retainer-invoices',
              name: AppRoutes.salesRetainerInvoices,
              builder: (context, state) => const RetainerInvoicesListPage(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesRetainerInvoicesCreate,
                  builder: (context, state) =>
                      const RetainerInvoicesCreatePage(),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesRetainerInvoicesDetail,
                  builder: (context, state) => RetainerInvoiceOverviewScreen(
                    invoiceId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/orders',
              name: AppRoutes.salesOrders,
              builder: (context, state) => SalesOrderOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
                initialFilter:
                    state.uri.queryParameters['filter'] ??
                    state.uri.queryParameters['status'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesOrdersCreate,
                  builder: (context, state) {
                    final initialOrder = state.extra;
                    return SalesOrderCreateScreen(
                      initialOrder: initialOrder is SalesOrder
                          ? initialOrder
                          : null,
                      initialCustomerId:
                          state.uri.queryParameters['customerId'],
                      cloneId: state.uri.queryParameters['cloneId'],
                      isClone: state.uri.queryParameters['clone'] == 'true',
                    );
                  },
                ),
                GoRoute(
                  path: ':id/edit',
                  name: AppRoutes.salesOrdersEdit,
                  builder: (context, state) {
                    final initialOrder = state.extra;
                    return SalesOrderCreateScreen(
                      initialOrder: initialOrder is SalesOrder
                          ? initialOrder
                          : null,
                      initialOrderId: state.pathParameters['id'],
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesOrdersDetail,
                  builder: (context, state) => SalesOrderOverviewScreen(
                    initialSearchQuery: state.uri.queryParameters['q'],
                    initialSelectedId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: ':id/email',
                  name: AppRoutes.salesOrdersEmail,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return SalesOrderEmailScreen(orderId: id);
                  },
                ),
              ],
            ),

            GoRoute(
              path: 'sales/invoices',
              name: AppRoutes.salesInvoices,
              builder: (context, state) => const SalesInvoiceOverviewScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesInvoicesCreate,
                  builder: (context, state) => SalesInvoiceCreateScreen(
                    initialCustomerId: state.uri.queryParameters['customerId'],
                    fromOrderId: state.uri.queryParameters['fromOrderId'],
                    fromPackageId: state.uri.queryParameters['fromPackageId'],
                    cloneId: state.uri.queryParameters['cloneId'],
                    isInstant: state.uri.queryParameters['instant'] == 'true',
                  ),
                ),
                GoRoute(
                  path: ':id/edit',
                  name: AppRoutes.salesInvoicesEdit,
                  builder: (context, state) {
                    final initialOrder = state.extra;
                    return SalesInvoiceCreateScreen(
                      initialOrder: initialOrder is SalesOrder
                          ? initialOrder
                          : null,
                      initialOrderId: state.pathParameters['id'],
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesInvoicesDetail,
                  builder: (context, state) => SalesInvoiceOverviewScreen(
                    initialSelectedId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/delivery-challans',
              name: AppRoutes.salesDeliveryChallans,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Delivery Challans'),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesDeliveryChallansCreate,
                  builder: (context, state) => SalesChallanCreateScreen(
                    initialCustomerId: state.uri.queryParameters['customerId'],
                    fromOrderId: state.uri.queryParameters['fromOrderId'],
                    cloneId: state.uri.queryParameters['cloneId'],
                  ),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesDeliveryChallansDetail,
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'delivery_challan',
                    initialTab: state.uri.queryParameters['tab'],
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/payments-received',
              name: AppRoutes.salesPaymentsReceived,
              builder: (context, state) => const PaymentRecievesReportPage(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesPaymentsReceivedCreate,
                  builder: (context, state) {
                    final editId =
                        state.uri.queryParameters['editId'] ??
                        state.uri.queryParameters['id'];
                    return SalesPaymentCreateScreen(
                      initialCustomerId:
                          state.uri.queryParameters['customerId'],
                      fromInvoiceId: state.uri.queryParameters['fromInvoiceId'],
                      cloneId: state.uri.queryParameters['cloneId'],
                      editPaymentId: editId,
                      initialTab: 0,
                    );
                  },
                ),
                GoRoute(
                  path: 'customer-advance',
                  name: AppRoutes.salesCustomerAdvanceCreate,
                  builder: (context, state) {
                    final editId =
                        state.uri.queryParameters['editId'] ??
                        state.uri.queryParameters['id'];
                    return SalesPaymentCreateScreen(
                      editPaymentId: editId,
                      initialTab: 1,
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesPaymentsReceivedDetail,
                  builder: (context, state) => PaymentRecievesOverview(
                    paymentId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: ':id/refund',
                  builder: (context, state) => PaymentRecievesOverview(
                    paymentId: state.pathParameters['id']!,
                    isRefund: true,
                  ),
                ),
              ],
            ),

            // Sales — Returns
            GoRoute(
              path: 'sales/returns',
              name: AppRoutes.salesReturns,
              builder: (context, state) => const SalesReturnsOverviewPage(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesReturnsCreate,
                  builder: (context, state) => const SalesReturnsCreatePage(),
                ),
                GoRoute(
                  path: ':id([0-9a-fA-F-]{36})',
                  name: AppRoutes.salesReturnsDetail,
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'sales_return',
                    initialTab: state.uri.queryParameters['tab'],
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/credit-notes',
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
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesCreditNotesDetail,
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'credit_note',
                    initialTab: state.uri.queryParameters['tab'],
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/e-way-bills',
              name: AppRoutes.salesEWayBills,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'e-Way Bills'),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesEWayBillsCreate,
                  builder: (context, state) => SalesEWayBillCreateScreen(
                    initialCustomerId: state.uri.queryParameters['customerId'],
                    fromChallanId: state.uri.queryParameters['fromChallanId'],
                    cloneId: state.uri.queryParameters['cloneId'],
                  ),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesEWayBillsDetail,
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'eway_bill',
                    initialTab: state.uri.queryParameters['tab'],
                  ),
                ),
              ],
            ),

            // Sales — Payment Links
            GoRoute(
              path: 'sales/payment-links',
              name: AppRoutes.salesPaymentLinks,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Payment Links'),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesPaymentLinksCreate,
                  builder: (context, state) => SalesPaymentLinkCreateScreen(
                    initialCustomerId: state.uri.queryParameters['customerId'],
                    fromInvoiceId: state.uri.queryParameters['fromInvoiceId'],
                  ),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesPaymentLinksDetail,
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'payment_link',
                    initialTab: state.uri.queryParameters['tab'],
                  ),
                ),
              ],
            ),

            // Sales — Recurring Invoices
            GoRoute(
              path: 'sales/recurring-invoices',
              name: AppRoutes.salesRecurringInvoices,
              builder: (context, state) => const RecurringInvoicesReportPage(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesRecurringInvoicesCreate,
                  builder: (context, state) =>
                      const RecurringInvoicesCreatePage(),
                ),
                GoRoute(
                  path: 'preferences',
                  name: AppRoutes.salesRecurringInvoicesPreferences,
                  builder: (context, state) =>
                      const RecurringInvoicesOverviewPage(
                        showPreferencesOverlayOnLoad: true,
                        closePreferencesToPreviousRoute: true,
                      ),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesRecurringInvoicesDetail,
                  builder: (context, state) => RecurringInvoicesOverviewPage(
                    invoiceId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),

            // Assemblies — create declared before the list/:id route so the
            // literal 'create' segment isn't captured by ':id'.
            GoRoute(
              path: 'inventory/assemblies',
              name: AppRoutes.assemblies,
              builder: (context, state) => const AssemblyListScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.assembliesCreate,
                  builder: (context, state) => const AssemblyCreateScreen(),
                ),
              ],
            ),

            // Price Lists
            GoRoute(
              path: 'pricelists/price-lists',
              name: AppRoutes.priceLists,
              builder: (context, state) => const PriceListOverviewScreen(),
            ),
            GoRoute(
              path: 'pricelists/price-lists/create',
              name: AppRoutes.priceListsCreate,
              builder: (context, state) => const PriceListCreateScreen(),
            ),
            GoRoute(
              path: 'pricelists/price-lists/edit/:id',
              name: AppRoutes.priceListsEdit,
              builder: (context, state) => PriceListCreateScreen(
                priceListId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'pricelists/branch-price-lists',
              name: AppRoutes.branchPriceLists,
              builder: (context, state) =>
                  const BranchPriceListOverviewScreen(),
            ),
            GoRoute(
              path: 'pricelists/branch-price-lists/create',
              name: AppRoutes.branchPriceListsCreate,
              builder: (context, state) => const BranchPriceListCreateScreen(),
            ),
            GoRoute(
              path: 'pricelists/branch-price-lists/edit/:id',
              name: AppRoutes.branchPriceListsEdit,
              builder: (context, state) => BranchPriceListCreateScreen(
                branchPriceListId: state.pathParameters['id'],
              ),
            ),

            // Inventory
            GoRoute(
              path: 'inventory/adjustments',
              name: AppRoutes.inventoryAdjustments,
              builder: (context, state) => InventoryAdjustmentsOverviewScreen(
                initialAdjustmentId: state.uri.queryParameters['adjustmentId'],
              ),
            ),
            GoRoute(
              path: 'inventory/adjustments/create',
              name: AppRoutes.inventoryAdjustmentsCreate,
              builder: (context, state) =>
                  const InventoryAdjustmentsCreateScreen(),
            ),
            GoRoute(
              path: 'inventory/adjustments/edit/:id',
              name: AppRoutes.inventoryAdjustmentsEdit,
              builder: (context, state) => InventoryAdjustmentsCreateScreen(
                initialAdjustmentId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'inventory/picklists',
              name: AppRoutes.picklists,
              builder: (context, state) => const InventoryPicklistsListScreen(),
            ),
            GoRoute(
              path: 'inventory/picklists/create',
              name: AppRoutes.picklistsCreate,
              builder: (context, state) => InventoryPicklistsCreateScreen(
                salesOrderId: state.uri.queryParameters['salesOrderId'],
              ),
            ),
            GoRoute(
              path: 'inventory/picklists/edit/:id',
              name: AppRoutes.picklistsEdit,
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                final mode = state.uri.queryParameters['mode'] ?? 'edit';
                if (mode == 'update') {
                  return InventoryPicklistsUpdateScreen(id: id);
                }
                return InventoryPicklistsCreateScreen(id: id);
              },
            ),
            GoRoute(
              path: 'inventory/picklists/:id',
              name: AppRoutes.picklistsDetail,
              builder: (context, state) =>
                  InventoryPicklistsListScreen(id: state.pathParameters['id']),
            ),
            GoRoute(
              path: 'inventory/packages',
              name: AppRoutes.packages,
              builder: (context, state) => const InventoryPackagesListScreen(),
            ),
            GoRoute(
              path: 'inventory/packages/create',
              name: AppRoutes.packagesCreate,
              builder: (context, state) => InventoryPackagesCreateScreen(
                salesOrderId: state.uri.queryParameters['salesOrderId'],
              ),
            ),
            GoRoute(
              path: 'inventory/packages/edit/:id',
              name: AppRoutes.packagesEdit,
              builder: (context, state) =>
                  InventoryPackagesCreateScreen(id: state.pathParameters['id']),
            ),
            GoRoute(
              path: 'inventory/packages/:id',
              name: AppRoutes.packagesDetail,
              builder: (context, state) =>
                  InventoryPackagesListScreen(id: state.pathParameters['id']),
            ),
            GoRoute(
              path: 'inventory/shipments',
              name: AppRoutes.shipments,
              builder: (context, state) => const InventoryShipmentsListScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.shipmentsCreate,
                  builder: (context, state) => InventoryShipmentsCreateScreen(
                    salesOrderId: state.uri.queryParameters['salesOrderId'],
                  ),
                ),
                GoRoute(
                  path: 'edit/:id',
                  name: AppRoutes.shipmentsEdit,
                  builder: (context, state) => InventoryShipmentsEditScreen(
                    shipmentId: state.pathParameters['id']!,
                  ),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => InventoryShipmentsListScreen(
                    id: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'inventory/transfer-orders',
              name: AppRoutes.transferOrders,
              builder: (context, state) => InventoryTransferOrdersListScreen(
                id:
                    state.uri.queryParameters['id'] ??
                    state.uri.queryParameters['transferId'],
              ),
            ),
            GoRoute(
              path: 'inventory/transfer-orders/create',
              name: AppRoutes.transferOrdersCreate,
              builder: (context, state) =>
                  const InventoryTransferOrdersCreateScreen(),
            ),
            GoRoute(
              path: 'inventory/transfer-orders/edit/:id',
              name: AppRoutes.transferOrdersEdit,
              builder: (context, state) => InventoryTransferOrdersCreateScreen(
                transferId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'inventory/transfer-orders/:id',
              name: AppRoutes.transferOrdersDetail,
              builder: (context, state) => InventoryTransferOrdersListScreen(
                id: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'inventory/move-orders',
              name: AppRoutes.moveOrders,
              builder: (context, state) => InventoryMoveOrdersListScreen(
                id: state.uri.queryParameters['id'],
              ),
            ),
            GoRoute(
              path: 'inventory/move-orders/create',
              name: AppRoutes.moveOrdersCreate,
              builder: (context, state) =>
                  const InventoryMoveOrdersCreateScreen(),
            ),
            GoRoute(
              path: 'inventory/move-orders/:id',
              name: AppRoutes.moveOrdersDetail,
              builder: (context, state) =>
                  InventoryMoveOrdersListScreen(id: state.pathParameters['id']),
            ),
            GoRoute(
              path: 'inventory/stock-counts',
              name: AppRoutes.stockCounts,
              builder: (context, state) => const StockCountReportPage(),
            ),
            GoRoute(
              path: 'inventory/stock-counts/create',
              name: AppRoutes.stockCountsCreate,
              builder: (context, state) {
                final extra = state.extra;
                return StockCountCreatePage(
                  editCountId:
                      state.uri.queryParameters['editId'] ??
                      state.uri.queryParameters['id'],
                  startAsRecurring:
                      state.uri.queryParameters['recurring'] == 'true',
                  initialCount: extra is StockCount ? extra : null,
                );
              },
            ),
            GoRoute(
              path: 'inventory/stock-counts/recurring',
              name: AppRoutes.recurringStockCounts,
              builder: (context, state) =>
                  const RecurringStockCountReportPage(),
            ),
            GoRoute(
              path: 'inventory/stock-counts/:id/perform',
              name: AppRoutes.stockCountsPerform,
              builder: (context, state) => StockCountPerformPage(
                countId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: 'inventory/stock-counts/:id',
              name: AppRoutes.stockCountsDetail,
              builder: (context, state) => StockCountOverviewPage(
                countId: state.pathParameters['id'] ?? '',
              ),
            ),

            // Missing Module Placeholders
            GoRoute(
              path: 'items/item-groups',
              name: AppRoutes.itemGroups,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Item Groups'),
            ),
            GoRoute(
              path: 'items/item-groups/create',
              name: AppRoutes.itemGroupsCreate,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Item Group'),
            ),
            GoRoute(
              path: 'items/mapping',
              name: AppRoutes.itemMapping,
              builder: (context, state) => const ItemTradeSetupReportPage(),
            ),
            GoRoute(
              path: 'items/mapping/create',
              name: AppRoutes.itemMappingCreate,
              builder: (context, state) => const ItemTradeSetupCreatePage(),
            ),
            GoRoute(
              path: 'items/mapping/edit/:id',
              name: AppRoutes.itemMappingEdit,
              builder: (context, state) => ItemTradeSetupCreatePage(
                editProductId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'items/mapping/:id',
              name: AppRoutes.itemMappingDetail,
              builder: (context, state) =>
                  ItemTradeSetupOverviewPage(id: state.pathParameters['id']),
            ),
            GoRoute(
              path: 'items/trade-setup',
              name: AppRoutes.itemTradeSetup,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Item Trade Setup'),
            ),
            GoRoute(
              path: 'items/trade-setup/create',
              name: AppRoutes.itemTradeSetupCreate,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Create Item Trade Setup'),
            ),
            GoRoute(
              path: 'items/trade-setup/:id',
              name: AppRoutes.itemTradeSetupDetail,
              builder: (context, state) => PlaceholderScreen(
                title:
                    'Item Trade Setup details: ${state.pathParameters['id']}',
              ),
            ),

            // Purchases Module
            GoRoute(
              path: 'purchases',
              redirect: (context, state) => AppRoutes.purchasesVendors,
            ),
            GoRoute(
              path: 'purchases/vendors',
              name: AppRoutes.vendors,
              builder: (context, state) => const VendorsReportPage(),
            ),
            GoRoute(
              path: 'purchases/vendors/create',
              name: AppRoutes.vendorsCreate,
              builder: (context, state) =>
                  const PurchasesVendorsVendorCreateScreen(),
            ),
            GoRoute(
              path: 'purchases/vendors/:id/edit',
              name: AppRoutes.vendorsEdit,
              builder: (context, state) => PurchasesVendorsVendorCreateScreen(
                editVendorId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'purchases/vendors/:id/email',
              name: AppRoutes.vendorsEmail,
              builder: (context, state) =>
                  VendorsEmailPage(vendorId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'purchases/vendors/:id',
              name: AppRoutes.vendorsDetail,
              builder: (context, state) =>
                  VendorsOverviewPage(vendorId: state.pathParameters['id']),
            ),
            GoRoute(
              path: 'purchases/purchase-orders',
              name: AppRoutes.purchaseOrders,
              builder: (context, state) => PurchaseOrderOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
                initialFilter:
                    state.uri.queryParameters['filter'] ??
                    state.uri.queryParameters['status'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.purchaseOrdersCreate,
                  builder: (context, state) {
                    final initialOrder = state.extra;
                    final fromPr = state.uri.queryParameters['from_pr'] ??
                        state.uri.queryParameters['fromPr'] ??
                        state.uri.queryParameters['fromPurchaseRequest'];
                    return PurchaseOrderCreateScreen(
                      initialOrder: initialOrder is PurchaseOrder
                          ? initialOrder
                          : null,
                      fromPurchaseRequest: fromPr,
                      isClone: state.uri.queryParameters['clone'] == 'true',
                      isDropship:
                          state.uri.queryParameters['isDropship'] == 'true',
                      dropshipCustomerName:
                          state.uri.queryParameters['dropshipCustomerName'],
                      dropshipAddress:
                          state.uri.queryParameters['dropshipAddress'],
                    );
                  },
                ),
                GoRoute(
                  path: ':id/edit',
                  name: AppRoutes.purchaseOrdersEdit,
                  builder: (context, state) {
                    final initialOrder = state.extra;
                    return PurchaseOrderCreateScreen(
                      initialOrder: initialOrder is PurchaseOrder
                          ? initialOrder
                          : null,
                      initialOrderId: state.pathParameters['id'],
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.purchaseOrdersDetail,
                  builder: (context, state) => PurchaseOrderOverviewScreen(
                    initialSelectedId: state.pathParameters['id'],
                    initialSearchQuery: state.uri.queryParameters['q'],
                    initialFilter:
                        state.uri.queryParameters['filter'] ??
                        state.uri.queryParameters['status'],
                  ),
                ),
                GoRoute(
                  path: ':id/email',
                  name: AppRoutes.purchaseOrdersEmail,
                  builder: (context, state) => PurchaseOrderEmailScreen(
                    orderId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'purchases/purchase-receives',
              name: AppRoutes.purchaseReceives,
              builder: (context, state) =>
                  const PurchasesPurchaseReceivesListScreen(),
            ),
            GoRoute(
              path: 'purchases/purchase-receives/create',
              name: AppRoutes.purchaseReceivesCreate,
              builder: (context, state) =>
                  PurchasesPurchaseReceivesCreateScreen(
                    initialPoId: state.uri.queryParameters['poId'],
                  ),
            ),
            GoRoute(
              path: 'purchases/purchase-receives/edit/:id',
              name: AppRoutes.purchaseReceivesEdit,
              builder: (context, state) =>
                  PurchasesPurchaseReceivesCreateScreen(
                    initialReceiveId: state.pathParameters['id'],
                  ),
            ),
            GoRoute(
              path: 'purchases/purchase-returns',
              name: AppRoutes.purchaseReturns,
              builder: (context, state) => PurchaseReturnsReportPage(
                initialId: state.uri.queryParameters['id'],
                initialStatus: state.uri.queryParameters['status'],
                initialSearch: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'purchases/purchase-returns/create',
              name: AppRoutes.purchaseReturnsCreate,
              builder: (context, state) => const PurchaseReturnsCreatePage(),
            ),
            GoRoute(
              path: 'purchases/purchase-returns/edit/:id',
              name: AppRoutes.purchaseReturnsEdit,
              builder: (context, state) => PurchaseReturnsCreatePage(
                purchaseReturnId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'purchases/purchase-returns/:id',
              name: AppRoutes.purchaseReturnsDetail,
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return PurchaseReturnDetailPage(purchaseReturnId: id);
              },
            ),
            GoRoute(
              path: 'purchases/expenses',
              name: AppRoutes.expenses,
              builder: (context, state) => const ExpensesReportPage(),
            ),
            GoRoute(
              path: 'purchases/expenses/create',
              name: AppRoutes.expensesCreate,
              builder: (context, state) => const ExpensesCreatePage(),
            ),
            GoRoute(
              path: 'purchases/expenses/receipts-inbox',
              name: AppRoutes.expensesReceiptsInbox,
              builder: (context, state) => const ExpensesReceiptsInboxPage(),
            ),
            GoRoute(
              path: 'purchases/expenses/:id',
              builder: (context, state) {
                final expenseId = state.pathParameters['id'] ?? '';
                return ExpensesOverview(expenseId: expenseId);
              },
            ),
            GoRoute(
              path: 'purchases/recurring-expenses',
              name: AppRoutes.recurringExpenses,
              builder: (context, state) =>
                  const PurchasesRecurringExpensesPage(),
            ),
            GoRoute(
              path: 'purchases/recurring-expenses/create',
              name: AppRoutes.recurringExpensesCreate,
              builder: (context, state) =>
                  const PurchasesRecurringExpensesCreatePage(),
            ),
            GoRoute(
              path: 'purchases/recurring-expenses/custom-view',
              name: AppRoutes.recurringExpensesCustomView,
              builder: (context, state) =>
                  const PurchasesRecurringExpensesCustomViewPage(),
            ),
            GoRoute(
              path: 'purchases/bills',
              name: AppRoutes.bills,
              builder: (context, state) => const PurchasesBillsListScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.billsCreate,
                  builder: (context, state) {
                    return PurchasesBillCreateScreen(
                      editBillId: state.uri.queryParameters['editId'],
                      cloneBillId: state.uri.queryParameters['cloneId'],
                      poId: state.uri.queryParameters['poId'],
                      receiveId: state.uri.queryParameters['receiveId'],
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.billsDetail,
                  builder: (context, state) => PurchasesBillsListScreen(
                    initialSelectedId: state.pathParameters['id'],
                    initialSearchQuery: state.uri.queryParameters['q'],
                    initialFilter:
                        state.uri.queryParameters['filter'] ??
                        state.uri.queryParameters['status'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'purchases/payments-made',
              name: AppRoutes.paymentsMade,
              builder: (context, state) => const PaymentsMadeOverviewPage(),
            ),
            GoRoute(
              path: 'purchases/payments-made/create',
              name: AppRoutes.paymentsMadeCreate,
              builder: (context, state) {
                final billIds = state.uri.queryParameters['billIds'];
                final paymentId = state.uri.queryParameters['paymentId'];
                final paymentNumber =
                    state.uri.queryParameters['paymentNumber'];
                return CreatePaymentMadePage(
                  billIds: billIds != null && billIds.isNotEmpty
                      ? billIds.split(',')
                      : const [],
                  paymentId: paymentId != null && paymentId.isNotEmpty
                      ? paymentId
                      : null,
                  paymentNumber:
                      paymentNumber != null && paymentNumber.isNotEmpty
                      ? paymentNumber
                      : null,
                );
              },
            ),
            GoRoute(
              path: 'purchases/payments-made/report',
              name: AppRoutes.paymentsMadeReport,
              builder: (context, state) => const PaymentsMadeReportPage(),
            ),
            GoRoute(
              path: 'purchases/vendor-credits',
              name: AppRoutes.vendorCredits,
              builder: (context, state) => const VendorCreditsOverviewPage(),
            ),
            GoRoute(
              path: 'purchases/vendor-credits/report',
              name: AppRoutes.vendorCreditsReport,
              builder: (context, state) => const VendorCreditsOverviewPage(),
            ),
            GoRoute(
              path: 'purchases/vendor-credits/create',
              name: AppRoutes.vendorCreditsCreate,
              builder: (context, state) {
                final vendorCreditId =
                    state.uri.queryParameters['vendorCreditId'];
                return VendorCreditsCreatePage(vendorCreditId: vendorCreditId);
              },
            ),
            GoRoute(
              path: 'purchases/vendor-credits/refund',
              name: AppRoutes.vendorCreditsRefund,
              builder: (context, state) {
                final vendorCreditId =
                    state.uri.queryParameters['vendorCreditId'] ??
                    state.uri.queryParameters['id'] ??
                    '';
                return VendorCreditRefundPage(
                  vendorCreditId: vendorCreditId,
                );
              },
            ),
            GoRoute(
              path: 'documents',
              name: AppRoutes.documents,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Documents'),
            ),
            GoRoute(
              path: 'audit-logs',
              name: AppRoutes.auditLogs,
              builder: (context, state) => AuditLogsScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),

            // Reports
            GoRoute(
              path: 'reports',
              name: AppRoutes.reports,
              builder: (context, state) => ReportsCenterScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'reports/daily-sales',
              name: AppRoutes.reportDailySales,
              builder: (context, state) => const ReportDailySalesScreen(),
            ),

            GoRoute(
              path: 'accountant/manual-journals',
              name: AppRoutes.accountantManualJournals,
              builder: (context, state) => ManualJournalOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.accountantManualJournalsCreate,
                  builder: (context, state) {
                    final extra = state.extra;
                    ManualJournal? initialJournal;
                    ManualJournalTemplate? template;
                    bool showTemplates = false;

                    if (extra is ManualJournal) {
                      initialJournal = extra;
                    } else if (extra is ManualJournalTemplate) {
                      template = extra;
                    } else if (extra is Map<String, dynamic>) {
                      initialJournal =
                          extra['initialJournal'] as ManualJournal?;
                      template = extra['template'] as ManualJournalTemplate?;
                      showTemplates = extra['showTemplates'] as bool? ?? false;
                    }

                    return ManualJournalCreateScreen(
                      initialJournal: initialJournal,
                      template: template,
                      showTemplates: showTemplates,
                    );
                  },
                ),
                GoRoute(
                  path: ':id/edit',
                  name: AppRoutes.accountantManualJournalsEdit,
                  builder: (context, state) {
                    final extra = state.extra;
                    return ManualJournalCreateScreen(
                      initialJournal: extra is ManualJournal ? extra : null,
                      initialJournalId: state.pathParameters['id'],
                    );
                  },
                ),
                GoRoute(
                  path: 'templates',
                  name: AppRoutes.accountantJournalTemplates,
                  builder: (context, state) =>
                      const ManualJournalTemplatesListScreen(),
                ),
                GoRoute(
                  path: 'journal-template-creation',
                  name: AppRoutes.accountantJournalTemplateCreation,
                  builder: (context, state) =>
                      const JournalTemplateCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.accountantManualJournalsDetail,
                  builder: (context, state) => ManualJournalOverviewScreen(
                    initialJournalId: state.pathParameters['id'],
                    initialSearchQuery: state.uri.queryParameters['q'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'accounts/chart-of-accounts',
              name: AppRoutes.accountsChartOfAccounts,
              redirect: (context, state) {
                if (!_hasStoredModuleAction(
                  'chart_of_accounts',
                  action: 'view',
                )) {
                  final orgSystemId =
                      state.pathParameters['orgSystemId'] ??
                      _kFallbackRouteSystemId;
                  return '/$orgSystemId/home';
                }
                return null;
              },
              builder: (context, state) => ChartOfAccountsPage(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.accountsChartOfAccountsCreate,
                  redirect: (context, state) {
                    if (!_hasStoredModuleAction(
                      'chart_of_accounts',
                      action: 'create',
                    )) {
                      final orgSystemId =
                          state.pathParameters['orgSystemId'] ??
                          _kFallbackRouteSystemId;
                      return '/$orgSystemId/accounts/chart-of-accounts';
                    }
                    return null;
                  },
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const ChartOfAccountsCreationPage(),
                    opaque: false,
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return child;
                        },
                  ),
                ),
                GoRoute(
                  path: 'edit/:id',
                  name: AppRoutes.accountsChartOfAccountsEdit,
                  redirect: (context, state) {
                    if (!_hasStoredModuleAction(
                      'chart_of_accounts',
                      action: 'edit',
                    )) {
                      final orgSystemId =
                          state.pathParameters['orgSystemId'] ??
                          _kFallbackRouteSystemId;
                      return '/$orgSystemId/accounts/chart-of-accounts';
                    }
                    return null;
                  },
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const ChartOfAccountsCreationPage(),
                    opaque: false,
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return child;
                        },
                  ),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.accountsChartOfAccountsDetail,
                  builder: (context, state) => ChartOfAccountsPage(
                    initialAccountId: state.pathParameters['id'],
                    initialSearchQuery: state.uri.queryParameters['q'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'accounts/opening-balances',
              builder: (context, state) => const OpeningBalancesScreen(),
            ),
            GoRoute(
              path: 'accounts/opening-balances/update',
              builder: (context, state) => const OpeningBalancesUpdateScreen(),
            ),
            GoRoute(
              path: 'accountant/recurring-journals',
              name: AppRoutes.accountantRecurringJournals,
              builder: (context, state) => RecurringJournalOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.accountantRecurringJournalsCreate,
                  builder: (context, state) {
                    final extra = state.extra;
                    if (extra is RecurringJournal) {
                      return RecurringJournalCreateScreen(
                        initialJournal: extra,
                        initialReturnTo: state.uri.queryParameters['returnTo'],
                      );
                    }
                    if (extra is ManualJournal) {
                      return RecurringJournalCreateScreen(
                        initialManualJournal: extra,
                        initialManualJournalId:
                            state.uri.queryParameters['sourceManualJournalId'],
                        initialReturnTo: state.uri.queryParameters['returnTo'],
                      );
                    }
                    if (extra is Map<String, dynamic>) {
                      return RecurringJournalCreateScreen(
                        initialJournal:
                            extra['initialJournal'] as RecurringJournal?,
                        initialManualJournal:
                            extra['initialManualJournal'] as ManualJournal?,
                        initialManualJournalId:
                            state.uri.queryParameters['sourceManualJournalId'],
                        initialReturnTo: state.uri.queryParameters['returnTo'],
                      );
                    }
                    return RecurringJournalCreateScreen(
                      initialManualJournalId:
                          state.uri.queryParameters['sourceManualJournalId'],
                      initialReturnTo: state.uri.queryParameters['returnTo'],
                    );
                  },
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.accountantRecurringJournalsDetail,
                  builder: (context, state) => RecurringJournalOverviewScreen(
                    initialJournalId: state.pathParameters['id'],
                    initialSearchQuery: state.uri.queryParameters['q'],
                  ),
                ),
              ],
            ),
            ...buildAccountantStandaloneRoutes(
              hasStoredModuleAction: _hasStoredModuleAction,
            ),
            ...buildStandaloneReportRoutes(),

            // Procurement Module
            GoRoute(
              path: 'procurement/purchase-requests',
              name: AppRoutes.procurementPurchaseRequests,
              builder: (context, state) =>
                  const ProcurementPurchaseRequestsListPage(),
              routes: [
                GoRoute(
                  path: 'requested-items',
                  name: AppRoutes.procurementRequestedItems,
                  builder: (context, state) =>
                      const ProcurementRequestedItemsPage(),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.procurementPurchaseRequestOverview,
                  builder: (context, state) =>
                      ProcurementPurchaseRequestOverviewPage(
                        id: state.pathParameters['id'] ?? '',
                      ),
                ),
              ],
            ),
            GoRoute(
              path: 'procurement/approvals',
              name: AppRoutes.procurementApprovals,
              builder: (context, state) =>
                  const ProcurementApprovalsReportPage(),
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
          ],
        ),
      ],
    ),
  ],
);
