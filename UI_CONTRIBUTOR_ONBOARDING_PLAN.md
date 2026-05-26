# UI Contributor Onboarding & Security Plan

## Objective
Safely onboard UI contributors without exposing backend environments, production data, or secrets.

## Scope
- Contributors work on Flutter UI only.
- No backend environment access.
- No cloud console access.
- No production/staging credentials.

---

## Implementation Plan

### 1. Create a Safe Baseline Branch
1. Create a branch named `ui-base` from stable `main`.
2. Keep only UI-safe foundations required for contributor work:
   - Sidebar
   - Navbar
   - Home dashboard shell
3. Ensure UI can run without backend secrets:
   - Keep `.env.example` only
   - Remove real values from all local config
4. Use mock/stub data for UI flows where needed.

### 2. Lock Down Repository Controls
1. Protect `main` branch:
   - Require pull requests
   - Require at least one approval
   - Disable force pushes
   - Restrict direct pushes
2. Ensure only maintainers can merge to `main`.
3. Enable 2FA requirement for organization/repo access.

### 3. Define Contributor Workflow
1. New contributor branches from `ui-base` (or forks then tracks `ui-base`).
2. Contributor creates feature branch:
   - `ui/<feature-name>`
3. Contributor opens PR against `ui-base`.
4. Maintainer reviews and merges to `ui-base`.
5. Maintainer periodically merges `ui-base` into `main`.

### 4. Add Review Ownership and Guardrails
1. Add `CODEOWNERS` to require maintainer review for critical paths.
2. Add PR template with explicit checks:
   - UI-only change
   - No backend/API contract changes
   - No env/secrets changed
3. Add CI checks:
   - Lint/format/tests
   - Secret scan
   - Block `.env`, key files, and forbidden sensitive paths for UI-only PRs

### 5. Onboard New Members Safely
1. Provide lowest required Git permissions (no admin).
2. Share only:
   - `ui-base` workflow
   - UI setup docs
   - Coding rules
3. Do not share:
   - Backend URLs requiring auth tokens
   - DB credentials
   - Service-role keys
   - Cloud console access

### 6. Operational Governance
1. Keep PRs small and focused.
2. Require naming convention and clean commit messages.
3. Run periodic security audits on repository secrets and access logs.
4. Rotate any credential immediately if accidental exposure is suspected.

---

## Master Checklist

### A. Baseline Branch Setup
- [ ] Create `ui-base` from stable `main`
- [ ] Confirm sidebar/navbar/home shell available
- [ ] Ensure app runs without backend secrets
- [ ] Provide `.env.example` with dummy values only
- [ ] Remove any hardcoded sensitive URLs/tokens

### B. Branch Protection & Access
- [ ] Enable PR-only merge on `main`
- [ ] Disable force push on `main`
- [ ] Restrict `main` direct push
- [ ] Require maintainer approval
- [ ] Enforce 2FA for members
- [ ] Grant contributors non-admin role only

### C. PR/Review Process
- [ ] Add `CODEOWNERS`
- [ ] Add PR template with UI-only assertions
- [ ] Require checks before merge
- [ ] Require maintainer final review

### D. CI Security Guardrails
- [ ] Add secret scanning workflow
- [ ] Block committed `.env` files
- [ ] Block private key/service-role patterns
- [ ] Add lint/format/test checks
- [ ] Optional: block sensitive file paths for UI contributors

### E. Contributor Workflow
- [ ] Branch from `ui-base`
- [ ] Use `ui/<feature-name>` naming
- [ ] Raise PR to `ui-base`
- [ ] Address review comments
- [ ] Maintainer merges `ui-base` to `main` periodically

### F. Data Protection
- [ ] Use mock/demo data only for UI contributors
- [ ] Avoid customer-identifiable sample data
- [ ] Avoid production screenshots with sensitive data

### G. Offboarding
- [ ] Remove repo access immediately
- [ ] Revoke tokens/shared integrations if any
- [ ] Rotate exposed credentials (if needed)
- [ ] Audit recent PRs and access logs

---

## Recommended Team Policy (Short Form)
- UI contributors must not access backend environments.
- UI contributors must not add/edit secrets or deployment configs.
- All merges to `main` are maintainer-controlled.
- Any exception requires explicit written approval.

---

## Suggested File Companions
- `CODEOWNERS`
- `.github/pull_request_template.md`
- `.github/workflows/secret-scan.yml`
- `README_UI_CONTRIBUTOR.md`

