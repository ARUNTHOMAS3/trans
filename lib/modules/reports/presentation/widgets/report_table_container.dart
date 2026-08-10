import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ReportTableContainer extends StatelessWidget {
  final Widget child;
  final Widget? headerActions;

  const ReportTableContainer({
    super.key,
    required this.child,
    this.headerActions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (headerActions != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space24,
                  AppTheme.space14,
                  AppTheme.space24,
                  AppTheme.space12,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: headerActions!,
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderLight,
              ),
            ],
          ),
        child,
      ],
    );
  }
}
