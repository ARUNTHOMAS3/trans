# Technology Stack

## Programming Languages

### Frontend
- **Dart**: 3.10.4+ (Flutter SDK language)
- **Language Features**: Null safety, async/await, extension methods

### Backend
- **TypeScript**: 5.1.3+
- **Node.js**: 20+

### Database
- **SQL**: PostgreSQL dialect for migrations and queries

## Frontend Technologies

### Framework & Core
- **Flutter**: 3.x (Web + Android cross-platform framework)
- **Flutter SDK**: Material Design 3 components

### State Management
- **flutter_riverpod**: 2.5.1 (Provider-based state management)
- **Patterns**: StateNotifier, AsyncValue, Provider composition

### Navigation
- **go_router**: 17.0.1 (Declarative routing with deep linking support)

### Networking
- **dio**: 5.9.0 (HTTP client with interceptors)
- **connectivity_plus**: 7.0.0 (Network connectivity monitoring)
- **internet_connection_checker**: 1.0.0+1

### Backend Integration
- **supabase_flutter**: 2.11.0 (Supabase client for auth and realtime)

### Local Storage
- **hive**: 2.2.3 (NoSQL local database)
- **hive_flutter**: 1.1.0
- **shared_preferences**: 2.3.3 (Key-value storage)
- **path_provider**: 2.1.5 (File system paths)

### UI Components & Styling
- **lucide_icons**: 0.257.0 (Icon library)
- **font_awesome_flutter**: 10.7.0
- **google_fonts**: 6.2.1
- **Inter Font Family**: Custom font assets
- **shimmer**: 3.0.0 (Loading placeholders)
- **dotted_border**: 2.1.0
- **lottie**: 3.3.2 (Animations)
- **flutter_svg**: 2.0.10+1
- **fl_chart**: 1.1.1 (Charts and graphs)

### Utilities
- **intl**: 0.19.0 (Internationalization and date formatting)
- **uuid**: 4.4.0 (UUID generation)
- **crypto**: 3.0.6 (Cryptographic functions)
- **logger**: 2.6.2 (Logging)
- **equatable**: 2.0.7 (Value equality)
- **flutter_dotenv**: 5.2.1 (Environment variables)

### Code Generation
- **json_annotation**: 4.9.0
- **json_serializable**: 6.8.0
- **freezed_annotation**: 2.4.4
- **freezed**: 2.5.2
- **build_runner**: 2.4.15

### Testing
- **flutter_test**: SDK (Unit and widget testing)
- **mocktail**: 1.0.4 (Mocking library)
- **flutter_lints**: 5.0.0 (Linting rules)

## Backend Technologies

### Framework
- **NestJS**: 10.0.0 (Progressive Node.js framework)
- **@nestjs/core**: 10.0.0
- **@nestjs/common**: 10.0.0
- **@nestjs/platform-express**: 10.0.0

### Authentication & Security
- **@nestjs/passport**: 11.0.5
- **@nestjs/jwt**: 11.0.2
- **passport**: 0.7.0
- **passport-jwt**: 4.0.1

### Database & ORM
- **drizzle-orm**: 0.45.1 (TypeScript ORM)
- **drizzle-kit**: 0.31.8 (Schema management and migrations)
- **pg**: 8.16.3 (PostgreSQL client)
- **postgres**: 3.4.8 (Alternative PostgreSQL client)
- **@supabase/supabase-js**: 2.39.0 (Supabase client)

### Utilities
- **class-transformer**: 0.5.1 (Object transformation)
- **class-validator**: 0.14.0 (Validation decorators)
- **dotenv**: 16.3.1 (Environment variables)
- **axios**: 1.13.3 (HTTP client)
- **rxjs**: 7.8.1 (Reactive programming)
- **reflect-metadata**: 0.1.13 (Metadata reflection)
- **@nestjs/schedule**: 6.1.1 (Task scheduling)
- **@nestjs/mapped-types**: 2.1.0 (DTO mapping)

### Development Tools
- **@nestjs/cli**: 10.0.0
- **@nestjs/schematics**: 10.0.0
- **@nestjs/testing**: 10.0.0
- **typescript**: 5.1.3
- **ts-node**: 10.9.1
- **ts-loader**: 9.4.3
- **tsconfig-paths**: 4.2.0

### Testing
- **jest**: 29.5.0
- **ts-jest**: 29.1.0
- **supertest**: 6.3.3

### Linting & Formatting
- **eslint**: 8.42.0
- **@typescript-eslint/eslint-plugin**: 6.0.0
- **@typescript-eslint/parser**: 6.0.0
- **prettier**: 3.8.1
- **eslint-config-prettier**: 9.0.0
- **eslint-plugin-prettier**: 5.0.0

## Database

### Platform
- **Supabase**: PostgreSQL-based backend-as-a-service
- **PostgreSQL**: Latest version via Supabase

### Features Used
- Row-Level Security (RLS)
- Trigram indexing (pg_trgm extension)
- GIN indexes for full-text search
- Composite indexes for cursor pagination
- Foreign key constraints
- Stored procedures and triggers

### Key Indexes
- `idx_products_active_created_id`: Keyset pagination
- `idx_products_name_trgm`: Trigram search on product names
- `idx_products_sku`, `idx_products_ean`: Exact match lookups
- `idx_outlet_inventory_outlet_product`: Stock level queries

## Build Systems

### Frontend
- **Flutter Build System**: Native compilation for each platform
- **Build Runner**: Code generation for JSON serialization and Freezed

### Backend
- **NestJS CLI**: Build and development tooling
- **TypeScript Compiler**: Transpilation to JavaScript
- **Drizzle Kit**: Database schema generation and migration

## Development Commands

### Frontend Development
```bash
# Install dependencies
flutter pub get

# Run development server (web)
flutter run -d chrome

# Run on Android
flutter run -d android

# Build for production
flutter build web
flutter build apk

# Run tests
flutter test

# Code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Clean build artifacts
flutter clean
```

### Backend Development
```bash
# Install dependencies
cd backend && npm install

# Development mode with hot reload
npm run start:dev

# Production build
npm run build

# Start production server
npm run start:prod

# Run tests
npm test
npm run test:watch
npm run test:cov

# Database operations
npm run db:generate    # Generate migrations
npm run db:push        # Push schema to database
npm run db:pull        # Pull schema from database

# Linting and formatting
npm run lint
npm run format
```

### Database Operations
```bash
# Apply migrations (via Supabase dashboard)
# Copy SQL from supabase/migrations/ and run in SQL Editor

# Run seed scripts
node backend/scripts/insert-dummy-data.js

# Apply indexes
node backend/apply-indexes.js
```

## Environment Configuration

### Frontend (.env)
```env
SUPABASE_URL=<supabase_project_url>
SUPABASE_ANON_KEY=<supabase_anon_key>
API_BASE_URL=http://localhost:3001
```

### Backend (backend/.env)
```env
SUPABASE_URL=<supabase_project_url>
SUPABASE_SERVICE_ROLE_KEY=<service_role_key>
PORT=3001
DATABASE_URL=<postgresql_connection_string>
```

## Deployment Targets

### Frontend
- **Web**: Static hosting (Vercel, Firebase Hosting)
- **Android**: APK/AAB via Google Play Store
- **Future**: iOS, Windows, macOS

### Backend
- **Vercel**: Serverless functions
- **Node.js**: Traditional server deployment
- **Port**: 3001 (default)

## Version Control
- **Git**: Source control
- **GitHub**: Repository hosting
- **Branch Strategy**: Feature branches from main
