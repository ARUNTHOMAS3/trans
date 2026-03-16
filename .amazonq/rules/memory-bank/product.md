# Product Overview

## Project Purpose
ZERPAI ERP is a modern, multi-tenant Enterprise Resource Planning system designed for pharmaceutical retail and distribution businesses. It provides comprehensive management of inventory, sales, purchases, accounting, and reporting through a unified platform.

## Value Proposition
- **Multi-tenant Architecture**: Supports multiple organizations and outlets with automatic data isolation via org_id and outlet_id filtering
- **Cross-platform**: Single codebase serving web and Android platforms through Flutter
- **Real-time Data**: Leverages Supabase for real-time database synchronization and authentication
- **Performance-optimized**: Cursor-based pagination, server-side search, and intelligent caching for handling large datasets (27k+ items)
- **Pharmaceutical-focused**: Specialized features for drug composition tracking, strength management, and regulatory compliance

## Key Features

### Inventory Management
- Product catalog with advanced search (trigram indexing, ranked results)
- Composition tracking (active ingredients, strengths, dosage forms)
- Stock level monitoring across multiple outlets
- Barcode/EAN scanning support
- Serial number tracking for controlled items

### Sales & Purchases
- Multi-outlet sales processing
- Purchase order management
- Price list management with customer-specific pricing
- Tax group configuration and calculation

### Accounting Module
- Chart of accounts with hierarchical structure
- Manual journal entries
- Fiscal year management
- Opening balance configuration
- Multi-currency support

### Multi-tenancy & Security
- Organization-level data isolation
- Outlet/branch-level filtering
- Row-level security (RLS) in database
- JWT-based authentication via Supabase

### Reporting & Analytics
- Real-time dashboard with key metrics
- Customizable column visibility
- Export capabilities
- Performance-optimized queries with database indexing

## Target Users
- Pharmaceutical retail chains
- Medical supply distributors
- Multi-branch pharmacy operations
- Healthcare inventory managers
- Accounting teams in healthcare organizations

## Use Cases
- Managing inventory across multiple pharmacy branches
- Processing sales with automatic tax calculations
- Tracking drug compositions and regulatory information
- Generating financial reports per outlet or organization
- Maintaining opening balances for fiscal year transitions
- Searching and filtering large product catalogs efficiently
