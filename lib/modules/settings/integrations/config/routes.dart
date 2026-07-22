import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/settings/shared/presentation/pages/settings_placeholder_page.dart';

List<GoRoute> buildSettingsIntegrationsRoutes() {
  return [
    GoRoute(
      path: 'settings/integrations/zoho',
      name: AppRoutes.settingsIntegrationsZoho,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Zoho Apps'),
    ),
    GoRoute(
      path: 'settings/integrations/whatsapp',
      name: AppRoutes.settingsIntegrationsWhatsapp,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'WhatsApp'),
    ),
    GoRoute(
      path: 'settings/integrations/sms',
      name: AppRoutes.settingsIntegrationsSms,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'SMS Integrations'),
    ),
    GoRoute(
      path: 'settings/integrations/shipping',
      name: AppRoutes.settingsIntegrationsShipping,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Shipping'),
    ),
    GoRoute(
      path: 'settings/integrations/pos',
      name: AppRoutes.settingsIntegrationsPos,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Shopping Cart & POS'),
    ),
    GoRoute(
      path: 'settings/integrations/ecommerce',
      name: AppRoutes.settingsIntegrationsEcommerce,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'eCommerce'),
    ),
    GoRoute(
      path: 'settings/integrations/accounting',
      name: AppRoutes.settingsIntegrationsAccounting,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Accounting'),
    ),
    GoRoute(
      path: 'settings/integrations/sales-marketing',
      name: AppRoutes.settingsIntegrationsSalesMarketing,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Sales & Marketing'),
    ),
    GoRoute(
      path: 'settings/integrations/edi',
      name: AppRoutes.settingsIntegrationsEdi,
      builder: (context, state) => const SettingsPlaceholderPage(title: 'EDI'),
    ),
    GoRoute(
      path: 'settings/integrations/other-apps',
      name: AppRoutes.settingsIntegrationsOtherApps,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Other Apps'),
    ),
    GoRoute(
      path: 'settings/integrations/marketplace',
      name: AppRoutes.settingsIntegrationsMarketplace,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Marketplace'),
    ),
  ];
}
