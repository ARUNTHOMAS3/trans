import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../shared/widgets/inputs/zerpai_date_picker.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/inputs/z_tooltip.dart';
import '../../../sales/controllers/sales_order_controller.dart';
import '../../../sales/models/sales_order_model.dart';
import '../../../sales/models/sales_order_item_model.dart';

class InventoryPackagesCreateScreen extends ConsumerStatefulWidget {
  const InventoryPackagesCreateScreen({super.key});

  @override
  ConsumerState<InventoryPackagesCreateScreen> createState() =>
      _InventoryPackagesCreateScreenState();
}

class _InventoryPackagesCreateScreenState
    extends ConsumerState<InventoryPackagesCreateScreen> {
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderCol = Color(0xFFE5E7EB);
  static const Color _focusBorder = Color(0xFF3B82F6);
  static const Color _greenBtn = Color(0xFF10B981);
  static const Color _bgLight = Color(0xFFF9FAFB);
  static const Color _dangerRed = Color(0xFFDC2626);
  static const Color _hintColor = Color(0xFF6B7280);
  static const Color _bgWhite = Color(0xFFFFFFFF);

  bool _isManualMode = false;
  List<_PackageItem> _items = [];
  final List<_PackageItemRowController> _rowControllers = [];
  final Set<String> _hoveredQtyFields = {};
  final Set<String> _focusedQtyFields = {};
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
      _items = [];
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
      for (var ctrl in _normalRowControllers) {
        ctrl.dispose();
      }
      _normalRowControllers.clear();
    });

    try {
      final order = await ref
          .read(salesOrderApiServiceProvider)
          .getSalesOrderById(salesOrderId);
      final items = order.items ?? [];
      if (mounted) {
        setState(() {
          _salesOrderItems = items;
          for (var item in items) {
            _normalRowControllers.add(
              TextEditingController(text: item.quantity.toString()),
            );
          }
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
                                  displayStringForValue: (val) {
                                    final customer = customers.firstWhere((c) => c.id == val);
                                    return customer.displayName;
                                  },
                                  searchStringForValue: (val) {
                                    final customer = customers.firstWhere((c) => c.id == val);
                                    return customer.displayName;
                                  },
                                  itemBuilder: (id, isSelected, isHovered) {
                                    final customer = customers.firstWhere(
                                      (c) => c.id == id,
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      color: isHovered
                                          ? const Color(0xFF3B82F6)
                                          : Colors.white,
                                      child: Text(
                                        customer.displayName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'Inter',
                                          color: isHovered
                                              ? Colors.white
                                              : _textPrimary,
                                        ),
                                      ),
                                    );
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
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      _buildNormalQtyInput(index, soItem),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Available for sale: 100 pcs',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF10B981), // Success Green
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Location: Main Warehouse',
                          style: TextStyle(
                            fontSize: 10,
                            color: _textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => _showSelectBatchDialog(index),
                          child: const Text(
                            'Add Batches',
                            style: TextStyle(
                              fontSize: 11,
                              color: _focusBorder,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              decoration: TextDecoration.underline,
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
        fontWeight: FontWeight.w600,
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
        // Handle qty change
      },
    );
  }

  Widget _buildManualItemsTable() {
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
                        child: Text(
                          'Batch: ${batch.batchNo} (${batch.quantity} pcs)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF065F46),
                            fontFamily: 'Inter',
                          ),
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
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      _buildQtyInput(index),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Available for sale: 100 pcs',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Location: Main Warehouse',
                          style: TextStyle(
                            fontSize: 10,
                            color: _textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => _showSelectBatchDialog(index),
                          child: const Text(
                            'Add Batches',
                            style: TextStyle(
                              fontSize: 11,
                              color: _focusBorder,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                              decoration: TextDecoration.underline,
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

  Widget _buildQtyInput(int index) {
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
            fontWeight: FontWeight.w600,
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

    final result = await showDialog<_BatchSelectionResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _BatchSelectionDialog(
        itemName: item.itemName,
        totalQuantity: qtyToPack,
        existingBatches: item.batches,
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _items[index] = _items[index].copyWith(batches: result.batches);
      final totalQty = result.batches.fold<double>(0, (sum, b) => sum + b.quantity);
      _rowControllers[index].qtyCtrl.text = totalQty.toString();
      _items[index] = _items[index].copyWith(qtyToPack: totalQty);
    });
  }
}

class _PackageBatch {
  final String batchNo;
  final double quantity;

  const _PackageBatch({
    required this.batchNo,
    required this.quantity,
  });
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
class _BatchSelectionResult {
  final List<_PackageBatch> batches;
  const _BatchSelectionResult({required this.batches});
}

// ---------------------------------------------------------------------------
// Inline Batch Selection Dialog
// ---------------------------------------------------------------------------
class _BatchSelectionDialog extends StatefulWidget {
  final String itemName;
  final double totalQuantity;
  final List<_PackageBatch> existingBatches;

  const _BatchSelectionDialog({
    required this.itemName,
    required this.totalQuantity,
    this.existingBatches = const [],
  });

  @override
  State<_BatchSelectionDialog> createState() => _BatchSelectionDialogState();
}

class _BatchSelectionDialogState extends State<_BatchSelectionDialog> {
  late List<_BatchRow> _rows;
  final _batchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rows = widget.existingBatches
        .map((b) => _BatchRow(
              batchNo: b.batchNo,
              qtyCtrl: TextEditingController(text: b.quantity.toString()),
            ))
        .toList();
    if (_rows.isEmpty) _addEmptyRow();
  }

  void _addEmptyRow() {
    _rows.add(_BatchRow(
      batchNo: '',
      qtyCtrl: TextEditingController(text: '0'),
    ));
  }

  @override
  void dispose() {
    _batchCtrl.dispose();
    for (final r in _rows) {
      r.qtyCtrl.dispose();
    }
    super.dispose();
  }

  double get _allocatedQty => _rows.fold<double>(
      0, (s, r) => s + (double.tryParse(r.qtyCtrl.text) ?? 0));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SELECT BATCHES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            color: Color(0xFF1F2937),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.itemName}  •  Qty to pack: ${widget.totalQuantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),

            // Batch rows
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shrinkWrap: true,
                itemCount: _rows.length,
                itemBuilder: (_, i) {
                  final row = _rows[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: row.batchNo,
                            style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Batch #',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                            ),
                            onChanged: (v) => row.batchNo = v,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: row.qtyCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Qty',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _rows[i].qtyCtrl.dispose();
                              _rows.removeAt(i);
                            });
                          },
                          child: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Add batch link
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _addEmptyRow()),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text(
                    'Add Batch',
                    style: TextStyle(fontSize: 13, fontFamily: 'Inter'),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Allocated: ${_allocatedQty.toStringAsFixed(2)} / ${widget.totalQuantity.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: _allocatedQty > widget.totalQuantity
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13, fontFamily: 'Inter')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final batches = _rows
                          .where((r) =>
                              r.batchNo.isNotEmpty &&
                              (double.tryParse(r.qtyCtrl.text) ?? 0) > 0)
                          .map((r) => _PackageBatch(
                                batchNo: r.batchNo,
                                quantity: double.tryParse(r.qtyCtrl.text) ?? 0,
                              ))
                          .toList();
                      Navigator.of(context)
                          .pop(_BatchSelectionResult(batches: batches));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22A95E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w500),
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

class _BatchRow {
  String batchNo;
  final TextEditingController qtyCtrl;

  _BatchRow({required this.batchNo, required this.qtyCtrl});
}
