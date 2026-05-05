import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zerpai_erp/modules/items/items/presentation/items_item_create.dart';
import 'package:zerpai_erp/modules/items/items/presentation/items_item_detail.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/report/items_report_overview.dart';
import 'package:zerpai_erp/modules/items/composite_items/presentation/items_composite_items_composite_creation.dart';
import 'package:zerpai_erp/modules/items/composite_items/presentation/items_composite_items_composite_listview.dart';
import 'package:zerpai_erp/modules/sales/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_customer_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_generic_list.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_order_overview.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_order_create.dart';
import 'package:zerpai_erp/modules/sales/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_invoice_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_retainer_invoice_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_delivery_challan_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_payment_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_credit_note_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_eway_bill_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_quotation_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_document_detail.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_customer_overview.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_payment_link_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_recurring_invoice_create.dart';
import 'package:zerpai_erp/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_creation.dart';
import 'package:zerpai_erp/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_overview.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/manual_journals_overview_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/manual_journal_create_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/manual_journal_template_create_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/manual_journal_templates_list_screen.dart';
import 'package:zerpai_erp/modules/accountant/recurring_journals/presentation/recurring_journal_create_screen.dart';
import 'package:zerpai_erp/modules/accountant/recurring_journals/presentation/recurring_journal_overview_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/models/manual_journal_model.dart';
import 'package:zerpai_erp/modules/accountant/recurring_journals/models/recurring_journal_model.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_chart_of_accounts_overview.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_chart_of_accounts_creation.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_bulk_update_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_account_transactions.dart';
import 'package:zerpai_erp/modules/items/pricelist/presentation/items_pricelist_pricelist_overview.dart';
import 'package:zerpai_erp/modules/items/pricelist/presentation/items_pricelist_pricelist_creation.dart';
import 'package:zerpai_erp/modules/items/pricelist/presentation/items_pricelist_pricelist_edit.dart';
import 'package:zerpai_erp/modules/items/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_opening_balances_screen.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_opening_balances_update_screen.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_transaction_locking_screen.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_settings_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_audit_logs_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_sales_sales_daily.dart';
import 'package:zerpai_erp/modules/home/presentation/home_dashboard_overview.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_profit_and_loss_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_general_ledger_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_trial_balance_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_sales_by_customer_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_inventory_valuation_screen.dart';
import 'package:zerpai_erp/core/pages/settings_page.dart';
import 'package:zerpai_erp/core/pages/settings_organization_profile_page.dart';
import 'package:zerpai_erp/core/pages/settings_organization_branding_page.dart';
import 'package:zerpai_erp/core/pages/settings_branch_profile_page.dart';
import 'package:zerpai_erp/core/pages/settings_branches_list_page.dart';
import 'package:zerpai_erp/core/pages/settings_branches_create_page.dart';
import 'package:zerpai_erp/core/pages/settings_zones_page.dart';
import 'package:zerpai_erp/core/pages/settings_zones_create_page.dart';
import 'package:zerpai_erp/core/pages/settings_zone_bins_page.dart';
import 'package:zerpai_erp/core/pages/settings_warehouses_list_page.dart';
import 'package:zerpai_erp/core/pages/settings_warehouses_create_page.dart';
import 'package:zerpai_erp/modules/settings/users/presentation/settings_users_user_overview.dart';
import 'package:zerpai_erp/modules/settings/users/presentation/settings_users_user_creation.dart';
import 'package:zerpai_erp/core/pages/settings_roles_page.dart';
import 'package:zerpai_erp/modules/settings/users_roles/settings_users_roles_role_creation.dart';
import 'package:zerpai_erp/modules/auth/presentation/auth_auth_login.dart';
import 'package:zerpai_erp/modules/auth/presentation/auth_auth_forgot_password.dart';
import 'package:zerpai_erp/modules/auth/presentation/auth_auth_reset_password.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/modules/auth/services/permission_service.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/purchases_vendors_vendor_list.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/purchases_vendors_vendor_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/presentation/purchases_purchase_receives_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/presentation/purchases_purchase_receives_list.dart';
import 'package:zerpai_erp/modules/purchases/bills/presentation/purchases_bills_list.dart';
import 'package:zerpai_erp/modules/purchases/bills/presentation/purchases_bills_create.dart';
import 'package:zerpai_erp/shared/widgets/placeholder_screen.dart';
import 'package:zerpai_erp/core/layout/zerpai_shell.dart';
import 'package:zerpai_erp/core/pages/error_page.dart';
import 'package:zerpai_erp/core/pages/maintenance_page.dart';
import 'package:zerpai_erp/core/pages/not_found_page.dart';
import 'package:zerpai_erp/core/pages/unauthorized_page.dart';
import 'package:zerpai_erp/modules/inventory/picklists/presentation/inventory_picklists_list.dart';
import 'package:zerpai_erp/modules/inventory/picklists/presentation/inventory_picklists_create.dart';
import 'package:zerpai_erp/modules/inventory/picklists/presentation/inventory_picklists_edit.dart';
import 'package:zerpai_erp/modules/inventory/picklists/presentation/inventory_picklists_update.dart';
import 'package:zerpai_erp/modules/inventory/packages/presentation/inventory_packages_list.dart';
import 'package:zerpai_erp/modules/inventory/packages/presentation/inventory_packages_create.dart';
import 'package:zerpai_erp/modules/inventory/packages/presentation/inventory_packages_edit.dart';
import 'package:zerpai_erp/modules/inventory/shipments/presentation/inventory_shipments_list.dart';
import 'package:zerpai_erp/modules/inventory/shipments/presentation/inventory_shipments_create.dart';
import 'app_routes.dart';
export 'app_routes.dart';

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

