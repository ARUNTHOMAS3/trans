# Zerpai ERP Tech Stack PRD
**Last Updated: 2026-04-20 12:46:08**

## Edit Policy

Do not edit this PRD file unless explicitly requested by the user or team head.

## Last Reviewed

- **Date:** 2026-04-04
- **Review Basis:** `pubspec.yaml`, root `package.json`, `backend/package.json`, `lib/main.dart`, `lib/core/routing/app_router.dart`, `lib/core/services/api_client.dart`, `backend/src/main.ts`, `backend/api/index.ts`, `backend/drizzle.config.ts`, `vercel.json`, `backend/vercel.json`, `PRD/PRD.md`, and PRD supplement files.

---

## 1. Canonical Stack Decisions

These stack choices are locked unless the PRD is intentionally revised.

| Layer | Canonical Technology | Implementation Notes |
| --- | --- | --- |
| Frontend app | Flutter (Dart) | Web-first ERP UI with offline-capable local storage and Android compatibility. |
| Frontend state | Riverpod (`flutter_riverpod`) | App entry uses `ProviderScope`; module providers live under `lib/modules/<module>/providers/`. |
| Frontend routing | GoRouter (`go_router`) | All app routes are centralized in `lib/core/routing/app_router.dart` and deep-link under `/:orgSystemId/*`. |
| Frontend HTTP | Dio (`dio`) only | `http` package is not allowed. Dio setup is centralized through `lib/core/services/api_client.dart` and re-exported from `lib/shared/services/api_client.dart`. |
| Frontend offline/local DB | Hive (`hive`, `hive_flutter`) | `lib/main.dart` initializes Hive, registers adapters, and opens business caches plus `config` and `local_drafts` boxes. |
| Frontend config | `flutter_dotenv` + `--dart-define` | Supabase and API base URL values are resolved from dart-define first, then `.env` asset fallback for local/mobile. |
| Backend framework | NestJS (`@nestjs/*`) | API runs as a Nest app locally and as a Vercel serverless handler through `backend/api/index.ts`. |
| Backend language | TypeScript | Backend source lives under `backend/src/`; strict Drizzle schema typing is enabled. |
| Backend ORM/query layer | Drizzle ORM + `drizzle-kit` | Canonical schema source is `backend/src/db/schema.ts`; generated artifacts are emitted to `backend/drizzle/`. |
| Database | Supabase PostgreSQL | Supabase client is used server-side and Flutter initializes `supabase_flutter` client-side. |
| Object storage | Cloudflare R2 via AWS S3 SDK | `@aws-sdk/client-s3` and `@aws-sdk/s3-request-presigner` are included in backend dependencies. |
| Frontend hosting | Vercel static deployment | Root `vercel.json` serves `build/web` and rewrites app routes to `index.html`. |
| Backend hosting | Vercel Node serverless | `backend/vercel.json` routes all requests to `api/index.ts` and configures daily cron. |
| Frontend unit/widget testing | `flutter_test`, `mocktail` | Root scripts expose `npm run test:flutter` as a wrapper around `flutter test`. |
| Backend testing | Jest + `ts-jest` | Backend scripts expose `npm test`, `npm run test:e2e`, and coverage commands. |
| E2E/browser testing | Playwright | Root `playwright.config.ts` builds Flutter web locally and serves `build/web` through `http-server` for Chromium tests. |

---

## 2. Frontend Stack Inventory

### 2.1 Runtime Dependencies

