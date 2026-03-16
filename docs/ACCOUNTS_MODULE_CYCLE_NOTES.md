# Accounts Module - Current Cycle Notes

## Delivered in this cycle
- Chart of Accounts stabilization (existing implementation retained).
- Manual Journals end-to-end contract updates:
  - `GET /api/v1/accounts/manual-journals`
  - `GET /api/v1/accounts/manual-journals/:id`
  - `POST /api/v1/accounts/manual-journals`
  - `PUT /api/v1/accounts/manual-journals/:id`
  - `DELETE /api/v1/accounts/manual-journals/:id`
  - `PUT /api/v1/accounts/manual-journals/:id/status`
  - `GET /api/v1/accounts/journal-number-settings`
  - `GET /api/v1/accounts/journal-settings` (compat alias)
- Manual Journals UI updates:
  - List + split detail panel.
  - Create/edit screen with balanced-entry validation.
  - Detail actions for edit, post, cancel, delete (draft-only).

## Status contract
- API status contract used by frontend: `draft`, `posted`, `cancelled`.
- Backend normalizes compatibility values from DB (`published`, `void_status`) to API contract.

## Deferred (visible but locked)
- Recurring Journals
- Bulk Update
- Transaction Locking
- Opening Balances
- Accounts Settings (advanced)

## Notes
- Current local environment can return `500` for Accounts endpoints when backing data/permissions are missing.
- Route mapping confirms static accounts subroutes are registered ahead of dynamic `:id` routes.
