part of '../pages/items_item_create.dart';

extension _ItemCreateTabs on _ItemCreateScreenState {
  List<String> _packSizeOptions(ItemsState itemsState) {
    final labels = itemsState.units
        .where((unit) => unit.isActive)
        .map((unit) => _formatUnitLabel(itemsState, unit.id))
        .where((label) => label.trim().isNotEmpty)
        .toList();
    if (selectedPackSize != null && selectedPackSize!.trim().isNotEmpty) {
      labels.add(selectedPackSize!.trim());
    }
    return labels.toSet().toList();
  }

  String? _lockUnitPackDisplayValue(ItemsState itemsState) {
    final raw = selectedLockUnitPack?.trim() ?? lockUnitPackCtrl.text.trim();
    if (raw.isEmpty) return null;
    final options = _packSizeOptions(itemsState);
    for (final option in options) {
      final match = RegExp(r'\(([^()]+)\)\s*$').firstMatch(option);
      final unitPack = match?.group(1)?.trim() ?? '';
      if (unitPack == raw) return option;
    }
    return raw;
  }

  void _onLockUnitPackChanged(ItemsState itemsState, String? value) {
    updateState(() {
      selectedLockUnitPack = value?.trim();
      final text = value?.trim() ?? '';
      if (text.isEmpty) {
        lockUnitPackCtrl.clear();
        return;
      }
      final options = _packSizeOptions(itemsState);
      if (options.contains(text)) {
        final match = RegExp(r'\(([^()]+)\)\s*$').firstMatch(text);
        lockUnitPackCtrl.text = match?.group(1)?.trim() ?? text;
        return;
      }
      lockUnitPackCtrl.text = text;
    });
  }

