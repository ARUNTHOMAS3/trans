### Dev- Rahul

<!-- LOG RULES START -->

### Zerpai Log Maintenance Rules

1. **Initialize/Locate**: If  exists in the root, read it first. If not, create it.
2. **Dev Attribution**: Always ensure the very first line of the file is .
3. **Structure**: Maintain a numbered list of features (e.g., ). Include a high-level description and bullet points for logic.
4. **File Categorization (CRITICAL)**: You MUST split the changed files into two distinct lists: 'Frontend Files' () and 'Backend Files' ().
5. **Append Only**: Never delete previous entries. Always add new changes at the **bottom** of the file.
6. **Timestamps**: Every batch of changes must end with: .
7. **Engineer-to-Engineer**: Write with technical depth, explaining 'why' architectural choices were made.
8. **Method**: Use node append script to append. NEVER use printf with full-file rewrite. NEVER use the Edit tool on this file for content entries.
<!-- LOG RULES END -->

## 1. Unified Enterprise Branching & LSGD Hierarchy

- **Problem**: Legacy settings_outlets and settings_locations created redundant data structures and naming conflicts for Kerala multi-unit operations.
- **Solution**: Implemented settings_branches as the single source of truth for all business locations (FOFO/COCO/Franchise/Warehouse).
- **Backend Files**: `backend/src/db/schema.ts` updated to remove deprecated outlet models and implement the new `branch_id` convention across all modules.
- **Logic**: Added Kerala-specific LSGD hierarchy (Districts, Local Bodies, Wards) to the organization and `settings_branches` to support localized compliance reporting and payment stub accuracy.
- **Status**: Migrated "Payment Stub Address", "Fiscal Year", "Report Basis", and "Industry" settings from Organization Profile to Branch Creation page to support autonomous branch reporting.
- **Cleanup**: Resolved all linting errors in `SettingsBranchCreatePage` (undefined variables, duplicated methods, and syntax errors). Corrected phone normalization for all addresses.

## 2. Enterprise Compliance & Financial Guardrails

- **Problem**: Missing fields for Drug License, FSSAI, and MSME numbers in the core organization profile prevented compliant GST reporting for pharma/retail tenants.
- **Solution**: Expanded the organization table with modular compliance fields and added the accounts_fiscal_years master to the Drizzle schema.
- **Backend Files**: Updated backend/src/db/schema.ts to include high-fidelity compliance attributes and fixed the missing account_id foreign key in the transaction model.
- **SQL Migration**: Generated sql_migrations_2026_04_03.md in the project root to synchronize the live database with the 84-table baseline.

Timestamp of Log Update: April 3, 2026 - 16:15 (IST)

## 3. Enterprise Schema Execution & Drizzle Synchronization

- **Execution**: Successfully applied `sql_migrations_2026_04_03.md` in Supabase, formalizing a 100% compliant 84-table baseline.
- **ORM Sync**: Performed `npx drizzle-kit generate` to reach zero-drift between code (`schema.ts`) and the live database.
- **Backend Files**: Generated migration `backend/drizzle/0002_closed_tomorrow_man.sql` containing all enterprise masters (LSGD, Branches, Fiscal Years).
- **Architecture**: Completed the transition from 'Outlets' to 'Branches' as the global scoping entity, ensuring high-fidelity multi-unit operations.

Timestamp of Log Update: April 3, 2026 - 22:50 (IST)

## 4. Accountant Enterprise Branch Migration & Service Refactoring

- **Problem**: Critical TypeScript build failures in the Accountant module and Vercel deployment blockers caused by legacy 'outletId' references after the enterprise schema had partially transitioned to 'branchId'.
- **Solution**: Performed a comprehensive refactoring of the Accountant service and controller layers to adopt the 'branchId' property and 'branch_id' database column convention globally.
- **Backend Files**:
  - backend/src/modules/accountant/accountant.service.ts
  - backend/src/modules/accountant/accountant.controller.ts
  - backend/src/db/schema.ts
- **Logic**: Resolved type mismatches across findAll, create, and ManualJournal operations. Achieved zero-drift between the Accountant module's business logic and the new 84-table enterprise baseline. Ensured that all service-layer filters correctly target the 'branch_id' scoping entity while maintaining compatibility with legacy raw SQL references where database migrations are pending.

Timestamp of Log Update: April 3, 2026 - 23:15 (IST)

## 5. Enterprise UI Standardization & Cloud Deployment (Vercel)

- **Problem**: Inconsistent attachment UI between the Manual Journal module and Organization Profile, coupled with hit-test failures (unclickable buttons) and layout instability in the shared FileUploadButton component.
- **Solution**: Standardized the FileUploadButton component by refactoring from a Stack to a Row-based layout, ensuring pixel-perfect alignment and robust interaction across all screen sizes.
- **Frontend Files**:
  - lib/shared/widgets/inputs/file_upload_button.dart
  - lib/core/pages/settings_organization_profile_page.dart
  - REUSABLES.md
- **Logic**:
  - Refactored FileUploadButton to eliminate absolute positioning, resolving clickability issues with the file count badge.
  - Implemented Zoho-style overlay aesthetics (border, elevation, and hover states) to ensure cross-module UI parity.
  - Integrated ZerpaiToast for standardized error feedback and updated the component documentation in REUSABLES.md.
- **Deployment**: Successfully deployed the finalized 84-table enterprise backend and the standardized Flutter web frontend to Vercel production environments.

Timestamp of Log Update: April 3, 2026 - 23:36 (IST)

## 6. Skeletonizer Refactoring Audit & Memory Stability Report

- **Problem**: Encountered an Out-of-Memory (OOM) crash during a project-wide refactoring of Skeletonizer(ignoreContainers: true). The refactoring was in an indeterminate state, causing potential instability in complex widget trees.
- **Investigation**: Performed a project-wide audit to determine the completion status of the ignoreContainers: true property transition.
- **Frontend Files** (Analyzed):
  - lib/modules/items/items/presentation/sections/report/items_report_body.dart
  - lib/modules/items/pricelist/presentation/items_pricelist_create.dart
  - lib/modules/items/pricelist/presentation/items_pricelist_edit.dart
  - lib/modules/sales/presentation/sales_order_overview.dart
  - lib/shared/widgets/z_skeletons.dart (Standardized approach)
  - lib/shared/widgets/skeleton.dart (Legacy approach)
