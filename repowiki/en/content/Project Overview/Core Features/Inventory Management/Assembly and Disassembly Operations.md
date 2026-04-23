# Assembly and Disassembly Operations

<cite>
**Referenced Files in This Document**
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart)
- [inventory_assemblies_assembly_list.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_list.dart)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart)
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart)
- [items_controller.dart](file://lib/modules/items/controller/items_state.dart)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Architecture Overview](#architecture-overview)
5. [Detailed Component Analysis](#detailed-component-analysis)
6. [Dependency Analysis](#dependency-analysis)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Conclusion](#conclusion)
10. [Appendices](#appendices)

## Introduction
This document explains the Assembly and Disassembly Operations in the Zerpai ERP system. It covers the end-to-end manufacturing workflow including Bill of Materials (BOM) creation, component tracking, finished goods assembly, configurable product composition, component substitution rules, quality control checkpoints, and disassembly operations for returns, repairs, and inventory adjustments. It also documents the composition model for manufactured items, component costing, profit margin calculations, and integration with inventory management for accurate component consumption and finished goods production tracking.

## Project Structure
Assembly and disassembly capabilities are primarily implemented in the inventory module’s assemblies presentation layer. Supporting composition logic is integrated via composite items and item composition models. The UI screens include:
- Assembly list screen for navigation and listing
- Assembly create screen for new assembly orders
- Add batches dialog for batch-level tracking during assembly

```mermaid
graph TB
subgraph "Inventory Assemblies UI"
A["AssemblyListScreen<br/>List existing assemblies"]
B["AssemblyCreateScreen<br/>Create new assembly order"]
C["AddBatchesDialog<br/>Manage batch details"]
end
subgraph "Composition & Items"
D["CompositeItemsProvider<br/>Filters composite items"]
E["ItemComposition<br/>Composition model"]
F["ItemsController<br/>Item state"]
end
A --> B
B --> C
B --> D
D --> F
B --> E
```

**Diagram sources**
- [inventory_assemblies_assembly_list.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_list.dart#L1-L37)
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart#L1-L590)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart#L1-L26)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L1-L51)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart)
- [items_controller.dart](file://lib/modules/items/controller/items_state.dart)

**Section sources**
- [inventory_assemblies_assembly_list.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_list.dart#L1-L37)
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart#L1-L590)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart#L1-L26)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L1-L51)

## Core Components
- AssemblyListScreen: Provides navigation to create new assembly orders and lists existing assemblies.
- AssemblyCreateScreen: Captures assembly metadata (composite item, assembly number, description, assembled date, quantity), displays associated items (BOM), and supports batch management.
- AddBatchesDialog: Manages batch references, manufacturer batch numbers, manufactured/expiry dates, and quantities for assembly inputs.
- CompositeItemsProvider: Filters items that are composite (either tracked via associated ingredients or have compositions).
- ItemComposition: Defines composition attributes for items (content, strength, unit, schedule identifiers).

Key UI behaviors:
- Composite item selection triggers display of associated items table.
- Quantity controls scale total quantities required per component.
- Batch management allows adding new or existing batches and toggling overwrite behavior.
- Footer actions include Save as Draft, Assemble (with split menu), and Cancel.

**Section sources**
- [inventory_assemblies_assembly_list.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_list.dart#L1-L37)
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart#L1-L590)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart#L1-L26)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L1-L51)

## Architecture Overview
The assembly workflow integrates UI screens with composition providers and models. The create screen orchestrates:
- Selection of a composite item
- Population of BOM-associated items
- Batch-level input for component tracking
- Footer actions to finalize assembly

```mermaid
sequenceDiagram
participant U as "User"
participant L as "AssemblyListScreen"
participant C as "AssemblyCreateScreen"
participant D as "AddBatchesDialog"
participant P as "CompositeItemsProvider"
participant S as "ItemsController"
U->>L : Open Assemblies
L->>U : Show "New Assembly" button
U->>L : Tap "New Assembly"
L->>C : Navigate to create screen
C->>P : Load composite items
P->>S : Read items state
S-->>P : Items list
C->>U : Render form and associated items table
U->>C : Tap "Add Batches"
C->>D : Open AddBatchesDialog
D->>U : Manage batch rows and totals
U->>C : Confirm assembly
C-->>U : Submit assembly order
```

**Diagram sources**
- [inventory_assemblies_assembly_list.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_list.dart#L1-L37)
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart#L1-L590)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart#L1-L26)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart)
- [items_controller.dart](file://lib/modules/items/controller/items_state.dart)

## Detailed Component Analysis

### AssemblyCreateScreen
Responsibilities:
- Capture assembly metadata (composite item, assembly number, description, assembled date, quantity).
- Display associated items table derived from the selected composite item.
- Support batch management via AddBatchesDialog.
- Provide footer actions for saving drafts, assembling, and canceling.

Processing logic highlights:
- Composite item selection enables rendering of associated items section.
- Quantity change updates total quantities required per component.
- Batch management computes total quantity to be added across rows.
- Overwrite toggle controls whether to replace line item quantities with the total quantity.

```mermaid
flowchart TD
Start(["Open AssemblyCreateScreen"]) --> SelectComposite["Select Composite Item"]
SelectComposite --> ShowForm["Show Assembly Form Fields"]
ShowForm --> EnterQuantity["Enter Quantity to Assemble"]
EnterQuantity --> ComputeTotals["Compute Total Qty Required Per Component"]
ComputeTotals --> AddBatches["Tap 'Add Batches'"]
AddBatches --> OpenDialog["Open AddBatchesDialog"]
OpenDialog --> ManageBatches["Add/Edit Batches<br/>Reference/Mfg Batch/Expiry/Qty"]
ManageBatches --> SaveBatches["Save Batches"]
SaveBatches --> ReviewOrder["Review Assembly Order"]
ReviewOrder --> Action{"Action"}
Action --> |Save as Draft| Draft["Save Draft"]
Action --> |Assemble| Finalize["Finalize Assembly"]
Action --> |Cancel| Exit["Exit Screen"]
```

**Diagram sources**
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart#L1-L590)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)

**Section sources**
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart#L1-L590)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)

### AddBatchesDialog
Responsibilities:
- Manage batch rows with fields for batch reference, manufacturer batch number, manufactured date, expiry date, and quantity.
- Allow adding new or selecting existing batches.
- Toggle overwrite behavior to replace line item quantities with the total quantity.
- Compute and display total quantity added across rows.

UI behaviors:
- Dynamic batch rows with add/remove actions.
- Real-time total calculation across batch entries.
- Footer with Save and Cancel actions.

```mermaid
flowchart TD
Open(["Open AddBatchesDialog"]) --> InitRows["Initialize Batch Rows"]
InitRows --> EditRow["Edit Batch Row<br/>Reference/Mfg Batch/Date/Qty"]
EditRow --> AddMore{"Add More Batches?"}
AddMore --> |Yes| AddRow["Add New/Existing Batch Row"]
AddMore --> |No| Compute["Compute Total Quantity Added"]
Compute --> Toggle["Toggle Overwrite Option"]
Toggle --> Save["Save Batches"]
Save --> Close(["Close Dialog"])
```

**Diagram sources**
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)

**Section sources**
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)

### CompositeItemsProvider and Composition Model
Composite items are identified by either tracking associated ingredients or having a non-empty compositions list. The composition model encapsulates composition attributes for items.

```mermaid
classDiagram
class CompositeItemsProvider {
+watch(itemsControllerProvider)
+filter(compositeItems)
}
class ItemsController {
+itemsState
}
class Item {
+trackAssocIngredients
+compositions
}
class ItemComposition {
+contentId
+strengthId
+contentUnitId
+scheduleId
}
CompositeItemsProvider --> ItemsController : "reads items state"
ItemsController --> Item : "provides items"
Item --> ItemComposition : "has compositions"
```

**Diagram sources**
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart#L1-L26)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart)
- [items_controller.dart](file://lib/modules/items/controller/items_state.dart)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L1-L51)

**Section sources**
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart#L1-L26)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L1-L51)

### Assembly Workflow: Manufacturing and BOM
End-to-end assembly workflow:
- Create assembly order with composite item selection and metadata.
- Populate BOM components in the associated items table.
- Optionally add batch details for each component.
- Finalize assembly to record finished goods and consume components.

```mermaid
sequenceDiagram
participant U as "User"
participant C as "AssemblyCreateScreen"
participant D as "AddBatchesDialog"
participant P as "CompositeItemsProvider"
participant S as "ItemsController"
U->>C : Select Composite Item
C->>P : Filter composite items
P->>S : Retrieve items state
S-->>P : Items list
C->>U : Render associated items table
U->>C : Set Quantity to Assemble
C->>U : Show "Add Batches"
U->>D : Open dialog and add batches
D-->>C : Return batch data
U->>C : Confirm assembly
C-->>U : Assembly order submitted
```

**Diagram sources**
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart#L1-L590)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart#L1-L26)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart)
- [items_controller.dart](file://lib/modules/items/controller/items_state.dart)

### Disassembly Operations: Returns, Repairs, Inventory Adjustments
Conceptual flow for disassembly:
- Create disassembly order referencing the finished good.
- Select components to remove and optionally assign replacement components.
- Record batch-level details for returned or scrapped components.
- Update inventory: reduce finished goods, increase component availability, adjust batch records.

```mermaid
flowchart TD
Start(["Disassembly Request"]) --> SelectFG["Select Finished Good"]
SelectFG --> ChooseComponents["Choose Components to Remove"]
ChooseComponents --> BatchDetails["Record Batch Details<br/>Return/Scrap/Repair"]
BatchDetails --> UpdateInventory["Update Inventory<br/>Decrease FG, Increase Components"]
UpdateInventory --> QC["Quality Control Checkpoint"]
QC --> Complete(["Complete Disassembly"])
```

[No sources needed since this diagram shows conceptual workflow, not actual code structure]

### Configurable Products and Component Substitution Rules
Conceptual model for configurable products:
- Composite item defines allowable substitutions per component.
- Substitution rules specify compatible alternatives (e.g., strength, unit, schedule).
- During assembly/disassembly, enforce rules and log deviations.

```mermaid
flowchart TD
Start(["Configurable Product"]) --> DefineBOM["Define BOM with Substitution Rules"]
DefineBOM --> Assemble["Assemble with Allowed Substitutions"]
Assemble --> Validate["Validate Substitutions Against Rules"]
Validate --> Approve{"Approved?"}
Approve --> |Yes| Record["Record Assembly with Substitutions"]
Approve --> |No| Override["Override with Authorization"]
Override --> Record
```

[No sources needed since this diagram shows conceptual workflow, not actual code structure]

### Quality Control Checkpoints
Conceptual QC checkpoints:
- Pre-assembly: Verify BOM completeness and component availability.
- Post-assembly: Inspect finished goods and batch details.
- Disassembly: Validate returned components and replacements.

```mermaid
stateDiagram-v2
[*] --> PreAssembly
PreAssembly --> PostAssembly : "Assembly Complete"
PostAssembly --> QCInspection : "QC Check"
QCInspection --> Approved : "Approved"
QCInspection --> Rejected : "Rejected"
Approved --> [*]
Rejected --> PostAssembly : "Remediation"
```

[No sources needed since this diagram shows conceptual workflow, not actual code structure]

### Composition Model, Costing, and Profit Margin
Composition model:
- ItemComposition captures content, strength, unit, and schedule identifiers.
- These attributes support recipe adherence and batch-level traceability.

Costing and margins:
- Component costs are aggregated per assembly order.
- Profit margin calculations can be applied at order level or per batch depending on pricing strategy.
- Service items can be added to associate additional costs (rent, labor, scrap).

```mermaid
flowchart TD
Start(["Assembly Order"]) --> GatherComponents["Gather Component Costs"]
GatherComponents --> SumCosts["Sum Direct Costs"]
SumCosts --> AddServices["Add Service Costs"]
AddServices --> TotalCost["Total Assembly Cost"]
TotalCost --> Pricing["Apply Pricing Scheme"]
Pricing --> Profit["Calculate Profit Margin"]
Profit --> End(["Report/Invoice"])
```

[No sources needed since this diagram shows conceptual workflow, not actual code structure]

### Practical Examples
- Assembly order example: Select composite item “Widget X”, set quantity to 100, add batch details for each component, save as draft, then assemble.
- Component reservation example: Use associated items table to reserve required quantities against available stock; adjust totals when quantity changes.
- Finished goods receipt: After assembly, record finished goods into the selected warehouse and update inventory balances.

[No sources needed since this section provides general guidance]

## Dependency Analysis
The assembly UI depends on:
- CompositeItemsProvider to filter composite items.
- ItemsController for items state.
- AddBatchesDialog for batch-level input management.

```mermaid
graph TB
Create["AssemblyCreateScreen"] --> Provider["CompositeItemsProvider"]
Provider --> Controller["ItemsController"]
Create --> Dialog["AddBatchesDialog"]
Create --> Composition["ItemComposition"]
```

**Diagram sources**
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart#L1-L590)
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart#L1-L26)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart)
- [items_controller.dart](file://lib/modules/items/controller/items_state.dart)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L1-L51)

**Section sources**
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart#L1-L590)
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart#L1-L26)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart)
- [items_controller.dart](file://lib/modules/items/controller/items_state.dart)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L1-L51)

## Performance Considerations
- Batch row management: Limit the number of simultaneous batch edits; debounce total calculations.
- Composite item filtering: Cache filtered composite items to avoid repeated filtering on large item lists.
- UI responsiveness: Use asynchronous loading states for item lists and batch computations.

[No sources needed since this section provides general guidance]

## Troubleshooting Guide
Common issues and resolutions:
- Composite item not appearing: Verify the item’s trackAssocIngredients flag or compositions list.
- Associated items table empty: Ensure a composite item is selected before enabling the section.
- Batch quantity mismatch: Confirm total quantity computed across batch rows matches the assembly quantity.
- Overwrite behavior confusion: Understand that overwrite replaces line item quantities with the total quantity.

**Section sources**
- [composite_items_provider.dart](file://lib/modules/composite/providers/composite_items_provider.dart#L1-L26)
- [inventory_assemblies_assembly_create.dart](file://lib/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_create.dart#L1-L590)
- [add_batches_dialog.dart](file://lib/modules/inventory/assemblies/presentation/widgets/add_batches_dialog.dart#L1-L488)

## Conclusion
The Assembly and Disassembly Operations in Zerpai ERP are centered around a robust UI for creating assembly orders, managing batch-level component tracking, and integrating with composite item composition models. The current implementation focuses on assembly creation and batch management, with clear pathways to extend support for disassembly, configurable products, substitution rules, and quality control checkpoints. Integrating these features with inventory management ensures accurate component consumption and finished goods production tracking.

## Appendices
- Related models and providers: CompositeItemsProvider, ItemComposition, ItemsController, and ItemsState.
- UI screens: AssemblyListScreen, AssemblyCreateScreen, and AddBatchesDialog.

[No sources needed since this section summarizes without analyzing specific files]