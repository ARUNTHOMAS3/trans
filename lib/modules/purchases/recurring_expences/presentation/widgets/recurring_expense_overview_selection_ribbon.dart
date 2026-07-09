import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';

import 'recurring_expense_hover_popup_menu_item.dart';

class RecurringExpenseOverviewSelectionRibbon extends StatefulWidget {
  final int selectedCount;
  final ValueChanged<String> onAction;
  final VoidCallback onClearSelection;

  const RecurringExpenseOverviewSelectionRibbon({
    super.key,
    required this.selectedCount,
    required this.onAction,
    required this.onClearSelection,
  });

  @override
  State<RecurringExpenseOverviewSelectionRibbon> createState() =>
      _RecurringExpenseOverviewSelectionRibbonState();
}

class _RecurringExpenseOverviewSelectionRibbonState
    extends State<RecurringExpenseOverviewSelectionRibbon> {
  final ValueNotifier<String?> _hoveredActionNotifier = ValueNotifier<String?>(
    null,
  );

  @override
  void dispose() {
    _hoveredActionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      decoration: const BoxDecoration(
        color: AppTheme.bgDisabled,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'Bulk Actions',
                    padding: EdgeInsets.zero,
                    offset: const Offset(0, 32),
                    color: AppTheme.backgroundColor,
                    surfaceTintColor: AppTheme.backgroundColor,
                    elevation: 8,
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppTheme.borderLight),
                    ),
                    constraints: const BoxConstraints.tightFor(width: 206),
                    onSelected: widget.onAction,
                    itemBuilder: (context) {
                      _hoveredActionNotifier.value = null;
                      return [
                        PopupMenuItem<String>(
                          value: 'bulk_update',
                          padding: EdgeInsets.zero,
                          height: 40,
                          child: RecurringExpenseHoverPopupMenuItem(
                            label: 'Bulk Update',
                            value: 'bulk_update',
                            hoveredNotifier: _hoveredActionNotifier,
                            onTap: () =>
                                Navigator.of(context).pop('bulk_update'),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'start',
                          padding: EdgeInsets.zero,
                          height: 40,
                          child: RecurringExpenseHoverPopupMenuItem(
                            label: 'Resume',
                            value: 'start',
                            hoveredNotifier: _hoveredActionNotifier,
                            onTap: () => Navigator.of(context).pop('start'),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'stop',
                          padding: EdgeInsets.zero,
                          height: 40,
                          child: RecurringExpenseHoverPopupMenuItem(
                            label: 'Stop',
                            value: 'stop',
                            hoveredNotifier: _hoveredActionNotifier,
                            onTap: () => Navigator.of(context).pop('stop'),
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem<String>(
                          value: 'delete',
                          padding: EdgeInsets.zero,
                          height: 40,
                          child: RecurringExpenseHoverPopupMenuItem(
                            label: 'Delete',
                            value: 'delete',
                            hoveredNotifier: _hoveredActionNotifier,
                            onTap: () => Navigator.of(context).pop('delete'),
                          ),
                        ),
                      ];
                    },
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bulk Actions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 14,
                    color: AppTheme.borderColor,
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.infoBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.selectedCount}',
                      style: AppTextStyles.body.copyWith(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Selected',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: widget.onClearSelection,
              borderRadius: BorderRadius.circular(4),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: const Padding(
                padding: EdgeInsets.only(left: 8, right: 2),
                child: Icon(
                  LucideIcons.x,
                  color: AppTheme.errorRed,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
