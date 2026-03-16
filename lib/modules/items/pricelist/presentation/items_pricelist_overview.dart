import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../core/routing/app_router.dart';
import '../models/pricelist_model.dart';
import '../providers/pricelist_provider.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';

/// Price Lists Screen - Inventory → Items → Price Lists
class PriceListOverviewScreen extends ConsumerStatefulWidget {
  const PriceListOverviewScreen({super.key});

  @override
  ConsumerState<PriceListOverviewScreen> createState() =>
      _PriceListOverviewScreenState();
}

class _PriceListOverviewScreenState
    extends ConsumerState<PriceListOverviewScreen> {
  String _sortColumn = 'name';
  bool _sortAscending = true;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceListsAsync = ref.watch(filteredPriceListsProvider);

    return ZerpaiLayout(
      pageTitle: 'All Price Lists',
      enableBodyScroll: false, // Disable scroll - this screen manages its own
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
              child: priceListsAsync.when(
                data: (priceLists) =>
                    _buildPriceListBody(context, ref, priceLists),
                loading: () => _buildLoadingSkeleton(),
                error: (error, stack) => _buildErrorState(context, ref, error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 240,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              ref.read(priceListFilterProvider.notifier).setSearchQuery(value);
            },
            decoration: const InputDecoration(
              hintText: 'Search in Price Lists',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => context.push(AppRoutes.priceListsCreate),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Price List'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            minimumSize: const Size(0, 36),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: 8,
      itemBuilder: (context, index) => Container(
        height: 60,
        margin: const EdgeInsets.only(bottom: 1),
        color: index.isEven ? const Color(0xFFF9FAFB) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 200,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 40),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
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
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Price Lists',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(priceListNotifierProvider.notifier).fetchPriceLists();
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
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
    List<PriceList> priceLists,
  ) {
    if (priceLists.isEmpty) {
      return _buildEmptyState(context);
    }

    // Sort price lists
    final sortedLists = _sortPriceLists(priceLists);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table header
                _buildTableHeader(),
                // Table rows
                ...sortedLists.asMap().entries.map((entry) {
                  return _buildTableRow(context, ref, entry.value, entry.key);
                }),
              ],
            ),
          ),
        ],
      ),
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
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(48),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Price Lists Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Price lists let you define custom prices for items.\n'
              'Create different pricing rules based on customer type, '
              'sales channel, contracts, or regions.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push(AppRoutes.priceListsCreate);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create your first price list'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
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

  /// Table Header - Columns: Name, Type, Status, Currency, Items Covered, Last Updated
  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 25, child: _buildHeaderCell('NAME', 'name')),
          Expanded(
            flex: 12,
            child: _buildHeaderCell(
              'TRANSACTION',
              'transactionType',
              sortable: false,
            ),
          ),
          Expanded(
            flex: 15,
            child: _buildHeaderCell(
              'PRICE LIST TYPE',
              'priceListType',
              sortable: false,
            ),
          ),
          Expanded(
            flex: 20,
            child: _buildHeaderCell('DETAILS', 'details', sortable: false),
          ),
          Expanded(
            flex: 15,
            child: _buildHeaderCell('PRICING SCHEME', 'type', sortable: false),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String label,
    String columnId, {
    bool sortable = true,
  }) {
    final isActive = _sortColumn == columnId;

    return InkWell(
      onTap: sortable
          ? () {
              setState(() {
                if (_sortColumn == columnId) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortColumn = columnId;
                  _sortAscending = true;
                }
              });
            }
          : null,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? AppTheme.primaryBlue : const Color(0xFF374151),
            ),
          ),
          if (sortable) ...[
            const SizedBox(width: 4),
            Icon(
              isActive
                  ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                  : Icons.unfold_more,
              size: 16,
              color: isActive ? AppTheme.primaryBlue : const Color(0xFF9CA3AF),
            ),
          ],
        ],
      ),
    );
  }

  /// Table Row - Each row = one pricing rule set
  /// Clicking row opens Price List Detail (no inline editing to prevent pricing disasters)
  Widget _buildTableRow(
    BuildContext context,
    WidgetRef ref,
    PriceList priceList,
    int index,
  ) {
    return InkWell(
      onTap: () {
        context.push('/price-lists/edit', extra: priceList);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Name column (25%)
            Expanded(
              flex: 25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        priceList.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: priceList.status == 'active'
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          priceList.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: priceList.status == 'active'
                                ? const Color(0xFF166534)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (priceList.description != null &&
                      priceList.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      priceList.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Transaction Type (10%)
            Expanded(
              flex: 12,
              child: Text(
                priceList.transactionType,
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
            ),
            // Price List Type (15%)
            Expanded(
              flex: 15,
              child: Text(
                priceList.priceListType == 'all_items'
                    ? 'All Items'
                    : 'Individual Items',
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
            ),
            // Details column (20%)
            Expanded(
              flex: 20,
              child: Text(
                priceList.details ?? '',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // Pricing Scheme column (15%)
            Expanded(
              flex: 15,
              child: Text(
                _getPricingSchemeDisplay(priceList.pricingScheme),
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
            ),
            // Actions
            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                onSelected: (value) {
                  _handleAction(context, ref, value, priceList);
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xFF374151),
                        ),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PriceList> _sortPriceLists(List<PriceList> priceLists) {
    final sorted = List<PriceList>.from(priceLists);

    sorted.sort((a, b) {
      int comparison = 0;

      switch (_sortColumn) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'updated':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return sorted;
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    PriceList priceList,
  ) {
    switch (action) {
      case 'edit':
        context.push('/price-lists/edit', extra: priceList);
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
          title: const Text(
            'Deactivate Price List',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          content: Text(
            'Are you sure you want to deactivate "${priceList.name}"? This price list will no longer be available for new transactions.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref
                    .read(priceListNotifierProvider.notifier)
                    .deactivatePriceList(priceList.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Price list "${priceList.name}" deactivated',
                      ),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Deactivate'),
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
          title: const Text(
            'Activate Price List',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          content: Text(
            'Activate "${priceList.name}"? This price list will become available for transactions.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref
                    .read(priceListNotifierProvider.notifier)
                    .updatePriceList(priceList.copyWith(status: 'active'));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Price list "${priceList.name}" activated'),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Activate'),
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
          title: const Text(
            'Delete Price List',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFDC2626),
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
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone. All pricing rules associated with this price list will be permanently removed.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref
                    .read(priceListNotifierProvider.notifier)
                    .deletePriceList(priceList.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Price list "${priceList.name}" deleted'),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
