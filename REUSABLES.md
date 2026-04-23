# REUSABLES.md — Zerpai ERP Shared Component Catalog

> **For agents**: Before writing new shared UI, services, utilities, or logic, search this file first.
> If a suitable reusable already exists, use it. If you create something new and reusable, add it here.

---

## Shared Widgets — `lib/shared/widgets/`

### Layout & Structure

| Widget | File | Description |
|--------|------|-------------|
| `ZerpaiLayout` | `zerpai_layout.dart` | Master page layout: header with title/actions, scrollable body, footer, shortcut + guard handling |
| `ZerpaiFormRow` | `form_row.dart` | **Horizontal Form Layout** row — 200 px label on left, field on right. Standard ERP "label-left / property-sheet" form pattern. Use inside `ZerpaiFormCard`. Params: `label`, `required`, `crossAxisAlignment`, `child`, `labelWidth`. |
| `ZerpaiFormCard` | `form_row.dart` | White bordered card container for horizontal form rows. Wrap `ZerpaiFormRow` children + `kZerpaiFormDivider` separators inside this. |
| `kZerpaiFormDivider` | `form_row.dart` | Const hairline divider (`height: 1`, `AppTheme.borderLight`) — place between rows inside a `ZerpaiFormCard`. |
| `SharedFieldLayout` | `inputs/shared_field_layout.dart` | Responsive form field wrapper (horizontal on wide screens, vertical on narrow) with label, tooltip, helper text |
| `SettingsFixedHeaderLayout` | `settings_fixed_header_layout.dart` | Fixed settings-page header with constrained-width scrollable body and optional footer; keeps titles/action rows pinned while forms and tables scroll |
| `SettingsNavigationSidebar` | `settings_navigation_sidebar.dart` | Canonical left sidebar for all settings pages using the shared "All Settings" navigation tree and active-route highlighting |
| `KeyboardScrollable` | `keyboard_scrollable.dart` | Enables arrow keys, Page Up/Down, Home/End for scroll on nested ScrollViews |
| `PlaceholderScreen` | `placeholder_screen.dart` | Under-construction screen for unimplemented modules |
| `UnsavedChangesGuard` | `unsaved_changes_guard.dart` | PopScope wrapper that prompts before leaving dirty forms |
| `ShortcutHandler` | `shortcut_handler.dart` | Keyboard shortcuts: Ctrl+S (save), Ctrl+Enter (publish), Esc (cancel), / (search focus) |
| `ZerpaiReportShell` | `reports/zerpai_report_shell.dart` | Report frame with sticky toolbar (date range, basis toggle, actions) and org/report header |

### Inputs

