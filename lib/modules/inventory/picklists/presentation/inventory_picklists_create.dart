import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/inventory/providers/stock_provider.dart';
import 'package:zerpai_erp/modules/sales/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/items/items/repositories/items_repository_provider.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/modules/auth/providers/user_provider.dart';
import 'package:zerpai_erp/modules/inventory/picklists/providers/inventory_picklists_provider.dart';
import 'package:zerpai_erp/shared/providers/lookup_providers.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

const _textPrimary = Color(0xFF1F2937);
const _textSecondary = Color(0xFF6B7280);
const _borderCol = Color(0xFFE5E7EB);
const _bgWhite = Color(0xFFFFFFFF);
const _focusBorder = Color(0xFF3B82F6);
const _dangerRed = Color(0xFFEF4444);
const _greenBtn = Color(0xFF22A95E);

class InventoryPicklistsCreateScreen extends ConsumerStatefulWidget {
  const InventoryPicklistsCreateScreen({super.key});

  @override
  ConsumerState<InventoryPicklistsCreateScreen> createState() =>
      _InventoryPicklistsCreateScreenState();
}

class _InventoryPicklistsCreateScreenState
    extends ConsumerState<InventoryPicklistsCreateScreen> {
  final _picklistNumberCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _itemNameSearchCtrl = TextEditingController();
  final _salesOrderSearchCtrl = TextEditingController();
  String _itemNameSearchQuery = '';
  String _salesOrderSearchQuery = '';
  bool _salesOrderSortAscending = true;
  bool _isItemSearchVisible = false;
  bool _isSOSearchVisible = false;

  List<WarehouseStockData> get _filteredSelectedItems {
    final filtered = _selectedItems.where((item) {
      final name = item.productName.toLowerCase();
      final productCode = item.productCode.toLowerCase();
      final so = (item.salesOrderNumber ?? '').toLowerCase();

      final matchesItem =
          _itemNameSearchQuery.isEmpty ||
          name.contains(_itemNameSearchQuery.toLowerCase()) ||
          productCode.contains(_itemNameSearchQuery.toLowerCase());
      final matchesSO =
          _salesOrderSearchQuery.isEmpty ||
          so.contains(_salesOrderSearchQuery.toLowerCase());

      return matchesItem && matchesSO;
    }).toList();

    filtered.sort((a, b) {
      final aOrder = (a.salesOrderNumber ?? '').trim();
      final bOrder = (b.salesOrderNumber ?? '').trim();
      final cmp = aOrder.compareTo(bOrder);
      return _salesOrderSortAscending ? cmp : -cmp;
    });
    return filtered;
  }

  List<String> _validationErrors = [];

  void _validatePickList() {
    setState(() {
      _validationErrors = [];
      for (var item in _selectedItems) {
        final picked = _getPickedQtyOutOnly(item);
        final toPick = _currentQtyToPick(item);
        final rowKey = _buildRowKey(item);
        final isFocused =
            _focusedQtyFieldKeys.contains('${rowKey}_picked_main') ||
            _focusedQtyFieldKeys.contains('${rowKey}_picked_compact') ||
            _focusedQtyFieldKeys.contains('${rowKey}_picked_mobile');
        final isMatched = (picked - toPick).abs() < 0.0001;
        if (picked > (toPick + 0.0001) &&
            !isFocused &&
            !isMatched &&
            !_savedBatchKeys.contains(rowKey)) {
          _validationErrors.add(
            'Please make sure that you have entered batch reference numbers for all the items.',
          );
        }
      }
    });
  }

  final GlobalKey _dateFieldKey = GlobalKey();

  String? _selectedGroup;
  String? _selectedAssignee;
  Warehouse? _selectedWarehouse;

  bool _isSaving = false;
  List<WarehouseStockData> _selectedItems = [];
  final Set<String> _qtyPickedOverrideKeys = <String>{};
  final Set<String> _savedBatchKeys = <String>{};
  final Map<String, int> _savedBatchCounts = <String, int>{};
  final Set<String> _hoveredQtyFieldKeys = <String>{};
  final Set<String> _focusedQtyFieldKeys = <String>{};

  // Picklist Numbering Preferences
  bool _isAutoGenerate = true;
  String _picklistPrefix = 'PL-';
  int _nextNumber = 1;

  // Batch data persistence
  final Map<String, List<Map<String, String>>> _savedBatchData =
      <String, List<Map<String, String>>>{};

  bool get _isFormValid =>
      _picklistNumberCtrl.text.trim().isNotEmpty &&
      _selectedGroup != null &&
      _selectedWarehouse != null;

  int _currentPage = 0;
  static const int _itemsPerPage = 30;

  bool get _hasMandatoryFieldsForItemSelection =>
      _picklistNumberCtrl.text.trim().isNotEmpty &&
      _selectedGroup != null &&
      _selectedWarehouse != null;

  bool get _allBatchesAdded =>
      _selectedItems.isNotEmpty &&
      _selectedItems.every((item) {
        final qtyPicked = _currentPickedQty(item);
        if (qtyPicked <= 0) return true;
        return _savedBatchKeys.contains(_buildRowKey(item));
      });

  @override
  void initState() {
    super.initState();
    _selectedGroup = 'No Grouping';
    _picklistNumberCtrl.text = _generatePicklistNumber();
    _loadNextPicklistNumber();
    _dateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  Future<void> _loadNextPicklistNumber() async {
    if (!_isAutoGenerate) return;

    try {
      final nextNumberData = await ref.read(nextPicklistNumberProvider.future);
      if (!mounted) return;

      setState(() {
        _picklistPrefix =
            nextNumberData['prefix']?.toString().trim().isNotEmpty == true
            ? nextNumberData['prefix'].toString()
            : 'PL-';
        _nextNumber = nextNumberData['next_number'] as int? ?? 1;
        if (_isAutoGenerate) {
          _picklistNumberCtrl.text =
              nextNumberData['formatted']?.toString().trim().isNotEmpty == true
              ? nextNumberData['formatted'].toString()
              : _generatePicklistNumber();
        }
      });
    } catch (_) {
      // Keep the local default when the backend value cannot be loaded.
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

  double _currentQtyToPick(WarehouseStockData item) {
    final rowKey = _buildRowKey(item);
    final idx = _selectedItems.indexWhere((e) => _buildRowKey(e) == rowKey);
    if (idx == -1) return item.quantityToPick ?? 1;
    return _selectedItems[idx].quantityToPick ?? 1;
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

  String _buildBatchQtyFocText(WarehouseStockData item) {
    final rowKey = _buildRowKey(item);
    final savedData = _savedBatchData[rowKey] ?? [];
    double totalQty = 0;
    double totalFoc = 0;
    for (final b in savedData) {
      totalQty += double.tryParse(b['qtyOut']?.toString() ?? '0') ?? 0;
      totalFoc += double.tryParse(b['foc']?.toString() ?? '0') ?? 0;
    }
    return '${totalQty.toInt()} pcs + ${totalFoc.toInt()} foc';
  }

  String _buildBatchSummaryText(WarehouseStockData item) {
    final rowKey = _buildRowKey(item);
    final savedData = _savedBatchData[rowKey] ?? [];
    double totalQty = 0;
    for (final b in savedData) {
      totalQty += double.tryParse(b['qtyOut']?.toString() ?? '0') ?? 0;
    }
    return '${totalQty.toInt()} pcs taken from\n${_savedBatchCounts[rowKey] ?? 1} ${(_savedBatchCounts[rowKey] ?? 1) == 1 ? "batch" : "batches"}.';
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
            controller:
                TextEditingController(
                    text: initialValue == 0
                        ? ''
                        : initialValue.toInt().toString(),
                  )
                  ..selection = TextSelection.collapsed(
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

  String _generatePicklistNumber() {
    if (!_isAutoGenerate) return _picklistNumberCtrl.text;
    return '$_picklistPrefix${_nextNumber.toString().padLeft(5, '0')}';
  }

  String _formatPicklistDateValue(String value) {
    try {
      return DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd-MM-yyyy').parse(value));
    } catch (_) {
      return value;
    }
  }

  String _computeItemStatus(double qtyPicked, double toPick) {
    if (qtyPicked <= 0) return 'YET_TO_START';
    if (qtyPicked < toPick) return 'IN_PROGRESS';
    return 'COMPLETED';
  }

  String _computePicklistStatus(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 'YET_TO_START';
    final allZero = items.every((i) => ((i['qty_picked'] as num?) ?? 0) <= 0);
    if (allZero) return 'YET_TO_START';
    final allComplete = items.every((i) {
      final picked = ((i['qty_picked'] as num?) ?? 0).toDouble();
      final toPick = ((i['qty_to_pick'] as num?) ?? 0).toDouble();
      return toPick > 0 && picked >= toPick;
    });
    return allComplete ? 'COMPLETED' : 'IN_PROGRESS';
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

    final uniqueProductIds = _selectedItems
        .map((item) => item.productId)
        .toSet();
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
      final batchRows =
          _savedBatchData[rowKey] ?? const <Map<String, String>>[];
      final batchLookup =
          batchesByProductId[item.productId] ??
          const <String, Map<String, dynamic>>{};

      final batchAllocations = <Map<String, dynamic>>[];
      for (final row in batchRows) {
        final batchNo = row['batchNo']?.trim() ?? '';
        final binCode = row['binLocation']?.trim() ?? '';
        final batch = batchLookup[batchNo];
        final bin = binsByCode[binCode];

        if (batch == null) {
          throw StateError(
            'Batch $batchNo could not be resolved for ${item.productName}.',
          );
        }
        if (bin == null) {
          throw StateError(
            'Bin $binCode could not be resolved for ${item.productName}.',
          );
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
        throw Exception(
          'Please allocate batch and bin for ${item.productName} (Qty Picked: $qtyPicked)',
        );
      }

      items.add({
        'product_id': item.productId,
        'sales_order_id': item.salesOrderId,
        'sales_order_line_id': item.salesOrderLineId,
        'qty_ordered': item.quantityOrdered ?? 0,
        'qty_to_pick': item.quantityToPick ?? 0,
        'qty_picked': qtyPicked,
        'status': _computeItemStatus(qtyPicked, item.quantityToPick ?? 0),
        'batch_allocations': batchAllocations,
      });
    }

    return {
      'picklist_no': _picklistNumberCtrl.text.trim(),
      'warehouse_id': _selectedWarehouse!.id,
      'assignee_id': _selectedAssignee,
      'picklist_date': _formatPicklistDateValue(_dateCtrl.text.trim()),
      'status': _computePicklistStatus(items),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'items': items,
    };
  }

  Future<void> _savePicklist() async {
    try {
      final payload = await _buildPicklistPayload();

      final result = await ref
          .read(picklistsProvider.notifier)
          .createPicklist(payload);
      ref.invalidate(nextPicklistNumberProvider);

      if (!mounted) return;
      setState(() => _isSaving = false);

      final displayNum = result?.picklistNumber ?? '';

      ZerpaiToast.success(
        context,
        displayNum.isNotEmpty
            ? 'Picklist $displayNum generated successfully'
            : 'Picklist generated successfully',
      );

      final orgId =
          GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
      context.goNamed(
        AppRoutes.picklists,
        pathParameters: {'orgSystemId': orgId},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      ZerpaiToast.error(context, 'Failed to generate picklist: $errorMessage');
    }
  }

  @override
  void dispose() {
    _picklistNumberCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showPicklistPreferencesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _PicklistPreferencesDialog(
        initialAutoGenerate: _isAutoGenerate,
        initialPrefix: _picklistPrefix,
        initialNextNumber: _nextNumber,
        onSave: (isAuto, prefix, nextNum) {
          setState(() {
            _isAutoGenerate = isAuto;
            _picklistPrefix = prefix;
            _nextNumber = nextNum;
            if (_isAutoGenerate) {
              _picklistNumberCtrl.text = _generatePicklistNumber();
              _loadNextPicklistNumber();
            } else {
              _picklistNumberCtrl.clear();
            }
          });
        },
      ),
    );
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
                      readOnly: _isAutoGenerate,
                      suffixWidget: ZTooltip(
                        message:
                            'Click here to enable or disable auto-generation of numbers.',
                        child: InkWell(
                          onTap: _showPicklistPreferencesDialog,
                          child: const Icon(
                            LucideIcons.settings,
                            size: 16,
                            color: _textSecondary,
                          ),
                        ),
                      ),
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
                      onTap: () async {
                        final picked = await ZerpaiDatePicker.show(
                          context,
                          initialDate: DateTime.now(),
                          targetKey: _dateFieldKey,
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _dateCtrl.text = DateFormat(
                              'dd-MM-yyyy',
                            ).format(picked);
                          });
                        }
                      },
                      suffixWidget: const Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: _textSecondary,
                      ),
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
                      enabled: true,
                      height: 32,
                      value: _selectedGroup,
                      items: const [
                        'No Grouping',
                        'By Item',
                        'By Sales Orders',
                      ],
                      hint: 'No Grouping',
                      showSearch: false,
                      displayStringForValue: (s) => s,
                      searchStringForValue: (s) => s,
                      itemBuilder: (item, isSelected, isHovered) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isHovered
                              ? const Color(0xFF3B82F6)
                              : (isSelected
                                    ? const Color(0xFFF3F4F6)
                                    : Colors.transparent),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Inter',
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                color: isHovered
                                    ? Colors.white
                                    : (isSelected
                                          ? const Color(0xFF1F2937)
                                          : const Color(0xFF1F2937)),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                LucideIcons.check,
                                size: 16,
                                color: isHovered
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                          ],
                        ),
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGroup = val);
                      },
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
                          onChanged: (val) =>
                              setState(() => _selectedAssignee = val?.id),
                          displayStringForValue: (user) => user.fullName,
                          searchStringForValue: (user) => user.fullName,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildFormRow(
                  label: 'Warehouse Name',
                  isRequired: true,
                  child: SizedBox(
                    width: 350,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final warehousesAsync = ref.watch(warehousesProvider);

                        return warehousesAsync.when(
                          data: (warehouses) => FormDropdown<Warehouse>(
                            enabled: true,
                            height: 32,
                            value: _selectedWarehouse,
                            items: warehouses,
                            hint: 'Select or type to search',
                            showSearch: true,
                            maxVisibleItems: 4,
                            displayStringForValue: (w) => w.name,
                            searchStringForValue: (w) => w.name,
                            itemBuilder: (item, isSelected, isHovered) =>
                                Container(
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
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Inter',
                                      color: isHovered
                                          ? Colors.white
                                          : (isSelected
                                                ? const Color(0xFF1F2937)
                                                : const Color(0xFF1F2937)),
                                    ),
                                  ),
                                ),
                            onChanged: (val) {
                              if (val != null &&
                                  val.id != _selectedWarehouse?.id) {
                                setState(() {
                                  _selectedWarehouse = val;
                                  // Reset all selection state when warehouse changes
                                  _selectedItems.clear();
                                  _savedBatchKeys.clear();
                                  _savedBatchCounts.clear();
                                  _savedBatchData.clear();
                                  _qtyPickedOverrideKeys.clear();
                                });
                              }
                            },
                          ),
                          loading: () => const Skeleton(
                            height: 32,
                            width: double.infinity,
                          ),
                          error: (err, stack) => Text(
                            'Error loading warehouses: $err',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildNotesSection(),

                const SizedBox(height: 40),

                Opacity(
                  opacity: _hasMandatoryFieldsForItemSelection ? 1.0 : 0.3,
                  child: IgnorePointer(
                    ignoring: !_hasMandatoryFieldsForItemSelection,
                    child: _buildItemSelectionArea(),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(LucideIcons.clipboardCheck, size: 24, color: _textPrimary),
          const SizedBox(width: 12),
          Text(
            'New Picklist',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          const SizedBox(width: 16),
          InkWell(
            onTap: () {
              final orgId =
                  GoRouterState.of(context).pathParameters['orgSystemId'] ??
                  '0000000000';
              context.goNamed(
                AppRoutes.picklists,
                pathParameters: {'orgSystemId': orgId},
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 20, color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required bool isRequired,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isRequired ? _dangerRed : _textPrimary,
                      fontFamily: 'Inter',
                    ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_selectedItems.isEmpty)
          Container(
            width: 420,
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(color: const Color(0xFFD1D5DB)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Add items to this picklist',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _hasMandatoryFieldsForItemSelection
                          ? _showAddItemsDialog
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasMandatoryFieldsForItemSelection
                            ? const Color(0xFFEAF3FF)
                            : const Color(0xFFF3F4F6),
                        foregroundColor: _hasMandatoryFieldsForItemSelection
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF9CA3AF),
                        side: BorderSide(
                          color: _hasMandatoryFieldsForItemSelection
                              ? const Color(0xFFD6E6FF)
                              : Colors.transparent,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Add Items',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: _buildSelectedItemsTable(),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showAddItemsDialog,
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text(
                  'Add More Items',
                  style: TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(foregroundColor: _focusBorder),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSelectedItemsTable() {
    if (_selectedGroup == 'By Item') {
      return _buildTableByItem();
    } else if (_selectedGroup == 'By Sales Orders') {
      return _buildTableBySalesOrder();
    } else {
      return _buildTableNoGrouping();
    }
  }

  Widget _buildHeaderSearchField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
    required bool isSearchVisible,
    required VoidCallback onToggle,
    TextAlign textAlign = TextAlign.start,
    bool showSortControls = false,
    required bool sortAscending,
    VoidCallback? onSortAscendingTap,
    VoidCallback? onSortDescendingTap,
  }) {
    if (!isSearchVisible) {
      return Row(
        mainAxisAlignment: textAlign == TextAlign.center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: _textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          if (showSortControls) ...[
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSortAscendingTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Icon(
                      LucideIcons.chevronUp,
                      size: 10,
                      color: sortAscending
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSortDescendingTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 10,
                      color: !sortAscending
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 4),
          InkWell(
            onTap: onToggle,
            child: const Icon(
              LucideIcons.search,
              size: 13,
              color: _textSecondary,
            ),
          ),
        ],
      );
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderCol),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 12, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              style: const TextStyle(fontSize: 11, color: _textPrimary),
              textAlign: textAlign,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              controller.clear();
              onChanged('');
              onToggle();
            },
            child: const Icon(LucideIcons.x, size: 12, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTableNoGrouping() {
    final totalItems = _filteredSelectedItems.length;
    final paginatedItems = _filteredSelectedItems
        .skip(_currentPage * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderCol),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
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
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildHeaderSearchField(
                        label: 'ITEM DETAILS',
                        controller: _itemNameSearchCtrl,
                        hintText: 'Search items...',
                        isSearchVisible: _isItemSearchVisible,
                        onToggle: () => setState(
                          () => _isItemSearchVisible = !_isItemSearchVisible,
                        ),
                        sortAscending: _salesOrderSortAscending,
                        onChanged: (val) => setState(() {
                          _itemNameSearchQuery = val;
                          _currentPage = 0;
                        }),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: _borderCol),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildHeaderSearchField(
                        label: 'SALES ORDER#',
                        controller: _salesOrderSearchCtrl,
                        hintText: 'Search SO...',
                        isSearchVisible: _isSOSearchVisible,
                        onToggle: () => setState(
                          () => _isSOSearchVisible = !_isSOSearchVisible,
                        ),
                        textAlign: TextAlign.center,
                        showSortControls: false,
                        sortAscending: _salesOrderSortAscending,
                        onSortAscendingTap: () {
                          if (_salesOrderSortAscending) return;
                          setState(() => _salesOrderSortAscending = true);
                        },
                        onSortDescendingTap: () {
                          if (!_salesOrderSortAscending) return;
                          setState(() => _salesOrderSortAscending = false);
                        },
                        onChanged: (val) => setState(() {
                          _salesOrderSearchQuery = val;
                          _currentPage = 0;
                        }),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: _borderCol),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'QUANTITY ORDERED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const VerticalDivider(width: 1, color: _borderCol),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'QUANTITY PACKED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const VerticalDivider(width: 1, color: _borderCol),
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
                  const VerticalDivider(width: 1, color: _borderCol),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Row(
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paginatedItems.length,
            itemBuilder: (context, index) {
              final item = paginatedItems[index];
              final rowKey = _buildRowKey(item);
              final available = item.availableQuantity;

              return Container(
                key: ValueKey(rowKey),
                padding: const EdgeInsets.only(left: 16, right: 0),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _borderCol)),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2, right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'Unit: ${item.unitTitle ?? "pcs"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _textSecondary,
                                ),
                              ),
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
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, color: _borderCol),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            '${item.quantityOrdered?.toInt() ?? 1}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, color: _borderCol),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            '${item.quantityPacked.toInt()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textPrimary,
                            ),
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
                            _buildQuantityField(
                              fieldKey: '${rowKey}_to_pick_main',
                              initialValue: item.quantityToPick ?? 1.0,
                              onChanged: (val) {
                                final d = val.trim().isEmpty
                                    ? 0.0
                                    : double.tryParse(val);
                                if (d != null) {
                                  final max = item.quantityOrdered ?? 0.0;
                                  // Restrict to quantityOrdered
                                  final finalVal = d > max
                                      ? max
                                      : (d < 0 ? 0.0 : d);

                                  setState(() {
                                    final idx = _selectedItems.indexWhere(
                                      (e) => _buildRowKey(e) == rowKey,
                                    );
                                    if (idx != -1) {
                                      _selectedItems[idx] = _selectedItems[idx]
                                          .copyWith(quantityToPick: finalVal);
                                    }
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Available To Pick:\n${available.toInt()} pcs',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: available >= (item.quantityToPick ?? 1.0)
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
                              fieldKey: '${rowKey}_picked_main',
                              initialValue: _currentPickedQty(item),
                              isRed:
                                  _currentPickedQty(item) >
                                  (item.quantityOrdered ?? 0),
                              isBlue:
                                  _currentPickedQty(item) > 0 &&
                                  _currentPickedQty(item) <=
                                      (item.quantityOrdered ?? 0),
                              readOnly: false,
                              onChanged: (val) {
                                final d = val.trim().isEmpty
                                    ? 0.0
                                    : double.tryParse(val);
                                if (d != null) {
                                  setState(() {
                                    final idx = _selectedItems.indexWhere(
                                      (e) => _buildRowKey(e) == rowKey,
                                    );
                                    if (idx != -1) {
                                      _selectedItems[idx] = _selectedItems[idx]
                                          .copyWith(
                                            quantityPicked: d < 0 ? 0.0 : d,
                                          );
                                    }
                                  });
                                }
                              },
                            ),
                            _currentPickedQty(item) == 0
                                ? const SizedBox.shrink()
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_savedBatchKeys.contains(rowKey))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            _buildBatchQtyFocText(item),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF9CA3AF),
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                      InkWell(
                                        onTap:
                                            () => _showSelectBatchesDialog(
                                              item,
                                            ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!_savedBatchKeys.contains(
                                              rowKey,
                                            ))
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  right: 4,
                                                ),
                                                child: Icon(
                                                  LucideIcons.alertTriangle,
                                                  size: 10,
                                                  color: Color(0xFFEF4444),
                                                ),
                                              ),
                                            Text(
                                              _savedBatchKeys.contains(rowKey)
                                                  ? _buildBatchSummaryText(item)
                                                  : 'Select Batch and Bin',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF2563EB),
                                                fontFamily: 'Inter',
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),

                      SizedBox(
                        width: 40,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedItems.removeAt(index)),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: _dangerRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildPaginationFooter(totalItems),
        ],
      ),
    );
  }

  Widget _buildTableByItem() {
    final grouped = <String, List<WarehouseStockData>>{};
    for (final item in _filteredSelectedItems) {
      grouped
          .putIfAbsent(item.productId, () => <WarehouseStockData>[])
          .add(item);
    }

    final groupKeys = grouped.keys.toList();
    final totalGroups = groupKeys.length;
    final paginatedKeys = groupKeys
        .skip(_currentPage * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Total Items: $totalGroups',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _borderCol),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Header Row
              Container(
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(bottom: BorderSide(color: _borderCol)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 28,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildHeaderSearchField(
                          label: 'ITEMS',
                          controller: _itemNameSearchCtrl,
                          hintText: 'Search items...',
                          isSearchVisible: _isItemSearchVisible,
                          onToggle: () => setState(
                            () => _isItemSearchVisible = !_isItemSearchVisible,
                          ),
                          textAlign: TextAlign.center,
                          showSortControls: false,
                          sortAscending: _salesOrderSortAscending,
                          onChanged: (val) =>
                              setState(() {
                                _itemNameSearchQuery = val;
                                _currentPage = 0;
                              }),
                        ),
                      ),
                    ),
                    Container(width: 1, color: _borderCol),
                    Expanded(
                      flex: 18,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildHeaderSearchField(
                          label: 'SALES ORDER#',
                          controller: _salesOrderSearchCtrl,
                          hintText: 'Search SO...',
                          isSearchVisible: _isSOSearchVisible,
                          onToggle: () => setState(
                            () => _isSOSearchVisible = !_isSOSearchVisible,
                          ),
                          sortAscending: _salesOrderSortAscending,
                          onChanged: (val) =>
                              setState(() {
                                _salesOrderSearchQuery = val;
                                _currentPage = 0;
                              }),
                        ),
                      ),
                    ),
                    Container(width: 1, color: _borderCol),
                    Expanded(
                      flex: 10,
                      child: Center(
                        child: Text(
                          'QTY ORDERED',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(width: 1, color: _borderCol),
                    Expanded(
                      flex: 14,
                      child: Center(
                        child: Text(
                          'PREFERRED BIN',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(width: 1, color: _borderCol),
                    Expanded(
                      flex: 16,
                      child: Center(
                        child: Text(
                          'QTY TO PICK',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(width: 1, color: _borderCol),
                    Expanded(
                      flex: 16,
                      child: Center(
                        child: Text(
                          'QTY PICKED',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // Groups
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paginatedKeys.length,
                itemBuilder: (context, groupIdx) {
                  final productId = paginatedKeys[groupIdx];
                  final itemsInGroup = grouped[productId]!;
                  final isLastGroup = groupIdx == paginatedKeys.length - 1;

                  return Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left Merged Product Column
                            Expanded(
                              flex: 28,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        itemsInGroup.first.productName,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total Orders: ${itemsInGroup.length}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, color: _borderCol),
                            // Right Side (Sub-rows)
                            Expanded(
                              flex: 74,
                              child: Column(
                                children: itemsInGroup.asMap().entries.map((e) {
                                  final item = e.value;
                                  final isLastItem =
                                      e.key == itemsInGroup.length - 1;
                                  final rowKey = _buildRowKey(item);
                                  return Column(
                                    children: [
                                      IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              flex: 18,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    item.salesOrderNumber ??
                                                        '-',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: _borderCol,
                                            ),
                                            Expanded(
                                              flex: 10,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${item.quantityOrdered?.toInt() ?? 1}',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: _borderCol,
                                            ),
                                            Expanded(
                                              flex: 14,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    item.preferredBin ?? 'N/A',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: _borderCol,
                                            ),
                                            Expanded(
                                              flex: 16,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    _buildQuantityField(
                                                      fieldKey:
                                                          '${rowKey}_to_pick_group_item',
                                                      initialValue:
                                                          item.quantityToPick ??
                                                          1.0,
                                                      onChanged: (val) {
                                                        final d =
                                                            double.tryParse(
                                                              val,
                                                            ) ??
                                                            1.0;
                                                        setState(() {
                                                          final idx = _selectedItems
                                                              .indexWhere(
                                                                (e) =>
                                                                    _buildRowKey(
                                                                      e,
                                                                    ) ==
                                                                    rowKey,
                                                              );
                                                          if (idx != -1) {
                                                            _selectedItems[idx] =
                                                                _selectedItems[idx]
                                                                    .copyWith(
                                                                      quantityToPick:
                                                                          d,
                                                                    );
                                                          }
                                                        });
                                                      },
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Available: ${item.availableQuantity.toInt()}',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            item.availableQuantity >=
                                                                (item.quantityToPick ??
                                                                    1.0)
                                                            ? _textSecondary
                                                            : _dangerRed,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: _borderCol,
                                            ),
                                            Expanded(
                                              flex: 16,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    _buildQuantityField(
                                                      fieldKey:
                                                          '${rowKey}_picked_group_item',
                                                      initialValue:
                                                          _currentPickedQty(
                                                            item,
                                                          ),
                                                      isBlue: _savedBatchKeys
                                                          .contains(rowKey),
                                                      onChanged: (val) {
                                                        final d =
                                                            double.tryParse(
                                                              val,
                                                            ) ??
                                                            0;
                                                        setState(() {
                                                          final idx = _selectedItems
                                                              .indexWhere(
                                                                (e) =>
                                                                    _buildRowKey(
                                                                      e,
                                                                    ) ==
                                                                    rowKey,
                                                              );
                                                          if (idx != -1) {
                                                            _selectedItems[idx] =
                                                                _selectedItems[idx]
                                                                    .copyWith(
                                                                      quantityPicked:
                                                                          d,
                                                                    );
                                                          }
                                                        });
                                                      },
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          _showSelectBatchesDialog(
                                                            item,
                                                          ),
                                                      style: TextButton.styleFrom(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        minimumSize: const Size(
                                                          0,
                                                          0,
                                                        ),
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          if (!_savedBatchKeys
                                                              .contains(rowKey))
                                                            const Padding(
                                                              padding:
                                                                  EdgeInsets.only(
                                                                    right: 4,
                                                                  ),
                                                              child: Icon(
                                                                LucideIcons
                                                                    .alertTriangle,
                                                                size: 10,
                                                                color: Color(
                                                                  0xFFEF4444,
                                                                ),
                                                              ),
                                                            ),
                                                          Text(
                                                            _savedBatchKeys
                                                                    .contains(
                                                                      rowKey,
                                                                    )
                                                                ? _buildBatchSummaryText(
                                                                    item,
                                                                  )
                                                                : 'Select Batch and Bin',
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              color: Color(
                                                                0xFF2563EB,
                                                              ),
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isLastItem)
                                        Divider(height: 1, color: _borderCol),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            // Action Column (Merged per item)
                            SizedBox(
                              width: 40,
                              child: Column(
                                children: itemsInGroup.asMap().entries.map((e) {
                                  final item = e.value;
                                  final isLastItem =
                                      e.key == itemsInGroup.length - 1;
                                  return Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: InkWell(
                                              onTap: () => setState(
                                                () =>
                                                    _selectedItems.remove(item),
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: _dangerRed,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (!isLastItem)
                                          Divider(height: 1, color: _borderCol),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLastGroup) Divider(height: 1, color: _borderCol),
                    ],
                  );
                },
              ),
              _buildPaginationFooter(totalGroups),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableBySalesOrder() {
    final grouped = <String, List<WarehouseStockData>>{};
    for (final item in _filteredSelectedItems) {
      final so = item.salesOrderNumber ?? 'No SO';
      grouped.putIfAbsent(so, () => <WarehouseStockData>[]).add(item);
    }

    final groupKeys = grouped.keys.toList();
    final totalGroups = groupKeys.length;
    final paginatedKeys = groupKeys
        .skip(_currentPage * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Total Sales Orders: $totalGroups',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _borderCol),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Header Row
              Container(
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(bottom: BorderSide(color: _borderCol)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 28,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildHeaderSearchField(
                          label: 'SALES ORDER#',
                          controller: _salesOrderSearchCtrl,
                          hintText: 'Search SO...',
                          isSearchVisible: _isSOSearchVisible,
                          onToggle: () => setState(
                            () => _isSOSearchVisible = !_isSOSearchVisible,
                          ),
                          textAlign: TextAlign.center,
                          showSortControls: false,
                          sortAscending: _salesOrderSortAscending,
                          onChanged: (val) =>
                              setState(() {
                                _salesOrderSearchQuery = val;
                                _currentPage = 0;
                              }),
                        ),
                      ),
                    ),
                    Container(width: 1, color: _borderCol),
                    Expanded(
                      flex: 18,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildHeaderSearchField(
                          label: 'ITEMS',
                          controller: _itemNameSearchCtrl,
                          hintText: 'Search items...',
                          isSearchVisible: _isItemSearchVisible,
                          onToggle: () => setState(
                            () => _isItemSearchVisible = !_isItemSearchVisible,
                          ),
                          sortAscending: _salesOrderSortAscending,
                          onChanged: (val) =>
                              setState(() {
                                _itemNameSearchQuery = val;
                                _currentPage = 0;
                              }),
                        ),
                      ),
                    ),
                    Container(width: 1, color: _borderCol),
                    Expanded(
                      flex: 10,
                      child: Center(
                        child: Text(
                          'QTY ORDERED',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(width: 1, color: _borderCol),
                    Expanded(
                      flex: 14,
                      child: Center(
                        child: Text(
                          'PREFERRED BIN',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(width: 1, color: _borderCol),
                    Expanded(
                      flex: 16,
                      child: Center(
                        child: Text(
                          'QTY TO PICK',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Container(width: 1, color: _borderCol),
                    Expanded(
                      flex: 16,
                      child: Center(
                        child: Text(
                          'QTY PICKED',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // Groups
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paginatedKeys.length,
                itemBuilder: (context, groupIdx) {
                  final soNum = paginatedKeys[groupIdx];
                  final itemsInGroup = grouped[soNum]!;
                  final isLastGroup = groupIdx == paginatedKeys.length - 1;

                  return Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left Merged SO Column
                            Expanded(
                              flex: 28,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        soNum,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total Items: ${itemsInGroup.length}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, color: _borderCol),
                            // Right Side (Sub-rows)
                            Expanded(
                              flex: 74,
                              child: Column(
                                children: itemsInGroup.asMap().entries.map((e) {
                                  final item = e.value;
                                  final isLastItem =
                                      e.key == itemsInGroup.length - 1;
                                  final rowKey = _buildRowKey(item);
                                  return Column(
                                    children: [
                                      IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              flex: 18,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      item.productName,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Unit: ${item.unitTitle ?? "pcs"}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: _textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: _borderCol,
                                            ),
                                            Expanded(
                                              flex: 10,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${item.quantityOrdered?.toInt() ?? 1}',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: _borderCol,
                                            ),
                                            Expanded(
                                              flex: 14,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    item.preferredBin ?? 'N/A',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: _borderCol,
                                            ),
                                            Expanded(
                                              flex: 16,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    _buildQuantityField(
                                                      fieldKey:
                                                          '${rowKey}_to_pick_group_so',
                                                      initialValue:
                                                          item.quantityToPick ??
                                                          1.0,
                                                      onChanged: (val) {
                                                        final d =
                                                            double.tryParse(
                                                              val,
                                                            ) ??
                                                            1.0;
                                                        setState(() {
                                                          final idx = _selectedItems
                                                              .indexWhere(
                                                                (e) =>
                                                                    _buildRowKey(
                                                                      e,
                                                                    ) ==
                                                                    rowKey,
                                                              );
                                                          if (idx != -1) {
                                                            _selectedItems[idx] =
                                                                _selectedItems[idx]
                                                                    .copyWith(
                                                                      quantityToPick:
                                                                          d,
                                                                    );
                                                          }
                                                        });
                                                      },
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Available: ${item.availableQuantity.toInt()}',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            item.availableQuantity >=
                                                                (item.quantityToPick ??
                                                                    1.0)
                                                            ? _textSecondary
                                                            : _dangerRed,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: _borderCol,
                                            ),
                                            Expanded(
                                              flex: 16,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    _buildQuantityField(
                                                      fieldKey:
                                                          '${rowKey}_picked_group_so',
                                                      initialValue:
                                                          _currentPickedQty(
                                                            item,
                                                          ),
                                                      isBlue: _savedBatchKeys
                                                          .contains(rowKey),
                                                      onChanged: (val) {
                                                        final d =
                                                            double.tryParse(
                                                              val,
                                                            ) ??
                                                            0;
                                                        setState(() {
                                                          final idx = _selectedItems
                                                              .indexWhere(
                                                                (e) =>
                                                                    _buildRowKey(
                                                                      e,
                                                                    ) ==
                                                                    rowKey,
                                                              );
                                                          if (idx != -1) {
                                                            _selectedItems[idx] =
                                                                _selectedItems[idx]
                                                                    .copyWith(
                                                                      quantityPicked:
                                                                          d,
                                                                    );
                                                          }
                                                        });
                                                      },
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          _showSelectBatchesDialog(
                                                            item,
                                                          ),
                                                      style: TextButton.styleFrom(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        minimumSize: const Size(
                                                          0,
                                                          0,
                                                        ),
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          if (!_savedBatchKeys
                                                              .contains(rowKey))
                                                            const Padding(
                                                              padding:
                                                                  EdgeInsets.only(
                                                                    right: 4,
                                                                  ),
                                                              child: Icon(
                                                                LucideIcons
                                                                    .alertTriangle,
                                                                size: 10,
                                                                color: Color(
                                                                  0xFFEF4444,
                                                                ),
                                                              ),
                                                            ),
                                                          Text(
                                                            _savedBatchKeys
                                                                    .contains(
                                                                      rowKey,
                                                                    )
                                                                ? _buildBatchSummaryText(
                                                                    item,
                                                                  )
                                                                : 'Select Batch and Bin',
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              color: Color(
                                                                0xFF2563EB,
                                                              ),
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isLastItem)
                                        Divider(height: 1, color: _borderCol),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            // Action Column
                            SizedBox(
                              width: 40,
                              child: Column(
                                children: itemsInGroup.asMap().entries.map((e) {
                                  final item = e.value;
                                  final isLastItem =
                                      e.key == itemsInGroup.length - 1;
                                  return Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: InkWell(
                                              onTap: () => setState(
                                                () =>
                                                    _selectedItems.remove(item),
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: _dangerRed,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (!isLastItem)
                                          Divider(height: 1, color: _borderCol),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLastGroup)
                        const Divider(height: 1, color: _borderCol),
                    ],
                  );
                },
              ),
              _buildPaginationFooter(totalGroups),
            ],
          ),
        ),
      ],
    );
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
            fillColor: _bgWhite,
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
            onPressed:
                (_isSaving ||
                    !_isFormValid ||
                    _selectedItems.isEmpty ||
                    !_allBatchesAdded)
                ? null
                : () async {
                    _validatePickList();
                    if (_validationErrors.isNotEmpty) return;

                    setState(() => _isSaving = true);
                    await _savePicklist();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  (_isFormValid &&
                      _selectedItems.isNotEmpty &&
                      _allBatchesAdded)
                  ? _greenBtn
                  : const Color(0xFFE5E7EB),
              foregroundColor:
                  (_isFormValid &&
                      _selectedItems.isNotEmpty &&
                      _allBatchesAdded)
                  ? Colors.white
                  : const Color(0xFF9CA3AF),
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
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Generate picklist',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textSecondary,
              side: const BorderSide(color: _borderCol),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.package, size: 20, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'Total Items Selected : ${_selectedItems.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddItemsDialog() {
    if (_selectedWarehouse == null) return;
    final warehouseId = _selectedWarehouse!.id;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final stocksAsync = ref.watch(
              stockByWarehouseProvider(warehouseId),
            );

            return stocksAsync.when(
              data: (allItems) => _AddItemsDialogContent(
                warehouseId: warehouseId,
                warehouseItems: allItems,
                warehouseName: _selectedWarehouse!.name,
                initialSelectedItems: _selectedItems,
                onItemsSelected: (selected) {
                  setState(() {
                    _selectedItems = selected;
                  });
                  Navigator.pop(dialogContext);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => AlertDialog(
                title: const Text('Error'),
                content: Text('Failed to load storage items: $err'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaginationFooter(int totalItems) {
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: _borderCol)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${(_currentPage * _itemsPerPage) + 1} - ${((_currentPage + 1) * _itemsPerPage).clamp(0, totalItems)} of $totalItems items',
            style: const TextStyle(fontSize: 12, color: _textSecondary),
          ),
          Row(
            children: [
              _buildPageButton(
                icon: LucideIcons.chevronLeft,
                isEnabled: _currentPage > 0,
                onTap: () => setState(() => _currentPage--),
              ),
              const SizedBox(width: 8),
              _buildPageButton(
                icon: LucideIcons.chevronRight,
                isEnabled: _currentPage < totalPages - 1,
                onTap: () => setState(() => _currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : const Color(0xFFF3F4F6),
          border: Border.all(color: _borderCol),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? _textPrimary : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _AddItemsDialogContent extends ConsumerStatefulWidget {
  final String warehouseId;
  final List<WarehouseStockData> warehouseItems;
  final String warehouseName;
  final Function(List<WarehouseStockData>) onItemsSelected;
  final List<WarehouseStockData> initialSelectedItems;

  const _AddItemsDialogContent({
    required this.warehouseId,
    required this.warehouseItems,
    required this.warehouseName,
    required this.onItemsSelected,
    required this.initialSelectedItems,
  });

  @override
  ConsumerState<_AddItemsDialogContent> createState() =>
      _AddItemsDialogContentState();
}

class _AddItemsDialogContentState
    extends ConsumerState<_AddItemsDialogContent> {
  final Set<String> selectedRowKeys = {};
  bool _isCustomerFilterHovered = false;
  bool _isItemsFilterHovered = false;
  bool _isSalesOrdersFilterHovered = false;

  String _buildRowKey(WarehouseStockData item) {
    return item.id ??
        '${item.productId}_${item.batchNo ?? ''}_${item.salesOrderId ?? ''}_${item.warehouseId}';
  }

  late String _currentGrouping;
  String searchQuery = '';
  int activeTab = 0; // 0 = All Items, 1 = Selected Items
  bool _showFilters = true;
  bool _sortAscending = true;
  int _pageSize = 30;
  int _currentPage = 1;
  int _totalPages = 1;
  List<WarehouseStockData> _allItems = [];
  List<WarehouseStockData> _filteredItems = [];
  List<WarehouseStockData> _items = [];
  int _totalItems = 0;
  bool _isLoading = false;
  final Map<String, WarehouseStockData> _selectedItemsMap = {};
  List<Map<String, dynamic>> _initialCustomers = [];
  List<Map<String, dynamic>> _initialProducts = [];
  List<Map<String, dynamic>> _initialSalesOrders = [];

  List<Map<String, dynamic>> _buildProductFallbackOptions() {
    final sourceItems = _allItems.isNotEmpty
        ? _allItems
        : (_items.isNotEmpty ? _items : widget.warehouseItems);
    final uniqueByProductId = <String, Map<String, dynamic>>{};
    for (final item in sourceItems) {
      if (item.productId.isEmpty) continue;
      if (uniqueByProductId.containsKey(item.productId)) continue;
      uniqueByProductId[item.productId] = {
        'id': item.productId,
        'name': item.productName,
      };
    }
    return uniqueByProductId.values.take(20).toList();
  }

  List<Map<String, dynamic>> _buildSalesOrderFallbackOptions() {
    final sourceItems = _allItems.isNotEmpty
        ? _allItems
        : (_items.isNotEmpty ? _items : widget.warehouseItems);
    final uniqueBySalesOrderId = <String, Map<String, dynamic>>{};
    for (final item in sourceItems) {
      final salesOrderId = item.salesOrderId;
      final salesOrderNumber = item.salesOrderNumber;
      final optionId = (salesOrderId != null && salesOrderId.isNotEmpty)
          ? salesOrderId
          : (salesOrderNumber ?? '');
      if (optionId.isEmpty) continue;
      if (uniqueBySalesOrderId.containsKey(optionId)) continue;
      uniqueBySalesOrderId[optionId] = {
        'id': optionId,
        'number': salesOrderNumber ?? optionId,
      };
    }
    return uniqueBySalesOrderId.values.take(20).toList();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(inventoryPicklistRepositoryProvider);

      // Build comma-separated filter IDs for server-side filtering
      final customerIds = _selectedCustomers
          .map((c) => c['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .join(',');
      final productIds = _selectedProducts
          .map((p) => p['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .join(',');
      final salesOrderIds = _selectedSalesOrders
          .map((o) => o['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .join(',');

      final result = await repository.getWarehouseItems(
        warehouseId: widget.warehouseId,
        page: _currentPage,
        limit: _pageSize,
        search: searchQuery.isEmpty ? null : searchQuery,
        customerId: customerIds.isEmpty ? null : customerIds,
        productId: productIds.isEmpty ? null : productIds,
        salesOrderId: salesOrderIds.isEmpty ? null : salesOrderIds,
        sortBy: 'salesOrder',
        sortAscending: _sortAscending,
      );

      final items = result['items'] as List<WarehouseStockData>;
      final total = result['total'] as int;

      if (mounted) {
        setState(() {
          _allItems = items;
          _items = items;
          _filteredItems = items;
          _totalItems = total;
          _totalPages = max(1, (total / _pageSize).ceil());
          if (_currentPage > _totalPages) {
            _currentPage = _totalPages;
          }
          if (_initialProducts.isEmpty) {
            _initialProducts = _buildProductFallbackOptions();
          }
          if (_initialSalesOrders.isEmpty) {
            _initialSalesOrders = _buildSalesOrderFallbackOptions();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentGrouping = 'No Grouping';
    for (final item in widget.initialSelectedItems) {
      _selectedItemsMap[_buildRowKey(item)] = item;
    }
    selectedRowKeys.addAll(_selectedItemsMap.keys);
    _loadInitialFilterData();
    _fetchData();
  }

  Future<void> _loadInitialFilterData() async {
    try {
      final results = await Future.wait([
        _onSearchCustomers(''),
        _onSearchProducts(''),
        _onSearchSalesOrders(''),
      ]);
      if (mounted) {
        setState(() {
          _initialCustomers = results[0];
          _initialProducts = results[1].isNotEmpty
              ? results[1]
              : _buildProductFallbackOptions();
          _initialSalesOrders = results[2].isNotEmpty
              ? results[2]
              : _buildSalesOrderFallbackOptions();
        });
      }
    } catch (e) {
      // Ignore errors for initial filter load
    }
  }

  // Real filter data - removed as we now use local provider data in build()
  bool isLoadingFilters = false;

  bool isSearching = false;

  // Selection states — full objects so chips display actual names
  List<Map<String, dynamic>> _selectedCustomers = [];
  List<Map<String, dynamic>> _selectedProducts = [];
  List<Map<String, dynamic>> _selectedSalesOrders = [];

  void _onSearch() {
    _currentPage = 1;
    _fetchData();
  }

  void _onSelectionChanged(WarehouseStockData item, bool isSelected) {
    final key = _buildRowKey(item);
    setState(() {
      if (isSelected) {
        selectedRowKeys.add(key);
        _selectedItemsMap[key] = item;
      } else {
        selectedRowKeys.remove(key);
        _selectedItemsMap.remove(key);
      }
    });
  }

  Future<void> _toggleSelectAll(List<WarehouseStockData> currentItems) async {
    final allKeysOnPage = currentItems.map((e) => _buildRowKey(e)).toList();
    final areAllOnPageSelected = allKeysOnPage.every(
      (k) => selectedRowKeys.contains(k),
    );

    if (areAllOnPageSelected) {
      // Uncheck everything
      setState(() {
        selectedRowKeys.clear();
        _selectedItemsMap.clear();
      });
    } else {
      // 1. SELECT CURRENT PAGE IMMEDIATELY FOR INSTANT FEEDBACK
      setState(() {
        for (final item in currentItems) {
          final key = _buildRowKey(item);
          selectedRowKeys.add(key);
          _selectedItemsMap[key] = item;
        }
      });

      // 2. IF THERE ARE MORE ITEMS, FETCH THEM IN BACKGROUND
      if (activeTab == 0 && _totalItems > currentItems.length) {
        setState(() => _isLoading = true);
        try {
          final repository = ref.read(inventoryPicklistRepositoryProvider);

          final customerIds = _selectedCustomers
              .map((c) => c['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .join(',');
          final productIds = _selectedProducts
              .map((p) => p['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .join(',');
          final salesOrderIds = _selectedSalesOrders
              .map((o) => o['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .join(',');

          final result = await repository.getWarehouseItems(
            warehouseId: widget.warehouseId,
            page: 1,
            limit: 5000,
            search: searchQuery.isEmpty ? null : searchQuery,
            customerId: customerIds.isEmpty ? null : customerIds,
            productId: productIds.isNotEmpty ? productIds : null, // Clean up
            salesOrderId: salesOrderIds.isNotEmpty
                ? salesOrderIds
                : null, // Clean up
          );

          final allItems = result['items'] as List<WarehouseStockData>;

          setState(() {
            for (final item in allItems) {
              final key = _buildRowKey(item);
              selectedRowKeys.add(key);
              _selectedItemsMap[key] = item;
            }
            _isLoading = false;
          });
        } catch (e) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> _onSearchCustomers(String query) async {
    final apiService = ref.read(salesOrderApiServiceProvider);
    final customers = await apiService.getCustomers(search: query, limit: 20);
    return customers
        .map((c) => {'id': c.id, 'name': c.displayName})
        .take(20)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _onSearchProducts(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty && normalizedQuery.length < 3) {
      return _initialProducts.isNotEmpty
          ? _initialProducts
          : _buildProductFallbackOptions();
    }

    try {
      final repo = ref.read(itemRepositoryProvider);
      final products = normalizedQuery.isEmpty
          ? await repo.getItems(limit: 20, offset: 0)
          : await repo.searchProducts(normalizedQuery, limit: 20);

      final mapped = products
          .map((i) => {'id': i.id ?? '', 'name': i.productName})
          .where((item) => (item['id'] ?? '').toString().isNotEmpty)
          .take(20)
          .toList();

      if (mapped.isNotEmpty) {
        return mapped;
      }
      return _buildProductFallbackOptions();
    } catch (_) {
      return _buildProductFallbackOptions();
    }
  }

  Future<List<Map<String, dynamic>>> _onSearchSalesOrders(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty && normalizedQuery.length < 3) {
      return _initialSalesOrders.isNotEmpty
          ? _initialSalesOrders
          : _buildSalesOrderFallbackOptions();
    }

    try {
      final apiService = ref.read(salesOrderApiServiceProvider);
      final orders = await apiService.getSalesByType(
        'order',
        search: normalizedQuery,
        limit: 20,
      );

      final mapped = orders
          .map((o) => {'id': o.id, 'number': o.saleNumber})
          .where(
            (item) =>
                (item['id'] ?? '').toString().isNotEmpty &&
                (item['number'] ?? '').toString().isNotEmpty,
          )
          .take(20)
          .toList();

      if (mapped.isNotEmpty) {
        return mapped;
      }
      return _buildSalesOrderFallbackOptions();
    } catch (_) {
      return _buildSalesOrderFallbackOptions();
    }
  }


  Border _buildFilterFieldBorder({
    required bool isHovered,
    required bool hasValue,
  }) {
    return Border.all(
      color: (isHovered || hasValue)
          ? const Color(0xFF3B82F6)
          : const Color(0xFFE5E7EB),
    );
  }

  Widget _buildFilterDropdownItem({
    required String label,
    required bool isSelected,
    required bool isHovered,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHovered
            ? const Color(0xFF3B82F6) // Blue on hover
            : (isSelected ? const Color(0xFFF3F4F6) : Colors.white),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isHovered ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.close,
              size: 14,
              color: isHovered
                  ? Colors.white
                  : const Color(0xFFEF4444), // White on hover, Red otherwise
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalFiltered = _totalItems;
    final totalPages = _totalPages;
    final clampedCurrentPage = _currentPage.clamp(1, totalPages);
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: SizedBox(
        width: 1200,
        height: 750,
        child: Column(
          children: [
            // Header Section
            _buildDialogHeader(),

            // Filter Section
            _buildFilterSection(),

            // Tabs & Group By
            _buildTabsAndGroupBy(_totalItems),

            // Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : activeTab == 0
                  ? _buildItemsTable(
                      _items,
                      selectionScopeItems: _filteredItems,
                    )
                  : _buildSelectedItemsTable(widget.warehouseItems),
            ),

            // Footer Section
            if (activeTab == 0)
              _buildDialogFooter(
                _items,
                totalFiltered: totalFiltered,
                currentPage: clampedCurrentPage,
                totalPages: totalPages,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      child: Row(
        children: [
          const Text(
            'Add Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Color(0xFF333333),
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'Location: ${widget.warehouseName.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 4),
              ZTooltip(
                message:
                    'Only items from this location can be added to the picklist.',
                child: Icon(
                  LucideIcons.info,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          const SizedBox(
            height: 24,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(width: 24),
          ZTooltip(
            message: 'Toggle filter view',
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: const Icon(LucideIcons.filter, size: 14),
              label: const Text('Filter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF333333),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade600),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(LucideIcons.x, size: 16, color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    if (!_showFilters) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Customer Name filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Name',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MouseRegion(
                      onEnter: (_) =>
                          setState(() => _isCustomerFilterHovered = true),
                      onExit: (_) =>
                          setState(() => _isCustomerFilterHovered = false),
                      child: FormDropdown<dynamic>(
                        hint: 'Click or Type to select',
                        multiSelect: true,
                        height: 30,
                        value: null,
                        onChanged: (_) {},
                        border: _buildFilterFieldBorder(
                          isHovered: _isCustomerFilterHovered,
                          hasValue: _selectedCustomers.isNotEmpty,
                        ),
                        selectedValues: _selectedCustomers,
                        items: _initialCustomers,
                        onSearch: _onSearchCustomers,
                        onSelectedValuesChanged: (vals) {
                          _selectedCustomers = vals
                              .cast<Map<String, dynamic>>();
                          _currentPage = 1;
                          _fetchData();
                        },
                        displayStringForValue: (val) => val['name'] as String,
                        showSearch: true,
                        searchStringForValue: (val) => val['name'] as String,
                        hideSelectedItemsInMultiSelect: true,
                        itemBuilder: (item, isSelected, isHovered) =>
                            _buildFilterDropdownItem(
                              label: item['name'] as String,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Items filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MouseRegion(
                      onEnter: (_) =>
                          setState(() => _isItemsFilterHovered = true),
                      onExit: (_) =>
                          setState(() => _isItemsFilterHovered = false),
                      child: FormDropdown<dynamic>(
                        hint: 'Click or Type to select',
                        multiSelect: true,
                        height: 30,
                        value: null,
                        onChanged: (_) {},
                        border: _buildFilterFieldBorder(
                          isHovered: _isItemsFilterHovered,
                          hasValue: _selectedProducts.isNotEmpty,
                        ),
                        selectedValues: _selectedProducts,
                        items: _initialProducts,
                        onSearch: _onSearchProducts,
                        onSelectedValuesChanged: (vals) {
                          _selectedProducts = vals.cast<Map<String, dynamic>>();
                          _currentPage = 1;
                          _fetchData();
                        },
                        displayStringForValue: (val) => val['name'] as String,
                        showSearch: true,
                        searchStringForValue: (val) => val['name'] as String,
                        hideSelectedItemsInMultiSelect: true,
                        itemBuilder: (item, isSelected, isHovered) =>
                            _buildFilterDropdownItem(
                              label: item['name'] as String,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Sales Orders filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Orders',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MouseRegion(
                      onEnter: (_) =>
                          setState(() => _isSalesOrdersFilterHovered = true),
                      onExit: (_) =>
                          setState(() => _isSalesOrdersFilterHovered = false),
                      child: FormDropdown<dynamic>(
                        hint: 'Click or Type to select',
                        multiSelect: true,
                        height: 30,
                        value: null,
                        onChanged: (_) {},
                        border: _buildFilterFieldBorder(
                          isHovered: _isSalesOrdersFilterHovered,
                          hasValue: _selectedSalesOrders.isNotEmpty,
                        ),
                        selectedValues: _selectedSalesOrders,
                        items: _initialSalesOrders,
                        onSearch: _onSearchSalesOrders,
                        onSelectedValuesChanged: (vals) {
                          _selectedSalesOrders = vals
                              .cast<Map<String, dynamic>>();
                          _currentPage = 1;
                          _fetchData();
                        },
                        displayStringForValue: (val) => val['number'] as String,
                        showSearch: true,
                        searchStringForValue: (val) => val['number'] as String,
                        hideSelectedItemsInMultiSelect: true,
                        itemBuilder: (item, isSelected, isHovered) =>
                            _buildFilterDropdownItem(
                              label: item['number'] as String,
                              isSelected: isSelected,
                              isHovered: isHovered,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22A95E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: isSearching
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Search',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsAndGroupBy(int allCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          _buildTab(
            'All Items($allCount)',
            activeTab == 0,
            () => setState(() => activeTab = 0),
          ),
          const SizedBox(width: 24),
          _buildTab(
            'Selected Items(${selectedRowKeys.length})',
            activeTab == 1,
            () => setState(() => activeTab = 1),
          ),
          const Spacer(),
          Row(
            children: [
              const Text(
                'Group By: ',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              SizedBox(
                width: 190,
                height: 30,
                child: FormDropdown<String>(
                  value: _currentGrouping,
                  height: 30,
                  items: const ['No Grouping', 'By Item', 'By Sales Orders'],
                  hint: 'No Grouping',
                  showSearch: false,
                  maxVisibleItems: 3,
                  displayStringForValue: (s) => s,
                  searchStringForValue: (s) => s,
                  itemBuilder: (item, isSelected, isHovered) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: isHovered
                        ? const Color(0xFF3B82F6)
                        : (isSelected
                              ? const Color(0xFFF3F4F6)
                              : Colors.transparent),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                            color: isHovered
                                ? Colors.white
                                : const Color(0xFF374151),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 14,
                            color: isHovered
                                ? Colors.white
                                : const Color(0xFF374151),
                          ),
                      ],
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _currentGrouping = val;
                        _currentPage = 1;
                        _fetchData();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  bool _isGroupFullSelected(String groupTitle, List<WarehouseStockData> items) {
    final itemsInGroup = items.where((item) {
      String key = _currentGrouping == 'By Item'
          ? item.productName
          : (item.salesOrderNumber ?? 'No Sales Order');
      return key == groupTitle;
    }).toList();
    if (itemsInGroup.isEmpty) return false;
    return itemsInGroup.every(
      (item) => selectedRowKeys.contains(_buildRowKey(item)),
    );
  }

  void _toggleGroupSelection(
    String groupTitle,
    List<WarehouseStockData> items,
  ) {
    final itemsInGroup = items.where((item) {
      String key = _currentGrouping == 'By Item'
          ? item.productName
          : (item.salesOrderNumber ?? 'No Sales Order');
      return key == groupTitle;
    }).toList();

    final groupKeys = itemsInGroup.map((e) => _buildRowKey(e)).toList();
    final allSelected = groupKeys.every((k) => selectedRowKeys.contains(k));

    setState(() {
      if (allSelected) {
        for (final item in itemsInGroup) {
          final key = _buildRowKey(item);
          selectedRowKeys.remove(key);
          _selectedItemsMap.remove(key);
        }
      } else {
        for (final item in itemsInGroup) {
          final key = _buildRowKey(item);
          selectedRowKeys.add(key);
          _selectedItemsMap[key] = item;
        }
      }
    });
  }

  Widget _buildItemsTable(
    List<WarehouseStockData> items, {
    required List<WarehouseStockData> selectionScopeItems,
  }) {
    // Determine the flat list to render based on grouping logic
    final flatList = <dynamic>[];

    if (_currentGrouping == 'No Grouping' || _currentGrouping.isEmpty) {
      flatList.addAll(items);
    } else {
      // Grouping by "By Item" or "By Sales Orders"
      final groupedItems = <String, List<WarehouseStockData>>{};
      for (var item in items) {
        String key = _currentGrouping == 'By Item'
            ? item.productName
            : (item.salesOrderNumber ?? 'No Sales Order');
        groupedItems.putIfAbsent(key, () => []).add(item);
      }

      for (var entry in groupedItems.entries) {
        flatList.add({'isHeader': true, 'title': entry.key});
        flatList.addAll(entry.value);
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value:
                      _filteredItems.isNotEmpty &&
                      _filteredItems.every(
                        (item) => selectedRowKeys.contains(_buildRowKey(item)),
                      ),
                  onChanged: (val) async {
                    await _toggleSelectAll(selectionScopeItems);
                  },
                  activeColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _headerCell('ITEM DETAILS')),
              Expanded(flex: 2, child: _headerCell('ORDER #', hasSort: true)),
              Expanded(flex: 2, child: _headerCell('CUSTOMER')),
              Expanded(
                flex: 2,
                child: _headerCell('QTY ORDERED', align: TextAlign.center),
              ),
              Expanded(flex: 2, child: _headerCell('PREFERRED BIN')),
              Expanded(
                flex: 2,
                child: _headerCell('TO PICK', align: TextAlign.center),
              ),
              Expanded(
                flex: 2,
                child: _headerCell('PICKED', align: TextAlign.center),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: flatList.length,
            itemBuilder: (context, index) {
              final itemOrHeader = flatList[index];

              if (itemOrHeader is Map) {
                // Header row
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _isGroupFullSelected(
                            itemOrHeader['title'] as String,
                            selectionScopeItems,
                          ),
                          onChanged: (val) => _toggleGroupSelection(
                            itemOrHeader['title'] as String,
                            selectionScopeItems,
                          ),
                          activeColor: const Color(0xFF3B82F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        itemOrHeader['title'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Normal item row
              final item = itemOrHeader as WarehouseStockData;
              final rowKey = _buildRowKey(item);
              final isSelected = selectedRowKeys.contains(rowKey);

              return Container(
                key: ValueKey(rowKey),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    _buildTableCheckbox(
                      isSelected,
                      () => _onSelectionChanged(item, !isSelected),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.salesOrderNumber ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.customerName ?? 'Walk-in',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.quantityOrdered?.toInt() ?? 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.preferredBin ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.quantityToPick?.toInt() ?? 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.quantityPicked?.toInt() ?? 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemsTable(List<WarehouseStockData> _) {
    final selectedItems = _selectedItemsMap.values.toList();

    if (selectedItems.isEmpty) {
      return const Center(
        child: Text(
          'No items selected yet',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
      );
    }

    return _buildItemsTable(selectedItems, selectionScopeItems: selectedItems);
  }

  Widget _headerCell(String text, {bool hasSort = false, TextAlign? align}) {
    return InkWell(
      onTap: hasSort ? null : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: align == TextAlign.center
            ? MainAxisAlignment.center
            : (align == TextAlign.right
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start),
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          if (hasSort) ...[
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_sortAscending) return;
                    setState(() {
                      _sortAscending = true;
                      _currentPage = 1;
                    });
                    _fetchData();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Icon(
                      LucideIcons.chevronUp,
                      size: 10,
                      color: _sortAscending
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!_sortAscending) return;
                    setState(() {
                      _sortAscending = false;
                      _currentPage = 1;
                    });
                    _fetchData();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 10,
                      color: !_sortAscending
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableCheckbox(bool value, VoidCallback onChanged) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Checkbox(
        value: value,
        onChanged: (val) => onChanged(),
        activeColor: const Color(0xFF3B82F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
    );
  }

  Widget _buildDialogFooter(
    List<WarehouseStockData> allMergedItems, {
    required int totalFiltered,
    required int currentPage,
    required int totalPages,
  }) {
    final pageIndicator = totalFiltered == 0
        ? '0 - 0'
        : '$currentPage - $totalPages';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () {
              final selectedItems = _selectedItemsMap.values.toList();
              widget.onItemsSelected(selectedItems);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22A95E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add Items',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const Spacer(),
          // ── Pagination ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Page size dropdown
              _PaginationSizeDropdown(
                value: _pageSize,
                options: const [30, 50, 100, 200, 500],
                onChanged: (size) {
                  _pageSize = size;
                  _currentPage = 1;
                  _fetchData();
                },
              ),
              const SizedBox(width: 16),
              // Prev button
              _PaginationArrow(
                icon: LucideIcons.chevronLeft,
                enabled: currentPage > 1,
                onTap: () {
                  _currentPage = currentPage - 1;
                  _fetchData();
                },
              ),
              const SizedBox(width: 8),
              // Range display
              Text(
                pageIndicator,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              // Next button
              _PaginationArrow(
                icon: LucideIcons.chevronRight,
                enabled: currentPage < totalPages,
                onTap: () {
                  _currentPage = currentPage + 1;
                  _fetchData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaginationSizeDropdown extends StatefulWidget {
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  const _PaginationSizeDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_PaginationSizeDropdown> createState() =>
      _PaginationSizeDropdownState();
}

class _PaginationSizeDropdownState extends State<_PaginationSizeDropdown> {
  OverlayEntry? _overlay;
  final LayerLink _link = LayerLink();
  int? _hoveredOption;

  void _open() {
    _close();
    _hoveredOption = null;
    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: const Offset(0, -(_kRowH * 5 + 2)),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.options.map((opt) {
                    final isSelected = opt == widget.value;
                    final isHovered = _hoveredOption == opt;
                    final bgColor = isHovered
                        ? const Color(0xFF3B82F6)
                        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
                    final fgColor = isHovered
                        ? Colors.white
                        : const Color(0xFF111827);

                    return MouseRegion(
                      onEnter: (_) {
                        _hoveredOption = opt;
                        _overlay?.markNeedsBuild();
                      },
                      onExit: (_) {
                        if (_hoveredOption == opt) {
                          _hoveredOption = null;
                          _overlay?.markNeedsBuild();
                        }
                      },
                      child: GestureDetector(
                        onTap: () {
                          widget.onChanged(opt);
                          _close();
                        },
                        child: Container(
                          height: _kRowH,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: opt == widget.options.first
                                ? const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  )
                                : opt == widget.options.last
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(4),
                                  )
                                : BorderRadius.zero,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$opt per page',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: fgColor,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check, size: 14, color: fgColor),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.maybeOf(context)?.insert(_overlay!);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    _hoveredOption = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _open,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings_outlined,
                size: 14,
                color: const Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.value} per page',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const double _kRowH = 36.0;

class _PaginationArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 4.0;

    // Top border
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }

    // Right border
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Bottom border
    startX = size.width;
    while (startX > 0) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(startX - dashWidth, size.height),
        paint,
      );
      startX -= dashWidth + dashSpace;
    }

    // Left border
    startY = size.height;
    while (startY > 0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY - dashWidth), paint);
      startY -= dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
  static const String _quantityMismatchMessage =

      'There\'s a mismatch between the quantity entered in the line item and the total quantity across all batches. Click the checkbox to overwrite the quantity in the line item.';

  @override
  void initState() {
    super.initState();
    _loadBins();
    if (widget.savedBatchData != null && widget.savedBatchData!.isNotEmpty) {
      for (var batchData in widget.savedBatchData!) {
        final row = _PicklistBatchRowController();
        row.binLocationCtrl.text = batchData['binLocation'] ?? '';
        row.batchRefCtrl.text = batchData['batchRef'] ?? '';
        row.batchNoCtrl.text = batchData['batchNo'] ?? '';
        row.unitPackCtrl.text = batchData['unitPack'] ?? '';
        row.mrpCtrl.text = batchData['mrp'] ?? '';
        row.ptrCtrl.text = batchData['ptr'] ?? '';
        row.expDateCtrl.text = batchData['expDate'] ?? '';
        if (row.expDateCtrl.text.isNotEmpty) {
          try {
            row.expDate = DateFormat('dd-MM-yyyy').parse(row.expDateCtrl.text);
          } catch (_) {}
        }
        row.mfgDateCtrl.text = batchData['mfgDate'] ?? '';
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
    if (widget.warehouseId.isEmpty) {
      debugPrint('⚠️ Warehouse ID is empty in _loadBins (Picklist)');
      return;
    }
    try {
      debugPrint(
        '🔄 Loading bins for Picklist - Warehouse: ${widget.warehouseId}, Product: ${widget.productId}',
      );
      final repository = ref.read(inventoryPicklistRepositoryProvider);
      final bins = await repository.getWarehouseBins(
        warehouseId: widget.warehouseId,
        productId: widget.productId,
      );
      
      debugPrint('📦 Found ${bins.length} bins from repository for Picklist');
      
      if (mounted) {
        setState(() {
          _binLocations = bins
              .map((b) => (b['binCode'] ?? b['bin_code'] ?? '').toString())
              .where((c) => c.isNotEmpty)
              .toList();
        });
        debugPrint('✅ Set _binLocations (Picklist): $_binLocations');
      }
    } catch (e) {
      debugPrint('❌ Error loading bins in Picklist: $e');
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
            onChanged: (_) => setState(() {}),

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
              onChanged: (_) => setState(() {}),

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
                        onEnter: (_) =>
                            setState(() => _hoveredBatchRows.add(index)),
                        onExit: (_) =>
                            setState(() => _hoveredBatchRows.remove(index)),
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
                                    isEnabled:
                                        row.binLocationCtrl.text.isNotEmpty,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              color: isHovered
                                                  ? const Color(0xFF3B82F6)
                                                  : (isSelected
                                                        ? const Color(
                                                            0xFFF3F4F6,
                                                          )
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
                                            row.binLocationCtrl.text =
                                                val ?? '';
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
                                        final batches =
                                            batchesAsync.value ?? [];

                                        return FormDropdown<
                                          Map<String, dynamic>
                                        >(
                                          height: _batchDropdownHeight,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                          itemBuilder:
                                              (item, isSelected, isHovered) {
                                                final batchNo =
                                                    item['batch_no']
                                                        ?.toString() ??
                                                    '-';
                                                final balance =
                                                    item['balance']
                                                        ?.toString() ??
                                                    '0';
                                                final expDate =
                                                    item['expiry_date']
                                                        ?.toString() ??
                                                    '-';
                                                final mrp =
                                                    item['mrp']?.toString() ??
                                                    '0.00';
                                                final ptr =
                                                    item['ptr']?.toString() ??
                                                    '0.00';

                                                final displayText =
                                                    '$batchNo | Bal: $balance | Exp: $expDate | MRP: $mrp | PTR: $ptr';

                                                return Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  color: isHovered
                                                      ? const Color(0xFF3B82F6)
                                                      : (isSelected
                                                            ? const Color(
                                                                0xFFF3F4F6,
                                                              )
                                                            : Colors
                                                                  .transparent),
                                                  child: Text(
                                                    displayText,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isHovered
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF1F2937,
                                                            ),
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                );
                                              },
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
                                                    v['unit_pack']
                                                        ?.toString() ??
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
                          ZerpaiToast.error(
                            context,
                            'Please select Bin Location in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.batchRefCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please select Batch Reference in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.batchNoCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please enter Batch No in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.unitPackCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please enter Unit Pack in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.mrpCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please enter MRP in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.expDateCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please select Expiry Date in Row ${i + 1}.',
                          );
                          return;
                        }

                        // Rule: Either Quantity Out or FOC must be filled
                        final qtyOut =
                            double.tryParse(row.qtyOutCtrl.text.trim()) ?? 0;
                        final foc =
                            double.tryParse(row.focCtrl.text.trim()) ?? 0;
                        if (qtyOut <= 0 && foc <= 0) {
                          ZerpaiToast.error(
                            context,
                            'Either Quantity Out or FOC must be filled in Row ${i + 1}.',
                          );
                          return;
                        }
                      }

                      // Check for duplicate Bin Location + Batch No
                      final seenPairs = <String>{};
                      for (var i = 0; i < _rows.length; i++) {
                        final row = _rows[i];
                        final bin = row.binLocationCtrl.text.trim();
                        final batch = row.batchNoCtrl.text.trim();
                        if (bin.isNotEmpty && batch.isNotEmpty) {
                          final pair = '$bin|$batch';
                          if (seenPairs.contains(pair)) {
                            ZerpaiToast.error(
                              context,
                              'Same Bin Location and Batch No can\'t be used multiple times.',
                            );
                            return;
                          }
                          seenPairs.add(pair);
                        }
                      }

                      if (_hasQuantityMismatch && !_overwriteLineItem) {
                        ZerpaiToast.error(context, _quantityMismatchMessage);
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

class _PicklistPreferencesDialog extends StatefulWidget {
  final bool initialAutoGenerate;
  final String initialPrefix;
  final int initialNextNumber;
  final void Function(bool isAuto, String prefix, int nextNum) onSave;

  const _PicklistPreferencesDialog({
    required this.initialAutoGenerate,
    required this.initialPrefix,
    required this.initialNextNumber,
    required this.onSave,
  });

  @override
  State<_PicklistPreferencesDialog> createState() =>
      __PicklistPreferencesDialogState();
}

class __PicklistPreferencesDialogState
    extends State<_PicklistPreferencesDialog> {
  late bool _isAuto;
  late TextEditingController _prefixCtrl;
  late TextEditingController _numberCtrl;

  @override
  void initState() {
    super.initState();
    _isAuto = widget.initialAutoGenerate;
    _prefixCtrl = TextEditingController(text: widget.initialPrefix);
    _numberCtrl = TextEditingController(
      text: widget.initialNextNumber.toString().padLeft(5, '0'),
    );
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF6B7280);
    const borderCol = Color(0xFFE5E7EB);
    const greenBtn = Color(0xFF22A95E);

    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 500,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configure Picklist# Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: borderCol),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your picklist numbers are set on auto-generate mode to save your time.',
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),
                  const Text(
                    'Are you sure about changing this setting?',
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),
                  const SizedBox(height: 24),

                  // Auto generate option
                  InkWell(
                    onTap: () => setState(() => _isAuto = true),
                    child: Row(
                      children: [
                        RadioGroup<bool>(
                          groupValue: _isAuto,
                          onChanged: (val) => setState(() => _isAuto = val!),
                          child: Radio<bool>(
                            value: true,
                            activeColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        const Text(
                          'Continue auto-generating picklist numbers',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.info,
                          size: 14,
                          color: textSecondary,
                        ),
                      ],
                    ),
                  ),

                  if (_isAuto) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prefix',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _prefixCtrl,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: borderCol,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: borderCol,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _numberCtrl,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: borderCol,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: borderCol,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Manual option
                  InkWell(
                    onTap: () => setState(() => _isAuto = false),
                    child: Row(
                      children: [
                        RadioGroup<bool>(
                          groupValue: _isAuto,
                          onChanged: (val) => setState(() => _isAuto = val!),
                          child: Radio<bool>(
                            value: false,
                            activeColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        const Text(
                          'Enter picklist numbers manually',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: borderCol),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final nextNum =
                          int.tryParse(_numberCtrl.text) ??
                          widget.initialNextNumber;
                      widget.onSave(_isAuto, _prefixCtrl.text, nextNum);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenBtn,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      backgroundColor: const Color(0xFFF3F4F6),
                      side: BorderSide.none,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
    Overlay.maybeOf(context)?.insert(_entry!);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
