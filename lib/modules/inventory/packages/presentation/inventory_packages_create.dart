import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../shared/widgets/inputs/zerpai_date_picker.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import 'package:skeletonizer/skeletonizer.dart' hide Skeleton;
import '../../../../shared/utils/zerpai_toast.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/modules/sales/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_order_item_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/inventory/picklists/models/inventory_picklist_model.dart';
import 'package:zerpai_erp/modules/inventory/picklists/providers/inventory_picklists_provider.dart';
import '../../../../shared/widgets/inputs/warehouse_popover.dart';
import '../../../../shared/widgets/inputs/custom_text_field.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/providers/lookup_providers.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import '../../providers/warehouse_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/inventory/packages/providers/inventory_packages_provider.dart';
import 'package:zerpai_erp/shared/widgets/inputs/radio_group.dart';

const Color _textPrimary = Color(0xFF1F2937);

const Color _textSecondary = Color(0xFF6B7280);
const Color _borderCol = Color(0xFFE5E7EB);
const Color _focusBorder = Color(0xFF3B82F6);
const Color _greenBtn = Color(0xFF10B981);
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
  bool _isPicklistMode = false;
  bool _isSaving = false;
  List<_PackageItem> _items = [];
  final List<_PackageItemRowController> _rowControllers = [];
  final Set<String> _hoveredQtyFields = {};
  final Map<int, String> _rowSelectedViews = {};
  final Map<int, String> _rowSelectedWarehouses = {};
  final Map<int, String> _rowSelectedWarehouseIds = {};
  final Set<String> _focusedQtyFields = {};
  final Map<int, int> _savedBatchCounts = <int, int>{};
  final Set<int> _savedBatchKeys = <int>{};
  int? _hoveredRowIndex;
  int? _hoveredManualRowIndex;

  Widget _commonItemBuilder<T>(
    T item,
    bool isSelected,
    bool isHovered,
    String Function(T) displayFn,
  ) {
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

  Widget _centeredUnitItemBuilder(
    String item,
    bool isSelected,
    bool isHovered,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: Alignment.center,
      color: isHovered
          ? const Color(0xFF3B82F6)
          : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
      child: Text(
        item,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: isHovered ? Colors.white : const Color(0xFF1F2937),
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildCustomerDropdownItem(
    SalesCustomer customer,
    bool isSelected,
    bool isHovered,
  ) {
    final customerNumber = (customer.customerNumber ?? '').trim();
    final email = (customer.email ?? '').trim();
    final companyName = (customer.companyName ?? '').trim();
    final firstName = (customer.firstName ?? '').trim();

    final topLine = customerNumber.isEmpty
        ? customer.displayName
        : '${customer.displayName} | $customerNumber';

    final List<String> bottomParts = [];
    if (email.isNotEmpty) bottomParts.add(email);
    if (companyName.isNotEmpty) bottomParts.add(companyName);
    final bottomLine = bottomParts.join(' | ');

    final initialSource = firstName.isNotEmpty
        ? firstName
        : (customer.displayName.isNotEmpty ? customer.displayName : '?');
    final initial = initialSource.substring(0, 1).toUpperCase();

    final backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
    final primaryTextColor = isHovered ? Colors.white : _textPrimary;
    final secondaryTextColor = isHovered
        ? Colors.white.withValues(alpha: 0.85)
        : _textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHovered
                  ? Colors.white.withValues(alpha: 0.25)
                  : const Color(0xFFE5E7EB),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              textAlign: TextAlign.center,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1,
                color: isHovered ? Colors.white : const Color(0xFF64748B),
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: primaryTextColor,
                    fontFamily: 'Inter',
                  ),
                ),
                if (bottomLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    bottomLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  SalesCustomer? _selectedCustomer;
  List<String> _selectedSalesOrderValues = [];
  List<SalesOrder> _selectedSalesOrderDataList = [];
  List<Picklist> _selectedPicklistValues = [];
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
  List<String> _lengthUnits = ['cm'];
  List<String> _weightUnits = ['kg'];

  final LookupsApiService _lookupsService = LookupsApiService();
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _dimLengthFocus = FocusNode();
  final FocusNode _dimWidthFocus = FocusNode();
  final FocusNode _dimHeightFocus = FocusNode();

  // Search State
  final _itemNameSearchCtrl = TextEditingController();
  final _salesOrderSearchCtrl = TextEditingController();
  String _itemNameSearchQuery = '';
  String _salesOrderSearchQuery = '';
  bool _isItemSearchVisible = false;
  bool _isSOSearchVisible = false;

  bool _dimFocused = false;

  bool _isAutoGenerate = true;
  String _packagePrefix = 'PKG-';
  int _nextNumber = 1;

  final List<TextEditingController> _normalRowControllers = [];
  int _currentPage = 0;
  static const int _itemsPerPage = 30;
  List<SalesOrderItem> _salesOrderItems = [];
  bool _isLoadingItems = false;

  bool get _isSalesOrderSelected => _selectedSalesOrderValues.isNotEmpty;

  bool get _isFormValid {
    if (_selectedCustomer == null) return false;
    if (_packageSlipCtrl.text.trim().isEmpty) return false;
    if (_items.isEmpty) return false;
    if (!_items.any((item) => item.qtyToPack > 0)) return false;

    // Check if at least one SO or Picklist is selected
    if (_selectedSalesOrderValues.isEmpty && _selectedPicklistValues.isEmpty) {
      return false;
    }

    // Mandatory fields for items
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.qtyToPack > 0) {
        if (item.itemId == null || item.itemId!.isEmpty) return false;

        // If not picklist mode, batches are mandatory
        if (!_isPicklistMode) {
          if (item.batches.isEmpty) return false;
          // Check if total batch quantity matches qtyToPack
          final batchTotal = item.batches.fold<double>(
            0,
            (sum, b) => sum + b.quantity,
          );
          if ((batchTotal - item.qtyToPack).abs() > 0.001) return false;
        }
      }
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _packageSlipCtrl.text = _generatePackageNumber();
    _loadNextPackageNumber();
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

    _fetchUnits();
  }

  Future<void> _loadNextPackageNumber() async {
    if (!_isAutoGenerate) return;

    try {
      final nextNumberData = await ref.read(nextPackageNumberProvider.future);
      if (!mounted) return;

      setState(() {
        _packagePrefix =
            nextNumberData['prefix']?.toString().trim().isNotEmpty == true
            ? nextNumberData['prefix'].toString()
            : 'PKG-';
        _nextNumber = nextNumberData['next_number'] as int? ?? 1;
        if (_isAutoGenerate) {
          _packageSlipCtrl.text =
              nextNumberData['formatted']?.toString().trim().isNotEmpty == true
              ? nextNumberData['formatted'].toString()
              : _generatePackageNumber();
        }
      });
    } catch (_) {
      // Keep local default
    }
  }

  void _showPackagePreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => _PackagePreferencesDialog(
        initialAutoGenerate: _isAutoGenerate,
        initialPrefix: _packagePrefix,
        initialNextNumber: _nextNumber,
        onSave: (isAuto, prefix, nextNum) async {
          setState(() {
            _isAutoGenerate = isAuto;
            _packagePrefix = prefix;
            _nextNumber = nextNum;
            if (isAuto) {
              _packageSlipCtrl.text = _generatePackageNumber();
            } else {
              _packageSlipCtrl.clear();
            }
          });

          // Save to DB
          try {
            await ref
                .read(inventoryPackagesProvider.notifier)
                .updateNextNumberSettings(prefix: prefix, nextNumber: nextNum);
          } catch (e) {
            if (mounted) {
              ZerpaiToast.error(context, 'Failed to save settings: $e');
            }
          }
        },
      ),
    );
  }

  Future<void> _fetchUnits() async {
    try {
      final fetchedUnits = await _lookupsService.getUnits();
      if (!mounted) return;

      final lengths = fetchedUnits
          .where((u) => u.unitType?.toLowerCase() == 'length')
          .map((u) => u.unitSymbol ?? u.unitName)
          .where((s) => s.isNotEmpty)
          .cast<String>()
          .toList();

      final weights = fetchedUnits
          .where((u) => u.unitType?.toLowerCase() == 'weight')
          .map((u) => u.unitSymbol ?? u.unitName)
          .where((s) => s.isNotEmpty)
          .cast<String>()
          .toList();

      setState(() {
        if (lengths.isNotEmpty) {
          _lengthUnits = lengths;
          if (!_lengthUnits.contains(_dimensionUnit)) {
            _dimensionUnit = _lengthUnits.first;
          }
        }
        if (weights.isNotEmpty) {
          _weightUnits = weights;
          if (!_weightUnits.contains(_weightUnit)) {
            _weightUnit = _weightUnits.first;
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Error fetching units for packages: $e');
    }
  }

  void _switchToManualMode() {
    setState(() {
      _isManualMode = true;
      _packageSlipCtrl.clear(); // Clear for user entry
      _items = [const _PackageItem()];
      _clearRowControllers();
      _rowControllers.add(_PackageItemRowController());
    });
  }

  void _switchToSelectionMode() {
    setState(() {
      _isManualMode = false;
      _items = _salesOrderItems
          .map(
            (item) => _PackageItem(
              itemId: item.itemId,
              itemName: item.item?.productName ?? item.description ?? '',
              ordered: item.quantity,
              qtyToPack: item.quantity,
            ),
          )
          .toList();
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
    setState(() {
      if (index < _items.length) {
        _items.removeAt(index);
      }
      if (index < _rowControllers.length) {
        _rowControllers[index].dispose();
        _rowControllers.removeAt(index);
      }
      if (index < _salesOrderItems.length) {
        _salesOrderItems.removeAt(index);
      }
      if (index < _normalRowControllers.length) {
        _normalRowControllers[index].dispose();
        _normalRowControllers.removeAt(index);
      }
    });
  }

  String _generatePackageNumber() {
    if (!_isAutoGenerate) return _packageSlipCtrl.text;
    return '$_packagePrefix${_nextNumber.toString().padLeft(5, '0')}';
  }

  Future<void> _savePackage() async {
    if (!_isFormValid || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final List<Map<String, dynamic>> itemsPayload = [];

      if (_isManualMode) {
        for (final item in _items) {
          if (item.itemId != null && item.qtyToPack > 0) {
            itemsPayload.add({
              'product_id': item.itemId,
              'quantity': item.qtyToPack,
              'sales_order_id': item.salesOrderId,
              'picklist_id': item.picklistId,
            });
          }
        }
      } else {
        for (var i = 0; i < _items.length; i++) {
          final item = _items[i];
          if (item.qtyToPack > 0) {
            itemsPayload.add({
              'product_id': item.itemId,
              'quantity': item.qtyToPack,
              'sales_order_id': item.salesOrderId,
              'picklist_id': item.picklistId,
            });
          }
        }
      }

      final payload = {
        'customer_id': _selectedCustomer?.id,
        'package_number': _isAutoGenerate ? '' : _packageSlipCtrl.text.trim(),
        'package_date':
            _selectedDate?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'dimension_length':
            double.tryParse(_dimensionLengthCtrl.text.trim()) ?? 0,
        'dimension_width':
            double.tryParse(_dimensionWidthCtrl.text.trim()) ?? 0,
        'dimension_height':
            double.tryParse(_dimensionHeightCtrl.text.trim()) ?? 0,
        'dimension_unit': _dimensionUnit,
        'weight': double.tryParse(_weightCtrl.text.trim()) ?? 0,
        'weight_unit': _weightUnit,
        'is_manual_mode': _isManualMode,
        'notes': _notesCtrl.text.trim(),
        'sales_order_ids': _selectedSalesOrderDataList.map((o) {
          final itemWithBatch = _items.firstWhere(
            (i) => i.salesOrderId == o.id && i.batches.isNotEmpty,
            orElse: () => const _PackageItem(),
          );
          if (itemWithBatch.batches.isNotEmpty) {
            return {
              'sales_order_id': o.id,
              'bin_location': itemWithBatch.batches[0].binLocation,
              'batch_no': itemWithBatch.batches[0].batchNo,
            };
          }
          return o.id;
        }).toList(),
        'picklist_ids': _selectedPicklistValues
            .map((p) => p.id)
            .where((id) => id != null)
            .toList(),
        'items': itemsPayload,
      };

      AppLogger.info('Creating Package', data: payload, module: 'inventory');

      final notifier = ref.read(inventoryPackagesProvider.notifier);
      final success = await notifier.createPackage(payload);

      if (success && mounted) {
        ZerpaiToast.success(context, 'Package generated successfully');
        ref.invalidate(nextPackageNumberProvider);
        context.go(AppRoutes.packages);
      } else if (mounted) {
        final state = ref.read(inventoryPackagesProvider);
        ZerpaiToast.error(context, state.error ?? 'Failed to create package');
      }
    } catch (e) {
      AppLogger.error('Failed to save package', error: e);
      if (mounted) {
        ZerpaiToast.error(context, 'An unexpected error occurred');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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

    _itemNameSearchCtrl.dispose();
    _salesOrderSearchCtrl.dispose();

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

  Future<void> _fetchMultipleSalesOrderItems(List<String> salesOrderIds) async {
    setState(() {
      _isLoadingItems = true;
      _salesOrderItems = [];
      _items = []; // Clear items
      _normalRowControllers.clear();
      for (var ctrl in _rowControllers) {
        ctrl.qtyCtrl.dispose();
      }
      _rowControllers.clear();
    });

    try {
      final List<SalesOrderItem> allItems = [];
      final List<SalesOrder> allOrders = [];

      for (var id in salesOrderIds) {
        final order = await ref
            .read(salesOrderApiServiceProvider)
            .getSalesOrderById(id);
        allOrders.add(order);
        final items = (order.items ?? []).toList();
        allItems.addAll(items);
      }

      if (mounted) {
        setState(() {
          _salesOrderItems = allItems;
          _items = allItems.map((item) {
            final order = allOrders.isNotEmpty
                ? allOrders.firstWhere(
                    (o) => o.id == item.salesOrderId,
                    orElse: () => allOrders.first,
                  )
                : SalesOrder(
                    id: '',
                    customerId: '',
                    saleNumber: '',
                    saleDate: DateTime.now(),
                    total: 0.0,
                  );
            return _PackageItem(
              itemId: item.itemId,
              itemName: item.item?.productName ?? item.description ?? '',
              ordered: item.quantity,
              qtyToPack: item.quantity,
              salesOrderId: item.salesOrderId,
              salesOrderNumber: order.saleNumber,
            );
          }).toList();

          _rowControllers.clear();
          _rowControllers.addAll(
            List.generate(_items.length, (_) => _PackageItemRowController()),
          );
          for (var i = 0; i < _items.length; i++) {
            _rowControllers[i].qtyCtrl.text = _items[i].qtyToPack.toString();
          }

          _normalRowControllers.clear();
          _normalRowControllers.addAll(
            List.generate(
              allItems.length,
              (i) =>
                  TextEditingController(text: allItems[i].quantity.toString()),
            ),
          );
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingItems = false);
        ZerpaiToast.error(context, 'Error fetching items: $e');
      }
    }
  }

  Future<void> _generateItemsFromPicklists(List<Picklist> picklists) async {
    setState(() {
      _isLoadingItems = true;
      _isPicklistMode = true;
      _salesOrderItems = [];
      _clearRowControllers();
      for (var ctrl in _normalRowControllers) {
        ctrl.dispose();
      }
      _normalRowControllers.clear();
    });

    final List<SalesOrderItem> allItems = [];
    final List<_PackageItem> collectedItems = [];
    final repository = ref.read(inventoryPicklistRepositoryProvider);

    try {
      for (var p in picklists) {
        // If items are missing (common in list view responses), fetch full details
        Picklist? fullPicklist = p;
        if (p.items.isEmpty && p.id != null) {
          fullPicklist = await repository.getPicklist(p.id!);
        }

        if (fullPicklist != null) {
          for (var pi in fullPicklist.items) {
            allItems.add(
              SalesOrderItem(
                id: pi.id ?? '',
                salesOrderId: fullPicklist.picklistNumber,
                itemId: pi.productId ?? '',
                quantity: pi.qtyToPick,
                rate: 0.0,
                description: pi.productName ?? '',
                item: null,
              ),
            );
            // Store picklist UUID in a way we can use it later
            collectedItems.add(
              _PackageItem(
                itemId: pi.productId ?? '',
                itemName: pi.productName ?? '',
                ordered: pi.qtyToPick,
                qtyToPack: pi.qtyToPick,
                picklistId: fullPicklist.id,
                salesOrderId: pi.salesOrderId,
                salesOrderNumber: pi.salesOrderNumber,
              ),
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error fetching picklist items', error: e);
    }

    if (mounted) {
      setState(() {
        _items = collectedItems;
        _salesOrderItems = allItems;

        _rowControllers.clear();
        _rowControllers.addAll(
          List.generate(_items.length, (_) => _PackageItemRowController()),
        );
        for (var i = 0; i < _items.length; i++) {
          _rowControllers[i].qtyCtrl.text = _items[i].qtyToPack.toString();
        }

        _normalRowControllers.clear();
        _normalRowControllers.addAll(
          List.generate(
            allItems.length,
            (i) => TextEditingController(text: allItems[i].quantity.toString()),
          ),
        );
        _isLoadingItems = false;
      });
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
                  onPressed: () => context.go(AppRoutes.packages),
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
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormRow(
                                    label: 'Customer Name',
                                    child: ref
                                        .watch(salesCustomersProvider)
                                        .when(
                                          data: (customers) =>
                                              FormDropdown<SalesCustomer>(
                                                fillColor: Colors.white,
                                                textStyle: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                  color: _textPrimary,
                                                ),
                                                value: _selectedCustomer,
                                                hint: 'Select Customer',
                                                items: customers,
                                                maxVisibleItems: 4,
                                                itemBuilder:
                                                    (
                                                      item,
                                                      isSelected,
                                                      isHovered,
                                                    ) =>
                                                        _buildCustomerDropdownItem(
                                                          item,
                                                          isSelected,
                                                          isHovered,
                                                        ),
                                                displayStringForValue: (val) =>
                                                    val.displayName,
                                                searchStringForValue: (val) =>
                                                    val.displayName,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _selectedCustomer = val;
                                                    _selectedSalesOrderValues =
                                                        [];
                                                    _selectedSalesOrderDataList =
                                                        [];
                                                    _selectedPicklistValues =
                                                        [];
                                                    _salesOrderItems = [];
                                                    _clearRowControllers();
                                                  });
                                                  if (val != null) {
                                                    ref.invalidate(
                                                      salesOrdersByCustomerProvider(
                                                        val.id,
                                                      ),
                                                    );
                                                  }
                                                },
                                                height: 32,
                                              ),
                                          loading: () => const Skeleton(
                                            height: 32,
                                            width: double.infinity,
                                          ),
                                          error: (e, _) => Text('Error: $e'),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: _buildFormRow(
                                    label: 'Sales Order#',
                                    isRequired: true,
                                    child: _selectedCustomer == null
                                        ? FormDropdown<String>(
                                            fillColor: AppTheme.bgDisabled,
                                            value: null,
                                            hint: 'Select Sales Order',
                                            items: const [],
                                            itemBuilder:
                                                (item, isSelected, isHovered) =>
                                                    _commonItemBuilder<String>(
                                                      item,
                                                      isSelected,
                                                      isHovered,
                                                      (s) => s,
                                                    ),
                                            displayStringForValue: (s) => s,
                                            searchStringForValue: (s) => s,
                                            onChanged: (val) {},
                                            height: 32,
                                          )
                                        : ref
                                              .watch(
                                                salesOrdersByCustomerProvider(
                                                  _selectedCustomer!.id,
                                                ),
                                              )
                                              .when(
                                                data: (orders) => FormDropdown<SalesOrder>(
                                                  value: null,
                                                  onChanged: (val) {},
                                                  fillColor: Colors.white,
                                                  textStyle: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w400,
                                                    color: _textPrimary,
                                                  ),
                                                  multiSelect: true,
                                                  selectedValues:
                                                      _selectedSalesOrderDataList,
                                                  onSelectedValuesChanged: (vals) {
                                                    setState(() {
                                                      _isPicklistMode = false;
                                                      _selectedSalesOrderDataList =
                                                          vals;
                                                      _selectedSalesOrderValues =
                                                          vals
                                                              .map((e) => e.id)
                                                              .toList();
                                                      if (vals.isNotEmpty) {
                                                        _selectedPicklistValues =
                                                            [];
                                                      }
                                                    });
                                                    if (vals.isNotEmpty) {
                                                      _fetchMultipleSalesOrderItems(
                                                        _selectedSalesOrderValues,
                                                      );
                                                    } else {
                                                      setState(() {
                                                        _salesOrderItems = [];
                                                        _items = [];
                                                        _clearRowControllers();
                                                      });
                                                    }
                                                    setState(() {
                                                      _currentPage = 0;
                                                    });
                                                  },
                                                  hint: 'Select Sales Order',
                                                  items: orders
                                                      .where(
                                                        (o) =>
                                                            !_selectedSalesOrderValues
                                                                .contains(o.id),
                                                      )
                                                      .toList(),
                                                  maxVisibleItems: 4,
                                                  itemBuilder:
                                                      (
                                                        item,
                                                        isSelected,
                                                        isHovered,
                                                      ) =>
                                                          _commonItemBuilder<
                                                            SalesOrder
                                                          >(
                                                            item,
                                                            isSelected,
                                                            isHovered,
                                                            (val) =>
                                                                val.saleNumber,
                                                          ),
                                                  displayStringForValue:
                                                      (val) => val.saleNumber,
                                                  searchStringForValue: (val) =>
                                                      val.saleNumber,
                                                  height: 32,
                                                ),
                                                loading: () => const Skeleton(
                                                  height: 32,
                                                  width: double.infinity,
                                                ),
                                                error: (e, _) =>
                                                    Text('Error: $e'),
                                              ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormRow(
                                    label: 'Picklist',
                                    child: ref
                                        .watch(picklistsProvider)
                                        .when(
                                          data: (picklists) {
                                            final filteredPicklists = picklists
                                                .where((p) {
                                                  final matchesCustomer =
                                                      _selectedCustomer ==
                                                          null ||
                                                      p.customerName ==
                                                          _selectedCustomer
                                                              ?.displayName;
                                                  final isNotSelected =
                                                      !_selectedPicklistValues
                                                          .any(
                                                            (s) => s.id == p.id,
                                                          );
                                                  return matchesCustomer &&
                                                      p.isEntrypass == true &&
                                                      isNotSelected;
                                                })
                                                .toList();
                                            return FormDropdown<Picklist>(
                                              value: null,
                                              onChanged: (val) {},
                                              fillColor:
                                                  _selectedCustomer == null
                                                  ? AppTheme.bgDisabled
                                                  : Colors.white,
                                              enabled:
                                                  _selectedCustomer != null,
                                              multiSelect: true,
                                              selectedValues:
                                                  _selectedPicklistValues,
                                              onSelectedValuesChanged: (vals) {
                                                setState(() {
                                                  _selectedPicklistValues =
                                                      vals;
                                                  if (vals.isNotEmpty) {
                                                    _selectedSalesOrderValues =
                                                        [];
                                                    _selectedSalesOrderDataList =
                                                        [];
                                                  }
                                                });
                                                if (vals.isNotEmpty) {
                                                  _generateItemsFromPicklists(
                                                    vals,
                                                  );
                                                } else {
                                                  setState(() {
                                                    _isPicklistMode = false;
                                                    _salesOrderItems = [];
                                                    _items = [];
                                                    _clearRowControllers();
                                                    for (var c
                                                        in _normalRowControllers) {
                                                      c.dispose();
                                                    }
                                                    _normalRowControllers
                                                        .clear();
                                                  });
                                                }
                                                setState(() {
                                                  _currentPage = 0;
                                                });
                                              },
                                              hint: 'Select Picklist',
                                              items: filteredPicklists,
                                              maxVisibleItems: 4,
                                              itemBuilder:
                                                  (
                                                    item,
                                                    isSelected,
                                                    isHovered,
                                                  ) =>
                                                      _commonItemBuilder<
                                                        Picklist
                                                      >(
                                                        item,
                                                        isSelected,
                                                        isHovered,
                                                        (p) => p.picklistNumber,
                                                      ),
                                              displayStringForValue: (p) =>
                                                  p.picklistNumber,
                                              searchStringForValue: (p) =>
                                                  p.picklistNumber,
                                              height: 32,
                                            );
                                          },
                                          loading: () => const Skeleton(
                                            height: 32,
                                            width: double.infinity,
                                          ),
                                          error: (e, _) => Text('Error: $e'),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                const Spacer(),
                              ], // END ROW CHILDREN
                            ), // END ROW
                          ], // END COLUMN CHILDREN
                        ), // END COLUMN
                      ), // END CONSTRAINEDBOX
                    ), // END ALIGN
                  ), // END CONTAINER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),

                        Opacity(
                          opacity:
                              (_isSalesOrderSelected ||
                                  _selectedPicklistValues.isNotEmpty)
                              ? 1.0
                              : 0.3,
                          child: IgnorePointer(
                            ignoring:
                                !(_isSalesOrderSelected ||
                                    _selectedPicklistValues.isNotEmpty),
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
                                          child: CustomTextField(
                                            controller: _packageSlipCtrl,
                                            height: 32,
                                            readOnly: _isAutoGenerate,
                                            suffixWidget: ZTooltip(
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
                                    const SizedBox(width: 32),
                                    SizedBox(
                                      width: 380, // Adjusted for label + field
                                      child: _buildFormRow(
                                        label: 'Date',
                                        isRequired: true,
                                        child: SizedBox(
                                          width: 210,
                                          child: CustomTextField(
                                            controller: _dateCtrl,
                                            height: 32,
                                            readOnly: true,
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
                                            suffixWidget: const Icon(
                                              LucideIcons.calendar,
                                              size: 16,
                                              color: _textSecondary,
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
                                          height: 32,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: _borderCol,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: _dimFocused
                                                          ? _focusBorder
                                                          : Colors.transparent,
                                                      width: _dimFocused
                                                          ? 1.4
                                                          : 0,
                                                    ),
                                                  ),
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
                                                          keyboardType:
                                                              const TextInputType.numberWithOptions(
                                                                decimal: true,
                                                              ),
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter.allow(
                                                              RegExp(r'[0-9.]'),
                                                            ),
                                                          ],
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                fontFamily:
                                                                    'Inter',
                                                              ),
                                                          decoration:
                                                              const InputDecoration(
                                                                contentPadding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          8,
                                                                    ),
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
                                                          fontSize: 12,
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
                                                          keyboardType:
                                                              const TextInputType.numberWithOptions(
                                                                decimal: true,
                                                              ),
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter.allow(
                                                              RegExp(r'[0-9.]'),
                                                            ),
                                                          ],
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                fontFamily:
                                                                    'Inter',
                                                              ),
                                                          decoration:
                                                              const InputDecoration(
                                                                contentPadding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          8,
                                                                    ),
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
                                                          fontSize: 12,
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
                                                          keyboardType:
                                                              const TextInputType.numberWithOptions(
                                                                decimal: true,
                                                              ),
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter.allow(
                                                              RegExp(r'[0-9.]'),
                                                            ),
                                                          ],
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                fontFamily:
                                                                    'Inter',
                                                              ),
                                                          decoration:
                                                              const InputDecoration(
                                                                contentPadding:
                                                                    EdgeInsets.symmetric(
                                                                      vertical:
                                                                          8,
                                                                    ),
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
                                              ),
                                              Container(
                                                height: 30,
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
                                                  height: 30,
                                                  fillColor:
                                                      AppTheme.bgDisabled,
                                                  border: Border.all(
                                                    color: Colors.transparent,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 2,
                                                      ),
                                                  hideBorderDefault: true,
                                                  showSearch: false,
                                                  value: _dimensionUnit,
                                                  items: _lengthUnits,
                                                  textAlign: TextAlign.center,
                                                  maxVisibleItems: 3,
                                                  itemBuilder:
                                                      (
                                                        item,
                                                        isSelected,
                                                        isHovered,
                                                      ) =>
                                                          _centeredUnitItemBuilder(
                                                            item,
                                                            isSelected,
                                                            isHovered,
                                                          ),
                                                  displayStringForValue: (s) =>
                                                      s,
                                                  searchStringForValue: (s) =>
                                                      s,
                                                  onChanged: (val) {
                                                    if (val == null) return;
                                                    setState(
                                                      () =>
                                                          _dimensionUnit = val,
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
                                          height: 32,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: _borderCol,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          _weightFocusNode
                                                              .hasFocus
                                                          ? _focusBorder
                                                          : Colors.transparent,
                                                      width:
                                                          _weightFocusNode
                                                              .hasFocus
                                                          ? 1.4
                                                          : 0,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: TextField(
                                                      controller: _weightCtrl,
                                                      focusNode:
                                                          _weightFocusNode,
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(
                                                          RegExp(r'[0-9.]'),
                                                        ),
                                                      ],
                                                      textAlignVertical:
                                                          TextAlignVertical
                                                              .center,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontFamily: 'Inter',
                                                      ),
                                                      decoration:
                                                          const InputDecoration(
                                                            contentPadding:
                                                                EdgeInsets.symmetric(
                                                                  vertical: 8,
                                                                ),
                                                            border: InputBorder
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
                                                ),
                                              ),
                                              Container(
                                                height: 30,
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
                                                  height: 30,
                                                  fillColor:
                                                      AppTheme.bgDisabled,
                                                  border: Border.all(
                                                    color: Colors.transparent,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 2,
                                                      ),
                                                  hideBorderDefault: true,
                                                  showSearch: false,
                                                  value: _weightUnit,
                                                  items: _weightUnits,
                                                  textAlign: TextAlign.center,
                                                  maxVisibleItems: 3,
                                                  itemBuilder:
                                                      (
                                                        item,
                                                        isSelected,
                                                        isHovered,
                                                      ) =>
                                                          _centeredUnitItemBuilder(
                                                            item,
                                                            isSelected,
                                                            isHovered,
                                                          ),
                                                  displayStringForValue: (s) =>
                                                      s,
                                                  searchStringForValue: (s) =>
                                                      s,
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
                                                alignment: PlaceholderAlignment
                                                    .baseline,
                                                baseline:
                                                    TextBaseline.alphabetic,
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
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
                  onPressed: (_isFormValid && !_isSaving) ? _savePackage : null,
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
                  onPressed: () => context.go(AppRoutes.packages),
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
                    'Close',
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

  Widget _buildHeaderSearchField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
    required bool isSearchVisible,
    required VoidCallback onToggle,
    TextAlign textAlign = TextAlign.start,
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
              fontWeight: FontWeight.w600,
              color: _textSecondary,
              fontFamily: 'Inter',
            ),
          ),
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
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final filteredItems = _salesOrderItems.where((item) {
      final matchesName = (item.item?.productName ?? item.description ?? '')
          .toLowerCase()
          .contains(_itemNameSearchQuery.toLowerCase());

      if (_isPicklistMode) {
        // In picklist mode, salesOrderId holds the picklist number
        final matchesSearch = (item.salesOrderId ?? '').toLowerCase().contains(
          _salesOrderSearchQuery.toLowerCase(),
        );
        return matchesName && matchesSearch;
      }

      final order = _selectedSalesOrderDataList.firstWhere(
        (o) => o.id == item.salesOrderId,
        orElse: () => _selectedSalesOrderDataList.isNotEmpty
            ? _selectedSalesOrderDataList.first
            : SalesOrder(
                id: '',
                customerId: '',
                saleNumber: '',
                saleDate: DateTime.now(),
                total: 0.0,
              ),
      );
      final matchesSO = order.saleNumber.toLowerCase().contains(
        _salesOrderSearchQuery.toLowerCase(),
      );

      return matchesName && matchesSO;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderCol),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          if (filteredItems.isEmpty)
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
          else ...[
            ...filteredItems
                .skip(_currentPage * _itemsPerPage)
                .take(_itemsPerPage)
                .toList()
                .asMap()
                .entries
                .map((entry) {
                  final pageIndex = entry.key;
                  final globalIndex =
                      (_currentPage * _itemsPerPage) + pageIndex;
                  final item = entry.value;
                  return _buildItemRowNormal(
                    globalIndex,
                    item,
                    filteredItems,
                    isFirstOnPage: pageIndex == 0,
                  );
                }),
            _buildPaginationFooter(filteredItems.length),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(int totalItems) {
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: _borderCol)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Page ${_currentPage + 1} of $totalPages',
            style: const TextStyle(fontSize: 12, color: _textSecondary),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(LucideIcons.chevronLeft, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(LucideIcons.chevronRight, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRowNormal(
    int index,
    SalesOrderItem soItem,
    List<SalesOrderItem> filteredItems, {
    bool isFirstOnPage = false,
  }) {
    final bool isFirstInGroup =
        isFirstOnPage ||
        index == 0 ||
        filteredItems[index - 1].salesOrderId != soItem.salesOrderId;
    final bool isLastInGroup =
        index == filteredItems.length - 1 ||
        filteredItems[index + 1].salesOrderId != soItem.salesOrderId;

    final String displayNumber;
    if (_isPicklistMode) {
      displayNumber = soItem.salesOrderId ?? '';
    } else {
      final order = _selectedSalesOrderDataList.firstWhere(
        (o) => o.id == soItem.salesOrderId,
        orElse: () => _selectedSalesOrderDataList.isNotEmpty
            ? _selectedSalesOrderDataList.firstWhere(
                (o) => o.id == soItem.salesOrderId,
                orElse: () => _selectedSalesOrderDataList.first,
              )
            : SalesOrder(
                id: '',
                customerId: '',
                saleNumber: '',
                saleDate: DateTime.now(),
                total: 0.0,
              ),
      );
      displayNumber = order.saleNumber;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: Container(
        padding: const EdgeInsets.only(left: 24, right: 0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: isLastInGroup
                        ? const Border(bottom: BorderSide(color: _borderCol))
                        : null,
                  ),
                  child: isFirstInGroup
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            displayNumber,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: _textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
              const VerticalDivider(width: 1, color: _borderCol),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, right: 12, left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          soItem.item?.productName ??
                              soItem.description ??
                              'Unknown Item',
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
                ),
              ),
              const VerticalDivider(width: 1, color: _borderCol),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        soItem.quantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, color: _borderCol),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        '0',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, color: _borderCol),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildQuantityCell(
                        index,
                        _buildNormalQtyInput(index, soItem),
                        _rowSelectedWarehouses[index] ?? "ZABNIX PVT/LTD",
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 40,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _borderCol)),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _hoveredRowIndex == index ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 100),
                    child: IconButton(
                      onPressed: () {
                        // Find the index in the original _items list
                        final originalIndex = _items.indexWhere(
                          (it) =>
                              it.itemId == soItem.itemId &&
                              it.salesOrderId == soItem.salesOrderId,
                        );
                        if (originalIndex != -1) {
                          _removeItem(originalIndex);
                        }
                      },
                      icon: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: _dangerRed,
                      ),
                      splashRadius: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalQtyInput(int index, SalesOrderItem soItem) {
    if (index >= _normalRowControllers.length) return const SizedBox();
    return TextField(
      controller: _normalRowControllers[index],
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _borderCol),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _focusBorder, width: 1.4),
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
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _borderCol),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTableHeader(),
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                final bool isFirstInGroup =
                    index == 0 ||
                    _items[index - 1].salesOrderId != item.salesOrderId;
                final bool isLastInGroup =
                    index == _items.length - 1 ||
                    _items[index + 1].salesOrderId != item.salesOrderId;

                return _buildManualRow(
                  index,
                  item,
                  isFirstInGroup: isFirstInGroup,
                  isLastInGroup: isLastInGroup,
                );
              }),
            ],
          ),
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
      padding: const EdgeInsets.only(left: 24, right: 0, top: 10, bottom: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: _borderCol)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildHeaderSearchField(
                  label: _isPicklistMode ? 'PICKLIST' : 'SALES ORDER',
                  controller: _salesOrderSearchCtrl,
                  hintText: 'Search SO...',
                  isSearchVisible: _isSOSearchVisible,
                  onToggle: () =>
                      setState(() => _isSOSearchVisible = !_isSOSearchVisible),
                  onChanged: (val) => setState(() {
                    _salesOrderSearchQuery = val;
                    _currentPage = 0;
                  }),
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: _borderCol),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, left: 12),
                child: _buildHeaderSearchField(
                  label: 'ITEMS & DESCRIPTION',
                  controller: _itemNameSearchCtrl,
                  hintText: 'Search items...',
                  isSearchVisible: _isItemSearchVisible,
                  onToggle: () => setState(
                    () => _isItemSearchVisible = !_isItemSearchVisible,
                  ),
                  onChanged: (val) => setState(() {
                    _itemNameSearchQuery = val;
                    _currentPage = 0;
                  }),
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: _borderCol),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'ORDERED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: _borderCol),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'PACKED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: _borderCol),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  'QTY TO PACK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildManualRow(
    int index,
    _PackageItem item, {
    bool isFirstInGroup = true,
    bool isLastInGroup = true,
  }) {
    // ignore: unused_local_variable
    final ctrl = _rowControllers[index];
    final soItems = _salesOrderItems;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredManualRowIndex = index),
      onExit: (_) => setState(() => _hoveredManualRowIndex = null),
      child: Container(
        padding: const EdgeInsets.only(left: 24, right: 0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: isLastInGroup
                        ? const Border(bottom: BorderSide(color: _borderCol))
                        : null,
                  ),
                  child: isFirstInGroup && item.salesOrderNumber != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            item.salesOrderNumber!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: _textPrimary,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
              const VerticalDivider(width: 1, color: _borderCol),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormDropdown<SalesOrderItem>(
                        fillColor: Colors.white,
                        value: soItems
                            .where(
                              (it) =>
                                  it.itemId == item.itemId &&
                                  it.salesOrderId == item.salesOrderId,
                            )
                            .firstOrNull,
                        hint: 'Select Item',
                        items: soItems.where((si) {
                          // Filter out already selected items, but keep the current row's item
                          final isAlreadySelected = _items.asMap().entries.any(
                            (entry) =>
                                entry.key != index &&
                                entry.value.itemId == si.itemId &&
                                entry.value.salesOrderId == si.salesOrderId,
                          );
                          return !isAlreadySelected;
                        }).toList(),
                        maxVisibleItems: 6,
                        itemBuilder: (it, isSelected, isHovered) =>
                            _commonItemBuilder<SalesOrderItem>(
                              it,
                              isSelected,
                              isHovered,
                              (val) =>
                                  val.item?.productName ??
                                  val.description ??
                                  '',
                            ),
                        displayStringForValue: (val) =>
                            val.item?.productName ?? val.description ?? '',
                        searchStringForValue: (val) =>
                            val.item?.productName ?? val.description ?? '',
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            final order = _selectedSalesOrderDataList
                                .firstWhere(
                                  (o) => o.id == val.salesOrderId,
                                  orElse: () =>
                                      _selectedSalesOrderDataList.isNotEmpty
                                      ? _selectedSalesOrderDataList.first
                                      : SalesOrder(
                                          id: '',
                                          customerId: '',
                                          saleNumber: 'Unknown',
                                          saleDate: DateTime.now(),
                                          total: 0,
                                        ),
                                );
                            _items[index] = _items[index].copyWith(
                              itemId: val.itemId,
                              itemName:
                                  val.item?.productName ??
                                  val.description ??
                                  '',
                              ordered: val.quantity,
                              qtyToPack: val.quantity,
                              batches:
                                  const [], // Reset batches when product changes
                              salesOrderId: val.salesOrderId,
                              salesOrderNumber: order.saleNumber,
                            );
                            _rowControllers[index].qtyCtrl.text = val.quantity
                                .toString();
                          });

                          // Auto-generate new row if this is the last row
                          if (index == _items.length - 1) {
                            _insertManualRow();
                          }
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
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1, color: _borderCol),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  child: Center(
                    child: Text(
                      item.ordered.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, color: _borderCol),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  child: Center(
                    child: Text(
                      item.packed.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, color: _borderCol),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _borderCol)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IgnorePointer(
                        ignoring: item.itemId == null || item.itemId!.isEmpty,
                        child: Opacity(
                          opacity:
                              (item.itemId != null && item.itemId!.isNotEmpty)
                              ? 1.0
                              : 0.4,
                          child: _buildQuantityCell(
                            index,
                            _buildQtyInput(index),
                            _rowSelectedWarehouses[index] ?? "ZABNIX PVT/LTD",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 40,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _borderCol)),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _hoveredManualRowIndex == index ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 100),
                    child: IconButton(
                      onPressed: () => _removeItem(index),
                      icon: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: _dangerRed,
                      ),
                      splashRadius: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityCell(int index, Widget qtyInput, String warehouseName) {
    // Mock available quantity for demo based on index to show red color when <= 0
    final avlQty = index == 1 ? -2 : 0;
    final isDanger = avlQty <= 0;
    final currentView = _rowSelectedViews[index] ?? 'Available for Sale';
    final item = _items[index];

    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: 80, child: qtyInput),
          const SizedBox(height: 12),
          Text(
            '$currentView:',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1F2937),
              fontFamily: 'Inter',
            ),
          ),
          Text(
            '$avlQty pcs',
            style: TextStyle(
              fontSize: 11,
              color: isDanger
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          WarehouseHoverPopover(
            warehouseName: warehouseName,
            selectedView: currentView,
            onViewChanged: (newView) {
              setState(() {
                _rowSelectedViews[index] = newView;
              });
            },
            onWarehouseChanged: (newName) {
              // We need the ID for the warehouse.
              // Since WarehouseHoverPopover only gives name,
              // we look it up in the warehousesProvider cache.
              ref.read(warehousesProvider).whenData((warehouses) {
                final w = warehouses.firstWhere(
                  (element) => element.name == newName,
                  orElse: () => warehouses.isNotEmpty
                      ? warehouses.first
                      : warehouses
                            .first, // This will still throw if empty, but better than nothing
                );
                setState(() {
                  _rowSelectedWarehouses[index] = newName;
                  _rowSelectedWarehouseIds[index] = w.id;
                });
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.building,
                  size: 12,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 4),
                Text(
                  warehouseName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2563EB),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (!_isPicklistMode &&
              item.qtyToPack > 0 &&
              item.qtyToPack <= item.ordered) ...[
            if (_savedBatchKeys.contains(index)) ...[
              InkWell(
                onTap: () => _showSelectBatchDialog(index),
                child: Text(
                  _buildBatchSummaryText(index),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2563EB),
                    fontFamily: 'Inter',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ] else ...[
              InkWell(
                onTap: () => _showSelectBatchDialog(index),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 12,
                      color: Color(0xFFEF4444),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Select Batch',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQtyInput(int index) {
    if (index >= _rowControllers.length) return const SizedBox();
    final ctrl = _rowControllers[index];
    final fieldKey = 'qty-$index';
    final isActive =
        _hoveredQtyFields.contains(fieldKey) ||
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
          style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
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
                color: _items[index].qtyToPack > _items[index].ordered
                    ? const Color(0xFFEF4444)
                    : (_items[index].qtyToPack > 0
                          ? const Color(0xFF2563EB)
                          : (isActive ? _focusBorder : _borderCol)),
                width: (_items[index].qtyToPack > 0) ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _items[index].qtyToPack > _items[index].ordered
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF2563EB),
                width: 1.4,
              ),
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
      qtyToPack =
          double.tryParse(_rowControllers[index].qtyCtrl.text) ??
          (item.ordered - item.packed);
    }
    if (qtyToPack <= 0) qtyToPack = 1.0;

    final result = await showDialog<_PackageBatchDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PackageBatchSelectionDialog(
        itemId: item.itemId,
        itemName: item.itemName,
        warehouseName: _rowSelectedWarehouses[index] ?? "ZABNIX PVT/LTD",
        warehouseId: _rowSelectedWarehouseIds[index],
        totalQuantity: qtyToPack,
        savedBatches: item.batches,
      ),
    );

    if (result != null) {
      setState(() {
        _items[index] = _items[index].copyWith(
          batches: result.batches,
          qtyToPack: result.overwriteLineItem
              ? result.appliedQuantity
              : item.qtyToPack,
        );
        if (result.overwriteLineItem) {
          _rowControllers[index].qtyCtrl.text = result.appliedQuantity
              .toInt()
              .toString();
        }
        _savedBatchKeys.add(index);
        _savedBatchCounts[index] = result.batchCount;
      });
    }
  }

  String _buildBatchSummaryText(int index) {
    final item = _items[index];
    final qty =
        double.tryParse(_rowControllers[index].qtyCtrl.text) ?? item.qtyToPack;
    return '${qty.toInt()} pcs taken from\n${_savedBatchCounts[index] ?? 1} ${(_savedBatchCounts[index] ?? 1) == 1 ? "batch" : "batches"}';
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
  final String? salesOrderId;
  final String? salesOrderNumber;
  final String? picklistId;

  const _PackageItem({
    this.itemId,
    this.itemName = '',
    this.ordered = 0,
    this.packed = 0,
    this.qtyToPack = 0,
    this.batches = const [],
    this.salesOrderId,
    this.salesOrderNumber,
    this.picklistId,
  });

  _PackageItem copyWith({
    String? itemId,
    String? itemName,
    double? ordered,
    double? packed,
    double? qtyToPack,
    List<_PackageBatch>? batches,
    String? salesOrderId,
    String? salesOrderNumber,
    String? picklistId,
  }) {
    return _PackageItem(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      ordered: ordered ?? this.ordered,
      packed: packed ?? this.packed,
      qtyToPack: qtyToPack ?? this.qtyToPack,
      batches: batches ?? this.batches,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      salesOrderNumber: salesOrderNumber ?? this.salesOrderNumber,
      picklistId: picklistId ?? this.picklistId,
    );
  }
}

class _PackagePreferencesDialog extends StatefulWidget {
  final bool initialAutoGenerate;
  final String initialPrefix;
  final int initialNextNumber;
  final void Function(bool isAuto, String prefix, int nextNumber) onSave;

  const _PackagePreferencesDialog({
    required this.initialAutoGenerate,
    required this.initialPrefix,
    required this.initialNextNumber,
    required this.onSave,
  });

  @override
  State<_PackagePreferencesDialog> createState() =>
      _PackagePreferencesDialogState();
}

class _PackagePreferencesDialogState extends State<_PackagePreferencesDialog> {
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
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Container(
        width: 500,
        padding: EdgeInsets.zero,
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
                      color: _textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: _textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderCol),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your package slip numbers are set on auto-generate mode to save your time.',
                    style: TextStyle(fontSize: 14, color: _textPrimary),
                  ),
                  const Text(
                    'Are you sure about changing this setting?',
                    style: TextStyle(fontSize: 14, color: _textPrimary),
                  ),
                  const SizedBox(height: 24),
                  RadioScope<bool>(
                    value: _isAuto,
                    onChanged: (val) => setState(() => _isAuto = val),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const RadioGroupItem<bool>(
                          value: true,
                          label:
                              'Continue auto-generating package slip numbers',
                          activeColor: _focusBorder,
                        ),
                        if (_isAuto) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 48, top: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Prefix',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _prefixCtrl,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            borderSide: const BorderSide(
                                              color: _borderCol,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            borderSide: const BorderSide(
                                              color: _borderCol,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Next Number',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _numberCtrl,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            borderSide: const BorderSide(
                                              color: _borderCol,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            borderSide: const BorderSide(
                                              color: _borderCol,
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
                        const RadioGroupItem<bool>(
                          value: false,
                          label: 'Enter package slip numbers manually',
                          activeColor: _focusBorder,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderCol),
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
                      backgroundColor: _greenBtn,
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
                      foregroundColor: _textPrimary,
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

class _PackageItemRowController {
  final TextEditingController qtyCtrl;

  _PackageItemRowController() : qtyCtrl = TextEditingController(text: '0');

  void dispose() {
    qtyCtrl.dispose();
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

class _PackageBatchSelectionDialog extends ConsumerStatefulWidget {
  final String? itemId;
  final String itemName;
  final String warehouseName;
  final String? warehouseId;
  final double totalQuantity;
  final List<_PackageBatch> savedBatches;

  const _PackageBatchSelectionDialog({
    this.itemId,
    required this.itemName,
    required this.warehouseName,
    this.warehouseId,
    required this.totalQuantity,
    this.savedBatches = const [],
  });

  @override
  ConsumerState<_PackageBatchSelectionDialog> createState() =>
      _PackageBatchSelectionDialogState();
}

class _PackageBatchSelectionDialogState
    extends ConsumerState<_PackageBatchSelectionDialog> {
  final List<_PackageBatchRowController> _rows = [];
  final Set<int> _hoveredBatchRows = {};
  List<String> _binLocations = [];
  bool _overwriteLineItem = false;
  bool _showMfgDetails = false;
  bool _showFocColumn = false;
  bool _isLoadingBins = false;

  @override
  void initState() {
    super.initState();
    _loadBins();
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

        if (b.expDate != null) {
          try {
            row.expDate = DateFormat('dd-MM-yyyy').parse(b.expDate!);
          } catch (_) {}
        }
        if (b.mfgDate != null) {
          try {
            row.mfgDate = DateFormat('dd-MM-yyyy').parse(b.mfgDate!);
          } catch (_) {}
        }

        _rows.add(row);
      }
    } else {
      _addRow();
      if (_rows.isNotEmpty) {
        _rows[0].qtyOutCtrl.text = widget.totalQuantity.toInt().toString();
      }
    }
  }

  Future<void> _loadBins() async {
    String? warehouseId = widget.warehouseId;

    // Fix: Properly await warehouse resolution if ID is missing
    if (warehouseId == null || warehouseId.isEmpty) {
      debugPrint('⚠️ Warehouse ID missing. Resolving from provider...');
      try {
        final warehouses = await ref.read(warehousesProvider.future);
        if (warehouses.isNotEmpty) {
          final defaultW = warehouses.firstWhere(
            (w) => w.name == widget.warehouseName,
            orElse: () => warehouses.first,
          );
          warehouseId = defaultW.id;
          debugPrint('✅ Resolved warehouse ID to: $warehouseId');
        }
      } catch (e) {
        debugPrint('❌ Failed to resolve warehouse: $e');
      }
    }

    if (warehouseId == null || warehouseId.isEmpty) {
      debugPrint('❌ Cannot load bins: Warehouse ID is still null');
      return;
    }

    setState(() => _isLoadingBins = true);
    try {
      debugPrint(
        '🔄 Loading bins for Packages - Warehouse: $warehouseId, Product: ${widget.itemId}',
      );
      final repository = ref.read(inventoryPicklistRepositoryProvider);

      // Using widget.itemId to filter bins by the specific product (same logic as Picklist)
      final bins = await repository.getWarehouseBins(
        warehouseId: warehouseId,
        productId: widget.itemId,
      );

      debugPrint('📦 Found ${bins.length} bins from repository');

      if (mounted) {
        setState(() {
          _binLocations = bins
              .map((b) => (b['binCode'] ?? b['bin_code'] ?? '').toString())
              .where((c) => c.isNotEmpty)
              .toList();
          _isLoadingBins = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading bins: $e');
      if (mounted) setState(() => _isLoadingBins = false);
    }
  }

  @override
  void dispose() {
    for (final r in _rows) r.dispose();
    super.dispose();
  }

  double get _totalQuantityOut => _rows.fold<double>(
    0,
    (sum, r) => sum + (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0),
  );

  void _addRow() {
    setState(() {
      _rows.add(_PackageBatchRowController());
    });
  }

  void _removeRow(int index) {
    setState(() {
      if (_rows.length == 1) {
        _rows[index].batchRefCtrl.clear();
        _rows[index].batchNoCtrl.clear();
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
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          inputFormatters: isNumber
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : null,
          textAlign: isNumber ? TextAlign.right : TextAlign.left,
          textAlignVertical: TextAlignVertical.center,
          strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
          style: TextStyle(
            fontSize: 13,
            color: readOnly ? _textSecondary : _textPrimary,
            fontFamily: 'Inter',
          ),
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
            constraints: const BoxConstraints(minHeight: 38, maxHeight: 38),
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
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required TextEditingController controller,
    required GlobalKey anchorKey,
    required int flex,
    DateTime? currentDate,
    required Function(DateTime) onDateChanged,
    bool readOnly = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 38,
          child: TextField(
            key: anchorKey,
            controller: controller,
            readOnly: true,
            style: TextStyle(
              fontSize: 13,
              color: readOnly ? _textSecondary : _textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              isDense: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              constraints: const BoxConstraints(minHeight: 38, maxHeight: 38),
              filled: true,
              fillColor: readOnly ? const Color(0xFFF9FAFB) : Colors.white,
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
              suffixIconConstraints: const BoxConstraints(
                minHeight: 38,
                maxHeight: 38,
                minWidth: 32,
                maxWidth: 32,
              ),
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(LucideIcons.calendar, size: 14),
              ),
            ),
            onTap: readOnly
                ? null
                : () async {
                    final d = await ZerpaiDatePicker.show(
                      context,
                      initialDate: currentDate ?? DateTime.now(),
                      targetKey: anchorKey,
                    );
                    if (d != null) {
                      onDateChanged(d);
                      controller.text = DateFormat('dd-MM-yyyy').format(d);
                    }
                  },
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
      child: SizedBox(
        width: _showMfgDetails
            ? (_showFocColumn ? 1480 : 1320)
            : (_showFocColumn ? 1320 : 1160),
        height: MediaQuery.of(context).size.height * 0.86,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Select Batches',
                    style: TextStyle(
                      fontSize: 14,
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
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: _dangerRed,
                      ),
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
                      const Icon(
                        LucideIcons.home,
                        size: 14,
                        color: _textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location : ${widget.warehouseName.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'BATCH DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Item: ${widget.itemName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Total Quantity : ${widget.totalQuantity.toInt()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '|',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ),
                      Text(
                        'Quantity to be added : ${_totalQuantityOut.toInt()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
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
                  Checkbox(
                    value: _showMfgDetails,
                    onChanged: (v) => setState(() => _showMfgDetails = v!),
                  ),
                  const Text(
                    'Manufacture Details',
                    style: TextStyle(fontSize: 13, fontFamily: 'Inter'),
                  ),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: _showFocColumn,
                    onChanged: (v) => setState(() => _showFocColumn = v!),
                  ),
                  const Text(
                    'FOC',
                    style: TextStyle(fontSize: 13, fontFamily: 'Inter'),
                  ),
                  const Spacer(),
                  Checkbox(
                    value: _overwriteLineItem,
                    onChanged: (v) => setState(() => _overwriteLineItem = v!),
                  ),
                  Text(
                    'Overwrite the line item with ${_totalQuantityOut.toInt()} quantities',
                    style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Table Content with Skeletonizer
            Expanded(
              child: Skeletonizer(
                enabled: _isLoadingBins,
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      color: const Color(0xFFF9FAFB),
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
                    // Rows
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _rows.length,
                        itemBuilder: (context, i) {
                          final r = _rows[i];
                          final isRowHovered = _hoveredBatchRows.contains(i);
                          return Column(
                            children: [
                              MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _hoveredBatchRows.add(i)),
                                onExit: (_) =>
                                    setState(() => _hoveredBatchRows.remove(i)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 15,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: _BinHoverBox(
                                            isEnabled: r
                                                .binLocationCtrl
                                                .text
                                                .isNotEmpty,
                                            message: r.binLocationCtrl.text,
                                            child: SizedBox(
                                              height: 38,
                                              child: FormDropdown<String>(
                                                height: 38,
                                                maxVisibleItems: 4,
                                                menuMaxHeight: 220,
                                                showSearch: true,
                                                value:
                                                    _binLocations.contains(
                                                      r.binLocationCtrl.text
                                                          .trim(),
                                                    )
                                                    ? r.binLocationCtrl.text
                                                          .trim()
                                                    : null,
                                                items: _binLocations,
                                                hint: 'Select Bin',
                                                displayStringForValue: (v) => v,
                                                onChanged: (v) => setState(
                                                  () => r.binLocationCtrl.text =
                                                      v ?? '',
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
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
                                            height: 38,
                                            child: Consumer(
                                              builder: (context, ref, _) {
                                                final batchesAsync = ref.watch(
                                                  batchLookupProvider(
                                                    widget.itemId ?? '',
                                                  ),
                                                );
                                                final batches =
                                                    batchesAsync.value ?? [];

                                                return FormDropdown<
                                                  Map<String, dynamic>
                                                >(
                                                  height: 38,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: _borderCol,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
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
                                                                r
                                                                    .batchRefCtrl
                                                                    .text
                                                                    .trim(),
                                                            orElse: () =>
                                                                <
                                                                  String,
                                                                  dynamic
                                                                >{},
                                                          )
                                                          .isEmpty
                                                      ? null
                                                      : batches.firstWhere(
                                                          (b) =>
                                                              b['batch_no']
                                                                  ?.toString()
                                                                  .trim() ==
                                                              r
                                                                  .batchRefCtrl
                                                                  .text
                                                                  .trim(),
                                                          orElse: () =>
                                                              batches.first,
                                                        ),
                                                  items: batches,
                                                  hint: 'Select Batch',
                                                  showSearch: true,
                                                  itemBuilder: (item, isSelected, isHovered) {
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
                                                        item['mrp']
                                                            ?.toString() ??
                                                        '0.00';
                                                    final ptr =
                                                        item['ptr']
                                                            ?.toString() ??
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
                                                      v['batch_no']
                                                          ?.toString() ??
                                                      '',
                                                  searchStringForValue: (v) =>
                                                      v['batch_no']
                                                          ?.toString() ??
                                                      '',
                                                  onChanged: (v) {
                                                    setState(() {
                                                      if (v != null) {
                                                        final batchNo =
                                                            v['batch_no']
                                                                ?.toString()
                                                                .trim();
                                                        r.batchRefCtrl.text =
                                                            batchNo ?? '';
                                                        r.batchNoCtrl.text =
                                                            batchNo ?? '';

                                                        // Auto-fill details from selected batch map
                                                        r.unitPackCtrl.text =
                                                            v['unit_pack']
                                                                ?.toString() ??
                                                            '';
                                                        r.expDateCtrl.text =
                                                            v['expiry_date']
                                                                ?.toString() ??
                                                            '';

                                                        final prices =
                                                            v['prices']
                                                                as List?;
                                                        if (prices != null &&
                                                            prices.isNotEmpty) {
                                                          final p = prices[0];
                                                          r.mrpCtrl.text =
                                                              (p['mrp'] as num?)
                                                                  ?.toDouble()
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ) ??
                                                              '0.00';
                                                          r.ptrCtrl.text =
                                                              (p['ptr'] as num?)
                                                                  ?.toDouble()
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ) ??
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
                                        controller: r.unitPackCtrl,
                                        flex: 15,
                                        hint: 'Pack',
                                        isNumber: true,
                                        readOnly: true,
                                      ),
                                      _buildInput(
                                        controller: r.mrpCtrl,
                                        flex: 15,
                                        hint: '0',
                                        isNumber: true,
                                        readOnly: true,
                                      ),
                                      _buildInput(
                                        controller: r.ptrCtrl,
                                        flex: 15,
                                        hint: '0',
                                        isNumber: true,
                                        readOnly: true,
                                      ),
                                      _buildDatePicker(
                                        controller: r.expDateCtrl,
                                        anchorKey: r.expKey,
                                        flex: 15,
                                        currentDate: r.expDate,
                                        onDateChanged: (d) =>
                                            setState(() => r.expDate = d),
                                        readOnly: true,
                                      ),
                                      if (_showMfgDetails) ...[
                                        _buildDatePicker(
                                          controller: r.mfgDateCtrl,
                                          anchorKey: r.mfgKey,
                                          flex: 15,
                                          currentDate: r.mfgDate,
                                          onDateChanged: (d) =>
                                              setState(() => r.mfgDate = d),
                                          readOnly: true,
                                        ),
                                        _buildInput(
                                          controller: r.mfgBatchCtrl,
                                          flex: 15,
                                          hint: 'Mfg Batch',
                                          readOnly: true,
                                        ),
                                      ],
                                      _buildInput(
                                        controller: r.qtyOutCtrl,
                                        flex: 15,
                                        hint: '0',
                                        isNumber: true,
                                      ),
                                      if (_showFocColumn)
                                        _buildInput(
                                          controller: r.focCtrl,
                                          flex: 15,
                                          hint: '0',
                                          isNumber: true,
                                        ),
                                      SizedBox(
                                        width: 24,
                                        child: AnimatedOpacity(
                                          opacity: isRowHovered ? 1 : 0,
                                          duration: const Duration(
                                            milliseconds: 120,
                                          ),
                                          child: IconButton(
                                            onPressed: () => _removeRow(i),
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
                              if (i < _rows.length - 1)
                                const Divider(height: 1, color: _borderCol),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
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
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Divider(height: 1, color: _borderCol),
            // Locked footer for Save/Cancel buttons
            Container(
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

                      final totalApplied = _totalQuantityOut;
                      if ((totalApplied - widget.totalQuantity).abs() >
                              0.0001 &&
                          !_overwriteLineItem) {
                        ZerpaiToast.error(
                          context,
                          'Total Quantity Out ($totalApplied) must be equal to Total Quantity (${widget.totalQuantity.toInt()}) unless overwrite is enabled.',
                        );
                        return;
                      }

                      final batches = _rows
                          .map(
                            (r) => _PackageBatch(
                              binLocation: r.binLocationCtrl.text,
                              batchRef: r.batchRefCtrl.text,
                              batchNo: r.batchNoCtrl.text,
                              unitPack: r.unitPackCtrl.text,
                              mrp: r.mrpCtrl.text,
                              ptr: r.ptrCtrl.text,
                              expDate: r.expDateCtrl.text,
                              mfgDate: r.mfgDateCtrl.text,
                              mfgBatch: r.mfgBatchCtrl.text,
                              quantity: double.tryParse(r.qtyOutCtrl.text) ?? 0,
                              foc: double.tryParse(r.focCtrl.text),
                            ),
                          )
                          .toList();

                      Navigator.pop(
                        context,
                        _PackageBatchDialogResult(
                          overwriteLineItem: _overwriteLineItem,
                          batchCount: batches.length,
                          appliedQuantity: totalApplied,
                          batches: batches,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1F2937),
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