| Widget | File | Description |
|--------|------|-------------|
| `CustomTextField` | `inputs/custom_text_field.dart` | Feature-rich text input: border animation, case formatting, numeric validation, prefix/suffix |
| `ZSearchField` | `inputs/z_search_field.dart` | Standard ERP search input bar with border animation and its variants |
| `FormDropdown<T>` | `inputs/dropdown_input.dart` | Generic searchable dropdown — **always use instead of `DropdownButtonFormField`**; supports multi-select, settings footer, custom items |
| `ZerpaiDatePicker` | `inputs/zerpai_date_picker.dart` | Standard date picker — anchored calendar popup below target field — **use for all ERP date inputs** |
| `ZerpaiCalendar` | `inputs/zerpai_calendar.dart` | Reusable calendar with day/month/year selector modes and date range constraints |
| `ZTooltip` | `inputs/z_tooltip.dart` | 220px-max-width tooltip with arrow — **always use instead of Flutter's `Tooltip`**; trigger icon `LucideIcons.helpCircle` size 14-15 |
| `FileUploadButton` | `inputs/file_upload_button.dart` | File picker button with badge count and overlay listing selected files |
| `GstinPrefillBanner` | `inputs/gstin_prefill_banner.dart` | Info banner prompting GSTIN prefill; params: `entityLabel` (e.g. `'Vendor'` or `'Customer'`), `onPrefill` |
| `FieldLabel` | `inputs/field_label.dart` | Label text with optional required asterisk |
| `FormRadio` | `inputs/radio_input.dart` | Single radio button with label |
| `ZerpaiRadioGroup<T>` | `inputs/zerpai_radio_group.dart` | Generic radio group (horizontal / vertical) |
| `AccountTreeDropdown` | `inputs/account_tree_dropdown.dart` | Hierarchical account selector with search and keyboard navigation |
| `CategoryDropdown` | `inputs/category_dropdown.dart` | Recursive category tree dropdown with optional manage footer and search |
| `TransactionSeriesDropdown` | `inputs/transaction_series_dropdown.dart` | Transaction series selector (Default always highlighted, optional add button) |
| `ResizableBox` | `inputs/resizable_box.dart` | Container with draggable bottom resize handle |
| `HsnSacSearchModal` | `hsn_sac_search_modal.dart` | Modal for searching HSN/SAC codes with debounced API lookup |
| `PhoneInputField` | `inputs/phone_input_field.dart` | Compound phone-number input: 90 px country-code `FormDropdown` + digits-only `CustomTextField` with per-country max-digit enforcement. Params: `selectedPrefix`, `controller`, `onPrefixChanged`, `hintText`, `enabled`. |
| `WarehouseHoverPopover` | `inputs/warehouse_popover.dart` | Overlay popover showing warehouse stock breakdown (Accounting/Physical) with location selector. Wraps any child widget; opens on tap. Params: `child`, `warehouseName`, `selectedView`, `onWarehouseChanged`, `onViewChanged`. |

### Text Formatters (via `CustomTextField` or direct use)

| Formatter | Location | Description |
|-----------|----------|-------------|
| `UpperCaseTextFormatter` | `inputs/uppercase_text_formatter.dart` | Forces all input to UPPERCASE (GSTIN, SKU, licence numbers) |
| `SentenceCaseTextFormatter` | inside `custom_text_field.dart` | Capitalises first letter of each sentence |
| `NumericOnlyFormatter` | inside `custom_text_field.dart` | Blocks non-numeric characters |

### Buttons

| Widget | File | Description |
|--------|------|-------------|
| `ZButton` | `z_button.dart` | Dual-mode button: primary green elevated / secondary gray outlined, with loading spinner and optional icon support |

### Sections (Composite Form Blocks)

Pre-assembled, reusable form sections that compose multiple inputs into a
domain-specific block. Place these directly inside `ZerpaiFormCard` or use them
standalone depending on the variant.

| Widget | File | Description |
|--------|------|-------------|
| `LicenseRegistrationSection` | `sections/license_registration_section.dart` | Toggle-gated registration block for Drug Licence (Wholesale/Retail/Combined with form 20/21/20B/21B), FSSAI, or MSME. Pass `licenseType` enum + `numberControllers` map + `selectedFiles` map. Renders `ZerpaiFormRow` with `CustomTextField` + `FileUploadButton` pairs and drug/MSME type `FormDropdown`s. |
| `ContactPersonsTable` | `sections/contact_persons_table.dart` | Full-width tabular editor for a list of `ContactPersonRow` data objects. Header + hover-reveal delete rows with `FormDropdown` (salutation), `CustomTextField` (name/email), and `PhoneInputField` (phone/mobile). Owns hover state internally; parent manages the row list. |
| `AddressSection` | `sections/address_section.dart` | Self-contained `ZerpaiFormCard` address block with Attention, Street 1/2, City, Pin Code, Country `FormDropdown`, State `FormDropdown` (allows custom values), and `PhoneInputField`. Supports optional "Copy billing address" link via `showCopyFromBilling` + `onCopyFromBilling`. |

---

### Layout & Tables

