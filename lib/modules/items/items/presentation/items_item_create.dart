import 'dart:async';
import 'package:flutter/material.dart';
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
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_list_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_reorder_terms_dialog.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/composition_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/formulation_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/sales_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/purchase_section.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/default_tax_rates_section.dart';
import 'package:zerpai_erp/shared/widgets/inputs/category_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_categories_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/shared/widgets/hsn_sac_search_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/services/draft_storage_service.dart';

part 'sections/items_item_create_primary_info.dart';
part 'sections/items_item_create_images.dart';
part 'sections/items_item_create_tabs.dart';
part 'sections/items_item_create_inventory.dart';
part 'sections/items_item_create_settings.dart';
part 'sections/items_item_create_widgets.dart';
part 'sections/items_item_create_components.dart';
part 'sections/more_info_section.dart';

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

  const ItemCreateScreen({
    super.key,
    this.item,
    this.itemId,
    this.isClone = false,
  });

  @override
  ConsumerState<ItemCreateScreen> createState() => _ItemCreateScreenState();
}

class _ItemCreateScreenState extends ConsumerState<ItemCreateScreen> {
  // Edit mode - stores the item being edited
  Item? editingItem;
  bool isEditMode = false;
  bool _isHydratingInitialItem = false;

  // Ghost Draft
  static const _draftKey = 'item_create';
  Timer? _draftTimer;
  bool _hasDraft = false;

  void updateState(VoidCallback fn) => setState(fn);

  // ---------------- IMAGES ----------------
  final List<dynamic> _itemImages =
      []; // Can be String (URL) or PlatformFile (Local)
  int _primaryImageIndex = 0;
  bool _isImageDragging = false;

