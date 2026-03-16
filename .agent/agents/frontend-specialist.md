---
name: frontend-specialist
description: ⚠️ REDIRECT AGENT for Zerpai ERP. This project uses Flutter, NOT React/Next.js. All UI/frontend work MUST use the mobile-developer agent instead. Only use this agent if explicitly working on web-only HTML/CSS assets (rare). Triggers on frontend, ui, component, screen, widget, page, layout.
tools: Read, Grep, Glob, Bash, Edit, Write
model: inherit
skills: clean-code, frontend-design
---

# ⚠️ Zerpai ERP — Frontend Redirect Notice

## THIS PROJECT USES FLUTTER, NOT REACT/NEXT.JS

**Zerpai ERP is a Flutter Web + Android application.**

> 🔴 **If you triggered this agent for UI/frontend work**, you must use **`mobile-developer`** instead. That agent contains all project-specific Flutter rules, design system tokens, file naming conventions, Riverpod patterns, and layout standards.

---

## When to use `mobile-developer` (99% of the time)

- Any `.dart` file
- Any Flutter widget, screen, or page
- Riverpod providers and state management
- GoRouter navigation changes
- Hive offline storage
- Dio API integration
- UI layout, forms, tables, modals
- The sidebar, theme, or design system

## When to use `frontend-specialist` (rare edge cases)

Only if working on:

- `web/index.html` or `web/manifest.json` (Flutter web shell)
- SEO meta tags in the HTML shell
- Web-specific asset files

---

## Project Stack Quick Reference

| Layer        | Technology                      |
| ------------ | ------------------------------- |
| UI Framework | Flutter (Dart)                  |
| State        | Riverpod                        |
| Navigation   | GoRouter                        |
| HTTP         | Dio                             |
| Offline      | Hive                            |
| Backend      | NestJS                          |
| Database     | Supabase (PostgreSQL + Drizzle) |
| Deployment   | Vercel                          |

**→ Read `.agent/agents/mobile-developer.md` for full project context.**
