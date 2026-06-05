import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/workflow/governance_insights_model.dart';
import 'package:zerpai_erp/core/workflow/workflow_runtime_store.dart';
import 'package:zerpai_erp/modules/settings/automation/providers/workflow_governance_provider.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/widgets/settings_workflow_nav_strip.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/widgets/settings_workflow_status_preset_controls.dart';

class SettingsWorkflowMissionControlPage extends ConsumerStatefulWidget {
  const SettingsWorkflowMissionControlPage({super.key});

  @override
  ConsumerState<SettingsWorkflowMissionControlPage> createState() =>
      _SettingsWorkflowMissionControlPageState();
}

class _SettingsWorkflowMissionControlPageState
    extends ConsumerState<SettingsWorkflowMissionControlPage> {
  late Set<GovernanceIncidentStatus> _statuses;

  @override
  void initState() {
    super.initState();
    _statuses = WorkflowRuntimeStore.instance.missionStatusPreset;
  }

  @override
  Widget build(BuildContext context) {
    final ops = ref.watch(workflowOperationsCenterProvider);
    final trends = ref.watch(workflowTrendSnapshotProvider);
    final ranking = ref.watch(workflowBranchRankingProvider);
    final store = ref.watch(workflowRuntimeStoreProvider);
    final alerts = store.incidentAlerts(statuses: _statuses);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Governance Mission Control',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unified live governance operations and investigation entrypoint.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          const SettingsWorkflowNavStrip(),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => context.go('/settings/workflow-ops-center'),
                child: const Text('Open Ops Center'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => context.go('/settings/workflow-investigation'),
                child: const Text('Open Investigation'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _kpi('Esc Hotspots', ops.escalationHotspots),
              _kpi('SLA Hotspots', ops.slaBreachHotspots),
              _kpi('Blocked Hotspots', ops.blockedHotspots),
              _kpi('Unstable Branches', ops.unstableBranches),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _kpi(
                'Blocked Δ',
                trends.currentBlocked - trends.previousBlocked,
              ),
              _kpi(
                'Escalations Δ',
                trends.currentEscalations - trends.previousEscalations,
              ),
              _kpi(
                'Overdue Δ',
                trends.currentOverdueApprovals - trends.previousOverdueApprovals,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SettingsWorkflowStatusPresetControls(
            title: 'Lifecycle Status Filter',
            statuses: _statuses,
            savedPreset: store.missionStatusPreset,
            onToggleStatus: (status) {
              setState(() {
                if (_statuses.contains(status) && _statuses.length > 1) {
                  _statuses.remove(status);
                } else {
                  _statuses.add(status);
                }
              });
            },
            onSavePreset: () {
              store.saveMissionStatusPreset(_statuses);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preset saved for Mission Control')),
              );
            },
            onApplySavedPreset: () {
              setState(() {
                _statuses = store.missionStatusPreset;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved preset applied')),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Top Unstable Branches',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...ranking.take(5).map(
            (r) => Text(
              'B ${r.branchId} • ${r.riskBand} • score ${r.score} • '
              'sla ${(r.slaBreachRatio * 100).toStringAsFixed(0)}% • '
              'esc ${r.escalationDensity.toStringAsFixed(2)}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Active RCA Alerts',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: alerts.isEmpty
                ? const Text(
                    'No active alerts.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                : ListView.separated(
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderColor),
                    itemBuilder: (context, index) {
                      final a = alerts[index];
                      return ListTile(
                        onTap: () => context.go(
                          '/settings/workflow-investigation'
                          '?type=${Uri.encodeComponent(a.transactionType)}'
                          '&id=${Uri.encodeComponent(a.transactionId)}',
                        ),
                        dense: true,
                        title: Text(
                          '${a.transactionType} • ${a.transactionId}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'blocked ${a.blockedCount} • escalated ${a.escalationCount} • '
                          'status ${a.status.label} • '
                          'owner ${store.incidentAssignment(transactionType: a.transactionType, transactionId: a.transactionId)?.investigationAssignee ?? '-'} • '
                          'rule ${a.latestRuleCode ?? '-'}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, int value) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
