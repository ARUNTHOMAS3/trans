# Main Branch Lockdown Checklist (`main`)

Use this checklist in **GitHub → Settings → Branches** and **Settings → Rules → Rulesets** for strict protection.

## Scope
- Repository: `ZABNIX/ZERPAI`
- Protected branch: `main`
- Allowed maintainers: `@frpboy` and org admin owner/team only

---

## 1) Branch Protection Rule for `main`
- [ ] Create/confirm branch protection rule for `main`
- [ ] **Require a pull request before merging**
- [ ] **Require approvals**: set to `2`
- [ ] **Require review from Code Owners**
- [ ] **Dismiss stale pull request approvals when new commits are pushed**
- [ ] **Require approval of the most recent reviewable push**
- [ ] **Require status checks to pass before merging**
- [ ] Enable **Require branches to be up to date before merging**
- [ ] Select required checks (example):
  - [ ] CI / build
  - [ ] lint/analyze
  - [ ] guardrails/secrets scan
- [ ] **Restrict who can push to matching branches**
  - [ ] Add only `@frpboy`
  - [ ] Add only org owner/admin team
- [ ] **Do not allow bypassing the above settings**
- [ ] **Do not allow force pushes**
- [ ] **Do not allow deletions**
- [ ] Enable **Lock branch** (optional strict mode; only if your workflow supports it)

---

## 2) CODEOWNERS Enforcement
- [ ] Ensure `.github/CODEOWNERS` exists on default branch
- [ ] Confirm 2 owners are present for `*` and sensitive paths
- [ ] Verify PRs touching protected files request both maintainers

---

## 3) Repository Role Hardening
- [ ] Org members needing contribution: set to **Read** by default
- [ ] Give **Write/Maintain/Admin** only to trusted maintainers
- [ ] Remove unnecessary outside collaborators
- [ ] Disable broad team write access unless required

---

## 4) Ruleset (Recommended, stricter than classic branch rule)
Create a **Repository Ruleset** targeting `main`:
- [ ] Block direct pushes
- [ ] Require PR merge only
- [ ] Require CODEOWNERS review
- [ ] Require 2 approvals
- [ ] Require passing checks
- [ ] Block force-push
- [ ] Block branch deletion
- [ ] Apply to admins (no bypass except explicit ruleset bypass list)

---

## 5) Merge Method Policy
- [ ] Allow only one merge strategy (recommended: **Squash merge**)
- [ ] Disable merge methods you do not use (merge commit/rebase merge)
- [ ] Require conversation resolution before merge

---

## 6) Action and Token Security
- [ ] Settings → Actions → General:
  - [ ] Allow only verified/trusted actions (or selected actions only)
  - [ ] Set workflow permissions to **Read repository contents**
  - [ ] Disable “Allow GitHub Actions to create and approve pull requests” unless required
- [ ] Protect environments with required reviewers for deployments

---

## 7) Secret Protection
- [ ] Enable secret scanning and push protection (GitHub Advanced Security if available)
- [ ] Keep CI guardrail workflow active for blocked files/patterns
- [ ] Ensure no real `.env` values are committed

---

## 8) Verify Lockdown (Acceptance Test)
- [ ] Test with a non-maintainer account:
  - [ ] Cannot push directly to `main`
  - [ ] Cannot force push
  - [ ] Cannot delete `main`
  - [ ] Cannot merge PR without required approvals/checks
- [ ] Test with maintainer account:
  - [ ] PR with required checks + approvals merges successfully

---

## 9) Important Limitation
- [ ] A user with **Read** access can still clone/fetch the repository.
- [ ] GitHub does **not** support “read but cannot clone”.
- [ ] To prevent code download, code must not be accessible (private access not granted).

---

## 10) Suggested Minimal Access Model
- [ ] New contributors: work only from `ui-base-clean` workflow with PRs
- [ ] Keep `main` merge rights with `@frpboy` + org admin owner/team
- [ ] Enforce CODEOWNERS + required checks for all production-bound changes

