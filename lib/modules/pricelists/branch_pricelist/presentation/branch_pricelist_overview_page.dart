import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../core/routing/app_router.dart';
import '../models/branch_pricelist_model.dart';
import '../models/branch_pricelist_pagination.dart';
import '../providers/branch_pricelist_provider.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import '../../../../shared/services/recent_history_service.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

/// Branch Price Lists Screen - Inventory → Items → Branch Price Lists
class BranchPriceListOverviewScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;

  const BranchPriceListOverviewScreen({super.key, this.initialSearchQuery});

  @override
  ConsumerState<BranchPriceListOverviewScreen> createState() =>
      _BranchPriceListOverviewScreenState();
}

class _BranchPriceListOverviewScreenState
    extends ConsumerState<BranchPriceListOverviewScreen> {
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final MenuController _titleMenuController = MenuController();
  final MenuController _moreMenuController = MenuController();

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialSearchQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final paginationAsync = ref.watch(filteredBranchPriceListPaginationProvider);
    final user = ref.watch(authUserProvider);
    final isRestrictedBranchAdmin =
        user?.role.trim().toLowerCase() == 'branch_admin' &&
        user?.roleIsDefault == true;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () async {
          if (isRestrictedBranchAdmin) {
            if (!context.mounted) return;
            ZerpaiToast.error(
              context,
              'Branch Admin role cannot create Branch Price Lists.',
            );
            return;
          }
          final result = await context.push(AppRoutes.branchPriceListsCreate);
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
                _buildCustomHeader(context, isRestrictedBranchAdmin),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(branchPriceListNotifierProvider.notifier)
                          .fetchBranchPriceLists();
                    },
                    child: paginationAsync.when(
                      data: (pagination) =>
                          _buildBody(
                            context,
                            ref,
                            pagination,
                            isRestrictedBranchAdmin,
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
      ),
    );
  }

  String _titleForTransactionType(String type) {
    switch (type) {
      case 'sales':
        return 'Sales Branch Price Lists';
      case 'purchase':
        return 'Purchase Branch Price Lists';
      default:
        return 'All Branch Price Lists';
    }
  }

  Widget _buildCustomHeader(
    BuildContext context,
    bool isRestrictedBranchAdmin,
  ) {
    final currentType =
        ref.watch(branchPriceListFilterProvider).transactionType;

    final menuItems = [
      ('all', 'All Branch Price Lists'),
      ('sales', 'Sales Branch Price Lists'),
      ('purchase', 'Purchase Branch Price Lists'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.space32, 20, AppTheme.space32, 0),
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
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 4),
              ),
            ),
            menuChildren: menuItems.map((item) {
              return _TitleMenuItem(
                label: item.$2,
                onTap: () {
                  _titleMenuController.close();
                  ref
                      .read(branchPriceListFilterProvider.notifier)
                      .setTransactionType(item.$1);
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
          if (!isRestrictedBranchAdmin) ...[
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentGreen,
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  final result =
                      await context.push(AppRoutes.branchPriceListsCreate);
                  if (result == true && context.mounted) {
                    ZerpaiToast.success(
                      context,
                      'Price list created successfully',
                    );
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
          ],
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
                  'Import Sales Branch Price List',
                  'Import Purchase Branch Price List',
                ],
              ),
              _MoreSubmenuButton(
                label: 'Export',
                icon: Icons.upload_outlined,
                subItems: const [
                  'Export Sales Branch Price List',
                  'Export Purchase Branch Price List',
                ],
              ),
              _MoreMenuItem(
                icon: Icons.settings_outlined,
                label: 'Disable Branch Price List',
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
        ref
            .read(branchPriceListNotifierProvider.notifier)
            .fetchBranchPriceLists();
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    BranchPriceListPagination pagination,
    bool isRestrictedBranchAdmin,
  ) {
    final priceLists = pagination.items;
    final filters = ref.watch(branchPriceListFilterProvider);
    if (priceLists.isEmpty && filters.searchQuery.isEmpty) {
      return _buildEmptyState(context, isRestrictedBranchAdmin);
    }

    final sortedLists = _sortPriceLists(priceLists, ref);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        final pl = sortedLists[index];
                        String detailsText = '-';
                        if (pl.priceListType == 'individual_items') {
                          detailsText = 'Per Item Rate';
                        } else if (pl.percentageValue != null && pl.percentageType != null) {
                          final pctType = pl.percentageType!.isEmpty
                              ? ''
                              : (pl.percentageType![0].toUpperCase() + pl.percentageType!.substring(1).toLowerCase());
                          detailsText = '${pl.percentageValue!.toStringAsFixed(0)}% $pctType';
                        } else {
                          detailsText = pl.details ?? '-';
                        }
                        final roundOffText =
                            (pl.roundOffPreference?.isNotEmpty ?? false)
                                ? pl.roundOffPreference!
                                : 'Never mind';

                        return _BranchPriceListRow(
                          priceList: pl,
                          detailsText: detailsText,
                          roundOffText: roundOffText,
                          pricingSchemeDisplay:
                              _getPricingSchemeDisplay(pl.pricingScheme),
                          onTap: () {},
                          onAction: (action) =>
                              _handleAction(context, ref, action, pl),
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

  Widget _buildEmptyState(
    BuildContext context,
    bool isRestrictedBranchAdmin,
  ) {
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
            if (!isRestrictedBranchAdmin)
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

  Widget _buildTableHeader(List<BranchPriceList> priceLists, WidgetRef ref) {
    final sortState = ref.watch(branchPriceListSortProvider);

    return Container(
      decoration: const BoxDecoration(color: AppTheme.bgLight),
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32),
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: _buildHeaderCell(
              'NAME AND DESCRIPTION',
              'name',
              sortState,
              ref,
              sortable: false,
            ),
          ),
          Expanded(
            flex: 14,
            child: _buildHeaderCell(
              'SEASONAL DATE',
              'seasonalDate',
              sortState,
              ref,
              sortable: false,
            ),
          ),
          Expanded(
            flex: 10,
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
    BranchSortState sortState,
    WidgetRef ref, {
    bool sortable = true,
  }) {
    final isActive = sortState.column == columnId;

    return InkWell(
      onTap: sortable
          ? () => ref.read(branchPriceListSortProvider.notifier).sort(columnId)
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
                color: AppTheme.textSecondary,
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

  List<BranchPriceList> _sortPriceLists(
    List<BranchPriceList> priceLists,
    WidgetRef ref,
  ) {
    final sorted = List<BranchPriceList>.from(priceLists);
    final sortState = ref.watch(branchPriceListSortProvider);

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
    BranchPriceList priceList,
  ) async {
    switch (action) {
      case 'edit':
        ref.read(recentHistoryProvider.notifier).addItem(
              RecentItem(
                id: priceList.id,
                title: priceList.name,
                type: 'Price List',
                route: AppRoutes.branchPriceListsEdit,
                extraData: priceList.toJson(),
                timestamp: DateTime.now(),
              ),
            );
        final result = await context.push(
          AppRoutes.branchPriceListsEdit.replaceAll(':id', priceList.id),
          extra: priceList,
        );
        if (result == true && context.mounted) {
          ZerpaiToast.success(context, 'Price list updated successfully');
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
    BranchPriceList priceList,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref
                  .read(branchPriceListNotifierProvider.notifier)
                  .deactivateBranchPriceList(priceList.id);
              if (context.mounted) {
                ZerpaiToast.success(
                  context,
                  'Price list "${priceList.name}" deactivated',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRedDark,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Deactivate', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _confirmActivate(
    BuildContext context,
    WidgetRef ref,
    BranchPriceList priceList,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref
                  .read(branchPriceListNotifierProvider.notifier)
                  .updateBranchPriceList(
                    priceList.copyWith(status: 'active'),
                  );
              if (context.mounted) {
                ZerpaiToast.success(
                  context,
                  'Price list "${priceList.name}" activated',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Activate', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BranchPriceList priceList,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref
                  .read(branchPriceListNotifierProvider.notifier)
                  .deleteBranchPriceList(priceList.id);
              if (context.mounted) {
                ZerpaiToast.success(
                  context,
                  'Price list "${priceList.name}" deleted',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRedDark,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
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

class _BranchPriceListRow extends StatefulWidget {
  final BranchPriceList priceList;
  final String detailsText;
  final String roundOffText;
  final String pricingSchemeDisplay;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  const _BranchPriceListRow({
    required this.priceList,
    required this.detailsText,
    required this.roundOffText,
    required this.pricingSchemeDisplay,
    required this.onTap,
    required this.onAction,
  });

  @override
  State<_BranchPriceListRow> createState() => _BranchPriceListRowState();
}

class _BranchPriceListRowState extends State<_BranchPriceListRow> {
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
    final pl = widget.priceList;

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
              // Name & Description
              Expanded(
                flex: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            pl.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        if (pl.isSeasonalEnabled) ...[
                          const SizedBox(width: AppTheme.space8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space6,
                              vertical: AppTheme.space2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.infoBlue.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.space10),
                              border: Border.all(
                                color: AppTheme.infoBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'SEASONAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: AppTheme.infoBlue,
                              ),
                            ),
                          ),
                        ],
                        if (pl.status != 'active') ...[
                          const SizedBox(width: AppTheme.space8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space6,
                              vertical: AppTheme.space2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.space10),
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
                    if (pl.description != null &&
                        pl.description!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.space2),
                      Text(
                        pl.description!,
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
              // Seasonal Date
              Expanded(
                flex: 14,
                child: (pl.isSeasonalEnabled && pl.startDate != null && pl.endDate != null)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('MMM d, y').format(pl.startDate!),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              'to',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, y').format(pl.endDate!),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
              ),
              // Currency
              Expanded(
                flex: 10,
                child: Text(
                  (pl.currency?.isNotEmpty ?? false) ? pl.currency! : '-',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              // Details
              Expanded(
                flex: 16,
                child: Text(
                  widget.detailsText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              // Pricing Scheme
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
              // Round Off
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
              // Actions
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
                              pl.status == 'active' ? 'deactivate' : 'activate',
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              pl.status == 'active'
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.errorRed,
                                  ),
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
