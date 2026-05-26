# Database Change Policy

## Source of Truth
- Primary and authoritative: `current schema.md`
- Secondary cross-reference only: `PRD/prd_schema.md`
- In any conflict, `current schema.md` wins.

## Required Process
1. Document intent and impacted workflows.
2. Create additive migration.
3. Validate forward compatibility.
4. Include rollback approach.
5. Run schema consistency checks in CI.

## Prohibited
- destructive drops without approved migration plan
- silent type changes on finance/inventory columns
- foreign key removal without compensating safety controls

## Required Controls
- transactional migrations for critical tables
- index review for new query paths
- UUID keys for business entities
- soft delete preference for master/business data

## ERP Critical Tables
Any change to accounting/inventory/transaction lock/payment tables requires domain owner approval and test evidence.
