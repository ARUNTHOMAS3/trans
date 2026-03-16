part of '../items_item_create.dart';

extension _ItemCreatePrimaryInfo on _ItemCreateScreenState {
  Widget _buildTopPanel(ItemsState itemsState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 900;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactLeftFields(itemsState),
                    const SizedBox(height: 20),
                    _buildImageUploadBox(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: _buildCompactLeftFields(itemsState),
                    ),
                    const SizedBox(width: 48),
                    _buildImageUploadBox(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCompactLeftFields(ItemsState itemsState) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- TYPE SWITCH ----------------
          SharedFieldLayout(
            label: "Type",
            required: true,
            compact: true,
            tooltip:
                "Select if this item is a physical good or a service. Cannot change after transactions.",
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                // 🔑 EXACT SAME WIDTH AS TEXT FIELDS
                constraints: const BoxConstraints(maxWidth: 360),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isSmall = constraints.maxWidth < 300;

                    return isSmall
                        // ---------- SMALL SCREEN: STACK ----------
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TypeRadio(
                                label: "Goods",
                                value: true,
                                selected: isGoods == true,
                                onChanged: (v) {
                                  updateState(() {
                                    isGoods = true;
                                    selectedTab = ItemTab.composition;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              _TypeRadio(
                                label: "Service",
                                value: false,
                                selected: isGoods == false,
                                onChanged: (v) {
                                  updateState(() {
                                    isGoods = false;
                                    selectedTab = ItemTab.sales;
                                    if (selectedUnitId == null &&
                                        itemsState.units.isNotEmpty) {
                                      selectedUnitId =
                                          itemsState.units.first.id;
                                    }
                                  });
                                },
                              ),
                            ],
                          )
                        // ---------- LARGE SCREEN: INLINE ----------
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _TypeRadio(
                                label: "Goods",
                                value: true,
                                selected: isGoods == true,
                                onChanged: (v) {
                                  updateState(() {
                                    isGoods = true;
                                    selectedTab = ItemTab.composition;
                                  });
                                },
                              ),
                              const SizedBox(width: 24),
                              _TypeRadio(
                                label: "Service",
                                value: false,
                                selected: isGoods == false,
                                onChanged: (v) {
                                  updateState(() {
                                    isGoods = false;
                                    selectedTab = ItemTab.sales;
                                    if (selectedUnitId == null &&
                                        itemsState.units.isNotEmpty) {
                                      selectedUnitId =
                                          itemsState.units.first.id;
                                    }
                                  });
                                },
                              ),
                            ],
                          );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ============================================================
          // GOODS MODE FIELDS
          // ============================================================
          if (isGoods) ...[
            SharedFieldLayout(
              label: "Name",
              required: true,
              compact: true,
              tooltip:
                  "The primary name of your product as it appears in the system.",
              child: CustomTextField(
                controller: nameCtrl,
                hintText: "Enter item name",
                errorText: itemsState.validationErrors['productName'],
              ),
            ),

            SharedFieldLayout(
              label: "Billing Name",
              compact: true,
              tooltip:
                  "The name that will be printed on invoices and billing documents.",
              child: CustomTextField(
                controller: billingNameCtrl,
                hintText: "Enter billing name",
              ),
            ),

            SharedFieldLayout(
              label: "Item Code",
              compact: true,
              tooltip:
                  "A unique identifier or internal reference code for this item.",
              child: CustomTextField(
                controller: itemCodeCtrl,
                hintText: "Enter item code",
                errorText: itemsState.validationErrors['itemCode'],
                enabled: !isEditMode, // Read-only when editing
              ),
            ),

            SharedFieldLayout(
              label: "SKU",
              required: true,
              compact: true,
              tooltip: "Stock Keeping Unit",
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
              tooltip: "UQC-based unit (kg, box, etc.)",
              child: Builder(
                builder: (context) {
                  final activeUnits = itemsState.units
                      .where((u) => u.isActive)
                      .toList();
                  return FormDropdown<String>(
                    value: selectedUnitId,
                    items: activeUnits.map((unit) => unit.id).toList(),
                    hint: "Select Unit",
                    onChanged: (v) => updateState(() => selectedUnitId = v),
                    onSearch: (q) async {
                      final results = await ref
                          .read(itemsControllerProvider.notifier)
                          .searchUnits(q);
                      return results.map((u) => u.id).toList();
                    },
                    showSettings: true,
                    settingsLabel: "Manage Units...",
                    onSettingsTap: _openUnitConfigDialog,
                    errorText: itemsState.validationErrors['unitId'],
                    displayStringForValue: (id) {
                      final match = itemsState.units
                          .where((e) => e.id == id)
                          .firstOrNull;
                      if (match != null) return match.unitName;
                      return itemsState.lookupCache[id] ?? id;
                    },
                    // Display unit name but value is ID
                    itemBuilder: (id, isSelected, isHovered) {
                      final unit = itemsState.units
                          .where((u) => u.id == id)
                          .firstOrNull;
                      final label =
                          unit?.unitName ?? itemsState.lookupCache[id] ?? id;

                      return Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: isHovered
                              ? const Color(0xFF2563EB)
                              : isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isHovered
                                      ? Colors.white
                                      : isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF111827),
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: isHovered
                                    ? Colors.white
                                    : const Color(0xFF2563EB),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            SharedFieldLayout(
              label: "Category",
              required: true,
              compact: true,
              child: CategoryDropdown(
                nodes: CategoryNode.fromFlatList(itemsState.categories),
                value: selectedCategoryId,
                displayString: itemsState.lookupCache[selectedCategoryId],
                onChanged: (v) => updateState(() => selectedCategoryId = v),
                onSearch: (q) async {
                  final results = await ref
                      .read(itemsControllerProvider.notifier)
                      .searchCategories(q);
                  return CategoryNode.fromFlatList(results);
                },
                onManageCategoriesTap: _openCategoryConfigDialog,
              ),
            ),

            SharedFieldLayout(
              label: "HSN Code",
              compact: true,
              tooltip:
                  "Harmonized System of Nomenclature code used for tax classification.",
              child: CustomTextField(
                controller: hsnCtrl,
                hintText: "Enter HSN code",
                suffixWidget: IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  onPressed: _openHsnSacSearch,
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
              tooltip:
                  "Specify if the item is taxable, exempt, or non-taxable.",
              child: FormDropdown<String>(
                value: taxPreference,
                items: _taxPreferenceOptions,
                hint: "Select Tax Preference",
                onChanged: (v) => updateState(() => taxPreference = v),
              ),
            ),

            if (taxPreference == 'Tax Exempt')
              SharedFieldLayout(
                label: "Exemption Reason",
                required: true,
                compact: true,
                child: FormDropdown<String>(
                  value: exemptionReason,
                  items: exemptionReasonOptions,
                  hint: "Select Reason",
                  onChanged: (v) => updateState(() => exemptionReason = v),
                ),
              ),

            // ---------------- CHECKBOX GROUP ----------------
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
                    onChanged: (v) =>
                        updateState(() => isReturnable = v ?? false),
                  ),
                  _InlineCheckbox(
                    label: "Push To Ecommerce",
                    value: pushToEcommerce,
                    onChanged: (v) => updateState(() {
                      pushToEcommerce = v ?? false;
                      if (!pushToEcommerce && selectedTab == ItemTab.moreInfo) {
                        selectedTab = ItemTab.composition;
                      }
                    }),
                  ),
                ],
              ),
            ),
          ],

          // ============================================================
          // SERVICE MODE FIELDS
          // ============================================================
          if (!isGoods) ...[
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
                enabled: !isEditMode,
              ),
            ),

            SharedFieldLayout(
              label: "Unit",
              required: true,
              compact: true,
              tooltip: "Service unit (e.g., Hour, Day, Session)",
              child: Builder(
                builder: (context) {
                  final activeUnits = itemsState.units
                      .where((u) => u.isActive)
                      .toList();
                  return FormDropdown<String>(
                    value: selectedUnitId,
                    items: activeUnits.map((unit) => unit.id).toList(),
                    hint: "Select Unit",
                    onChanged: (v) => updateState(() => selectedUnitId = v),
                    onSearch: (q) async {
                      final results = await ref
                          .read(itemsControllerProvider.notifier)
                          .searchUnits(q);
                      return results.map((u) => u.id).toList();
                    },
                    showSettings: true,
                    settingsLabel: "Manage Units...",
                    onSettingsTap: _openUnitConfigDialog,
                    errorText: itemsState.validationErrors['unitId'],
                    displayStringForValue: (id) {
                      final match = itemsState.units
                          .where((e) => e.id == id)
                          .firstOrNull;
                      if (match != null) return match.unitName;
                      return itemsState.lookupCache[id] ?? id;
                    },
                    itemBuilder: (id, isSelected, isHovered) {
                      final unit = itemsState.units
                          .where((u) => u.id == id)
                          .firstOrNull;
                      final label =
                          unit?.unitName ?? itemsState.lookupCache[id] ?? id;

                      return Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: isHovered
                              ? const Color(0xFF2563EB)
                              : isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isHovered
                                      ? Colors.white
                                      : isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF111827),
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 16,
                                color: isHovered
                                    ? Colors.white
                                    : const Color(0xFF2563EB),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
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
                  onPressed: _openHsnSacSearch,
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
                onChanged: (v) => updateState(() => taxPreference = v),
              ),
            ),

            if (taxPreference == 'Tax Exempt')
              SharedFieldLayout(
                label: "Exemption Reason",
                required: true,
                compact: true,
                child: FormDropdown<String>(
                  value: exemptionReason,
                  items: exemptionReasonOptions,
                  hint: "Select Reason",
                  onChanged: (v) => updateState(() => exemptionReason = v),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // Type Radio Button Widget
  // ============================================================================
  Widget _TypeRadio({
    required String label,
    required bool value,
    required bool selected,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF9CA3AF),
                  width: 2,
                ),
                color: Colors.white,
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
