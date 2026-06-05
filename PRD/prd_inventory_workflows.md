# Inventory & Transfer Operational Workflows (PRD)

**Last Updated:** 2026-05-15 13:00:00 IST

## 1. Overview
This document defines inventory management flows, specifically Store-to-Store (Outlet) transfers and requirement requests.

## 2. Store to Store (Outlet) Transfer Workflows
Flow for requesting products between outlets and handling HO approvals.

### 2.1 Mermaid Diagram
```mermaid
graph TD
    K5lQso8g2.27["Sales Return"] --> 45lQ0S~A2KTQ["Credit Note"]
    eqUQ2v2Z65hs["Approve request?"] --> |Entry-wise: Approve| eqUQ1gbc89XM["Raise Purchase Return Request to HO"]
    58lQEAGgJ9Wi["Invoice to Outlet A"] --> t2lQrt0JWW31["End"]
    eqUQ22vuMGcw["Auto Convert to Invoice for Outlet A"] --> eqUQu65RykJc["Dispatch Items from Outlet B"]
    eqUQcqV2-A9T["HO approves purchase return?"] --> |No| eqUQ~Oqm6XVP["Notify HO Rejection to Outlet B"]
    eqUQ~Oqm6XVP["Notify HO Rejection to Outlet B"] --> eqUQz5wCBK1F["Review Request"]
    45lQ0S~A2KTQ["Credit Note"] --> S7lQ9qo77e1i["Vendor Credit to Outlet B"]
    eqUQ-w9cWien["Convert to Vendor Credits to Outlet B"] --> dqUQ0P2PqJOE["End"]
    dqUQw4_XDqIS["Receive Items at Outlet A"] --> eqUQrquGWeAG["Complete Transfer and Settlement"]
    eqUQ1gbc89XM["Raise Purchase Return Request to HO"] --> eqUQ~ugs0EB4["Review Purchase Return Request"]
    u0lQeUXxubq0["Outlet B"] --> |Accept| R3lQHOh8igKT["Purchase return request to HO"]
    eqUQcqV2-A9T["HO approves purchase return?"] --> |Yes| eqUQZ46xTSCY["Auto Convert to Sales Return and Credit Note"]
    45lQ0S~A2KTQ["Credit Note"] --> 58lQEAGgJ9Wi["Invoice to Outlet A"]
    dqUQsr5I1gpn["Outlet A: Create Product Requirement Request"] --> dqUQgSZ_e3Vi["Send Request to Outlet B"]
    dqUQMuDqdxRe["Resend Request to Outlet B"] --> eqUQz5wCBK1F["Review Request"]
    tZlQE3HhJwN.["Outlet A"] --> |Raise Product Requirement Request| u0lQeUXxubq0["Outlet B"]
    u0lQeUXxubq0["Outlet B"] --> |Reject| t2lQrt0JWW31["End"]
    dqUQlbmVaqhg["Revise Request"] --> dqUQMuDqdxRe["Resend Request to Outlet B"]
    H2lQfUN5tBQX["Start"] --> tZlQE3HhJwN.["Outlet A"]
    eqUQz5wCBK1F["Review Request"] --> eqUQ2v2Z65hs["Approve request?"]
    dqUQhzYANH82["Close Rejected Request"] --> dqUQ0P2PqJOE["End"]
    eqUQ2v2Z65hs["Approve request?"] --> |Entry-wise: Reject| eqUQRrvR8y0j["Notify Rejection to Outlet A"]
    eqUQZ46xTSCY["Auto Convert to Sales Return and Credit Note"] --> eqUQ-w9cWien["Convert to Vendor Credits to Outlet B"]
    eqUQZ46xTSCY["Auto Convert to Sales Return and Credit Note"] --> eqUQ22vuMGcw["Auto Convert to Invoice for Outlet A"]
    eqUQDMoMANmE["Item-wise Approve?"] --> |Rejected items| eqUQRrvR8y0j["Notify Rejection to Outlet A"]
    eqUQu65RykJc["Dispatch Items from Outlet B"] --> dqUQw4_XDqIS["Receive Items at Outlet A"]
    eqUQRrvR8y0j["Notify Rejection to Outlet A"] --> eqUQvqfDrqXA["Notify Rejection to Outlet A"]
    dqUQgSZ_e3Vi["Send Request to Outlet B"] --> eqUQz5wCBK1F["Review Request"]
    c5lQTeDJyC8r["Receive PR Request"] --> K5lQso8g2.27["Sales Return"]
    eqUQ2v2Z65hs["Approve request?"] --> |Item-wise mixed| eqUQDMoMANmE["Item-wise Approve?"]
    S7lQ9qo77e1i["Vendor Credit to Outlet B"] --> t2lQrt0JWW31["End"]
    dqUQ27~QwDm7["Start"] --> dqUQsr5I1gpn["Outlet A: Create Product Requirement Request"]
    eqUQ1gbc89XM["Raise Purchase Return Request to HO"] --> eqUQu65RykJc["Dispatch Items from Outlet B"]
    eqUQDMoMANmE["Item-wise Approve?"] --> |Approved items| eqUQ1gbc89XM["Raise Purchase Return Request to HO"]
    R3lQHOh8igKT["Purchase return request to HO"] --> c5lQTeDJyC8r["Receive PR Request"]
    eqUQvqfDrqXA["Notify Rejection to Outlet A"] --> dqUQlbmVaqhg["Revise Request"]
    eqUQvqfDrqXA["Notify Rejection to Outlet A"] --> dqUQhzYANH82["Close Rejected Request"]
    eqUQrquGWeAG["Complete Transfer and Settlement"] --> dqUQ0P2PqJOE["End"]
    eqUQ~ugs0EB4["Review Purchase Return Request"] --> eqUQcqV2-A9T["HO approves purchase return?"]
```

### 2.2 Procedural Steps
- **Request:** Outlet A raises a requirement request to Outlet B.
- **Review:** Outlet B reviews and approves/rejects.
- **HO Mediation:** If approved, a Purchase Return request is sent to HO.
- **Auto-Conversion:** If HO approves, system auto-converts to Sales Return (at HO) and Credit Note, then Invoice for Outlet A.
- **Settlement:** Dispatch from B -> Receive at A -> Complete settlement.
- **Rejection Handling:** Rejections trigger notifications and allow for request revision or closure.

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
