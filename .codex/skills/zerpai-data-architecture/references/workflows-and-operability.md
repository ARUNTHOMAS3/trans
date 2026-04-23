# Workflows And Operability

## Workflow Locks

- Sales must move through quotation, sales order, invoice, then payment.
- Purchases must move through purchase order, receipt, bill, then payment.
- Inventory deductions happen on confirmed invoice events, not earlier.
- Inventory additions happen on receipt events, not on bill creation.

## Reporting

- Reports should read from the proper transactional tables, not inferred UI state.
- Exports in v1 focus on CSV and Excel workflows.
- Preserve outlet and date filtering capability where the PRD expects it.

## Auth-Ready Without Enforced Auth

- Backend and schema should remain ready for later RLS and JWT integration.
- Do not require active auth in dev or staging flows unless explicitly requested.

## Operability Expectations

- Keep health checks, deployment, rollback, and monitoring assumptions compatible with the PRD operational docs.
- Avoid data model changes that would complicate backup, restore, or incident response without clear justification.