- **Logic**:
  - Found that the ignoreContainers: true refactoring is **incomplete**, with transitionary implementation only in 3 files within the Items module.
  - Identified that massive screens (~4000 lines) like SalesOrderOverview are using Skeletonizer without ignoreContainers, which likely caused the OOM due to the overhead of processing extremely deep container hierarchies.
  - Determined that the codebase currently maintains multiple parallel skeleton strategies: legacy shimmer, manual Skeletonizer wrapper with dummyList, and the newer standardized Z-skeleton components (ZBone, ZTableSkeleton, etc.).
  - Recommended a phased migration strictly to the components in z_skeletons.dart to ensure visual parity with Zoho and avoid the performance bottlenecks associated with project-wide Skeletonizer properties.

Timestamp of Log Update: April 4, 2026 - 13:30 (IST)

## 7. Standardized ERP Branch Settings & GST/PAN Integration

- **Problem**: Inconsistent branch creation fields compared to organization profile and customer modules. Missing support for Industry, PAN, and Regulatory compliance (Drug License, FSSAI, MSME) at the branch level.
- **Solution**: Standardized the branch settings module by integrating industry-aware lookups, specialized GST treatment logic, and a modular regulatory compliance section with Zoho-style UI parity.
- **Frontend Files**:
  - lib/core/pages/settings_branches_create_page.dart
  - lib/modules/sales/models/gstin_lookup_model.dart (Imported)
  - lib/modules/sales/services/gstin_lookup_service.dart (Imported)
  - lib/shared/widgets/inputs/gstin_prefill_banner.dart (Imported)
- **Logic**:
  - Implemented \_loadLookups() to dynamically fetch industry options and pre-fill branch defaults (Industry, GST Treatment, PAN) from the organization profile.
  - Expanded the \_save payload to include industry, pan, and gst_treatment, ensuring database parity.
  - Added specialized UI rows for Industry selection and PAN input, following the established high-density ERP pattern.
  - Prepared the state and disposal logic for regulatory compliance fields (Drug License, FSSAI, MSME) to support pharmacy and food-service specific branch requirements.
- **SQL Migration**: Provided ALTER TABLE script for settings_branches to include pan, industry, gst_treatment, and regulatory boolean/text fields.

Timestamp of Log Update: April 4, 2026 - 16:30 (IST)

## 8. Warehouse & Location Settings Standardization

- **Problem**: Build failures in the warehouse module caused by missing skeletonizer imports and invalid AppTheme references (borderMedium). Inconsistent loading states between list and create views.
- **Solution**: Refactored the warehouse and location settings modules to use standardized Z-skeleton components and corrected all lint/build errors.
- **Frontend Files**:
  - lib/core/pages/settings_warehouses_create_page.dart
  - lib/core/pages/settings_warehouses_list_page.dart
  - lib/core/pages/settings_locations_create_page.dart
  - lib/core/theme/app_theme.dart (Verified)
  - REUSABLES.md (Updated)
- **Logic**:
  - Replaced legacy `skeleton.dart` imports with the standardized `z_skeletons.dart` library.
  - Corrected `AppTheme.borderMedium` to `AppTheme.borderColor` to resolve theme-token mismatches.
  - Implemented `ZFormSkeleton` for high-fidelity loading states in create pages and `ZTableSkeleton` for list views.
  - Cleaned up redundant imports and unused GSTIN lookup logic in the branches module to ensure zero-lint warnings.
- **Documentation**: Updated REUSABLES.md to deprecate `skeleton.dart` in favor of the specialized `Z-skeleton` component suite, ensuring long-term maintainability of ERP loading states.

Timestamp of Log Update: April 4, 2026 - 17:00 (IST)

## 9. Hardcoded State Lookup Refactoring & Structural Repair

- **Problem**: Critical structural corruption in settings_branches_create_page.dart (broken formatters and missing helpers). Hardcoded \_indianStates list in settings_locations_create_page.dart and settings_organization_profile_page.dart caused data inconsistency and maintenance overhead.
- **Solution**: Repaired settings_branches_create_page.dart and migrated state lookups to dynamic database-backed lookups (/lookups/states) across all settings pages.
- **Frontend Files**:
  - lib/core/pages/settings_branches_create_page.dart
  - lib/core/pages/settings_locations_create_page.dart
  - lib/core/pages/settings_organization_profile_page.dart
- **Logic**:
  - **Structural Repair**: Restored \_normalizeIndiaPhone and \_GstinData in the branches creation page, resolving compilation errors from previous failed edits.
  - **Dynamic Lookups**: Implemented \_loadStates() and \_loadPaymentStubStates() to fetch state data from the backend.
  - **Refactoring**: Completely removed the hardcoded \_indianStates constant from the codebase.
  - **Data Integrity**: Updated state-matching logic to normalize existing database values against dynamic lookup names during profile loading.
  - **Cleanup**: Resolved linting warnings by removing unused ID-to-name mapping fields that were redundant for FormDropdown usage.

Timestamp of Log Update: April 4, 2026 - 17:35 (IST)

## 10. Branch Settings Cleanup & Legacy Logic Removal

- **Problem**: Legacy Kerala LSGD (Local Self Government Department) address lookup logic in settings_branches_create_page.dart was causing development overhead and potential structural corruption. Incomplete data binding for Tax Information (PAN, GST Treatment, GSTIN) and missing UI sections (Location Access, Transaction Series) hindered full functional parity with the organization profile.
- **Solution**: Performed a comprehensive cleanup of the branch creation page by purging all legacy Kerala-specific lookup methods and state variables. Restored and finalized the missing UI sections to ensure 100% functional completeness for enterprise branch management.
- **Frontend Files**:
  - lib/core/pages/settings_branches_create_page.dart
