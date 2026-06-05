import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/workflow/approval_queue_engine.dart';
import 'package:zerpai_erp/core/workflow/domain_events.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/settings/automation/providers/workflow_governance_provider.dart';

class SettingsWorkflowActionsPage extends ConsumerStatefulWidget {
  const SettingsWorkflowActionsPage({super.key});

  @override
  ConsumerState<SettingsWorkflowActionsPage> createState() =>
      _SettingsWorkflowActionsPageState();
}

class _SettingsWorkflowActionsPageState
    extends ConsumerState<SettingsWorkflowActionsPage> {
  String? _selectedQueueId;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(workflowRuntimeStoreProvider);
    final queue = store.approvalQueue;
    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    ApprovalQueueItem? selected;
    if (_selectedQueueId != null) {
      for (final item in queue) {
        if (item.queueId == _selectedQueueId) {
          selected = item;
          break;
        }
      }
    }
    final trace = selected == null
        ? const []
        : store.traceForTransaction(
            transactionType: selected.transactionType,
            transactionId: selected.transactionId,
          );
    final blockedReason = selected == null
        ? null
        : store.latestBlockedReason(
            transactionType: selected.transactionType,
            transactionId: selected.transactionId,
          );
    final blockedEvent = selected == null
        ? null
        : store.latestBlockedEvent(
            transactionType: selected.transactionType,
            transactionId: selected.transactionId,
          );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approval Workbench',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pending approval queue with SLA and overdue visibility.',
            style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: () {
                  store.evaluateApprovalEscalations();
                },
                child: const Text('Run Escalation Check'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: queue.isEmpty
                ? const _EmptyState(
                    message: 'No pending approvals captured yet.',
                  )
                : ListView.separated(
                    itemCount: queue.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppTheme.borderColor),
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      final escalationLevel = store.escalationLevelFor(
                        item.queueId,
                      );
                      return ListTile(
                        selected: item.queueId == _selectedQueueId,
                        onTap: () {
                          setState(() {
                            _selectedQueueId = item.queueId;
                          });
                        },
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        title: Text(
                          '${item.transactionType} • ${item.transactionId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Pending since ${dateFmt.format(item.pendingSince)}'
                          '${item.sla != null ? ' • SLA ${item.sla!.inHours}h' : ''}'
                          '${escalationLevel > 0 ? ' • Esc L$escalationLevel' : ''}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.isOverdue
                                ? const Color(0xFFFFEAEA)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            item.isOverdue ? 'Overdue' : 'Within SLA',
                            style: TextStyle(
                              color: item.isOverdue
                                  ? AppTheme.errorRed
                                  : AppTheme.successGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (selected != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approval Trace • ${selected.transactionId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (blockedReason != null)
                    Text(
                      'Why blocked: $blockedReason',
                      style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (blockedEvent != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Rule: ${blockedEvent.ruleCode ?? '-'}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      'Permission: ${blockedEvent.permissionUsed ?? '-'}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      'Actor: ${blockedEvent.actorName ?? blockedEvent.actorId ?? 'system'}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (trace.isEmpty)
                    const Text(
                      'No trace events yet.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    ...trace.reversed.map((e) {
                      final label = switch (e.event) {
                        TransactionTransitionedEvent t =>
                          'Transition: ${t.fromStatus} -> ${t.toStatus}',
                        WorkflowBlockedEvent b =>
                          'Blocked: ${b.fromStatus} -> ${b.toStatus}',
                        ApprovalQueuedEvent _ => 'Approval queued',
                        ApprovalEscalatedEvent a =>
                          'Escalated to level ${a.level}',
                        InventoryFreezeViolationEvent _ =>
                          'Inventory freeze violation',
                        _ => e.event.eventType,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${dateFmt.format(e.event.occurredAt)} • $label',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }
}
