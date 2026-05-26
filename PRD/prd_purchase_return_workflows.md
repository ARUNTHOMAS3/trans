# Purchase Return & Receiving Workflows (PRD)

**Last Updated:** 2026-05-15 13:00:00 IST

## 1. Overview
This document defines the workflows for Purchase Returns from Outlets to HO and the process of receiving items at Outlets from HO.

## 2. Purchase Return & Item Receiving Workflows
Handles return requests, credit limits, and discrepancy management during receiving.

### 2.1 Mermaid Diagram
```mermaid
graph TD
    QOFQyEPfTHBc["Purchase Return"] --> 0OFQFdij62qN["Vendor Credits"]
    zWTQQ8IzZZZF["HO accepts request?"] --> |No| zWTQoZlk8be4["HO rejects request"]
    bJFQxMY2N2Qt["Sales Return"] --> |Partially accepting| CQFQcNGXrKwV["Reject items row-wise"]
    K.EQ3yqVcMNH["Outlet accepts receipt"] --> K.EQUvvooo8_["Item details auto-fill into Purchase Receives"]
    bJFQxMY2N2Qt["Sales Return"] --> lMFQBYxW9C25["Sales Return Receives"]
    zWTQnPA~MIHh["HO converts Sales Return to Return Receives"] --> zWTQgMQunYBq["HO converts Return Receives to Vendor Credits"]
    zWTQrBEYuwQY["Cancel draft"] --> zWTQYyYVD5Ho["End"]
    UHFQof4hOBiH["Purchase Return Request from Outlet"] --> eIFQ49.ssIx7["Sales Return Request in HO"]
    CQFQcNGXrKwV["Reject items row-wise"] --> |Reship items in next courier| 3IFQScru5n8W["End"]
    K.EQUHvd7D93["Outlet receives items from HO"] --> K.EQEUk-Yq35["System sends notification to outlet"]
    eIFQ49.ssIx7["Sales Return Request in HO"] --> 3IFQScru5n8W["End"]
    K.EQJQCCbIi_["Any issues? Damage / Shortage"] --> |No issues| L.EQZOMLViIz["Save receive"]
    CQFQcNGXrKwV["Reject items row-wise"] --> lMFQBYxW9C25["Sales Return Receives"]
    L.EQbHlIhnJY["Convert receive into bill"] --> |Issues marked| L.EQJNOWDMfV["Create Purchase Return Request to HO instantly"]
    L.EQbHlIhnJY["Convert receive into bill"] --> |No issues| L.EQj4MPPuSB["End"]
    K.EQUvvooo8_["Item details auto-fill into Purchase Receives"] --> K.EQKUT6YcCD["Outlet checks received items"]
    K.EQKUT6YcCD["Outlet checks received items"] --> K.EQJQCCbIi_["Any issues? Damage / Shortage"]
    L.EQZOMLViIz["Save receive"] --> L.EQbHlIhnJY["Convert receive into bill"]
    zWTQgMQunYBq["HO converts Return Receives to Vendor Credits"] --> zWTQYyYVD5Ho["End"]
    KOFQ_CHsuzzB["Credit Note"] --> QOFQyEPfTHBc["Purchase Return"]
    zWTQ2p1dL_Kp["Outlet submits Purchase Return Request to HO"] --> zWTQ9boJlH5x["HO reviews Purchase Return Request"]
    eIFQ49.ssIx7["Sales Return Request in HO"] --> |Fully accepting| bJFQxMY2N2Qt["Sales Return"]
    L.EQcdcNIsd-["Mark issues: damage / shortage"] --> L.EQZOMLViIz["Save receive"]
    K.EQJQCCbIi_["Any issues? Damage / Shortage"] --> |Issues found| L.EQcdcNIsd-["Mark issues: damage / shortage"]
    zWTQ35Hkmbe3["HO converts Purchase Return Request to Sales Return"] --> zWTQnPA~MIHh["HO converts Sales Return to Return Receives"]
    zWTQa6v6XmlM["Start"] --> zWTQ1ndjhdOj["Outlet creates Purchase Return Request"]
    zWTQ1ndjhdOj["Outlet creates Purchase Return Request"] --> zWTQBNiS.Ds-["Balance or credit limit issues?"]
    zWTQBNiS.Ds-["Balance or credit limit issues?"] --> |No| zWTQ2p1dL_Kp["Outlet submits Purchase Return Request to HO"]
    zWTQLEAtB1A1["Outlet cannot submit request"] --> zWTQrBEYuwQY["Cancel draft"]
    zWTQnnJbnlZw["Wait for clearance/restoration"] --> zWTQ4C4rPe7c["Recheck account status"]
    zWTQ9boJlH5x["HO reviews Purchase Return Request"] --> zWTQQ8IzZZZF["HO accepts request?"]
    L.EQJNOWDMfV["Create Purchase Return Request to HO instantly"] --> L.EQj4MPPuSB["End"]
    L.EQJNOWDMfV["Create Purchase Return Request to HO instantly"] --> |If shortage item in HO| CQFQcNGXrKwV["Reject items row-wise"]
    zWTQBNiS.Ds-["Balance or credit limit issues?"] --> |Yes| zWTQLEAtB1A1["Outlet cannot submit request"]
    K.EQEUk-Yq35["System sends notification to outlet"] --> K.EQ3yqVcMNH["Outlet accepts receipt"]
    zWTQQ8IzZZZF["HO accepts request?"] --> |Yes| zWTQ35Hkmbe3["HO converts Purchase Return Request to Sales Return"]
    zWTQLEAtB1A1["Outlet cannot submit request"] --> zWTQnnJbnlZw["Wait for clearance/restoration"]
    lMFQBYxW9C25["Sales Return Receives"] --> KOFQ_CHsuzzB["Credit Note"]
    K.EQF7Vx9ytu["Start"] --> K.EQUHvd7D93["Outlet receives items from HO"]
    zWTQoZlk8be4["HO rejects request"] --> zWTQYyYVD5Ho["End"]
    zWTQ4C4rPe7c["Recheck account status"] --> zWTQBNiS.Ds-["Balance or credit limit issues?"]
```

### 2.2 Procedural Steps
- **Return Initiation:** Outlet creates PR request -> System checks outstanding balance/credit limits.
- **HO Approval:** HO reviews -> Fully accepts, partially accepts (rejecting specific items), or rejects.
- **Sync:** Accepted items convert to Sales Return (HO) -> Return Receives -> Vendor Credits.
- **Receiving Flow:** Outlet receives items from HO -> Notification sent -> Outlet accepts receipt.
- **Discrepancy Check:** Outlet checks for damage/shortage. If issues found, they are marked.
- **Finalization:** Save receive -> Convert to bill. Any marked issues trigger an instant PR request back to HO.

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
