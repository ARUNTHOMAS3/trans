# Development Guidelines

## Scope
Standards for implementing production-grade changes in ZERPAI ERP without architectural drift.

## Core Rules
- Follow existing folder structure; do not introduce parallel architecture.
- Extend existing patterns before introducing new abstractions.
- Use shared widgets/services first.
- Keep routes deep-linkable through GoRouter.

## Flutter
- Keep UI dense, responsive, and token-driven.
- Use shared responsive foundation and table/form shells.
- Avoid direct `Tooltip`, `DropdownButton(FormField)`, and raw date picker usage where shared controls exist.

## Backend
- Keep controllers thin; use service/repository patterns.
- Validate DTOs strictly.
- Use transaction boundaries for multi-write operations.
- Use consistent API response envelope.

## Data
- `current schema.md` is the authoritative database source of truth.
- Use `PRD/prd_schema.md` as supporting reference only.
- No destructive migrations in shared envs.
- Add indexes for high-cardinality query paths.

## Reviewability
- Keep PRs small and cohesive.
- Add before/after notes and risk assessment.
- Include rollout and rollback notes for critical changes.
