# Branching Strategy

## Long-Lived Branches
- `main`: production-ready code only.
- `dev`: integration branch for upcoming release.
- `staging`: optional stabilization mirror.

## Short-Lived Branches
- `feature/*`
- `fix/*`
- `bugfix/*`
- `perf/*`
- `hotfix/*`
- `docs/*`

## Merge Rules
- Short-lived branches -> `dev` via PR.
- `release/*` -> `main` after full checks and approvals.
- `hotfix/*` -> `main` then back-merge to `dev`.

## Protection Rules
- Require pull request.
- Require status checks.
- Require CODEOWNERS review.
- Restrict force-push/deletions on `main` and `dev`.
