# Architecture Guardrails

## Monorepo Integrity
- Frontend: `lib/`
- Backend: `backend/src/`
- Database migrations: `supabase/` and approved SQL locations.
- Do not move module roots or rewrite naming conventions.

## Module Boundaries
- `lib/modules/<module>/` stores feature-specific UI/business logic.
- `lib/shared/` stores reusable cross-feature assets.
- `lib/core/` stores app infrastructure only.
- NestJS modules under `backend/src/modules/` must own their controllers/services/entities.

## ERP Safety Boundaries
Changes touching these must include architecture review:
- accounting journals, account transactions, lock dates
- inventory adjustments/transfers/valuation
- GST/tax logic and totals
- sequence generators and reference numbering

## Anti-Patterns
- duplicate shared widgets/services
- bypassing existing repositories/providers
- endpoint-specific ad hoc model duplication
- cross-module circular dependencies
- module-level hardcoded color styling that bypasses centralized theme tokens

## Reusable Promotion Rule
- Repeated UI/logic patterns discovered in active work should be evaluated for reusable extraction.
- If reusable extraction is deferred, document rationale in PR notes to prevent drift.
