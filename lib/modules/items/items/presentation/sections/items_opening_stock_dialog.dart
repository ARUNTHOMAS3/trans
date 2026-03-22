part of '../items_item_detail.dart';

/// Public screen wrapper — used by GoRouter so the opening-stock flow has its
/// own URL (`/items/detail/:id/opening-stock`) and supports deep linking.
/// Rendered inside [ZerpaiShell] which already provides the sidebar and navbar,
/// so this widget only renders the content panel.
class ItemsOpeningStockScreen extends ConsumerWidget {
  final String itemId;
  final Map<String, String> initialQueryParameters;

  const ItemsOpeningStockScreen({
    super.key,
    required this.itemId,
    this.initialQueryParameters = const <String, String>{},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailByIdProvider(itemId));
    final warehousesAsync = ref.watch(itemWarehouseStocksProvider(itemId));

    return itemAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading item: $e')),
      data: (item) {
        if (item == null) {
          return const Center(child: Text('Item not found'));
        }
        OpeningStockMode mode = OpeningStockMode.none;
        if (item.trackBatches) mode = OpeningStockMode.batches;
        if (item.trackSerialNumber) mode = OpeningStockMode.serials;

        return warehousesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading warehouses: $e')),
          data: (warehouses) => ColoredBox(
            color: Colors.white,
            child: _OpeningStockDialog(
              itemId: item.id!,
              itemName: item.productName,
              mode: mode,
              warehouses: warehouses,
              initialQueryParameters: initialQueryParameters,
            ),
          ),
        );
      },
    );
  }
}

class _OpeningStockDialog extends ConsumerStatefulWidget {
  final String itemId;
  final String itemName;
  final OpeningStockMode mode;
  final List<WarehouseStockRow> warehouses;
  final Map<String, String> initialQueryParameters;

  const _OpeningStockDialog({
    required this.itemId,
    required this.itemName,
    required this.mode,
    required this.warehouses,
    this.initialQueryParameters = const <String, String>{},
  });

  @override
  ConsumerState<_OpeningStockDialog> createState() =>
      _OpeningStockDialogState();
}

