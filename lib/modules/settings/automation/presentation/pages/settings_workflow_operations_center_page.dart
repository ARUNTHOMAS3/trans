import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/workflow/governance_insights_model.dart';
import 'package:zerpai_erp/core/workflow/workflow_runtime_store.dart';
import 'package:zerpai_erp/modules/settings/automation/providers/workflow_governance_provider.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/widgets/settings_workflow_status_preset_controls.dart';

class SettingsWorkflowOperationsCenterPage extends ConsumerStatefulWidget {
  const SettingsWorkflowOperationsCenterPage({super.key});

  @override
  ConsumerState<SettingsWorkflowOperationsCenterPage> createState() =>
      _SettingsWorkflowOperationsCenterPageState();
}

class _SettingsWorkflowOperationsCenterPageState
    extends ConsumerState<SettingsWorkflowOperationsCenterPage> {
  late Set<GovernanceIncidentStatus> _statuses;

  @override
  void initState() {
    super.initState();
    _statuses = WorkflowRuntimeStore.instance.opsStatusPreset;
  }

  @override
  Widget build(BuildContext context) {
    final ops = ref.watch(workflowOperationsCenterProvider);
    final ranking = ref.watch(workflowBranchRankingProvider);
    final friction = ref.watch(workflowPolicyFrictionProvider);
    final store = ref.watch(workflowRuntimeStoreProvider);
    final alerts = store.incidentAlerts(statuses: _statuses);
    final statusPipeline = ref.watch(workflowIncidentStatusPipelineProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Governance Command Console',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unified operations center for hotspots, branch risk, and incident alerts.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniCard('Esc Hotspots', ops.escalationHotspots),
              _MiniCard('SLA Hotspots', ops.slaBreachHotspots),
              _MiniCard('Blocked Hotspots', ops.blockedHotspots),
              _MiniCard('Unstable Branches', ops.unstableBranches),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Incident Status Pipeline',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: GovernanceIncidentStatus.values
                .map(
                  (status) =>
                      _MiniCard(status.label, statusPipeline[status] ?? 0),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          SettingsWorkflowStatusPresetControls(
            title: 'Lifecycle Status Filter',
            statuses: _statuses,
            savedPreset: store.opsStatusPreset,
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
              store.saveOpsStatusPreset(_statuses);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preset saved for Ops Center')),
              );
            },
            onApplySavedPreset: () {
              setState(() {
                _statuses = store.opsStatusPreset;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved preset applied')),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'High-Risk Branch Ranking',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...ranking
              .take(5)
              .map(
                (r) => Text(
                  'B ${r.branchId} • ${r.riskBand} • score ${r.score} • '
                  'sla ${(r.slaBreachRatio * 100).toStringAsFixed(0)}% • '
                  'esc ${r.escalationDensity.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
          const SizedBox(height: 16),
          Text(
            'Policy Friction Top 5',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...friction.map(
            (x) => Text(
              '${x.ruleCode} • ${x.permissionKey} • ${x.count}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Incident RCA Alerts',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (alerts.isEmpty)
            const Text(
              'No incident alerts.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: alerts.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.borderColor),
                itemBuilder: (context, index) {
                  final a = alerts[index];
                  return ListTile(
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
}

class _MiniCard extends StatelessWidget {
  final String label;
  final int value;

  const _MiniCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
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