- **Logic**:
  - **Logic Purge**: Removed all Kerala-specific district, local body, and ward lookup fields and methods (e.g., _loadDistrictsForSelectedState, _loadLocalBodies, etc.), significantly reducing file complexity.
  - **UI Restoration**: Restored the missing TAX INFORMATION section, LOCATION ACCESS section, and TRANSACTION SERIES section in _buildBody, ensuring these features are now visible and functional.
  - **Data Binding**: Fixed _loadExisting to correctly populate pan and gst_treatment from branch data when editing. Verified that the _save payload includes all tax and compliance attributes.
  - **Lint Resolution**: Resolved several unused_element warnings by reconnecting the _buildLocationAccessContent, _buildTransactionSeriesField, and _showManageBusinessTypesDialog methods to the UI.
  - **Consistency**: Integrated the standard _buildGstinDropdownField and associated detail dialog into the branch creation flow, matching the organization profile's high-fidelity GST management.

Timestamp of Log Update: April 5, 2026 - 17:15 (IST)

## 11. Settings Fax Removal & Enterprise Schema Alignment

- **Problem**: Legacy "fax" fields in the Settings modules (Organization, Branches, Locations) were redundant and inconsistent with modern ERP communication standards.
- **Solution**: Performed a systematic cleanup of all fax references in the Settings modules, synchronized the Drizzle schema, and refined the database migration to ensure enterprise-wide consistency.
- **Frontend Files**:
  - lib/core/pages/settings_organization_profile_page.dart
  - lib/core/pages/settings_branches_create_page.dart
  - lib/core/pages/settings_locations_create_page.dart
- **Backend Files**:
  - backend/src/db/schema.ts
  - backend/drizzle/0003_awesome_ozymandias.sql
- **Logic**:
  - **Fax Purge**: Removed _faxCtrl and _paymentStubFaxController from the UI and save logic across all Settings modules.
  - **Schema Alignment**: Updated 0003_awesome_ozymandias.sql to rename outlet_id to branch_id in the accounts table and drop fax from settings_branches.
  - **Structural Repair**: Fixed syntax errors in settings_locations_create_page.dart by correcting the widget tree nesting and restoring the Phone field which was accidentally partially deleted.
  - **Scope Enforcement**: Enforced the "Settings-only" cleanup policy by explicitly removing fax drop statements for the vendors table (non-settings module) to preserve legacy data in other domains as requested.
  - **Verification**: Confirmed zero schema drift using db:pull and verified that _IndiaPhoneFormatter is correctly referenced across all affected pages.

Timestamp of Log Update: April 5, 2026 - 19:50 (IST)

## 12. Standardized Branch Settings UI & LSGD Restoration

- **Problem**: Inconsistent field order in Branch Creation compared to the requested Zoho-style mockup. Critical ERP configurations (Industry, Fiscal Year, Report Basis) were misplaced, and the Kerala-specific LSGD hierarchy for payment stubs was missing from the branch-level autonomous settings.
- **Solution**: Reorganized the SettingsBranchCreatePage form to match the gold-standard parity mockup. Restored the LSGD address hierarchy (District/Local Body/Ward) for the Payment Stub section to support localized compliance.
- **Frontend Files**:
  - lib/core/pages/settings_branches_create_page.dart
- **Logic**:
  - Reordered the form to follow the [Logo -> Name -> Industry -> Fiscal Year -> Report Basis -> Branch Code -> Email -> Business Type -> Address] layout.
  - Integrated 'Manage Business Types' as a settings footer in the Business Type dropdown using FormDropdown's showSettings parameter.
  - Restored dynamic LSGD lookups (Districts, Local Bodies, Wards) for Kerala-based branch payment stubs, ensuring accurate compliance data persistence.
  - Enforced mandatory field markers (*) for Industry, Fiscal Year, and Report Basis.

Timestamp of Log Update: April 5, 2026 - 20:30 (IST)


## 13. Organization Profile — Field Reorder, Report Basis, & UI Hardening

- **Problem**: Industry field was buried below Organization Location/State, breaking the logical top-down data entry flow (org identity then location then configuration). The Report Basis field (accrual vs. cash) existed in the database (report_basis column, default accrual) but had no UI on the Organization Profile page. The Edit Currency dialog was vertically centered instead of top-anchored, and the Date Format dropdown group headings (SHORT / MEDIUM / LONG) lacked visual weight. Several required dropdowns had no save-time validation or scroll-to-field behavior on failure.
- **Solution**: Reordered Organization Name -> Industry -> Organization Location -> State, added the Report Basis radio row after Fiscal Year, replaced the Dialog widget with a Material widget for true top-anchored positioning, bolded date format group headers, and hardened all required-field validations with scroll-to-field on error.
- **Frontend Files**:
  - lib/core/pages/settings_organization_profile_page.dart
- **Backend Files**: None — report_basis column already present in backend/src/db/schema.ts (organizations table).
- **Logic**:
  - **Field Reorder**: Moved Industry ZerpaiFormRow to immediately follow Organization Name, placing org identity fields (Name + Industry) before location fields (Location + State).
  - **Report Basis Radio**: Added _selectedReportBasis state variable (default: accrual), loaded from orgData on fetch, persisted in save payload. Used RadioGroup<String> ancestor to manage group state without deprecated groupValue/onChanged. Rich text labels (bold option + description) via RichText + TextSpan. Row placed after Fiscal Year in the Configuration section.
  - **Dialog Top Alignment**: Replaced Dialog widget with bare Material widget inside Align(Alignment.topCenter). Set useSafeArea: false on showDialog to eliminate safe-area top inset. Dialog now snaps flush to the top of the viewport with zero edge padding.
  - **Date Format Headers Bold**: Replaced AppTheme.captionText.copyWith(fontWeight: FontWeight.bold) with explicit TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.6) to guarantee visible bold rendering for SHORT / MEDIUM / LONG group separators.
  - **Validation Hardening**: Added missing Industry validation as first dropdown check in _saveProfile. Consolidated/deduplicated location and state checks that were previously placed after timezone checks. Added _scrollToKey() to all required-field error paths (Industry, Location, State, Base Currency, Fiscal Year, Time Zone, Date Format, Company ID) so the form auto-scrolls to the offending field before showing the ZerpaiToast error.

Timestamp of Log Update: April 5, 2026 - 22:10 (IST)

## 14. Branch Page — FileUploadButton Import, Unused Method Cleanup & Save Payload Fix

