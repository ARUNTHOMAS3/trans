# `APP_PERFORMANCE_AND_LOADING_PLAN.md` (Draft)

## 1. Goals
- Make UI loading feel instant and predictable.
- Reduce app weight and runtime overhead.
- Ensure DB/API data loads are reliable, cache-friendly, and observable.
- Remove unnecessary rebuilds, duplicate requests, and spinner-heavy UX.

## 2. Success Metrics
- First meaningful paint < 2.0s on web.
- Route transition perceived latency < 300ms.
- API error rate < 1%.
- Duplicate network calls reduced by 50%+.
- Spinner-only loaders replaced by contextual skeleton loaders across major pages.

## 3. Architecture Strategy
- Keep feature-first module structure.
- Standardize data flow: `Provider -> Repository -> API Service`.
- Enforce one source of truth per screen state.
- Add strict request lifecycle handling: loading, success, empty, error, retry.

## 4. Loading UX Strategy
- Use contextual skeletons for page/section loading.
- Keep button-level inline loaders for save/update only.
- Use optimistic updates where safe (list edits, status toggles).
- Preload likely next-screen data on hover/navigation intent.

## 5. Data Loading Strategy (Backend + DB)
- Add paginated APIs everywhere lists are large (`limit`, cursor/page).
- Add selective fields/projections for list endpoints.
- Normalize all endpoint payload shapes.
- Add backend indexes for common filters/sorts (entity_id, product_id, created_at, status).
- Prevent N+1 queries in service layer; batch related lookups.

## 6. Caching Strategy
- In-memory cache for hot lookups (units, tax, warehouses, categories).
- Stale-while-revalidate for list/detail screens.
- Cache key policy: route params + filters + org/entity context.
- Invalidate cache only on relevant write operations.

## 7. Network & API Efficiency
- Debounce search/filter requests.
- Cancel in-flight requests on filter/tab changes.
- Add retry policy for transient failures (with cap/backoff).
- Compress payloads and avoid over-fetching.
- Add request timing logs (client + server).

## 8. Flutter Performance Strategy
- Reduce rebuild scope using granular providers/selectors.
- Use `const` widgets where possible.
- Virtualize long lists/tables; avoid full-column rebuilds.
- Avoid expensive sync work in build methods.
- Profile and eliminate jank-heavy widgets on key pages.

## 9. Error Handling & Resilience
- No silent fallback to empty data on API failure.
- Standard error surface per section with retry action.
- Add typed exceptions from API service to UI layer.
- Add offline/network-aware states for critical screens.

## 10. Observability
- Add screen-level load timing events.
- Track API latency percentiles (p50/p95/p99).
- Track cache hit ratio per endpoint.
- Track UI states: loading, empty, error, success frequency.
- Add route/navigation failure tracking (GoRouter params, missing context).

## 11. Security & Data Integrity
- Enforce org/entity scoping on all endpoints.
- Validate all IDs and filter params server-side.
- Avoid client assumptions for business-critical defaults.
- Keep DB schema and API contracts versioned and documented.

## 12. Rollout Plan
1. Baseline profiling and metric capture.
2. Loader UX standardization (skeleton-first).
3. API pagination + payload normalization.
4. Caching + request cancellation/debounce.
5. DB query/index optimization.
6. Provider rebuild optimization.
7. Error/observability hardening.
8. Staged rollout with regression checks.

## 13. Validation Checklist
- `flutter analyze` clean on touched scope.
- No route-param assertion failures.
- No UUID leakage in user-facing labels where human reference exists.
- Empty/error states validated for all major pages.
- Lighthouse/web performance comparison before vs after.
- Real DB data verified across key flows (items, inventory, settings, reports).

## 14. Risks
- Over-caching stale data.
- Payload contract drift between backend and frontend.
- Skeleton mismatch creating perceived instability.
- Pagination edge bugs (duplicate/missing rows).

## 15. Deliverables
- Performance baseline report.
- Loading UX standards doc.
- API contract + pagination checklist.
- Caching/invalidation matrix.
- DB optimization report (indexes + query plans).
- Final performance comparison report (before/after).