| Concern | Package | Current Version |
| --- | --- | --- |
| State management | `flutter_riverpod` | `^2.5.1` |
| Navigation | `go_router` | `^17.0.1` |
| HTTP client | `dio` | `^5.9.0` |
| Supabase client | `supabase_flutter` | `^2.11.0` |
| Environment variables | `flutter_dotenv` | `^5.2.1` |
| Offline storage | `hive`, `hive_flutter` | `^2.2.3`, `^1.1.0` |
| Connectivity checks | `connectivity_plus`, `internet_connection_checker` | `^7.0.0`, `^1.0.0+1` |
| UI icons | `lucide_icons`, `font_awesome_flutter`, `cupertino_icons` | `^0.257.0`, `^10.7.0`, `^1.0.8` |
| Charts and visual states | `fl_chart`, `shimmer`, `skeletonizer`, `lottie`, `flutter_svg`, `dotted_border`, `flutter_colorpicker` | `^1.1.1`, `^3.0.0`, `^2.1.3`, `^3.3.2`, `^2.0.10+1`, `^2.1.0`, `^1.1.0` |
| Fonts and formatting | `google_fonts`, `intl` | `^6.2.1`, `^0.19.0` |
| Data modeling/codegen | `freezed_annotation`, `json_annotation`, `freezed`, `json_serializable`, `build_runner`, `hive_generator` | `^2.4.4`, `^4.9.0`, `^2.5.2`, `^6.8.0`, `^2.4.15`, `^2.0.1` |
| Utilities | `uuid`, `crypto`, `logger`, `equatable` | `^4.4.0`, `^3.0.6`, `^2.6.2`, `^2.0.7` |
| Device/file helpers | `path_provider`, `shared_preferences`, `file_picker`, `flutter_image_compress`, `desktop_drop` | `^2.1.5`, `^2.3.3`, `^8.0.3`, `^2.3.0`, `^0.5.0` |
| Web interop | `web` | `1.1.0` |

### 2.2 Flutter Runtime Architecture

- `lib/main.dart` bootstraps path-based URLs, Hive, Supabase, env loading, and `ProviderScope`.
- `lib/core/routing/app_router.dart` is the central GoRouter registry and shells all module pages through `ZerpaiShell`.
- `lib/core/services/api_client.dart` is the Dio client singleton and applies standard response unwrapping, error normalization, short-lived GET caching, and `X-Request-ID` injection.
- `lib/shared/services/api_client.dart` currently re-exports the core API client to satisfy the shared-service import path.
- `lib/core/theme/`, `lib/core/layout/`, `lib/shared/widgets/`, and `lib/modules/<module>/` remain the canonical frontend structure boundaries.

### 2.3 Flutter Module Inventory

Current top-level Flutter feature modules under `lib/modules/`:

- `accountant`
- `auth`
- `branches`
- `home`
- `inventory`
- `items`
- `mapping`
- `printing`
- `purchases`
- `reports`
- `sales`
- `settings`

Observed source footprint at review time:

- `lib/`: 435 tracked source files
- `test/`: 7 tracked test files

### 2.4 Frontend UI Stack Rules

- All form dropdowns must use `FormDropdown<T>`.
- All tooltips must use `ZTooltip`.
- Anchored business date inputs should use `ZerpaiDatePicker`.
- Floating surfaces such as dialogs, menus, dropdown overlays, and popovers must default to pure white `#FFFFFF`.
- New modules, tabs, and significant sub-screens must be exposed through named GoRouter routes with path/query parameters preserved.

---

## 3. Backend Stack Inventory

### 3.1 Runtime Dependencies

| Concern | Package | Current Version |
| --- | --- | --- |
| Nest framework | `@nestjs/common`, `@nestjs/core`, `@nestjs/platform-express`, `@nestjs/mapped-types`, `@nestjs/schedule` | `^10.0.0`, `^10.0.0`, `^10.0.0`, `^2.1.0`, `^6.1.1` |
| Auth-ready packages | `@nestjs/jwt`, `@nestjs/passport`, `passport`, `passport-jwt` | `^11.0.2`, `^11.0.5`, `^0.7.0`, `^4.0.1` |
| Database/query | `drizzle-orm`, `drizzle-kit`, `pg`, `postgres`, `@supabase/supabase-js` | `^0.45.1`, `^0.31.8`, `^8.16.3`, `^3.4.8`, `^2.39.0` |
| Validation and transforms | `class-validator`, `class-transformer` | `^0.14.0`, `^0.5.1` |
| Environment/config | `dotenv` | `^16.3.1` |
| Storage integration | `@aws-sdk/client-s3`, `@aws-sdk/s3-request-presigner` | `^3.1004.0`, `^3.1004.0` |
| Server HTTP client | `axios` | `^1.14.0` |
| Runtime support | `reflect-metadata`, `rxjs` | `^0.1.13`, `^7.8.1` |
| Lint/build/test tooling | `typescript`, `eslint`, `prettier`, `jest`, `ts-jest`, `ts-node`, `ts-loader`, `tsconfig-paths`, `supertest` | `^5.1.3`, `^8.57.1`, `3.8.1`, `^29.5.0`, `^29.1.0`, `^10.9.1`, `^9.4.3`, `^4.2.0`, `^6.3.3` |

### 3.2 Backend Runtime Architecture

