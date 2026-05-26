# Sales Operational Workflows (PRD)

**Last Updated:** 2026-05-15 13:00:00 IST

## 1. Overview
This document defines the authoritative sales process flows for Zerpai ERP, covering standard sales, outlet-specific variations, and integrated procurement-to-sales cycles.

## 2. Standard & Outlet Sales Workflows
This workflow describes the primary path from order reception (or quotation) to delivery and e-way bill generation.

### 2.1 Mermaid Diagram
```mermaid
graph TD
    ~W_OD2oDP8k0["Create Bills"] --> ~W_OW9SAGXd2["Create Invoice"]
    .W_OE1S7P2sq["Receive Quotation Request"] --> .W_Op-X3dQ8u["Create Quotation"]
    .W_OLvgC2oKA["Check Stock Availability"] --> |In stock| .W_Obghnu2iz["Generate Picklist (Available for Sales)"]
    .W_Op-X3dQ8u["Create Quotation"] --> .W_OLt_dtnaJ["Send Quotation to Customer"]
    q18O1c2~iJhM["Check Inventory"] --> |In Stock| q18OOzoNLvz8["Generate Picklist"]
    LS_OFN9AmXF8["Check Stock Availability"] --> |Not in stock| MS_Oerlmjym7["Create Purchase Order to Vendor"]
    r18O0VU47SF6["Deliver to Customer"] --> q18O4M2VTCaM["End"]
    q18OOzoNLvz8["Generate Picklist"] --> q18Oal0ZW._1["Create Invoice"]
    q18Oal0ZW._1["Create Invoice"] --> r18O0VU47SF6["Deliver to Customer"]
    ~W_ODXONCu0t["Customer Response"] --> |Reject| .W_OvlKs_vy0["End"]
    q18OOhOIuxax["Vendor Invoice Type"] --> |Separate Bill| r18OcDXDnr8a["Enter Bill Directly"]
    .W_ONWHpX~Hn["Convert Quotation to Sales Order"] --> .W_OLvgC2oKA["Check Stock Availability"]
    MS_OzZkvHSYh["Create Picklist After Receipt"] --> MS_OhULT_jBB["Package Items"]
    MS_O3lnIzRUr["Create Picklist"] --> MS_OhULT_jBB["Package Items"]
    .W_OuODF8jDx["Package Items"] --> .W_OU7~tApuZ["Ship Items (Shipment)"]
    q18O-_HNS~zc["Start"] --> q18OTzZkWYv1["Receive Customer Order"]
    ~W_OqMF6_1y6["Receive Items (Purchase Receives)"] --> .W_Obghnu2iz["Generate Picklist (Available for Sales)"]
    .W_OLt_dtnaJ["Send Quotation to Customer"] --> ~W_ODXONCu0t["Customer Response"]
    MS_O3W~TNac.["Ship Items"] --> LS_OW4wFilvV["Create Final Invoice"]
    ~W_OW9SAGXd2["Create Invoice"] --> ~W_OZdX.~0yV["Generate E-way Bills"]
    r18O0VU47SF6["Deliver to Customer"] --> q18O4M2VTCaM["End"]
    .W_ONWHpX~Hn["Convert Quotation to Sales Order"] --> .W_OLvgC2oKA["Check Stock Availability"]
    r18OcDXDnr8a["Enter Bill Directly"] --> r18OjMJ88Qlj["Convert Bill to Invoice"]
    .W_OLvgC2oKA["Check Stock Availability"] --> |Non stocked item| .W_OeXFD5971["Create Purchase Order"]
    MS_OGeLUgaRS["Customer Pays"] --> LS_OEA6ZzQAW["Convert Retainer Invoice to Payment Made"]
    .W_OeXFD5971["Create Purchase Order"] --> ~W_OqMF6_1y6["Receive Items (Purchase Receives)"]
    MS_Oerlmjym7["Create Purchase Order to Vendor"] --> MS_ONZGQss3D["Receive Items from Vendor"]
    q18OWgli.bS3["Enter Purchase Receives"] --> q18OYgMhz0Ce["Enter Bill"]
    LS_Oim882Ere["Start"] --> LS_OLlU9rDer["Raise Sales Order"]
    q18OYgMhz0Ce["Enter Bill"] --> q18OkdUecEyT["Generate Picklist After Receipt"]
    LS_OW4wFilvV["Create Final Invoice"] --> LS_OqDNt5O-b["End"]
    LS_OFN9AmXF8["Check Stock Availability"] --> |In stock| MS_O3lnIzRUr["Create Picklist"]
    MS_O3W~TNac.["Ship Items"] --> LS_OW4wFilvV["Create Final Invoice"]
    DhzQT1F9vcZw["convert to payment made"] --> .W_ONWHpX~Hn["Convert Quotation to Sales Order"]
    r18OjMJ88Qlj["Convert Bill to Invoice"] --> r18O0VU47SF6["Deliver to Customer"]
    LS_OH_qN0I.W["Enter Bill"] --> MS_OzZkvHSYh["Create Picklist After Receipt"]
    ~W_OW9SAGXd2["Create Invoice"] --> ~W_OZdX.~0yV["Generate E-way Bills"]
    q18O1c2~iJhM["Check Inventory"] --> |No Stock| q18O80_E91md["Create Purchase Order to Vendor"]
    q18Oal0ZW._1["Create Invoice"] --> r18O0VU47SF6["Deliver to Customer"]
    .W_Orm4XHp_U["Accept Orders from Outlets (SO)"] --> .W_OLvgC2oKA["Check Stock Availability"]
    wfzQpyWHBe~y["request retainer invoice"] --> DhzQT1F9vcZw["convert to payment made"]
    q18OOhOIuxax["Vendor Invoice Type"] --> |Combined Invoice| q18OWgli.bS3["Enter Purchase Receives"]
    LS_OLlU9rDer["Raise Sales Order"] --> LS_OMAMuKcdd["Request Retainer Invoice"]
    .W_OktXIvJG8["Start"] --> .W_OE1S7P2sq["Receive Quotation Request"]
    ~W_OqMF6_1y6["Receive Items (Purchase Receives)"] --> ~W_OD2oDP8k0["Create Bills"]
    ~W_ODXONCu0t["Customer Response"] --> |Accept| wfzQpyWHBe~y["request retainer invoice"]
    .W_OU7~tApuZ["Ship Items (Shipment)"] --> ~W_OW9SAGXd2["Create Invoice"]
    .W_Obghnu2iz["Generate Picklist (Available for Sales)"] --> .W_OuODF8jDx["Package Items"]
    LS_OEA6ZzQAW["Convert Retainer Invoice to Payment Made"] --> LS_OFN9AmXF8["Check Stock Availability"]
    q18OkdUecEyT["Generate Picklist After Receipt"] --> q18Oal0ZW._1["Create Invoice"]
    ~W_OZdX.~0yV["Generate E-way Bills"] --> ~W_O8p0cVKeQ["Deliver to Outlet Customer"]
    q18O80_E91md["Create Purchase Order to Vendor"] --> q18OOhOIuxax["Vendor Invoice Type"]
    q18OTzZkWYv1["Receive Customer Order"] --> q18O1c2~iJhM["Check Inventory"]
    LS_OW4wFilvV["Create Final Invoice"] --> LS_OqDNt5O-b["End"]
    ~W_O8p0cVKeQ["Deliver to Outlet Customer"] --> .W_OvlKs_vy0["End"]
    LS_OMAMuKcdd["Request Retainer Invoice"] --> MS_OGeLUgaRS["Customer Pays"]
    MS_OhULT_jBB["Package Items"] --> MS_O3W~TNac.["Ship Items"]
    MS_ONZGQss3D["Receive Items from Vendor"] --> LS_OH_qN0I.W["Enter Bill"]
    .W_OktXIvJG8["Start"] --> .W_Orm4XHp_U["Accept Orders from Outlets (SO)"]
    MS_OhULT_jBB["Package Items"] --> MS_O3W~TNac.["Ship Items"]
```

