# ZERPAI ERP — Technology Stack

## Frontend

| Layer | Technology | Version |
|---|---|---|
| Framework | Flutter | SDK >=3.10.4 <4.0.0 |
| Language | Dart | >=3.10.4 |
| State Management | flutter_riverpod | ^2.5.1 |
| Navigation | go_router | ^17.0.1 |
| HTTP Client | dio | ^5.9.0 |
| Auth / DB Client | supabase_flutter | ^2.11.0 |
| Local Storage | hive + hive_flutter | ^2.2.3 / ^1.1.0 |
| Error Monitoring | sentry_flutter | ^8.14.2 |
| Charts | fl_chart | ^1.1.1 |
| Icons | lucide_icons, font_awesome_flutter | ^0.257.0 / ^10.7.0 |
| Fonts | Inter (variable), NotoSans family | bundled TTF |
| Code Generation | freezed, json_serializable, hive_generator | dev deps |
| Testing | flutter_test, mocktail | dev deps |
| E2E Testing | Playwright | via `tests/e2e/` |

## Backend

| Layer | Technology | Version |
|---|---|---|
| Framework | NestJS | ^10.0.0 |
| Language | TypeScript | ^5.1.3 |
| Runtime | Node.js | 20+ |
| ORM | Drizzle ORM | ^0.45.1 |
| DB Driver | postgres (pg) | ^3.4.8 / ^8.16.3 |
| Auth | @nestjs/jwt + passport-jwt | ^11.0.2 / ^4.0.1 |
| Validation | class-validator + class-transformer | ^0.14.0 / ^0.5.1 |
| Queue | BullMQ | ^5.73.0 |
| Queue UI | @bull-board/api + express | ^6.20.6 |
| Email | Resend | ^6.10.0 |
| File Storage | @aws-sdk/client-s3 | ^3.1004.0 |
| Security | Helmet | ^8.1.0 |
| Error Monitoring | @sentry/nestjs | ^10.47.0 |
| Scheduler | @nestjs/schedule | ^6.1.1 |
| Linting | ESLint + Prettier | ^8.57.1 / 3.8.1 |
| Testing | Jest + ts-jest | ^29.5.0 |

## Database

| Layer | Technology |
|---|---|
| Database | Supabase (PostgreSQL) |
| Auth | Supabase Auth |
| Storage | Supabase Storage |
| Schema Management | Drizzle Kit (generate / push / pull) |
| RLS | Enabled (Row Level Security) |

## Infrastructure & Deployment

| Concern | Solution |
|---|---|
| Frontend hosting | Vercel (Flutter web build) |
| Backend hosting | Vercel (serverless NestJS via `api/index.ts`) |
| Database | Supabase cloud |
| Error tracking | Sentry (both frontend and backend) |
| CI/CD | Vercel auto-deploy on push |

## Environment Variables

### Frontend (`assets/.env` or `--dart-define`)
```
SUPABASE_URL=
SUPABASE_ANON_KEY=
API_BASE_URL=http://localhost:3001
SENTRY_DSN=
ENABLE_AUTH=true
```

### Backend (`backend/.env.local`)
```
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
PORT=3001
CORS_ORIGINS=
ENABLE_HELMET=true
ENABLE_BULL_BOARD=true
ENABLE_AUTH=true
```

## Development Commands

### Flutter Frontend
```bash
flutter pub get                    # Install dependencies
flutter run -d chrome              # Run on web
flutter run -d android             # Run on Android
flutter build web                  # Build for web
flutter test                       # Run unit tests
npx playwright test                # Run e2e tests
```

### NestJS Backend
```bash
cd backend
npm install                        # Install dependencies
npm run start:dev                  # Dev mode with watch (port 3001)
npm run build                      # Production build
npm run start:prod                 # Run production build
npm run lint                       # ESLint fix
npm test                           # Jest unit tests
npm run db:generate                # Generate Drizzle migration
npm run db:push                    # Push schema to DB
npm run db:pull                    # Pull schema from DB
```

## API Conventions

- Base path: `/api/v1`
- Multi-tenant headers: `X-Org-Id`, `X-Branch-Id`, `X-Entity-Id` (preferred)
- Auth header: `Authorization: Bearer <jwt>`
- Response envelope: `{ data, message, statusCode }` via `StandardResponseInterceptor`
- Validation: `ValidationPipe` with `whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`
- Use `@Tenant()` or `@Tenant('entityId')` decorator in controllers to access resolved `TenantContext`
