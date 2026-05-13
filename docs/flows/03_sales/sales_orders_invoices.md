# Sales — Orders & Invoices Flow

## Document Type Shared Model

```mermaid
graph LR
    MODEL[SalesOrderModel] --> TYPES

    TYPES --> ORDER[type: order\n/sales/orders]
    TYPES --> INVOICE[type: invoice\n/sales/invoices]
    TYPES --> QUOTE[type: quotation\n/sales/quotations]
    TYPES --> CHALLAN[type: delivery_challan\n/sales/delivery-challans]
    TYPES --> RETAINER[type: retainer_invoice\n/sales/retainer-invoices]
```

## Create Sales Invoice Flow

```mermaid
flowchart TD
    PAGE[sales_invoices_create.dart] --> LOAD[Load reference data in parallel]
    LOAD --> L1[GET /sales/customers]
    LOAD --> L2[GET /products]
    LOAD --> L3[GET /lookups/payment-terms]
    LOAD --> L4[GET /sequences/invoice/next\nauto-generate invoice number]
    LOAD --> L5[GET /products/pricelist\nfor price lookup]

    LOAD --> FORM[Invoice form]
    FORM --> H[Header\ncustomer selector, invoice#, date, due date]
    FORM --> ITEMS_TBL[Line items table]
    ITEMS_TBL --> ROW[Each row:\nproduct + qty + unit + price + tax + discount]
    ROW --> HSN_FILL[Auto-fill HSN/SAC from product]
    ROW --> TAX_CALC[TaxEngine.calculate\nCGST/SGST or IGST based on state]
    ROW --> PRICE_FILL[Price from pricelist if assigned]

    FORM --> SUMMARY[Summary panel\nsubtotal + tax breakdown + total]
    FORM --> NOTES[Notes + Terms + Attachments]

    FORM --> SAVE[Ctrl+S → Draft]
    FORM --> PUBLISH[Ctrl+Enter → Publish]

    SAVE --> CTRL[SalesOrderController]
    PUBLISH --> CTRL
    CTRL --> REPO[SalesOrdersRepository]
    REPO --> API[POST /api/v1/sales/orders\nor /sales/invoices]
    API -->|success| NAV[Navigate to detail\nZerpaiToast]
    API -->|fail| TOAST[ZerpaiToast error]
```

## Invoice Status State Machine

```mermaid
stateDiagram-v2
    [*] --> Draft : Create (Ctrl+S)
    Draft --> Sent : Send to customer
    Draft --> Void : Void
    Sent --> PartiallyPaid : Payment received < total
    Sent --> Paid : Full payment received
    PartiallyPaid --> Paid : Remaining payment
    Paid --> [*]
    Sent --> Overdue : Past due date (auto)
    Overdue --> Paid : Payment received
    Sent --> Void : Void
    Draft --> [*] : Delete
```

## Sales Order → Invoice Conversion

```mermaid
flowchart TD
    ORDER[Sales Order\nstatus: confirmed] --> CONVERT[Convert to Invoice button]
    CONVERT --> NEW_INV[Create invoice\npre-filled from order data]
    NEW_INV --> LINK[Link: invoice.sales_order_id = order.id]
    NEW_INV --> SEQ[GET /sequences/invoice/next]
    NEW_INV --> SAVE[POST /api/v1/sales/invoices]
```

## Generic List Screen Flow (all doc types share this)

```mermaid
flowchart TD
    LIST_PAGE[GenericSalesListScreen] --> PROV[provider by type\ne.g. salesInvoicesProvider]
    PROV --> API[GET /api/v1/sales/:type\n?page&limit&status&dateFrom&dateTo&search]
    API --> TABLE[Data table\n100 rows default]

    TABLE --> FILTERS[Filter bar\nstatus, date range, customer, amount range]
    TABLE --> SEARCH[Search field\n/ shortcut to focus]
    TABLE --> BULK[Bulk operations\nexport CSV, bulk delete, bulk status update]
    TABLE --> IMPORT[Import CSV]

    TABLE --> ROW[Row click → detail panel]
    TABLE --> ACTIONS[Row actions menu\nMenuAnchor]
    ACTIONS --> A1[Edit]
    ACTIONS --> A2[Clone]
    ACTIONS --> A3[Void]
    ACTIONS --> A4[Record payment]
    ACTIONS --> A5[Print / Download PDF]
```

## Payment Recording Flow

```mermaid
flowchart TD
    BTN[Record Payment button] --> DIALOG[Payment dialog]
    DIALOG --> D1[Amount]
    DIALOG --> D2[Payment date]
    DIALOG --> D3[Payment mode\ncash/bank/UPI]
    DIALOG --> D4[Reference number]
    DIALOG --> D5[Account to credit\naccount tree dropdown]

    DIALOG --> CONFIRM[Confirm]
    CONFIRM --> REPO[PaymentsRepository]
    REPO --> API[POST /api/v1/sales/payments-received]
    API --> COA[Auto-creates account_transaction\nDebit: A/R, Credit: payment account]
    API --> INV_UPDATE[Update invoice status\npartially_paid or paid]
```

## Data Model

```mermaid
classDiagram
    class SalesOrderModel {
        +String id
        +String orgId
        +String branchId
        +String type
        +String number
        +String customerId
        +DateTime date
        +DateTime? dueDate
        +String status
        +List~SalesOrderItem~ items
        +double subtotal
        +double taxAmount
        +double total
        +double amountPaid
        +double balance
        +String? notes
        +String? terms
    }

    class SalesOrderItem {
        +String productId
        +String productName
        +String hsnSac
        +double quantity
        +String unitId
        +double unitPrice
        +double discountPercent
        +double taxPercent
        +String taxType
        +double lineTotal
    }

    class SalesPaymentModel {
        +String id
        +String orgId
        +String invoiceId
        +double amount
        +DateTime paymentDate
        +String paymentMode
        +String? referenceNumber
        +String creditAccountId
    }

    SalesOrderModel --> SalesOrderItem
    SalesOrderModel --> SalesPaymentModel
```
