import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_state.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

class SalesItemQuickEditDialog extends ConsumerStatefulWidget {
  final Item item;
  final Function(Item) onUpdated;

  const SalesItemQuickEditDialog({
    super.key,
    required this.item,
    required this.onUpdated,
  });

  @override
  ConsumerState<SalesItemQuickEditDialog> createState() =>
      _SalesItemQuickEditDialogState();
}

class _SalesItemQuickEditDialogState
    extends ConsumerState<SalesItemQuickEditDialog> {
  final _formKey = GlobalKey<FormState>();
  bool isSaving = false;

  // Controllers
  late TextEditingController nameCtrl;
  late TextEditingController skuCtrl;
  late TextEditingController sellingPriceCtrl;
  late TextEditingController costPriceCtrl;
  late TextEditingController hsnCtrl;
  late TextEditingController dimLengthCtrl;
  late TextEditingController dimWidthCtrl;
  late TextEditingController dimHeightCtrl;
  late TextEditingController weightCtrl;
  late TextEditingController mpnCtrl;
  late TextEditingController upcCtrl;
  late TextEditingController isbnCtrl;
  late TextEditingController eanCtrl;
  late TextEditingController salesDescCtrl;
  late TextEditingController purchaseDescCtrl;
  late TextEditingController reorderPointCtrl;

  // State
  late bool isGoods;
  late bool isReturnable;
  late bool isSellable;
  late bool isPurchasable;
  late bool isTrackInventory;
  late bool trackBinLocation;
  late String? selectedUnitId;
  late String? selectedCategoryId;
  late String taxPreference;
  late String? intraStateTaxId;
  late String? interStateTaxId;
  late String? manufacturerId;
  late String? brandId;
  late String? salesAccountId;
  late String? purchaseAccountId;
  late String? inventoryAccountId;
  late String valuationMethod;
  late String trackingType; // 'None', 'Serial', 'Batches'
  late String dimUnit;
  late String weightUnit;

  // Focus Nodes for custom borders
  final FocusNode _dimLengthFocus = FocusNode();
  final FocusNode _dimWidthFocus = FocusNode();
  final FocusNode _dimHeightFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _reorderPointFocus = FocusNode();
  bool _dimFocused = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    nameCtrl = TextEditingController(text: item.productName);
    skuCtrl = TextEditingController(text: item.sku);
    sellingPriceCtrl =
        TextEditingController(text: item.sellingPrice?.toString() ?? '');
    costPriceCtrl =
        TextEditingController(text: item.costPrice?.toString() ?? '');
    hsnCtrl = TextEditingController(text: item.hsnCode);
    dimLengthCtrl = TextEditingController(text: item.length?.toString() ?? '');
    dimWidthCtrl = TextEditingController(text: item.width?.toString() ?? '');
    dimHeightCtrl = TextEditingController(text: item.height?.toString() ?? '');
    weightCtrl = TextEditingController(text: item.weight?.toString() ?? '');
    mpnCtrl = TextEditingController(text: item.mpn);
    upcCtrl = TextEditingController(text: item.upc);
    isbnCtrl = TextEditingController(text: item.isbn);
    eanCtrl = TextEditingController(text: item.ean);
    salesDescCtrl = TextEditingController(text: item.salesDescription);
    purchaseDescCtrl = TextEditingController(text: item.purchaseDescription);
    reorderPointCtrl = TextEditingController(text: item.reorderPoint.toString());

    isGoods = item.type == 'goods';
    isReturnable = item.isReturnable;
    isSellable = item.isSalesItem;
    isPurchasable = item.isPurchaseItem;
    isTrackInventory = item.isTrackInventory;
    trackBinLocation = item.trackBinLocation;
    selectedUnitId = item.unitId;
    selectedCategoryId = item.categoryId;
    taxPreference = item.taxPreference == 'taxable'
        ? 'Taxable'
        : item.taxPreference == 'exempt'
            ? 'Tax Exempt'
            : 'Non-Taxable';
    intraStateTaxId = item.intraStateTaxId;
    interStateTaxId = item.interStateTaxId;
    manufacturerId = item.manufacturerId;
    brandId = item.brandId;
    salesAccountId = item.salesAccountId;
    purchaseAccountId = item.purchaseAccountId;
    inventoryAccountId = item.inventoryAccountId;
    valuationMethod = item.inventoryValuationMethod ?? 'FIFO';
    trackingType = item.trackSerialNumber
        ? 'Serial'
        : item.trackBatches
            ? 'Batches'
            : 'None';
    dimUnit = item.dimensionUnit;
    weightUnit = item.weightUnit;

    _dimLengthFocus.addListener(_onDimFocusChange);
    _dimWidthFocus.addListener(_onDimFocusChange);
    _dimHeightFocus.addListener(_onDimFocusChange);
    _weightFocus.addListener(() => setState(() {}));
    _reorderPointFocus.addListener(() => setState(() {}));
  }

  void _onDimFocusChange() {
    setState(() {
      _dimFocused = _dimLengthFocus.hasFocus ||
          _dimWidthFocus.hasFocus ||
          _dimHeightFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    skuCtrl.dispose();
    sellingPriceCtrl.dispose();
    costPriceCtrl.dispose();
    hsnCtrl.dispose();
    dimLengthCtrl.dispose();
    dimWidthCtrl.dispose();
    dimHeightCtrl.dispose();
    weightCtrl.dispose();
    mpnCtrl.dispose();
    upcCtrl.dispose();
    isbnCtrl.dispose();
    eanCtrl.dispose();
    salesDescCtrl.dispose();
    purchaseDescCtrl.dispose();
    reorderPointCtrl.dispose();
    _dimLengthFocus.dispose();
    _dimWidthFocus.dispose();
    _dimHeightFocus.dispose();
    _weightFocus.dispose();
    _reorderPointFocus.dispose();
    super.dispose();
  }

  String _toBackendTaxPreference(String pref) {
    if (pref == 'Taxable') return 'taxable';
    if (pref == 'Tax Exempt') return 'exempt';
    return 'non-taxable';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final updatedItem = widget.item.copyWith(
        productName: nameCtrl.text.trim(),
        sku: skuCtrl.text.trim().isEmpty ? null : skuCtrl.text.trim(),
        type: isGoods ? 'goods' : 'service',
        unitId: selectedUnitId ?? '',
        categoryId: isGoods ? selectedCategoryId : null,
        isReturnable: isReturnable,
        isSalesItem: isSellable,
        isPurchaseItem: isPurchasable,
        isTrackInventory: isTrackInventory,
        trackBinLocation: trackBinLocation,
        hsnCode: hsnCtrl.text.trim(),
        taxPreference: _toBackendTaxPreference(taxPreference),
        intraStateTaxId: intraStateTaxId,
        interStateTaxId: interStateTaxId,
        sellingPrice: double.tryParse(sellingPriceCtrl.text),
        costPrice: double.tryParse(costPriceCtrl.text),
        salesDescription: salesDescCtrl.text.trim(),
        purchaseDescription: purchaseDescCtrl.text.trim(),
        length: double.tryParse(dimLengthCtrl.text),
        width: double.tryParse(dimWidthCtrl.text),
        height: double.tryParse(dimHeightCtrl.text),
        dimensionUnit: dimUnit,
        weight: double.tryParse(weightCtrl.text),
        weightUnit: weightUnit,
        manufacturerId: manufacturerId,
        brandId: brandId,
        mpn: mpnCtrl.text.trim(),
        upc: upcCtrl.text.trim(),
        isbn: isbnCtrl.text.trim(),
        ean: eanCtrl.text.trim(),
        inventoryAccountId: inventoryAccountId,
        inventoryValuationMethod: valuationMethod,
        trackBatches: trackingType == 'Batches',
        trackSerialNumber: trackingType == 'Serial',
        reorderPoint: int.tryParse(reorderPointCtrl.text) ?? 0,
      );

      final result = await ref
          .read(itemsControllerProvider.notifier)
          .updateItem(updatedItem);

      if (result) {
        widget.onUpdated(updatedItem);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      ZerpaiToast.error(context, 'Failed to update item: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsControllerProvider);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 850,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Radio
                      Row(
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text(
                              'Type',
                              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                            ),
                          ),
                          _buildRadio(
                            'Goods',
                            isGoods,
                            (v) => setState(() => isGoods = true),
                          ),
                          const SizedBox(width: 24),
                          _buildRadio(
                            'Service',
                            !isGoods,
                            (v) => setState(() => isGoods = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Name
                      _LabeledField(
                        label: 'Name',
                        isRequired: true,
                        child: CustomTextField(
                          controller: nameCtrl,
                          hintText: '',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SKU
                      _LabeledField(
                        label: 'SKU',
                        child: CustomTextField(
                          controller: skuCtrl,
                          hintText: '',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Unit
                      _LabeledField(
                        label: 'Unit',
                        isRequired: true,
                        child: FormDropdown<String>(
                          value: selectedUnitId,
                          items: itemsState.units.map((u) => u.id!).toList(),
                          displayStringForValue: (id) =>
                              itemsState.units.firstWhere((u) => u.id == id).unitName,
                          onChanged: (v) => setState(() => selectedUnitId = v),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category
                      _LabeledField(
                        label: 'Category',
                        child: FormDropdown<String>(
                          value: selectedCategoryId,
                          items: itemsState.categories
                              .map((c) => c['id'] as String)
                              .toList(),
                          displayStringForValue: (id) => itemsState.categories
                              .firstWhere((c) => c['id'] == id)['category_name'] ??
                              id,
                          onChanged: (v) => setState(() => selectedCategoryId = v),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Returnable Checkbox
                      Row(
                        children: [
                          const SizedBox(width: 120),
                          Checkbox(
                            value: isReturnable,
                            onChanged: (v) => setState(() => isReturnable = v ?? false),
                            activeColor: const Color(0xFF0088FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Text(
                            'Returnable Item',
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 6),
                          const ZTooltip(
                            message: 'Enable this if the item can be returned by customers.',
                            child: Icon(
                              LucideIcons.helpCircle,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // HSN Code
                      _LabeledField(
                        label: 'HSN Code',
                        child: CustomTextField(
                          controller: hsnCtrl,
                          hintText: '',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tax Preference
                      _LabeledField(
                        label: 'Tax Preference',
                        isRequired: true,
                        child: FormDropdown<String>(
                          value: taxPreference,
                          items: const ['Taxable', 'Tax Exempt', 'Non-Taxable'],
                          onChanged: (v) => setState(() => taxPreference = v!),
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Divider(height: 1),
                      const SizedBox(height: 32),

                      // Dimensions and Weight Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'Dimensions',
                              subLabel: '(Length X Width X Height)',
                              child: _buildDimensionsInput(),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _LabeledField(
                              label: 'Weight',
                              child: _buildWeightInput(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Manufacturer and Brand
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'Manufacturer',
                              child: FormDropdown<String>(
                                value: manufacturerId,
                                items: itemsState.manufacturers
                                    .map((m) => m['id'] as String)
                                    .toList(),
                                displayStringForValue: (id) =>
                                    itemsState.manufacturers.firstWhere(
                                      (m) => m['id'] == id,
                                    )['name'] ??
                                    id,
                                onChanged: (v) => setState(() => manufacturerId = v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _LabeledField(
                              label: 'Brand',
                              child: FormDropdown<String>(
                                value: brandId,
                                items: itemsState.brands
                                    .map((b) => b['id'] as String)
                                    .toList(),
                                displayStringForValue: (id) =>
                                    itemsState.brands.firstWhere(
                                      (b) => b['id'] == id,
                                    )['name'] ??
                                    id,
                                onChanged: (v) => setState(() => brandId = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // UPC, MPN, EAN, ISBN
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'UPC',
                              hasHelp: true,
                              child: CustomTextField(controller: upcCtrl),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _LabeledField(
                              label: 'MPN',
                              hasHelp: true,
                              child: CustomTextField(controller: mpnCtrl),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'EAN',
                              hasHelp: true,
                              child: CustomTextField(controller: eanCtrl),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _LabeledField(
                              label: 'ISBN',
                              hasHelp: true,
                              child: CustomTextField(controller: isbnCtrl),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      const Divider(height: 1),
                      const SizedBox(height: 32),

                      // Sales and Purchase Information
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Sales Information',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Checkbox(
                                      value: isSellable,
                                      onChanged: (v) =>
                                          setState(() => isSellable = v ?? false),
                                      activeColor: const Color(0xFF0088FF),
                                    ),
                                    const Text(
                                      'Sellable',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _LabeledField(
                                  label: 'Selling Price',
                                  isRequired: true,
                                  child: CustomTextField(
                                    controller: sellingPriceCtrl,
                                    prefixWidget: const Padding(
                                      padding: EdgeInsets.only(left: 10, right: 4),
                                      child: Text('INR'),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _LabeledField(
                                  label: 'Account',
                                  isRequired: true,
                                  child: FormDropdown<String>(
                                    value: 'Sales',
                                    items: const ['Sales'],
                                    onChanged: (v) {},
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _LabeledField(
                                  label: 'Description',
                                  child: CustomTextField(
                                    controller: salesDescCtrl,
                                    maxLines: 3,
                                    height: 80,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Purchase Information',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Checkbox(
                                      value: isPurchasable,
                                      onChanged: (v) =>
                                          setState(() => isPurchasable = v ?? false),
                                      activeColor: const Color(0xFF0088FF),
                                    ),
                                    const Text(
                                      'Purchasable',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _LabeledField(
                                  label: 'Cost Price',
                                  isRequired: true,
                                  child: CustomTextField(
                                    controller: costPriceCtrl,
                                    prefixWidget: const Padding(
                                      padding: EdgeInsets.only(left: 10, right: 4),
                                      child: Text('INR'),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _LabeledField(
                                  label: 'Account',
                                  isRequired: true,
                                  child: FormDropdown<String>(
                                    value: 'Cost of Goods Sold',
                                    items: const ['Cost of Goods Sold'],
                                    onChanged: (v) {},
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _LabeledField(
                                  label: 'Description',
                                  child: CustomTextField(
                                    controller: purchaseDescCtrl,
                                    maxLines: 3,
                                    height: 80,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _LabeledField(
                                  label: 'Preferred Vendor',
                                  child: FormDropdown<String>(
                                    value: null,
                                    items: const [],
                                    onChanged: (v) {},
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(height: 1),
                      const SizedBox(height: 32),

                      // Default Tax Rates
                      const Text(
                        'Default Tax Rates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Intra State Tax Rate',
                        hasDottedUnderline: true,
                        child: FormDropdown<String>(
                          value: intraStateTaxId,
                          items: itemsState.taxRates.map((t) => t.id!).toList(),
                          displayStringForValue: (id) => itemsState.taxRates
                              .firstWhere((t) => t.id == id)
                              .taxName,
                          onChanged: (v) => setState(() => intraStateTaxId = v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'Inter State Tax Rate',
                        hasDottedUnderline: true,
                        child: FormDropdown<String>(
                          value: interStateTaxId,
                          items: itemsState.taxRates.map((t) => t.id!).toList(),
                          displayStringForValue: (id) => itemsState.taxRates
                              .firstWhere((t) => t.id == id)
                              .taxName,
                          onChanged: (v) => setState(() => interStateTaxId = v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildNoteBox(
                        'NOTE: You have changed the tax rate manually. Any changes you make in your organisation\'s Default Tax Preferences will not be applied to this item.',
                      ),
                      const SizedBox(height: 32),
                      const Divider(height: 1),
                      const SizedBox(height: 32),

                      // Inventory Tracking
                      _buildInventoryTrackingSection(),
                      const SizedBox(height: 32),
                      const Divider(height: 1),
                      const SizedBox(height: 32),

                      // Additional Reporting Tags (if any)
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: 'ADGF',
                              child: FormDropdown<String>(
                                value: null,
                                hint: 'None',
                                items: const [],
                                onChanged: (v) {},
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _LabeledField(
                              label: 'shedule',
                              child: FormDropdown<String>(
                                value: null,
                                hint: 'None',
                                items: const [],
                                onChanged: (v) {},
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: 'demo adavced reporting tag',
                        child: FormDropdown<String>(
                          value: null,
                          hint: 'None',
                          items: const [],
                          onChanged: (v) {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Edit Item',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFFEF4444)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildRadio(String label, bool selected, Function(bool?) onChanged) {
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<bool>(
            value: true,
            groupValue: selected,
            onChanged: onChanged,
            activeColor: const Color(0xFF0088FF),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInventoryTrackingSection() {
    final itemsState = ref.watch(itemsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isTrackInventory,
              onChanged: (v) => setState(() => isTrackInventory = v ?? false),
              activeColor: const Color(0xFF0088FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Track Inventory for this item',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.helpCircle, size: 14, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                  const Text(
                    'You cannot enable/disable inventory tracking once you\'ve created transactions for this item',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildNoteBox(
          'Note: You can configure the opening stock and stock tracking for this item under the Items module',
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: trackBinLocation,
              onChanged: (v) => setState(() => trackBinLocation = v ?? false),
              activeColor: const Color(0xFF0088FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Track Bin location for this item',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.helpCircle, size: 14, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                  const Text(
                    'Enable this option if you want to track the bin locations for this item while creating transactions',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Advanced Inventory Tracking',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildRadioRow('None', trackingType == 'None', () => setState(() => trackingType = 'None')),
            _buildRadioRow('Track Serial Number', trackingType == 'Serial', () => setState(() => trackingType = 'Serial')),
            _buildRadioRow('Track Batches', trackingType == 'Batches', () => setState(() => trackingType = 'Batches')),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Inventory Account',
                isRequired: true,
                hasDottedUnderline: true,
                child: FormDropdown<String>(
                  value: inventoryAccountId,
                  hint: 'Inventory Asset',
                  items: itemsState.accounts
                      .where((a) =>
                          a['account_type'] == 'Inventory' ||
                          a['account_type'] == 'Inventory Asset')
                      .map((a) => a['id'] as String)
                      .toList(),
                  displayStringForValue: (id) => itemsState.accounts
                          .firstWhere((a) => a['id'] == id)['system_account_name'] ??
                      id,
                  onChanged: (v) => setState(() => inventoryAccountId = v),
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _LabeledField(
                label: 'Inventory Valuation Method',
                isRequired: true,
                hasDottedUnderline: true,
                child: FormDropdown<String>(
                  value: valuationMethod,
                  hint: 'FIFO (First In, First Out)',
                  items: const ['FIFO', 'Average Cost'],
                  displayStringForValue: (v) =>
                      v == 'FIFO' ? 'FIFO (First In, First Out)' : 'Average Cost',
                  onChanged: (v) => setState(() => valuationMethod = v!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'Reorder Point',
          hasDottedUnderline: true,
          child: CustomTextField(
            controller: reorderPointCtrl,
            height: 36,
          ),
        ),
      ],
    );
  }

  Widget _buildRadioRow(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: const Color(0xFF0088FF),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
      ),
    );
  }

  Widget _buildDimensionsInput() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _dimFocused ? const Color(0xFF0088FF) : const Color(0xFFD1D5DB),
          width: _dimFocused ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildDimField(dimLengthCtrl, _dimLengthFocus, 'x')),
                const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                Expanded(child: _buildDimField(dimWidthCtrl, _dimWidthFocus, 'x')),
                const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                Expanded(child: _buildDimField(dimHeightCtrl, _dimHeightFocus, '')),
              ],
            ),
          ),
          Container(
            width: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              border: Border(left: BorderSide(color: Color(0xFFD1D5DB))),
            ),
            child: FormDropdown<String>(
              height: 34,
              fillColor: Colors.transparent,
              hideBorderDefault: true,
              value: dimUnit,
              items: const ['cm', 'in', 'mm'],
              onChanged: (v) => setState(() => dimUnit = v!),
              showSearch: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimField(TextEditingController ctrl, FocusNode fn, String sep) {
    return Stack(
      alignment: Alignment.center,
      children: [
        TextField(
          controller: ctrl,
          focusNode: fn,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
          ),
        ),
        if (sep.isNotEmpty)
          Positioned(
            right: 0,
            child: Text(
              sep,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ),
      ],
    );
  }

  Widget _buildWeightInput() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _weightFocus.hasFocus ? const Color(0xFF0088FF) : const Color(0xFFD1D5DB),
          width: _weightFocus.hasFocus ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: weightCtrl,
              focusNode: _weightFocus,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 13),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
            ),
          ),
          Container(
            width: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              border: Border(left: BorderSide(color: Color(0xFFD1D5DB))),
            ),
            child: FormDropdown<String>(
              height: 34,
              fillColor: Colors.transparent,
              hideBorderDefault: true,
              value: weightUnit,
              items: const ['kg', 'g', 'lb', 'oz'],
              onChanged: (v) => setState(() => weightUnit = v!),
              showSearch: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF28A745),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(isSaving ? 'Saving...' : 'Save & Update Line Item'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF28A745),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text('Save'),
            ),
          ),
          const SizedBox(width: 12),
          ZButton.secondary(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String? subLabel;
  final Widget child;
  final bool isRequired;
  final bool hasHelp;
  final bool hasDottedUnderline;

  const _LabeledField({
    required this.label,
    this.subLabel,
    required this.child,
    this.isRequired = false,
    this.hasHelp = false,
    this.hasDottedUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: hasDottedUnderline
                    ? const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF9CA3AF),
                            width: 1,
                            style: BorderStyle.solid, // Flutter doesn't have native dotted
                          ),
                        ),
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isRequired ? const Color(0xFFEF4444) : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isRequired)
                      const Text(
                        '*',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    if (hasHelp) ...[
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.helpCircle, size: 14, color: Color(0xFF9CA3AF)),
                    ],
                  ],
                ),
              ),
              if (subLabel != null)
                Text(
                  subLabel!,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}
