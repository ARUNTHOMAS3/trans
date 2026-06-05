## Summary
Implements enterprise repository governance, strict PR scope controls, AI mandatory-read bootstrap rules, commit/branch policy enforcement, issue templates, and CI quality/security workflows.

## Scope
- Modules touched: repository governance/docs and GitHub automation
- Backend/API impacted: none (policy/workflow only)
- DB/migration impacted: none
- UI impacted: none
- Why each changed file is required:
  - `.github/*`: enforce PR, security, lint, build, schema, scope, and ownership policies
  - root governance `*.md`: define team/AI/process standards and ERP safety guardrails
  - `package.json`, `package-lock.json`, `commitlint.config.cjs`, `.husky/*`, `scripts/validate-branch-name.mjs`: enforce commit and branch conventions

## Validation
- [x] PR includes only task-specific files (no unrelated/full-project changes)
- [x] Governance/automation files reviewed for consistency with repository structure
- [ ] CI checks pending on GitHub

## Notes
- This PR intentionally excludes unrelated module/runtime edits.
- `current schema.md` remains the authoritative DB source-of-truth reference in governance and PR checks.

## Linked Issues
- Closes #
