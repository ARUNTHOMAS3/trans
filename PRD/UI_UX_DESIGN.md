# 🎨 UI/UX Design Document - Zerpai ERP

**Last Updated:** 2026-05-15 13:20:00 IST
**Version:** 1.0 (Lifecycle Aligned)

---

## 1. Design Principles
- **Minimalism:** Clean, white surfaces with clear typography (Inter/Roboto).
- **Accessibility:** AA standard contrast, keyboard-first navigation.
- **Responsiveness:** Flutter-based adaptive layouts for Web/Mobile.
- **Consistency:** Unified tokens for all modals, inputs, and tables.

---

## 2. Branding & Design Language
- **Colors:** 
    - Pure White (`#FFFFFF`) for all surfaces.
    - Zoho Blue (`#0088FF`) for primary accents/focus.
    - Success Green (`#28A745`) for primary actions.
- **Typography:** Sentence case for labels/instructions; Title Case for actions/titles.
- **Icons:** Lucide (95%) and FontAwesome (brands).

---

## 3. Design System Components
- **Buttons:** 4px radius, Title Case labels.
- **Inputs:** 160px fixed label width, white fill, light-gray border.
- **Tables:** Right-aligned numeric data, high-density row heights (32-40px).
- **Modals:** Pure white background, elevation 8, centralized placement.

---

## 4. Navigation Structure
- **Sidebar:** Dark theme, accordion pattern, active green indicator.
- **Header:** Breadcrumbs, Organization Switcher, Quick Create (+).
- **Routing:** Deep-linkable GoRouter routes for every major view.

---

## 5. User Journey & Interactions
- **Billing:** Barcode scan -> Auto-populate item -> Check Price List -> Generate Invoice.
- **Transfer:** Request -> Dispatch -> In-Transit -> Receive.
- **Onboarding:** Org -> Branch -> Warehouse -> Bin.

---

## 6. UX Rules & Standards
- **Validation:** Red border + helper text on error.
- **Loading:** Skeleton screens for tables; shimmer for cards.
- **Empty States:** Descriptive text + single CTA button.
- **One-Line Principle:** Destinations (Title Case), Instructions (Sentence case), Actions (Title Case).

---

## 7. Accessibility & Edge Cases
- **Accessibility:** Full keyboard support (`Tab`, `Esc`, `Enter`).
- **No Internet:** "Offline Mode" banner; persistent draft storage in Hive.
- **Large Data:** Virtual scrolling for lists exceeding 1000 items.
- **Duplicate Prevention:** Immediate button disabling on click.

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
