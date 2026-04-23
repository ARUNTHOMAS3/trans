# Segmented Widgets

Use this reference when a widget file becomes hard to maintain.

## Segment When

- The file is roughly 1000 lines or more.
- The build method contains multiple distinct sections.
- Large private UI helpers are making the main file unreadable.

## Pattern

- Keep the main file as the state owner.
- Put section files in `presentation/sections/`.
- Use `part 'sections/<file>_<section>.dart';` in the main file.
- Use `part of '../<file>.dart';` in section files.
- Implement section builders with extensions on the widget state class.

## Keep In The Main File

- Widget and state declarations.
- Controllers and local state.
- Lifecycle methods such as `initState` and `dispose`.
- High-level orchestration in `build`.

## Keep In Section Files

- UI builder methods for logically separate blocks such as headers, primary info, address sections, footers, or tables.

## Constraint

- Do not change business logic while extracting sections. This is a structure refactor, not a behavior rewrite.
