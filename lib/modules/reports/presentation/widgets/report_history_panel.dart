import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';

class ReportHistoryPanel extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const ReportHistoryPanel({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  static const double panelWidth = 360;

  @override
  Widget build(BuildContext context) {
    final shadowColor = Theme.of(context).shadowColor;

    return IgnorePointer(
      ignoring: !isOpen,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: isOpen ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                onTap: onClose,
                child: Container(color: shadowColor.withValues(alpha: 0.08)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              offset: isOpen ? Offset.zero : const Offset(1.08, 0),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: isOpen ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: SizedBox(
                  width: panelWidth,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      border: Border(
                        left: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.space20,
                            AppTheme.space20,
                            AppTheme.space16,
                            AppTheme.space16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Report Activity',
                                  style: AppTheme.pageTitle,
                                ),
                              ),
                              ReportIconActionButton(
                                icon: LucideIcons.x,
                                onPressed: onClose,
                                tooltip: 'Close',
                                iconColor: AppTheme.errorRed,
                                chromeless: true,
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppTheme.borderLight,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'No comments yet.',
                              style: AppTheme.bodyText,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
