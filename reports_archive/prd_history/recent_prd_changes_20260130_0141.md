# PRD Changes (last 1 hour)

Generated: 2026-01-30 01:41

## Files
- D:\K4NN4N\zerpai_erp\PRD\README_PRD.md — 2026-01-30 01:26:00
- D:\K4NN4N\zerpai_erp\PRD\recent_prd_changes_20260130_0133.md — 2026-01-30 01:33:13
- D:\K4NN4N\zerpai_erp\PRD\PRD.md — 2026-01-30 01:38:44
- D:\K4NN4N\zerpai_erp\PRD\prd_ui.md — 2026-01-30 01:39:06

## Diffs
```diff
diff --git a/PRD/PRD.md b/PRD/PRD.md
index c5168c3..5974728 100644
--- a/PRD/PRD.md
+++ b/PRD/PRD.md
@@ -7,8 +7,8 @@ Do not edit PRD files unless explicitly requested by the user or team head.
 ## 🔒 Auth Policy (Pre-Production)
 
 No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
-**Last Edited:** 2026-01-28 22:59
-**Last Edited Version:** 1.4
+**Last Edited:** 2026-01-30 01:38
+**Last Edited Version:** 2.1
 
 ---
 
@@ -195,10 +195,11 @@ The primary navigation is a Zoho-style collapsible sidebar. Current order (as im
 3.  Inventory
 4.  Sales
 5.  Purchases
-6.  Reports
-7.  Documents
+6.  Accounts (Primary module: Chart of Accounts)
+7.  Reports
+8.  Documents
 
-Additional modules (e.g., Settings, Accounts) are planned but not yet part of the sidebar.
+Additional modules (e.g., Settings) are planned but not yet part of the sidebar.
 
 ### 8.2 Sales Workflow (STRICT)
 
@@ -430,6 +431,16 @@ All UI colors, typography, spacing, and interaction behavior MUST originate from
 
 **❌ MUST NOT:** Arbitrary spacing values are not allowed.
 
+### 14.4.1 Layout Stability Rules (Golden Rules) — MANDATORY
+
+These rules prevent overflow, unbounded constraints, and broken layouts. **All developers and AI agents MUST follow them strictly.**
+
+1. **Expanded Rule (Overflow Fix):** Any child inside a `Row` or `Column` that can grow (e.g., `Text`, `TextField`, `ListView`) **must** be wrapped in `Expanded` or `Flexible` to respect available space.
+2. **Scroll Rule (Unbounded Constraints Fix):** **Never** place `Expanded` inside a `SingleChildScrollView` or `ListView` in the same axis. Use `SizedBox`/`ConstrainedBox`, `CustomScrollView`, or `shrinkWrap: true` only when necessary.
+3. **Safe Text Rule:** Any text from API/DB must define `maxLines` and `overflow` (e.g., `TextOverflow.ellipsis`) so long strings never break layout.
+4. **Responsive Rule (Web Critical):** Avoid fixed pixel widths for major layout regions. Use `Flex`/`Expanded` ratios or `LayoutBuilder` constraints. Fixed widths are allowed only for icons, small controls, or min/max bounds.
+5. **Constraint Inspection Rule:** If a layout breaks, check parent constraints first. Preferred hierarchy: `Scaffold -> Column -> Expanded -> Row -> Expanded -> Scrollable` for complex dashboards.
+
 ### 14.5 Table System (CRITICAL SECTION)
 
 #### 14.5.1 Table Behavior Rules (MANDATORY)
@@ -500,6 +511,253 @@ The AI agent must strictly follow the global UI system defined in `app_theme.dar
 - Improvements apply only to new or refactored modules.
 - Migration will be handled separately at production stage.
 
