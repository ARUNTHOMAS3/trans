# Zerpai ERP — Agent Architecture

> Antigravity Kit customized for Zerpai ERP (Flutter Web + Android + NestJS + Supabase)

## 🏗️ Zerpai ERP Stack

| Layer          | Technology                     |
| -------------- | ------------------------------ |
| **Frontend**   | Flutter (Dart) — Web + Android |
| **State**      | Riverpod                       |
| **Navigation** | GoRouter                       |
| **HTTP**       | Dio                            |
| **Offline**    | Hive                           |
| **Backend**    | NestJS (TypeScript)            |
| **ORM**        | Drizzle ORM                    |
| **Database**   | Supabase (PostgreSQL)          |
| **Deployment** | Vercel                         |
| **Storage**    | Cloudflare R2                  |

## UI Surface Rule

- For Zerpai UI, dialogs, popup menus, dropdown overlays, date pickers, popovers, and similar floating surfaces must default to pure white `#FFFFFF`.
- Do not rely on inherited tinted Material surfaces for these components unless a task explicitly requires an exception.

## Shared Date Picker Rule

- Use `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` as the standard reusable date picker for anchored business date inputs.
- Treat new raw `showDatePicker(...)` usage as an exception that must be justified, not the default pattern.

## Dropdown Rule

- All form-input dropdowns must use `FormDropdown<T>` from `lib/shared/widgets/inputs/dropdown_input.dart`.
- Never use `DropdownButtonFormField` or `DropdownButton`. `FormDropdown` provides built-in search, correct overlay styling, and consistent Zerpai visual language.

## Tooltip Rule

- Always use `ZTooltip` from `lib/shared/widgets/inputs/z_tooltip.dart`. Never use Flutter's built-in `Tooltip` widget.
- `ZTooltip` enforces a 220 px max-width so text wraps compactly. Trigger icon is `LucideIcons.helpCircle` at 14–15 px. Copy must be ≤ 2 short sentences.

## Deep-Linking Rule

- Every screen, sub-screen, tab, and significant dialog state must be addressable via a named GoRouter route.
- Routes must preserve path/query parameters so refresh, direct URL, and back-navigation restore full context.
- Never use `Navigator.push` — always navigate through GoRouter (`context.go`, `context.push`, `context.goNamed`).

## Global Settings Rules

- Prefer real DB-backed runtime data wherever a schema-backed source exists; do not normalize dummy/demo values into production paths.
- Keep empty states and error states explicit instead of masking failures with fabricated business values.
- Resolve master defaults from DB-backed rows where schema-backed master tables exist.
- Centralize reusable control styling and behavior instead of duplicating ERP patterns per screen.
- Use the shared responsive Flutter foundation for web layouts: global breakpoints, shared responsive table shells, shared responsive form rows/grids, shared responsive dialog width rules, and sidebar-aware shell/content metrics.
- New modules and major sub-screens must be deep-linkable through GoRouter so refresh, direct URLs, and browser navigation preserve context.
- Keep warehouse masters, storage/location masters, accounting stock, and physical stock as separate concepts.
- Keep save/create buttons, cancel/secondary actions, upload affordances, and border/divider treatments on centralized theme rules rather than screen-local color choices.

## 🚦 Agent Routing Quick Reference

| Task                      | Use Agent            |
| ------------------------- | -------------------- |
| Any Flutter/Dart UI       | `mobile-developer`   |
| NestJS API/service        | `backend-specialist` |
| Schema/Drizzle/migrations | `database-architect` |
| Bug investigation         | `debugger`           |
| Security audit            | `security-auditor`   |
| Multi-domain tasks        | `orchestrator`       |
| Task planning             | `project-planner`    |

> ⚠️ `frontend-specialist` redirects to `mobile-developer` for this project.

---

## 📋 Overview

Antigravity Kit is a modular system consisting of:

- **20 Specialist Agents** - Role-based AI personas
- **36 Skills** - Domain-specific knowledge modules
- **11 Workflows** - Slash command procedures

---

## 🏗️ Directory Structure

```plaintext
.agent/
├── ARCHITECTURE.md          # This file
├── agents/                  # 20 Specialist Agents
├── skills/                  # 36 Skills
├── workflows/               # 11 Slash Commands
├── rules/                   # Global Rules
└── scripts/                 # Master Validation Scripts
```

---

## 🤖 Agents (20)

