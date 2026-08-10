import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

import 'report_action_buttons.dart';
import 'report_company_header.dart';
import 'report_content_card.dart';
import 'report_error_state.dart';
import 'report_filter_bar.dart';
import 'report_history_panel.dart';
import 'report_navigation_sidebar.dart';
import 'report_table_container.dart';
import 'report_title_section.dart';
import 'report_toolbar.dart';

class ReportViewScaffold extends StatefulWidget {
  final String categoryLabel;
  final String reportTitle;
  final String dateLabel;
  final String? contentTitle;
  final String? contentSubtitle;
  final String companyName;
  final List<Widget> filters;
  final Widget reportContent;
  final Widget? tableHeaderActions;
  final Widget? reportHeading;
  final VoidCallback? onRunReport;
  final VoidCallback? onClose;
  final VoidCallback? onRefresh;
  final VoidCallback? onReload;
  final VoidCallback? onHistory;
  final VoidCallback? onSchedule;
  final VoidCallback? onSettings;
  final VoidCallback? onExport;
  final VoidCallback? onDownload;
  final VoidCallback? onPrint;
  final bool showExport;
  final bool showRefresh;
  final bool showReload;
  final bool showSchedule;
  final bool showSettings;
  final bool showClose;
  final bool showPrint;
  final bool showDownload;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isEmpty;
  final String emptyTitle;
  final String emptyMessage;
  final String currentNavigationCategory;
  final String currentNavigationReport;
  final void Function(String reportName, String category)? onReportSelected;
  final String settingsTooltip;
  final String scheduleTooltip;
  final Widget? expandedFilterPanel;
  final bool isExpandedFilterPanelOpen;
  final VoidCallback? onDismissExpandedFilterPanel;
  final bool showInlineRunReportButton;
  final bool showFilterBar;
  final bool hasPendingFilterChanges;
  final List<Widget> leadingToolbarActions;
  final Widget? noticeBanner;

  const ReportViewScaffold({
    super.key,
    required this.categoryLabel,
    required this.reportTitle,
    required this.dateLabel,
    this.contentTitle,
    this.contentSubtitle,
    required this.companyName,
    required this.filters,
    required this.reportContent,
    this.tableHeaderActions,
    this.reportHeading,
    this.onRunReport,
    this.onClose,
    this.onRefresh,
    this.onReload,
    this.onHistory,
    this.onSchedule,
    this.onSettings,
    this.onExport,
    this.onDownload,
    this.onPrint,
    this.showExport = true,
    this.showRefresh = false,
    this.showReload = true,
    this.showSchedule = false,
    this.showSettings = true,
    this.showClose = true,
    this.showPrint = true,
    this.showDownload = true,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.isEmpty = false,
    this.emptyTitle = 'No data available',
    this.emptyMessage =
        'There are no rows available for the current report filters.',
    required this.currentNavigationCategory,
    required this.currentNavigationReport,
    this.onReportSelected,
    this.settingsTooltip = 'Settings',
    this.scheduleTooltip = 'Schedule',
    this.expandedFilterPanel,
    this.isExpandedFilterPanelOpen = false,
    this.onDismissExpandedFilterPanel,
    this.showInlineRunReportButton = true,
    this.showFilterBar = true,
    this.hasPendingFilterChanges = false,
    this.leadingToolbarActions = const <Widget>[],
    this.noticeBanner,
  });

  @override
  State<ReportViewScaffold> createState() => _ReportViewScaffoldState();
}

class _ReportViewScaffoldState extends State<ReportViewScaffold> {
  final ScrollController _contentScrollController = ScrollController();
  bool _isNavigationOpen = false;
  bool _isHistoryOpen = false;

  void _toggleNavigationPanel() {
    if (_isHistoryOpen) {
      _closeHistoryPanel();
    }
    setState(() => _isNavigationOpen = !_isNavigationOpen);
  }

  void _closeNavigationPanel() {
    if (_isNavigationOpen) {
      setState(() => _isNavigationOpen = false);
    }
  }

  void _openHistoryPanel() {
    _closeNavigationPanel();
    if (!_isHistoryOpen) {
      setState(() => _isHistoryOpen = true);
    }
    widget.onHistory?.call();
  }

  void _closeHistoryPanel() {
    if (_isHistoryOpen) {
      setState(() => _isHistoryOpen = false);
    }
  }

  void _handleEscape() {
    if (_isHistoryOpen) {
      _closeHistoryPanel();
      return;
    }
    _closeNavigationPanel();
  }

  void _handleReportSelection(String reportName, String category) {
    _closeNavigationPanel();
    widget.onReportSelected?.call(reportName, category);
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  Widget _buildReportBody() {
    if (widget.isLoading) {
      return const SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: TableSkeleton(rows: 8, columns: 7),
      );
    }

    if (widget.errorMessage != null) {
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ReportErrorState(
          message: widget.errorMessage!,
          onRetry: widget.onRetry,
        ),
      );
    }

