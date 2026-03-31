import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/inventory/providers/stock_provider.dart';
import 'package:zerpai_erp/modules/sales/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/modules/auth/providers/user_provider.dart';

const _textPrimary = Color(0xFF1F2937);
const _textSecondary = Color(0xFF6B7280);
const _borderCol = Color(0xFFE5E7EB);
const _bgWhite = Color(0xFFFFFFFF);
const _focusBorder = Color(0xFF0088FF);
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
  List<String> _validationErrors = [];

  void _validatePickList() {
    setState(() {
      _validationErrors = [];
      for (var item in _selectedItems) {
        final picked = _currentPickedQty(item);
        final toPick = _currentQtyToPick(item);
        final rowKey = _buildRowKey(item);
        final isFocused =
            _focusedQtyFieldKeys.contains('${rowKey}_picked_main') ||
            _focusedQtyFieldKeys.contains('${rowKey}_picked_compact') ||
            _focusedQtyFieldKeys.contains('${rowKey}_picked_mobile');
        final isMatched = (picked - toPick).abs() < 0.0001;
        if (picked > (toPick + 0.0001) && !isFocused && !isMatched) {
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
  final Set<String> _hoveredAssigneeFieldKeys = <String>{};
  final Map<String, String?> _itemGroupAssigneeByProductId =
      <String, String?>{};
  final Map<String, String?> _salesOrderGroupAssigneeByOrderNumber =
      <String, String?>{};

  // Picklist Numbering Preferences
  bool _isAutoGenerate = true;
  String _picklistPrefix = 'PL-';
  int _nextNumber = 17;

  // Batch data persistence
  final Map<String, List<Map<String, String>>> _savedBatchData =
      <String, List<Map<String, String>>>{};

  bool get _isFormValid =>
      _picklistNumberCtrl.text.trim().isNotEmpty &&
      _selectedGroup != null &&
      _selectedWarehouse != null &&
      _selectedAssignee != null;

  bool get _hasMandatoryFieldsForItemSelection =>
      _picklistNumberCtrl.text.trim().isNotEmpty &&
      _selectedGroup != null &&
      _selectedWarehouse != null;

  bool get _allBatchesAdded =>
      _selectedItems.isNotEmpty &&
      _selectedItems.every(
        (item) => _savedBatchKeys.contains(_buildRowKey(item)),
      );

  @override
  void initState() {
    super.initState();
    _selectedGroup = 'No Grouping';
    _picklistNumberCtrl.text = _generatePicklistNumber();
    _dateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
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

  Future<void> _showSelectBatchesDialog(WarehouseStockData item) async {
    final existingBatches = _selectedItems
        .map((e) => (e.batchNo ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final dropdownRefs = {'REF-2024-001', ...existingBatches}.toList();

    final result = await showDialog<_PicklistBatchDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PicklistSelectBatchesDialog(
        itemName: item.productName,
        warehouseName: _selectedWarehouse?.name ?? 'ZABNIX PRIVATE LIMITED',
        totalQuantity: item.quantityToPick ?? 1,
        existingBatchRefs: dropdownRefs,
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
          quantityPicked: result.appliedQuantity,
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
    bool hasError = false,
    bool showPermanentBorder = false,
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
            color: hasError
                ? _dangerRed
                : (showBlueOutline ? _focusBorder : Colors.transparent),
            width: (hasError || showBlueOutline) ? 1.2 : 0,
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
            ),
            controller:
                TextEditingController(text: initialValue.toInt().toString())
                  ..selection = TextSelection.collapsed(
                    offset: initialValue.toInt().toString().length,
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
            _picklistNumberCtrl.text = _generatePicklistNumber();
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
                    child: TextField(
                      controller: _picklistNumberCtrl,
                      readOnly: _isAutoGenerate,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textPrimary,
                        fontFamily: 'Inter',
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bgWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: _borderCol),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: _focusBorder,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        suffixIcon: _PicklistZTooltip(
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
                ),
                const SizedBox(height: 20),

                _buildFormRow(
                  label: 'Date',
                  isRequired: false,
                  child: SizedBox(
                    width: 350,
                    child: TextField(
                      controller: _dateCtrl,
                      readOnly: true,
                      key: _dateFieldKey,
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textPrimary,
                        fontFamily: 'Inter',
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bgWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: _borderCol),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: _focusBorder,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        suffixIcon: const Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: _textSecondary,
                        ),
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

                if (_selectedGroup == 'No Grouping' ||
                    _selectedGroup == null) ...[
                  _buildFormRow(
                    label: 'Assignee',
                    isRequired: false,
                    child: SizedBox(
                      width: 350,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final usersAsync = ref.watch(allUsersProvider);
                          return FormDropdown<User>(
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
                ],

                _buildFormRow(
                  label: 'Warehouse',
                  isRequired: true,
                  child: SizedBox(
                    width: 350,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final warehousesAsync = ref.watch(warehousesProvider);

                        return warehousesAsync.when(
                          data: (warehouses) => FormDropdown<Warehouse>(
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
                              if (val != null)
                                setState(() => _selectedWarehouse = val);
                            },
                          ),
                          loading: () => Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: _borderCol),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Loading warehouses...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
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
          const Text(
            'New Picklist',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          const SizedBox(width: 16),
          InkWell(
            onTap: () => context.pop(),
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

  Widget _buildTableNoGrouping() {
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
                  const Expanded(
                    flex: 4,
                    child: Padding(
                      padding: EdgeInsets.only(top: 2),
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
                  const VerticalDivider(width: 1, color: _borderCol),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'SALES ORDER#',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const VerticalDivider(width: 1, color: _borderCol),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'QTY ORDERED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const VerticalDivider(width: 1, color: _borderCol),
                  const Expanded(
                    flex: 1,
                    child: Text(
                      'PREFERRED BIN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
                            'QTY TO PICK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const _PicklistZTooltip(
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'QTY PICKED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const _PicklistZTooltip(
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
            itemCount: _selectedItems.length,
            itemBuilder: (context, index) {
              final item = _selectedItems[index];
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
                      const VerticalDivider(width: 1, color: _borderCol),
                      Expanded(
                        flex: 2,
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
                            item.preferredBin ?? 'N/A',
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
                          children: [
                            _buildQuantityField(
                              fieldKey: '${rowKey}_to_pick_main',
                              initialValue: item.quantityToPick ?? 1.0,
                              onChanged: (val) {
                                final d = double.tryParse(val);
                                if (d != null) {
                                  setState(() {
                                    final idx = _selectedItems.indexWhere(
                                      (e) => _buildRowKey(e) == rowKey,
                                    );
                                    if (idx != -1) {
                                      final normalizedToPick = d < 0 ? 0.0 : d;
                                      _selectedItems[idx] = item.copyWith(
                                        quantityToPick: normalizedToPick,
                                      );
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
                          children: [
                            _buildQuantityField(
                              fieldKey: '${rowKey}_picked_main',
                              initialValue: _currentPickedQty(item),
                              hasError:
                                  _currentPickedQty(item) >
                                  (_currentQtyToPick(item) + 0.0001),
                              showPermanentBorder:
                                  (_currentPickedQty(item) -
                                          _currentQtyToPick(item))
                                      .abs() <
                                  0.0001,
                              onChanged: (val) {
                                final d = double.tryParse(val);
                                if (d != null) {
                                  setState(() {
                                    final nonNegative = d < 0 ? 0.0 : d;
                                    final idx = _selectedItems.indexWhere(
                                      (e) => _buildRowKey(e) == rowKey,
                                    );
                                    if (idx != -1) {
                                      _selectedItems[idx] = item.copyWith(
                                        quantityPicked: nonNegative,
                                      );
                                    }
                                  });
                                }
                              },
                            ),
                            if (_currentPickedQty(item) > 0) ...[
                              if (_savedBatchKeys.contains(rowKey)) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _showSelectBatchesDialog(item),
                                  child: Text(
                                    '${_currentPickedQty(item).toInt()} pcs taken from\n${_savedBatchCounts[rowKey] ?? 1} ${(_savedBatchCounts[rowKey] ?? 1) == 1 ? 'batch' : 'batches'}.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _showSelectBatchesDialog(item),
                                  child: Text(
                                    'Select Batch and Bin',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
                              LucideIcons.x,
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
        ],
      ),
    );
  }

  Widget _buildTableByItem() {
    // Group _selectedItems by productId
    final Map<String, List<WarehouseStockData>> grouped = {};
    for (var item in _selectedItems) {
      if (!grouped.containsKey(item.productId)) {
        grouped[item.productId] = [];
      }
      grouped[item.productId]!.add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Total Items: ${grouped.length}',
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
              IntrinsicHeight(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 4,
                              child: Text(
                                'ITEMS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: _borderCol),
                            const Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  'ASSIGNEE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: _borderCol),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 8,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
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
                            const VerticalDivider(width: 1, color: _borderCol),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text(
                                  'QTY ORDERED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: _borderCol),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  'PREFERRED BIN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
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
                                    const Text(
                                      'QTY TO PICK',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const _PicklistZTooltip(
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'QTY PICKED',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const _PicklistZTooltip(
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
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final productId = grouped.keys.elementAt(index);
                  final itemsInGroup = grouped[productId]!;
                  final firstItem = itemsInGroup.first;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _borderCol)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left side spanning details (Item & Assignee)
                          Expanded(
                            flex: 6, // 4 + 2
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: _borderCol),
                                ),
                              ),
                              padding: const EdgeInsets.only(
                                left: 0,
                                right: 0,
                                top: 12,
                                bottom: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          firstItem.productName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Total Orders: ${itemsInGroup.length}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const VerticalDivider(
                                    width: 1,
                                    color: _borderCol,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: MouseRegion(
                                        onEnter: (_) => setState(
                                          () => _hoveredAssigneeFieldKeys.add(
                                            'item_assignee_$productId',
                                          ),
                                        ),
                                        onExit: (_) => setState(
                                          () => _hoveredAssigneeFieldKeys
                                              .remove('item_assignee_$productId'),
                                        ),
                                        child: Consumer(
                                          builder: (context, ref, _) {
                                            final usersAsync = ref.watch(
                                              allUsersProvider,
                                            );
                                            final assigneeOptions =
                                                usersAsync.maybeWhen(
                                                  data: (users) => users
                                                      .map((u) => u.fullName)
                                                      .where(
                                                        (name) =>
                                                            name.trim().isNotEmpty,
                                                      )
                                                      .toList(),
                                                  orElse: () => <String>[],
                                                );
                                            const fallbackAssignees = <String>[
                                              'User 1',
                                              'User 2',
                                              'User 3',
                                            ];
                                            final assigneeItems =
                                                assigneeOptions.isNotEmpty
                                                ? assigneeOptions
                                                : fallbackAssignees;

                                            return FormDropdown<String>(
                                              hint: 'Select User',
                                              value: assigneeItems.contains(
                                                _itemGroupAssigneeByProductId[
                                                    productId],
                                              )
                                                  ? _itemGroupAssigneeByProductId[
                                                        productId]
                                                  : null,
                                              items: assigneeItems,
                                              border: Border.all(
                                                color:
                                                    _hoveredAssigneeFieldKeys
                                                            .contains(
                                                              'item_assignee_$productId',
                                                            )
                                                        ||
                                                        _itemGroupAssigneeByProductId[
                                                                productId] !=
                                                            null
                                                    ? const Color(0xFF3B82F6)
                                                    : Colors.transparent,
                                              ),
                                              fillColor: Colors.transparent,
                                                displayStringForValue: (name) =>
                                                  name,
                                                searchStringForValue: (name) =>
                                                  name,
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
                                                        ? const Color(
                                                            0xFF3B82F6,
                                                          )
                                                        : (isSelected
                                                              ? const Color(
                                                                  0xFFF3F4F6,
                                                                )
                                                              : Colors
                                                                    .transparent),
                                                    child: Text(
                                                      item,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: isHovered
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF1F2937,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                              onChanged: (val) => setState(
                                                () =>
                                                    _itemGroupAssigneeByProductId[
                                                      productId
                                                    ] = val,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Right side rows for each order
                          Expanded(
                            flex: 8, // 3 + 1 + 1 + 2 + 1
                            child: Column(
                              children: itemsInGroup.map((item) {
                                final isLast = item == itemsInGroup.last;
                                final available = item.availableQuantity;

                                return Container(
                                  padding: const EdgeInsets.only(
                                    left: 0,
                                    right: 0,
                                    top: 8,
                                    bottom: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: isLast
                                        ? null
                                        : const Border(
                                            bottom: BorderSide(
                                              color: _borderCol,
                                            ),
                                          ),
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                        flex: 1,
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
                                      const VerticalDivider(
                                        width: 1,
                                        color: _borderCol,
                                      ),
                                      Expanded(
                                        flex: 1,
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
                                      const VerticalDivider(
                                        width: 1,
                                        color: _borderCol,
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            item.preferredBin ?? 'N/A',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const VerticalDivider(
                                        width: 1,
                                        color: _borderCol,
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            _buildQuantityField(
                                              fieldKey:
                                                  '${_buildRowKey(item)}_to_pick_compact',
                                              initialValue:
                                                  item.quantityToPick ?? 1.0,
                                              onChanged: (val) {
                                                final d = double.tryParse(val);
                                                if (d != null) {
                                                  setState(() {
                                                    final idx = _selectedItems
                                                        .indexOf(item);
                                                    if (idx != -1) {
                                                      final normalizedToPick =
                                                          d < 0 ? 0.0 : d;
                                                      _selectedItems[idx] = item
                                                          .copyWith(
                                                            quantityToPick:
                                                                normalizedToPick,
                                                          );
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
                                                color:
                                                    available >=
                                                        (item.quantityToPick ??
                                                            1.0)
                                                    ? _textSecondary
                                                    : _dangerRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const VerticalDivider(
                                        width: 1,
                                        color: _borderCol,
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            _buildQuantityField(
                                              fieldKey:
                                                  '${_buildRowKey(item)}_picked_compact',
                                              initialValue: _currentPickedQty(
                                                item,
                                              ),
                                              hasError:
                                                  _currentPickedQty(item) >
                                                  (_currentQtyToPick(item) +
                                                      0.0001),
                                              showPermanentBorder:
                                                  (_currentPickedQty(item) -
                                                          _currentQtyToPick(
                                                            item,
                                                          ))
                                                      .abs() <
                                                  0.0001,
                                              onChanged: (val) {
                                                final d = double.tryParse(val);
                                                if (d != null) {
                                                  setState(() {
                                                    final nonNegative = d < 0 ? 0.0 : d;
                                                    final idx = _selectedItems
                                                        .indexOf(item);
                                                    if (idx != -1) {
                                                      _selectedItems[idx] = item
                                                          .copyWith(
                                                            quantityPicked: nonNegative,
                                                          );
                                                    }
                                                  });
                                                }
                                              },
                                            ),
                                            if (_currentPickedQty(item) >
                                                0) ...[
                                              if (_savedBatchKeys.contains(
                                                _buildRowKey(item),
                                              )) ...[
                                                const SizedBox(height: 6),
                                                InkWell(
                                                  onTap: () =>
                                                      _showSelectBatchesDialog(
                                                        item,
                                                      ),
                                                  child: Text(
                                                    '${_currentPickedQty(item).toInt()} pcs taken from\n${_savedBatchCounts[_buildRowKey(item)] ?? 1} ${(_savedBatchCounts[_buildRowKey(item)] ?? 1) == 1 ? 'batch' : 'batches'}.',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF2563EB),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                              ] else ...[
                                                const SizedBox(height: 6),
                                                InkWell(
                                                  onTap: () =>
                                                      _showSelectBatchesDialog(
                                                        item,
                                                      ),
                                                  child: Text(
                                                    'Select Batch and Bin',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors
                                                          .orange
                                                          .shade700,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: InkWell(
                                          onTap: () => setState(
                                            () => _selectedItems.remove(item),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              LucideIcons.x,
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
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableBySalesOrder() {
    // Group _selectedItems by salesOrderId
    final Map<String, List<WarehouseStockData>> grouped = {};
    for (var item in _selectedItems) {
      final so = item.salesOrderNumber ?? 'Unknown SO';
      if (!grouped.containsKey(so)) {
        grouped[so] = [];
      }
      grouped[so]!.add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Total Sales Orders: ${grouped.length}',
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'SALES ORDER#',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: _borderCol),
                            const Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  'ASSIGNEE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: _borderCol),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text(
                                  'ITEMS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: _borderCol),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text(
                                  'QTY ORDERED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const VerticalDivider(width: 1, color: _borderCol),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text(
                                  'PREFERRED BIN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
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
                                    const Text(
                                      'QTY TO PICK',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const _PicklistZTooltip(
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'QTY PICKED',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const _PicklistZTooltip(
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
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final so = grouped.keys.elementAt(index);
                  final itemsInGroup = grouped[so]!;
                  final firstItem = itemsInGroup.first;

                  return Container(
                    padding: const EdgeInsets.only(left: 16, right: 0),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _borderCol)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left side spanning details (Order & Assignee)
                          Expanded(
                            flex: 5,
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: _borderCol),
                                ),
                              ),
                              padding: const EdgeInsets.only(
                                left: 0,
                                right: 0,
                                top: 12,
                                bottom: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          so,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Customer: ${firstItem.customerName ?? "Unknown"}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _textSecondary,
                                          ),
                                        ),
                                        Text(
                                          'Total Items: ${itemsInGroup.length}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const VerticalDivider(
                                    width: 1,
                                    color: _borderCol,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: MouseRegion(
                                        onEnter: (_) => setState(
                                          () => _hoveredAssigneeFieldKeys.add(
                                            'so_assignee_$so',
                                          ),
                                        ),
                                        onExit: (_) => setState(
                                          () => _hoveredAssigneeFieldKeys
                                              .remove('so_assignee_$so'),
                                        ),
                                        child: Consumer(
                                          builder: (context, ref, _) {
                                            final usersAsync = ref.watch(
                                              allUsersProvider,
                                            );
                                            final assigneeOptions =
                                                usersAsync.maybeWhen(
                                                  data: (users) => users
                                                      .map((u) => u.fullName)
                                                      .where(
                                                        (name) =>
                                                            name.trim().isNotEmpty,
                                                      )
                                                      .toList(),
                                                  orElse: () => <String>[],
                                                );
                                            const fallbackAssignees = <String>[
                                              'User 1',
                                              'User 2',
                                              'User 3',
                                            ];
                                            final assigneeItems =
                                                assigneeOptions.isNotEmpty
                                                ? assigneeOptions
                                                : fallbackAssignees;

                                            return FormDropdown<String>(
                                              hint: 'Select User',
                                              value: assigneeItems.contains(
                                                _salesOrderGroupAssigneeByOrderNumber[
                                                    so],
                                              )
                                                  ? _salesOrderGroupAssigneeByOrderNumber[
                                                        so]
                                                  : null,
                                              items: assigneeItems,
                                              border: Border.all(
                                                color:
                                                    _hoveredAssigneeFieldKeys
                                                            .contains(
                                                              'so_assignee_$so',
                                                            )
                                                        ||
                                                        _salesOrderGroupAssigneeByOrderNumber[
                                                                so] !=
                                                            null
                                                    ? const Color(0xFF3B82F6)
                                                    : Colors.transparent,
                                              ),
                                              fillColor: Colors.transparent,
                                                displayStringForValue: (name) =>
                                                  name,
                                                searchStringForValue: (name) =>
                                                  name,
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
                                                        ? const Color(
                                                            0xFF3B82F6,
                                                          )
                                                        : (isSelected
                                                              ? const Color(
                                                                  0xFFF3F4F6,
                                                                )
                                                              : Colors
                                                                    .transparent),
                                                    child: Text(
                                                      item,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: isHovered
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF1F2937,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                              onChanged: (val) => setState(
                                                () =>
                                                    _salesOrderGroupAssigneeByOrderNumber[
                                                      so
                                                    ] = val,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Right side rows for each item
                          Expanded(
                            flex: 9, // 4 + 1 + 1 + 2 + 1
                            child: Column(
                              children: itemsInGroup.map((item) {
                                final isLast = item == itemsInGroup.last;
                                final available = item.availableQuantity;

                                return Container(
                                  padding: const EdgeInsets.only(
                                    left: 0,
                                    right: 0,
                                    top: 8,
                                    bottom: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: isLast
                                        ? null
                                        : const Border(
                                            bottom: BorderSide(
                                              color: _borderCol,
                                            ),
                                          ),
                                  ),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: _textPrimary,
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
                                      const VerticalDivider(
                                        width: 1,
                                        color: _borderCol,
                                      ),
                                      Expanded(
                                        flex: 1,
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
                                      const VerticalDivider(
                                        width: 1,
                                        color: _borderCol,
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Text(
                                            item.preferredBin ?? 'N/A',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const VerticalDivider(
                                        width: 1,
                                        color: _borderCol,
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            _buildQuantityField(
                                              fieldKey:
                                                  '${_buildRowKey(item)}_to_pick_mobile',
                                              initialValue:
                                                  item.quantityToPick ?? 1.0,
                                              onChanged: (val) {
                                                final d = double.tryParse(val);
                                                if (d != null) {
                                                  setState(() {
                                                    final idx = _selectedItems
                                                        .indexOf(item);
                                                    if (idx != -1) {
                                                      final normalizedToPick =
                                                          d < 0 ? 0.0 : d;
                                                      _selectedItems[idx] = item
                                                          .copyWith(
                                                            quantityToPick:
                                                                normalizedToPick,
                                                          );
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
                                                color:
                                                    available >=
                                                        (item.quantityToPick ??
                                                            1.0)
                                                    ? _textSecondary
                                                    : _dangerRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const VerticalDivider(
                                        width: 1,
                                        color: _borderCol,
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            _buildQuantityField(
                                              fieldKey:
                                                  '${_buildRowKey(item)}_picked_mobile',
                                              initialValue: _currentPickedQty(
                                                item,
                                              ),
                                              hasError:
                                                  _currentPickedQty(item) >
                                                  (_currentQtyToPick(item) +
                                                      0.0001),
                                              showPermanentBorder:
                                                  (_currentPickedQty(item) -
                                                          _currentQtyToPick(
                                                            item,
                                                          ))
                                                      .abs() <
                                                  0.0001,
                                              onChanged: (val) {
                                                final d = double.tryParse(val);
                                                if (d != null) {
                                                  setState(() {
                                                    final nonNegative = d < 0 ? 0.0 : d;
                                                    final idx = _selectedItems
                                                        .indexOf(item);
                                                    if (idx != -1) {
                                                      _selectedItems[idx] = item
                                                          .copyWith(
                                                            quantityPicked: nonNegative,
                                                          );
                                                    }
                                                  });
                                                }
                                              },
                                            ),
                                            if (_currentPickedQty(item) >
                                                0) ...[
                                              if (_savedBatchKeys.contains(
                                                _buildRowKey(item),
                                              )) ...[
                                                const SizedBox(height: 6),
                                                InkWell(
                                                  onTap: () =>
                                                      _showSelectBatchesDialog(
                                                        item,
                                                      ),
                                                  child: Text(
                                                    '${_currentPickedQty(item).toInt()} pcs taken from\n${_savedBatchCounts[_buildRowKey(item)] ?? 1} ${(_savedBatchCounts[_buildRowKey(item)] ?? 1) == 1 ? 'batch' : 'batches'}.',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF2563EB),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                              ] else ...[
                                                const SizedBox(height: 6),
                                                InkWell(
                                                  onTap: () =>
                                                      _showSelectBatchesDialog(
                                                        item,
                                                      ),
                                                  child: Text(
                                                    'Select Batch and Bin',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors
                                                          .orange
                                                          .shade700,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: InkWell(
                                          onTap: () => setState(
                                            () => _selectedItems.remove(item),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              LucideIcons.x,
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
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
              borderSide: const BorderSide(color: _focusBorder, width: 1.5),
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
                    // Simulate API call
                    await Future.delayed(const Duration(seconds: 1));
                    if (mounted) {
                      setState(() => _isSaving = false);
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Picklist generated successfully'),
                          backgroundColor: _greenBtn,
                        ),
                      );
                    }
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
                : const Text(
                    'Generate picklist',
                    style: TextStyle(
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
    final warehouseId = _selectedWarehouse!.outletId ?? _selectedWarehouse!.id;

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
                warehouseItems: allItems,
                warehouseName: _selectedWarehouse!.name,
                initialGrouping: _selectedGroup ?? 'No Grouping',
                onGroupingChanged: (val) =>
                    setState(() => _selectedGroup = val),
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
}

class _AddItemsDialogContent extends StatefulWidget {
  final List<WarehouseStockData> warehouseItems;
  final String warehouseName;
  final String initialGrouping;
  final Function(String) onGroupingChanged;
  final Function(List<WarehouseStockData>) onItemsSelected;

  const _AddItemsDialogContent({
    required this.warehouseItems,
    required this.warehouseName,
    required this.initialGrouping,
    required this.onGroupingChanged,
    required this.onItemsSelected,
  });

  @override
  State<_AddItemsDialogContent> createState() => _AddItemsDialogContentState();
}

class _AddItemsDialogContentState extends State<_AddItemsDialogContent> {
  final Set<String> selectedRowKeys = {};
  bool _isCustomerFilterHovered = false;
  bool _isItemsFilterHovered = false;
  bool _isSalesOrdersFilterHovered = false;

  String _buildRowKey(WarehouseStockData item) {
    return '${item.productId}_${item.batchNo ?? ''}_${item.salesOrderId ?? ''}';
  }

  late String _currentGrouping;
  String searchQuery = '';
  int activeTab = 0; // 0 = All Items, 1 = Selected Items
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _currentGrouping = widget.initialGrouping;

    // Populate filters from data
    final distinctCustomers = <String, String>{};
    final distinctItems = <String, String>{};
    final distinctOrders = <String, String>{};

    for (var item in widget.warehouseItems) {
      if (item.customerId != null && item.customerName != null) {
        distinctCustomers[item.customerId!] = item.customerName!;
      }
      distinctItems[item.productId] = item.productName;
      if (item.salesOrderId != null && item.salesOrderNumber != null) {
        distinctOrders[item.salesOrderId!] = item.salesOrderNumber!;
      }
    }

    customers = distinctCustomers.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
    items = distinctItems.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();
    salesOrders = distinctOrders.entries
        .map((e) => {'id': e.key, 'number': e.value})
        .toList();
  }

  // Real filter data
  List<dynamic> customers = [];
  List<dynamic> items = [];
  List<dynamic> salesOrders = [];

  bool isLoadingFilters = false;

  bool isSearching = false;

  // Selection states
  Set<String> _selectedCustomerId = <String>{};
  Set<String> _selectedProductId = <String>{};
  Set<String> _selectedSalesOrderId = <String>{};
  Set<String> _appliedCustomerId = <String>{};
  Set<String> _appliedProductId = <String>{};
  Set<String> _appliedSalesOrderId = <String>{};

  void _onSearch() async {
    setState(() {
      isSearching = true;
      _appliedCustomerId = Set<String>.from(_selectedCustomerId);
      _appliedProductId = Set<String>.from(_selectedProductId);
      _appliedSalesOrderId = Set<String>.from(_selectedSalesOrderId);
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => isSearching = false);
  }

  void _toggleSelectAll(List<WarehouseStockData> items) {
    setState(() {
      if (selectedRowKeys.length == items.length) {
        selectedRowKeys.clear();
      } else {
        selectedRowKeys.addAll(items.map((e) => _buildRowKey(e)));
      }
    });
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
    final bool selectedAndHovered = isSelected && isHovered;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selectedAndHovered
            ? const Color(0xFF3B82F6)
            : (isSelected ? const Color(0xFFF3F4F6) : Colors.white),
        borderRadius: BorderRadius.circular(4),
        border: (!isSelected && isHovered)
            ? Border.all(color: const Color(0xFFE5E7EB))
            : null,
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
                color: selectedAndHovered ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFFEF4444),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only use warehouse items passed from parent to avoid async merge freezes
    final List<WarehouseStockData> displayItems = [...widget.warehouseItems];

    final filteredItems = displayItems.where((item) {
      // Apply Text Search
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!item.productName.toLowerCase().contains(query) &&
            !item.productCode.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Apply Filters (INCLUSIVE: show items that match the selected options)
      if (_appliedCustomerId.isNotEmpty) {
        if (!_appliedCustomerId.contains(item.customerId)) return false;
      }
      if (_appliedProductId.isNotEmpty) {
        if (!_appliedProductId.contains(item.productId)) return false;
      }
      if (_appliedSalesOrderId.isNotEmpty) {
        if (!_appliedSalesOrderId.contains(item.salesOrderId)) return false;
      }

      return true;
    }).toList();

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
            _buildTabsAndGroupBy(filteredItems.length),

            // Table
            Expanded(
              child: activeTab == 0
                  ? _buildItemsTable(filteredItems)
                  : _buildSelectedItemsTable(displayItems),
            ),

            // Footer
            _buildDialogFooter(displayItems),
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
              const _PicklistZTooltip(
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
          _PicklistZTooltip(
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
                child: Consumer(
                  builder: (context, ref, _) {
                    final customersAsync = ref.watch(salesCustomersProvider);
                    return Column(
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
                          child: FormDropdown<SalesCustomer>(
                            hint: 'Click or Type to select',
                            multiSelect: true,
                            value: null,
                            onChanged: (_) {},
                            border: _buildFilterFieldBorder(
                              isHovered: _isCustomerFilterHovered,
                              hasValue: _selectedCustomerId.isNotEmpty,
                            ),
                            selectedValues: customersAsync.maybeWhen(
                              data: (list) => list
                                  .where((c) => _selectedCustomerId.contains(c.id))
                                  .toList(),
                              orElse: () => [],
                            ),
                            items: customersAsync.maybeWhen(
                              data: (list) => list,
                              orElse: () => [],
                            ),
                            onSelectedValuesChanged: (vals) => setState(() {
                              _selectedCustomerId = vals.map((v) => v.id).toSet();
                            }),
                            displayStringForValue: (val) => val.displayName,
                            showSearch: true,
                            searchStringForValue: (val) => val.displayName,
                            hideSelectedItemsInMultiSelect: false,
                            itemBuilder: (item, isSelected, isHovered) =>
                                _buildFilterDropdownItem(
                                  label: item.displayName,
                                  isSelected: isSelected,
                                  isHovered: isHovered,
                                ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              // Items filter
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final productsAsync = ref.watch(itemsControllerProvider);
                    return Column(
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
                          child: FormDropdown<Item>(
                            hint: 'Click or Type to select',
                            multiSelect: true,
                            value: null,
                            onChanged: (_) {},
                            border: _buildFilterFieldBorder(
                              isHovered: _isItemsFilterHovered,
                              hasValue: _selectedProductId.isNotEmpty,
                            ),
                            selectedValues: _selectedProductId.isEmpty
                                ? []
                                : productsAsync.items
                                      .where(
                                        (p) => _selectedProductId.contains(p.id),
                                      )
                                      .toList(),
                            items: productsAsync.items,
                            onSelectedValuesChanged: (vals) => setState(() {
                              _selectedProductId = vals
                                  .map((v) => v.id ?? '')
                                  .toSet();
                            }),
                            displayStringForValue: (val) => val.productName,
                            showSearch: true,
                            searchStringForValue: (val) => val.productName,
                            hideSelectedItemsInMultiSelect: false,
                            itemBuilder: (item, isSelected, isHovered) =>
                                _buildFilterDropdownItem(
                                  label: item.productName,
                                  isSelected: isSelected,
                                  isHovered: isHovered,
                                ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              // Sales Orders filter
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final soAsync = ref.watch(salesOrderControllerProvider);
                    return Column(
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
                          onExit: (_) => setState(
                            () => _isSalesOrdersFilterHovered = false,
                          ),
                          child: FormDropdown<SalesOrder>(
                            hint: 'Click or Type to select',
                            multiSelect: true,
                            value: null,
                            onChanged: (_) {},
                            border: _buildFilterFieldBorder(
                              isHovered: _isSalesOrdersFilterHovered,
                              hasValue: _selectedSalesOrderId.isNotEmpty,
                            ),
                            selectedValues: soAsync.maybeWhen(
                              data: (list) => list
                                  .where(
                                    (s) => _selectedSalesOrderId.contains(s.id),
                                  )
                                  .toList(),
                              orElse: () => [],
                            ),
                            items: soAsync.maybeWhen(
                              data: (list) => list,
                              orElse: () => [],
                            ),
                            onSelectedValuesChanged: (vals) => setState(() {
                              _selectedSalesOrderId = vals
                                  .map((v) => v.id)
                                  .toSet();
                            }),
                            displayStringForValue: (val) => val.saleNumber,
                            showSearch: true,
                            searchStringForValue: (val) => val.saleNumber,
                            hideSelectedItemsInMultiSelect: false,
                            itemBuilder: (item, isSelected, isHovered) =>
                                _buildFilterDropdownItem(
                                  label: item.saleNumber,
                                  isSelected: isSelected,
                                  isHovered: isHovered,
                                ),
                          ),
                        ),
                      ],
                    );
                  },
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
                width: 140,
                height: 40,
                child: FormDropdown<String>(
                  value: _currentGrouping,
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
                      setState(() => _currentGrouping = val);
                      widget.onGroupingChanged(val);
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

  Widget _buildItemsTable(List<WarehouseStockData> items) {
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
                      items.isNotEmpty &&
                      selectedRowKeys.length == items.length,
                  onChanged: (val) => _toggleSelectAll(items),
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
                  child: Text(
                    itemOrHeader['title'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
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
                    _buildTableCheckbox(isSelected, () {
                      setState(() {
                        if (isSelected) {
                          selectedRowKeys.remove(rowKey);
                        } else {
                          selectedRowKeys.add(rowKey);
                        }
                      });
                    }),
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

  Widget _buildSelectedItemsTable(List<WarehouseStockData> allMergedItems) {
    final selectedItems = allMergedItems
        .where((item) => selectedRowKeys.contains(_buildRowKey(item)))
        .toList();

    if (selectedItems.isEmpty) {
      return const Center(
        child: Text(
          'No items selected yet',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
      );
    }

    return _buildItemsTable(selectedItems);
  }

  Widget _headerCell(String text, {bool hasSort = false, TextAlign? align}) {
    return Row(
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
              Icon(
                LucideIcons.chevronUp,
                size: 8,
                color: Color(0xFF9CA3AF),
              ),
              Icon(
                LucideIcons.chevronDown,
                size: 8,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ],
      ],
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

  Widget _buildDialogFooter(List<WarehouseStockData> allMergedItems) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () {
              final selectedItems = allMergedItems
                  .where((e) => selectedRowKeys.contains(_buildRowKey(e)))
                  .toList();
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
        ],
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
  final List<Map<String, String>>? batchDataList;

  const _PicklistBatchDialogResult({
    required this.overwriteLineItem,
    required this.batchCount,
    required this.appliedQuantity,
    this.batchDataList,
  });
}

class _PicklistSelectBatchesDialog extends StatefulWidget {
  final String itemName;
  final String warehouseName;
  final double totalQuantity;
  final List<String> existingBatchRefs;
  final List<Map<String, String>>? savedBatchData;

  const _PicklistSelectBatchesDialog({
    required this.itemName,
    required this.warehouseName,
    required this.totalQuantity,
    required this.existingBatchRefs,
    this.savedBatchData,
  });

  @override
  State<_PicklistSelectBatchesDialog> createState() =>
      _PicklistSelectBatchesDialogState();
}

class _PicklistSelectBatchesDialogState
    extends State<_PicklistSelectBatchesDialog> {
  static const double _batchDropdownHeight = 38;
  static const double _batchTextFieldHeight = 38;
  final List<_PicklistBatchRowController> _rows = [];
  final Set<int> _hoveredFocRows = <int>{};
  final List<String> _mockBinLocations = const <String>[
    'A1-R1-S1',
    'A1-R1-S2',
    'A1-R2-S1',
    'B1-R1-S1',
    'B1-R2-S3',
    'C1-R4-S2',
  ];
  bool _overwriteLineItem = false;
  bool _showMfgDetails = false;
  bool _showFocColumn = false;
  String? _dialogErrorMessage;
  static const String _quantityMismatchMessage =
      'There\'s a mismatch between the quantity entered in the line item and the total quantity across all batches. Click the checkbox to overwrite the quantity in the line item.';

  @override
  void initState() {
    super.initState();
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
        row.mfgDateCtrl.text = batchData['mfgDate'] ?? '';
        row.mfgBatchCtrl.text = batchData['mfgBatch'] ?? '';
        row.qtyOutCtrl.text =
            batchData['qtyOut'] ?? widget.totalQuantity.toInt().toString();
        row.focCtrl.text = batchData['foc'] ?? '';
        _rows.add(row);
      }
    } else {
      final firstRow = _PicklistBatchRowController();
      firstRow.qtyOutCtrl.text = widget.totalQuantity.toInt().toString();
      _rows.add(firstRow);
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  double get _totalQuantityOut => _rows.fold<double>(
    0,
    (sum, r) => sum + (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0),
  );

  double get _quantityToBeAdded =>
      (widget.totalQuantity - _totalQuantityOut).clamp(0, widget.totalQuantity);

  bool get _hasQuantityMismatch => _totalQuantityOut != widget.totalQuantity;

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
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          child: TextField(
            controller: controller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : null,
            inputFormatters: isNumber
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : [],
            textAlign: isNumber ? TextAlign.right : TextAlign.left,
            textAlignVertical: TextAlignVertical.center,
            strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
            style: const TextStyle(
              fontSize: 13,
              color: _textPrimary,
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
              fillColor: Colors.white,
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
                borderSide: const BorderSide(color: _borderCol),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _focusBorder, width: 1.4),
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
            style: const TextStyle(
              fontSize: 13,
              color: _textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              isDense: false,
              hintText: '',
              hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              constraints: const BoxConstraints(
                minHeight: _batchTextFieldHeight,
                maxHeight: _batchTextFieldHeight,
              ),
              suffixIcon: const Icon(
                LucideIcons.calendar,
                size: 14,
                color: _textSecondary,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 32,
                maxWidth: 32,
                minHeight: _batchTextFieldHeight,
                maxHeight: _batchTextFieldHeight,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _borderCol),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _focusBorder, width: 1.4),
              ),
            ),
            onTap: () async {
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
                    'Overwrite the line item with ${_totalQuantityOut.toInt()} quantities',
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
                  _headerCell(
                    'BATCH REFERENCE*',
                    15,
                    alignment: TextAlign.center,
                  ),
                  _headerCell('BATCH NO*', 15),
                  _headerCell('UNIT PACK*', 15),
                  _headerCell('MRP*', 15),
                  _headerCell('PTR', 15),
                  _headerCell('EXPIRY DATE*', 15),
                  if (_showMfgDetails) ...[
                    _headerCell('MANUFACTURING DATE', 15),
                    _headerCell('MANUFACTURING BATCH', 15),
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
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 15,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
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
                                        _mockBinLocations.contains(
                                          row.binLocationCtrl.text.trim(),
                                        )
                                        ? row.binLocationCtrl.text.trim()
                                        : null,
                                    items: _mockBinLocations,
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
                            // Batch Reference — always a FormDropdown
                            Expanded(
                              flex: 15,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
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
                                        widget.existingBatchRefs.contains(
                                          row.batchRefCtrl.text.trim(),
                                        )
                                        ? row.batchRefCtrl.text.trim()
                                        : null,
                                    items: widget.existingBatchRefs,
                                    hint: 'Select Ref',
                                    showSearch: true,
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
                                        row.batchRefCtrl.text = val ?? '';
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            _buildInput(
                              controller: row.batchNoCtrl,
                              flex: 15,
                              hint: 'Batch No',
                              isNumber: true,
                            ),
                            _buildInput(
                              controller: row.unitPackCtrl,
                              flex: 15,
                              hint: 'Pack',
                              isNumber: true,
                            ),
                            _buildInput(
                              controller: row.mrpCtrl,
                              flex: 15,
                              hint: '0',
                              isNumber: true,
                            ),
                            _buildInput(
                              controller: row.ptrCtrl,
                              flex: 15,
                              hint: '0',
                              isNumber: true,
                            ),
                            _buildDatePicker(
                              controller: row.expDateCtrl,
                              anchorKey: row.expKey,
                              flex: 15,
                              currentDate: row.expDate,
                              onDateChanged: (d) =>
                                  setState(() => row.expDate = d),
                            ),
                            if (_showMfgDetails) ...[
                              _buildDatePicker(
                                controller: row.mfgDateCtrl,
                                anchorKey: row.mfgKey,
                                flex: 15,
                                currentDate: row.mfgDate,
                                onDateChanged: (d) =>
                                    setState(() => row.mfgDate = d),
                              ),
                              _buildInput(
                                controller: row.mfgBatchCtrl,
                                flex: 15,
                                hint: 'Mfg Batch',
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
                              child: IconButton(
                                onPressed: () => _removeRow(index),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  LucideIcons.xCircle,
                                  size: 14,
                                  color: _dangerRed,
                                ),
                              ),
                            ),
                          ],
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
                        if (row.expDate == null) {
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
                          appliedQuantity: _overwriteLineItem
                              ? _totalQuantityOut
                              : widget.totalQuantity,
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
                        Radio<bool>(
                          value: true,
                          groupValue: _isAuto,
                          onChanged: (val) => setState(() => _isAuto = val!),
                          activeColor: const Color(0xFF3B82F6),
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
                        Radio<bool>(
                          value: false,
                          groupValue: _isAuto,
                          onChanged: (val) => setState(() => _isAuto = val!),
                          activeColor: const Color(0xFF3B82F6),
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

class _PicklistZTooltip extends StatefulWidget {
  final String message;
  final Widget? child;

  const _PicklistZTooltip({required this.message, this.child});

  @override
  State<_PicklistZTooltip> createState() => _PicklistZTooltipState();
}

class _PicklistZTooltipState extends State<_PicklistZTooltip> {
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();
  bool _isHovering = false;
  bool _isTooltipHovering = false;

  void _showTooltip() {
    if (_entry != null) return;
    _entry = _createOverlayEntry();
    if (_entry != null) {
      Overlay.of(context).insert(_entry!);
    }
  }

  void _hideTooltip() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted && !_isHovering && !_isTooltipHovering) {
      _entry?.remove();
      _entry = null;
    }
  }

  OverlayEntry? _createOverlayEntry() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
              offset: const Offset(0, 8),
              child: FractionalTranslation(
                translation: const Offset(0, 0),
                child: MouseRegion(
                  onEnter: (_) => _isTooltipHovering = true,
                  onExit: (_) {
                    _isTooltipHovering = false;
                    _hideTooltip();
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomPaint(
                          size: const Size(10, 6),
                          painter: _PicklistTooltipArrowPainter(),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _isHovering = true;
          _showTooltip();
        },
        onExit: (_) {
          _isHovering = false;
          _hideTooltip();
        },
        child:
            widget.child ??
            const Icon(LucideIcons.helpCircle, size: 14, color: _textSecondary),
      ),
    );
  }
}

class _PicklistTooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
