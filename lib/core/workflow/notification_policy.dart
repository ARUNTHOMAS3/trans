class WorkflowNotificationAction {
  final String channel;
  final String templateKey;
  final String severity;

  const WorkflowNotificationAction({
    required this.channel,
    required this.templateKey,
    required this.severity,
  });
}

class WorkflowNotificationPolicy {
  final String eventType;
  final List<WorkflowNotificationAction> actions;

  const WorkflowNotificationPolicy({
    required this.eventType,
    required this.actions,
  });
}

const List<WorkflowNotificationPolicy> workflowNotificationPolicies =
    <WorkflowNotificationPolicy>[
      WorkflowNotificationPolicy(
        eventType: 'approval.queued',
        actions: <WorkflowNotificationAction>[
          WorkflowNotificationAction(
            channel: 'in_app',
            templateKey: 'approval_queued_default',
            severity: 'info',
          ),
          WorkflowNotificationAction(
            channel: 'email',
            templateKey: 'approval_queued_email',
            severity: 'info',
          ),
        ],
      ),
      WorkflowNotificationPolicy(
        eventType: 'workflow.blocked',
        actions: <WorkflowNotificationAction>[
          WorkflowNotificationAction(
            channel: 'in_app',
            templateKey: 'workflow_blocked_warning',
            severity: 'warning',
          ),
        ],
      ),
      WorkflowNotificationPolicy(
        eventType: 'approval.escalated',
        actions: <WorkflowNotificationAction>[
          WorkflowNotificationAction(
            channel: 'in_app',
            templateKey: 'approval_escalated_warning',
            severity: 'warning',
          ),
          WorkflowNotificationAction(
            channel: 'email',
            templateKey: 'approval_escalated_email',
            severity: 'high',
          ),
        ],
      ),
      WorkflowNotificationPolicy(
        eventType: 'inventory.freeze_violation',
        actions: <WorkflowNotificationAction>[
          WorkflowNotificationAction(
            channel: 'in_app',
            templateKey: 'inventory_freeze_violation_alert',
            severity: 'warning',
          ),
          WorkflowNotificationAction(
            channel: 'email',
            templateKey: 'inventory_freeze_violation_email',
            severity: 'high',
          ),
        ],
      ),
    ];

WorkflowNotificationPolicy? resolveWorkflowNotificationPolicy(
  String eventType,
) {
  for (final policy in workflowNotificationPolicies) {
    if (policy.eventType == eventType) return policy;
  }
  return null;
}
