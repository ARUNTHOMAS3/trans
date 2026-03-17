import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/routing/app_router.dart';
import '../models/accountant_chart_of_accounts_account_model.dart';
import '../providers/accountant_chart_of_accounts_provider.dart';
import 'widgets/accountant_chart_of_accounts_row.dart';
import 'widgets/accountant_chart_of_accounts_detail_panel.dart';
import '../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../shared/widgets/inputs/zerpai_builders.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/utils/zerpai_toast.dart';

class ChartOfAccountsPage extends ConsumerStatefulWidget {
  final String? initialAccountId;
  const ChartOfAccountsPage({super.key, this.initialAccountId});

  @override
  ConsumerState<ChartOfAccountsPage> createState() =>
      _ChartOfAccountsPageState();
}

class _ChartOfAccountsPageState extends ConsumerState<ChartOfAccountsPage> {
  bool _forceWideTable = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chartOfAccountsProvider.notifier)
          .selectAccount(widget.initialAccountId);
    });
  }

  @override
  void didUpdateWidget(ChartOfAccountsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAccountId != oldWidget.initialAccountId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(chartOfAccountsProvider.notifier)
            .selectAccount(widget.initialAccountId);
      });
    }
  }

  // LayerLinks for precision positioning
  final LayerLink _moreMenuLink = LayerLink();
  final LayerLink _sortRowLink = LayerLink();
  final LayerLink _exportRowLink = LayerLink();

  OverlayEntry? _moreMenuEntry;
  OverlayEntry? _sortMenuEntry;
  OverlayEntry? _exportMenuEntry;

  bool _isHoveringSortRow = false;
  bool _isHoveringSortMenu = false;
  bool _isHoveringExportRow = false;
  bool _isHoveringExportMenu = false;

  @override
  void dispose() {
    _closeAllMenus();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _closeAllMenus() {
    _moreMenuEntry?.remove();
    _moreMenuEntry = null;
    _sortMenuEntry?.remove();
    _sortMenuEntry = null;
    _exportMenuEntry?.remove();
    _exportMenuEntry = null;
  }

  final List<String> _views = const [
    'All Accounts',
    'Active Accounts',
    'Inactive Accounts',
    'Asset Accounts',
    'Liability Accounts',
    'Equity Accounts',
    'Income Accounts',
    'Expense Accounts',
  ];

  @override
  Widget build(BuildContext context) {
    // Correctly using ref.listen inside build
    ref.listen<String?>(
      chartOfAccountsProvider.select((s) => s.selectedAccountId),
      (previous, next) {
        if (next != null) {
          setState(() => _forceWideTable = false);
        }
      },
    );

    final state = ref.watch(chartOfAccountsProvider);
    final notifier = ref.read(chartOfAccountsProvider.notifier);
    final selectedAccountId = state.selectedAccountId;
    final selectedAccount = selectedAccountId == null
        ? null
        : state.selectedAccount;
    final hasSelection = state.selectedIds.isNotEmpty;

    // Logic
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    final roots = state.filteredRoots;

    // View States
    final bool showMobileDetail =
        selectedAccountId != null &&
        selectedAccount != null && // Added null check
        screenWidth < 800 &&
        !_forceWideTable;
    final bool showDesktopSplit =
        widget.initialAccountId != null &&
        selectedAccountId != null &&
        selectedAccount != null && // Added null check
        screenWidth >= 800 &&
        !_forceWideTable;

    // Compact Mode (for list rows)
    final bool compact = showDesktopSplit || !isLargeScreen;
    final bool hasAdvancedSearch =
        state.advancedSearchName.trim().isNotEmpty ||
        state.advancedSearchCode.trim().isNotEmpty;

    final Widget leftPanel = Column(
      children: [
        // Toolbar: View Filter + Search
        Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Row(
            children: [
              Flexible(
                flex: 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: FormDropdown<String>(
                    height: 32,
                    value: state.selectedView,
                    items: _views,
                    onChanged: (v) {
                      if (v != null) notifier.setView(v);
                    },
                    itemBuilder: (item, isSelected, isHovered) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space12,
                          vertical: AppTheme.space8,
                        ),
                        color: isSelected
                            ? AppTheme.bgDisabled
                            : isHovered
                            ? AppTheme.bgLight
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              LucideIcons.star,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widths = !compact
                  ? _AccountTableWidths.fromMaxWidth(
                      constraints.maxWidth,
                      showDocuments: state.showDocuments,
                      showParentName: state.showParentName,
                    )
                  : null;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: widths != null && widths.total > constraints.maxWidth
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: widths?.total ?? constraints.maxWidth,
                  child: Column(
                    children: [
                      if (hasAdvancedSearch)
                        _buildSearchCriteriaBanner(
                          state,
                          notifier,
                          context,
                          ref,
                        ),
                      _buildTableHeader(
                        state,
                        notifier,
                        compact,
                        widths,
                        context,
                        ref,
                      ),
                      Expanded(
                        child: state.isLoading
                            ? const TableSkeleton(columns: 5)
                            : ListView.builder(
                                itemCount: roots.length,
                                itemBuilder: (context, index) {
                                  final node = roots[index];
                                  return AccountRow(
                                    node: node,
                                    level: 0,
                                    isExpanded: state.expandedIds.contains(
                                      node.id,
                                    ),
                                    onToggle: () =>
                                        notifier.toggleExpand(node.id),
                                    onTap: () => context.go(
                                      AppRoutes.accountsChartOfAccountsDetail
                                          .replaceAll(':id', node.id),
                                    ),
                                    expandedIds: state.expandedIds,
                                    onToggleChild: notifier.toggleExpand,
                                    onTapChild: (id) => context.go(
                                      AppRoutes.accountsChartOfAccountsDetail
                                          .replaceAll(':id', id),
                                    ),
                                    isLast: index == roots.length - 1,
                                    ancestorHasNext: const [],
                                    compact: compact,
                                    selectedAccountId: selectedAccountId,
                                    columnOrder: state.columnOrder,
                                    nameWidth: widths?.name,
                                    codeWidth: widths?.code,
                                    balanceWidth: widths?.balance,
                                    typeWidth: widths?.type,
                                    documentsWidth: widths?.documents,
                                    parentWidth: widths?.parent,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );

    // 1. MOBILE DETAIL VIEW
    if (showMobileDetail) {
      return ZerpaiLayout(
        pageTitle: 'Account Details',
        enableBodyScroll: false,
        actions: const [], // No actions in detail view
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.space8),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: AccountOverviewPanel(
            account: selectedAccount,
            onClose: () => notifier.clearSelection(),
          ),
        ),
      );
    }

    // 2. DESKTOP VIEW (List or Split)
    return ZerpaiLayout(
      pageTitle: 'Chart of Accounts',
      enableBodyScroll: false,
      searchFocusNode: _searchFocusNode,
      actions: [
        // NEW ACCOUNT BUTTON
        SizedBox(
          height: 32,
          child: ElevatedButton.icon(
            onPressed: () =>
                context.push(AppRoutes.accountsChartOfAccountsCreate),
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('New', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // MORE MENU BUTTON
        CompositedTransformTarget(
          link: _moreMenuLink,
          child: Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: InkWell(
              onTap: () {
                if (_moreMenuEntry != null) {
                  _closeAllMenus();
                } else {
                  _openMoreMenu();
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: const Icon(
                LucideIcons.moreHorizontal,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSelection) _buildBulkActionBar(state, notifier),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.space8),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: !showDesktopSplit
                  ? leftPanel
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 300, child: leftPanel),
                        const VerticalDivider(
                          width: 1,
                          color: AppTheme.borderColor,
                        ),
                        Expanded(
                          flex: 7,
                          child: AccountOverviewPanel(
                            // Use ! since isSplitView guarantees selectedAccountId/Account is not null
                            account: selectedAccount,
                            onClose: () {
                              setState(() {
                                _forceWideTable = true;
                              });
                              // Don't clear selection if we just want to hide the panel
                              // but keep the highlight in the list.
                              // Actually, if they click 'X', it should clear selection.
                              // Let's keep it consistent.
                              context.go(AppRoutes.accountsChartOfAccounts);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(
    ChartOfAccountsState state,
    ChartOfAccountsNotifier notifier,
  ) {
    final selectedAccounts = <AccountNode>[];
    void collectSelected(List<AccountNode> nodes) {
      for (final node in nodes) {
        if (state.selectedIds.contains(node.id)) {
          selectedAccounts.add(node);
        }
        collectSelected(node.children);
      }
    }

    collectSelected(state.roots);

    final hasActive = selectedAccounts.any((a) => a.isActive);
    final hasInactive = selectedAccounts.any((a) => !a.isActive);

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.space6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          if (hasInactive) ...[
            _BulkButton(
              label: 'Mark as Active',
              onPressed: () => _handleBulkStatus(true),
            ),
            const SizedBox(width: AppTheme.space8),
          ],
          if (hasActive) ...[
            _BulkButton(
              label: 'Mark as Inactive',
              onPressed: () => _handleBulkStatus(false),
            ),
            const SizedBox(width: AppTheme.space8),
          ],
          _BulkButton(label: 'Delete', onPressed: _handleBulkDelete),
          const SizedBox(width: AppTheme.space12),
          const VerticalDivider(
            width: 1,
            indent: 12,
            endIndent: 12,
            color: AppTheme.borderColor,
          ),
          const SizedBox(width: AppTheme.space12),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${state.selectedIds.length}',
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Selected',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          ),
          const Spacer(),
          Tooltip(
            message: 'Clear selection',
            child: InkWell(
              onTap: () => notifier.toggleSelectAll(),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.errorRed.withValues(alpha: 0.06),
                ),
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: AppTheme.errorRed.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBulkStatus(bool isActive) async {
    final notifier = ref.read(chartOfAccountsProvider.notifier);
    final selectedIds = ref.read(chartOfAccountsProvider).selectedIds;

    try {
      for (final id in selectedIds) {
        await notifier.updateAccountStatus(id, isActive);
      }
      if (mounted) {
        ZerpaiToast.success(
          context,
          '${selectedIds.length} accounts marked as ${isActive ? 'Active' : 'Inactive'}',
        );
        notifier.toggleSelectAll(); // Clear selection
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _handleBulkDelete() async {
    final notifier = ref.read(chartOfAccountsProvider.notifier);
    final selectedIds = ref.read(chartOfAccountsProvider).selectedIds;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Delete Selected Accounts'),
        content: Text(
          'Are you sure you want to delete ${selectedIds.length} accounts?',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => context.pop(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await notifier.deleteAccounts(selectedIds.toList());
        if (mounted) {
          ZerpaiToast.success(
            context,
            'Selected accounts deleted successfully',
          );
          notifier.toggleSelectAll();
        }
      } catch (e) {
        if (mounted) {
          ZerpaiToast.error(context, 'Error: $e');
        }
      }
    }
  }

  void _showAdvancedSearchPopup(BuildContext context, WidgetRef ref) {
    final state = ref.read(chartOfAccountsProvider);
    final notifier = ref.read(chartOfAccountsProvider.notifier);

    final nameController = TextEditingController(
      text: state.advancedSearchName,
    );
    final codeController = TextEditingController(
      text: state.advancedSearchCode,
    );
    String selectedView = state.selectedView;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: math.min(
                        920,
                        MediaQuery.of(context).size.width - 80,
                      ),
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.space8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final double fieldWidth = math
                              .min(
                                320.0,
                                math.max(220.0, (maxWidth - 220.0) / 2),
                              )
                              .toDouble();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header Row
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 70,
                                    child: Text(
                                      'Search',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: FormDropdown<String>(
                                      items: const [
                                        'Chart of Accounts',
                                        'Transactions',
                                      ],
                                      value: 'Chart of Accounts',
                                      onChanged: (val) {
                                        // This is a local filter scope, not a global navigation menu.
                                      },
                                      height: 32,
                                      showSearch: false,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.space24),
                                  const SizedBox(
                                    width: 50,
                                    child: Text(
                                      'Filter',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: FormDropdown<String>(
                                      items: [
                                        'All Accounts',
                                        'Active Accounts',
                                        'Inactive Accounts',
                                        'Asset Accounts',
                                        'Liability Accounts',
                                        'Equity Accounts',
                                        'Income Accounts',
                                        'Expense Accounts',
                                      ],
                                      value: selectedView,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => selectedView = val);
                                        }
                                      },
                                      height: 32,
                                      showSearch: false,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.x,
                                      size: 18,
                                      color: AppTheme.textSecondary,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space12),
                              const Divider(
                                height: 1,
                                color: AppTheme.borderColor,
                              ),
                              const SizedBox(height: AppTheme.space12),

                              // Filter Inputs Row
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 110,
                                    child: Text(
                                      'Account Name',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _buildPopupTextField(
                                      nameController,
                                      'Search by name',
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.space24),
                                  const SizedBox(
                                    width: 110,
                                    child: Text(
                                      'Account Code',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _buildPopupTextField(
                                      codeController,
                                      'Search by code',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space16),

                              // Actions Row
                              Container(
                                padding: const EdgeInsets.only(top: 12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        notifier.setAdvancedSearch(
                                          name: nameController.text.trim(),
                                          code: codeController.text.trim(),
                                          view: selectedView,
                                        );
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF16A34A,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: const Text('Search'),
                                    ),
                                    const SizedBox(width: AppTheme.space8),
                                    OutlinedButton(
                                      onPressed: () {
                                        notifier.clearAdvancedSearch();
                                        Navigator.pop(context);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textSecondary,
                                        side: const BorderSide(
                                          color: AppTheme.borderColor,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(
    ChartOfAccountsState state,
    ChartOfAccountsNotifier notifier,
    bool compact,
    _AccountTableWidths? widths,
    BuildContext context,
    WidgetRef ref,
  ) {
    final bool useFixed = widths != null && !compact;
    final _AccountTableWidths fixed = widths ?? _AccountTableWidths.zero;

    if (compact) {
      return const SizedBox.shrink();
    }

    final List<String> visibleOrder = state.columnOrder.where((key) {
      if (key == 'documents') return state.showDocuments;
      if (key == 'parent') return state.showParentName;
      return true;
    }).toList();

    double widthFor(String key) {
      switch (key) {
        case 'name':
          return fixed.name;
        case 'code':
          return fixed.code;
        case 'balance':
          return fixed.balance;
        case 'type':
          return fixed.type;
        case 'documents':
          return fixed.documents;
        case 'parent':
          return fixed.parent;
        default:
          return 0;
      }
    }

    Widget buildHeaderFor(String key) {
      String label;
      String sortKey;
      switch (key) {
        case 'name':
          label = 'Account Name';
          sortKey = 'name';
          break;
        case 'code':
          label = 'Account Code';
          sortKey = 'code';
          break;
        case 'balance':
          label = 'Balance';
          sortKey = 'balance';
          break;
        case 'type':
          label = 'Account Type';
          sortKey = 'type';
          break;
        case 'documents':
          label = 'Documents';
          sortKey = 'documents';
          break;
        case 'parent':
          label = 'Parent Account Name';
          sortKey = 'parent';
          break;
        default:
          label = key;
          sortKey = key;
      }

      return SizedBox(
        width: widthFor(key),
        child: _HeaderCell(
          label,
          padding: key == 'name' ? 26.0 : 0,
          isSorted: state.sortColumn == sortKey,
          isAscending: state.isAscending,
          onSort: () => notifier.setSort(sortKey),
        ),
      );
    }

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          // 1. Combined Header Filter / Select Toggle
          SizedBox(
            width: 42,
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: 20), // Alignment padding
                Expanded(
                  child: Center(
                    child: state.selectedIds.isEmpty
                        ? PopupMenuButton<_HeaderFilterAction>(
                            tooltip: 'Customize Columns',
                            elevation: 8,
                            color: Colors.white,
                            offset: const Offset(0, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                            ),
                            icon: const Icon(
                              LucideIcons.sliders,
                              size: 16,
                              color: AppTheme.primaryBlueDark,
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case _HeaderFilterAction.customizeColumns:
                                  _showCustomizeColumnsDialog(context, ref);
                                  break;
                                case _HeaderFilterAction.wrapText:
                                  notifier.toggleTextWrapping();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<_HeaderFilterAction>(
                                value: _HeaderFilterAction.customizeColumns,
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      LucideIcons.columns,
                                      size: 16,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Customize Columns',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<_HeaderFilterAction>(
                                value: _HeaderFilterAction.wrapText,
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.wrapText,
                                      size: 16,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Wrap Text',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (state.isTextWrapped)
                                      const Icon(
                                        LucideIcons.check,
                                        size: 16,
                                        color: Color(0xFF3B82F6),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : InkResponse(
                            onTap: notifier.toggleSelectAll,
                            radius: 16,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: AppTheme.primaryBlue,
                                  width: 1.5,
                                ),
                                color: AppTheme.primaryBlue,
                              ),
                              child: const Icon(
                                LucideIcons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (useFixed)
            Expanded(
              child: Row(children: visibleOrder.map(buildHeaderFor).toList()),
            ),
          const VerticalDivider(width: 1, color: AppTheme.borderColor),
          SizedBox(
            width: compact ? 36 : 48,
            child: Center(
              child: InkWell(
                onTap: () => _showAdvancedSearchPopup(context, ref),
                child: const Icon(
                  LucideIcons.search,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCriteriaBanner(
    ChartOfAccountsState state,
    ChartOfAccountsNotifier notifier,
    BuildContext context,
    WidgetRef ref,
  ) {
    final criteria = <String>[];
    if (state.advancedSearchName.trim().isNotEmpty) {
      criteria.add('Account Name contains ${state.advancedSearchName.trim()}');
    }
    if (state.advancedSearchCode.trim().isNotEmpty) {
      criteria.add('Account Code contains ${state.advancedSearchCode.trim()}');
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppTheme.space12,
        0,
        AppTheme.space12,
        AppTheme.space12,
      ),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: const Color(0xFFECF8EE),
        borderRadius: BorderRadius.circular(AppTheme.space6),
        border: Border.all(color: const Color(0xFFD4EFD9)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search Criteria',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ...criteria.map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '•',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => _showAdvancedSearchPopup(context, ref),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Change Criteria',
                    style: TextStyle(color: Color(0xFF2563EB), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: InkResponse(
              onTap: notifier.clearAdvancedSearch,
              radius: 14,
              child: const Icon(
                LucideIcons.x,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomizeColumnsDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(chartOfAccountsProvider);
    final notifier = ref.read(chartOfAccountsProvider.notifier);

    bool showDocuments = state.showDocuments;
    bool showParentName = state.showParentName;
    String searchQuery = '';

    final searchController = TextEditingController();

    final columns = [
      {'label': 'Account Name', 'locked': true, 'key': 'name'},
      {'label': 'Account Code', 'locked': true, 'key': 'code'},
      {'label': 'Type', 'locked': true, 'key': 'type'},
      {'label': 'Documents', 'locked': false, 'key': 'documents'},
      {'label': 'Parent Account Name', 'locked': false, 'key': 'parent'},
      {'label': 'Balance', 'locked': true, 'key': 'balance'},
    ];
    final columnByKey = {
      for (final column in columns) column['key'] as String: column,
    };
    final defaultOrder = columns
        .map((column) => column['key'] as String)
        .toList();
    final existingOrder = state.columnOrder
        .where(columnByKey.containsKey)
        .toList();
    List<String> order = [
      ...existingOrder,
      ...defaultOrder.where((key) => !existingOrder.contains(key)),
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final selectedCount =
              4 + (showDocuments ? 1 : 0) + (showParentName ? 1 : 0);
          final normalizedQuery = searchQuery.trim().toLowerCase();
          final listKeys = normalizedQuery.isEmpty
              ? order
              : order.where((key) {
                  final label = columnByKey[key]!['label'] as String;
                  return label.toLowerCase().contains(normalizedQuery);
                }).toList();
          final bool canReorder = normalizedQuery.isEmpty;
          final double listHeight = math.min(260.0, listKeys.length * 44.0 + 8);

          Widget buildColumnRow(
            String key,
            int index, {
            required bool draggable,
          }) {
            final column = columnByKey[key]!;
            final label = column['label'] as String;
            final locked = column['locked'] as bool;
            final isChecked = locked
                ? true
                : (key == 'documents' ? showDocuments : showParentName);

            final dragHandle = draggable
                ? ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      LucideIcons.gripVertical,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                  )
                : const Icon(
                    LucideIcons.gripVertical,
                    size: 16,
                    color: AppTheme.textMuted,
                  );

            return InkWell(
              key: ValueKey(key),
              onTap: locked
                  ? null
                  : () => setState(() {
                      if (key == 'documents') {
                        showDocuments = !showDocuments;
                      } else if (key == 'parent') {
                        showParentName = !showParentName;
                      }
                    }),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppTheme.space8),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(AppTheme.space6),
                ),
                child: Row(
                  children: [
                    dragHandle,
                    const SizedBox(width: AppTheme.space8),
                    if (locked)
                      const Icon(
                        LucideIcons.lock,
                        size: 16,
                        color: AppTheme.textSecondary,
                      )
                    else
                      Checkbox(
                        value: isChecked,
                        onChanged: (_) => setState(() {
                          if (key == 'documents') {
                            showDocuments = !showDocuments;
                          } else if (key == 'parent') {
                            showParentName = !showParentName;
                          }
                        }),
                        visualDensity: VisualDensity.compact,
                        activeColor: AppTheme.primaryBlue,
                      ),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget listWidget;
          if (listKeys.isEmpty) {
            listWidget = const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.space12),
              child: Text(
                'No columns found',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            );
          } else if (canReorder) {
            listWidget = SizedBox(
              height: listHeight,
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final moved = order.removeAt(oldIndex);
                    order.insert(newIndex, moved);
                  });
                },
                children: [
                  for (int i = 0; i < listKeys.length; i++)
                    buildColumnRow(listKeys[i], i, draggable: true),
                ],
              ),
            );
          } else {
            listWidget = SizedBox(
              height: listHeight,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listKeys.length,
                itemBuilder: (context, index) =>
                    buildColumnRow(listKeys[index], index, draggable: false),
              ),
            );
          }

          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space24,
              vertical: AppTheme.space24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.space8),
            ),
            child: SizedBox(
              width: 480,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.sliders,
                          size: 18,
                          color: AppTheme.primaryBlueDark,
                        ),
                        const SizedBox(width: AppTheme.space8),
                        const Expanded(
                          child: Text(
                            'Customize Columns',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$selectedCount of 6 Selected',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        InkResponse(
                          onTap: () {
                            setState(() {
                              showDocuments = true;
                              showParentName = true;
                              order = [...defaultOrder];
                              searchQuery = '';
                              searchController.clear();
                            });
                          },
                          radius: 16,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: const Icon(
                              LucideIcons.rotateCcw,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        InkResponse(
                          onTap: () => Navigator.pop(context),
                          radius: 16,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              size: 16,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space16),
                    TextField(
                      controller: searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) =>
                          setState(() => searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space12,
                          vertical: AppTheme.space10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.space6),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.space6),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.space6),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: AppTheme.inputFill,
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    listWidget,
                    const SizedBox(height: AppTheme.space16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final bool orderChanged =
                                order.length != state.columnOrder.length ||
                                List.generate(
                                  order.length,
                                  (i) => order[i] == state.columnOrder[i],
                                ).contains(false);
                            final bool documentsChanged =
                                showDocuments != state.showDocuments;
                            final bool parentChanged =
                                showParentName != state.showParentName;
                            if (documentsChanged) {
                              notifier.toggleColumn('documents');
                            }
                            if (parentChanged) {
                              notifier.toggleColumn('parent');
                            }
                            notifier.setColumnOrder(order);
                            Navigator.pop(context);
                            if (orderChanged ||
                                documentsChanged ||
                                parentChanged) {
                              ZerpaiBuilders.showSuccessToast(
                                context,
                                'Custom View has been updated.',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                              vertical: AppTheme.space10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.space6,
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                              vertical: AppTheme.space10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.space6,
                              ),
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openMoreMenu() {
    final overlay = Overlay.of(context);
    _moreMenuEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeAllMenus,
                child: const SizedBox.shrink(),
              ),
            ),
            Positioned(
              width: 240,
              child: CompositedTransformFollower(
                link: _moreMenuLink,
                showWhenUnlinked: false,
                offset: const Offset(-204, 44),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CompositedTransformTarget(
                          link: _sortRowLink,
                          child: _buildMoreMenuItem(
                            label: 'Sort by',
                            icon: LucideIcons.arrowUpDown,
                            trailing: LucideIcons.chevronRight,
                            onHover: (isHovered) {
                              _isHoveringSortRow = isHovered;
                              if (isHovered) {
                                _openSortMenu();
                                _isHoveringExportRow = false;
                                _exportMenuEntry?.remove();
                                _exportMenuEntry = null;
                              } else {
                                _scheduleCloseSortMenu();
                              }
                            },
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        _buildMoreMenuItem(
                          label: 'Import Chart of Accounts',
                          icon: LucideIcons.download,
                          onTap: () {
                            _closeAllMenus();
                            // Handle Import
                          },
                        ),
                        CompositedTransformTarget(
                          link: _exportRowLink,
                          child: _buildMoreMenuItem(
                            label: 'Export',
                            icon: LucideIcons.upload,
                            trailing: LucideIcons.chevronRight,
                            onHover: (isHovered) {
                              _isHoveringExportRow = isHovered;
                              if (isHovered) {
                                _openExportMenu();
                                _isHoveringSortRow = false;
                                _sortMenuEntry?.remove();
                                _sortMenuEntry = null;
                              } else {
                                _scheduleCloseExportMenu();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_moreMenuEntry!);
  }

  void _scheduleCloseSortMenu() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isHoveringSortRow && !_isHoveringSortMenu) {
        _sortMenuEntry?.remove();
        _sortMenuEntry = null;
      }
    });
  }

  void _scheduleCloseExportMenu() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isHoveringExportRow && !_isHoveringExportMenu) {
        _exportMenuEntry?.remove();
        _exportMenuEntry = null;
      }
    });
  }

  void _openSortMenu() {
    if (_sortMenuEntry != null) return;
    final overlay = Overlay.of(context);
    _sortMenuEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 200,
          child: CompositedTransformFollower(
            link: _sortRowLink,
            showWhenUnlinked: false,
            offset: const Offset(-204, 0),
            child: MouseRegion(
              onEnter: (_) => _isHoveringSortMenu = true,
              onExit: (_) {
                _isHoveringSortMenu = false;
                _scheduleCloseSortMenu();
              },
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSubmenuItem('Account Name', field: 'name'),
                      _buildSubmenuItem('Account Code', field: 'code'),
                      _buildSubmenuItem('Type', field: 'accountGroup'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_sortMenuEntry!);
  }

  void _openExportMenu() {
    if (_exportMenuEntry != null) return;
    final overlay = Overlay.of(context);
    _exportMenuEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 200,
          child: CompositedTransformFollower(
            link: _exportRowLink,
            showWhenUnlinked: false,
            offset: const Offset(-204, 0),
            child: MouseRegion(
              onEnter: (_) => _isHoveringExportMenu = true,
              onExit: (_) {
                _isHoveringExportMenu = false;
                _scheduleCloseExportMenu();
              },
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSubmenuItem('Export Chart of Accounts'),
                      _buildSubmenuItem('Export Current View'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_exportMenuEntry!);
  }

  Widget _buildMoreMenuItem({
    required String label,
    required IconData icon,
    IconData? trailing,
    void Function(bool)? onHover,
    VoidCallback? onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        bool isLocalHover = false;
        final bool isSortingSticky =
            label == 'Sort by' && (_isHoveringSortRow || _isHoveringSortMenu);
        final bool isExportSticky =
            label == 'Export' &&
            (_isHoveringExportRow || _isHoveringExportMenu);
        final bool highlight =
            isLocalHover || isSortingSticky || isExportSticky;

        return MouseRegion(
          onEnter: (_) {
            setLocalState(() => isLocalHover = true);
            onHover?.call(true);
          },
          onExit: (_) {
            setLocalState(() => isLocalHover = false);
            onHover?.call(false);
          },
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: highlight ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: highlight ? BorderRadius.circular(4) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: highlight ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: highlight
                            ? Colors.white
                            : const Color(0xFF374151),
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Icon(
                      trailing,
                      size: 16,
                      color: highlight ? Colors.white : const Color(0xFF64748B),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmenuItem(String label, {String? field}) {
    final state = ref.watch(chartOfAccountsProvider);
    final notifier = ref.read(chartOfAccountsProvider.notifier);
    final bool isSelected = field != null && state.sortColumn == field;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        bool isLocalHover = false;
        final bool highlight = isLocalHover || isSelected;

        return MouseRegion(
          onEnter: (_) => setLocalState(() => isLocalHover = true),
          onExit: (_) => setLocalState(() => isLocalHover = false),
          child: InkWell(
            onTap: () {
              if (field != null) {
                notifier.setSort(field);
              }
              _closeAllMenus();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: highlight ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: highlight ? BorderRadius.circular(4) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: highlight
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: highlight
                            ? Colors.white
                            : const Color(0xFF374151),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      LucideIcons.arrowUp,
                      size: 14,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupTextField(TextEditingController controller, String hint) {
    return Container(
      height: 32,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          prefixIcon: const Icon(
            LucideIcons.search,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF3B82F6)),
          ),
          isDense: true,
          fillColor: Colors.white,
          filled: true,
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _BulkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _BulkButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        side: const BorderSide(color: AppTheme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: const Color(0xFFF9FAFB),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

class _AccountTableWidths {
  final double name;
  final double code;
  final double balance;
  final double type;
  final double documents;
  final double parent;
  final double total;

  static const _AccountTableWidths zero = _AccountTableWidths(
    name: 0,
    code: 0,
    balance: 0,
    type: 0,
    documents: 0,
    parent: 0,
    total: 0,
  );

  const _AccountTableWidths({
    required this.name,
    required this.code,
    required this.balance,
    required this.type,
    required this.documents,
    required this.parent,
    required this.total,
  });

  factory _AccountTableWidths.fromMaxWidth(
    double maxWidth, {
    required bool showDocuments,
    required bool showParentName,
  }) {
    // Reserve space for: Header Start (42) + List Action (48) + Header Divider (1)
    // Matches fixed elements in AccountRow to ensure exact sum calculation.
    const double reserved = 42 + 48 + 1;

    // Minimum widths to ensure readability
    const double minName = 260.0;
    const double minCode = 140.0;
    const double minBalance = 140.0;
    const double minType = 160.0;
    const double minDocs = 100.0;
    const double minParent = 210.0;

    // Proportional weights
    const double nameWeight = 3.5;
    const double codeWeight = 1.2;
    const double balanceWeight = 1.8;
    const double typeWeight = 2.0;
    const double docsWeight = 1.5;
    const double parentWeight = 2.5;

    double totalWeight = nameWeight + codeWeight + balanceWeight + typeWeight;
    if (showDocuments) totalWeight += docsWeight;
    if (showParentName) totalWeight += parentWeight;

    // Calculate available space for dynamic columns
    final double baseAvailable = math.max(0.0, maxWidth - reserved);
    final double unit = baseAvailable / totalWeight;

    // Calculate individual column widths
    final double wName = math.max(minName, unit * nameWeight);
    final double wCode = math.max(minCode, unit * codeWeight);
    final double wBalance = math.max(minBalance, unit * balanceWeight);
    final double wType = math.max(minType, unit * typeWeight);
    final double wDocs = showDocuments
        ? math.max(minDocs, unit * docsWeight)
        : 0;
    final double wParent = showParentName
        ? math.max(minParent, unit * parentWeight)
        : 0;

    // FINAL TOTAL: sum of all parts (prevents internal Row overflows)
    final double finalTotal =
        reserved + wName + wCode + wBalance + wType + wDocs + wParent;

    return _AccountTableWidths(
      name: wName,
      code: wCode,
      balance: wBalance,
      type: wType,
      documents: wDocs,
      parent: wParent,
      total: finalTotal,
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double padding;
  final VoidCallback? onSort;
  final bool isSorted;
  final bool isAscending;

  const _HeaderCell(
    this.text, {
    this.padding = 0,
    this.onSort,
    this.isSorted = false,
    this.isAscending = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSort,
      child: Padding(
        padding: EdgeInsets.only(left: padding + 8, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (onSort != null) ...[
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.chevronUp,
                    size: 12,
                    color: isSorted && isAscending
                        ? AppTheme.primaryBlue
                        : AppTheme.textSecondary.withValues(alpha: 0.4),
                  ),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 12,
                    color: isSorted && !isAscending
                        ? AppTheme.primaryBlue
                        : AppTheme.textSecondary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _HeaderFilterAction { customizeColumns, wrapText }
