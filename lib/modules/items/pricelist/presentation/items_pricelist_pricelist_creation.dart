import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import '../models/pricelist_model.dart';
import '../providers/pricelist_provider.dart';

/// Price List Creation Screen - Inventory → Items → Price Lists → New
///
/// Elegant form following Zerpai Inventory aesthetics for creating new price lists.
class PriceListCreateScreen extends ConsumerStatefulWidget {
  final PriceList? template;

  const PriceListCreateScreen({super.key, this.template});

  @override
  ConsumerState<PriceListCreateScreen> createState() =>
      _PriceListCreateScreenState();
}

class _PriceListCreateScreenState extends ConsumerState<PriceListCreateScreen> {
  static const double _formFieldWidth = 360;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _percentageController = TextEditingController();
  final _searchItemController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _transactionType = 'sales';
  String _priceListType = 'all_items';
  String _pricingScheme = 'unit_pricing';
  String _percentageType = 'Markup';
  String _roundOffTo = 'Never mind';
  String _currencyCode = 'INR';
  bool _isDiscountEnabled = false;
  bool _isSubmitting = false;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  final Set<String> _selectedItemIds = {};
  String? _selectionError;

  final _popoverController = MenuController();
  final Map<String, PriceListItemRate> _itemRateOverrides = {};
  final Map<String, TextEditingController> _rateControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};

  @override
  void initState() {
    super.initState();
    _percentageController.addListener(_handleGlobalPercentageChange);
    if (widget.template != null) {
      _initializeFromTemplate(widget.template!);
    }
  }

  void _initializeFromTemplate(PriceList template) {
    _nameController.text = 'Copy of ${template.name}';
    _descriptionController.text = template.description ?? '';
    _transactionType = template.transactionType;
    _priceListType = template.priceListType;
    _pricingScheme = template.pricingScheme;
    _currencyCode = template.currency ?? 'INR';
    _roundOffTo = template.roundOffPreference ?? 'Never mind';
    _isDiscountEnabled = template.isDiscountEnabled;

    if (_priceListType == 'all_items') {
      final details = template.details ?? '';
      // Parse "10% Markup"
      final parts = details.split('% ');
      if (parts.length == 2) {
        _percentageController.text = parts[0];
        _percentageType = parts[1];
      }
    } else if (template.itemRates != null) {
      for (var rate in template.itemRates!) {
        _itemRateOverrides[rate.itemId] = rate;
      }
      _selectedItemIds.addAll(template.itemRates!.map((r) => r.itemId));
    }
  }

  void _handleGlobalPercentageChange() {
    if (_priceListType == 'all_items') {
      _updateAllItemControllers();
      setState(() {});
    }
  }

  void _updateAllItemControllers() {
    // When in "All Items" mode, refresh all controllers based on global percentage
    _rateControllers.forEach((itemId, controller) {
      final rate = _itemRateOverrides[itemId];
      final calcRate = _calculateRate(rate?.salesRate ?? 0);
      final formattedRate = calcRate.toStringAsFixed(2);
      if (controller.text != formattedRate) {
        controller.text = formattedRate;
      }

      if (_discountControllers.containsKey(itemId) &&
          rate?.salesRate != null &&
          rate!.salesRate! > 0) {
        final disc = ((rate.salesRate! - calcRate) / rate.salesRate!) * 100;
        final formattedDisc = disc.toStringAsFixed(2);
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
        text: initialValue?.toString() ?? '',
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
        text: initialValue?.toString() ?? '',
      );
    }
    return _discountControllers[itemId]!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _percentageController.dispose();
    _searchItemController.dispose();
    _searchFocusNode.dispose();
    for (var controller in _rateControllers.values) {
      controller.dispose();
    }
    for (var controller in _discountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _itemKey(dynamic item) {
    final raw = item.id ?? item.itemCode ?? item.sku ?? item.productName ?? '';
    return raw.toString();
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
    final itemsState = ref.watch(itemsControllerProvider);

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
        child: ZerpaiLayout(
          pageTitle: 'New Price List',
          enableBodyScroll: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Color(0xFF9CA3AF)),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.priceLists);
                }
              },
              tooltip: 'Close',
            ),
          ],
          footer: _buildFooterActions(context),
          child: _buildFormContent(context, itemsState),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, dynamic itemsState) {
    if (itemsState.isLoading) {
      return const FormSkeleton();
    }

    final rawItems = itemsState.items ?? [];
    final items = rawItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      final name = (item.productName ?? '').toString().toLowerCase();
      final sku = (item.sku ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase().trim();
      return name.contains(query) || sku.contains(query);
    }).toList();

    return Form(
      key: _formKey,
      child: CustomScrollView(
        key: const ValueKey('pricelist_create_scrollview'),
        slivers: [
          // 1. General Info & Discount Section
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space40,
              vertical: AppTheme.space24,
            ),
            sliver: SliverToBoxAdapter(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space24,
                  AppTheme.space32,
                  AppTheme.space24,
                  AppTheme.space48,
                ),
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
                  key: const ValueKey('creation_table_header_container'),
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space40 + AppTheme.space24,
                  ),
                  child: Container(
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: AppTheme.borderColor),
                        left: BorderSide(color: AppTheme.borderColor),
                        right: BorderSide(color: AppTheme.borderColor),
                        bottom: BorderSide(color: AppTheme.borderColor),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.space6),
                        topRight: Radius.circular(AppTheme.space6),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: AppTheme.space32,
                          child: Checkbox(
                            value:
                                items.isNotEmpty &&
                                items.every(
                                  (i) => _selectedItemIds.contains(_itemKey(i)),
                                ),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedItemIds.addAll(
                                    items
                                        .map(_itemKey)
                                        .where((id) => id.isNotEmpty)
                                        .cast<String>(),
                                  );
                                  _selectionError = null;
                                } else {
                                  _selectedItemIds.clear();
                                }
                              });
                            },
                            activeColor: AppTheme.primaryBlue,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        Expanded(
                          flex: 40,
                          child: _buildSearchTableHeader('ITEM DETAILS'),
                        ),
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
                        if (_isDiscountEnabled)
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
                        if (_pricingScheme == 'volume_pricing')
                          const SizedBox(width: AppTheme.space32),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 3. Table Items (SliverList)
          if (_priceListType == 'individual_items')
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space40 + AppTheme.space24,
              ),
              sliver: items.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyItemsState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        final isLast = index == items.length - 1;
                        final isSelected = _selectedItemIds.contains(
                          _itemKey(item),
                        );
                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.infoBg : Colors.white,
                            border: Border(
                              left: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                              right: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                              bottom: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                              top: index == 0
                                  ? BorderSide.none
                                  : const BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                            ),
                            borderRadius: isLast
                                ? const BorderRadius.only(
                                    bottomLeft: Radius.circular(
                                      AppTheme.space6,
                                    ),
                                    bottomRight: Radius.circular(
                                      AppTheme.space6,
                                    ),
                                  )
                                : null,
                          ),
                          child: _buildItemRow(item),
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

  Widget _buildGeneralInformationSection() {
    final currencyAsync = ref.watch(currenciesProvider(null));
    final remoteCurrencies = currencyAsync.maybeWhen(
      data: (data) => data,
      orElse: () => const <CurrencyOption>[],
    );
    final currencyOptions = remoteCurrencies.isNotEmpty
        ? remoteCurrencies
        : defaultCurrencyOptions;
    final selectedCurrency = _resolveCurrencyOption(currencyOptions);
    if (currencyOptions.isNotEmpty &&
        !currencyOptions.any((c) => c.code == _currencyCode)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currencyCode = selectedCurrency.code);
      });
    }

    return Column(
      children: [
        _buildLabeledField(
          label: 'Name',
          required: true,
          child: _halfWidth(
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(hintText: 'Enter price list name'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Name is required' : null,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space24),
        _buildLabeledField(
          label: 'Transaction Type',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildRadioOption(
                _transactionType,
                'sales',
                (val) => setState(() => _transactionType = val),
                label: 'Sales',
              ),
              const SizedBox(width: AppTheme.space32),
              _buildRadioOption(
                _transactionType,
                'purchase',
                (val) => setState(() {
                  _transactionType = val;
                  if (val == 'purchase') {
                    _isDiscountEnabled = false;
                  }
                }),
                label: 'Purchase',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space24),
        _buildLabeledField(
          label: 'Price List Type',
          child: _halfWidth(
            Row(
              children: [
                _buildTypeCard(
                  'all_items',
                  'All Items',
                  'Mark up or mark down the rates of all items',
                ),
                const SizedBox(width: AppTheme.space16),
                _buildTypeCard(
                  'individual_items',
                  'Individual Items',
                  'Customize the rate of each item',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space24),
        _buildLabeledField(
          label: 'Description',
          child: _halfWidth(
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.space4),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Enter the description',
                  hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  contentPadding: EdgeInsets.all(AppTheme.space12),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space24),
        if (_priceListType == 'individual_items') ...[
          _buildLabeledField(
            key: const ValueKey('pricing_scheme_row'),
            label: 'Pricing Scheme',
            child: Row(
              children: [
                _buildRadioOption(
                  _pricingScheme,
                  'unit_pricing',
                  (val) => setState(() => _pricingScheme = val),
                  label: 'Unit Pricing',
                ),
                const SizedBox(width: AppTheme.space32),
                _buildRadioOption(
                  _pricingScheme,
                  'volume_pricing',
                  (val) => setState(() => _pricingScheme = val),
                  label: 'Volume Pricing',
                ),
                const SizedBox(width: AppTheme.space8),
                const Icon(
                  Icons.help_outline,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),
        ],
        if (_priceListType == 'all_items') ...[
          _buildLabeledField(
            key: const ValueKey('percentage_row'),
            label: 'Percentage',
            required: true,
            child: _halfWidth(
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderColorDark),
                  borderRadius: BorderRadius.circular(AppTheme.space4),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: FormDropdown<String>(
                        height: 36,
                        value: _percentageType,
                        items: const ['Markup', 'Markdown'],
                        onChanged: (val) =>
                            setState(() => _percentageType = val ?? 'Markup'),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppTheme.borderColorDark,
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _percentageController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.space12,
                            vertical: AppTheme.space12,
                          ),
                          hintText: '0',
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.right,
                        validator: (val) {
                          if (_priceListType == 'all_items' &&
                              (val == null || val.isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppTheme.borderColorDark,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                      ),
                      color: AppTheme.inputFill,
                      alignment: Alignment.center,
                      child: const Text(
                        '%',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          _buildLabeledField(
            key: const ValueKey('round_off_row'),
            label: 'Round Off To',
            required: true,
            child: _halfWidth(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormDropdown<String>(
                    height: 36,
                    value: _roundOffTo,
                    items: const [
                      'Never mind',
                      'Nearest whole number',
                      '0.99',
                      '0.50',
                      '0.49',
                      'Decimal Places',
                    ],
                    isItemEnabled: (item) => item != 'Decimal Places',
                    onChanged: (val) =>
                        setState(() => _roundOffTo = val ?? _roundOffTo),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  MenuAnchor(
                    controller: _popoverController,
                    builder: (context, controller, child) {
                      return GestureDetector(
                        onTap: () => _popoverController.isOpen
                            ? _popoverController.close()
                            : _popoverController.open(),
                        child: const Text(
                          'View Examples',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      );
                    },
                    menuChildren: [
                      _buildRoundingExamplesPopover(_popoverController),
                    ],
                    style: MenuStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      elevation: WidgetStateProperty.all(0),
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space24),
        ],

        if (_priceListType == 'individual_items')
          _buildLabeledField(
            label: 'Currency',
            child: _halfWidth(
              FormDropdown<CurrencyOption>(
                height: 36,
                value: selectedCurrency,
                items: currencyOptions,
                isLoading: currencyAsync.isLoading,
                displayStringForValue: (v) => v.label,
                searchStringForValue: (v) => '${v.code} ${v.name}',
                onSearch: (q) async {
                  return await ref.read(currenciesProvider(q).future);
                },
                onChanged: (val) =>
                    setState(() => _currencyCode = val?.code ?? _currencyCode),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIndividualItemsHeader(List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_transactionType == 'sales')
          _buildLabeledField(
            label: 'Discount',
            child: Row(
              children: [
                Checkbox(
                  value: _isDiscountEnabled,
                  onChanged: (val) => setState(() => _isDiscountEnabled = val!),
                  activeColor: AppTheme.primaryBlue,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'I want to include discount percentage for the items',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (_isDiscountEnabled)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'When a price list is applied, the discount percentage will be applied only if discount is enabled at line-item level.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryBlue,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppTheme.space32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customise Rates in Bulk',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (_selectionError != null) ...[
                  const SizedBox(height: AppTheme.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                      borderRadius: BorderRadius.circular(AppTheme.space4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: AppTheme.errorRedDark,
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Text(
                          _selectionError!,
                          style: const TextStyle(
                            color: AppTheme.errorRedDark,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        GestureDetector(
                          onTap: () => setState(() => _selectionError = null),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppTheme.errorRedDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.space8),
                TextButton.icon(
                  onPressed: () => _updateRatesInBulk(items),
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text(
                    'Update Rates in Bulk',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox.shrink(),
          ],
        ),
      ],
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
            const SizedBox(height: AppTheme.space8),
            const Text(
              'Please create some items first to add them to this price list',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
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

  Widget _buildSearchTableHeader(String t) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space10,
      ),
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
                    horizontal: AppTheme.space8,
                    vertical: AppTheme.space8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.space4),
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
  }

  void _updateRatesInBulk(List<dynamic> items) {
    if (_selectedItemIds.isEmpty) {
      setState(() {
        _selectionError = 'Select the items you want to update in bulk.';
      });
      return;
    }

    final selectedItems = items
        .where((i) => _selectedItemIds.contains(_itemKey(i)))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
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

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              child: SizedBox(
                width: 680,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Update Rates in Bulk',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

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
                                _buildBulkField(
                                  label: 'Bulk Update Rule',
                                  width: 200,
                                  child: FormDropdown<String>(
                                    value: updateRule,
                                    items: updateRuleOptions,
                                    height: 36,
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
                                    height: 36,
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
                                const SizedBox(width: 20),
                                _buildBulkField(
                                  label: 'Update By',
                                  width: 200,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: bulkRanges
                                              .first['value']
                                              .toString(),
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration(),
                                          style: const TextStyle(fontSize: 13),
                                          onChanged: (v) =>
                                              bulkRanges.first['value'] =
                                                  double.tryParse(v) ?? 0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 60,
                                        child: FormDropdown<String>(
                                          value: bulkRanges.first['unit'],
                                          items: unitOptions,
                                          height: 36,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          onChanged: (val) => setDialogState(
                                            () => bulkRanges.first['unit'] =
                                                val ?? bulkRanges.first['unit'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                    height: 36,
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
                                    height: 36,
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
                                _buildBulkLabel('Start Quantity', width: 150),
                                const SizedBox(width: 16),
                                _buildBulkLabel('End Quantity', width: 150),
                                const SizedBox(width: 16),
                                _buildBulkLabel('Update By', width: 200),
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
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        initialValue: range['start'].toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: _inputDecoration(
                                          hintText: 'Start',
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                        onChanged: (v) => range['start'] =
                                            double.tryParse(v) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        initialValue:
                                            range['end']?.toString() ?? '',
                                        keyboardType: TextInputType.number,
                                        decoration: _inputDecoration(
                                          hintText: 'End',
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                        onChanged: (v) =>
                                            range['end'] = double.tryParse(v),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 200,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: range['value']
                                                  .toString(),
                                              keyboardType:
                                                  TextInputType.number,
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
                                              height: 36,
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
                                    if (bulkRanges.length > 1)
                                      SizedBox(
                                        width: 32,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          onPressed: () => setDialogState(
                                            () => bulkRanges.removeAt(idx),
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
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
                                foregroundColor: const Color(0xFF2563EB),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
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
                                for (var item in selectedItems) {
                                  final itemId = _itemKey(item);
                                  double baseValue = 0;
                                  if (baseRateField == 'Sales Rate') {
                                    baseValue =
                                        (item.sellingPrice ?? 0.0) as double;
                                  } else {
                                    baseValue =
                                        (item.costPrice ?? 0.0) as double;
                                  }

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
                                      ),
                                    );
                                  }

                                  final currentOverride =
                                      _itemRateOverrides[itemId] ??
                                      PriceListItemRate(
                                        itemId: itemId,
                                        itemName: item.productName as String,
                                        sku: item.sku as String?,
                                        salesRate: baseValue,
                                      );

                                  if (_pricingScheme == 'volume_pricing') {
                                    _itemRateOverrides[itemId] = currentOverride
                                        .copyWith(volumeRanges: newItemRanges);
                                  } else {
                                    _itemRateOverrides[itemId] = currentOverride
                                        .copyWith(
                                          customRate:
                                              newItemRanges.first.customRate,
                                        );
                                  }
                                }
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28A745),
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
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF374151),
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

  Widget _buildItemRow(dynamic item) {
    final itemId = _itemKey(item);
    final baseRate = _transactionType == 'sales'
        ? ((item.sellingPrice ?? 0.0) as double)
        : ((item.costPrice ?? 0.0) as double);
    final isSelected = _selectedItemIds.contains(itemId);

    if (_pricingScheme == 'unit_pricing') {
      return Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            _buildSelectItemCell(itemId, isSelected),
            _buildItemDetailsCell(item),
            _buildRateCell(baseRate),
            _buildUnitCustomRateCell(
              itemId,
              item.productName,
              item.sku,
              baseRate,
            ),
            if (_isDiscountEnabled)
              _buildUnitDiscountCell(
                itemId,
                item.productName,
                item.sku,
                baseRate,
              ),
          ],
        ),
      );
    } else {
      final override = _itemRateOverrides[itemId];
      final ranges =
          override?.volumeRanges ??
          [const PriceListVolumeRange(startQuantity: 1, customRate: 0)];

      return Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Column(
          children: [
            for (int i = 0; i < ranges.length; i++)
              _buildVolumeRangeRow(
                item,
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
        ),
      );
    }
  }

  Widget _buildSelectItemCell(String itemId, bool isSelected) => SizedBox(
    width: 32,
    child: Checkbox(
      value: isSelected,
      onChanged: itemId.isEmpty
          ? null
          : (val) {
              setState(() {
                if (val == true) {
                  _selectedItemIds.add(itemId);
                  _selectionError = null;
                } else {
                  _selectedItemIds.remove(itemId);
                }
              });
            },
      activeColor: const Color(0xFF2563EB),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );

  Widget _buildItemDetailsCell(dynamic item) => Expanded(
    flex: 40,
    child: Padding(
      padding: const EdgeInsets.all(16),
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
              color: Color(0xFF2563EB),
            ),
          ),
          if (item.sku != null && item.sku!.isNotEmpty)
            Text(
              'SKU: ${item.sku}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
        ],
      ),
    ),
  );

  Widget _buildRateCell(double rate) {
    return Expanded(
      flex: 15,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            '\u20B9${rate.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
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
          prefixText: '\u20B9',
          readOnly: isAllItems,
          textAlign: TextAlign.right,
          enabled: !isAllItems || (_selectedItemIds.contains(itemId)),
          onChanged: (val) {
            if (isAllItems) return;
            final rate = double.tryParse(val) ?? 0;
            double? newDiscount;
            if (baseRate > 0) {
              newDiscount = ((baseRate - rate) / baseRate) * 100;
              _discountControllers[itemId]?.text = newDiscount.toStringAsFixed(
                2,
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
              _rateControllers[itemId]?.text = newCustomRate.toStringAsFixed(2);
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
    dynamic item,
    PriceListVolumeRange range,
    int idx,
    int totalRanges,
    String itemId,
    double baseRate,
  ) {
    bool isFirst = idx == 0;
    return Row(
      children: [
        if (isFirst)
          _buildSelectItemCell(itemId, _selectedItemIds.contains(itemId))
        else
          const SizedBox(width: 32),
        if (isFirst)
          _buildItemDetailsCell(item)
        else
          const Expanded(flex: 40, child: SizedBox()),
        Expanded(
          flex: 15,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '\u20B9${baseRate.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ),
          ),
        ),
        // Start Qty
        Expanded(
          flex: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _tableInputField(
              controller: TextEditingController(
                text: range.startQuantity.toString(),
              ),
              hintText: 'Start',
              textAlign: TextAlign.right,
              onChanged: (v) =>
                  _updateVolumeRange(itemId, idx, startQty: double.tryParse(v)),
            ),
          ),
        ),
        // End Qty
        Expanded(
          flex: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _tableInputField(
              controller: TextEditingController(
                text: range.endQuantity?.toString() ?? '',
              ),
              hintText: 'End',
              textAlign: TextAlign.right,
              onChanged: (v) =>
                  _updateVolumeRange(itemId, idx, endQty: double.tryParse(v)),
            ),
          ),
        ),
        // Custom Rate
        Expanded(
          flex: 15,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _tableInputField(
              controller: TextEditingController(
                text: range.customRate.toString(),
              ),
              prefixText: '\u20B9',
              textAlign: TextAlign.right,
              onChanged: (v) =>
                  _updateVolumeRange(itemId, idx, rate: double.tryParse(v)),
            ),
          ),
        ),
        if (_isDiscountEnabled)
          Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: _tableInputField(
                controller: TextEditingController(
                  text: range.discountPercentage?.toString() ?? '',
                ),
                suffixText: '%',
                textAlign: TextAlign.right,
                onChanged: (v) => _updateVolumeRange(
                  itemId,
                  idx,
                  discount: double.tryParse(v),
                ),
              ),
            ),
          ),
        if (idx > 0)
          SizedBox(
            width: 32,
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
          const SizedBox(width: 32),
      ],
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
        const SizedBox(width: 32), // Checkbox
        const Expanded(flex: 40, child: SizedBox()), // Item details space
        const Expanded(flex: 15, child: SizedBox()), // Sales Rate space
        Expanded(
          flex: 10 + 10 + 15 + (_isDiscountEnabled ? 10 : 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: TextButton.icon(
                onPressed: () => _addVolumeRange(itemId, name, sku, baseRate),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text(
                  'Add New Range',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 8,
                  ), // Adjusted padding
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),
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
      decoration: _inputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        suffixText: suffixText,
      ),
    );
  }

  void _addVolumeRange(
    String itemId,
    String name,
    String? sku,
    double salesRate,
  ) {
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
    double? startQty,
    double? endQty,
    double? rate,
    double? discount,
  }) {
    final current = _itemRateOverrides[itemId];
    if (current == null || current.volumeRanges == null) return;
    final updated = List<PriceListVolumeRange>.from(current.volumeRanges!);
    final old = updated[index];

    double newRate = rate ?? old.customRate;
    double? newDiscount = discount ?? old.discountPercentage;

    if (discount != null && current.salesRate != null) {
      newRate = current.salesRate! * (1 - (discount / 100));
    } else if (rate != null &&
        current.salesRate != null &&
        current.salesRate! > 0) {
      newDiscount = ((current.salesRate! - rate) / current.salesRate!) * 100;
    }

    updated[index] = PriceListVolumeRange(
      startQuantity: startQty ?? old.startQuantity,
      endQuantity: endQty ?? old.endQuantity,
      customRate: newRate,
      discountPercentage: newDiscount,
    );
    setState(
      () =>
          _itemRateOverrides[itemId] = current.copyWith(volumeRanges: updated),
    );
  }

  // calculateRow for internal use
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
        // Never mind: keep decimal
        break;
    }
    return rate;
  }

  void _removeVolumeRange(String itemId, int index) {
    setState(() {
      final current = _itemRateOverrides[itemId];
      if (current != null && current.volumeRanges != null) {
        final updated = List<PriceListVolumeRange>.from(current.volumeRanges!);
        updated.removeAt(index);
        _itemRateOverrides[itemId] = current.copyWith(volumeRanges: updated);
      }
    });
  }

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
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                        color: Color(0xFF374151),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => controller.close(),
                      color: const Color(0xFFEF4444),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Table(
                  border: TableBorder.all(color: const Color(0xFFF3F4F6)),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFF9FAFB)),
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
                      color: Color(0xFF2563EB),
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
        width: 160,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text.rich(
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 13,
                color: required
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
              children: [
                if (required)
                  const TextSpan(
                    text: '*',
                    style: TextStyle(color: Color(0xFFD32F2F)),
                  ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: child),
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

  CurrencyOption _resolveCurrencyOption(List<CurrencyOption> options) {
    if (options.isEmpty) return defaultCurrencyOptions.first;
    return options.firstWhere(
      (option) => option.code == _currencyCode,
      orElse: () => options.first,
    );
  }

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
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF9CA3AF),
                width: isSelected ? 4 : 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label ?? v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String id, String title, String sub) {
    bool isSelected = _priceListType == id;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('type_card_$id'),
          onTap: () => setState(() {
            _priceListType = id;
            if (id == 'all_items') {
              _pricingScheme = 'unit_pricing';
            }
          }),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE0E0E0),
                width: 1,
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
                          ? const Color(0xFF3B82F6)
                          : const Color(
                              0xFFE5E7EB,
                            ), // Grey check for unselected
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF374151),
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
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.8)
                        : const Color(0xFF6B7280),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildBulkLabel(String label, {double width = 150}) => SizedBox(
    width: width,
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
    ),
  );

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
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      borderRadius: BorderRadius.circular(4),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
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
      border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
    ),
    child: Row(
      children: [
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: Skeleton(
                    width: 18,
                    height: 18,
                    borderRadius: 9,
                    baseColor: Colors.white.withValues(alpha: 0.4),
                    highlightColor: Colors.white.withValues(alpha: 0.8),
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => context.pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      String detailsText = _priceListType == 'all_items'
          ? '${_percentageController.text}% $_percentageType'
          : (_pricingScheme == 'unit_pricing'
                ? 'Fixed Rates'
                : 'Tiered Pricing');
      final pricelist = PriceList(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        currency: _currencyCode,
        pricingScheme: _pricingScheme,
        priceListType: _priceListType,
        details: detailsText,
        roundOffPreference: _roundOffTo,
        status: 'active',
        transactionType: _transactionType,
        isDiscountEnabled: _isDiscountEnabled,
        itemRates: _priceListType == 'individual_items'
            ? _itemRateOverrides.values.toList()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await ref
          .read(priceListNotifierProvider.notifier)
          .createPriceList(pricelist);
      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
      ..color = const Color(0xFFE5E7EB)
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
          color: Color(0xFF6B7280),
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
          color: isLink ? const Color(0xFF2563EB) : const Color(0xFF374151),
        ),
      ),
    );
  }
}
