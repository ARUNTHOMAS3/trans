# 🎨 UI-Only PRD (Zerpai ERP)

**Purpose:** UI standards and visual interaction rules only.  
**Scope:** All creation/edit pages, lists, tables, and navigation chrome.  
**Last Edited:** 2026-01-30 03:38  
**Version:** 1.7

---

## 1. Core UI Governance (Mandatory)

- **Use app_theme.dart tokens only** (colors, spacing, typography).
- **No hardcoded colors, spacing, or fonts** unless explicitly approved.
- **All UI decisions must follow PRD Section 14** and the rules below.
- **All modal, popup, dropdown, menu, date-picker, popover, and overlay surfaces must default to pure white `#FFFFFF`.** Do not rely on inherited Material surface tinting or non-white theme surfaces unless an explicit design exception is approved.
- **Use `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` as the standard reusable date picker** wherever the shared anchored picker pattern is feasible. Do not add new raw `showDatePicker(...)` usages for standard ERP screens unless an explicit exception is required.
- **Icons:** Use Lucide for ~95% of UI icons. Use FontAwesome **only** for brand icons (WhatsApp, Google, etc.).
- **Icon Packages:** `lucide_icons` (primary), `font_awesome_flutter` (brands only).

---

## 1.5 UI Case Standards (Mandatory)

| UI Element                  | Case Style            | Usage Rules                      | Examples                     | Must Not                                 |
| :-------------------------- | :-------------------- | :------------------------------- | :--------------------------- | :--------------------------------------- |
| Page / Screen Title         | Title Case            | Primary page identifier.         | Create Sales Order           | CREATE SALES ORDER, Create sales order   |
| Section Headings            | Title Case            | Grouping related content.        | Billing Information          | Billing information, BILLING INFORMATION |
| Sidebar Menu Items          | Title Case            | Consistent navigation labels.    | Inventory, Reports           | dashboard, DASHBOARD                     |
| Form Field Labels           | Sentence case         | Description for user input.      | Customer name, Invoice date  | Customer Name, CUSTOMER NAME             |
| Placeholder Text            | Sentence case         | Hint text inside inputs.         | Enter customer name          | Enter Customer Name                      |
| Primary / Secondary Buttons | Title Case            | Action-oriented, no punctuation. | Save, Create Invoice         | SAVE, save invoice                       |
| Table Column Headers        | Title Case            | Data labels for columns.         | Item Name, Unit Price, SKU   | Item name, ITEM NAME                     |
| Table Cell Values           | Sentence case / As-is | Displaying actual data.          | Pending, Paid                | PENDING                                  |
| Status Labels (Badges)      | Sentence case         | Short system-generated states.   | Draft, Partially delivered   | PARTIALLY DELIVERED                      |
| Helper Text                 | Sentence case         | Supporting guidance.             | This field is required       | This Field Is Required                   |
| Validation Errors           | Sentence case         | Human-readable errors.           | Enter a valid GST number     | Enter A Valid GST Number                 |
| Toast / Snackbar Messages   | Sentence case         | System feedback.                 | Invoice created successfully | INVOICE CREATED                          |
| Dialog Titles               | Title Case            | Modal or dialog headers.         | Delete Invoice               | Delete invoice                           |
| Dialog Body Text            | Sentence case         | Explanatory or warning text.     | This action cannot be undone | This Action Cannot Be Undone             |
| Empty State Messages        | Sentence case         | Informational text.              | No items found               | No Items Found                           |
| Tooltips                    | Sentence case         | Brief explanatory text.          | Click to refresh data        | Click To Refresh Data                    |

### Global Enforcement Rules

- **ALL CAPS is strictly prohibited** in UI text, except standard abbreviations (GST, SKU, ID).
- Case must never be used as a styling tool; use font weight or color instead.
- Mixed casing on the same screen is not allowed.
- User-entered data must be displayed exactly as entered.
- Any deviation requires explicit UX approval.

### PRD One-Line Principle

**Destinations use Title Case. Instructions use sentence case. Actions use Title Case. Data stays untouched.**

---

## 1.6 Data Casing Policy (UI Enforcement)

