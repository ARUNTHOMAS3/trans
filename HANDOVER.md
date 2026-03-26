# Handover — Branches Create Page (settings_branches_create_page.dart)
_Last updated: March 26, 2026_

---

## Project Context

**Zerpai ERP** — Flutter (Web + Android) + NestJS backend. Read `CLAUDE.md` fully before touching anything. Key rules: Riverpod only, Dio only, GoRouter only, AppTheme tokens only, no hardcoded colors, `FormDropdown<T>` for all dropdowns, `ZTooltip` for tooltips, `ZerpaiDatePicker` for dates. Check `REUSABLES.md` before creating any new shared widget.

---

## File Being Worked On

`lib/core/pages/settings_branches_create_page.dart`

This is the Branches Create/Edit page under **Settings → Branches**. It is a single-page form (not a dialog itself) that creates or edits a branch. Route: `/settings/branches/create`.

---

## What Was Completed This Session

### 1. Main Form Layout
- ✅ Background: `Colors.white` (was `AppTheme.bgLight`)
- ✅ Form is left-aligned: `Align(alignment: Alignment.topLeft) + SizedBox(width: 620)` inside `SingleChildScrollView` — NOT `Center` or `ConstrainedBox` (those don't work inside SingleChildScrollView due to tight constraints)
- ✅ All `kZerpaiFormDivider` lines removed from main form body
- ✅ Main form card: plain `Container(color: Colors.white)` — no border, no radius
- ✅ **Sticky bottom bar**: `Form → Column → [Expanded(SingleChildScrollView(form content)), Container(sticky bar)]`
- ✅ Bottom bar: Save (green ElevatedButton) + Cancel (OutlinedButton), `MainAxisAlignment.start`

### 2. GST Details Dialog (`_showGstinDialog()`)
- ✅ **Style matches Chart of Accounts "Create Account" modal** exactly:
  - `Dialog(alignment: Alignment.topCenter, insetPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 20))`
  - `borderRadius: BorderRadius.circular(8)`
  - Header: `Container` with `border: Border(bottom: BorderSide(color: AppTheme.borderColor))`, title `fontSize: 18, fontWeight: bold`, X icon `size: 20, color: AppTheme.errorRed`
  - Footer: `Container` with `border: Border(top: BorderSide(color: AppTheme.borderColor))`, Save (green, padding 24×12) + Cancel (`bgDisabled` ElevatedButton with `borderColor` side)
  - No inner bordered card — form rows sit directly in `padding: horizontal: space24, vertical: space16`
- ✅ **"Get Taxpayer details" link** wired to `fetchTaxpayer()` (was a stub toast)
- ✅ **Auto-fetch on 15 chars**: `onChanged` of GSTIN field calls `fetchTaxpayer()` when `v.length == 15`
- ✅ **Loading state**: link shows `CircularProgressIndicator` + "Fetching..." while `isFetchingTaxpayer` is true
- ✅ **`isFetchingTaxpayer` declared outside the `StatefulBuilder` builder lambda** so it persists across rebuilds (inside builder = resets to false every rebuild)
- ✅ **Form auto-fill on success**: fills `legalName`, `tradeName`, `registrationType`, `registeredOn` from API response
- ✅ **Taxpayer Info Dialog**: shown after successful fetch
  - `alignment: Alignment.topCenter, insetPadding: EdgeInsets.zero`
  - Width 460, `ConstrainedBox(maxHeight: 80% screen)`
  - Shows: GSTIN, Company Name, Date of Registration, GSTIN/UIN Status, Taxpayer Type (mapped), State Jurisdiction, Constitution of Business, Business Trade Name
  - Close button (green ElevatedButton)
- ✅ `_tdRow(String label, String value)` added as a state class method (not local function — needed because it's called from a nested closure inside `fetchTaxpayer`)

### 3. Backend GST API (already existed, no changes needed)
- `backend/src/modules/gst/gst.controller.ts` — `GET /gst/taxpayer-details?gstin=`
- `backend/src/modules/gst/gst.service.ts` — calls Sandbox API, returns `{gstin, legalName, tradeName, registrationType, registeredOn (dd-MM-yyyy), status, constitutionOfBusiness, stateJurisdiction}`
- Registration type mapping: `Regular→registered_regular`, `Composition→composition`, `ISD→isd`, `SEZ Developer/Unit→sez`, `Non-Resident→overseas`

---

## What Still Needs Doing

### A. Taxpayer Info Dialog — Additional Fields (Low priority, visual polish)
The Zoho reference screenshot showed these fields that our API doesn't currently return:
- **Centre Jurisdiction** — not in Sandbox API response (skip or show "—")
- **e-Invoicing Applicability** — not in Sandbox API response (skip)
- **"View Return Details"** expandable section — Zoho shows a collapsible section; ours doesn't have this. Could add a placeholder or skip.

The current implementation shows all available API fields. If the user wants the Zoho-exact layout, you'd need to extend the Sandbox API response OR show those fields as "—".

### B. Verify Taxpayer Info Dialog Context
The taxpayer info dialog's close button uses `Navigator.pop(tCtx)` where `tCtx` is the inner dialog builder context. This should work correctly but has not been visually verified end-to-end. Confirm it closes only the inner taxpayer-info dialog (not the parent GST dialog).

### C. GST Dialog — `kZerpaiFormDivider` still present inside it
The GST dialog body still uses `kZerpaiFormDivider` between form rows. The main form had these removed, but the dialog's own rows still have dividers. This is intentional (dividers look fine in dialogs) — but if the user wants them removed to match the clean style, remove the `kZerpaiFormDivider` lines between each `ZerpaiFormRow` in `_showGstinDialog`.

### D. `GstinPrefillBanner` / `LicenceValidationMixin`
Check `REUSABLES.md` — there is a `GstinPrefillBanner` widget catalogued. If a GSTIN prefill banner should appear on the main form after a successful lookup, that reusable already exists.

---

## Key Technical Notes

### Widget Structure (main form `_buildBody`)
```
Form(key: _formKey)
  └── Column(crossAxisAlignment: start)
        ├── Expanded
        │     └── SingleChildScrollView(padding: all(space32))
        │           └── Align(topLeft)
        │                 └── SizedBox(width: 620)
        │                       └── Column(crossAxisAlignment: start)
        │                             ├── Text (page title)
        │                             ├── Container(color: white) ← main form card
        │                             │     └── Column(rows...)
        │                             └── ZerpaiFormRow (Location access)
        └── Container(sticky bar) ← Save / Cancel buttons
```

### `StatefulBuilder` State Variable Rule
State variables inside `showDialog`'s `StatefulBuilder` MUST be declared **outside** the builder function (but inside the `showDialog` caller function). If declared inside the builder, they reset to initial value on every `setS(...)` call.

```dart
// CORRECT
bool isFetchingTaxpayer = false; // ← outside builder
showDialog(builder: (ctx) => StatefulBuilder(
  builder: (ctx, setS) {
    // use isFetchingTaxpayer here
  }
));
```

### Local Function Forward-Reference Issue in Dart
Local functions in Dart cannot be forward-referenced within the same scope. If `fetchTaxpayer` uses `_tdRow`, `_tdRow` must be declared BEFORE `fetchTaxpayer` — OR (preferred) promote `_tdRow` to a state class method.

### `ConstrainedBox` vs `Align+SizedBox` in `SingleChildScrollView`
`ConstrainedBox(maxWidth: 620)` does NOT work inside `SingleChildScrollView` because SSV passes tight width constraints that `ConstrainedBox` cannot override. Use `Align(topLeft) + SizedBox(width: 620)` instead — `Align` breaks the tight constraint.

---

## Important Shared Widgets to Know
| Widget | Location | Notes |
|--------|----------|-------|
| `FormDropdown<T>` | `lib/shared/widgets/inputs/dropdown_input.dart` | All dropdowns — includes built-in search |
| `ZerpaiDatePicker` | `lib/shared/widgets/inputs/zerpai_date_picker.dart` | Anchored date picker |
| `ZTooltip` | `lib/shared/widgets/inputs/z_tooltip.dart` | Always use instead of Flutter Tooltip |
| `ZerpaiFormRow` | shared widgets | Label-left + field-right 2-column form row |
| `kZerpaiFormDivider` | shared | Thin divider between form rows |
| `ZerpaiToast` | `lib/shared/utils/zerpai_toast.dart` | `.info`, `.success`, `.error` only — no `.warning` |
| `appBrandingProvider` | providers | `.accentColor` for primary green tint |

---

## API Client Usage
```dart
final res = await _apiClient.get(
  'gst/taxpayer-details',
  queryParameters: {'gstin': gstin},
);
final d = res.data as Map<String, dynamic>;
```
`_apiClient` is a `Dio`-based client injected via Riverpod. Backend dev runs on port 3001. Prod: `https://zabnix-backend.vercel.app`.

---

## Reference Modals for Style Matching
- **Chart of Accounts → Create Account** (`lib/modules/accountant/presentation/accountant_chart_of_accounts_creation.dart` lines 610–1422) — the canonical Zerpai modal style. GST dialog now matches this exactly.
- Key style: `Alignment.topCenter`, `borderRadius: 8`, red X, bold 18px title, `borderColor` dividers, Save green + Cancel `bgDisabled`.
