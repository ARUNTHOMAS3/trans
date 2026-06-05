# Permission Governance Rollout Plan

Last Updated: 2026-05-30 (Step 10 wiring batch)
Owner: Codex + Zerpai Team
Status: Completed (Phase 2 Hardening + Coverage Audit)

## 1) Frozen Permission Format

Final format (frozen):
- `module.resource.action`

Examples:
- `sales.invoice.view`
- `inventory.transfer.approve`
- `settings.roles.manage`

## 2) Rollout Checklist

- [x] Step 1: Freeze naming convention to `module.resource.action`.
- [x] Step 2: Create central registry scaffold in `lib/core/auth/permission_registry.dart`.
- [x] Step 3: Create global action constants in `lib/core/auth/permission_actions.dart`.
- [x] Step 4: Create effective permission resolver in `lib/core/auth/permission_resolver.dart`.
- [x] Step 5: Create centralized capability service in `lib/core/auth/capability_service.dart`.
- [x] Step 6 (Phase 1): Connect sidebar gating to capability service.
- [x] Step 6 (Phase 2): Replace all scattered `PermissionService.hasModuleAction` checks.
- [x] Step 7: Enforce role-creation anti-escalation on backend.
- [x] Step 8: Freeze role scope types (`platform`, `organization`, `branch`) in backend code path.
- [x] Step 9: Enforce role ownership editing rules (platform/org/branch) in backend code path.
- [x] Step 10: Invalidate effective permission cache on branch/role/permission updates.

## 3) Phase 1 Scope (Implemented)

- Central permission model foundations added.
- Registry seeded for:
  - `sales`
  - `inventory`
  - `settings`
  - `users`
  - `roles`
- Resolver provides:
  - role permission expansion
  - inheritance handling (`full_access`, `full`)
  - branch guard support
  - override hooks
- Capability API exposed via `capability.can(...)`.
- Sidebar checks migrated to use capability service.

## 4) Next Execution Batches

### Batch A: Backend Role Security (Step 7)
- Done:
  - Assigned permissions are validated against creator permissions.
  - Create/update now block privilege-escalating payloads.

### Batch B: Scope Governance (Steps 8-9)
- Done (backend enforcement path):
  - Role scope type normalized and validated (`platform|organization|branch`).
  - Scope ownership rules enforced for create/update:
    - platform -> platform admin only
    - organization -> same organization
    - branch -> same branch
  - Scope metadata persisted inside role permissions `__meta` for runtime checks.

### Batch C: Full UI Migration (Step 6 Phase 2)
- Done:
  - Replaced remaining direct `PermissionService.hasModuleAction(...)` checks
    across `lib/app` + `lib/modules`.
  - Shared wrapper (`withModulePermission`) routes through `CapabilityService`.
  - Route-level auth checks now use capability service.

### Batch D: Cache Invalidation (Step 10)
- Done:
  - Added central resolver cache + invalidation API.
  - Invalidation hooked on:
    - tenant switch + auth refresh points
    - role create/update/delete/clone
    - user role assignment update

### Batch E: Hardening & Validation
- Done:
  - Added unit tests for resolver/capability engine:
    - `test/core/auth/permission_resolver_test.dart`
    - `test/core/auth/capability_service_test.dart`
  - Fixed legacy fallback guard gap by enforcing branch guard before fallback
    path inside capability service.
  - Verified with:
    - `flutter test test/core/auth/permission_resolver_test.dart test/core/auth/capability_service_test.dart`
    - `dart analyze` for touched auth/test files.

### Batch F: Full Module Coverage Audit
- Done:
  - Expanded canonical permission registry and legacy-to-canonical mappings to
    cover all role matrix domains.
  - Added module coverage artifact:
    - `PERMISSION_MODULE_COVERAGE_MATRIX.md`
  - Verified role matrix legacy keys have 100% mapping coverage.

### Batch G: Canonical Runtime Key Cleanup
- Done:
  - Migrated active runtime capability checks in settings/items/purchases paths
    from legacy keys to canonical keys (e.g., `items.item.edit`,
    `purchases.bill.view`, `settings.branch.edit`).
  - Updated module-permission wrapper checks in users/roles screens to use
    canonical settings keys.
  - Preserved compatibility for navigation metadata paths where action-agnostic
    key design still intentionally uses central mapping.

