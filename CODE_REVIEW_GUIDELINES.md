# Code Review Guidelines

## Review Priorities
1. correctness and ERP workflow safety
2. data integrity and tenancy isolation
3. architecture consistency
4. performance and UX
5. maintainability

## Required Checks
- no schema drift
- no reusable duplication
- no route/state regressions
- migration and rollback clarity
- tests for changed business logic

## High-Risk Paths
Finance, inventory, tax, transaction locks, sequence generation require deeper review and domain owner approval.
