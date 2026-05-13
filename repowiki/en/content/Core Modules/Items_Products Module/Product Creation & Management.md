# Product Creation & Management

<cite>
**Referenced Files in This Document**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart)
- [items_item_detail.dart](file://lib/modules/items/presentation/items_item_detail.dart)
- [item_model.dart](file://lib/modules/items/models/item_model.dart)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart)
- [items_state.dart](file://lib/modules/items/controller/items_state.dart)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart)
- [items_repository.dart](file://lib/modules/items/repositories/items_repository.dart)
- [composition_section.dart](file://lib/modules/items/presentation/sections/composition_section.dart)
- [formulation_section.dart](file://lib/modules/items/presentation/sections/formulation_section.dart)
- [sales_section.dart](file://lib/modules/items/presentation/sections/sales_section.dart)
- [purchase_section.dart](file://lib/modules/items/presentation/sections/purchase_section.dart)
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
This document explains the product creation and management functionality, focusing on the end-to-end workflow for registering and maintaining product records. It covers the multi-tab interface design, data capture across composition, formulation, sales, and purchase sections, the underlying product data model, validation and error handling, offline-first persistence via Hive, and API integration patterns for CRUD operations. Practical scenarios such as creating goods vs. services, managing composition and formulations, setting pricing and taxes, and handling media uploads are included.

## Project Structure
The product feature spans three layers:
- Presentation: Screen and tabbed sections for capturing product data
- Domain: Controller and state management with Riverpod
- Data: API service and repository implementing online-first with offline fallback

```mermaid
graph TB
subgraph "Presentation Layer"
Create["ItemCreateScreen<br/>Multi-tab UI"]
Detail["ItemDetailScreen<br/>Overview + Warehouses"]
Sections["Sections:<br/>Composition | Formulation | Sales | Purchase"]
end
subgraph "Domain Layer (Riverpod)"
Controller["ItemsController<br/>State + Validation"]
State["ItemsState<br/>UI state + lookups"]
end
subgraph "Data Layer"
API["ProductsApiService<br/>HTTP client"]
Repo["ProductsRepository<br/>Online-first + Hive"]
Model["Item / ItemComposition<br/>Models"]
end
Create --> Controller
Detail --> Controller
Sections --> Controller
Controller --> State
Controller --> Repo
Repo --> API
Repo --> Model
```

**Diagram sources**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L44-L544)
- [items_item_detail.dart](file://lib/modules/items/presentation/items_item_detail.dart#L46-L346)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L16-L568)
- [items_state.dart](file://lib/modules/items/controller/items_state.dart#L7-L113)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L7-L208)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L7-L161)
- [item_model.dart](file://lib/modules/items/models/item_model.dart#L4-L461)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L3-L51)

**Section sources**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L44-L544)
- [items_item_detail.dart](file://lib/modules/items/presentation/items_item_detail.dart#L46-L346)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L16-L568)
- [items_state.dart](file://lib/modules/items/controller/items_state.dart#L7-L113)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L7-L208)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L7-L161)
- [item_model.dart](file://lib/modules/items/models/item_model.dart#L4-L461)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L3-L51)

## Core Components
- ItemCreateScreen orchestrates the entire product creation flow, including media upload, tax preference translation, and saving/updating items.
- Multi-tab UI organizes data capture into Composition, Formulation, Sales, and Purchase sections.
- ItemsController manages state, validation, and API interactions via ProductsApiService and ProductsRepository.
- ProductsRepository implements online-first strategy with Hive caching for offline support.
- Item and ItemComposition models define the product data schema and child table entries.

**Section sources**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L44-L544)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L16-L568)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L7-L208)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L7-L161)
- [item_model.dart](file://lib/modules/items/models/item_model.dart#L4-L461)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L3-L51)

## Architecture Overview
The system follows an online-first architecture with offline caching:
- UI captures product data and triggers controller actions.
- Controller validates and calls repository.
- Repository attempts API first, caches results to Hive, and falls back to cache on failure.
- API service encapsulates HTTP requests and error formatting.

```mermaid
sequenceDiagram
participant UI as "ItemCreateScreen"
participant Ctrl as "ItemsController"
participant Repo as "ProductsRepository"
participant API as "ProductsApiService"
participant Hive as "HiveService"
UI->>Ctrl : createItem()/updateItem()
Ctrl->>Ctrl : validateItem()
alt Valid
Ctrl->>Repo : createItem()/updateItem()
Repo->>API : POST/PUT /products
API-->>Repo : Item JSON
Repo->>Hive : saveProduct()
Repo-->>Ctrl : Item
Ctrl->>Ctrl : loadItems()
Ctrl-->>UI : success
else Invalid
Ctrl-->>UI : validationErrors
end
```

**Diagram sources**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L352-L451)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L232-L346)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L76-L117)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L80-L124)

## Detailed Component Analysis

### Product Registration Workflow
- Type selection toggles tabs: Goods (Composition, Formulation, Sales, Purchase) vs. Service (Sales, Purchase).
- Primary info collects name, billing name, item code/SKU, unit, category, returnable flag, ecommerce push, HSN/SAC, and tax preference.
- Media upload allows selecting multiple images; on success, primary image and URLs are attached to the item.
- Saving triggers validation, then controller delegates to repository and API, followed by cache update and reload.

```mermaid
flowchart TD
Start(["Open Item Registration"]) --> TypeSel["Select Type: Goods or Service"]
TypeSel --> Primary["Fill Primary Info"]
Primary --> Media["Upload Images (optional)"]
Media --> Tabs["Open Tabs: Composition | Formulation | Sales | Purchase"]
Tabs --> Validate["Validate Fields"]
Validate --> |Valid| Save["Save/Update Item"]
Validate --> |Invalid| ShowErr["Show Validation Errors"]
Save --> API["Call API /products"]
API --> Cache["Cache to Hive"]
Cache --> Reload["Reload Items"]
Reload --> Done(["Done"])
ShowErr --> Done
```

**Diagram sources**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L352-L524)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L186-L230)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L21-L48)

**Section sources**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L44-L544)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L186-L230)