### Batch H: Workflow Governance Prep (Status + Transition Core)
- Done:
  - Added centralized workflow status registry:
    - `lib/core/workflow/transaction_statuses.dart`
  - Added migration-safe status normalizer and UI label helper:
    - `lib/core/workflow/transaction_status_normalizer.dart`
  - Added centralized transition matrix:
    - `lib/core/workflow/transaction_status_transition_matrix.dart`
  - Added transition guard with capability-aware checks:
    - `lib/core/workflow/transaction_status_transition_guard.dart`
  - Added transition audit payload model:
    - `lib/core/workflow/transaction_status_audit_event.dart`
  - Added tests:
    - `test/core/workflow/transaction_status_transition_guard_test.dart`

### Batch I: Workflow Transition Enforcement (Inventory/Sales/Invoices)
- Done:
  - Enforced transition guard in inventory adjustment create/edit submit flow:
    - `lib/modules/inventory/adjustments/presentation/pages/inventory_adjustments_create.dart`
  - Enforced transition guard in inventory adjustment approve action:
    - `lib/modules/inventory/adjustments/presentation/pages/inventory_adjustments_list.dart`
  - Enforced transition guard in sales return create submit flow:
    - `lib/modules/sales/sales_return/presentation/pages/sales_return_create_page.dart`
  - Enforced transition guard in legacy sales return add flow:
    - `lib/modules/sales/sales_return/presentation/sales_return_add_page.dart`
  - Enforced transition guard in invoice void action:
    - `lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart`
  - Added audit-enriched status-transition logging (actor/reason/permission/time
    + `entity_context`/`branch_context`/`warehouse_context`) at these transition
    callsites via `AppLogger.info(...)`.

### Batch J: Transition Definition Governance Standardization (Tier 1)
- Done:
  - Added centralized transition-definition metadata registry:
    - `lib/core/workflow/transaction_transition_definitions.dart`
  - Added module status ownership governance map (core + module extensions):
    - `moduleStatusOwnership` in transition definitions file.
  - Upgraded transition guard to definition-aware permission and reason checks:
    - `lib/core/workflow/transaction_status_transition_guard.dart`
  - Enforced reason capture for invoice void flow (runtime prompt + guard check):
    - `lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart`
  - Wired explicit reason propagation into Tier-1 guarded writes:
    - inventory adjustments submit
    - sales return create/add submit
  - Replaced key Tier-1 UI status string logic with canonical normalization in
    inventory adjustments detail panel.
  - Added test coverage for reason-required transitions:
    - `test/core/workflow/transaction_status_transition_guard_test.dart`

### Batch K: Transfer + Purchase Lifecycle Governance (Tier 1)
- Done:
  - Expanded transition definitions for:
    - `inventory.transfer` (`draft -> initiated -> received`, cancel rules)
    - `purchases.bill` (`draft -> confirmed`, `confirmed -> voided`)
  - Expanded matrix support for transfer and purchase-bill lifecycle edges.
  - Added optional permission-enforcement switch in transition guard to support
    non-Riverpod callsites while preserving centralized legality/reason checks.
  - Enforced transfer-order receive workflow through transition guard before
    repository calls; added audit emission on initiate/receive transitions:
    - `lib/modules/inventory/transfer_orders/presentation/pages/inventory_transfer_orders_list.dart`
  - Added purchase-bill status mutation repository/provider methods:
    - `updateBillStatus(...)`, `approveBill(...)`, `voidBill(...)`
  - Enforced purchase-bill approve/void actions through transition guard with
    reason-required void prompt and audit emission:
    - `lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart`
  - Extended workflow tests for transfer lifecycle transitions.

