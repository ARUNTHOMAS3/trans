import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_state.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/item_composition_model.dart';
import 'package:zerpai_erp/modules/items/items/models/unit_model.dart';

import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_list_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_reorder_terms_dialog.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/composition_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/formulation_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/sales_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/purchase_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/default_tax_rates_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/dialogs/manage_pack_sizes_dialog.dart';
import 'package:zerpai_erp/modules/items/items/presentation/dialogs/manage_reps_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/category_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_categories_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/services/draft_storage_service.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

part '../sections/items_item_create_primary_info.dart';
part '../sections/items_item_create_images.dart';
part '../sections/items_item_create_tabs.dart';
part '../sections/items_item_create_inventory.dart';
part '../sections/items_item_create_settings.dart';
part '../sections/items_item_create_widgets.dart';
part '../sections/items_item_create_components.dart';
part '../sections/more_info_section.dart';

// Tabs
enum ItemTab { composition, formulation, sales, purchase, moreInfo }

// Inventory tracking
enum InventoryTrackingMode { none, serialNumbers, batches }

const List<String> _taxPreferenceOptions = [
  'Taxable',
  'Tax Exempt',
  'Non-Taxable',
];

class ItemCreateScreen extends ConsumerStatefulWidget {
  final Item? item;
  final String? itemId;
  final bool isClone;
  final String? initialTab;

  const ItemCreateScreen({
    super.key,
    this.item,
    this.itemId,
    this.isClone = false,
    this.initialTab,
  });

  @override
  ConsumerState<ItemCreateScreen> createState() => _ItemCreateScreenState();
}

class _ItemCreateScreenState extends ConsumerState<ItemCreateScreen> {
  static const String _defaultDrugScheduleName = 'NONE / GENERAL';
  static const String _defaultBuyingRuleName = 'No Restriction (OTC)';
  static const String _defaultStorageName = 'Normal Temp';
  static const String _defaultInventoryAccountName = 'Inventory Asset';
  static const String _defaultSalesAccountName = 'Sales';
  static const String _defaultPurchaseAccountName = 'Cost of Goods Sold';
  static const String _defaultPurchaseAccountAltName = 'Cost Of Goods Sold';

  // Edit mode - stores the item being edited
  Item? editingItem;
  bool isEditMode = false;
  bool _isHydratingInitialItem = false;
  bool _isDirty = false;
  bool _suspendDirtyTracking = true;

  // Ghost Draft
  static const _draftKey = 'item_create';
  Timer? _draftTimer;
  bool _hasDraft = false;

  void updateState(VoidCallback fn) => setState(fn);

  void _markDirty() {
    if (!mounted || _suspendDirtyTracking || _isDirty) return;
    setState(() => _isDirty = true);
  }

  void _resetDirty() {
    if (mounted) {
      setState(() => _isDirty = false);
    } else {
      _isDirty = false;
    }
  }

  ItemTab _parseItemTab(String? value) {
    switch (value) {
      case 'formulation':
        return ItemTab.formulation;
      case 'sales':
        return ItemTab.sales;
      case 'purchase':
        return ItemTab.purchase;
      case 'more-info':
        return ItemTab.moreInfo;
      case 'composition':
      default:
        return ItemTab.composition;
    }
  }

  String _itemTabKey(ItemTab tab) {
    switch (tab) {
      case ItemTab.composition:
        return 'composition';
      case ItemTab.formulation:
        return 'formulation';
      case ItemTab.sales:
        return 'sales';
      case ItemTab.purchase:
        return 'purchase';
      case ItemTab.moreInfo:
        return 'more-info';
    }
  }

  void _goToItemsList() {
    final currentOrgSystemId = _currentOrgSystemId();
    context.goNamed(
      AppRoutes.itemsReport,
      pathParameters: {'orgSystemId': currentOrgSystemId},
    );
  }

  String _currentOrgSystemId() {
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'];
    if (orgId != null && orgId.trim().isNotEmpty) {
      return orgId.trim();
    }
    return '';
  }

  void _setSelectedTab(ItemTab tab) {
    if (!mounted) return;
    setState(() => selectedTab = tab);

    final queryParameters = <String, String>{};
    if (tab != ItemTab.composition) {
      queryParameters['tab'] = _itemTabKey(tab);
    }

    // GoRouter requires all path params for nested routes to be provided.
    // Since this widget is always nested under /:orgSystemId, the param
    // should always be in the current route state.
    final currentOrgSystemId = _currentOrgSystemId();

    if (widget.itemId != null) {
      context.goNamed(
        AppRoutes.itemsEdit,
        pathParameters: {
          'orgSystemId': currentOrgSystemId,
          'id': widget.itemId!,
        },
        queryParameters: queryParameters,
        extra: widget.item ?? editingItem,
      );
      return;
    }

    context.goNamed(
      AppRoutes.itemsCreate,
      pathParameters: {'orgSystemId': currentOrgSystemId},
      queryParameters: queryParameters,
      extra:
          widget.item ??
          (widget.isClone && editingItem != null
              ? {'cloneItem': editingItem}
              : null),
    );
  }

  // ---------------- IMAGES ----------------
  final List<dynamic> _itemImages =
      []; // Can be String (URL) or PlatformFile (Local)
  int _primaryImageIndex = 0;
  bool _isImageDragging = false;

