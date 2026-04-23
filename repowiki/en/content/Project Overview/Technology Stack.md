# Technology Stack

<cite>
**Referenced Files in This Document**
- [pubspec.yaml](file://pubspec.yaml)
- [main.dart](file://lib/main.dart)
- [env_service.dart](file://lib/shared/services/env_service.dart)
- [items_controller.dart](file://lib/modules/items/controller/items_controller.dart)
- [app.dart](file://lib/app.dart)
- [backend/package.json](file://backend/package.json)
- [backend/nest-cli.json](file://backend/nest-cli.json)
- [backend/tsconfig.json](file://backend/tsconfig.json)
- [backend/drizzle.config.ts](file://backend/drizzle.config.ts)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts)
- [backend/src/db/db.ts](file://backend/src/db/db.ts)
- [.env.example](file://.env.example)
- [backend/.env.example](file://backend/.env.example)
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
This document details the complete technology stack powering ZerpAI ERP. It covers the frontend built with Flutter 3.x (with web and Android targets), the backend powered by NestJS 10.x and TypeScript, Supabase for database, authentication, and storage, PostgreSQL for persistent data, and Riverpod for scalable state management. For each technology, we explain version requirements, rationale, compatibility, and practical implications for Indian SMEs, including offline-first capabilities, regulatory alignment, and deployment considerations.

## Project Structure
ZerpAI ERP follows a clear separation of concerns:
- Frontend: Flutter application under lib/, supporting web and mobile targets via Flutter SDK.
- Backend: NestJS application under backend/, written in TypeScript, using Drizzle ORM and Supabase client.
- Database: PostgreSQL schema defined with Drizzle ORM and managed via Supabase.
- Shared configuration: Environment variables under .env.example and backend/.env.example.

```mermaid
graph TB
subgraph "Frontend (Flutter)"
FM["lib/main.dart"]
ENV["lib/shared/services/env_service.dart"]
CTRL["lib/modules/items/controller/items_controller.dart"]
APP["lib/app.dart"]
end
subgraph "Backend (NestJS)"
PKG["backend/package.json"]
NEST["backend/nest-cli.json"]
TS["backend/tsconfig.json"]
DRZCFG["backend/drizzle.config.ts"]
SUPSRV["backend/src/supabase/supabase.service.ts"]
SCHEMA["backend/src/db/schema.ts"]
DBMOD["backend/src/db/db.ts"]
end
subgraph "Data Layer"
SUP["Supabase"]
PG["PostgreSQL"]
end
FM --> ENV
FM --> SUP
FM --> APP
CTRL --> ENV
CTRL --> SUP
PKG --> NEST
PKG --> TS
PKG --> DRZCFG
DRZCFG --> SCHEMA
SUPSRV --> SUP
DBMOD --> SUP
SUP --> PG
```

**Diagram sources**
- [lib/main.dart](file://lib/main.dart#L1-L29)
- [lib/shared/services/env_service.dart](file://lib/shared/services/env_service.dart#L1-L72)
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L1-L568)
- [lib/app.dart](file://lib/app.dart#L1-L200)
- [backend/package.json](file://backend/package.json#L1-L79)
- [backend/nest-cli.json](file://backend/nest-cli.json#L1-L12)
- [backend/tsconfig.json](file://backend/tsconfig.json#L1-L22)
- [backend/drizzle.config.ts](file://backend/drizzle.config.ts#L1-L16)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L1-L32)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [backend/src/db/db.ts](file://backend/src/db/db.ts#L1-L13)

**Section sources**
- [pubspec.yaml](file://pubspec.yaml#L1-L128)
- [lib/main.dart](file://lib/main.dart#L1-L29)
- [backend/package.json](file://backend/package.json#L1-L79)
- [backend/nest-cli.json](file://backend/nest-cli.json#L1-L12)
- [backend/tsconfig.json](file://backend/tsconfig.json#L1-L22)
- [backend/drizzle.config.ts](file://backend/drizzle.config.ts#L1-L16)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [backend/src/db/db.ts](file://backend/src/db/db.ts#L1-L13)
- [.env.example](file://.env.example#L1-L68)
- [backend/.env.example](file://backend/.env.example#L1-L40)

## Core Components
- Flutter 3.x (web and Android): Single-codebase UI with Riverpod state management, Supabase Flutter SDK, and offline caching via Hive.
- NestJS 10.x + TypeScript: Modular backend with DTOs, middleware, and Supabase integration.
- Supabase: Authentication, real-time features, storage, and database abstraction.
- PostgreSQL: Persistent relational data via Supabase-managed Postgres.
- Riverpod: Predictable, testable, and scalable state management for Flutter.

Rationale and version requirements:
- Flutter 3.x SDK ensures modern Dart language features and cross-platform builds. The project’s SDK constraint aligns with this.
- NestJS 10.x provides a robust, scalable backend foundation with excellent TypeScript support and modular architecture.
- Supabase offers a unified platform for auth, DB, and storage, simplifying infrastructure for SMEs.
- PostgreSQL is the industry-standard relational engine; Supabase manages migrations and RLS policies.
- Riverpod replaces provider/bloc patterns with a more flexible, composable solution.

Compatibility considerations:
- Flutter and NestJS TypeScript configurations target ES2021 and modern Node LTS.
- Supabase client libraries integrate seamlessly with both environments.
- Drizzle ORM schema aligns with PostgreSQL dialect and supports migrations.

**Section sources**
- [pubspec.yaml](file://pubspec.yaml#L21-L23)
- [backend/package.json](file://backend/package.json#L22-L36)
- [backend/tsconfig.json](file://backend/tsconfig.json#L10-L10)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L10-L26)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L1-L20)

## Architecture Overview
The system architecture centers around a Flutter frontend communicating with a NestJS backend over HTTP. Supabase provides authentication, real-time subscriptions, and storage, while PostgreSQL persists data. Riverpod orchestrates UI state locally, and Hive enables offline-first experiences.

```mermaid
sequenceDiagram
participant UI as "Flutter UI<br/>lib/main.dart"
participant RP as "Riverpod State<br/>items_controller.dart"
participant ENV as "Env Service<br/>env_service.dart"
participant API as "NestJS API<br/>backend/package.json"
participant SB as "Supabase Client<br/>supabase_flutter"
participant DB as "PostgreSQL via Supabase"
UI->>ENV : Load .env and validate keys
UI->>SB : Initialize Supabase (URL, ANON_KEY)
UI->>RP : Build UI with providers
RP->>API : GET /api/products
API->>DB : Query via Drizzle ORM
DB-->>API : Rows
API-->>RP : JSON payload
RP-->>UI : Update state and render
```

**Diagram sources**
- [lib/main.dart](file://lib/main.dart#L8-L28)
- [lib/shared/services/env_service.dart](file://lib/shared/services/env_service.dart#L7-L18)
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L25-L60)
- [backend/package.json](file://backend/package.json#L8-L21)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L116-L195)

## Detailed Component Analysis

### Flutter Frontend (State Management with Riverpod)
- Initialization: The app initializes Hive for offline caching, loads environment variables, and sets up Supabase.
- State Management: ItemsController extends StateNotifier and uses Riverpod providers to manage UI state, loading flags, errors, and validation messages.
- Offline Support: Hive boxes are opened during startup to enable offline reads/writes.
- Environment Access: EnvService centralizes .env loading and validation for Supabase credentials and optional R2 storage settings.

```mermaid
classDiagram
class ItemsController {
+loadItems()
+loadLookupData()
+createItem(item)
+updateItem(item)
+deleteItem(id)
+validateItem(item) Map
+clearValidationErrors()
}
class ItemsState {
+bool isLoading
+bool isSaving
+bool isLoadingLookups
+dynamic[] items
+Map~String,String~ validationErrors
+String? error
}
class EnvService {
+initialize()
+validate()
+supabaseUrl
+supabaseAnonKey
+supabaseServiceRoleKey
}
ItemsController --> ItemsState : "manages"
ItemsController --> EnvService : "reads config"
```

**Diagram sources**
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L16-L568)
- [lib/shared/services/env_service.dart](file://lib/shared/services/env_service.dart#L6-L71)
- [lib/main.dart](file://lib/main.dart#L11-L25)

**Section sources**
- [lib/main.dart](file://lib/main.dart#L8-L28)
- [lib/shared/services/env_service.dart](file://lib/shared/services/env_service.dart#L7-L71)
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L16-L60)

### Backend (NestJS + Supabase + Drizzle ORM)
- Package Scripts: Build, watch, debug, lint, and test commands are defined for iterative development.
- TypeScript Compiler Options: Targets ES2021 and enables decorators and metadata for NestJS.
- Supabase Service: Initializes a Supabase client using service role key and disables auto session persistence for server-side contexts.
- Database Schema: Drizzle ORM tables define product catalogs, sales, tax rates, units, and lookup entities aligned with Indian ERP needs.
- Database Connection: Drizzle connects to PostgreSQL via a connection string from environment variables.

```mermaid
flowchart TD
Start(["Startup"]) --> LoadEnv["Load .env (backend)"]
LoadEnv --> InitSupabase["Initialize Supabase Service"]
InitSupabase --> ConnectDB["Drizzle connect to PostgreSQL"]
ConnectDB --> DefineSchema["Define ORM schema"]
DefineSchema --> ExposeAPI["Expose NestJS Controllers"]
ExposeAPI --> Ready(["Ready"])
```

**Diagram sources**
- [backend/.env.example](file://backend/.env.example#L3-L10)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L10-L26)
- [backend/src/db/db.ts](file://backend/src/db/db.ts#L7-L12)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [backend/package.json](file://backend/package.json#L8-L21)

**Section sources**
- [backend/package.json](file://backend/package.json#L8-L21)
- [backend/tsconfig.json](file://backend/tsconfig.json#L2-L21)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L7-L31)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [backend/src/db/db.ts](file://backend/src/db/db.ts#L1-L13)

### Database Schema (PostgreSQL via Supabase)
- Entities: Units, Categories, Tax Rates, Manufacturers, Brands, Accounts, Storage Locations, Racks, Reorder Terms, Vendors, Products, Product Compositions, Customers, Sales Orders/Payments, E-Way Bills, Payment Links.
- Enumerations: Product type, tax preference, valuation method, unit type, tax type, account type, vendor type.
- Relationships: Foreign keys enforce referential integrity across entities.
- Regulatory Alignment: GSTIN, HSN code, and tax rate tables support Indian tax compliance.

```mermaid
erDiagram
UNITS {
uuid id PK
varchar unitName UK
varchar unitSymbol
enum unitType
boolean isActive
timestamp createdAt
}
CATEGORIES {
uuid id PK
varchar name UK
text description
uuid parentId FK
boolean isActive
timestamp createdAt
}
TAX_RATES {
uuid id PK
varchar taxName UK
decimal taxRate
enum taxType
boolean isActive
timestamp createdAt
}
PRODUCTS {
uuid id PK
enum type
varchar productName
varchar billingName
varchar itemCode UK
varchar sku
uuid unitId FK
uuid categoryId FK
boolean isReturnable
boolean pushToEcommerce
varchar hsnCode
enum taxPreference
uuid intraStateTaxId FK
uuid interStateTaxId FK
text primaryImageUrl
text imageUrls
decimal sellingPrice
varchar sellingPriceCurrency
decimal mrp
decimal ptr
uuid salesAccountId FK
text salesDescription
decimal costPrice
varchar costPriceCurrency
uuid purchaseAccountId FK
uuid preferredVendorId FK
text purchaseDescription
decimal length
decimal width
decimal height
varchar dimensionUnit
decimal weight
varchar weightUnit
uuid manufacturerId FK
uuid brandId FK
varchar mpn
varchar upc
varchar isbn
varchar ean
boolean trackAssocIngredients
varchar buyingRule
varchar scheduleOfDrug
boolean isTrackInventory
boolean trackBinLocation
boolean trackBatches
uuid inventoryAccountId FK
enum inventoryValuationMethod
uuid storageId FK
uuid rackId FK
integer reorderPoint
uuid reorderTermId FK
boolean isActive
boolean isLock
timestamp createdAt
uuid createdById
timestamp updatedAt
uuid updatedById
}
CUSTOMERS {
uuid id PK
varchar displayName
varchar customerType
varchar salutation
varchar firstName
varchar lastName
varchar companyName
varchar email
varchar phone
varchar mobilePhone
varchar gstin
varchar pan
varchar currency
varchar paymentTerms
text billingAddress
text shippingAddress
boolean isActive
decimal receivables
timestamp createdAt
}
SALES_ORDERS {
uuid id PK
uuid customerId FK
varchar saleNumber
varchar reference
timestamp saleDate
timestamp expectedShipmentDate
varchar deliveryMethod
varchar paymentTerms
varchar documentType
varchar status
decimal total
varchar currency
text customerNotes
text termsAndConditions
timestamp createdAt
}
SALES_PAYMENTS {
uuid id PK
uuid customerId FK
varchar paymentNumber
timestamp paymentDate
varchar paymentMode
decimal amount
decimal bankCharges
varchar reference
varchar depositTo
text notes
timestamp createdAt
}
VENDORS {
uuid id PK
varchar vendorName UK
enum vendorType
varchar contactPerson
varchar email
varchar phone
text address
varchar gstin
varchar drugLicenseNo
boolean isActive
timestamp createdAt
}
ACCOUNTS {
uuid id PK
varchar accountName UK
enum accountType
varchar accountCode
boolean isActive
timestamp createdAt
}
STORAGE_LOCATIONS {
uuid id PK
varchar locationName UK
varchar temperatureRange
text description
boolean isActive
timestamp createdAt
}
RACKS {
uuid id PK
varchar rackCode UK
varchar rackName
uuid storageId FK
integer capacity
boolean isActive
timestamp createdAt
}
REORDER_TERMS {
uuid id PK
varchar termName UK
varchar presetFormula
text description
boolean isActive
timestamp createdAt
}
PRODUCT_COMPOSITIONS {
uuid id PK
uuid productId FK
varchar contentName
decimal strength
varchar strengthUnit
varchar schedule
integer displayOrder
timestamp createdAt
}
UNITS ||--o{ PRODUCTS : "unitId"
CATEGORIES ||--o{ PRODUCTS : "categoryId"
TAX_RATES ||--o{ PRODUCTS : "intraStateTaxId"
TAX_RATES ||--o{ PRODUCTS : "interStateTaxId"
ACCOUNTS ||--o{ PRODUCTS : "salesAccountId"
ACCOUNTS ||--o{ PRODUCTS : "purchaseAccountId"
ACCOUNTS ||--o{ PRODUCTS : "inventoryAccountId"
VENDORS ||--o{ PRODUCTS : "preferredVendorId"
CUSTOMERS ||--o{ SALES_ORDERS : "customerId"
CUSTOMERS ||--o{ SALES_PAYMENTS : "customerId"
STORAGE_LOCATIONS ||--o{ RACKS : "storageId"
PRODUCTS ||--o{ PRODUCT_COMPOSITIONS : "productId"
```

**Diagram sources**
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L293)

**Section sources**
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L293)

### Environment and Configuration
- Frontend .env: API base URL, Supabase keys, environment flags, cache settings, timeouts, and logging preferences.
- Backend .env: Database URL, Supabase keys, JWT secret, CORS origins, API prefix/version, and Cloudflare R2 storage configuration.

```mermaid
flowchart TD
FE[".env.example (frontend)"] --> LoadFE["lib/shared/services/env_service.dart"]
BE[".env.example (backend)"] --> NestCfg["backend/package.json scripts"]
LoadFE --> SupabaseInit["lib/main.dart initialize Supabase"]
NestCfg --> DrizzleCfg["backend/drizzle.config.ts"]
DrizzleCfg --> DBConn["backend/src/db/db.ts"]
```

**Diagram sources**
- [.env.example](file://.env.example#L5-L68)
- [backend/.env.example](file://backend/.env.example#L3-L40)
- [lib/shared/services/env_service.dart](file://lib/shared/services/env_service.dart#L7-L71)
- [lib/main.dart](file://lib/main.dart#L20-L25)
- [backend/package.json](file://backend/package.json#L8-L21)
- [backend/drizzle.config.ts](file://backend/drizzle.config.ts#L6-L15)
- [backend/src/db/db.ts](file://backend/src/db/db.ts#L7-L12)

**Section sources**
- [.env.example](file://.env.example#L5-L68)
- [backend/.env.example](file://backend/.env.example#L3-L40)
- [lib/shared/services/env_service.dart](file://lib/shared/services/env_service.dart#L7-L71)
- [lib/main.dart](file://lib/main.dart#L20-L25)
- [backend/package.json](file://backend/package.json#L8-L21)
- [backend/drizzle.config.ts](file://backend/drizzle.config.ts#L6-L15)
- [backend/src/db/db.ts](file://backend/src/db/db.ts#L7-L12)

## Dependency Analysis
- Frontend dependencies include Riverpod for state, Supabase Flutter SDK for auth/storage/DB, Hive/Hive Flutter for offline caching, Dio for HTTP, and Google Fonts/intl for UX.
- Backend dependencies include NestJS core/platform, Supabase JS client, Drizzle ORM, PostgreSQL drivers, and testing/linting tools.

```mermaid
graph LR
subgraph "Flutter Frontend"
Riverpod["flutter_riverpod"]
SupabaseFlutter["supabase_flutter"]
Hive["hive_flutter"]
Dio["dio"]
Intl["intl"]
end
subgraph "NestJS Backend"
NestCommon["@nestjs/common"]
NestCore["@nestjs/core"]
SupabaseJS["@supabase/supabase-js"]
DrizzleORM["drizzle-orm"]
DrizzleKit["drizzle-kit"]
PG["pg"]
end
Riverpod --> SupabaseFlutter
Hive --> Riverpod
Dio --> NestCommon
NestCore --> SupabaseJS
DrizzleORM --> PG
DrizzleKit --> NestCommon
```

**Diagram sources**
- [pubspec.yaml](file://pubspec.yaml#L38-L70)
- [backend/package.json](file://backend/package.json#L22-L36)

**Section sources**
- [pubspec.yaml](file://pubspec.yaml#L38-L70)
- [backend/package.json](file://backend/package.json#L22-L36)

## Performance Considerations
- Parallel Lookup Loading: ItemsController loads lookup lists concurrently to reduce UI latency.
- Caching and Offline: Hive boxes enable offline reads/writes; environment flags control cache staleness and sizes.
- Logging and Monitoring: Structured logging and performance timing are integrated for observability.
- Database Queries: Drizzle ORM schema and PostgreSQL indexing (via Supabase) support efficient queries.

**Section sources**
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L71-L88)
- [.env.example](file://.env.example#L47-L68)
- [lib/shared/services/env_service.dart](file://lib/shared/services/env_service.dart#L48-L70)

## Troubleshooting Guide
- Missing Supabase Keys: EnvService throws explicit errors if required keys are missing; verify .env values.
- Supabase Client Initialization: Ensure URL and keys are loaded before initializing Supabase in main().
- Backend Environment: Confirm DATABASE_URL and Supabase keys; verify CORS origins and API prefix/version.
- Drizzle Configuration: Ensure DATABASE_URL is set and Drizzle config matches schema path.

**Section sources**
- [lib/shared/services/env_service.dart](file://lib/shared/services/env_service.dart#L48-L71)
- [lib/main.dart](file://lib/main.dart#L20-L25)
- [backend/.env.example](file://backend/.env.example#L3-L10)
- [backend/drizzle.config.ts](file://backend/drizzle.config.ts#L6-L15)

## Conclusion
ZerpAI ERP leverages a modern, cohesive stack: Flutter 3.x for a responsive, cross-platform UI with Riverpod state management; NestJS 10.x with TypeScript for a maintainable backend; Supabase for authentication, storage, and database; and PostgreSQL for reliable persistence. This combination delivers scalability, regulatory alignment for Indian markets, offline-first capabilities, and simplified infrastructure—ideal for SMEs seeking an enterprise-grade ERP without heavy DevOps overhead.

## Appendices
- Development Environment Setup
  - Flutter: Install SDK per pubspec.yaml environment constraint; configure web and Android targets.
  - Backend: Install Node.js and Nest CLI; run scripts defined in backend/package.json.
  - Database: Provision Supabase project; apply migrations via Drizzle kit; seed data as needed.
  - Environment: Copy .env.example files to .env.local and populate values; load in both frontend and backend.

- Deployment Notes
  - Frontend: Build for web and Android using Flutter build commands; host on Vercel or similar.
  - Backend: Deploy NestJS app to Vercel or a Node-compatible platform; ensure environment variables are configured.
  - Database: Supabase-managed PostgreSQL; configure RLS policies and roles as per schema.

[No sources needed since this section provides general guidance]