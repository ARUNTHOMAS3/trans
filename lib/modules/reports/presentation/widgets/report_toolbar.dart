import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_export_menu.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';

class ReportToolbar extends StatelessWidget {
  final bool showExport;
  final bool showRefresh;
  final bool showReload;
  final bool showSchedule;
  final bool showSettings;
  final bool showClose;
  final bool showCompare;
  final bool showCustomizeColumns;
  final bool showPrint;
  final bool showDownload;
  final VoidCallback? onRefresh;
  final VoidCallback? onReload;
  final VoidCallback? onHistory;
  final VoidCallback? onSchedule;
  final VoidCallback? onSettings;
  final VoidCallback? onClose;
  final VoidCallback? onExport;
  final VoidCallback? onDownload;
  final VoidCallback? onPrint;
  final String settingsTooltip;
  final String scheduleTooltip;
  final List<Widget> leadingActions;

  const ReportToolbar({
    super.key,
    this.showExport = true,
    this.showRefresh = false,
    this.showReload = true,
    this.showSchedule = false,
    this.showSettings = true,
    this.showClose = true,
    this.showCompare = false,
    this.showCustomizeColumns = false,
    this.showPrint = true,
    this.showDownload = true,
    this.onRefresh,
    this.onReload,
    this.onHistory,
    this.onSchedule,
    this.onSettings,
    this.onClose,
    this.onExport,
    this.onDownload,
    this.onPrint,
    this.settingsTooltip = 'Settings',
    this.scheduleTooltip = 'Schedule',
    this.leadingActions = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final action in leadingActions) ...[
            action,
            const SizedBox(width: AppTheme.space8),
          ],
          if (showSettings) ...[
            ReportIconActionButton(
              icon: LucideIcons.slidersHorizontal,
              onPressed: onSettings,
              tooltip: settingsTooltip,
              useLocalTooltip: true,
            ),
            const SizedBox(width: AppTheme.space8),
          ],
          if (showSchedule) ...[
            ReportIconActionButton(
              icon: LucideIcons.alarmClock,
              onPressed: onSchedule,
              tooltip: scheduleTooltip,
              useLocalTooltip: true,
            ),
            const SizedBox(width: AppTheme.space8),
          ],
          if (showExport) ...[
            ReportExportMenu(
              onExport: onExport,
              onDownload: showDownload ? onDownload : null,
              onPrint: showPrint ? onPrint : null,
            ),
            const SizedBox(width: AppTheme.space8),
          ],
          if (showReload) ...[
            ReportIconActionButton(
              icon: LucideIcons.history,
              onPressed: onHistory ?? onReload,
              tooltip: 'Show History',
              useLocalTooltip: true,
            ),
            const SizedBox(width: AppTheme.space8),
          ],
          if (showRefresh) ...[
            ReportIconActionButton(
              icon: LucideIcons.rotateCw,
              onPressed: onRefresh,
              tooltip: 'Refresh',
            ),
            const SizedBox(width: AppTheme.space8),
          ],
          if (showClose) ...[
            const SizedBox(width: AppTheme.space16),
            ReportIconActionButton(
              icon: LucideIcons.x,
              onPressed: onClose,
              iconColor: AppTheme.errorRed,
              chromeless: true,
              useLocalTooltip: true,
            ),
          ],
        ],
      ),
    );
  }
}
