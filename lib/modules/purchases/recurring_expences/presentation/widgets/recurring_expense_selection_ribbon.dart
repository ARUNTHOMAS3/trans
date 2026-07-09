import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';

class RecurringExpenseSelectionRibbon extends StatelessWidget {
  final int selectedCount;
  final ValueChanged<String> onAction;
  final VoidCallback onClearSelection;

  const RecurringExpenseSelectionRibbon({
    super.key,
    required this.selectedCount,
    required this.onAction,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _RibbonButton(
            label: 'Bulk Update',
            onPressed: () => onAction('bulk_update'),
          ),
          const _RibbonDivider(),
          _RibbonButton(label: 'Start', onPressed: () => onAction('start')),
          const SizedBox(width: 12),
          _RibbonButton(label: 'Stop', onPressed: () => onAction('stop')),
          const SizedBox(width: 12),
          _RibbonButton(label: 'Delete', onPressed: () => onAction('delete')),
          const _RibbonDivider(),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.infoBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$selectedCount',
              style: AppTextStyles.body.copyWith(
                color: AppTheme.primaryBlueDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Selected',
            style: AppTextStyles.body.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onClearSelection,
            borderRadius: BorderRadius.circular(4),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Esc',
                    style: AppTextStyles.body.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.x, color: AppTheme.errorRed, size: 19),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RibbonDivider extends StatelessWidget {
  const _RibbonDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      color: AppTheme.borderColor,
      margin: const EdgeInsets.symmetric(horizontal: 18),
    );
  }
}

class _RibbonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _RibbonButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: AppTextStyles.body.copyWith(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
