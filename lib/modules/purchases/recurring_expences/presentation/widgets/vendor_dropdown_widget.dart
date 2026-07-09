import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';

class VendorDropdownWidget extends StatelessWidget {
  final RecurringExpenseVendorOption? value;
  final List<RecurringExpenseVendorOption> items;
  final ValueChanged<RecurringExpenseVendorOption?> onChanged;
  final VoidCallback? onAddVendor;
  final bool isLoading;
  final String? hint;
  final BorderRadius? borderRadius;

  const VendorDropdownWidget({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.onAddVendor,
    this.isLoading = false,
    this.hint = 'Select a Vendor',
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return FormDropdown<RecurringExpenseVendorOption>(
      height: 32,
      value: value,
      items: items,
      isLoading: isLoading,
      hint: hint,
      showSearch: true,
      onChanged: onChanged,
      borderRadius: borderRadius,
      allowClear: true,
      showSettings: onAddVendor != null,
      settingsLabel: 'New Vendor',
      settingsIcon: LucideIcons.plus,
      onSettingsTap: onAddVendor,
      displayStringForValue: (item) => item.displayName,
      searchStringForValue: (item) => item.displayName,
      itemHeight: 56.0,
      itemBuilder: (item, isSelected, isHovered) {
        final firstName = (item.firstName ?? '').trim();
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
        final topLine =
            item.vendorNumber != null && item.vendorNumber!.isNotEmpty
            ? '${item.displayName} | ${item.vendorNumber}'
            : item.displayName;

        return Container(
          height: 56.0,
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: primaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.companyName != null &&
                        item.companyName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.companyName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
