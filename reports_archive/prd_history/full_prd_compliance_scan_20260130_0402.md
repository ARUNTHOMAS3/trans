# Full PRD Compliance Scan

Generated: 2026-01-30 04:02

## 1. File Naming (presentation)
Total presentation files: 112
Violations: 9
- lib/modules/items/items/presentation/sections/composition_section.dart
- lib/modules/items/items/presentation/sections/formulation_section.dart
- lib/modules/items/items/presentation/sections/purchase_section.dart
- lib/modules/items/items/presentation/sections/sales_section.dart
- lib/modules/items/items/presentation/sections/report/itemsgrid_view.dart
- lib/modules/items/items/presentation/sections/report/itemslist_view.dart
- lib/modules/items/items/presentation/sections/report/items_filters.dart
- lib/modules/items/items/presentation/sections/report/items_table.dart
- lib/modules/items/items/presentation/sections/report/item_row.dart

## 2. Hardcoded Colors in lib/**/*.dart
Files with hardcoded colors: 95
- lib/core/constants/app_colors.dart :: Color(0xFF007BFF), Color(0xFF28A745), Color(0xFF6B7280), Color(0xFFF0F2F5)
- lib/core/layout/zerpai_layout.dart :: Color(0xFF1F2937)
- lib/core/layout/zerpai_navbar.dart :: Color(0xFF1F2937), Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFFEFF6FF), Color(0xFFF1F3F9)
- lib/core/layout/zerpai_sidebar.dart :: Color(0xFF22A95E), Color(0xFF2B3040), Color(0xFF2C3E50), Color(0xFF34495E), Color(0xFF3E4F63)
- lib/core/layout/zerpai_sidebar_item.dart :: Color(0xFF10B981), Color(0xFF22A95E), Color(0xFF2E344A), Color(0xFF34495E), Color(0xFF3E4F63)
- lib/core/router/theme/app_theme.dart :: Color(0x14000000), Color(0xff1f2633), Color(0xff1f2933), Color(0xff27c59a), Color(0xff3b7cff), Color(0xff6b7280), Color(0xffd3d9e3)
- lib/core/theme/app_theme.dart :: Color(0xFF10B981), Color(0xFF111827), Color(0xFF1D4ED8), Color(0xFF1F2633), Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFEF4444) ...
- lib/modules/accounts/presentation/accounts_chart_of_accounts_creation.dart :: Color(0xFF10B981), Color(0xFF2563EB), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFEEEEEE), Color(0xFFF9FAFB)
- lib/modules/accounts/presentation/widgets/accounts_chart_of_accounts_overview.dart :: Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFF93C5FD), Color(0xFF9CA3AF), Color(0xFFE5E7EB), Color(0xFFF3F4F6)
- lib/modules/accounts/presentation/widgets/accounts_chart_of_accounts_row.dart :: Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFFE5E7EB), Color(0xFFEEEEEE)
- lib/modules/home/presentation/home_dashboard_overview.dart :: Color(0xFF3F51B5)
- lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_creation.dart :: Color(0xFF10B981), Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF4B5563), Color(0xFF64748B), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFB91C1C), Color(0xFFDBEAFE) ...
- lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart :: Color(0xFF10B981), Color(0xFF111827), Color(0xFF1F2937), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFEF4444) ...
- lib/modules/items/composite_items/presentation/items_composite_item_create.dart :: Color(0xFF111827), Color(0xFF166534), Color(0xFF16A34A), Color(0xFF1B8EF1), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFB91C1C) ...
- lib/modules/items/composite_items/presentation/items_composite_items_composite_creation.dart :: Color(0x11000000), Color(0xFF111827), Color(0xFF166534), Color(0xFF16A34A), Color(0xFF1B8EF1), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFF9CA3AF) ...
- lib/modules/items/composite_items/presentation/items_composite_items_composite_overview.dart :: Color(0xFF10B981), Color(0xFF111827), Color(0xFF374151), Color(0xFF3B82F6), Color(0xFF4F46E5), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFF9FAFB)
- lib/modules/items/items/presentation/items_items_item_creation.dart :: Color(0x11000000), Color(0xFF111827)
- lib/modules/items/items/presentation/items_items_item_detail.dart :: Color(0xFF10B981), Color(0xFF111827), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFEF4444), Color(0xFFF9FAFB)
- lib/modules/items/items/presentation/items_items_item_overview.dart :: Color(0xFF1A73E8), Color(0xFF1F1F1F), Color(0xff2E2E2E), Color(0xff666666), Color(0xffd5d5d5), Color(0xffe3e3e3)
- lib/modules/items/items/presentation/sections/composition_section.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF374151), Color(0xFFE5E7EB), Color(0xFFEFF6FF), Color(0xFFF9FAFB)
- lib/modules/items/items/presentation/sections/default_tax_rates_section.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFFE5E7EB), Color(0xFFEFF6FF)
- lib/modules/items/items/presentation/sections/formulation_extra_details.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF9CA3AF), Color(0xFFE5E7EB), Color(0xFFEFF6FF)
- lib/modules/items/items/presentation/sections/formulation_section.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFFEFF6FF)
- lib/modules/items/items/presentation/sections/items_item_create_components.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFF9CA3AF)
- lib/modules/items/items/presentation/sections/items_item_create_images.dart :: Color(0xFF111827), Color(0xFF166534), Color(0xFF16A34A), Color(0xFF1B8EF1), Color(0xFF2563EB), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFD4D7E2), Color(0xFFDC2626), Color(0xFFE5E7EB) ...
- lib/modules/items/items/presentation/sections/items_item_create_inventory.dart :: Color(0xFF111827), Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFFE5E7EB), Color(0xFFEFF6FF)
- lib/modules/items/items/presentation/sections/items_item_create_primary_info.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFFE5E7EB), Color(0xFFEFF6FF)
- lib/modules/items/items/presentation/sections/items_item_create_settings.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFFFEF3C7)
- lib/modules/items/items/presentation/sections/items_item_create_tabs.dart :: Color(0xFF111827), Color(0xFF1B8EF1), Color(0xFF6B7280), Color(0xFFE5E7EB)
- lib/modules/items/items/presentation/sections/items_item_detail_components.dart :: Color(0xFF10B981), Color(0xFF111827), Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFE5E7EB) ...
- lib/modules/items/items/presentation/sections/items_item_detail_menus.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF4B5563), Color(0xFFE5E7EB), Color(0xFFF3F4F6)
- lib/modules/items/items/presentation/sections/items_item_detail_overview.dart :: Color(0xFF0EA5E9), Color(0xFF0F6CBD), Color(0xFF111827), Color(0xFF16A34A), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF3B82F6), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFF9CA3AF) ...
- lib/modules/items/items/presentation/sections/items_item_detail_price_lists.dart :: Color(0xFF10B981), Color(0xFF111827), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF9FAFB)
- lib/modules/items/items/presentation/sections/items_item_detail_stock.dart :: Color(0x14000000), Color(0x1A2563EB), Color(0x33000000), Color(0xFF10B981), Color(0xFF111827), Color(0xFF1D4ED8), Color(0xFF1F2937), Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF374151) ...
- lib/modules/items/items/presentation/sections/items_opening_stock_dialog.dart :: Color(0xFF10B981), Color(0xFF111827), Color(0xFF1F2937), Color(0xFF2563EB), Color(0xFF3730A3), Color(0xFF374151), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFE0E7FF) ...
- lib/modules/items/items/presentation/sections/purchase_section.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF9CA3AF), Color(0xFFEFF6FF)
- lib/modules/items/items/presentation/sections/report/dialogs/bulk_update_dialog.dart :: Color(0xFF111827), Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF4B5563), Color(0xFF9CA3AF), Color(0xFFB91C1C), Color(0xFFD1D5DB), Color(0xFFE11D48), Color(0xFFE5E7EB) ...
- lib/modules/items/items/presentation/sections/report/dialogs/export_items_dialog.dart :: Color(0xFF16A34A), Color(0xFFE5F2FF)
- lib/modules/items/items/presentation/sections/report/dialogs/import_items_dialog.dart :: Color(0xFF111827), Color(0xFF374151), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFE5E7EB)
- lib/modules/items/items/presentation/sections/report/dialogs/items_custom_columns.dart :: Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFE5E7EB)
- lib/modules/items/items/presentation/sections/report/items_filter_dropdown.dart :: Color(0xFF111827), Color(0xFF16A34A), Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF59E0B)
- lib/modules/items/items/presentation/sections/report/items_table.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFDDE4FF), Color(0xFFE5E7EB), Color(0xFFF2F4FF), Color(0xFFF5F7FF), Color(0xFFF9FAFB)
- lib/modules/items/items/presentation/sections/report/itemsgrid_view.dart :: Color(0xFF111827), Color(0xFF16A34A), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF94A3B8), Color(0xFFDBEAFE), Color(0xFFE11D48), Color(0xFFE5E7EB)
- lib/modules/items/items/presentation/sections/report/itemslist_view.dart :: Color(0xFFE5E7EB)
- lib/modules/items/items/presentation/sections/report/sections/items_report_body_actions.dart :: Color(0xFF111827), Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF4B5563), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFF9FAFB)
- lib/modules/items/items/presentation/sections/report/sections/items_report_body_components.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFE5E7EB)
- lib/modules/items/items/presentation/sections/report/sections/items_report_body_menu.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF4B5563), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFF9FAFB)
- lib/modules/items/items/presentation/sections/sales_section.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF9CA3AF), Color(0xFFEFF6FF)
- lib/modules/items/pricelist/presentation/items_pricelist_pricelist_creation.dart :: Color(0xFF0088FF), Color(0xFF111827), Color(0xFF16A34A), Color(0xFF2563EB), Color(0xFF28A745), Color(0xFF374151), Color(0xFF444444), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFB91C1C) ...
- lib/modules/items/pricelist/presentation/items_pricelist_pricelist_edit.dart :: Color(0xFF0088FF), Color(0xFF111827), Color(0xFF16A34A), Color(0xFF2563EB), Color(0xFF28A745), Color(0xFF374151), Color(0xFF444444), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD32F2F) ...
- lib/modules/items/pricelist/presentation/items_pricelist_pricelist_overview.dart :: Color(0xFF111827), Color(0xFF166534), Color(0xFF16A34A), Color(0xFF374151), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFDC2626), Color(0xFFDCFCE7), Color(0xFFE5E7EB), Color(0xFFF3F4F6) ...
- lib/modules/reports/presentation/reports_account_transactions.dart :: Color(0xFF10B981), Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFF9FAFB), Color(0xFFFAFAFA)
- lib/modules/reports/presentation/reports_reports_overview.dart :: Color(0xFF10B981), Color(0xFF111827), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFFE5E7EB), Color(0xFFEF4444), Color(0xFFF59E0B)
- lib/modules/reports/presentation/reports_sales_sales_daily.dart :: Color(0xFF6B7280)
- lib/modules/sales/presentation/sales_credit_note_create.dart :: Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sales_customer_create.dart :: Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFFE5E7EB)
- lib/modules/sales/presentation/sales_customer_overview.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFFE5E7EB)
- lib/modules/sales/presentation/sales_delivery_challan_create.dart :: Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sales_document_detail.dart :: Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFFE5E7EB), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sales_eway_bill_create.dart :: Color(0xFF374151), Color(0xFFD1D5DB), Color(0xFFE5E7EB)
- lib/modules/sales/presentation/sales_generic_list.dart :: Color(0xFF2563EB), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sales_order_create.dart :: Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sales_order_overview.dart :: Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFE5E7EB)
- lib/modules/sales/presentation/sales_payment_create.dart :: Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFE5E7EB)
- lib/modules/sales/presentation/sales_payment_link_create.dart :: Color(0xFFE5E7EB)
- lib/modules/sales/presentation/sales_recurring_invoice_create.dart :: Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sales_retainer_invoice_create.dart :: Color(0xFFD1D5DB), Color(0xFFE5E7EB)
- lib/modules/sales/presentation/sections/sales_customer_address_section.dart :: Color(0xFF2563EB)
- lib/modules/sales/presentation/sections/sales_customer_builders.dart :: Color(0xFF111827), Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF3B82F6), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFDBEAFE), Color(0xFFDC2626) ...
- lib/modules/sales/presentation/sections/sales_customer_contact_persons_section.dart :: Color(0xFF6B7280), Color(0xFFE5E7EB), Color(0xFFEF4444), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sections/sales_customer_demography_section.dart :: Color(0xFF2563EB), Color(0xFF6B7280)
- lib/modules/sales/presentation/sections/sales_customer_dialogs.dart :: Color(0xFF111827), Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFF92400E), Color(0xFFDC2626), Color(0xFFE11D48), Color(0xFFE5E7EB), Color(0xFFEF4444) ...
- lib/modules/sales/presentation/sections/sales_customer_helpers.dart :: Color(0xFF111827), Color(0xFF6B7280)
- lib/modules/sales/presentation/sections/sales_customer_other_details_section.dart :: Color(0xFF2563EB), Color(0xFF6B7280)
- lib/modules/sales/presentation/sections/sales_customer_overview_actions.dart :: Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sections/sales_customer_overview_left_panel.dart :: Color(0xFF111827), Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sections/sales_customer_overview_other_tabs.dart :: Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sections/sales_customer_overview_tab.dart :: Color(0xFF111827), Color(0xFF166534), Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFDCFCE7), Color(0xFFE5E7EB) ...
- lib/modules/sales/presentation/sections/sales_customer_primary_info_section.dart :: Color(0xFFE5E7EB)
- lib/modules/sales/presentation/sections/sales_generic_list_columns.dart :: Color(0xFF10B981), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFD1D5DB), Color(0xFFEF4444), Color(0xFFEFF6FF), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sections/sales_generic_list_filter.dart :: Color(0xFF10B981), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFE5E7EB), Color(0xFFEFF6FF), Color(0xFFF59E0B)
- lib/modules/sales/presentation/sections/sales_generic_list_import_export_dialog.dart :: Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF374151), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFEF4444), Color(0xFFEFF6FF), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sections/sales_generic_list_search_dialog.dart :: Color(0xFF111827), Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFEFF6FF), Color(0xFFF9FAFB)
- lib/modules/sales/presentation/sections/sales_generic_list_table.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFE5E7EB)
- lib/modules/sales/presentation/sections/sales_generic_list_table_logic.dart :: Color(0xFF2563EB), Color(0xFFD1D5DB)
- lib/modules/sales/presentation/sections/sales_generic_list_ui.dart :: Color(0xFF059669), Color(0xFF111827), Color(0xFF1E3A8A), Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF374151), Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFEF4444) ...
- lib/shared/services/sync/global_sync_manager.dart :: Color(0xFF111827), Color(0xFF1B8EF1), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFFEFF6FF)
- lib/shared/theme/app_text_styles.dart :: Color(0xFF111827), Color(0xFF374151), Color(0xFF6B7280), Color(0xFF9CA3AF), Color(0xFFE11D48)
- lib/shared/widgets/inputs/dropdown_input.dart :: Color(0xFF374151), Color(0xFF408DFB)
- lib/shared/widgets/inputs/manage_categories_dialog.dart :: Color(0xFF111827), Color(0xFF2563EB), Color(0xFF4B5563), Color(0xFF6B7280), Color(0xFFD1D5DB), Color(0xFFE5E7EB), Color(0xFFEF4444), Color(0xFFF3F4F6), Color(0xFFF3F4FF), Color(0xFFF9FAFB)
- lib/shared/widgets/inputs/manage_simple_list_dialog.dart :: Color(0xFF111827), Color(0xFF22C55E), Color(0xFF2563EB), Color(0xFF6B7280), Color(0xFFDC2626), Color(0xFFE11D48), Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFF8FAFC), Color(0xFFF9FAFB)
- lib/shared/widgets/inputs/text_input.dart :: Color(0xFF2563EB), Color(0xFFD1D5DB)
- lib/shared/widgets/inputs/z_tooltip.dart :: Color(0xFF111827), Color(0xFF9CA3AF)
- lib/shared/widgets/inputs/zerpai_radio_group.dart :: Color(0xFF1F2937), Color(0xFF2563EB)
- lib/shared/widgets/skeleton.dart :: Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFF9FAFB)

