import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
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
  final GlobalKey _fromDateButtonKey = GlobalKey();
  final GlobalKey _toDateButtonKey = GlobalKey();

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
  bool _isLeftPanelCollapsed = false;

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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: _isLeftPanelCollapsed ? 56 : (isCompact ? 280 : 320),
                    child: _buildModulePanel(context),
                  ),
                  if (!_isLeftPanelCollapsed)
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
    if (_isLeftPanelCollapsed) {
      return Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.space12),
            IconButton(
              tooltip: 'Expand filters',
              onPressed: () {
                setState(() => _isLeftPanelCollapsed = false);
              },
              icon: const Icon(LucideIcons.panelLeftOpen),
            ),
            const SizedBox(height: AppTheme.space8),
            const Icon(
              LucideIcons.history,
              size: 18,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      );
    }

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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space12,
              AppTheme.space12,
              AppTheme.space12,
              0,
            ),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  tooltip: 'Collapse filters',
                  onPressed: () {
                    setState(() => _isLeftPanelCollapsed = true);
                  },
                  icon: const Icon(LucideIcons.panelLeftClose),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space4,
              AppTheme.space16,
              0,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = AppTheme.space10;
                final cardWidth = ((constraints.maxWidth - spacing) / 2).clamp(
                  120.0,
                  220.0,
                );
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildScopeCard(
                        title: 'All Logs',
                        subtitle: 'Everything in one timeline',
                        icon: LucideIcons.database,
                        scope: 'all',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildScopeCard(
                        title: 'Recent',
                        subtitle: 'Hot table activity',
                        icon: LucideIcons.clock3,
                        scope: 'recent',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildScopeCard(
                        title: 'Archived',
                        subtitle: 'Older retained history',
                        icon: LucideIcons.archive,
                        scope: 'archived',
                      ),
                    ),
                  ],
                );
              },
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
        width: double.infinity,
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
              targetKey: _fromDateButtonKey,
              label: _fromDate == null
                  ? 'From date'
                  : DateFormat('dd MMM yyyy').format(_fromDate!),
              icon: LucideIcons.calendarDays,
              onTap: () => _pickDate(isFromDate: true),
            ),
            _buildDateButton(
              targetKey: _toDateButtonKey,
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
    required GlobalKey targetKey,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      key: targetKey,
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
    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1320,
                child: Column(
                  children: [
                    _buildTableHeader(),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _logs.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppTheme.borderColor,
                        ),
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
      ),
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
            SizedBox(width: 220, child: Text('Record')),
            SizedBox(width: 260, child: Text('Details')),
            SizedBox(width: 120, child: Text('Action')),
            SizedBox(width: 126, child: Text('Actor')),
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
    final String recordName = _resolveAuditRecordName(log);
    final String detailText = _resolveAuditRowSummary(log);

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
            SizedBox(
              width: 220,
              child: Text(
                recordName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tableCell.copyWith(
                  color: recordName == '--'
                      ? AppTheme.textMuted
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 260,
              child: Text(
                detailText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tableCell.copyWith(
                  color: detailText == '--'
                      ? AppTheme.textMuted
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            SizedBox(width: 120, child: _buildActionBadge(action)),
            SizedBox(width: 126, child: Text(actor, style: AppTheme.tableCell)),
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
      'DELETE' => (AppTheme.errorRed, AppTheme.errorBgBorder),
      'TRUNCATE' => (AppTheme.warningOrange, AppTheme.warningBg),
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
              ? AppTheme.warningBg
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
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.white,
                highlightColor: Colors.white,
                hoverColor: Colors.white,
                splashColor: Colors.transparent,
                focusColor: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _pageSize,
                  dropdownColor: Colors.white,
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
    final List<String> readableChanges = _describeAuditChanges(log);

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
                    title: 'Record',
                    value: _resolveAuditRecordName(log),
                  ),
                  _buildInspectorMeta(
                    title: 'Details',
                    value: _resolveAuditRowSummary(log),
                  ),
                  _buildInspectorMeta(
                    title: 'Actor',
                    value: _stringValue(log['actor_name'], fallback: 'system'),
                  ),
                  _buildInspectorMeta(
                    title: 'Source',
                    value: _stringValue(log['source'], fallback: 'system'),
                  ),
                  _buildInspectorMeta(
                    title: 'Created At',
                    value: _formatTimestamp(log['created_at']?.toString()),
                  ),
                  const SizedBox(height: AppTheme.space14),
                  Text('Changes', style: AppTheme.sectionHeader),
                  const SizedBox(height: AppTheme.space10),
                  if (readableChanges.isEmpty)
                    Text(
                      'No readable field changes available.',
                      style: AppTheme.metaHelper,
                    )
                  else
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: readableChanges
                            .map(
                              (change) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppTheme.space14,
                                  AppTheme.space10,
                                  AppTheme.space14,
                                  AppTheme.space10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.space10),
                                    Expanded(
                                      child: Text(
                                        change,
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (changedColumns.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.space16),
                    Text('Touched Fields', style: AppTheme.sectionHeader),
                    const SizedBox(height: AppTheme.space10),
                    Wrap(
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
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Text(
                                _auditFieldLabel(column.toString()),
                                style: AppTheme.metaHelper.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
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

    final DateTime? picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 2),
      targetKey: isFromDate ? _fromDateButtonKey : _toDateButtonKey,
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

  String _resolveAuditRecordName(Map<String, dynamic> log) {
    final Map<String, dynamic> oldValues =
        log['old_values'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(log['old_values'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final Map<String, dynamic> newValues =
        log['new_values'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(log['new_values'] as Map<String, dynamic>)
        : <String, dynamic>{};

    String? pickValue(Map<String, dynamic> values, List<String> keys) {
      for (final key in keys) {
        final raw = values[key];
        if (raw == null) continue;
        final text = raw.toString().trim();
        if (text.isEmpty ||
            text.toLowerCase() == 'null' ||
            _looksLikeUuid(text)) {
          continue;
        }
        return text;
      }
      return null;
    }

    final candidates = <String?>[
      pickValue(newValues, const [
        'product_name',
        'display_name',
        'company_name',
        'name',
        'buying_rule',
        'shedule_name',
        'location_name',
        'batch',
        'tag_name',
        'group_name',
        'journal_number',
      ]),
      pickValue(oldValues, const [
        'product_name',
        'display_name',
        'company_name',
        'name',
        'buying_rule',
        'shedule_name',
        'location_name',
        'batch',
        'tag_name',
        'group_name',
        'journal_number',
      ]),
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return '--';
  }

  String _resolveAuditRowSummary(Map<String, dynamic> log) {
    final changes = _describeAuditChanges(log);
    if (changes.isNotEmpty) {
      return changes.first;
    }
    return '--';
  }

  List<String> _describeAuditChanges(Map<String, dynamic> log) {
    final Map<String, dynamic> oldValues =
        log['old_values'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(log['old_values'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final Map<String, dynamic> newValues =
        log['new_values'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(log['new_values'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final List<String> fields =
        (log['changed_columns'] as List<dynamic>? ?? const <dynamic>[])
            .map((value) => value.toString())
            .toList();
    final Iterable<String> effectiveFields = fields.isNotEmpty
        ? fields
        : newValues.keys.where((key) => !_auditIsHiddenField(key));

    final changes = <String>[];
    for (final field in effectiveFields) {
      final description = _describeAuditFieldChange(
        field,
        oldValues[field],
        newValues[field],
        _stringValue(log['action'], fallback: '').toUpperCase(),
      );
      if (description != null && description.trim().isNotEmpty) {
        changes.add(description);
      }
    }
    return changes;
  }

  String? _describeAuditFieldChange(
    String field,
    dynamic oldValue,
    dynamic newValue,
    String action,
  ) {
    final label = _auditFieldLabel(field);
    final previous = _auditDisplayValue(field, oldValue);
    final next = _auditDisplayValue(field, newValue);

    if (_auditUsesGenericMessage(field)) {
      if (next == null && previous == null) {
        return '$label updated';
      }
      if (next == null) {
        return '$label cleared';
      }
      if (previous == null) {
        return action == 'INSERT' ? '$label set to $next' : '$label set';
      }
      if (previous != next) {
        return '$label changed from $previous to $next';
      }
      return '$label updated';
    }

    if (previous == next) {
      return next == null ? null : '$label updated';
    }
    if (previous == null && next != null) {
      return '$label set to $next';
    }
    if (previous != null && next == null) {
      return '$label cleared';
    }
    if (previous != null && next != null) {
      return '$label changed from $previous to $next';
    }
    return null;
  }

  String _auditFieldLabel(String field) {
    const labels = <String, String>{
      'buying_rule_id': 'Buying Rule',
      'schedule_of_drug_id': 'Schedule of Drug',
      'shedule_id': 'Schedule of Drug',
      'storage_id': 'Storage',
      'rack_id': 'Rack',
      'manufacturer_id': 'Manufacturer / Patent',
      'brand_id': 'Brand',
      'category_id': 'Category',
      'unit_id': 'Unit',
      'preferred_vendor_id': 'Preferred Vendor',
      'sales_account_id': 'Sales Account',
      'purchase_account_id': 'Purchase Account',
      'inventory_account_id': 'Inventory Account',
      'image_urls': 'Images',
      'faq_text': 'FAQ',
      'side_effects': 'Side Effects',
      'track_assoc_ingredients': 'Track Active Ingredients',
      'track_bin_location': 'Track Bin Location',
      'track_serial_number': 'Track Serial Number',
      'track_batches': 'Track Batches',
      'inventory_valuation_method': 'Inventory Valuation Method',
      'reorder_point': 'Reorder Point',
      'display_order': 'Display Order',
      'content_id': 'Content',
      'strength_id': 'Strength',
      'warehouse_id': 'Warehouse',
      'opening_stock': 'Opening Stock',
      'opening_stock_value': 'Opening Stock Value',
      'accounting_stock': 'Accounting Stock',
      'physical_stock': 'Physical Stock',
      'committed_stock': 'Committed Stock',
      'variance_qty': 'Variance Quantity',
      'batch': 'Batch Reference',
      'manufacture_batch_number': 'Manufacturer Batch',
      'exp': 'Expiry Date',
      'manufacture_exp': 'Manufactured Date',
    };
    final mapped = labels[field];
    if (mapped != null) {
      return mapped;
    }
    return field
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  bool _auditUsesGenericMessage(String field) {
    const genericFields = <String>{
      'buying_rule_id',
      'schedule_of_drug_id',
      'shedule_id',
      'storage_id',
      'rack_id',
      'manufacturer_id',
      'brand_id',
      'category_id',
      'unit_id',
      'content_id',
      'strength_id',
      'warehouse_id',
      'preferred_vendor_id',
      'sales_account_id',
      'purchase_account_id',
      'inventory_account_id',
      'intra_state_tax_id',
      'inter_state_tax_id',
      'reorder_term_id',
      'image_urls',
      'faq_text',
      'side_effects',
    };
    return genericFields.contains(field);
  }

  bool _auditIsHiddenField(String field) {
    const hiddenFields = <String>{
      'id',
      'product_id',
      'item_id',
      'org_id',
      'outlet_id',
      'created_at',
      'updated_at',
      'created_by_id',
      'updated_by_id',
      'record_id',
      'request_id',
    };
    return hiddenFields.contains(field);
  }

  String? _auditDisplayValue(String field, dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      if (field == 'is_active') {
        return value ? 'Active' : 'Inactive';
      }
      return value ? 'Enabled' : 'Disabled';
    }
    if (value is num) {
      return value.toString();
    }
    if (value is List) {
      final nonEmpty = value
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList();
      if (nonEmpty.isEmpty) {
        return 'empty';
      }
      return nonEmpty.every(_looksLikeUuid) ? null : nonEmpty.join(', ');
    }
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    if (_looksLikeUuid(text)) {
      return null;
    }
    return text;
  }

  bool _looksLikeUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
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
      const _AuditFilterNode(
        key: 'all-modules',
        title: 'All Modules',
        icon: LucideIcons.layoutGrid,
      ),
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
