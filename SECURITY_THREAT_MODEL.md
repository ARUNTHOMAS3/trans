# Security Threat Model

## Primary Risks
- tenant data leakage
- privilege escalation
- financial record tampering
- stock manipulation
- secret exposure

## Controls
- strict `entity_id` scoping
- RBAC checks for sensitive operations
- DTO validation and output sanitization
- parameterized queries/ORM-safe operations
- immutable audit logging for critical changes

## OWASP Mapping
- A01 Broken Access Control: enforce route + service authorization
- A03 Injection: strict validation, no string-built SQL
- A05 Security Misconfiguration: CI checks and safe defaults
- A09 Logging/Monitoring Failures: structured logs + alerts

## Incident Expectations
Any suspected tenant breach or financial tamper event is P0.
