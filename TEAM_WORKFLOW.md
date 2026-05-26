# Team Workflow

## Lifecycle
Issue -> Branch -> PR -> Review -> CI Pass -> Merge -> Release

## Branch Prefixes
`feature/*`, `fix/*`, `bugfix/*`, `perf/*`, `hotfix/*`, `docs/*`

## Access Policy
- Full repo control is reserved to maintainers/owners only.
- All contributors must work on their own prefixed branches.
- Direct pushes to `main` are prohibited for everyone.

## PR Expectations
- single concern per PR
- checklist fully completed
- evidence for tests and UI validation
- include only the files required for the specific task/change request
- do not open PRs containing broad unrelated file modifications or full-repo sweeps
- keep extra/in-progress work on personal branches until split into focused PRs

## Review SLAs
- first review within 1 business day
- critical hotfix review ASAP with owner sign-off