### Multi-Tab Interface Design
- Composition: Tracks active ingredients, strength, units, schedules, and buying rules. Supports managing lookup lists and checking usage before deletion.
- Formulation: Captures dimensions, weight, manufacturer, brand, and identifiers (MPN, UPC, ISBN, EAN).
- Sales: Captures selling price, MRP, PTR, currency, account, and description; controlled by a “sellable” flag.
- Purchase: Captures cost price, currency, account, preferred vendor, and description; controlled by a “purchasable” flag.

```mermaid
classDiagram
class CompositionSection {
+initialRows
+contentOptions
+strengthOptions
+unitOptions
+buyingRuleOptions
+drugScheduleOptions
+onChanged(rows)
+onBuyingRuleChanged(id)
+onDrugScheduleChanged(id)
}
class FormulationSection {
+dimXCtrl
+dimYCtrl
+dimZCtrl
+dimUnit
+weightCtrl
+weightUnit
+manufacturer
+brand
+upcCtrl
+eanCtrl
+mpnCtrl
+isbnCtrl
}
class SalesSection {
+sellingPriceCtrl
+mrpCtrl
+ptrCtrl
+descriptionCtrl
+currency
+accountValue
+sellable
}
class PurchaseSection {
+costPriceCtrl
+currency
+accountValue
+preferredVendor
+purchasable
}
```

