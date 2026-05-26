# Return Operational Workflows (PRD)

**Last Updated:** 2026-05-15 13:00:00 IST

## 1. Overview
This document defines the process flows for Sales Returns and Purchase Returns in Zerpai ERP, including damaged goods handling and vendor credit conversion.

## 2. System Return Workflows
Comprehensive flow for HO and Outlet returns.

### 2.1 Mermaid Diagram
```mermaid
graph TD
    tepPD0~uL5wk["Customer Reports Damaged Goods"] --> tepPJ-hPq8xg["No Goods Returned to HO Inventory"]
    YepPVw3~WzcG["Receive Credit Note from Vendor"] --> YepPE~Q8as9B["Convert Purchase Return to Vendor Credits"]
    mhoPmZ328~hW["Start"] --> mhoPQh_ebcd8["Sales Return"]
    XepPybe59SGz["Start"] --> XepPNh1C_q_Y["Invoice to Customer (Outlet)"]
    YepPE~Q8as9B["Convert Purchase Return to Vendor Credits"] --> XepPoGl2XndD["End"]
    XepPCYe_1_37["Create Purchase Return Request to HO"] --> XepPRHgGh5LW["HO Accepts Return Request?"]
    XepPxUMeUD1H["Customer Returns Item to Outlet"] --> XepPpMQM.oS6["Item Condition at Outlet?"]
    XepPpMQM.oS6["Item Condition at Outlet?"] --> |Non-damaged or non-expired| XepP4Hv5LgtQ["Keep in Outlet Inventory"]
    YepPMyyY4m04["Create Sales Return at HO"] --> YepPko0wTCoC["Convert to Return Receives"]
    j90PP5DJ4HwA["Purchase return in outlet convert into damage (inventory adjustment)"] --> XepPoGl2XndD["End"]
    tepPN3Sxcsju["Generate Sales Return"] --> tepP0m.J2oqK["Create Credit Note for Customer"]
    tepPJ-hPq8xg["No Goods Returned to HO Inventory"] --> tepPrzLIA8Fz["Outlet Raises PR Request to HO"]
    tepP0m.J2oqK["Create Credit Note for Customer"] --> tepPfXglb9tM["End"]
    tepPU4Z.ujct["Courier from HO Arrives Damaged"] --> tepPD0~uL5wk["Customer Reports Damaged Goods"]
    YepPiG18XlSd["Create Purchase Return to Vendor"] --> YepPVw3~WzcG["Receive Credit Note from Vendor"]
    tepPN-soAb8I["HO Accepts PO Request?"] --> |Accept| tepPN3Sxcsju["Generate Sales Return"]
    mhoPq.cVCx7j["Transfer Orders"] --> mhoP2m~n-PrC["End"]
    XepPpMQM.oS6["Item Condition at Outlet?"] --> |Damaged or expired| XepPmVfbuO1c["Return Item to HO"]
    XepPmVfbuO1c["Return Item to HO"] --> XepPCYe_1_37["Create Purchase Return Request to HO"]
    YepPvts8soGZ["Create Credit Note at HO"] --> |Non-damaged or non-expired goods| YepPbRL6uvL1["Create Transfer Order to Main Warehouse"]
    XepPNh1C_q_Y["Invoice to Customer (Outlet)"] --> XepPxUMeUD1H["Customer Returns Item to Outlet"]
    mhoPgJnvNZNW["Purchase Return"] --> mhoP~PNQouY5["Vendor Credits"]
    mhoPQh_ebcd8["Sales Return"] --> mhoPTpsPjPxH["Sales Return Receives"]
    mhoP~Cpbogpi["Credit Note"] --> |Non-expired items| mhoPq.cVCx7j["Transfer Orders"]
    YepPbRL6uvL1["Create Transfer Order to Main Warehouse"] --> YepP1~nz52~_["Store as Live Ready Items in Main Warehouse"]
    YepPko0wTCoC["Convert to Return Receives"] --> YepPvts8soGZ["Create Credit Note at HO"]
    XepPRHgGh5LW["HO Accepts Return Request?"] --> |Reject| XepPoGl2XndD["End"]
    XepPRHgGh5LW["HO Accepts Return Request?"] --> |Accept| YepPMyyY4m04["Create Sales Return at HO"]
    YepPvts8soGZ["Create Credit Note at HO"] --> |Damaged or expired goods| YepPiG18XlSd["Create Purchase Return to Vendor"]
    mhoP~Cpbogpi["Credit Note"] --> |Expired or damaged items| mhoPgJnvNZNW["Purchase Return"]
    YepP1~nz52~_["Store as Live Ready Items in Main Warehouse"] --> XepPoGl2XndD["End"]
    XepP4Hv5LgtQ["Keep in Outlet Inventory"] --> j90PP5DJ4HwA["Purchase return in outlet convert into damage (inventory adjustment)"]
    tepPrzLIA8Fz["Outlet Raises PR Request to HO"] --> tepPN-soAb8I["HO Accepts PO Request?"]
    tepPUi-DjrV4["Start"] --> tepPU4Z.ujct["Courier from HO Arrives Damaged"]
    mhoPTpsPjPxH["Sales Return Receives"] --> mhoP~Cpbogpi["Credit Note"]
    mhoP~PNQouY5["Vendor Credits"] --> mhoP2m~n-PrC["End"]
    tepPN-soAb8I["HO Accepts PO Request?"] --> |Reject| tepPfXglb9tM["End"]
```

### 2.2 Procedural Steps
- **Customer Return:** Outlet receives item -> Checks condition.
- **Good Condition:** Keep in outlet inventory -> Adjust as needed.
- **Damaged/Expired:** Return to HO -> HO reviews.
- **HO Action:** HO accepts -> Generates Sales Return -> Credit Note.
- **Vendor Sync:** If HO marks as vendor return -> Purchase Return to Vendor -> Vendor Credit Note.
- **Inventory Update:** Transfer orders used to move ready items back to main warehouse.

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
