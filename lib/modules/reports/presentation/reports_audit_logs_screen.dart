import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  static const List<int> _pageSizeOptions = [10, 25, 50, 100, 200];
  static const Set<String> _validActions = {
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
  };

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _requestIdController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();

  late final List<_AuditFilterNode> _moduleTree = _buildModuleTree();
  late final Map<String, _AuditModuleMeta> _tableMetaLookup =
      _buildTableMetaLookup(_moduleTree);

  final Set<String> _expandedNodeKeys = <String>{'items', 'accountant'};
  final Set<String> _selectedActions = <String>{};

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedScope = 'all';
  String? _selectedNodeKey;
  DateTime? _fromDate;
  DateTime? _toDate;

  int _page = 1;
  int _pageSize = 100;
  int _total = 0;

  List<Map<String, dynamic>> _logs = const [];
  Map<String, dynamic> _summary = const {};
  Map<String, dynamic>? _selectedLog;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _requestIdController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Audit Logs',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Container(
        color: AppTheme.bgLight,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space24,
          AppTheme.space12,
          AppTheme.space24,
          AppTheme.space24,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxWidth < 1320;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: isCompact ? 280 : 320,
                    child: _buildModulePanel(context),
                  ),
                  Container(width: 1, color: AppTheme.borderColor),
                  Expanded(child: _buildContentPanel(context, isCompact)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModulePanel(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.sidebarColor,
                  AppTheme.sidebarColor.withValues(alpha: 0.92),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.history,
                    color: Colors.white,
                    size: AppTheme.iconSizeLarge,
                  ),
                ),
                const SizedBox(height: AppTheme.space14),
                Text(
                  'Activity Explorer',
                  style: AppTheme.pageTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Track changes across every module from one audit timeline.',
                  style: AppTheme.bodyText.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space16,
              0,
            ),
            child: Wrap(
              spacing: AppTheme.space10,
              runSpacing: AppTheme.space10,
              children: [
                _buildScopeCard(
                  title: 'All Logs',
                  subtitle: 'Everything in one timeline',
                  icon: LucideIcons.database,
                  scope: 'all',
                ),
                _buildScopeCard(
                  title: 'Recent',
                  subtitle: 'Hot table activity',
                  icon: LucideIcons.clock3,
                  scope: 'recent',
                ),
                _buildScopeCard(
                  title: 'Archived',
                  subtitle: 'Older retained history',
                  icon: LucideIcons.archive,
                  scope: 'archived',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space18,
              AppTheme.space18,
              AppTheme.space20,
              AppTheme.space6,
            ),
            child: Text(
              'Modules and Submodules',
              style: AppTheme.sectionHeader.copyWith(fontSize: 14),
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space12,
                  0,
                  AppTheme.space12,
                  AppTheme.space20,
                ),
                children: _moduleTree
                    .map((node) => _buildModuleNode(node, depth: 0))
                    .toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.space10),
                Expanded(
                  child: Text(
                    '${_logs.length} visible rows loaded in this page',
                    style: AppTheme.metaHelper.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String scope,
  }) {
    final bool isSelected = _selectedScope == scope;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (_selectedScope == scope) return;
        setState(() {
          _selectedScope = scope;
          _page = 1;
        });
        _loadLogs();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 132,
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.infoBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
            ),
            const SizedBox(height: AppTheme.space10),
            Text(title, style: AppTheme.sectionHeader.copyWith(fontSize: 13)),
            const SizedBox(height: AppTheme.space4),
            Text(
              subtitle,
              style: AppTheme.captionText.copyWith(
                color: isSelected ? AppTheme.textSecondary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleNode(_AuditFilterNode node, {required int depth}) {
    final bool isExpanded = _expandedNodeKeys.contains(node.key);
    final bool isSelected = _selectedNodeKey == node.key;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 12 + (depth * 14),
            right: 12,
            top: 2,
            bottom: 2,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _onNodeSelected(node),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space10,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.24),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    node.icon,
                    size: 18,
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : AppTheme.textPrimary,
                  ),
                  const SizedBox(width: AppTheme.space10),
                  Expanded(
                    child: Text(
                      node.title,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.textPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (node.children.isNotEmpty)
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedNodeKeys.remove(node.key);
                          } else {
                            _expandedNodeKeys.add(node.key);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          isExpanded
                              ? LucideIcons.chevronDown
                              : LucideIcons.chevronRight,
                          size: 16,
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          ...node.children.map(
            (child) => _buildModuleNode(child, depth: depth + 1),
          ),
      ],
    );
  }

  Widget _buildContentPanel(BuildContext context, bool isCompact) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space20,
            AppTheme.space20,
            AppTheme.space20,
            AppTheme.space16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
            ),
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(isCompact),
              const SizedBox(height: AppTheme.space14),
              _buildSummaryCards(isCompact),
              const SizedBox(height: AppTheme.space12),
              _buildFilterBar(isCompact),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorState()
              : _buildDataRegion(isCompact),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(bool isCompact) {
    final selectedNode = _selectedNode;
    final scopeLabel = switch (_selectedScope) {
      'recent' => 'Recent',
      'archived' => 'Archived',
      _ => 'All',
    };

    final Widget intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Audit Timeline', style: AppTheme.pageTitle),
        const SizedBox(height: AppTheme.space6),
        Text(
          selectedNode == null
              ? '$scopeLabel activity across all modules'
              : '$scopeLabel activity for ${selectedNode.title}',
          style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );

    final Widget actions = Wrap(
      spacing: AppTheme.space10,
      runSpacing: AppTheme.space10,
      children: [
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _resetFilters,
          icon: const Icon(LucideIcons.rotateCcw, size: 16),
          label: const Text('Reset'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _loadLogs,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
          ),
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          label: const Text('Refresh'),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          intro,
          const SizedBox(height: AppTheme.space16),
          actions,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: intro),
        actions,
      ],
    );
  }

  Widget _buildSummaryCards(bool isCompact) {
    final cards = <Widget>[
      _buildSummaryCard(
        title: 'Visible',
        value: '${_summaryValue('visibleItems')}',
        icon: LucideIcons.list,
        color: AppTheme.primaryBlue,
      ),
      _buildSummaryCard(
        title: 'Inserted',
        value: '${_summaryValue('insertCount')}',
        icon: LucideIcons.plus,
        color: AppTheme.accentGreen,
      ),
      _buildSummaryCard(
        title: 'Updated',
        value: '${_summaryValue('updateCount')}',
        icon: LucideIcons.pencil,
        color: AppTheme.primaryBlueDark,
      ),
      _buildSummaryCard(
        title: 'Deleted',
        value: '${_summaryValue('deleteCount')}',
        icon: LucideIcons.trash2,
        color: AppTheme.errorRed,
      ),
      _buildSummaryCard(
        title: 'Archived',
        value: '${_summaryValue('archivedCount')}',
        icon: LucideIcons.archive,
        color: AppTheme.warningOrange,
      ),
    ];

    return Wrap(
      spacing: AppTheme.space10,
      runSpacing: AppTheme.space10,
      children: isCompact
          ? cards
          : cards.map((card) => SizedBox(width: 172, child: card)).toList(),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.captionText),
                const SizedBox(height: AppTheme.space4),
                Text(
                  value,
                  style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppTheme.space12,
          runSpacing: AppTheme.space10,
          children: [
            SizedBox(
              width: isCompact ? 240 : 260,
              child: CustomTextField(
                controller: _searchController,
                hintText: 'Search table, actor, action or record',
                prefixIcon: LucideIcons.search,
                forceUppercase: false,
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            SizedBox(
              width: isCompact ? 210 : 220,
              child: CustomTextField(
                controller: _requestIdController,
                hintText: 'Request ID',
                prefixIcon: LucideIcons.fingerprint,
                forceUppercase: false,
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            SizedBox(
              width: isCompact ? 170 : 180,
              child: CustomTextField(
                controller: _sourceController,
                hintText: 'Source',
                prefixIcon: LucideIcons.radioTower,
                forceUppercase: false,
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            _buildDateButton(
              label: _fromDate == null
                  ? 'From date'
                  : DateFormat('dd MMM yyyy').format(_fromDate!),
              icon: LucideIcons.calendarDays,
              onTap: () => _pickDate(isFromDate: true),
            ),
            _buildDateButton(
              label: _toDate == null
                  ? 'To date'
                  : DateFormat('dd MMM yyyy').format(_toDate!),
              icon: LucideIcons.calendarRange,
              onTap: () => _pickDate(isFromDate: false),
            ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 42),
              ),
              icon: const Icon(LucideIcons.filter, size: 16),
              label: const Text('Apply'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space10),
        Wrap(
          spacing: AppTheme.space10,
          runSpacing: AppTheme.space8,
          children: _validActions
              .map(
                (action) => FilterChip(
                  selected: _selectedActions.contains(action),
                  showCheckmark: false,
                  label: Text(action),
                  side: const BorderSide(color: AppTheme.borderColor),
                  labelStyle: AppTheme.metaHelper.copyWith(
                    color: _selectedActions.contains(action)
                        ? AppTheme.primaryBlue
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.infoBg,
                  onSelected: (_) {
                    setState(() {
                      if (_selectedActions.contains(action)) {
                        _selectedActions.remove(action);
                      } else {
                        _selectedActions.add(action);
                      }
                    });
                    _applyFilters();
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        side: const BorderSide(color: AppTheme.borderColor),
        foregroundColor: AppTheme.textPrimary,
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.alertTriangle,
              size: 40,
              color: AppTheme.warningOrange,
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              'Unable to load audit logs',
              style: AppTheme.sectionHeader.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              _errorMessage!,
              style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space16),
            ElevatedButton(
              onPressed: _loadLogs,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRegion(bool isCompact) {
    if (_logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.infoBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.searchX,
                  color: AppTheme.primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                'No audit logs found',
                style: AppTheme.sectionHeader.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                'Try widening your filters or switching the module scope.',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isCompact) {
      return Column(
        children: [
          Expanded(flex: 5, child: _buildTableSection()),
          Container(height: 1, color: AppTheme.borderColor),
          Expanded(flex: 4, child: _buildInspectorSection()),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 8, child: _buildTableSection()),
        Container(width: 1, color: AppTheme.borderColor),
        Expanded(flex: 3, child: _buildInspectorSection()),
      ],
    );
  }

  Widget _buildTableSection() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1040,
              child: Column(
                children: [
                  _buildTableHeader(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _logs.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppTheme.borderColor),
                      itemBuilder: (context, index) =>
                          _buildTableRow(_logs[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildPaginationBar(),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: AppTheme.tableHeaderBg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      child: DefaultTextStyle(
        style: AppTheme.tableHeader.copyWith(fontSize: 12, letterSpacing: 0.2),
        child: const Row(
          children: [
            SizedBox(width: 142, child: Text('Time')),
            SizedBox(width: 126, child: Text('Module')),
            SizedBox(width: 156, child: Text('Section')),
            SizedBox(width: 120, child: Text('Action')),
            SizedBox(width: 126, child: Text('Actor')),
            SizedBox(width: 180, child: Text('Request ID')),
            SizedBox(width: 110, child: Text('Scope')),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> log) {
    final bool isSelected =
        _selectedLog != null && _selectedLog!['id'] == log['id'];
    final String action = (log['action']?.toString() ?? '').toUpperCase();
    final _AuditModuleMeta meta = _resolveMeta(log);
    final bool isArchived = log['archived_at'] != null;
    final String createdAt = _formatTimestamp(log['created_at']?.toString());
    final String actor = _stringValue(log['actor_name'], fallback: 'system');
    final String requestId = _stringValue(log['request_id'], fallback: '--');

    return InkWell(
      onTap: () => setState(() => _selectedLog = log),
      child: Container(
        color: isSelected ? AppTheme.selectionActiveBg : Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space14,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 142,
              child: Text(createdAt, style: AppTheme.tableCell),
            ),
            SizedBox(
              width: 126,
              child: Text(meta.moduleLabel, style: AppTheme.tableCell),
            ),
            SizedBox(
              width: 156,
              child: Text(meta.sectionLabel, style: AppTheme.tableCell),
            ),
            SizedBox(width: 120, child: _buildActionBadge(action)),
            SizedBox(width: 126, child: Text(actor, style: AppTheme.tableCell)),
            SizedBox(
              width: 180,
              child: Text(
                requestId,
                style: AppTheme.tableCell.copyWith(
                  color: requestId == '--'
                      ? AppTheme.textMuted
                      : AppTheme.textPrimary,
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: _buildScopeBadge(isArchived ? 'Archived' : 'Recent'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBadge(String action) {
    final (Color color, Color bg) = switch (action) {
      'INSERT' => (AppTheme.accentGreen, AppTheme.successBg),
      'UPDATE' => (AppTheme.primaryBlue, AppTheme.infoBg),
      'DELETE' => (AppTheme.errorRed, const Color(0xFFFEE2E2)),
      'TRUNCATE' => (AppTheme.warningOrange, const Color(0xFFFFF7ED)),
      _ => (AppTheme.textSecondary, AppTheme.selectionInactiveBg),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space10,
          vertical: AppTheme.space6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          action.isEmpty ? '--' : action,
          style: AppTheme.metaHelper.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildScopeBadge(String label) {
    final bool isArchived = label == 'Archived';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space10,
          vertical: AppTheme.space6,
        ),
        decoration: BoxDecoration(
          color: isArchived
              ? const Color(0xFFFFF7ED)
              : AppTheme.selectionInactiveBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTheme.metaHelper.copyWith(
            color: isArchived ? AppTheme.warningOrange : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    final int start = _logs.isEmpty ? 0 : ((_page - 1) * _pageSize) + 1;
    final int end = _logs.isEmpty ? 0 : start + _logs.length - 1;
    final int totalPages = _total == 0 ? 1 : (_total / _pageSize).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Text('Showing $start-$end of $_total', style: AppTheme.metaHelper),
          const Spacer(),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _pageSize,
                items: _pageSizeOptions
                    .map(
                      (size) => DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size per page'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null || value == _pageSize) return;
                  setState(() {
                    _pageSize = value;
                    _page = 1;
                  });
                  _loadLogs();
                },
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          IconButton(
            onPressed: _page > 1 && !_isLoading
                ? () {
                    setState(() => _page -= 1);
                    _loadLogs();
                  }
                : null,
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          Text('$_page / $totalPages', style: AppTheme.metaHelper),
          IconButton(
            onPressed: _page < totalPages && !_isLoading
                ? () {
                    setState(() => _page += 1);
                    _loadLogs();
                  }
                : null,
            icon: const Icon(LucideIcons.chevronRight),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorSection() {
    final log = _selectedLog;
    if (log == null) {
      return Container(
        color: AppTheme.bgLight,
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.panelRightOpen,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Text('Select a log entry', style: AppTheme.sectionHeader),
              const SizedBox(height: AppTheme.space8),
              Text(
                'The change details, old values, new values, and metadata will appear here.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final meta = _resolveMeta(log);
    final List<dynamic> changedColumns =
        (log['changed_columns'] as List<dynamic>? ?? const <dynamic>[]);

    return Container(
      color: AppTheme.bgLight,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Entry Inspector',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                  ),
                ),
                _buildActionBadge(
                  _stringValue(log['action'], fallback: '--').toUpperCase(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInspectorMeta(title: 'Module', value: meta.moduleLabel),
                  _buildInspectorMeta(
                    title: 'Section',
                    value: meta.sectionLabel,
                  ),
                  _buildInspectorMeta(
                    title: 'Table',
                    value: _stringValue(log['table_name'], fallback: '--'),
                  ),
                  _buildInspectorMeta(
                    title: 'Actor',
                    value: _stringValue(log['actor_name'], fallback: 'system'),
                  ),
                  _buildInspectorMeta(
                    title: 'Record',
                    value: _stringValue(log['record_pk'], fallback: '--'),
                  ),
                  _buildInspectorMeta(
                    title: 'Source',
                    value: _stringValue(log['source'], fallback: 'system'),
                  ),
                  _buildInspectorMeta(
                    title: 'Request ID',
                    value: _stringValue(log['request_id'], fallback: '--'),
                  ),
                  _buildInspectorMeta(
                    title: 'Created At',
                    value: _formatTimestamp(log['created_at']?.toString()),
                  ),
                  const SizedBox(height: AppTheme.space14),
                  Text('Changed Columns', style: AppTheme.sectionHeader),
                  const SizedBox(height: AppTheme.space10),
                  changedColumns.isEmpty
                      ? Text(
                          'No field diff available',
                          style: AppTheme.metaHelper,
                        )
                      : Wrap(
                          spacing: AppTheme.space8,
                          runSpacing: AppTheme.space8,
                          children: changedColumns
                              .map(
                                (column) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.space10,
                                    vertical: AppTheme.space6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    column.toString(),
                                    style: AppTheme.metaHelper.copyWith(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                  const SizedBox(height: AppTheme.space18),
                  _buildJsonCard(
                    title: 'Old Values',
                    value: _prettyJson(log['old_values']),
                  ),
                  const SizedBox(height: AppTheme.space14),
                  _buildJsonCard(
                    title: 'New Values',
                    value: _prettyJson(log['new_values']),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorMeta({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              title,
              style: AppTheme.metaHelper.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(value, style: AppTheme.bodyText.copyWith(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonCard({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.sectionHeader),
        const SizedBox(height: AppTheme.space8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space14),
              child: SelectableText(
                value,
                style: AppTheme.metaHelper.copyWith(
                  fontFamily: 'monospace',
                  height: 1.5,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _AuditFilterNode? get _selectedNode => _selectedNodeKey == null
      ? null
      : _findNodeByKey(_moduleTree, _selectedNodeKey!);

  void _onNodeSelected(_AuditFilterNode node) {
    setState(() {
      if (_selectedNodeKey == node.key) {
        _selectedNodeKey = null;
      } else {
        _selectedNodeKey = node.key;
      }
      _page = 1;
    });
    _loadLogs();
  }

  Future<void> _pickDate({required bool isFromDate}) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = (isFromDate ? _fromDate : _toDate) ?? now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;

    setState(() {
      if (isFromDate) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  void _applyFilters() {
    setState(() => _page = 1);
    _loadLogs();
  }

  void _resetFilters() {
    _searchController.clear();
    _requestIdController.clear();
    _sourceController.clear();
    setState(() {
      _selectedScope = 'all';
      _selectedNodeKey = null;
      _selectedActions.clear();
      _fromDate = null;
      _toDate = null;
      _page = 1;
    });
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(reportsRepositoryProvider);
      final response = await repo.getAuditLogs(
        page: _page,
        pageSize: _pageSize,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        requestId: _requestIdController.text.trim().isEmpty
            ? null
            : _requestIdController.text.trim(),
        source: _sourceController.text.trim().isEmpty
            ? null
            : _sourceController.text.trim(),
        actions: _selectedActions.isEmpty ? null : _selectedActions.toList(),
        tables: _selectedNode?.allTables.isEmpty ?? true
            ? null
            : _selectedNode!.allTables,
        fromDate: _fromDate == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_fromDate!),
        toDate: _toDate == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_toDate!),
        scope: _selectedScope == 'all' ? null : _selectedScope,
      );

      final payload = _unwrapPayload(response);
      final List<Map<String, dynamic>> items =
          (payload['items'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
      final Map<String, dynamic> summary = Map<String, dynamic>.from(
        payload['summary'] as Map? ?? const {},
      );
      final int total = (payload['total'] as num?)?.toInt() ?? items.length;

      setState(() {
        _logs = items;
        _summary = summary;
        _total = total;
        _selectedLog = items.isEmpty
            ? null
            : items.firstWhere(
                (item) => item['id'] == _selectedLog?['id'],
                orElse: () => items.first,
              );
      });
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> response) {
    final dynamic data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  int _summaryValue(String key) {
    return (_summary[key] as num?)?.toInt() ?? 0;
  }

  String _formatTimestamp(String? value) {
    final DateTime? parsed = value == null ? null : DateTime.tryParse(value);
    if (parsed == null) return '--';
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
  }

  String _stringValue(dynamic value, {required String fallback}) {
    final String normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  String _prettyJson(dynamic value) {
    if (value == null) return 'No data';
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  _AuditFilterNode? _findNodeByKey(List<_AuditFilterNode> nodes, String key) {
    for (final node in nodes) {
      if (node.key == key) return node;
      final child = _findNodeByKey(node.children, key);
      if (child != null) return child;
    }
    return null;
  }

  _AuditModuleMeta _resolveMeta(Map<String, dynamic> log) {
    final String tableName = _stringValue(log['table_name'], fallback: '--');
    return _tableMetaLookup[tableName] ??
        _AuditModuleMeta(moduleLabel: 'System', sectionLabel: tableName);
  }

  List<_AuditFilterNode> _buildModuleTree() {
    return [
      _AuditFilterNode(
        key: 'system',
        title: 'System',
        icon: LucideIcons.home,
        tables: const ['organization', 'currencies', 'countries', 'states'],
        children: const [
          _AuditFilterNode(
            key: 'system-activity',
            title: 'Activity',
            icon: LucideIcons.activity,
            tables: ['transactional_sequences', 'transaction_locks'],
          ),
        ],
      ),
      const _AuditFilterNode(
        key: 'items',
        title: 'Items',
        icon: LucideIcons.package2,
        children: [
          _AuditFilterNode(
            key: 'items-products',
            title: 'Products',
            icon: LucideIcons.box,
            tables: ['products', 'product_contents'],
          ),
          _AuditFilterNode(
            key: 'items-composite',
            title: 'Composite Items',
            icon: LucideIcons.boxes,
            tables: ['composite_items', 'composite_item_parts'],
          ),
          _AuditFilterNode(
            key: 'items-pricelists',
            title: 'Price Lists',
            icon: LucideIcons.indianRupee,
            tables: [
              'price_lists',
              'price_list_items',
              'price_list_volume_ranges',
            ],
          ),
          _AuditFilterNode(
            key: 'items-masters',
            title: 'Masters',
            icon: LucideIcons.folderKanban,
            tables: [
              'categories',
              'brands',
              'manufacturers',
              'buying_rules',
              'schedules',
              'contents',
              'strengths',
              'units',
              'uqc',
              'storage_locations',
              'racks',
              'reorder_terms',
              'item_vendor_mappings',
            ],
          ),
        ],
      ),
      const _AuditFilterNode(
        key: 'inventory',
        title: 'Inventory',
        icon: LucideIcons.warehouse,
        tables: ['outlet_inventory', 'batches', 'warehouses'],
      ),
      const _AuditFilterNode(
        key: 'sales',
        title: 'Sales',
        icon: LucideIcons.shoppingCart,
        children: [
          _AuditFilterNode(
            key: 'sales-customers',
            title: 'Customers',
            icon: LucideIcons.users,
            tables: ['customers', 'customer_contact_persons'],
          ),
          _AuditFilterNode(
            key: 'sales-documents',
            title: 'Sales Documents',
            icon: LucideIcons.fileBarChart2,
            tables: [
              'sales_orders',
              'sales_payments',
              'sales_payment_links',
              'sales_eway_bills',
            ],
          ),
        ],
      ),
      const _AuditFilterNode(
        key: 'purchases',
        title: 'Purchases',
        icon: LucideIcons.truck,
        children: [
          _AuditFilterNode(
            key: 'purchases-vendors',
            title: 'Vendors',
            icon: LucideIcons.contact2,
            tables: [
              'vendors',
              'vendor_contact_persons',
              'vendor_bank_accounts',
            ],
          ),
        ],
      ),
      const _AuditFilterNode(
        key: 'accountant',
        title: 'Accountant',
        icon: LucideIcons.landmark,
        children: [
          _AuditFilterNode(
            key: 'accountant-accounts',
            title: 'Accounts',
            icon: LucideIcons.wallet,
            tables: ['accounts', 'account_transactions'],
          ),
          _AuditFilterNode(
            key: 'accountant-manual-journals',
            title: 'Manual Journals',
            icon: LucideIcons.receipt,
            tables: [
              'accounts_manual_journals',
              'accounts_manual_journal_items',
              'accounts_manual_journal_attachments',
              'accounts_manual_journal_tag_mappings',
            ],
          ),
          _AuditFilterNode(
            key: 'accountant-recurring-journals',
            title: 'Recurring Journals',
            icon: LucideIcons.repeat2,
            tables: [
              'accounts_recurring_journals',
              'accounts_recurring_journal_items',
            ],
          ),
          _AuditFilterNode(
            key: 'accountant-templates',
            title: 'Journal Templates',
            icon: LucideIcons.folderOpen,
            tables: [
              'accounts_journal_templates',
              'accounts_journal_template_items',
            ],
          ),
          _AuditFilterNode(
            key: 'accountant-settings',
            title: 'Controls and Settings',
            icon: LucideIcons.settings2,
            tables: [
              'accounts_journal_number_settings',
              'accounts_fiscal_years',
              'accounts_reporting_tags',
              'transaction_locks',
            ],
          ),
        ],
      ),
      const _AuditFilterNode(
        key: 'tax-compliance',
        title: 'Tax and Compliance',
        icon: LucideIcons.badgePercent,
        tables: [
          'associate_taxes',
          'tax_groups',
          'tax_group_taxes',
          'tds_sections',
          'tds_rates',
          'tds_groups',
          'tds_group_items',
        ],
      ),
    ];
  }

  Map<String, _AuditModuleMeta> _buildTableMetaLookup(
    List<_AuditFilterNode> nodes, {
    String? moduleLabel,
  }) {
    final lookup = <String, _AuditModuleMeta>{};

    for (final node in nodes) {
      final String resolvedModule = moduleLabel ?? node.title;
      final String sectionLabel = moduleLabel == null ? node.title : node.title;

      for (final table in node.tables) {
        lookup[table] = _AuditModuleMeta(
          moduleLabel: resolvedModule,
          sectionLabel: sectionLabel,
        );
      }

      lookup.addAll(
        _buildTableMetaLookup(
          node.children,
          moduleLabel: moduleLabel ?? node.title,
        ),
      );
    }

    return lookup;
  }
}

class _AuditFilterNode {
  final String key;
  final String title;
  final IconData icon;
  final List<String> tables;
  final List<_AuditFilterNode> children;

  const _AuditFilterNode({
    required this.key,
    required this.title,
    required this.icon,
    this.tables = const [],
    this.children = const [],
  });

  List<String> get allTables => <String>{...tables, ..._childTables}.toList();

  List<String> get _childTables =>
      children.expand((child) => child.allTables).toSet().toList();
}

class _AuditModuleMeta {
  final String moduleLabel;
  final String sectionLabel;

  const _AuditModuleMeta({
    required this.moduleLabel,
    required this.sectionLabel,
  });
}
