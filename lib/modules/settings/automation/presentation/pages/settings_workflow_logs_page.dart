import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/workflow/domain_events.dart';
import 'package:zerpai_erp/core/workflow/governance_insights_model.dart';
import 'package:zerpai_erp/core/workflow/workflow_runtime_store.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/settings/automation/providers/workflow_governance_provider.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class SettingsWorkflowLogsPage extends ConsumerStatefulWidget {
  const SettingsWorkflowLogsPage({super.key});

  @override
  ConsumerState<SettingsWorkflowLogsPage> createState() =>
      _SettingsWorkflowLogsPageState();
}

class _SettingsWorkflowLogsPageState
    extends ConsumerState<SettingsWorkflowLogsPage> {
  final _transactionTypeController = TextEditingController();
  final _transactionIdController = TextEditingController();
  late GovernanceIncidentStatus _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = WorkflowRuntimeStore.instance.logsStatusPreset;
  }

  @override
  void dispose() {
    _transactionTypeController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(workflowRuntimeStoreProvider);
    final timeline = ref.watch(workflowEventTimelineProvider);
    final type = _transactionTypeController.text.trim();
    final id = _transactionIdController.text.trim();
    final filtered = type.isNotEmpty && id.isNotEmpty
        ? store
              .traceForTransaction(transactionType: type, transactionId: id)
              .reversed
              .toList(growable: false)
        : timeline;
    final blockedReason = type.isNotEmpty && id.isNotEmpty
        ? store.latestBlockedReason(transactionType: type, transactionId: id)
        : null;
    final incidentSummary = type.isNotEmpty && id.isNotEmpty
        ? store.incidentSummary(transactionType: type, transactionId: id)
        : null;
    final statusPass =
        incidentSummary == null || incidentSummary.status == _statusFilter;
    final evidencePack = type.isNotEmpty && id.isNotEmpty
        ? store.incidentEvidencePack(transactionType: type, transactionId: id)
        : null;
    final rca = type.isNotEmpty && id.isNotEmpty
        ? store.incidentRcaTopBlockers(transactionType: type, transactionId: id)
        : const [];
    final replay = type.isNotEmpty && id.isNotEmpty
        ? store.incidentReplayTimeline(transactionType: type, transactionId: id)
        : const [];
    final evidenceJson = type.isNotEmpty && id.isNotEmpty
        ? store.incidentEvidenceExportJson(
            transactionType: type,
            transactionId: id,
          )
        : '';
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm:ss a');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Timeline & Debug Traces',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Idempotent event stream with correlation and decision trace details.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _transactionTypeController,
                  decoration: const InputDecoration(
                    hintText: 'transactionType',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _transactionIdController,
                  decoration: const InputDecoration(
                    hintText: 'transactionId',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Trace'),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 170,
                child: FormDropdown<GovernanceIncidentStatus>(
                  value: _statusFilter,
                  items: GovernanceIncidentStatus.values,
                  hint: 'Status',
                  displayStringForValue: (s) => s.label,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _statusFilter = value);
                    store.saveLogsStatusPreset(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _statusFilter = store.logsStatusPreset;
                  });
                },
                child: const Text('Load Preset'),
              ),
            ],
          ),
          if (blockedReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Why blocked: $blockedReason',
              style: const TextStyle(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (type.isNotEmpty && id.isNotEmpty)
            Text(
              'Replay View: ${filtered.length} lifecycle events',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (!statusPass)
            Text(
              'Filtered out by status: ${_statusFilter.label}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          if (incidentSummary != null && statusPass) ...[
            const SizedBox(height: 6),
            Text(
              'Incident: events ${incidentSummary.totalEvents} • '
              'blocked ${incidentSummary.blockedCount} • '
              'escalated ${incidentSummary.escalationCount} • '
              'status ${incidentSummary.status.label}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (incidentSummary.latestRuleCode != null)
              Text(
                'Last rule: ${incidentSummary.latestRuleCode} • '
                'perm: ${incidentSummary.latestPermission ?? '-'}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            if (rca.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                'RCA Top Blockers:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ...rca.map(
                (x) => Text(
                  '${x.ruleCode} • ${x.permissionKey} • ${x.count}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
            if (evidencePack != null) ...[
              const SizedBox(height: 6),
              const Text(
                'Evidence Pack:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'tx=${evidencePack.transactionType}/${evidencePack.transactionId} '
                'events=${evidencePack.totalEvents}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                'rule=${evidencePack.latestRuleCode ?? '-'} '
                'perm=${evidencePack.latestPermission ?? '-'}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              if (evidencePack.latestReason != null)
                Text(
                  'reason=${evidencePack.latestReason}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              if (replay.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Text(
                  'Replay Timeline:',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ...replay
                    .take(8)
                    .map(
                      (r) => Text(
                        '${dateFmt.format(r.at)} • ${r.eventType} • ${r.detail}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
              ],
              const SizedBox(height: 6),
              const Text(
                'Evidence Export (JSON):',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SelectableText(
                evidenceJson,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
          if (type.isNotEmpty && id.isNotEmpty && statusPass)
            const SizedBox(height: 8),
          Expanded(
            child: !statusPass
                ? const Center(
                    child: Text(
                      'No events for selected lifecycle status.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No workflow events emitted yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderColor),
                    itemBuilder: (context, index) {
                      final envelope = filtered[index];
                      final event = envelope.event;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        title: Text(
                          event.eventType,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'eventId: ${envelope.eventId}\n'
                          'correlationId: ${envelope.correlationId}\n'
                          'at: ${dateFmt.format(event.occurredAt)}\n'
                          '${_describe(event)}',
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

String _describe(DomainEvent event) {
  if (event is TransactionTransitionedEvent) {
    return '${event.transactionType}/${event.transactionId} '
        '${event.fromStatus} -> ${event.toStatus}'
        ' | actor=${event.actorName ?? event.actorId ?? 'system'}'
        ' | perm=${event.permissionUsed ?? '-'}'
        ' | branch=${event.branchId ?? '-'}';
  }
  if (event is WorkflowBlockedEvent) {
    return '${event.transactionType}/${event.transactionId} blocked: ${event.reason}'
        ' | rule=${event.ruleCode ?? '-'}'
        ' | actor=${event.actorName ?? event.actorId ?? 'system'}'
        ' | perm=${event.permissionUsed ?? '-'}';
  }
  if (event is ApprovalQueuedEvent) {
    final age = DateTime.now().difference(event.pendingSince).inHours;
    return '${event.transactionType}/${event.transactionId} queue: ${event.queueId}'
        ' | age=${age}h'
        ' | sla=${event.sla?.inHours ?? '-'}h';
  }
  if (event is ApprovalEscalatedEvent) {
    return '${event.transactionType}/${event.transactionId} escalated L${event.level}: ${event.reason}'
        ' | overdue=${event.overdueHours ?? '-'}h'
        ' | branch=${event.branchId ?? '-'}';
  }
  if (event is InventoryFreezeViolationEvent) {
    return '${event.transactionType}/${event.transactionId} freeze violation: ${event.reason}';
  }
  if (event is GovernanceIncidentStatusChangedEvent) {
    return '${event.transactionType}/${event.transactionId} status: '
        '${event.fromStatus} -> ${event.toStatus}'
        ' | reason=${event.reason}';
  }
  return event.eventType;
}