### Batch L: Lock + Side-Effect + Threshold + SLA Governance Prep
- Done:
  - Added transition governance context model:
    - `lib/core/workflow/transition_governance_context.dart`
  - Extended `TransitionDefinition` metadata with:
    - `affectsInventory`
    - `affectsAccounting`
    - `createsLedgerEntries`
    - `requiresStockValidation`
    - `requiresLockCheck`
    - `approvalThresholdAmount`
    - `maxPendingDuration`
    - `staleAfterDuration`
  - Added SLA helper:
    - `isTransitionSlaBreached(...)`
  - Upgraded transition guard enforcement to include:
    - branch close lock blocking
    - financial period lock blocking (accounting-affecting transitions)
    - inventory freeze blocking (inventory-affecting transitions)
    - approval threshold blocking for direct `approved`/`confirmed` transitions
      without override
  - Added incremental backend transition-centralization contract scaffold:
    - `backend/src/modules/transaction-locking/transition-orchestrator.contract.ts`
  - Added tests for:
    - lock governance denial
    - approval threshold denial
    - SLA metadata evaluation

### Phase M: Operational Integration Layer
- Done:
  - Added lock-governance policy resolver:
    - `lib/core/workflow/transition_lock_policy.dart`
    - maps backend lock records to runtime governance context
  - Added approval queue foundation (no workflow engine):
    - `lib/core/workflow/approval_queue_engine.dart`
    - creates pending queue items with SLA/overdue evaluation
  - Added workflow observability foundation:
    - `lib/core/workflow/workflow_observability.dart`
    - computes pending/overdue/stale/blocked/high-risk metrics snapshot
  - Added transition telemetry emission points:
    - `lib/core/workflow/transition_telemetry.dart`
    - integrated into transition guard for allowed/blocked decisions when
      `transactionId` is provided
  - Added incremental backend contract expansion:
    - `backend/src/modules/transaction-locking/transition-orchestrator.contract.ts`
    - includes approval queue + telemetry contracts and side-effect/SLA fields
  - Added operational integration tests:
    - `test/core/workflow/workflow_operational_integration_test.dart`

### Phase N: Domain Event Convergence (In-Process)
- Done:
  - Added core domain-event contracts:
    - `lib/core/workflow/domain_events.dart`
    - `TransactionTransitionedEvent`
    - `ApprovalQueuedEvent`
    - `WorkflowBlockedEvent`
    - `InventoryFreezeViolationEvent`
  - Added in-process domain-event dispatcher:
    - `lib/core/workflow/domain_event_dispatcher.dart`
  - Added default domain-event handlers (audit/queue/notification-ready hooks):
    - `lib/core/workflow/domain_event_handlers.dart`
  - Wired domain-event emission into:
    - transition guard outcomes (allowed + blocked)
    - approval queue creation
    - inventory freeze lock-policy violations
  - Added deterministic convergence tests:
    - `test/core/workflow/domain_event_convergence_test.dart`

### Phase O: Operational Consistency
- Done:
  - Standardized domain-event dispatch contracts with envelope metadata:
    - `eventId`
    - `correlationId`
    - deterministic handler input shape
  - Added idempotency scaffolding:
    - `lib/core/workflow/domain_event_idempotency.dart`
    - `InMemoryDomainEventIdempotencyStore`
  - Upgraded dispatcher to idempotent delivery and envelope-based handlers:
    - `lib/core/workflow/domain_event_dispatcher.dart`
    - `lib/core/workflow/domain_event_envelope.dart`
  - Centralized workflow notification contracts/policies:
    - `lib/core/workflow/notification_policy.dart`
  - Standardized handler isolation and policy-driven notification hook path:
    - `lib/core/workflow/domain_event_handlers.dart`
  - Added governance dashboard aggregation service:
    - `lib/core/workflow/governance_dashboard_service.dart`
  - Added deterministic tests for:
    - dispatcher idempotency
    - dashboard aggregation
    - envelope-based event convergence compatibility
    - `test/core/workflow/operational_consistency_test.dart`