  @override
  void initState() {
    super.initState();
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
    for (final c in sideEffectCtrls) {
      c.dispose();
    }
    for (final c in faqTextCtrls) {
      c.dispose();
    }
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
      'salesDescription': salesDescriptionCtrl.text,
      'purchaseDescription': purchaseDescriptionCtrl.text,
      'manufacturerId': manufacturerId,
      'brandId': brandId,
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
      salesDescriptionCtrl.text = data['salesDescription'] as String? ?? '';
      purchaseDescriptionCtrl.text =
          data['purchaseDescription'] as String? ?? '';
      manufacturerId = data['manufacturerId'] as String?;
      brandId = data['brandId'] as String?;
      _hasDraft = false;
    });

    DraftStorageService.clear(_draftKey);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft restored successfully.')),
      );
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
          const Icon(Icons.history, color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'We found an unsaved draft. Would you like to restore it?',
              style: TextStyle(
                color: Color(0xFF92400E),
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
                color: Color(0xFFF59E0B),
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
              style: TextStyle(color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  void _loadInitialData() async {
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
        }
      } else if (widget.item != null) {
        _initializeWithItem(widget.item!, isClone: widget.isClone);
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
      upcCtrl.text = item.upc ?? '';
      eanCtrl.text = item.ean ?? '';
      mpnCtrl.text = item.mpn ?? '';
      isbnCtrl.text = item.isbn ?? '';

      trackInventory = item.isTrackInventory;
      trackBinLocation = item.trackBinLocation;
      if (item.trackBatches) {
        trackingMode = InventoryTrackingMode.batches;
      } else if (item.trackSerialNumber) {
        trackingMode = InventoryTrackingMode.serialNumbers;
      } else {
        trackingMode = InventoryTrackingMode.none;
      }
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

      storageDescCtrl.text = item.storageDescription ?? '';
      aboutCtrl.text = item.about ?? '';
      usesDescCtrl.text = item.usesDescription ?? '';
      howToUseCtrl.text = item.howToUse ?? '';
      dosageDescCtrl.text = item.dosageDescription ?? '';
      missedDoseDescCtrl.text = item.missedDoseDescription ?? '';
      safetyAdviceCtrl.text = item.safetyAdvice ?? '';

      sideEffectCtrls.clear();
      if (item.sideEffects != null) {
        for (var se in item.sideEffects!) {
          sideEffectCtrls.add(TextEditingController(text: se));
        }
      }
      faqTextCtrls.clear();
      if (item.faqText != null) {
        for (var f in item.faqText!) {
          faqTextCtrls.add(TextEditingController(text: f));
        }
      }
      _itemImages.clear();
      if (item.imageUrls != null) {
        _itemImages.addAll(item.imageUrls!);
      }
    });
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
  bool trackInventory = false;
  bool trackBinLocation = false;
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
  String? preferredVendorId;
  bool purchasable = true;

  InventoryTrackingMode trackingMode = InventoryTrackingMode.batches;
  String? inventoryAccountId;
  String? valuationMethod;
  String? storageId;
  String? rackId;
  List<ItemComposition> compositions = [];
  bool trackAssocIngredients = true;
  String? buyingRuleId;
  String? scheduleOfDrugId;
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
  final List<TextEditingController> sideEffectCtrls = [];
  final List<TextEditingController> faqTextCtrls = [];

  void _addSideEffect() {
    setState(() => sideEffectCtrls.add(TextEditingController()));
  }

  void _removeSideEffect(int index) {
    setState(() {
      sideEffectCtrls[index].dispose();
      sideEffectCtrls.removeAt(index);
    });
  }

  void _addFaq() {
    setState(() => faqTextCtrls.add(TextEditingController()));
  }

  void _removeFaq(int index) {
    setState(() {
      faqTextCtrls[index].dispose();
      faqTextCtrls.removeAt(index);
    });
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
      return const ZerpaiLayout(
        pageTitle: 'Loading Item...',
        child: Center(child: CircularProgressIndicator()),
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
                style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _hydrateInitialItem(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
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
        footer: _buildSaveCancel(itemsController, itemsState),
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
              },
            ),
            const SizedBox(height: 24),
            _buildTabsCard(itemsState),
            const SizedBox(height: 24),
            if (isGoods) _buildInventoryFlags(itemsState),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveCancel(ItemsController controller, ItemsState itemsState) {
    return Container(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ZButton.secondary(
            label: "Cancel",
            onPressed: () {
              DraftStorageService.clear(_draftKey);
              if (isEditMode && editingItem?.id != null) {
                // If we are editing, go back to the details page (split view)
                context.goNamed(
                  AppRoutes.itemsDetail,
                  pathParameters: {'id': editingItem!.id!},
                );
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.itemsReport);
              }
            },
          ),
          const SizedBox(width: 12),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Warning: Failed to upload images: $e',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    } else if (isEditMode) {
                      primaryImageUrl = null;
                      imageUrls = [];
                    }

                    final item = Item(
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
                      salesDescription: salesDescriptionCtrl.text.trim().isEmpty
                          ? null
                          : salesDescriptionCtrl.text.trim(),
                      costPrice: costPriceCtrl.text.isEmpty
                          ? null
                          : double.tryParse(costPriceCtrl.text),
                      costPriceCurrency: purchaseCurrency,
                      purchaseAccountId: purchaseAccountId,
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
                      isTrackInventory: isGoods ? trackInventory : false,
                      trackBinLocation: isGoods ? trackBinLocation : false,
                      trackBatches:
                          isGoods &&
                          (trackingMode == InventoryTrackingMode.batches),
                      trackSerialNumber:
                          isGoods &&
                          (trackingMode == InventoryTrackingMode.serialNumbers),
                      inventoryAccountId: isGoods ? inventoryAccountId : null,
                      inventoryValuationMethod: isGoods
                          ? valuationMethod
                          : null,
                      storageId: isGoods ? storageId : null,
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
                      buyingRuleId: buyingRuleId,
                      scheduleOfDrugId: scheduleOfDrugId,
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
                      sideEffects: sideEffectCtrls
                          .map((e) => e.text.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      faqText: faqTextCtrls
                          .map((e) => e.text.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                    );

                    final success = isEditMode
                        ? await controller.updateItem(item)
                        : await controller.createItem(item);
                    if (!mounted) return;
                    if (success) {
                      DraftStorageService.clear(_draftKey);
                      ZerpaiBuilders.showSuccessToast(
                        context,
                        'Item details have been saved.',
                      );
                      if (isEditMode && item.id != null) {
                        context.goNamed(
                          AppRoutes.itemsDetail,
                          pathParameters: {'id': item.id!},
                        );
                      } else {
                        context.goNamed(AppRoutes.itemsReport);
                      }
                    } else {
                      final freshState = ref.read(itemsControllerProvider);
                      final errors = freshState.validationErrors;
                      if (errors.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Validation failed: ${errors.values.first}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (freshState.error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${freshState.error}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
          ),
        ],
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

  void _openCategoryConfigDialog() {
    final itemsState = ref.read(itemsControllerProvider);
    final controller = ref.read(itemsControllerProvider.notifier);

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