    return widget.reportContent;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _handleEscape,
      },
      child: Focus(
        autofocus: true,
        child: ZerpaiLayout(
          pageTitle: '',
          enableBodyScroll: false,
          useHorizontalPadding: false,
          useTopPadding: false,
          child: Container(
            color: AppTheme.bgLight,
            child: Stack(
              children: [
                Column(
                  children: [
                    _ReportHeaderShell(
                      categoryLabel: widget.categoryLabel,
                      title: widget.reportTitle,
                      dateLabel: widget.dateLabel,
                      onLeadingPressed: _toggleNavigationPanel,
                      toolbar: ReportToolbar(
                        showExport: widget.showExport,
                        showRefresh: widget.showRefresh,
                        showReload: widget.showReload,
                        showSchedule: widget.showSchedule,
                        showSettings: widget.showSettings,
                        showClose: widget.showClose,
                        showPrint: widget.showPrint,
                        showDownload: widget.showDownload,
                        onRefresh: widget.onRefresh,
                        onReload: widget.onReload,
                        onHistory: _openHistoryPanel,
                        onSchedule: widget.onSchedule,
                        onSettings: widget.onSettings,
                        onClose: widget.onClose,
                        onExport: widget.onExport,
                        onDownload: widget.onDownload,
                        onPrint: widget.onPrint,
                        settingsTooltip: widget.settingsTooltip,
                        scheduleTooltip: widget.scheduleTooltip,
                        leadingActions: widget.leadingToolbarActions,
                      ),
                    ),
                    Expanded(
                      child: NestedScrollView(
                        physics: const ClampingScrollPhysics(),
                        key: ValueKey<String>(
                          '${widget.currentNavigationCategory}:${widget.currentNavigationReport}',
                        ),
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            if (widget.showFilterBar)
                              SliverToBoxAdapter(
                                child: ReportFilterBar(
                                  filters: widget.filters,
                                  onRunReport: widget.onRunReport,
                                  expandedPanel: widget.expandedFilterPanel,
                                  isExpandedPanelOpen:
                                      widget.isExpandedFilterPanelOpen,
                                  onDismissExpandedPanel:
                                      widget.onDismissExpandedFilterPanel,
                                  showRunButton:
                                      widget.showInlineRunReportButton,
                                  hasPendingFilterChanges:
                                      widget.hasPendingFilterChanges,
                                ),
                              ),
                            if (widget.noticeBanner != null && !widget.isEmpty)
                              SliverToBoxAdapter(child: widget.noticeBanner!),
                          ];
                        },
                        body: Padding(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          child: ReportContentCard(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.space12,
                              ),
                              child: Scrollbar(
                                controller: _contentScrollController,
                                thumbVisibility: true,
                                notificationPredicate: (notification) =>
                                    notification.depth == 0 &&
                                    notification.metrics.axis == Axis.vertical,
                                child: NestedScrollView(
                                  controller: _contentScrollController,
                                  physics: const ClampingScrollPhysics(),
                                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                                    return [
                                      SliverToBoxAdapter(
                                        child: ReportTableContainer(
                                          headerActions:
                                              widget.tableHeaderActions,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              const SizedBox(
                                                height: AppTheme.space28,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal:
                                                          AppTheme.space24,
                                                    ),
                                                child:
                                                    widget.reportHeading ??
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        ReportCompanyHeader(
                                                          companyName: widget
                                                              .companyName,
                                                        ),
                                                        const SizedBox(
                                                          height:
                                                              AppTheme.space12,
                                                        ),
                                                        ReportTitleSection(
                                                          title:
                                                              widget
                                                                  .contentTitle ??
                                                              widget
                                                                  .reportTitle,
                                                          subtitle:
                                                              widget
                                                                  .contentSubtitle ??
                                                              widget.dateLabel,
                                                        ),
                                                      ],
                                                    ),
                                              ),
                                              const SizedBox(
                                                height: AppTheme.space24,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ];
                                  },
                                  body: _buildReportBody(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ReportNavigationSidebar(
                  isOpen: _isNavigationOpen,
                  currentCategory: widget.currentNavigationCategory,
                  currentReportName: widget.currentNavigationReport,
                  onSelectReport: _handleReportSelection,
                  onClose: _closeNavigationPanel,
                ),
                ReportHistoryPanel(
                  isOpen: _isHistoryOpen,
                  onClose: _closeHistoryPanel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportHeaderShell extends StatelessWidget {
  final String categoryLabel;
  final String title;
  final String dateLabel;
  final Widget toolbar;
  final VoidCallback? onLeadingPressed;

  const _ReportHeaderShell({
    required this.categoryLabel,
    required this.title,
    required this.dateLabel,
    required this.toolbar,
    this.onLeadingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space12,
        AppTheme.space16,
        AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ReportIconActionButton(
            icon: Icons.menu,
            onPressed: onLeadingPressed,
            tooltip: 'Menu',
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryLabel,
                  style: AppTheme.metaHelper.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.space2),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppTheme.space10,
                  runSpacing: AppTheme.space4,
                  children: [
                    Text(title, style: AppTheme.pageTitle),
                    if (dateLabel.isNotEmpty) ...[
                      Icon(
                        Icons.circle,
                        size: AppTheme.space10,
                        color: AppTheme.textSecondary,
                      ),
                      Text(
                        dateLabel,
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: toolbar),
          ),
        ],
      ),
    );
  }
}
