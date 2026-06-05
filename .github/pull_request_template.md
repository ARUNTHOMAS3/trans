# Pull Request Template

## Summary
- What problem does this change solve?
- Why is this approach chosen?

## Scope
- Modules touched:
- Backend/API impacted:
- DB/migration impacted:
- UI impacted:
- Why each changed file is required:

## Validation
- [ ] flutter analyze
- [ ] flutter test
- [ ] backend build/test
- [ ] e2e (if applicable)
- [ ] manual QA steps documented
- [ ] PR includes only task-specific files (no unrelated/full-project changes)

## Architecture Review Checklist
- [ ] No new parallel architecture introduced
- [ ] Module boundaries preserved
- [ ] Reusable-first check completed (`REUSABLES.md`)
- [ ] Repeated patterns reviewed for reusable extraction/promotion
- [ ] Routes/state conventions preserved
- [ ] No unrelated files included; each changed file maps to this PR's objective

## Database Migration Checklist
- [ ] Migration required / not required
- [ ] Additive and backward compatible
- [ ] Rollback steps included
- [ ] Index and constraint impact reviewed
- [ ] `current schema.md` verified as source of truth
- [ ] `PRD/prd_schema.md` cross-check completed (if applicable)

## UI/UX Review Checklist
- [ ] Shared controls used (`FormDropdown`, `ZTooltip`, `ZerpaiDatePicker`)
- [ ] Responsive behavior verified
- [ ] Pure-white floating surfaces maintained
- [ ] Theme token compliance verified
- [ ] No hardcoded color literals introduced in feature code

## Performance Review Checklist
- [ ] No avoidable rebuild hotspots
- [ ] Pagination/lazy loading respected for large data
- [ ] Query/API impact reviewed

## Security Review Checklist
- [ ] Tenant isolation preserved
- [ ] Input validation updated where needed
- [ ] No secrets or sensitive data committed
- [ ] Audit-sensitive flows reviewed

## ERP Safety Checklist
- [ ] Journal integrity preserved
- [ ] Stock movement/valuation safe
- [ ] GST/tax calculations unchanged or validated
- [ ] Transaction locks honored

## Evidence
- Screenshots / recordings:
- Logs / test outputs:
- Migration verification queries:

## Linked Issues
- Closes #