| Context                 | Uppercase Policy          | Rule                                                    |
| :---------------------- | :------------------------ | :------------------------------------------------------ |
| **Tables / Lists**      | ✅ Allowed (Display-only) | Optional for item names/categories to aid scanning.     |
| **Forms (Create/Edit)** | ❌ Strictly Prohibited    | Show text exactly as stored. No manual shift.           |
| **Detail Views**        | ⚠️ Limited                | Headlines only (Item/Customer name). Prefer Title Case. |
| **PDF / Printables**    | ❌ Prohibited             | Descriptive data must follow stored case.               |
| **Exports / API**       | ❌ Strictly Prohibited    | No transformation. Export as stored.                    |
| **Identifiers**         | ✅ Mandatory              | SKU, GSTIN, codes always forced to UPPERCASE.           |

### Visual Integrity Rules

- Never use full caps for Paragraphs, Addresses, or Notes.
- CSS/Flutter `text-transform: uppercase` must only be applied visually and must not mutate terminal input.
- **One-Line Principle:** Store what the user means. Style what the UI needs.

---

- **Sidebar Navigation (Left):** Dark theme (~`#2C3E50`), accordion pattern. Active item uses green accent (~`#22A95E`) with a lighter background block.
- **Main Canvas (Right):** Light theme (white cards on very light gray background).
- **Header (Top):** Minimal; document title, breadcrumbs, window controls (Close/Maximize).
- **Global Search:** Context-aware placeholder with keyboard shortcut hint (`/`).
- **Recent History:** Clock icon showing the last 5–10 visited records.
- **Form Alignment:** Left-aligned horizontal labels, fixed label column width, fluid input column.
- **Gutter:** Clear whitespace between label column and input column.
- **Sectioning:** Logical blocks separated by whitespace (avoid heavy borders).

---

## 3. Input Fields & Text Entry

- **Standard Inputs:** Rectangular, slight radius (3–4px), thin light-gray border (~`#E0E0E0`), height ~36px.
- **Focus State:** Blue/green border or glow.
- **Required Fields:** Red asterisk and label often red.
- **Text Areas:** Multi-line with resize handle; optional helper text (e.g., "Max 500 characters").
- **Compound Inputs:** Multi-field rows (e.g., [Salutation] [First Name] [Last Name]) with tight spacing.
- **Input Adornments:** Numeric fields with attached gray unit dropdowns on the right (e.g., kg, cm).
- **Numeric Input Rule:** Any field intended for numeric data (Quantity, Rate, Tax, Phone, HSN) must strictly block non-numeric characters (alphabets/special characters except decimals where applicable).

---

## 4. Dropdowns & Select Menus

- **Standard Select:** White box with right chevron; placeholder in light gray.
- **Searchable Select:** Input + dropdown; optional green lookup/search button on right.
- **Dropdown Content:** Grouped items; richer rows with status circle, primary line (name/code), secondary line (company/code).
- **Date Picker:** Field with calendar icon; dropdown with month/year header, arrows, 7-column grid, highlighted active date, "today" indicator.
- **Date Picker Implementation Rule:** Reuse `ZerpaiDatePicker` for business forms and dialogs wherever possible so calendar behavior stays consistent with Manual Journals and other accountant flows.

## 4.5 Global Settings Rules

- UI should prefer real DB-backed runtime data wherever a schema-backed source already exists.
- Empty and error states must remain explicit; do not silently substitute fabricated business values.
- Defaults for master-driven fields should come from DB-backed master rows rather than hardcoded IDs or display strings.
- Reusable ERP controls and centralized style sources should be extended instead of replaced with screen-local variants.
- Shared responsive Flutter primitives must be used for web adaptability: global breakpoints, responsive table shells, responsive form rows/grids, responsive dialog width rules, and sidebar-aware content-width handling.
- New modules and major internal sub-screens must be deep-linkable through GoRouter so refresh, browser navigation, and direct URLs preserve the current working page and state context.
- Warehouse master data, storage/location master data, accounting stock, and physical stock must remain distinct in UI behavior and copy.
- Shared environments should be updated with additive migrations and scoped upserts instead of destructive resets.

## 4.6 Button, Border, And Upload Styling Rules

- **Primary Save/Create/Confirm Buttons:** Use the approved primary/success button styling from the design system. Do not invent per-screen greens or blues for save-like actions.
- **Cancel/Secondary Buttons:** Use the shared neutral secondary button style. They must remain visually subordinate to the primary action.
- **New/Add Buttons:** Use the approved add/create action treatment already established by the module/theme instead of ad hoc button colors.
- **Upload/Image Select Controls:** Use the shared upload affordance style with approved border, text, and hover/focus behavior. Do not restyle upload cards or image selectors per screen.
- **Borders And Dividers:** Use the light approved border tokens for inputs, cards, tables, separators, and section dividers. Avoid darker local border guesses.
- **Field Borders:** Default border, focused border, error border, and disabled border must come from centralized theme/input styling, not widget-local hardcoded colors.

