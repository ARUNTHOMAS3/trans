import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/settings/customization/pdf_templates/presentation/pages/printing_templates_overview.dart';
import 'package:zerpai_erp/modules/settings/customization/email_notifications/presentation/pages/email_notifications_page.dart';
import 'package:zerpai_erp/modules/settings/customization/reporting_tags/presentation/pages/reporting_tag_create_page.dart';
import 'package:zerpai_erp/modules/settings/customization/transaction_number_series/presentation/pages/transaction_number_series_create_page.dart';
import 'package:zerpai_erp/modules/settings/customization/transaction_number_series/presentation/pages/transaction_number_series_report_page.dart';
import 'package:zerpai_erp/modules/settings/shared/presentation/pages/settings_placeholder_page.dart';

List<GoRoute> buildSettingsCustomizationRoutes() {
  return [
    GoRoute(
      path: 'settings/transaction-number-series',
      name: AppRoutes.settingsTransactionNumberSeries,
      builder: (context, state) => const TransactionNumberSeriesReportPage(),
    ),
    GoRoute(
      path: 'settings/transaction-number-series/create',
      name: AppRoutes.settingsTransactionNumberSeriesCreate,
      builder: (context, state) => const TransactionNumberSeriesCreatePage(),
    ),
    GoRoute(
      path: 'settings/pdf-templates',
      name: AppRoutes.settingsPdfTemplates,
      builder: (context, state) => const PrintTemplatesPage(),
    ),
    GoRoute(
      path: 'settings/email-notifications',
      name: AppRoutes.settingsEmailNotifications,
      builder: (context, state) => const EmailNotificationsPage(),
    ),
    GoRoute(
      path: 'settings/email-notifications/insights',
      name: AppRoutes.settingsEmailInsights,
      builder: (context, state) => const EmailNotificationsPage(
        initialSection: EmailNotificationsSection.emailInsights,
      ),
    ),
    GoRoute(
      path: 'settings/email-notifications/customer-review',
      name: AppRoutes.settingsCustomerReviewNotification,
      builder: (context, state) => EmailNotificationsPage(
        initialSection: EmailNotificationsSection.customerReviewNotification,
        initialTemplateName: state.uri.queryParameters['template'],
        initialEditTemplateName: state.uri.queryParameters['item'],
        initialEditIsNew: state.uri.queryParameters['mode'] == 'new',
      ),
    ),
    GoRoute(
      path: 'settings/sms-notifications',
      name: AppRoutes.settingsSmsNotifications,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'SMS Notifications'),
    ),
    GoRoute(
      path: 'settings/reporting-tags',
      name: AppRoutes.settingsReportingTags,
      builder: (context, state) => const ReportingTagCreatePage(),
    ),
    GoRoute(
      path: 'settings/reporting-tags/create',
      name: AppRoutes.settingsReportingTagsCreate,
      builder: (context, state) =>
          const ReportingTagCreatePage(isCreateMode: true),
    ),
    GoRoute(
      path: 'settings/web-tabs',
      name: AppRoutes.settingsWebTabs,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Web Tabs'),
    ),
  ];
}
