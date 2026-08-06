# ðŸ“š Zerpai ERP Documentation Index

##      PRD Edit Policy

Do not edit PRD files unless explicitly requested by the user or team head.

## ðŸ”’ Auth Policy (Pre-Production)

No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-29 23:32
**Last Edited Version:** 1.6

---

##   š¡ **QUICK START**

### ðŸ”´ **Starting Development? Read This First:**

ðŸ‘‰ **[PRD_COMPLIANCE_AUDIT.md](PRD_COMPLIANCE_AUDIT.md)** - Current codebase vs PRD requirements

- **What needs to change NOW**
- **Prioritized action plan (P0, P1, P2)**
- **Week-by-week checklist**

---

## ðŸ“– Documentation Structure

### **Core Product Requirements**

#### 1. **`PRD.md`**   ­ **START HERE**

- **Complete PRD (25 sections, ~1,800 lines)**
- Architecture, tech stack, workflows
- Development standards, testing, security
- ALL essential information in one place
- **Use this as:** Single source of truth for development

#### 1.1 **`prd_tech_stack.md`** ðŸ§± **STACK REFERENCE**

- Canonical Flutter/NestJS/Supabase/Drizzle/Railway/Cloudflare Pages stack decisions
- Package inventory and runtime implementation notes from the current codebase
- Environment, deployment, testing, and monitoring stack details
- PRD-vs-code drift list for stack-related gaps
- **Use this for:** Dependency decisions, environment setup, backend/frontend integration, and stack reviews

---

### **Operational Guides** (Detailed Standalone Documents)

These are extracted from the comprehensive PRD for focused operational use:

#### 2. **`prd_disaster_recovery.md`**

- Backup strategy (Daily, PITR, manual)
- Recovery objectives (RTO <4h, RPO <24h)
- Incident response plan (P0-P3 severity)
- Disaster scenarios & recovery procedures
- **Use this for:** DevOps, infrastructure, incident response

#### 3. **`prd_deployment.md`**

- CI/CD pipeline (GitHub Actions)
- Deployment environments (dev, staging, prod)
- Release process (step-by-step)
- Versioning strategy (semantic versioning)
- Rollback procedures
- **Use this for:** Deployment, releases, DevOps

#### 4. **`prd_monitoring.md`**

- Monitoring stack (Sentry, Railway/Cloudflare Pages, UptimeRobot)
- Key metrics & alert thresholds
- Health check endpoints
- Logging standards
- **Use this for:** Operations, on-call, performance

#### 5. **`prd_onboarding.md`**

- New user setup flow
- First-time user experience (FTUE)
- Training materials (videos, docs)
- Sample data / demo mode
- **Use this for:** Product, UX, support

#### 6. **`prd_roadmap.md`**

- Version history & future releases
- Feature roadmap (v1.1 through v3.0)
- Known limitations
- Feature request process
- **Use this for:** Product planning, stakeholder communication

#### 7. **`prd_folder_structure.md`** ðŸ“ **NEW - CRITICAL**

- Complete folder structure (Frontend & Backend)
- File naming conventions (STRICT snake_case)
- Module internal organization
- Decision tree: "Where should I put this file?"
- Backend (NestJS) structure
- Asset & test organization
- **Use this for:** New code placement, refactoring, onboarding

---

#### 8. **`prd_ui.md`** ðŸŽ¨ **UI-ONLY PRD**

- UI standards only (layouts, inputs, tables, navigation chrome)
- Creation/edit page rules
- Advanced UI behaviors and hidden logic
- **Use this for:** UI/UX implementation and consistency

---

#### 9. **`prd_schema.md`** ðŸ—„ï¸ **SCHEMA SNAPSHOT**
- Current DB schema table list (snapshot)
- Strict form-to-table mapping rules
- **Use this for:** Data mapping and backend integration

---

#### 10. **`prd_keyboard_shortcuts.md`**     ¨ï¸ **SHORTCUT REFERENCE**
- Centralized list of all power-user shortcuts
- Implementation details (ShortcutHandler, isDirty tracking)
- Tooltip and visual hint standards
- **Use this for:** UI/UX implementation and power-user accessibility