Specialist AI personas for different domains.

| Agent                   | Focus                          | Zerpai Context                                          |
| ----------------------- | ------------------------------ | ------------------------------------------------------- |
| `mobile-developer`      | **PRIMARY UI agent**           | Flutter/Dart, Riverpod, GoRouter, Hive, Dio, PRD themes |
| `backend-specialist`    | NestJS API                     | NestJS, Drizzle ORM, Supabase, multi-tenancy headers    |
| `database-architect`    | Schema, Drizzle migrations     | Supabase PostgreSQL, Drizzle Kit, PRD schema snapshots  |
| `orchestrator`          | Multi-agent coordination       | Parallel agents, synthesis                              |
| `project-planner`       | Discovery, task planning       | Brainstorming, plan-writing, architecture               |
| `frontend-specialist`   | ⚠️ REDIRECT → mobile-developer | Not for this Flutter project                            |
| `debugger`              | Root cause analysis            | Systematic debugging for Flutter + NestJS               |
| `security-auditor`      | Security compliance            | Vulnerability scanning, OWASP                           |
| `test-engineer`         | Testing strategies             | Flutter tests, NestJS unit tests                        |
| `devops-engineer`       | CI/CD, Vercel deployment       | Vercel config, deployment procedures                    |
| `performance-optimizer` | Speed optimization             | Flutter rendering, API performance                      |
| `documentation-writer`  | Docs (explicit only)           | Only when explicitly requested                          |
| `code-archaeologist`    | Legacy code, refactoring       | Clean-code, code-review                                 |
| `explorer-agent`        | Codebase analysis              | Read-only discovery                                     |

---

## 🧩 Skills (36)

Modular knowledge domains that agents can load on-demand. based on task context.

### Frontend & UI

| Skill                   | Description                                                           |
| ----------------------- | --------------------------------------------------------------------- |
| `react-best-practices`  | React & Next.js performance optimization (Vercel - 57 rules)          |
| `web-design-guidelines` | Web UI audit - 100+ rules for accessibility, UX, performance (Vercel) |
| `tailwind-patterns`     | Tailwind CSS v4 utilities                                             |
| `frontend-design`       | UI/UX patterns, design systems                                        |
| `ui-ux-pro-max`         | 50 styles, 21 palettes, 50 fonts                                      |

### Backend & API

| Skill                   | Description                    |
| ----------------------- | ------------------------------ |
| `api-patterns`          | REST, GraphQL, tRPC            |
| `nestjs-expert`         | NestJS modules, DI, decorators |
| `nodejs-best-practices` | Node.js async, modules         |
| `python-patterns`       | Python standards, FastAPI      |

### Database

| Skill             | Description                 |
| ----------------- | --------------------------- |
| `database-design` | Schema design, optimization |
| `prisma-expert`   | Prisma ORM, migrations      |

### TypeScript/JavaScript

| Skill               | Description                         |
| ------------------- | ----------------------------------- |
| `typescript-expert` | Type-level programming, performance |

### Cloud & Infrastructure

| Skill                   | Description               |
| ----------------------- | ------------------------- |
| `docker-expert`         | Containerization, Compose |
| `deployment-procedures` | CI/CD, deploy workflows   |
| `server-management`     | Infrastructure management |

### Testing & Quality

| Skill                   | Description              |
| ----------------------- | ------------------------ |
| `testing-patterns`      | Jest, Vitest, strategies |
| `webapp-testing`        | E2E, Playwright          |
| `tdd-workflow`          | Test-driven development  |
| `code-review-checklist` | Code review standards    |
| `lint-and-validate`     | Linting, validation      |

### Security

| Skill                   | Description              |
| ----------------------- | ------------------------ |
| `vulnerability-scanner` | Security auditing, OWASP |
| `red-team-tactics`      | Offensive security       |

### Architecture & Planning

| Skill           | Description                |
| --------------- | -------------------------- |
| `app-builder`   | Full-stack app scaffolding |
| `architecture`  | System design patterns     |
| `plan-writing`  | Task planning, breakdown   |
| `brainstorming` | Socratic questioning       |

### Mobile

| Skill           | Description           |
| --------------- | --------------------- |
| `mobile-design` | Mobile UI/UX patterns |

### Game Development

| Skill              | Description           |
| ------------------ | --------------------- |
| `game-development` | Game logic, mechanics |

### SEO & Growth

