import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/inventory/providers/stock_provider.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/modules/auth/providers/user_provider.dart';
import 'package:zerpai_erp/modules/inventory/picklists/providers/inventory_picklists_provider.dart';
import 'package:zerpai_erp/modules/inventory/picklists/models/inventory_picklist_model.dart';
import 'package:zerpai_erp/shared/providers/lookup_providers.dart';

const _textPrimary = Color(0xFF1F2937);
const _textSecondary = Color(0xFF6B7280);
const _borderCol = Color(0xFFE5E7EB);
const _focusBorder = Color(0xFF3B82F6);
const _dangerRed = Color(0xFFEF4444);
const _greenBtn = Color(0xFF22A95E);
const _createTableWidthFactor = 0.7;
const _updateExtraSalesOrderColumnFactor = 2 / 12;

class InventoryPicklistsUpdateScreen extends ConsumerStatefulWidget {
  final String id;

  const InventoryPicklistsUpdateScreen({super.key, required this.id});

  @override
  ConsumerState<InventoryPicklistsUpdateScreen> createState() =>
      _InventoryPicklistsUpdateScreenState();
}

class _InventoryPicklistsUpdateScreenState
    extends ConsumerState<InventoryPicklistsUpdateScreen> {
  final _picklistNumberCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedGroup;
  String? _selectedAssignee;
  Warehouse? _selectedWarehouse;

  bool _isSaving = false;
  String? _currentStatus;
  List<WarehouseStockData> _selectedItems = [];
  final Set<String> _qtyPickedOverrideKeys = <String>{};
  final Set<String> _savedBatchKeys = <String>{};
  final Map<String, int> _savedBatchCounts = <String, int>{};
  final Set<String> _hoveredQtyFieldKeys = <String>{};
  final Set<String> _focusedQtyFieldKeys = <String>{};
  final List<String> _validationErrors = [];

  // Batch data persistence
  final Map<String, List<Map<String, String>>> _savedBatchData =
      <String, List<Map<String, String>>>{};


  bool get _allBatchesAdded =>
      _selectedItems.isNotEmpty &&
      _selectedItems.every(
        (item) {
          final qtyPicked = _currentPickedQty(item);
          if (qtyPicked <= 0) return true;
          return _savedBatchKeys.contains(_buildRowKey(item));
        },
      );


  @override
  void initState() {
    super.initState();
    _selectedGroup = 'No Grouping';
    _dateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _loadPicklistData();
  }

  Future<void> _loadPicklistData() async {
    try {
      final picklist = await ref.read(picklistByIdProvider(widget.id).future);
      if (picklist == null || !mounted) return;

      // Wait for warehouses to be loaded if they aren't already
      final warehouses = await ref.read(warehousesProvider.future);
      if (!mounted) return;

      setState(() {
        _picklistNumberCtrl.text = picklist.picklistNumber;
        _dateCtrl.text = picklist.date != null
            ? DateFormat('dd-MM-yyyy').format(picklist.date!)
            : '';
        _notesCtrl.text = picklist.notes ?? '';
        _selectedAssignee = picklist.assignee;
        _currentStatus = picklist.status;

        // Try to find the warehouse by name or ID if possible
        _selectedWarehouse = warehouses.where((w) => w.name == picklist.location).firstOrNull;

        // Map items back to WarehouseStockData
        _selectedItems = picklist.items.map((pi) {
          final stockData = WarehouseStockData(
            id: pi.id,
            warehouseId: _selectedWarehouse?.id ?? '',
            productId: pi.productId ?? '',
            productCode: '', // SKU not always available in PicklistItem
            productName: pi.productName ?? '',
            salesOrderId: pi.salesOrderId,
            salesOrderLineId: pi.salesOrderLineId,
            salesOrderNumber: pi.salesOrderNumber,
            customerName: pi.customerName,
            quantityToPick: pi.qtyToPick,
            quantityPicked: pi.qtyPicked,
            quantityOrdered: pi.qtyOrdered,
            status: pi.status,
            quantityPacked: pi.qtyPacked,
            stock: 0, // Placeholder
          );

          final rowKey = _buildRowKey(stockData);
          if (pi.batchAllocations.isNotEmpty) {
            _savedBatchKeys.add(rowKey);
            _savedBatchCounts[rowKey] = pi.batchAllocations.length;
            _savedBatchData[rowKey] = pi.batchAllocations.map((ba) {
              final batchNo = ba['batch_no']?.toString() ?? '';
              final binCode = ba['bin_code']?.toString() ?? '';
              final qtyOut =
                  ba['qty']?.toString() ?? ba['qty_picked']?.toString() ?? '0';
              final expiryDate = ba['expiry_date']?.toString() ?? '';
              return {
                'batchId': ba['batch_id']?.toString() ?? '',
                'batchNo': batchNo,
                'batchRef': batchNo,
                'qtyOut': qtyOut,
                'binId': ba['bin_id']?.toString() ?? '',
                'binCode': binCode,
                'binLocation': binCode,
                'expiryDate': expiryDate,
                'expDate': expiryDate,
                'layerId': ba['layer_id']?.toString() ?? '',
                'unitPack': ba['unit_pack']?.toString() ?? '',
                'mrp': ba['mrp']?.toString() ?? '',
                'ptr': ba['ptr']?.toString() ?? '',
                'mfgDate': ba['mfg_date']?.toString() ?? '',
                'mfgBatch': ba['mfg_batch']?.toString() ?? '',
                'foc': ba['foc']?.toString() ?? '0',
              };
            }).toList();
          }

          return stockData;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading picklist data: $e');
    }
  }

  String _buildRowKey(WarehouseStockData item) {
    return '${item.productId}_${item.batchNo ?? ''}_${item.salesOrderId ?? ''}';
  }

  double _currentPickedQty(WarehouseStockData item) {
    final rowKey = _buildRowKey(item);
    final idx = _selectedItems.indexWhere((e) => _buildRowKey(e) == rowKey);
    if (idx == -1) return item.quantityPicked ?? 0;
    return _selectedItems[idx].quantityPicked ?? 0;
  }


  double _getPickedQtyOutOnly(WarehouseStockData item) {
    final rowKey = _buildRowKey(item);
    if (_savedBatchKeys.contains(rowKey)) {
      final batches = _savedBatchData[rowKey];
      if (batches != null && batches.isNotEmpty) {
        double totalQty = 0;
        for (final b in batches) {
          totalQty += double.tryParse(b['qtyOut']?.toString() ?? '0') ?? 0;
        }
        return totalQty;
      }
    }
    return _currentPickedQty(item);
  }

  String _buildBatchSummaryText(WarehouseStockData item) {
    final rowKey = _buildRowKey(item);
    return '${_currentPickedQty(item).toInt()} pcs taken from\n${_savedBatchCounts[rowKey] ?? 1} ${(_savedBatchCounts[rowKey] ?? 1) == 1 ? "batch" : "batches"}.';
  }

  Future<void> _showSelectBatchesDialog(WarehouseStockData item) async {
    final result = await showDialog<_PicklistBatchDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PicklistSelectBatchesDialog(
        itemName: item.productName,
        productId: item.productId,
        warehouseName: _selectedWarehouse?.name ?? '',
        warehouseId: _selectedWarehouse?.id ?? '',
        branchId: _selectedWarehouse?.branchId,
        totalQuantity: _getPickedQtyOutOnly(item),
        savedBatchData: _savedBatchData[_buildRowKey(item)],
      ),
    );
    if (!mounted || result == null) return;
    final rowKey = _buildRowKey(item);
    setState(() {
      _savedBatchKeys.add(rowKey);
      _savedBatchCounts[rowKey] = result.batchCount;
      _savedBatchData[rowKey] = result.batchDataList ?? [];
      final idx = _selectedItems.indexWhere((e) => _buildRowKey(e) == rowKey);
      if (idx != -1) {
        _selectedItems[idx] = _selectedItems[idx].copyWith(
          quantityPicked: result.totalIncludingFoc,
        );
      }
      if (result.overwriteLineItem) {
        _qtyPickedOverrideKeys.add(rowKey);
      } else {
        _qtyPickedOverrideKeys.remove(rowKey);
      }
    });
  }

  Widget _buildQuantityField({
    required String fieldKey,
    required double initialValue,
    required ValueChanged<String> onChanged,
    bool isRed = false,
    bool isBlue = false,
    bool hasError = false,
    bool readOnly = false,
  }) {
    final showBlueOutline =
        _hoveredQtyFieldKeys.contains(fieldKey) ||
        _focusedQtyFieldKeys.contains(fieldKey);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredQtyFieldKeys.add(fieldKey)),
      onExit: (_) => setState(() => _hoveredQtyFieldKeys.remove(fieldKey)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 80,
        height: 32,
        decoration: BoxDecoration(
          color: (hasError || showBlueOutline)
              ? Colors.white
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isRed
                ? _dangerRed
                : (isBlue
                      ? _focusBorder
                      : (showBlueOutline ? _focusBorder : Colors.transparent)),
            width: (isRed || isBlue || showBlueOutline) ? 1.2 : 0,
          ),
        ),

        child: Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              if (hasFocus) {
                _focusedQtyFieldKeys.add(fieldKey);
              } else {
                _focusedQtyFieldKeys.remove(fieldKey);
              }
            });
          },
          child: TextField(
            textAlign: TextAlign.right,
            textAlignVertical: TextAlignVertical.center,
            strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
            style: const TextStyle(
              fontSize: 13,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            readOnly: readOnly,
            decoration: InputDecoration(
              isDense: false,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
              constraints: const BoxConstraints(minHeight: 32, maxHeight: 32),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              hintText: '0',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            controller: TextEditingController(
              text: initialValue == 0 ? '' : initialValue.toInt().toString(),
            )..selection = TextSelection.collapsed(
                offset: initialValue == 0
                    ? 0
                    : initialValue.toInt().toString().length,
              ),
            onChanged: onChanged,
            onSubmitted: onChanged,
          ),
        ),
      ),
    );
  }

  String _formatPicklistDateValue(String value) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(value));
    } catch (_) {
      return value;
    }
  }

  Future<Map<String, dynamic>> _buildPicklistPayload() async {
    final bins = await ref.read(binsLookupProvider.future);
    final binsByCode = <String, Map<String, String>>{};
    for (final bin in bins) {
      final code = bin['bin_code']?.trim() ?? '';
      if (code.isNotEmpty && !binsByCode.containsKey(code)) {
        binsByCode[code] = bin;
      }
    }

    final uniqueProductIds = _selectedItems.map((item) => item.productId).toSet();
    final batchesByProductId = <String, Map<String, Map<String, dynamic>>>{};
    for (final productId in uniqueProductIds) {
      if (productId.isEmpty) continue;
      final batches = await ref.read(batchLookupProvider(productId).future);
      final batchMapByNo = <String, Map<String, dynamic>>{};
      for (final batch in batches) {
        final batchNo = batch['batch_no']?.toString().trim() ?? '';
        if (batchNo.isNotEmpty && !batchMapByNo.containsKey(batchNo)) {
          batchMapByNo[batchNo] = batch;
        }
      }
      batchesByProductId[productId] = batchMapByNo;
    }

    final items = <Map<String, dynamic>>[];
    for (final item in _selectedItems) {
      final rowKey = _buildRowKey(item);
      final batchRows = _savedBatchData[rowKey] ?? const <Map<String, String>>[];
      final batchLookup = batchesByProductId[item.productId] ?? const <String, Map<String, dynamic>>{};

      final batchAllocations = <Map<String, dynamic>>[];
      for (final row in batchRows) {
        final batchNo = row['batchNo']?.trim() ?? '';
        final binCode = row['binLocation']?.trim() ?? '';
        final batch = batchLookup[batchNo];
        final bin = binsByCode[binCode];

        if (batch == null) {
          throw StateError('Batch $batchNo could not be resolved for ${item.productName}.');
        }
        if (bin == null) {
          throw StateError('Bin $binCode could not be resolved for ${item.productName}.');
        }

        final prices = batch['prices'] as List<dynamic>? ?? const [];
        final priceMap = prices.isNotEmpty
            ? Map<String, dynamic>.from(prices.first as Map)
            : <String, dynamic>{};

        batchAllocations.add({
          'batch_id': batch['id'],
          'layer_id': batch['layer_id'] ?? priceMap['layer_id'],
          'warehouse_id': _selectedWarehouse!.id,
          'bin_id': bin['id'],
          'qty': double.tryParse(row['qtyOut'] ?? '') ?? 0,
          'foc_qty': double.tryParse(row['foc'] ?? '') ?? 0,
        });
      }

      final qtyPicked = _currentPickedQty(item);
      if (qtyPicked > 0 && batchAllocations.isEmpty) {
        throw Exception('Please allocate batch and bin for ${item.productName} (Qty Picked: $qtyPicked)');
      }

      items.add({
        'product_id': item.productId,
        'sales_order_id': item.salesOrderId,
        'sales_order_line_id': item.salesOrderLineId,
        'qty_ordered': item.quantityOrdered ?? 0,
        'qty_to_pick': item.quantityToPick ?? 0,
        'qty_picked': qtyPicked,
        'batch_allocations': batchAllocations,
      });
    }

    return {
      'picklist_no': _picklistNumberCtrl.text.trim(),
      'warehouse_id': _selectedWarehouse!.id,
      'assignee_id': _selectedAssignee,
      'picklist_date': _formatPicklistDateValue(_dateCtrl.text.trim()),
      'status': _currentStatus ?? 'DRAFT',
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'items': items,
    };
  }

  Future<void> _savePicklist() async {
    final repository = ref.read(inventoryPicklistRepositoryProvider);

    try {
      final payload = await _buildPicklistPayload();
      final dynamic result = await repository.updatePicklist(widget.id, payload);

      if (!mounted) return;
      setState(() => _isSaving = false);

      final displayNum = result is Picklist ? result.picklistNumber : (result['picklist_no'] ?? '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            displayNum.toString().isNotEmpty
                ? 'Picklist $displayNum updated successfully'
                : 'Picklist updated successfully',
          ),
          backgroundColor: _greenBtn,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update picklist: $errorMessage'),
          backgroundColor: _dangerRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _picklistNumberCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      footer: _buildStickyFooter(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_validationErrors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _validationErrors
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 8, top: 2),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormRow(
                  label: 'Picklist#',
                  isRequired: true,
                  child: SizedBox(
                    width: 350,
                    child: CustomTextField(
                      controller: _picklistNumberCtrl,
                      height: 36,
                      readOnly: true,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildFormRow(
                  label: 'Date',
                  isRequired: false,
                  child: SizedBox(
                    width: 350,
                    child: CustomTextField(
                      controller: _dateCtrl,
                      height: 32,
                      readOnly: true,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildFormRow(
                  label: 'Group',
                  isRequired: true,
                  child: SizedBox(
                    width: 350,
                    child: FormDropdown<String>(
                      enabled: false,
                      height: 32,
                      value: _selectedGroup,
                      items: const [
                        'No Grouping',
                      ],
                      hint: 'No Grouping',
                      showSearch: false,
                      displayStringForValue: (s) => s,
                      searchStringForValue: (s) => s,
                      onChanged: (val) {},
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildFormRow(
                  label: 'Assignee',
                  isRequired: false,
                  child: SizedBox(
                    width: 350,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final usersAsync = ref.watch(allUsersProvider);
                        return FormDropdown<User>(
                          enabled: false,
                          height: 32,
                          hint: 'Select User',
                          value: usersAsync.maybeWhen(
                            data: (users) => users
                                .where((u) => u.id == _selectedAssignee)
                                .firstOrNull,
                            orElse: () => null,
                          ),
                          items: usersAsync.maybeWhen(
                            data: (users) => users,
                            orElse: () => [],
                          ),
                          onChanged: (val) {},
                          displayStringForValue: (user) => user.fullName,
                          searchStringForValue: (user) => user.fullName,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildFormRow(
                  label: 'Location Name',
                  isRequired: true,
                  child: SizedBox(
                    width: 350,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final warehousesAsync = ref.watch(warehousesProvider);

                        return warehousesAsync.when(
                          data: (warehouses) => FormDropdown<Warehouse>(
                            enabled: false,
                            height: 32,
                            value: _selectedWarehouse,
                            items: warehouses,
                            onChanged: (val) {},
                            displayStringForValue: (w) => w.name,
                            searchStringForValue: (w) => w.name,
                          ),
                          loading: () => const Skeleton(height: 32, width: 350),
                          error: (err, stack) => Text('Error: $err'),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildNotesSection(),

                const SizedBox(height: 40),

                _buildItemSelectionArea(),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.clipboardCheck, size: 24, color: _textPrimary),
          const SizedBox(width: 12),
          const Text(
            'Update Picklist',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.x, size: 20, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(
                      color: _dangerRed,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildItemSelectionArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedItems.isNotEmpty)
          SizedBox(
            width:
                MediaQuery.of(context).size.width *
                (_createTableWidthFactor * (1 + _updateExtraSalesOrderColumnFactor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {}, // Scan item placeholder
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.scan, size: 16, color: _focusBorder),
                        const SizedBox(width: 6),
                        const Text(
                          'Scan Item',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _focusBorder,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSelectedItemsTable(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedItemsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderCol),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          IntrinsicHeight(
            child: Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 0,
                top: 10,
                bottom: 10,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(bottom: BorderSide(color: _borderCol)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text(
                        'ITEM DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ),
                  VerticalDivider(width: 1, color: _borderCol),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          'SALES ORDER#',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  VerticalDivider(width: 1, color: _borderCol),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'QUANTITY ORDERED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  VerticalDivider(width: 1, color: _borderCol),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'QUANTITY PACKED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  VerticalDivider(width: 1, color: _borderCol),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'QUANTITY TO PICK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          ZTooltip(
                            message:
                                "The quantity that has to be picked for an item from the location. This shouldn't exceed the ordered quantity.",
                            child: Icon(
                              LucideIcons.info,
                              size: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(width: 1, color: _borderCol),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'QUANTITY PICKED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              ZTooltip(
                                message:
                                    "The quantity that has been picked for an item from the location. This shouldn't exceed the quantity to pick.",
                                child: Icon(
                                  LucideIcons.info,
                                  size: 12,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                for (int i = 0; i < _selectedItems.length; i++) {
                                  final item = _selectedItems[i];
                                  _selectedItems[i] = item.copyWith(
                                    quantityPicked: item.quantityToPick ?? 0,
                                  );
                                }
                              });
                            },
                            child: const Text(
                              'PICK ALL ITEMS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Rows
          ..._selectedItems.map((item) {
            final rowKey = _buildRowKey(item);
            return IntrinsicHeight(
              child: Container(
                padding: const EdgeInsets.only(left: 16, right: 0),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _borderCol)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12, right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.productName,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                            if (item.productCode.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(item.productCode,
                                  style: const TextStyle(
                                      fontSize: 11, color: _textSecondary)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: _borderCol),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Center(
                          child: Text(
                            item.salesOrderNumber ?? '--',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: _borderCol),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          item.quantityOrdered?.toInt().toString() ?? '0',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: _borderCol),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          item.quantityPacked.toInt().toString(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: _borderCol),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.quantityToPick?.toInt().toString() ?? '0',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available To Pick:\n${item.stock.toInt()} pcs',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: item.stock >= (item.quantityToPick ?? 0)
                                  ? _textSecondary
                                  : _dangerRed,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1, color: _borderCol),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuantityField(
                            fieldKey: '${rowKey}_picked_update',
                            initialValue: _currentPickedQty(item),
                            onChanged: (val) {
                              final d = double.tryParse(val) ?? 0.0;
                              setState(() {
                                final idx = _selectedItems.indexOf(item);
                                if (idx != -1) {
                                  _selectedItems[idx] =
                                      item.copyWith(quantityPicked: d);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _showSelectBatchesDialog(item),
                            child: Text(
                              _currentPickedQty(item) > 0
                                  ? _buildBatchSummaryText(item)
                                  : 'Select Batch',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                color: _focusBorder,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(item.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 130,
                              child: FormDropdown<String>(
                                height: 32,
                                hideBorderDefault: true,
                                fillColor: Colors.transparent,
                                showSearch: false,
                                value: item.status,
                                items: const [
                                  'YET_TO_START',
                                  'IN_PROGRESS',
                                  'COMPLETED',
                                  'ON_HOLD'
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      final idx = _selectedItems.indexOf(item);
                                      if (idx != -1) {
                                        _selectedItems[idx] =
                                            item.copyWith(status: val);
                                      }
                                    });
                                  }
                                },
                                displayStringForValue: (v) =>
                                    v.replaceAll('_', ' '),
                              ),
                            ),
                          ],
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return const Color(0xFF2563EB); // Blue
      case 'ON_HOLD':
        return const Color(0xFFEF4444); // Red
      case 'COMPLETED':
        return const Color(0xFF10B981); // Green
      case 'YET_TO_START':
      default:
        return const Color(0xFF9CA3AF); // Grey
    }
  }

  Widget _buildNotesSection() {
    return _buildFormRow(
      label: 'Internal Notes',
      isRequired: false,
      child: SizedBox(
        width: 350,
        child: TextField(
          controller: _notesCtrl,
          maxLines: 4,
          style: const TextStyle(
            fontSize: 13,
            color: _textPrimary,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _borderCol),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _focusBorder, width: 1.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyFooter() {
    double totalOrdered = 0;
    double totalPicked = 0;
    for (var item in _selectedItems) {
      totalOrdered += item.quantityOrdered ?? 0;
      totalPicked += _currentPickedQty(item);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderCol)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0a000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: (_isSaving || _selectedItems.isEmpty || !_allBatchesAdded)
                ? null
                : _savePicklist,
            style: ElevatedButton.styleFrom(
              backgroundColor: _greenBtn,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              side: const BorderSide(color: _borderCol),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Total Picked Quantity: ${totalPicked.toInt()}/${totalOrdered.toInt()}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _PicklistBatchRowController {
  final TextEditingController binLocationCtrl = TextEditingController();
  final TextEditingController batchRefCtrl = TextEditingController();
  final TextEditingController batchNoCtrl = TextEditingController();
  final TextEditingController unitPackCtrl = TextEditingController();
  final TextEditingController mrpCtrl = TextEditingController();
  final TextEditingController ptrCtrl = TextEditingController();
  final TextEditingController qtyOutCtrl = TextEditingController();
  final TextEditingController focCtrl = TextEditingController();
  final TextEditingController expDateCtrl = TextEditingController();
  final TextEditingController mfgDateCtrl = TextEditingController();
  final TextEditingController mfgBatchCtrl = TextEditingController();
  final GlobalKey expKey = GlobalKey();
  final GlobalKey mfgKey = GlobalKey();
  DateTime? expDate;
  DateTime? mfgDate;

  void dispose() {
    binLocationCtrl.dispose();
    batchRefCtrl.dispose();
    batchNoCtrl.dispose();
    unitPackCtrl.dispose();
    mrpCtrl.dispose();
    ptrCtrl.dispose();
    qtyOutCtrl.dispose();
    focCtrl.dispose();
    expDateCtrl.dispose();
    mfgDateCtrl.dispose();
    mfgBatchCtrl.dispose();
  }
}

class _PicklistBatchDialogResult {
  final bool overwriteLineItem;
  final int batchCount;
  final double appliedQuantity;
  final double totalIncludingFoc;
  final List<Map<String, String>>? batchDataList;

  const _PicklistBatchDialogResult({
    required this.overwriteLineItem,
    required this.batchCount,
    required this.appliedQuantity,
    required this.totalIncludingFoc,
    this.batchDataList,
  });
}

class _PicklistSelectBatchesDialog extends ConsumerStatefulWidget {
  final String itemName;
  final String productId;
  final String warehouseName;
  final String warehouseId;
  final String? branchId;
  final double totalQuantity;
  final List<Map<String, String>>? savedBatchData;

  _PicklistSelectBatchesDialog({
    required this.itemName,
    required this.productId,
    required this.warehouseName,
    required this.warehouseId,
    this.branchId,
    required this.totalQuantity,
    this.savedBatchData,
  });

  @override
  ConsumerState<_PicklistSelectBatchesDialog> createState() =>
      _PicklistSelectBatchesDialogState();
}

class _PicklistSelectBatchesDialogState
    extends ConsumerState<_PicklistSelectBatchesDialog> {
  static const double _batchDropdownHeight = 38;
  static const double _batchTextFieldHeight = 38;
  final List<_PicklistBatchRowController> _rows = [];
  final Set<int> _hoveredFocRows = <int>{};
  final Set<int> _hoveredBatchRows = <int>{};
  List<String> _binLocations = [];
  bool _overwriteLineItem = false;
  bool _showMfgDetails = false;
  bool _showFocColumn = false;
  String? _dialogErrorMessage;
  static const String _quantityMismatchMessage =
      'There\'s a mismatch between the quantity entered in the line item and the total quantity across all batches. Click the checkbox to overwrite the quantity in the line item.';

  String _normalizeDateForUi(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    try {
      if (value.contains('-') && value.length >= 10) {
        final parsed = DateTime.tryParse(value.substring(0, 10));
        if (parsed != null) {
          return DateFormat('dd-MM-yyyy').format(parsed);
        }
      }
      return DateFormat('dd-MM-yyyy')
          .format(DateFormat('dd-MM-yyyy').parse(value));
    } catch (_) {
      return value;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBins();
    if (widget.savedBatchData != null && widget.savedBatchData!.isNotEmpty) {
      for (var batchData in widget.savedBatchData!) {
        final row = _PicklistBatchRowController();
        row.binLocationCtrl.text =
            batchData['binLocation'] ?? batchData['binCode'] ?? '';
        row.batchRefCtrl.text =
            batchData['batchRef'] ?? batchData['batchNo'] ?? '';
        row.batchNoCtrl.text =
            batchData['batchNo'] ?? batchData['batchRef'] ?? '';
        row.unitPackCtrl.text = batchData['unitPack'] ?? '';
        row.mrpCtrl.text = batchData['mrp'] ?? '';
        row.ptrCtrl.text = batchData['ptr'] ?? '';
        row.expDateCtrl.text = _normalizeDateForUi(
          batchData['expDate'] ?? batchData['expiryDate'] ?? '',
        );
        if (row.expDateCtrl.text.isNotEmpty) {
          try {
            row.expDate = DateFormat('dd-MM-yyyy').parse(row.expDateCtrl.text);
          } catch (_) {}
        }
        row.mfgDateCtrl.text = _normalizeDateForUi(batchData['mfgDate'] ?? '');
        if (row.mfgDateCtrl.text.isNotEmpty) {
          try {
            row.mfgDate = DateFormat('dd-MM-yyyy').parse(row.mfgDateCtrl.text);
          } catch (_) {}
        }
        row.mfgBatchCtrl.text = batchData['mfgBatch'] ?? '';
        row.qtyOutCtrl.text =
            batchData['qtyOut'] ?? widget.totalQuantity.toInt().toString();
        row.focCtrl.text = batchData['foc'] ?? '';

        // Preserve checkbox visibility states based on filled data
        if (row.focCtrl.text.isNotEmpty &&
            (double.tryParse(row.focCtrl.text) ?? 0) > 0) {
          _showFocColumn = true;
        }
        if (row.mfgDateCtrl.text.isNotEmpty ||
            row.mfgBatchCtrl.text.isNotEmpty) {
          _showMfgDetails = true;
        }

        _rows.add(row);
      }
    } else {
      final firstRow = _PicklistBatchRowController();
      firstRow.qtyOutCtrl.text = widget.totalQuantity.toInt().toString();
      _rows.add(firstRow);
    }
  }

  Future<void> _loadBins() async {
    try {
      final repository = ref.read(inventoryPicklistRepositoryProvider);
      final bins = await repository.getWarehouseBins(warehouseId: widget.warehouseId);
      if (mounted) {
        setState(() {
          _binLocations = bins.map((b) => b['binCode'] ?? '').where((c) => c.isNotEmpty).toList();
        });
      }
    } catch (_) {
      // Error handling
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  double get _totalQuantityOnlyOut => _rows.fold<double>(
    0,
    (sum, r) => sum + (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0),
  );

  double get _totalAppliedIncludingFoc => _rows.fold<double>(
    0,
    (sum, r) =>
        sum +
        (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0) +
        (double.tryParse(r.focCtrl.text.trim()) ?? 0),
  );

  double get _quantityToBeAdded =>
      (widget.totalQuantity - _totalQuantityOnlyOut).clamp(
        0,
        widget.totalQuantity,
      );

  bool get _hasQuantityMismatch =>
      (_totalQuantityOnlyOut - widget.totalQuantity).abs() > 0.0001;

  int get _batchCount {
    final refs = _rows
        .where((r) => (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0) > 0)
        .map((r) => r.batchRefCtrl.text.trim())
        .where((ref) => ref.isNotEmpty)
        .toSet();
    return refs.length;
  }

  void _addRow() {
    setState(() {
      _rows.add(_PicklistBatchRowController());
    });
  }

  void _removeRow(int index) {
    setState(() {
      if (_rows.length == 1) {
        _rows[index].batchRefCtrl.clear();
        _rows[index].qtyOutCtrl.clear();
      } else {
        _rows[index].dispose();
        _rows.removeAt(index);
      }
    });
  }

  Widget _headerCell(
    String text,
    int flex, {
    TextAlign alignment = TextAlign.center,
  }) {
    final isRequired = text.contains('*');
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          textAlign: alignment,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isRequired ? const Color(0xFFD32F2F) : _textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required int flex,
    required String hint,
    bool isNumber = false,
    bool readOnly = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : null,
            inputFormatters: isNumber
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : [],
            textAlign: isNumber ? TextAlign.right : TextAlign.left,
            textAlignVertical: TextAlignVertical.center,
            strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
            style: TextStyle(
              fontSize: 13,
              color: readOnly ? _textSecondary : _textPrimary,
              fontFamily: 'Inter',
            ),
            onChanged: (_) => setState(() {
              _dialogErrorMessage = null;
            }),
            decoration: InputDecoration(
              isDense: false,
              hintText: hint,
              hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
              filled: true,
              fillColor: readOnly ? const Color(0xFFF9FAFB) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              constraints: const BoxConstraints(
                minHeight: _batchTextFieldHeight,
                maxHeight: _batchTextFieldHeight,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? const Color(0xFFE5E7EB) : _borderCol,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? const Color(0xFFE5E7EB) : _focusBorder,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required TextEditingController controller,
    required GlobalKey anchorKey,
    required int flex,
    required DateTime? currentDate,
    required ValueChanged<DateTime?> onDateChanged,
    bool readOnly = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: _batchTextFieldHeight,
          child: TextField(
            key: anchorKey,
            controller: controller,
            readOnly: true,
            textAlignVertical: TextAlignVertical.center,
            strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
            style: TextStyle(
              fontSize: 13,
              color: readOnly ? _textSecondary : _textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              isDense: false,
              hintText: '',
              hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
              filled: true,
              fillColor: readOnly ? const Color(0xFFF9FAFB) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              constraints: const BoxConstraints(
                minHeight: _batchTextFieldHeight,
                maxHeight: _batchTextFieldHeight,
              ),
              suffixIcon: Icon(
                LucideIcons.calendar,
                size: 14,
                color: readOnly ? const Color(0xFFD1D5DB) : _textSecondary,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 32,
                maxWidth: 32,
                minHeight: _batchTextFieldHeight,
                maxHeight: _batchTextFieldHeight,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? const Color(0xFFE5E7EB) : _borderCol,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? const Color(0xFFE5E7EB) : _focusBorder,
                  width: 1.4,
                ),
              ),
            ),
            onTap: () async {
              if (readOnly)
                return; // Don't show date picker if field is read-only
              final picked = await ZerpaiDatePicker.show(
                context,
                initialDate: currentDate ?? DateTime.now(),
                targetKey: anchorKey,
              );
              if (picked != null) {
                onDateChanged(picked);
                controller.text = DateFormat('dd-MM-yyyy').format(picked);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFocInput(_PicklistBatchRowController row, int index) {
    final isHovered = _hoveredFocRows.contains(index);
    return Expanded(
      flex: 15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredFocRows.add(index)),
          onExit: (_) => setState(() => _hoveredFocRows.remove(index)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: _batchTextFieldHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isHovered ? _focusBorder : _borderCol,
                width: isHovered ? 1.4 : 1,
              ),
            ),
            child: TextField(
              controller: row.focCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.right,
              textAlignVertical: TextAlignVertical.center,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
              style: const TextStyle(
                fontSize: 13,
                color: _textPrimary,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                isDense: false,
                hintText: '0',
                hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                constraints: const BoxConstraints(
                  minHeight: _batchTextFieldHeight,
                  maxHeight: _batchTextFieldHeight,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {
                _dialogErrorMessage = null;
              }),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: SizedBox(
        width: _showMfgDetails
            ? (_showFocColumn ? 1480 : 1320)
            : (_showFocColumn ? 1320 : 1160),
        height: MediaQuery.of(context).size.height * 0.86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Select Batches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: _dangerRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderCol),
            if (_dialogErrorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF9D3D3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        child: Text(
                          '•',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                           _dialogErrorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textPrimary,
                            fontFamily: 'Inter',
                            height: 1.35,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _dialogErrorMessage = null),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: _dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  const Icon(LucideIcons.home, size: 16, color: _textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Location : ${widget.warehouseName.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'BATCH DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      'Item: ${widget.itemName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Total Quantity : ${widget.totalQuantity.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('|', style: TextStyle(color: _textSecondary)),
                  const SizedBox(width: 8),
                  Text(
                    'Quantity to be added : ${_quantityToBeAdded.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: _showMfgDetails,
                      onChanged: (val) =>
                          setState(() => _showMfgDetails = val ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: _greenBtn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Manufacture Details',
                    style: TextStyle(fontSize: 13, color: _textPrimary),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: _showFocColumn,
                      onChanged: (val) =>
                          setState(() => _showFocColumn = val ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: _greenBtn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FOC',
                    style: TextStyle(fontSize: 13, color: _textPrimary),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: _overwriteLineItem,
                      onChanged: (val) => setState(() {
                        _overwriteLineItem = val ?? false;
                        _dialogErrorMessage = null;
                      }),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: _greenBtn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overwrite the line item with ${_totalQuantityOnlyOut.toInt()} quantities',
                    style: const TextStyle(fontSize: 13, color: _textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _borderCol),
            const SizedBox(height: 8),
            // ── Table header ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(bottom: BorderSide(color: _borderCol)),
              ),
              child: Row(
                children: [
                  _headerCell('BIN LOCATION*', 15),
                  _headerCell('BATCH NO*', 15),
                  _headerCell('UNIT PACK*', 15),
                  _headerCell('MRP*', 15),
                  _headerCell('PTR', 15),
                  _headerCell('EXPIRY DATE*', 15),
                  if (_showMfgDetails) ...[
                    _headerCell('MANUFACTURED DATE', 15),
                    _headerCell('MANUFACTURER BATCH', 15),
                  ],
                  _headerCell('QUANTITY OUT*', 15),
                  if (_showFocColumn) _headerCell('FOC', 15),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            // ── Batch rows ──
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.28,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 0,
                ),
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  final isRowHovered = _hoveredBatchRows.contains(index);
                  return Column(
                    children: [
                      MouseRegion(
                        onEnter: (_) => setState(() => _hoveredBatchRows.add(index)),
                        onExit: (_) => setState(() => _hoveredBatchRows.remove(index)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Expanded(
                              flex: 15,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: _BinHoverBox(
                                  isEnabled: row.binLocationCtrl.text.isNotEmpty,
                                  message: row.binLocationCtrl.text,
                                  child: SizedBox(
                                    height: _batchDropdownHeight,
                                    child: FormDropdown<String>(
                                      height: _batchDropdownHeight,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _borderCol),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      value:
                                          _binLocations.contains(
                                            row.binLocationCtrl.text.trim(),
                                          )
                                          ? row.binLocationCtrl.text.trim()
                                          : null,
                                      items: _binLocations,
                                      hint: 'Select Bin',
                                      showSearch: true,
                                      maxVisibleItems: 4,
                                      menuMaxHeight: 220,
                                      displayStringForValue: (v) => v,
                                      searchStringForValue: (v) => v,
                                      itemBuilder:
                                          (
                                            item,
                                            isSelected,
                                            isHovered,
                                          ) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            color: isHovered
                                                ? const Color(0xFF3B82F6)
                                                : (isSelected
                                                      ? const Color(0xFFF3F4F6)
                                                      : Colors.transparent),
                                            child: Text(
                                              item,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isHovered
                                                    ? Colors.white
                                                    : (isSelected
                                                          ? const Color(
                                                              0xFF1F2937,
                                                            )
                                                          : const Color(
                                                              0xFF1F2937,
                                                            )),
                                              ),
                                            ),
                                          ),
                                      onChanged: (val) {
                                        setState(() {
                                          row.binLocationCtrl.text = val ?? '';
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Batch No — FormDropdown from batch_master
                            Expanded(
                              flex: 15,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: SizedBox(
                                  height: _batchDropdownHeight,
                                  child: Consumer(
                                    builder: (context, ref, _) {
                                      final batchesAsync = ref.watch(
                                        batchLookupProvider(widget.productId),
                                      );
                                      final batches = batchesAsync.value ?? [];

                                      return FormDropdown<Map<String, dynamic>>(
                                        height: _batchDropdownHeight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: _borderCol),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        value:
                                            batches
                                                .firstWhere(
                                                  (b) =>
                                                      b['batch_no']
                                                          ?.toString()
                                                          .trim() ==
                                                      row.batchRefCtrl.text
                                                          .trim(),
                                                  orElse: () =>
                                                      <String, dynamic>{},
                                                )
                                                .isEmpty
                                            ? null
                                            : batches.firstWhere(
                                                (b) =>
                                                    b['batch_no']
                                                        ?.toString()
                                                        .trim() ==
                                                    row.batchRefCtrl.text
                                                        .trim(),
                                              ),
                                        items: batches,
                                        hint: 'Select Batch',
                                        showSearch: true,
                                        displayStringForValue: (v) =>
                                            v['batch_no']?.toString() ?? '',
                                        searchStringForValue: (v) =>
                                            v['batch_no']?.toString() ?? '',
                                        onChanged: (v) {
                                          setState(() {
                                            if (v != null) {
                                              final batchNo = v['batch_no']
                                                  ?.toString()
                                                  .trim();
                                              row.batchRefCtrl.text =
                                                  batchNo ?? '';
                                              row.batchNoCtrl.text =
                                                  batchNo ?? '';

                                              // Auto-fill details from selected batch map
                                              row.unitPackCtrl.text =
                                                  v['unit_pack']?.toString() ??
                                                  '';
                                              row.expDateCtrl.text =
                                                  v['expiry_date']
                                                      ?.toString() ??
                                                  '';

                                              final prices =
                                                  v['prices'] as List?;
                                              if (prices != null &&
                                                  prices.isNotEmpty) {
                                                final p = prices[0];
                                                row.mrpCtrl.text =
                                                    (p['mrp'] as num?)
                                                        ?.toDouble()
                                                        .toStringAsFixed(2) ??
                                                    '0.00';
                                                row.ptrCtrl.text =
                                                    (p['ptr'] as num?)
                                                        ?.toDouble()
                                                        .toStringAsFixed(2) ??
                                                    '0.00';
                                              }
                                            }
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            _buildInput(
                              controller: row.unitPackCtrl,
                              flex: 15,
                              hint: 'Pack',
                              isNumber: true,
                              readOnly: true,
                            ),
                            _buildInput(
                              controller: row.mrpCtrl,
                              flex: 15,
                              hint: '0',
                              isNumber: true,
                              readOnly: true,
                            ),
                            _buildInput(
                              controller: row.ptrCtrl,
                              flex: 15,
                              hint: '0',
                              isNumber: true,
                              readOnly: true,
                            ),
                            _buildDatePicker(
                              controller: row.expDateCtrl,
                              anchorKey: row.expKey,
                              flex: 15,
                              currentDate: row.expDate,
                              onDateChanged: (d) =>
                                  setState(() => row.expDate = d),
                              readOnly: true,
                            ),
                            if (_showMfgDetails) ...[
                              _buildDatePicker(
                                controller: row.mfgDateCtrl,
                                anchorKey: row.mfgKey,
                                flex: 15,
                                currentDate: row.mfgDate,
                                onDateChanged: (d) =>
                                    setState(() => row.mfgDate = d),
                                readOnly: true,
                              ),
                              _buildInput(
                                controller: row.mfgBatchCtrl,
                                flex: 15,
                                hint: 'Mfg Batch',
                                readOnly: true,
                              ),
                            ],
                            _buildInput(
                              controller: row.qtyOutCtrl,
                              flex: 15,
                              hint: '0',
                              isNumber: true,
                            ),
                            if (_showFocColumn) _buildFocInput(row, index),
                              SizedBox(
                                width: 24,
                                child: AnimatedOpacity(
                                  opacity: isRowHovered ? 1 : 0,
                                  duration: const Duration(milliseconds: 120),
                                  child: IconButton(
                                    onPressed: () => _removeRow(index),
                                    tooltip: 'Remove row',
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      LucideIcons.x,
                                      size: 15,
                                      color: _dangerRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < _rows.length - 1)
                        const Divider(height: 1, color: _borderCol),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: _addRow,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.plusCircle,
                          size: 14,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'New Row',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Batches added: ${_rows.length}/100',
                    style: const TextStyle(fontSize: 13, color: _textPrimary),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Divider(height: 1, color: _borderCol),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      for (var i = 0; i < _rows.length; i++) {
                        final row = _rows[i];
                        if (row.binLocationCtrl.text.isEmpty) {
                          setState(() {
                            _dialogErrorMessage =
                                'Please select Bin Location in Row ${i + 1}.';
                          });
                          return;
                        }
                        if (row.batchRefCtrl.text.isEmpty) {
                          setState(() {
                            _dialogErrorMessage =
                                'Please select Batch Reference in Row ${i + 1}.';
                          });
                          return;
                        }
                        if (row.batchNoCtrl.text.isEmpty) {
                          setState(() {
                            _dialogErrorMessage =
                                'Please enter Batch No in Row ${i + 1}.';
                          });
                          return;
                        }
                        if (row.unitPackCtrl.text.isEmpty) {
                          setState(() {
                            _dialogErrorMessage =
                                'Please enter Unit Pack in Row ${i + 1}.';
                          });
                          return;
                        }
                        if (row.mrpCtrl.text.isEmpty) {
                          setState(() {
                            _dialogErrorMessage =
                                'Please enter MRP in Row ${i + 1}.';
                          });
                          return;
                        }
                        if (row.expDateCtrl.text.isEmpty) {
                          setState(() {
                            _dialogErrorMessage =
                                'Please select Expiry Date in Row ${i + 1}.';
                          });
                          return;
                        }
                      }

                      if (_hasQuantityMismatch && !_overwriteLineItem) {
                        setState(() {
                          _dialogErrorMessage = _quantityMismatchMessage;
                        });
                        return;
                      }

                      final batchDataList = _rows
                          .map(
                            (row) => {
                              'binLocation': row.binLocationCtrl.text,
                              'batchRef': row.batchRefCtrl.text,
                              'batchNo': row.batchNoCtrl.text,
                              'unitPack': row.unitPackCtrl.text,
                              'mrp': row.mrpCtrl.text,
                              'ptr': row.ptrCtrl.text,
                              'expDate': row.expDateCtrl.text,
                              'mfgDate': row.mfgDateCtrl.text,
                              'mfgBatch': row.mfgBatchCtrl.text,
                              'qtyOut': row.qtyOutCtrl.text,
                              'foc': row.focCtrl.text,
                            },
                          )
                          .toList();

                      Navigator.pop(
                        context,
                        _PicklistBatchDialogResult(
                          overwriteLineItem: _overwriteLineItem,
                          batchCount: _batchCount > 0
                              ? _batchCount
                              : _rows.length,
                          appliedQuantity: _totalQuantityOnlyOut,
                          totalIncludingFoc: _totalAppliedIncludingFoc,
                          batchDataList: batchDataList,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenBtn,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textPrimary,
                      side: const BorderSide(color: _borderCol),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
}

class _BinHoverBox extends StatefulWidget {
  final String message;
  final Widget child;
  final bool isEnabled;

  const _BinHoverBox({
    required this.message,
    required this.child,
    this.isEnabled = true,
  });

  @override
  State<_BinHoverBox> createState() => _BinHoverBoxState();
}

class _BinHoverBoxState extends State<_BinHoverBox> {
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_entry != null || !widget.isEnabled) return;
    _entry = _createOverlayEntry();
    Overlay.of(context).insert(_entry!);
  }

  void _hideOverlay() {
    _entry?.remove();
    _entry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 250),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showOverlay(),
        onExit: (_) => _hideOverlay(),
        child: widget.child,
      ),
    );
  }
}

