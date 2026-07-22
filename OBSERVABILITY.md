
# Zerpai Observability Implementation

Status: instrumentation-only; business logic unchanged.
Feature flag: ENABLE_PERFORMANCE_MONITORING.
Default: disabled.

## 1. Implementation plan

1. Enable the compile-time Flutter flag and backend environment flag only in
   diagnostic/staged builds.
2. Start the Flutter telemetry collector before runApp; attach frame timings,
   Riverpod observer, GoRouter NavigatorObserver, Dio interceptor, and browser
   PerformanceObserver.
3. Start backend correlation middleware before tenant middleware and the global
   request interceptor after business handlers.
4. Measure Drizzle/Postgres tagged queries through the client proxy; store only
   hashed query fingerprints, durations, row counts, and errors.
5. Export bounded in-memory records as JSON or CSV.
6. Correlate records with X-Request-ID / correlation_id; review telemetry before
   any optimization.

## 2. Architecture

\`\`\`mermaid
flowchart LR
  UI[Flutter UI] --> F[Flutter telemetry]
  F --> T[Bounded local collector]
  UI --> D[Dio interceptor]
  D -->|X-Request-ID| C[Correlation middleware]
  C --> N[Nest request interceptor]
  N --> S[Observability service]
  N --> B[Business handlers]
  B --> DB[Drizzle/Postgres client proxy]
  DB --> S
  T --> E[JSON/CSV export]
  S --> E
\`\`\`

## 3. Files modified

- lib/main.dart
- lib/app/routing/app_router.dart
- lib/core/services/api_client.dart
- backend/src/main.ts
- backend/src/app.module.ts
- backend/src/db/db.ts

## 4. Files created

- lib/core/observability/performance_telemetry.dart
- lib/core/observability/dio_telemetry_interceptor.dart
- lib/core/observability/browser_performance_observer.dart
- lib/core/observability/browser_performance_observer_web.dart
- lib/core/observability/browser_performance_observer_stub.dart
- backend/src/common/observability/observability.service.ts
- backend/src/common/observability/correlation.middleware.ts
- backend/src/common/observability/observability.interceptor.ts
- backend/src/common/observability/observability.controller.ts

## 5. Telemetry schema

Flutter and backend records share this envelope:

\`\`\`json
{
  "timestamp": "ISO-8601 UTC",
  "name": "api_request|frame|route_push|database_query",
  "category": "navigation|network|frame|riverpod|database|browser",
  "correlation_id": "request/session id",
  "duration_ms": 12.34,
  "metrics": {}
}
\`\`\`

Common metrics: method, path, status_code, request_bytes,
response_bytes, build_ms, raster_ms, dropped, long_frame, provider,
cache hit/miss, query_fingerprint, rows, error.

## 6. Logging schema

- Console mode: one JSON event per line.
- Development mode: sampled events plus debug console output.
- Production mode: bounded sampled memory records; no raw payloads, tokens,
  passwords, SQL text, customer data, or response bodies.
- JSON export: GET /api/v1/telemetry/export?format=json.
- CSV export: GET /api/v1/telemetry/export?format=csv.
- Export is protected by the existing tenant/auth middleware and should be
  exposed only to an operationally approved admin session.

## 7. Correlation flow

\`\`\`
Flutter session correlation
  -> Dio request correlation_id
  -> X-Request-ID
  -> backend request correlationId
  -> HTTP telemetry record
  -> database query fingerprint record
  -> JSON/CSV export
\`\`\`

The database deliberately stores only a SHA-256 query fingerprint, never SQL
text or bind values. Existing tenant and authentication headers remain intact.

## 8. Metrics catalog

Frontend:
route push/pop, API duration/status/bytes, cache lookup/hit/miss, provider add/
update/dispose, frame build/raster/total, dropped/long frame, browser resource/
longtask/event/paint/LCP/layout-shift entries.

Backend:
request ID, route, controller, handler, status, request/response bytes, total
duration, database query duration, query fingerprint, row count, error.

Not automatically available from a single global hook:
individual widget build/rebuild duration, service-method spans, guard-only
duration, connection wait, pool usage, and serialization-only duration. Use the
span/record APIs at those owners before claiming those metrics.

## 9. Dashboard design

Dashboard panels should consume exported records or a collector:

1. Route and API p50/p95/p99 latency.
2. Error rate by route/status.
3. Request and response byte percentiles.
4. Duplicate request count by path/correlation session.
5. Frame build/raster p95, dropped-frame rate, long-frame count.
6. Provider invalidation count by provider.
7. Cache hit/miss ratio.
8. Database query p50/p95/p99 by fingerprint and row count.
9. Correlation drill-down from route to API to database.
10. Heap/browser PerformanceObserver data when available.

## 10. Implementation order

- First: enable flag in a diagnostic build; verify disabled build has no observers.
- Second: verify one Flutter route and one Dio request correlation.
- Third: verify backend response header and HTTP telemetry.
- Fourth: verify one Drizzle query duration and row count.
- Fifth: validate JSON/CSV exports and redaction.
- Sixth: run route/table/dropdown/date-picker scenarios and review data.
- Seventh: add owner-local spans only where a missing metric is actionable.

## Safety boundaries

- No business rules, DTOs, queries, routes, schema tables, or UI behavior were
  changed.
- No telemetry database table or migration was added.
- Records are bounded in memory and sampled.
- Disable with ENABLE_PERFORMANCE_MONITORING=false or omit the Flutter
  dart-define.

