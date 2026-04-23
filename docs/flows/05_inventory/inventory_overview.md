# Inventory Module — Overview

## Module Structure

```mermaid
graph TD
    INV[Inventory Module\nlib/modules/inventory/]

    INV --> ASSM[assemblies/\nAssemblies]
    INV --> ADJ[adjustments/\nStock Adjustments]
    INV --> PICK[picklists/\nPick Lists]
    INV --> PKG[packages/\nPackages]
    INV --> SHIP[shipments/\nShipments]
    INV --> TR[transfer_orders/\nTransfer Orders]

    ASSM --> ASSM_M[inventory_adjustment_model.dart\nstock_model.dart]
    ASSM --> ASSM_R[adjustments_repository.dart\nstock_repository.dart]

    TR --> TR_M[stock_transfer_model.dart]
    TR --> TR_R[transfers_repository.dart]
```

## Inventory Data Flow

```mermaid
flowchart TD
    INV_EVENTS[Inventory Events]

    INV_EVENTS --> RECEIVE[Goods Received\nfrom Purchase Order]
    INV_EVENTS --> ISSUE[Goods Issued\nfrom Sales Order / Delivery Challan]
    INV_EVENTS --> ADJ[Manual Adjustment]
    INV_EVENTS --> TRANSFER[Transfer Order\nbranch to branch]
    INV_EVENTS --> ASSM[Assembly\nbuild composite item]

    RECEIVE --> branch_inventory[(branch_inventory\nstock levels per branch)]
    ISSUE --> branch_inventory
    ADJ --> branch_inventory
    TRANSFER --> branch_inventory
    ASSM --> branch_inventory
```

## Route Map

```mermaid
graph LR
    BASE[/inventory]

    BASE --> A[/assemblies]
    BASE --> B[/adjustments]
    BASE --> C[/picklists]
    BASE --> D[/packages]
    BASE --> E[/shipments]
    BASE --> F[/transfer-orders]

    A --> A1[list]
    A --> A2[/create]
    F --> F1[list]
    F --> F2[/create]
```