### Phase P: Operational Productization (Slice 1)
- Done:
  - Replaced settings automation placeholders with live governance surfaces:
    - `Workflow Governance Dashboard`
    - `Approval Workbench`
    - `Event Timeline & Debug Traces`
  - Added runtime governance store with in-memory aggregation from converged
    domain events:
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added settings automation providers for dashboard/timeline consumption:
    - `lib/modules/settings/automation/providers/workflow_governance_provider.dart`
  - Added productionized settings pages:
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart`
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_actions_page.dart`
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_logs_page.dart`
  - Updated automation routes from placeholder pages to operational pages:
    - `lib/modules/settings/automation/config/routes.dart`
  - Registered domain event handlers at app boot so runtime events populate
    the productized governance surfaces:
    - `lib/main.dart`

### Phase Q: Governance Operations (Slice 1 - Escalation)
- Done:
  - Added approval escalation engine for SLA-based escalation evaluation:
    - `lib/core/workflow/approval_escalation_engine.dart`
  - Added escalation domain event contract:
    - `ApprovalEscalatedEvent` in `lib/core/workflow/domain_events.dart`
  - Wired escalation event handling and notification-policy evaluation:
    - `lib/core/workflow/domain_event_handlers.dart`
    - `lib/core/workflow/notification_policy.dart`
  - Extended runtime governance store with escalation state:
    - escalation levels per queue item
    - escalated approvals counter
    - on-demand escalation evaluation trigger
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Extended governance dashboard snapshot with escalation metric:
    - `lib/core/workflow/governance_dashboard_service.dart`
  - Updated settings automation governance surfaces:
    - dashboard card `Escalated Approvals`
    - approval workbench action `Run Escalation Check`
    - per-row escalation level visibility
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart`
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_actions_page.dart`
  - Added escalation-focused tests:
    - `test/core/workflow/approval_escalation_engine_test.dart`
    - updated `test/core/workflow/operational_consistency_test.dart`

### Phase Q: Governance Operations (Slice 2 - Explainability + Supportability)
- Done:
  - Added runtime explainability APIs:
    - transaction trace extraction
    - latest blocked-reason lookup
    - branch governance health scoring
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added provider surface for branch governance health:
    - `lib/modules/settings/automation/providers/workflow_governance_provider.dart`
  - Upgraded Workflow Governance Dashboard page with:
    - branch governance health section (score signals)
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart`
  - Upgraded Approval Workbench page with:
    - per-row trace selection
    - inline approval trace viewer
    - inline blocked-reason explainability
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_actions_page.dart`
  - Upgraded Event Timeline page with:
    - transaction trace filters (`transactionType`, `transactionId`)
    - inline event-description rendering for operational diagnostics
    - inline `Why blocked` visibility
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_logs_page.dart`
  - Added/extended tests:
    - operational consistency test for runtime trace + blocked-reason APIs
    - `test/core/workflow/operational_consistency_test.dart`