class _OpeningStockDialogState extends ConsumerState<_OpeningStockDialog> {
  final List<_OpeningStockWarehouseEntry> _warehouseEntries = [];
  final Map<TextEditingController, GlobalKey> _dateFieldKeys = {};
  int _selectedWarehouseIndex = 0;
  final GlobalKey _serialGenerateKey = GlobalKey();
  OverlayEntry? _serialGenerateEntry;
  TextEditingController? _serialGenerateController;
  TextEditingController? _serialGenerateCountController;
  bool _isSaving = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    for (final wh in widget.warehouses) {
      _warehouseEntries.add(
        _OpeningStockWarehouseEntry(
          warehouseId: wh.id,
          warehouseName: wh.name,
          outletName: wh.outletName,
          mode: widget.mode,
          openingStock: wh.openingStock,
          openingStockValue: wh.openingStockValue,
        ),
      );
    }
  }

  @override
  void dispose() {
    _closeSerialGeneratorPopover();
    for (final entry in _warehouseEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shellMetrics = context.shellMetrics;
    final currentEntry = _warehouseEntries.isNotEmpty
        ? _warehouseEntries[_selectedWarehouseIndex]
        : null;
    final bodyPadding = shellMetrics.isVeryTightContent ? 16.0 : 24.0;

    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          if (_allowPop && mounted) {
            setState(() => _allowPop = false);
          }
          return;
        }
        _attemptCloseOpeningStockScreen();
      },
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  widget.itemName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _attemptCloseOpeningStockScreen,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(bodyPadding),
              child: currentEntry == null
                  ? const Center(child: Text('No warehouses available'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.mode == OpeningStockMode.serials)
                          _buildSerialSection(currentEntry)
                        else if (widget.mode == OpeningStockMode.batches)
                          _buildBatchSection(currentEntry)
                        else ...[
                          _buildSimpleStockTable(currentEntry),
                        ],
                      ],
                    ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _attemptCloseOpeningStockScreen,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textBody,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasUnsavedChanges =>
      _warehouseEntries.any((entry) => entry.hasUnsavedChanges);

  Widget _buildSimpleStockTable(_OpeningStockWarehouseEntry entry) {
    const borderColor = AppTheme.borderColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
        ),
        child: _buildScrollableTableShell(
          minWidth: 720,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(1.2),
              3: FixedColumnWidth(48),
            },
            border: TableBorder(
              top: BorderSide(color: borderColor),
              horizontalInside: BorderSide(color: borderColor),
              verticalInside: BorderSide(color: borderColor),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.bgLight),
                children: [
                  _buildSerialHeaderCell('WAREHOUSE'),
                  _buildSerialHeaderCopyCell('OPENING STOCK', () {}),
                  _buildSerialHeaderCopyCell(
                    'OPENING STOCK VALUE\nPER UNIT',
                    () {},
                  ),
                  const SizedBox.shrink(),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: _buildWarehouseSelector(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: _buildNumberInput(entry.openingStockController),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: _buildNumberInput(entry.openingStockValueController),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.errorRed,
                        size: 20,
                      ),
                      onPressed: null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarehouseSelector() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
          highlightColor: Colors.white,
          focusColor: Colors.white,
          hoverColor: Colors.white,
          splashColor: Colors.transparent,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _selectedWarehouseIndex,
            isExpanded: true,
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedWarehouseIndex = value);
              }
            },
            items: _warehouseEntries.asMap().entries.map((e) {
              return DropdownMenuItem<int>(
                value: e.key,
                child: Text(e.value.displayWarehouseName),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBatchSection(_OpeningStockWarehouseEntry entry) {
    const borderColor = AppTheme.borderColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch-wise Opening Stock',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enter warehouse opening quantity, batch details, and received quantity.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildBatchSearchField(),
                ],
              ),
            ),
            _buildScrollableTableShell(
              minWidth: 1240,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(1.05),
                  2: FlexColumnWidth(1.15),
                  3: FlexColumnWidth(1.55),
                  4: FlexColumnWidth(1.45),
                  5: FlexColumnWidth(1.0),
                  6: FlexColumnWidth(1.15),
                  7: FlexColumnWidth(1.15),
                  8: FlexColumnWidth(0.95),
                  9: FixedColumnWidth(36),
                  10: FixedColumnWidth(36),
                },
                border: TableBorder(
                  top: BorderSide(color: borderColor),
                  horizontalInside: BorderSide(color: borderColor),
                  verticalInside: BorderSide(color: borderColor),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppTheme.bgLight),
                    children: [
                      _buildBatchHeaderCell('WAREHOUSE'),
                      _buildSerialHeaderCopyCell('OPENING QTY', () {}),
                      _buildSerialHeaderCopyCell('UNIT VALUE', () {}),
                      _buildBatchHeaderCell(
                        'BATCH REF#*',
                        color: AppTheme.errorRed,
                      ),
                      _buildBatchHeaderCell('MFR BATCH#'),
                      _buildBatchHeaderCell('UNIT PACK'),
                      _buildBatchHeaderCell('MFD DATE'),
                      _buildBatchHeaderCell('EXPIRY DATE'),
                      _buildBatchHeaderCell(
                        'QTY IN*',
                        color: AppTheme.errorRed,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox.shrink(),
                      const SizedBox.shrink(),
                    ],
                  ),
                  ...entry.batchEntries.asMap().entries.map((e) {
                    final batch = e.value;
                    final isFirstRow = e.key == 0;

                    return TableRow(
                      children: [
                        _buildBatchBodyCell(
                          isFirstRow
                              ? _buildWarehouseSelector()
                              : const SizedBox.shrink(),
                        ),
                        _buildBatchBodyCell(
                          isFirstRow
                              ? _buildNumberInput(entry.openingStockController)
                              : const SizedBox.shrink(),
                        ),
                        _buildBatchBodyCell(
                          isFirstRow
                              ? _buildNumberInput(
                                  entry.openingStockValueController,
                                )
                              : const SizedBox.shrink(),
                        ),
                        _buildBatchBodyCell(
                          _buildTextField(
                            batch.batchReferenceController,
                            'Enter Batch#',
                          ),
                        ),
                        _buildBatchBodyCell(
                          _buildTextField(
                            batch.mfrBatchController,
                            'Enter MFR Batch#',
                          ),
                        ),
                        _buildBatchBodyCell(
                          _buildIntegerInput(
                            batch.unitPackController,
                            hint: '0',
                          ),
                        ),
                        _buildBatchBodyCell(
                          _buildDateField(
                            batch.mfrDateController,
                            'dd-MM-yyyy',
                          ),
                        ),
                        _buildBatchBodyCell(
                          _buildDateField(
                            batch.expiryDateController,
                            'dd-MM-yyyy',
                          ),
                        ),
                        _buildBatchBodyCell(
                          _buildNumberInput(batch.quantityController),
                        ),
                        _buildBatchActionCell(
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppTheme.errorRed,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                entry.batchEntries.removeAt(e.key);
                                if (entry.batchEntries.isEmpty) {
                                  entry.batchEntries.add(_BatchEntry());
                                }
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        _buildBatchActionCell(
                          isFirstRow
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.errorRed,
                                    size: 20,
                                  ),
                                  onPressed: null,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useCompactLayout = constraints.maxWidth < 980;

                  return Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 12,
                    spacing: 16,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            entry.batchEntries.add(_BatchEntry());
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F8FF),
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.add,
                                size: 16,
                                color: AppTheme.primaryBlueDark,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'New Batch',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryBlueDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: useCompactLayout ? double.infinity : null,
                        child: _buildBatchSummaryRow(entry),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchSearchField() {
    return Container(
      width: 240,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Find Batch Number',
          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: AppTheme.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildBatchHeaderCell(
    String label, {
    Color color = AppTheme.textSecondary,
    TextAlign textAlign = TextAlign.left,
  }) {
    final alignment = textAlign == TextAlign.right
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Align(
        alignment: alignment,
        child: Text(
          label,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildBatchBodyCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: child,
    );
  }

  Widget _buildBatchActionCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      child: Align(alignment: Alignment.center, child: child),
    );
  }

  Widget _buildSerialSection(_OpeningStockWarehouseEntry entry) {
    final serialNumbers = entry.serialNumbersController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    const borderColor = AppTheme.borderColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
        ),
        child: _buildScrollableTableShell(
          minWidth: 920,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(3.1),
              4: FixedColumnWidth(48),
            },
            border: TableBorder(
              top: BorderSide(color: borderColor),
              horizontalInside: BorderSide(color: borderColor),
              verticalInside: BorderSide(color: borderColor),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.bgLight),
                children: [
                  _buildSerialHeaderCell('WAREHOUSE'),
                  _buildSerialHeaderCopyCell('OPENING STOCK', () {}),
                  _buildSerialHeaderCopyCell(
                    'OPENING STOCK VALUE\nPER UNIT',
                    () {},
                  ),
                  _buildSerialNumbersHeaderCell(() {}),
                  const SizedBox.shrink(),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: _buildWarehouseSelector(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: _buildNumberInput(entry.openingStockController),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: _buildNumberInput(entry.openingStockValueController),
                  ),
                  _buildSerialInputCell(entry, serialNumbers),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.errorRed,
                        size: 20,
                      ),
                      onPressed: null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableTableShell({
    required double minWidth,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMinWidth = constraints.maxWidth > minWidth
            ? constraints.maxWidth
            : minWidth;
        return ResponsiveTableShell(minWidth: effectiveMinWidth, child: child);
      },
    );
  }

  Widget _buildSerialHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSerialHeaderCopyCell(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: onTap,
            child: const Text(
              'COPY TO ALL',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryBlueDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialNumbersHeaderCell(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Text(
            'SERIAL NUMBERS*',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput(TextEditingController controller) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        style: const TextStyle(fontSize: 13),
        onTap: () => _selectAllNumericInput(controller),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            borderSide: const BorderSide(color: AppTheme.primaryBlueDark),
          ),
        ),
      ),
    );
  }

  Widget _buildIntegerInput(TextEditingController controller, {String? hint}) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.right,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 13),
        onTap: () => _selectAllNumericInput(controller),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            borderSide: const BorderSide(color: AppTheme.primaryBlueDark),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String hint) {
    final fieldKey = _dateFieldKeys.putIfAbsent(controller, () => GlobalKey());
    return SizedBox(
      key: fieldKey,
      height: 36,
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(fontSize: 13),
        onTap: () => _pickDate(controller),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            borderSide: const BorderSide(color: AppTheme.primaryBlueDark),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final existingDate = _parseDate(controller.text);
    final initialDate = existingDate ?? now;
    final targetKey = _dateFieldKeys.putIfAbsent(controller, () => GlobalKey());
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      targetKey: targetKey,
    );
    if (picked != null) {
      controller.text = _formatDate(picked);
      setState(() {});
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      return null;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  void _selectAllNumericInput(TextEditingController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  Widget _buildSerialInputCell(
    _OpeningStockWarehouseEntry entry,
    List<String> serialNumbers,
  ) {
    const cellBorderColor = AppTheme.borderColor;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...serialNumbers.map(
                      (serial) => _buildSerialChip(serial, entry),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SizedBox(
                          width: constraints.maxWidth,
                          child: _SerialInputField(
                            hintText: serialNumbers.isEmpty
                                ? 'Type (comma separated) or scan the serial numbers'
                                : null,
                            onSerialAdded: (value) {
                              if (value.trim().isNotEmpty) {
                                final trimmedValue = value.trim();
                                final existingSerials = entry
                                    .serialNumbersController
                                    .text
                                    .split(',')
                                    .map((s) => s.trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList();
                                if (!existingSerials.contains(trimmedValue)) {
                                  final current =
                                      entry.serialNumbersController.text;
                                  entry.serialNumbersController.text =
                                      current.isEmpty
                                      ? trimmedValue
                                      : '$current, $trimmedValue';
                                  setState(() {});
                                  return true;
                                }
                                return false;
                              }
                              return false;
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Count: ${serialNumbers.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Generate Serial Numbers',
                decoration: BoxDecoration(
                  color: AppTheme.textPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                preferBelow: false,
                child: InkWell(
                  key: _serialGenerateKey,
                  onTap: () => _toggleSerialGeneratorPopover(entry),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  entry.serialNumbersController.clear();
                  setState(() {});
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: cellBorderColor)),
            ),
            child: _buildSerialSummaryRow(entry),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialSummaryRow(_OpeningStockWarehouseEntry entry) {
    final qtyToAdd = entry.getRemainingQuantityToAdd();
    final addedQty = entry.getDetailedQuantityTotal();
    final hasMismatch = entry.hasDetailedQuantityMismatch;

    final Widget warningIcon = Tooltip(
      message:
          '- There\'s a mismatch between the quantity entered in the opening stock and the total serial quantity entered here.\n- Once you click Save, the opening stock quantity will be overwritten by the serial/batch/bin quantity.',
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primaryBlueDark),
      ),
      textStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      preferBelow: true,
      child: const Icon(
        Icons.warning_amber,
        size: 16,
        color: Color(0xFFF97316),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Quantity To Be Added: ',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          entry.formatQuantity(qtyToAdd),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFF97316),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        if (hasMismatch) ...[warningIcon, const SizedBox(width: 8)],
        const Text(
          'Added Qty to Warehouse: ',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          entry.formatQuantity(addedQty),
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBatchSummaryRow(_OpeningStockWarehouseEntry entry) {
    final qtyToAdd = entry.getRemainingQuantityToAdd();
    final addedQty = entry.getDetailedQuantityTotal();
    final hasMismatch = entry.hasDetailedQuantityMismatch;

    final Widget warningIcon = Tooltip(
      message:
          '- There\'s a mismatch between the quantity entered in the opening stock and the total batch quantity entered here.\n- Once you click Save, the opening stock quantity will be overwritten by the serial/batch/bin quantity.',
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primaryBlueDark),
      ),
      textStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      preferBelow: true,
      child: const Icon(
        Icons.warning_amber,
        size: 16,
        color: Color(0xFFF97316),
      ),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      spacing: 8,
      children: [
        const Text(
          'Quantity To Be Added: ',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          entry.formatQuantity(qtyToAdd),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFF97316),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        if (hasMismatch) ...[warningIcon, const SizedBox(width: 8)],
        const Text(
          'Added Qty to Warehouse: ',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          entry.formatQuantity(addedQty),
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSerialChip(String serial, _OpeningStockWarehouseEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            serial,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3730A3),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              final serials = entry.serialNumbersController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty && s != serial)
                  .toList();
              entry.serialNumbersController.text = serials.join(', ');
              setState(() {});
            },
            child: const Icon(Icons.close, size: 14, color: Color(0xFF3730A3)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            borderSide: const BorderSide(color: AppTheme.primaryBlueDark),
          ),
        ),
      ),
    );
  }

  void _toggleSerialGeneratorPopover(_OpeningStockWarehouseEntry entry) {
    if (_serialGenerateEntry != null) {
      _closeSerialGeneratorPopover();
      return;
    }

    final RenderBox? renderBox =
        _serialGenerateKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final overlay = Overlay.of(context);

    _serialGenerateController = TextEditingController();
    _serialGenerateCountController = TextEditingController();

    const popoverWidth = 360.0;
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final overlaySize = overlayBox.size;

    double left = offset.dx - (popoverWidth / 2) + (size.width / 2);
    final maxLeft = overlaySize.width - popoverWidth - 16.0;
    final clampedMaxLeft = maxLeft < 16.0 ? 16.0 : maxLeft;
    left = left.clamp(16.0, clampedMaxLeft);
    final double top = offset.dy + size.height + 8;

    double arrowLeft = (offset.dx + size.width / 2) - left - 6;
    if (arrowLeft < 12) {
      arrowLeft = 12;
    }
    if (arrowLeft > popoverWidth - 24) {
      arrowLeft = popoverWidth - 24;
    }

    String? errorMessage;

    _serialGenerateEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopoverState) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeSerialGeneratorPopover,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -6,
                          left: arrowLeft,
                          child: Transform.rotate(
                            angle: 0.785,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: popoverWidth,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Serial Number',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message:
                                        'You need to enter the first serial number ending with numeric value. For example, SN-001 with a count of 100 generates SN-001 to SN-100.',
                                    decoration: BoxDecoration(
                                      color: AppTheme.textPrimary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    preferBelow: false,
                                    child: const Icon(
                                      Icons.help_outline,
                                      size: 14,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _serialGenerateController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                onChanged: (_) {
                                  if (errorMessage != null) {
                                    setPopoverState(() => errorMessage = null);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Count',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _serialGenerateCountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                onChanged: (_) {
                                  if (errorMessage != null) {
                                    setPopoverState(() => errorMessage = null);
                                  }
                                },
                              ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      final serialSeed =
                                          _serialGenerateController?.text
                                              .trim() ??
                                          '';
                                      final countText =
                                          _serialGenerateCountController?.text
                                              .trim() ??
                                          '';
                                      final count =
                                          int.tryParse(countText) ?? 0;
                                      if (serialSeed.isEmpty) {
                                        setPopoverState(() {
                                          errorMessage =
                                              'Enter a starting serial number.';
                                        });
                                        return;
                                      }
                                      if (count <= 0) {
                                        setPopoverState(() {
                                          errorMessage = 'Enter a valid count.';
                                        });
                                        return;
                                      }
                                      if (!RegExp(
                                        r'^(.*?)(\d+)$',
                                      ).hasMatch(serialSeed)) {
                                        setPopoverState(() {
                                          errorMessage =
                                              'Serial number must end with digits.';
                                        });
                                        return;
                                      }
                                      _handleGenerateSerials(
                                        entry,
                                        serialSeed,
                                        count,
                                      );
                                      _closeSerialGeneratorPopover();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: const Text('Generate'),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: _closeSerialGeneratorPopover,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.textBody,
                                      side: const BorderSide(
                                        color: AppTheme.borderColor,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
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
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    overlay.insert(_serialGenerateEntry!);
  }

  void _closeSerialGeneratorPopover() {
    _serialGenerateEntry?.remove();
    _serialGenerateEntry = null;
    _serialGenerateController?.dispose();
    _serialGenerateController = null;
    _serialGenerateCountController?.dispose();
    _serialGenerateCountController = null;
  }

  void _handleGenerateSerials(
    _OpeningStockWarehouseEntry entry,
    String serialSeed,
    int count,
  ) {
    final generated = _buildSerialSequence(serialSeed, count);
    if (generated.isEmpty) {
      return;
    }

    final existing = entry.serialNumbersController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final existingSet = existing.toSet();

    for (final serial in generated) {
      if (!existingSet.contains(serial)) {
        existingSet.add(serial);
        existing.add(serial);
      }
    }

    entry.serialNumbersController.text = existing.join(', ');
    setState(() {});
  }

  List<String> _buildSerialSequence(String seed, int count) {
    if (count <= 0) {
      return [];
    }
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(seed);
    if (match == null) {
      return [];
    }
    final prefix = match.group(1) ?? '';
    final numberPart = match.group(2) ?? '';
    final start = int.tryParse(numberPart) ?? 0;
    final width = numberPart.length;

    return List.generate(count, (index) {
      final next = start + index;
      final padded = next.toString().padLeft(width, '0');
      return '$prefix$padded';
    });
  }

  Future<void> _handleSave() async {
    final rows = <WarehouseStockRow>[];
    double totalStock = 0;

    for (final entry in _warehouseEntries) {
      final stock = entry.getEffectiveStockForSave();
      final rate = double.tryParse(entry.openingStockValueController.text) ?? 0;
      totalStock += stock;

      rows.add(
        WarehouseStockRow(
          id: entry.warehouseId,
          name: entry.warehouseName,
          outletName: entry.outletName,
          openingStock: stock,
          openingStockValue: rate,
          accounting: StockNumbers(onHand: stock, committed: 0),
          physical: StockNumbers(onHand: stock, committed: 0),
        ),
      );
    }

    if (totalStock <= 0) {
      ZerpaiToast.error(context, 'Please enter opening stock quantity');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(itemsControllerProvider.notifier)
          .updateWarehouseStocks(widget.itemId, rows);

      ref.invalidate(itemWarehouseStocksProvider(widget.itemId));
      await ref
          .read(itemsControllerProvider.notifier)
          .fetchQuickStats(widget.itemId);

      if (mounted) {
        _performCloseOpeningStockScreen(result: true);
        ZerpaiToast.saved(context, 'Opening stock');
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to update opening stock: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _attemptCloseOpeningStockScreen() async {
    if (_isSaving) return;

    if (_hasUnsavedChanges) {
      final shouldDiscard = await showUnsavedChangesDialog(
        context,
        title: 'Leave this page?',
        message:
            'If you leave, your unsaved opening stock changes will be discarded.',
      );
      if (!mounted || !shouldDiscard) return;
    }

    _performCloseOpeningStockScreen();
  }

  void _performCloseOpeningStockScreen({bool? result}) {
    if (result != null && context.canPop()) {
      Navigator.pop(context, result);
      return;
    }

    if (context.canPop()) {
      setState(() => _allowPop = true);
      context.pop();
      return;
    }

    final queryParameters = <String, String>{
      ...widget.initialQueryParameters,
      'tab': 'warehouses',
    };
    context.goNamed(
      AppRoutes.itemsDetail,
      pathParameters: {'id': widget.itemId},
      queryParameters: queryParameters,
    );
  }
}

// Supporting classes
class _OpeningStockWarehouseEntry {
  final String warehouseId;
  final String warehouseName;
  final String outletName;
  final OpeningStockMode mode;
  final TextEditingController openingStockController = TextEditingController(
    text: '0',
  );
  final TextEditingController openingStockValueController =
      TextEditingController(text: '0');
  final String _initialOpeningStockText;
  final String _initialOpeningStockValueText;
  final TextEditingController serialNumbersController = TextEditingController();
  final List<_BatchEntry> batchEntries = [];

  _OpeningStockWarehouseEntry({
    required this.warehouseId,
    required this.warehouseName,
    this.outletName = '',
    required this.mode,
    double openingStock = 0,
    double openingStockValue = 0,
  }) : _initialOpeningStockText = _formatInitialNumber(openingStock),
       _initialOpeningStockValueText = _formatInitialNumber(openingStockValue) {
    openingStockController.text = _initialOpeningStockText;
    openingStockValueController.text = _initialOpeningStockValueText;
    if (mode == OpeningStockMode.batches) {
      batchEntries.add(_BatchEntry());
    }
  }

  static String _formatInitialNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toString();
  }

  double getTotalQuantityToAdd() {
    if (mode == OpeningStockMode.batches) {
      return batchEntries.fold<double>(0, (sum, batch) {
        return sum + (double.tryParse(batch.quantityController.text) ?? 0);
      });
    } else if (mode == OpeningStockMode.serials) {
      return serialNumbersController.text
          .split(',')
          .where((s) => s.trim().isNotEmpty)
          .length
          .toDouble();
    }
    return double.tryParse(openingStockController.text) ?? 0;
  }

  double getOpeningStockQuantity() {
    return double.tryParse(openingStockController.text) ?? 0;
  }

  double getDetailedQuantityTotal() {
    if (mode == OpeningStockMode.none) {
      return getOpeningStockQuantity();
    }
    return getTotalQuantityToAdd();
  }

  double getRemainingQuantityToAdd() {
    if (mode == OpeningStockMode.none) {
      return getOpeningStockQuantity();
    }
    final remaining = getOpeningStockQuantity() - getDetailedQuantityTotal();
    return remaining > 0 ? remaining : 0;
  }

  bool get hasDetailedQuantityMismatch {
    if (mode == OpeningStockMode.none) {
      return false;
    }
    return getDetailedQuantityTotal() != getOpeningStockQuantity();
  }

  double getEffectiveStockForSave() {
    if (mode == OpeningStockMode.none) {
      return getOpeningStockQuantity();
    }
    return getDetailedQuantityTotal();
  }

  String formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  bool get hasUnsavedChanges {
    if (openingStockController.text.trim() != _initialOpeningStockText) {
      return true;
    }
    if (openingStockValueController.text.trim() !=
        _initialOpeningStockValueText) {
      return true;
    }
    if (serialNumbersController.text.trim().isNotEmpty) {
      return true;
    }

    for (final batch in batchEntries) {
      if (batch.hasUnsavedChanges) {
        return true;
      }
    }

    return false;
  }

  String get displayWarehouseName {
    final resolvedWarehouseName = warehouseName.trim();
    if (resolvedWarehouseName.isNotEmpty) {
      return resolvedWarehouseName;
    }

    final resolvedOutletName = outletName.trim();
    if (resolvedOutletName.isNotEmpty) {
      return resolvedOutletName;
    }

    return 'Unnamed Outlet';
  }

  void dispose() {
    openingStockController.dispose();
    openingStockValueController.dispose();
    serialNumbersController.dispose();
    for (final batch in batchEntries) {
      batch.dispose();
    }
  }
}

class _BatchEntry {
  final TextEditingController batchReferenceController =
      TextEditingController();
  final TextEditingController mfrBatchController = TextEditingController();
  final TextEditingController unitPackController = TextEditingController();
  final TextEditingController mfrDateController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: '0',
  );

  bool get hasUnsavedChanges =>
      batchReferenceController.text.trim().isNotEmpty ||
      mfrBatchController.text.trim().isNotEmpty ||
      mfrDateController.text.trim().isNotEmpty ||
      expiryDateController.text.trim().isNotEmpty ||
      (int.tryParse(unitPackController.text.trim()) ?? 0) > 0 ||
      (double.tryParse(quantityController.text.trim()) ?? 0) > 0;

  void dispose() {
    batchReferenceController.dispose();
    mfrBatchController.dispose();
    unitPackController.dispose();
    mfrDateController.dispose();
    expiryDateController.dispose();
    quantityController.dispose();
  }
}

// Widget for inline serial number input
class _SerialInputField extends StatefulWidget {
  final bool Function(String) onSerialAdded;
  final String? hintText;

  const _SerialInputField({required this.onSerialAdded, this.hintText});

  @override
  State<_SerialInputField> createState() => _SerialInputFieldState();
}

class _SerialInputFieldState extends State<_SerialInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isDuplicate = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final currentText = _controller.text;
    if (currentText.isEmpty || !currentText.endsWith(',')) {
      return;
    }

    final valueBeforeComma = currentText
        .substring(0, currentText.length - 1)
        .trim();
    if (valueBeforeComma.isEmpty) {
      _controller.removeListener(_onTextChanged);
      _controller.text = '';
      _controller.addListener(_onTextChanged);
      return;
    }

    _processSerialInput(valueBeforeComma);
  }

  void _handleSubmit(String value) {
    if (value.trim().isNotEmpty) {
      _processSerialInput(value.trim());
    }
  }

  void _processSerialInput(String value) {
    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return;
    }

    bool allSuccess = true;
    for (final part in parts) {
      final success = widget.onSerialAdded(part);
      if (!success) {
        allSuccess = false;
      }
    }

    _controller.removeListener(_onTextChanged);
    if (allSuccess) {
      _controller.text = '';
      // Keep focus for continuous input
      _focusNode.requestFocus();
    } else {
      _showDuplicateError();
    }
    _controller.addListener(_onTextChanged);
  }

  void _showDuplicateError() {
    setState(() => _isDuplicate = true);
    _controller.clear();
    // Reset after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isDuplicate = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        hintText: widget.hintText,
        hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        enabledBorder: _isDuplicate
            ? const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.errorRed, width: 2),
              )
            : InputBorder.none,
        focusedBorder: _isDuplicate
            ? const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.errorRed, width: 2),
              )
            : InputBorder.none,
      ),
      onSubmitted: _handleSubmit,
    );
  }
}
