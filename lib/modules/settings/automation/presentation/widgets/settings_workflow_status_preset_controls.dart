import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/workflow/governance_insights_model.dart';

class SettingsWorkflowStatusPresetControls extends StatelessWidget {
  final String title;
  final Set<GovernanceIncidentStatus> statuses;
  final Set<GovernanceIncidentStatus> savedPreset;
  final ValueChanged<GovernanceIncidentStatus> onToggleStatus;
  final VoidCallback onSavePreset;
  final VoidCallback onApplySavedPreset;

  const SettingsWorkflowStatusPresetControls({
    super.key,
    required this.title,
    required this.statuses,
    required this.savedPreset,
    required this.onToggleStatus,
    required this.onSavePreset,
    required this.onApplySavedPreset,
  });

  @override
  Widget build(BuildContext context) {
    final presetSummary = _statusSummary(savedPreset);
    final isPresetActive = _matchesPreset(statuses, savedPreset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GovernanceIncidentStatus.values.map((status) {
            final selected = statuses.contains(status);
            return FilterChip(
              label: Text(status.label),
              selected: selected,
              onSelected: (_) => onToggleStatus(status),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: onSavePreset,
              child: const Text('Save Current Preset'),
            ),
            OutlinedButton(
              onPressed: onApplySavedPreset,
              child: const Text('Apply Saved Preset'),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isPresetActive
                    ? 'Current preset active • $presetSummary'
                    : 'Custom filter • preset $presetSummary',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _matchesPreset(
    Set<GovernanceIncidentStatus> current,
    Set<GovernanceIncidentStatus> preset,
  ) {
    if (current.length != preset.length) {
      return false;
    }
    return current.every(preset.contains);
  }

  String _statusSummary(Set<GovernanceIncidentStatus> statuses) {
    if (statuses.isEmpty) {
      return 'none';
    }
    final labels = statuses.map((x) => x.label).toList(growable: false);
    if (labels.length <= 2) {
      return labels.join(', ');
    }
    return '${labels.take(2).join(', ')} +${labels.length - 2}';
  }
}