**Diagram sources**
- [composition_section.dart](file://lib/modules/items/presentation/sections/composition_section.dart#L6-L51)
- [formulation_section.dart](file://lib/modules/items/presentation/sections/formulation_section.dart#L5-L33)
- [sales_section.dart](file://lib/modules/items/presentation/sections/sales_section.dart#L42-L83)
- [purchase_section.dart](file://lib/modules/items/presentation/sections/purchase_section.dart#L40-L85)

**Section sources**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L107-L258)
- [composition_section.dart](file://lib/modules/items/presentation/sections/composition_section.dart#L6-L51)
- [formulation_section.dart](file://lib/modules/items/presentation/sections/formulation_section.dart#L5-L33)
- [sales_section.dart](file://lib/modules/items/presentation/sections/sales_section.dart#L42-L83)
- [purchase_section.dart](file://lib/modules/items/presentation/sections/purchase_section.dart#L40-L85)

### Product Data Model
The Item model defines the canonical product record, including:
- Basic info: type, product name, billing name, item code/SKU, unit, category, returnable, ecommerce flag
- Tax and regulatory: HSN/SAC, tax preference, intra/inter-state tax IDs
- Pricing: selling price, MRP, PTR, cost price, currencies, sales/purchase account IDs
- Formulation: dimensions (L×W×H), weight, units, manufacturer, brand, identifiers
- Inventory: tracking flags, valuation method, storage/rack, reorder point, terms
- Status flags: active, locked, sales/purchase eligibility, temperature-controlled
- Associations: compositions (child table), timestamps, and computed stock-on-hand

```mermaid
classDiagram
class Item {
+id
+type
+productName
+billingName
+itemCode
+sku
+unitId
+categoryId
+isReturnable
+pushToEcommerce
+hsnCode
+taxPreference
+intraStateTaxId
+interStateTaxId
+primaryImageUrl
+imageUrls
+sellingPrice
+sellingPriceCurrency
+mrp
+ptr
+salesAccountId
+salesDescription
+costPrice
+costPriceCurrency
+purchaseAccountId
+preferredVendorId
+purchaseDescription
+length
+width
+height
+dimensionUnit
+weight
+weightUnit
+manufacturerId
+brandId
+mpn
+upc
+isbn
+ean
+trackAssocIngredients
+buyingRuleId
+scheduleOfDrugId
+isTrackInventory
+trackBinLocation
+trackBatches
+trackSerialNumber
+inventoryAccountId
+inventoryValuationMethod
+storageId
+rackId
+reorderPoint
+reorderTermId
+isActive
+isLock
+isSalesItem
+isPurchaseItem
+isTemperatureControlled
+compositions
+createdAt
+createdById
+updatedAt
+updatedById
+stockOnHand
}
class ItemComposition {
+contentId
+strengthId
+contentUnitId
+scheduleId
}
Item --> ItemComposition : "has many"
```

**Diagram sources**
- [item_model.dart](file://lib/modules/items/models/item_model.dart#L4-L172)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L3-L27)

**Section sources**
- [item_model.dart](file://lib/modules/items/models/item_model.dart#L4-L461)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L3-L51)

### Validation Rules, Input Sanitization, and Error Handling
- Validation enforces required fields and numeric constraints:
  - Required: type, product name, item code/SKU, unit ID
  - Optional numeric validations: selling price ≥ 0, MRP ≥ 0, inventory valuation method when inventory tracking is enabled
- Error handling:
  - Validation exceptions populate UI validationErrors
  - API exceptions are formatted and surfaced to the UI
  - Repository catches and rethrows errors, optionally falling back to cached data

```mermaid
flowchart TD
VStart["validateItem(item)"] --> CheckType["Check type not empty"]
CheckType --> CheckName["Check product name not empty"]
CheckName --> CheckCode["Check item code/SKU not empty"]
CheckCode --> CheckUnit["Check unitId not empty"]
CheckUnit --> Prices["Validate prices >= 0 if present"]
Prices --> Inv["Validate valuation method if inventory tracked"]
Inv --> VEnd["Return errors map"]
```

**Diagram sources**
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L186-L230)

**Section sources**
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L186-L230)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L10-L49)

### Integration with API and Offline Persistence
- ProductsApiService encapsulates HTTP GET/POST/PUT/DELETE for /products and formats error responses.
- ProductsRepository implements online-first:
  - Fetch from API, cache to Hive, update last sync timestamp
  - On failure, return cached data
  - Create/update/delete propagate to API then update cache
- ItemsRepository is an abstract contract; a mock implementation exists for development.

```mermaid
sequenceDiagram
participant Repo as "ProductsRepository"
participant API as "ProductsApiService"
participant Hive as "HiveService"
Repo->>API : fetchProducts()
API-->>Repo : List<Item>
Repo->>Hive : saveProducts()
Repo-->>Repo : updateLastSyncTime()
Repo->>API : createProductFromMap(data)
API-->>Repo : Map
Repo->>Hive : saveProduct()
Repo->>API : updateProductFromMap(id,data)
API-->>Repo : Map
Repo->>Hive : saveProduct()
```

**Diagram sources**
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L21-L48)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L142-L206)

**Section sources**
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L7-L208)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L7-L161)
- [items_repository.dart](file://lib/modules/items/repositories/items_repository.dart#L3-L53)

### State Management with Riverpod
- ItemsController extends StateNotifier<ItemsState> and exposes provider itemsControllerProvider.
- ItemsState holds items list, loading flags, error messages, selected item ID, validation errors, and lookup collections.
- Consumers watch itemsControllerProvider for UI updates and call createItem/updateItem.

```mermaid
classDiagram
class ItemsController {
+loadItems()
+loadLookupData()
+validateItem(item)
+createItem(item)
+updateItem(item)
+deleteItem(id)
+checkLookupUsage(key,id)
}
class ItemsState {
+items
+isLoading
+isSaving
+isLoadingLookups
+error
+selectedItemId
+validationErrors
+units,categories,taxRates
+manufacturers,brands,vendors
+accounts,contentUnits,strengths,buyingRules,drugSchedules
}
ItemsController --> ItemsState : "notifies"
```

**Diagram sources**
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L16-L568)
- [items_state.dart](file://lib/modules/items/controller/items_state.dart#L7-L113)

**Section sources**
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L16-L568)
- [items_state.dart](file://lib/modules/items/controller/items_state.dart#L7-L113)

### Practical Scenarios
- Creating a new product (goods):
  - Select type “Goods”
  - Fill primary info (name, item code, SKU, unit, category)
  - Optionally upload images
  - Configure composition, formulation, sales, and purchase details
  - Save; on success, show confirmation dialog and reset to new form
- Editing an existing product:
  - Prepopulate fields from Item
  - Update as needed and save to trigger updateItem
- Bulk operations and migrations:
  - Use repository’s raw map APIs to fetch and persist product sets for batch operations
  - Clear cache via repository if needed

**Section sources**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L74-L139)
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L352-L524)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L173-L206)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L155-L160)

