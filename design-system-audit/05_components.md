# 🧩 Component Inventory

This is a complete inventory of shared and reusable UI components in Zerpai ERP.

## 1. Buttons
| Component | Location | Purpose | Variants |
| :--- | :--- | :--- | :--- |
| `ZButton` | `lib/shared/widgets/z_button.dart` | Primary/Secondary actions. | `primary`, `secondary`, `outline`, `ghost`. |
| `ZSplitActionMenuButton`| `lib/shared/widgets/buttons/z_split_action_menu_button.dart` | Main action + dropdown options. | Primary action with secondary menu. |
| `FileUploadButton` | `lib/shared/widgets/inputs/file_upload_button.dart` | File selection/upload. | Standard upload UI. |

## 2. Inputs & Forms
| Component | Location | Purpose | Key Props |
| :--- | :--- | :--- | :--- |
| `CustomTextField` | `lib/shared/widgets/inputs/custom_text_field.dart` | Standard text input. | `label`, `hint`, `controller`, `isDense`. |
| `FormDropdown<T>` | `lib/shared/widgets/inputs/dropdown_input.dart` | Searchable dropdown. | `items`, `onChanged`, `asyncItems`. |
| `ZerpaiDatePicker`| `lib/shared/widgets/inputs/zerpai_date_picker.dart` | Date selection. | Anchored popover picker. |
| `ZerpaiRadioGroup`| `lib/shared/widgets/inputs/zerpai_radio_group.dart` | Radio selection. | `options`, `selectedValue`. |
| `PhoneInputField` | `lib/shared/widgets/inputs/phone_input_field.dart` | Phone number with country code. | Masked input. |

## 3. Tables & Data Display
| Component | Location | Purpose | Key Patterns |
| :--- | :--- | :--- | :--- |
| `ZDataTableShell` | `lib/shared/widgets/z_data_table_shell.dart` | Standard table container. | Handles horizontal scroll/resize. |
| `ColumnCustomizer` | `lib/shared/widgets/tables/column_customizer.dart` | Column visibility toggle. | Persists visibility settings. |
| `ZRowActions` | `lib/shared/widgets/z_row_actions.dart` | Table row hover actions. | Edit/Delete/More triggers. |
| `ZCurrencyDisplay` | `lib/shared/widgets/z_currency_display.dart` | Standardized currency format. | Multi-currency support. |

## 4. Layouts & Navigation
| Component | Location | Purpose | Structure |
| :--- | :--- | :--- | :--- |
| `ZerpaiLayout` | `lib/shared/widgets/zerpai_layout.dart` | Main screen wrapper. | Sidebar, TopBar, Body integration. |
| `ZerpaiShell` | `lib/core/layout/zerpai_shell.dart` | Global app shell. | Navigation wrapper for GoRouter. |
| `ZerpaiSidebar` | `lib/core/layout/zerpai_sidebar.dart` | Main navigation sidebar. | Module-based collapsible menu. |
| `SplitListDetailLayout`| `lib/shared/widgets/tables/split_list_detail_layout.dart` | Master-Detail split. | 30/70 or 40/60 split ratios. |

## 5. Feedback & Overlays
| Component | Location | Purpose | Behavior |
| :--- | :--- | :--- | :--- |
| `ZerpaiToast` | `lib/shared/utils/zerpai_toast.dart` | System notifications. | Success/Info/Error snackbars. |
| `ZTooltip` | `lib/shared/widgets/inputs/z_tooltip.dart` | Descriptive tooltips. | Max-width 220px, Lucide trigger. |
| `ZerpaiConfirmationDialog`| `lib/shared/widgets/dialogs/zerpai_confirmation_dialog.dart` | Action confirmation. | Destructive/Safe prompts. |
| `ZSkeletons` | `lib/shared/widgets/z_skeletons.dart` | Loading states. | List, Table, Detail variants. |

## 6. Specialties
| Component | Location | Purpose |
| :--- | :--- | :--- |
| `GstinPrefillBanner`| `lib/shared/widgets/inputs/gstin_prefill_banner.dart` | GST prefill automation trigger. |
| `HSNSACSearchModal` | `lib/shared/widgets/hsn_sac_search_modal.dart` | Global HSN/SAC code discovery. |

## Duplication Analysis & Recommendations
- **Dropdowns**: Use `FormDropdown<T>` (dropdown_input.dart). Avoid legacy `DropdownButtonFormField`.
- **Date Pickers**: Use `ZerpaiDatePicker`. Do not use raw `showDatePicker` unless for custom calendar flows.
- **Buttons**: Use `ZButton` for all standard actions. Ensure secondary actions use `outline` or `ghost` variants.