---

## 5. Tabular Input (Item Table)

- **Headers:** Uppercase, bold, small font (ITEM DETAILS, QUANTITY, RATE, TAX, AMOUNT).
- **Hardware Integration:** “Scan Item” button with barcode icon above table headers.
- **Context Filters:** Table-level selectors (e.g., Warehouse, Price List) between section header and grid.
- **Rows:** Empty-state row shows placeholder image + text ("Type or click to select an item.").
- **Inline Editing:** Text appears static until clicked.
- **Numeric Columns:** Right-aligned.
- **Row Actions:** On hover, show red delete (x) and drag handle at far right.
- **Bulk Action:** "Add items in Bulk" below table.

---

## 6. Tabs & Internal Navigation

- **Horizontal Tabs:** Text-only; selected state uses blue text + blue underline; default state is gray.
- **View Switcher Dropdown:** "All [Module]" dropdown with favorite star; list items show blue link styling.

---

## 7. Buttons & Actions

- **Primary Action:** Green (~`#22A95E` to `#28A745`), white text, rounded corners.
- **Split Button:** Primary action with dropdown for alternatives (e.g., Save & Send).
- **Secondary Action:** Neutral/gray or outline; cancel is link/ghost.
- **Utility Icons:** Small gear/settings icons beside specific fields (outlined blue/gray).

---

## 8. Feedback & Status Indicators

- **Info Icons:** Small "i" inside a circle; hover shows tooltip.
- **Inline Hints:** Gray helper text inside/below fields.
- **Status Tags (List View):** Colored text (no pill). APPROVED=Blue, RECEIVED=Green.
- **Validation:** Red input border + red error text below.

---

## 8.1 Zoho Visual Language Tokens (Mandatory)

- **Page Background:** Pure white `#FFFFFF`.
- **Input Fill:** `#FFFFFF` (pure white, matching page background).
- **Input Border:** `#E0E0E0` (light gray).
- **Table Header Background:** `#F5F5F5`.
- **Primary Blue:** `#0088FF` (checkboxes, selected cards, active borders).
- **Required Asterisk:** `#D32F2F`.

---

## 8.2 Form Field Specification (Greyed Boxes)

- **Label Column:** Fixed width ~160px, left-aligned, text color `#444444`.
- **Input Decoration (Flutter):**

```dart
InputDecoration(
  filled: true,
  fillColor: Color(0xFFFFFFFF),
  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
    borderRadius: BorderRadius.circular(4),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFF0088FF), width: 1.5),
    borderRadius: BorderRadius.circular(4),
  ),
)
```

---

## 8.3 Zoho UI/UX Spec Addendum (STRICT COMPLIANCE)

**Global Design Tokens**

| Element                 | Specification   | HEX / Value |
| :---------------------- | :-------------- | :---------- |
| Page Background         | Pure White      | `#FFFFFF`   |
| Input Fill Color        | Pure White      | `#FFFFFF`   |
| Border Color (Default)  | Light Grey      | `#E0E0E0`   |
| Border Color (Active)   | Zoho Blue       | `#0088FF`   |
| Primary Brand Color     | Zoho Blue       | `#0088FF`   |
| Success / Save Button   | Green           | `#28A745`   |
| Required Field Label    | Dark Red        | `#D32F2F`   |
| Primary Text Color      | Dark Charcoal   | `#444444`   |
| Secondary/Helper Text   | Medium Grey     | `#666666`   |
| Table Header Background | Light Tint Grey | `#F5F5F5`   |
| Border Radius           | Standard Radius | `4px`       |

**Layout & Spacing**

- **Form Label Width:** 160px fixed.
- **Row Spacing:** 20px between form rows.
- **Table Cell Padding:** 8px vertical / 12px horizontal.
- **Page Margins:** 24px padding on main scaffold area.
- **Field Max Width:** 400px for Percentage / Round Off / Currency fields.

**Component Specs**

