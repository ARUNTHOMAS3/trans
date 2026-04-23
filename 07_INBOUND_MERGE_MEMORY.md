# Inbound Merge Memory (Codev -> Local)

This file is the persistent reminder/checklist for when codev sends files later.

## Goal
Integrate codev’s April 22, 2026 changes into this repo without regressing current Purchase Receives stability.

## Merge Order (when files arrive)

1. Compare codev `LOG_ENTRIES_2026-04-22.md` with local root `log.md`.
2. Review `FILES_CHANGED.md` from codev and map overlaps with local edits.
3. Merge backend first:
   - DTOs
   - controllers
   - services
   - module wiring
4. Merge frontend second:
   - models
   - repositories/providers
   - screens
   - route/constants
5. Run validations:
   - `npm.cmd run build` in `backend/`
   - `flutter analyze` on touched frontend files
6. Manual smoke checks:
   - Purchase Receive create flow
   - vendor-scoped PO dropdown
   - warehouse resolution/fallback
   - next number generation
   - post-save redirect
7. Update root `log.md` with integration entry.

## High-Risk Areas to Guard

- Tenant scope regressions (`entity_id` handling)
- DTO whitelist breaks (extra payload fields)
- Purchase order vendor filter removal
- Next-number endpoint/response shape drift
- SnackBar reintroduction (must keep `ZerpaiToast`)

## Conflict Strategy

- Prefer behavior proven in latest local logs unless codev fix is clearly newer and verified.
- Never drop paths/fields without checking both create payload and backend DTO.
- If both sides changed same file, keep a short “decision note” in root `log.md`.

