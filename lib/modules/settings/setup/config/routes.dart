import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/settings/setup/currencies/presentation/pages/currencies_settings_page.dart';
import 'package:zerpai_erp/modules/settings/setup/presentation/pages/settings_general_page.dart';
import 'package:zerpai_erp/modules/settings/setup/reminders/presentation/pages/settings_reminders_page.dart';
import 'package:zerpai_erp/modules/settings/setup/units_of_measurement/presentation/pages/settings_units_of_measurement_page.dart';
import 'package:zerpai_erp/modules/settings/general/customers_and_vendors/presentation/pages/customers_and_vendors_settings_page.dart';

List<GoRoute> buildSettingsSetupRoutes() {
  return [
    GoRoute(
      path: 'settings/general',
      name: AppRoutes.settingsGeneral,
      builder: (context, state) => const SettingsGeneralPage(),
    ),
    GoRoute(
      path: 'settings/currencies',
      name: AppRoutes.settingsCurrencies,
      builder: (context, state) => const CurrenciesSettingsPage(),
    ),
    GoRoute(
      path: 'settings/currencies/import',
      name: AppRoutes.settingsCurrenciesImport,
      builder: (context, state) => const ImportExchangeRatesPage(),
    ),
    GoRoute(
      path: 'settings/reminders',
      name: AppRoutes.settingsReminders,
      builder: (context, state) => const SetupConfigureReminderPage(),
    ),
    GoRoute(
      path: 'settings/units-of-measurement',
      name: AppRoutes.settingsUnitsOfMeasurement,
      builder: (context, state) => const SettingsUnitsOfMeasurementPage(),
    ),
    GoRoute(
      path: 'settings/customers-and-vendors',
      name: AppRoutes.settingsCustomersAndVendors,
      builder: (context, state) => const CustomersAndVendorsSettingsPage(),
    ),
  ];
}