- **Problem**: Three post-edit issues remained in settings_branches_create_page.dart after the Regulatory Compliance UI replacement: (1) FileUploadButton widget was used but not imported, causing a build error; (2) legacy _buildRegulatoryToggle method was unused after the toggle-based UI was replaced, causing a lint warning; (3) drug_licence_20b and drug_licence_21b fields were bound to controllers but missing from the save payload.
- **Solution**: Added the missing import, removed the dead method, and added the two missing fields to the _save payload.
- **Frontend Files**:
  - lib/core/pages/settings_branches_create_page.dart
- **Logic**:
  - Added import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart' to resolve the undefined FileUploadButton build error.
  - Removed _buildRegulatoryToggle method (Switch-based toggle, no longer used after org-profile-matching UI was implemented).
  - Added 'drug_licence_20b' and 'drug_licence_21b' keys to the _save payload map, ensuring new wholesale licence fields are persisted to the database.

Timestamp of Log Update: April 5, 2026 - 22:45 (IST)

## 15. Branch Settings — Remove Dividers & Section Headings

- **Problem**: Hairline kZerpaiFormDivider lines between form rows and ALL-CAPS section headings (TAX INFORMATION, REGULATORY COMPLIANCE, LOCATION ACCESS, TRANSACTION SERIES, SUBSCRIPTION) added visual clutter inconsistent with the desired clean card layout.
- **Solution**: Stripped all dividers and section headings from the settings module.
- **Frontend Files**:
  - lib/core/pages/settings_branches_create_page.dart
  - lib/core/pages/settings_organization_profile_page.dart
- **Logic**:
  - Removed all kZerpaiFormDivider usages (21 from branches page, 10 from org profile page).
  - Removed all _buildSectionHeader(...) call sites (5 headings) and the _buildSectionHeader method definition from the branches page.

Timestamp of Log Update: April 5, 2026 - 23:00 (IST)

## 16. Branch Settings — Subscription/Transaction/Access Reorder & Spacing Cleanup

- **Problem**: Branch settings page was missing 'Subscription from', 'Default transaction series', and 'Branch access' as proper ZerpaiFormRow entries. Sections had double-SizedBox spacing causing large visual gaps between rows. FormDropdown was called with invalid 'options'/'DropdownOption' API instead of 'items'/'displayStringForValue'.
- **Solution**: Added missing _subFromKey, restructured the bottom section to match the reference layout, fixed FormDropdown API usage, removed all redundant SizedBox spacing.
- **Frontend Files**:
  - lib/core/pages/settings_branches_create_page.dart
- **Logic**:
  - Added _subFromKey GlobalKey and Subscription from ZerpaiFormRow (was missing entirely).
  - Reordered section: Subscription from -> Subscription to -> Transaction number series -> Default transaction series -> Branch access.
  - Wrapped _buildLocationAccessContent() in a ZerpaiFormRow with label 'Branch access'.
  - Added Default transaction series as a FormDropdown<String> filtered to only selected series IDs.
  - Fixed FormDropdown to use items: + displayStringForValue: instead of invalid options:/DropdownOption API.
  - Removed all redundant double-SizedBox(space24+space16) gaps between Tax Information, Industry, and Regulatory Compliance sections.

Timestamp of Log Update: April 5, 2026 - 23:20 (IST)

## 17. Branch Settings — Industry Field Moved After Branch Code

- **Problem**: Industry dropdown was placed after GSTIN in the Tax Information section, but per the requested layout it should appear immediately after Branch code (identity fields before tax configuration).
- **Solution**: Moved the Industry ZerpaiFormRow to directly follow the Branch code row.
- **Frontend Files**:
  - lib/core/pages/settings_branches_create_page.dart

Timestamp of Log Update: April 5, 2026 - 23:30 (IST)

## 18. Branch Settings — Transaction Number Series Label Alignment

- **Problem**: 'Add transaction series' dropdown was rendered outside a ZerpaiFormRow, so it appeared without a label column and stretched full-width — inconsistent with the rest of the form.
- **Solution**: Wrapped _buildTransactionSeriesField() in a ZerpaiFormRow with label 'Transaction number series' and crossAxisAlignment.start.
- **Frontend Files**:
  - lib/core/pages/settings_branches_create_page.dart

Timestamp of Log Update: April 5, 2026 - 23:40 (IST)


## 19. Branch Settings — Shared Transaction Series Reuse & Live Payment Stub LSGD Restoration

- **Problem**: The latest Branch Settings refactor had two remaining gaps. First, the Transaction number series UI was still implemented with a page-local chip/dropdown flow instead of the shared `TransactionSeriesDropdown`, which drifted from the repo's reuse-first rule. Second, the Kerala payment-stub LSGD persistence logic still existed in state/load/save code, but the live Branch form no longer rendered the District / Local Body / Ward inputs, leaving the logged restoration incomplete in practice.
- **Solution**: Standardized the Branch Settings page onto the shared transaction-series control and restored the missing payment-stub LSGD controls directly in the rendered form using the existing lookup/load/save path.
- **Frontend Files**:
  - `lib/core/pages/settings_branches_create_page.dart`
  - `lib/shared/widgets/inputs/transaction_series_dropdown.dart`
- **Backend Files**:
  - None.
- **Logic**:
  - Replaced the page-local Transaction number series builder with the shared `TransactionSeriesDropdown` for both multi-select and default-series selection, keeping the current branch save payload contract intact.
  - Extended `TransactionSeriesDropdown` with configurable placeholder text and optional suppression of the synthetic default-row entry so Branch Settings could reuse the shared control without introducing invalid default-series IDs.
  - Restored the live Payment stub address section with separate-address toggle, state/phone capture, and Kerala-only District / Local Body Type / Local Body / Ward selectors wired to the existing payment-stub lookup methods.
  - Cleared the branch-page dead code/warning residue left from earlier edits and re-ran Flutter analysis successfully on the touched files.

Timestamp of Log Update: April 5, 2026 - 22:08 (IST)


## 20. Branch Settings — Required Field Enforcement & Users-Mapped Branch Access UI

