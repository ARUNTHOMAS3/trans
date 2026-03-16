part of '../items_item_detail.dart';

class _OpeningStockDialog extends ConsumerStatefulWidget {
  final String itemId;
  final String itemName;
  final OpeningStockMode mode;
  final List<WarehouseStockRow> warehouses;

  const _OpeningStockDialog({
    required this.itemId,
    required this.itemName,
    required this.mode,
    required this.warehouses,
  });

  @override
  ConsumerState<_OpeningStockDialog> createState() =>
      _OpeningStockDialogState();
}

class _OpeningStockDialogState extends ConsumerState<_OpeningStockDialog> {
  final List<_OpeningStockWarehouseEntry> _warehouseEntries = [];
  int _selectedWarehouseIndex = 0;
  final GlobalKey _serialGenerateKey = GlobalKey();
  OverlayEntry? _serialGenerateEntry;
  TextEditingController? _serialGenerateController;
  TextEditingController? _serialGenerateCountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize with one entry per warehouse
    for (final wh in widget.warehouses) {
      _warehouseEntries.add(
        _OpeningStockWarehouseEntry(warehouseName: wh.name, mode: widget.mode),
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
    final currentEntry = _warehouseEntries.isNotEmpty
        ? _warehouseEntries[_selectedWarehouseIndex]
        : null;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              Text(
                widget.itemName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
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
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
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
    );
  }

  Widget _buildSimpleStockTable(_OpeningStockWarehouseEntry entry) {
    const borderColor = Color(0xFFE5E7EB);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.2),
            1: FlexColumnWidth(1.1),
            2: FlexColumnWidth(1.2),
            3: FixedColumnWidth(48),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: borderColor),
            verticalInside: BorderSide(color: borderColor),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
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
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    onPressed: () {
                      // Delete warehouse entry
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseSelector() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedWarehouseIndex,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedWarehouseIndex = value);
            }
          },
          items: _warehouseEntries.asMap().entries.map((e) {
            return DropdownMenuItem<int>(
              value: e.key,
              child: Text(e.value.warehouseName),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBatchSection(_OpeningStockWarehouseEntry entry) {
    const borderColor = Color(0xFFE5E7EB);

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(children: [const Spacer(), _buildBatchSearchField()]),
            ),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.1),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.6),
                4: FlexColumnWidth(1.4),
                5: FlexColumnWidth(1.0),
                6: FlexColumnWidth(1.2),
                7: FlexColumnWidth(1.2),
                8: FlexColumnWidth(1.0),
                9: FixedColumnWidth(32),
                10: FixedColumnWidth(48),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: borderColor),
                verticalInside: BorderSide(color: borderColor),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                  children: [
                    _buildBatchHeaderCell('WAREHOUSE'),
                    _buildSerialHeaderCopyCell('OPENING STOCK', () {}),
                    _buildSerialHeaderCopyCell(
                      'OPENING STOCK VALUE\nPER UNIT',
                      () {},
                    ),
                    _buildBatchHeaderCell(
                      'BATCH REFERENCE#*',
                      color: const Color(0xFFEF4444),
                    ),
                    _buildBatchHeaderCell('MANUFACTURER BATCH#'),
                    _buildBatchHeaderCell('UNIT PACK'),
                    _buildBatchHeaderCell('MANUFACTURED DATE'),
                    _buildBatchHeaderCell('EXPIRY DATE'),
                    _buildBatchHeaderCell(
                      'QUANTITY IN*',
                      color: const Color(0xFFEF4444),
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
                        _buildIntegerInput(batch.unitPackController, hint: '0'),
                      ),
                      _buildBatchBodyCell(
                        _buildDateField(batch.mfrDateController, 'dd-MM-yyyy'),
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
                            color: Color(0xFFEF4444),
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
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                                onPressed: () {
                                  // Delete warehouse entry
                                },
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        entry.batchEntries.add(_BatchEntry());
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 4),
                        Text(
                          'New Batch',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildBatchSummaryRow(entry),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchSearchField() {
    return Container(
      width: 200,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Find Batch Number',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: Color(0xFF6B7280),
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
    Color color = const Color(0xFF6B7280),
    TextAlign textAlign = TextAlign.left,
  }) {
    final alignment = textAlign == TextAlign.right
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Align(
        alignment: alignment,
        child: Text(
          label,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBatchBodyCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: child,
    );
  }

  Widget _buildBatchActionCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Align(alignment: Alignment.center, child: child),
    );
  }

  Widget _buildSerialSection(_OpeningStockWarehouseEntry entry) {
    final serialNumbers = entry.serialNumbersController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    const borderColor = Color(0xFFE5E7EB);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.2),
            1: FlexColumnWidth(1.1),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(3.1),
            4: FixedColumnWidth(48),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: borderColor),
            verticalInside: BorderSide(color: borderColor),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
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
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    onPressed: () {
                      // Delete
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSerialHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSerialHeaderCopyCell(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
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
                color: Color(0xFF2563EB),
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
              color: Color(0xFFEF4444),
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
        keyboardType: TextInputType.number,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 13),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
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
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String hint) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(fontSize: 13),
        onTap: () => _pickDate(controller),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
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

  Widget _buildSerialInputCell(
    _OpeningStockWarehouseEntry entry,
    List<String> serialNumbers,
  ) {
    const cellBorderColor = Color(0xFFE5E7EB);

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
              border: Border.all(color: const Color(0xFFD1D5DB)),
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
                style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Generate Serial Numbers',
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
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
                      color: Color(0xFF2563EB),
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
                    color: Color(0xFFEF4444),
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
    final qtyToAdd = entry.getTotalQuantityToAdd();
    final addedQty = 0;
    final openingStock = int.tryParse(entry.openingStockController.text) ?? 0;
    final hasMismatch = qtyToAdd != openingStock;

    final Widget warningIcon = Tooltip(
      message:
          '- There\'s a mismatch between the quantity entered in the opening stock and the total serial quantity entered here.\n- Once you click Save, the opening stock quantity will be overwritten by the serial/batch/bin quantity.',
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2563EB)),
      ),
      textStyle: const TextStyle(color: Color(0xFF111827), fontSize: 12),
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
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          '$qtyToAdd',
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
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          '$addedQty',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBatchSummaryRow(_OpeningStockWarehouseEntry entry) {
    final qtyToAdd = entry.getTotalQuantityToAdd();
    final addedQty = 0;
    final openingStock = int.tryParse(entry.openingStockController.text) ?? 0;
    final hasMismatch = qtyToAdd != openingStock;

    final Widget warningIcon = Tooltip(
      message:
          '- There\'s a mismatch between the quantity entered in the opening stock and the total batch quantity entered here.\n- Once you click Save, the opening stock quantity will be overwritten by the serial/batch/bin quantity.',
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2563EB)),
      ),
      textStyle: const TextStyle(color: Color(0xFF111827), fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      preferBelow: true,
      child: const Icon(
        Icons.warning_amber,
        size: 16,
        color: Color(0xFFF97316),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Quantity To Be Added: ',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          '$qtyToAdd',
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
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        Text(
          '$addedQty',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
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
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
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
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: popoverWidth,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message:
                                        'You need to enter the first serial number ending with numeric value. For example, SN-001 with a count of 100 generates SN-001 to SN-100.',
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1F2937),
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
                                      color: Color(0xFF9CA3AF),
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
                                  color: Color(0xFF111827),
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
                                    color: Color(0xFFEF4444),
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
                                      backgroundColor: const Color(0xFF10B981),
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
                                      foregroundColor: const Color(0xFF374151),
                                      side: const BorderSide(
                                        color: Color(0xFFD1D5DB),
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
    double totalStock = 0;
    double totalValue = 0;

    for (final entry in _warehouseEntries) {
      final stock = double.tryParse(entry.openingStockController.text) ?? 0;
      final rate = double.tryParse(entry.openingStockValueController.text) ?? 0;
      totalStock += stock;
      totalValue += (stock * rate);
    }

    if (totalStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter opening stock quantity')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(itemsControllerProvider.notifier)
          .updateOpeningStock(
            widget.itemId,
            totalStock,
            totalValue / totalStock,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening stock updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update opening stock: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

// Supporting classes
class _OpeningStockWarehouseEntry {
  final String warehouseName;
  final OpeningStockMode mode;
  final TextEditingController openingStockController = TextEditingController(
    text: '0',
  );
  final TextEditingController openingStockValueController =
      TextEditingController(text: '0');
  final TextEditingController serialNumbersController = TextEditingController();
  final List<_BatchEntry> batchEntries = [];

  _OpeningStockWarehouseEntry({
    required this.warehouseName,
    required this.mode,
  }) {
    if (mode == OpeningStockMode.batches) {
      batchEntries.add(_BatchEntry());
    }
  }

  int getTotalQuantityToAdd() {
    if (mode == OpeningStockMode.batches) {
      return batchEntries.fold(0, (sum, batch) {
        return sum + (int.tryParse(batch.quantityController.text) ?? 0);
      });
    } else if (mode == OpeningStockMode.serials) {
      return serialNumbersController.text
          .split(',')
          .where((s) => s.trim().isNotEmpty)
          .length;
    }
    return int.tryParse(openingStockController.text) ?? 0;
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
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        enabledBorder: _isDuplicate
            ? const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
              )
            : InputBorder.none,
        focusedBorder: _isDuplicate
            ? const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
              )
            : InputBorder.none,
      ),
      onSubmitted: _handleSubmit,
    );
  }
}
