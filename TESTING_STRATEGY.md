# Testing Strategy

## Pyramid
- unit: domain logic and helpers
- integration: service + repository + API contracts
- e2e: critical user journeys via Playwright

## Must-Test Scenarios
- accounting journal integrity
- inventory movement and valuation correctness
- GST/tax totals and rounding
- transaction lock enforcement
- tenant isolation in list/detail endpoints

## CI Gates
- analyze/lint
- unit/integration suites
- build verification
- selective e2e on PR and full e2e on release branches