### Phase Q: Governance Operations (Slice 3 - Operational Intelligence + Replay)
- Done:
  - Upgraded domain governance events with forensic metadata:
    - actor context (`actorId`, `actorName`)
    - permission context (`permissionUsed`)
    - rule explainability (`ruleCode`, explainability map)
    - escalation context (`sla`, `overdueHours`, branch/warehouse scope)
    - `lib/core/workflow/domain_events.dart`
  - Upgraded transition guard to emit structured explainability metadata:
    - rule codes (`reason_required`, `matrix_denied`, `permission_denied`, etc.)
    - required permission trail for blocked/allowed transitions
    - event actor propagation from runtime user context
    - `lib/core/workflow/transaction_status_transition_guard.dart`
  - Upgraded escalation engine to emit SLA/overdue context for replay/analytics:
    - `lib/core/workflow/approval_escalation_engine.dart`
  - Upgraded domain handlers to log explainability + escalation context fields:
    - `lib/core/workflow/domain_event_handlers.dart`
  - Upgraded workflow logs page into replay-style forensic viewer:
    - transaction replay header
    - actor/permission/rule/branch/SLA-age rendering
    - blocked rule trace visibility
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_logs_page.dart`

### Phase R: Governance Intelligence (Slice 1 - Branch Intelligence + Explainability Panel)
- Done:
  - Added branch-governance intelligence model and metrics contract:
    - `lib/core/workflow/governance_intelligence_model.dart`
  - Added runtime intelligence aggregation APIs:
    - `latestBlockedEvent(...)`
    - `branchGovernanceIntelligence(...)`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added provider surface for intelligence cards/lists:
    - `workflowBranchIntelligenceProvider`
    - `lib/modules/settings/automation/providers/workflow_governance_provider.dart`
  - Upgraded rules page with branch intelligence panel:
    - score + pending/overdue/blocked/escalation/SLA/latency metrics
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart`
  - Upgraded approval workbench explainability panel:
    - blocked rule code
    - failed permission key
    - actor context
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_actions_page.dart`
  - Added tests for branch intelligence metrics and blocked-event retrieval:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase R: Governance Intelligence (Slice 2 - Trends + Friction + Executive Surfaces)
- Done:
  - Added governance-insights contracts:
    - `GovernanceTrendSnapshot`
    - `PolicyFrictionMetric`
    - `GovernanceExecutiveSummary`
    - `lib/core/workflow/governance_insights_model.dart`
  - Added runtime intelligence APIs:
    - `governanceTrends(...)`
    - `topPolicyFriction(...)`
    - `executiveSummary()`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added provider surfaces for intelligence visualization:
    - `workflowTrendSnapshotProvider`
    - `workflowPolicyFrictionProvider`
    - `workflowExecutiveSummaryProvider`
    - `lib/modules/settings/automation/providers/workflow_governance_provider.dart`
  - Upgraded governance dashboard page with:
    - executive governance summary cards
    - 7-day vs prior-7-day trend deltas
    - policy friction analytics list (rule + permission + count)
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart`
  - Added test coverage for trend/friction/executive aggregations:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase S: Operational Governance Intelligence (Slice 1 - Heatmaps + Forecast + Support Summaries)
- Done:
  - Extended governance insights contracts with:
    - `GovernanceHeatmapCell`
    - `GovernanceForecastSignal`
    - `GovernanceIncidentSummary`
    - `lib/core/workflow/governance_insights_model.dart`
  - Added runtime cognition APIs:
    - `branchGovernanceHeatmap()`
    - `governanceForecastSignals(...)`
    - `incidentSummary(...)`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added provider surfaces:
    - `workflowHeatmapProvider`
    - `workflowForecastProvider`
    - `lib/modules/settings/automation/providers/workflow_governance_provider.dart`
  - Upgraded rules page with:
    - governance forecast signal cards
    - governance heatmap topology panel
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart`
  - Upgraded logs page with support acceleration summary:
    - incident events/blocked/escalation summary
    - latest rule + permission evidence
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_logs_page.dart`
  - Added tests for heatmap/forecast/incident summarization:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase S: Operational Governance Intelligence (Slice 2 - Optimization + Executive Usability)
- Done:
  - Extended governance insights contracts:
    - `BranchGovernanceRanking`
    - `lib/core/workflow/governance_insights_model.dart`
  - Added runtime optimization/support APIs:
    - `branchGovernanceRanking()`
    - `incidentRcaTopBlockers(...)`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added provider surface:
    - `workflowBranchRankingProvider`
    - `lib/modules/settings/automation/providers/workflow_governance_provider.dart`
  - Upgraded governance dashboard with executive branch ranking section:
    - branch score
    - risk band
    - SLA breach ratio
    - escalation density
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart`
  - Upgraded incident RCA surface in logs page:
    - top blocker rules + permissions + counts
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_logs_page.dart`
  - Extended tests for ranking + RCA blocker outputs:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase T: Governance Operations Platform (Slice 1 - Ops Center + Evidence Packs)
- Done:
  - Extended governance insight contracts:
    - `GovernanceOperationsCenterSnapshot`
    - `GovernanceEvidencePack`
    - `lib/core/workflow/governance_insights_model.dart`
  - Added runtime governance-operations APIs:
    - `operationsCenterSnapshot()`
    - `incidentEvidencePack(...)`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added provider surface:
    - `workflowOperationsCenterProvider`
    - `lib/modules/settings/automation/providers/workflow_governance_provider.dart`
  - Upgraded governance dashboard with operations-center command cards:
    - escalation hotspots
    - SLA breach hotspots
    - blocked hotspots
    - unstable branches
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart`
  - Upgraded logs page with evidence-pack panel for support acceleration:
    - transaction evidence lines
    - latest rule/permission/reason evidence
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_logs_page.dart`
  - Extended tests for ops-center and evidence-pack outputs:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase T: Governance Operations Platform (Slice 2 - Executive Usability + RCA Acceleration)
