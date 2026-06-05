# Release Process

## Branches
- `dev` for integration
- `release/*` for release stabilization
- `main` for production
- `hotfix/*` for urgent production fixes

## Release Checklist
1. Freeze non-release changes.
2. Ensure all required CI checks pass.
3. Validate migrations in staging.
4. Run smoke tests (finance, inventory, reports).
5. Tag release and publish notes.

## Rollback
- Revert deployment to last known good tag.
- Execute approved DB rollback steps if needed.
- Run post-rollback smoke tests.
- Publish incident summary.
