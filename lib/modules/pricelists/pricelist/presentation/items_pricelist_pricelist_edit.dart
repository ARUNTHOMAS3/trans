import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/services/recent_history_service.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import '../models/pricelist_model.dart';
import '../providers/pricelist_provider.dart';

/// Price List Edit Screen - Inventory → Items → Price Lists → Edit
class PriceListEditScreen extends ConsumerStatefulWidget {
  final PriceList? priceList;
  final String? priceListId;

  const PriceListEditScreen({super.key, this.priceList, this.priceListId});

  @override
  ConsumerState<PriceListEditScreen> createState() =>
      _PriceListEditScreenState();
}

class _PriceListEditScreenState extends ConsumerState<PriceListEditScreen> {
  static const double _formFieldWidth = 320;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _percentageController;
  final _searchItemController = TextEditingController();
  final _searchFocusNode = FocusNode();

  late String _transactionType;
  late String _priceListType;
  late String _pricingScheme;
  late String _percentageType;
  late String _roundOffTo;
  late bool _isDiscountEnabled;
  late String _status;
  late String _currencyCode;
  bool _isSubmitting = false;
  PriceList? _currentPriceList;
  // ignore: unused_field
  final _popoverController = MenuController();

  final Map<String, PriceListItemRate> _itemRateOverrides = {};
  final Map<String, TextEditingController> _rateControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};
  final Map<String, TextEditingController> _volStartControllers = {};
  final Map<String, TextEditingController> _volEndControllers = {};
  final Map<String, TextEditingController> _volRateControllers = {};
  final Map<String, TextEditingController> _volDiscountControllers = {};
  final Set<String> _selectedItemIds = {};
  String _searchQuery = '';
  bool _isSearchVisible = false;
  bool _isBulkUpdateMode = false;
  bool _isImportPriceListEnabled = false;
  String? _hoveredBulkRateItemId;

  @override
  void initState() {
    super.initState();
    // Initialize all late fields with safe defaults so first build never hits uninitialized access
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _percentageController = TextEditingController();
    _transactionType = 'sales';
    _priceListType = 'all_items';
    _pricingScheme = 'percentage';
    _percentageType = 'Markup';
    _roundOffTo = RoundOffPreference.neverMind.displayName;
    _isDiscountEnabled = false;
    _status = 'active';
    _currencyCode = 'INR';

    if (widget.priceList != null) {
      _currentPriceList = widget.priceList;
      _initializeFromPriceList(widget.priceList!);
    } else if (widget.priceListId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchPriceList();
      });
    }
  }

  void _initializeFromPriceList(PriceList p) {
    // Parse percentage from details if all_items
    String pctValue = '';
    String pctType = 'Markup';
    if (p.priceListType == 'all_items') {
      final details = p.details ?? '';
      final match = RegExp(r'(\d+\.?\d*)').firstMatch(details);
      if (match != null) pctValue = match.group(0)!;
      if (details.contains('Markdown')) pctType = 'Markdown';
    }
    _nameController.dispose();
    _descriptionController.dispose();
    _percentageController.dispose();
    _nameController = TextEditingController(text: p.name);
    _descriptionController = TextEditingController(text: p.description ?? '');
    _percentageController = TextEditingController(text: pctValue);
    _percentageType = pctType;

    _currencyCode = p.currency ?? 'INR';
    _percentageType = pctType;

    _transactionType = p.transactionType.toLowerCase();
    _priceListType = p.priceListType;
    _pricingScheme = p.pricingScheme;
    _roundOffTo =
        p.roundOffPreference ?? RoundOffPreference.neverMind.displayName;
    _isDiscountEnabled = p.isDiscountEnabled;
    _status = p.status;

    // Track in recent history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(recentHistoryProvider.notifier)
          .addItem(
            RecentItem(
              id: p.id,
              title: p.name,
              type: 'Price List',
              route: AppRoutes.priceListsEdit,
              extraData: p.toJson(),
              timestamp: DateTime.now(),
            ),
          );
    });

    // Load existing overrides
    if (p.itemRates != null) {
      for (var rate in p.itemRates!) {
        _itemRateOverrides[rate.itemId] = rate;
      }
    }

    _percentageController.addListener(_handleGlobalPercentageChange);
  }

  Future<void> _fetchPriceList() async {
    try {
      final p = await ref
          .read(priceListNotifierProvider.notifier)
          .fetchPriceListById(widget.priceListId!);
      if (mounted && p != null) {
        _initializeFromPriceList(p);
        setState(() {
          _currentPriceList = p;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _handleGlobalPercentageChange() {
    if (_priceListType == 'all_items') {
      _updateAllItemControllers();
      setState(() {});
    }
  }

  void _updateAllItemControllers() {
    _rateControllers.forEach((itemId, controller) {
      final rate = _itemRateOverrides[itemId];
      final calcRate = _calculateRate(rate?.salesRate ?? 0);
      final formattedRate = _formatDouble(calcRate);
      if (controller.text != formattedRate) {
        controller.text = formattedRate;
      }

      if (_discountControllers.containsKey(itemId) &&
          rate?.salesRate != null &&
          rate!.salesRate! > 0) {
        final disc = ((rate.salesRate! - calcRate) / rate.salesRate!) * 100;
        final formattedDisc = _formatDouble(disc);
        if (_discountControllers[itemId]!.text != formattedDisc) {
          _discountControllers[itemId]!.text = formattedDisc;
        }
      }
    });
  }

  TextEditingController _getRateController(
    String itemId,
    double? initialValue,
  ) {
    if (!_rateControllers.containsKey(itemId)) {
      _rateControllers[itemId] = TextEditingController(
        text: (initialValue != null && initialValue != 0)
            ? _formatDouble(initialValue)
            : '',
      );
    }
    return _rateControllers[itemId]!;
  }

  TextEditingController _getDiscountController(
    String itemId,
    double? initialValue,
  ) {
    if (!_discountControllers.containsKey(itemId)) {
      _discountControllers[itemId] = TextEditingController(
        text: (initialValue != null && initialValue != 0)
            ? _formatDouble(initialValue)
            : '',
      );
    }
    return _discountControllers[itemId]!;
  }

  TextEditingController _getVolCtrl(
    Map<String, TextEditingController> cache,
    String key,
    double? initialValue,
  ) {
    if (!cache.containsKey(key)) {
      cache[key] = TextEditingController(
        text: (initialValue != null && initialValue != 0)
            ? _formatDouble(initialValue)
            : '',
      );
    }
    return cache[key]!;
  }

  double _calculateRate(double baseRate) {
    final percentage = double.tryParse(_percentageController.text) ?? 0.0;
    double rate = baseRate;

    if (_percentageType == 'Markup') {
      rate = baseRate * (1 + percentage / 100);
    } else {
      rate = baseRate * (1 - percentage / 100);
    }

    switch (_roundOffTo) {
      case '0.99':
        rate = rate.floorToDouble() + 0.99;
        break;
      case '0.50':
        rate = (rate * 2).roundToDouble() / 2;
        break;
      case '0.49':
        rate = rate.floorToDouble() + 0.49;
        break;
      case 'Nearest whole number':
        rate = rate.roundToDouble();
        break;
      default:
        break;
    }
    return rate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _percentageController.dispose();
    _searchItemController.dispose();
    _searchFocusNode.dispose();
    for (var c in _rateControllers.values) {
      c.dispose();
    }
    for (var c in _discountControllers.values) {
      c.dispose();
    }
    for (var c in _volStartControllers.values) {
      c.dispose();
    }
    for (var c in _volEndControllers.values) {
      c.dispose();
    }
    for (var c in _volRateControllers.values) {
      c.dispose();
    }
    for (var c in _volDiscountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _itemKey(dynamic item) {
    final raw = item.id ?? item.itemCode ?? item.sku ?? item.productName ?? '';
    return raw.toString();
  }

  String _formatDouble(double? value) {
    if (value == null) return '';
    String s = value.toString();
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      if (s.endsWith('.')) {
        s = s.substring(0, s.length - 1);
      }
    }
    return s;
  }

  void _showSearch() {
    setState(() => _isSearchVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _clearSearch() {
    setState(() {
      _isSearchVisible = false;
      _searchQuery = '';
      _searchItemController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.priceLists);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: Colors.white,
          child: ZerpaiLayout(
            pageTitle: 'Edit Price List',
            enableBodyScroll: false,
            useTopPadding: false,
            footer: _buildFooterActions(context),
            actions: [
              InkWell(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.priceLists);
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: const Icon(
                  Icons.close,
                  size: 22,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            child: Column(
              children: [
                const Divider(height: 1, color: AppTheme.borderLight),
                Expanded(child: _buildFormContent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    if (_currentPriceList == null) {
      return const Skeletonizer(
        ignoreContainers: true,
        enabled: true,
        child: ZFormSkeleton(),
      );
    }

    final savedRates = _currentPriceList!.itemRates ?? <PriceListItemRate>[];
    final List<PriceListItemRate> items = _searchQuery.isEmpty
        ? savedRates
        : savedRates.where((r) {
            final name = (r.itemName ?? '').toLowerCase();
            final sku = (r.sku ?? '').toLowerCase();
            final query = _searchQuery.toLowerCase().trim();
            return name.contains(query) || sku.contains(query);
          }).toList();

    return Form(
      key: _formKey,
      child: CustomScrollView(
        key: const ValueKey('pricelist_edit_scrollview'),
        slivers: [
          // 1. General Info Section
          SliverPadding(
            padding: const EdgeInsets.only(top: AppTheme.space24),
            sliver: SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGeneralInformationSection(),
                    const SizedBox(height: AppTheme.space48),
                    if (_priceListType == 'individual_items')
                      _buildIndividualItemsHeader(items),
                  ],
                ),
              ),
            ),
          ),

          // 2. Sticky Table Header
          if (_priceListType == 'individual_items')
            SliverPersistentHeader(
              pinned: true,
              delegate: _TableHeaderDelegate(
                child: Container(
                  key: const ValueKey('edit_table_header_container'),
                  color: Colors.white,
                  child: Container(
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: AppTheme.borderLight),
                        bottom: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isBulkUpdateMode)
                          SizedBox(
                            width: AppTheme.space32,
                            child: Center(
                              child: _buildBulkRateCheckbox(
                                value: items.isNotEmpty &&
                                    items.every(
                                      (r) => _selectedItemIds.contains(r.itemId),
                                    ),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedItemIds.addAll(
                                        items
                                            .map((r) => r.itemId)
                                            .where((id) => id.isNotEmpty),
                                      );
                                    } else {
                                      _selectedItemIds.clear();
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        Expanded(
                          flex: 40,
                          child: _buildSearchTableHeader('ITEM DETAILS'),
                        ),
                        _buildTableDivider(),
                        Expanded(
                          flex: 15, // 1.5
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _tileHeader(
                              _transactionType == 'sales'
                                  ? 'SALES RATE'
                                  : 'PURCHASE RATE',
                            ),
                          ),
                        ),
                        if (_priceListType != 'all_items') ...[
                          _buildTableDivider(),
                          if (_pricingScheme == 'volume_pricing') ...[
                          Expanded(
                            flex: 10, // 1
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _tileHeader(
                                'START QTY',
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space6,
                                  vertical: AppTheme.space10,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 10, // 1
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _tileHeader(
                                'END QTY',
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space6,
                                  vertical: AppTheme.space10,
                                ),
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          flex: 15, // 1.5
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _tileHeader(
                              'CUSTOM RATE',
                              padding: EdgeInsets.symmetric(
                                horizontal: _pricingScheme == 'volume_pricing'
                                    ? AppTheme.space6
                                    : AppTheme.space10,
                                vertical: AppTheme.space10,
                              ),
                            ),
                          ),
                        ),
                        if (_isDiscountEnabled) ...[
                          _buildTableDivider(),
                          Expanded(
                            flex: 10, // 1
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _tileHeader(
                                'DISCOUNT (%)',
                                padding: EdgeInsets.symmetric(
                                  horizontal: _pricingScheme == 'volume_pricing'
                                      ? AppTheme.space6
                                      : AppTheme.space10,
                                  vertical: AppTheme.space10,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_pricingScheme == 'volume_pricing')
                          const SizedBox(width: AppTheme.space32),
                      ],
                    ],
                    ),
                  ),
                ),
              ),
            ),

          // 3. Table Items
          if (_priceListType == 'individual_items')
            SliverPadding(
              padding: EdgeInsets.zero,
              sliver: items.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyItemsState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final rate = items[index];
                        final itemId = rate.itemId;
                        final isSelected =
                            _isBulkUpdateMode &&
                            _selectedItemIds.contains(itemId);
                        final isHovered = _hoveredBulkRateItemId == itemId;
                        return MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hoveredBulkRateItemId = itemId),
                          onExit: (_) {
                            if (_hoveredBulkRateItemId == itemId) {
                              setState(() => _hoveredBulkRateItemId = null);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.infoBg
                                  : (isHovered
                                        ? AppTheme.bgLight
                                        : Colors.white),
                              border: const Border(
                                bottom: BorderSide(color: AppTheme.borderLight),
                              ),
                            ),
                            child: _buildEditableSavedRateRow(rate),
                          ),
                        );
                      }, childCount: items.length),
                    ),
            ),

          if (_isSearchVisible && _priceListType == 'individual_items')
            const SliverToBoxAdapter(child: SizedBox(height: 300)),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSearchTableHeader(String t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    child: Row(
      children: [
        if (!_isSearchVisible) ...[
          Text(
            t.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 16),
            onPressed: _showSearch,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: AppTheme.textSecondary,
          ),
        ] else ...[
          SizedBox(
            width: 300,
            height: 32,
            child: TextField(
              controller: _searchItemController,
              autofocus: true,
              focusNode: _searchFocusNode,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search by Item Name/SKU',
                hintStyle: const TextStyle(fontSize: 12),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: _clearSearch,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildBulkField({
    required String label,
    required Widget child,
    double width = 200,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildBulkLabel(String label) => Expanded(
    child: Text(
      label,
      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
    ),
  );

  Widget _buildIndividualItemsHeader(List<PriceListItemRate> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isBulkUpdateMode)
          _buildBulkUpdateModeToolbar(items)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customise Rates in Bulk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: items.isEmpty ? null : _openBulkUpdateMode,
                      icon: const Icon(LucideIcons.settings, size: 16),
                      label: const Text(
                        'Update Rates in Bulk',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlueDark,
                        disabledForegroundColor: AppTheme.textDisabled,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Import Price List for Items',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: 0.72,
                    child: Switch(
                      value: _isImportPriceListEnabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppTheme.primaryBlueDark,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: AppTheme.borderMid,
                      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.primaryBlueDark;
                        }
                        return AppTheme.borderMid;
                      }),
                      onChanged: (value) {
                        setState(() => _isImportPriceListEnabled = value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  void _openBulkUpdateMode() {
    setState(() => _isBulkUpdateMode = true);
  }

  void _closeBulkUpdateMode() {
    setState(() {
      _isBulkUpdateMode = false;
      _selectedItemIds.clear();
    });
  }

  Widget _buildBulkUpdateModeToolbar(List<PriceListItemRate> items) {
    return Container(
      width: double.infinity,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.selectionActiveBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () => _updateRatesInBulk(items),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlueDark,
              side: const BorderSide(color: AppTheme.borderMid),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Update Rates in Bulk',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _closeBulkUpdateMode,
            icon: const Icon(Icons.close, size: 22),
            color: AppTheme.primaryBlueDark,
            tooltip: '',
          ),
        ],
      ),
    );
  }

  void _updateRatesInBulk(List<PriceListItemRate> items) {
    if (_selectedItemIds.isEmpty) {
      ZerpaiToast.info(context, 'Please select at least one item.');
      return;
    }

    final selectedItems = items
        .where((r) => _selectedItemIds.contains(r.itemId))
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        String updateRule = 'Markup';
        String baseRateField = _transactionType == 'sales'
            ? 'Sales Rate'
            : 'Purchase Rate';
        List<Map<String, dynamic>> bulkRanges = [
          {'start': 1.0, 'end': null, 'value': 0.0, 'unit': '%'},
        ];
        final updateRuleOptions = ['Markup', 'Markdown'];
        final baseRateOptions = ['Sales Rate', 'Purchase Rate'];
        final unitOptions = ['%', '\u20B9'];
        double bulkDiscount = 0.0;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              alignment: Alignment.topCenter,
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.fromLTRB(280, 0, 24, 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 650,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFBFD),
                        border: Border(
                          bottom: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Update Rates in Bulk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(dialogContext),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.primaryBlueDark,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (_pricingScheme == 'unit_pricing') ...[
                            Row(
                              children: [
                                const SizedBox(
                                  width: 120,
                                  child: Text(
                                    'Bulk Update Rule',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: FormDropdown<String>(
                                    value: updateRule,
                                    items: updateRuleOptions,
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    onChanged: (val) => setDialogState(
                                      () => updateRule = val ?? updateRule,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 140,
                                  child: FormDropdown<String>(
                                    value: baseRateField,
                                    items: baseRateOptions,
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    onChanged: (val) => setDialogState(
                                      () =>
                                          baseRateField = val ?? baseRateField,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'by',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 130,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: _formatDouble(
                                            bulkRanges.first['value'],
                                          ),
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          decoration: _inputDecoration(),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 13),
                                          onChanged: (v) =>
                                              bulkRanges.first['value'] =
                                                  double.tryParse(v) ?? 0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 58,
                                        child: FormDropdown<String>(
                                          value: bulkRanges.first['unit'],
                                          items: unitOptions,
                                          height: 34,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          onChanged: (val) => setDialogState(
                                            () => bulkRanges.first['unit'] =
                                                val ?? bulkRanges.first['unit'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isDiscountEnabled) ...[
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Discount (%)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 80,
                                        child: TextFormField(
                                          initialValue: '0',
                                          keyboardType:
                                              const TextInputType
                                                  .numberWithOptions(
                                                    decimal: true,
                                                  ),
                                          decoration: _inputDecoration(
                                            hintText: 'Disc %',
                                          ),
                                          textAlign: TextAlign.right,
                                          style:
                                              const TextStyle(fontSize: 13),
                                          onChanged: (v) => setDialogState(
                                            () =>
                                                bulkDiscount =
                                                    double.tryParse(v) ?? 0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                _buildBulkField(
                                  label: 'Bulk Update Rule',
                                  width: 200,
                                  child: FormDropdown<String>(
                                    value: updateRule,
                                    items: updateRuleOptions,
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    onChanged: (val) => setDialogState(
                                      () => updateRule = val ?? updateRule,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                _buildBulkField(
                                  label: _transactionType == 'sales'
                                      ? 'Sales Rate'
                                      : 'Purchase Rate',
                                  width: 200,
                                  child: FormDropdown<String>(
                                    value: baseRateField,
                                    items: baseRateOptions,
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    onChanged: (val) => setDialogState(
                                      () =>
                                          baseRateField = val ?? baseRateField,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                _buildBulkLabel('Start Quantity'),
                                const SizedBox(width: 16),
                                _buildBulkLabel('End Quantity'),
                                const SizedBox(width: 16),
                                _buildBulkLabel('Update By'),
                                if (_isDiscountEnabled) ...[
                                  const SizedBox(width: 16),
                                  _buildBulkLabel('Discount (%)'),
                                ],
                                const SizedBox(width: 32),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...bulkRanges.asMap().entries.map((entry) {
                              int idx = entry.key;
                              var range = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _formatDouble(
                                          range['start'],
                                        ),
                                        decoration: _inputDecoration(
                                          hintText: 'Start',
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                        onChanged: (v) => range['start'] =
                                            double.tryParse(v) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _formatDouble(
                                          range['end'],
                                        ),
                                        decoration: _inputDecoration(
                                          hintText: 'End',
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                        onChanged: (v) =>
                                            range['end'] = double.tryParse(v),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: range['value']
                                                  .toString(),
                                              decoration: _inputDecoration(),
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                              onChanged: (v) => range['value'] =
                                                  double.tryParse(v) ?? 0,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 60,
                                            child: FormDropdown<String>(
                                              value: range['unit'],
                                              items: unitOptions,
                                              height: 34,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              onChanged: (val) =>
                                                  setDialogState(
                                                    () => range['unit'] =
                                                        val ?? range['unit'],
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_isDiscountEnabled) ...[
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: (range['discount'] ??
                                                  0.0)
                                              .toString(),
                                          decoration: _inputDecoration(
                                            hintText: 'Discount',
                                          ),
                                          style: const TextStyle(fontSize: 13),
                                          onChanged: (v) => range['discount'] =
                                              double.tryParse(v) ?? 0,
                                        ),
                                      ),
                                    ],
                                    if (bulkRanges.length > 1)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: InkWell(
                                          onTap: () => setDialogState(
                                            () => bulkRanges.removeAt(idx),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: AppTheme.errorRed,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 32),
                                  ],
                                ),
                              );
                            }),
                            TextButton.icon(
                              onPressed: () => setDialogState(() {
                                bulkRanges.add({
                                  'start': (bulkRanges.last['end'] ?? 0.0) + 1,
                                  'end': null,
                                  'value': 0.0,
                                  'unit': '%',
                                });
                              }),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 16,
                              ),
                              label: const Text('Add New Range'),
                              style: TextButton.styleFrom(
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                foregroundColor: AppTheme.primaryBlueDark,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Actions
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                for (var rate in selectedItems) {
                                  final itemId = rate.itemId;
                                  final baseValue = rate.salesRate ?? 0.0;

                                  final List<PriceListVolumeRange>
                                  newItemRanges = [];
                                  for (var br in bulkRanges) {
                                    double val = br['value'] as double;
                                    double finalRate = 0;
                                    if (br['unit'] == '%') {
                                      finalRate = updateRule == 'Markup'
                                          ? baseValue * (1 + (val / 100))
                                          : baseValue * (1 - (val / 100));
                                    } else {
                                      finalRate = updateRule == 'Markup'
                                          ? baseValue + val
                                          : baseValue - val;
                                    }
                                    newItemRanges.add(
                                      PriceListVolumeRange(
                                        startQuantity: br['start'] as double,
                                        endQuantity: br['end'] as double?,
                                        customRate: finalRate,
                                        discountPercentage: _isDiscountEnabled
                                            ? (br['discount'] as double? ?? 0.0)
                                            : null,
                                      ),
                                    );
                                  }

                                  final currentOverride =
                                      _itemRateOverrides[itemId] ??
                                      PriceListItemRate(
                                        itemId: itemId,
                                        itemName: rate.itemName,
                                        sku: rate.sku,
                                        salesRate: baseValue,
                                      );

                                  _discountControllers
                                      .remove(itemId)
                                      ?.dispose();

                                  if (_pricingScheme == 'volume_pricing') {
                                    _itemRateOverrides[itemId] = currentOverride
                                        .copyWith(volumeRanges: newItemRanges);
                                  } else {
                                    final disc = _isDiscountEnabled
                                        ? (_pricingScheme == 'unit_pricing'
                                              ? bulkDiscount
                                              : (bulkRanges.first['discount']
                                                      as double? ??
                                                  0.0))
                                        : null;
                                    _itemRateOverrides[itemId] = currentOverride
                                        .copyWith(
                                          customRate:
                                              newItemRanges.first.customRate,
                                          discountPercentage: disc,
                                        );
                                  }
                                }
                              });
                              Navigator.pop(dialogContext);
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Update'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.space4),
      ),
      padding: const EdgeInsets.all(AppTheme.space48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: AppTheme.space16),
            Text(
              'No items found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please create some items first to add them to this price list',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInformationSection() {
    return Column(
      children: [
        _buildLabeledField(
          key: const ValueKey('edit_name_row'),
          label: 'Name',
          required: true,
          child: _halfWidth(
            CustomTextField(
              controller: _nameController,
              height: 34,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Name is required' : null,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildLabeledField(
          label: 'Transaction Type',
          child: IgnorePointer(
            child: ZerpaiRadioGroup<String>(
              options: const ['sales', 'purchase'],
              current: _transactionType,
              labelBuilder: (v) => v == 'sales' ? 'Sales' : 'Purchase',
              onChanged: (_) {},
              activeColor: AppTheme.primaryBlueDark,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildLabeledField(
          label: 'Price List Type',
          child: IgnorePointer(
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _EditTypeCard(
                  selected: _priceListType == 'all_items',
                  title: 'All Items',
                  subtitle: 'Mark up or mark down the rates of all items',
                  onTap: () {},
                ),
                _EditTypeCard(
                  selected: _priceListType == 'individual_items',
                  title: 'Individual Items',
                  subtitle: 'Customize the rate of each item',
                  width: 260,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildLabeledField(
          label: 'Description',
          child: _halfWidth(
            CustomTextField(
              controller: _descriptionController,
              hintText: 'Enter the description',
              height: 58,
              maxLines: 2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_priceListType == 'individual_items') ...[
          _buildLabeledField(
            key: const ValueKey('edit_pricing_scheme_row'),
            label: 'Pricing Scheme',
            child: IgnorePointer(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EditPricingSchemeCard(
                    selected: _pricingScheme == 'unit_pricing',
                    title: 'Unit Pricing',
                    width: 146,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _EditPricingSchemeCard(
                    selected: _pricingScheme == 'volume_pricing',
                    title: 'Volume Pricing',
                    width: 162,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            key: const ValueKey('edit_currency_row'),
            label: 'Currency',
            child: _halfWidth(
              FormDropdown<CurrencyOption>(
                height: 34,
                value: defaultCurrencyOptions.firstWhere(
                  (c) => c.code == _currencyCode,
                  orElse: () => defaultCurrencyOptions.first,
                ),
                items: defaultCurrencyOptions,
                displayStringForValue: (c) => c.label,
                searchStringForValue: (c) => c.label,
                onChanged: (c) {
                  if (c == null) return;
                  setState(() => _currencyCode = c.code);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            key: const ValueKey('edit_discount_row'),
            label: 'Discount',
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _isDiscountEnabled,
                        onChanged: (_) {},
                        activeColor: AppTheme.primaryBlue,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppTheme.textSecondary, width: 1.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'I want to include discount percentage for the items',
                          style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (_priceListType == 'all_items') ...[
          _buildLabeledField(
            key: const ValueKey('edit_percentage_row'),
            label: 'Percentage',
            required: true,
            child: _halfWidth(
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderColorDark),
                  borderRadius: BorderRadius.circular(AppTheme.space4),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: FormDropdown<String>(
                        height: 34,
                        value: _percentageType,
                        items: const ['Markup', 'Markdown'],
                        showSearch: false,
                        showSearchIcon: false,
                        hideBorderDefault: true,
                        menuWidth: 124,
                        onChanged: (val) {
                          if (val != null) setState(() => _percentageType = val);
                        },
                      ),
                    ),
                    Container(width: 1, height: 34, color: AppTheme.borderColorDark),
                    Expanded(
                      child: TextFormField(
                        controller: _percentageController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorStyle: TextStyle(height: 0, fontSize: 0),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          hintText: '0',
                        ),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Container(width: 1, height: 34, color: AppTheme.borderColorDark),
                    Container(
                      width: 42,
                      alignment: Alignment.center,
                      color: AppTheme.inputFill,
                      child: const Text('%', style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            key: const ValueKey('edit_round_off_row'),
            label: 'Round Off To',
            required: true,
            child: _halfWidth(
              FormDropdown<String>(
                height: 34,
                value: _roundOffTo,
                items: const [
                  'Never mind',
                  'Nearest whole number',
                  '0.99',
                  '0.50',
                  '0.49',
                  'Decimal Places',
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _roundOffTo = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _tileHeader(
    String t, {
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: AppTheme.space8,
      vertical: AppTheme.space10,
    ),
  }) => Padding(
    padding: padding,
    child: Text(
      t.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.4,
      ),
    ),
  );

  Widget _buildTableDivider() {
    return Container(
      width: 1,
      color: AppTheme.borderLight,
    );
  }

  Widget _buildEditableSavedRateRow(PriceListItemRate rate) {
    final override = _itemRateOverrides[rate.itemId];
    if (_pricingScheme == 'volume_pricing') {
      final ranges = override?.volumeRanges ??
          rate.volumeRanges ??
          [const PriceListVolumeRange(startQuantity: 1, customRate: 0)];
      return Column(
        children: [
          for (int i = 0; i < ranges.length; i++)
            _buildVolumeRangeRow(
              rate.itemName,
              rate.sku,
              ranges[i],
              i,
              ranges.length,
              rate.itemId,
              rate.salesRate ?? 0,
            ),
          _buildAddVolumeRangeLine(
            rate.itemId,
            rate.itemName ?? '',
            rate.sku,
            rate.salesRate ?? 0,
          ),
        ],
      );
    }

    final salesRate = rate.salesRate ?? 0.0;
    final currentCustomRate = override?.customRate ?? rate.customRate;
    final currentDiscount = override?.discountPercentage ?? rate.discountPercentage;
    final isSelected = _isBulkUpdateMode && _selectedItemIds.contains(rate.itemId);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isBulkUpdateMode) _buildSelectItemCell(rate.itemId, isSelected),
          Expanded(
            flex: 40,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rate.itemName ?? rate.itemId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  if (rate.sku != null && rate.sku!.isNotEmpty)
                    Text(
                      'SKU: ${rate.sku}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
          ),
          _buildTableDivider(),
          Expanded(
            flex: 15,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '₹${_formatDouble(salesRate)}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
                ),
              ),
            ),
          ),
          _buildTableDivider(),
          Expanded(
            flex: 15,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: _tableInputField(
                controller: _getRateController(rate.itemId, currentCustomRate),
                prefixText: '₹',
                textAlign: TextAlign.right,
                onChanged: (val) {
                  final newRate = double.tryParse(val) ?? 0;
                  double? newDiscount;
                  if (salesRate > 0) {
                    newDiscount = ((salesRate - newRate) / salesRate) * 100;
                    _getDiscountController(rate.itemId, newDiscount).text =
                        _formatDouble(newDiscount);
                  }
                  setState(() => _itemRateOverrides[rate.itemId] =
                      (_itemRateOverrides[rate.itemId] ??
                              PriceListItemRate(
                                itemId: rate.itemId,
                                itemName: rate.itemName,
                                sku: rate.sku,
                                salesRate: salesRate,
                              ))
                          .copyWith(customRate: newRate, discountPercentage: newDiscount));
                },
              ),
            ),
          ),
          if (_isDiscountEnabled) ...[
            _buildTableDivider(),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: _tableInputField(
                  controller: _getDiscountController(rate.itemId, currentDiscount),
                  suffixText: '%',
                  textAlign: TextAlign.right,
                  onChanged: (val) {
                    final discount = double.tryParse(val);
                    double? newCustomRate;
                    if (discount != null) {
                      newCustomRate = salesRate * (1 - (discount / 100));
                      _getRateController(rate.itemId, newCustomRate).text =
                          _formatDouble(newCustomRate);
                    }
                    setState(() => _itemRateOverrides[rate.itemId] =
                        (_itemRateOverrides[rate.itemId] ??
                                PriceListItemRate(
                                  itemId: rate.itemId,
                                  itemName: rate.itemName,
                                  sku: rate.sku,
                                  salesRate: salesRate,
                                ))
                            .copyWith(discountPercentage: discount, customRate: newCustomRate));
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildItemRow(dynamic item) {
    final itemId = _itemKey(item);
    final baseRate = _transactionType == 'sales'
        ? ((item.sellingPrice ?? 0.0) as double)
        : ((item.costPrice ?? 0.0) as double);
    final isSelected = _selectedItemIds.contains(itemId);

    if (_pricingScheme == 'unit_pricing') {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isBulkUpdateMode) _buildSelectItemCell(itemId, isSelected),
            _buildItemDetailsCell(item),
            _buildTableDivider(),
            _buildRateCell(baseRate),
            if (_priceListType != 'all_items') ...[
              _buildTableDivider(),
              _buildUnitCustomRateCell(
                itemId,
              item.productName,
              item.sku,
              baseRate,
            ),
            if (_isDiscountEnabled) ...[
              _buildTableDivider(),
              _buildUnitDiscountCell(
                itemId,
                item.productName,
                item.sku,
                baseRate,
              ),
            ],
          ],
        ],
        ),
      );
    } else {
      final override = _itemRateOverrides[itemId];
      final ranges =
          override?.volumeRanges ??
          [const PriceListVolumeRange(startQuantity: 1, customRate: 0)];

      return Column(
        children: [
          for (int i = 0; i < ranges.length; i++)
            _buildVolumeRangeRow(
              item.productName as String?,
              item.sku as String?,
              ranges[i],
              i,
              ranges.length,
              itemId,
              baseRate,
            ),
          _buildAddVolumeRangeLine(
            itemId,
            item.productName,
            item.sku,
            baseRate,
          ),
        ],
      );
    }
  }

  Widget _buildSelectItemCell(String itemId, bool isSelected) => SizedBox(
    width: AppTheme.space32,
    child: Center(
      child: _buildBulkRateCheckbox(
        value: isSelected,
        onChanged: itemId.isEmpty
            ? null
            : (val) {
                setState(() {
                  if (val == true) {
                    _selectedItemIds.add(itemId);
                  } else {
                    _selectedItemIds.remove(itemId);
                  }
                });
              },
      ),
    ),
  );

  Widget _buildBulkRateCheckbox({
    required bool value,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Transform.scale(
      scale: 0.9,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBlue,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: AppTheme.textSecondary, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildItemDetailsCell(dynamic item) => Expanded(
    flex: 40,
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryBlue,
            ),
          ),
          if (item.sku != null && item.sku!.isNotEmpty)
            Text(
              'SKU: ${item.sku}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    ),
  );

  Widget _buildRateCell(double rate) {
    return Expanded(
      flex: 15,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            '\u20B9${_formatDouble(rate)}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCustomRateCell(
    String itemId,
    String name,
    String? sku,
    double baseRate,
  ) {
    final bool isAllItems = _priceListType == 'all_items';
    final double? currentCustomRate = isAllItems
        ? _calculateRate(baseRate)
        : _itemRateOverrides[itemId]?.customRate;
    final controller = _getRateController(itemId, currentCustomRate);

    return Expanded(
      flex: 15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: _tableInputField(
          controller: controller,
          readOnly: isAllItems,
          textAlign: TextAlign.left,
          enabled: !isAllItems || (_selectedItemIds.contains(itemId)),
          onChanged: (val) {
            if (isAllItems) return;
            final rate = double.tryParse(val) ?? 0;
            double? newDiscount;
            if (baseRate > 0) {
              newDiscount = ((baseRate - rate) / baseRate) * 100;
              _getDiscountController(itemId, newDiscount).text = _formatDouble(
                newDiscount,
              );
            }
            setState(
              () => _itemRateOverrides[itemId] =
                  (_itemRateOverrides[itemId] ??
                          PriceListItemRate(
                            itemId: itemId,
                            itemName: name,
                            sku: sku,
                            salesRate: baseRate,
                          ))
                      .copyWith(
                        customRate: rate,
                        discountPercentage: newDiscount,
                      ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnitDiscountCell(
    String itemId,
    String name,
    String? sku,
    double baseRate,
  ) {
    final bool isAllItems = _priceListType == 'all_items';
    double? currentDiscount;
    if (isAllItems) {
      final calcRate = _calculateRate(baseRate);
      if (baseRate > 0) {
        currentDiscount = ((baseRate - calcRate) / baseRate) * 100;
      }
    } else {
      currentDiscount = _itemRateOverrides[itemId]?.discountPercentage;
    }
    final controller = _getDiscountController(itemId, currentDiscount);

    return Expanded(
      flex: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: _tableInputField(
          controller: controller,
          suffixText: '%',
          readOnly: isAllItems,
          textAlign: TextAlign.right,
          enabled: !isAllItems || (_selectedItemIds.contains(itemId)),
          onChanged: (val) {
            if (isAllItems) return;
            final discount = double.tryParse(val);
            double? newCustomRate;
            if (discount != null) {
              newCustomRate = baseRate * (1 - (discount / 100));
              _getRateController(itemId, newCustomRate).text = _formatDouble(
                newCustomRate,
              );
            }
            setState(
              () => _itemRateOverrides[itemId] =
                  (_itemRateOverrides[itemId] ??
                          PriceListItemRate(
                            itemId: itemId,
                            itemName: name,
                            sku: sku,
                            salesRate: baseRate,
                          ))
                      .copyWith(
                        discountPercentage: discount,
                        customRate: newCustomRate,
                      ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVolumeRangeRow(
    String? itemName,
    String? sku,
    PriceListVolumeRange range,
    int idx,
    int totalRanges,
    String itemId,
    double baseRate,
  ) {
    bool isFirst = idx == 0;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isBulkUpdateMode)
            if (isFirst)
              _buildSelectItemCell(itemId, _selectedItemIds.contains(itemId))
            else
              const SizedBox(width: AppTheme.space32),
          if (isFirst)
            Expanded(
              flex: 40,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName ?? itemId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    if (sku != null && sku.isNotEmpty)
                      Text(
                        'SKU: $sku',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                  ],
                ),
              ),
            )
          else
            const Expanded(flex: 40, child: SizedBox()),
          _buildTableDivider(),
          Expanded(
            flex: 15,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '\u20B9${_formatDouble(baseRate)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
        _buildTableDivider(),
        // Start Qty
        Expanded(
          flex: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _tableInputField(
              controller: _getVolCtrl(
                _volStartControllers,
                '${itemId}_$idx',
                range.startQuantity,
              ),
              hintText: 'Start',
              textAlign: TextAlign.right,
              onChanged: (v) => _updateVolumeRange(
                itemId,
                idx,
                itemName: itemName,
                sku: sku,
                salesRate: baseRate,
                startQty: double.tryParse(v),
              ),
            ),
          ),
        ),
        _buildTableDivider(),
        // End Qty
        Expanded(
          flex: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _tableInputField(
              controller: _getVolCtrl(
                _volEndControllers,
                '${itemId}_$idx',
                range.endQuantity,
              ),
              hintText: 'End',
              textAlign: TextAlign.right,
              onChanged: (v) => _updateVolumeRange(
                itemId,
                idx,
                itemName: itemName,
                sku: sku,
                salesRate: baseRate,
                endQty: double.tryParse(v),
              ),
            ),
          ),
        ),
        _buildTableDivider(),
        // Custom Rate
        Expanded(
          flex: 15,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _tableInputField(
              controller: _getVolCtrl(
                _volRateControllers,
                '${itemId}_$idx',
                range.customRate,
              ),
              textAlign: TextAlign.right,
              onChanged: (v) => _updateVolumeRange(
                itemId,
                idx,
                itemName: itemName,
                sku: sku,
                salesRate: baseRate,
                rate: double.tryParse(v),
              ),
            ),
          ),
        ),
        if (_isDiscountEnabled) ...[
          _buildTableDivider(),
          Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: _tableInputField(
                controller: _getVolCtrl(
                  _volDiscountControllers,
                  '${itemId}_$idx',
                  range.discountPercentage,
                ),
                suffixText: '%',
                textAlign: TextAlign.right,
                onChanged: (v) => _updateVolumeRange(
                  itemId,
                  idx,
                  itemName: itemName,
                  sku: sku,
                  salesRate: baseRate,
                  discount: double.tryParse(v),
                ),
              ),
            ),
          ),
        ],
        if (idx > 0)
          SizedBox(
            width: AppTheme.space32,
            child: IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                size: 16,
                color: Colors.red,
              ),
              onPressed: () => _removeVolumeRange(itemId, idx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          )
        else
          const SizedBox(width: AppTheme.space32),
      ],
    ),
    );
  }

  Widget _buildAddVolumeRangeLine(
    String itemId,
    String name,
    String? sku,
    double baseRate,
  ) {
    return Row(
      children: [
        const SizedBox(width: AppTheme.space32), // Checkbox
        const Expanded(flex: 3, child: SizedBox()), // Item details space
        const Expanded(flex: 15, child: SizedBox()), // Sales Rate space
        Expanded(
          flex: 10 + 10 + 15 + (_isDiscountEnabled ? 10 : 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addVolumeRange(itemId, name, sku, baseRate),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text(
                'Add New Range',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space32),
      ],
    );
  }

  Widget _tableInputField({
    required TextEditingController controller,
    String? hintText,
    String? prefixText,
    String? suffixText,
    TextInputType keyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    ),
    void Function(String)? onChanged,
    bool readOnly = false,
    bool enabled = true,
    TextAlign textAlign = TextAlign.left,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      keyboardType: keyboardType,
      textAlign: textAlign,
      onChanged: (val) {
        if (onChanged != null) onChanged(val);
      },
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText ?? '0',
        prefixText: prefixText,
        suffixText: suffixText,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.infoBlue, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  void _clearVolCaches(String itemId) {
    for (final cache in [
      _volStartControllers,
      _volEndControllers,
      _volRateControllers,
      _volDiscountControllers,
    ]) {
      cache.removeWhere((k, v) {
        if (k.startsWith('${itemId}_')) {
          v.dispose();
          return true;
        }
        return false;
      });
    }
  }

  void _addVolumeRange(
    String itemId,
    String name,
    String? sku,
    double salesRate,
  ) {
    _clearVolCaches(itemId);
    setState(() {
      final current =
          _itemRateOverrides[itemId] ??
          PriceListItemRate(
            itemId: itemId,
            itemName: name,
            sku: sku,
            salesRate: salesRate,
            volumeRanges: [],
          );
      final updated = List<PriceListVolumeRange>.from(
        current.volumeRanges ?? [],
      );
      double start = 1;
      if (updated.isNotEmpty && updated.last.endQuantity != null) {
        start = updated.last.endQuantity! + 1;
      }
      updated.add(PriceListVolumeRange(startQuantity: start, customRate: 0));
      _itemRateOverrides[itemId] = current.copyWith(volumeRanges: updated);
    });
  }

  void _updateVolumeRange(
    String itemId,
    int index, {
    String? itemName,
    String? sku,
    double? salesRate,
    double? startQty,
    double? endQty,
    double? rate,
    double? discount,
  }) {
    // Bootstrap override if item was never touched (default display row)
    final current =
        _itemRateOverrides[itemId] ??
        PriceListItemRate(
          itemId: itemId,
          itemName: itemName,
          sku: sku,
          salesRate: salesRate,
          volumeRanges: [
            const PriceListVolumeRange(startQuantity: 1, customRate: 0),
          ],
        );
    final ranges =
        current.volumeRanges ??
        [const PriceListVolumeRange(startQuantity: 1, customRate: 0)];
    final updated = List<PriceListVolumeRange>.from(ranges);
    if (index >= updated.length) return;
    final old = updated[index];
    updated[index] = PriceListVolumeRange(
      startQuantity: startQty ?? old.startQuantity,
      endQuantity: endQty ?? old.endQuantity,
      customRate: rate ?? old.customRate,
      discountPercentage: discount ?? old.discountPercentage,
    );
    setState(
      () =>
          _itemRateOverrides[itemId] = current.copyWith(volumeRanges: updated),
    );
  }

  void _removeVolumeRange(String itemId, int index) {
    _clearVolCaches(itemId);
    setState(() {
      final current = _itemRateOverrides[itemId];
      if (current != null && current.volumeRanges != null) {
        final updated = List<PriceListVolumeRange>.from(current.volumeRanges!);
        updated.removeAt(index);
        _itemRateOverrides[itemId] = current.copyWith(volumeRanges: updated);
      }
    });
  }

  // ignore: unused_element
  Widget _buildRoundingExamplesPopover(MenuController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: CustomPaint(
            size: const Size(12, 8),
            painter: _TrianglePainter(),
          ),
        ),
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rounding Examples',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textBody,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => controller.close(),
                      color: AppTheme.errorRed,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Table(
                  border: TableBorder.all(color: AppTheme.bgDisabled),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: AppTheme.bgLight),
                      children: [
                        _PopHeader('ROUND OFF TO'),
                        _PopHeader('INPUT VALUE'),
                        _PopHeader('ROUNDED VALUE'),
                      ],
                    ),
                    _popRow('Never mind', '1000.678', '1000.678'),
                    _popRow('Nearest whole number', '1000.678', '1001'),
                    _popRow('0.99', '1000.678', '1000.99'),
                    _popRow('0.50', '1000.678', '1000.50'),
                    _popRow('0.49', '1000.678', '1000.49'),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Decimal Places',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryBlueDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _popRow(String c1, String c2, String c3) => TableRow(
    children: [
      _PopCell(c1, isLink: c1 == 'Never mind' || c1 == 'Nearest whole number'),
      _PopCell(c2),
      _PopCell(c3),
    ],
  );

  Widget _buildLabeledField({
    Key? key,
    required String label,
    required Widget child,
    bool required = false,
  }) => Row(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 150,
        child: Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Text(
            required ? '$label*' : label,
            style: TextStyle(
              fontSize: 14,
              color: required ? AppTheme.errorRedDark : AppTheme.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
      Flexible(fit: FlexFit.loose, child: child),
    ],
  );

  Widget _halfWidth(Widget child) => LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      if (!maxWidth.isFinite) {
        return Align(alignment: Alignment.centerLeft, child: child);
      }
      final targetWidth = maxWidth <= _formFieldWidth
          ? maxWidth
          : _formFieldWidth;
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(width: targetWidth, child: child),
      );
    },
  );

  // ignore: unused_element
  Widget _buildRadioOption(
    String g,
    String v,
    ValueChanged<String> o, {
    String? label,
  }) {
    bool isSelected = g == v;
    return InkWell(
      onTap: () => o(v),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.infoBlue : AppTheme.textMuted,
                width: isSelected ? 4 : 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label ?? v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTypeCard(String id, String title, String sub) {
    bool isSelected = _priceListType == id;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('edit_type_card_$id'),
          onTap: () => setState(() {
            _priceListType = id;
            if (id == 'all_items') _pricingScheme = 'unit_pricing';
          }),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.infoBlue.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.infoBlue : AppTheme.borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: isSelected
                          ? AppTheme.infoBlue
                          : AppTheme.borderColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.infoBlue
                              : AppTheme.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? AppTheme.infoBlue.withValues(alpha: 0.8)
                        : AppTheme.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    String? prefixText,
    String? suffixText,
  }) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: hintText,
    prefixText: prefixText,
    suffixText: suffixText,
    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      borderRadius: BorderRadius.circular(4),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppTheme.infoBlue, width: 1.5),
      borderRadius: BorderRadius.circular(4),
    ),
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      borderRadius: BorderRadius.circular(4),
    ),
  );

  Widget _buildFooterActions(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: AppTheme.bgDisabled)),
    ),
    child: Row(
      children: [
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.accentGreen.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.priceLists);
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textBody,
            side: const BorderSide(color: AppTheme.borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      String detailsText = _priceListType == 'all_items'
          ? '${_percentageController.text}% $_percentageType'
          : (_pricingScheme == 'unit_pricing'
                ? 'Fixed Rates'
                : 'Tiered Pricing');
      if (_currentPriceList == null) return;
      final updated = _currentPriceList!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        currency: _currencyCode,
        pricingScheme: _pricingScheme,
        priceListType: _priceListType,
        details: detailsText,
        roundOffPreference: _roundOffTo,
        status: _status,
        transactionType: _transactionType,
        isDiscountEnabled: _isDiscountEnabled,
        itemRates: _priceListType == 'individual_items'
            ? _itemRateOverrides.values.toList()
            : null,
        updatedAt: DateTime.now(),
      );
      await ref
          .read(priceListNotifierProvider.notifier)
          .updatePriceList(updated);
      if (mounted) {
        ZerpaiToast.success(context, 'Price list updated successfully');
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(AppRoutes.priceLists);
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _EditPricingSchemeCard extends StatelessWidget {
  const _EditPricingSchemeCard({
    required this.selected,
    required this.title,
    required this.onTap,
    this.width = 162,
  });

  final bool selected;
  final String title;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: width,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _EditPricingSchemeIndicator(selected: selected),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPricingSchemeIndicator extends StatelessWidget {
  const _EditPricingSchemeIndicator({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFB8BDC5), width: 1.5),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFDCEBFF),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: AppTheme.primaryBlueDark,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _EditTypeCard extends StatelessWidget {
  const _EditTypeCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.width = 370,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: width,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.primaryBlueDark : AppTheme.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 20,
              color: selected ? AppTheme.primaryBlueDark : AppTheme.textDisabled,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
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
}

class _TableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TableHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 42;

  @override
  double get minExtent => 42;

  @override
  bool shouldRebuild(covariant _TableHeaderDelegate oldDelegate) {
    return true;
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _PopHeader extends StatelessWidget {
  final String label;
  const _PopHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _PopCell extends StatelessWidget {
  final String content;
  final bool isLink;
  const _PopCell(this.content, {this.isLink = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 12,
          color: isLink ? AppTheme.primaryBlueDark : AppTheme.textBody,
        ),
      ),
    );
  }
}