- Done:
  - Extended governance operations contracts:
    - `BranchGovernanceRanking`
    - `GovernanceOperationsCenterSnapshot`
    - `GovernanceEvidencePack`
    - `lib/core/workflow/governance_insights_model.dart`
  - Added runtime governance operations APIs:
    - `branchGovernanceRanking()`
    - `incidentRcaTopBlockers(...)`
    - `operationsCenterSnapshot()`
    - `incidentEvidencePack(...)`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added provider surfaces:
    - `workflowBranchRankingProvider`
    - `workflowOperationsCenterProvider`
    - `lib/modules/settings/automation/providers/workflow_governance_provider.dart`
  - Upgraded governance rules dashboard with:
    - governance operations center command cards
    - executive branch ranking section
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart`
  - Upgraded logs page with RCA acceleration panels:
    - RCA top blockers
    - evidence pack summary
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_logs_page.dart`
  - Extended tests for ranking/ops-center/evidence-pack outputs:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase U: Governance Operations Experience (Slice 1 - Live Command Console)
- Done:
  - Added runtime incident-alert extraction for ops console:
    - `incidentAlerts(...)`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added provider surface:
    - `workflowIncidentAlertsProvider`
    - `lib/modules/settings/automation/providers/workflow_governance_provider.dart`
  - Added dedicated governance command console page:
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_operations_center_page.dart`
    - includes:
      - hotspot command cards
      - high-risk branch ranking snapshot
      - policy friction top list
      - incident RCA alerts
  - Added deep-link route:
    - `settings/workflow-ops-center`
    - `lib/modules/settings/automation/config/routes.dart`
  - Extended tests for incident-alert output:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase U: Governance Operations Experience (Slice 2 - Investigation + Evidence Export)
- Done:
  - Added incident investigation runtime APIs:
    - `incidentReplayTimeline(...)`
    - `incidentEvidenceExportJson(...)`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added replay-step contract:
    - `GovernanceReplayStep`
    - `lib/core/workflow/governance_insights_model.dart`
  - Upgraded workflow logs page investigation experience:
    - replay timeline section
    - evidence export JSON block
    - evidence-pack + RCA chain remains integrated
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_logs_page.dart`
  - Extended tests for replay + evidence export JSON:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase V: Governance Experience Platform (Slice 1 - Investigation Workspace)
- Done:
  - Added dedicated investigation workspace page:
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_investigation_page.dart`
    - includes:
      - incident KPI summary (events/blocked/escalated)
      - RCA top blockers
      - replay timeline
      - evidence export JSON viewer
  - Added deep-link route:
    - `settings/workflow-investigation`
    - `lib/modules/settings/automation/config/routes.dart`
  - Reused existing runtime investigation primitives:
    - `incidentSummary(...)`
    - `incidentRcaTopBlockers(...)`
    - `incidentReplayTimeline(...)`
    - `incidentEvidenceExportJson(...)`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Extended tests for replay-step integrity:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase W: Governance Experience Optimization (Slice 1 - Mission Control + Export UX)
- Done:
  - Added unified governance mission-control page:
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_mission_control_page.dart`
    - includes:
      - live ops hotspot cards
      - trend delta cards
      - top unstable branch list
      - active RCA alert feed
      - quick navigation to ops center and investigation workspace
  - Added deep-link route:
    - `settings/workflow-mission-control`
    - `lib/modules/settings/automation/config/routes.dart`
  - Added one-click JSON evidence export action in investigation workspace:
    - copy-to-clipboard action with confirmation snackbar
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_investigation_page.dart`

### Phase X: Governance Operational Simplification (Slice 1 - Unified Nav + Incident Flow)
- Done:
  - Added unified governance navigation strip reusable:
    - `lib/modules/settings/automation/presentation/widgets/settings_workflow_nav_strip.dart`
    - links Mission / Ops Center / Investigation / Rules / Actions / Logs
  - Added nav strip to:
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_mission_control_page.dart`
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_investigation_page.dart`
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart`
  - Added incident-driven mission-control flow:
    - RCA alert row click deep-links to investigation with prefilled context
  - Added investigation route query-parameter prefill:
    - `settings/workflow-investigation?type=...&id=...`
    - wired in `lib/modules/settings/automation/config/routes.dart`