---

## ðŸ—ºï¸ Quick Navigation

### **For Developers:**

1. Read `PRD.md` sections 1-15
2. Follow live module naming/placement:
   - `snake_case`
   - `presentation/` owns UI
   - many route screens live under `presentation/pages/`
   - `presentation/*.dart` may be export shims
3. Use Riverpod, Dio (no deprecated packages!)
4. Reference Section 14 (UI System & Design Governance)
5. Use `prd_ui.md` for UI-only rules and patterns
6. Follow Layout Stability Rules (Section 14.4.1)

### **For DevOps:**

1. `prd_disaster_recovery.md` - Set up backups
2. `prd_deployment.md` - Configure CI/CD
3. `prd_monitoring.md` - Set up alerts

### **For Product Managers:**

1. `PRD.md` sections 1, 8, 9
2. `prd_roadmap.md` - Plan features
3. `prd_onboarding.md` - Improve UX

### **For QA/Testing:**

1. `PRD.md` section 17 (Testing Strategy)
2. Critical test scenarios (17.5)
3. 70% coverage requirement

### **For Security:**

1. `PRD.md` section 20 (Security)
2. RLS policies, authentication, compliance

---

## ðŸ“Š Document Statistics

| Document                     | Sections | Lines | Purpose                      |
| ---------------------------- | -------- | ----- | ---------------------------- |
| **PRD.md**                   | 25       | 1,867 | Complete PRD (all-in-one)    |
| **prd_tech_stack.md**        | 9        | ~330  | Stack inventory, runtime, drift |
| **prd_disaster_recovery.md** | 11       | ~600  | Backups, incidents, recovery |
| **prd_deployment.md**        | 12       | ~900  | CI/CD, releases, rollbacks   |
| **prd_monitoring.md**        | 9        | ~300  | Metrics, alerts, logs        |
| **prd_onboarding.md**        | 8        | ~350  | User setup, training, FTUE   |
| **prd_roadmap.md**           | 11       | ~550  | Versions, features, timeline |
| **prd_ui.md**                | 47       | 380   | UI-only standards & patterns |
| **prd_keyboard_shortcuts.md**| 6        | ~120  | Power-user shortcut ref      |

**Total:** ~5,277 lines of comprehensive documentation

---

## ðŸŽ¯ Key Decisions (Locked)

These **cannot** be changed without major discussion:

1. **Products are Global** (no `org_id`) - Section 12.1
2. **Riverpod** for state management - Section 7
3. **Dio** for HTTP (no `http` package) - Section 7
4. **Hive** for offline data - Section 7.1
5. **File Naming/Placement:** `snake_case` owner-based module files with live `presentation/pages/` usage - Section 15
6. **UI System Compliance:** Strictly via `app_theme.dart` - Section 14
7. **Git Workflow:** `feat/*`, `fix/*`   †’ `dev`   †’ `main` - Section 14.4
8. **Testing:** 70% coverage minimum - Section 17.2
9. **Latest Stable Dependencies Only** - Section 7.1
10. **DB Options/Master Table Naming:** `<module_name>_<options_descriptor>` for all new lookup tables - Section 12.1
11. **Menu & Dropdown System:** Mandatory use of `MenuAnchor` for actions and `FormDropdown` for inputs - Section 14.11
12. **Sidebar Module Map:** Locked navigation order and sub-modules for Items, Inventory, Sales, Purchases, Accountant, Accounts, Reports, Documents, and Audit Logs - Section 8.1
13. **Layout Stability Rules (Golden Rules):** Mandatory for all UI layouts - Section 14.4.1
14. **Schema Snapshot Compliance:** All forms must map to `PRD/prd_schema.md` - Section 12.3
15. **Settings Table Naming:** Settings-related backend work must use canonical table names from `current schema.md`; no blanket `settings_` prefix
15. **UI Case Standards:** Mandatory Title Case for destinations/actions and Sentence case for instructions - Section 14.3.1
16. **Data Casing Policy:** Descriptive data must be stored exactly as entered; visual uppercase is allowed only in specific contexts (Tables/Identifiers) - Section 14.3.2
17. **Mandatory Pagination:** All tables must implement server-side pagination with a default of 100 rows per page - Section 14.5.4
18. **Numeric Input Restriction:** Fields expecting digits (Quantity, Rate, Tax, etc.) must strictly block alphabetic characters - Section 14.12.2
19. **Standardized Shortcuts:** All power-user shortcuts must align with the `prd_keyboard_shortcuts.md` and use the `ShortcutHandler` wrapper.
20. **Canonical Stack Reference:** `prd_tech_stack.md` is the standalone package/runtime/deployment stack index and must stay aligned with `PRD.md` Section 7.
21. **Polymorphic Entity Tenancy:** All transactions must use the `entity_id` scoped model referencing `organisation_branch_master`. Dual-column `org_id + branch_id` is deprecated.

