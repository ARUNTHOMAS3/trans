import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../core/routing/app_router.dart';
import '../models/pricelist_model.dart';
import '../models/pricelist_pagination.dart';
import '../providers/pricelist_provider.dart';
import '../../../../shared/services/recent_history_service.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

/// Price Lists Screen - Inventory → Items → Price Lists
class PriceListOverviewScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;

  const PriceListOverviewScreen({super.key, this.initialSearchQuery});

  @override
  ConsumerState<PriceListOverviewScreen> createState() =>
      _PriceListOverviewScreenState();
}

class _PriceListOverviewScreenState
    extends ConsumerState<PriceListOverviewScreen> {
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
        ref.read(priceListFilterProvider.notifier).setSearchQuery(initialQuery);
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
        .read(priceListNotifierProvider.notifier)
        .bulkDeletePriceLists(ids);
    setState(() => _selectedIds.clear());
    if (mounted) {
      ZerpaiToast.error(context, '${ids.length} price lists deleted');
    }
  }

  Future<void> _bulkActivate() async {
    final ids = _selectedIds.toList();
    await ref
        .read(priceListNotifierProvider.notifier)
        .bulkActivatePriceLists(ids);
    setState(() => _selectedIds.clear());
    if (mounted) {
      ZerpaiToast.success(context, 'Price lists activated');
    }
  }

  Future<void> _bulkDeactivate() async {
    final ids = _selectedIds.toList();
    await ref
        .read(priceListNotifierProvider.notifier)
        .bulkDeactivatePriceLists(ids);
    setState(() => _selectedIds.clear());
    if (mounted) {
      ZerpaiToast.success(context, 'Price lists deactivated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginationAsync = ref.watch(filteredPriceListPaginationProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(
          LogicalKeyboardKey.keyN,
          control: true,
        ): () async {
          final result = await context.push(AppRoutes.priceListsCreate);
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
          pageTitle: 'All Price Lists',
          enableBodyScroll: false,
          child: Column(
            children: [
              _buildActionsBar(context),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(priceListNotifierProvider.notifier)
                        .fetchPriceLists();
                  },
                  child: paginationAsync.when(
                    data: (pagination) =>
                        _buildPriceListBody(context, ref, pagination),
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
    final filters = ref.watch(priceListFilterProvider);
    final notifier = ref.read(priceListFilterProvider.notifier);

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
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: filters.startDate != null
                      ? DateTimeRange(
                          start: filters.startDate!,
                          end: filters.endDate ?? DateTime.now(),
                        )
                      : null,
                );
                if (picked != null) {
                  notifier.setDateRange(picked.start, picked.end);
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                filters.startDate != null
                    ? '${DateFormat('MMM d').format(filters.startDate!)} - ${DateFormat('MMM d').format(filters.endDate!)}'
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
              width: 240,
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
            const SizedBox(width: 12),

            // New Button
            ElevatedButton.icon(
              onPressed: () async {
                final result = await context.push(AppRoutes.priceListsCreate);
                if (result == true && context.mounted) {
                  ZerpaiToast.success(context, 'Price list created successfully');
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                ),
                minimumSize: const Size(0, AppTheme.buttonHeight),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.space4),
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
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.space32),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          height: 60,
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space24,
              vertical: AppTheme.space12,
            ),
            child: Row(
              children: [
                Container(
                  width: 200,
                  height: AppTheme.space16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.space4),
                  ),
                ),
                const SizedBox(width: AppTheme.space40),
                Container(
                  width: 80,
                  height: AppTheme.space16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.space4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorRedDark,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Price Lists',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(priceListNotifierProvider.notifier).fetchPriceLists();
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
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

  Widget _buildPriceListBody(
    BuildContext context,
    WidgetRef ref,
    PriceListPagination pagination,
  ) {
    final priceLists = pagination.items;
    final filters = ref.watch(priceListFilterProvider);
    if (priceLists.isEmpty && filters.searchQuery.isEmpty) {
      return _buildEmptyState(context);
    }

    // Sort price lists
    final sortedLists = _sortPriceLists(priceLists, ref);

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
                          final priceList = sortedLists[index];
                          final detailsText =
                              priceList.priceListType == 'individual_items'
                              ? 'Per Item Rate'
                              : (priceList.details ?? '-');
                          final roundOffText =
                              (priceList.roundOffPreference?.isNotEmpty ??
                                  false)
                              ? priceList.roundOffPreference!
                              : 'Never mind';

                          return _PriceListRow(
                            priceList: priceList,
                            detailsText: detailsText,
                            roundOffText: roundOffText,
                            pricingSchemeDisplay: _getPricingSchemeDisplay(
                              priceList.pricingScheme,
                            ),
                            isSelected: _selectedIds.contains(priceList.id),
                            visibleColumns: ref.watch(priceListColumnProvider),
                            onSelectionChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(priceList.id);
                                } else {
                                  _selectedIds.remove(priceList.id);
                                }
                              });
                            },
                            onTap: () => context.go(
                              AppRoutes.priceListsEdit.replaceAll(
                                ':id',
                                priceList.id,
                              ),
                              extra: priceList,
                            ),
                            onAction: (action) =>
                                _handleAction(context, ref, action, priceList),
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

  Widget _buildPaginationFooter(PriceListPagination pagination) {
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
        ref.read(priceListLimitProvider.notifier).state = value;
        ref.read(priceListPageProvider.notifier).state = 1;
        ref.read(priceListNotifierProvider.notifier).fetchPriceLists();
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
                  ref.read(priceListPageProvider.notifier).state = prevPage;
                  ref
                      .read(priceListNotifierProvider.notifier)
                      .fetchPriceLists();
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
                  ref.read(priceListPageProvider.notifier).state = nextPage;
                  ref
                      .read(priceListNotifierProvider.notifier)
                      .fetchPriceLists();
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
              'No Price Lists Yet',
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
              onPressed: () => context.go(AppRoutes.priceListsCreate),
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

  Widget _buildTableHeader(List<PriceList> priceLists, WidgetRef ref) {
    final allSelected =
        priceLists.isNotEmpty &&
        priceLists.every((pl) => _selectedIds.contains(pl.id));
    final cols = ref.watch(priceListColumnProvider);
    final sortState = ref.watch(priceListSortProvider);

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
                    _selectedIds.addAll(priceLists.map((pl) => pl.id));
                  } else {
                    _selectedIds.removeAll(priceLists.map((pl) => pl.id));
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
                sortState,
                ref,
              ),
            ),
          if (cols['itemsCovered']!)
            Expanded(
              flex: 12,
              child: _buildHeaderCell(
                'ITEMS COVERED',
                'itemsCovered',
                sortState,
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
                sortState,
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
                sortState,
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
                sortState,
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
                sortState,
                ref,
                sortable: false,
              ),
            ),
          SizedBox(
            width: 240,
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
    final cols = ref.watch(priceListColumnProvider);
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: cols[key]!,
      onChanged: (val) {
        ref.read(priceListColumnProvider.notifier).toggleColumn(key);
      },
    );
  }

  Widget _buildHeaderCell(
    String label,
    String columnId,
    SortState sortState,
    WidgetRef ref, {
    bool sortable = true,
  }) {
    final isActive = sortState.column == columnId;

    return InkWell(
      onTap: sortable
          ? () {
              ref.read(priceListSortProvider.notifier).sort(columnId);
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
                  ? (sortState.ascending
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

  List<PriceList> _sortPriceLists(List<PriceList> priceLists, WidgetRef ref) {
    final sorted = List<PriceList>.from(priceLists);
    final sortState = ref.watch(priceListSortProvider);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (sortState.column) {
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

      return sortState.ascending ? comparison : -comparison;
    });

    return sorted;
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    PriceList priceList,
  ) async {
    switch (action) {
      case 'edit':
        ref
            .read(recentHistoryProvider.notifier)
            .addItem(
              RecentItem(
                id: priceList.id,
                title: priceList.name,
                type: 'Price List',
                route: AppRoutes.priceListsEdit,
                extraData: priceList.toJson(),
                timestamp: DateTime.now(),
              ),
            );
        final result = await context.push(
          AppRoutes.priceListsEdit,
          extra: priceList,
        );
        if (result == true && context.mounted) {
          ZerpaiToast.success(context, 'Price list updated successfully');
        }
        break;
      case 'clone':
        final result = await context.push(
          AppRoutes.priceListsCreate,
          extra: priceList,
        );
        if (result == true && context.mounted) {
          ZerpaiToast.success(context, 'Price list cloned successfully');
        }
        break;
      case 'deactivate':
        _confirmDeactivate(context, ref, priceList);
        break;
      case 'activate':
        _confirmActivate(context, ref, priceList);
        break;
      case 'delete':
        _confirmDelete(context, ref, priceList);
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
    PriceList priceList,
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
            'Are you sure you want to deactivate "${priceList.name}"? This price list will no longer be available for new transactions.',
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
                    .read(priceListNotifierProvider.notifier)
                    .deactivatePriceList(priceList.id);
                if (context.mounted) {
                  ZerpaiToast.success(context, 'Price list "${priceList.name}" deactivated');
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
    PriceList priceList,
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
            'Activate "${priceList.name}"? This price list will become available for transactions.',
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
                    .read(priceListNotifierProvider.notifier)
                    .updatePriceList(priceList.copyWith(status: 'active'));
                if (context.mounted) {
                  ZerpaiToast.success(context, 'Price list "${priceList.name}" activated');
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
    PriceList priceList,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'Delete Price List',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.errorRedDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${priceList.name}"?',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone. All pricing rules associated with this price list will be permanently removed.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
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
                    .read(priceListNotifierProvider.notifier)
                    .deletePriceList(priceList.id);
                if (context.mounted) {
                  ZerpaiToast.error(context, 'Price list "${priceList.name}" deleted');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRedDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Delete', style: TextStyle(fontSize: 13)),
            ),
          ],
        );
      },
    );
  }
}

class _PriceListRow extends StatefulWidget {
  final PriceList priceList;
  final String detailsText;
  final String roundOffText;
  final String pricingSchemeDisplay;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;
  final Map<String, bool> visibleColumns;

  const _PriceListRow({
    required this.priceList,
    required this.detailsText,
    required this.roundOffText,
    required this.pricingSchemeDisplay,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
    required this.onAction,
    required this.visibleColumns,
  });

  @override
  State<_PriceListRow> createState() => _PriceListRowState();
}

class _PriceListRowState extends State<_PriceListRow> {
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
    final priceList = widget.priceList;
    final cols = widget.visibleColumns;

    return Material(
      color: Colors.white,
      child: InkWell(
        hoverColor: AppTheme.bgLight,
        onHover: _handleHover,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Checkbox(
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
                              priceList.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: priceList.status == 'active'
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          if (priceList.status != 'active') ...[
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
                      if (priceList.description != null &&
                          priceList.description!.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space2),
                        Text(
                          priceList.description!,
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
                    _getItemsCoveredText(priceList),
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
                    (priceList.currency?.isNotEmpty ?? false)
                        ? priceList.currency!
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
              SizedBox(
                width: 240,
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
                              priceList.status == 'active'
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
                              priceList.status == 'active'
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

  String _getItemsCoveredText(PriceList priceList) {
    if (priceList.priceListType == 'individual_items') {
      // For individual items price lists, show the count of items with custom rates
      return '${priceList.itemRates?.length ?? 0}';
    } else {
      // For all items price lists, we could show total items count
      // For now, showing "-" to indicate it applies to all items
      return '-';
    }
  }
}
