import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/settings/automation/providers/workflow_governance_provider.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/widgets/settings_workflow_nav_strip.dart';

class SettingsWorkflowRulesPage extends ConsumerWidget {
  const SettingsWorkflowRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(workflowDashboardSnapshotProvider);
    final branchHealth = ref.watch(workflowBranchHealthProvider);
    final branchIntel = ref.watch(workflowBranchIntelligenceProvider);
    final trends = ref.watch(workflowTrendSnapshotProvider);
    final friction = ref.watch(workflowPolicyFrictionProvider);
    final exec = ref.watch(workflowExecutiveSummaryProvider);
    final heatmap = ref.watch(workflowHeatmapProvider);
    final forecast = ref.watch(workflowForecastProvider);
    final ops = ref.watch(workflowOperationsCenterProvider);
    final ranking = ref.watch(workflowBranchRankingProvider);
    final cards = <_MetricCardData>[
      _MetricCardData('Pending Approvals', snapshot.pendingApprovals),
      _MetricCardData('Overdue Approvals', snapshot.overdueApprovals),
      _MetricCardData('Stale Transitions', snapshot.staleTransitions),
      _MetricCardData('Blocked Transitions', snapshot.blockedTransitions),
      _MetricCardData('High Risk Signals', snapshot.highRiskTransitions),
      _MetricCardData('Freeze Violations', snapshot.freezeViolations),
      _MetricCardData('Escalated Approvals', snapshot.escalatedApprovals),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workflow Governance Dashboard',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Operational metrics from runtime governance events and queues.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          const SettingsWorkflowNavStrip(),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map(_MetricCard.new).toList(growable: false),
          ),
          const SizedBox(height: 20),
          Text(
            'Executive Governance Summary',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricCard(_MetricCardData('Branches', exec.totalBranches)),
              _MetricCard(_MetricCardData('Unhealthy', exec.unhealthyBranches)),
              _MetricCard(_MetricCardData('Critical', exec.criticalBranches)),
              _MetricCard(_MetricCardData('Total Blocked', exec.totalBlocked)),
              _MetricCard(
                _MetricCardData('Total Escalations', exec.totalEscalations),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Governance Trends (Last 7 Days vs Previous 7 Days)',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricCard(
                _MetricCardData(
                  'Blocked Δ',
                  trends.currentBlocked - trends.previousBlocked,
                ),
              ),
              _MetricCard(
                _MetricCardData(
                  'Escalations Δ',
                  trends.currentEscalations - trends.previousEscalations,
                ),
              ),
              _MetricCard(
                _MetricCardData(
                  'Overdue Δ',
                  trends.currentOverdueApprovals -
                      trends.previousOverdueApprovals,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Policy Friction Analytics',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (friction.isEmpty)
            const Text(
              'No policy friction signals yet.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            ...friction.map(
              (x) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${x.ruleCode} • ${x.permissionKey} • ${x.count}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Governance Forecast Signals',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: forecast
                .map(
                  (f) => _MetricCard(
                    _MetricCardData(
                      '${f.metric} (${f.direction})',
                      f.currentDelta - f.previousDelta,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          Text(
            'Governance Heatmap',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (heatmap.isEmpty)
            const Text(
              'No heatmap signals yet.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: heatmap
                  .map(
                    (h) => Container(
                      width: 210,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: h.severity == 'critical'
                            ? const Color(0xFFFFEAEA)
                            : (h.severity == 'warning'
                                  ? const Color(0xFFFFF5E6)
                                  : const Color(0xFFE8F5E9)),
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'B ${h.branchId} • ${h.metric}\n'
                        '${h.value.toStringAsFixed(2)} • ${h.severity}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 20),
          Text(
            'Governance Operations Center',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricCard(
                _MetricCardData('Esc Hotspots', ops.escalationHotspots),
              ),
              _MetricCard(
                _MetricCardData('SLA Hotspots', ops.slaBreachHotspots),
              ),
              _MetricCard(
                _MetricCardData('Blocked Hotspots', ops.blockedHotspots),
              ),
              _MetricCard(
                _MetricCardData('Unstable Branches', ops.unstableBranches),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Executive Branch Ranking',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (ranking.isEmpty)
            const Text(
              'No ranking data yet.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            ...ranking.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'B ${r.branchId} • score ${r.score} • ${r.riskBand} • '
                  'sla ${(r.slaBreachRatio * 100).toStringAsFixed(0)}% • '
                  'esc ${r.escalationDensity.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Branch Governance Health',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          branchHealth.isEmpty
              ? const Text(
                  'No branch signals captured yet.',
                  style: TextStyle(color: AppTheme.textSecondary),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: branchHealth.entries
                      .map(
                        (e) => _MetricCard(
                          _MetricCardData('Branch ${e.key}', e.value),
                        ),
                      )
                      .toList(growable: false),
                ),
          const SizedBox(height: 20),
          Text(
            'Branch Governance Intelligence',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (branchIntel.isEmpty)
            const Text(
              'No branch intelligence signals yet.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: branchIntel.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.borderColor),
                itemBuilder: (context, index) {
                  final x = branchIntel[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      'Branch ${x.branchId} • Score ${x.governanceHealthScore}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'pending ${x.pendingApprovals} • overdue ${x.overdueApprovals} • '
                      'blocked ${x.blockedTransitions} • escalations ${x.escalations} • '
                      'sla ${(x.slaBreachRatio * 100).toStringAsFixed(0)}% • '
                      'lat ${x.approvalLatencyHours.toStringAsFixed(1)}h',
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

class _MetricCardData {
  final String label;
  final int value;

  const _MetricCardData(this.label, this.value);
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;

  const _MetricCard(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.value.toString(),
            style: const TextStyle(
              fontSize: 24,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
