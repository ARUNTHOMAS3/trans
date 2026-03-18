part of '../items_item_create.dart';

extension _ItemCreateInventory on _ItemCreateScreenState {
  Widget _buildInventoryFlags(ItemsState itemsState) {
    // controller available via ref if needed
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventory Settings',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),

        // -------- Track Inventory --------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: trackInventory,
              visualDensity: VisualDensity.compact,
              onChanged: (v) => updateState(() {
                trackInventory = v ?? false;
                if (!trackInventory && valuationMethod == 'FEFO') {
                  valuationMethod = 'FIFO';
                }
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Track Inventory for this item',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "You cannot enable/disable inventory tracking once you've created transactions.",
                    softWrap: true,
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // -------- Track Bin Location --------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: trackBinLocation,
              visualDensity: VisualDensity.compact,
              onChanged: (v) =>
                  updateState(() => trackBinLocation = v ?? false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Track Bin Location for this item',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Enable this option to record the exact bin, rack, or shelf where the item is stored.',
                    softWrap: true,
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (trackInventory) _buildAdvancedInventory(itemsState),
      ],
    );
  }

  Widget _buildAdvancedInventory(ItemsState itemsState) {
    final controller = ref.read(itemsControllerProvider.notifier);
    final seenStorageLabels = <String>{};
    final uniqueStorageLocations = itemsState.storageLocations.where((storage) {
      final label =
          (storage['name'] ??
                  storage['display_text'] ??
                  storage['location_name'] ??
                  '')
              .toString()
              .trim()
              .toLowerCase();
      if (label.isEmpty) return true;
      if (storage['id']?.toString() == storageId) {
        seenStorageLabels.add(label);
        return true;
      }
      if (seenStorageLabels.contains(label)) {
        return false;
      }
      seenStorageLabels.add(label);
      return true;
    }).toList();
    return Container(
      margin: const EdgeInsets.only(top: 24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Inventory Tracking',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Radio Tracking Modes ----
          RadioGroup<InventoryTrackingMode>(
            groupValue: trackingMode,
            onChanged: (v) => updateState(() {
              trackingMode = v ?? InventoryTrackingMode.none;
              // FEFO requires batches. If user switches away from batches, we must reset FEFO.
              if (trackingMode != InventoryTrackingMode.batches &&
                  valuationMethod == 'FEFO') {
                valuationMethod = 'FIFO';
              }
            }),
            child: Column(
              children: [
                _trackingRadioRow(
                  title: 'None',
                  value: InventoryTrackingMode.none,
                ),
                _trackingRadioRow(
                  title: 'Track Serial Number',
                  value: InventoryTrackingMode.serialNumbers,
                ),
                _trackingRadioRow(
                  title: 'Track Batches',
                  value: InventoryTrackingMode.batches,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ------- 2-Column Grid Layout -------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT COLUMN
              Expanded(
                child: Column(
                  children: [
                    _zerpaiField(
                      label: "Inventory Account",
                      required: true,
                      labelWidth: 160,
                      tooltip:
                          "The account which tracks the inventory of this item",
                      child: FormDropdown<String>(
                        value: inventoryAccountId,
                        items: itemsState.accounts
                            .map((a) => a['id'] as String)
                            .toList(),
                        hint: 'Select account',
                        onChanged: (v) =>
                            updateState(() => inventoryAccountId = v),
                        onSearch: (q) async {
                          final results = await ref
                              .read(itemsControllerProvider.notifier)
                              .searchAccounts(q);
                          return results.map((a) => a['id'] as String).toList();
                        },
                        displayStringForValue: (id) {
                          final acc = itemsState.accounts
                              .where((a) => a['id'] == id)
                              .firstOrNull;
                          if (acc != null)
                            return acc['system_account_name'] ?? id;
                          return itemsState.lookupCache[id] ?? id;
                        },
                        itemBuilder: (id, isSelected, isHovered) {
                          final acc = itemsState.accounts
                              .where((a) => a['id'] == id)
                              .firstOrNull;
                          final label =
                              acc?['system_account_name'] ??
                              itemsState.lookupCache[id] ??
                              id;

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
                        errorText:
                            itemsState.validationErrors['inventoryAccountId'],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _zerpaiField(
                      label: "Storage",
                      tooltip:
                          _selectedStorageTooltip(itemsState) ??
                          "Optimal storage conditions or temperature requirements for the item.",
                      child: _zerpaiDropdown<String>(
                        value: storageId,
                        items: uniqueStorageLocations
                            .map((s) => s['id'] as String)
                            .toList(),
                        hint: 'Select storage temperature',
                        onChanged: (v) => updateState(() => storageId = v),
                        onSearch: (q) async {
                          final results = await ref
                              .read(itemsControllerProvider.notifier)
                              .searchStorageLocations(q);
                          return results.map((s) => s['id'] as String).toList();
                        },
                        displayStringForValue: (id) {
                          final s = itemsState.storageLocations
                              .where((s) => s['id'] == id)
                              .firstOrNull;
                          if (s != null) return s['name'] ?? id;
                          return itemsState.lookupCache[id] ?? id;
                        },
                        itemBuilder: (id, isSelected, isHovered) {
                          final s = itemsState.storageLocations
                              .where((s) => s['id'] == id)
                              .firstOrNull;
                          final label =
                              s?['name'] ?? itemsState.lookupCache[id] ?? id;

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
                        onSettingsTap: () => _openSyncManageDialog(
                          title: 'Storage Temperature',
                          singularLabel: 'Temperature',
                          headerLabel: 'Temperature Name',
                          lookupKey: 'storage-locations',
                          items: itemsState.storageLocations,
                          onSave: controller.syncStorageLocations,
                          onSelect: (v) => updateState(() => storageId = v),
                        ),
                        showSettings: true,
                        settingsLabel: 'Manage Storage',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _zerpaiField(
                      label: "Reorder Point",
                      tooltip:
                          "Minimum stock quantity at which a reorder should be triggered.",
                      child: _zerpaiTextField(
                        controller: reorderPointCtrl,
                        keyboardType: TextInputType.number,
                        hint: 'Enter reorder point',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 48),

              // RIGHT COLUMN
              Expanded(
                child: Column(
                  children: [
                    _zerpaiField(
                      label: "Inventory Valuation Method",
                      required: true,
                      labelWidth: 160,
                      tooltip:
                          "The method you select here will be used for inventory valuation",
                      child: FormDropdown<String>(
                        value: valuationMethod,
                        items: const [
                          'FIFO',
                          'LIFO',
                          'FEFO',
                          'Weighted Average',
                        ],
                        hint: 'Select method',
                        onChanged: (v) => updateState(() {
                          valuationMethod = v;
                          if (v == 'FEFO') {
                            trackInventory = true;
                            trackingMode = InventoryTrackingMode.batches;
                          }
                        }),
                        itemBuilder: (id, isSelected, isHovered) {
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        id,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isHovered
                                              ? Colors.white
                                              : isSelected
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF111827),
                                        ),
                                      ),
                                      if (id == 'FEFO')
                                        Text(
                                          'Requires Batch Tracking',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isHovered
                                                ? Colors.white70
                                                : Colors.grey[600],
                                          ),
                                        ),
                                    ],
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
                        errorText:
                            itemsState.validationErrors['valuationMethod'],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _zerpaiField(
                      label: "Lock Unit Pack",
                      tooltip:
                          "Sets a fixed unit pack for purchase and opening stock, making those fields read-only in transactions. Example: If set to 10, purchases will be fixed at 10 units per pack and cannot be edited.",
                      child: _zerpaiTextField(
                        controller: lockUnitPackCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hint: 'Enter lock unit pack',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _zerpaiField(
                      label: "Reorder Terms",
                      tooltip:
                          "Defines the rule for calculating suggested reorder quantities. Example: 'Standard' (Reorder Point + 50) suggests ordering 50 units extra with reorder point needed quantity.",
                      child: _zerpaiDropdown<String>(
                        value: reorderTermsId,
                        items: itemsState.reorderTerms
                            .map((rt) => rt['id'] as String)
                            .toList(),
                        hint: 'Select term',
                        onChanged: (v) => updateState(() => reorderTermsId = v),
                        onSearch: (q) async {
                          final results = await ref
                              .read(itemsControllerProvider.notifier)
                              .searchReorderTerms(q);
                          return results
                              .map((rt) => rt['id'] as String)
                              .toList();
                        },
                        displayStringForValue: (id) {
                          final rt = itemsState.reorderTerms
                              .where((rt) => rt['id'] == id)
                              .firstOrNull;
                          final name =
                              rt?['term_name'] ??
                              rt?['name'] ??
                              itemsState.lookupCache[id] ??
                              'Unknown';
                          final qty = rt?['quantity'] ?? '0';
                          return '$name (Reorder Point + $qty)';
                        },
                        itemBuilder: (id, isSelected, isHovered) {
                          final rt = itemsState.reorderTerms
                              .where((rt) => rt['id'] == id)
                              .firstOrNull;
                          final name =
                              rt?['term_name'] ??
                              rt?['name'] ??
                              itemsState.lookupCache[id] ??
                              '';
                          final qty = rt?['quantity'] ?? '0';
                          final label = '$name (Reorder Point + $qty)';

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
                        showSettings: true,
                        settingsLabel: 'Manage Reorder Terms',
                        onSettingsTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => ManageReorderTermsDialog(
                              items: itemsState.reorderTerms,
                              onSave: controller.syncReorderTerms,
                              selectedId: reorderTermsId,
                              onSelect: (id) =>
                                  updateState(() => reorderTermsId = id),
                              onDeleteCheck: (item) => controller
                                  .checkLookupUsage('reorder-terms', item),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // NOTE Banner
          _buildInventoryNote(),
        ],
      ),
    );
  }

  Widget _trackingRadioRow({
    required String title,
    required InventoryTrackingMode value,
  }) {
    final bool isSelected = value == trackingMode;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF3F4F6) : Colors.transparent,
      ),
      child: RadioListTile<InventoryTrackingMode>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: const Color(0xFF111827),
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        value: value,
        activeColor: const Color(0xFF2563EB),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildInventoryNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "NOTE: You can add opening stock on the Item Details page by clicking the gear icon under the Warehouses.",
              style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }
}