## Dependency Analysis
- UI depends on ItemsController via Riverpod provider
- Controller depends on ProductsRepository and ProductsApiService
- Repository depends on ProductsApiService and HiveService
- Models are used across UI, controller, and repository boundaries

```mermaid
graph LR
UI["ItemCreateScreen"] --> Ctrl["ItemsController"]
Ctrl --> Repo["ProductsRepository"]
Repo --> API["ProductsApiService"]
Repo --> Hive["HiveService"]
Ctrl --> Model["Item / ItemComposition"]
API --> Model
```

**Diagram sources**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L247-L249)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L17-L23)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L7-L13)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L7-L8)
- [item_model.dart](file://lib/modules/items/models/item_model.dart#L4-L461)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L3-L51)

**Section sources**
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L247-L249)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L17-L23)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L7-L13)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L7-L8)
- [item_model.dart](file://lib/modules/items/models/item_model.dart#L4-L461)
- [item_composition_model.dart](file://lib/modules/items/models/item_composition_model.dart#L3-L51)

## Performance Considerations
- Parallel lookup loading in ItemsController improves initial render performance.
- Online-first caching reduces repeated network calls and enables offline usability.
- Numeric parsing and trimming occur during item construction to prevent invalid payloads.
- Consider debouncing heavy lookups and batching cache writes for large datasets.

[No sources needed since this section provides general guidance]

## Troubleshooting Guide
- Validation failures:
  - Check validationErrors surfaced in UI; resolve missing/invalid fields
- API errors:
  - Review formatted error messages returned by ProductsApiService
- Offline issues:
  - Confirm cache availability and staleness thresholds
  - Use repository’s cache info and clear cache when necessary
- Image upload warnings:
  - Inspect warnings shown in UI when uploads fail

**Section sources**
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L264-L287)
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L10-L49)
- [products_repository.dart](file://lib/modules/items/repositories/products_repository.dart#L135-L153)
- [items_item_create.dart](file://lib/modules/items/presentation/items_item_create.dart#L335-L347)

## Conclusion
The product creation and management feature provides a robust, offline-capable solution for registering and maintaining product records. Its modular design with Riverpod state management, strict validation, and layered data access ensures reliability and scalability. The multi-tab UI streamlines data capture across composition, formulation, sales, and purchase domains, while API and repository abstractions support seamless integration and caching strategies.

[No sources needed since this section summarizes without analyzing specific files]

## Appendices

### API Endpoints Used
- GET /products
- GET /products/:id
- POST /products
- PUT /products/:id
- DELETE /products/:id

**Section sources**
- [products_api_service.dart](file://lib/modules/items/services/products_api_service.dart#L51-L136)