- **White Box Input:** `filled: true`, `#FFFFFF` fill, `#E0E0E0` border, `#0088FF` focus at 1.5px.
- **Prefix/Suffix:** Currency symbols (₹, $) as `prefixText` inside the grey box; numbers right-aligned.
- **Selection Cards:** Selected = `#F0F7FF` bg, `#0088FF` border, blue check icon. Inactive = `#F9F9F9` bg, `#E0E0E0` border.
- **Dropdown Overlay:** Elevation 8 (shadow ~`rgba(0,0,0,0.15)`), selected row `#0088FF` with white text, check icon on far right.
- **Dropdown Search:** Only for Currency/Item dropdowns; disabled for Markup/Markdown and Round Off.

**Dynamic Table Logic (Price List)**

- **Unit Pricing Columns:** ITEM DETAILS | SALES/PURCHASE RATE | CUSTOM RATE.
- **Volume Pricing Columns:** ITEM DETAILS | SALES/PURCHASE RATE | START QTY | END QTY | CUSTOM RATE.
- **Ranges:** Stack within a single item row; “+ Add New Range” aligns left of quantity columns.
- **Alignment:** Item details left; rates/quantities right-aligned (`TextAlign.right`).

**Visibility Matrix**

| Component           | All Items | Individual Items |
| :------------------ | :-------- | :--------------- |
| Description         | Visible   | Visible          |
| Percentage (Markup) | Visible   | Hidden           |
| Round Off To        | Visible   | Hidden           |
| Currency Selection  | Visible   | Visible          |
| Items Data Table    | Hidden    | Visible          |
| Discount Checkbox   | Hidden    | Visible          |

**Interactive Behaviors**

- **Bulk Update Modal:** Horizontal row (Dropdown + Dropdown + “by” + Input + Dropdown). Footer buttons right-aligned (Update green, Cancel neutral).
- **Discount Helper Text:** Visible only if discount checkbox is true; blue, 12px, italic, directly below checkbox label.
- **Round Off Popover:** “View Examples” opens floating card with arrow and static examples table.
- **Currency Dropdown:** Searchable; selection updates all currency prefix texts in the table.

**Typography**

- **Primary Font:** Inter or Roboto.
- **Main Labels:** 14px, w500.
- **Table Body:** 13px, normal.
- **Table Headers:** 12px, bold, ALL CAPS.
- **Helper Text:** 12px, regular.

**Backend Payload (Next.js)**

- **Unit Pricing:** Single `custom_rate` number.
- **Volume Pricing:** `ranges[]` array with `{ start, end, rate }`.

---

## 8.4 Dropdown Menu Zero-Tolerance Rules (STRICT)

**Box Rule (Width & Alignment)**

- **Max Width:** `400px` for dropdown overlays.
- **Alignment:** Left edge aligns to the input field’s left edge (no full-width stretch).

**Color & Border Reset**

- **Background:** `#FFFFFF` only.
- **Selected Bar:** `#0088FF` with white checkmark on far right.
- **Hover:** `#F5F5F5`.
- **Border:** 1px solid `#E0E0E0` around menu, subtle shadow (elevation ~4).
- **No inherited tint:** Dialogs, popup menus, date pickers, dropdown overlays, and floating surfaces must set an explicit pure white background instead of inheriting tinted Material surfaces.

**Vertical Density**

- **Row Height:** 36–40px per item.
- **Padding:** `EdgeInsets.symmetric(horizontal: 12, vertical: 0)`.

**Layout Stability**

- **Label Width Lock:** Left labels (e.g., “Round Off To”, “Currency”) stay fixed at 160px and must not shift when menus open.

---

## 9. Advanced Form Controls & Input Patterns

### 9.1 Input Adornments (Suffixes & Prefixes)

- **Right-addon dropdowns** for units (e.g., cm, kg) attached directly to the input.
- Treat value + unit as a single input group block.

### 9.2 Rich Radio Buttons (With Descriptions)

- Vertical layout.
- Label + muted grey description under the label (microcopy).

### 9.3 Inline Configuration (Gear Icon)

- Small blue gear icon inside or next to inputs.
- Opens quick configuration modal (e.g., invoice numbering, tax preference).

### 9.4 Drag-and-Drop Uploader

- Large dashed border zone with constraints listed (max images, size, resolution).
- Dual-action guidance: "Drag image(s)" and "Browse images."

---

## 10. Global Navigation & Utility Bar

- **Quick Create (+):** Top-right and sidebar (+) allow create from anywhere.
- **Recent Items (Clock):** Opens last 5–10 visited records.
- **Contextual Search:** Placeholder changes by module (e.g., "Search in Invoices ( / )").
- **Shortcut Hint:** "/" to focus search.

---

## 11. Date Picker Specifics

