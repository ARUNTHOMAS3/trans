# 📋 PRD: Price Lists & Branch Price Lists

**Last Updated:** 2026-05-15 12:45:00 IST
**Status:** Integrated
**Owner:** Product Team

---

## 1. Overview

The Price List module enables businesses to manage custom pricing strategies beyond the standard product rate. It supports both global price lists (managed by HO) and branch-specific price lists to handle regional pricing, seasonal discounts, and customer-specific rates.

## 2. Modules

### 2.1 Price List (Global/HO)
- **Purpose:** Define standard pricing rules and markup/markdown percentages.
- **Access:** Head Office (HO) only.
- **Features:**
  - Create/Edit/Delete Price Lists.
  - Type: Percentage (Markup/Markdown) or Individual Item Pricing.
  - Rounding rules for automated calculations.

### 2.2 Branch Price List
- **Purpose:** Assign specific price lists to branches or override HO price lists for specific locations.
- **Access:** HO (for assignment) and Branch (for viewing/usage).
- **Features:**
  - Map Price Lists to specific Branches.
  - Set effective date ranges for branch-level pricing.
  - Priority logic: Branch Price List > Customer Price List > Global Price List > Base Rate.

## 3. Functional Requirements

### 3.1 Price List Creation
- **Name:** Unique identifier for the price list.
- **Description:** Internal notes on the purpose.
- **Type:**
  - **All Items:** Apply a flat percentage markup/markdown to all products.
  - **Individual Items:** Set specific rates for specific items.
- **Currency:** Defaults to base currency (INR).
- **Rounding:** No rounding, Round to nearest integer, etc.

### 3.2 Branch Assignment
- Select one or more branches to apply the price list.
- Set "Active" status and date ranges.

## 4. User Interface (UI/UX)

Following the **Zoho Standard** and **PRD Section 14** rules:
- **Table View:** Full-width data table listing all price lists.
- **Master-Detail:** Clicking a price list opens a split view (30/70) showing the list of items/rules on the right.
- **Form:** Horizontal labels, fixed width (160px), white background (`#FFFFFF`), Inter font.
- **Sidebar:** Price Lists appears as a main module.

## 5. Technical Requirements

### 5.1 Backend Schema (Additions)
The following tables are required (Prefix: `inventory_` per PRD naming convention):

- `inventory_price_lists`: Stores the header info.
- `inventory_price_list_items`: Stores individual item overrides.
- `inventory_branch_price_list_mapping`: Links price lists to branches.

### 5.2 API Endpoints
- `GET /inventory/price-lists`
- `POST /inventory/price-lists`
- `PUT /inventory/price-lists/:id`
- `DELETE /inventory/price-lists/:id`
- `GET /inventory/branch-price-lists`

## 6. Business Logic & Workflows

### 6.1 Pricing Resolution Logic
When an item is added to a Sales Order/Invoice:
1. Check if a **Branch Price List** is active for the current branch and item.
2. If not, check if the **Customer** has an assigned Price List.
3. If not, check if a **Global Price List** is marked as default.
4. Fallback to **Product Base Rate**.

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