- **Problem**: Several Branch Settings inputs that the workflow depends on were visually present but not consistently enforced as required fields. Industry, Business Type, Address, GST Treatment, Drug Licence Type, Email, Transaction Number Series, and Default Transaction Series lacked a complete combination of red required-state treatment and save-time enforcement. The Branch Access card also did not match the requested table-like layout and was not preserving user-role data from the live Users dataset when assigning access.
- **Solution**: Hardened Branch Settings with explicit required-state visuals and save-time validation for the requested fields, then refactored Branch Access to match the supplied reference more closely while mapping assigned user role data directly from the Users source already loaded by the page.
- **Frontend Files**:
  - `lib/core/pages/settings_branches_create_page.dart`
  - `lib/shared/widgets/form_row.dart`
- **Backend Files**:
  - None.
- **Logic**:
  - Added required enforcement for Industry, Business Type, Address, GST Treatment, Drug Licence Type, Email, Transaction Number Series, and Default Transaction Series, combining red required labels/asterisks with field-level or save-time validation and targeted error toasts.
  - Extended `ZerpaiFormRow` with an opt-in required-label emphasis flag so required labels on the Branch page can render in red without forcing that styling globally across unrelated forms.
  - Strengthened Branch save guards so invalid submission is blocked when required dropdowns are empty, address fields are incomplete, no transaction series is selected, the default series is missing or not part of the selected series set, or Branch Access has no user selection while all-user access is disabled.
  - Reworked Branch Access into a cleaner summary + table card, preserved role values from the live `_orgUsers` dataset when users are added, formatted role labels for display, and surfaced inline validation when access remains unassigned.

Timestamp of Log Update: April 5, 2026 - 22:15 (IST)

## 21. Settings Masters — DB-Backed Lookup Integration Across Branch, Organization, and Location Settings

- **Problem**: After the new settings master tables were added in the database, several settings screens and one branch-access backend path still depended on hardcoded lists or legacy tables. Branches had already started consuming some of the new lookup endpoints, but Organization Profile and both Location settings screens still hardcoded fiscal years, date formats, date separators, GST registration types, drug licence types, and transaction-series module catalogs. Branch access also still needed to use the role-aware `settings_branch_user_access` path consistently.
- **Solution**: Completed the runtime migration to the new DB-backed settings masters by exposing lookup endpoints in the backend, wiring Branch service writes/reads to the role-aware branch-access table, and replacing the remaining hardcoded settings dropdown sources in Flutter with live lookup data.
- **Frontend Files**:
  - `lib/core/pages/settings_branches_create_page.dart`
  - `lib/core/pages/settings_organization_profile_page.dart`
  - `lib/core/pages/settings_locations_create_page.dart`
  - `lib/core/pages/settings_locations_page.dart`
- **Backend Files**:
  - `backend/src/modules/lookups/global-lookups.controller.ts`
  - `backend/src/modules/branches/branches.service.ts`
  - `backend/src/modules/branches/branches.controller.ts`
- **Logic**:
  - Added backend lookup endpoints for business types, GST treatments, GST registration types, drug licence types, fiscal year presets, date format options, date separator options, transaction modules, transaction restart options, and transaction prefix placeholders.
  - Moved branch-access persistence from the lightweight legacy mapping into `settings_branch_user_access`, resolving role labels to `settings_roles.id` where available and returning role-aware access rows back to the frontend.
  - Corrected branch save/update payload mapping for live schema fields such as `drug_licence_*`, `fiscal_year`, `report_basis`, `has_separate_payment_stub_address`, `payment_stub_address`, and MSME fields.
  - Replaced the remaining hardcoded Organization Profile dropdown data with lookup-backed fiscal year, date format, date separator, and drug licence options while preserving existing saved-value matching against labels/patterns during the migration.
  - Replaced Location Settings GST registration type and transaction-series module catalogs with lookup-backed data so new GST dialogs and series-creation flows no longer depend on embedded master lists.
  - Verified the changes with `flutter analyze` on the touched Flutter screens and `npm run build` in `backend/`.

Timestamp of Log Update: April 5, 2026 - 23:55 (IST)

## 22. Settings Routing — Missing Locations Deep Links Restored and Settings CRUD Routes Normalized

- **Problem**: The settings module had route constants for Locations and role CRUD flows, but the router did not actually register the Locations paths and the Roles create/edit/detail child routes were not fully named. That left several settings navigation actions depending on string-built URLs or pointing to routes that could not be opened directly after refresh or URL paste.
- **Solution**: Completed the missing settings deep-link surface in GoRouter and normalized the settings CRUD navigation calls to use named routes with path parameters for the major parameterized settings flows.
- **Frontend Files**:
  - `lib/core/routing/app_router.dart`
  - `lib/core/pages/settings_locations_page.dart`
  - `lib/core/pages/settings_roles_page.dart`
  - `lib/modules/settings/users/presentation/settings_users_user_overview.dart`
  - `lib/core/pages/settings_branches_list_page.dart`
  - `lib/core/pages/settings_warehouses_list_page.dart`
- **Backend Files**:
  - None.
- **Logic**:
  - Registered `settings/locations`, `settings/locations/create`, and `settings/locations/:id/edit` in `app_router.dart` so the Locations settings pages are now directly addressable and refresh-safe.
  - Added named GoRouter entries for `settingsRoleCreate`, `settingsRoleDetail`, and `settingsRoleEdit` so the Roles area has complete deep-link coverage instead of only an unnamed nested flow.
  - Switched the major settings create/edit/detail navigations for locations, users, roles, branches, and warehouses from manual `replaceFirst(':id', ...)` path assembly to `context.goNamed(..., pathParameters: ...)`.
  - Preserved the existing screen behavior while routing all major settings CRUD entry points through the centralized named-route layer.

Timestamp of Log Update: April 6, 2026 - 00:20 (IST)

## 23. Settings Address LSGD Flow — Assembly Dropdown Added for Kerala Payment Stub Addresses

- **Problem**: The Kerala-specific LSGD address flow in Settings captured district, local body type, local body, and ward, but it still missed `Assembly` even though the seeded LSGD dataset already includes assembly metadata. That left the address flow incomplete in both Organization Profile and Branch Settings.
- **Solution**: Added an Assembly lookup endpoint backed by the existing LSGD seed data and surfaced an `Assembly` dropdown in the Kerala payment-stub address sections of the settings module, saving the selected assembly alongside the existing address JSON payload.
- **Frontend Files**:
  - `lib/core/pages/settings_branches_create_page.dart`
  - `lib/core/pages/settings_organization_profile_page.dart`
