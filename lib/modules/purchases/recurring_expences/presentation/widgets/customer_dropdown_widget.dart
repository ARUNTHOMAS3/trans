import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';

class CustomerDropdownWidget extends StatelessWidget {
  final RecurringExpenseCustomerOption? value;
  final List<RecurringExpenseCustomerOption> items;
  final ValueChanged<RecurringExpenseCustomerOption?> onChanged;
  final VoidCallback? onAddCustomer;
  final bool isLoading;
  final String? hint;
  final BorderRadius? borderRadius;

  const CustomerDropdownWidget({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.onAddCustomer,
    this.isLoading = false,
    this.hint = 'Select Customer',
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return FormDropdown<RecurringExpenseCustomerOption>(
      height: 32,
      value: value,
      items: items,
      isLoading: isLoading,
      hint: hint,
      showSearch: true,
      onChanged: onChanged,
      borderRadius: borderRadius,
      allowClear: true,
      showSettings: onAddCustomer != null,
      settingsLabel: 'New Customer',
      settingsIcon: LucideIcons.plus,
      onSettingsTap: onAddCustomer,
      displayStringForValue: (item) => item.displayName,
      searchStringForValue: (item) => item.displayName,
      itemHeight: 56,
      itemBuilder: (item, isSelected, isHovered) {
        final customerNumber = (item.customerNumber ?? '').trim();
        final email = (item.email ?? '').trim();
        final companyName = (item.companyName ?? '').trim();
        final firstName = (item.firstName ?? '').trim();

        final topLine = customerNumber.isEmpty
            ? item.displayName
            : '${item.displayName} | $customerNumber';

        final List<String> bottomParts = <String>[];
        if (email.isNotEmpty) bottomParts.add(email);
        if (companyName.isNotEmpty) bottomParts.add(companyName);
        final bottomLine = bottomParts.join(' | ');

        final initialSource = firstName.isNotEmpty
            ? firstName
            : (item.displayName.isNotEmpty ? item.displayName : '?');
        final initial = initialSource.substring(0, 1).toUpperCase();

        final backgroundColor = isHovered
            ? const Color(0xFF3B82F6)
            : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
        final primaryTextColor = isHovered
            ? Colors.white
            : AppTheme.textPrimary;
        final secondaryTextColor = isHovered
            ? Colors.white.withValues(alpha: 0.85)
            : AppTheme.textSecondary;

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHovered
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFE5E7EB),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isHovered ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      topLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: primaryTextColor,
                      ),
                    ),
                    if (bottomLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        bottomLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