  @override
  void initState() {
    super.initState();
    selectedTab = _parseItemTab(widget.initialTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    // Ghost Draft: only for create-from-scratch (no item ID or existing item).
    if (widget.item == null && widget.itemId == null && !widget.isClone) {
      _hasDraft = DraftStorageService.hasDraft(_draftKey);
      _draftTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _saveDraft(),
      );
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
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
    howItWorksCtrl.dispose();
    drugInteractionsCtrl.dispose();
    contraindicationsCtrl.dispose();
    sideEffectsManagementCtrl.dispose();
    goodToKnowCtrl.dispose();
    quickTipsCtrl.dispose();
    allergyInformationCtrl.dispose();
    productHighlightsCtrl.dispose();
    ingredientsListCtrl.dispose();
    safetyPregnancyCtrl.dispose();
    safetyBreastfeedingCtrl.dispose();
    safetyAlcoholCtrl.dispose();
    safetyLiverCtrl.dispose();
    safetyKidneyCtrl.dispose();
    safetyDrivingCtrl.dispose();
    safetyAllergyCtrl.dispose();
    safetyChildrenCtrl.dispose();
    safetyOlderPatientsCtrl.dispose();
    interactionsDrugDrugCtrl.dispose();
    interactionsDrugDiseaseCtrl.dispose();
    dosageDailyDoseCtrl.dispose();
    dosageOverDoseCtrl.dispose();
    dosageMissedDoseCtrl.dispose();
    referencesTextCtrl.dispose();
    productDescriptionCtrl.dispose();
    additionalInfoAllergyCtrl.dispose();
    additionalInfoConcernsCtrl.dispose();
    additionalInfoGoodToKnowCtrl.dispose();
    additionalInfoQuickTipsCtrl.dispose();
    directionsForUseCtrl.dispose();
    sideEffectsCtrl.dispose();
    faqTextCtrl.dispose();
    super.dispose();
  }

  // ── Ghost Draft ───────────────────────────────────────────────────────────

  void _saveDraft() {
    if (!mounted || isEditMode) return;
    final hasContent = nameCtrl.text.isNotEmpty || itemCodeCtrl.text.isNotEmpty;
    if (!hasContent) return;

    DraftStorageService.save(_draftKey, {
      'name': nameCtrl.text,
      'billingName': billingNameCtrl.text,
      'itemCode': itemCodeCtrl.text,
      'sku': skuCtrl.text,
      'isGoods': isGoods,
      'unitId': selectedUnitId,
      'categoryId': selectedCategoryId,
      'hsn': hsnCtrl.text,
      'sac': sacCtrl.text,
      'taxPreference': taxPreference,
      'intraStateTaxId': intraStateTaxId,
      'interStateTaxId': interStateTaxId,
      'sellingPrice': sellingPriceCtrl.text,
      'mrp': mrpCtrl.text,
      'ptr': ptrCtrl.text,
      'costPrice': costPriceCtrl.text,
      'salesAccountId': salesAccountId,
      'purchaseAccountId': purchaseAccountId,
      'repId': repId,
      'salesDescription': salesDescriptionCtrl.text,
      'purchaseDescription': purchaseDescriptionCtrl.text,
      'manufacturerId': manufacturerId,
      'brandId': brandId,
      'storageDescription': storageDescCtrl.text,
      'about': aboutCtrl.text,
      'usesDescription': usesDescCtrl.text,
      'howToUse': howToUseCtrl.text,
      'dosageDescription': dosageDescCtrl.text,
      'missedDoseDescription': missedDoseDescCtrl.text,
      'safetyAdvice': safetyAdviceCtrl.text,
      'howItWorks': howItWorksCtrl.text,
      'drugInteractions': drugInteractionsCtrl.text,
      'contraindications': contraindicationsCtrl.text,
      'sideEffectsManagement': sideEffectsManagementCtrl.text,
      'goodToKnow': goodToKnowCtrl.text,
      'quickTips': quickTipsCtrl.text,
      'allergyInformation': allergyInformationCtrl.text,
      'productHighlights': productHighlightsCtrl.text,
      'ingredientsList': ingredientsListCtrl.text,
      'safetyMeasuresWarningsPregnancy': safetyPregnancyCtrl.text,
      'safetyMeasuresWarningsBreastfeeding': safetyBreastfeedingCtrl.text,
      'safetyMeasuresWarningsAlcohol': safetyAlcoholCtrl.text,
      'safetyMeasuresWarningsLiver': safetyLiverCtrl.text,
      'safetyMeasuresWarningsKidney': safetyKidneyCtrl.text,
      'safetyMeasuresWarningsUseInDrivingAndOperatingMachinery':
          safetyDrivingCtrl.text,
      'safetyMeasuresWarningsAllergy': safetyAllergyCtrl.text,
      'safetyMeasuresWarningsChildren': safetyChildrenCtrl.text,
      'safetyMeasuresWarningsOlderPatients': safetyOlderPatientsCtrl.text,
      'interactionsDrugDrugInteractions': interactionsDrugDrugCtrl.text,
      'interactionsDrugDiseaseInteractions': interactionsDrugDiseaseCtrl.text,
      'dosageDailyDose': dosageDailyDoseCtrl.text,
      'dosageOverDose': dosageOverDoseCtrl.text,
      'dosageMissedDose': dosageMissedDoseCtrl.text,
      'referencesText': referencesTextCtrl.text,
      'productDescription': productDescriptionCtrl.text,
      'additionalInfoAllergy': additionalInfoAllergyCtrl.text,
      'additionalInfoConcerns': additionalInfoConcernsCtrl.text,
      'additionalInfoGoodToKnow': additionalInfoGoodToKnowCtrl.text,
      'additionalInfoQuickTips': additionalInfoQuickTipsCtrl.text,
      'directionsForUse': directionsForUseCtrl.text,
      'sideEffectsText': sideEffectsCtrl.text,
      'faqText': faqTextCtrl.text,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  void _restoreDraft() {
    final data = DraftStorageService.load(_draftKey);
    if (data == null) return;

    setState(() {
      nameCtrl.text = data['name'] as String? ?? '';
      billingNameCtrl.text = data['billingName'] as String? ?? '';
      itemCodeCtrl.text = data['itemCode'] as String? ?? '';
      skuCtrl.text = data['sku'] as String? ?? '';
      isGoods = data['isGoods'] as bool? ?? true;
      selectedUnitId = data['unitId'] as String?;
      selectedCategoryId = data['categoryId'] as String?;
      hsnCtrl.text = data['hsn'] as String? ?? '';
      sacCtrl.text = data['sac'] as String? ?? '';
      taxPreference = data['taxPreference'] as String? ?? 'Taxable';
      intraStateTaxId = data['intraStateTaxId'] as String?;
      interStateTaxId = data['interStateTaxId'] as String?;
      sellingPriceCtrl.text = data['sellingPrice'] as String? ?? '';
      mrpCtrl.text = data['mrp'] as String? ?? '';
      ptrCtrl.text = data['ptr'] as String? ?? '';
      costPriceCtrl.text = data['costPrice'] as String? ?? '';
      salesAccountId = data['salesAccountId'] as String?;
      purchaseAccountId = data['purchaseAccountId'] as String?;
      repId = data['repId'] as String?;
      salesDescriptionCtrl.text = data['salesDescription'] as String? ?? '';
      purchaseDescriptionCtrl.text =
          data['purchaseDescription'] as String? ?? '';
      manufacturerId = data['manufacturerId'] as String?;
      brandId = data['brandId'] as String?;
      storageDescCtrl.text = data['storageDescription'] as String? ?? '';
      aboutCtrl.text = data['about'] as String? ?? '';
      usesDescCtrl.text = data['usesDescription'] as String? ?? '';
      howToUseCtrl.text = data['howToUse'] as String? ?? '';
      dosageDescCtrl.text = data['dosageDescription'] as String? ?? '';
      missedDoseDescCtrl.text = data['missedDoseDescription'] as String? ?? '';
      safetyAdviceCtrl.text = data['safetyAdvice'] as String? ?? '';
      howItWorksCtrl.text = data['howItWorks'] as String? ?? '';
      drugInteractionsCtrl.text = data['drugInteractions'] as String? ?? '';
      contraindicationsCtrl.text = data['contraindications'] as String? ?? '';
      sideEffectsManagementCtrl.text =
          data['sideEffectsManagement'] as String? ?? '';
      goodToKnowCtrl.text = data['goodToKnow'] as String? ?? '';
      quickTipsCtrl.text = data['quickTips'] as String? ?? '';
      allergyInformationCtrl.text =
          data['allergyInformation'] as String? ?? '';
      productHighlightsCtrl.text = data['productHighlights'] as String? ?? '';
      ingredientsListCtrl.text = data['ingredientsList'] as String? ?? '';
      safetyPregnancyCtrl.text =
          data['safetyMeasuresWarningsPregnancy'] as String? ?? '';
      safetyBreastfeedingCtrl.text =
          data['safetyMeasuresWarningsBreastfeeding'] as String? ?? '';
      safetyAlcoholCtrl.text =
          data['safetyMeasuresWarningsAlcohol'] as String? ?? '';
      safetyLiverCtrl.text =
          data['safetyMeasuresWarningsLiver'] as String? ?? '';
      safetyKidneyCtrl.text =
          data['safetyMeasuresWarningsKidney'] as String? ?? '';
      safetyDrivingCtrl.text =
          data['safetyMeasuresWarningsUseInDrivingAndOperatingMachinery']
              as String? ??
          '';
      safetyAllergyCtrl.text =
          data['safetyMeasuresWarningsAllergy'] as String? ?? '';
      safetyChildrenCtrl.text =
          data['safetyMeasuresWarningsChildren'] as String? ?? '';
      safetyOlderPatientsCtrl.text =
          data['safetyMeasuresWarningsOlderPatients'] as String? ?? '';
      interactionsDrugDrugCtrl.text =
          data['interactionsDrugDrugInteractions'] as String? ?? '';
      interactionsDrugDiseaseCtrl.text =
          data['interactionsDrugDiseaseInteractions'] as String? ?? '';
      dosageDailyDoseCtrl.text = data['dosageDailyDose'] as String? ?? '';
      dosageOverDoseCtrl.text = data['dosageOverDose'] as String? ?? '';
      dosageMissedDoseCtrl.text = data['dosageMissedDose'] as String? ?? '';
      referencesTextCtrl.text = data['referencesText'] as String? ?? '';
      productDescriptionCtrl.text =
          data['productDescription'] as String? ?? '';
      additionalInfoAllergyCtrl.text =
          data['additionalInfoAllergy'] as String? ?? '';
      additionalInfoConcernsCtrl.text =
          data['additionalInfoConcerns'] as String? ?? '';
      additionalInfoGoodToKnowCtrl.text =
          data['additionalInfoGoodToKnow'] as String? ?? '';
      additionalInfoQuickTipsCtrl.text =
          data['additionalInfoQuickTips'] as String? ?? '';
      directionsForUseCtrl.text = data['directionsForUse'] as String? ?? '';
      sideEffectsCtrl.text = data['sideEffectsText'] as String? ?? '';
      faqTextCtrl.text = data['faqText'] as String? ?? '';
      _hasDraft = false;
      _isDirty = true;
    });

    DraftStorageService.clear(_draftKey);
    if (mounted) {
      ZerpaiToast.info(context, 'Draft restored successfully.');
    }
  }

  Widget _buildDraftBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFCC02)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppTheme.warningOrange, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'We found an unsaved draft. Would you like to restore it?',
              style: TextStyle(
                color: AppTheme.warningTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _restoreDraft,
            child: const Text(
              'Restore',
              style: TextStyle(
                color: AppTheme.warningOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              DraftStorageService.clear(_draftKey);
              setState(() => _hasDraft = false);
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: AppTheme.warningTextDark),
            ),
          ),
        ],
      ),
    );
  }

  void _loadInitialData() async {
    _suspendDirtyTracking = true;
    final controller = ref.read(itemsControllerProvider.notifier);
    final itemId = widget.itemId ?? widget.item?.id;

    // Load lookups first - they are essential
    await controller.loadLookupData();

    if (itemId != null) {
      // CRITICAL: We MUST fetch the item from the API with forceRefresh: true.
      // List views often pass a partial Item object missing joined names (content_name, strength_name).
      // Hydrating it here ensures the lookupCache and compositions are fully populated.

      // OPTIONAL: Initialize with what we have immediately for a "snappy" feel
      if (widget.item != null) {
        _initializeWithItem(widget.item!, isClone: widget.isClone);
      }

      await _hydrateInitialItem(forceRefresh: true);
    } else if (widget.item != null) {
      // New item but with initial data
      _initializeWithItem(widget.item!, isClone: widget.isClone);
      _applyOperationalDefaultsIfMissing();
    } else {
      _applyOperationalDefaultsIfMissing();
    }

    if (mounted) {
      setState(() {
        _suspendDirtyTracking = false;
        _isDirty = false;
      });
    } else {
      _suspendDirtyTracking = false;
      _isDirty = false;
    }
  }

  Future<void> _hydrateInitialItem({bool forceRefresh = false}) async {
    final itemId = widget.itemId ?? widget.item?.id;
    if (itemId == null ||
        _isHydratingInitialItem ||
        editingItem?.id == itemId ||
        !mounted) {
      return;
    }

    final controller = ref.read(itemsControllerProvider.notifier);
    setState(() => _isHydratingInitialItem = true);

    try {
      final freshItem = await controller.ensureItemLoaded(
        itemId,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      if (freshItem != null) {
        await Future.delayed(Duration.zero);
        if (mounted) {
          _initializeWithItem(freshItem, isClone: widget.isClone);
          _resetDirty();
        }
      } else if (widget.item != null) {
        _initializeWithItem(widget.item!, isClone: widget.isClone);
        _resetDirty();
      }
    } finally {
      if (mounted) {
        setState(() => _isHydratingInitialItem = false);
      }
    }
  }

  void _initializeWithItem(Item item, {bool isClone = false}) {
    setState(() {
      editingItem = isClone ? null : item;
      isEditMode = !isClone;
      isGoods = item.type == 'goods';

      nameCtrl.text = item.productName;
      billingNameCtrl.text = item.billingName ?? '';
      itemCodeCtrl.text = item.itemCode;
      skuCtrl.text = item.sku ?? '';
      selectedUnitId = item.unitId;
      selectedCategoryId = item.categoryId;
      isReturnable = item.isReturnable;
      pushToEcommerce = item.pushToEcommerce;
      if (item.type == 'service') {
        sacCtrl.text = item.hsnCode ?? '';
        hsnCtrl.clear();
      } else {
        hsnCtrl.text = item.hsnCode ?? '';
        sacCtrl.clear();
      }
      taxPreference = _toUiTaxPreference(item.taxPreference) ?? 'Taxable';
      intraStateTaxId = item.intraStateTaxId;
      interStateTaxId = item.interStateTaxId;

      sellingPriceCtrl.text = item.sellingPrice?.toString() ?? '';
      salesCurrency = item.sellingPriceCurrency;
      mrpCtrl.text = item.mrp?.toString() ?? '';
      ptrCtrl.text = item.ptr?.toString() ?? '';
      salesAccountId = item.salesAccountId;
      salesDescriptionCtrl.text = item.salesDescription ?? '';

      costPriceCtrl.text = item.costPrice?.toString() ?? '';
      purchaseCurrency = item.costPriceCurrency;
      purchaseAccountId = item.purchaseAccountId;
      repId = item.repId;
      preferredVendorId = item.preferredVendorId;
      purchaseDescriptionCtrl.text = item.purchaseDescription ?? '';

      dimXCtrl.text = item.length?.toString() ?? '';
      dimYCtrl.text = item.width?.toString() ?? '';
      dimZCtrl.text = item.height?.toString() ?? '';
      dimUnit = item.dimensionUnit;
      weightCtrl.text = item.weight?.toString() ?? '';
      weightUnit = item.weightUnit;
      manufacturerId = item.manufacturerId;
      brandId = item.brandId;
      selectedPackSize = item.unitPack;
      selectedLockUnitPack = item.lockUnitPack == null
          ? null
          : item.lockUnitPack!.toString();
      upcCtrl.text = item.upc ?? '';
      eanCtrl.text = item.ean ?? '';
      mpnCtrl.text = item.mpn ?? '';
      isbnCtrl.text = item.isbn ?? '';

      trackInventory = true;
      trackBinLocation = true;
      trackingMode = InventoryTrackingMode.batches;
      inventoryAccountId = item.inventoryAccountId;
      valuationMethod = item.inventoryValuationMethod;
      storageId = item.storageId;
      rackId = item.rackId;
      reorderPointCtrl.text = item.reorderPoint.toString();
      lockUnitPackCtrl.text = item.lockUnitPack?.toString() ?? '';
      reorderTermsId = item.reorderTermId;

      compositions = item.compositions ?? [];
      trackAssocIngredients = item.trackAssocIngredients;
      buyingRuleId = item.buyingRuleId;
      scheduleOfDrugId = item.scheduleOfDrugId;
      productTypeId = item.productTypeId;

      storageDescCtrl.text = item.storageDescription ?? '';
      aboutCtrl.text = item.about ?? '';
      usesDescCtrl.text = item.usesDescription ?? '';
      howToUseCtrl.text = item.howToUse ?? '';
      dosageDescCtrl.text = item.dosageDescription ?? '';
      missedDoseDescCtrl.text = item.missedDoseDescription ?? '';
      safetyAdviceCtrl.text = item.safetyAdvice ?? '';
      howItWorksCtrl.text = item.howItWorks ?? '';
      drugInteractionsCtrl.text = item.drugInteractions ?? '';
      contraindicationsCtrl.text = item.contraindications ?? '';
      sideEffectsManagementCtrl.text = item.sideEffectsManagement ?? '';
      goodToKnowCtrl.text = item.goodToKnow ?? '';
      quickTipsCtrl.text = item.quickTips ?? '';
      allergyInformationCtrl.text = item.allergyInformation ?? '';
      productHighlightsCtrl.text = item.productHighlights ?? '';
      ingredientsListCtrl.text = item.ingredientsList ?? '';
      safetyPregnancyCtrl.text = item.safetyMeasuresWarningsPregnancy ?? '';
      safetyBreastfeedingCtrl.text =
          item.safetyMeasuresWarningsBreastfeeding ?? '';
      safetyAlcoholCtrl.text = item.safetyMeasuresWarningsAlcohol ?? '';
      safetyLiverCtrl.text = item.safetyMeasuresWarningsLiver ?? '';
      safetyKidneyCtrl.text = item.safetyMeasuresWarningsKidney ?? '';
      safetyDrivingCtrl.text =
          item.safetyMeasuresWarningsUseInDrivingAndOperatingMachinery ?? '';
      safetyAllergyCtrl.text = item.safetyMeasuresWarningsAllergy ?? '';
      safetyChildrenCtrl.text = item.safetyMeasuresWarningsChildren ?? '';
      safetyOlderPatientsCtrl.text =
          item.safetyMeasuresWarningsOlderPatients ?? '';
      interactionsDrugDrugCtrl.text =
          item.interactionsDrugDrugInteractions ?? '';
      interactionsDrugDiseaseCtrl.text =
          item.interactionsDrugDiseaseInteractions ?? '';
      dosageDailyDoseCtrl.text = item.dosageDailyDose ?? '';
      dosageOverDoseCtrl.text = item.dosageOverDose ?? '';
      dosageMissedDoseCtrl.text = item.dosageMissedDose ?? '';
      referencesTextCtrl.text = item.referencesText ?? '';
      productDescriptionCtrl.text = item.productDescription ?? '';
      additionalInfoAllergyCtrl.text = item.additionalInfoAllergy ?? '';
      additionalInfoConcernsCtrl.text = item.additionalInfoConcerns ?? '';
      additionalInfoGoodToKnowCtrl.text =
          item.additionalInfoGoodToKnow ?? '';
      additionalInfoQuickTipsCtrl.text = item.additionalInfoQuickTips ?? '';
      directionsForUseCtrl.text = item.directionsForUse ?? '';
      sideEffectsCtrl.text = _joinStructuredItems(item.sideEffects);
      faqTextCtrl.text = _joinStructuredItems(item.faqText);
      _itemImages.clear();
      if (item.imageUrls != null) {
        _itemImages.addAll(item.imageUrls!);
      }
    });

    _applyOperationalDefaultsIfMissing();
  }

  Future<void> _onFilesDropped(DropDoneDetails details) async {
    final List<PlatformFile> newFiles = [];

    for (final file in details.files) {
      final bytes = await file.readAsBytes();
      newFiles.add(
        PlatformFile(
          name: file.name,
          size: bytes.length,
          bytes: bytes,
          path: file.path,
        ),
      );
    }

    if (newFiles.isNotEmpty) {
      setState(() {
        _itemImages.addAll(newFiles);
        if (_itemImages.isNotEmpty &&
            _primaryImageIndex >= _itemImages.length) {
          _primaryImageIndex = 0;
        }
      });
    }
  }

  Future<void> _pickItemImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return;

    setState(() {
      _itemImages.addAll(result.files);
      if (_itemImages.isNotEmpty && _primaryImageIndex >= _itemImages.length) {
        _primaryImageIndex = 0;
      }
    });
  }

  ItemTab selectedTab = ItemTab.composition;
  String? exemptionReason;
  final List<String> exemptionReasonOptions = [
    "GSTMARGINCHEME",
    "LACK OF STOCK",
  ];

  bool isGoods = true;

  String? _findLookupIdByName(
    List<Map<String, dynamic>> items,
    String targetName,
  ) {
    for (final item in items) {
      final candidates = <String?>[
        item['name']?.toString(),
        item['user_account_name']?.toString(),
        item['system_account_name']?.toString(),
        item['account_name']?.toString(),
        item['buying_rule']?.toString(),
        item['shedule_name']?.toString(),
        item['location_name']?.toString(),
        item['display_text']?.toString(),
        item['storage_type']?.toString(),
      ];
      for (final rawName in candidates) {
        if (rawName != null &&
            rawName.trim().toLowerCase() == targetName.trim().toLowerCase()) {
          return item['id']?.toString();
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _findLookupItemById(
    List<Map<String, dynamic>> items,
    String? id,
  ) {
    if (id == null || id.isEmpty) return null;
    for (final item in items) {
      if (item['id']?.toString() == id) {
        return item;
      }
    }
    return null;
  }

  String? _composeTooltip(List<String?> parts) {
    final cleaned = parts
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (cleaned.isEmpty) return null;
    return cleaned.join('\n');
  }

  String? _selectedStorageTooltip(ItemsState itemsState) {
    final selected = _findLookupItemById(
      itemsState.storageLocations,
      storageId,
    );
    if (selected == null) return null;

    final minTemp = selected['min_temp_c'];
    final maxTemp = selected['max_temp_c'];
    String? temperatureLine;
    if (minTemp != null && maxTemp != null) {
      temperatureLine = 'Temperature Range: ${minTemp}°C to ${maxTemp}°C';
    } else if (maxTemp != null) {
      temperatureLine = 'Temperature Range: Up to ${maxTemp}°C';
    }

    return _composeTooltip([
      selected['display_text']?.toString() ??
          selected['description']?.toString(),
      temperatureLine,
      selected['common_examples'] != null
          ? 'Examples: ${selected['common_examples']}'
          : null,
      selected['is_cold_chain'] == true ? 'Cold Chain Handling: Yes' : null,
      selected['requires_fridge'] == true ? 'Requires Fridge: Yes' : null,
    ]);
  }

  String _formatStorageLabel(Map<String, dynamic>? storage) {
    if (storage == null) return '';

    final displayText =
        storage['display_text']?.toString().trim().isNotEmpty == true
        ? storage['display_text'].toString().trim()
        : storage['name']?.toString().trim().isNotEmpty == true
        ? storage['name'].toString().trim()
        : storage['location_name']?.toString().trim().isNotEmpty == true
        ? storage['location_name'].toString().trim()
        : 'Unknown';

    final storageType = storage['storage_type']?.toString().trim();
    if (storageType == null ||
        storageType.isEmpty ||
        storageType.toLowerCase() == displayText.toLowerCase()) {
      return displayText;
    }

    return '$displayText [$storageType]';
  }

  void _applyOperationalDefaultsIfMissing() {
    if (!mounted) return;
    final itemsState = ref.read(itemsControllerProvider);
    if (itemsState.isLoadingLookups) return;

    final defaultBuyingRuleId = _findLookupIdByName(
      itemsState.buyingRules,
      _defaultBuyingRuleName,
    );
    final defaultDrugScheduleId = _findLookupIdByName(
      itemsState.drugSchedules,
      _defaultDrugScheduleName,
    );
    final defaultStorageId = _findLookupIdByName(
      itemsState.storageLocations,
      _defaultStorageName,
    );

    final defaultInventoryAccountId = _findLookupIdByName(
      itemsState.accounts,
      _defaultInventoryAccountName,
    );
    final defaultSalesAccountId = _findLookupIdByName(
      itemsState.accounts,
      _defaultSalesAccountName,
    );
    final defaultPurchaseAccountId =
        _findLookupIdByName(itemsState.accounts, _defaultPurchaseAccountName) ??
        _findLookupIdByName(
          itemsState.accounts,
          _defaultPurchaseAccountAltName,
        );

    setState(() {
      buyingRuleId ??= defaultBuyingRuleId;
      scheduleOfDrugId ??= defaultDrugScheduleId;
      storageId ??= defaultStorageId;
      valuationMethod ??= 'FEFO';
      inventoryAccountId ??= defaultInventoryAccountId;
      salesAccountId ??= defaultSalesAccountId;
      purchaseAccountId ??= defaultPurchaseAccountId;
    });
  }

  static const Map<String, String> _backendToUiTaxPref = {
    'taxable': 'Taxable',
    'exempt': 'Tax Exempt',
    'non-taxable': 'Non-Taxable',
  };

  static const Map<String, String> _uiToBackendTaxPref = {
    'Taxable': 'taxable',
    'Tax Exempt': 'exempt',
    'Non-Taxable': 'non-taxable',
  };

  String? _toUiTaxPreference(String? backendValue) {
    if (backendValue == null) return null;
    return _backendToUiTaxPref[backendValue.toLowerCase()];
  }

  String? _toBackendTaxPreference(String? uiValue) {
    if (uiValue == null) return null;
    return _uiToBackendTaxPref[uiValue];
  }

  final nameCtrl = TextEditingController();
  final billingNameCtrl = TextEditingController();
  final itemCodeCtrl = TextEditingController();
  final skuCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  String? selectedCategoryId;
  String? selectedUnitId;
  final hsnCtrl = TextEditingController();
  final sacCtrl = TextEditingController();
  String? taxPreference = 'Taxable';
  bool isReturnable = true;
  bool pushToEcommerce = false;
  bool trackInventory = true;
  bool trackBinLocation = true;
  String? intraStateTaxId;
  String? interStateTaxId;

  final dimXCtrl = TextEditingController();
  final dimYCtrl = TextEditingController();
  final dimZCtrl = TextEditingController();
  String dimUnit = 'cm';
  final weightCtrl = TextEditingController();
  String weightUnit = 'kg';
  String? manufacturerId;
  String? brandId;
  String? selectedPackSize;
  String? selectedLockUnitPack;
  final upcCtrl = TextEditingController();
  final eanCtrl = TextEditingController();
  final mpnCtrl = TextEditingController();
  final isbnCtrl = TextEditingController();

  final sellingPriceCtrl = TextEditingController();
  final mrpCtrl = TextEditingController();
  final ptrCtrl = TextEditingController();
  final salesDescriptionCtrl = TextEditingController();
  String salesCurrency = 'INR';
  String? salesAccountId;
  bool sellable = true;

  final costPriceCtrl = TextEditingController();
  final purchaseDescriptionCtrl = TextEditingController();
  String purchaseCurrency = 'INR';
  String? purchaseAccountId;
  String? repId;
  String? preferredVendorId;
  bool purchasable = true;

  InventoryTrackingMode trackingMode = InventoryTrackingMode.batches;
  String? inventoryAccountId;
  String? valuationMethod = 'FEFO';
  String? storageId;
  String? rackId;
  List<ItemComposition> compositions = [];
  bool trackAssocIngredients = true;
  String? buyingRuleId;
  String? scheduleOfDrugId;
  String? productTypeId;
  final reorderPointCtrl = TextEditingController();
  final lockUnitPackCtrl = TextEditingController();
  String? reorderTermsId;

  // eCommerce Controllers
  final storageDescCtrl = TextEditingController();
  final aboutCtrl = TextEditingController();
  final usesDescCtrl = TextEditingController();
  final howToUseCtrl = TextEditingController();
  final dosageDescCtrl = TextEditingController();
  final missedDoseDescCtrl = TextEditingController();
  final safetyAdviceCtrl = TextEditingController();
  final howItWorksCtrl = TextEditingController();
  final drugInteractionsCtrl = TextEditingController();
  final contraindicationsCtrl = TextEditingController();
  final sideEffectsManagementCtrl = TextEditingController();
  final goodToKnowCtrl = TextEditingController();
  final quickTipsCtrl = TextEditingController();
  final allergyInformationCtrl = TextEditingController();
  final productHighlightsCtrl = TextEditingController();
  final ingredientsListCtrl = TextEditingController();
  final safetyPregnancyCtrl = TextEditingController();
  final safetyBreastfeedingCtrl = TextEditingController();
  final safetyAlcoholCtrl = TextEditingController();
  final safetyLiverCtrl = TextEditingController();
  final safetyKidneyCtrl = TextEditingController();
  final safetyDrivingCtrl = TextEditingController();
  final safetyAllergyCtrl = TextEditingController();
  final safetyChildrenCtrl = TextEditingController();
  final safetyOlderPatientsCtrl = TextEditingController();
  final interactionsDrugDrugCtrl = TextEditingController();
  final interactionsDrugDiseaseCtrl = TextEditingController();
  final dosageDailyDoseCtrl = TextEditingController();
  final dosageOverDoseCtrl = TextEditingController();
  final dosageMissedDoseCtrl = TextEditingController();
  final referencesTextCtrl = TextEditingController();
  final productDescriptionCtrl = TextEditingController();
  final additionalInfoAllergyCtrl = TextEditingController();
  final additionalInfoConcernsCtrl = TextEditingController();
  final additionalInfoGoodToKnowCtrl = TextEditingController();
  final additionalInfoQuickTipsCtrl = TextEditingController();
  final directionsForUseCtrl = TextEditingController();
  final sideEffectsCtrl = TextEditingController();
  final faqTextCtrl = TextEditingController();

  String _joinStructuredItems(List<String>? values) {
    if (values == null || values.isEmpty) return '';
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join('\n\n');
  }

  List<String>? _splitStructuredItems(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final paragraphParts = text
        .split(RegExp(r'\r?\n\s*\r?\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (paragraphParts.length > 1) {
      return paragraphParts;
    }

    final lineParts = text
        .split(RegExp(r'\r?\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return lineParts.isEmpty ? null : lineParts;
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsControllerProvider);
    final itemsController = ref.read(itemsControllerProvider.notifier);
    final isDirectEditLoadPending =
        widget.itemId != null && editingItem == null && !widget.isClone;

    if (isDirectEditLoadPending &&
        !_isHydratingInitialItem &&
        !itemsState.isHydratingItem &&
        !itemsState.isLoadingLookups &&
        itemsState.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hydrateInitialItem();
      });
    }

    if (isDirectEditLoadPending && itemsState.error == null) {
      return ZerpaiLayout(
        pageTitle: 'Loading Item...',
        child: Skeletonizer(
          enabled: true,
          ignoreContainers: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  height: 40,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 40,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Container(height: 40, width: 300, color: Colors.white),
                const SizedBox(height: 24),
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isDirectEditLoadPending && itemsState.error != null) {
      return ZerpaiLayout(
        pageTitle: 'Loading Item...',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                itemsState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppTheme.textBody),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _hydrateInitialItem(forceRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return DropTarget(
      onDragDone: (_) {}, // Global intercept to prevent browser navigation
      child: ZerpaiLayout(
        pageTitle: (widget.itemId != null || isEditMode)
            ? 'Edit Item'
            : 'New Item',
        enableBodyScroll: true,
        onCancel: () async {
          final shouldDiscard =
              !_isDirty ||
              await showUnsavedChangesDialog(
                context,
                title: 'Leave this page?',
                message:
                    'If you leave, your unsaved item changes will be discarded.',
              );

          if (!mounted || !shouldDiscard) return;
          DraftStorageService.clear(_draftKey);
          if (isEditMode && editingItem?.id != null) {
            context.goNamed(
              AppRoutes.itemsDetail,
              pathParameters: {
                'orgSystemId': _currentOrgSystemId(),
                'id': editingItem!.id!,
              },
            );
          } else if (context.canPop()) {
            context.pop();
          } else {
            _goToItemsList();
          }
        },
        isDirty: _isDirty,
        footer: _buildSaveCancel(itemsController, itemsState),
        child: Form(
          onChanged: _markDirty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasDraft) _buildDraftBanner(),
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
                  _markDirty();
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
    );
  }

  Widget _buildSaveCancel(ItemsController controller, ItemsState itemsState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZButton.primary(
              label: isEditMode ? "Update" : "Save",
              loading: itemsState.isSaving,
              onPressed: itemsState.isSaving
                  ? null
                  : () async {
                      String? primaryImageUrl;
                      List<String>? imageUrls;

                      if (_itemImages.isNotEmpty) {
                        try {
                          final storage = StorageService();

                          // Separate existing URLs and new PlatformFiles
                          final newFiles = _itemImages
                              .whereType<PlatformFile>()
                              .toList();

                          List<String> uploadedUrls = [];
                          if (newFiles.isNotEmpty) {
                            uploadedUrls = await storage.uploadProductImages(
                              newFiles,
                            );
                          }

                          // Reconstruct the final list in the correct order
                          final List<String> finalUrls = [];
                          int uploadedIdx = 0;
                          for (var item in _itemImages) {
                            if (item is String) {
                              finalUrls.add(item);
                            } else if (item is PlatformFile) {
                              if (uploadedIdx < uploadedUrls.length) {
                                finalUrls.add(uploadedUrls[uploadedIdx]);
                                uploadedIdx++;
                              }
                            }
                          }

                          if (finalUrls.isNotEmpty) {
                            primaryImageUrl = finalUrls[_primaryImageIndex];
                            imageUrls = finalUrls;
                          }
                        } catch (e) {
                          if (mounted) {
                            ZerpaiToast.info(
                              context,
                              'Warning: Failed to upload images: $e',
                            );
                          }
                        }
                      } else if (isEditMode) {
                        primaryImageUrl = null;
                        imageUrls = [];
                      }

                      final item = Item(
                        buyingRuleId:
                            buyingRuleId ??
                            _findLookupIdByName(
                              itemsState.buyingRules,
                              _defaultBuyingRuleName,
                            ),
                        scheduleOfDrugId:
                            scheduleOfDrugId ??
                            _findLookupIdByName(
                              itemsState.drugSchedules,
                              _defaultDrugScheduleName,
                            ),
                        productTypeId: productTypeId,
                        id: isEditMode ? editingItem?.id : null,
                        type: isGoods ? 'goods' : 'service',
                        productName: nameCtrl.text.trim(),
                        billingName: billingNameCtrl.text.trim().isEmpty
                            ? null
                            : billingNameCtrl.text.trim(),
                        itemCode: itemCodeCtrl.text.trim(),
                        sku: skuCtrl.text.trim().isEmpty
                            ? null
                            : skuCtrl.text.trim(),
                        unitId: selectedUnitId ?? '',
                        categoryId: isGoods ? selectedCategoryId : null,
                        isReturnable: isReturnable,
                        pushToEcommerce: pushToEcommerce,
                        hsnCode: isGoods
                            ? (hsnCtrl.text.trim().isEmpty
                                  ? null
                                  : hsnCtrl.text.trim())
                            : (sacCtrl.text.trim().isEmpty
                                  ? null
                                  : sacCtrl.text.trim()),
                        taxPreference: _toBackendTaxPreference(taxPreference),
                        exemptionReason: exemptionReason,
                        intraStateTaxId: intraStateTaxId,
                        interStateTaxId: interStateTaxId,
                        sellingPrice: sellingPriceCtrl.text.isEmpty
                            ? null
                            : double.tryParse(sellingPriceCtrl.text),
                        sellingPriceCurrency: salesCurrency,
                        mrp: mrpCtrl.text.isEmpty
                            ? null
                            : double.tryParse(mrpCtrl.text),
                        ptr: ptrCtrl.text.isEmpty
                            ? null
                            : double.tryParse(ptrCtrl.text),
                        salesAccountId: salesAccountId,
                        salesDescription:
                            salesDescriptionCtrl.text.trim().isEmpty
                            ? null
                            : salesDescriptionCtrl.text.trim(),
                        costPrice: costPriceCtrl.text.isEmpty
                            ? null
                            : double.tryParse(costPriceCtrl.text),
                        costPriceCurrency: purchaseCurrency,
                        purchaseAccountId: purchaseAccountId,
                        repId: repId,
                        preferredVendorId: preferredVendorId,
                        purchaseDescription:
                            purchaseDescriptionCtrl.text.trim().isEmpty
                            ? null
                            : purchaseDescriptionCtrl.text.trim(),
                        length: dimXCtrl.text.isEmpty
                            ? null
                            : double.tryParse(dimXCtrl.text),
                        width: dimYCtrl.text.isEmpty
                            ? null
                            : double.tryParse(dimYCtrl.text),
                        height: dimZCtrl.text.isEmpty
                            ? null
                            : double.tryParse(dimZCtrl.text),
                        dimensionUnit: dimUnit,
                        weight: weightCtrl.text.isEmpty
                            ? null
                            : double.tryParse(weightCtrl.text),
                        weightUnit: weightUnit,
                        manufacturerId: manufacturerId,
                        brandId: brandId,
                        unitPack: isGoods
                            ? ((selectedPackSize?.trim().isEmpty ?? true)
                                  ? null
                                  : selectedPackSize!.trim())
                            : null,
                        mpn: mpnCtrl.text.trim().isEmpty
                            ? null
                            : mpnCtrl.text.trim(),
                        upc: upcCtrl.text.trim().isEmpty
                            ? null
                            : upcCtrl.text.trim(),
                        isbn: isbnCtrl.text.trim().isEmpty
                            ? null
                            : isbnCtrl.text.trim(),
                        ean: eanCtrl.text.trim().isEmpty
                            ? null
                            : eanCtrl.text.trim(),
                        isTrackInventory: isGoods ? true : false,
                        trackBinLocation: isGoods ? true : false,
                        trackBatches: isGoods ? true : false,
                        trackSerialNumber: false,
                        inventoryAccountId: isGoods ? inventoryAccountId : null,
                        inventoryValuationMethod: isGoods
                            ? valuationMethod
                            : null,
                        storageId: isGoods
                            ? (storageId ??
                                  _findLookupIdByName(
                                    itemsState.storageLocations,
                                    _defaultStorageName,
                                  ))
                            : null,
                        rackId: isGoods ? rackId : null,
                        reorderPoint: isGoods
                            ? (reorderPointCtrl.text.isEmpty
                                  ? 0
                                  : int.tryParse(reorderPointCtrl.text) ?? 0)
                            : 0,
                        reorderTermId: isGoods ? reorderTermsId : null,
                        lockUnitPack: isGoods
                            ? (lockUnitPackCtrl.text.isEmpty
                                  ? null
                                  : double.tryParse(lockUnitPackCtrl.text))
                            : null,
                        compositions: compositions,
                        trackAssocIngredients: trackAssocIngredients,
                        primaryImageUrl: primaryImageUrl,
                        imageUrls: imageUrls,
                        isActive: true,
                        isLock: false,
                        storageDescription: storageDescCtrl.text.trim().isEmpty
                            ? null
                            : storageDescCtrl.text.trim(),
                        about: aboutCtrl.text.trim().isEmpty
                            ? null
                            : aboutCtrl.text.trim(),
                        usesDescription: usesDescCtrl.text.trim().isEmpty
                            ? null
                            : usesDescCtrl.text.trim(),
                        howToUse: howToUseCtrl.text.trim().isEmpty
                            ? null
                            : howToUseCtrl.text.trim(),
                        dosageDescription: dosageDescCtrl.text.trim().isEmpty
                            ? null
                            : dosageDescCtrl.text.trim(),
                        missedDoseDescription:
                            missedDoseDescCtrl.text.trim().isEmpty
                            ? null
                            : missedDoseDescCtrl.text.trim(),
                        safetyAdvice: safetyAdviceCtrl.text.trim().isEmpty
                            ? null
                            : safetyAdviceCtrl.text.trim(),
                        howItWorks: howItWorksCtrl.text.trim().isEmpty
                            ? null
                            : howItWorksCtrl.text.trim(),
                        drugInteractions:
                            drugInteractionsCtrl.text.trim().isEmpty
                            ? null
                            : drugInteractionsCtrl.text.trim(),
                        contraindications:
                            contraindicationsCtrl.text.trim().isEmpty
                            ? null
                            : contraindicationsCtrl.text.trim(),
                        sideEffectsManagement:
                            sideEffectsManagementCtrl.text.trim().isEmpty
                            ? null
                            : sideEffectsManagementCtrl.text.trim(),
                        goodToKnow: goodToKnowCtrl.text.trim().isEmpty
                            ? null
                            : goodToKnowCtrl.text.trim(),
                        quickTips: quickTipsCtrl.text.trim().isEmpty
                            ? null
                            : quickTipsCtrl.text.trim(),
                        allergyInformation:
                            allergyInformationCtrl.text.trim().isEmpty
                            ? null
                            : allergyInformationCtrl.text.trim(),
                        productHighlights:
                            productHighlightsCtrl.text.trim().isEmpty
                            ? null
                            : productHighlightsCtrl.text.trim(),
                        safetyMeasuresWarningsPregnancy:
                            safetyPregnancyCtrl.text.trim().isEmpty
                            ? null
                            : safetyPregnancyCtrl.text.trim(),
                        safetyMeasuresWarningsBreastfeeding:
                            safetyBreastfeedingCtrl.text.trim().isEmpty
                            ? null
                            : safetyBreastfeedingCtrl.text.trim(),
                        safetyMeasuresWarningsAlcohol:
                            safetyAlcoholCtrl.text.trim().isEmpty
                            ? null
                            : safetyAlcoholCtrl.text.trim(),
                        safetyMeasuresWarningsLiver:
                            safetyLiverCtrl.text.trim().isEmpty
                            ? null
                            : safetyLiverCtrl.text.trim(),
                        safetyMeasuresWarningsKidney:
                            safetyKidneyCtrl.text.trim().isEmpty
                            ? null
                            : safetyKidneyCtrl.text.trim(),
                        safetyMeasuresWarningsUseInDrivingAndOperatingMachinery:
                            safetyDrivingCtrl.text.trim().isEmpty
                            ? null
                            : safetyDrivingCtrl.text.trim(),
                        safetyMeasuresWarningsAllergy:
                            safetyAllergyCtrl.text.trim().isEmpty
                            ? null
                            : safetyAllergyCtrl.text.trim(),
                        safetyMeasuresWarningsChildren:
                            safetyChildrenCtrl.text.trim().isEmpty
                            ? null
                            : safetyChildrenCtrl.text.trim(),
                        safetyMeasuresWarningsOlderPatients:
                            safetyOlderPatientsCtrl.text.trim().isEmpty
                            ? null
                            : safetyOlderPatientsCtrl.text.trim(),
                        interactionsDrugDrugInteractions:
                            interactionsDrugDrugCtrl.text.trim().isEmpty
                            ? null
                            : interactionsDrugDrugCtrl.text.trim(),
                        interactionsDrugDiseaseInteractions:
                            interactionsDrugDiseaseCtrl.text.trim().isEmpty
                            ? null
                            : interactionsDrugDiseaseCtrl.text.trim(),
                        dosageDailyDose:
                            dosageDailyDoseCtrl.text.trim().isEmpty
                            ? null
                            : dosageDailyDoseCtrl.text.trim(),
                        dosageOverDose:
                            dosageOverDoseCtrl.text.trim().isEmpty
                            ? null
                            : dosageOverDoseCtrl.text.trim(),
                        dosageMissedDose:
                            dosageMissedDoseCtrl.text.trim().isEmpty
                            ? null
                            : dosageMissedDoseCtrl.text.trim(),
                        referencesText:
                            referencesTextCtrl.text.trim().isEmpty
                            ? null
                            : referencesTextCtrl.text.trim(),
                        productDescription:
                            productDescriptionCtrl.text.trim().isEmpty
                            ? null
                            : productDescriptionCtrl.text.trim(),
                        additionalInfoAllergy:
                            additionalInfoAllergyCtrl.text.trim().isEmpty
                            ? null
                            : additionalInfoAllergyCtrl.text.trim(),
                        additionalInfoConcerns:
                            additionalInfoConcernsCtrl.text.trim().isEmpty
                            ? null
                            : additionalInfoConcernsCtrl.text.trim(),
                        additionalInfoGoodToKnow:
                            additionalInfoGoodToKnowCtrl.text.trim().isEmpty
                            ? null
                            : additionalInfoGoodToKnowCtrl.text.trim(),
                        additionalInfoQuickTips:
                            additionalInfoQuickTipsCtrl.text.trim().isEmpty
                            ? null
                            : additionalInfoQuickTipsCtrl.text.trim(),
                        directionsForUse:
                            directionsForUseCtrl.text.trim().isEmpty
                            ? null
                            : directionsForUseCtrl.text.trim(),
                        sideEffects: _splitStructuredItems(
                          sideEffectsCtrl.text,
                        ),
                        faqText: _splitStructuredItems(faqTextCtrl.text),
                        ingredientsList:
                            ingredientsListCtrl.text.trim().isEmpty
                            ? null
                            : ingredientsListCtrl.text.trim(),
                      );

                      final success = isEditMode
                          ? await controller.updateItem(item)
                          : await controller.createItem(item);
                      if (!mounted) return;
                      if (success) {
                        DraftStorageService.clear(_draftKey);
                        _resetDirty();
                        ZerpaiBuilders.showSuccessToast(
                          context,
                          'Item details have been saved.',
                        );
                        if (isEditMode && item.id != null) {
                          context.goNamed(
                            AppRoutes.itemsDetail,
                            pathParameters: {
                              'orgSystemId': _currentOrgSystemId(),
                              'id': item.id!,
                            },
                          );
                        } else {
                          _goToItemsList();
                        }
                      } else {
                        final freshState = ref.read(itemsControllerProvider);
                        final errors = freshState.validationErrors;
                        if (errors.isNotEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Validation failed: ${errors.values.first}',
                          );
                        } else if (freshState.error != null) {
                          ZerpaiToast.error(
                            context,
                            'Error: ${freshState.error}',
                          );
                        }
                      }
                    },
            ),
            const SizedBox(width: 12),
            ZButton.secondary(
              label: "Cancel",
              onPressed: () async {
                final shouldDiscard =
                    !_isDirty ||
                    await showUnsavedChangesDialog(
                      context,
                      title: 'Leave this page?',
                      message:
                          'If you leave, your unsaved item changes will be discarded.',
                    );

                if (!mounted || !shouldDiscard) return;

                DraftStorageService.clear(_draftKey);
                if (isEditMode && editingItem?.id != null) {
                  context.goNamed(
                    AppRoutes.itemsDetail,
                    pathParameters: {
                      'orgSystemId': _currentOrgSystemId(),
                      'id': editingItem!.id!,
                    },
                  );
                } else if (context.canPop()) {
                  context.pop();
                } else {
                  _goToItemsList();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _checkLookupUsage(
    String lookupKey,
    Map<String, dynamic> item,
  ) async {
    try {
      final String? id = item['id']?.toString();
      if (id == null) return null;

      // Extract name from various possible fields
      final String? _ =
          item['name']?.toString() ??
          item['item_content']?.toString() ??
          item['content_name']?.toString() ??
          item['item_strength']?.toString() ??
          item['strength_name']?.toString() ??
          item['buying_rule']?.toString() ??
          item['shedule_name']?.toString() ??
          item['schedule_name']?.toString();

      final controller = ref.read(itemsControllerProvider.notifier);
      return await controller.checkLookupUsage(lookupKey, item);
    } catch (_) {
      return 'Unable to verify usage for deletion.';
    }
  }

  Future<void> _openCategoryConfigDialog() async {
    final controller = ref.read(itemsControllerProvider.notifier);
    await controller.refreshCategories(useCache: false);
    if (!mounted) return;
    final itemsState = ref.read(itemsControllerProvider);

    showDialog(
      context: context,
      builder: (context) => ManageCategoriesDialog(
        nodes: CategoryNode.fromFlatList(itemsState.categories),
        flatList: itemsState.categories,
        selectedCategory: selectedCategoryId,
        onCategoryApplied: (id) => setState(() => selectedCategoryId = id),
        onSave: (newList) => controller.syncCategories(newList),
      ),
    );
  }

  void _openHsnSacSearch() async {
    final result = await showDialog<HsnSacCode>(
      context: context,
      useSafeArea: false,
      builder: (context) => HsnSacSearchModal(
        type: isGoods ? 'HSN' : 'SAC',
        initialQuery: isGoods ? hsnCtrl.text : sacCtrl.text,
      ),
    );

    if (result != null) {
      setState(() {
        if (isGoods) {
          hsnCtrl.text = result.code;
        } else {
          sacCtrl.text = result.code;
        }

        if (result.code.isNotEmpty) {
          taxPreference = 'Taxable';
        }

        if (result.gstRate != null) {
          final itemsState = ref.read(itemsControllerProvider);
          final matchingRate = itemsState.taxRates
              .where((r) => (r.taxRate - result.gstRate!).abs() < 0.01)
              .firstOrNull;
          if (matchingRate != null) {
            intraStateTaxId = matchingRate.id;
            interStateTaxId = matchingRate.id;
          }
        }
      });
    }
  }
}
