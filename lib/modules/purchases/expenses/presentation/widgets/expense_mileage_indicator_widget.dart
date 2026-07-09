import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_record.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

const String kMileageExpenseAccountLabel = 'Fuel/Mileage Expenses';

bool isMileageExpenseRecord(ExpenseRecord record) {
  return record.expenseMode.toUpperCase() == 'RECORD_MILEAGE';
}

String displayExpenseAccountLabel(ExpenseRecord record) {
  final firstItemAccount = record.items.isNotEmpty
      ? record.items.first.expenseAccountName?.trim() ?? ''
      : '';
  if (firstItemAccount.isNotEmpty) {
    return firstItemAccount;
  }
  final value = record.expenseAccount.trim();
  if (value.isNotEmpty) {
    return value;
  }
  return isMileageExpenseRecord(record) ? kMileageExpenseAccountLabel : '';
}

class ExpenseMileageIndicatorIcon extends StatelessWidget {
  const ExpenseMileageIndicatorIcon({
    super.key,
    this.size = 15,
    this.color = AppTheme.textPrimary,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ZTooltip(
      message: 'Mileage Expense',
      child: Icon(LucideIcons.gauge, size: size, color: color),
    );
  }
}

class ExpenseMileageAccountInline extends StatelessWidget {
  const ExpenseMileageAccountInline({
    super.key,
    required this.record,
    required this.style,
    this.maxLines = 2,
    this.iconSize = 15,
    this.iconColor = AppTheme.textPrimary,
    this.iconSpacing = 4,
    this.iconBottomPadding = 2,
  });

  final ExpenseRecord record;
  final TextStyle style;
  final int maxLines;
  final double iconSize;
  final Color iconColor;
  final double iconSpacing;
  final double iconBottomPadding;

  @override
  Widget build(BuildContext context) {
    final label = displayExpenseAccountLabel(record);
    if (!isMileageExpenseRecord(record)) {
      return Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: maxLines,
        softWrap: maxLines > 1,
        style: style,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            softWrap: maxLines > 1,
            style: style,
          ),
        ),
        SizedBox(width: iconSpacing),
        Padding(
          padding: EdgeInsets.only(bottom: iconBottomPadding),
          child: ExpenseMileageIndicatorIcon(size: iconSize, color: iconColor),
        ),
      ],
    );
  }
}
