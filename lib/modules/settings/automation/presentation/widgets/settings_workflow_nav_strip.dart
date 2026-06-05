import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class SettingsWorkflowNavStrip extends StatelessWidget {
  const SettingsWorkflowNavStrip({super.key});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String path) {
      return OutlinedButton(
        onPressed: () => context.go(path),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.borderColor),
          backgroundColor: Colors.white,
        ),
        child: Text(label),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Mission', '/settings/workflow-mission-control'),
        chip('Ops Center', '/settings/workflow-ops-center'),
        chip('Investigation', '/settings/workflow-investigation'),
        chip('Rules', '/settings/workflow-rules'),
        chip('Actions', '/settings/workflow-actions'),
        chip('Logs', '/settings/workflow-logs'),
      ],
    );
  }
}

