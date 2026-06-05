import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../shared/widgets/z_button.dart';
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
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final MenuController _titleMenuController = MenuController();
  final MenuController _moreMenuController = MenuController();
  String _defaultRetailPriceList = '';

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

  List<String> _defaultPriceListOptions(List<PriceList> priceLists) {
    final names = <String>{
      for (final priceList in priceLists)
        if (priceList.name.trim().isNotEmpty) priceList.name.trim(),
      if (_defaultRetailPriceList.trim().isNotEmpty) _defaultRetailPriceList.trim(),
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return names;
  }

  Future<void> _openDefaultRetailPriceListDialog(
    List<String> priceListOptions,
  ) async {
    final selectedPriceList = await showDialog<String>(
      context: context,
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.68),
      useSafeArea: false,
      builder: (dialogContext) => _DefaultRetailPriceListDialog(
        initialValue: _defaultRetailPriceList,
        priceListOptions: priceListOptions,
      ),
    );

    if (!mounted || selectedPriceList == null) {
      return;
    }

    setState(() => _defaultRetailPriceList = selectedPriceList);
    ZerpaiToast.success(context, 'Default price list updated');
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
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: Colors.white,
          child: ZerpaiLayout(
            pageTitle: '',
            enableBodyScroll: false,
            useTopPadding: false,
            useHorizontalPadding: false,
            actions: const [],
            child: Column(
              children: [
                _buildCustomHeader(context),
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
      ),
    );
  }

  String _titleForTransactionType(String type) {
    switch (type) {
      case 'sales':
        return 'Sales Price Lists';
      case 'purchase':
        return 'Purchase Price Lists';
      default:
        return 'All Price Lists';
    }
  }

  Widget _buildCustomHeader(BuildContext context) {
    final priceListOptions = _defaultPriceListOptions(
      ref.watch(priceListNotifierProvider).valueOrNull ?? const <PriceList>[],
    );
    final currentType = ref.watch(priceListFilterProvider).transactionType;

    final menuItems = [
      ('all', 'All Price Lists'),
      ('sales', 'Sales Price Lists'),
      ('purchase', 'Purchase Price Lists'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space32,
        20,
        AppTheme.space32,
        0,
      ),
      child: Row(
        children: [
          MenuAnchor(
            controller: _titleMenuController,
            style: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: WidgetStatePropertyAll(Colors.white),
              elevation: WidgetStatePropertyAll(4),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
            ),
            menuChildren: menuItems.map((item) {
              return _TitleMenuItem(
                label: item.$2,
                onTap: () {
                  _titleMenuController.close();
                  ref.read(priceListFilterProvider.notifier).setTransactionType(item.$1);
                },
              );
            }).toList(),
            child: InkWell(
              onTap: () {
                if (_titleMenuController.isOpen) {
                  _titleMenuController.close();
                } else {
                  _titleMenuController.open();
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _titleForTransactionType(currentType),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _openDefaultRetailPriceListDialog(priceListOptions),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Default Price List for Retail Transactions: ${_defaultRetailPriceList.trim().isEmpty ? 'Not set' : _defaultRetailPriceList}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextButton.icon(
              onPressed: () async {
                final result = await context.push(AppRoutes.priceListsCreate);
                if (result == true && context.mounted) {
                  ZerpaiToast.success(context, 'Price list created successfully');
                }
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'New',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 8),
          MenuAnchor(
            controller: _moreMenuController,
            alignmentOffset: const Offset(0, 4),
            style: const MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: WidgetStatePropertyAll(Colors.white),
              elevation: WidgetStatePropertyAll(4),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 4),
              ),
            ),
            menuChildren: [
              _MoreSubmenuButton(
                label: 'Import',
                icon: Icons.download_outlined,
                subItems: const [
                  'Import Sales Price List',
                  'Import Purchase Price List',
                ],
              ),
              _MoreSubmenuButton(
                label: 'Export',
                icon: Icons.upload_outlined,
                subItems: const [
                  'Export Sales Price List',
                  'Export Purchase Price List',
                ],
              ),
              _MoreMenuItem(
                icon: Icons.settings_outlined,
                label: 'Disable Price List',
                onTap: () => _moreMenuController.close(),
              ),
            ],
            child: InkWell(
              onTap: () {
                if (_moreMenuController.isOpen) {
                  _moreMenuController.close();
                } else {
                  _moreMenuController.open();
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
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
        ref.read(priceListNotifierProvider.notifier).fetchPriceLists();
      },
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
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data table
                Column(
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
                            (priceList.roundOffPreference?.isNotEmpty ?? false)
                            ? priceList.roundOffPreference!
                            : 'Never mind';

                        return _PriceListRow(
                          priceList: priceList,
                          detailsText: detailsText,
                          roundOffText: roundOffText,
                          pricingSchemeDisplay: _getPricingSchemeDisplay(
                            priceList.pricingScheme,
                          ),
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
              ],
            ),
          ),
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
    final sortState = ref.watch(priceListSortProvider);

    return Container(
      decoration: const BoxDecoration(color: AppTheme.bgLight),
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32),
      child: Row(
        children: [
          Expanded(
            flex: 34,
            child: _buildHeaderCell(
              'NAME AND DESCRIPTION',
              'name',
              sortState,
              ref,
              sortable: false,
            ),
          ),
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
          const SizedBox(width: 240),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String label,
    String columnId,
    SortState sortState,
    WidgetRef ref, {
    bool sortable = true,
    Color? labelColor,
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
                color: labelColor ?? AppTheme.textSecondary,
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
              color: isActive ? AppTheme.textSecondary : AppTheme.textMuted,
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
          AppRoutes.priceListsEdit.replaceAll(':id', priceList.id),
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
                  ZerpaiToast.success(context, 'Price list "${priceList.name}" deleted');
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

class _MoreSubmenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> subItems;

  const _MoreSubmenuButton({
    required this.label,
    required this.icon,
    required this.subItems,
  });

  static ButtonStyle _buttonStyle(Set<WidgetState> states) {
    final active = states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused);
    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        active ? AppTheme.primaryBlue : Colors.white,
      ),
      foregroundColor: WidgetStatePropertyAll(
        active ? Colors.white : AppTheme.textPrimary,
      ),
      iconColor: WidgetStatePropertyAll(
        active ? Colors.white : AppTheme.textSecondary,
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 14),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(220, 36)),
      maximumSize: const WidgetStatePropertyAll(Size(220, 36)),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SubmenuButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (s) => _buttonStyle(s).backgroundColor?.resolve(s),
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (s) => _buttonStyle(s).foregroundColor?.resolve(s),
        ),
        iconColor: WidgetStateProperty.resolveWith<Color?>(
          (s) => _buttonStyle(s).iconColor?.resolve(s),
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(220, 36)),
        maximumSize: const WidgetStatePropertyAll(Size(220, 36)),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
      ),
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        elevation: WidgetStatePropertyAll(4),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
      ),
      menuChildren: subItems
          .map((label) => _MoreSubMenuItem(label: label))
          .toList(),
      child: Row(
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

class _MoreSubMenuItem extends StatelessWidget {
  final String label;

  const _MoreSubMenuItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.hovered)
              ? AppTheme.primaryBlue
              : Colors.white,
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.hovered)
              ? Colors.white
              : AppTheme.textPrimary,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(240, 36)),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        ),
      ),
      onPressed: () {},
      child: Text(label),
    );
  }
}

