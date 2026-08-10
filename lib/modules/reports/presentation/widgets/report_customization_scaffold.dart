import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

import 'report_action_buttons.dart';
import 'report_customization_nav_item.dart';

class ReportCustomizationScaffold extends StatelessWidget {
  final String title;
  final List<(String id, String label)> navItems;
  final String selectedNavId;
  final ValueChanged<String> onNavChanged;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const ReportCustomizationScaffold({
    super.key,
    required this.title,
    required this.navItems,
    required this.selectedNavId,
    required this.onNavChanged,
    required this.child,
    this.onBack,
    this.onClose,
    this.primaryActionLabel = 'Run Report',
    this.onPrimaryAction,
    this.secondaryActionLabel = 'Cancel',
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = (AppTheme.space64 * 3) + AppTheme.space8;

    return Material(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space16,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                ReportIconActionButton(
                  icon: Icons.menu,
                  onPressed: onBack,
                  tooltip: 'Back',
                ),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.pageTitle,
                  ),
                ),
                ReportIconActionButton(
                  icon: Icons.close,
                  onPressed: onClose,
                  tooltip: 'Close',
                  iconColor: AppTheme.errorRed,
                  chromeless: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: sidebarWidth,
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    border: Border(right: BorderSide(color: AppTheme.borderLight)),
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final item in navItems)
                        ReportCustomizationNavItem(
                          label: item.$2,
                          selected: selectedNavId == item.$1,
                          onTap: () => onNavChanged(item.$1),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: child,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space20,
                          vertical: AppTheme.space16,
                        ),
                        decoration: const BoxDecoration(
                          color: AppTheme.backgroundColor,
                          border: Border(top: BorderSide(color: AppTheme.borderLight)),
                        ),
                        child: Row(
                          children: [
                            ReportPrimaryActionButton(
                              label: primaryActionLabel,
                              onPressed: onPrimaryAction,
                            ),
                            const SizedBox(width: AppTheme.space16),
                            TextButton(
                              onPressed: onSecondaryAction,
                              child: Text(
                                secondaryActionLabel,
                                style: AppTheme.bodyText.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