- **Backend Files**:
  - `backend/src/modules/lookups/global-lookups.controller.ts`
- **Logic**:
  - Added `GET /lookups/assemblies?districtId=...` that resolves the selected district and returns distinct assembly code/name pairs from `settings_lsgd_seed_stage`.
  - Added `Assembly` dropdown state and loading logic to the Branch payment-stub LSGD flow, clearing and reloading it whenever the selected district changes.
  - Added the same `Assembly` dropdown state and loading logic to the Organization Profile payment-stub LSGD flow so both settings screens stay aligned.
  - Persisted `assembly_code` and `assembly_name` inside the existing `payment_stub_address` JSON payloads for both Branch and Organization settings so the selection survives reloads without hardcoded values.
  - Verified the touched Flutter screens with `flutter analyze` and the backend with `npm run build`.

Timestamp of Log Update: April 6, 2026 - 00:45 (IST)

## 24. Settings LSGD Normalization — Assembly Master Table Mapping

- **Problem**: The new `Assembly` dropdown in the Kerala/LSGD settings address flow was initially sourced from the raw `settings_lsgd_seed_stage` table, which worked for UI population but kept the assembly master outside the normalized settings-master layer.
- **Solution**: Switched the settings lookup path to a proper `settings_assemblies` master contract and aligned the schema cache definitions so the Assembly dropdown can be backed by a first-class settings table instead of the seed stage.
- **Frontend Files**:
  - None beyond the already-added `Assembly` dropdown wiring in Branch and Organization settings.
- **Backend Files**:
  - `backend/src/modules/lookups/global-lookups.controller.ts`
  - `backend/src/db/schema.ts`
  - `backend/drizzle/schema.ts`
- **Logic**:
  - Changed `GET /lookups/assemblies` to read active rows from `settings_assemblies` filtered by `district_id`.
  - Added `settingsAssemblies` schema definitions to the local DB schema cache so backend schema references stay aligned with the normalized table.
  - Kept the settings UI contract unchanged (`code` + `name`) so the existing `Assembly` dropdowns continue working after the table migration.
  - Verified the touched Flutter screens with `flutter analyze` and the backend with `npm run build`.

Timestamp of Log Update: April 6, 2026 - 01:00 (IST)

## 25. Settings Assembly FK Migration — Branch Save/Load Now Uses `payment_stub_assembly_id`

- **Problem**: The settings UI had already been updated to read Assembly options from `settings_assemblies`, and Organization save/load paths had started persisting `payment_stub_assembly_id`, but the Branch backend flow still treated `assembly_code` and `assembly_name` inside `payment_stub_address` JSON as the only persisted assembly source. That left the new `payment_stub_assembly_id` column unused on branch save/update and created drift between the normalized settings master and the branch payload contract.
- **Solution**: Moved the Branch backend save/load path onto `payment_stub_assembly_id` as the persisted source of truth while preserving the existing frontend JSON contract during the transition.
- **Frontend Files**:
  - None.
- **Backend Files**:
  - `backend/src/modules/branches/branches.service.ts`
  - `backend/src/db/schema.ts`
- **Logic**:
  - Added Branch service helpers to parse the payment-stub JSON payload, resolve the selected assembly against `settings_assemblies`, and rehydrate `assembly_code` / `assembly_name` back into the JSON returned to the current frontend.
  - Updated branch create to derive and persist `payment_stub_assembly_id` from the submitted payment-stub JSON whenever separate payment-stub addressing is enabled.
  - Updated branch update to clear `payment_stub_assembly_id` when separate payment-stub addressing is disabled and to recompute it from `payment_stub_address` whenever that JSON payload changes.
  - Updated the local DB schema cache to include `payment_stub_assembly_id` on both `organization` and `settings_branches`, keeping the codebase schema definitions aligned with the live database.
  - Verified the backend build with `npm run build`.

Timestamp of Log Update: April 5, 2026 - 23:44 (IST)

## 26. Log Sync — Assembly FK Save/Load Migration Confirmed

- **Problem**: The latest backend migration that moved branch payment-stub assembly persistence onto `payment_stub_assembly_id` needed an explicit follow-up log sync so the implementation trail stays current in `log.md`.
- **Solution**: Recorded the completed branch save/load migration and verification status as a separate confirmation entry.
- **Frontend Files**:
  - None.
- **Backend Files**:
  - `backend/src/modules/branches/branches.service.ts`
  - `backend/src/db/schema.ts`
- **Logic**:
  - Confirmed branch create/update now resolve assembly selections against `settings_assemblies` and persist `payment_stub_assembly_id`.
  - Confirmed branch read responses still hydrate `assembly_code` and `assembly_name` into `payment_stub_address` JSON for frontend compatibility.
  - Confirmed backend schema cache now includes the assembly FK columns used by the live settings schema.
  - Confirmed verification completed with `npm run build` in `backend/`.

Timestamp of Log Update: April 5, 2026 - 23:46 (IST)

## 27. Settings Deep-Link Fix — Missing `orgSystemId` Path Parameters Restored

- **Problem**: Several settings screens had been moved to named GoRouter navigation, but some `goNamed(...)` calls into routes nested under `/:orgSystemId/...` were still being fired without `orgSystemId`. That caused runtime assertions like `missing param "orgSystemId"` when opening settings create/edit flows such as Branch Create.
- **Solution**: Restored `orgSystemId` path parameter passing in the affected settings create/edit/detail navigations.
- **Frontend Files**:
  - `lib/core/pages/settings_branches_list_page.dart`
  - `lib/core/pages/settings_locations_page.dart`
  - `lib/core/pages/settings_warehouses_list_page.dart`
  - `lib/core/pages/settings_roles_page.dart`
  - `lib/modules/settings/users/presentation/settings_users_user_overview.dart`
- **Backend Files**:
  - None.
- **Logic**:
  - Updated Branch, Location, Warehouse, User, and Role settings navigations to pass the current `orgSystemId` from `GoRouterState.of(context).pathParameters`.
  - Fixed Branch and Warehouse action-menu edit routes and related cross-navigation into Locations.
  - Kept the named-route approach intact instead of falling back to raw `Navigator` calls or string-built URLs.
  - Verified with `flutter analyze` on the touched settings screens.

