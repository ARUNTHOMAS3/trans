# AI Agent Mandatory Reads

All AI agents (ChatGPT, Claude, Gemini, Cursor, Copilot, CodeRabbit) must read these files before suggesting or generating implementation changes.

## Mandatory Startup Reads
1. `AGENTS.md`
2. `AI_AGENT_RULES.md`
3. `REUSABLES.md`
4. `current schema.md` (authoritative DB source of truth)
5. `ARCHITECTURE_GUARDRAILS.md`
6. `DATABASE_CHANGE_POLICY.md`
7. `FRONTEND_STANDARDS.md`
8. `BACKEND_STANDARDS.md`
9. `TESTING_STRATEGY.md`
10. `.github/pull_request_template.md`
11. `log.md` (last 2000 lines and if available in root)

## PR Scope Discipline (Strict)
- Only include files needed for the exact task.
- Never generate PRs with broad unrelated project changes.
- Keep in-progress work on personal branches; open focused PRs only.
- If a file is changed, AI output must justify why that file is required.

## Reusables and Theming
- Check `REUSABLES.md` first; use existing reusable abstractions where possible.
- If repeated pattern appears in 2+ touched places, suggest reusable extraction/promotion.
- No hardcoded colors in feature code; use centralized `AppTheme`/approved theme tokens.

## Database Integrity
- `current schema.md` is authoritative. In conflicts, `current schema.md` wins.
- `PRD/prd_schema.md` is secondary cross-reference.

## Enforcement
- If required context files are not read, AI should pause and request/perform context loading before proposing implementation.