- **Today:** Solid red/orange highlight.
- **Weekend Labels:** Sat/Sun in red.
- **Month/Year Header:** Clickable to switch to year view.

---

## 12. Alert & Feedback Systems

- **Info Banners (Blue Box):** Light blue bar with dark blue info icon; includes actionable link (e.g., "Prefill").
- **Contextual Empty States:** Ghost text + subtle CTA (e.g., "Add items to this picklist").

---

## 13. Table Functionality & Context

- **Barcode Scanner Button:** Above item tables; implies hardware/camera integration.
- **Contextual Dropdowns:** Warehouse/Price List selectors placed between header and table; apply to all rows.

---

## 14. Support & Onboarding Elements

- **Live Guided Onboarding Toggle:** In sidebar footer.
- **Smart Chat Bar:** Bottom footer bar with command/AI entry (Ctrl+Space).
- **Floating Help Widget:** Bottom-right support button.

---

## 15. List View "View Manager"

- **Custom Views:** "All [Module]" dropdown supports create/edit views.
- **Pin/Favorite:** Star icons to pin views to top.

---

## 16. Right Utility Bar (Collapsible Sidebar)

- **Right Utility Bar:** Fixed-position vertical icon strip at far right with a light-gray divider.
- **Icons:** Help (?), Updates (megaphone), Feedback (chat), App Switcher (grid), User Avatar.
- **Behavior:** Clicking an icon opens a right-side slide-out panel (overlay, no page navigation).

---

## 17. Swap Interaction (Transfer Order)

- **Swap Control:** Circular two-arrow icon between Source/Destination warehouse fields.
- **Behavior:** Clicking swaps the values of the two dropdowns.
- **Placement:** Sits in the gutter between columns to imply it affects both fields.

---

## 18. Inside-Input Actions (Config Gear)

- **Embedded Gear:** Gear icon appears **inside** the input on the right edge (auto-number fields).
- **Meaning:** Field is auto-generated; gear opens configuration (prefix/sequence), not manual input.

---

## 19. Advanced Table Row Actions (Kebab Menu)

- **Row Actions:** Red delete (x), drag handle, and vertical ellipsis (⋮) for advanced options.
- **Menu Options:** Clone row, add description row, show additional fields (discount, serial, etc.).

---

## 20. Breadcrumb & Back Navigation

- **Header Pattern:** Module Icon → Back Arrow → Page Title.
- **Behavior:** Back arrow returns to the list view (one-click up).

---

## 21. Dropdown Visual Hierarchy (Rich List)

- **Active Row:** Blue background (~`#408DFB`) with white text.
- **Scrollbar:** Slim floating scrollbar (webkit-style).
- **Row Layout:** Primary line (bold/normal) + secondary line (smaller/gray).

---

## 22. Placeholder Date Formatting

- **Format Hint:** Empty date fields show `dd-MM-yyyy` as placeholder.

---

## 23. Currency Prefix Alignment

- **Prefix:** Currency symbol (₹/INR) outside the input or non-editable prefix.
- **Alignment:** Totals column aligns currency symbols vertically for clean numeric columns.

---

## 24. Checkbox Grouping (Progressive Disclosure)

- **Checkbox Style:** Standard square checkbox with label to the right.
- **Behavior:** Certain checkboxes appear only when relevant (indented, progressive disclosure).

---

## 25. Link Styling in List Views

