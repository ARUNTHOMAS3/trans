# Zerpai ERP — Technology Stack

## Frontend (Flutter)

| Concern | Package | Version |
|---|---|---|
| SDK | Flutter | >=3.10.4 / Dart >=3.x |
| State management | flutter_riverpod | ^2.5.1 |
| Navigation | go_router | ^17.0.1 |
| HTTP client | dio | ^5.9.0 (ONLY — `http` package is banned) |
| Supabase | supabase_flutter | ^2.11.0 |
| Local DB (offline) | hive + hive_flutter | ^2.2.3 / ^1.1.0 |
| Config storage | shared_preferences | ^2.3.3 (config-only, not entity cache) |
| Icons (primary) | lucide_icons | ^0.257.0 |
| Icons (brands only) | font_awesome_flutter | ^10.7.0 |
| Charts | fl_chart | ^1.1.1 |
| Animations | lottie | ^3.3.2 |
| Env vars | flutter_dotenv | ^5.2.1 |
| Connectivity | connectivity_plus | ^7.0.0 |
| File picker | file_picker | ^8.0.3 |
| Image compress | flutter_image_compress | ^2.3.0 |
| Code gen | freezed + json_serializable | ^2.5.2 / ^6.8.0 |
| Testing | mocktail | ^1.0.4 |
| E2E testing | Playwright (root package.json) | — |

**Font**: Inter (all weights bundled in `assets/fonts/`), with NotoSans fallbacks for Indian scripts.

## Backend (NestJS)

| Concern | Package | Version |
|---|---|---|
| Framework | @nestjs/common + core | ^10.0.0 |
| Language | TypeScript | ^5.1.3 |
| ORM | drizzle-orm | ^0.45.1 |
| DB migrations | drizzle-kit | ^0.31.8 |
| Database driver | postgres + pg | ^3.4.8 / ^8.16.3 |
| Supabase client | @supabase/supabase-js | ^2.39.0 |
| Auth (ready, not enforced) | @nestjs/jwt + passport-jwt | ^11.0.2 / ^4.0.1 |
| Validation | class-validator + class-transformer | ^0.14.0 / ^0.5.1 |
| Scheduling | @nestjs/schedule | ^6.1.1 |
| Object storage | @aws-sdk/client-s3 (Cloudflare R2) | ^3.1004.0 |
| HTTP client | axios | ^1.14.0 |
| Linter | ESLint + Prettier | ^8.57.1 / 3.8.1 |
| Test runner | Jest + ts-jest | ^29.5.0 / ^29.1.0 |

## Database

- **PostgreSQL** hosted on **Supabase**
- Schema managed via Drizzle ORM (`backend/drizzle/schema.ts` = generated snapshot)
- RLS policies defined but disabled for dev
- Migrations in `supabase/migrations/` (SQL files, numbered)

## Storage

- **Cloudflare R2** for object storage (product images, documents)
- Accessed via AWS SDK S3-compatible API in `accountant/r2-storage.service.ts`

## Deployment

- **Frontend**: Vercel (`vercel.json` at root)
- **Backend**: Vercel (`backend/vercel.json`, entry `api/index.ts`)
- **Prod backend URL**: `https://zabnix-backend.vercel.app`
- **Dev backend URL**: `http://localhost:3001`

## Environment Configuration

### Frontend (`assets/.env`)
```
SUPABASE_URL=
SUPABASE_ANON_KEY=
API_BASE_URL=http://localhost:3001
```

### Backend (`backend/.env`)
```
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
DATABASE_URL=
PORT=3001
```

URL selection logic in `lib/shared/services/api_client.dart`:
- Release build → `https://zabnix-backend.vercel.app`
- Debug web → `http://localhost:3001`
- Otherwise → `API_BASE_URL` from `.env`

## Development Commands

### Flutter Frontend
```bash
flutter pub get                    # Install dependencies
flutter run -d chrome              # Run on web (dev)
flutter build web --release        # Production web build
flutter test                       # Unit/widget tests
flutter analyze                    # Static analysis
dart run build_runner build        # Code generation (Freezed/Hive)
dart run build_runner watch        # Watch mode code gen
flutter pub outdated               # Check for updates
```

### NestJS Backend
```bash
cd backend
npm install                        # Install dependencies
npm run start:dev                  # Dev with watch (port 3001)
npm run build                      # Production build
npm run start:prod                 # Run production build
npm run lint                       # ESLint fix
npm test                           # Jest unit tests
npm run test:e2e                   # E2E tests
npm run db:generate                # Drizzle generate migrations
npm run db:push                    # Push schema to DB
npm run db:pull                    # Pull schema from DB (run BEFORE schema changes)
```

### E2E Tests (Playwright)
```bash
npx playwright test                # Run all e2e tests
npx playwright test --ui           # Interactive UI mode
```

## Multi-Tenant Request Headers

Every API request must include:
- `X-Org-Id`: organization UUID
- `X-Outlet-Id`: outlet/branch UUID

These are injected by `TenantMiddleware` and consumed by all service queries.
