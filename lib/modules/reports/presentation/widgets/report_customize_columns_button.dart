import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';

class ReportCustomizeColumnsButton extends StatelessWidget {
  final String label;
  final int? count;
  final VoidCallback? onPressed;

  const ReportCustomizeColumnsButton({
    super.key,
    this.label = 'Customize Report Columns',
    this.count,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ReportTextActionButton(
      label: label,
      icon: Icons.view_column_outlined,
      onPressed: onPressed,
      trailing: count == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space6,
                vertical: AppTheme.space2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.infoBg,
                borderRadius: BorderRadius.circular(AppTheme.space12),
              ),
              child: Text(
                '$count',
                style: AppTheme.captionText.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}
