// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_state.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/category_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/composition_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/formulation_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/sales_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/purchase_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/default_tax_rates_section.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/modules/items/items/models/item_composition_model.dart';

// Tabs enum as in items_item_create.dart
enum ItemTab { composition, formulation, sales, purchase, moreInfo }

// Inventory tracking enum
enum InventoryTrackingMode { none, serialNumbers, batches }

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

  // Controllers from items_item_create.dart
  late TextEditingController nameCtrl;
  late TextEditingController billingNameCtrl;
  late TextEditingController itemCodeCtrl;
  late TextEditingController skuCtrl;
  late TextEditingController hsnCtrl;
  late TextEditingController sacCtrl;
  late TextEditingController dimXCtrl;
  late TextEditingController dimYCtrl;
  late TextEditingController dimZCtrl;
  late TextEditingController weightCtrl;
  late TextEditingController upcCtrl;
  late TextEditingController eanCtrl;
  late TextEditingController mpnCtrl;
  late TextEditingController isbnCtrl;
  late TextEditingController sellingPriceCtrl;
  late TextEditingController mrpCtrl;
  late TextEditingController ptrCtrl;
  late TextEditingController salesDescriptionCtrl;
  late TextEditingController costPriceCtrl;
  late TextEditingController purchaseDescriptionCtrl;
  late TextEditingController reorderPointCtrl;
  late TextEditingController lockUnitPackCtrl;
  late TextEditingController storageDescCtrl;
  late TextEditingController aboutCtrl;
  late TextEditingController usesDescCtrl;
  late TextEditingController howToUseCtrl;
  late TextEditingController dosageDescCtrl;
  late TextEditingController missedDoseDescCtrl;
  late TextEditingController safetyAdviceCtrl;
  final List<TextEditingController> sideEffectCtrls = [];
  final List<TextEditingController> faqTextCtrls = [];

  // State Variables
  late bool isGoods;
  late String? selectedUnitId;
  late String? selectedCategoryId;
  late bool isReturnable;
  late bool pushToEcommerce;
  late String taxPreference;
  late String? intraStateTaxId;
  late String? interStateTaxId;
  late String salesCurrency;
  late String? salesAccountId;
  late String purchaseCurrency;
  late String? purchaseAccountId;
  late String? repId;
  late String? preferredVendorId;
  late String dimUnit;
  late String weightUnit;
  late String? manufacturerId;
  late String? brandId;
  late String? productTypeId;
  late String? selectedPackSize;
  late bool trackInventory;
  late bool trackBinLocation;
  late InventoryTrackingMode trackingMode;
  late String? inventoryAccountId;
  late String valuationMethod;
  late String? storageId;
  late String? rackId;
  late String? reorderTermsId;
  late List<ItemComposition> compositions;
  late bool trackAssocIngredients;
  late String? buyingRuleId;
  late String? scheduleOfDrugId;

  late ItemTab selectedTab;

  final List<String> _taxPreferenceOptions = [
    'Taxable',
    'Tax Exempt',
    'Non-Taxable',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    selectedTab = ItemTab.composition;

    isGoods = item.type == 'goods';

    nameCtrl = TextEditingController(text: item.productName);
    billingNameCtrl = TextEditingController(text: item.billingName ?? '');
    itemCodeCtrl = TextEditingController(text: item.itemCode);
    skuCtrl = TextEditingController(text: item.sku ?? '');
    selectedUnitId = item.unitId;
    selectedCategoryId = item.categoryId;
    isReturnable = item.isReturnable;
    pushToEcommerce = item.pushToEcommerce;
    
    if (item.type == 'service') {
      sacCtrl = TextEditingController(text: item.hsnCode ?? '');
      hsnCtrl = TextEditingController();
    } else {
      hsnCtrl = TextEditingController(text: item.hsnCode ?? '');
      sacCtrl = TextEditingController();
    }
    
    taxPreference = item.taxPreference == 'taxable'
        ? 'Taxable'
        : item.taxPreference == 'exempt'
            ? 'Tax Exempt'
            : 'Non-Taxable';
            
    intraStateTaxId = item.intraStateTaxId;
    interStateTaxId = item.interStateTaxId;

    sellingPriceCtrl = TextEditingController(text: item.sellingPrice?.toString() ?? '');
    salesCurrency = item.sellingPriceCurrency;
    mrpCtrl = TextEditingController(text: item.mrp?.toString() ?? '');
    ptrCtrl = TextEditingController(text: item.ptr?.toString() ?? '');
    salesAccountId = item.salesAccountId;
    salesDescriptionCtrl = TextEditingController(text: item.salesDescription ?? '');

    costPriceCtrl = TextEditingController(text: item.costPrice?.toString() ?? '');
    purchaseCurrency = item.costPriceCurrency;
    purchaseAccountId = item.purchaseAccountId;
    repId = item.repId;
    preferredVendorId = item.preferredVendorId;
    purchaseDescriptionCtrl = TextEditingController(text: item.purchaseDescription ?? '');

    dimXCtrl = TextEditingController(text: item.length?.toString() ?? '');
    dimYCtrl = TextEditingController(text: item.width?.toString() ?? '');
    dimZCtrl = TextEditingController(text: item.height?.toString() ?? '');
    dimUnit = item.dimensionUnit;
    weightCtrl = TextEditingController(text: item.weight?.toString() ?? '');
    weightUnit = item.weightUnit;
    manufacturerId = item.manufacturerId;
    brandId = item.brandId;
    productTypeId = item.productTypeId;
    selectedPackSize = item.unitPack;
    upcCtrl = TextEditingController(text: item.upc ?? '');
    eanCtrl = TextEditingController(text: item.ean ?? '');
    mpnCtrl = TextEditingController(text: item.mpn ?? '');
    isbnCtrl = TextEditingController(text: item.isbn ?? '');

    trackInventory = item.isTrackInventory;
    trackBinLocation = item.trackBinLocation;
    trackingMode = item.trackSerialNumber
        ? InventoryTrackingMode.serialNumbers
        : item.trackBatches
            ? InventoryTrackingMode.batches
            : InventoryTrackingMode.none;
            
    inventoryAccountId = item.inventoryAccountId;
    valuationMethod = item.inventoryValuationMethod ?? 'FIFO';
    storageId = item.storageId;
    rackId = item.rackId;
    reorderPointCtrl = TextEditingController(text: item.reorderPoint.toString());
    lockUnitPackCtrl = TextEditingController(text: item.lockUnitPack?.toString() ?? '');
    reorderTermsId = item.reorderTermId;

    compositions = item.compositions ?? [];
    trackAssocIngredients = item.trackAssocIngredients;
    buyingRuleId = item.buyingRuleId;
    scheduleOfDrugId = item.scheduleOfDrugId;

    storageDescCtrl = TextEditingController(text: item.storageDescription ?? '');
    aboutCtrl = TextEditingController(text: item.about ?? '');
    usesDescCtrl = TextEditingController(text: item.usesDescription ?? '');
    howToUseCtrl = TextEditingController(text: item.howToUse ?? '');
    dosageDescCtrl = TextEditingController(text: item.dosageDescription ?? '');
    missedDoseDescCtrl = TextEditingController(text: item.missedDoseDescription ?? '');
    safetyAdviceCtrl = TextEditingController(text: item.safetyAdvice ?? '');

    if (item.sideEffects != null) {
      for (var se in item.sideEffects!) {
        sideEffectCtrls.add(TextEditingController(text: se));
      }
    }
    if (item.faqText != null) {
      for (var f in item.faqText!) {
        faqTextCtrls.add(TextEditingController(text: f));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsControllerProvider.notifier).loadLookupData();
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    billingNameCtrl.dispose();
    itemCodeCtrl.dispose();
    skuCtrl.dispose();
    hsnCtrl.dispose();
    sacCtrl.dispose();
    dimXCtrl.dispose();
    dimYCtrl.dispose();
    dimZCtrl.dispose();
    weightCtrl.dispose();
    upcCtrl.dispose();
    eanCtrl.dispose();
    mpnCtrl.dispose();
    isbnCtrl.dispose();
    sellingPriceCtrl.dispose();
    mrpCtrl.dispose();
    ptrCtrl.dispose();
    salesDescriptionCtrl.dispose();
    costPriceCtrl.dispose();
    purchaseDescriptionCtrl.dispose();
    reorderPointCtrl.dispose();
    lockUnitPackCtrl.dispose();
    storageDescCtrl.dispose();
    aboutCtrl.dispose();
    usesDescCtrl.dispose();
    howToUseCtrl.dispose();
    dosageDescCtrl.dispose();
    missedDoseDescCtrl.dispose();
    safetyAdviceCtrl.dispose();
    for (final c in sideEffectCtrls) {
      c.dispose();
    }
    for (final c in faqTextCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _setSelectedTab(ItemTab tab) {
    setState(() => selectedTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsControllerProvider);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.only(top: 0, left: 40, right: 40, bottom: 24),
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 1000, // Wider for full fields
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopPanel(itemsState),
                      const SizedBox(height: 24),
                      DefaultTaxRatesSection(
                        intraStateRateId: intraStateTaxId,
                        interStateRateId: interStateTaxId,
                        taxRates: itemsState.taxRates,
                        taxGroups: itemsState.taxGroups,
                        onChanged: (i, o) {
                          setState(() {
                            intraStateTaxId = i;
                            interStateTaxId = o;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildTabsCard(itemsState),
                      const SizedBox(height: 24),
                      if (isGoods) _buildInventoryFlags(itemsState),
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
            'Edit Item Full Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPanel(ItemsState itemsState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: _buildCompactLeftFields(itemsState),
      ),
    );
  }

  /// Unit name for [id], or an empty label when the id resolves to nothing.
  ///
  /// The selected id is not guaranteed to be in the list: the credit note page
  /// seeds this dialog with an empty `unitId`, and the dropdown's options are
  /// filtered to active units so an inactive one is absent too. A bare
  /// `firstWhere` threw "Bad state: No element" and replaced the whole dialog
  /// body with an error box.
  String _unitName(ItemsState itemsState, String? id) {
    if (id == null || id.isEmpty) return '';
    for (final unit in itemsState.units) {
      if (unit.id == id) return unit.unitName;
    }
    return '';
  }

  Widget _buildCompactLeftFields(ItemsState itemsState) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SharedFieldLayout(
            label: "Type",
            required: true,
            compact: true,
            child: Row(
              children: [
                _TypeRadio(
                  label: "Goods",
                  value: true,
                  selected: isGoods == true,
                  onChanged: (v) {
                    setState(() {
                      isGoods = true;
                    });
                    _setSelectedTab(ItemTab.composition);
                  },
                ),
                const SizedBox(width: 24),
                _TypeRadio(
                  label: "Service",
                  value: false,
                  selected: isGoods == false,
                  onChanged: (v) {
                    setState(() {
                      isGoods = false;
                      if (selectedUnitId == null && itemsState.units.isNotEmpty) {
                        selectedUnitId = itemsState.units.first.id;
                      }
                    });
                    _setSelectedTab(ItemTab.sales);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (isGoods) ...[
            SharedFieldLayout(
              label: "Name",
              required: true,
              compact: true,
              child: CustomTextField(
                controller: nameCtrl,
                hintText: "Enter item name",
                errorText: itemsState.validationErrors['productName'],
              ),
            ),
            SharedFieldLayout(
              label: "Billing Name",
              compact: true,
              child: CustomTextField(
                controller: billingNameCtrl,
                hintText: "Enter billing name",
              ),
            ),
            SharedFieldLayout(
              label: "Item Code",
              compact: true,
              child: CustomTextField(
                controller: itemCodeCtrl,
                hintText: "Enter item code",
                errorText: itemsState.validationErrors['itemCode'],
                enabled: false,
              ),
            ),
            SharedFieldLayout(
              label: "SKU",
              required: true,
              compact: true,
              child: CustomTextField(
                controller: skuCtrl,
                hintText: "Enter SKU",
                errorText: itemsState.validationErrors['sku'],
              ),
            ),
            SharedFieldLayout(
              label: "Unit",
              required: true,
              compact: true,
              child: FormDropdown<String>(
                value: selectedUnitId,
                items: itemsState.units.where((u) => u.isActive).map((u) => u.id).toList(),
                hint: "Select Unit",
                onChanged: (v) => setState(() => selectedUnitId = v),
                displayStringForValue: (id) => _unitName(itemsState, id),
              ),
            ),
            SharedFieldLayout(
              label: "Category",
              required: true,
              compact: true,
              child: CategoryDropdown(
                nodes: CategoryNode.fromFlatList(itemsState.categories.cast<Map<String, dynamic>>()),
                value: selectedCategoryId,
                displayString: itemsState.lookupCache[selectedCategoryId],
                onChanged: (v) => setState(() => selectedCategoryId = v),
                onSearch: (q) async {
                  final results = await ref
                      .read(itemsControllerProvider.notifier)
                      .searchCategories(q);
                  return CategoryNode.fromFlatList(results.cast<Map<String, dynamic>>());
                },
              ),
            ),
            SharedFieldLayout(
              label: "HSN Code",
              compact: true,
              child: CustomTextField(
                controller: hsnCtrl,
                hintText: "Enter HSN code",
                suffixWidget: IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: () => _openHsnSacSearch(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ),
            ),
            SharedFieldLayout(
              label: "Tax Preference",
              required: true,
              compact: true,
              child: FormDropdown<String>(
                value: taxPreference,
                items: _taxPreferenceOptions,
                hint: "Select Tax Preference",
                onChanged: (v) => setState(() => taxPreference = v!),
              ),
            ),
            SharedFieldLayout(
              label: "",
              compact: true,
              child: Wrap(
                spacing: 24,
                runSpacing: 10,
                children: [
                  _InlineCheckbox(
                    label: "Returnable Item",
                    value: isReturnable,
                    onChanged: (v) => setState(() => isReturnable = v ?? false),
                  ),
                  _InlineCheckbox(
                    label: "Push To Ecommerce",
                    value: pushToEcommerce,
                    onChanged: (v) => setState(() => pushToEcommerce = v ?? false),
                  ),
                ],
              ),
            ),
          ] else ...[
            SharedFieldLayout(
              label: "Service Name",
              required: true,
              compact: true,
              child: CustomTextField(
                controller: nameCtrl,
                hintText: "Enter service name",
                errorText: itemsState.validationErrors['productName'],
              ),
            ),
            SharedFieldLayout(
              label: "Service Code",
              compact: true,
              child: CustomTextField(
                controller: itemCodeCtrl,
                hintText: "Enter service code",
                errorText: itemsState.validationErrors['itemCode'],
                enabled: false,
              ),
            ),
            SharedFieldLayout(
              label: "Unit",
              required: true,
              compact: true,
              child: FormDropdown<String>(
                value: selectedUnitId,
                items: itemsState.units.where((u) => u.isActive).map((u) => u.id).toList(),
                hint: "Select Unit",
                onChanged: (v) => setState(() => selectedUnitId = v),
                displayStringForValue: (id) => _unitName(itemsState, id),
              ),
            ),
            SharedFieldLayout(
              label: "SAC Code",
              compact: true,
              child: CustomTextField(
                controller: sacCtrl,
                hintText: "Enter SAC code",
                suffixWidget: IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: () => _openHsnSacSearch(context, isSac: true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ),
            ),
            SharedFieldLayout(
              label: "Tax Preference",
              required: true,
              compact: true,
              child: FormDropdown<String>(
                value: taxPreference,
                items: _taxPreferenceOptions,
                hint: "Select Tax Preference",
                onChanged: (v) => setState(() => taxPreference = v!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabsCard(ItemsState itemsState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (isGoods) ...[
                    _tabHeader(
                      title: 'Composition Information',
                      active: selectedTab == ItemTab.composition,
                      onTap: () => _setSelectedTab(ItemTab.composition),
                    ),
                    _tabHeader(
                      title: 'Formulation Information',
                      active: selectedTab == ItemTab.formulation,
                      onTap: () => _setSelectedTab(ItemTab.formulation),
                    ),
                  ],
                  _tabHeader(
                    title: 'Sales Information',
                    active: selectedTab == ItemTab.sales,
                    onTap: () => _setSelectedTab(ItemTab.sales),
                  ),
                  _tabHeader(
                    title: 'Purchase Information',
                    active: selectedTab == ItemTab.purchase,
                    onTap: () => _setSelectedTab(ItemTab.purchase),
                  ),
                  if (isGoods && pushToEcommerce)
                    _tabHeader(
                      title: 'More Informations',
                      active: selectedTab == ItemTab.moreInfo,
                      onTap: () => _setSelectedTab(ItemTab.moreInfo),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedTab == ItemTab.composition)
                    CompositionSection(
                      initialRows: compositions,
                      onChanged: (v) => setState(() => compositions = v),
                      initialBuyingRule: buyingRuleId,
                      onBuyingRuleChanged: (v) => setState(() => buyingRuleId = v),
                      buyingRuleOptions: itemsState.buyingRules,
                      initialDrugSchedule: scheduleOfDrugId,
                      onDrugScheduleChanged: (v) => setState(() => scheduleOfDrugId = v),
                      drugScheduleOptions: itemsState.drugSchedules,
                      initialProductType: productTypeId,
                      onProductTypeChanged: (v) =>
                          setState(() => productTypeId = v),
                      productTypeOptions: itemsState.productTypes,
                      contentOptions: itemsState.contents,
                      strengthOptions: itemsState.strengths,
                      lookupCache: itemsState.lookupCache,
                      initialTrackActiveIngredients: trackAssocIngredients,
                      onTrackActiveIngredientsChanged: (v) => setState(() => trackAssocIngredients = v),
                    )
                  else if (selectedTab == ItemTab.formulation)
                    FormulationSection(
                      dimXCtrl: dimXCtrl,
                      dimYCtrl: dimYCtrl,
                      dimZCtrl: dimZCtrl,
                      dimUnit: dimUnit,
                      onDimUnitChange: (v) => setState(() => dimUnit = v ?? 'cm'),
                      weightCtrl: weightCtrl,
                      weightUnit: weightUnit,
                      onWeightUnitChange: (v) => setState(() => weightUnit = v ?? 'kg'),
                      manufacturer: manufacturerId,
                      onManufacturerChange: (v) => setState(() => manufacturerId = v),
                      manufacturerOptions: itemsState.manufacturers,
                      brand: brandId,
                      onBrandChange: (v) => setState(() => brandId = v),
                      brandOptions: itemsState.brands,
                      packSizeValue: selectedPackSize,
                      onPackSizeChanged: (v) =>
                          setState(() => selectedPackSize = v),
                      packSizeOptions: _packSizeOptions(itemsState),
                      packSizeDisplayLabelForId: (id) => id,
                      lockUnitPackValue: lockUnitPackCtrl.text.trim().isEmpty
                          ? null
                          : lockUnitPackCtrl.text.trim(),
                      onLockUnitPackChanged: (v) {
                        final text = v?.trim() ?? '';
                        final match = RegExp(r'\(([^()]+)\)\s*$').firstMatch(
                          text,
                        );
                        lockUnitPackCtrl.text =
                            match?.group(1)?.trim() ?? text;
                      },
                      lockUnitPackCtrl: lockUnitPackCtrl,
                      upcCtrl: upcCtrl,
                      eanCtrl: eanCtrl,
                      mpnCtrl: mpnCtrl,
                      isbnCtrl: isbnCtrl,
                      zerpaiField: _zerpaiField,
                      zerpaiTextField: _zerpaiTextField,
                      zerpaiDropdown: _zerpaiDropdown,
                      lookupCache: itemsState.lookupCache,
                    )
                  else if (selectedTab == ItemTab.sales)
                    SalesSection(
                      sellingPriceCtrl: sellingPriceCtrl,
                      mrpCtrl: mrpCtrl,
                      ptrCtrl: ptrCtrl,
                      descriptionCtrl: salesDescriptionCtrl,
                      currency: salesCurrency,
                      onCurrencyChange: (v) => setState(() => salesCurrency = v ?? 'INR'),
                      accountValue: salesAccountId,
                      onAccountChanged: (v) => setState(() => salesAccountId = v),
                      sellable: true,
                      onSellableChanged: (v) {},
                      zerpaiField: _zerpaiField,
                      zerpaiTextField: _zerpaiTextField,
                      zerpaiDropdown: _zerpaiDropdown,
                      accountOptions: itemsState.accounts,
                    )
                  else if (selectedTab == ItemTab.purchase)
                    PurchaseSection(
                      costPriceCtrl: costPriceCtrl,
                      descriptionCtrl: purchaseDescriptionCtrl,
                      currency: purchaseCurrency,
                      onCurrencyChange: (v) => setState(() => purchaseCurrency = v ?? 'INR'),
                      accountValue: purchaseAccountId,
                      onAccountChanged: (v) => setState(() => purchaseAccountId = v),
                      repValue: repId,
                      onRepChanged: (v) => setState(() => repId = v),
                      preferredVendor: preferredVendorId,
                      onVendorChanged: (v) => setState(() => preferredVendorId = v),
                      purchasable: true,
                      onPurchasableChanged: (v) {},
                      zerpaiField: _zerpaiField,
                      zerpaiTextField: _zerpaiTextField,
                      zerpaiDropdown: _zerpaiDropdown,
                      accountOptions: itemsState.accounts,
                      repOptions: itemsState.reps,
                      vendorOptions: itemsState.vendors,
                    )
                  else if (selectedTab == ItemTab.moreInfo)
                    MoreInfoSection(
                      storageDescCtrl: storageDescCtrl,
                      aboutCtrl: aboutCtrl,
                      usesDescCtrl: usesDescCtrl,
                      howToUseCtrl: howToUseCtrl,
                      dosageDescCtrl: dosageDescCtrl,
                      missedDoseDescCtrl: missedDoseDescCtrl,
                      safetyAdviceCtrl: safetyAdviceCtrl,
                      sideEffectCtrls: sideEffectCtrls,
                      faqTextCtrls: faqTextCtrls,
                      onAddSideEffect: () => setState(() => sideEffectCtrls.add(TextEditingController())),
                      onRemoveSideEffect: (index) => setState(() => sideEffectCtrls.removeAt(index).dispose()),
                      onAddFaq: () => setState(() => faqTextCtrls.add(TextEditingController())),
                      onRemoveFaq: (index) => setState(() => faqTextCtrls.removeAt(index).dispose()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _packSizeOptions(ItemsState itemsState) {
    final labels = itemsState.units
        .where((unit) => unit.isActive)
        .map((unit) => unit.unitName.trim())
        .where((label) => label.isNotEmpty)
        .toList();
    if (selectedPackSize != null && selectedPackSize!.trim().isNotEmpty) {
      labels.add(selectedPackSize!.trim());
    }
    return labels.toSet().toList();
  }

  Widget _tabHeader({required String title, required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppTheme.primaryBlueDark : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryFlags(ItemsState itemsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventory Settings',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: trackInventory,
              onChanged: (v) => setState(() => trackInventory = v ?? false),
            ),
            const Text('Track Inventory for this item', style: TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Checkbox(
              value: trackBinLocation,
              onChanged: (v) => setState(() => trackBinLocation = v ?? false),
            ),
            const Text('Track Bin Location for this item', style: TextStyle(fontSize: 13)),
          ],
        ),
        if (trackInventory) ...[
          const SizedBox(height: 16),
          _zerpaiField(
            label: "Inventory Account",
            required: true,
            child: FormDropdown<String>(
              value: inventoryAccountId,
              items: itemsState.accounts.map((a) => a['id'] as String).toList(),
              hint: 'Select account',
              onChanged: (v) => setState(() => inventoryAccountId = v),
              displayStringForValue: (id) {
                final acc = itemsState.accounts.where((a) => a['id'] == id).firstOrNull;
                return acc?['system_account_name'] ?? id;
              },
            ),
          ),
          const SizedBox(height: 16),
          _zerpaiField(
            label: "Valuation Method",
            required: true,
            child: FormDropdown<String>(
              value: valuationMethod,
              items: const ['FIFO', 'LIFO', 'FEFO', 'Weighted Average'],
              hint: 'Select method',
              onChanged: (v) => setState(() => valuationMethod = v!),
            ),
          ),
        ],
      ],
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
                backgroundColor: Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(isSaving ? 'Saving...' : 'Save & Update Item'),
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

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final updatedItem = widget.item.copyWith(
        productName: nameCtrl.text,
        billingName: billingNameCtrl.text,
        sku: skuCtrl.text,
        unitId: selectedUnitId,
        categoryId: selectedCategoryId,
        isReturnable: isReturnable,
        pushToEcommerce: pushToEcommerce,
        hsnCode: isGoods ? hsnCtrl.text : sacCtrl.text,
        taxPreference: taxPreference.toLowerCase(),
        intraStateTaxId: intraStateTaxId,
        interStateTaxId: interStateTaxId,
        sellingPrice: double.tryParse(sellingPriceCtrl.text),
        sellingPriceCurrency: salesCurrency,
        mrp: double.tryParse(mrpCtrl.text),
        ptr: double.tryParse(ptrCtrl.text),
        salesAccountId: salesAccountId,
        salesDescription: salesDescriptionCtrl.text,
        costPrice: double.tryParse(costPriceCtrl.text),
        costPriceCurrency: purchaseCurrency,
        purchaseAccountId: purchaseAccountId,
        repId: repId,
        preferredVendorId: preferredVendorId,
        purchaseDescription: purchaseDescriptionCtrl.text,
        length: double.tryParse(dimXCtrl.text),
        width: double.tryParse(dimYCtrl.text),
        height: double.tryParse(dimZCtrl.text),
        dimensionUnit: dimUnit,
        weight: double.tryParse(weightCtrl.text),
        weightUnit: weightUnit,
        manufacturerId: manufacturerId,
        brandId: brandId,
        productTypeId: productTypeId,
        unitPack: (selectedPackSize?.trim().isEmpty ?? true)
            ? null
            : selectedPackSize!.trim(),
        upc: upcCtrl.text,
        ean: eanCtrl.text,
        mpn: mpnCtrl.text,
        isbn: isbnCtrl.text,
        isTrackInventory: trackInventory,
        trackBinLocation: trackBinLocation,
        inventoryAccountId: inventoryAccountId,
        inventoryValuationMethod: valuationMethod,
        storageId: storageId,
        rackId: rackId,
        reorderPoint: int.tryParse(reorderPointCtrl.text) ?? 0,
        lockUnitPack: double.tryParse(lockUnitPackCtrl.text),
        reorderTermId: reorderTermsId,
        compositions: compositions,
        trackAssocIngredients: trackAssocIngredients,
        buyingRuleId: buyingRuleId,
        scheduleOfDrugId: scheduleOfDrugId,
        storageDescription: storageDescCtrl.text,
        about: aboutCtrl.text,
        usesDescription: usesDescCtrl.text,
        howToUse: howToUseCtrl.text,
        dosageDescription: dosageDescCtrl.text,
        missedDoseDescription: missedDoseDescCtrl.text,
        safetyAdvice: safetyAdviceCtrl.text,
        sideEffects: sideEffectCtrls.map((c) => c.text).toList(),
        faqText: faqTextCtrls.map((c) => c.text).toList(),
      );

      final success = await ref.read(itemsControllerProvider.notifier).updateItem(updatedItem);
      if (success) {
        widget.onUpdated(updatedItem);
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
        // ignore: use_build_context_synchronously
        ZerpaiToast.success(context, 'Item updated successfully');
      } else {
        // ignore: use_build_context_synchronously
        ZerpaiToast.error(context, 'Failed to update item in database');
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ZerpaiToast.error(context, 'Failed to update item: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _openHsnSacSearch(BuildContext context, {bool isSac = false}) async {
    final result = await showDialog<HsnSacCode>(
      context: context,
      builder: (context) => HsnSacSearchModal(
        type: isSac ? 'SAC' : 'HSN',
      ),
    );
    
    if (result != null) {
      setState(() {
        if (isSac) {
          sacCtrl.text = result.code;
        } else {
          hsnCtrl.text = result.code;
        }
      });
    }
  }

  // Helper widgets to match items_item_create style
  Widget _zerpaiField({
    required Widget child,
    String? helper,
    required String label,
    Color? labelColor,
    bool required = false,
    String? tooltip,
  }) {
    return SharedFieldLayout(
      label: label,
      required: required,
      compact: true,
      tooltip: tooltip,
      child: child,
    );
  }

  Widget _zerpaiTextField({
    required TextEditingController controller,
    bool enabled = true,
    String? errorText,
    double? height,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return CustomTextField(
      controller: controller,
      hintText: hint ?? '',
      keyboardType: keyboardType,
      maxLines: maxLines,
      height: height,
      enabled: enabled,
    );
  }

  Widget _zerpaiDropdown<T>({
    bool allowClear = true,
    String Function(T)? displayStringForValue,
    bool enabled = true,
    String? errorText,
    String? hint,
    Widget Function(T, bool, bool)? itemBuilder,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    Future<List<T>> Function(String)? onSearch,
    VoidCallback? onSettingsTap,
    String settingsLabel = '',
    bool showSearch = true,
    bool showSearchIcon = true,
    bool showSettings = false,
    T? value,
  }) {
    return FormDropdown<T>(
      value: value,
      items: items,
      hint: hint ?? '',
      onChanged: onChanged,
      displayStringForValue: displayStringForValue,
      itemBuilder: itemBuilder,
      onSearch: onSearch,
      showSettings: showSettings,
      settingsLabel: settingsLabel,
      onSettingsTap: onSettingsTap,
      allowClear: allowClear,
      enabled: enabled,
    );
  }
}

class _TypeRadio extends StatelessWidget {
  final String label;
  final bool value;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _TypeRadio({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<bool>(
            value: value,
            groupValue: selected ? value : !value,
            onChanged: (v) => onChanged(v!),
            activeColor: AppTheme.primaryBlueDark,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _InlineCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _InlineCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryBlueDark,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class MoreInfoSection extends StatelessWidget {
  final TextEditingController storageDescCtrl;
  final TextEditingController aboutCtrl;
  final TextEditingController usesDescCtrl;
  final TextEditingController howToUseCtrl;
  final TextEditingController dosageDescCtrl;
  final TextEditingController missedDoseDescCtrl;
  final TextEditingController safetyAdviceCtrl;
  final List<TextEditingController> sideEffectCtrls;
  final List<TextEditingController> faqTextCtrls;
  final VoidCallback onAddSideEffect;
  final Function(int) onRemoveSideEffect;
  final VoidCallback onAddFaq;
  final Function(int) onRemoveFaq;

  const MoreInfoSection({
    super.key,
    required this.storageDescCtrl,
    required this.aboutCtrl,
    required this.usesDescCtrl,
    required this.howToUseCtrl,
    required this.dosageDescCtrl,
    required this.missedDoseDescCtrl,
    required this.safetyAdviceCtrl,
    required this.sideEffectCtrls,
    required this.faqTextCtrls,
    required this.onAddSideEffect,
    required this.onRemoveSideEffect,
    required this.onAddFaq,
    required this.onRemoveFaq,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextArea("Storage description", storageDescCtrl),
            const SizedBox(height: 16),
            _buildTextArea("About", aboutCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Uses description", usesDescCtrl),
            const SizedBox(height: 16),
            _buildTextArea("How-to-use", howToUseCtrl),
            const SizedBox(height: 16),
            _buildTextArea("Safety advice", safetyAdviceCtrl),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            _buildDynamicList(
              "Side Effects",
              sideEffectCtrls,
              onAddSideEffect,
              onRemoveSideEffect,
            ),
            const SizedBox(height: 24),
            _buildDynamicList("FAQ", faqTextCtrls, onAddFaq, onRemoveFaq),
          ],
        ),
      ),
    );
  }

  Widget _buildTextArea(String label, TextEditingController controller) {
    return SharedFieldLayout(
      label: label,
      compact: false,
      child: CustomTextField(
        controller: controller,
        hintText: 'Enter $label',
        maxLines: 4,
        height: 100,
      ),
    );
  }

  Widget _buildDynamicList(
    String label,
    List<TextEditingController> ctrls,
    VoidCallback onAdd,
    Function(int) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textBody,
          ),
        ),
        const SizedBox(height: 12),
        ...ctrls.asMap().entries.map((entry) {
          final index = entry.key;
          final ctrl = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: ctrl,
                    hintText: 'Enter point',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => onRemove(index),
                ),
              ],
            ),
          );
        }),
        InkWell(
          onTap: onAdd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 16, color: AppTheme.primaryBlueDark),
                const SizedBox(width: 4),
                Text(
                  "Add More",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
