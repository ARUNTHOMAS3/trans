# LEAN-CTX.md — Zerpai Structure + Merge Guardrails

This file is the local Lean context rule reference for safe structural work.

## Mandatory Rules

- Canonical ownership first; no random placement.
- Backup-first for any inbound handoff merge.
- Compatibility-first for moved active paths.
- No delete+move in same batch.
- Verify touched scope before claiming done.
- Update `log.md` for all structural merges.
- Never delete handoff backups/folders without explicit approval.
