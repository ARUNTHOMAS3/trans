# Table And Form Patterns

## Forms

- Use left-aligned horizontal labels with a fixed label column around 160px.
- Keep a clear gutter between labels and input controls.
- Required labels should visually indicate required status, typically including a red asterisk.
- Numeric fields such as quantity, rate, tax, HSN, and phone should block invalid non-numeric entry.
- Empty date fields should hint `dd-MM-yyyy`.
- Standard ERP date fields should use `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` wherever the shared anchored picker pattern is viable.
- Primary submit/save buttons should use the shared primary/success styling, while cancel/secondary actions should use the shared neutral secondary styling.
- Upload/image controls and dashed/bordered selection surfaces should follow the shared upload treatment instead of per-screen restyling.

## Dropdowns

- Standard dropdown overlays should stay compact, left-aligned to the field, and not stretch full width.
- Standard dropdown overlays, popup menus, and floating selectors must use a pure white `#FFFFFF` surface.
- Searchable dropdowns are appropriate for currencies and item-like lookups.
- Use richer dropdown rows when the user must disambiguate similar records.

## Item Tables

- Keep item details left-aligned and numeric columns right-aligned.
- Support table-level contextual selectors such as warehouse or price list where the PRD calls for them.
- Support row actions such as delete, drag, and advanced actions when relevant.
- Dense or wide tables must use the shared responsive table shell so the table preserves usable minimum widths and falls back to horizontal scrolling instead of compressing headers and inputs into overflow-prone layouts.

## Pagination

- Every list or data table must paginate on the server.
- Default page size is 100.
- Offer 10, 25, 50, 100, and 200 in the page-size selector.
- Show range controls and previous and next navigation.
- Queue the next page in the background after the current page renders when feasible.

## Feedback

- Validation errors use red border plus red helper text.
- Loading states should appear centrally if page transitions exceed roughly 200ms.
- Empty states should guide the next action with one clear CTA.
- Dialogs, popovers, and calendars must use explicit pure white surfaces rather than inherited tinted theme surfaces.
- Avoid adding fresh raw `showDatePicker(...)` usage for ordinary form/dialog date entry unless the shared picker cannot satisfy the requirement.
- Keep empty states and error states distinct; do not silently convert backend failures into misleading empty business data.
- Master-driven defaults should resolve from DB-backed lookup rows where schema-backed masters exist instead of hardcoded IDs or visible labels.
- Keep borders, dividers, and control outlines on approved shared border colors so form/table styling does not drift per screen.
- Dialogs and form-heavy popovers should use the shared responsive dialog and responsive form row/grid primitives so width, label alignment, and wrap behavior stay consistent across screen sizes.
