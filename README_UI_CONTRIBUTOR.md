# UI Contributor Guide

## Goal
You are contributing to Zerpai UI safely, without backend or production access.

## Access Boundaries
- UI-only work in `lib/`.
- No backend env required.
- No DB credentials required.
- No cloud console access required.

## Branch Workflow
1. Create your branch from `ui-base`.
2. Use naming: `ui/<feature-name>`.
3. Commit focused changes only.
4. Open PR to `ui-base`.
5. Address review comments.
6. Maintainer merges to `ui-base` and later to `main`.

## Do
- Use existing shared widgets from `REUSABLES.md` before creating new ones.
- Follow AGENTS rules in the repository.
- Keep PRs small and focused.
- Add screenshots for visual changes.
- Run `flutter analyze` before pushing.

## Don't
- Do not add/edit `.env` files.
- Do not add secrets, keys, or tokens.
- Do not modify backend, Supabase, or deployment configuration unless explicitly assigned.
- Do not push directly to `main`.

## Project Commands
```bash
flutter pub get
flutter analyze
flutter run -d chrome
```

## Files Usually In Scope
- `lib/modules/**`
- `lib/shared/widgets/**`
- `lib/core/layout/**` (only when assigned)

## Files Out Of Scope (Unless Explicitly Assigned)
- `backend/**`
- `supabase/**`
- `.github/workflows/**`
- `firebase.json`, `Railway/Cloudflare Pages.json`
- schema and migration docs/sql

## PR Quality Checklist
- UI matches requested design and behavior.
- No forbidden/sensitive file changes.
- No hardcoded secrets.
- Lint/analyze clean.
- Screenshots included for UI diffs.

## Support Path
If blocked by API/data, ask maintainer for mock/stub direction. Do not request production credentials.

