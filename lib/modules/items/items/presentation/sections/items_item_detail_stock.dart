part of '../items_item_detail.dart';

extension _ItemDetailStock on _ItemDetailScreenState {
  Widget _buildWarehousesTab(ItemsState state, Item item) {
    if (!item.isTrackInventory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Inventory tracking is turned off for this item.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Enable tracking to view stock by warehouse.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    final String stockLabel = _stockView == _StockView.accounting
        ? 'Accounting Stock'
        : 'Physical Stock';
    final warehouseStocksAsync = ref.watch(
      itemWarehouseStocksProvider(item.id!),
    );

    return warehouseStocksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Unable to load warehouse stock.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Refresh the item and try again.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      data: (warehouses) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Stock Locations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                _buildWarehouseActions(item, warehouses),
                const Spacer(),
                _buildStockToggle(item),
              ],
            ),
            const SizedBox(height: 12),
            _buildWarehouseStockSummary(warehouses),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: _buildWarehouseTable(stockLabel, warehouses),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSerialNumbersTab(Item item) {
    if (item.id == null) {
      return _buildUnavailableStockState(
        'Serial numbers are unavailable for this item.',
      );
    }

    final serialsAsync = ref.watch(itemSerialsProvider(item.id!));
    return serialsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildUnavailableStockState(
        'Unable to load serial numbers from the database.',
      ),
      data: (serials) {
        final filteredSerials = serials.where((serial) {
          final matchesWarehouse =
              _serialWarehouseFilter == 'all' ||
              serial.warehouseName == _serialWarehouseFilter;
          final matchesAvailability =
              _showAllSerialNumbers || serial.isAvailable;
          return matchesWarehouse && matchesAvailability;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Available Serial Numbers',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  _buildSerialFindLink(serials),
                  const Spacer(),
                  _buildSerialExportButton(),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSerialWarehouseDropdown(serials),
                  const SizedBox(width: 16),
                  _buildShowAllSerialNumbersCheckbox(),
                ],
              ),
              const SizedBox(height: 12),
              _buildSerialNumbersGrid(filteredSerials),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSerialFindLink(List<SerialData> serials) {
    return InkWell(
      onTap: () => _showSerialFindPanel(serials),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.search, size: 16, color: AppTheme.primaryBlueDark),
          SizedBox(width: 6),
          Text(
            'Find Serial Number',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primaryBlueDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialExportButton() {
    return PopupMenuButton<String>(
      onSelected: (value) {},
      itemBuilder: (context) => [
        _buildHoverMenuItem(value: 'csv', label: 'CSV'),
        _buildHoverMenuItem(value: 'xlsx', label: 'XLSX'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.file_upload_outlined,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              'Export As',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSerialWarehouseDropdown(List<SerialData> serials) {
    final warehouseLabels = <String, String>{'all': 'All'};
    for (final serial in serials) {
      if (serial.warehouseName.trim().isNotEmpty) {
        warehouseLabels[serial.warehouseName] = serial.warehouseName;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Warehouse',
          style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        _buildTransactionMenuButton(
          label: warehouseLabels[_serialWarehouseFilter] ?? 'All',
          currentValue: _serialWarehouseFilter,
          items: warehouseLabels,
          onSelected: (value) =>
              updateState(() => _serialWarehouseFilter = value),
        ),
      ],
    );
  }

  Widget _buildShowAllSerialNumbersCheckbox() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _showAllSerialNumbers,
          onChanged: (value) {
            updateState(() => _showAllSerialNumbers = value ?? false);
          },
          activeColor: AppTheme.primaryBlueDark,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Tooltip(
          message:
              'Enable this option to view both available and unavailable serial numbers. If disabled, only available serial numbers will be displayed.',
          decoration: BoxDecoration(
            color: AppTheme.textPrimary,
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          preferBelow: true,
          child: Row(
            children: const [
              Text(
                'Show All Serial Numbers',
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
              SizedBox(width: 4),
              Icon(Icons.help_outline, size: 14, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSerialNumbersGrid(List<SerialData> serials) {
    const borderColor = AppTheme.borderColor;
    const columns = 4;
    final rows = <TableRow>[];

    for (var i = 0; i < serials.length; i += columns) {
      final cells = <Widget>[];
      for (var j = 0; j < columns; j++) {
        final index = i + j;
        final serial = index < serials.length ? serials[index] : null;
        cells.add(_buildSerialCell(serial));
      }
      rows.add(TableRow(children: cells));
    }

    if (rows.isEmpty) {
      rows.add(
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No serial numbers found.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
            SizedBox(),
            SizedBox(),
            SizedBox(),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: borderColor),
          verticalInside: BorderSide(color: borderColor),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: rows,
      ),
    );
  }

  Widget _buildSerialCell(SerialData? serial) {
    if (serial == null) {
      return const SizedBox();
    }
    final color = serial.isAvailable
        ? AppTheme.textPrimary
        : AppTheme.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        serial.serialNumber,
        style: TextStyle(fontSize: 13, color: color),
      ),
    );
  }

  Future<void> _showSerialFindPanel(List<SerialData> serials) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Find serial number',
      barrierColor: const Color(0x33000000),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SerialFindPanel(serials: serials),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetTween = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        );
        return SlideTransition(
          position: animation.drive(offsetTween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  Widget _buildBatchNumbersTab(Item item) {
    if (item.id == null) {
      return _buildUnavailableStockState(
        'Batch details are unavailable for this item.',
      );
    }

    final batchesAsync = ref.watch(itemBatchesProvider(item.id!));
    return batchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildUnavailableStockState(
        'Unable to load batch details from the database.',
      ),
      data: (batches) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBatchFiltersRow(item, batches),
            const SizedBox(height: 16),
            if (_selectedBatchRefs.isNotEmpty) ...[
              _buildBatchBulkActionsBar(),
              const SizedBox(height: 12),
            ],
            _buildBatchTable(batches),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(Item item) {
    if (item.id == null) {
      return _buildUnavailableStockState(
        'History is unavailable for this item.',
      );
    }

    final historyAsync = ref.watch(itemHistoryProvider(item.id!));
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildUnavailableStockState(
        'Unable to load item history from the audit logs.',
      ),
      data: (entries) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _buildHistoryHeaderText('DATE')),
                    Expanded(flex: 1, child: _buildHistoryHeaderText('ACTION')),
                    Expanded(
                      flex: 1,
                      child: _buildHistoryHeaderText('SECTION'),
                    ),
                    Expanded(
                      flex: 4,
                      child: _buildHistoryHeaderText('DETAILS'),
                    ),
                  ],
                ),
              ),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No audit history found for this item.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              else
                ...entries.map((entry) => _buildHistoryEntryRow(entry, item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryEntryRow(ItemHistoryEntry entry, Item item) {
    final changes = _describeHistoryChanges(entry, item);
    final summary = _sanitizeHistorySummary(entry.summary, entry.section);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  _formatHistoryDate(entry.createdAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(flex: 1, child: _buildHistoryActionBadge(entry.action)),
              Expanded(
                flex: 1,
                child: Text(
                  entry.section,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (changes.isEmpty)
                    const Text(
                      'No readable field changes available.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  else
                    ...changes.map(
                      (change) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(
                                Icons.circle,
                                size: 6,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                change,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  List<String> _describeHistoryChanges(ItemHistoryEntry entry, Item item) {
    final itemsState = ref.read(itemsControllerProvider);
    final oldValues = entry.oldValues ?? const <String, dynamic>{};
    final newValues = entry.newValues ?? const <String, dynamic>{};
    final fields = entry.changedColumns.isNotEmpty
        ? entry.changedColumns
        : newValues.keys.where((key) => !_isHiddenHistoryField(key)).toList();

    final changes = <String>[];
    for (final field in fields) {
      final change = _describeHistoryFieldChange(
        field,
        oldValues[field],
        newValues[field],
        item,
        itemsState,
        entry.action,
      );
      if (change != null && change.trim().isNotEmpty) {
        changes.add(change);
      }
    }

    if (changes.isEmpty && entry.summary.isNotEmpty) {
      changes.add(
        _sanitizeHistorySummary(entry.summary, entry.section),
      );
    }

    return changes;
  }

  String? _describeHistoryFieldChange(
    String field,
    dynamic oldValue,
    dynamic newValue,
    Item item,
    ItemsState itemsState,
    String action,
  ) {
    final label = _historyFieldLabel(field);
    final previous = _historyDisplayValue(
      field,
      oldValue,
      item,
      itemsState: itemsState,
    );
    final next = _historyDisplayValue(
      field,
      newValue,
      item,
      itemsState: itemsState,
    );

    if (_usesGenericHistoryMessage(field)) {
      if (next == null && previous == null) {
        return '$label updated';
      }
      if (next == null) {
        return '$label cleared';
      }
      if (previous == null) {
        return action == 'INSERT' ? '$label set to $next' : '$label set';
      }
      return '$label updated';
    }

    if (previous == next) {
      return next == null ? null : '$label updated';
    }
    if (previous == null && next != null) {
      return '$label set to $next';
    }
    if (previous != null && next == null) {
      return '$label cleared';
    }
    if (previous != null && next != null) {
      return '$label changed from $previous to $next';
    }
    return null;
  }

  String _historyFieldLabel(String field) {
    const labels = <String, String>{
      'buying_rule_id': 'Buying Rule',
      'schedule_of_drug_id': 'Schedule of Drug',
      'storage_id': 'Storage',
      'rack_id': 'Rack',
      'manufacturer_id': 'Manufacturer / Patent',
      'brand_id': 'Brand',
      'category_id': 'Category',
      'unit_id': 'Unit',
      'track_assoc_ingredients': 'Track Active Ingredients',
      'track_bin_location': 'Track Bin Location',
      'track_serial_number': 'Track Serial Number',
      'track_batches': 'Track Batches',
      'inventory_valuation_method': 'Inventory Valuation Method',
      'reorder_point': 'Reorder Point',
      'image_urls': 'Images',
      'faq_text': 'FAQ',
      'side_effects': 'Side Effects',
      'dimension_unit': 'Dimension Unit',
      'weight_unit': 'Weight Unit',
      'lock_unit_pack': 'Locked Unit Pack',
      'is_lock': 'Item Lock',
      'is_active': 'Status',
      'display_order': 'Display Order',
      'batch': 'Batch Reference',
      'manufacture_batch_number': 'Manufacturer Batch',
      'exp': 'Expiry Date',
      'manufacture_exp': 'Manufactured Date',
      'shedule_id': 'Schedule of Drug',
      'opening_stock': 'Opening Stock',
      'opening_stock_value': 'Opening Stock Value',
      'accounting_stock': 'Accounting Stock',
      'physical_stock': 'Physical Stock',
      'committed_stock': 'Committed Stock',
      'variance_qty': 'Variance Quantity',
      'reason': 'Reason',
      'notes': 'Notes',
      'product_name': 'Item Name',
      'billing_name': 'Billing Name',
      'item_code': 'Item Code',
      'sku': 'SKU',
      'hsn_code': 'HSN Code',
      'tax_preference': 'Tax Preference',
      'mrp': 'MRP',
      'ptr': 'PTR',
      'cost_price': 'Cost Price',
      'selling_price': 'Selling Price',
      'width': 'Width',
      'height': 'Height',
      'length': 'Length',
      'weight': 'Weight',
      'about': 'About',
      'uses_description': 'Uses',
      'how_to_use': 'How To Use',
      'dosage_description': 'Dosage',
      'missed_dose_description': 'Missed Dose',
      'safety_advice': 'Safety Advice',
    };
    final mapped = labels[field];
    if (mapped != null) {
      return mapped;
    }
    return field
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  bool _usesGenericHistoryMessage(String field) {
    const genericFields = <String>{
      'buying_rule_id',
      'schedule_of_drug_id',
      'storage_id',
      'rack_id',
      'manufacturer_id',
      'brand_id',
      'category_id',
      'unit_id',
      'content_id',
      'strength_id',
      'shedule_id',
      'warehouse_id',
      'preferred_vendor_id',
      'sales_account_id',
      'purchase_account_id',
      'inventory_account_id',
      'intra_state_tax_id',
      'inter_state_tax_id',
      'reorder_term_id',
      'image_urls',
      'faq_text',
      'side_effects',
    };
    return genericFields.contains(field);
  }

  bool _isHiddenHistoryField(String field) {
    const hiddenFields = <String>{
      'id',
      'product_id',
      'item_id',
      'org_id',
      'outlet_id',
      'created_at',
      'updated_at',
      'created_by_id',
      'updated_by_id',
      'record_id',
      'request_id',
    };
    return hiddenFields.contains(field);
  }

  String? _historyDisplayValue(
    String field,
    dynamic value,
    Item item, {
    required ItemsState itemsState,
  }) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      if (field == 'is_active') {
        return value ? 'Active' : 'Inactive';
      }
      return value ? 'Enabled' : 'Disabled';
    }

    if (value is num) {
      return value.toString();
    }

    if (value is List) {
      final nonEmpty = value
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList();
      if (nonEmpty.isEmpty) {
        return 'empty';
      }
      return nonEmpty.join(', ');
    }

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    if (_looksLikeUuid(text)) {
      return _resolveKnownHistoryLookup(
        field,
        text,
        item,
        itemsState: itemsState,
      );
    }

    return text;
  }

  String? _resolveKnownHistoryLookup(
    String field,
    String id,
    Item item, {
    required ItemsState itemsState,
  }) {
    String? fromNamedMap(
      List<Map<String, dynamic>> rows, {
      List<String> preferredKeys = const <String>[
        'display_text',
        'name',
        'label',
        'display_name',
        'account_name',
        'location_name',
        'storage_type',
        'tag_name',
        'group_name',
        'term_name',
        'template_name',
        'company_name',
      ],
    }) {
      for (final row in rows) {
        if (row['id']?.toString() != id) {
          continue;
        }
        for (final key in preferredKeys) {
          final candidate = row[key]?.toString().trim();
          if (candidate != null && candidate.isNotEmpty) {
            return candidate;
          }
        }
      }
      return null;
    }

    final lookupMap = <String, String?>{
      'buying_rule_id': item.buyingRuleId == id ? item.buyingRuleName : null,
      'schedule_of_drug_id': item.scheduleOfDrugId == id
          ? item.drugScheduleName
          : null,
      'shedule_id': item.scheduleOfDrugId == id ? item.drugScheduleName : null,
      'storage_id': item.storageId == id ? item.storageName : null,
      'rack_id': item.rackId == id ? item.rackName : null,
      'manufacturer_id': item.manufacturerId == id
          ? item.manufacturerName
          : null,
      'brand_id': item.brandId == id ? item.brandName : null,
      'preferred_vendor_id': item.preferredVendorId == id
          ? item.preferredVendorName
          : null,
      'sales_account_id': item.salesAccountId == id
          ? item.salesAccountName
          : null,
      'purchase_account_id': item.purchaseAccountId == id
          ? item.purchaseAccountName
          : null,
      'inventory_account_id': item.inventoryAccountId == id
          ? item.inventoryAccountName
          : null,
      'unit_id': item.unitId == id ? item.unitName : null,
      'category_id': item.categoryId == id ? item.categoryName : null,
      'intra_state_tax_id': item.intraStateTaxId == id
          ? item.intraStateTaxName
          : null,
      'inter_state_tax_id': item.interStateTaxId == id
          ? item.interStateTaxName
          : null,
    };

    final currentItemName = lookupMap[field];
    if (currentItemName != null && currentItemName.trim().isNotEmpty) {
      return currentItemName;
    }

    switch (field) {
      case 'storage_id':
        return fromNamedMap(itemsState.storageLocations);
      case 'rack_id':
        return fromNamedMap(itemsState.racks);
      case 'manufacturer_id':
        return fromNamedMap(itemsState.manufacturers);
      case 'brand_id':
        return fromNamedMap(itemsState.brands);
      case 'preferred_vendor_id':
        return fromNamedMap(itemsState.vendors);
      case 'buying_rule_id':
        return fromNamedMap(itemsState.buyingRules);
      case 'schedule_of_drug_id':
      case 'shedule_id':
        return fromNamedMap(itemsState.drugSchedules);
      case 'category_id':
        return fromNamedMap(itemsState.categories);
      case 'reorder_term_id':
        return fromNamedMap(itemsState.reorderTerms);
      case 'content_id':
        return fromNamedMap(itemsState.contents);
      case 'strength_id':
        return fromNamedMap(itemsState.strengths);
      case 'sales_account_id':
      case 'purchase_account_id':
      case 'inventory_account_id':
        return fromNamedMap(itemsState.accounts);
      case 'unit_id':
        for (final unit in itemsState.units) {
          if (unit.id == id && unit.unitName.trim().isNotEmpty) {
            return unit.unitName;
          }
        }
        return null;
      case 'intra_state_tax_id':
      case 'inter_state_tax_id':
        for (final tax in [...itemsState.taxRates, ...itemsState.taxGroups]) {
          if (tax.id == id && tax.taxName.trim().isNotEmpty) {
            return tax.taxName;
          }
        }
        return null;
      default:
        return null;
    }
  }

  bool _looksLikeUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  String _sanitizeHistorySummary(String summary, String section) {
    final trimmed = summary.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    const uuidPattern =
        r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}';
    final uuidRegex = RegExp(uuidPattern);
    if (!uuidRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    String replacementFor(String match) {
      if (section == 'Warehouses') {
        return 'Unknown warehouse';
      }
      return 'Unknown reference';
    }

    final sanitized = trimmed.replaceAllMapped(
      uuidRegex,
      (match) => replacementFor(match.group(0)!),
    );

    return sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _buildTransactionsTab(Item item) {
    if (item.id == null) {
      return _buildUnavailableStockState(
        'Stock transactions are unavailable for this item.',
      );
    }

    final transactionsAsync = ref.watch(stockTransactionsProvider(item.id!));
    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildUnavailableStockState(
        'Unable to load stock transactions from the database.',
      ),
      data: (transactions) {
        final filtered = transactions.where((tx) {
          final matchesType =
              _transactionTypeFilter == 'all' ||
              tx.documentType == _transactionTypeFilter;
          final matchesStatus =
              _transactionStatusFilter == 'all' ||
              tx.status == _transactionStatusFilter;
          return matchesType && matchesStatus;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionFiltersRow(item),
              const SizedBox(height: 12),
              _buildTransactionsTable(filtered),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionFiltersRow(Item item) {
    return Row(
      children: [
        _buildTransactionTypeDropdown(item),
        const SizedBox(width: 12),
        _buildTransactionStatusDropdown(item),
      ],
    );
  }

  Widget _buildTransactionTypeDropdown(Item item) {
    final filterLabels = {
      'all': 'All',
      'salesOrders': 'Sales Orders',
      'invoices': 'Invoices',
      'deliveryChallans': 'Delivery Challans',
      'creditNotes': 'Credit Notes',
      'purchaseOrders': 'Purchase Orders',
      'bills': 'Bills',
      'vendorCredits': 'Vendor Credits',
      'transferOrders': 'Transfer Orders',
      'inventoryAdjustments': 'Inventory Adjustments',
      'assemblies': 'Assemblies',
    };

    return _buildTransactionMenuButton(
      label: 'Filter By: ${filterLabels[_transactionTypeFilter] ?? 'All'}',
      currentValue: _transactionTypeFilter,
      items: filterLabels,
      onSelected: (value) =>
          _setTransactionTypeFilter(value, _tabsForItem(item)),
    );
  }

  Widget _buildTransactionStatusDropdown(Item item) {
    final statusLabels = {
      'all': 'All',
      'draft': 'Draft',
      'partiallyInvoiced': 'Partially Invoiced',
      'invoiced': 'Invoiced',
      'closed': 'Closed',
      'void': 'Void',
      'confirmed': 'Confirmed',
      'partiallyShipped': 'Partially shipped',
      'shipped': 'Shipped',
      'dropshipped': 'Dropshipped',
      'backordered': 'Backordered',
      'onHold': 'On Hold',
    };

    return _buildTransactionMenuButton(
      label: 'Status: ${statusLabels[_transactionStatusFilter] ?? 'All'}',
      currentValue: _transactionStatusFilter,
      items: statusLabels,
      onSelected: (value) =>
          _setTransactionStatusFilter(value, _tabsForItem(item)),
    );
  }

  Widget _buildTransactionsTable(List<TransactionData> transactions) {
    const borderColor = AppTheme.borderColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: _buildTransactionsHeader(),
          ),
          ...transactions.map(_buildTransactionRow),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No transactions found.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionMenuButton({
    required String label,
    required String currentValue,
    required Map<String, String> items,
    required ValueChanged<String> onSelected,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        offset: const Offset(0, 40),
        elevation: 6,
        color: Colors.white,
        constraints: const BoxConstraints(minWidth: 220),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        itemBuilder: (context) {
          return items.entries.map((entry) {
            return _buildHoverMenuItem(
              value: entry.key,
              label: entry.value,
              isSelected: entry.key == currentValue,
            );
          }).toList();
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildHoverMenuItem({
    required String value,
    required String label,
    bool isSelected = false,
  }) {
    bool isHovered = false;

    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: StatefulBuilder(
        builder: (context, setItemState) {
          final showBlue = isHovered;
          final showGray = !isHovered && isSelected;
          final backgroundColor = showBlue
              ? AppTheme.infoBlue
              : (showGray ? AppTheme.borderColor : Colors.transparent);
          final textColor = showBlue ? Colors.white : AppTheme.textPrimary;

          return MouseRegion(
            onEnter: (_) => setItemState(() => isHovered = true),
            onExit: (_) => setItemState(() => isHovered = false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: backgroundColor,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: showBlue ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildTransactionsHeaderText('DATE', sortable: true),
          ),
          Expanded(
            flex: 2,
            child: _buildTransactionsHeaderText('SALES ORDER#'),
          ),
          Expanded(
            flex: 3,
            child: _buildTransactionsHeaderText('CUSTOMER NAME'),
          ),
          Expanded(
            flex: 2,
            child: _buildTransactionsHeaderText(
              'QUANTITY SOLD',
              align: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildTransactionsHeaderText(
              'PRICE',
              align: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildTransactionsHeaderText(
              'TOTAL',
              align: TextAlign.right,
            ),
          ),
          Expanded(flex: 2, child: _buildTransactionsHeaderText('STATUS')),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(TransactionData tx) {
    final statusColor = tx.status == 'confirmed'
        ? AppTheme.primaryBlueDark
        : AppTheme.textSecondary;

    return InkWell(
      onTap: () => updateState(() => _selectedTransaction = tx),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(tx.date, style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  tx.documentNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  tx.customerName,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  tx.quantitySold.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatCurrency(tx.price),
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatCurrency(tx.total),
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _statusLabel(tx.status),
                  style: TextStyle(fontSize: 13, color: statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Moved to _ItemDetailScreenState

  Widget _buildTransactionsHeaderText(
    String text, {
    bool sortable = false,
    TextAlign align = TextAlign.left,
  }) {
    return Row(
      mainAxisAlignment: align == TextAlign.right
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 0.3,
          ),
          textAlign: align,
        ),
        if (sortable) ...[
          const SizedBox(width: 4),
          const Icon(Icons.unfold_more, size: 14, color: AppTheme.textMuted),
        ],
      ],
    );
  }

  Widget _buildHistoryActionBadge(String action) {
    final normalized = action.toUpperCase();
    final (backgroundColor, textColor) = switch (normalized) {
      'INSERT' => (AppTheme.successBg, AppTheme.successTextDark),
      'UPDATE' => (AppTheme.infoBgBorder, AppTheme.primaryBlueDark),
      'DELETE' => (AppTheme.errorBgBorder, AppTheme.errorRedDark),
      _ => (AppTheme.bgDisabled, AppTheme.textBody),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          normalized,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  String _formatHistoryDate(DateTime? date) {
    if (date == null) {
      return '--';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final isAm = hour < 12;
    final amPm = isAm ? 'AM' : 'PM';
    hour = hour % 12;
    if (hour == 0) {
      hour = 12;
    }
    final hourText = hour.toString().padLeft(2, '0');
    return '$day-$month-$year $hourText:$minute $amPm';
  }

  Widget _buildHistoryHeaderText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textMuted,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildBatchFiltersRow(Item item, List<BatchData> batches) {
    return Row(
      children: [
        _buildBatchFilterDropdown(item),
        const SizedBox(width: 12),
        _buildWarehouseFilterDropdown(item),
        const SizedBox(width: 12),
        _buildShowEmptyBatchesCheckbox(item),
        const Spacer(),
        _buildBatchFindLink(batches),
        const SizedBox(width: 12),
        _buildNewBatchButton(),
      ],
    );
  }

  Widget _buildBatchFilterDropdown(Item item) {
    final filterLabels = {
      'all': 'All Batches',
      'active': 'Active Batches',
      'inactive': 'Inactive Batches',
      'expired': 'Expired Batches',
      'empty': 'Empty Batches',
    };

    return _buildTransactionMenuButton(
      label: 'Filter By: ${filterLabels[_batchFilter] ?? 'All Batches'}',
      currentValue: _batchFilter,
      items: filterLabels,
      onSelected: (value) => _setBatchFilter(value, _tabsForItem(item)),
    );
  }

  Widget _buildWarehouseFilterDropdown(Item item) {
    final warehouseLabels = <String, String>{'all': 'All'};
    final storageName = item.storageName?.trim();
    if (storageName != null && storageName.isNotEmpty) {
      warehouseLabels[storageName] = storageName;
    }

    return _buildTransactionMenuButton(
      label: 'Warehouse: ${warehouseLabels[_warehouseFilter] ?? 'All'}',
      currentValue: _warehouseFilter,
      items: warehouseLabels,
      onSelected: (value) => _setWarehouseFilter(value, _tabsForItem(item)),
    );
  }

  Widget _buildShowEmptyBatchesCheckbox(Item item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _showEmptyBatches,
          onChanged: (value) {
            _setShowEmptyBatches(value ?? false, _tabsForItem(item));
          },
          activeColor: AppTheme.primaryBlueDark,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Select this option to display batches with zero quantity',
          decoration: BoxDecoration(
            color: AppTheme.textPrimary,
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          preferBelow: true,
          child: Row(
            children: [
              const Text(
                'Show Empty Batches',
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 4),
              Icon(Icons.help_outline, size: 14, color: Colors.grey[600]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatchFindLink(List<BatchData> batches) {
    return InkWell(
      onTap: () => _showBatchFindPanel(batches),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.search, size: 16, color: AppTheme.primaryBlueDark),
          SizedBox(width: 6),
          Text(
            'Find Batch Number',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primaryBlueDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBatchFindPanel(List<BatchData> batches) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Find batch details',
      barrierColor: const Color(0x33000000),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: BatchFindPanel(batches: batches),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetTween = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        );
        return SlideTransition(
          position: animation.drive(offsetTween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  Widget _buildNewBatchButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _showCreateBatchDialog();
      },
      icon: const Icon(Icons.add, size: 16),
      label: const Text('New'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBatchTable(List<BatchData> batches) {
    const borderColor = AppTheme.borderColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: _buildBatchTableHeader(batches),
          ),
          // Body rows
          ...batches.asMap().entries.map((entry) {
            final index = entry.key;
            final batch = entry.value;
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: index < batches.length - 1
                      ? const BorderSide(color: borderColor)
                      : BorderSide.none,
                ),
              ),
              child: _buildBatchTableRow(batch, index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBatchBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            onSelected: (value) {
              updateState(() {
                if (value == 'active') {
                  _inactiveBatchRefs.removeAll(_selectedBatchRefs);
                } else if (value == 'inactive') {
                  _inactiveBatchRefs.addAll(_selectedBatchRefs);
                }
              });
            },
            itemBuilder: (context) => [
              _buildHoverMenuItem(value: 'active', label: 'Mark as Active'),
              _buildHoverMenuItem(value: 'inactive', label: 'Mark as Inactive'),
              _buildHoverMenuItem(value: 'delete', label: 'Delete'),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Bulk Actions',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 18,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => updateState(() => _selectedBatchRefs.clear()),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateBatchDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CreateBatchDialog(),
    );
  }

  Widget _buildBatchTableHeader(List<BatchData> batches) {
    final selectedCount = batches
        .where((batch) => _selectedBatchRefs.contains(batch.batchReference))
        .length;
    final allSelected = batches.isNotEmpty && selectedCount == batches.length;
    final anySelected = selectedCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Checkbox column
          SizedBox(
            width: 40,
            child: Checkbox(
              tristate: true,
              value: allSelected ? true : (anySelected ? null : false),
              onChanged: (value) {
                updateState(() {
                  if (value == true) {
                    _selectedBatchRefs
                      ..clear()
                      ..addAll(batches.map((b) => b.batchReference));
                  } else {
                    _selectedBatchRefs.clear();
                  }
                });
              },
              activeColor: AppTheme.primaryBlueDark,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          // Batch Reference#
          Expanded(
            flex: 2,
            child: _buildHeaderText('BATCH REFERENCE#', sortable: true),
          ),
          // Manufacturer/Patent Batch#
          Expanded(
            flex: 2,
            child: _buildHeaderText('MANUFACTURER/PATENT BATCH#'),
          ),
          // Unit Pack
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildHeaderText('UNIT PACK', align: TextAlign.right),
            ),
          ),
          // Manufactured Date
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _buildHeaderText('MANUFACTURED DATE', sortable: true),
            ),
          ),
          // Expiry Date
          Expanded(
            flex: 2,
            child: _buildHeaderText('EXPIRY DATE', sortable: true),
          ),
          // Quantity In
          Expanded(
            flex: 1,
            child: _buildHeaderText('QUANTITY IN', align: TextAlign.right),
          ),
          // Quantity Available
          Expanded(
            flex: 2,
            child: _buildHeaderText(
              'QUANTITY AVAILABLE',
              align: TextAlign.right,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildHeaderText(
    String text, {
    bool sortable = false,
    TextAlign align = TextAlign.left,
  }) {
    return Row(
      mainAxisAlignment: align == TextAlign.right
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 0.3,
          ),
          textAlign: align,
        ),
        if (sortable) ...[
          const SizedBox(width: 4),
          const Icon(Icons.unfold_more, size: 14, color: AppTheme.textMuted),
        ],
      ],
    );
  }

  Widget _buildBatchTableRow(BatchData batch, int index) {
    final isExpired = batch.isExpired;
    final isEmpty = batch.quantityAvailable == 0;
    final isSelected = _selectedBatchRefs.contains(batch.batchReference);
    final isInactive = _inactiveBatchRefs.contains(batch.batchReference);
    final baseTextColor = isInactive
        ? AppTheme.textMuted
        : AppTheme.textPrimary;
    final linkColor = isInactive
        ? AppTheme.textMuted
        : AppTheme.primaryBlueDark;

    return MouseRegion(
      onEnter: (_) => updateState(() => _hoveredBatchIndex = index),
      onExit: (_) => updateState(() => _hoveredBatchIndex = null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 40,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) {
                  updateState(() {
                    if (value == true) {
                      _selectedBatchRefs.add(batch.batchReference);
                    } else {
                      _selectedBatchRefs.remove(batch.batchReference);
                    }
                  });
                },
                activeColor: AppTheme.primaryBlueDark,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            // Batch Reference#
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: isInactive
                    ? null
                    : () {
                        // Navigate to batch details
                      },
                child: Text(
                  batch.batchReference,
                  style: TextStyle(
                    fontSize: 13,
                    color: linkColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Manufacturer/Patent Batch#
            Expanded(
              flex: 2,
              child: Text(
                batch.manufacturerBatch,
                style: TextStyle(fontSize: 13, color: baseTextColor),
              ),
            ),
            // Unit Pack
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  batch.unitPack.toString(),
                  style: TextStyle(fontSize: 13, color: baseTextColor),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            // Manufactured Date
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  batch.manufacturedDate,
                  style: TextStyle(fontSize: 13, color: baseTextColor),
                ),
              ),
            ),
            // Expiry Date
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    batch.expiryDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: isInactive
                          ? AppTheme.textMuted
                          : (isExpired
                                ? AppTheme.errorRed
                                : AppTheme.textPrimary),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity In
            Expanded(
              flex: 1,
              child: Text(
                batch.quantityIn.toString(),
                style: TextStyle(fontSize: 13, color: baseTextColor),
                textAlign: TextAlign.right,
              ),
            ),
            // Quantity Available
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    batch.quantityAvailable.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isInactive
                          ? AppTheme.textMuted
                          : (isEmpty
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary),
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 36,
              child: _hoveredBatchIndex == index
                  ? GestureDetector(
                      onTapDown: (details) {
                        _showBatchRowMenu(details.globalPosition, batch);
                      },
                      child: const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppTheme.accentGreen,
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBatchRowMenu(Offset position, BatchData batch) async {
    final isInactive = _inactiveBatchRefs.contains(batch.batchReference);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(
          value: 'toggle',
          child: Text(isInactive ? 'Mark as Active' : 'Mark as Inactive'),
        ),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
    if (action == 'edit') {
      await _showEditBatchDialog(batch);
    }
    if (action == 'toggle') {
      updateState(() {
        if (isInactive) {
          _inactiveBatchRefs.remove(batch.batchReference);
        } else {
          _inactiveBatchRefs.add(batch.batchReference);
        }
      });
    }
  }

  Future<void> _showEditBatchDialog(BatchData batch) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CreateBatchDialog(initialBatch: batch),
    );
  }

  Widget _buildUnavailableStockState(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildWarehouseTable(
    String stockLabel,
    List<WarehouseStockRow> warehouses,
  ) {
    final TextStyle headerStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppTheme.textSecondary,
      letterSpacing: 0.2,
    );

    final TextStyle cellStyle = const TextStyle(
      fontSize: 13,
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w600,
    );

    final borderColor = AppTheme.borderColor;

    List<TableRow> rows = [];

    // Header row 2
    rows.add(
      TableRow(
        children: [
          _headerCell('Warehouse Name', headerStyle),
          _headerCell('Stock on Hand', headerStyle, center: true),
          _headerCell('Committed Stock', headerStyle, center: true),
          _headerCell('Available for Sale', headerStyle, center: true),
        ],
      ),
    );

    if (warehouses.isEmpty) {
      rows.add(
        TableRow(
          children: [
            _emptyCell(),
            _emptyCell(showText: false),
            _emptyCell(showText: false),
            _emptyCell(showText: false),
          ],
        ),
      );
    } else {
      for (final wh in warehouses) {
        final numbers = _stockView == _StockView.accounting
            ? wh.accounting
            : wh.physical;
        rows.add(
          TableRow(
            children: [
              _warehouseNameCell(wh),
              _stockValueCell(
                numbers.onHand,
                cellStyle,
                isWarning: _stockView == _StockView.physical && wh.hasVariance,
              ),
              _stockValueCell(
                numbers.committed,
                cellStyle,
                isWarning: numbers.isOverCommitted,
              ),
              _stockValueCell(
                numbers.available,
                cellStyle,
                isWarning: numbers.isOverCommitted,
              ),
            ],
          ),
        );
      }
    }

    return Column(
      children: [
        // Top merged header row
        SizedBox(
          height: 34,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: borderColor)),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    stockLabel.toUpperCase(),
                    style: headerStyle.copyWith(color: AppTheme.textBody),
                  ),
                ),
              ),
            ],
          ),
        ),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          border: TableBorder(
            verticalInside: BorderSide(color: borderColor),
            horizontalInside: BorderSide(color: borderColor),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ],
    );
  }

  Widget _headerCell(String label, TextStyle style, {bool center = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: center ? Alignment.center : Alignment.center,
      child: Text(
        label,
        style: style,
        textAlign: center ? TextAlign.center : TextAlign.center,
      ),
    );
  }

  Widget _warehouseNameCell(WarehouseStockRow warehouse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warehouse.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (warehouse.hasVariance) ...[
                  const SizedBox(height: 4),
                  Text(
                    warehouse.variance > 0
                        ? 'Variance: +${_formatQty(warehouse.variance)}'
                        : 'Variance: ${_formatQty(warehouse.variance)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: warehouse.variance > 0
                          ? AppTheme.successDark
                          : AppTheme.errorRed,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (warehouse.isPrimary)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.star, size: 16, color: AppTheme.warningOrange),
            ),
        ],
      ),
    );
  }

  Widget _stockValueCell(
    double value,
    TextStyle style, {
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.center,
      child: Text(
        _formatQty(value),
        style: style.copyWith(
          color: isWarning ? AppTheme.errorRed : style.color,
        ),
      ),
    );
  }

  Widget _emptyCell({bool showText = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: showText
          ? const Text(
              'No warehouse stock yet',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            )
          : const SizedBox(),
    );
  }

  Widget _buildStockToggle(Item item) {
    final bool isAccounting = _stockView == _StockView.accounting;

    Widget buildChip(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryBlueDark : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppTheme.primaryBlueDark : AppTheme.borderColor,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1A2563EB),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppTheme.textBody,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bgDisabled,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildChip('Accounting Stock', isAccounting, () {
            if (_stockView != _StockView.accounting) {
              _setStockView(_StockView.accounting, _tabsForItem(item));
            }
          }),
          const SizedBox(width: 6),
          buildChip('Physical Stock', !isAccounting, () {
            if (_stockView != _StockView.physical) {
              _setStockView(_StockView.physical, _tabsForItem(item));
            }
          }),
        ],
      ),
    );
  }

  Widget _buildWarehouseStockSummary(List<WarehouseStockRow> warehouses) {
    if (warehouses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Text(
          'Add opening stock to initialize warehouse-wise book stock and physical stock.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSubtle),
        ),
      );
    }

    final accountingOnHand = warehouses.fold<double>(
      0,
      (sum, row) => sum + row.accounting.onHand,
    );
    final accountingCommitted = warehouses.fold<double>(
      0,
      (sum, row) => sum + row.accounting.committed,
    );
    final physicalOnHand = warehouses.fold<double>(
      0,
      (sum, row) => sum + row.physical.onHand,
    );
    final variance = physicalOnHand - accountingOnHand;
    final bool isAccounting = _stockView == _StockView.accounting;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAccounting
                ? 'Accounting stock follows ERP book stock. Committed stock is reserved against open sales commitments, and available for sale is book stock minus committed stock.'
                : 'Physical stock reflects the latest counted quantity in each warehouse. Use the variance against accounting stock to spot shortages or excess stock.',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSubtle),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildWarehouseSummaryChip(
                'Accounting On Hand',
                _formatQty(accountingOnHand),
              ),
              _buildWarehouseSummaryChip(
                'Committed',
                _formatQty(accountingCommitted),
              ),
              _buildWarehouseSummaryChip(
                'Physical On Hand',
                _formatQty(physicalOnHand),
              ),
              _buildWarehouseSummaryChip(
                'Variance',
                variance > 0
                    ? '+${_formatQty(variance)}'
                    : _formatQty(variance),
                valueColor: variance > 0
                    ? AppTheme.successDark
                    : variance < 0
                    ? AppTheme.errorRed
                    : AppTheme.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseSummaryChip(
    String label,
    String value, {
    Color valueColor = AppTheme.textPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseActions(Item item, List<WarehouseStockRow> warehouses) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
      tooltip: 'Warehouse actions',
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (!mounted) return;
        switch (value) {
          case 'opening-stock':
            _openOpeningStockDialog(item, warehouses);
            break;
          // TODO(inventory): re-enable adjust-physical-stock case once
          // new inventory stock calculation logic is implemented.
          // case 'adjust-physical-stock':
          //   _openPhysicalStockAdjustmentDialog(item, warehouses);
          //   break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'opening-stock',
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'Add Opening Stock',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        // TODO(inventory): re-enable Adjust Physical Stock menu item once
        // new physical stock adjustment logic is implemented.
        // PopupMenuItem(
        //   value: 'adjust-physical-stock',
        //   height: 44,
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        //   child: Text(
        //     'Adjust Physical Stock',
        //     style: const TextStyle(
        //       fontSize: 14,
        //       fontWeight: FontWeight.w600,
        //       color: AppTheme.textPrimary,
        //     ),
        //   ),
        // ),
      ],
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Icon(
          Icons.settings_outlined,
          size: 18,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Future<void> _openOpeningStockDialog(
    Item item,
    List<WarehouseStockRow> warehouses,
  ) async {
    if (!mounted || item.id == null) return;
    final id = item.id!;
    context.go('/items/detail/$id/opening-stock?tab=warehouses');
  }

  // TODO(inventory): re-enable once new physical stock adjustment logic is implemented.
  // Future<void> _openPhysicalStockAdjustmentDialog(
  //   Item item,
  //   List<WarehouseStockRow> warehouses,
  // ) async {
  //   if (item.id == null) return;
  //   final result = await showDialog<bool>(
  //     context: context,
  //     barrierColor: Colors.black.withValues(alpha: 0.12),
  //     builder: (_) => Dialog(
  //       backgroundColor: Colors.white,
  //       insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       child: Container(
  //         width: 620,
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: _PhysicalStockAdjustmentDialog(
  //           itemId: item.id!,
  //           warehouses: warehouses,
  //         ),
  //       ),
  //     ),
  //   );
  //   if (result == true && mounted) {
  //     ref.invalidate(itemWarehouseStocksProvider(item.id!));
  //     await ref.read(itemsControllerProvider.notifier).fetchQuickStats(item.id!);
  //   }
  // }

  // Moved to _ItemDetailScreenState
}

class _PhysicalStockAdjustmentDialog extends ConsumerStatefulWidget {
  final String itemId;
  final List<WarehouseStockRow> warehouses;

  const _PhysicalStockAdjustmentDialog({
    required this.itemId,
    required this.warehouses,
  });

  @override
  ConsumerState<_PhysicalStockAdjustmentDialog> createState() =>
      _PhysicalStockAdjustmentDialogState();
}

class _PhysicalStockAdjustmentDialogState
    extends ConsumerState<_PhysicalStockAdjustmentDialog> {
  late WarehouseStockRow? _selectedWarehouse;
  late final TextEditingController _countedStockController;
  late final TextEditingController _notesController;
  String? _selectedReason;
  bool _isSaving = false;

  static const List<String> _reasons = [
    'Cycle Count',
    'Damage / Expiry',
    'Shrinkage / Theft',
    'Found Extra Stock',
    'Manual Correction',
  ];

  @override
  void initState() {
    super.initState();
    _selectedWarehouse = widget.warehouses.isNotEmpty
        ? widget.warehouses.first
        : null;
    _countedStockController = TextEditingController(
      text: _selectedWarehouse == null
          ? '0'
          : _selectedWarehouse!.physical.onHand.toStringAsFixed(2),
    );
    _notesController = TextEditingController();
    _selectedReason = _reasons.first;
  }

  @override
  void dispose() {
    _countedStockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _countedStock =>
      double.tryParse(_countedStockController.text.trim()) ?? 0;

  double get _variance =>
      _countedStock - (_selectedWarehouse?.accounting.onHand ?? 0);

  @override
  Widget build(BuildContext context) {
    final warehouse = _selectedWarehouse;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              const Text(
                'Adjust Physical Stock',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Count the stock physically and record the counted quantity. Accounting stock stays unchanged; this flow only updates physical stock and logs the variance.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSubtle),
                ),
                const SizedBox(height: 16),
                FormDropdown<WarehouseStockRow>(
                  value: warehouse,
                  items: widget.warehouses,
                  hint: 'Select warehouse',
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedWarehouse = value;
                      _countedStockController.text = value.physical.onHand
                          .toStringAsFixed(2);
                    });
                  },
                  displayStringForValue: (row) => row.name,
                  searchStringForValue: (row) => row.name,
                ),
                const SizedBox(height: 16),
                if (warehouse != null) _buildWarehouseSnapshot(warehouse),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildLabeledField(
                        'Counted physical stock',
                        TextField(
                          controller: _countedStockController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}$'),
                            ),
                          ],
                          decoration: _dialogInputDecoration(
                            'Enter counted qty',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildLabeledField(
                        'Adjustment reason',
                        FormDropdown<String>(
                          value: _selectedReason,
                          items: _reasons,
                          hint: 'Select reason',
                          onChanged: (value) =>
                              setState(() => _selectedReason = value),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabeledField(
                  'Notes',
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: _dialogInputDecoration(
                      'Optional notes for this count',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildVarianceBanner(),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: _isSaving || warehouse == null ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Adjustment',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseSnapshot(WarehouseStockRow warehouse) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _metricText('Accounting On Hand', warehouse.accounting.onHand),
          _metricText('Current Physical', warehouse.physical.onHand),
          _metricText('Committed', warehouse.accounting.committed),
          _metricText('Available for Sale', warehouse.accounting.available),
        ],
      ),
    );
  }

  Widget _metricText(String label, double value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value.toStringAsFixed(2),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _dialogInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppTheme.primaryBlueDark),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildVarianceBanner() {
    final variance = _variance;
    final color = variance > 0
        ? AppTheme.successDark
        : variance < 0
        ? AppTheme.errorRed
        : AppTheme.textPrimary;
    final message = variance == 0
        ? 'No variance. Physical stock matches accounting stock.'
        : variance > 0
        ? 'Positive variance of +${variance.toStringAsFixed(2)} will be recorded.'
        : 'Negative variance of ${variance.toStringAsFixed(2)} will be recorded.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_selectedWarehouse == null) return;
    if (_selectedReason == null || _selectedReason!.trim().isEmpty) {
      ZerpaiToast.error(context, 'Please select an adjustment reason');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(itemsControllerProvider.notifier)
          .adjustWarehousePhysicalStock(
            widget.itemId,
            warehouseId: _selectedWarehouse!.id,
            countedStock: _countedStock,
            reason: _selectedReason!,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context, true);
        ZerpaiToast.success(context, 'Physical stock adjusted successfully');
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to adjust physical stock: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
