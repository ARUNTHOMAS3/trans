# AI Agent Rules

Applies to ChatGPT, Claude, Gemini, Cursor, Copilot, CodeRabbit.

Mandatory context bootstrap: `AI_AGENT_MANDATORY_READS.md`.

## Mandatory
- PRD-first and schema-aware changes.
- `current schema.md` is the authoritative DB schema source of truth.
- Reusable-first implementation (`REUSABLES.md` check required).
- Always suggest reusable usage when available; if none exists and a repeated pattern is found, recommend reusable extraction/promotion.
- Enforce centralized theming: use `AppTheme`/approved theme sources only for colors and visual states.
- For numeric and placeholder-driven inputs, use hint text (for example `0`) instead of prefilled default values whenever the field should remain user-entered.
- No duplicate widgets/services with overlapping purpose.
- No schema assumptions outside documented sources.
- Preserve project naming and folder conventions.
- Keep changes minimal and auditable.

## Prohibited
- uncontrolled refactors across modules
- architecture rewrites without explicit approval
- bypassing theme/responsive/shared UI systems
- hardcoded color values in feature/module code without approved exception
- introducing hidden migration side effects

## Review Requirements
AI-assisted PRs must include:
- what was generated vs manually authored
- risk areas and verification performed
- impacted modules and migration impact summary
