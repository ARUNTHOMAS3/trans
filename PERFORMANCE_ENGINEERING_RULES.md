# Performance Engineering Rules

## Frontend
- minimize rebuild scope in Riverpod consumers
- paginate and virtualize large tables
- avoid expensive sync work in build methods
- prefer debounced search and lazy detail hydration

## Backend
- index query-critical columns
- avoid N+1 query patterns
- paginate list endpoints server-side
- use batch operations for bulk updates

## Budgets
- API p95 target: < 500ms
- page load target: < 2s
- slow query threshold: 200ms
