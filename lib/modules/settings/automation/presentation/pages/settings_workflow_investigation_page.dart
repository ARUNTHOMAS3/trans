import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/workflow/governance_insights_model.dart';
import 'package:zerpai_erp/core/workflow/workflow_runtime_store.dart';
import 'package:zerpai_erp/modules/settings/automation/providers/workflow_governance_provider.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/widgets/settings_workflow_nav_strip.dart';

class SettingsWorkflowInvestigationPage extends ConsumerStatefulWidget {
  final String? initialTransactionType;
  final String? initialTransactionId;

  const SettingsWorkflowInvestigationPage({
    super.key,
    this.initialTransactionType,
    this.initialTransactionId,
  });

  @override
  ConsumerState<SettingsWorkflowInvestigationPage> createState() =>
      _SettingsWorkflowInvestigationPageState();
}

class _SettingsWorkflowInvestigationPageState
    extends ConsumerState<SettingsWorkflowInvestigationPage> {
  final _typeController = TextEditingController();
  final _idController = TextEditingController();
  final _replayFilterController = TextEditingController();
  final _assignedOperatorController = TextEditingController();
  final _branchLeadController = TextEditingController();
  final _escalationOwnerController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _watchersController = TextEditingController();
  final _transferReasonController = TextEditingController();
  final _transferAssigneeController = TextEditingController();
  final _noteController = TextEditingController();
  final _snapshotLabelController = TextEditingController();
  bool _onlyCriticalReplay = false;

  @override
  void initState() {
    super.initState();
    final store = WorkflowRuntimeStore.instance;
    _typeController.text =
        widget.initialTransactionType ?? store.lastInvestigationType ?? '';
    _idController.text =
        widget.initialTransactionId ?? store.lastInvestigationId ?? '';
    _replayFilterController.text = store.lastInvestigationReplayFilter;
    _onlyCriticalReplay = store.lastInvestigationOnlyCritical;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _idController.dispose();
    _replayFilterController.dispose();
    _assignedOperatorController.dispose();
    _branchLeadController.dispose();
    _escalationOwnerController.dispose();
    _assigneeController.dispose();
    _watchersController.dispose();
    _transferReasonController.dispose();
    _transferAssigneeController.dispose();
    _noteController.dispose();
    _snapshotLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(workflowRuntimeStoreProvider);
    final type = _typeController.text.trim();
    final id = _idController.text.trim();
    final hasQuery = type.isNotEmpty && id.isNotEmpty;
    final summary = hasQuery
        ? store.incidentSummary(transactionType: type, transactionId: id)
        : null;
    final resolved = hasQuery
        ? store.isIncidentResolved(transactionType: type, transactionId: id)
        : false;
    final archived = hasQuery
        ? store.isIncidentArchived(transactionType: type, transactionId: id)
        : false;
    final replayFilter = _replayFilterController.text.trim().toLowerCase();
    final assignment = hasQuery
        ? store.incidentAssignment(transactionType: type, transactionId: id)
        : null;
    final notes = hasQuery
        ? store.incidentNotes(transactionType: type, transactionId: id)
        : const <String>[];
    final assignmentHistory = hasQuery
        ? store.incidentAssignmentHistory(
            transactionType: type,
            transactionId: id,
          )
        : const <String>[];
    final snapshots = hasQuery
        ? store.investigationSnapshots(transactionType: type, transactionId: id)
        : const <GovernanceInvestigationSnapshot>[];
    final replay = hasQuery
        ? store.incidentReplayTimeline(transactionType: type, transactionId: id)
        : const [];
    final replayVisible = replay
        .where((r) {
          final detail = '${r.eventType} ${r.detail}'.toLowerCase();
          final isCritical =
              r.eventType == 'workflow.blocked' ||
              r.eventType == 'approval.escalated';
          if (_onlyCriticalReplay && !isCritical) return false;
          if (replayFilter.isNotEmpty && !detail.contains(replayFilter))
            return false;
          return true;
        })
        .toList(growable: false);
    final blockers = hasQuery
        ? store.incidentRcaTopBlockers(transactionType: type, transactionId: id)
        : const [];
    final export = hasQuery
        ? store.incidentEvidenceExportJson(
            transactionType: type,
            transactionId: id,
          )
        : '';
    final handoffExport = hasQuery
        ? store.incidentHandoffBundleJson(
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
            'Governance Investigation Workspace',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Replay lifecycle, inspect RCA chains, and export evidence bundles.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          const SettingsWorkflowNavStrip(),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _typeController,
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
                  controller: _idController,
                  decoration: const InputDecoration(
                    hintText: 'transactionId',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_typeController.text.trim().isEmpty ||
                      _idController.text.trim().isEmpty) {
                    setState(() {});
                    return;
                  }
                  store.setLastInvestigationContext(
                    transactionType: _typeController.text.trim(),
                    transactionId: _idController.text.trim(),
                  );
                  store.startInvestigating(
                    transactionType: _typeController.text.trim(),
                    transactionId: _idController.text.trim(),
                  );
                  store.setLastInvestigationViewState(
                    replayFilter: _replayFilterController.text,
                    onlyCritical: _onlyCriticalReplay,
                  );
                  setState(() {});
                },
                child: const Text('Investigate'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasQuery)
            const Text(
              'Enter transaction type + transaction id to load workspace.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _kpi('Events', summary?.totalEvents ?? 0),
                _kpi('Blocked', summary?.blockedCount ?? 0),
                _kpi('Escalated', summary?.escalationCount ?? 0),
                _kpi('Resolved', resolved ? 1 : 0),
                _kpi('Archived', archived ? 1 : 0),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'RCA Summary: ${summary?.blockedCount ?? 0} blocked, '
                '${summary?.escalationCount ?? 0} escalated, '
                'status ${summary?.status.label ?? '-'}, '
                'latest rule ${summary?.latestRuleCode ?? '-'} '
                '(${summary?.latestPermission ?? '-'})',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            if (summary?.latestRuleCode != null)
              Text(
                'Latest Rule: ${summary!.latestRuleCode} • '
                'Permission: ${summary.latestPermission ?? '-'}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (summary?.latestReason != null)
              Text(
                'Latest Reason: ${summary!.latestReason}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            const SizedBox(height: 12),
            const Text(
              'Incident Ownership',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _inlineInput(_assignedOperatorController, 'assigned operator'),
                _inlineInput(_branchLeadController, 'branch lead'),
                _inlineInput(_escalationOwnerController, 'escalation owner'),
                _inlineInput(_assigneeController, 'investigation assignee'),
                ElevatedButton(
                  onPressed: () {
                    store.setIncidentAssignment(
                      transactionType: type,
                      transactionId: id,
                      assignedOperator: _assignedOperatorController.text,
                      branchLead: _branchLeadController.text,
                      escalationOwner: _escalationOwnerController.text,
                      investigationAssignee: _assigneeController.text,
                      watcherList: _parseWatchers(_watchersController.text),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incident ownership saved')),
                    );
                  },
                  child: const Text('Save Owner'),
                ),
                OutlinedButton(
                  onPressed: () {
                    _assigneeController.text = 'current_operator';
                    store.setIncidentAssignment(
                      transactionType: type,
                      transactionId: id,
                      assignedOperator: _assignedOperatorController.text,
                      branchLead: _branchLeadController.text,
                      escalationOwner: _escalationOwnerController.text,
                      investigationAssignee: _assigneeController.text,
                      watcherList: _parseWatchers(_watchersController.text),
                      transferReason:
                          'self-assigned from investigation workspace',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Assigned to current operator'),
                      ),
                    );
                  },
                  child: const Text('Assign To Me'),
                ),
                _inlineInput(_watchersController, 'watchers: user1, user2'),
                _inlineInput(
                  _transferAssigneeController,
                  'transfer to assignee',
                ),
                _inlineInput(_transferReasonController, 'transfer reason'),
                OutlinedButton(
                  onPressed: () {
                    store.setIncidentAssignment(
                      transactionType: type,
                      transactionId: id,
                      assignedOperator: _assignedOperatorController.text,
                      branchLead: _branchLeadController.text,
                      escalationOwner: _escalationOwnerController.text,
                      investigationAssignee: _transferAssigneeController.text,
                      watcherList: _parseWatchers(_watchersController.text),
                      transferReason: _transferReasonController.text,
                    );
                    _assigneeController.text = _transferAssigneeController.text;
                    _transferReasonController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ownership transferred')),
                    );
                  },
                  child: const Text('Transfer Owner'),
                ),
              ],
            ),
            if (assignment != null) ...[
              const SizedBox(height: 6),
              Text(
                'Owner: ${assignment.investigationAssignee ?? '-'} • '
                'Escalation: ${assignment.escalationOwner ?? '-'} • '
                'Branch lead: ${assignment.branchLead ?? '-'} • '
                'Watchers: ${assignment.watcherList.isEmpty ? '-' : assignment.watcherList.join(', ')}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
            if (assignmentHistory.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                'Ownership Chain',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...assignmentHistory.reversed
                  .take(3)
                  .map(
                    (entry) => Text(
                      entry,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
            ],
            const SizedBox(height: 12),
            const Text(
              'RCA Top Blockers',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            ...blockers.map(
              (x) => Text(
                '${x.ruleCode} • ${x.permissionKey} • ${x.count}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Investigation Snapshots',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _snapshotLabelController,
                    decoration: const InputDecoration(
                      hintText: 'snapshot label',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    store.saveInvestigationSnapshot(
                      transactionType: type,
                      transactionId: id,
                      label: _snapshotLabelController.text,
                    );
                    _snapshotLabelController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Snapshot saved')),
                    );
                    setState(() {});
                  },
                  child: const Text('Save Snapshot'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: archived
                      ? () {
                          store.restoreIncidentToActive(
                            transactionType: type,
                            transactionId: id,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Archived incident reopened'),
                            ),
                          );
                          setState(() {});
                        }
                      : null,
                  child: const Text('Reopen Archived'),
                ),
              ],
            ),
            if (snapshots.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...snapshots.reversed
                  .take(3)
                  .map(
                    (s) => Text(
                      '${dateFmt.format(s.createdAt)} • ${s.label} • '
                      'filter=${s.replayFilter.isEmpty ? '-' : s.replayFilter} • '
                      'critical=${s.onlyCritical ? 'yes' : 'no'}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: snapshots.reversed
                    .take(3)
                    .map((s) {
                      return OutlinedButton(
                        onPressed: () {
                          final ok = store.applyInvestigationSnapshot(
                            transactionType: type,
                            transactionId: id,
                            createdAt: s.createdAt,
                          );
                          if (!ok) return;
                          setState(() {
                            _replayFilterController.text =
                                store.lastInvestigationReplayFilter;
                            _onlyCriticalReplay =
                                store.lastInvestigationOnlyCritical;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Snapshot applied: ${s.label}'),
                            ),
                          );
                        },
                        child: Text('Apply ${s.label}'),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Support Handoff Notes',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 420,
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'handoff note',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    store.addIncidentNote(
                      transactionType: type,
                      transactionId: id,
                      note: _noteController.text,
                    );
                    _noteController.clear();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Note added')));
                    setState(() {});
                  },
                  child: const Text('Add Note'),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...notes.reversed
                  .take(4)
                  .map(
                    (n) => Text(
                      n,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _replayFilterController,
                    onChanged: (_) {
                      store.setLastInvestigationViewState(
                        replayFilter: _replayFilterController.text,
                        onlyCritical: _onlyCriticalReplay,
                      );
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      hintText: 'filter replay',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Checkbox(
                  value: _onlyCriticalReplay,
                  onChanged: (value) {
                    _onlyCriticalReplay = value ?? false;
                    store.setLastInvestigationViewState(
                      replayFilter: _replayFilterController.text,
                      onlyCritical: _onlyCriticalReplay,
                    );
                    setState(() {});
                  },
                ),
                const Text(
                  'Only blocked/escalated',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    _replayFilterController.text = 'blocked';
                    store.setLastInvestigationViewState(
                      replayFilter: _replayFilterController.text,
                      onlyCritical: _onlyCriticalReplay,
                    );
                    setState(() {});
                  },
                  child: const Text('Jump Blocked'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: () {
                    _replayFilterController.text = 'escalated';
                    store.setLastInvestigationViewState(
                      replayFilter: _replayFilterController.text,
                      onlyCritical: _onlyCriticalReplay,
                    );
                    setState(() {});
                  },
                  child: const Text('Jump Escalated'),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: () {
                    _replayFilterController.text = 'incident_status';
                    store.setLastInvestigationViewState(
                      replayFilter: _replayFilterController.text,
                      onlyCritical: _onlyCriticalReplay,
                    );
                    setState(() {});
                  },
                  child: const Text('Jump Status'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Replay Timeline',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: replayVisible.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.borderColor),
                itemBuilder: (context, index) {
                  final r = replayVisible[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      r.eventType,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${dateFmt.format(r.at)} • ${r.detail}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Evidence Export (JSON)',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: export));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Evidence JSON copied')),
                    );
                  },
                  child: const Text('Copy JSON'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text('Handoff Bundle Preview'),
                        content: SizedBox(
                          width: 700,
                          child: SingleChildScrollView(
                            child: SelectableText(
                              handoffExport,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: handoffExport),
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Handoff bundle copied'),
                                ),
                              );
                            },
                            child: const Text('Copy'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Copy Handoff Bundle'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: resolved
                      ? null
                      : () {
                          store.resolveIncident(
                            transactionType: type,
                            transactionId: id,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Incident marked as resolved'),
                            ),
                          );
                          setState(() {});
                        },
                  child: Text(resolved ? 'Resolved' : 'Mark Resolved'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: (!resolved || archived)
                      ? null
                      : () {
                          store.archiveIncident(
                            transactionType: type,
                            transactionId: id,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Incident archived')),
                          );
                          setState(() {});
                        },
                  child: Text(archived ? 'Archived' : 'Archive'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 180,
              child: SingleChildScrollView(
                child: SelectableText(
                  export,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kpi(String label, int value) {
    return Container(
      width: 160,
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
          const SizedBox(height: 4),
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

  Widget _inlineInput(TextEditingController controller, String hint) {
    return SizedBox(
      width: 170,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  List<String> _parseWatchers(String raw) {
    if (raw.trim().isEmpty) {
      return const <String>[];
    }
    final seen = <String>{};
    final out = <String>[];
    for (final part in raw.split(',')) {
      final value = part.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(value);
    }
    return out;
  }
}