### Phase Y: Governance Operational UX (Slice 1 - Incident Workflow Continuity)
- Done:
  - Added incident workflow continuity runtime state:
    - last investigation context memory (`transactionType`, `transactionId`)
    - resolved-incident tracking
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added investigation workflow controls:
    - context-aware `Investigate` action persistence
    - human-readable RCA summary panel
    - `Mark Resolved` operational action
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_investigation_page.dart`
  - Added incident-alert filtering for resolved incidents:
    - `incidentAlerts(...)` excludes resolved keys
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Extended tests for incident resolve lifecycle behavior:
    - resolved incident removed from alert feed
    - `test/core/workflow/operational_consistency_test.dart`

### Phase Z: Governance Operational Maturity (Slice 1 - Incident Flow + Session Memory)
- Done:
  - Extended runtime lifecycle state with incident archival and investigation view-state memory:
    - `archiveIncident(...)`
    - `isIncidentArchived(...)`
    - `setLastInvestigationViewState(...)`
    - `lastInvestigationReplayFilter`
    - `lastInvestigationOnlyCritical`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Upgraded investigation workspace lifecycle UX:
    - replay filter input
    - critical-only replay toggle (blocked/escalated)
    - archived KPI visibility
    - archive action (enabled post-resolve)
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_investigation_page.dart`
  - Extended regression coverage for archive lifecycle + view-state continuity:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase Z: Governance Operational Maturity (Slice 2 - Incident Status Pipeline + Lifecycle Readability)
- Done:
  - Added typed incident status pipeline contract:
    - `GovernanceIncidentStatus` (`active|investigating|escalated|resolved|archived`)
    - incident status label extension
    - `lib/core/workflow/governance_insights_model.dart`
  - Added lifecycle event primitive:
    - `GovernanceIncidentStatusChangedEvent`
    - `lib/core/workflow/domain_events.dart`
  - Added runtime lifecycle APIs and pipeline aggregation:
    - `incidentStatusFor(...)`
    - `setIncidentStatus(...)`
    - `startInvestigating(...)`
    - `markIncidentEscalated(...)`
    - `restoreIncidentToActive(...)`
    - `incidentStatusPipelineCounts()`
    - status included in `incidentSummary(...)` and evidence export JSON
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added provider surface:
    - `workflowIncidentStatusPipelineProvider`
    - `lib/modules/settings/automation/providers/workflow_governance_provider.dart`
  - Upgraded lifecycle readability in governance UI:
    - Incident status shown in Mission Control and Ops Center alert rows
    - Incident Status Pipeline cards in Ops Center
    - investigation workspace starts incident lifecycle as `Investigating`
    - logs incident summary now shows status