## 3. Spacing Literals (non-allowed values)
Files with non-allowed spacing numbers: 105
- lib/core/layout/zerpai_layout.dart :: 0, 20, 40
- lib/core/layout/zerpai_navbar.dart :: 0, 1, 2, 3, 6, 10, 13, 14, 20, 22, 36, 60, 120, 160, 180, 220, 300, 400
- lib/core/layout/zerpai_sidebar.dart :: 0, 1, 2, 3, 6, 10, 11, 13, 14, 18, 20, 22, 28, 40, 46, 72, 120, 180, 220, 230 ...
- lib/core/layout/zerpai_sidebar_item.dart :: 0, 1, 2, 6, 10, 11, 13, 14, 18, 20, 26, 40, 56, 71, 72, 95, 115, 255
- lib/core/router/app_router.dart :: 18, 48
- lib/core/router/theme/app_theme.dart :: 0, 1, 6, 10, 13, 14, 18
- lib/core/theme/app_theme.dart :: 0, 1, 13, 14, 15, 18, 50, 100, 200, 300, 400, 500, 600, 700, 900
- lib/main.dart :: 1, 2, 3, 20, 48
- lib/modules/accounts/presentation/accounts_chart_of_accounts_creation.dart :: 1, 2, 3, 6, 13, 18, 20, 720
- lib/modules/accounts/presentation/accounts_chart_of_accounts_page.dart :: 0, 1, 3, 6, 7, 10, 11, 13, 18, 36, 40, 48, 70, 100, 140, 180, 200, 240, 300, 400
- lib/modules/accounts/presentation/widgets/accounts_chart_of_accounts_overview.dart :: 0, 1, 2, 6, 11, 13, 14, 18, 28, 36, 72, 200, 300, 500
- lib/modules/accounts/presentation/widgets/accounts_chart_of_accounts_row.dart :: 0, 1, 2, 3, 6, 13, 14, 18, 20, 28, 36, 44, 48, 70, 100, 140, 180, 700
- lib/modules/home/presentation/home_dashboard_overview.dart :: 64, 600
- lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_creation.dart :: 0, 1, 2, 3, 10, 13, 14, 18, 20, 28, 38, 40, 180, 600, 2000, 2100
- lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_overview.dart :: 20
- lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart :: 0, 1, 2, 3, 10, 11, 13, 14, 18, 20, 22, 30, 36, 40, 99, 100, 600, 1000, 2024, 2025
- lib/modules/items/composite_items/presentation/items_composite_item_create.dart :: 0, 1, 2, 3, 5, 6, 10, 11, 13, 14, 15, 18, 20, 22, 26, 28, 34, 36, 40, 42 ...
- lib/modules/items/composite_items/presentation/items_composite_items_composite_creation.dart :: 0, 1, 2, 3, 5, 6, 10, 11, 13, 14, 15, 18, 20, 22, 26, 34, 36, 40, 42, 44 ...
- lib/modules/items/composite_items/presentation/items_composite_items_composite_overview.dart :: 0, 1, 2, 3, 6, 10, 11, 13, 14, 18, 20, 22, 36, 44
- lib/modules/items/items/presentation/items_items_item_creation.dart :: 0, 2, 15, 20, 28
- lib/modules/items/items/presentation/items_items_item_detail.dart :: 0, 1, 2, 3, 6, 10, 13, 14, 20, 36, 40, 48, 80, 100, 110, 200, 240, 300, 400
- lib/modules/items/items/presentation/items_items_item_overview.dart :: 1, 2, 6, 10, 13, 14, 15, 18, 20, 40, 300
- lib/modules/items/items/presentation/sections/composition_section.dart :: 0, 2, 6, 13, 18, 20, 36, 40, 48, 160, 360, 720
- lib/modules/items/items/presentation/sections/default_tax_rates_section.dart :: 5, 6, 13, 14, 36, 130, 260, 500
- lib/modules/items/items/presentation/sections/formulation_extra_details.dart :: 1, 2, 6, 11, 13, 20, 36, 44, 70, 135, 138
- lib/modules/items/items/presentation/sections/formulation_section.dart :: 13, 15, 20, 36, 44, 96, 768, 900
- lib/modules/items/items/presentation/sections/items_item_create_components.dart :: 1, 2, 5, 6, 13, 18
- lib/modules/items/items/presentation/sections/items_item_create_images.dart :: 0, 1, 2, 3, 5, 6, 10, 11, 13, 14, 15, 18, 22, 26, 34, 40, 42, 48, 110, 148 ...
- lib/modules/items/items/presentation/sections/items_item_create_inventory.dart :: 6, 10, 11, 13, 14, 20, 36, 1100
- lib/modules/items/items/presentation/sections/items_item_create_primary_info.dart :: 6, 10, 13, 18, 20, 36, 300, 360, 520, 680, 900
- lib/modules/items/items/presentation/sections/items_item_create_settings.dart :: 0, 1, 2, 6, 10, 13, 18, 40, 150, 520, 720
- lib/modules/items/items/presentation/sections/items_item_create_tabs.dart :: 1, 2, 6, 13, 14, 700, 900, 960
- lib/modules/items/items/presentation/sections/items_item_detail_components.dart :: 0, 1, 2, 3, 6, 10, 13, 14, 17, 18, 20, 25, 28, 36, 50, 56, 64, 100, 200, 240 ...
- lib/modules/items/items/presentation/sections/items_item_detail_menus.dart :: 0, 1, 6, 13, 18, 38, 40, 80, 200, 220, 260
- lib/modules/items/items/presentation/sections/items_item_detail_overview.dart :: 0, 1, 2, 3, 5, 6, 10, 11, 13, 14, 15, 18, 20, 30, 40, 42, 48, 50, 60, 150 ...
- lib/modules/items/items/presentation/sections/items_item_detail_price_lists.dart :: 0, 1, 2, 6, 9, 10, 11, 13, 15, 18, 20, 36, 110, 190, 380, 600
- lib/modules/items/items/presentation/sections/items_item_detail_stock.dart :: 0, 1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15, 17, 18, 19, 20, 22, 26, 27 ...
- lib/modules/items/items/presentation/sections/items_opening_stock_dialog.dart :: 0, 1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 18, 20, 28, 36, 48, 100, 120, 200 ...
- lib/modules/items/items/presentation/sections/purchase_section.dart :: 1, 3, 10, 13, 36, 44, 80, 96, 150, 700
- lib/modules/items/items/presentation/sections/report/dialogs/bulk_update_dialog.dart :: 0, 1, 6, 10, 13, 14, 15, 18, 20, 36, 180, 255, 520, 600
- lib/modules/items/items/presentation/sections/report/dialogs/export_items_dialog.dart :: 6, 10, 13, 18, 20, 28, 36, 180, 720, 1997, 2004
- lib/modules/items/items/presentation/sections/report/dialogs/import_items_dialog.dart :: 0, 6, 10, 13, 14, 18, 40, 80, 150, 700
- lib/modules/items/items/presentation/sections/report/dialogs/items_custom_columns.dart :: 1, 13, 15, 18, 20, 560, 620
- lib/modules/items/items/presentation/sections/report/items_filter_dropdown.dart :: 1, 2, 6, 10, 11, 13, 15, 18, 22, 40, 220, 320, 420, 999
- lib/modules/items/items/presentation/sections/report/items_table.dart :: 0, 1, 10, 11, 13, 14, 15, 18, 42, 80, 120, 600
- lib/modules/items/items/presentation/sections/report/itemsgrid_view.dart :: 0, 1, 2, 3, 6, 10, 14, 15, 18, 20, 36, 86, 150, 900, 1200
- lib/modules/items/items/presentation/sections/report/itemslist_view.dart :: 0, 1, 6, 150, 260
- lib/modules/items/items/presentation/sections/report/sections/items_report_body_actions.dart :: 0, 2, 6, 10, 13, 18, 20, 36, 48, 260
- lib/modules/items/items/presentation/sections/report/sections/items_report_body_components.dart :: 1, 2, 6, 10, 13, 18, 28, 255
- lib/modules/items/items/presentation/sections/report/sections/items_report_body_menu.dart :: 0, 1, 6, 10, 13, 18, 25, 36, 38, 40, 50, 80, 100, 200, 240
- lib/modules/items/items/presentation/sections/sales_section.dart :: 1, 3, 10, 13, 36, 44, 90, 96, 150
- lib/modules/items/pricelist/presentation/items_pricelist_pricelist_creation.dart :: 0, 1, 2, 3, 5, 6, 9, 10, 11, 13, 14, 15, 18, 20, 36, 40, 48, 52, 60, 80 ...
- lib/modules/items/pricelist/presentation/items_pricelist_pricelist_edit.dart :: 0, 1, 2, 3, 5, 6, 9, 10, 11, 13, 14, 15, 18, 20, 40, 48, 52, 60, 80, 100 ...
- lib/modules/items/pricelist/presentation/items_pricelist_pricelist_overview.dart :: 0, 1, 2, 6, 10, 13, 14, 15, 18, 20, 25, 36, 40, 48, 60, 64, 80, 96, 200, 240 ...
- lib/modules/reports/presentation/reports_account_transactions.dart :: 0, 1, 2, 3, 5, 6, 10, 11, 13, 18, 20, 31, 64, 100, 120, 200, 300, 2023
- lib/modules/reports/presentation/reports_reports_overview.dart :: 0, 1, 10, 13, 14, 15, 18, 20, 22, 240, 300, 400, 500
- lib/modules/reports/presentation/reports_sales_sales_daily.dart :: 0, 1, 2, 3, 5, 13, 18
- lib/modules/sales/presentation/sales_credit_note_create.dart :: 0, 1, 2, 3, 11, 13, 18, 44, 48, 280, 400, 2000, 2100
- lib/modules/sales/presentation/sales_customer_create.dart :: 0, 1, 2, 3, 7, 11, 13, 20, 26, 34, 70, 91, 180, 360, 400, 420, 800
- lib/modules/sales/presentation/sales_customer_overview.dart :: 1, 3, 5, 13, 14, 18, 60, 200, 280
- lib/modules/sales/presentation/sales_delivery_challan_create.dart :: 0, 1, 3, 11, 20, 44, 48, 2000, 2100
- lib/modules/sales/presentation/sales_document_detail.dart :: 0, 1, 2, 10, 11, 13, 14, 100
- lib/modules/sales/presentation/sales_eway_bill_create.dart :: 0, 13, 20, 44, 48, 2000, 2100
- lib/modules/sales/presentation/sales_generic_list.dart :: 0, 1, 13, 40, 44, 52, 150
- lib/modules/sales/presentation/sales_invoice_create.dart :: 0, 1, 2, 3, 11, 13, 15, 18, 30, 44, 45, 48, 60, 100, 280, 400, 2000, 2100
- lib/modules/sales/presentation/sales_order_create.dart :: 0, 1, 2, 3, 11, 13, 15, 18, 20, 30, 44, 45, 48, 60, 100, 280, 400, 2000, 2100
- lib/modules/sales/presentation/sales_order_overview.dart :: 0, 2, 10, 13, 15, 18, 64
- lib/modules/sales/presentation/sales_payment_create.dart :: 0, 3, 13, 44, 48, 2000, 2100
- lib/modules/sales/presentation/sales_payment_link_create.dart :: 0, 7, 44
- lib/modules/sales/presentation/sales_quotation_create.dart :: 0, 1, 2, 3, 11, 13, 18, 30, 44, 48, 100, 280, 400, 2000, 2100
- lib/modules/sales/presentation/sales_recurring_invoice_create.dart :: 0, 1, 3, 11, 20, 44, 48, 2000, 2100
- lib/modules/sales/presentation/sales_retainer_invoice_create.dart :: 0, 1, 3, 13, 20, 44, 48, 150, 2000, 2100
- lib/modules/sales/presentation/sections/sales_customer_address_section.dart :: 1, 2, 14, 48
- lib/modules/sales/presentation/sections/sales_customer_attributes_section.dart :: 1001, 1002, 1003, 2001, 3001, 9000000011, 9123456780, 9876543210, 9888001122, 9988776655
- lib/modules/sales/presentation/sections/sales_customer_builders.dart :: 0, 1, 2, 6, 10, 13, 14, 18, 20, 36, 44, 61, 75, 80, 91, 140, 971, 974
- lib/modules/sales/presentation/sections/sales_customer_contact_persons_section.dart :: 1, 2, 3, 6, 10, 11, 18
- lib/modules/sales/presentation/sections/sales_customer_demography_section.dart :: 18
- lib/modules/sales/presentation/sections/sales_customer_dialogs.dart :: 0, 1, 6, 9, 10, 13, 15, 18, 20, 36, 80, 140, 200, 560, 820
- lib/modules/sales/presentation/sections/sales_customer_helpers.dart :: 0, 1, 2, 7, 9, 11, 15, 1900, 2000
- lib/modules/sales/presentation/sections/sales_customer_other_details_section.dart :: 6, 10, 13, 30, 45, 360
- lib/modules/sales/presentation/sections/sales_customer_overview_actions.dart :: 2, 10, 11, 13, 14, 18, 20, 320
- lib/modules/sales/presentation/sections/sales_customer_overview_left_panel.dart :: 1, 2, 3, 13, 14, 40
- lib/modules/sales/presentation/sections/sales_customer_overview_other_tabs.dart :: 0, 1, 2, 5, 10, 11, 13, 14, 18, 20, 30, 31, 48, 250, 800, 2025, 2026, 679322
- lib/modules/sales/presentation/sections/sales_customer_overview_tab.dart :: 0, 1, 2, 3, 5, 6, 10, 11, 13, 14, 15, 17, 18, 19, 20, 28, 30, 36, 40, 48 ...
- lib/modules/sales/presentation/sections/sales_customer_remarks_section.dart :: 5, 120
- lib/modules/sales/presentation/sections/sales_generic_list_columns.dart :: 0, 1, 13, 14, 18, 20, 50, 150, 200, 250, 300, 500, 600
- lib/modules/sales/presentation/sections/sales_generic_list_filter.dart :: 0, 1, 2, 10, 11, 13, 14, 18, 20, 35, 40, 250
- lib/modules/sales/presentation/sections/sales_generic_list_import_export_dialog.dart :: 0, 1, 6, 10, 11, 13, 14, 18, 20, 25, 36, 234, 500, 650, 1997, 2004
- lib/modules/sales/presentation/sections/sales_generic_list_search_dialog.dart :: 0, 10, 11, 13, 20, 36, 40, 48, 150, 900
- lib/modules/sales/presentation/sections/sales_generic_list_table.dart :: 0, 1, 2, 10, 11, 13, 14, 20, 44, 150
- lib/modules/sales/presentation/sections/sales_generic_list_ui.dart :: 0, 1, 6, 13, 18, 20, 28, 64
- lib/shared/services/sync/global_sync_manager.dart :: 0, 1, 2, 3, 5, 6, 14, 18, 20, 420, 500
- lib/shared/widgets/form_row.dart :: 160
- lib/shared/widgets/inputs/account_tree_dropdown.dart :: 0, 1, 6, 10, 11, 18, 36, 40, 72, 240
- lib/shared/widgets/inputs/category_dropdown.dart :: 0, 1, 2, 6, 10, 18, 20, 28, 34, 36, 40, 320, 360
- lib/shared/widgets/inputs/custom_text_field.dart :: 0, 1, 6, 10, 11, 18, 44, 60, 120
- lib/shared/widgets/inputs/dropdown_input.dart :: 0, 1, 2, 6, 10, 14, 18, 20, 30, 36, 40, 56, 80, 100, 220, 320, 600, 700
- lib/shared/widgets/inputs/manage_categories_dialog.dart :: 0, 1, 2, 6, 10, 13, 14, 18, 20, 26, 28, 36, 42, 64, 120, 160, 360, 420, 760
- lib/shared/widgets/inputs/manage_simple_list_dialog.dart :: 0, 1, 2, 6, 10, 11, 18, 20, 40, 44, 60, 400, 620
- lib/shared/widgets/inputs/shared_field_layout.dart :: 6, 10, 11, 140, 260
- lib/shared/widgets/inputs/text_input.dart :: 1, 10
- lib/shared/widgets/inputs/z_tooltip.dart :: 6, 48, 60, 180, 230
- lib/shared/widgets/inputs/zerpai_radio_group.dart :: 14, 800
- lib/shared/widgets/skeleton.dart :: 0, 1, 5, 6, 10, 14, 20, 34, 36, 40, 60, 80, 100, 120, 180, 200, 250, 300
- lib/shared/widgets/z_button.dart :: 9, 14, 18, 28, 38

## 4. API Client Centralization
Dio() instantiations outside api_client.dart: 1
- lib/shared/services/storage_service.dart

http package imports: 0

## 5. Hive Offline Compliance
Hive TypeAdapters/@HiveType found: 1
- lib/shared/services/hive_adapters.dart
main.dart has Hive.initFlutter: True
main.dart registers adapters: True
main.dart opens boxes: True

## 6. Backend Response Standardization (heuristic)
Backend files containing both 'data' and 'meta': 1
- backend/src/common/interceptors/standard_response.interceptor.ts

## 7. Resizable Table Columns (heuristic)
Files mentioning resizable columns: 1
- lib/modules/items/items/presentation/sections/report/items_table.dart

## 8. Manual Review Required
- Schema mapping: verify each form maps to tables in PRD/prd_schema.md (not auto-detectable).
- Table column visibility toggling + persistence: verify in table components.
- Auth policy: verify no auth gating in routes (manual).