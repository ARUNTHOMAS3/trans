# Table And Form Patterns

## Forms

- Use left-aligned horizontal labels with a fixed label column around 160px.
- Keep a clear gutter between labels and input controls.
- Required labels should visually indicate required status, typically including a red asterisk.
- Numeric fields such as quantity, rate, tax, HSN, and phone should block invalid non-numeric entry.
- Empty date fields should hint `dd-MM-yyyy`.

## Dropdowns

- Standard dropdown overlays should stay compact, left-aligned to the field, and not stretch full width.
- Searchable dropdowns are appropriate for currencies and item-like lookups.
- Use richer dropdown rows when the user must disambiguate similar records.

## Item Tables

- Keep item details left-aligned and numeric columns right-aligned.
- Support table-level contextual selectors such as warehouse or price list where the PRD calls for them.
- Support row actions such as delete, drag, and advanced actions when relevant.

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
