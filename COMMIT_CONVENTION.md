# Commit Convention

Format: `type(scope): summary`

Allowed types:
- `feat`
- `fix`
- `perf`
- `refactor`
- `docs`
- `test`
- `security`
- `style`
- `chore`

Examples:
- `fix(inventory): prevent zero-quantity batch allocation save`
- `perf(items): memoize product table row rendering`
- `security(auth): validate tenant headers in middleware`

Rules:
- subject in imperative mood
- <= 72 chars recommended
- include body for migration or risk-heavy changes
- commit scope must be focused: only task-specific staged files
- avoid broad `git add .` style commits for unrelated work