Timestamp of Log Update: April 5, 2026 - 23:58 (IST)

## 28. Settings Warehouses — Create Page Layout Restored to Standard Settings Form Pattern

- **Problem**: The Warehouse Create screen had drifted away from the standard settings create-page layout. Its footer was rendered inside the constrained form body, the primary action styling had switched away from the shared settings treatment, and the address field ordering no longer matched the intended settings UI.
- **Solution**: Restored the Warehouse Create screen to the same fixed-header settings layout pattern used by the reference settings forms.
- **Frontend Files**:
  - `lib/core/pages/settings_warehouses_create_page.dart`
- **Backend Files**:
  - None.
- **Logic**:
  - Moved the warehouse page action bar into the shared `SettingsFixedHeaderLayout.footer` slot so the footer spans the page correctly instead of appearing as a narrow inline block.
  - Restored the primary save button to use the settings accent/primary styling and kept the neutral outlined cancel treatment.
  - Reordered the address section to match the expected settings layout: `City + Pin code`, then `Country`, then `State / Union territory`.
  - Preserved the existing form behavior and data mapping while correcting only the visual/layout regression.
  - Verified with `flutter analyze lib/core/pages/settings_warehouses_create_page.dart`.

Timestamp of Log Update: April 5, 2026 - 23:52 (IST)

## 29. Kerala LSGD Drill-Down Added to Main Branch and Warehouse Address Sections

- **Problem**: The main address blocks in Settings Branch Create and Settings Warehouse Create only captured generic address text and state. Kerala-specific address hierarchy fields (`district`, `local body`, `ward`) were missing from the main address flow, even though Branch already had backend support for those IDs and the LSGD lookup APIs already existed. Warehouse also lacked DB/backend support for persisting those address IDs.
- **Solution**: Added a Kerala-only LSGD drill-down under the main address section in both Branch and Warehouse create/edit screens, wired save/load behavior for the new IDs, and extended Warehouse backend/schema support to persist `district_id`, `local_body_id`, and `ward_id`.
- **Frontend Files**:
  - `lib/core/pages/settings_branches_create_page.dart`
  - `lib/core/pages/settings_warehouses_create_page.dart`
- **Backend Files**:
  - `backend/src/modules/warehouses-settings/warehouses-settings.service.ts`
  - `backend/src/db/schema.ts`
  - `backend/drizzle/schema.ts`
- **Logic**:
  - Added a second Kerala-aware lookup flow to the Branch main address section so `district`, `local body type`, `local body`, and `ward` appear only when the selected main address state is Kerala.
  - Preserved the existing Payment Stub Kerala flow on Branch and kept it separate from the main address hierarchy.
  - Extended Warehouse Create/Edit to match the Branch main-address pattern by adding phone plus Kerala-only `district`, `local body type`, `local body`, and `ward` dropdowns under the normal address block.
  - Wired Branch main-address save/load to the already-existing `district_id`, `local_body_id`, and `ward_id` branch fields.
  - Extended Warehouse backend create/update to accept and persist `district_id`, `local_body_id`, and `ward_id`.
  - Updated backend schema caches so the Warehouse table definitions stay aligned with the live database after the warehouse migration is applied.
  - Verified with `flutter analyze lib/core/pages/settings_branches_create_page.dart lib/core/pages/settings_warehouses_create_page.dart` and `npm run build` in `backend/`.

Timestamp of Log Update: April 6, 2026 - 01:34 (IST)

## 30. Branch and Warehouse Main Address Layout Aligned to Kerala LSGD Screenshot Pattern

- **Problem**: The Kerala-only LSGD drill-down had been added to the main address blocks, but the row structure still did not match the requested layout. The user specifically wanted the main address section to follow the screenshot pattern: `District + Local body type`, then `Local body name + Ward`, then a full-width `Assembly` field in place of the old fax-style row. The database layer also still lacked a first-class `assembly_id` on main branch and warehouse addresses.
- **Solution**: Reshaped both main address sections to match the requested layout exactly and added first-class `assembly_id` persistence for Branch and Warehouse.
- **Frontend Files**:
  - `lib/core/pages/settings_branches_create_page.dart`
  - `lib/core/pages/settings_warehouses_create_page.dart`
- **Backend Files**:
  - `backend/src/modules/branches/branches.service.ts`
  - `backend/src/modules/warehouses-settings/warehouses-settings.service.ts`
  - `backend/src/db/schema.ts`
  - `backend/drizzle/schema.ts`
- **Logic**:
  - Updated the Branch main address Kerala section to use:
    - `District + Local body type`
    - `Local body name + Ward`
    - `Assembly` as a full-width row
  - Updated the Warehouse main address Kerala section to use the exact same layout and lookup flow.
  - Added main-address `assembly_id` save/load wiring for both Branch and Warehouse.
  - Extended Branch and Warehouse backend update/create flows to persist `assembly_id` as a normalized UUID.
  - Updated local schema caches so Branch and Warehouse address models include `assembly_id`.
  - Verified with `flutter analyze lib/core/pages/settings_branches_create_page.dart lib/core/pages/settings_warehouses_create_page.dart` and `npm run build` in `backend/`.

Timestamp of Log Update: April 6, 2026 - 01:51 (IST)

## 31. Organization Profile — Primary Contact Gear Added and Placeholder Address Banner Replaced

- **Problem**: The Organization Profile page still had a placeholder “Organization Address” info banner instead of a real editable address form, while the Primary Contact card lacked the requested settings gear affordance. The organization backend also did not expose or persist a full branch-style main address model for the org profile.
- **Solution**: Added the settings gear with a `Coming soon` toast to the Primary Contact card and replaced the placeholder organization-address banner with a full address form that follows the branch creation page pattern, including Kerala-only LSGD drill-down and Assembly.
- **Frontend Files**:
  - `lib/core/pages/settings_organization_profile_page.dart`
- **Backend Files**:
  - `backend/src/modules/lookups/global-lookups.controller.ts`
  - `backend/src/db/schema.ts`
  - `backend/drizzle/schema.ts`
