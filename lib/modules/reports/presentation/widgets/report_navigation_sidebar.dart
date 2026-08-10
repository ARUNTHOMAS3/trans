import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_navigation_catalog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_navigation_item.dart';

class ReportNavigationSidebar extends StatefulWidget {
  final bool isOpen;
  final String currentCategory;
  final String currentReportName;
  final void Function(String reportName, String category) onSelectReport;
  final VoidCallback onClose;

  const ReportNavigationSidebar({
    super.key,
    required this.isOpen,
    required this.currentCategory,
    required this.currentReportName,
    required this.onSelectReport,
    required this.onClose,
  });

  @override
  State<ReportNavigationSidebar> createState() => _ReportNavigationSidebarState();
}

class _ReportNavigationSidebarState extends State<ReportNavigationSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedCategories = <String>{};

  static const double _panelWidth = (AppTheme.space64 * 4) + AppTheme.space24;

  @override
  void initState() {
    super.initState();
    _expandedCategories.add(widget.currentCategory);
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(covariant ReportNavigationSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentCategory != widget.currentCategory) {
      _expandedCategories.add(widget.currentCategory);
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = Theme.of(context).shadowColor;
    final query = _searchController.text.trim().toLowerCase();

    return IgnorePointer(
      ignoring: !widget.isOpen,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: widget.isOpen ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(color: shadowColor.withValues(alpha: 0.08)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            child: AnimatedSlide(
              offset: widget.isOpen ? Offset.zero : const Offset(-1.08, 0),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: widget.isOpen ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: SizedBox(
                  width: _panelWidth,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      border: Border(
                        right: BorderSide(color: AppTheme.borderLight),
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
                            AppTheme.space12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Reports',
                                  style: AppTheme.pageTitle,
                                ),
                              ),
                              ReportIconActionButton(
                                icon: Icons.close,
                                onPressed: widget.onClose,
                                tooltip: 'Close navigation',
                                iconColor: AppTheme.errorRed,
                                chromeless: true,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search reports',
                              prefixIcon: const Icon(
                                Icons.search,
                                size: AppTheme.space16,
                                color: AppTheme.textSecondary,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space12,
                                vertical: AppTheme.space12,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.space16,
                            AppTheme.space16,
                            AppTheme.space16,
                            AppTheme.space8,
                          ),
                          child: Text(
                            'ALL REPORTS',
                            style: AppTheme.metaHelper.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            radius: const Radius.circular(AppTheme.space8),
                            thickness: AppTheme.space6,
                            child: ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                AppTheme.space12,
                                0,
                                AppTheme.space12,
                                AppTheme.space16,
                              ),
                              children: [
                                for (final category in reportNavigationCategories)
                                  ..._buildCategorySection(category, query),
                              ],
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

  List<Widget> _buildCategorySection(String category, String query) {
    final reports = reportNavigationReportsByCategory[category] ?? const <String>[];
    final filteredReports = query.isEmpty
        ? reports
        : reports.where((report) => report.toLowerCase().contains(query)).toList(growable: false);
    final categoryMatches = category.toLowerCase().contains(query);
    final hasChildren = filteredReports.isNotEmpty;
    final shouldShowCategory = query.isEmpty || categoryMatches || hasChildren;

    if (!shouldShowCategory) {
      return const <Widget>[];
    }

    final isExpanded = query.isNotEmpty ? hasChildren : _expandedCategories.contains(category);
    final isCurrentCategory = widget.currentCategory == category;
    final trailingIcon = hasChildren && isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight;

    return [
      ReportNavigationItem(
        label: category,
        selected: isCurrentCategory && widget.currentReportName.isEmpty,
        onTap: hasChildren ? () => _toggleCategory(category) : null,
        leading: Icon(
          LucideIcons.folder,
          size: AppTheme.space16,
          color: AppTheme.textDisabled,
        ),
        trailing: Icon(
          trailingIcon,
          size: AppTheme.space16,
          color: AppTheme.textSecondary,
        ),
      ),
      if (hasChildren && isExpanded)
        ...filteredReports.map(
          (reportName) => Padding(
            padding: const EdgeInsets.only(top: AppTheme.space4),
            child: ReportNavigationItem(
              label: reportName,
              selected: widget.currentReportName == reportName,
              leadingInset: AppTheme.space24,
              onTap: () => widget.onSelectReport(reportName, category),
            ),
          ),
        ),
      const SizedBox(height: AppTheme.space4),
    ];
  }
}
