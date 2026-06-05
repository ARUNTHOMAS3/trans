import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/modules/settings/shared/presentation/pages/settings_placeholder_page.dart';

List<GoRoute> buildSettingsIntegrationsRoutes() {
  return [
    GoRoute(
      path: 'settings/integrations/zoho',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Zoho Apps'),
    ),
    GoRoute(
      path: 'settings/integrations/whatsapp',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'WhatsApp'),
    ),
    GoRoute(
      path: 'settings/integrations/sms',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'SMS Integrations'),
    ),
    GoRoute(
      path: 'settings/integrations/shipping',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Shipping'),
    ),
    GoRoute(
      path: 'settings/integrations/pos',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Shopping Cart & POS'),
    ),
    GoRoute(
      path: 'settings/integrations/ecommerce',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'eCommerce'),
    ),
    GoRoute(
      path: 'settings/integrations/accounting',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Accounting'),
    ),
    GoRoute(
      path: 'settings/integrations/sales-marketing',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Sales & Marketing'),
    ),
    GoRoute(
      path: 'settings/integrations/edi',
      builder: (context, state) => const SettingsPlaceholderPage(title: 'EDI'),
    ),
    GoRoute(
      path: 'settings/integrations/other-apps',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Other Apps'),
    ),
    GoRoute(
      path: 'settings/integrations/marketplace',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Marketplace'),
    ),
  ];
}