- **Logic**:
  - Replaced the static organization-address info banner with editable org address fields: `Attention`, `Street 1`, `Street 2`, `City`, `Pin code`, `Country`, `State / Union territory`, `Phone`, and Kerala-only `District`, `Local body type`, `Local body name`, `Ward`, and `Assembly`.
  - Kept the existing org country/state behavior by moving the country selector into the new address section and preserving the dependent state/timezone reload flow.
  - Added org-address save/load support for `attention`, `address_street_1`, `address_street_2`, `city`, `pincode`, `phone`, `district_id`, `local_body_id`, `assembly_id`, and `ward_id`.
  - Added a top-right gear icon to the Primary Contact card that shows `Coming soon` via `ZerpaiToast`.
  - Updated org profile save verification to include the new address fields.
  - Verified with `flutter analyze lib/core/pages/settings_organization_profile_page.dart` and `npm run build` in `backend/`.

Timestamp of Log Update: April 6, 2026 - 02:13 (IST)

## 32. Settings Users Screens Switched from Raw Spinners to Shared Skeleton Loading States

- **Problem**: A few remaining settings user flows still used raw `CircularProgressIndicator` placeholders during their initial async fetches, which broke the otherwise consistent settings loading experience across the module.
- **Solution**: Replaced the remaining full-screen and pane-level spinners in the Users settings flows with the shared skeleton loading reusables already used elsewhere in settings.
- **Frontend Files**:
  - `lib/modules/settings/users/presentation/settings_users_user_overview.dart`
  - `lib/modules/settings/users/presentation/settings_users_user_creation.dart`
- **Backend Files**:
  - None.
- **Logic**:
  - Added a full list/detail loading skeleton to the Users overview screen so both standalone list mode and master-detail mode render with shared table/list/detail placeholders while data loads.
  - Added a full loading scaffold to the User creation screen using the existing shared skeleton patterns for the header, form rows, access section, dual-pane location card, and footer.
  - Replaced the nested location-tree spinner inside the User creation access pane with a shared list skeleton so reloads remain visually consistent inside the split card.
  - Reused the existing shared `ZBone`, `ZFormSkeleton`, `ZListSkeleton`, `ZTableSkeleton`, and `ZDetailContentSkeleton` reusables instead of introducing new screen-local skeleton widgets.
  - Verified with `flutter analyze lib/modules/settings/users/presentation/settings_users_user_overview.dart lib/modules/settings/users/presentation/settings_users_user_creation.dart`.

Timestamp of Log Update: April 6, 2026 - 02:31 (IST)

## 33. Settings Module Log Sync for Skeleton Coverage Rollout

- **Problem**: The latest settings skeleton coverage rollout had already been applied in code, but the user requested an explicit fresh log update to keep the running implementation trail current.
- **Solution**: Added a follow-up log-sync entry confirming the settings loading-state standardization work and its current verified status.
- **Frontend Files**:
  - `lib/modules/settings/users/presentation/settings_users_user_overview.dart`
  - `lib/modules/settings/users/presentation/settings_users_user_creation.dart`
- **Backend Files**:
  - None.
- **Logic**:
  - Confirmed the shared settings skeleton rollout remains applied to the outstanding user-settings screens.
  - Kept the implementation aligned with the existing shared skeleton reusables instead of introducing any new loading widget layer.
  - Retained the previously verified state from `flutter analyze lib/modules/settings/users/presentation/settings_users_user_overview.dart lib/modules/settings/users/presentation/settings_users_user_creation.dart`.

Timestamp of Log Update: April 6, 2026 - 02:36 (IST)

## 34. Transaction Series — Branch Code and Warehouse Code Persisted as First-Class Fields

- **Problem**: The transaction-series creation flow showed `Branch Code` in the branch dialog as read-only context, but that code was not being persisted into `settings_transaction_series`. The warehouse/location transaction-series flow also had no equivalent first-class `warehouse_code` persistence, leaving the table out of sync with the UI intent.
- **Solution**: Wired `branch_code` and `warehouse_code` into `settings_transaction_series` as first-class persisted fields and updated the relevant transaction-series creation payloads to send them.
- **Frontend Files**:
  - `lib/core/pages/settings_branches_create_page.dart`
  - `lib/core/pages/settings_locations_create_page.dart`
- **Backend Files**:
  - `backend/src/modules/transaction-series/transaction-series.service.ts`
  - `backend/src/db/schema.ts`
  - `backend/drizzle/schema.ts`
- **Logic**:
  - Updated transaction-series create/update persistence to accept and save `code`, `branch_code`, and `warehouse_code`.
  - Kept the branch transaction-series dialog aligned with the existing UI while making the displayed branch code actually persist.
  - Extended the legacy location transaction-series dialog to auto-generate a series code and send either `branch_code` or `warehouse_code` based on the selected location type.
  - Aligned the Drizzle schema caches with the altered `settings_transaction_series` table shape.
  - Verified with `flutter analyze lib/core/pages/settings_branches_create_page.dart lib/core/pages/settings_locations_create_page.dart` and `npm run build` in `backend/`.

Timestamp of Log Update: April 6, 2026 - 03:02 (IST)

## 35. Transaction Series Modal — Branch and Warehouse Added as Proper Module Rows

- **Problem**: The transaction-series preferences modal still did not match the intended layout. `Branch Code` / `Warehouse Code` had been surfaced as separate context fields and then as a table column, but the user wanted `Branch` and `Warehouse` to appear as normal transaction rows in the same list as `Credit Note`, `Invoice`, and the other module entries.
- **Solution**: Removed the incorrect code-column treatment and appended `Branch` and `Warehouse` to the transaction-module row source so both transaction-series modals render them as standard rows.
- **Frontend Files**:
  - `lib/core/pages/settings_branches_create_page.dart`
  - `lib/core/pages/settings_locations_create_page.dart`
- **Backend Files**:
  - None.
- **Logic**:
  - Removed the temporary `BRANCH CODE` / `WAREHOUSE CODE` table-column approach from the transaction-series modal.
  - Added helper logic in both settings flows so `Branch` and `Warehouse` are injected into the module-row list if they are not already present in the lookup-backed module master.
  - Kept the persisted `branch_code` / `warehouse_code` backend support intact while fixing only the modal row rendering pattern.
  - Verified with `flutter analyze lib/core/pages/settings_branches_create_page.dart lib/core/pages/settings_locations_create_page.dart`.

Timestamp of Log Update: April 6, 2026 - 03:16 (IST)
