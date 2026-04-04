import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../shared/widgets/inputs/zerpai_date_picker.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/inputs/z_tooltip.dart';
import '../../../sales/controllers/sales_order_controller.dart';
import '../../../sales/models/sales_order_model.dart';
import '../../../sales/models/sales_order_item_model.dart';

const Color _textPrimary = Color(0xFF1F2937);
const Color _textSecondary = Color(0xFF6B7280);
const Color _borderCol = Color(0xFFE5E7EB);
const Color _focusBorder = Color(0xFF3B82F6);
const Color _greenBtn = Color(0xFF10B981);
const Color _bgLight = Color(0xFFF9FAFB);
const Color _dangerRed = Color(0xFFDC2626);

class InventoryPackagesCreateScreen extends ConsumerStatefulWidget {
  const InventoryPackagesCreateScreen({super.key});

  @override
  ConsumerState<InventoryPackagesCreateScreen> createState() =>
      _InventoryPackagesCreateScreenState();
}

class _InventoryPackagesCreateScreenState
    extends ConsumerState<InventoryPackagesCreateScreen> {

  bool _isManualMode = false;
  List<_PackageItem> _items = [];
  final List<_PackageItemRowController> _rowControllers = [];
  final Set<String> _hoveredQtyFields = {};
  final Map<int, String> _rowSelectedViews = {};
  final Set<String> _focusedQtyFields = {};
  
  Widget _commonItemBuilder<T>(T item, bool isSelected, bool isHovered, String Function(T) displayFn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isHovered 
          ? const Color(0xFF3B82F6) 
          : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
      child: Text(
        displayFn(item),
        style: TextStyle(
          fontSize: 13, 
          color: isHovered ? Colors.white : const Color(0xFF1F2937),
          fontFamily: 'Inter',
        ),
      ),
    );
  }
  final List<String?> _preferredBins = [];
  final Set<String> _hoveredBinFields = {};
  final Set<String> _focusedBinFields = {};

  String? _selectedCustomer;
  String? _selectedSalesOrder;
  SalesOrder? _selectedSalesOrderData;
  final TextEditingController _packageSlipCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _dimensionLengthCtrl = TextEditingController();
  final TextEditingController _dimensionWidthCtrl = TextEditingController();
  final TextEditingController _dimensionHeightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final GlobalKey _dateFieldKey = GlobalKey();
  DateTime? _selectedDate;
  String _dimensionUnit = 'cm';
  String _weightUnit = 'kg';

  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _dimLengthFocus = FocusNode();
  final FocusNode _dimWidthFocus = FocusNode();
  final FocusNode _dimHeightFocus = FocusNode();
  bool _dimFocused = false;

  bool _isAutoGenerate = true;
  String _packagePrefix = 'PKG-';
  int _nextNumber = 1;

  List<SalesOrderItem> _salesOrderItems = [];
  bool _isLoadingItems = false;
  final List<TextEditingController> _normalRowControllers = [];

  bool get _isSalesOrderSelected => _selectedSalesOrder != null;

  bool get _isFormValid => _isSalesOrderSelected;

  @override
  void initState() {
    super.initState();
    _packageSlipCtrl.text = _generatePackageNumber();
    _dateCtrl.text =
        "${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}";
    _weightFocusNode.addListener(() => setState(() {}));
    void dimListener() {
      final focused =
          _dimLengthFocus.hasFocus ||
          _dimWidthFocus.hasFocus ||
          _dimHeightFocus.hasFocus;
      if (focused != _dimFocused) setState(() => _dimFocused = focused);
    }

    _dimLengthFocus.addListener(dimListener);
    _dimWidthFocus.addListener(dimListener);
    _dimHeightFocus.addListener(dimListener);
  }


  void _switchToManualMode() {
    setState(() {
      _isManualMode = true;
      _items = [const _PackageItem()];
      _clearRowControllers();
      _rowControllers.add(_PackageItemRowController());
    });
  }

  void _switchToSelectionMode() {
    setState(() {
      _isManualMode = false;
      _items = _salesOrderItems.map((item) => _PackageItem(
        itemId: item.itemId,
        itemName: item.item?.productName ?? item.description ?? '',
        ordered: item.quantity,
        qtyToPack: item.quantity,
      )).toList();
      _clearRowControllers();
    });
  }

  void _clearRowControllers() {
    for (final ctrl in _rowControllers) {
      ctrl.dispose();
    }
    _rowControllers.clear();
  }

  void _insertManualRow() {
    setState(() {
      _items.add(const _PackageItem());
      _rowControllers.add(_PackageItemRowController());
    });
  }

  void _removeItem(int index) {
    if (index < _items.length) {
      setState(() {
        _items.removeAt(index);
        _rowControllers[index].dispose();
        _rowControllers.removeAt(index);
      });
    }
  }

  String _generatePackageNumber() {
    if (!_isAutoGenerate) return _packageSlipCtrl.text;
    return '$_packagePrefix${_nextNumber.toString().padLeft(5, '0')}';
  }

  @override
  void dispose() {
    _packageSlipCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    _dimensionLengthCtrl.dispose();
    _dimensionWidthCtrl.dispose();
    _dimensionHeightCtrl.dispose();
    _weightCtrl.dispose();
    _weightFocusNode.dispose();
    _dimLengthFocus.dispose();
    _dimWidthFocus.dispose();
    _dimHeightFocus.dispose();
    _clearRowControllers();
    for (var ctrl in _normalRowControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchSalesOrderItems(String salesOrderId) async {
    setState(() {
      _isLoadingItems = true;
      _salesOrderItems = [];
      _normalRowControllers.clear();
      for (var ctrl in _rowControllers) {
        ctrl.qtyCtrl.dispose();
      }
      _rowControllers.clear();
    });

    try {
      final order = await ref
          .read(salesOrderApiServiceProvider)
          .getSalesOrderById(salesOrderId);
      final items = order.items ?? [];
      if (mounted) {
        setState(() {
          _salesOrderItems = items;
          _items = items.map((item) => _PackageItem(
            itemId: item.itemId,
            itemName: item.item?.productName ?? item.description ?? '',
            ordered: item.quantity,
            qtyToPack: item.quantity,
          )).toList();

          _rowControllers.clear();
          _rowControllers.addAll(List.generate(_items.length, (_) => _PackageItemRowController()));
          for (var i = 0; i < _items.length; i++) {
            _rowControllers[i].qtyCtrl.text = _items[i].qtyToPack.toString();
          }

          _normalRowControllers.clear();
          _normalRowControllers.addAll(List.generate(items.length, (i) => TextEditingController(text: items[i].quantity.toString())));
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingItems = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching items: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(LucideIcons.box, size: 24, color: _textPrimary),
                const SizedBox(width: 12),
                const Text(
                  'New Package',
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
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: _textSecondary,
                  ),
                  splashRadius: 20,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderCol),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Group (Customer & Sale Order) — flush below divider
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 750),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormRow(
                              label: 'Customer Name',
                              child: ref.watch(salesCustomersProvider).when(
                                data: (customers) => FormDropdown<String>(
                                  fillColor: Colors.white,
                                  value: _selectedCustomer,
                                  hint: 'Select Customer',
                                  items: customers.map((e) => e.id).toList(),
                                  maxVisibleItems: 4,
                                  itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<String>(
                                    item, 
                                    isSelected, 
                                    isHovered, 
                                    (id) => customers.firstWhere((c) => c.id == id).displayName,
                                  ),
                                  displayStringForValue: (val) {
                                    final customer = customers.firstWhere((c) => c.id == val);
                                    return customer.displayName;
                                  },
                                  searchStringForValue: (val) {
                                    final customer = customers.firstWhere((c) => c.id == val);
                                    return customer.displayName;
                                  },
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedCustomer = val;
                                      _selectedSalesOrder = null;
                                    });
                                  },
                                ),
                                loading: () => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                error: (e, _) => Text('Error: $e'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFormRow(
                              label: 'Sales Order#',
                              isRequired: true,
                              child: _selectedCustomer == null
                                  ? FormDropdown<String>(
                                    fillColor: AppTheme.bgDisabled,
                                    value: null,
                                    hint: 'Select Sales Order',
                                    items: const [],
                                    itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<String>(item, isSelected, isHovered, (s) => s),
                                    displayStringForValue: (s) => s,
                                    searchStringForValue: (s) => s,
                                    onChanged: (val) {},
                                  )
                                  : ref
                                      .watch(
                                        salesOrdersByCustomerProvider(
                                          _selectedCustomer!,
                                        ),
                                      )
                                    .when(
                                      data: (orders) => FormDropdown<SalesOrder>(
                                        fillColor: Colors.white,
                                        value: _selectedSalesOrderData,
                                        hint: 'Select Sales Order',
                                        items: orders,
                                        maxVisibleItems: 4,
                                        itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<SalesOrder>(item, isSelected, isHovered, (val) => val.saleNumber),
                                        displayStringForValue: (val) => val.saleNumber,
                                        searchStringForValue: (val) => val.saleNumber,
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedSalesOrder = val?.id;
                                            _selectedSalesOrderData = val;
                                          });
                                          if (val != null) {
                                            _fetchSalesOrderItems(val.id);
                                          }
                                        },
                                      ),
                                        loading: () => const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        error: (e, _) => Text('Error: $e'),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),

                        Opacity(
                          opacity: _isSalesOrderSelected ? 1.0 : 0.3,
                          child: IgnorePointer(
                            ignoring: !_isSalesOrderSelected,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row 1: Package Slip + Date
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 380, // Adjusted for label + field
                                      child: _buildFormRow(
                                        label: 'Package Slip#',
                                        isRequired: true,
                                        child: SizedBox(
                                          width: 210,
                                          child: TextField(
                                            controller: _packageSlipCtrl,
                                            readOnly: _isAutoGenerate,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: _textPrimary,
                                              fontFamily: 'Inter',
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: _borderCol,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: _focusBorder,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              suffixIcon: ZTooltip(
                                                message:
                                                    'Click here to enable or disable auto-generation of Package numbers.',
                                                child: InkWell(
                                                  onTap:
                                                      _showPackagePreferencesDialog,
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
                                    ),
                                    const SizedBox(width: 32),
                                    SizedBox(
                                      width: 380, // Adjusted for label + field
                                      child: _buildFormRow(
                                        label: 'Date',
                                        isRequired: true,
                                        child: SizedBox(
                                          width: 210,
                                          child: TextField(
                                            controller: _dateCtrl,
                                            readOnly: true,
                                            key: _dateFieldKey,
                                            onTap: () async {
                                              final picked =
                                                  await ZerpaiDatePicker.show(
                                                    context,
                                                    initialDate:
                                                        _selectedDate ??
                                                        DateTime.now(),
                                                    targetKey: _dateFieldKey,
                                                  );
                                              if (picked != null && mounted) {
                                                setState(() {
                                                  _selectedDate = picked;
                                                  _dateCtrl.text =
                                                      "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
                                                });
                                              }
                                            },
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'dd-MM-yyyy',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                  color: _borderCol,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                  color: _borderCol,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                  color: _focusBorder,
                                                ),
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
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Dimensions',
                                        subLabel: '(Length X Width X Height)',
                                        child: Container(
                                          height: 40,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: _dimFocused ? _focusBorder : _borderCol,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            _dimensionLengthCtrl,
                                                        focusNode:
                                                            _dimLengthFocus,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontFamily: 'Inter',
                                                        ),
                                                        decoration:
                                                            const InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              enabledBorder:
                                                                  InputBorder
                                                                      .none,
                                                              focusedBorder:
                                                                  InputBorder
                                                                      .none,
                                                              hoverColor: Colors
                                                                  .transparent,
                                                              isDense: true,
                                                            ),
                                                      ),
                                                    ),
                                                    const Text(
                                                      '×',
                                                      style: TextStyle(
                                                        color: _textSecondary,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            _dimensionWidthCtrl,
                                                        focusNode:
                                                            _dimWidthFocus,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontFamily: 'Inter',
                                                        ),
                                                        decoration:
                                                            const InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              enabledBorder:
                                                                  InputBorder
                                                                      .none,
                                                              focusedBorder:
                                                                  InputBorder
                                                                      .none,
                                                              hoverColor: Colors
                                                                  .transparent,
                                                              isDense: true,
                                                            ),
                                                      ),
                                                    ),
                                                    const Text(
                                                      '×',
                                                      style: TextStyle(
                                                        color: _textSecondary,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            _dimensionHeightCtrl,
                                                        focusNode:
                                                            _dimHeightFocus,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontFamily: 'Inter',
                                                        ),
                                                        decoration:
                                                            const InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              enabledBorder:
                                                                  InputBorder
                                                                      .none,
                                                              focusedBorder:
                                                                  InputBorder
                                                                      .none,
                                                              hoverColor: Colors
                                                                  .transparent,
                                                              isDense: true,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                height: 40,
                                                width: 70,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.bgDisabled,
                                                  border: Border(
                                                    left: BorderSide(
                                                      color: _borderCol,
                                                    ),
                                                  ),
                                                ),
                                                child: FormDropdown<String>(
                                                  height: 38,
                                                  fillColor: AppTheme.bgDisabled,
                                                  border: Border.all(
                                                    color: Colors.transparent,
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                                  hideBorderDefault: true,
                                                  showSearch: false,
                                                  value: _dimensionUnit,
                                                  items: const ['cm', 'in'],
                                                  displayStringForValue: (s) => s,
                                                  searchStringForValue: (s) => s,
                                                  onChanged: (val) {
                                                    if (val == null) return;
                                                    setState(
                                                      () => _dimensionUnit = val,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    SizedBox(
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Weight',
                                        child: Container(
                                          height: 40,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: _weightFocusNode.hasFocus
                                                  ? _focusBorder
                                                  : _borderCol,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Center(
                                                  child: TextField(
                                                    controller: _weightCtrl,
                                                    focusNode: _weightFocusNode,
                                                    textAlign: TextAlign.center,
                                                    textAlignVertical:
                                                        TextAlignVertical.center,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontFamily: 'Inter',
                                                    ),
                                                    decoration:
                                                        const InputDecoration(
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                      border: InputBorder.none,
                                                      enabledBorder:
                                                          InputBorder.none,
                                                      focusedBorder:
                                                          InputBorder.none,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      isDense: true,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                height: 40,
                                                width: 60,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.bgDisabled,
                                                  border: Border(
                                                    left: BorderSide(
                                                      color: _borderCol,
                                                    ),
                                                  ),
                                                ),
                                                child: FormDropdown<String>(
                                                  height: 38,
                                                  fillColor: AppTheme.bgDisabled,
                                                  border: Border.all(
                                                    color: Colors.transparent,
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                                  hideBorderDefault: true,
                                                  showSearch: false,
                                                  value: _weightUnit,
                                                  items: const [
                                                    'kg',
                                                    'g',
                                                    'lb',
                                                    'oz',
                                                  ],
                                                  displayStringForValue: (s) => s,
                                                  searchStringForValue: (s) => s,
                                                  onChanged: (val) {
                                                    if (val == null) return;
                                                    setState(
                                                      () => _weightUnit = val,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    border: Border.all(
                                      color: const Color(0xFFFDE68A),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.info,
                                        size: 16,
                                        color: Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF92400E),
                                              fontFamily: 'Inter',
                                            ),
                                            children: [
                                              TextSpan(
                                                text: _isManualMode
                                                    ? 'You can also add all items from the sales order and manually adjust their quantities. '
                                                    : 'You can also select or scan the items to be included from the sales order. ',
                                              ),
                                              WidgetSpan(
                                                alignment: PlaceholderAlignment.baseline,
                                                baseline: TextBaseline.alphabetic,
                                                child: InkWell(
                                                  onTap: _isManualMode
                                                      ? _switchToSelectionMode
                                                      : _switchToManualMode,
                                                  child: Text(
                                                    _isManualMode
                                                        ? 'Add Manually'
                                                        : 'Select or Scan items',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: _focusBorder,
                                                      fontFamily: 'Inter',
                                                    ),
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
                                const SizedBox(height: 32),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.6,
                                    child: _buildItemsTable(),
                                  ),
                                ),
                                const SizedBox(height: 40),

                                const Text(
                                  'INTERNAL NOTES',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 350,
                                  child: TextField(
                                    controller: _notesCtrl,
                                    maxLines: 4,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Inter',
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(
                                          color: _borderCol,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(
                                          color: _borderCol,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(
                                          color: _focusBorder,
                                        ),
                                      ),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _borderCol)),
            ),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isFormValid ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? _greenBtn
                        : const Color(0xFFE5E7EB),
                    foregroundColor: _isFormValid
                        ? Colors.white
                        : const Color(0xFF9CA3AF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
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
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textPrimary,
                    side: const BorderSide(color: _borderCol),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    backgroundColor: Colors.white,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPackagePreferencesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _PackagePreferencesDialog(
        initialAutoGenerate: _isAutoGenerate,
        initialPrefix: _packagePrefix,
        initialNextNumber: _nextNumber,
        onSave: (isAuto, prefix, nextNum) {
          setState(() {
            _isAutoGenerate = isAuto;
            _packagePrefix = prefix;
            _nextNumber = nextNum;
            _packageSlipCtrl.text = _generatePackageNumber();
          });
        },
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    String? subLabel,
    bool isRequired = false,
  }) {
    final Color labelColor = isRequired
        ? const Color(0xFFDC2626)
        : const Color(0xFF1F2937); // Darker grey/black for non-required
    return Row(
      crossAxisAlignment: subLabel != null
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w400, // Regular weight as in screenshot
                      color: labelColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (isRequired)
                    const Text(
                      '*',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFDC2626),
                        fontFamily: 'Inter',
                      ),
                    ),
                ],
              ),
              if (subLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildItemsTable() {
    if (_isManualMode) {
      return _buildManualItemsTable();
    } else {
      return _buildItemsTableNormal();
    }
  }

  Widget _buildItemsTableNormal() {
    if (_isLoadingItems) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final soItems = _salesOrderItems;
    return Column(
      children: [
        _buildTableHeader(),
        if (soItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _borderCol)),
            ),
            child: const Center(
              child: Text(
                'No items found.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          )
        else
          ...soItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildItemRowNormal(index, item);
          }),
      ],
    );
  }

  Widget _buildItemRowNormal(int index, SalesOrderItem soItem) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  soItem.item?.productName ?? soItem.description ?? 'Unknown Item',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  'Unit: ${soItem.item?.unitName ?? "pcs"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                if (soItem.item?.sku != null && soItem.item?.sku != "")
                  Text(
                    'SKU: ${soItem.item?.sku}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                if (_items[index].batches.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _items[index].batches.map((batch) {
                      final hasBin = batch.binLocation != null && batch.binLocation!.isNotEmpty;
                      final hasRef = batch.batchRef != null && batch.batchRef!.isNotEmpty;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F9F5),
                          border: Border.all(color: const Color(0xFFCFE9D8)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Batch: ${batch.batchNo} (${batch.quantity} pcs)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                            if (hasBin || hasRef)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${hasBin ? "Bin: ${batch.binLocation}" : ""}${hasBin && hasRef ? " | " : ""}${hasRef ? "Ref: ${batch.batchRef}" : ""}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF065F46),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                soItem.quantity.toString(),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '0', // TODO: Fetch already packed qty
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildQuantityCell(
                  index, 
                  _buildNormalQtyInput(index, soItem),
                  "ZABNIX PRIVATE LIMITED"
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildNormalQtyInput(int index, SalesOrderItem soItem) {
    if (index >= _normalRowControllers.length) return const SizedBox();
    return TextField(
      controller: _normalRowControllers[index],
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 13,
        fontFamily: 'Inter',
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _borderCol),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _focusBorder, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: (val) {
        final double? dVal = double.tryParse(val);
        if (dVal != null && index < _items.length) {
          setState(() {
            _items[index] = _items[index].copyWith(qtyToPack: dVal);
          });
        }
      },
    );
  }

  Widget _buildManualItemsTable() {
    if (_isLoadingItems) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableHeader(),
        ...List.generate(
          _items.length,
          (index) => _buildManualRow(index, _items[index]),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _insertManualRow,
          style: TextButton.styleFrom(
            foregroundColor: _focusBorder,
            padding: EdgeInsets.zero,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.plus, size: 14),
              SizedBox(width: 4),
              Text(
                'Insert New Row',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _bgLight,
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'ITEMS & DESCRIPTION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'ORDERED',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'PACKED',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'QUANTITY TO PACK',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildManualRow(int index, _PackageItem item) {
    // ignore: unused_local_variable
    final ctrl = _rowControllers[index];
    final soItems = _salesOrderItems;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormDropdown<SalesOrderItem>(
                  fillColor: Colors.white,
                  value: soItems.where((it) => it.itemId == item.itemId).firstOrNull,
                  hint: 'Select Item',
                  items: soItems,
                  maxVisibleItems: 4,
                  itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<SalesOrderItem>(
                    item, 
                    isSelected, 
                    isHovered, 
                    (it) => it.item?.productName ?? it.description ?? 'Unknown',
                  ),
                  displayStringForValue: (it) => it.item?.productName ?? it.description ?? 'Unknown',
                  searchStringForValue: (it) => it.item?.productName ?? it.description ?? '',
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _items[index] = _items[index].copyWith(
                        itemId: val.itemId,
                        itemName: val.item?.productName ?? val.description ?? '',
                        ordered: val.quantity,
                      );
                      _rowControllers[index].qtyCtrl.text = val.quantity.toString();
                    });
                  },
                ),
                if (item.itemId != null && item.itemId!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Unit: ${soItems.firstWhere((it) => it.itemId == item.itemId, orElse: () => soItems.first).item?.unitName ?? "pcs"}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                if (item.batches.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: item.batches.map((batch) {
                      final hasBin = batch.binLocation != null && batch.binLocation!.isNotEmpty;
                      final hasRef = batch.batchRef != null && batch.batchRef!.isNotEmpty;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F9F5),
                          border: Border.all(color: const Color(0xFFCFE9D8)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Batch: ${batch.batchNo} (${batch.quantity} pcs)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                            if (hasBin || hasRef)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${hasBin ? "Bin: ${batch.binLocation}" : ""}${hasBin && hasRef ? " | " : ""}${hasRef ? "Ref: ${batch.batchRef}" : ""}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF065F46),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                item.ordered.toString(),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                item.packed.toString(),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IgnorePointer(
                  ignoring: item.itemId == null || item.itemId!.isEmpty,
                  child: Opacity(
                    opacity: (item.itemId != null && item.itemId!.isNotEmpty) ? 1.0 : 0.4,
                    child: _buildQuantityCell(
                      index, 
                      _buildQtyInput(index),
                      "ZABNIX PRIVATE LIMITED"
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 32,
            child: IconButton(
              onPressed: () => _removeItem(index),
              icon: const Icon(
                LucideIcons.trash2,
                size: 16,
                color: _dangerRed,
              ),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCell(int index, Widget qtyInput, String warehouseName) {
    // Mock available quantity for demo based on index to show red color when <= 0
    final avlQty = index == 1 ? -2 : 0;
    final isDanger = avlQty <= 0;
    final currentView = _rowSelectedViews[index] ?? 'Available for Sale';

    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: 80, child: qtyInput),
          const SizedBox(height: 12),
          Text(
            '$currentView:',
            style: const TextStyle(fontSize: 11, color: Color(0xFF1F2937), fontFamily: 'Inter'),
          ),
          Text(
            '$avlQty pcs',
            style: TextStyle(
              fontSize: 11,
              color: isDanger ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          _WarehouseHoverPopover(
            warehouseName: warehouseName,
            selectedView: currentView,
            onViewChanged: (newView) {
              setState(() {
                _rowSelectedViews[index] = newView;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.building, size: 12, color: Color(0xFF2563EB)),
                const SizedBox(width: 4),
                Text(
                  warehouseName,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _showSelectBatchDialog(index),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertTriangle, size: 12, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                const Text(
                  'Select Batch',
                  style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyInput(int index) {
    if (index >= _rowControllers.length) return const SizedBox();
    final ctrl = _rowControllers[index];
    final fieldKey = 'qty-$index';
    final isActive = _hoveredQtyFields.contains(fieldKey) ||
        _focusedQtyFields.contains(fieldKey);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredQtyFields.add(fieldKey)),
      onExit: (_) => setState(() => _hoveredQtyFields.remove(fieldKey)),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            if (hasFocus) {
              _focusedQtyFields.add(fieldKey);
            } else {
              _focusedQtyFields.remove(fieldKey);
            }
          });
        },
        child: TextField(
          controller: ctrl.qtyCtrl,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isActive ? _focusBorder : _borderCol,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _focusBorder, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final qty = double.tryParse(val) ?? 0;
            setState(() {
              _items[index] = _items[index].copyWith(qtyToPack: qty);
            });
          },
        ),
      ),
    );
  }

  Future<void> _showSelectBatchDialog(int index) async {
    final item = _items[index];

    double qtyToPack = item.qtyToPack;
    if (qtyToPack <= 0) {
      qtyToPack = double.tryParse(_rowControllers[index].qtyCtrl.text) ?? (item.ordered - item.packed);
    }
    if (qtyToPack <= 0) qtyToPack = 1.0;

    final result = await showDialog<_PackageBatchDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PackageBatchSelectionDialog(
        itemName: item.itemName,
        warehouseName: _rowSelectedViews[index] ?? 'DEMO WAREHOUSE 1',
        totalQuantity: qtyToPack,
        savedBatches: item.batches,
      ),
    );

    if (result != null) {
      setState(() {
        _items[index] = _items[index].copyWith(
          batches: result.batches,
          qtyToPack: result.overwriteLineItem ? result.appliedQuantity : item.qtyToPack,
        );
        if (result.overwriteLineItem) {
          _rowControllers[index].qtyCtrl.text = result.appliedQuantity.toInt().toString();
        }
      });
    }
  }
}

class _PackageBatch {
  final String batchNo;
  final double quantity;
  final String? binLocation;
  final String? batchRef;
  final String? unitPack;
  final String? mrp;
  final String? ptr;
  final String? expDate;
  final String? mfgDate;
  final String? mfgBatch;
  final double? foc;

  const _PackageBatch({
    required this.batchNo,
    required this.quantity,
    this.binLocation,
    this.batchRef,
    this.unitPack,
    this.mrp,
    this.ptr,
    this.expDate,
    this.mfgDate,
    this.mfgBatch,
    this.foc,
  });

  Map<String, String> toMap() {
    return {
      'batchNo': batchNo,
      'quantity': quantity.toString(),
      'binLocation': binLocation ?? '',
      'batchRef': batchRef ?? '',
      'unitPack': unitPack ?? '',
      'mrp': mrp ?? '',
      'ptr': ptr ?? '',
      'expDate': expDate ?? '',
      'mfgDate': mfgDate ?? '',
      'mfgBatch': mfgBatch ?? '',
      'foc': foc?.toString() ?? '',
    };
  }
}

class _PackageItem {
  final String? itemId;
  final String itemName;
  final double ordered;
  final double packed;
  final double qtyToPack;
  final List<_PackageBatch> batches;

  const _PackageItem({
    this.itemId,
    this.itemName = '',
    this.ordered = 0,
    this.packed = 0,
    this.qtyToPack = 0,
    this.batches = const [],
  });

  _PackageItem copyWith({
    String? itemId,
    String? itemName,
    double? ordered,
    double? packed,
    double? qtyToPack,
    List<_PackageBatch>? batches,
  }) {
    return _PackageItem(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      ordered: ordered ?? this.ordered,
      packed: packed ?? this.packed,
      qtyToPack: qtyToPack ?? this.qtyToPack,
      batches: batches ?? this.batches,
    );
  }
}

class _PackageItemRowController {
  final TextEditingController qtyCtrl;

  _PackageItemRowController() : qtyCtrl = TextEditingController(text: '0');

  void dispose() {
    qtyCtrl.dispose();
  }
}

class _PackagePreferencesDialog extends StatefulWidget {
  final bool initialAutoGenerate;
  final String initialPrefix;
  final int initialNextNumber;
  final void Function(bool isAuto, String prefix, int nextNum) onSave;

  const _PackagePreferencesDialog({
    required this.initialAutoGenerate,
    required this.initialPrefix,
    required this.initialNextNumber,
    required this.onSave,
  });

  @override
  State<_PackagePreferencesDialog> createState() =>
      __PackagePreferencesDialogState();
}

class __PackagePreferencesDialogState extends State<_PackagePreferencesDialog> {
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
    const greenBtn = Color(0xFF10B981);

    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configure Package Slip# Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 18, color: textSecondary),
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
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Your package slip numbers are set on auto-generate mode to save your time.',
                          style: TextStyle(
                            fontSize: 13,
                            color: textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Are you sure about changing this setting?',
                    style: TextStyle(
                      fontSize: 13,
                      color: textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () => setState(() => _isAuto = true),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Radio<bool>(
                            value: true,
                            groupValue: _isAuto,
                            onChanged: (val) => setState(() => _isAuto = val!),
                            activeColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Continue auto-generating package numbers',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        ZTooltip(
                          message: 'The edited prefix and next number will be updated in the transaction number series associated with your package slip.',
                          child: const Icon(LucideIcons.info, size: 14, color: textSecondary),
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
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _prefixCtrl,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                  ),
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
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _numberCtrl,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                  ),
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
                  InkWell(
                    onTap: () => setState(() => _isAuto = false),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Radio<bool>(
                            value: false,
                            groupValue: _isAuto,
                            onChanged: (val) => setState(() => _isAuto = val!),
                            activeColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Enter package numbers manually',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400, // Regular as requested
                            color: textPrimary,
                            fontFamily: 'Inter',
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
                        fontFamily: 'Inter',
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
                        fontFamily: 'Inter',
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

// ---------------------------------------------------------------------------
// Batch selection result (local to this module)
// ---------------------------------------------------------------------------
class _PackageBatchDialogResult {
  final bool overwriteLineItem;
  final int batchCount;
  final double appliedQuantity;
  final List<_PackageBatch> batches;

  const _PackageBatchDialogResult({
    required this.overwriteLineItem,
    required this.batchCount,
    required this.appliedQuantity,
    required this.batches,
  });
}

class _PackageBatchSelectionDialog extends StatefulWidget {
  final String itemName;
  final String warehouseName;
  final double totalQuantity;
  final List<String> existingBatchRefs;
  final List<_PackageBatch> savedBatches;

  const _PackageBatchSelectionDialog({
    required this.itemName,
    required this.warehouseName,
    required this.totalQuantity,
    this.existingBatchRefs = const [],
    this.savedBatches = const [],
  });

  @override
  State<_PackageBatchSelectionDialog> createState() => _PackageBatchSelectionDialogState();
}

class _PackageBatchSelectionDialogState extends State<_PackageBatchSelectionDialog> {
  final List<_PackageBatchRowController> _rows = [];
  final List<String> _mockBinLocations = const <String>[
    'A1-R1-S1', 'A1-R1-S2', 'A1-R2-S1', 'B1-R1-S1', 'B1-R2-S3', 'C1-R4-S2',
  ];
  bool _overwriteLineItem = false;
  bool _showMfgDetails = false;
  bool _showFocColumn = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedBatches.isNotEmpty) {
      for (var b in widget.savedBatches) {
        final row = _PackageBatchRowController();
        row.binLocationCtrl.text = b.binLocation ?? '';
        row.batchRefCtrl.text = b.batchRef ?? '';
        row.batchNoCtrl.text = b.batchNo;
        row.unitPackCtrl.text = b.unitPack ?? '';
        row.mrpCtrl.text = b.mrp ?? '';
        row.ptrCtrl.text = b.ptr ?? '';
        row.expDateCtrl.text = b.expDate ?? '';
        row.mfgDateCtrl.text = b.mfgDate ?? '';
        row.mfgBatchCtrl.text = b.mfgBatch ?? '';
        row.qtyOutCtrl.text = b.quantity.toInt().toString();
        row.focCtrl.text = b.foc?.toInt().toString() ?? '';
        _rows.add(row);
      }
    } else {
      _addRow();
      if (_rows.isNotEmpty) {
        _rows[0].qtyOutCtrl.text = widget.totalQuantity.toInt().toString();
      }
    }
  }

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  double get _totalQuantityOut => _rows.fold<double>(
    0, (sum, r) => sum + (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0));

  void _addRow() {
    setState(() => _rows.add(_PackageBatchRowController()));
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

  Widget _headerCell(String text, int flex, {TextAlign alignment = TextAlign.center}) {
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
        child: TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : null,
          textAlign: isNumber ? TextAlign.right : TextAlign.left,
          style: const TextStyle(fontSize: 13, color: _textPrimary, fontFamily: 'Inter'),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _borderCol),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _focusBorder, width: 1.4),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
      child: SizedBox(
        width: _showMfgDetails ? (_showFocColumn ? 1480 : 1320) : (_showFocColumn ? 1200 : 1000),
        height: MediaQuery.of(context).size.height * 0.86,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                   const Text('Select Batches', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary, fontFamily: 'Inter')),
                   const Spacer(),
                   InkWell(
                     onTap: () => Navigator.pop(context),
                     child: Container(
                       padding: const EdgeInsets.all(4),
                       decoration: BoxDecoration(
                         border: Border.all(color: const Color(0xFFE5E7EB)),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: const Icon(LucideIcons.x, size: 14, color: _dangerRed),
                     ),
                   ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Sub-header info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.home, size: 14, color: _textSecondary),
                      const SizedBox(width: 8),
                      Text('Location : ${widget.warehouseName.toUpperCase()}', style: const TextStyle(fontSize: 12, color: _textSecondary, fontFamily: 'Inter')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('BATCH DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSecondary, fontFamily: 'Inter')),
                      const SizedBox(width: 16),
                      Text('Item: ${widget.itemName}', style: const TextStyle(fontSize: 12, color: _textSecondary, fontFamily: 'Inter')),
                      const Spacer(),
                      Text('Total Quantity : ${widget.totalQuantity.toInt()}', style: const TextStyle(fontSize: 12, color: _textSecondary, fontFamily: 'Inter')),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('|', style: TextStyle(color: _textSecondary))),
                      Text('Quantity to be added : ${_totalQuantityOut.toInt()}', style: const TextStyle(fontSize: 12, color: _textSecondary, fontFamily: 'Inter')),
                    ],
                  ),
                ],
              ),
            ),
            // Toggles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Checkbox(value: _showMfgDetails, onChanged: (v) => setState(() => _showMfgDetails = v!)),
                  const Text('Manufacture Details', style: TextStyle(fontSize: 13, fontFamily: 'Inter')),
                  const SizedBox(width: 16),
                  Checkbox(value: _showFocColumn, onChanged: (v) => setState(() => _showFocColumn = v!)),
                  const Text('FOC', style: TextStyle(fontSize: 13, fontFamily: 'Inter')),
                  const Spacer(),
                  Checkbox(value: _overwriteLineItem, onChanged: (v) => setState(() => _overwriteLineItem = v!)),
                  Text('Overwrite the line item with ${_totalQuantityOut.toInt()} quantities', style: const TextStyle(fontSize: 13, fontFamily: 'Inter')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Table Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              color: const Color(0xFFF9FAFB),
              child: Row(
                children: [
                  _headerCell('BIN LOCATION*', 15),
                  _headerCell('BATCH REF*', 15),
                  _headerCell('BATCH NO*', 15),
                  _headerCell('UNIT PACK*', 15),
                  _headerCell('MRP*', 15),
                  _headerCell('PTR', 15),
                  _headerCell('EXPIRY*', 15),
                  if (_showMfgDetails) ...[
                    _headerCell('MFG DATE', 15),
                    _headerCell('MFG BATCH', 15),
                  ],
                  _headerCell('QTY OUT*', 15),
                  if (_showFocColumn) _headerCell('FOC', 15),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Rows
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _rows.length,
                itemBuilder: (context, i) {
                  final r = _rows[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 15,
                          child: FormDropdown<String>(
                            value: _mockBinLocations.contains(r.binLocationCtrl.text) ? r.binLocationCtrl.text : null,
                            items: _mockBinLocations,
                            hint: 'Select Bin',
                            displayStringForValue: (v) => v,
                            onChanged: (v) => setState(() => r.binLocationCtrl.text = v ?? ''),
                          ),
                        ),
                        Expanded(
                          flex: 15,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FormDropdown<String>(
                                value: widget.existingBatchRefs.contains(r.batchRefCtrl.text) ? r.batchRefCtrl.text : null,
                                items: widget.existingBatchRefs,
                                hint: 'Select Ref',
                                displayStringForValue: (v) => v,
                                onChanged: (v) => setState(() => r.batchRefCtrl.text = v ?? ''),
                            ),
                          ),
                        ),
                        _buildInput(controller: r.batchNoCtrl, flex: 15, hint: 'Batch No'),
                        _buildInput(controller: r.unitPackCtrl, flex: 15, hint: 'Unit Pack'),
                        _buildInput(controller: r.mrpCtrl, flex: 15, hint: 'MRP', isNumber: true),
                        _buildInput(controller: r.ptrCtrl, flex: 15, hint: 'PTR', isNumber: true),
                        Expanded(
                          flex: 15,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextField(
                              key: r.expDateKey,
                              controller: r.expDateCtrl,
                              readOnly: true,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                suffixIcon: const Icon(LucideIcons.calendar, size: 14),
                              ),
                              onTap: () async {
                                final d = await ZerpaiDatePicker.show(context, initialDate: DateTime.now(), targetKey: r.expDateKey);
                                if (d != null) setState(() => r.expDateCtrl.text = DateFormat('dd-MM-yyyy').format(d));
                              },
                            ),
                          ),
                        ),
                        if (_showMfgDetails) ...[
                          _buildInput(controller: r.mfgDateCtrl, flex: 15, hint: 'MFG Date'), // Simplified for now
                          _buildInput(controller: r.mfgBatchCtrl, flex: 15, hint: 'MFG Batch'),
                        ],
                        _buildInput(controller: r.qtyOutCtrl, flex: 15, hint: 'Qty', isNumber: true),
                        if (_showFocColumn) _buildInput(controller: r.focCtrl, flex: 15, hint: 'FOC', isNumber: true),
                        IconButton(
                          onPressed: () => _removeRow(i), 
                          icon: const Icon(LucideIcons.xCircle, size: 20, color: _dangerRed)
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Actions below table
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: _addRow,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plusCircle, size: 16, color: _greenBtn),
                        SizedBox(width: 8),
                        Text(
                          'New Row',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _greenBtn,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Batches added: ${_rows.length}/100',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                       final batches = _rows.map((r) => _PackageBatch(
                         batchNo: r.batchNoCtrl.text,
                         quantity: double.tryParse(r.qtyOutCtrl.text) ?? 0,
                         binLocation: r.binLocationCtrl.text,
                         batchRef: r.batchRefCtrl.text,
                         unitPack: r.unitPackCtrl.text,
                         mrp: r.mrpCtrl.text,
                         ptr: r.ptrCtrl.text,
                         expDate: r.expDateCtrl.text,
                         mfgDate: r.mfgDateCtrl.text,
                         mfgBatch: r.mfgBatchCtrl.text,
                         foc: double.tryParse(r.focCtrl.text),
                       )).where((b) => b.batchNo.isNotEmpty && b.quantity > 0).toList();
                       
                       Navigator.pop(context, _PackageBatchDialogResult(
                         overwriteLineItem: _overwriteLineItem,
                         batchCount: batches.length,
                         appliedQuantity: batches.fold(0.0, (s, b) => s + b.quantity),
                         batches: batches,
                       ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenBtn,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textPrimary,
                      side: const BorderSide(color: _borderCol),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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

class _WarehouseHoverPopover extends StatefulWidget {
  final Widget child;
  final String warehouseName;
  final String selectedView;
  final ValueChanged<String> onViewChanged;

  const _WarehouseHoverPopover({
    required this.child,
    required this.warehouseName,
    required this.selectedView,
    required this.onViewChanged,
  });

  @override
  State<_WarehouseHoverPopover> createState() => _WarehouseHoverPopoverState();
}

class _WarehouseHoverPopoverState extends State<_WarehouseHoverPopover> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -6),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 620,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [
                           BoxShadow(
                             color: Color(0x1A000000), 
                             blurRadius: 10, 
                             offset: Offset(0, 4)
                           ),
                        ],
                      ),
                      child: _WarehousePopoverContent(
                        warehouseName: widget.warehouseName,
                        selectedView: widget.selectedView,
                        onViewChanged: widget.onViewChanged,
                        onClose: _closeOverlay,
                      ),
                    ),
                    CustomPaint(
                      size: const Size(14, 7), // approx 12x6
                      painter: _PopoverArrowPainter(
                        color: Colors.white,
                        borderColor: const Color(0xFFE5E7EB),
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

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _showOverlay,
        child: widget.child,
      ),
    );
  }
}

class _WarehousePopoverContent extends StatefulWidget {
  final VoidCallback onClose;
  final String warehouseName;
  final String selectedView;
  final ValueChanged<String> onViewChanged;
  
  const _WarehousePopoverContent({
    required this.onClose, 
    required this.warehouseName,
    required this.selectedView,
    required this.onViewChanged,
  });

  @override
  State<_WarehousePopoverContent> createState() => _WarehousePopoverContentState();
}

class _WarehousePopoverContentState extends State<_WarehousePopoverContent> {
  late String _localSelectedView;
  String selectedStockType = 'Accounting'; // 'Accounting' or 'Physical'
  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _localSelectedView = widget.selectedView;
  }

  void _toggleStockType(String type) {
    setState(() {
      selectedStockType = type;
      isDropdownOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine footer text dynamically
    String footer1, footer2, footer3;
    if (selectedStockType == 'Accounting') {
      footer1 = 'Stock on Hand : This is calculated based on Bills and Invoices.';
      footer2 = 'Committed Stock : Stock that is committed to sales order(s) but not yet invoiced';
      footer3 = 'Available for Sale : Stock on Hand - Committed Stock';
    } else {
      footer1 = 'Stock on Hand : Based on Receives and Shipments';
      footer2 = 'Committed Stock : Committed but not shipped';
      footer3 = 'Available for Sale : Stock on Hand - Committed Stock';
    }

    // Determine row values for ZABNIX
    String zHand, zComm, zAvail;
    if (selectedStockType == 'Accounting') {
      zHand = '5.00'; zComm = '5.00'; zAvail = '0.00';
    } else {
      zHand = '10.00'; zComm = '10.00'; zAvail = '0.00';
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            if (isDropdownOpen) setState(() => isDropdownOpen = false);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(child: Text('Warehouse Locations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
                    Row(
                      children: [
                        const Text('View: ', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                        
                        // Dropdown Target
                        GestureDetector(
                          onTap: () => setState(() => isDropdownOpen = !isDropdownOpen),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Text(_localSelectedView, style: const TextStyle(fontSize: 12, fontFamily: 'Inter', color: Color(0xFF374151))),
                                const SizedBox(width: 4),
                                const Icon(LucideIcons.chevronDown, size: 14, color: Color(0xFF6B7280)),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF3B82F6)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleStockType('Accounting'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selectedStockType == 'Accounting' ? const Color(0xFF3B82F6) : Colors.white,
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), bottomLeft: Radius.circular(3)),
                                  ),
                                  child: Text('Accounting Stock', style: TextStyle(
                                    fontSize: 12, 
                                    fontFamily: 'Inter', 
                                    color: selectedStockType == 'Accounting' ? Colors.white : const Color(0xFF3B82F6)
                                  )),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _toggleStockType('Physical'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selectedStockType == 'Physical' ? const Color(0xFF3B82F6) : Colors.white,
                                    borderRadius: const BorderRadius.only(topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
                                  ),
                                  child: Text('Physical Stock', style: TextStyle(
                                    fontSize: 12, 
                                    fontFamily: 'Inter', 
                                    color: selectedStockType == 'Physical' ? Colors.white : const Color(0xFF3B82F6)
                                  )),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: widget.onClose,
                          child: const Icon(LucideIcons.x, size: 20, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Container( // TABLE HEADER
                color: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Row(children: [const Text('Location Name', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')), const SizedBox(width: 4), const Icon(LucideIcons.search, size: 12, color: Color(0xFF9CA3AF))])),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Text('$selectedStockType Stock', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Expanded(child: Text('Stock on Hand', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter'))),
                              Expanded(child: Text('Committed Stock', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter'))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2, 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Available for Sale', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                          const SizedBox(height: 4),
                          const Icon(LucideIcons.eye, size: 14, color: Color(0xFF9CA3AF)),
                        ],
                      )
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              // ROW 1
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Row(children: [
                      // Custom Radio
                      Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3B82F6)),
                        ),
                      ),
                      const SizedBox(width: 10), 
                      Text(widget.warehouseName, style: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: Color(0xFF374151)))
                    ])),
                    Expanded(flex: 2, child: Text(zHand, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, fontFamily: 'Inter'))),
                    Expanded(flex: 2, child: Text(zComm, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: Color(0xFF6B7280)))),
                    Expanded(flex: 2, child: Text(zAvail, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              // ROW 2 (Disabled/Opaque)
              Opacity(
                opacity: 0.5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Row(children: [
                        // Custom Unselected Radio
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 10), 
                        const Text('DEMO WAREHOUSE 1 ', style: TextStyle(fontSize: 13, fontFamily: 'Inter', color: Color(0xFF374151)))
                      ])),
                      Expanded(flex: 2, child: Text('0.00', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, fontFamily: 'Inter'))),
                      Expanded(flex: 2, child: Text('0.00', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: Color(0xFF6B7280)))),
                      Expanded(flex: 2, child: Text('0.00', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
                    ],
                  ),
                ),
              ),
              // FOOTER
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(footer1, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text(footer2, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text(footer3, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontFamily: 'Inter')),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Custom Dropdown Overlaid
        if (isDropdownOpen)
          Positioned(
            top: 42,
            left: 204, // Positioned near the 'View' selection box inside the 620px container
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDropdownItem('Stock on Hand'),
                    _buildDropdownItem('Available for Sale'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownItem(String text) {
    return _CommonDropdownItem(
      text: text, 
      isSelected: _localSelectedView == text, 
      onTap: () {
        setState(() {
          _localSelectedView = text;
          widget.onViewChanged(text);
          isDropdownOpen = false;
        });
      },
    );
  }
}

class _CommonDropdownItem extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _CommonDropdownItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CommonDropdownItem> createState() => _CommonDropdownItemState();
}

class _CommonDropdownItemState extends State<_CommonDropdownItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _isHovered 
              ? const Color(0xFF3B82F6) 
              : (widget.isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 12,
              color: _isHovered ? Colors.white : const Color(0xFF374151),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

class _PopoverArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  _PopoverArrowPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
    
    // Draw over the top line with the fill color to "merge" with the box
    final mergePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(1, 0), Offset(size.width - 1, 0), mergePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PackageBatchRowController {
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

  final GlobalKey expDateKey = GlobalKey();
  final GlobalKey mfgDateKey = GlobalKey();

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
