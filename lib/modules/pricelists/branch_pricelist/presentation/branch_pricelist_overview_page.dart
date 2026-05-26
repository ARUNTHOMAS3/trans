import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../app/routing/app_router.dart';
import '../models/branch_pricelist_model.dart';
import '../models/branch_pricelist_pagination.dart';
import '../providers/branch_pricelist_provider.dart';
import '../../../../shared/services/recent_history_service.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_calendar.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker_style.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';

/// Price Lists Screen - Inventory → Items → Price Lists
class BranchPriceListOverviewScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;

  const BranchPriceListOverviewScreen({super.key, this.initialSearchQuery});

  @override
  ConsumerState<BranchPriceListOverviewScreen> createState() =>
      _BranchPriceListOverviewScreenState();
}

class _BranchPriceListOverviewScreenState
    extends ConsumerState<BranchPriceListOverviewScreen> {
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final _dateRangeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialSearchQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref
            .read(branchPriceListFilterProvider.notifier)
            .setSearchQuery(initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _bulkDelete() async {
    final ids = _selectedIds.toList();
    await ref
        .read(branchPriceListNotifierProvider.notifier)
        .bulkDeleteBranchPriceLists(ids);
    setState(() => _selectedIds.clear());
    if (mounted) {
      ZerpaiToast.success(context, '${ids.length} price lists deleted');
    }
  }

  Future<void> _bulkActivate() async {
    final ids = _selectedIds.toList();
    await ref
        .read(branchPriceListNotifierProvider.notifier)
        .bulkActivateBranchPriceLists(ids);
    setState(() => _selectedIds.clear());
    if (mounted) {
      ZerpaiToast.success(context, 'Price lists activated');
    }
  }

  Future<void> _bulkDeactivate() async {
    final ids = _selectedIds.toList();
    await ref
        .read(branchPriceListNotifierProvider.notifier)
        .bulkDeactivateBranchPriceLists(ids);
    setState(() => _selectedIds.clear());
    if (mounted) {
      ZerpaiToast.success(context, 'Price lists deactivated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginationAsync = ref.watch(
      filteredBranchPriceListPaginationProvider,
    );
    final isBranchViewOnly =
        ref.watch(authUserProvider)?.activeTenantType == 'BRANCH';

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () {
          _searchFocusNode.requestFocus();
        },
        if (!isBranchViewOnly)
          const SingleActivator(
            LogicalKeyboardKey.keyN,
            control: true,
          ): () async {
            final result = await context.push(AppRoutes.branchPriceListsCreate);
            if (result == true && context.mounted) {
              ZerpaiToast.success(context, 'Price list created successfully');
            }
          },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_selectedIds.isNotEmpty) {
            setState(() => _selectedIds.clear());
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: ZerpaiLayout(
          pageTitle: 'All Branch Price Lists',
          enableBodyScroll: false,
          actions: isBranchViewOnly
              ? const []
              : [
                  Container(
                    height: AppTheme.buttonHeight,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      borderRadius: BorderRadius.circular(AppTheme.space4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final result = await context.push(
                              AppRoutes.branchPriceListsCreate,
                            );
                            if (result == true && context.mounted) {
                              ZerpaiToast.success(
                                context,
                                'Price list created successfully',
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'New',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: AppTheme.buttonHeight,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        MenuAnchor(
                          builder: (context, controller, child) {
                            return InkWell(
                              onTap: () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open();
                                }
                              },
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(4),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () {},
                              child: const Text('Import Branch Price Lists'),
                            ),
                          ],
                          style: MenuStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.white,
                            ),
                            surfaceTintColor: WidgetStateProperty.all(
                              Colors.white,
                            ),
                            elevation: WidgetStateProperty.all(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          child: Column(
            children: [
              if (!isBranchViewOnly) _buildActionsBar(context),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(branchPriceListNotifierProvider.notifier)
                        .fetchBranchPriceLists();
                  },
                  child: paginationAsync.when(
                    data: (pagination) => _buildbranchPriceListBody(
                      context,
                      ref,
                      pagination,
                      isBranchViewOnly,
                    ),
                    loading: () => _buildLoadingSkeleton(),
                    error: (error, stack) =>
                        _buildErrorState(context, ref, error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsBar(BuildContext context) {
    if (_selectedIds.isNotEmpty) {
      return _buildBulkActionsBar(context);
    }
    return _buildAdvancedFilterBar(context);
  }

  Widget _buildAdvancedFilterBar(BuildContext context) {
    final filters = ref.watch(branchPriceListFilterProvider);
    final notifier = ref.read(branchPriceListFilterProvider.notifier);

    return Column(
      children: [
        Row(
          children: [
            // Status Filter
            _buildDropdownFilter(
              value: filters.status,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Status')),
                const DropdownMenuItem(
                  value: 'active',
                  child: Text('Active Only'),
                ),
                const DropdownMenuItem(
                  value: 'inactive',
                  child: Text('Inactive Only'),
                ),
              ],
              onChanged: (v) => notifier.setStatus(v ?? 'all'),
            ),
            const SizedBox(width: 12),

            // Transaction Type Filter
            _buildDropdownFilter(
              value: filters.transactionType,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Types')),
                const DropdownMenuItem(value: 'sales', child: Text('Sales')),
                const DropdownMenuItem(
                  value: 'purchase',
                  child: Text('Purchases'),
                ),
              ],
              onChanged: (v) => notifier.setTransactionType(v ?? 'all'),
            ),
            const SizedBox(width: 12),

            // Date Range Picker
            OutlinedButton.icon(
              key: _dateRangeKey,
              onPressed: () async {
                final RenderBox? box =
                    _dateRangeKey.currentContext?.findRenderObject()
                        as RenderBox?;
                if (box == null) return;
                final offset = box.localToGlobal(Offset.zero);
                final size = box.size;
                DateTime fromDate = filters.startDate ?? DateTime.now();
                DateTime toDate = filters.endDate ?? DateTime.now();
                await showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (ctx) => StatefulBuilder(
                    builder: (ctx, setS) => Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            behavior: HitTestBehavior.translucent,
                          ),
                        ),
                        Positioned(
                          left: offset.dx,
                          top:
                              offset.dy +
                              size.height +
                              ZerpaiDatePickerStyle.popupOffsetY,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppTheme.borderColor),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ZerpaiCalendar(
                                        selectedDate: fromDate,
                                        firstDate: DateTime(2020),
                                        lastDate: toDate,
                                        onDateSelected: (d) =>
                                            setS(() => fromDate = d),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 1,
                                    color: AppTheme.borderColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'To',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ZerpaiCalendar(
                                        selectedDate: toDate,
                                        firstDate: fromDate,
                                        lastDate: DateTime.now(),
                                        onDateSelected: (d) =>
                                            setS(() => toDate = d),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: offset.dx,
                          top:
                              offset.dy +
                              size.height +
                              ZerpaiDatePickerStyle.popupOffsetY +
                              480,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  left: BorderSide(color: AppTheme.borderColor),
                                  right: BorderSide(
                                    color: AppTheme.borderColor,
                                  ),
                                  bottom: BorderSide(
                                    color: AppTheme.borderColor,
                                  ),
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      notifier.setDateRange(fromDate, toDate);
                                      Navigator.of(ctx).pop();
                                    },
                                    child: const Text('Apply'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                filters.startDate != null
                    ? '${DateFormat('MMM d').format(filters.startDate!)} – ${DateFormat('MMM d').format(filters.endDate!)}'
                    : 'Date Range',
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.borderColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Clear Filters
            if (filters.status != 'all' ||
                filters.transactionType != 'all' ||
                filters.startDate != null)
              TextButton(
                onPressed: () => notifier.clearFilters(),
                child: const Text('Clear All'),
              ),

            const Spacer(),

            // Search
            Container(
              width: 280,
              height: AppTheme.buttonHeight,
              decoration: BoxDecoration(
                color: AppTheme.bgDisabled,
                borderRadius: BorderRadius.circular(AppTheme.space4),
              ),
              child: TextField(
                focusNode: _searchFocusNode,
                controller: _searchController,
                onChanged: (value) => notifier.setSearchQuery(value),
                decoration: InputDecoration(
                  hintText: 'Search (Press /)',
                  hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownFilter<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return MenuAnchor(
      builder: (context, controller, child) {
        final selectedItem = items.firstWhere((item) => item.value == value);
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  child: selectedItem.child,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: items.map((item) {
        final isSelected = item.value == value;
        return MenuItemButton(
          onPressed: () => onChanged(item.value),
          style: MenuItemButton.styleFrom(
            backgroundColor: isSelected ? AppTheme.primaryBlue : null,
            foregroundColor: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
          child: Container(
            constraints: const BoxConstraints(minWidth: 120),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                item.child,
                if (isSelected)
                  const Icon(Icons.check, size: 14, color: Colors.white),
              ],
            ),
          ),
        );
      }).toList(),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(4),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppTheme.borderColor),
        ),
        maximumSize: WidgetStateProperty.all(const Size(400, 400)),
      ),
    );
  }

  Widget _buildBulkActionsBar(BuildContext context) {
    return Container(
      height: AppTheme.buttonHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.space4),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedIds.length} Selected',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _bulkActivate,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Activate', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _bulkDeactivate,
            icon: const Icon(Icons.block, size: 16),
            label: const Text('Deactivate', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.warningOrange,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _bulkDelete,
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Clear Selection',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Skeletonizer(
      ignoreContainers: true,
      enabled: true,
      child: ZTableSkeleton(rows: 8, columns: 3),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return ZErrorPlaceholder(
      message: 'Unable to Load Price Lists',
      error: error,
      onRetry: () {
        ref
            .read(branchPriceListNotifierProvider.notifier)
            .fetchBranchPriceLists();
      },
    );
  }

  Widget _buildbranchPriceListBody(
    BuildContext context,
    WidgetRef ref,
    BranchPriceListPagination pagination,
    bool isBranchViewOnly,
  ) {
    final BranchPriceLists = pagination.items;
    final filters = ref.watch(branchPriceListFilterProvider);
    if (BranchPriceLists.isEmpty && filters.searchQuery.isEmpty) {
      return _buildEmptyState(context);
    }

    // Sort price lists
    final sortedLists = _sortBranchPriceLists(BranchPriceLists, ref);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space32,
              AppTheme.space16,
              AppTheme.space32,
              AppTheme.space16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(AppTheme.space6),
                  ),
                  child: Column(
                    children: [
                      _buildTableHeader(sortedLists, ref),
                      Divider(height: 1, color: AppTheme.borderColor),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedLists.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: AppTheme.borderColor),
                        itemBuilder: (context, index) {
                          final branchPriceList = sortedLists[index];
                          final detailsText =
                              branchPriceList.priceListType ==
                                  'individual_items'
                              ? 'Per Item Rate'
                              : (branchPriceList.details ?? '-');
                          final roundOffText =
                              (branchPriceList.roundOffPreference?.isNotEmpty ??
                                  false)
                              ? branchPriceList.roundOffPreference!
                              : 'Never mind';

                          return _branchPriceListRow(
                            branchPriceList: branchPriceList,
                            detailsText: detailsText,
                            roundOffText: roundOffText,
                            pricingSchemeDisplay: _getPricingSchemeDisplay(
                              branchPriceList.pricingScheme,
                            ),
                            isSelected: _selectedIds.contains(
                              branchPriceList.id,
                            ),
                            visibleColumns: ref.watch(
                              branchPriceListColumnProvider,
                            ),
                            onSelectionChanged: (val) {
                              if (!isBranchViewOnly) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIds.add(branchPriceList.id);
                                  } else {
                                    _selectedIds.remove(branchPriceList.id);
                                  }
                                });
                              }
                            },
                            onTap: isBranchViewOnly
                                ? () {}
                                : () => context.go(
                                    AppRoutes.branchPriceListsEdit.replaceAll(
                                      ':id',
                                      branchPriceList.id,
                                    ),
                                    extra: BranchPriceList,
                                  ),
                            onAction: isBranchViewOnly
                                ? (_) {}
                                : (action) => _handleAction(
                                    context,
                                    ref,
                                    action,
                                    branchPriceList,
                                  ),
                            readOnly: isBranchViewOnly,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildPaginationFooter(pagination),
      ],
    );
  }

  Widget _buildPaginationFooter(BranchPriceListPagination pagination) {
    final currentPage = pagination.page;
    final totalCount = pagination.totalCount;
    final limit = pagination.limit;
    final startRange = totalCount == 0 ? 0 : (currentPage - 1) * limit + 1;
    final endRange = (startRange + pagination.items.length - 1).clamp(
      0,
      totalCount,
    );

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Text(
            'Total Count: ',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          InkWell(
            onTap: () {},
            child: Text(
              '$totalCount',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          _buildPageSizeSelector(limit),
          const SizedBox(width: 24),
          Text(
            '$startRange - $endRange of $totalCount',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 16),
          _buildPageNavigation(currentPage, totalCount, limit),
        ],
      ),
    );
  }

  Widget _buildPageSizeSelector(int currentLimit) {
    return PopupMenuButton<int>(
      onSelected: (value) {
        ref.read(branchPriceListLimitProvider.notifier).state = value;
        ref.read(branchPriceListPageProvider.notifier).state = 1;
        ref
            .read(branchPriceListNotifierProvider.notifier)
            .fetchBranchPriceLists();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.settings, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              '$currentLimit per page',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => [10, 25, 50, 100, 200].map((size) {
        return PopupMenuItem<int>(
          value: size,
          height: 36,
          child: Text('$size per page', style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
    );
  }

  Widget _buildPageNavigation(int currentPage, int totalCount, int limit) {
    final totalPages = totalCount == 0 ? 1 : (totalCount / limit).ceil();
    final canPrev = currentPage > 1;
    final canNext = currentPage < totalPages;

    return Row(
      children: [
        IconButton(
          onPressed: canPrev
              ? () {
                  final prevPage = currentPage - 1;
                  ref.read(branchPriceListPageProvider.notifier).state =
                      prevPage;
                  ref
                      .read(branchPriceListNotifierProvider.notifier)
                      .fetchBranchPriceLists();
                }
              : null,
          icon: const Icon(Icons.chevron_left, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: canNext
              ? () {
                  final nextPage = currentPage + 1;
                  ref.read(branchPriceListPageProvider.notifier).state =
                      nextPage;
                  ref
                      .read(branchPriceListNotifierProvider.notifier)
                      .fetchBranchPriceLists();
                }
              : null,
          icon: const Icon(Icons.chevron_right, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.bgDisabled,
                borderRadius: BorderRadius.circular(48),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Branch Price Lists Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Price lists let you define custom prices for items.\n'
              'Create different pricing rules based on customer type, '
              'sales channel, contracts, or regions.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.branchPriceListsCreate),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create your first price list'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(
    List<BranchPriceList> BranchPriceLists,
    WidgetRef ref,
  ) {
    final allSelected =
        BranchPriceLists.isNotEmpty &&
        BranchPriceLists.every((pl) => _selectedIds.contains(pl.id));
    final cols = ref.watch(branchPriceListColumnProvider);
    final BranchSortState = ref.watch(branchPriceListSortProvider);

    return Container(
      decoration: const BoxDecoration(color: AppTheme.bgLight),
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: allSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedIds.addAll(BranchPriceLists.map((pl) => pl.id));
                  } else {
                    _selectedIds.removeAll(BranchPriceLists.map((pl) => pl.id));
                  }
                });
              },
              activeColor: AppTheme.primaryBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (cols['name']!)
            Expanded(
              flex: 34,
              child: _buildHeaderCell(
                'NAME AND DESCRIPTION',
                'name',
                BranchSortState,
                ref,
              ),
            ),
          if (cols['itemsCovered']!)
            Expanded(
              flex: 12,
              child: _buildHeaderCell(
                'ITEMS COVERED',
                'itemsCovered',
                BranchSortState,
                ref,
                sortable: false,
              ),
            ),
          if (cols['currency']!)
            Expanded(
              flex: 12,
              child: _buildHeaderCell(
                'CURRENCY',
                'currency',
                BranchSortState,
                ref,
                sortable: false,
              ),
            ),
          if (cols['details']!)
            Expanded(
              flex: 16,
              child: _buildHeaderCell(
                'DETAILS',
                'details',
                BranchSortState,
                ref,
                sortable: false,
              ),
            ),
          if (cols['pricingScheme']!)
            Expanded(
              flex: 14,
              child: _buildHeaderCell(
                'PRICING SCHEME',
                'pricingScheme',
                BranchSortState,
                ref,
                sortable: false,
              ),
            ),
          if (cols['roundOffPreference']!)
            Expanded(
              flex: 16,
              child: _buildHeaderCell(
                'ROUND OFF PREFERENCE',
                'roundOffPreference',
                BranchSortState,
                ref,
                sortable: false,
              ),
            ),
          SizedBox(
            width: 280,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () =>
                        _showColumnCustomizationDialog(context, ref),
                    icon: const Icon(
                      Icons.view_column_outlined,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    tooltip: 'Customize Columns',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColumnCustomizationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Customize Columns',
            style: TextStyle(fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildColumnSwitch(ref, 'Name', 'name'),
                _buildColumnSwitch(ref, 'Items Covered', 'itemsCovered'),
                _buildColumnSwitch(ref, 'Currency', 'currency'),
                _buildColumnSwitch(ref, 'Details', 'details'),
                _buildColumnSwitch(ref, 'Pricing Scheme', 'pricingScheme'),
                _buildColumnSwitch(
                  ref,
                  'Round Off Preference',
                  'roundOffPreference',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColumnSwitch(WidgetRef ref, String label, String key) {
    final cols = ref.watch(branchPriceListColumnProvider);
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: cols[key]!,
      onChanged: (val) {
        ref.read(branchPriceListColumnProvider.notifier).toggleColumn(key);
      },
    );
  }

  Widget _buildHeaderCell(
    String label,
    String columnId,
    BranchSortState BranchSortState,
    WidgetRef ref, {
    bool sortable = true,
  }) {
    final isActive = BranchSortState.column == columnId;

    return InkWell(
      onTap: sortable
          ? () {
              ref.read(branchPriceListSortProvider.notifier).sort(columnId);
            }
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
            ),
          ),
          if (sortable) ...[
            const SizedBox(width: AppTheme.space4),
            Icon(
              isActive
                  ? (BranchSortState.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                  : Icons.unfold_more,
              size: 14,
              color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
          ],
        ],
      ),
    );
  }

  List<BranchPriceList> _sortBranchPriceLists(
    List<BranchPriceList> BranchPriceLists,
    WidgetRef ref,
  ) {
    final sorted = List<BranchPriceList>.from(BranchPriceLists);
    final BranchSortState = ref.watch(branchPriceListSortProvider);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (BranchSortState.column) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'updated':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case 'details':
          comparison = (a.details ?? '').compareTo(b.details ?? '');
          break;
      }

      return BranchSortState.ascending ? comparison : -comparison;
    });

    return sorted;
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    BranchPriceList branchPriceList,
  ) async {
    switch (action) {
      case 'edit':
        ref
            .read(recentHistoryProvider.notifier)
            .addItem(
              RecentItem(
                id: branchPriceList.id,
                title: branchPriceList.name,
                type: 'Price List',
                route: AppRoutes.branchPriceListsEdit,
                extraData: branchPriceList.toJson(),
                timestamp: DateTime.now(),
              ),
            );
        final result = await context.push(
          AppRoutes.branchPriceListsEdit,
          extra: BranchPriceList,
        );
        if (result == true && context.mounted) {
          ZerpaiToast.success(context, 'Price list updated successfully');
        }
        break;
      case 'clone':
        final result = await context.push(
          AppRoutes.branchPriceListsCreate,
          extra: BranchPriceList,
        );
        if (result == true && context.mounted) {
          ZerpaiToast.success(context, 'Price list cloned successfully');
        }
        break;
      case 'deactivate':
        _confirmDeactivate(context, ref, branchPriceList);
        break;
      case 'activate':
        _confirmActivate(context, ref, branchPriceList);
        break;
      case 'delete':
        _confirmDelete(context, ref, branchPriceList);
        break;
    }
  }

  String _getPricingSchemeDisplay(String scheme) {
    switch (scheme) {
      case 'unit_pricing':
        return 'Unit Pricing';
      case 'volume_pricing':
        return 'Volume Pricing';
      case 'markup':
        return 'Markup';
      case 'markdown':
        return 'Markdown';
      case 'per_item_rate':
        return 'Per Item Rate';
      default:
        return scheme;
    }
  }

  void _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    BranchPriceList branchPriceList,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'Deactivate Price List',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to deactivate "${branchPriceList.name}"? This price list will no longer be available for new transactions.',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref
                    .read(branchPriceListNotifierProvider.notifier)
                    .deactivateBranchPriceList(branchPriceList.id);
                if (context.mounted) {
                  ZerpaiToast.success(
                    context,
                    'Price list "${branchPriceList.name}" deactivated',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRedDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Deactivate', style: TextStyle(fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  void _confirmActivate(
    BuildContext context,
    WidgetRef ref,
    BranchPriceList branchPriceList,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'Activate Price List',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Activate "${branchPriceList.name}"? This price list will become available for transactions.',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref
                    .read(branchPriceListNotifierProvider.notifier)
                    .updateBranchPriceList(
                      branchPriceList.copyWith(status: 'active'),
                    );
                if (context.mounted) {
                  ZerpaiToast.success(
                    context,
                    'Price list "${branchPriceList.name}" activated',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Activate', style: TextStyle(fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BranchPriceList branchPriceList,
  ) {
    showZerpaiConfirmationDialog(
      context,
      title: 'Delete Price List',
      message:
          'Are you sure you want to delete "${branchPriceList.name}"?\n\nThis action cannot be undone. All pricing rules associated with this price list will be permanently removed.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    ).then((confirmed) async {
      if (!confirmed) return;
      await ref
          .read(branchPriceListNotifierProvider.notifier)
          .deleteBranchPriceList(branchPriceList.id);
      if (context.mounted) {
        ZerpaiToast.success(
          context,
          'Price list "${branchPriceList.name}" deleted',
        );
      }
    });
  }
}

class _branchPriceListRow extends StatefulWidget {
  final BranchPriceList branchPriceList;
  final String detailsText;
  final String roundOffText;
  final String pricingSchemeDisplay;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;
  final Map<String, bool> visibleColumns;
  final bool readOnly;

  const _branchPriceListRow({
    required this.branchPriceList,
    required this.detailsText,
    required this.roundOffText,
    required this.pricingSchemeDisplay,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
    required this.onAction,
    required this.visibleColumns,
    this.readOnly = false,
  });

  @override
  State<_branchPriceListRow> createState() => _branchPriceListRowState();
}

class _branchPriceListRowState extends State<_branchPriceListRow> {
  bool _isHovered = false;

  void _handleHover(bool hovered) {
    if (_isHovered == hovered) return;
    setState(() => _isHovered = hovered);
  }

  Widget _actionDivider() => Container(
    width: 1,
    height: 12,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: AppTheme.borderColor,
  );

  @override
  Widget build(BuildContext context) {
    final branchPriceList = widget.branchPriceList;
    final cols = widget.visibleColumns;

    return Material(
      color: Colors.white,
      child: InkWell(
        hoverColor: AppTheme.bgLight,
        onHover: _handleHover,
        onTap: widget.readOnly ? null : widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: widget.readOnly
                    ? const SizedBox.shrink()
                    : Checkbox(
                        value: widget.isSelected,
                        onChanged: widget.onSelectionChanged,
                        activeColor: AppTheme.primaryBlue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
              ),
              if (cols['name']!)
                Expanded(
                  flex: 34,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              branchPriceList.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: branchPriceList.status == 'active'
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          if (branchPriceList.isSeasonalEnabled) ...[
                            const SizedBox(width: AppTheme.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space6,
                                vertical: AppTheme.space2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.infoBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.space10,
                                ),
                                border: Border.all(
                                  color: AppTheme.infoBlue.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                (branchPriceList.startDate != null &&
                                        branchPriceList.endDate != null)
                                    ? 'SEASONAL: ${DateFormat('MMM d, y').format(branchPriceList.startDate!)} - ${DateFormat('MMM d, y').format(branchPriceList.endDate!)}'
                                    : 'SEASONAL',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  color: AppTheme.infoBlue,
                                ),
                              ),
                            ),
                          ],
                          if (branchPriceList.status != 'active') ...[
                            const SizedBox(width: AppTheme.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space6,
                                vertical: AppTheme.space2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.borderColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.space10,
                                ),
                              ),
                              child: const Text(
                                'INACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (branchPriceList.description != null &&
                          branchPriceList.description!.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space2),
                        Text(
                          branchPriceList.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              if (cols['itemsCovered']!)
                Expanded(
                  flex: 12,
                  child: Text(
                    _getItemsCoveredText(branchPriceList),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (cols['currency']!)
                Expanded(
                  flex: 12,
                  child: Text(
                    (branchPriceList.currency?.isNotEmpty ?? false)
                        ? branchPriceList.currency!
                        : '-',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              if (cols['details']!)
                Expanded(
                  flex: 16,
                  child: Text(
                    widget.detailsText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (cols['pricingScheme']!)
                Expanded(
                  flex: 14,
                  child: Text(
                    widget.pricingSchemeDisplay,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              if (cols['roundOffPreference']!)
                Expanded(
                  flex: 16,
                  child: Text(
                    widget.roundOffText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              if (!widget.readOnly)
                SizedBox(
                  width: 280,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IgnorePointer(
                      ignoring: !_isHovered,
                      child: AnimatedOpacity(
                        opacity: _isHovered ? 1 : 0,
                        duration: const Duration(milliseconds: 120),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => widget.onAction('edit'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            _actionDivider(),
                            TextButton(
                              onPressed: () => widget.onAction('clone'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Clone',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            _actionDivider(),
                            TextButton(
                              onPressed: () => widget.onAction(
                                branchPriceList.status == 'active'
                                    ? 'deactivate'
                                    : 'activate',
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                branchPriceList.status == 'active'
                                    ? 'Mark as Inactive'
                                    : 'Mark as Active',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            _actionDivider(),
                            TextButton(
                              onPressed: () => widget.onAction('delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.errorRedDark,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getItemsCoveredText(BranchPriceList branchPriceList) {
    if (branchPriceList.priceListType == 'individual_items') {
      // For individual items price lists, show the count of items with custom rates
      return '${branchPriceList.itemRates?.length ?? 0}';
    } else {
      // For all items price lists, we could show total items count
      // For now, showing "-" to indicate it applies to all items
      return '-';
    }
  }
}