### 2.2 Procedural Steps
- **Order Reception:** Receive Customer Order or Quotation Request.
- **Stock Check:** Verify inventory. If out of stock, trigger Purchase Order to Vendor.
- **Processing:** Convert Quotation to Sales Order (SO).
- **Fulfillment:** Generate Picklist -> Package Items -> Ship Items.
- **Billing:** Create Invoice -> Generate E-way Bill (if required).
- **Delivery:** Deliver to Customer and finalize transaction.

---

## 3. Integrated Modules Workflows
Detailed flow including estimates, advances (retainer invoices), and procurement integration.

### 3.1 Mermaid Diagram
```mermaid
graph TD
    buqPy5TtCGY3["Enter Bill"] --> buqPYGJxOZ.a["Generate Picklist"]
    mjqPtrNA3skL["Prepare Estimate (Quotation)"] --> mjqPfppiCHhQ["Accepted Estimate"]
    I7qPnk.-EOze["Delivered Order"] --> I7qPxeoquyCe["Sales Return Created"]
    mjqPVNHxq822["Shipment"] --> mjqPIjMbAlVd["Create Invoice"]
    I7qPAfZ.2~V3["Picklist Created"] --> I7qPgikgbVOd["Package Created"]
    mjqPFmPQFoKc["Stock Available?"] --> |No| mjqPbCv-u7T.["Create Purchase Order"]
    I7qPg8coFvX2["Shipment Created"] --> |Full| I7qPpXHXEXSI["Full Delivery → Invoice → Paid"]
    I7qP6KmGTpyo["Purchase Request (Auto/Manual)"] --> I7qPnxCeAvI6["Purchase Order (PO)"]
    I7qP5yaI5Whc["Vendor Bill Recorded"] --> I7qPvpJ2rdes["Vendor Payment"]
    mjqPFmPQFoKc["Stock Available?"] --> |Yes| mjqPaCwgd8la["Create Picklist"]
    I7qPnxCeAvI6["Purchase Order (PO)"] --> I7qPu4fvknrp["Purchase Receives"]
    H7qP1SrqFnHn["Customer Request"] --> J7qPc~n_hB9-["Customer Advance / Retainer Invoice"]
    J7qPT9TewTDW["Adjust with Future Bills"] --> I7qP5yaI5Whc["Vendor Bill Recorded"]
    I7qP7rTcjhq7["Goods Received Back (Stock Increased)"] --> I7qPXZbleBXA["Credit Note Issued"]
    buqPxz._cO26["Package Items"] --> buqP65XRq6S9["Shipment"]
    buqPirUNPn-9["Start"] --> buqPzmxJR1kJ["Sales Order (SO)"]
    buqPhU6F-7v1["Raise Purchase Order to Vendor"] --> buqPvgTHmTqO["Purchase Receives"]
    mjqPaCwgd8la["Create Picklist"] --> mjqPKrZ4wRni["Package Items"]
    mjqPKrZ4wRni["Package Items"] --> mjqPVNHxq822["Shipment"]
    I7qPiy6V36EB["Return to Supplier (Purchase Return)"] --> I7qP2dcMI8xC["Vendor Credit Note"]
    I7qPXZbleBXA["Credit Note Issued"] --> I7qPozU2NqGz["Customer: Refund or Apply as Credit?"]
    I7qPERxUTw2u["Confirm Sales Order"] --> I7qPOKpm5kj1["Check Stock Availability"]
    I7qPXZbleBXA["Credit Note Issued"] --> |Non-active goods| I7qPiy6V36EB["Return to Supplier (Purchase Return)"]
    mjqP1xHdO1E9["Enter Vendor Bills"] --> mjqPaCwgd8la["Create Picklist"]
    mjqPUawRGLYw["Customer Request"] --> mjqP5lyV3J5.["Create Sales Order"]
    I7qPnk.-EOze["Delivered Order"] --> I7qPxeoquyCe["Sales Return Created"]
    I7qPOKpm5kj1["Check Stock Availability"] --> |Stock Available| I7qPAfZ.2~V3["Picklist Created"]
    I7qPILDwd0Dm["Refund Processed"] --> J7qPEbfuRYW8["End"]
    buqP65XRq6S9["Shipment"] --> cuqP9rv4MwQI["Invoice"]
    mjqPbCv-u7T.["Create Purchase Order"] --> mjqP2VHa7dsB["Receive Purchased Items (Purchase Receive)"]
    I7qP_0dpnDh6["Create Sales Order (SO)"] --> I7qPERxUTw2u["Confirm Sales Order"]
    I7qPNHu-IcmK["Mark as Delivered"] --> |Reject| I7qPnk.-EOze["Delivered Order"]
    I7qPg80M2_n2["PAID"] --> J7qPEbfuRYW8["End"]
    H7qPyX5DprAq["Start"] --> H7qP1SrqFnHn["Customer Request"]
    mjqP2VHa7dsB["Receive Purchased Items (Purchase Receive)"] --> mjqP1xHdO1E9["Enter Vendor Bills"]
    I7qPxeoquyCe["Sales Return Created"] --> I7qP7rTcjhq7["Goods Received Back (Stock Increased)"]
    I7qPXZbleBXA["Credit Note Issued"] --> |Active Stock| j7ZPSohrRueb["Transfer Orders"]
    I7qPNHu-IcmK["Mark as Delivered"] --> |Accept| I7qPYZANBrm9["Invoice Created (Draft)"]
    buqPvgTHmTqO["Purchase Receives"] --> buqPy5TtCGY3["Enter Bill"]
    I7qP-brN8NSh["Stock Increased + Batch Created"] --> I7qP5yaI5Whc["Vendor Bill Recorded"]
    I7qP03kSnnC5["Applied as Credit to Future Invoice"] --> I7qPYZANBrm9["Invoice Created (Draft)"]
    I7qPPaZWr1P7["Vendor: Refund or Adjust with Future Bills?"] --> |Adjust| J7qPT9TewTDW["Adjust with Future Bills"]
    J7qPc~n_hB9-["Customer Advance / Retainer Invoice"] --> J7qPPEN8kGiM["Advance Payment Received"]
    I7qP1Lo89wdo["Invoice Sent"] --> I7qPnr0JdP3e["Payment Received"]
    cuqPYyXFC3.1["Stock available?"] --> |Stocked| buqPYGJxOZ.a["Generate Picklist"]
    I7qPYZANBrm9["Invoice Created (Draft)"] --> I7qP1Lo89wdo["Invoice Sent"]
    I7qPg8coFvX2["Shipment Created"] --> |Partial| I7qPREBC.DHs["Partial Delivery → Partial Invoice + Backorder"]
    buqPYGJxOZ.a["Generate Picklist"] --> buqPxz._cO26["Package Items"]
    I7qPvpJ2rdes["Vendor Payment"] --> I7qPYZANBrm9["Invoice Created (Draft)"]
    mjqPpRxjpX9P["Start"] --> mjqPUawRGLYw["Customer Request"]
    I7qP5yaI5Whc["Vendor Bill Recorded"] --> I7qPYZANBrm9["Invoice Created (Draft)"]
    I7qPOKpm5kj1["Check Stock Availability"] --> |Stock Not Available| I7qP6KmGTpyo["Purchase Request (Auto/Manual)"]
    H7qPmUu0~2eO["Accepted Estimate"] --> I7qP_0dpnDh6["Create Sales Order (SO)"]
    I7qPu4fvknrp["Purchase Receives"] --> I7qP-brN8NSh["Stock Increased + Batch Created"]
    I7qP2dcMI8xC["Vendor Credit Note"] --> I7qPPaZWr1P7["Vendor: Refund or Adjust with Future Bills?"]
    mjqPbf9BTnZV["Confirm Sales Order"] --> mjqPFmPQFoKc["Stock Available?"]
    I7qPu4fvknrp["Purchase Receives"] --> I7qP-brN8NSh["Stock Increased + Batch Created"]
    H7qP1SrqFnHn["Customer Request"] --> H7qPZ1teyN7w["Estimate (Quotes)"]
    buqPy5TtCGY3["Enter Bill"] --> cuqP9rv4MwQI["Invoice"]
    J7qPFt6~Z7fA["Stored as Customer Credit"] --> J7qPv3wCRTGf["Auto Apply to Future Invoices"]
    mjqPfppiCHhQ["Accepted Estimate"] --> mjqP5lyV3J5.["Create Sales Order"]
    I7qPozU2NqGz["Customer: Refund or Apply as Credit?"] --> |Apply as Credit| I7qP03kSnnC5["Applied as Credit to Future Invoice"]
    J7qPPEN8kGiM["Advance Payment Received"] --> J7qPFt6~Z7fA["Stored as Customer Credit"]
    I7qPu4fvknrp["Purchase Receives"] --> I7qPAfZ.2~V3["Picklist Created"]
    J7qP~l_JrJsc["Vendor Refund"] --> J7qPEbfuRYW8["End"]
    H7qPZ1teyN7w["Estimate (Quotes)"] --> H7qPmUu0~2eO["Accepted Estimate"]
    mjqP5lyV3J5.["Create Sales Order"] --> mjqPbf9BTnZV["Confirm Sales Order"]
    mjqP98BFcWvy["Receive Payment"] --> mjqPcZ9LOf0e["End"]
    H7qP1SrqFnHn["Customer Request"] --> I7qP_0dpnDh6["Create Sales Order (SO)"]
    I7qPnr0JdP3e["Payment Received"] --> I7qPg80M2_n2["PAID"]
    J7qPv3wCRTGf["Auto Apply to Future Invoices"] --> I7qPYZANBrm9["Invoice Created (Draft)"]
    mjqPUawRGLYw["Customer Request"] --> mjqPtrNA3skL["Prepare Estimate (Quotation)"]
    buqPzmxJR1kJ["Sales Order (SO)"] --> cuqPYyXFC3.1["Stock available?"]
    I7qPRWhz6a0T["Failed Delivery → Return Entry"] --> I7qPxeoquyCe["Sales Return Created"]
    cuqPYyXFC3.1["Stock available?"] --> |Non-stocked| buqPhU6F-7v1["Raise Purchase Order to Vendor"]
    I7qPozU2NqGz["Customer: Refund or Apply as Credit?"] --> |Refund| I7qPILDwd0Dm["Refund Processed"]
    mjqPIjMbAlVd["Create Invoice"] --> mjqP98BFcWvy["Receive Payment"]
    I7qPg8coFvX2["Shipment Created"] --> |Failed| I7qPRWhz6a0T["Failed Delivery → Return Entry"]
    I7qPg8coFvX2["Shipment Created"] --> I7qPvP8H2Xey["Delivery Challan (Optional)"]
    I7qPvP8H2Xey["Delivery Challan (Optional)"] --> I7qPNHu-IcmK["Mark as Delivered"]
    I7qPgikgbVOd["Package Created"] --> I7qPg8coFvX2["Shipment Created"]
    I7qPPaZWr1P7["Vendor: Refund or Adjust with Future Bills?"] --> |Refund| J7qP~l_JrJsc["Vendor Refund"]
```

### 3.2 Procedural Steps
- **Estimates:** Prepare and send Estimate (Quotation). If accepted, convert to SO.
- **Advances:** Generate Retainer Invoice for customer advance payment.
- **Inventory Sync:** Confirm SO -> Check Stock. Trigger procurement if missing.
- **Fulfillment:** Picklist -> Package -> Shipment.
- **Financials:** Generate Invoice -> Record Payment. Adjust with advances or credits.
- **Exceptions:** Handle partial deliveries, failed shipments, and sales returns.

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
