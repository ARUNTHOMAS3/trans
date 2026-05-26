# Migration Policy

## Principles
- additive first
- backward compatible rollouts
- explicit rollback steps
- avoid data-destructive operations in shared environments

## Required PR Content
- migration intent
- impacted tables and indexes
- data backfill strategy
- rollback strategy
- verification queries

## Safety
For finance/inventory-impacting migrations, require domain owner + DB owner approval.