| Skill              | Description                   |
| ------------------ | ----------------------------- |
| `seo-fundamentals` | SEO, E-E-A-T, Core Web Vitals |
| `geo-fundamentals` | GenAI optimization            |

### Shell/CLI

| Skill                | Description               |
| -------------------- | ------------------------- |
| `bash-linux`         | Linux commands, scripting |
| `powershell-windows` | Windows PowerShell        |

### Other

| Skill                     | Description               |
| ------------------------- | ------------------------- |
| `clean-code`              | Coding standards (Global) |
| `behavioral-modes`        | Agent personas            |
| `parallel-agents`         | Multi-agent patterns      |
| `mcp-builder`             | Model Context Protocol    |
| `documentation-templates` | Doc formats               |
| `i18n-localization`       | Internationalization      |
| `performance-profiling`   | Web Vitals, optimization  |
| `systematic-debugging`    | Troubleshooting           |

---

## 🔄 Workflows (11)

Slash command procedures. Invoke with `/command`.

| Command          | Description              |
| ---------------- | ------------------------ |
| `/brainstorm`    | Socratic discovery       |
| `/create`        | Create new features      |
| `/debug`         | Debug issues             |
| `/deploy`        | Deploy application       |
| `/enhance`       | Improve existing code    |
| `/orchestrate`   | Multi-agent coordination |
| `/plan`          | Task breakdown           |
| `/preview`       | Preview changes          |
| `/status`        | Check project status     |
| `/test`          | Run tests                |
| `/ui-ux-pro-max` | Design with 50 styles    |

---

## 🎯 Skill Loading Protocol

```plaintext
User Request → Skill Description Match → Load SKILL.md
                                            ↓
                                    Read references/
                                            ↓
                                    Read scripts/
```

### Skill Structure

```plaintext
skill-name/
├── SKILL.md           # (Required) Metadata & instructions
├── scripts/           # (Optional) Python/Bash scripts
├── references/        # (Optional) Templates, docs
└── assets/            # (Optional) Images, logos
```

### Enhanced Skills (with scripts/references)

| Skill           | Files | Coverage                         |
| --------------- | ----- | -------------------------------- |
| `ui-ux-pro-max` | 27    | 50 styles, 21 palettes, 50 fonts |
| `app-builder`   | 20    | Full-stack scaffolding           |

---

## � Scripts (2)

Master validation scripts that orchestrate skill-level scripts.

### Master Scripts

| Script          | Purpose                                 | When to Use              |
| --------------- | --------------------------------------- | ------------------------ |
| `checklist.py`  | Priority-based validation (Core checks) | Development, pre-commit  |
| `verify_all.py` | Comprehensive verification (All checks) | Pre-deployment, releases |

### Usage

```bash
# Quick validation during development
python .agent/scripts/checklist.py .

# Full verification before deployment
python .agent/scripts/verify_all.py . --url http://localhost:3000
```

### What They Check

**checklist.py** (Core checks):

- Security (vulnerabilities, secrets)
- Code Quality (lint, types)
- Schema Validation
- Test Suite
- UX Audit
- SEO Check

**verify_all.py** (Full suite):

- Everything in checklist.py PLUS:
- Lighthouse (Core Web Vitals)
- Playwright E2E
- Bundle Analysis
- Mobile Audit
- i18n Check

For details, see [scripts/README.md](scripts/README.md)

---

## 📊 Statistics

| Metric              | Value                         |
| ------------------- | ----------------------------- |
| **Total Agents**    | 20                            |
| **Total Skills**    | 36                            |
| **Total Workflows** | 11                            |
| **Total Scripts**   | 2 (master) + 18 (skill-level) |
| **Coverage**        | ~90% web/mobile development   |

---

## 🔗 Quick Reference

| Need     | Agent                 | Skills                                |
| -------- | --------------------- | ------------------------------------- |
| Web App  | `frontend-specialist` | react-best-practices, frontend-design |
| API      | `backend-specialist`  | api-patterns, nodejs-best-practices   |
| Mobile   | `mobile-developer`    | mobile-design                         |
| Database | `database-architect`  | database-design, prisma-expert        |
| Security | `security-auditor`    | vulnerability-scanner                 |
| Testing  | `test-engineer`       | testing-patterns, webapp-testing      |
| Debug    | `debugger`            | systematic-debugging                  |
| Plan     | `project-planner`     | brainstorming, plan-writing           |
