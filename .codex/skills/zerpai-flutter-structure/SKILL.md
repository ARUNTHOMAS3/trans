---
name: zerpai-flutter-structure
description: Place, name, route, and segment Flutter code according to the Zerpai ERP folder structure rules. Use when creating, moving, renaming, or reviewing Dart files under `lib/` or `test/`, especially for new modules, widgets, providers, repositories, routes, and large form screens.
---

# Zerpai Flutter Structure

Use this skill to decide where Dart code belongs before editing. The main failure mode in this repo is correct logic placed in the wrong folder or named with the wrong pattern.

## Workflow

1. Read `references/placement-rules.md` to classify the file as `core`, `shared`, or a feature module.
2. Pick the exact module and sub-module path before writing code.
3. Name files in strict `snake_case` using the Zerpai module pattern.
4. Mirror new Flutter files in `test/` when the change needs coverage.
5. Read `references/segmented-widgets.md` when a screen or form is large enough to split into `part` files.

## Rules

- `lib/core/` is for app infrastructure, layout, routing, theme, core widgets, utilities, API, and storage.
- `lib/shared/` is for shared providers and models only.
- `lib/modules/<module>/` is for business features and should contain `models/`, `providers/`, `repositories/`, optional `controllers/`, and `presentation/`.
- Main business modules must match the PRD sidebar hierarchy.
- Flutter routes must reflect the module hierarchy and stay centralized through GoRouter.
- New modules and major sub-screens must include deep-linkable create/detail/edit/history/report-style routes where applicable so direct URLs and refresh preserve context.
- Test paths should mirror the structure of `lib/`.

## Naming

- Use `snake_case` only.
- For feature files, prefer `<module>_<submodule>_<entity_or_page>.dart`.
- For screens, prefer suffixes such as `_overview.dart`, `_creation.dart`, `_edit.dart`, and `_detail.dart`.
- For module widgets, keep them in `presentation/widgets/` and use the same prefixing scheme.

## Reference Loading

- Use `references/placement-rules.md` for folder decisions, route shape, and naming patterns.
- Use `references/segmented-widgets.md` for large widget sectioning and `part of` rules.
