# 🎨 UI/UX Design System - Zerpai ERP

**Last Updated:** 2026-05-15 12:45:00 IST
**Version:** 2.0 (Premium Enterprise Aesthetics)

---

## 1. Design Philosophy

Zerpai ERP adheres to a **Premium Enterprise** aesthetic, characterized by high data density, clean typography, and a "Zentific" approach to white space. It is heavily inspired by Zoho Inventory's efficiency and visual clarity.

### 1.1 Core Principles
- **Clarity Over Complexity**: Avoid visual noise. Focus on the data.
- **High Density**: Optimize for power users who need to see maximum information with minimal scrolling.
- **Pure White Surfaces**: All floating surfaces (modals, menus, popovers) MUST be pure white `#FFFFFF`.
- **Keyboard-First**: Navigation and data entry should be possible without a mouse.

---

## 2. Global Aesthetics

### 2.1 Color Palette (Locked)
| Purpose | Token | HEX |
| :--- | :--- | :--- |
| **Primary Action** | `primaryBlue` | `#3B7CFF` |
| **Success/Secondary** | `accentGreen` | `#27C59A` |
| **Sidebar BG** | `sidebarColor` | `#1F2633` |
| **App Background** | `backgroundColor` | `#FFFFFF` |
| **Borders** | `borderColor` | `#D3D9E3` |
| **Text Primary** | `textPrimary` | `#1F2933` |
| **Text Secondary** | `textSecondary` | `#6B7280` |

### 2.2 Typography
- **Primary Font**: `Inter` (Variable).
- **Page Titles**: 18px, Semi-Bold (600).
- **Labels/Data**: 13px, Regular (400) or Medium (500).
- **Table Headers**: 12px, Bold (700), All Caps (Optional).

---

## 3. UI Components

### 3.1 Buttons
- **Primary**: Solid blue or green, `BorderRadius.circular(4)`.
- **Secondary**: Outlined or gray background.
- **Action Buttons**: Icon + Label (e.g., "Add New").
- **Split Buttons**: Primary action with a dropdown for variations.

### 3.2 Form Inputs
- **CustomTextField**: Standardized padding, borders, and hint styles.
- **FormDropdown**: Searchable overlay with rich row data.
- **ZerpaiDatePicker**: Anchored popover with clean calendar grid.
- **Numeric Restriction**: Fields for Quantity/Rate must block non-numeric input.

### 3.3 Tables (The Heart of the App)
- **ZDataTableShell**: Horizontal scrolling, resizable columns, sticky headers.
- **Density**: 32px-40px row height.
- **Actions**: Row-level actions in a trailing `MenuAnchor`.

### 3.4 Feedback & Overlays
- **ZerpaiToast**: Non-intrusive status feedback.
- **ZerpaiConfirmationDialog**: Consistent "Warning/Danger" styling for destructive actions.
- **ZTooltip**: Max-width 220px, Lucide help icon.

---

## 4. UX Patterns

### 4.1 Master-Detail View
- Clicking a table row splits the screen: List on the left (30-40%), Details on the right (60-70%).
- Provides context without navigating away from the list.

### 4.2 Sidebar Navigation
- Collapsible hierarchy.
- Parent items expand on click.
- Active states indicated by high-contrast indicators.

### 4.3 Form Layouts
- Horizontal labels (Label on left, Input on right).
- Grouping of related fields into logical sections.

---

## 5. Responsive Foundation

- **Breakpoints**: 600px (Mobile), 1024px (Tablet), 1440px (Desktop).
- **Behavior**: Sidebar hides on mobile; tables collapse into cards or scroll horizontally.
- **Shell Metrics**: The app shell calculates available space dynamically to adjust sidebar/content ratios.

---

## 6. Accessibility & Compliance

- **Contrast**: Maintain a minimum ratio of 4.5:1 for text.
- **Focus Indicators**: Visible focus rings for all interactive elements.
- **ARIA**: Semantic HTML tags in Flutter Web where possible.

---

## 7. Hard Rules (Design Governance)

1. **No Violet/Purple**: Strict ban on violet hues unless branded.
2. **Title Case Titles**: Screen titles must be Title Case.
3. **Sentence Case Labels**: Form labels and hints must be Sentence case.
4. **Pure White Overlays**: No tinted material surfaces for popups.
5. **Rounded Circular(4)**: All buttons and inputs must use 4px radius.

---

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