| Widget | File | Description |
|--------|------|-------------|
| `ZDataTableShell` | `z_data_table_shell.dart` | Bordered table container with integrated header and divider |
| `ZTableHeader` | `z_data_table_shell.dart` | Standardized header row for ERP tables |
| `ZTableRowLayout` | `z_data_table_shell.dart` | Generic clickable row layout with consistent ERP padding |
| `ZTableCell` | `z_data_table_shell.dart` | Cell wrapper with flex support to match header/row column widths |
| `ZCurrencyDisplay` | `z_currency_display.dart` | Reusable currency display with standardized symbol rendering (Roboto fallback) and decimal formatting |
| `ZRowActions` | `z_row_actions.dart` | Vertical ellipsis (⋮) menu for row-level actions; supports Edit, Delete, Duplicate, and custom actions with dividers |

### Dialogs

| Widget / Function | File | Description |
|-------------------|------|-------------|
| `showZerpaiConfirmationDialog()` | `dialogs/zerpai_confirmation_dialog.dart` | Standard confirmation dialog (warning / danger variants) |
| `showUnsavedChangesDialog()` | `dialogs/unsaved_changes_dialog.dart` | Confirmation dialog specifically for unsaved changes prompts |
| `ManageListDialog` | `inputs/manage_list_dialog.dart` | Two-level dialog: view list → edit individual item |
| `ManagePaymentTermsDialog` | `inputs/manage_payment_terms_dialog.dart` | Dialog for managing payment term schedules |
| `ManageCategoriesDialog` | `inputs/manage_categories_dialog.dart` | Dialog for managing category hierarchy |

### Loading / Error States

| Widget | File | Description |
|--------|------|-------------|
| `ZBone` / `ZFormSkeleton` / `ZTableSkeleton` / `ZListSkeleton` / `ZCardSkeleton` / `ZDetailSkeleton` | `z_skeletons.dart` | Shimmer loading placeholders — **always use instead of raw `Skeletonizer`**; matches Zoho-style high density and spacing. |
| `ZErrorPlaceholder` | `z_skeletons.dart` | Unified error state with icon and retry affordance — replaces legacy `ErrorPlaceholder`. |
| `ZerpaiBuilders.buildErrorAlert()` | `inputs/zerpai_builders.dart` | Styled error banner with close button |
| `ZerpaiBuilders.parseErrorMessage()` | `inputs/zerpai_builders.dart` | Context-aware error string translation (duplicates, associations, subcategories) |

### Text & Links

| Widget | File | Description |
|--------|------|-------------|
| `ZerpaiLinkText` | `texts/zerpai_link_text.dart` | Clickable link text with primary blue color and underline on hover |

---

## Shared Mixins — `lib/shared/mixins/`

| Mixin | File | Description |
|-------|------|-------------|
| `LicenceValidationMixin` | `licence_validation_mixin.dart` | On-blur, context-aware validation for drug licence (20/21/20B/21B), FSSAI, and MSME registration fields. Used on both vendor and customer create screens. Provides: `initLicenceValidation()`, `disposeLicenceNodes()`, `clearDrugLicenceErrors()`, `clearDrugLicenceErrorsForType()`, `clearFssaiError()`, `clearMsmeError()`. |

---

## Shared Services — `lib/shared/services/`

| Service | File | Description |
|---------|------|-------------|
| `ApiClient` | `api_client.dart` | Dio-based HTTP client with Supabase auth, org/branch headers, error handling |
| `HiveService` | `hive_service.dart` | Hive local DB wrapper: initialisation, box management, CRUD |
| `DialogService` | `dialog_service.dart` | Shows dialogs, snackbars, and toast notifications |
| `StorageService` | `storage_service.dart` | Cloudflare R2 file uploads/downloads |
| `LookupUtils` | `lookup_service.dart` (utils/lookup_utils.dart) | Generic lookup/search for master data mapping (IDs to Names) |
| `ImagePickerService` | `image_picker_service.dart` | File/image picker abstraction |
| `LookupService` | `lookup_service.dart` | Generic lookup/search for master data |
| `RecentHistoryService` | `recent_history_service.dart` | In-memory cache of recently opened items |
| `DraftStorageService` | `draft_storage_service.dart` | Persists unsaved form drafts to Hive |
| `EnvService` | `env_service.dart` | Environment config loader (API URLs, feature flags) |
| `SyncService` | `sync/sync_service.dart` | Offline-first sync of pending changes to backend |
| `GlobalSyncManager` | `sync/global_sync_manager.dart` | App-wide sync state, periodic background sync, conflict resolution |
| `BinLocationsService` | `bin_locations_service.dart` | Persists settings bin-location zones per branch in the shared Hive config box and seeds default zones on first enable |

