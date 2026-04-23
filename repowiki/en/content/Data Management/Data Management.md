# Data Management
**Last Updated: 2026-04-20 12:46:08**

<cite>
**Referenced Files in This Document**
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql)
- [002_seed_data.sql](file://supabase/migrations/002_seed_data.sql)
- [README.md](file://supabase/migrations/README.md)
- [schema.ts](file://backend/src/db/schema.ts)
- [db.ts](file://backend/src/db/db.ts)
- [drizzle.config.ts](file://backend/drizzle.config.ts)
- [supabase.service.ts](file://backend/src/supabase/supabase.service.ts)
- [tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts)
- [products.service.ts](file://backend/src/products/products.service.ts)
- [sales.service.ts](file://backend/src/sales/sales.service.ts)
- [api_client.dart](file://lib/shared/services/api_client.dart)
- [hive_service.dart](file://lib/shared/services/hive_service.dart)
- [storage_service.dart](file://lib/shared/services/storage_service.dart)
- [items_repository.dart](file://lib/modules/items/repositories/items_repository.dart)
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart)
- [supabase_item_repository.dart](file://lib/modules/items/repositories/supabase_item_repository.dart)
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
This document describes the data management strategy for ZerpAI ERP, covering database schema design, Supabase integration, row-level security (RLS), multi-tenant isolation, local storage with Hive, API integration patterns, synchronization mechanisms, migrations, data seeding, validation, indexing, performance optimization, audit logging, and security measures. It also provides examples of common data operations and troubleshooting guidance.

## Project Structure
ZerpAI ERP separates concerns across:
- Backend (NestJS) with Drizzle ORM for schema and Supabase client for product data
- Frontend (Flutter) with Hive for offline caching and R2 for images
- Supabase migrations for schema and seed data

```mermaid
graph TB
subgraph "Frontend (Flutter)"
API["ApiClient<br/>Dio"]
Repo["ItemsRepositoryImpl<br/>Offline-first"]
Hive["HiveService<br/>Local Cache"]
R2["StorageService<br/>Cloudflare R2"]
end
subgraph "Backend (NestJS)"
SupabaseSvc["SupabaseService"]
ProdSvc["ProductsService"]
SalesSvc["SalesService"]
Drizzle["Drizzle ORM<br/>schema.ts"]
DB["PostgreSQL"]
end
subgraph "Supabase"
Migrations["Migrations<br/>001_* / 002_*"]
end
API --> ProdSvc
API --> SalesSvc
Repo --> API
Repo --> Hive
ProdSvc --> SupabaseSvc
SupabaseSvc --> DB
Drizzle --> DB
Migrations --> DB
R2 <- --> API
```

**Diagram sources**
- [api_client.dart](file://lib/shared/services/api_client.dart#L1-L62)
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L1-L297)
- [hive_service.dart](file://lib/shared/services/hive_service.dart#L1-L134)
- [storage_service.dart](file://lib/shared/services/storage_service.dart#L1-L227)
- [supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L1-L32)
- [products.service.ts](file://backend/src/products/products.service.ts#L1-L723)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L1-L162)
- [schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [db.ts](file://backend/src/db/db.ts#L1-L13)
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L1-L218)
- [002_seed_data.sql](file://supabase/migrations/002_seed_data.sql#L1-L88)

**Section sources**
- [api_client.dart](file://lib/shared/services/api_client.dart#L1-L62)
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L1-L297)
- [hive_service.dart](file://lib/shared/services/hive_service.dart#L1-L134)
- [storage_service.dart](file://lib/shared/services/storage_service.dart#L1-L227)
- [supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L1-L32)
- [products.service.ts](file://backend/src/products/products.service.ts#L1-L723)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L1-L162)
- [schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [db.ts](file://backend/src/db/db.ts#L1-L13)
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L1-L218)
- [002_seed_data.sql](file://supabase/migrations/002_seed_data.sql#L1-L88)

## Core Components
- Database schema: Drizzle ORM schema defines entities and enums; Supabase migrations define initial tables, indexes, and RLS policies.
- Supabase client: Backend initializes a Supabase client for product data operations.
- Middleware: Tenant middleware injects unified entity context via x-entity-id header.
- Services: ProductsService orchestrates product CRUD and metadata sync; SalesService handles sales entities via Drizzle.
- Offline-first repository: ItemsRepositoryImpl integrates API calls with Hive caching and fallback.
- Local storage: HiveService manages boxes for products, customers, POS drafts, and config; StorageService uploads/deletes images to Cloudflare R2.
- API client: ApiClient centralizes HTTP requests with timeouts and interceptors.

**Section sources**
- [schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [db.ts](file://backend/src/db/db.ts#L1-L13)
- [supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L1-L32)
- [tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L1-L70)
- [products.service.ts](file://backend/src/products/products.service.ts#L1-L723)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L1-L162)
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L1-L297)
- [hive_service.dart](file://lib/shared/services/hive_service.dart#L1-L134)
- [storage_service.dart](file://lib/shared/services/storage_service.dart#L1-L227)
- [api_client.dart](file://lib/shared/services/api_client.dart#L1-L62)

## Architecture Overview
The system follows an online-first architecture with offline fallback:
- API requests are attempted first; successful responses are cached to Hive.
- On failure, the repository falls back to Hive cache.
- Image assets are uploaded to Cloudflare R2 via StorageService.
- Backend services use Supabase for product data and Drizzle for sales data.

```mermaid
sequenceDiagram
participant UI as "UI Layer"
participant Repo as "ItemsRepositoryImpl"
participant API as "ProductsApiService"
participant Hive as "HiveService"
participant Supabase as "SupabaseService"
participant DB as "PostgreSQL"
UI->>Repo : getItems()
Repo->>API : GET /products
alt Success
API-->>Repo : List<Item>
Repo->>Hive : saveProducts(items)
Repo-->>UI : List<Item>
else Network/API Error
API-->>Repo : throws
Repo->>Hive : getProducts()
Hive-->>Repo : List<Item>
Repo-->>UI : List<Item> (offline)
end
UI->>Repo : createItem(item)
Repo->>API : POST /products
API-->>Repo : Item
Repo->>Hive : saveProduct(item)
Repo-->>UI : Item
UI->>Repo : updateItem(item)
Repo->>API : PUT /products/ : id
API-->>Repo : Item
Repo->>Hive : saveProduct(item)
Repo-->>UI : Item
UI->>Repo : deleteItem(id)
Repo->>API : DELETE /products/ : id
API-->>Repo : ok
Repo->>Hive : deleteProduct(id)
Repo-->>UI : void
```

**Diagram sources**
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L24-L272)
- [hive_service.dart](file://lib/shared/services/hive_service.dart#L19-L45)
- [api_client.dart](file://lib/shared/services/api_client.dart#L46-L60)
- [supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L28-L30)
- [products.service.ts](file://backend/src/products/products.service.ts#L18-L89)

## Detailed Component Analysis

### Database Schema Design
- Entities: products, categories, vendors, units, tax rates, accounts, storage locations, racks, reorder terms, manufacturers, brands, product compositions, customers, sales orders/payments/e-way bills/payment links.
- Enums: product type, tax preference, inventory valuation method, unit type, tax type, account type, vendor type.
- Keys and constraints: UUID primary keys, unique constraints on entity-scoped identifiers, foreign keys, and JSON-like fields stored as text.
- Indexes: composite indexes on entity_id and selective columns for performance.
- RLS: Policies and enable statements were intentionally removed for development; re-enable before production.

```mermaid
erDiagram
UNITS {
uuid id PK
string unit_name UK
string unit_symbol
enum unit_type
boolean is_active
timestamptz created_at
}
CATEGORIES {
uuid id PK
uuid parent_id FK
string name UK
text description
boolean is_active
timestamptz created_at
}
TAX_RATES {
uuid id PK
string tax_name UK
decimal tax_rate
enum tax_type
boolean is_active
timestamptz created_at
}
MANUFACTURERS {
uuid id PK
string name UK
text contact_info
boolean is_active
timestamptz created_at
}
BRANDS {
uuid id PK
uuid manufacturer_id FK
string name UK
boolean is_active
timestamptz created_at
}
ACCOUNTS {
uuid id PK
string account_name UK
enum account_type
string account_code
boolean is_active
timestamptz created_at
}
STORAGE_LOCATIONS {
uuid id PK
string location_name UK
string temperature_range
text description
boolean is_active
timestamptz created_at
}
RACKS {
uuid id PK
string rack_code UK
string rack_name
uuid storage_id FK
integer capacity
boolean is_active
timestamptz created_at
}
REORDER_TERMS {
uuid id PK
string term_name UK
string preset_formula
text description
boolean is_active
timestamptz created_at
}
VENDORS {
uuid id PK
string vendor_name UK
enum vendor_type
string contact_person
string email
string phone
text address
string gstin
string drug_license_no
boolean is_active
timestamptz created_at
}
PRODUCTS {
uuid id PK
enum type
string product_name
string billing_name
string item_code UK
string sku UK
uuid unit_id FK
uuid category_id FK
boolean is_returnable
boolean push_to_ecommerce
string hsn_code
enum tax_preference
uuid intra_state_tax_id FK
uuid inter_state_tax_id FK
text primary_image_url
text image_urls
decimal selling_price
string selling_price_currency
decimal mrp
decimal ptr
uuid sales_account_id FK
text sales_description
decimal cost_price
string cost_price_currency
uuid purchase_account_id FK
uuid preferred_vendor_id FK
text purchase_description
decimal length
decimal width
decimal height
string dimension_unit
decimal weight
string weight_unit
uuid manufacturer_id FK
uuid brand_id FK
string mpn
string upc
string isbn
string ean
boolean track_assoc_ingredients
string buying_rule
string schedule_of_drug
boolean is_track_inventory
boolean track_bin_location
boolean track_batches
uuid inventory_account_id FK
enum inventory_valuation_method
uuid storage_id FK
uuid rack_id FK
integer reorder_point
uuid reorder_term_id FK
boolean is_active
boolean is_lock
timestamptz created_at
uuid created_by_id
timestamptz updated_at
uuid updated_by_id
}
PRODUCT_COMPOSITIONS {
uuid id PK
uuid product_id FK
string content_name
decimal strength
string strength_unit
string schedule
integer display_order
timestamptz created_at
}
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
decimal receivables
timestamptz created_at
}
SALES_ORDERS {
uuid id PK
uuid customer_id FK
string sale_number UK
string reference
timestamptz sale_date
timestamptz expected_shipment_date
string delivery_method
string payment_terms
string document_type
string status
decimal total
string currency
text customer_notes
text terms_and_conditions
timestamptz created_at
}
SALES_PAYMENTS {
uuid id PK
uuid customer_id FK
string payment_number UK
timestamptz payment_date
string payment_mode
decimal amount
decimal bank_charges
string reference
string deposit_to
text notes
timestamptz created_at
}
SALES_EWAY_BILLS {
uuid id PK
uuid sale_id FK
string bill_number UK
timestamptz bill_date
string supply_type
string sub_type
string transporter_id
string vehicle_number
string status
timestamptz created_at
}
SALES_PAYMENT_LINKS {
uuid id PK
uuid customer_id FK
decimal amount
text link_url
string status
timestamptz created_at
}
PRODUCTS ||--o{ PRODUCT_COMPOSITIONS : "has"
UNITS ||--o{ PRODUCTS : "unit_id"
CATEGORIES ||--o{ PRODUCTS : "category_id"
TAX_RATES ||--o{ PRODUCTS : "intra_state_tax_id"
TAX_RATES ||--o{ PRODUCTS : "inter_state_tax_id"
ACCOUNTS ||--o{ PRODUCTS : "sales_account_id"
ACCOUNTS ||--o{ PRODUCTS : "purchase_account_id"
ACCOUNTS ||--o{ PRODUCTS : "inventory_account_id"
VENDORS ||--o{ PRODUCTS : "preferred_vendor_id"
MANUFACTURERS ||--o{ PRODUCTS : "manufacturer_id"
BRANDS ||--o{ PRODUCTS : "brand_id"
STORAGE_LOCATIONS ||--o{ PRODUCTS : "storage_id"
RACKS ||--o{ PRODUCTS : "rack_id"
REORDER_TERMS ||--o{ PRODUCTS : "reorder_term_id"
CUSTOMERS ||--o{ SALES_ORDERS : "customer_id"
CUSTOMERS ||--o{ SALES_PAYMENTS : "customer_id"
SALES_ORDERS ||--o{ SALES_EWAY_BILLS : "sale_id"
```

**Diagram sources**
- [schema.ts](file://backend/src/db/schema.ts#L1-L293)

**Section sources**
- [schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L24-L141)

### Supabase Integration and Multi-Tenant Isolation
- Supabase client initialization with service role key and disabled auth persistence.
- Tenant context injection via middleware; currently bypassed for testing; production-ready code is commented and can be enabled.
- Product operations use Supabase client for create/read/update/delete and metadata sync helpers.

```mermaid
sequenceDiagram
participant Client as "Client"
participant MW as "TenantMiddleware"
participant Ctrl as "ProductsController"
participant Svc as "ProductsService"
participant SB as "SupabaseService"
participant DB as "PostgreSQL"
Client->>MW : Request with x-entity-id
MW-->>Ctrl : tenantContext (entityId/role)
Ctrl->>Svc : create/find/update/remove
Svc->>SB : getClient()
SB-->>Svc : SupabaseClient
Svc->>DB : SQL operations (RLS applies)
DB-->>Svc : Results
Svc-->>Ctrl : Data
Ctrl-->>Client : Response
```

**Diagram sources**
- [tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L24-L68)
- [supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L10-L30)
- [products.service.ts](file://backend/src/products/products.service.ts#L18-L194)

**Section sources**
- [supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L1-L32)
- [tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L1-L70)
- [products.service.ts](file://backend/src/products/products.service.ts#L1-L723)

### Local Storage Strategy with Hive and Offline Patterns
- HiveService provides typed boxes for products, customers, POS drafts, and config.
- ItemsRepositoryImpl implements online-first with Hive caching and fallback:
  - Fetch from API; on success, cache to Hive and update last sync timestamps.
  - On network/API errors, fall back to Hive cache.
  - Supports force refresh, offline availability check, and cache stats.

```mermaid
flowchart TD
Start(["getItems()"]) --> TryAPI["Call API getProducts()"]
TryAPI --> APISuccess{"API Success?"}
APISuccess --> |Yes| Cache["Save to Hive<br/>updateLastSyncTime"]
Cache --> ReturnAPI["Return API data"]
APISuccess --> |No| TryCache["Read Hive cache"]
TryCache --> CacheSuccess{"Cache Success?"}
CacheSuccess --> |Yes| ReturnCache["Return cached data"]
CacheSuccess --> |No| ReturnEmpty["Return empty list"]
ReturnAPI --> End(["Done"])
ReturnCache --> End
ReturnEmpty --> End
```

**Diagram sources**
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L24-L112)
- [hive_service.dart](file://lib/shared/services/hive_service.dart#L19-L45)

**Section sources**
- [hive_service.dart](file://lib/shared/services/hive_service.dart#L1-L134)
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L1-L297)

### API Integration Patterns and Synchronization
- ApiClient centralizes HTTP configuration and interceptors.
- ProductsService exposes CRUD and metadata sync helpers:
  - create/findOne/update/remove for products
  - lookup methods for units, categories, tax rates, manufacturers, brands, vendors, storage, racks, reorder terms, accounts, contents, strengths, buying rules, schedules
  - Generic syncTableMetadata with upsert and deactivation of unused records
- SalesService uses Drizzle ORM for customers, sales orders, payments, e-way bills, and payment links.

```mermaid
sequenceDiagram
participant Repo as "ItemsRepositoryImpl"
participant API as "ProductsApiService"
participant Svc as "ProductsService"
participant SB as "SupabaseService"
participant DB as "PostgreSQL"
Repo->>API : createProduct(item)
API->>Svc : create(dto, userId)
Svc->>SB : getClient()
SB-->>Svc : SupabaseClient
Svc->>DB : INSERT products (+ compositions)
DB-->>Svc : Product
Svc-->>API : Product
API-->>Repo : Product
Repo->>Hive : saveProduct(Product)
```

**Diagram sources**
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L166-L197)
- [products.service.ts](file://backend/src/products/products.service.ts#L18-L89)
- [supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L28-L30)

**Section sources**
- [api_client.dart](file://lib/shared/services/api_client.dart#L1-L62)
- [products.service.ts](file://backend/src/products/products.service.ts#L1-L723)
- [sales.service.ts](file://backend/src/sales/sales.service.ts#L1-L162)

### Data Seeding and Migration Procedures
- Initial schema and seed: creates tables, indexes, and inserts sample data; RLS disabled for development.
- Seed data script: inserts users, categories, vendors, and products; prints org/branch IDs for testing.
- Migration configuration: Drizzle config pointing to DATABASE_URL and schema file.

```mermaid
flowchart TD
MStart(["Run Migrations"]) --> SchemaOnly["001_schema_only.sql<br/>Create tables/indexes/RLS"]
SchemaOnly --> CreateUser["Create Supabase Auth User"]
CreateUser --> Seed["002_seed_data.sql<br/>Insert users/categories/vendors/products"]
Seed --> Verify["Verify counts in UI/SQL"]
Verify --> MEnd(["Ready for Testing"])
```

**Diagram sources**
- [README.md](file://supabase/migrations/README.md#L1-L48)
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L144-L218)
- [002_seed_data.sql](file://supabase/migrations/002_seed_data.sql#L7-L87)
- [drizzle.config.ts](file://backend/drizzle.config.ts#L1-L16)

**Section sources**
- [README.md](file://supabase/migrations/README.md#L1-L48)
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L1-L218)
- [002_seed_data.sql](file://supabase/migrations/002_seed_data.sql#L1-L88)
- [drizzle.config.ts](file://backend/drizzle.config.ts#L1-L16)

### Data Validation Strategies
- Frontend repository validates presence of item ID before update and logs warnings on cache failures.
- Backend services validate DTO fields and enforce unique constraints; throw conflicts for duplicates.
- Lookup usage checks ensure referential integrity before deletions.

**Section sources**
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L200-L206)
- [products.service.ts](file://backend/src/products/products.service.ts#L47-L50)
- [products.service.ts](file://backend/src/products/products.service.ts#L172-L176)

### Indexing Approaches and Performance Optimization
- Indexes on entity_id, type, category_id, vendor_id, is_selectable, item_code for efficient filtering and joins.
- Drizzle schema uses enums and precise numeric types to reduce storage and improve query performance.
- API client sets connect/receive timeouts to avoid long blocking.

**Section sources**
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L122-L134)
- [schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [api_client.dart](file://lib/shared/services/api_client.dart#L13-L25)

### Audit Logging and Data Security Measures
- Audit fields in products: created_at, created_by_id, last_modified_by, last_modified_date.
- RLS policies intentionally disabled for development; enable before production.
- Tenant middleware injects entityId; production code path is active for x-entity-id header.

**Section sources**
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L80-L84)
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L137-L141)
- [tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L41-L67)

### Examples of Common Data Operations
- Create product: call createProduct via API; repository caches result; backend maps legacy fields and inserts compositions.
- Get products: online-first fetch; on success, cache and update last sync; on failure, return cached data.
- Sync lookups: generic syncTableMetadata upserts records and deactivates unused ones.
- Upload images: StorageService signs and uploads to R2; returns URL.

**Section sources**
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L166-L197)
- [products.service.ts](file://backend/src/products/products.service.ts#L18-L89)
- [products.service.ts](file://backend/src/products/products.service.ts#L609-L716)
- [storage_service.dart](file://lib/shared/services/storage_service.dart#L25-L44)

## Dependency Analysis
- Frontend depends on ApiClient, ItemsRepositoryImpl, HiveService, and StorageService.
- Backend depends on SupabaseService for product data and Drizzle ORM for sales data.
- Supabase migrations define schema and indexes; Drizzle config maps schema to database.

```mermaid
graph LR
A["api_client.dart"] --> B["items_repository_impl.dart"]
B --> C["hive_service.dart"]
B --> D["products.service.ts"]
D --> E["supabase.service.ts"]
E --> F["001_initial_schema_and_seed.sql"]
G["schema.ts"] --> H["drizzle.config.ts"]
H --> F
```

**Diagram sources**
- [api_client.dart](file://lib/shared/services/api_client.dart#L1-L62)
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L1-L297)
- [hive_service.dart](file://lib/shared/services/hive_service.dart#L1-L134)
- [products.service.ts](file://backend/src/products/products.service.ts#L1-L723)
- [supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L1-L32)
- [schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [drizzle.config.ts](file://backend/drizzle.config.ts#L1-L16)
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L1-L218)

**Section sources**
- [api_client.dart](file://lib/shared/services/api_client.dart#L1-L62)
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L1-L297)
- [hive_service.dart](file://lib/shared/services/hive_service.dart#L1-L134)
- [products.service.ts](file://backend/src/products/products.service.ts#L1-L723)
- [supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L1-L32)
- [schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [drizzle.config.ts](file://backend/drizzle.config.ts#L1-L16)
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L1-L218)

## Performance Considerations
- Use indexes on entity_id and frequently filtered columns.
- Prefer online-first with Hive caching to minimize repeated network calls.
- Batch operations where possible; leverage Supabase upsert for metadata sync.
- Monitor cache hit ratios and prune stale data periodically.

## Troubleshooting Guide
- Network/API errors: ItemsRepositoryImpl falls back to Hive; check cache stats and last sync timestamps.
- Duplicate item codes: Backend throws conflict exceptions; adjust item_code or SKU uniqueness.
- Missing tenant context: Ensure x-entity-id header is present; middleware injects tenantContext.
- RLS issues: Confirm RLS policies are enabled and properly configured in Supabase.
- Image upload failures: Verify Cloudflare credentials and bucket permissions; inspect signed authorization headers.

**Section sources**
- [items_repository_impl.dart](file://lib/modules/items/repositories/items_repository_impl.dart#L57-L82)
- [products.service.ts](file://backend/src/products/products.service.ts#L47-L50)
- [tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L24-L68)
- [001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L137-L141)
- [storage_service.dart](file://lib/shared/services/storage_service.dart#L108-L136)

## Conclusion
ZerpAI ERP employs a robust data management strategy combining Supabase-backed product data, Drizzle-driven sales data, Hive-based offline caching, and Cloudflare R2 for images. The system supports multi-tenant isolation, configurable RLS, and scalable synchronization patterns. Adhering to the outlined procedures ensures reliable data operations, strong security, and optimal performance.

## Appendices
- Migration and seeding steps are documented in the Supabase migrations README.
- Drizzle configuration points to the schema and DATABASE_URL for schema generation and migrations.

**Section sources**
- [README.md](file://supabase/migrations/README.md#L1-L48)
- [drizzle.config.ts](file://backend/drizzle.config.ts#L1-L16)