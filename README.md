# ZERPAI ERP - Monorepo

Modern ERP system with Flutter frontend and NestJS backend.

## 📁 Monorepo Structure

```
zerpai_erp/
├── lib/                    # Flutter Frontend (Web + Android)
│   ├── core/               # Core utilities, API client
│   ├── data/               # Models, repositories
│   ├── modules/            # Feature modules
│   └── shared/             # Shared widgets, services
│
├── backend/                # NestJS Backend API
│   ├── src/
│   │   ├── products/       # Products module
│   │   ├── supabase/       # Supabase client
│   │   ├── common/         # Middleware (multi-tenant)
│   │   └── main.ts
│   └── package.json
│
├── supabase/               # Database
│   └── migrations/         # SQL migrations
│
├── pubspec.yaml            # Flutter dependencies
└── README.md
```

## 🚀 Tech Stack

- **Frontend**: Flutter (Web + Android), Riverpod, Dio
- **Backend**: NestJS, TypeScript, Supabase Client
- **Database**: Supabase (PostgreSQL) + Auth + Storage
- **Multi-tenancy**: org_id + outlet_id filtering

## 🛠️ Development Setup

### Prerequisites
- Flutter SDK 3.x
- Node.js 20+
- Supabase account

### 1. Database Setup

Run the migration in Supabase dashboard:
```bash
# Copy contents of: supabase/migrations/001_initial_schema_and_seed.sql
# Paste in: Supabase Dashboard → SQL Editor → New Query
```

### 2. Backend Setup

```bash
cd backend
npm install
npm run start:dev  # Runs on http://localhost:3001
```

### 3. Frontend Setup

```bash
flutter pub get
flutter run -d chrome
```

## 🌐 Environment Variables

### Frontend (.env)
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
API_BASE_URL=http://localhost:3001
```

### Backend (backend/.env)
```env
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
PORT=3001
```

## 📊 Architecture

```
Flutter App
    ↓ REST API (dio)
NestJS Backend (Multi-tenant middleware)
    ↓ SQL Queries
Supabase PostgreSQL (RLS enabled)
```

## 🔒 Multi-Tenancy

Every request includes:
- `X-Org-Id` header (organization)
- `X-Outlet-Id` header (outlet/branch)

Backend automatically filters all queries by org_id.

## 📦 Available Scripts

### Backend
- `npm run start:dev` - Development mode
- `npm run build` - Production build
- `npm test` - Run tests

### Frontend
- `flutter run` - Run app
- `flutter build web` - Build for web
- `flutter test` - Run tests

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes
3. Test locally
4. Create pull request

## 📝 License

Private - ZABNIX Organization