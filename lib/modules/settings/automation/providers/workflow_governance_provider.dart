import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/workflow/domain_event_envelope.dart';
import 'package:zerpai_erp/core/workflow/governance_intelligence_model.dart';
import 'package:zerpai_erp/core/workflow/governance_insights_model.dart';
import 'package:zerpai_erp/core/workflow/governance_dashboard_service.dart';
import 'package:zerpai_erp/core/workflow/workflow_runtime_store.dart';

final workflowRuntimeStoreProvider = ChangeNotifierProvider<WorkflowRuntimeStore>(
  (ref) => WorkflowRuntimeStore.instance,
);

final workflowDashboardSnapshotProvider =
    Provider<GovernanceDashboardSnapshot>((ref) {
      final store = ref.watch(workflowRuntimeStoreProvider);
      return store.dashboardSnapshot();
    });

final workflowEventTimelineProvider = Provider<List<DomainEventEnvelope>>((ref) {
  final store = ref.watch(workflowRuntimeStoreProvider);
  final events = store.events;
  return events.reversed.toList(growable: false);
});

final workflowBranchHealthProvider = Provider<Map<String, int>>((ref) {
  final store = ref.watch(workflowRuntimeStoreProvider);
  return store.branchGovernanceHealthScores();
});

final workflowBranchIntelligenceProvider =
    Provider<List<BranchGovernanceIntelligence>>((ref) {
      final store = ref.watch(workflowRuntimeStoreProvider);
      return store.branchGovernanceIntelligence();
    });

final workflowTrendSnapshotProvider = Provider<GovernanceTrendSnapshot>((ref) {
  final store = ref.watch(workflowRuntimeStoreProvider);
  return store.governanceTrends();
});

final workflowPolicyFrictionProvider = Provider<List<PolicyFrictionMetric>>((
  ref,
) {
  final store = ref.watch(workflowRuntimeStoreProvider);
  return store.topPolicyFriction();
});

final workflowExecutiveSummaryProvider = Provider<GovernanceExecutiveSummary>((
  ref,
) {
  final store = ref.watch(workflowRuntimeStoreProvider);
  return store.executiveSummary();
});

final workflowHeatmapProvider = Provider<List<GovernanceHeatmapCell>>((ref) {
  final store = ref.watch(workflowRuntimeStoreProvider);
  return store.branchGovernanceHeatmap();
});

final workflowForecastProvider = Provider<List<GovernanceForecastSignal>>((ref) {
  final store = ref.watch(workflowRuntimeStoreProvider);
  return store.governanceForecastSignals();
});

final workflowBranchRankingProvider = Provider<List<BranchGovernanceRanking>>((
  ref,
) {
  final store = ref.watch(workflowRuntimeStoreProvider);
  return store.branchGovernanceRanking();
});

final workflowOperationsCenterProvider =
    Provider<GovernanceOperationsCenterSnapshot>((ref) {
      final store = ref.watch(workflowRuntimeStoreProvider);
      return store.operationsCenterSnapshot();
    });

final workflowIncidentAlertsProvider = Provider<List<GovernanceIncidentSummary>>((
  ref,
) {
  final store = ref.watch(workflowRuntimeStoreProvider);
  return store.incidentAlerts();
});

final workflowIncidentStatusPipelineProvider =
    Provider<Map<GovernanceIncidentStatus, int>>((ref) {
      final store = ref.watch(workflowRuntimeStoreProvider);
      return store.incidentStatusPipelineCounts();
    });