- `backend/src/main.ts` starts the Nest app locally on `PORT` (default `3001`) and applies:
  - global prefix `api/v1`
  - CORS allowlist with localhost and Vercel-friendly host patterns
  - `ValidationPipe` with whitelist, transform, and reject-on-unknown-fields behavior
  - `StandardResponseInterceptor`
  - `GlobalExceptionFilter`
- `backend/api/index.ts` wraps the Nest app in an Express adapter for Vercel serverless execution and reuses the same `api/v1` prefix plus validation/interceptor setup.
- `backend/src/common/middleware/tenant.middleware.ts` resolves `entityId` from `X-Entity-Id`, `X-Org-Id`, or `X-Branch-Id` headers by looking up `organisation_branch_master`. Controllers access resolved context via `@Tenant()` or `@Tenant('entityId')` decorator.
- `backend/drizzle.config.ts` points Drizzle to `backend/src/db/schema.ts`, writes generated artifacts to `backend/drizzle/`, and uses `DATABASE_URL`.

### 3.3 Backend Module Inventory

Current top-level backend modules under `backend/src/modules/`:

- `accountant`
- `branches`
- `documents`
- `gst`
- `health`
- `inventory`
- `lookups`
- `branches`
- `products`
- `purchases`
- `reports`
- `sales`
- `supabase`
- `transaction-locking`
- `transaction-series`
- `users`
- `warehouses-settings`

Observed source footprint at review time:

- `backend/src/`: 108 tracked source/test files

---

## 4. Data, Tenancy, and Storage Stack

### 4.1 Database and Schema Management

- Primary database: Supabase-hosted PostgreSQL.
- Canonical Drizzle schema source: `backend/src/db/schema.ts`.
- Generated Drizzle artifacts: `backend/drizzle/schema.ts`, `backend/drizzle/relations.ts`, and numbered SQL snapshots under `backend/drizzle/`.
- Legacy/manual SQL migrations exist under `supabase/legacy_migrations/` and should be treated as historical migration artifacts, not the preferred authoring path for new schema work unless a scoped manual migration is explicitly required.

### 4.2 Tenancy Model

- Dev and staging may run with auth toggled off, but schema and services must stay auth-ready.`r`n- All business tables scope data via `entity_id uuid NOT NULL REFERENCES organisation_branch_master(id)` � the single canonical tenant scope column.`r`n- `organisation_branch_master`: `type` = `'ORG'` or `'BRANCH'`, `ref_id` links to actual `organization.id` or `branches.id`.`r`n- Global lookup tables (`products`, `categories`, `brands`, etc.) have NO `entity_id`.`r`n- API requests use tenant headers `X-Entity-Id` (preferred), `X-Org-Id`, and `X-Branch-Id`. Controllers access resolved context via `@Tenant()` or `@Tenant('entityId')` decorator.
- Current frontend routes inject a dev `orgSystemId` path segment and default to `0000000000` when no org prefix is present.

### 4.3 Object and Offline Storage

- Cloud object storage uses Cloudflare R2 with S3-compatible AWS SDK packages in the backend.
- Client-side offline persistence uses Hive boxes for products, customers, POS drafts, sales documents, purchasing documents, stock, journal/accounting data, and local form drafts.
- `shared_preferences` is available for lightweight config only and should not be used as the primary business-entity cache.

---

## 5. Deployment, Environments, and Operations

### 5.1 Frontend Deployment

- Root `vercel.json` serves `build/web` and rewrites all routes to `/index.html`, which is required for GoRouter deep-link refresh behavior.
- Local dev command remains `flutter run -d chrome`.
- Production web build command remains `flutter build web --release`.

### 5.2 Backend Deployment

- `backend/vercel.json` uses `@vercel/node` against `api/index.ts`.
- All backend routes are rewritten to the Vercel function entrypoint.
- CORS headers explicitly allow org/branch tenant headers.
- A daily cron is configured for `/api/accounts/recurring-journals/trigger-cron`.

### 5.3 Environment Variables

Frontend:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `API_BASE_URL`

Backend (`backend/.env.example`):

