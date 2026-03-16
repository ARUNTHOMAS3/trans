# Sales — Customers Flow

## Customer Create Flow

```mermaid
flowchart TD
    PAGE[sales_customers_customer_create.dart] --> LOAD[Load lookups]
    LOAD --> L1[GET /lookups/currencies]
    LOAD --> L2[GET /lookups/payment-terms]
    LOAD --> L3[GET /sales/hsn/search]

    LOAD --> FORM[Multi-section form]
    FORM --> S1[Primary Info\ndisplay name, company, GSTIN]
    FORM --> S2[Address\nbilling + shipping]
    FORM --> S3[Contact Persons\nmultiple rows]
    FORM --> S4[Financial Details\ncurrency, payment terms, credit limit]
    FORM --> S5[Custom Fields]
    FORM --> S6[Remarks]

    FORM --> GSTIN_CHECK[GSTIN entered]
    GSTIN_CHECK --> LOOKUP[GstinLookupService\nGET /sales/gstin/lookup/:gstin]
    LOOKUP -->|found| AUTO_FILL[Auto-fill company name\n+ address from GST portal]
    LOOKUP -->|not found| MANUAL[Manual entry]

    FORM --> SAVE[Save]
    SAVE --> VALID{Validate}
    VALID -->|fail| ERR[Field errors\nsentence case messages]
    VALID -->|pass| CTRL[CustomersRepository.create]
    CTRL --> API[POST /api/v1/sales/customers]
    API -->|success| TOAST[ZerpaiToast success]
    API -->|fail| TOAST_ERR[ZerpaiToast error]
```

## Customer List Flow

```mermaid
flowchart TD
    PAGE[sales_customers_overview.dart] --> PROV[salesCustomersProvider]
    PROV --> REPO[CustomersRepository]
    REPO --> TRY{Online?}
    TRY -->|yes| API[GET /api/v1/sales/customers\n?page&limit&search]
    TRY -->|no| HIVE[(Hive cache)]
    API --> CACHE[Cache to Hive]
    CACHE --> TABLE[Render table]
    HIVE --> TABLE

    TABLE --> FILTER[Filters\nstatus, balance, created date]
    TABLE --> BULK[Bulk actions\nexport, delete]
    TABLE --> IMPORT[Import CSV]

    TABLE --> ROW[Row click]
    ROW --> DETAIL[/sales/customers/:id]
```

## Customer Detail Flow

```mermaid
flowchart TD
    PAGE[sales_customers_customer_detail.dart\n:id] --> LOAD[GET /api/v1/sales/customers/:id]
    LOAD --> TABS[Tabs]
    TABS --> T1[Overview\nbalance, contact info]
    TABS --> T2[Transactions\norders + invoices + payments]
    TABS --> T3[Addresses]
    TABS --> T4[Contact Persons]
    TABS --> T5[Custom Fields]

    TABS --> EDIT_BTN[Edit]
    EDIT_BTN --> PUT[PUT /api/v1/sales/customers/:id]
```

## Backend Flow — Customers Service

```mermaid
flowchart TD
    CTRL[CustomersController] --> SVC[CustomersService]

    SVC --> GET_ALL[getAll\nfilter by org_id + search + pagination]
    SVC --> GET_ONE[getById\nwith contact persons + addresses]
    SVC --> CREATE[create\ninsert customers\ninsert customer_contact_persons]
    SVC --> UPDATE[update\nupsert addresses + contacts]

    GET_ALL --> DRIZZLE[(Drizzle ORM)]
    GET_ONE --> DRIZZLE
    CREATE --> DRIZZLE
    UPDATE --> DRIZZLE

    DRIZZLE --> DB[(customers\ncustomer_contact_persons)]
```

## Customer Data Model

```mermaid
classDiagram
    class CustomerModel {
        +String id
        +String orgId
        +String displayName
        +String? companyName
        +String? gstin
        +String? email
        +String? phone
        +String currency
        +double creditLimit
        +double outstandingBalance
        +List~Address~ addresses
        +List~ContactPerson~ contactPersons
        +Map customFields
    }

    class Address {
        +String type
        +String street
        +String city
        +String state
        +String pincode
        +String country
    }

    class ContactPerson {
        +String name
        +String phone
        +String email
        +String designation
    }

    CustomerModel --> Address
    CustomerModel --> ContactPerson
```