**Last Updated: 2026-04-20 12:46:08**

| Document                 | Review Schedule     | Owner                 |
| ------------------------ | ------------------- | --------------------- |
| PRD.md                   | Every major release | Product + Engineering |
| prd_tech_stack.md        | Every stack change  | Engineering + DevOps  |
| prd_disaster_recovery.md | Quarterly + post-P0 | DevOps                |
| prd_deployment.md        | After CI/CD changes | DevOps                |
| prd_monitoring.md        | Quarterly           | DevOps                |
| prd_onboarding.md        | Monthly             | Product               |
| prd_roadmap.md           | Monthly             | Product               |

### **Version Control**

All PRD documents are version-controlled in Git. Check commit history for changes.

---

## ðŸš   Getting Started Checklist

**New to the project? Start here:**

- [ ] Read `PRD.md` sections 1-7 (Overview, Architecture, Tech Stack)
- [ ] Understand the workflows (Section 8)
- [ ] Review development standards (Section 14)
- [ ] Set up local environment (`.env.example`)
- [ ] Read through code conventions (file naming, commit messages)
- [ ] Join team Slack channels (#engineering, #product)

---

## ðŸ“ž Questions?

**Documentation Issues:**

- Create issue: `github.com/zerpai/erp/issues`
- Label: `docs`

**Contact:**

- **Product:** product@zerpai.com
- **Engineering:** dev@zerpai.com
- **DevOps:** devops@zerpai.com

---

## ðŸ“ Changelog

| Date       | Version | Changes                                   |
| ---------- | ------- | ----------------------------------------- |
| 2026-01-20 | 1.0     | Initial comprehensive documentation suite |

---

**Last Updated:** 2026-01-30  
**Next Review:** 2026-04-20


---

## Strict Structure + Handoff Merge Governance (2026-05-24)

1. Canonical placement mandatory:
- Business code -> `lib/modules/<domain>/...`
- App infra -> `lib/core/...` or `lib/app/...`
- Cross-domain reusable UI -> `lib/shared/widgets/...`
- Cross-domain services -> `lib/shared/services/...`

2. File/folder creation controls:
- Confirm owner domain before creating files/folders.
- No new legacy roots or ambiguous sink files/folders.
- New `shared/` items require real cross-domain reuse justification.

3. Incoming handoff merge protocol:
- Backup first: `backups/refactor-batches/<timestamp>-<scope>/`.
- Map every inbound file/folder to canonical destination before merge.
- Use compatibility shims for moved active paths until import-zero proof.
- No destructive delete in same batch as move/rewire.

4. Mandatory verification gates:
- Frontend touched -> `dart analyze` touched scope.
- Backend touched -> `npm.cmd run build` in `backend/`.
- Route/deeplink-affecting changes -> route smoke checks.

5. Mandatory audit trail:
- Update root `log.md` with moved files, shim status, verifications, risks.
- Keep handoff backups/handoff folders until explicit approval to delete.

6. Auto-reject merge if any true:
- analyze/build failures,
- unresolved ownership ambiguity,
- schema/DTO drift vs `current schema.md`,
- route regression without safe fallback.
