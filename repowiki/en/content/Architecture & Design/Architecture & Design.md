# Architecture & Design

<cite>
**Referenced Files in This Document**
- [README.md](file://README.md)
- [lib/main.dart](file://lib/main.dart)
- [lib/app.dart](file://lib/app.dart)
- [lib/shared/services/api_client.dart](file://lib/shared/services/api_client.dart)
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart)
- [lib/modules/items/repositories/items_repository.dart](file://lib/modules/items/repositories/items_repository.dart)
- [lib/shared/services/storage_service.dart](file://lib/shared/services/storage_service.dart)
- [backend/src/main.ts](file://backend/src/main.ts)
- [backend/src/app.module.ts](file://backend/src/app.module.ts)
- [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql)
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
This document describes the ZerpAI ERP system architecture, focusing on the Flutter frontend, NestJS backend, and Supabase database integration. It explains the multi-tenant design with organization and outlet-level isolation, the layered architecture (presentation, business logic, data access, persistence), component interactions, data flows, and integration points. It also covers system boundaries, scalability considerations, deployment topology, Riverpod state management, API communication patterns, offline-first strategy, and cross-cutting concerns such as authentication, authorization, and data security via Row-level Security (RLS).

## Project Structure
The monorepo follows a clear separation of concerns:
- Flutter frontend (lib/) with Riverpod state management, API clients, and feature modules
- NestJS backend (backend/src/) with modules, middleware, and Supabase integration
- Supabase database (supabase/migrations/) with initial schema and seed data

```mermaid
graph TB
subgraph "Frontend (Flutter)"
FE_Main["lib/main.dart"]
FE_App["lib/app.dart"]
FE_API["lib/shared/services/api_client.dart"]
FE_Riverpod["lib/modules/items/controller/items_controller.dart"]
FE_Repo["lib/modules/items/repositories/items_repository.dart"]
FE_S3["lib/shared/services/storage_service.dart"]
end
subgraph "Backend (NestJS)"
BE_Main["backend/src/main.ts"]
BE_App["backend/src/app.module.ts"]
BE_MW["backend/src/common/middleware/tenant.middleware.ts"]
BE_DB["backend/src/db/schema.ts"]
BE_SVC["backend/src/supabase/supabase.service.ts"]
end
subgraph "Database (Supabase)"
DB_SQL["supabase/migrations/001_initial_schema_and_seed.sql"]
end
FE_Main --> FE_App
FE_App --> FE_Riverpod
FE_Riverpod --> FE_API
FE_Riverpod --> FE_Repo
FE_API --> BE_Main
BE_Main --> BE_App
BE_App --> BE_MW
BE_App --> BE_SVC
BE_SVC --> DB_SQL
BE_DB --> DB_SQL
```

**Diagram sources**
- [lib/main.dart](file://lib/main.dart#L1-L29)
- [lib/app.dart](file://lib/app.dart#L1-L32)
- [lib/shared/services/api_client.dart](file://lib/shared/services/api_client.dart#L1-L62)
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L1-L568)
- [lib/modules/items/repositories/items_repository.dart](file://lib/modules/items/repositories/items_repository.dart#L1-L53)
- [lib/shared/services/storage_service.dart](file://lib/shared/services/storage_service.dart#L1-L227)
- [backend/src/main.ts](file://backend/src/main.ts#L1-L56)
- [backend/src/app.module.ts](file://backend/src/app.module.ts#L1-L20)
- [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L1-L70)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L1-L32)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L1-L218)

**Section sources**
- [README.md](file://README.md#L1-L122)
- [lib/main.dart](file://lib/main.dart#L1-L29)
- [lib/app.dart](file://lib/app.dart#L1-L32)
- [backend/src/main.ts](file://backend/src/main.ts#L1-L56)
- [backend/src/app.module.ts](file://backend/src/app.module.ts#L1-L20)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L293)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L1-L218)

## Core Components
- Flutter Application Bootstrap and Initialization
  - Initializes Hive for offline storage, Supabase client, and wraps the app in Riverpod’s ProviderScope
  - See [lib/main.dart](file://lib/main.dart#L8-L28)
- API Client
  - Centralized Dio-based HTTP client configured with base URL and interceptors
  - See [lib/shared/services/api_client.dart](file://lib/shared/services/api_client.dart#L6-L62)
- Riverpod State Management
  - ItemsController orchestrates loading, validation, saving, and error handling for items
  - Provides provider bindings for consumption by UI
  - See [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L16-L568)
- Repository Layer
  - Abstraction for data access; includes a mock implementation for development
  - See [lib/modules/items/repositories/items_repository.dart](file://lib/modules/items/repositories/items_repository.dart#L3-L53)
- Backend Entry Point
  - Bootstraps NestJS app, enables CORS, sets global validation pipe, and listens on configured port
  - See [backend/src/main.ts](file://backend/src/main.ts#L10-L53)
- Tenant Middleware
  - Extracts X-Org-Id and X-Outlet-Id headers and attaches a tenant context to requests
  - Includes placeholder for production JWT verification
  - See [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L24-L68)
- Supabase Service
  - Creates a Supabase client using service role credentials
  - See [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L7-L31)
- Database Schema
  - Drizzle ORM schema for products, categories, vendors, and sales entities
  - See [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L293)
- Database Migration
  - Initial schema with multi-tenant fields (org_id, outlet_id), indexes, and seed data
  - RLS policies intentionally disabled for development
  - See [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L24-L141)

**Section sources**
- [lib/main.dart](file://lib/main.dart#L8-L28)
- [lib/shared/services/api_client.dart](file://lib/shared/services/api_client.dart#L6-L62)
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L16-L568)
- [lib/modules/items/repositories/items_repository.dart](file://lib/modules/items/repositories/items_repository.dart#L3-L53)
- [backend/src/main.ts](file://backend/src/main.ts#L10-L53)
- [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L24-L68)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L7-L31)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L116-L293)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L24-L141)

## Architecture Overview
ZerpAI ERP follows a layered architecture:
- Presentation Layer: Flutter UI with Riverpod state management
- Business Logic Layer: Controllers and services coordinating workflows
- Data Access Layer: Repositories and API services
- Persistence Layer: Supabase (PostgreSQL) with RLS and indexes

```mermaid
graph TB
UI["Flutter UI<br/>Riverpod State"] --> CTRL["ItemsController<br/>Business Logic"]
CTRL --> REPO["ItemRepository<br/>Data Access"]
REPO --> API["ApiClient<br/>REST Calls"]
API --> NEST["NestJS Backend"]
NEST --> MW["Tenant Middleware<br/>X-Org-Id/X-Outlet-Id"]
NEST --> SVC["SupabaseService<br/>Supabase Client"]
SVC --> DB["Supabase DB<br/>RLS + Indexes"]
subgraph "Frontend"
UI
CTRL
REPO
API
end
subgraph "Backend"
NEST
MW
SVC
end
subgraph "Database"
DB
end
```

**Diagram sources**
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L16-L568)
- [lib/shared/services/api_client.dart](file://lib/shared/services/api_client.dart#L6-L62)
- [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L24-L68)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L7-L31)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L24-L141)

## Detailed Component Analysis

### Multi-Tenant Design and Tenant Middleware
- Headers
  - X-Org-Id and X-Outlet-Id are used to isolate data per organization and outlet
- Middleware Behavior
  - Currently attaches a test tenant context for development
  - Includes commented production code for JWT verification and header extraction
- Impact
  - Ensures backend routes operate under tenant context; database queries should filter by org_id and outlet_id

```mermaid
sequenceDiagram
participant UI as "Flutter UI"
participant API as "ApiClient"
participant MW as "TenantMiddleware"
participant NEST as "NestJS Controller"
participant SVC as "SupabaseService"
participant DB as "Supabase DB"
UI->>API : "HTTP Request"
API->>MW : "Forward with X-Org-Id/X-Outlet-Id"
MW->>MW : "Attach tenantContext"
MW->>NEST : "Proceed to route handlers"
NEST->>SVC : "Execute query with tenant filters"
SVC->>DB : "SQL with org_id/outlet_id"
DB-->>SVC : "Filtered results"
SVC-->>NEST : "Data"
NEST-->>API : "Response"
API-->>UI : "Rendered UI"
```

**Diagram sources**
- [lib/shared/services/api_client.dart](file://lib/shared/services/api_client.dart#L46-L60)
- [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L24-L68)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L28-L31)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L30-L33)

**Section sources**
- [README.md](file://README.md#L93-L100)
- [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L24-L68)

### Riverpod State Management and Offline-First Strategy
- Initialization
  - Hive boxes opened for offline support (products, customers, pos drafts, config)
- State Management
  - ItemsController manages loading, validation, saving, and error states
  - Parallel loading of lookup data improves responsiveness
- Offline-First
  - Hive initialization ensures offline readiness
  - Image uploads to Cloudflare R2 bypass Supabase for media assets

```mermaid
flowchart TD
Start(["App Start"]) --> InitHive["Open Hive Boxes"]
InitHive --> InitSupabase["Initialize Supabase"]
InitSupabase --> RunApp["Run ProviderScope"]
RunApp --> LoadItems["ItemsController.loadItems()"]
LoadItems --> ParallelLoad["Parallel Lookup Loads"]
ParallelLoad --> RenderUI["Render UI with Items"]
RenderUI --> OfflineSupport{"Offline?"}
OfflineSupport --> |Yes| UseLocal["Use Hive data"]
OfflineSupport --> |No| UseRemote["Fetch from API"]
UseLocal --> End(["Ready"])
UseRemote --> End
```

**Diagram sources**
- [lib/main.dart](file://lib/main.dart#L11-L28)
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L25-L184)

**Section sources**
- [lib/main.dart](file://lib/main.dart#L11-L28)
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L25-L184)

### API Communication Patterns and CORS
- Backend CORS
  - Enabled for localhost origins and allowed headers including X-Org-Id and X-Outlet-Id
- Frontend API Client
  - Configured base URL from environment and generic HTTP helpers
- Error Handling
  - Global ValidationPipe logs detailed validation errors

```mermaid
sequenceDiagram
participant FE as "Flutter App"
participant AC as "ApiClient"
participant BE as "NestJS Server"
participant MW as "TenantMiddleware"
FE->>AC : "POST /api/items"
AC->>BE : "HTTP Request (JSON)"
BE->>MW : "Apply tenant middleware"
MW-->>BE : "Tenant context attached"
BE-->>AC : "201/4xx/5xx"
AC-->>FE : "Handle response/error"
```

**Diagram sources**
- [lib/shared/services/api_client.dart](file://lib/shared/services/api_client.dart#L46-L60)
- [backend/src/main.ts](file://backend/src/main.ts#L19-L24)
- [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L24-L39)

**Section sources**
- [backend/src/main.ts](file://backend/src/main.ts#L19-L42)
- [lib/shared/services/api_client.dart](file://lib/shared/services/api_client.dart#L12-L43)

### Data Model and Multi-Tenant Fields
- Products and lookup tables include org_id and outlet_id for tenant isolation
- Indexes optimized for org_id/outlet_id and common filters
- Seed data demonstrates multi-tenant records with sample org_id and outlet_id

```mermaid
erDiagram
PRODUCTS {
uuid id PK
uuid org_id
uuid outlet_id
varchar type
varchar billing_name
varchar item_code
varchar sku
uuid unit_id
uuid category_id
boolean is_track_inventory
integer reorder_point
timestamp created_at
}
CATEGORIES {
uuid id PK
uuid org_id
varchar name
text description
uuid parent_id
boolean is_active
timestamp created_at
}
VENDORS {
uuid id PK
uuid org_id
varchar vendor_name
varchar contact_person
varchar phone
text address
varchar gstin
boolean is_active
timestamp created_at
}
PRODUCTS ||--|| CATEGORIES : "category_id"
PRODUCTS ||--|| VENDORS : "preferred_vendor_id"
```

**Diagram sources**
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L26-L89)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L94-L120)

**Section sources**
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L24-L141)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L116-L195)

### Cross-Cutting Concerns: Authentication, Authorization, and Data Security
- Authentication
  - Supabase Auth is available; current tenant middleware uses test context
  - Production code includes placeholders for JWT verification and extracting user/role from headers
- Authorization
  - Backend middleware attaches role to tenant context; enforcement depends on route handlers
- Data Security
  - Row-level Security (RLS) policies are intentionally disabled for development
  - Recommended to enable RLS and fine-grained policies before production deployment

```mermaid
flowchart TD
A["Incoming Request"] --> B["Extract X-Org-Id/X-Outlet-Id"]
B --> C{"Production JWT?"}
C --> |Yes| D["Verify JWT and extract claims"]
C --> |No| E["Use test context (development)"]
D --> F["Attach tenantContext (userId, role)"]
E --> F
F --> G["Route Handler"]
G --> H["Enforce authorization rules"]
H --> I["Apply RLS policies"]
```

**Diagram sources**
- [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L41-L67)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L137-L141)

**Section sources**
- [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L41-L67)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L137-L141)

## Dependency Analysis
- Frontend Dependencies
  - Flutter, Riverpod, Dio, Supabase Flutter SDK, Hive
- Backend Dependencies
  - NestJS, Supabase client, Drizzle ORM schema
- Database Dependencies
  - Supabase PostgreSQL with multi-tenant tables and indexes

```mermaid
graph LR
FE["Flutter App"] --> |HTTP| BE["NestJS Backend"]
BE --> |Supabase JS| DB["Supabase DB"]
BE --> |Drizzle| DB
FE --> |Hive| FE
```

**Diagram sources**
- [lib/shared/services/api_client.dart](file://lib/shared/services/api_client.dart#L3-L5)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L4-L5)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L2)

**Section sources**
- [lib/shared/services/api_client.dart](file://lib/shared/services/api_client.dart#L3-L5)
- [backend/src/supabase/supabase.service.ts](file://backend/src/supabase/supabase.service.ts#L4-L5)
- [backend/src/db/schema.ts](file://backend/src/db/schema.ts#L1-L2)

## Performance Considerations
- Parallel Lookup Loading
  - ItemsController loads multiple lookup datasets concurrently to reduce latency
- Indexes
  - Database includes indexes on org_id/outlet_id and frequently queried columns
- Validation Pipe
  - Global ValidationPipe provides structured error logging and early failure detection
- Media Handling
  - Product images uploaded to Cloudflare R2 to offload storage and improve CDN reach

**Section sources**
- [lib/modules/items/controller/items_controller.dart](file://lib/modules/items/controller/items_controller.dart#L72-L88)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L124-L134)
- [backend/src/main.ts](file://backend/src/main.ts#L27-L42)
- [lib/shared/services/storage_service.dart](file://lib/shared/services/storage_service.dart#L25-L44)

## Troubleshooting Guide
- CORS Issues
  - Ensure API_BASE_URL matches backend CORS configuration and allowed headers include tenant headers
- Validation Errors
  - Global ValidationPipe returns detailed messages; inspect logs for field-specific constraints
- Tenant Context
  - Confirm X-Org-Id and X-Outlet-Id headers are present; middleware currently attaches test context in development
- RLS Policies
  - During development, RLS is disabled; enable policies and verify row-level filtering before production

**Section sources**
- [backend/src/main.ts](file://backend/src/main.ts#L19-L24)
- [backend/src/main.ts](file://backend/src/main.ts#L32-L41)
- [backend/src/common/middleware/tenant.middleware.ts](file://backend/src/common/middleware/tenant.middleware.ts#L24-L39)
- [supabase/migrations/001_initial_schema_and_seed.sql](file://supabase/migrations/001_initial_schema_and_seed.sql#L137-L141)

## Conclusion
ZerpAI ERP employs a clean layered architecture with a Flutter frontend powered by Riverpod, a NestJS backend enforcing multi-tenant isolation via headers and middleware, and a Supabase-backed database with multi-tenant tables and indexes. The system is designed for scalability and maintainability, with room for production hardening around authentication, authorization, and RLS. The offline-first strategy leverages Hive and external media storage to ensure resilience and performance.

## Appendices
- Deployment Topology
  - Frontend: Hosted via Flutter web or native platforms
  - Backend: Deployed as a NestJS server with environment-specific CORS and ports
  - Database: Supabase managed PostgreSQL with RLS policies enabled in production
- Scalability Notes
  - Horizontal scaling of backend instances supported by stateless controllers and shared database
  - CDN and external storage for media improve global availability and throughput