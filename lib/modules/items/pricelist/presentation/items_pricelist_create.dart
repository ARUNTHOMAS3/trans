import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import '../models/pricelist_model.dart';
import '../providers/pricelist_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';

/// Price List Creation Screen - Inventory → Items → Price Lists → New
///
/// Elegant form following esthetics for creating new price lists.
class PriceListCreateScreen extends ConsumerStatefulWidget {
  const PriceListCreateScreen({super.key});

  @override
  ConsumerState<PriceListCreateScreen> createState() =>
      _PriceListCreateScreenState();
}

class _PriceListCreateScreenState extends ConsumerState<PriceListCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _percentageController = TextEditingController();
  final _searchItemController = TextEditingController();

  String _transactionType = 'Sales';
  String _priceListType = 'all_items';
  String _pricingScheme = 'unit_pricing';
  String _percentageType = 'Markup';
  String _roundOffTo = 'Never mind';
  bool _isDiscountEnabled = false;
  bool _isSubmitting = false;
  bool _isDirty = false;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  final Set<String> _selectedItemIds = {};
  String? _selectionError;

  final Map<String, PriceListItemRate> _itemRateOverrides = {};
  final Map<String, TextEditingController> _rateControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _handleCancel() async {
    if (_isDirty) {
      final shouldDiscard = await showUnsavedChangesDialog(
        context,
        message:
            'If you leave, your unsaved price list changes will be discarded.',
      );
      if (!mounted || !shouldDiscard) return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.priceLists);
    }
  }

  @override
  void initState() {
    super.initState();
    _percentageController.addListener(_handleGlobalPercentageChange);
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
    for (var controller in _rateControllers.values) {
      controller.dispose();
    }
    for (var controller in _discountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsControllerProvider);

    return ZerpaiLayout(
      pageTitle: 'New Price List',
      onCancel: _handleCancel,
      isDirty: _isDirty,
      footer: _buildFooterActions(context),
      child: _buildFormContent(context, itemsState),
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
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || sku.contains(query);
    }).toList();

    return Form(
      key: _formKey,
      onChanged: _markDirty,
      child: CustomScrollView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // 1. General Info & Discount Section
          SliverToBoxAdapter(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGeneralInformationSection(),
                  const SizedBox(height: 48),
                  if (_priceListType == 'individual_items')
                    _buildIndividualItemsHeader(items),
                ],
              ),
            ),
          ),

          // 2. Sticky Table Header
          if (_priceListType == 'individual_items' && items.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TableHeaderDelegate(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 52,
                    decoration: const BoxDecoration(
                      color: AppTheme.bgLight,
                      border: Border(
                        top: BorderSide(color: AppTheme.borderColor),
                        left: BorderSide(color: AppTheme.borderColor),
                        right: BorderSide(color: AppTheme.borderColor),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Checkbox(
                              value:
                                  items.isNotEmpty &&
                                  items.every(
                                    (i) => _selectedItemIds.contains(i.id),
                                  ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedItemIds.addAll(
                                      items.map((i) => i.id as String),
                                    );
                                    _selectionError = null;
                                  } else {
                                    _selectedItemIds.clear();
                                  }
                                });
                              },
                              activeColor: AppTheme.primaryBlueDark,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 25,
                          child: _buildSearchTableHeader('ITEM DETAILS'),
                        ),
                        SizedBox(width: 120, child: _tileHeader('SALES RATE')),
                        Expanded(
                          flex: 40,
                          child: _tileHeader(
                            _pricingScheme == 'unit_pricing'
                                ? 'CUSTOM RATE'
                                : 'VOLUME PRICING RANGES',
                          ),
                        ),
                        if (_isDiscountEnabled)
                          SizedBox(
                            width: 120,
                            child: _tileHeader('DISCOUNT (%)'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 3. Table Items (SliverList)
          if (_priceListType == 'individual_items')
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: items.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyItemsState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        final isLast = index == items.length - 1;
                        return Container(
                          decoration: BoxDecoration(
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
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
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
    return Column(
      children: [
        _buildLabeledField(
          label: 'Name',
          required: true,
          child: SizedBox(
            width: 400,
            child: TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Name is required' : null,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabeledField(
          label: 'Transaction Type',
          child: Row(
            children: [
              _buildRadioOption(
                _transactionType,
                'Sales',
                (val) => setState(() => _transactionType = val),
              ),
              const SizedBox(width: 32),
              _buildRadioOption(
                _transactionType,
                'Purchase',
                (val) => setState(() => _transactionType = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildLabeledField(
          label: 'Price List Type',
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Row(
              children: [
                _buildTypeCard(
                  'all_items',
                  'All Items',
                  'Mark up or mark down the rates of all items',
                ),
                const SizedBox(width: 16),
                _buildTypeCard(
                  'individual_items',
                  'Individual Items',
                  'Customize the rate of each item',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildLabeledField(
          label: 'Description',
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter the description',
                hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_priceListType == 'individual_items') ...[
          _buildLabeledField(
            label: 'Pricing Scheme',
            child: Row(
              children: [
                _buildRadioOption(
                  _pricingScheme,
                  'unit_pricing',
                  (val) => setState(() => _pricingScheme = val),
                  label: 'Unit Pricing',
                ),
                const SizedBox(width: 32),
                _buildRadioOption(
                  _pricingScheme,
                  'volume_pricing',
                  (val) => setState(() => _pricingScheme = val),
                  label: 'Volume Pricing',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (_priceListType == 'all_items') ...[
          _buildLabeledField(
            label: 'Percentage',
            required: true,
            child: SizedBox(
              width: 400,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildSimpleDropdown(
                      _percentageType,
                      ['Markup', 'Markdown'],
                      (val) => setState(() => _percentageType = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      controller: _percentageController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration().copyWith(suffixText: '%'),
                      validator: (val) {
                        if (_priceListType == 'all_items' &&
                            (val == null || val.isEmpty)) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _buildLabeledField(
          label: 'Round Off To',
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSimpleDropdown(_roundOffTo, [
                  'Never mind',
                  'To the nearest .99',
                  'To the nearest .50',
                  'To the nearest whole number',
                ], (val) => setState(() => _roundOffTo = val!)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showRoundingExamples(context),
                  child: const Text(
                    'View Examples',
                    style: TextStyle(
                      color: AppTheme.primaryBlueDark,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
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
        _buildLabeledField(
          label: 'Discount',
          child: Row(
            children: [
              Checkbox(
                value: _isDiscountEnabled,
                onChanged: (val) => setState(() => _isDiscountEnabled = val!),
                activeColor: AppTheme.primaryBlueDark,
              ),
              const Text(
                'I want to include discount percentage for the items',
                style: TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.primaryBlueDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customise Rates in Bulk (${items.length} items)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (_selectionError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorBg,
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: AppTheme.errorRedDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectionError!,
                          style: const TextStyle(
                            color: AppTheme.errorRedDark,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _updateRatesInBulk(items),
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text(
                    'Update Rates in Bulk',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlueDark,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  'Import Price List for Items',
                  style: TextStyle(fontSize: 13, color: AppTheme.textBody),
                ),
                Switch(
                  value: false,
                  onChanged: (v) {},
                  activeThumbColor: AppTheme.primaryBlueDark,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
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

  Widget _tileHeader(String t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    ),
  );

  Widget _buildSearchTableHeader(String t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (!_isSearchVisible) ...[
            Text(
              t,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, size: 16),
              onPressed: () => setState(() => _isSearchVisible = true),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppTheme.textSecondary,
            ),
          ] else ...[
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _searchItemController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search items...',
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
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = false;
                          _searchQuery = '';
                          _searchItemController.clear();
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
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
        .where((i) => _selectedItemIds.contains(i.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        String updateRule = 'Markup';
        String baseRateField = 'Selling Price';
        List<Map<String, dynamic>> bulkRanges = [
          {'start': 1.0, 'end': null, 'value': 0.0, 'unit': '%'},
        ];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Update Rates in Bulk',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Top Settings Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bulk Update Rule',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textBody,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FormDropdown<String>(
                                value: updateRule,
                                items: const ['Markup', 'Markdown'],
                                onChanged: (val) =>
                                    setDialogState(() => updateRule = val!),
                                displayStringForValue: (v) => v,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 18), // Align with label
                              const SizedBox(height: 0),
                              FormDropdown<String>(
                                value: baseRateField,
                                items: const ['Selling Price', 'Purchase Rate'],
                                onChanged: (val) =>
                                    setDialogState(() => baseRateField = val!),
                                displayStringForValue: (v) => v,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ranges Table
                    const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Start Quantity',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'End Quantity',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Update By',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 40), // Space for delete icon
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...bulkRanges.asMap().entries.map((entry) {
                              int idx = entry.key;
                              var range = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        initialValue: range['start'].toString(),
                                        style: const TextStyle(fontSize: 13),
                                        keyboardType: TextInputType.number,
                                        decoration: _inputDecoration(),
                                        onChanged: (val) => range['start'] =
                                            double.tryParse(val) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        initialValue:
                                            range['end']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 13),
                                        keyboardType: TextInputType.number,
                                        decoration: _inputDecoration(),
                                        onChanged: (val) =>
                                            range['end'] = double.tryParse(val),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppTheme.borderColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: range['value']
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                decoration:
                                                    const InputDecoration(
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 10,
                                                          ),
                                                      border: InputBorder.none,
                                                    ),
                                                onChanged: (val) =>
                                                    range['value'] =
                                                        double.tryParse(val) ??
                                                        0,
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              height: 34,
                                              color: AppTheme.borderColor,
                                            ),
                                            SizedBox(
                                              width: 45,
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: range['unit'],
                                                  isDense: true,
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme.textBody,
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: '%',
                                                      child: Text('%'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: '₹',
                                                      child: Text('₹'),
                                                    ),
                                                  ],
                                                  onChanged: (val) =>
                                                      setDialogState(
                                                        () => range['unit'] =
                                                            val!,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: AppTheme.errorRedDark,
                                        ),
                                        onPressed: () {
                                          if (bulkRanges.length > 1) {
                                            setDialogState(
                                              () => bulkRanges.removeAt(idx),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          final lastEnd = bulkRanges.last['end'];
                          bulkRanges.add({
                            'start': (lastEnd ?? 0.0) + 1.0,
                            'end': null,
                            'value': 0.0,
                            'unit': '%',
                          });
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text(
                        'Add New Range',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlueDark,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              for (var item in selectedItems) {
                                final itemId = item.id;
                                double baseValue = 0;
                                if (baseRateField == 'Selling Price') {
                                  baseValue =
                                      (item.sellingPrice ?? 0.0) as double;
                                } else {
                                  baseValue = (item.costPrice ?? 0.0) as double;
                                }

                                final List<PriceListVolumeRange> newItemRanges =
                                    [];

                                for (var br in bulkRanges) {
                                  double finalRate = 0;
                                  double val = br['value'] as double;

                                  if (br['unit'] == '%') {
                                    if (updateRule == 'Markup') {
                                      finalRate = baseValue * (1 + (val / 100));
                                    } else {
                                      finalRate = baseValue * (1 - (val / 100));
                                    }
                                  } else {
                                    // Absolute value
                                    if (updateRule == 'Markup') {
                                      finalRate = baseValue + val;
                                    } else {
                                      finalRate = baseValue - val;
                                    }
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
                                      salesRate:
                                          (item.sellingPrice ?? 0.0) as double,
                                    );

                                if (_pricingScheme == 'volume_pricing') {
                                  _itemRateOverrides[itemId] = currentOverride
                                      .copyWith(volumeRanges: newItemRanges);
                                } else {
                                  // Unit Pricing - just apply the first range's calculated rate
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
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
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
                            foregroundColor: AppTheme.textBody,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            side: const BorderSide(color: AppTheme.borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
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
    final itemId = item.id;
    final salesPrice = (item.sellingPrice ?? 0.0) as double;
    final isSelected = _selectedItemIds.contains(itemId);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedItemIds.add(itemId as String);
                      _selectionError = null;
                    } else {
                      _selectedItemIds.remove(itemId);
                    }
                  });
                },
                activeColor: AppTheme.primaryBlueDark,
              ),
            ),
          ),
          Expanded(
            flex: 25,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                  if (item.sku != null && item.sku!.isNotEmpty)
                    Text(
                      'SKU: ${item.sku}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '₹${salesPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
          ),
          Expanded(
            flex: 40,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _pricingScheme == 'unit_pricing'
                  ? _buildUnitPricingField(
                      itemId,
                      item.productName,
                      item.sku,
                      salesPrice,
                    )
                  : _buildVolumePricingFields(
                      itemId,
                      item.productName,
                      item.sku,
                      salesPrice,
                    ),
            ),
          ),
          if (_isDiscountEnabled)
            SizedBox(
              width: 120,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _buildDiscountField(
                  itemId,
                  item.productName,
                  item.sku,
                  salesPrice,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnitPricingField(
    String itemId,
    String name,
    String? sku,
    double salesRate,
  ) {
    final bool isAllItems = _priceListType == 'all_items';
    final double? currentCustomRate = isAllItems
        ? _calculateRate(salesRate)
        : _itemRateOverrides[itemId]?.customRate;

    final controller = _getRateController(itemId, currentCustomRate);

    return SizedBox(
      width: 140,
      child: TextFormField(
        controller: controller,
        readOnly: isAllItems,
        enabled: !isAllItems || (_selectedItemIds.contains(itemId)),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (val) {
          if (isAllItems) return;
          final customRate = double.tryParse(val);
          double? newDiscount;
          if (customRate != null && salesRate > 0) {
            newDiscount = ((salesRate - customRate) / salesRate) * 100;
            _discountControllers[itemId]?.text = newDiscount.toStringAsFixed(2);
          }
          setState(
            () => _itemRateOverrides[itemId] =
                (_itemRateOverrides[itemId] ??
                        PriceListItemRate(
                          itemId: itemId,
                          itemName: name,
                          sku: sku,
                          salesRate: salesRate,
                        ))
                    .copyWith(
                      customRate: customRate,
                      discountPercentage: newDiscount,
                    ),
          );
        },
        decoration: _inputDecoration(prefixText: '₹').copyWith(
          fillColor: isAllItems ? AppTheme.bgDisabled : Colors.white,
          filled: isAllItems,
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildDiscountField(
    String itemId,
    String name,
    String? sku,
    double salesRate,
  ) {
    final bool isAllItems = _priceListType == 'all_items';
    double? currentDiscount;

    if (isAllItems) {
      final calcRate = _calculateRate(salesRate);
      if (salesRate > 0) {
        currentDiscount = ((salesRate - calcRate) / salesRate) * 100;
      }
    } else {
      currentDiscount = _itemRateOverrides[itemId]?.discountPercentage;
    }

    final controller = _getDiscountController(itemId, currentDiscount);

    if (isAllItems && currentDiscount != null) {
      final formatted = currentDiscount.toStringAsFixed(2);
      if (controller.text != formatted) {
        controller.text = formatted;
      }
    }

    return SizedBox(
      width: 100,
      child: TextFormField(
        controller: controller,
        readOnly: isAllItems,
        enabled: !isAllItems || (_selectedItemIds.contains(itemId)),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (val) {
          if (isAllItems) return;
          final discount = double.tryParse(val);
          double? newCustomRate;
          if (discount != null) {
            newCustomRate = salesRate * (1 - (discount / 100));
            _rateControllers[itemId]?.text = newCustomRate.toStringAsFixed(2);
          }
          setState(
            () => _itemRateOverrides[itemId] =
                (_itemRateOverrides[itemId] ??
                        PriceListItemRate(
                          itemId: itemId,
                          itemName: name,
                          sku: sku,
                          salesRate: salesRate,
                        ))
                    .copyWith(
                      discountPercentage: discount,
                      customRate: newCustomRate,
                    ),
          );
        },
        decoration: _inputDecoration().copyWith(
          suffixText: '%',
          fillColor: isAllItems ? AppTheme.bgDisabled : Colors.white,
          filled: isAllItems,
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildVolumePricingFields(
    String itemId,
    String name,
    String? sku,
    double salesRate,
  ) {
    final rateOverride = _itemRateOverrides[itemId];
    final ranges =
        rateOverride?.volumeRanges ??
        [const PriceListVolumeRange(startQuantity: 1, customRate: 0)];

    return Column(
      children: [
        ...ranges.asMap().entries.map((entry) {
          int idx = entry.key;
          var r = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: r.startQuantity.toString(),
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(hintText: 'Start'),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (v) => _updateVolumeRange(
                      itemId,
                      idx,
                      startQty: double.tryParse(v),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    initialValue: r.endQuantity?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(hintText: 'End'),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (v) => _updateVolumeRange(
                      itemId,
                      idx,
                      endQty: double.tryParse(v),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('${itemId}_vrate_${idx}_${r.customRate}'),
                    initialValue: r.customRate.toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration(prefixText: 'rs'),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (v) => _updateVolumeRange(
                      itemId,
                      idx,
                      rate: double.tryParse(v),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (_isDiscountEnabled)
                  Expanded(
                    child: TextFormField(
                      key: ValueKey(
                        '${itemId}_vdisc_${idx}_${r.discountPercentage ?? 'none'}',
                      ),
                      initialValue: r.discountPercentage?.toString() ?? '',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration().copyWith(suffixText: '%'),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (v) => _updateVolumeRange(
                        itemId,
                        idx,
                        discount: double.tryParse(v),
                      ),
                    ),
                  ),
                if (idx > 0)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    onPressed: () => _removeVolumeRange(itemId, idx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addVolumeRange(itemId, name, sku, salesRate),
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text(
              'Add New Range',
              style: TextStyle(fontSize: 12, color: AppTheme.primaryBlueDark),
            ),
          ),
        ),
      ],
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
      case 'To the nearest .99':
        rate = rate.floorToDouble() + 0.99;
        break;
      case 'To the nearest .50':
        rate = (rate * 2).roundToDouble() / 2;
        break;
      case 'To the nearest whole number':
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

  void _showRoundingExamples(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Rounding Examples', style: TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: Table(
          border: TableBorder.all(color: AppTheme.borderColor),
          children: const [
            TableRow(
              decoration: BoxDecoration(color: AppTheme.bgLight),
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'ROUND OFF TO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'INPUT VALUE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'ROUNDED VALUE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Never mind', style: TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('1000.678', style: TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('1000.678', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Nearest whole number',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('1000.678', style: TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('1001', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('0.99', style: TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('1000.678', style: TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('1000.99', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    bool required = false,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 180,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(fontSize: 14, color: AppTheme.textBody),
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppTheme.errorRed),
                  ),
                TextSpan(
                  text: '',
                  style: const TextStyle(color: AppTheme.textBody),
                ),
              ],
            ),
          ),
        ),
      ),
      child,
    ],
  );

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
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryBlueDark
                    : AppTheme.textMuted,
                width: isSelected ? 5 : 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label ?? v,
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String id, String title, String sub) {
    bool isSelected = _priceListType == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _priceListType = id;
          if (id == 'all_items') {
            _pricingScheme = 'unit_pricing';
          }
        }),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.selectionActiveBg : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryBlueDark
                  : AppTheme.borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                    size: 16,
                    color: isSelected
                        ? AppTheme.primaryBlueDark
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.infoTextDark
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
                      ? AppTheme.infoTextDark.withValues(alpha: 0.8)
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
    );
  }

  Widget _buildSimpleDropdown(
    String v,
    List<String> i,
    ValueChanged<String?> o,
  ) => SizedBox(
    width: 400,
    child: FormDropdown<String>(
      value: v,
      items: i,
      onChanged: o,
      displayStringForValue: (val) => val,
    ),
  );

  InputDecoration _inputDecoration({
    String? hintText,
    String? prefixText,
  }) => InputDecoration(
    hintText: hintText,
    prefixText: prefixText,
    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      borderSide: const BorderSide(color: AppTheme.primaryBlueDark, width: 1),
    ),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
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
            backgroundColor: AppTheme.successGreen,
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
          onPressed: _handleCancel,
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
        currency: 'INR',
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
        setState(() => _isDirty = false);
        _handleCancel();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
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
  double get maxExtent => 52;

  @override
  double get minExtent => 52;

  @override
  bool shouldRebuild(covariant _TableHeaderDelegate oldDelegate) {
    return true;
  }
}