### Phase Z: Governance Operational Maturity (Slice 3 - Ownership + Snapshots + Handoffs)
- Done:
  - Added governance collaboration contracts:
    - `GovernanceIncidentAssignment`
    - `GovernanceInvestigationSnapshot`
    - `lib/core/workflow/governance_insights_model.dart`
  - Added runtime accountability/collaboration APIs:
    - `setIncidentAssignment(...)` / `incidentAssignment(...)`
    - `addIncidentNote(...)` / `incidentNotes(...)`
    - `saveInvestigationSnapshot(...)` / `investigationSnapshots(...)`
    - `restoreIncidentToActive(...)` (reopen archived investigation)
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Upgraded investigation workspace with operational refinement UX:
    - incident ownership section (operator/branch lead/escalation owner/assignee)
    - investigation snapshots save/list
    - support handoff notes add/list
    - archived-incident reopen action
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_investigation_page.dart`
  - Extended test coverage for assignment/notes/snapshots/reopen lifecycle:
    - `test/core/workflow/operational_consistency_test.dart`

### Phase Z: Governance Operational Maturity (Slice 4 - Usability + Handoff Acceleration)
- Done:
  - Added lifecycle status filtering support in runtime alert API:
    - `incidentAlerts(statuses: ...)`
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added one-click handoff bundle export contract:
    - `incidentHandoffBundleJson(...)` (status + assignment + notes + snapshots + evidence)
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added assignment visibility in command surfaces:
    - Mission Control alert rows now show investigation owner
    - Ops Center alert rows now show investigation owner
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_mission_control_page.dart`
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_operations_center_page.dart`
  - Added lifecycle status filters across governance surfaces:
    - Mission Control status chips
    - Ops Center status chips
    - Logs status selector for transaction-trace readability
  - Added investigation handoff acceleration UX:
    - `Copy Handoff Bundle` action
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_investigation_page.dart`
  - Added explicit lifecycle transition timeline detail rendering:
    - `GovernanceIncidentStatusChangedEvent` descriptions now visible in logs/replay pathways
    - fixed status transition emission ordering for resolve/archive to preserve lifecycle events.
  - Extended tests:
    - handoff bundle export
    - lifecycle transition event presence
    - `test/core/workflow/operational_consistency_test.dart`

### Phase Z: Governance Operational Maturity (Slice 5 - Operator Speed Refinement)
- Done:
- Added status-filter preset memory in runtime store:
- mission preset (`saveMissionStatusPreset`)
    - ops preset (`saveOpsStatusPreset`)
    - logs preset (`saveLogsStatusPreset`)
    - `lib/core/workflow/workflow_runtime_store.dart`
  - Added preset UX actions:
    - Mission Control: Save Preset / Load Preset for lifecycle status chips
    - Ops Center: Save Preset / Load Preset for lifecycle status chips
    - Logs: lifecycle status preset persistence + load action
  - Added quick ownership acceleration:
    - Investigation: `Assign To Me` action for assignee shortcut
    - `lib/modules/settings/automation/presentation/pages/settings_workflow_investigation_page.dart`
  - Added handoff bundle preview workflow:
    - modal preview before copy for `Copy Handoff Bundle`
- Added replay jump markers in investigation timeline controls:
- Jump Blocked / Jump Escalated / Jump Status
- Added runtime + test updates for preset/filtered alert compatibility.

### Phase Z: Governance Operational Maturity (Slice 6 - Usability Polish)
- Done:
- Unified lifecycle status filter/preset UX wording between Mission Control and
Ops Center:
  - `Save Current Preset`
  - `Apply Saved Preset`
- Reduced duplicate controls by extracting shared module-level widget:
  - `lib/modules/settings/automation/presentation/widgets/settings_workflow_status_preset_controls.dart`
- Added compact preset-state indicator in both Mission/Ops:
  - `Current preset active • <summary>`
  - `Custom filter • preset <summary>`
- Kept runtime contracts unchanged:
  - no `workflow_runtime_store` API changes
  - no domain-event contract changes

### Phase Z: Governance Operational Maturity (Slice 6B - Collaboration Continuity)
- Done:
- Added watcher-aware incident assignment state:
  - `GovernanceIncidentAssignment.watcherList`
  - persisted via `setIncidentAssignment(... watcherList: ...)`
- Added ownership-transfer continuity trail:
  - `incidentAssignmentHistory(...)`
  - transfer reason capture on assignee handoff
- Added replay-context restoration from saved snapshots:
  - `applyInvestigationSnapshot(...)` restores:
    - transaction context
    - replay filter
    - critical-only toggle
- Upgraded investigation workspace ergonomics:
  - watcher input
  - transfer owner controls (assignee + reason)
  - ownership chain preview
  - per-snapshot apply actions
- Extended handoff payload:
  - assignment watchers
  - assignment history
- Verification:
  - `dart analyze` on touched workflow/runtime/ui/test files
  - `flutter test test/core/workflow/operational_consistency_test.dart`
