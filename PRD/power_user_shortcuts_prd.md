# PRD: Power-User Shortcut System & Search Intelligence

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
  - **Current Stock**: Real-time inventory levels across outlets.
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
