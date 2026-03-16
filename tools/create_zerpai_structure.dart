// PATH: tools/create_zerpai_structure.dart
//
// Run with: dart run tools/create_zerpai_structure.dart
//
// Creates the FULL Zerpai ERP folder + file structure.
//
// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final structure = [
    // Core
    "lib/core/router/app_router.dart",
    "lib/core/theme/app_theme.dart",
    "lib/core/constants/app_strings.dart",
    "lib/core/constants/app_colors.dart",
    "lib/core/constants/sizes.dart",
    "lib/core/errors/app_exception.dart",
    "lib/core/errors/error_logger.dart",

    // Utils
    "lib/utils/validators.dart",
    "lib/utils/formatters.dart",
    "lib/utils/date_utils.dart",
    "lib/utils/price_utils.dart",

    // Shared services & widgets
    "lib/shared/widgets/z_button.dart",
    "lib/shared/widgets/z_textfield.dart",
    "lib/shared/widgets/z_loader.dart",
    "lib/shared/widgets/z_card.dart",
    "lib/shared/widgets/z_table.dart",

    "lib/shared/services/image_picker_service.dart",
    "lib/shared/services/dialog_service.dart",
    "lib/shared/services/storage_service.dart",

    // Data models & providers
    "lib/data/models/user_model.dart",
    "lib/data/models/branch_model.dart",
    "lib/data/models/vendor_model.dart",
    "lib/data/models/customer_model.dart",

    "lib/data/providers/auth_provider.dart",
    "lib/data/providers/branch_provider.dart",

    // Auth module
    "lib/modules/auth/presentation/login_screen.dart",
    "lib/modules/auth/presentation/forgot_password_screen.dart",
    "lib/modules/auth/controller/auth_controller.dart",

    // Dashboard
    "lib/modules/dashboard/presentation/dashboard_screen.dart",
    "lib/modules/dashboard/controller/dashboard_controller.dart",

    // Items module
    "lib/modules/items/presentation/items_list_screen.dart",
    "lib/modules/items/presentation/item_create_screen.dart",
    "lib/modules/items/presentation/item_edit_screen.dart",
    "lib/modules/items/presentation/item_details_screen.dart",
    "lib/modules/items/controller/items_controller.dart",
    "lib/modules/items/models/item_model.dart",
    "lib/modules/items/models/batch_model.dart",

    // Price list module
    "lib/modules/pricelist/presentation/pricelist_list_screen.dart",
    "lib/modules/pricelist/presentation/pricelist_create_screen.dart",
    "lib/modules/pricelist/presentation/pricelist_edit_screen.dart",
    "lib/modules/pricelist/controller/pricelist_controller.dart",
    "lib/modules/pricelist/models/pricelist_model.dart",

    // Composite items module
    "lib/modules/composite/presentation/composite_list_screen.dart",
    "lib/modules/composite/presentation/composite_create_screen.dart",
    "lib/modules/composite/presentation/composite_edit_screen.dart",
    "lib/modules/composite/controller/composite_controller.dart",
    "lib/modules/composite/models/composite_model.dart",

    // Adjustments module
    "lib/modules/adjustments/presentation/adjustments_list_screen.dart",
    "lib/modules/adjustments/presentation/adjustment_create_screen.dart",
    "lib/modules/adjustments/controller/adjustments_controller.dart",
    "lib/modules/adjustments/models/adjustment_model.dart",

    // Item group module
    "lib/modules/itemgroup/presentation/itemgroup_list_screen.dart",
    "lib/modules/itemgroup/presentation/itemgroup_create_screen.dart",
    "lib/modules/itemgroup/controller/itemgroup_controller.dart",
    "lib/modules/itemgroup/models/itemgroup_model.dart",

    // Item mapping module
    "lib/modules/mapping/presentation/mapping_list_screen.dart",
    "lib/modules/mapping/presentation/mapping_create_screen.dart",
    "lib/modules/mapping/controller/mapping_controller.dart",
    "lib/modules/mapping/models/mapping_model.dart",

    // Vendors module
    "lib/modules/vendors/presentation/vendor_list_screen.dart",
    "lib/modules/vendors/presentation/vendor_create_screen.dart",
    "lib/modules/vendors/controller/vendor_controller.dart",
    "lib/modules/vendors/models/vendor_model.dart",

    // Purchases
    "lib/modules/purchases/presentation/purchases_list_screen.dart",
    "lib/modules/purchases/presentation/purchase_create_screen.dart",
    "lib/modules/purchases/controller/purchase_controller.dart",
    "lib/modules/purchases/models/purchase_model.dart",
    "lib/modules/purchases/models/purchase_item_model.dart",

    // Sales
    "lib/modules/sales/presentation/sales_list_screen.dart",
    "lib/modules/sales/presentation/sale_create_screen.dart",
    "lib/modules/sales/controller/sales_controller.dart",
    "lib/modules/sales/models/sale_model.dart",
    "lib/modules/sales/models/sale_item_model.dart",

    // Branches
    "lib/modules/branches/presentation/branch_list_screen.dart",
    "lib/modules/branches/presentation/branch_create_screen.dart",
    "lib/modules/branches/controller/branch_controller.dart",
    "lib/modules/branches/models/branch_model.dart",

    // Reports
    "lib/modules/reports/presentation/reports_dashboard_screen.dart",
    "lib/modules/reports/presentation/report_daily_sales_screen.dart",
    "lib/modules/reports/presentation/report_stock_screen.dart",
    "lib/modules/reports/controller/reports_controller.dart",
    "lib/modules/reports/models/report_model.dart",

    // Settings
    "lib/modules/settings/presentation/settings_screen.dart",
    "lib/modules/settings/controller/settings_controller.dart",
  ];

  for (var filePath in structure) {
    final file = File(filePath);
    file.createSync(recursive: true);
  }

  print("✅ Zerpai ERP Complete Folder Structure Created Successfully!");
}
