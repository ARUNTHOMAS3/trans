# Project Structure

## Monorepo Organization
ZERPAI ERP uses a monorepo structure with Flutter frontend and NestJS backend colocated in a single repository.

```
zerpai-new/
├── lib/                    # Flutter Frontend
├── backend/                # NestJS Backend API
├── supabase/               # Database migrations
├── android/                # Android platform files
├── web/                    # Web platform files
├── windows/                # Windows platform files
├── macos/                  # macOS platform files
├── ios/                    # iOS platform files
├── assets/                 # Static assets (fonts, images)
├── PRD/                    # Product requirements documentation
├── docs/                   # Technical documentation
└── tools/                  # Development utilities
```

## Frontend Structure (lib/)

### Core Layer (lib/core/)
Foundation services and utilities used across the application:
- **api/**: HTTP client configuration (Dio), API interceptors, multi-tenant headers
- **constants/**: Application-wide constants and configuration
- **errors/**: Error handling and custom exceptions
- **layout/**: Main layout components (sidebar, app bar, navigation)
- **logging/**: Logging service and utilities
- **pages/**: Core pages (home, error pages)
- **routing/**: GoRouter configuration and route definitions
- **services/**: Core services (auth, storage, connectivity)
- **theme/**: Theme configuration and styling
- **utils/**: Utility functions and helpers
- **widgets/**: Reusable core widgets

### Data Layer (lib/data/)
Shared data models and state management:
- **models/**: Common data models used across modules
- **providers/**: Global Riverpod providers

### Modules Layer (lib/modules/)
Feature-based modules following domain-driven design:
- **accounts/**: Chart of accounts, journal entries, fiscal years
- **auth/**: Authentication and authorization
- **branches/**: Outlet/branch management
- **home/**: Dashboard and home screen
- **inventory/**: Stock management and tracking
- **items/**: Product catalog, compositions, categories
- **mapping/**: Data mapping and synchronization
- **printing/**: Print templates and services
- **purchases/**: Purchase orders and vendor management
- **reports/**: Reporting and analytics
- **sales/**: Sales processing and invoicing
- **settings/**: Application configuration

Each module typically contains:
```
module_name/
├── models/              # Domain models
├── repositories/        # Data access layer
├── providers/           # Riverpod state management
├── presentation/        # UI screens and widgets
│   └── widgets/         # Module-specific widgets
└── controllers/         # Business logic
```

### Shared Layer (lib/shared/)
Reusable components across modules:
- **constants/**: Shared constants
- **models/**: Common models
- **responsive/**: Responsive layout utilities
- **services/**: Shared services
- **theme/**: Shared theme components
- **utils/**: Shared utility functions
- **widgets/**: Reusable UI components (inputs, buttons, tables, dropdowns)

## Backend Structure (backend/)

### Source Code (backend/src/)
- **common/**: Middleware (multi-tenant context, logging)
- **currencies/**: Currency management module
- **database/**: Database connection and configuration
- **db/**: Drizzle ORM schema and seed data
- **health/**: Health check endpoints
- **lookups/**: Lookup tables (categories, UQC, strengths, etc.)
- **modules/**: Feature modules
  - **accounts/**: Accounting endpoints
  - **products/**: Product CRUD and search
  - **outlets/**: Outlet management
  - **inventory/**: Stock operations
- **sandbox/**: Testing and development utilities
- **sequences/**: Number sequence generation
- **app.module.ts**: Root application module
- **main.ts**: Application entry point

### Database Layer (backend/drizzle/)
- **schema.ts**: Drizzle ORM schema definitions
- **relations.ts**: Table relationships
- **meta/**: Migration metadata
- **migrations/**: SQL migration files

### Scripts (backend/scripts/)
Utility scripts for database operations:
- Data seeding
- Table creation
- Dummy data insertion

## Database Structure (supabase/)

### Migrations (supabase/migrations/)
SQL migration files for schema evolution:
- Initial schema setup
- Product catalog structure
- Accounting tables
- Lookup tables
- Permissions and RLS policies

## Architectural Patterns

### Frontend Architecture
- **State Management**: Riverpod with StateNotifier pattern
- **Navigation**: Declarative routing with GoRouter
- **API Communication**: Dio HTTP client with interceptors
- **Data Flow**: Repository pattern with providers
- **UI Pattern**: Master-detail layout for list/detail views

### Backend Architecture
- **Framework**: NestJS with modular architecture
- **ORM**: Drizzle ORM for type-safe database queries
- **Multi-tenancy**: Middleware-based tenant context injection
- **Authentication**: JWT tokens via Supabase Auth
- **Database**: PostgreSQL with Row-Level Security (RLS)

### Data Flow
```
Flutter UI
    ↓ (User Action)
Riverpod Provider
    ↓ (State Update)
Repository
    ↓ (HTTP Request via Dio)
NestJS Controller
    ↓ (Multi-tenant Middleware)
Service Layer
    ↓ (Drizzle ORM)
Supabase PostgreSQL
```

## Key Relationships

### Multi-tenancy Hierarchy
```
Organization (org_id)
    └── Outlets (outlet_id)
        └── Data (products, sales, inventory)
```

### Product Structure
```
Product
    ├── Category
    ├── Manufacturer
    ├── Tax Group
    ├── Product Contents (compositions)
    │   ├── Content (active ingredient)
    │   └── Strength
    └── Outlet Inventory (stock levels)
```

### Accounting Structure
```
Chart of Accounts
    ├── Account Groups (hierarchical)
    └── Accounts
        └── Journal Entries
            └── Fiscal Years
```