bool _hasStoredAuthSession() {
  if (!_hasStoredAuthToken()) {
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
  _RoutePermissionRule('/items/price-lists', 'price_list'),
  _RoutePermissionRule('/items', 'item'),

  _RoutePermissionRule('/inventory/assemblies', 'assemblies'),
  _RoutePermissionRule('/inventory/adjustments', 'inventory_adjustments'),
  _RoutePermissionRule('/inventory/picklists', 'picklists'),
  _RoutePermissionRule('/inventory/packages', 'packages'),
  _RoutePermissionRule('/inventory/shipments', 'shipments'),
  _RoutePermissionRule('/inventory/transfer-orders', 'transfer_orders'),

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
    'account_transactions',
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
        ShellRoute(
          builder: (context, state, child) => ZerpaiShell(child: child),
          routes: [
            // Home
            GoRoute(
              path: 'home',
              name: AppRoutes.home,
              builder: (context, state) => const HomeDashboardScreen(),
            ),
            GoRoute(
              path: 'settings',
              name: AppRoutes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: 'settings/orgprofile',
              name: AppRoutes.settingsOrgProfile,
              redirect: (context, state) {
                final orgSystemId =
                    state.pathParameters['orgSystemId'] ??
                    _kFallbackRouteSystemId;
                final activeTenantType = _storedActiveTenantType();
                final activeTenantId = _storedActiveTenantId();
                if (activeTenantType == 'BRANCH' &&
                    activeTenantId != null &&
                    activeTenantId.isNotEmpty) {
                  return '/$orgSystemId/settings/branches/$activeTenantId/profile';
                }
                return null;
              },
              builder: (context, state) =>
                  const SettingsOrganizationProfilePage(),
            ),
            GoRoute(
              path: 'settings/orgbranding',
              name: AppRoutes.settingsOrgBranding,
              builder: (context, state) =>
                  const SettingsOrganizationBrandingPage(),
            ),
            GoRoute(
              path: 'settings/locations',
              name: AppRoutes.settingsLocations,
              redirect: (context, state) {
                final orgSystemId =
                    state.pathParameters['orgSystemId'] ??
                    _kFallbackRouteSystemId;
                return '/$orgSystemId/settings/branches';
              },
            ),
            GoRoute(
              path: 'settings/zones',
              name: AppRoutes.settingsZones,
              builder: (context, state) => SettingsZonesPage(
                branchId: state.uri.queryParameters['warehouseId'] == null
                    ? state.uri.queryParameters['branchId'] ??
                          state.uri.queryParameters['locationId'] ??
                          state.uri.queryParameters['branchId']
                    : null,
                branchName: state.uri.queryParameters['warehouseName'] == null
                    ? state.uri.queryParameters['branchName'] ??
                          state.uri.queryParameters['locationName'] ??
                          state.uri.queryParameters['branchName']
                    : null,
                warehouseId: state.uri.queryParameters['warehouseId'],
                warehouseName: state.uri.queryParameters['warehouseName'],
              ),
            ),
            GoRoute(
              path: 'settings/zones/new',
              name: AppRoutes.settingsZonesCreate,
              builder: (context, state) => SettingsZonesCreatePage(
                branchId: state.uri.queryParameters['warehouseId'] == null
                    ? state.uri.queryParameters['branchId'] ??
                          state.uri.queryParameters['locationId'] ??
                          state.uri.queryParameters['branchId']
                    : null,
                branchName: state.uri.queryParameters['warehouseName'] == null
                    ? state.uri.queryParameters['branchName'] ??
                          state.uri.queryParameters['locationName'] ??
                          state.uri.queryParameters['branchName']
                    : null,
                warehouseId: state.uri.queryParameters['warehouseId'],
                warehouseName: state.uri.queryParameters['warehouseName'],
              ),
            ),
            GoRoute(
              path: 'settings/zones/:zoneId/bins',
              name: AppRoutes.settingsZoneBins,
              builder: (context, state) => SettingsZoneBinsPage(
                zoneId: state.pathParameters['zoneId'] ?? '',
                branchId: state.uri.queryParameters['warehouseId'] == null
                    ? state.uri.queryParameters['branchId'] ??
                          state.uri.queryParameters['locationId'] ??
                          state.uri.queryParameters['branchId']
                    : null,
                branchName: state.uri.queryParameters['warehouseName'] == null
                    ? state.uri.queryParameters['branchName'] ??
                          state.uri.queryParameters['locationName'] ??
                          state.uri.queryParameters['branchName']
                    : null,
                warehouseId: state.uri.queryParameters['warehouseId'],
                warehouseName: state.uri.queryParameters['warehouseName'],
                zoneName: state.uri.queryParameters['zoneName'] ?? '',
              ),
            ),
            GoRoute(
              path: 'settings/locations/create',
              name: AppRoutes.settingsLocationsCreate,
              redirect: (context, state) {
                final orgSystemId =
                    state.pathParameters['orgSystemId'] ??
                    _kFallbackRouteSystemId;
                return '/$orgSystemId/settings/branches/create';
              },
            ),
            GoRoute(
              path: 'settings/locations/:id/edit',
              name: AppRoutes.settingsLocationsEdit,
              redirect: (context, state) {
                final orgSystemId =
                    state.pathParameters['orgSystemId'] ??
                    _kFallbackRouteSystemId;
                final id = state.pathParameters['id'] ?? '';
                return '/$orgSystemId/settings/branches/$id/edit';
              },
            ),
            GoRoute(
              path: 'settings/branches',
              name: AppRoutes.settingsBranches,
              builder: (context, state) => const SettingsBranchesListPage(),
            ),
            GoRoute(
              path: 'settings/branches/create',
              name: AppRoutes.settingsBranchCreate,
              builder: (context, state) => const SettingsBranchCreatePage(),
            ),
            GoRoute(
              path: 'settings/branches/:id/edit',
              name: AppRoutes.settingsBranchEdit,
              builder: (context, state) => SettingsBranchCreatePage(
                branchId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'settings/branches/:id/profile',
              name: AppRoutes.settingsBranchProfile,
              builder: (context, state) => SettingsBranchProfilePage(
                branchId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: 'settings/warehouses',
              name: AppRoutes.settingsWarehouses,
              builder: (context, state) => const SettingsWarehousesListPage(),
            ),
            GoRoute(
              path: 'settings/warehouses/create',
              name: AppRoutes.settingsWarehouseCreate,
              builder: (context, state) => const SettingsWarehouseCreatePage(),
            ),
            GoRoute(
              path: 'settings/warehouses/:id/edit',
              name: AppRoutes.settingsWarehouseEdit,
              builder: (context, state) => SettingsWarehouseCreatePage(
                warehouseId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'settings/users',
              name: AppRoutes.settingsUsers,
              builder: (context, state) => const SettingsUsersUserOverview(),
              routes: [
                GoRoute(
                  path: 'new',
                  name: AppRoutes.settingsUserInvite,
                  builder: (context, state) =>
                      const SettingsUsersUserCreation(),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.settingsUserDetail,
                  builder: (context, state) => SettingsUsersUserOverview(
                    selectedUserId: state.pathParameters['id'],
                  ),
                ),
                GoRoute(
                  path: ':id/edit',
                  name: AppRoutes.settingsUserEdit,
                  builder: (context, state) => SettingsUsersUserCreation(
                    userId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'settings/roles',
              name: AppRoutes.settingsRoles,
              builder: (context, state) => const SettingsRolesPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  name: AppRoutes.settingsRoleCreate,
                  builder: (context, state) =>
                      const SettingsUsersRolesRoleCreation(),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.settingsRoleDetail,
                  builder: (context, state) => SettingsUsersRolesRoleCreation(
                    roleId: state.pathParameters['id'],
                  ),
                ),
                GoRoute(
                  path: ':id/edit',
                  name: AppRoutes.settingsRoleEdit,
                  builder: (context, state) => SettingsUsersRolesRoleCreation(
                    roleId: state.pathParameters['id'],
                  ),
                ),
              ],
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
              builder: (context, state) => const CompositeCreateScreen(),
            ),
            GoRoute(
              path: 'items/composite-items',
              name: AppRoutes.compositeItems,
              builder: (context, state) => CompositeItemsListScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  name: AppRoutes.compositeItemsDetail,
                  builder: (context, state) => CompositeItemsListScreen(
                    initialItemId: state.pathParameters['id'],
                    initialSearchQuery: state.uri.queryParameters['q'],
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
              builder: (context, state) => SalesGenericListScreen(
                title: 'Customers',
                createRoute: AppRoutes.salesCustomersCreate,
                detailRoute: AppRoutes.salesCustomersDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesCustomersProvider,
                columns: [
                  'name',
                  'company_name',
                  'email',
                  'phone',
                  'gst_treatment',
                  'receivables_bcy',
                ],
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
              builder: (context, state) => SalesGenericListScreen(
                title: 'Quotations',
                createRoute: AppRoutes.salesQuotationsCreate,
                detailRoute: AppRoutes.salesQuotationsDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesQuotesProvider,
                columns: [
                  'quotation_number',
                  'customer',
                  'date',
                  'amount',
                  'status',
                ],
              ),
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
              builder: (context, state) => SalesGenericListScreen(
                title: 'Retainer Invoices',
                createRoute: AppRoutes.salesRetainerInvoicesCreate,
                detailRoute: AppRoutes.salesRetainerInvoicesDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesRetainerInvoicesProvider,
                columns: [
                  'invoice_number',
                  'customer',
                  'date',
                  'amount',
                  'status',
                ],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesRetainerInvoicesCreate,
                  builder: (context, state) =>
                      const SalesRetainerInvoiceCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesRetainerInvoicesDetail,
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'retainer_invoice',
                    initialTab: state.uri.queryParameters['tab'],
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
              ],
            ),

            GoRoute(
              path: 'sales/invoices',
              name: AppRoutes.salesInvoices,
              builder: (context, state) => SalesGenericListScreen(
                title: 'Invoices',
                createRoute: AppRoutes.salesInvoicesCreate,
                detailRoute: AppRoutes.salesInvoicesDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesInvoicesProvider,
                columns: [
                  'invoice_number',
                  'customer',
                  'date',
                  'amount',
                  'balance',
                  'status',
                ],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesInvoicesCreate,
                  builder: (context, state) => SalesInvoiceCreateScreen(
                    initialCustomerId: state.uri.queryParameters['customerId'],
                    fromOrderId: state.uri.queryParameters['fromOrderId'],
                    cloneId: state.uri.queryParameters['cloneId'],
                  ),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesInvoicesDetail,
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'invoice',
                    initialTab: state.uri.queryParameters['tab'],
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/delivery-challans',
              name: AppRoutes.salesDeliveryChallans,
              builder: (context, state) => SalesGenericListScreen(
                title: 'Delivery Challans',
                createRoute: AppRoutes.salesDeliveryChallansCreate,
                detailRoute: AppRoutes.salesDeliveryChallansDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesChallansProvider,
                columns: const ['challan_number', 'customer', 'date', 'status'],
              ),
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
              builder: (context, state) => SalesGenericListScreen(
                title: 'Payments Received',
                createRoute: AppRoutes.salesPaymentsReceivedCreate,
                detailRoute: AppRoutes.salesPaymentsReceivedDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesPaymentsProvider,
                columns: const [
                  'payment_number',
                  'customer',
                  'date',
                  'amount',
                  'mode',
                ],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesPaymentsReceivedCreate,
                  builder: (context, state) => SalesPaymentCreateScreen(
                    initialCustomerId: state.uri.queryParameters['customerId'],
                    fromInvoiceId: state.uri.queryParameters['fromInvoiceId'],
                    cloneId: state.uri.queryParameters['cloneId'],
                  ),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesPaymentsReceivedDetail,
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'payment_received',
                    initialTab: state.uri.queryParameters['tab'],
                  ),
                ),
              ],
            ),

            // Sales — Returns
            GoRoute(
              path: 'sales/returns',
              name: AppRoutes.salesReturns,
              builder: (context, state) => SalesGenericListScreen(
                title: 'Sales Returns',
                createRoute: AppRoutes.salesReturns,
                detailRoute: AppRoutes.salesReturnsDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                columns: const [
                  'return_number',
                  'customer',
                  'date',
                  'amount',
                  'status',
                ],
              ),
              routes: [
                GoRoute(
                  path: ':id',
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
              builder: (context, state) => SalesGenericListScreen(
                title: 'Credit Notes',
                createRoute: AppRoutes.salesCreditNotesCreate,
                detailRoute: AppRoutes.salesCreditNotesDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesCreditNotesProvider,
                columns: const [
                  'credit_note_number',
                  'customer',
                  'date',
                  'amount',
                  'status',
                ],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesCreditNotesCreate,
                  builder: (context, state) => SalesCreditNoteCreateScreen(
                    initialCustomerId: state.uri.queryParameters['customerId'],
                    fromInvoiceId: state.uri.queryParameters['fromInvoiceId'],
                    cloneId: state.uri.queryParameters['cloneId'],
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
              builder: (context, state) => SalesGenericListScreen(
                title: 'e-Way Bills',
                createRoute: AppRoutes.salesEWayBillsCreate,
                detailRoute: AppRoutes.salesEWayBillsDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesEWayBillsProvider,
                columns: const ['bill_number', 'customer', 'date', 'status'],
              ),
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
              builder: (context, state) => SalesGenericListScreen(
                title: 'Payment Links',
                createRoute: AppRoutes.salesPaymentLinksCreate,
                detailRoute: AppRoutes.salesPaymentLinksDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesPaymentLinksProvider,
                columns: const [
                  'link_id',
                  'customer',
                  'amount',
                  'expiry',
                  'status',
                ],
              ),
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
              builder: (context, state) => SalesGenericListScreen(
                title: 'Recurring Invoices',
                createRoute: AppRoutes.salesRecurringInvoicesCreate,
                detailRoute: AppRoutes.salesRecurringInvoicesDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesRecurringInvoicesProvider,
                columns: const [
                  'profile_name',
                  'customer',
                  'frequency',
                  'next_invoice_date',
                  'status',
                ],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  name: AppRoutes.salesRecurringInvoicesCreate,
                  builder: (context, state) =>
                      SalesRecurringInvoiceCreateScreen(
                        initialCustomerId:
                            state.uri.queryParameters['customerId'],
                        fromInvoiceId:
                            state.uri.queryParameters['fromInvoiceId'],
                        cloneId: state.uri.queryParameters['cloneId'],
                      ),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRoutes.salesRecurringInvoicesDetail,
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'recurring_invoice',
                    initialTab: state.uri.queryParameters['tab'],
                  ),
                ),
              ],
            ),

            // Assemblies
            GoRoute(
              path: 'inventory/assemblies',
              name: AppRoutes.assemblies,
              builder: (context, state) => const AssemblyListScreen(),
            ),
            GoRoute(
              path: 'inventory/assemblies/create',
              name: AppRoutes.assembliesCreate,
              builder: (context, state) => const AssemblyCreateScreen(),
            ),

            // Price Lists
            GoRoute(
              path: 'items/price-lists',
              name: AppRoutes.priceLists,
              builder: (context, state) => PriceListOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'items/price-lists/create',
              name: AppRoutes.priceListsCreate,
              builder: (context, state) {
                final extra = state.extra;
                if (extra is PriceList) {
                  return PriceListCreateScreen(template: extra);
                }
                return const PriceListCreateScreen();
              },
            ),
            GoRoute(
              path: 'items/price-lists/edit/:id',
              name: AppRoutes.priceListsEdit,
              builder: (context, state) {
                final id = state.pathParameters['id'];
                final extra = state.extra as PriceList?;
                return PriceListEditScreen(priceList: extra, priceListId: id);
              },
            ),

            // Placeholders (Inventory)
            GoRoute(
              path: 'inventory/adjustments',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Inventory Adjustments'),
            ),
            GoRoute(
              path: 'inventory/adjustments/create',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Adjustment'),
            ),
            GoRoute(
              path: 'inventory/picklists',
              name: AppRoutes.picklists,
              builder: (context, state) => const InventoryPicklistsListScreen(),
            ),
            GoRoute(
              path: 'inventory/picklists/create',
              name: AppRoutes.picklistsCreate,
              builder: (context, state) =>
                  const InventoryPicklistsCreateScreen(),
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
                return InventoryPicklistsEditScreen(id: id);
              },
            ),
            GoRoute(
              path: 'inventory/picklists/:id',
              name: AppRoutes.picklistsDetail,
              builder: (context, state) => InventoryPicklistsListScreen(
                id: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'inventory/packages',
              name: AppRoutes.packages,
              builder: (context, state) => const InventoryPackagesListScreen(),
            ),
            GoRoute(
              path: 'inventory/packages/create',
              name: AppRoutes.packagesCreate,
              builder: (context, state) => const InventoryPackagesCreateScreen(),
            ),
            GoRoute(
              path: 'inventory/packages/edit/:id',
              name: AppRoutes.packagesEdit,
              builder: (context, state) => InventoryPackagesEditScreen(
                id: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'inventory/packages/:id',
              name: AppRoutes.packagesDetail,
              builder: (context, state) => InventoryPackagesListScreen(
                id: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'inventory/shipments',
              name: AppRoutes.shipments,
              builder: (context, state) => const InventoryShipmentsListScreen(),
            ),
            GoRoute(
              path: 'inventory/shipments/create',
              name: AppRoutes.shipmentsCreate,
              builder: (context, state) =>
                  const InventoryShipmentsCreateScreen(),
            ),
            GoRoute(
              path: 'inventory/transfer-orders',
              name: AppRoutes.transferOrders,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Transfer Orders'),
            ),
            GoRoute(
              path: 'inventory/transfer-orders/create',
              name: AppRoutes.transferOrdersCreate,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Transfer Order'),
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
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Item Mapping'),
            ),
            GoRoute(
              path: 'items/mapping/create',
              name: AppRoutes.itemMappingCreate,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Item Mapping'),
            ),

            // Purchases Module
            GoRoute(
              path: 'purchases',
              redirect: (context, state) => AppRoutes.purchasesVendors,
            ),
            GoRoute(
              path: 'purchases/vendors',
              name: AppRoutes.vendors,
              builder: (context, state) => PurchasesVendorsVendorListScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'purchases/vendors/create',
              name: AppRoutes.vendorsCreate,
              builder: (context, state) =>
                  const PurchasesVendorsVendorCreateScreen(),
            ),
            GoRoute(
              path: 'purchases/purchase-orders',
              name: AppRoutes.purchaseOrders,
              builder: (context, state) => PurchaseOrderOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'purchases/purchase-orders/create',
              name: AppRoutes.purchaseOrdersCreate,
              builder: (context, state) => const PurchaseOrderCreateScreen(),
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
                  const PurchasesPurchaseReceivesCreateScreen(),
            ),
            GoRoute(
              path: 'purchases/expenses',
              name: AppRoutes.expenses,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Expenses'),
            ),
            GoRoute(
              path: 'purchases/expenses/create',
              name: AppRoutes.expensesCreate,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Expense'),
            ),
            GoRoute(
              path: 'purchases/bills',
              name: AppRoutes.bills,
              builder: (context, state) => const PurchasesBillsListScreen(),
            ),
            GoRoute(
              path: 'purchases/bills/create',
              name: AppRoutes.billsCreate,
              builder: (context, state) => const PurchasesBillCreateScreen(),
            ),
            GoRoute(
              path: 'purchases/payments-made',
              name: AppRoutes.paymentsMade,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Payments Made'),
            ),
            GoRoute(
              path: 'purchases/payments-made/create',
              name: AppRoutes.paymentsMadeCreate,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Payment Made'),
            ),
            GoRoute(
              path: 'purchases/vendor-credits',
              name: AppRoutes.vendorCredits,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Vendor Credits'),
            ),
            GoRoute(
              path: 'purchases/vendor-credits/create',
              name: AppRoutes.vendorCreditsCreate,
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Vendor Credit'),
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
                      );
                    }
                    if (extra is ManualJournal) {
                      return RecurringJournalCreateScreen(
                        initialManualJournal: extra,
                      );
                    }
                    if (extra is Map<String, dynamic>) {
                      return RecurringJournalCreateScreen(
                        initialJournal:
                            extra['initialJournal'] as RecurringJournal?,
                        initialManualJournal:
                            extra['initialManualJournal'] as ManualJournal?,
                      );
                    }
                    return const RecurringJournalCreateScreen();
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
            GoRoute(
              path: 'accountant/bulk-update',
              name: AppRoutes.accountantBulkUpdate,
              redirect: (context, state) {
                if (!_hasStoredModuleAction('bulk_update', action: 'view')) {
                  final orgSystemId =
                      state.pathParameters['orgSystemId'] ??
                      _kFallbackRouteSystemId;
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
                if (!_hasStoredModuleAction(
                  'transaction_locking',
                  action: 'view',
                )) {
                  final orgSystemId =
                      state.pathParameters['orgSystemId'] ??
                      _kFallbackRouteSystemId;
                  return '/$orgSystemId/home';
                }
                return null;
              },
              builder: (context, state) =>
                  const AccountantTransactionLockingScreen(),
            ),

            GoRoute(
              path: 'accountant/opening-balances',
              name: AppRoutes.accountantOpeningBalances,
              redirect: (context, state) {
                if (!_hasStoredModuleAction(
                  'opening_balances',
                  action: 'view',
                )) {
                  final orgSystemId =
                      state.pathParameters['orgSystemId'] ??
                      _kFallbackRouteSystemId;
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
                if (!_hasStoredModuleAction(
                  'opening_balances',
                  action: 'edit',
                )) {
                  final orgSystemId =
                      state.pathParameters['orgSystemId'] ??
                      _kFallbackRouteSystemId;
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
                final String accountId =
                    state.uri.queryParameters['accountId'] ?? '';
                final String accountName =
                    state.uri.queryParameters['accountName'] ?? '';
                return AccountTransactionsReportPage(
                  accountId: accountId.isNotEmpty ? accountId : null,
                  accountName: accountName.isNotEmpty ? accountName : null,
                );
              },
            ),
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
          ],
        ),
      ],
    ),
  ],
);
