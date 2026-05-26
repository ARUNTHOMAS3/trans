# Prompt To Request Codev Files (Copy-Paste)

Use this exact prompt with codev:

---
You have today’s updates on your machine that I need to pull into my repo.

Please prepare an **inbound handoff package** for April 23 -24, 2026.

## What to send

1. Your updated source files (frontend + backend) for today.
2. Your `log_A.md` entries created today (April 23 -24, 2026).
3. A short changelog mapping:
   - file path
   - what changed
   - why it changed
   - any known risks
4. Any SQL or migration scripts you created today.

## Required path format

Keep original repo-relative paths exactly.  
Example:
- `lib/modules/...`
- `backend/src/modules/...`

## Package structure to send

Create a folder like:
`handoff/inbound_2026-04-23 -24_from_codev/`

Inside it include:
- `source_snapshot/` (all changed files with original relative paths)
- `LOG_ENTRIES_2026-04-23 -24.md` (copied from your log.md for today)
- `FILES_CHANGED.md`
- `IMPLEMENTATION_SUMMARY.md`
- `PRECAUTIONS.md`
- `MIGRATIONS_OR_SQL.md` (if applicable)

## Validation before sending

- Backend: `npm run build` passes
- Flutter: `flutter analyze` passes for touched areas
- Mention any failing tests/analyzers explicitly if present

## Important

- Do not squash/remove paths.
- Do not send only snippets; send full files.
- Include both files and any dependent files ( filters, endpoints, providers, models, DTO/service/controller changes).

After packaging, send me:
- package folder path
- list of changed files
- top 5 risk points to watch while merging
---

