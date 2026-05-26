# Zerpai Current Structure (Runtime + Canonical Guardrails)
**Updated:** 2026-05-24
**Scope:** Live repo snapshot + enforced placement/merge rules

## 1) Runtime Roots (Current)

```txt
E:/zerpai-new/
├── lib/
├── backend/
├── docs/
├── PRD/
├── design-system-audit/
├── repowiki/
├── test/
├── tests/
├── assets/
├── web/
├── windows/
├── scripts/
├── supabase/
├── backups/
└── archive/
```

## 2) Frontend Canonical Roots (Mandatory)

```txt
lib/
├── app/
├── bootstrap/
├── config/
├── core/
├── shared/
├── engines/
├── modules/
├── generated/
└── main.dart
```

## 3) Frontend Module Runtime Map (Current)

```txt
lib/modules/
├── home/
├── items/
├── pricelists/
├── inventory/
├── sales/
├── purchases/
├── accountant/
├── accounts/
├── reports/
├── documents/
├── settings/
├── branches/        # transitional; target: settings/organization/branches
├── mapping/         # transitional; target: items/item_mapping
├── printing/        # infra module (not business owner)
└── shared/          # module-shared transitional; avoid new business logic here
```

## 4) Backend Runtime Map (Current)

```txt
backend/src/
├── app.module.ts
├── common/
├── config/
├── database/
├── db/
├── health/
├── lookups/
├── modules/
└── sequences/
```

`backend/src/modules/` currently contains mixed canonical + transitional domains (not fully mirrored yet).

## 5) Canonical Ownership Rules (Strict)

1. Business code MUST live under `lib/modules/<domain>/...`.
2. App infrastructure MUST live under `lib/core/...` or `lib/app/...`.
3. Reusable cross-domain UI MUST live under `lib/shared/widgets/...`.
4. Cross-domain reusable services MUST live under `lib/shared/services/...`.
5. `core/` MUST NOT import business modules.
6. New business routes MUST be module-owned and composed centrally.
7. No new monolith route/provider files.
8. No new top-level legacy domains (example: do not add new `lib/modules/<legacy_domain>` outside canonical plan).

## 6) File/Folder Creation Rules (Strict)

1. Before creating any file/folder, verify owner domain and target path.
2. New module subfolders should prefer:
   - `data/models|repositories|datasource|dto`
   - `presentation/pages|dialogs|sections|tables|forms|state`
   - `providers`, `config`, `routes`, `shared` (module local)
3. Naming MUST be snake_case and owner-specific.
4. Do not create generic sink files (`new.dart`, `temp.dart`, ambiguous `helpers.dart`).
5. If reusable candidate created, update `REUSABLES.md` same batch.

## 7) Incoming Handoff Merge Protocol (Strict)

For every inbound handoff bundle:

1. Create timestamped backup under `backups/refactor-batches/<timestamp>-<scope>/`.
2. Stage merge in compatibility mode first:
   - move/rewire
   - add shim exports where needed
   - avoid destructive deletions
3. Validate import graph before deleting/moving old owners.
4. Mandatory verification per batch:
   - frontend: `dart analyze` touched files
   - backend: `npm.cmd run build` in `backend/` when backend touched
5. Update `log.md` with:
   - files moved
   - shims added/removed
   - verification commands/results
   - risks/remaining follow-up
6. Do not delete `handoff_backups`/inbound backup folders until explicit sign-off.
7. Any ownership conflict between local and handoff code must be resolved with a written decision note in `log.md`.

## 8) Merge Safety Gates (Blockers)

Do NOT merge inbound changes when any of these fail:

- analyzer/build fails in touched scope
- route ownership ambiguity remains
- DB/DTO mismatch against `current schema.md`
- breaking change without shim for active imports

## 9) Reference Docs

- `structure folder refactoring plan.md`
- `PRD/prd_folder_structure.md`
- `07_INBOUND_MERGE_MEMORY.md`
- `AGENTS.md`
- `current schema.md`
- `REUSABLES.md`
