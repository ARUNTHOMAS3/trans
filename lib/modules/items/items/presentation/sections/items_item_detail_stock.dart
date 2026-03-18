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
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    final warehouses = _resolveWarehouseRows(state, item);
    final String stockLabel = _stockView == _StockView.accounting
        ? 'Accounting Stock'
        : 'Physical Stock';

    return SingleChildScrollView(
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
              _buildWarehouseActions(item),
              const Spacer(),
              _buildStockToggle(),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _buildWarehouseTable(stockLabel, warehouses),
            ),
          ),
        ],
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
          Icon(Icons.search, size: 16, color: Color(0xFF2563EB)),
          SizedBox(width: 6),
          Text(
            'Find Serial Number',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF2563EB),
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
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.file_upload_outlined,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            SizedBox(width: 6),
            Text(
              'Export As',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF6B7280)),
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
          style: TextStyle(fontSize: 12, color: Color(0xFF111827)),
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
          activeColor: const Color(0xFF2563EB),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Tooltip(
          message:
              'Enable this option to view both available and unavailable serial numbers. If disabled, only available serial numbers will be displayed.',
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          preferBelow: true,
          child: Row(
            children: const [
              Text(
                'Show All Serial Numbers',
                style: TextStyle(fontSize: 13, color: Color(0xFF111827)),
              ),
              SizedBox(width: 4),
              Icon(Icons.help_outline, size: 14, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSerialNumbersGrid(List<SerialData> serials) {
    const borderColor = Color(0xFFE5E7EB);
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
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
        ? const Color(0xFF111827)
        : const Color(0xFF9CA3AF);
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
    final entries = <MapEntry<DateTime, String>>[];
    final createdAt = item.createdAt;
    if (createdAt != null) {
      entries.add(
        MapEntry(createdAt, 'created by - ${item.createdById ?? 'system'}'),
      );
    }
    final updatedAt = item.updatedAt;
    if (updatedAt != null) {
      entries.add(
        MapEntry(updatedAt, 'updated by - ${item.updatedById ?? 'system'}'),
      );
    }

    entries.sort((a, b) => b.key.compareTo(a.key));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _buildHistoryHeaderText('DATE')),
                    Expanded(
                      flex: 5,
                      child: _buildHistoryHeaderText('DETAILS'),
                    ),
                  ],
                ),
              ),
            ),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No history available.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              )
            else
              ...entries.map((entry) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatHistoryDate(entry.key),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
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
              _buildTransactionFiltersRow(),
              const SizedBox(height: 12),
              _buildTransactionsTable(filtered),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionFiltersRow() {
    return Row(
      children: [
        _buildTransactionTypeDropdown(),
        const SizedBox(width: 12),
        _buildTransactionStatusDropdown(),
      ],
    );
  }

  Widget _buildTransactionTypeDropdown() {
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
      onSelected: (value) => updateState(() => _transactionTypeFilter = value),
    );
  }

  Widget _buildTransactionStatusDropdown() {
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
          updateState(() => _transactionStatusFilter = value),
    );
  }

  Widget _buildTransactionsTable(List<TransactionData> transactions) {
    const borderColor = Color(0xFFE5E7EB);

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
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
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
              ? const Color(0xFF3B82F6)
              : (showGray ? const Color(0xFFE5E7EB) : Colors.transparent);
          final textColor = showBlue ? Colors.white : const Color(0xFF111827);

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
        ? const Color(0xFF2563EB)
        : const Color(0xFF6B7280);

    return InkWell(
      onTap: () => updateState(() => _selectedTransaction = tx),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
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
                    color: Color(0xFF2563EB),
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
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.3,
          ),
          textAlign: align,
        ),
        if (sortable) ...[
          const SizedBox(width: 4),
          const Icon(Icons.unfold_more, size: 14, color: Color(0xFF9CA3AF)),
        ],
      ],
    );
  }

  String _formatHistoryDate(DateTime date) {
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
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildBatchFiltersRow(Item item, List<BatchData> batches) {
    return Row(
      children: [
        _buildBatchFilterDropdown(),
        const SizedBox(width: 12),
        _buildWarehouseFilterDropdown(item),
        const SizedBox(width: 12),
        _buildShowEmptyBatchesCheckbox(),
        const Spacer(),
        _buildBatchFindLink(batches),
        const SizedBox(width: 12),
        _buildNewBatchButton(),
      ],
    );
  }

  Widget _buildBatchFilterDropdown() {
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
      onSelected: (value) => updateState(() => _batchFilter = value),
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
      onSelected: (value) => updateState(() => _warehouseFilter = value),
    );
  }

  Widget _buildShowEmptyBatchesCheckbox() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _showEmptyBatches,
          onChanged: (value) {
            updateState(() => _showEmptyBatches = value ?? false);
          },
          activeColor: const Color(0xFF2563EB),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Select this option to display batches with zero quantity',
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          preferBelow: true,
          child: Row(
            children: [
              const Text(
                'Show Empty Batches',
                style: TextStyle(fontSize: 13, color: Color(0xFF111827)),
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
          Icon(Icons.search, size: 16, color: Color(0xFF2563EB)),
          SizedBox(width: 6),
          Text(
            'Find Batch Number',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF2563EB),
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
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBatchTable(List<BatchData> batches) {
    const borderColor = Color(0xFFE5E7EB);

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
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                border: Border.all(color: const Color(0xFFD1D5DB)),
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
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
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
              activeColor: const Color(0xFF2563EB),
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
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.3,
          ),
          textAlign: align,
        ),
        if (sortable) ...[
          const SizedBox(width: 4),
          const Icon(Icons.unfold_more, size: 14, color: Color(0xFF9CA3AF)),
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
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF111827);
    final linkColor = isInactive
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF2563EB);

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
                activeColor: const Color(0xFF2563EB),
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
                          ? const Color(0xFF9CA3AF)
                          : (isExpired
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF111827)),
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
                          ? const Color(0xFF9CA3AF)
                          : (isEmpty
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF111827)),
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
                        color: Color(0xFF10B981),
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
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
      color: Color(0xFF6B7280),
      letterSpacing: 0.2,
    );

    final TextStyle cellStyle = const TextStyle(
      fontSize: 13,
      color: Color(0xFF111827),
      fontWeight: FontWeight.w600,
    );

    final borderColor = const Color(0xFFE5E7EB);

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
              _stockValueCell(numbers.onHand, cellStyle),
              _stockValueCell(numbers.committed, cellStyle),
              _stockValueCell(numbers.available, cellStyle),
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
                    style: headerStyle.copyWith(color: const Color(0xFF374151)),
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
            child: Text(
              warehouse.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (warehouse.isPrimary)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
            ),
        ],
      ),
    );
  }

  Widget _stockValueCell(double value, TextStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.center,
      child: Text(_formatQty(value), style: style),
    );
  }

  Widget _emptyCell({bool showText = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: showText
          ? const Text(
              'No warehouse stock yet',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            )
          : const SizedBox(),
    );
  }

  Widget _buildStockToggle() {
    final bool isAccounting = _stockView == _StockView.accounting;

    Widget buildChip(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFD1D5DB),
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
              color: selected ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildChip('Accounting Stock', isAccounting, () {
            if (_stockView != _StockView.accounting) {
              updateState(() => _stockView = _StockView.accounting);
            }
          }),
          const SizedBox(width: 6),
          buildChip('Physical Stock', !isAccounting, () {
            if (_stockView != _StockView.physical) {
              updateState(() => _stockView = _StockView.physical);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildWarehouseActions(Item item) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
      tooltip: 'Warehouse actions',
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (!mounted) return;
        switch (value) {
          case 'opening-stock':
            _openOpeningStockDialog(item);
            break;
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
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: const Icon(
          Icons.settings_outlined,
          size: 18,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  List<WarehouseStockRow> _resolveWarehouseRows(ItemsState state, Item item) {
    if (state.storageLocations.isEmpty) {
      return [];
    }

    return state.storageLocations.map((loc) {
      final name = loc['name'] ?? loc['storage_name'] ?? 'Unknown';
      final id = loc['id']?.toString();
      final isPrimary = item.storageId == id;

      // For now, if it's the primary storage (or if we only have one),
      // show total stock. In a future update, we would pull per-warehouse stock.
      final stock = (isPrimary || state.storageLocations.length == 1)
          ? (item.stockOnHand ?? 0)
          : 0.0;

      return WarehouseStockRow(
        name: name,
        isPrimary: isPrimary,
        accounting: StockNumbers(onHand: stock, committed: 0),
        physical: StockNumbers(onHand: stock, committed: 0),
      );
    }).toList();
  }

  OpeningStockMode _resolveOpeningStockMode(Item item) {
    if (item.trackBatches) return OpeningStockMode.batches;
    if (item.trackSerialNumber) return OpeningStockMode.serials;
    return OpeningStockMode.none;
  }

  Future<void> _openOpeningStockDialog(Item item) async {
    final warehouses = _resolveWarehouseRows(
      ref.read(itemsControllerProvider),
      item,
    );
    final mode = _resolveOpeningStockMode(item);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: 230,
                child: ZerpaiSidebar(onNavigate: (route) => context.go(route)),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _OpeningStockDialog(
                    itemId: item.id!,
                    itemName: item.productName,
                    mode: mode,
                    warehouses: warehouses,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted && item.id != null) {
      await ref
          .read(itemsControllerProvider.notifier)
          .updateOpeningStock(
            item.id!,
            result['totalStock'],
            result['totalValue'],
          );
    }
  }

  // Moved to _ItemDetailScreenState
}
