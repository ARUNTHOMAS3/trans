# Contributing to ZERPAI ERP

This repository uses enterprise governance for a multi-team ERP codebase. Follow this guide for all contributions.

## Branching
- Create feature branches from `dev`.
- Allowed prefixes: `feature/*`, `fix/*`, `bugfix/*`, `perf/*`, `hotfix/*`, `docs/*`.
- Never push directly to `main`.

## Required Reading
- `AGENTS.md`
- `current schema.md` (authoritative DB schema source of truth)
- `PRD/PRD.md`
- `PRD/prd_schema.md`
- `REUSABLES.md`
- `ARCHITECTURE_GUARDRAILS.md`
- `DATABASE_CHANGE_POLICY.md`
- `log.md`

## PR Requirements
- Use the PR template fully.
- Link issue or ticket.
- Include screenshots for UI changes.
- Include migration notes when schema-affecting.
- Pass all required CI checks.
- PRs must contain only task-specific changes; no broad/unrelated project-wide edits.
- Never create "full project" PRs that touch large unrelated file sets.
- Team members may keep broader local work in their own branches, but PRs must be trimmed to the exact intended scope.

## Coding Standards
- Reusable-first: check `REUSABLES.md` before creating shared UI.
- Flutter UI must use project shared controls (`FormDropdown`, `ZTooltip`, `ZerpaiDatePicker`).
- Respect module boundaries in `lib/modules` and NestJS module boundaries in `backend/src/modules`.
- No hardcoded business IDs or schema assumptions.
- Keep business logic and infrastructure logic separated:
  - business ownership in module folders
  - printer/network/storage infrastructure in `core`/shared infra layers
- New import/export/print files must be module-owned unless they are pure infrastructure adapters.
- Avoid generic sink names (`helpers`, `utils`, `common`) for new feature code; use owner-specific names.
- For new routes, define feature route files per module and compose centrally; avoid adding new monolithic router ownership.

## Quality Gates
- `flutter analyze`
- `flutter test`
- backend build/test
- workflow lint/security checks
- migration validation for DB changes

## Commit and Review
- Conventional commits only.
- Stage and commit only task-specific changed files; do not stage broad unrelated sets.
- Local strict hook blocks oversized staging and `node_modules` commits.
- At least 2 reviewers for protected paths.
- CODEOWNERS approvals required where applicable.

## Security and Data Safety
- Never commit secrets.
- Preserve tenant isolation (`entity_id` scoped operations).
- Use audit-safe patterns for finance/inventory/accounting changes.

## Local Commands
```bash
flutter pub get
flutter analyze
flutter test
npm run test:backend
npm run test:e2e
```

## Escalation
If a change can impact journals, stock valuation, GST, transaction locking, or migration integrity, request architecture and domain owner review before merge.