- `PORT`
- `NODE_ENV`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ANON_KEY`
- `CORS_ORIGINS`
- `DATABASE_URL`
- `JWT_SECRET`
- `SESSION_SECRET`
- `SANDBOX_API_KEY`
- `SANDBOX_API_SECRET`
- `LOG_LEVEL`
- `ENABLE_REQUEST_LOGGING`
- `REQUEST_TIMEOUT`
- `MAX_REQUEST_SIZE`

### 5.4 Monitoring and Resilience Stack

PRD supplements currently prescribe:

- Vercel observability/deployment monitoring
- Sentry for frontend/backend error tracking
- UptimeRobot or equivalent uptime checks
- structured logs with contextual metadata and no sensitive data leakage

Implementation note: the repository currently contains custom response/error middleware and logger package dependencies, but no Sentry SDK package was observed in `pubspec.yaml` or `backend/package.json` during this review.

---

## 6. Quality, Testing, and Tooling

### 6.1 Available Test Commands

Root scripts:

- `npm run test:flutter`
- `npm run test:backend`
- `npm run test:e2e`
- `npm run test:e2e:ui`
- `npm run test:e2e:debug`
- `npm run test:e2e:report`
- `npm run test:all`

Backend scripts:

- `npm run build`
- `npm run lint`
- `npm test`
- `npm run test:watch`
- `npm run test:cov`
- `npm run test:e2e`
- `npm run db:generate`
- `npm run db:push`
- `npm run db:pull`

Flutter commands:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web --release`
- `dart run build_runner build`

### 6.2 Test Stack Constraints

- PRD target coverage remains 70% line/branch coverage for new and modified code.
- Flutter tests should mirror `lib/` paths under `test/`.
- Backend integration tests should validate controller + DTO + service + database behavior for new APIs.
- Playwright E2E is configured at root under `tests/e2e` and currently runs Chromium locally, with Firefox/WebKit enabled in CI mode.

---

## 7. PRD vs Codebase Drift Found During Review

This section should be actively maintained when the stack changes.

| Topic | PRD Expectation | Observed Codebase State | Recommended Action |
| --- | --- | --- | --- |
| Swagger/OpenAPI | `PRD/PRD.md` requires OpenAPI docs via `@nestjs/swagger` and `/api-docs`. | No `@nestjs/swagger` dependency or Swagger bootstrap code was found in `backend/package.json` or `backend/src/main.ts`. | Either implement Swagger or revise the PRD requirement if API docs are intentionally deferred. |
| Monitoring SDKs | `PRD/prd_monitoring.md` and `PRD/README_PRD.md` mention Sentry/UptimeRobot. | No Sentry SDK dependency was found in frontend/backend manifests during this review. | Add observability SDKs and uptime setup, or mark this as a deployment-phase gap. |
| CI/CD workflow files | `PRD/prd_deployment.md` describes GitHub Actions CI/CD. | No `.github/workflows/*` files were present in this checkout at review time. | Add workflows or document the current manual/Vercel-only release flow. |
| Frontend API client path | PRD references `lib/shared/services/api_client.dart` as the implementation anchor. | The actual implementation now lives in `lib/core/services/api_client.dart`; `lib/shared/services/api_client.dart` is a re-export shim. | Keep the shim for compatibility and update PRD text to mention the core implementation location plus shared export path. |
| Root env template | `PRD/PRD.md` expects a committed `.env.example` template. | No root `.env.example` file was found at checkout root; backend has `backend/.env.example`, and Flutter loads `assets/.env`. | Add a root/frontend env template or revise the PRD to document `assets/.env` as the Flutter env template. |

---

## 8. Locked Do-Not-Introduce List

- Do not introduce the Dart `http` package as a parallel API client.
- Do not replace Riverpod with Provider/Bloc/GetX without a deliberate PRD revision.
- Do not bypass GoRouter with direct `Navigator.push` for app navigation.
- Do not use `shared_preferences` as the primary store for business entities.
- Do not scope the `products` master itself by `entity_id` (it is a global table with no tenant scope).
- Do not enable enforced auth, RBAC, or JWT route guards in dev/staging until production approval.
- Do not create new global-settings tables without the `settings_` prefix.

---

## 9. Related PRD References

- `PRD/PRD.md` — master PRD and locked behavioral rules
- `PRD/prd_folder_structure.md` — frontend/backend folder conventions
- `PRD/prd_ui.md` — UI system and control rules
- `PRD/prd_schema.md` — schema snapshot and form-table mapping rules
- `PRD/prd_deployment.md` — release, rollback, and environment workflow
- `PRD/prd_monitoring.md` — monitoring and alerting expectations
- `PRD/prd_disaster_recovery.md` — backup, restore, RTO/RPO
