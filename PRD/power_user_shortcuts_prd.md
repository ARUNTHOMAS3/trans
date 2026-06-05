# PRD: Power-User Features & Keyboard Shortcuts PRD
**Last Updated: 2026-04-20 12:46:08**

## Overview
This document outlines the implementation of productivity-focused shortcuts and intelligent search features within the Zerpai ERP system. These enhancements are designed to improve efficiency for high-frequency users (Accountants, Inventory Managers).

## 1. Shortcut Key System
A global `ShortcutHandler` has been implemented to provide consistent keyboard navigation across the application.

### Key Mappings
| Shortcut | Action | Scope |
| :--- | :--- | :--- |
| `Ctrl + S` | **Save as Draft** | Form screens (Manual Journal, etc.) |
| `Ctrl + Enter` | **Save & Publish** / **Post** | Form screens (Manual Journal, etc.) |
| `Esc` | **Discard / Cancel** | All screens (with Discard Guard) |
| `/` (Slash) | **Focus Search** | Screens with a primary search bar |

### Discard Guard Implementation
When `Esc` is pressed on a modified form (`isDirty = true`):
- A standard confirmation dialog is displayed: *"Discard unsaved changes?"*
- Prevents accidental loss of complex data (e.g., multi-line journals).

## 2. Search Intelligence (QuickStats)
To reduce navigation fatigue, search results and item lists now support high-speed data extraction on hover.

### Item QuickStats Overlay
- **Trigger**: Hovering over an item row in the report or search results.
- **Delay**: 600ms (debounced) to prevent flickering during rapid scrolling.
- **Data Points**:
  - **Current Stock**: Real-time inventory levels across branches.
  - **Last Purchase Price**: The cost price from the most recent procurement.
- **Performance**:
  - Implemented as a dedicated backend endpoint (`GET /api/v1/products/:id/quick-stats`).
  - Frontend utilizes a local LRU-style cache (`_statsCache`) to eliminate redundant API calls for recently viewed items.

## 3. UI/UX Visibility
Shortcuts are made discoverable through updated tooltips:
- **Save Button**: Tooltip changed to `Save (Ctrl+S)`
- **New Button**: Tooltip changed to `New (/)` (where search/create integration exists)
- **Publish Button**: Tooltip changed to `Publish (Ctrl+Enter)`

## 4. Technical Implementation Notes
- **Backend**: NestJS + Drizzle ORM for sub-10ms response times on QuickStats.
- **Frontend**: Flutter `CallbackShortcuts` + `OverlayEntry` + `CompositedTransformFollower`.
- **State Management**: Riverpod `ItemsController` manages the fetching and caching logic.

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