---

## Core Theme & Text — `lib/core/theme/`

| Token / Class | File | Description |
|---------------|------|-------------|
| `AppTheme` | `app_theme.dart` | **All** color, spacing, and theme tokens — never hardcode values; always use `AppTheme.*` |
| `AppTextStyles` | `app_text_styles.dart` | Reusable text styles: title, subtitle, body, label, input, helper, hint |

---

## Core Layout Shell — `lib/core/layout/`

| Widget | File | Description |
|--------|------|-------------|
| `ZerpaiShell` | `zerpai_shell.dart` | Main app shell: sidebar + navbar + page; applies org branding |
| `ZerpaiSidebar` | `zerpai_sidebar.dart` | Collapsible sidebar with nested menu tree |
| `ZerpaiNavbar` | `zerpai_navbar.dart` | Top navbar: global search, org switcher, profile menu |
| `ZerpaiSidebarItem` | `zerpai_sidebar_item.dart` | Sidebar menu item with icon, label, hover/active states |
| `ZerpaiShellMetrics` | `zerpai_shell_metrics.dart` | InheritedWidget providing sidebar width, viewport width, content width to the tree |

---

## Constants — `lib/shared/constants/`

| Constant | File | Description |
|----------|------|-------------|
| `defaultCurrencyOptions` / `CurrencyOption` | `currency_constants.dart` | List of supported currencies (INR, USD, EUR, …) with code, name, symbol, decimals |
| `phonePrefixMaxDigits` | `phone_prefixes.dart` | Map of phone country code → max digit length for validation |
| `kGstTreatmentOptions` / `kGstRegistrationTypes` / `kSalutationOptions` / `kDrugLicenceTypeOptions` | `gst_constants.dart` | Centralised GST treatment, registration type, salutation, and drug licence dropdown option lists |
| `kFormLabelWidth` / `kFormFieldWidth` / `kFormInputHeight` / `kFormFieldSpacing` / `kFormSectionSpacing` / `kLicenseInputWidth` / `kFormCardPadding` | `../utils/form_layout_constants.dart` | Standard form dimension constants — replaces hardcoded `_labelWidth = 180`, `_fieldWidth = 480`, etc. repeated across 10+ create/edit screens |

---

## Shared Utilities — `lib/shared/utils/`

| Utility | File | Description |
|---------|------|-------------|
| `ZerpaiToast` | `zerpai_toast.dart` | Overlay toast system: `success(context, msg)`, `error(context, msg)`, `info(context, msg)`, `saved(context, subject)`, `deleted(context, subject)` |
| `AsyncActionHandler` | `async_action_handler.dart` | Centralised try/catch + toast + loading state handler; `run(context, action, setLoading, ...)` and `delete(...)` convenience wrapper |
| `DisplayNameUtils` | `display_name_utils.dart` | Generates Zoho-style display name option lists from salutation/first/last name parts; `generateOptions(...)` and `defaultOption(...)` |
| `GstinPrefillUtils` | `gstin_prefill_utils.dart` | Applies GSTIN lookup result maps to controller maps, extracts PAN from GSTIN string, validates GSTIN format |
| `FormControllersManager` | `form_controllers_manager.dart` | Keyed `TextEditingController` lifecycle manager — `init`, `get`/`[]`, `set`, `clear`, `clearAll`, `toMap`, `dispose`; eliminates 40-50 manual controller declarations per create/edit screen |

---

## How to Keep This File Updated

- Whenever a new reusable widget, mixin, service, or utility is extracted or created, add it to the relevant section above.
- Whenever something is deleted or significantly renamed, update or remove its entry.
- Keep descriptions concise (one sentence max).
- **Do not** list module-specific widgets here — only things living in `lib/shared/`, `lib/core/theme/`, or `lib/core/layout/`.