  Future<void> _openPackSizeDialog(ItemsState itemsState) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => ManagePackSizesDialog(
        units: itemsState.units,
        lookupLabelForUnitId: (unitId) => _formatUnitLabel(itemsState, unitId),
        initialPackSize: selectedPackSize,
      ),
    );
    if (selected == null || selected.trim().isEmpty) return;
    updateState(() => selectedPackSize = selected.trim());
  }

  Widget _buildTabsCard(ItemsState itemsState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================================
          // TAB HEADERS
          // ============================================================
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
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
                  _tabTitleWithCheckbox(
                    'Sales Information',
                    sellable,
                    (v) => updateState(() {
                      sellable = v ?? false;
                      if (sellable) {
                        selectedTab = ItemTab.sales;
                      }
                    }),
                    active: selectedTab == ItemTab.sales,
                    onTap: () => _setSelectedTab(ItemTab.sales),
                  ),
                  _tabTitleWithCheckbox(
                    'Purchase Information',
                    purchasable,
                    (v) => updateState(() {
                      purchasable = v ?? false;
                      if (purchasable) {
                        selectedTab = ItemTab.purchase;
                      }
                    }),
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

          // ============================================================
          // TAB BODY
          // ============================================================
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedTab == ItemTab.composition)
                    _buildCompositionSection(itemsState)
                  else if (selectedTab == ItemTab.formulation)
                    _buildFormulationSection(itemsState)
                  else if (selectedTab == ItemTab.sales)
                    _buildSalesSection(itemsState)
                  else if (selectedTab == ItemTab.purchase)
                    _buildPurchaseSection(itemsState)
                  else if (selectedTab == ItemTab.moreInfo)
                    _buildMoreInfoSection(itemsState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabHeader({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
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

  // ============================================================================
  // COMPOSITION SECTION
  // ============================================================================
  Widget _buildCompositionSection(ItemsState itemsState) {
    final controller = ref.read(itemsControllerProvider.notifier);

    return CompositionSection(
      initialRows: compositions,
      onChanged: (v) => updateState(() => compositions = v),
      initialBuyingRule: buyingRuleId,
      onBuyingRuleChanged: (v) => updateState(() => buyingRuleId = v),
      buyingRuleOptions: itemsState.buyingRules,
      onSyncBuyingRules: controller.syncBuyingRules,
      onCreateBuyingRule: controller.createBuyingRule,
      initialDrugSchedule: scheduleOfDrugId,
      onDrugScheduleChanged: (v) => updateState(() => scheduleOfDrugId = v),
      initialProductType: productTypeId,
      onProductTypeChanged: (v) => updateState(() => productTypeId = v),
      drugScheduleOptions: itemsState.drugSchedules,
      productTypeOptions: itemsState.productTypes,
      onSyncDrugSchedules: controller.syncDrugSchedules,
      onSyncProductTypes: controller.syncProductTypes,
      onCreateDrugSchedule: controller.createDrugSchedule,
      onCreateProductType: controller.createProductType,
      contentOptions: itemsState.contents,
      onSyncContents: controller.syncContents,
      onCreateContent: controller.createContent,
      strengthOptions: itemsState.strengths,
      onSyncStrengths: controller.syncStrengths,
      onCreateStrength: controller.createStrength,
      lookupCache: itemsState.lookupCache,
      initialTrackActiveIngredients: trackAssocIngredients,
      onTrackActiveIngredientsChanged: (v) =>
          updateState(() => trackAssocIngredients = v),
      onDeleteCheck: (key, item) => controller.checkLookupUsage(key, item),
      onContentSearch: (q) async {
        return await controller.searchContents(q);
      },
      onStrengthSearch: (q) async {
        return await controller.searchStrengths(q);
      },
      onBuyingRuleSearch: (q) async {
        return await controller.searchBuyingRules(q);
      },
      onDrugScheduleSearch: (q) async {
        return await controller.searchDrugSchedules(q);
      },
      onProductTypeSearch: (q) async {
        return await controller.searchProductTypes(q);
      },
    );
  }

  void _openSyncManageDialog({
    required String title,
    required String singularLabel,
    required String headerLabel,
    required String lookupKey,
    required List<Map<String, dynamic>> items,
    required Future<List<Map<String, dynamic>>> Function(
      List<Map<String, dynamic>>,
    )
    onSave,
    Future<Map<String, dynamic>> Function(String name)? onCreateOne,
    ValueChanged<dynamic>? onSelect,
  }) {
    showDialog(
      context: context,
      builder: (context) => ManageListDialog(
        title: title,
        singularLabel: singularLabel,
        headerLabel: headerLabel,
        items: items,
        onSave: onSave,
        onCreateOne: onCreateOne,
        onSelect: (value) {
          if (onSelect == null) return;
          if (value is Map<String, dynamic>) {
            onSelect(value['id'] ?? value);
            return;
          }
          onSelect(value);
        },
        onDeleteCheck: (item) => _checkLookupUsage(lookupKey, item),
      ),
    );
  }

  // ============================================================================
  // FORMULATION SECTION
  // ============================================================================
  Widget _buildFormulationSection(ItemsState itemsState) {
    final controller = ref.read(itemsControllerProvider.notifier);
    return FormulationSection(
      dimXCtrl: dimXCtrl,
      dimYCtrl: dimYCtrl,
      dimZCtrl: dimZCtrl,
      dimUnit: dimUnit,
      onDimUnitChange: (v) => updateState(() => dimUnit = v ?? 'cm'),
      weightCtrl: weightCtrl,
      weightUnit: weightUnit,
      onWeightUnitChange: (v) => updateState(() => weightUnit = v ?? 'kg'),
      manufacturer: manufacturerId,
      onManufacturerChange: (v) => updateState(() => manufacturerId = v),
      manufacturerOptions: itemsState.manufacturers,
      onManageManufacturersTap: () => _openSyncManageDialog(
        title: 'Manufacturer/Patents',
        singularLabel: 'Manufacturer/Patent',
        headerLabel: 'Manufacturer/Patent Name',
        lookupKey: 'manufacturers',
        items: itemsState.manufacturers,
        onSave: controller.syncManufacturers,
        onCreateOne: controller.createManufacturer,
        onSelect: (v) => updateState(() => manufacturerId = v),
      ),
      brand: brandId,
      onBrandChange: (v) => updateState(() => brandId = v),
      brandOptions: itemsState.brands,
      onManageBrandsTap: () => _openSyncManageDialog(
        title: 'Brands',
        singularLabel: 'Brand',
        headerLabel: 'Brand Name',
        lookupKey: 'brands',
        items: itemsState.brands,
        onSave: controller.syncBrands,
        onCreateOne: controller.createBrand,
        onSelect: (v) => updateState(() => brandId = v),
      ),
        packSizeValue: selectedPackSize,
        onPackSizeChanged: (v) => updateState(() => selectedPackSize = v),
        packSizeOptions: _packSizeOptions(itemsState),
        onManagePackSizesTap: () => _openPackSizeDialog(itemsState),
        lockUnitPackValue: _lockUnitPackDisplayValue(itemsState),
        onLockUnitPackChanged: (v) => _onLockUnitPackChanged(itemsState, v),
        lockUnitPackCtrl: lockUnitPackCtrl,
        upcCtrl: upcCtrl,
        eanCtrl: eanCtrl,
      mpnCtrl: mpnCtrl,
      isbnCtrl: isbnCtrl,
      zerpaiField: _zerpaiField,
      zerpaiTextField: _zerpaiTextField,
      zerpaiDropdown: _zerpaiDropdown,
      manufacturerError: itemsState.validationErrors['manufacturer'],
      brandError: itemsState.validationErrors['brand'],
      onManufacturerSearch: (query) async {
        final results = await controller.searchManufacturers(query);
        // We return the IDs, but also ensure the options are available for display mapping
        // In a real app, you might want to merge these into itemsState.manufacturers
        // but for now, the dropdown just needs the IDs to show results.
        return results.map((m) => m['id'] as String).toList();
      },
      onBrandSearch: (query) async {
        final results = await controller.searchBrands(query);
        return results.map((b) => b['id'] as String).toList();
      },
      lookupCache: itemsState.lookupCache,
    );
  }

  // ============================================================================
  // SALES SECTION
  // ============================================================================
  Widget _buildSalesSection(ItemsState itemsState) {
    final controller = ref.read(itemsControllerProvider.notifier);
    return SalesSection(
      sellingPriceCtrl: sellingPriceCtrl,
      mrpCtrl: mrpCtrl,
      ptrCtrl: ptrCtrl,
      descriptionCtrl: salesDescriptionCtrl,
      currency: salesCurrency,
      onCurrencyChange: (v) => updateState(() => salesCurrency = v ?? 'INR'),
      accountValue: salesAccountId,
      onAccountChanged: (v) => updateState(() => salesAccountId = v),
      sellable: sellable,
      onSellableChanged: (v) => updateState(() => sellable = v ?? false),
      zerpaiField: _zerpaiField,
      zerpaiTextField: _zerpaiTextField,
      zerpaiDropdown: _zerpaiDropdown,
      accountOptions: itemsState.accounts,
      sellingPriceError: itemsState.validationErrors['sellingPrice'],
      accountError: itemsState.validationErrors['salesAccountId'],
      onAccountSearch: (query) async {
        final results = await controller.searchAccounts(query);
        return results.map((a) => a['id'] as String).toList();
      },
    );
  }

  // ============================================================================
  // PURCHASE SECTION
  // ============================================================================
  Widget _buildPurchaseSection(ItemsState itemsState) {
    final controller = ref.read(itemsControllerProvider.notifier);
    return PurchaseSection(
      costPriceCtrl: costPriceCtrl,
      descriptionCtrl: purchaseDescriptionCtrl,
      currency: purchaseCurrency,
      onCurrencyChange: (v) => updateState(() => purchaseCurrency = v ?? 'INR'),
      accountValue: purchaseAccountId,
      onAccountChanged: (v) => updateState(() => purchaseAccountId = v),
      repValue: repId,
      onRepChanged: (v) => updateState(() => repId = v),
      preferredVendor: preferredVendorId,
      onVendorChanged: (v) => updateState(() => preferredVendorId = v),
      purchasable: purchasable,
      onPurchasableChanged: (v) => updateState(() => purchasable = v ?? false),
      zerpaiField: _zerpaiField,
      zerpaiTextField: _zerpaiTextField,
      zerpaiDropdown: _zerpaiDropdown,
      accountOptions: itemsState.accounts,
      repOptions: itemsState.reps,
      vendorOptions: itemsState.vendors,
      costPriceError: itemsState.validationErrors['costPrice'],
      accountError: itemsState.validationErrors['purchaseAccountId'],
      onAccountSearch: (query) async {
        final results = await controller.searchAccounts(query);
        return results.map((a) => a['id'] as String).toList();
      },
      onVendorSearch: (query) async {
        final results = await controller.searchVendors(query);
        return results.map((v) => v['id'] as String).toList();
      },
      onRepSearch: (query) async {
        final results = await controller.searchReps(query);
        return results
            .map((r) => r['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      },
      onManageRepsTap: () async {
        final selected = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => ManageRepsDialog(
            reps: itemsState.reps,
            brands: itemsState.brands,
            onSearch: controller.searchReps,
            onCreate: ({
              required String name,
              String? number,
              String? brandId,
              String? division,
              String? area,
            }) => controller.createRep(
              name: name,
              number: number,
              brandId: brandId,
              division: division,
              area: area,
            ),
          ),
        );
        if (selected != null) {
          updateState(() => repId = selected['id']?.toString());
        }
      },
    );
  }

  // ============================================================================
  // MORE INFORMATION SECTION
  // ============================================================================
  Widget _buildMoreInfoSection(ItemsState itemsState) {
    return MoreInfoSection(
      storageDescCtrl: storageDescCtrl,
      aboutCtrl: aboutCtrl,
      usesDescCtrl: usesDescCtrl,
      howToUseCtrl: howToUseCtrl,
      dosageDescCtrl: dosageDescCtrl,
      missedDoseDescCtrl: missedDoseDescCtrl,
      safetyAdviceCtrl: safetyAdviceCtrl,
      sideEffectCtrls: sideEffectCtrls,
      faqTextCtrls: faqTextCtrls,
      onAddSideEffect: _addSideEffect,
      onRemoveSideEffect: _removeSideEffect,
      onAddFaq: _addFaq,
      onRemoveFaq: _removeFaq,
    );
  }
}
