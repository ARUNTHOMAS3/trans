# Invoicing System

<cite>
**Referenced Files in This Document**
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart)
- [sales_delivery_challan_create.dart](file://lib/modules/sales/presentation/sales_delivery_challan_create.dart)
- [sales_order_controller.dart](file://lib/modules/sales/controller/sales_order_controller.dart)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart)
- [sales_order_model.dart](file://lib/modules/sales/models/sales_order_model.dart)
- [sales_order_item_model.dart](file://lib/modules/sales/models/sales_order_item_model.dart)
- [tax_rate_model.dart](file://lib/modules/items/models/tax_rate_model.dart)
- [gstin_lookup_model.dart](file://lib/modules/sales/models/gstin_lookup_model.dart)
- [sales.service.ts](file://backend/src/sales/sales.service.ts)
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts)
- [schema.ts](file://backend/src/db/schema.ts)
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
This document describes the Invoicing System within the ZerpAI ERP platform. It focuses on invoice creation from sales orders, invoice numbering schemes, tax calculation automation, and invoice generation workflows. It also covers delivery challan creation, invoice modification and cancellation procedures, practical generation scenarios, tax computation methods, integration with accounting systems, invoice templates, bulk processing, and GST compliance requirements.

## Project Structure
The invoicing system spans the frontend Flutter module and the backend NestJS service:
- Frontend: Sales domain UI screens for invoices and challans, Riverpod state management, and API service integration.
- Backend: Sales controller and service for CRUD operations, database schema for sales documents, and mock GSTIN lookup.

```mermaid
graph TB
subgraph "Frontend (Flutter)"
UI_Invoice["Invoice Screen<br/>sales_invoice_invoice_create.dart"]
UI_Challan["Delivery Challan Screen<br/>sales_delivery_challan_create.dart"]
Controller["Sales Order Controller<br/>sales_order_controller.dart"]
ApiService["Sales Order API Service<br/>sales_order_api_service.dart"]
Models["Models<br/>sales_order_model.dart<br/>sales_order_item_model.dart<br/>tax_rate_model.dart"]
end
subgraph "Backend (NestJS)"
Ctrl["Sales Controller<br/>sales.controller.ts"]
Svc["Sales Service<br/>sales.service.ts"]
DB["Database Schema<br/>schema.ts"]
end
UI_Invoice --> Controller
UI_Challan --> Controller
Controller --> ApiService
ApiService --> Ctrl
Ctrl --> Svc
Svc --> DB
Models --> UI_Invoice
Models --> UI_Challan
```

**Diagram sources**
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L1-L573)
- [sales_delivery_challan_create.dart](file://lib/modules/sales/presentation/sales_delivery_challan_create.dart#L1-L343)
- [sales_order_controller.dart](file://lib/modules/sales/controller/sales_order_controller.dart#L1-L119)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L1-L192)
- [sales_order_model.dart](file://lib/modules/sales/models/sales_order_model.dart#L1-L118)
- [sales_order_item_model.dart](file://lib/modules/sales/models/sales_order_item_model.dart#L1-L62)
- [tax_rate_model.dart](file://lib/modules/items/models/tax_rate_model.dart#L1-L38)
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L1-L102)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L1-L162)
- [schema.ts](file://backend/src/db/schema.ts#L236-L253)

**Section sources**
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L1-L573)
- [sales_delivery_challan_create.dart](file://lib/modules/sales/presentation/sales_delivery_challan_create.dart#L1-L343)
- [sales_order_controller.dart](file://lib/modules/sales/controller/sales_order_controller.dart#L1-L119)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L1-L192)
- [sales_order_model.dart](file://lib/modules/sales/models/sales_order_model.dart#L1-L118)
- [sales_order_item_model.dart](file://lib/modules/sales/models/sales_order_item_model.dart#L1-L62)
- [tax_rate_model.dart](file://lib/modules/items/models/tax_rate_model.dart#L1-L38)
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L1-L102)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L1-L162)
- [schema.ts](file://backend/src/db/schema.ts#L236-L253)

## Core Components
- Invoice Creation Screen: Builds invoice headers, items table, totals, and sends a unified SalesOrder payload to the backend.
- Delivery Challan Creation Screen: Similar structure but tailored for delivery challans with distinct numbering and document type.
- Sales Order Controller: Riverpod notifier orchestrating data loading and persistence via API service.
- Sales Order API Service: Encapsulates HTTP calls to the backend sales endpoints.
- SalesOrder and SalesOrderItem models: Define the invoice/challan data contract and serialization.
- TaxRate model: Represents tax rates and types used for tax computations.
- Backend Sales Controller/Service: Exposes endpoints for sales records and implements mock GSTIN lookup.
- Database Schema: Defines sales_orders, customers, sales_payments, sales_eway_bills, and sales_payment_links tables.

**Section sources**
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L1-L573)
- [sales_delivery_challan_create.dart](file://lib/modules/sales/presentation/sales_delivery_challan_create.dart#L1-L343)
- [sales_order_controller.dart](file://lib/modules/sales/controller/sales_order_controller.dart#L1-L119)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L1-L192)
- [sales_order_model.dart](file://lib/modules/sales/models/sales_order_model.dart#L1-L118)
- [sales_order_item_model.dart](file://lib/modules/sales/models/sales_order_item_model.dart#L1-L62)
- [tax_rate_model.dart](file://lib/modules/items/models/tax_rate_model.dart#L1-L38)
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L1-L102)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L1-L162)
- [schema.ts](file://backend/src/db/schema.ts#L236-L253)

## Architecture Overview
The invoicing workflow integrates UI, state management, API service, backend controller/service, and database.

```mermaid
sequenceDiagram
participant U as "User"
participant F as "Invoice Screen<br/>sales_invoice_invoice_create.dart"
participant C as "SalesOrderController<br/>sales_order_controller.dart"
participant A as "SalesOrderApiService<br/>sales_order_api_service.dart"
participant B as "SalesController<br/>sales.controller.ts"
participant S as "SalesService<br/>sales.service.ts"
participant D as "DB Schema<br/>schema.ts"
U->>F : "Fill invoice form and click Save"
F->>C : "createSalesOrder(SalesOrder)"
C->>A : "createSalesOrder(payload)"
A->>B : "POST /sales"
B->>S : "createSalesOrder(data)"
S->>D : "INSERT sales_orders"
S-->>B : "Created record"
B-->>A : "201/200 Created"
A-->>C : "SalesOrder"
C-->>F : "Refresh list and close"
```

**Diagram sources**
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L525-L565)
- [sales_order_controller.dart](file://lib/modules/sales/controller/sales_order_controller.dart#L86-L95)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L104-L121)
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L91-L95)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L80-L97)
- [schema.ts](file://backend/src/db/schema.ts#L236-L253)

## Detailed Component Analysis

### Invoice Creation Workflow
- Numbering Scheme: The invoice number is auto-generated with a pattern combining a prefix and timestamp.
- Totals Calculation: Subtotal is computed from line items; shipping and adjustment are added; totals are recalculated reactively.
- Payload Construction: The screen composes a SalesOrder with items and posts it to the backend.
- Status and Document Type: Invoices are saved with a confirmed status and document type set to invoice.

```mermaid
flowchart TD
Start(["Open Invoice Screen"]) --> Init["Initialize Controllers<br/>Set Invoice# with timestamp"]
Init --> AddRows["Add Line Items"]
AddRows --> EditQty["Edit Quantity/Rate/Discount"]
EditQty --> Recalc["Recalculate Subtotal and Total"]
Recalc --> CustomerSel["Select Customer"]
CustomerSel --> Submit{"Ready to Save?"}
Submit --> |Yes| BuildPayload["Build SalesOrder Payload"]
BuildPayload --> CallAPI["Call createSalesOrder"]
CallAPI --> Persist["Persist to DB"]
Persist --> Done(["Close and Refresh"])
Submit --> |No| EditQty
```

**Diagram sources**
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L48-L108)
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L525-L565)
- [sales_order_model.dart](file://lib/modules/sales/models/sales_order_model.dart#L28-L51)

**Section sources**
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L48-L108)
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L525-L565)
- [sales_order_model.dart](file://lib/modules/sales/models/sales_order_model.dart#L28-L51)

### Delivery Challan Creation Workflow
- Numbering Scheme: Challan number uses a distinct prefix and timestamp.
- Document Type: Stored as a challan document type.
- Payload Construction: Similar to invoices but without tax totals and simplified fields.

```mermaid
sequenceDiagram
participant U as "User"
participant F as "Challan Screen<br/>sales_delivery_challan_create.dart"
participant C as "SalesOrderController"
participant A as "SalesOrderApiService"
participant B as "SalesController"
participant S as "SalesService"
U->>F : "Fill challan form and click Save"
F->>C : "createSalesOrder(SalesOrder : challan)"
C->>A : "createSalesOrder(payload)"
A->>B : "POST /sales"
B->>S : "createSalesOrder(data)"
S-->>B : "Created record"
B-->>A : "201/200 Created"
A-->>C : "SalesOrder"
C-->>F : "Navigate back"
```

**Diagram sources**
- [sales_delivery_challan_create.dart](file://lib/modules/sales/presentation/sales_delivery_challan_create.dart#L304-L341)
- [sales_order_controller.dart](file://lib/modules/sales/controller/sales_order_controller.dart#L86-L95)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L104-L121)
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L91-L95)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L80-L97)

**Section sources**
- [sales_delivery_challan_create.dart](file://lib/modules/sales/presentation/sales_delivery_challan_create.dart#L304-L341)
- [sales_order_model.dart](file://lib/modules/sales/models/sales_order_model.dart#L28-L51)

### Tax Calculation Automation
- Tax Rate Model: Provides tax name, rate, type (IGST/CGST/SGST), and active status.
- Current Implementation: The invoice screen computes subtotal and total but does not compute per-item tax amounts in the frontend. Tax totals are expected to be managed by the backend or extended in the future.
- GST Compliance: The backend includes a mock GSTIN lookup endpoint; the frontend model supports GSTIN-related fields in customer records.

```mermaid
classDiagram
class TaxRate {
+string id
+string taxName
+double taxRate
+string taxType
+bool isActive
+fromJson(json) TaxRate
+toJson() Map
}
class SalesOrderItem {
+string? id
+string itemId
+string? description
+double quantity
+double rate
+double discount
+string? taxId
+double taxAmount
+double itemTotal
+Item? item
}
class SalesOrder {
+string id
+string customerId
+string saleNumber
+string? reference
+DateTime saleDate
+DateTime? expectedShipmentDate
+string? paymentTerms
+string? deliveryMethod
+string? salesperson
+string status
+string documentType
+double subTotal
+double taxTotal
+double discountTotal
+double shippingCharges
+double adjustment
+double total
+string? customerNotes
+string? termsAndConditions
+SalesCustomer? customer
+SalesOrderItem[]? items
+DateTime? createdAt
}
SalesOrder --> SalesOrderItem : "contains"
```

**Diagram sources**
- [tax_rate_model.dart](file://lib/modules/items/models/tax_rate_model.dart#L1-L38)
- [sales_order_item_model.dart](file://lib/modules/sales/models/sales_order_item_model.dart#L1-L62)
- [sales_order_model.dart](file://lib/modules/sales/models/sales_order_model.dart#L1-L118)

**Section sources**
- [tax_rate_model.dart](file://lib/modules/items/models/tax_rate_model.dart#L1-L38)
- [sales_order_item_model.dart](file://lib/modules/sales/models/sales_order_item_model.dart#L1-L62)
- [sales_order_model.dart](file://lib/modules/sales/models/sales_order_model.dart#L1-L118)
- [gstin_lookup_model.dart](file://lib/modules/sales/models/gstin_lookup_model.dart#L1-L173)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L8-L27)

### Invoice Modification and Cancellation Procedures
- Modification: The current UI saves invoices as confirmed and does not expose editing fields after save. To support modifications, extend the invoice screen to load existing records and allow edits while preserving audit trails.
- Cancellation: The backend exposes a DELETE endpoint for sales records. Invoke it via the API service to cancel an invoice by ID.

```mermaid
sequenceDiagram
participant U as "User"
participant C as "SalesOrderController"
participant A as "SalesOrderApiService"
participant B as "SalesController"
U->>C : "deleteSalesOrder(id)"
C->>A : "deleteSalesOrder(id)"
A->>B : "DELETE /sales/ : id"
B-->>A : "200/204 Deleted"
A-->>C : "void"
C-->>U : "Refresh list"
```

**Diagram sources**
- [sales_order_controller.dart](file://lib/modules/sales/controller/sales_order_controller.dart#L97-L105)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L123-L132)
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L97-L100)

**Section sources**
- [sales_order_controller.dart](file://lib/modules/sales/controller/sales_order_controller.dart#L97-L105)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L123-L132)
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L97-L100)

### Practical Examples of Invoice Generation Scenarios
- Scenario A: Single product invoice with flat discount and shipping charge.
- Scenario B: Multiple line items with varying quantities and discounts.
- Scenario C: Invoice with customer notes and terms and conditions.
- Scenario D: Delivery challan with job work type and reference number.

These scenarios are supported by the invoice and challan screens’ reactive totals and item table logic.

**Section sources**
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L91-L108)
- [sales_delivery_challan_create.dart](file://lib/modules/sales/presentation/sales_delivery_challan_create.dart#L167-L247)

### Integration with Accounting Systems
- Payment Links: The backend supports generating payment links for invoices, enabling accounting reconciliation.
- Payment Records: The backend persists sales payments with modes, references, and amounts.
- GSTIN Lookup: The backend provides a mock GSTIN lookup endpoint for compliance verification.

```mermaid
graph LR
Invoice["Invoice Record<br/>sales_orders"] --> Payments["Payments<br/>sales_payments"]
Invoice --> Eway["E-Way Bills<br/>sales_eway_bills"]
Invoice --> Links["Payment Links<br/>sales_payment_links"]
GSTIN["GSTIN Lookup<br/>GET /sales/gstin/lookup"] --> Invoice
```

**Diagram sources**
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L35-L39)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L8-L27)
- [schema.ts](file://backend/src/db/schema.ts#L254-L291)

**Section sources**
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L35-L39)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L8-L27)
- [schema.ts](file://backend/src/db/schema.ts#L254-L291)

### Invoice Templates and Bulk Processing
- Templates: The UI renders standardized invoice layouts with customer info, items, totals, and notes. Templates can be exported to PDF/print-ready formats in the UI layer.
- Bulk Processing: The backend supports retrieving invoices by type and paginated lists. Extend the UI to batch-select invoices and process them in bulk.

**Section sources**
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L111-L134)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L42-L57)

### GST Compliance Requirements
- GSTIN Lookup: The backend exposes a GSTIN lookup endpoint for legal name, trade name, status, taxpayer type, and addresses.
- Customer Fields: The customer model includes GSTIN and PAN fields to capture GST compliance data.
- Tax Types: TaxRate supports IGST, CGST, and SGST types for accurate tax reporting.

**Section sources**
- [gstin_lookup_model.dart](file://lib/modules/sales/models/gstin_lookup_model.dart#L1-L173)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L8-L27)
- [schema.ts](file://backend/src/db/schema.ts#L213-L234)
- [tax_rate_model.dart](file://lib/modules/items/models/tax_rate_model.dart#L1-L38)

## Dependency Analysis
- UI depends on Riverpod providers for customers and sales data.
- Controller depends on API service for network operations.
- API service depends on shared API client and backend endpoints.
- Backend controller depends on service for business logic.
- Service depends on database schema for persistence.

```mermaid
graph TB
UI["Invoice/Challan Screens"] --> CTRL["SalesOrderController"]
CTRL --> API["SalesOrderApiService"]
API --> BC["SalesController"]
BC --> BS["SalesService"]
BS --> DB["DB Schema"]
subgraph "Frontend"
UI
CTRL
API
end
subgraph "Backend"
BC
BS
DB
end
```

**Diagram sources**
- [sales_order_controller.dart](file://lib/modules/sales/controller/sales_order_controller.dart#L1-L119)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L1-L192)
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L1-L102)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L1-L162)
- [schema.ts](file://backend/src/db/schema.ts#L236-L253)

**Section sources**
- [sales_order_controller.dart](file://lib/modules/sales/controller/sales_order_controller.dart#L1-L119)
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L1-L192)
- [sales.controller.ts](file://backend/src/sales/sales.controller.ts#L1-L102)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L1-L162)
- [schema.ts](file://backend/src/db/schema.ts#L236-L253)

## Performance Considerations
- Reactive Calculations: Totals are recalculated on each input change; consider debouncing for large item lists.
- Network Calls: Batch UI updates and avoid redundant refreshes after successful saves.
- Backend Pagination: Use query parameters to limit invoice lists and improve UI responsiveness.

## Troubleshooting Guide
- Error Handling: API service logs detailed error messages and status codes; UI displays snackbars for user feedback.
- Validation: Ensure required fields (customer, items) are present before saving.
- Debugging: Inspect payload sent to backend and server-side logs for discrepancies.

**Section sources**
- [sales_order_api_service.dart](file://lib/modules/sales/services/sales_order_api_service.dart#L114-L120)
- [sales_invoice_invoice_create.dart](file://lib/modules/sales/presentation/sales_invoice_invoice_create.dart#L558-L564)

## Conclusion
The ZerpAI ERP invoicing system provides a robust foundation for invoice and challan creation, with clear separation between UI, state management, API service, and backend logic. While tax computation is currently handled outside the invoice screen, the system’s schema and models support GST compliance and future enhancements. Extending the UI to support invoice modifications and cancellations, and integrating automated tax calculations, will further strengthen the system’s capabilities.

## Appendices
- Data Model Overview

```mermaid
erDiagram
CUSTOMERS {
uuid id PK
string display_name
string customer_type
string salutation
string first_name
string last_name
string company_name
string email
string phone
string mobile_phone
string gstin
string pan
string currency
string payment_terms
text billing_address
text shipping_address
boolean is_active
numeric receivables
timestamp created_at
}
SALES_ORDERS {
uuid id PK
uuid customer_id FK
string sale_number UK
string reference
timestamp sale_date
timestamp expected_shipment_date
string delivery_method
string payment_terms
string document_type
string status
numeric total
string currency
text customer_notes
text terms_and_conditions
timestamp created_at
}
SALES_PAYMENTS {
uuid id PK
uuid customer_id FK
string payment_number UK
timestamp payment_date
string payment_mode
numeric amount
numeric bank_charges
string reference
string deposit_to
text notes
timestamp created_at
}
SALES_EWAY_BILLS {
uuid id PK
uuid sale_id FK
string bill_number UK
timestamp bill_date
string supply_type
string sub_type
string transporter_id
string vehicle_number
string status
timestamp created_at
}
SALES_PAYMENT_LINKS {
uuid id PK
uuid customer_id FK
numeric amount
text link_url
string status
timestamp created_at
}
CUSTOMERS ||--o{ SALES_ORDERS : "has"
CUSTOMERS ||--o{ SALES_PAYMENTS : "has"
SALES_ORDERS ||--o{ SALES_EWAY_BILLS : "generates"
CUSTOMERS ||--o{ SALES_PAYMENT_LINKS : "creates"
```

**Diagram sources**
- [schema.ts](file://backend/src/db/schema.ts#L213-L291)