class _MoreMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const _MoreMenuItem({
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  State<_MoreMenuItem> createState() => _MoreMenuItemState();
}

class _MoreMenuItemState extends State<_MoreMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 220,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: _isHovered ? AppTheme.primaryBlue : Colors.white,
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 15,
                  color: _isHovered ? Colors.white : AppTheme.textSecondary,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _isHovered ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleMenuItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _TitleMenuItem({required this.label, required this.onTap});

  @override
  State<_TitleMenuItem> createState() => _TitleMenuItemState();
}

class _TitleMenuItemState extends State<_TitleMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 200,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: _isHovered ? AppTheme.primaryBlue : Colors.white,
          alignment: Alignment.centerLeft,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _isHovered ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultRetailPriceListDialog extends StatefulWidget {
  final String initialValue;
  final List<String> priceListOptions;

  const _DefaultRetailPriceListDialog({
    required this.initialValue,
    required this.priceListOptions,
  });

  @override
  State<_DefaultRetailPriceListDialog> createState() =>
      _DefaultRetailPriceListDialogState();
}

class _DefaultRetailPriceListDialogState
    extends State<_DefaultRetailPriceListDialog> {
  late String? _selectedPriceList;

  @override
  void initState() {
    super.initState();
    _selectedPriceList = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 66,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Assign the Default Price List for Retail Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(4),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.close,
                          size: 22,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 760,
                    child: Text(
                      'Select the price list that you want to apply by default every time you create a new retail transaction.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 220,
                        child: Text(
                          'Default Price List',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 280,
                        child: FormDropdown<String>(
                          value: _selectedPriceList,
                          items: widget.priceListOptions,
                          hint: 'Select price list',
                          height: 42,
                          allowClear: true,
                          forceDownward: true,
                          menuWidth: 280,
                          menuMaxHeight: 260,
                          itemHeight: 44,
                          fillColor: AppTheme.backgroundColor,
                          displayStringForValue: (value) => value,
                          itemBuilder: (value, isSelected, isHovered) {
                            final active = isSelected || isHovered;
                            return Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              alignment: Alignment.centerLeft,
                              color: active
                                  ? AppTheme.primaryBlue
                                  : AppTheme.backgroundColor,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      value,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: active
                                            ? AppTheme.backgroundColor
                                            : AppTheme.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: active
                                          ? AppTheme.backgroundColor
                                          : AppTheme.primaryBlue,
                                    ),
                                ],
                              ),
                            );
                          },
                          onChanged: (value) {
                            setState(() => _selectedPriceList = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: _selectedPriceList == null
                        ? null
                        : () => Navigator.of(context).pop(_selectedPriceList),
                  ),
                  const SizedBox(width: 12),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceListRow extends StatefulWidget {
  final PriceList priceList;
  final String detailsText;
  final String roundOffText;
  final String pricingSchemeDisplay;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  const _PriceListRow({
    required this.priceList,
    required this.detailsText,
    required this.roundOffText,
    required this.pricingSchemeDisplay,
    required this.onTap,
    required this.onAction,
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

    return Material(
      color: Colors.white,
      child: InkWell(
        hoverColor: AppTheme.bgLight,
        onHover: _handleHover,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space32,
            vertical: AppTheme.space12,
          ),
          child: Row(
            children: [
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
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryBlue,
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
              Expanded(
                flex: 16,
                child: Text(
                  widget.detailsText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.errorRed,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Delete',
                                  style: TextStyle(fontSize: 12, color: AppTheme.errorRed),
                                ),
                              ],
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
}
