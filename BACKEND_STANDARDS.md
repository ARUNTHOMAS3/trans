# Backend Standards

## NestJS
- modular structure under `backend/src/modules`
- thin controllers, rich services
- explicit DTO validation
- unified response envelope

## Data and Safety
- strict tenant context usage
- transaction wrappers for multi-step writes
- strong error handling with actionable logs
- no raw unparameterized SQL
- treat `current schema.md` as the authoritative DB schema contract for all service/repository changes

## Observability
- structured logs for failures and critical operations
- include module context and correlation IDs where available