- **Primary Identifier:** Blue link (e.g., Order # / RMA #) navigates to document.
- **Secondary Data:** Black/gray text; may be non-clickable or filter-only.
- **Sort Indicators:** Column headers show up/down arrows on hover/active.

---

## 26. Draft vs Live Status Visuals

- **Save as Draft:** Neutral/gray (low urgency).
- **Save and Send:** Green (high urgency).
- **Cancel:** Text-only, no background (escape hatch).

---

## 27. Organization Switcher (Tenant Selector)

- **Location:** Top-right header near the primary “New (+)” action.
- **Design:** Dropdown text link showing current org.
- **Behavior:** Switches organizations without logout.

---

## 28. Master Checkbox (Bulk Selection)

- **Header Checkbox:** Far-left of table header.
- **Logic:** Unchecked = none, checked = all visible rows, indeterminate (dash) = partial selection.

---

## 29. Sidebar Hamburger Toggle

- **Location:** Top-left near logo.
- **Behavior:** Collapses sidebar to icon-only mini mode.

---

## 30. Semantic Status Colors (Text-Only)

- **Approved/Open:** Blue text.
- **Received/Closed:** Green text.
- **Draft/Void:** Black/gray text.

---

## 31. Round Off Logic (Footer Calculation)

- **Row Placement:** Between Subtotal and Total.
- **Behavior:** Auto-calculates rounding difference; optionally editable.

---

## 32. Reference # vs Order Number

- **Order Number:** Auto-generated; gear/config, typically non-editable.
- **Reference #:** User-entered customer PO/reference field.

---

## 33. Attachment Module

- **Section:** “Attach File(s) to Transfer Order” (or equivalent).
- **Controls:** Upload button with cloud/arrow icon; dropdown source selector.
- **Constraints:** Microcopy shows limits (e.g., max 5 files, 10MB each).

---

## 34. Currency & Locale Indicators

- **Currency Code:** INR where applicable.
- **Formatting:** Two decimals (0.00) and right-aligned numeric columns with aligned decimals.

---

## 35. Guided Action Links (Empty States)

- **Empty State CTA:** Instructional text + single action button (e.g., “Add Items”).
- **Behavior:** Guides users to the next required step.

---

## 36. Active Tab Sidebar Indicator

- **Visual:** Vertical green bar on far left of active item.
- **Purpose:** Clear active state via position + color.

---

## 37. Mandatory Label Styling

- **Rule:** Entire label text turns red for required fields (not just asterisk).

---

## 38. Terms Dropdown Logic

- **Behavior:** Selecting terms auto-updates Due Date.
- **Type:** Trigger input (changes dependent fields).

---

## 39. PDF Template Switcher (Footer)

- **Location:** Bottom-right footer of creation forms (e.g., Retainer Invoice, Delivery Challan).
- **Design:** “PDF Template: Standard Template” with a Change action.
- **Behavior:** Pre-save print configuration (template selection before saving).

---

## 40. Just-in-Time Stock Visibility

- **Location:** Under item table in Transfer Order.
- **Design:** “CURRENT AVAILABILITY” with Source Stock / Destination Stock.
- **Behavior:** Real-time population based on selected items.

---

## 41. HSN Lookup (External Search)

- **Location:** Item creation → HSN Code field.
- **Design:** Blue magnifying-glass icon distinct from dropdown chevron.
- **Behavior:** Opens modal/global lookup (external GST/HSN database).

---

## 42. Rich-Content Dropdowns (Card List)

- **Location:** Package / Sales Order selection dropdowns.
- **Design:** Micro-card items with left badge, blue primary line, gray secondary line.
- **Purpose:** Disambiguate similar IDs quickly.

---

## 43. Progressive Disclosure (Toggle Checkboxes)

- **Location:** Item creation → Sellable / Purchasable.
- **Behavior:** Toggles visibility of Sales/Purchase info blocks.

---

## 44. Dynamic Primary Button Text

- **Behavior:** Primary CTA text changes by module context (e.g., “Save and Send”, “Generate picklist”).

---

## 45. Inventory Tracking Shortcut

- **Location:** Sales Order footer (right).
- **Design:** Small blue link with box icon (“Inventory Tracking”).
- **Behavior:** Cross-module quick view of stock history/availability.

---

## 46. GST/Tax Trigger Fields

- **GST Treatment:** Controls GSTIN visibility/required state.
- **Place of Supply:** Auto-populates from address, allows override.

---

---

## 48. Global Pagination System (MANDATORY)

- **Requirement:** Every data table and list view must implement a footer-based pagination system.
- **Default State:** Load `100` rows by default.
- **Visual Components (Horizontal Footer Bar):**
  - **Total Count (Left):** "Total Count: View" (Blue link-style text). Clicking "View" triggers the total record count calculation.
  - **Page Size Selector (Right):** A button/dropdown displaying "[gear icon] X per page".
  - **Selector Options:** Must include `10, 25, 50, 100, 200` as options with a search bar and checkmarks for the active selection.
  - **Navigation Controls (Far Right):**
    - Numeric range: `1 - 100` (or appropriate range).
    - Arrows: Previous (`<`) and Next (`>`) arrows for page switching.
- **Micro-interactions:**
  - Hovering over arrows or the rows selector should show a subtle light-gray background highlight.
  - Page transitions must show a centralized loading indicator if data retrieval takes >200ms.
  - **Background Loading:** The next page’s data must be queued for background loading immediately after the current page is rendered to facilitate near-instant navigation.