+### 14.11 Menu & Dropdown System (Unified Refactor)
+
+To ensure a modern and consistent user interface, the application has standardized its menu and dropdown architecture:
+
+- **MenuAnchor:** All legacy `PopupMenuButton` instances MUST be refactored to use `MenuAnchor`. This is the standard for all action-based menus and triggers.
+- **MenuItemButton:** Use standard `MenuItemButton` widgets for children within a `MenuAnchor`.
+- **FormDropdown:** For all form-based inputs and selections, use the `FormDropdown` component (defined in `dropdown_input.dart`). Do not use `MenuAnchor` or `DropdownButton` for form inputs.
+- **Hover States:** Rely on the native hover and focus states of `MenuItemButton`. Custom implementations like `_HoverableMenuItem` are deprecated and should be removed.
+
+### 14.12 Form UI System (Creation/Edit Pages) — MANDATORY
+
+These rules define the visual and interaction standards for all **creation/edit pages** (e.g., New Customer, New Invoice). **All developers and AI agents MUST follow them strictly.**
+
+#### 14.12.1 General Layout & Grid System
+
+- **Sidebar Navigation (Left):** Dark theme (~`#2C3E50`). Accordion pattern; clicking parent expands children. Active tab uses green accent (~`#22A95E`) with a lighter background block.
+- **Main Canvas (Right):** Light theme (white cards on very light gray background).
+- **Header (Top):** Minimal; document title, breadcrumbs, and window controls (Close/Maximize).
+- **Global Search:** Context-aware placeholder with keyboard shortcut hint (`/`).
+- **Recent History:** Clock icon showing the last 5–10 visited records.
+- **Form Alignment:** Left-aligned horizontal labels, fixed label column width, fluid input column.
+- **Gutter:** Clear whitespace between label column and input column.
+- **Sectioning:** Logical blocks separated by whitespace (avoid heavy borders).
+
+#### 14.12.2 Input Fields & Text Entry
+
+- **Standard Inputs:** Rectangular, slight radius (3–4px), thin light-gray border (~`#E0E0E0`), consistent height (~36px).
+- **Focus State:** Blue or green border/glow to indicate focus.
+- **Required Fields:** Red asterisk; label often red.
+- **Text Areas:** Multi-line with resize handle (bottom-right diagonal lines). Optional helper text like "Max 500 characters".
+- **Compound Inputs:** Multiple related fields on one row (e.g., [Salutation] [First Name] [Last Name]) with tight spacing.
+- **Input Adornments:** Numeric fields with attached gray unit dropdowns on the right (e.g., kg, cm).
+
+#### 14.12.3 Dropdowns & Select Menus
+
+- **Standard Select:** White box with right chevron; placeholder in light gray.
+- **Searchable Select (Autocomplete):** Input + dropdown; often paired with a green search/lookup button on the right.
+- **Dropdown Content:** Grouped items; richer rows with status circle, primary line (name/code), secondary line (company/code).
+- **Date Picker:** Field with calendar icon; dropdown panel with month/year header, arrows, 7-column grid, highlighted active date, and subtle "today" indicator.
+
+#### 14.12.4 Tabular Input (Item Table)
+
+- **Headers:** Uppercase, bold, small font (ITEM DETAILS, QUANTITY, RATE, TAX, AMOUNT).
+- **Hardware Integration:** “Scan Item” button with barcode icon above table headers.
+- **Context Filters:** Table-level selectors (e.g., Warehouse, Price List) between section header and grid.
+- **Rows:** Empty-state row shows placeholder image + text ("Type or click to select an item.").
+- **Inline Editing:** Text appears static until clicked.
+- **Numeric Columns:** Right-aligned (quantity/rate/amount).
+- **Row Actions:** On hover, show red delete (x) and drag handle (dotted grid) at far right.
+- **Bulk Action:** "Add items in Bulk" below table.
+
+#### 14.12.5 Tabs & Internal Navigation
+
+- **Horizontal Tabs:** Text-only; selected state uses blue text + blue underline; default state is gray.
+- **View Switcher Dropdown:** "All [Module]" dropdown with favorite star; list items show blue link styling.
+
+#### 14.12.6 Buttons & Actions
+
+- **Primary Action:** Green (~`#22A95E` to `#28A745`), white text, rounded corners.
+- **Split Button:** Primary action with dropdown for alternatives (e.g., Save & Send).
+- **Secondary Action:** Neutral/gray or outline; cancel is link/ghost.
+- **Utility Icons:** Small gear/settings icons beside specific fields (outlined blue/gray).
+
+#### 14.12.7 Feedback & Status Indicators
+
+- **Info Icons:** Small "i" inside a circle; hover shows tooltip.
+- **Inline Hints:** Gray helper text inside/below fields.
+- **Status Tags (List View):** Colored text (no pill). APPROVED=Blue, RECEIVED=Green.
+- **Validation:** Red input border + red error text below.
+
+#### 14.12.8 Visual Language Summary
+
+- **Font:** Sans-serif (high legibility).
+- **Colors:** Primary=Green (actions), Secondary=Blue (links/selection), Alert=Red (required/delete).
+- **Density:** High density, compact spacing for power users.
+
+#### 14.12.9 Right Utility Bar (Collapsible Sidebar)
+
+- **Right Utility Bar:** Fixed-position vertical icon strip at far right with a light-gray divider.
+- **Icons:** Help (?), Updates (megaphone), Feedback (chat), App Switcher (grid), User Avatar.
+- **Behavior:** Clicking an icon opens a right-side slide-out panel (overlay, no page navigation).
+
+#### 14.12.10 Swap Interaction (Transfer Order)
+
+- **Swap Control:** Circular two-arrow icon between Source/Destination warehouse fields.
+- **Behavior:** Clicking swaps the values of the two dropdowns.
+- **Placement:** Sits in the gutter between columns to imply it affects both fields.
+
+#### 14.12.11 Inside-Input Actions (Config Gear)
+
+- **Embedded Gear:** Gear icon appears **inside** the input on the right edge (auto-number fields).
+- **Meaning:** Field is auto-generated; gear opens configuration (prefix/sequence), not manual input.
+
+#### 14.12.12 Advanced Table Row Actions (Kebab Menu)
+
+- **Row Actions:** Red delete (x), drag handle, and vertical ellipsis (⋮) for advanced options.
+- **Menu Options:** Clone row, add description row, show additional fields (discount, serial, etc.).
+
+#### 14.12.13 Breadcrumb & Back Navigation
+
+- **Header Pattern:** Module Icon → Back Arrow → Page Title.
+- **Behavior:** Back arrow returns to the list view (one-click up).
+
+#### 14.12.14 Dropdown Visual Hierarchy (Rich List)
+
+- **Active Row:** Blue background (~`#408DFB`) with white text.
+- **Scrollbar:** Slim floating scrollbar (webkit-style).
+- **Row Layout:** Primary line (bold/normal) + secondary line (smaller/gray).
+
+#### 14.12.15 Placeholder Date Formatting
+
+- **Format Hint:** Empty date fields show `dd-MM-yyyy` as placeholder.
+
+#### 14.12.16 Currency Prefix Alignment
+
+- **Prefix:** Currency symbol (₹/INR) outside the input or non-editable prefix.
+- **Alignment:** Totals column aligns currency symbols vertically for clean numeric columns.
+
+#### 14.12.17 Checkbox Grouping (Progressive Disclosure)
+
+- **Checkbox Style:** Standard square checkbox with label to the right.
+- **Behavior:** Certain checkboxes appear only when relevant (indented, progressive disclosure).
+
+#### 14.12.18 Link Styling in List Views
+
+- **Primary Identifier:** Blue link (e.g., Order # / RMA #) navigates to document.
+- **Secondary Data:** Black/gray text; may be non-clickable or filter-only.
+- **Sort Indicators:** Column headers show up/down arrows on hover/active.
+
+#### 14.12.19 Draft vs Live Status Visuals
+
+- **Save as Draft:** Neutral/gray (low urgency).
+- **Save and Send:** Green (high urgency).
+- **Cancel:** Text-only, no background (escape hatch).
+
+#### 14.12.20 Organization Switcher (Tenant Selector)
+
+- **Location:** Top-right header, near the primary “New (+)” action.
+- **Design:** Dropdown text link showing current org (e.g., “ZABNIX PRIVATE L...”).
+- **Behavior:** Switches between organizations without logout (multi-entity support).
+
+#### 14.12.21 Master Checkbox (Bulk Selection)
+
+- **Header Checkbox:** Far-left of table header.
+- **Logic:** Unchecked = none, checked = all visible rows, indeterminate (dash) = partial selection.
+
+#### 14.12.22 Sidebar Hamburger Toggle
+
+- **Location:** Top-left near logo.
+- **Behavior:** Collapses sidebar to icon-only mini mode to expand canvas width.
+
+#### 14.12.23 Semantic Status Colors (Text-Only)
+
+- **Approved/Open:** Blue text.
+- **Received/Closed:** Green text.
+- **Draft/Void:** Black/gray text.
+
+#### 14.12.24 Round Off Logic (Footer Calculation)
+
+- **Row Placement:** Between Subtotal and Total.
+- **Behavior:** Auto-calculates rounding difference; optionally editable for manual adjustment.
+
+#### 14.12.25 Reference # vs Order Number
+
+- **Order Number:** Auto-generated; uses gear/config and is typically non-editable.
+- **Reference #:** User-entered customer PO/reference field (standard text input).
+
+#### 14.12.26 Attachment Module
+
+- **Section:** “Attach File(s) to Transfer Order” (or equivalent).
+- **Controls:** Upload button with cloud/arrow icon; dropdown source selector.
+- **Constraints:** Microcopy shows limits (e.g., max 5 files, 10MB each).
+
+#### 14.12.27 Currency & Locale Indicators
+
+- **Currency Code:** Displayed as INR where applicable.
+- **Formatting:** Two decimal places (0.00) and right-aligned numeric columns with aligned decimals.
+
+#### 14.12.28 Guided Action Links (Empty States)
+
+- **Empty State CTA:** Instructional text + a single action button (e.g., “Add Items”).
+- **Behavior:** Guides users to the next required step, not a blank table.
+
+#### 14.12.29 Active Tab Sidebar Indicator
+
+- **Visual:** Vertical green bar on far left edge of the active sidebar item.
+- **Purpose:** Clear active state via position + color.
+
+#### 14.12.30 Mandatory Label Styling
+
+- **Rule:** Entire label text turns red for required fields (not just the asterisk).
+
+#### 14.12.31 Terms Dropdown Logic
+
+- **Behavior:** Selecting payment terms (e.g., Net 15/Net 360) auto-updates Due Date.
+- **Type:** Trigger input (changes dependent fields).
+
+#### 14.12.32 PDF Template Switcher (Footer)
+
+- **Location:** Bottom-right footer of creation forms (e.g., Retainer Invoice, Delivery Challan).
+- **Design:** “PDF Template: Standard Template” with a Change action.
+- **Behavior:** Pre-save print configuration (template selection before saving).
+
+#### 14.12.33 Just-in-Time Stock Visibility
+
+- **Location:** Under item table in Transfer Order.
+- **Design:** “CURRENT AVAILABILITY” with Source Stock / Destination Stock.
+- **Behavior:** Real-time population based on selected items; prevents invalid transfers.
+
+#### 14.12.34 HSN Lookup (External Search)
+
+- **Location:** Item creation → HSN Code field.
+- **Design:** Blue magnifying-glass icon (distinct from dropdown chevron).
+- **Behavior:** Opens modal/global lookup (external GST/HSN database).
+
+#### 14.12.35 Rich-Content Dropdowns (Card List)
+
+- **Location:** Package / Sales Order selection dropdowns.
+- **Design:** Micro-card items with left badge, blue primary line, gray secondary line.
+- **Purpose:** Disambiguate similar IDs quickly.
+
+#### 14.12.36 Progressive Disclosure (Toggle Checkboxes)
+
+- **Location:** Item creation → Sellable / Purchasable.
+- **Behavior:** Toggles visibility of Sales/Purchase info blocks to reduce clutter.
+
+#### 14.12.37 Dynamic Primary Button Text
+
+- **Behavior:** Primary CTA text changes by module context (e.g., “Save and Send”, “Generate picklist”).
+- **Goal:** Action-oriented labeling for clarity.
+
+#### 14.12.38 Inventory Tracking Shortcut
+
+- **Location:** Sales Order footer (right).
+- **Design:** Small blue link with box icon (“Inventory Tracking”).
+- **Behavior:** Cross-module quick view of stock history/availability.
+
+#### 14.12.39 GST/Tax Trigger Fields
+
+- **GST Treatment:** Controls GSTIN visibility/required state.
+- **Place of Supply:** Auto-populates from address, allows override.
+
+#### 14.12.40 Live Chat Integration
+
+- **Locations:** Bottom bar (“Smart Chat”), sidebar (“Chats”).
+- **Behavior:** Internal chat/command palette; `Ctrl+Space` hint for quick access.
+
 ---
 
 ## 15. File Naming Convention (STRICT)
diff --git a/PRD/README_PRD.md b/PRD/README_PRD.md
index 4fcc842..5a3fd62 100644
--- a/PRD/README_PRD.md
+++ b/PRD/README_PRD.md
@@ -7,8 +7,8 @@ Do not edit PRD files unless explicitly requested by the user or team head.
 ## 🔒 Auth Policy (Pre-Production)
 
 No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
-**Last Edited:** 2026-01-28 22:59
-**Last Edited Version:** 1.4
+**Last Edited:** 2026-01-29 23:32
+**Last Edited Version:** 1.6
 
 ---
 
@@ -95,6 +95,15 @@ These are extracted from the comprehensive PRD for focused operational use:
 
 ---
 
+#### 8. **`prd_ui.md`** 🎨 **UI-ONLY PRD**
+
+- UI standards only (layouts, inputs, tables, navigation chrome)
+- Creation/edit page rules
+- Advanced UI behaviors and hidden logic
+- **Use this for:** UI/UX implementation and consistency
+
+---
+
 ## 🗺️ Quick Navigation
 
 ### **For Developers:**
@@ -103,6 +112,8 @@ These are extracted from the comprehensive PRD for focused operational use:
 2. Follow file naming: `module_submodule_page.dart`
 3. Use Riverpod, Dio (no deprecated packages!)
 4. Reference Section 14 (UI System & Design Governance)
+5. Use `prd_ui.md` for UI-only rules and patterns
+5. Follow Layout Stability Rules (Section 14.4.1)
 
 ### **For DevOps:**
 
@@ -139,8 +150,9 @@ These are extracted from the comprehensive PRD for focused operational use:
 | **prd_monitoring.md**        | 9        | ~300  | Metrics, alerts, logs        |
 | **prd_onboarding.md**        | 8        | ~350  | User setup, training, FTUE   |
 | **prd_roadmap.md**           | 11       | ~550  | Versions, features, timeline |
+| **prd_ui.md**                | 47       | 380   | UI-only standards & patterns |
 
-**Total:** ~4,567 lines of comprehensive documentation
+**Total:** ~4,947 lines of comprehensive documentation
 
 ---
 
@@ -158,6 +170,9 @@ These **cannot** be changed without major discussion:
 8. **Testing:** 70% coverage minimum - Section 17.2
 9. **Latest Stable Dependencies Only** - Section 7.1
 10. **DB Options/Master Table Naming:** `<module_name>_<options_descriptor>` for all new lookup tables - Section 12.1
+11. **Menu & Dropdown System:** Mandatory use of `MenuAnchor` for actions and `FormDropdown` for inputs - Section 14.11
+12. **Accounts Module:** Sidebar integration with Chart of Accounts - Section 8.1
+13. **Layout Stability Rules (Golden Rules):** Mandatory for all UI layouts - Section 14.4.1
 
 ---
 
@@ -216,5 +231,5 @@ All PRD documents are version-controlled in Git. Check commit history for change
 
 ---
 
-**Last Updated:** 2026-01-29  
+**Last Updated:** 2026-01-30  
 **Next Review:** 2026-04-20
```
