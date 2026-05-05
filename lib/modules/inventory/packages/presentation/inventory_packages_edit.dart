import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/modules/inventory/picklists/providers/inventory_picklists_provider.dart';
import 'package:zerpai_erp/modules/inventory/packages/providers/inventory_packages_provider.dart';
import 'package:zerpai_erp/shared/widgets/inputs/radio_group.dart';
import 'package:zerpai_erp/modules/sales/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/inventory/picklists/models/inventory_picklist_model.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/inventory/picklists/data/inventory_picklist_repository.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/inventory/packages/models/inventory_package_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';
import 'package:skeletonizer/skeletonizer.dart' hide Skeleton;
import 'package:zerpai_erp/shared/providers/lookup_providers.dart';

// --- Colors ---
const _borderCol = Color(0xFFE5E7EB);
const _textPrimary = Color(0xFF1F2937);
const _textSecondary = Color(0xFF6B7280);
const _focusBorder = Color(0xFF3B82F6);
const _greenBtn = Color(0xFF10B981);
const _dangerRed = Color(0xFFDC2626);

class InventoryPackagesEditScreen extends ConsumerStatefulWidget {
  final String? id;
  const InventoryPackagesEditScreen({super.key, this.id});

  @override
  ConsumerState<InventoryPackagesEditScreen> createState() => _InventoryPackagesEditScreenState();
}

class _InventoryPackagesEditScreenState extends ConsumerState<InventoryPackagesEditScreen> {
  List<_PackageItem> _items = [];
  final List<_PackageItemRowController> _rowControllers = [];
  bool _isSaving = false;
  bool _isPicklistMode = false;
  bool _isAutoGenerate = true;

  final Set<int> _savedBatchKeys = {};
  final Map<int, int> _savedBatchCounts = {};
  final Map<int, String> _rowSelectedWarehouses = {};
  final Map<int, String> _rowSelectedWarehouseIds = {};
  final Map<int, String> _rowSelectedViews = {};

  SalesCustomer? _selectedCustomer;
  List<String> _selectedSalesOrderValues = [];
  List<SalesOrder> _selectedSalesOrderDataList = [];
  Picklist? _selectedPicklist;
  List<Picklist> _selectedPicklistValues = [];
  final TextEditingController _packageSlipCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _dimensionLengthCtrl = TextEditingController();
  final TextEditingController _dimensionWidthCtrl = TextEditingController();
  final TextEditingController _dimensionHeightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  DateTime? _selectedDate;
  String _dimensionUnit = 'cm';
  String _weightUnit = 'kg';
  final List<String> _dimensionUnits = ['cm', 'in', 'mm'];
  final List<String> _weightUnits = ['kg', 'lb', 'g'];
  
  // Focus nodes for dimension highlighting
  final FocusNode _dimLengthFocus = FocusNode();
  final FocusNode _dimWidthFocus = FocusNode();
  final FocusNode _dimHeightFocus = FocusNode();
  bool _dimFocused = false;
  final GlobalKey _dateFieldKey = GlobalKey();
  
  // Auto-generation state
  String _packagePrefix = 'PKG-';
  int _nextPackageNumber = 1;
  bool _isLoadingItems = false;
  bool _hasChanges = false;
  InventoryPackage? _initialPackage;


  // Search State
  final _itemSearchCtrl = TextEditingController();
  final _soSearchCtrl = TextEditingController();

  bool _isItemSearchVisible = false;
  bool _isSOSearchVisible = false;


  final List<TextEditingController> _normalRowControllers = [];

  // Editability constraint
  bool get _canEditItems => !_isPicklistMode;

  bool get _isFormValid {
    if (_selectedCustomer == null) return false;
    if (_packageSlipCtrl.text.trim().isEmpty) return false;
    if (_items.isEmpty) return false;
    if (!_items.any((item) => item.qtyToPack > 0)) return false;

    if (_selectedSalesOrderValues.isEmpty && _selectedPicklistValues.isEmpty) {
      return false;
    }

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.qtyToPack > 0) {
        if (item.itemId == null || item.itemId!.isEmpty) return false;
        if (!_isPicklistMode) {
          if (item.batches.isEmpty) return false;
          final batchTotal = item.batches.fold<double>(0, (sum, b) => sum + b.quantity);
          if ((batchTotal - item.qtyToPack).abs() > 0.001) return false;
        }
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loadPackageData();
    }
    _dateCtrl.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    
    // Listen to dimension focus for blue highlighting
    _dimLengthFocus.addListener(_onDimFocusChange);
    _dimWidthFocus.addListener(_onDimFocusChange);
    _dimHeightFocus.addListener(_onDimFocusChange);
    
    // Add listeners for change tracking
    _packageSlipCtrl.addListener(_checkForChanges);
    _notesCtrl.addListener(_checkForChanges);
    _dimensionLengthCtrl.addListener(_checkForChanges);
    _dimensionWidthCtrl.addListener(_checkForChanges);
    _dimensionHeightCtrl.addListener(_checkForChanges);
    _weightCtrl.addListener(_checkForChanges);
  }

  void _onDimFocusChange() {
    final hasFocus = _dimLengthFocus.hasFocus || _dimWidthFocus.hasFocus || _dimHeightFocus.hasFocus;
    if (hasFocus != _dimFocused) {
      setState(() => _dimFocused = hasFocus);
    }
  }

  void _checkForChanges() {
    if (_initialPackage == null) return;
    
    bool changed = false;
    
    if (_packageSlipCtrl.text != _initialPackage!.packageNumber) changed = true;
    if (_notesCtrl.text != (_initialPackage!.notes ?? '')) changed = true;
    
    final currentLen = double.tryParse(_dimensionLengthCtrl.text) ?? 0;
    if ((currentLen - _initialPackage!.dimensionLength).abs() > 0.001) changed = true;
    
    final currentWidth = double.tryParse(_dimensionWidthCtrl.text) ?? 0;
    if ((currentWidth - _initialPackage!.dimensionWidth).abs() > 0.001) changed = true;
    
    final currentHeight = double.tryParse(_dimensionHeightCtrl.text) ?? 0;
    if ((currentHeight - _initialPackage!.dimensionHeight).abs() > 0.001) changed = true;
    
    final currentWeight = double.tryParse(_weightCtrl.text) ?? 0;
    if ((currentWeight - _initialPackage!.weight).abs() > 0.001) changed = true;
    
    if (_dimensionUnit != _initialPackage!.dimensionUnit) changed = true;
    if (_weightUnit != _initialPackage!.weightUnit) changed = true;
    
    if (_selectedDate != null && _initialPackage!.packageDate != null) {
      if (_selectedDate!.year != _initialPackage!.packageDate!.year ||
          _selectedDate!.month != _initialPackage!.packageDate!.month ||
          _selectedDate!.day != _initialPackage!.packageDate!.day) {
        changed = true;
      }
    } else if (_selectedDate != _initialPackage!.packageDate) {
      changed = true;
    }
    
    // Check items
    if (_items.length != _initialPackage!.items.length) {
      changed = true;
    } else {
      for (int i = 0; i < _items.length; i++) {
        if ((_items[i].qtyToPack - _initialPackage!.items[i].quantity).abs() > 0.001) {
          changed = true;
          break;
        }
      }
    }
    
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  @override
  void dispose() {
    _packageSlipCtrl.removeListener(_checkForChanges);
    _notesCtrl.removeListener(_checkForChanges);
    _dimensionLengthCtrl.removeListener(_checkForChanges);
    _dimensionWidthCtrl.removeListener(_checkForChanges);
    _dimensionHeightCtrl.removeListener(_checkForChanges);
    _weightCtrl.removeListener(_checkForChanges);
    
    _packageSlipCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    _dimensionLengthCtrl.dispose();
    _dimensionWidthCtrl.dispose();
    _dimensionHeightCtrl.dispose();
    _weightCtrl.dispose();
    _itemSearchCtrl.dispose();
    _soSearchCtrl.dispose();
    _dimLengthFocus.dispose();
    _dimWidthFocus.dispose();
    _dimHeightFocus.dispose();
    _clearRowControllers();
    super.dispose();
  }

  void _showPackagePreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => _PackagePreferencesDialog(
        initialAutoGenerate: _isAutoGenerate,
        initialPrefix: _packagePrefix,
        initialNextNumber: _nextPackageNumber,
        onSave: (isAuto, prefix, nextNumber) {
          setState(() {
            _isAutoGenerate = isAuto;
            _packagePrefix = prefix;
            _nextPackageNumber = nextNumber;
          });
        },
      ),
    );
  }
  Widget _centeredUnitItemBuilder(String item, bool isSelected, bool isHovered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isHovered
          ? const Color(0xFF3B82F6)
          : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
      child: Center(
        child: Text(
          item,
          style: TextStyle(
            fontSize: 13,
            color: isHovered ? Colors.white : const Color(0xFF1F2937),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Future<void> _loadPackageData() async {
    if (widget.id == null) return;
    setState(() => _isLoadingItems = true);
    try {
      final pkg = await ref.read(packageByIdProvider(widget.id!).future);
      if (pkg == null || !mounted) return;
      _initialPackage = pkg;

      final List<_PackageItem> loadedItems = [];
      for (final pi in pkg.items) {
        List<_PackageBatch> batches = [];
        if (pi.salesOrderId != null) {
          final soRef = pkg.salesOrderRefs.firstWhere(
            (r) => r.salesOrderId == pi.salesOrderId,
            orElse: () => InventoryPackageSORef(salesOrderId: ''),
          );
          if (soRef.batchNo != null && soRef.batchNo!.isNotEmpty) {
            // Fetch full batch details from DB using the batch lookup provider
            final productId = pi.productId ?? '';
            Map<String, dynamic>? match;
            
            if (productId.isNotEmpty) {
              try {
                final allBatches = await ref.read(batchLookupProvider(productId).future);
                match = allBatches.firstWhere(
                  (b) => b['batch_no']?.toString().trim() == soRef.batchNo!.trim(),
                  orElse: () => <String, dynamic>{},
                );
              } catch (e) {
                AppLogger.error('Failed to fetch batch details for product $productId', error: e);
              }
            }

            batches.add(_PackageBatch(
              batchNo: soRef.batchNo!,
              batchRef: soRef.batchNo!, // Ensure batchRef is also populated
              binLocation: soRef.binLocation,
              quantity: pi.quantity,
              // Load details from the database match if found
              unitPack: match != null && match.isNotEmpty ? match['unit_pack']?.toString() : null,
              mrp: match != null && match.isNotEmpty ? match['mrp']?.toString() : null,
              ptr: match != null && match.isNotEmpty ? match['ptr']?.toString() : null,
              expDate: match != null && match.isNotEmpty ? match['expiry_date']?.toString() : null,
              mfgDate: match != null && match.isNotEmpty ? match['mfg_date']?.toString() : null,
              mfgBatch: match != null && match.isNotEmpty ? match['mfg_batch']?.toString() : null,
            ));
          }
        }

        loadedItems.add(_PackageItem(
          itemId: pi.productId,
          itemName: pi.itemName ?? '',
          qtyToPack: pi.quantity,
          ordered: pi.quantity,
          salesOrderId: pi.salesOrderId,
          salesOrderNumber: pi.salesOrderNumber,
          picklistId: pi.picklistId,
          picklistNumber: pi.picklistNumber,
          batches: batches,
        ));
      }

      setState(() {
        _isAutoGenerate = false;
        _packageSlipCtrl.text = pkg.packageNumber;
        _selectedDate = pkg.packageDate;
        if (_selectedDate != null) {
          _dateCtrl.text = DateFormat('dd-MM-yyyy').format(_selectedDate!);
        }
        _notesCtrl.text = pkg.notes ?? '';
        _dimensionLengthCtrl.text = pkg.dimensionLength.toString();
        _dimensionWidthCtrl.text = pkg.dimensionWidth.toString();
        _dimensionHeightCtrl.text = pkg.dimensionHeight.toString();
        _dimensionUnit = pkg.dimensionUnit;
        _weightCtrl.text = pkg.weight.toString();
        _weightUnit = pkg.weightUnit;

        _items = loadedItems;

        // Populate saved batch tracking
        _savedBatchKeys.clear();
        _savedBatchCounts.clear();
        for (int i = 0; i < _items.length; i++) {
          if (_items[i].batches.isNotEmpty) {
            _savedBatchKeys.add(i);
            _savedBatchCounts[i] = _items[i].batches.length;
          }
        }

        _isPicklistMode = pkg.picklistIds.isNotEmpty;

        _clearRowControllers();
        _rowControllers.addAll(List.generate(_items.length, (_) => _PackageItemRowController()));
        for (int i = 0; i < _items.length; i++) {
          _rowControllers[i].qtyCtrl.text = _items[i].qtyToPack.toInt().toString();
          _rowControllers[i].qtyCtrl.addListener(_checkForChanges);
          _rowSelectedWarehouses[i] = "ZABNIX PVT/LTD";
          // Default warehouse ID for demo/placeholder if needed
          _rowSelectedWarehouseIds[i] = ""; 
        }

        if (pkg.customerId != null) {
          _selectedCustomer = SalesCustomer(
            id: pkg.customerId!,
            displayName: pkg.customerName ?? '',
            firstName: '',
            lastName: '',
            email: '',
            companyName: '',
          );
        }

        _isPicklistMode = pkg.picklistIds.isNotEmpty;

        if (_isPicklistMode) {
          _selectedSalesOrderDataList = [];
          _selectedPicklist = pkg.picklistIds.isNotEmpty 
            ? Picklist(
                id: pkg.picklistIds[0],
                picklistNumber: pkg.picklistNumbers.isNotEmpty ? pkg.picklistNumbers[0] : '',
                date: DateTime.now(),
              )
            : null;
          _selectedPicklistValues = List.generate(
            pkg.picklistIds.length,
            (i) => Picklist(
              id: pkg.picklistIds[i],
              picklistNumber: pkg.picklistNumbers.length > i ? pkg.picklistNumbers[i] : '',
              date: DateTime.now(),
            ),
          );
        } else {
          _selectedSalesOrderValues = pkg.salesOrderIds;
          _selectedSalesOrderDataList = List.generate(
            pkg.salesOrderIds.length,
            (i) => SalesOrder(
              id: pkg.salesOrderIds[i],
              saleNumber: pkg.salesOrderNumbers.length > i ? pkg.salesOrderNumbers[i] : '',
              customerId: pkg.customerId ?? '',
              saleDate: DateTime.now(),
              total: 0.0,
            ),
          );
          _selectedPicklistValues = [];
        }
        _isLoadingItems = false;
      });
    } catch (e) {
      AppLogger.error('Error loading package data', error: e);
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }


  void _clearRowControllers() {
    for (var c in _rowControllers) c.dispose();
    _rowControllers.clear();
    for (var c in _normalRowControllers) c.dispose();
    _normalRowControllers.clear();
  }

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


  Future<void> _savePackage() async {
    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> packageData = {
        'package_number': _packageSlipCtrl.text.trim(),
        'package_date': _selectedDate?.toIso8601String(),
        'notes': _notesCtrl.text.trim(),
        'dimension_length': double.tryParse(_dimensionLengthCtrl.text) ?? 0,
        'dimension_width': double.tryParse(_dimensionWidthCtrl.text) ?? 0,
        'dimension_height': double.tryParse(_dimensionHeightCtrl.text) ?? 0,
        'dimension_unit': _dimensionUnit,
        'weight': double.tryParse(_weightCtrl.text) ?? 0,
        'weight_unit': _weightUnit,
        'items': _items.where((i) => i.qtyToPack > 0).map((i) => {
          'product_id': i.itemId,
          'quantity': i.qtyToPack,
          'sales_order_id': i.salesOrderId,
          'picklist_id': i.picklistId,
        }).toList(),
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
      };

      final success = await ref.read(inventoryPackagesProvider.notifier).updatePackage(widget.id!, packageData);
      
      if (success) {
        ZerpaiToast.success(context, 'Package updated successfully');
        if (mounted) context.go(AppRoutes.packages);
      } else {
        ZerpaiToast.error(context, 'Failed to update package');
      }
    } catch (e) {
      AppLogger.error('Error updating package', error: e);
      ZerpaiToast.error(context, 'An error occurred while updating the package');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
              children: [
                const Icon(LucideIcons.box, size: 24, color: _textPrimary),
                const SizedBox(width: 12),
                const Text(
                  'Edit Package',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InkWell(
                    onTap: () {
                      // TODO: Implement geometry evaluation
                    },
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.activity,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Evaluate packing geometry',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => context.go(AppRoutes.packages),
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: _textSecondary,
                  ),
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
                  // Header Group (Customer & Sale Order)
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
                                    isRequired: true,
                                    child: _buildCustomerDropdown(),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: _buildFormRow(
                                    label: 'Sales Order#',
                                    isRequired: true,
                                    child: _buildSalesOrderDropdown(),
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
                                    child: _buildPicklistDropdown(),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                const Expanded(child: SizedBox()),
                              ],
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
                          opacity: 1.0, // Always visible in edit mode
                          child: IgnorePointer(
                            ignoring: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row 1: Package Slip + Date
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 380,
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
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Date',
                                        isRequired: true,
                                        child: SizedBox(
                                          width: 210,
                                          child: CustomTextField(
                                            key: _dateFieldKey,
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
                                                      DateFormat(
                                                        'dd-MM-yyyy',
                                                      ).format(picked);
                                                });
                                                _checkForChanges();
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
                                        child: _buildDimensionsInput(),
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    SizedBox(
                                      width: 380,
                                      child: _buildFormRow(
                                        label: 'Weight',
                                        child: _buildWeightInput(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(color: _borderCol),
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
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _borderCol)),
            ),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: (_isFormValid && !_isSaving && _hasChanges) ? _savePackage : null,
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
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.packages),
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
                    'Close',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsInput() {
    return Container(
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderCol),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dimensionLengthCtrl,
                      focusNode: _dimLengthFocus,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const Text('×', style: TextStyle(color: _textSecondary, fontSize: 12)),
                  Expanded(
                    child: TextField(
                      controller: _dimensionWidthCtrl,
                      focusNode: _dimWidthFocus,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const Text('×', style: TextStyle(color: _textSecondary, fontSize: 12)),
                  Expanded(
                    child: TextField(
                      controller: _dimensionHeightCtrl,
                      focusNode: _dimHeightFocus,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
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
              border: Border(left: BorderSide(color: _borderCol)),
            ),
            child: FormDropdown<String>(
              height: 30,
              fillColor: AppTheme.bgDisabled,
              border: Border.all(color: Colors.transparent),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              hideBorderDefault: true,
              showSearch: false,
              value: _dimensionUnit,
              items: _dimensionUnits,
              textAlign: TextAlign.center,
              maxVisibleItems: 3,
              itemBuilder: (item, isSelected, isHovered) => _centeredUnitItemBuilder(item, isSelected, isHovered),
              displayStringForValue: (s) => s,
              searchStringForValue: (s) => s,
              onChanged: (val) {
                if (val == null) return;
                setState(() => _dimensionUnit = val);
                _checkForChanges();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInput() {
    return Container(
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderCol),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _weightCtrl,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(
            height: 30,
            width: 60,
            decoration: const BoxDecoration(
              color: AppTheme.bgDisabled,
              border: Border(left: BorderSide(color: _borderCol)),
            ),
            child: FormDropdown<String>(
              height: 30,
              fillColor: AppTheme.bgDisabled,
              border: Border.all(color: Colors.transparent),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              hideBorderDefault: true,
              showSearch: false,
              value: _weightUnit,
              items: _weightUnits,
              textAlign: TextAlign.center,
              maxVisibleItems: 3,
              itemBuilder: (item, isSelected, isHovered) => _centeredUnitItemBuilder(item, isSelected, isHovered),
              displayStringForValue: (s) => s,
              searchStringForValue: (s) => s,
              onChanged: (val) {
                if (val == null) return;
                setState(() => _weightUnit = val);
                _checkForChanges();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
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

                final bool isFirstInGroup = index == 0 ||
                    (_items[index - 1].salesOrderId != item.salesOrderId);
                final bool isLastInGroup = index == _items.length - 1 ||
                    (_items[index + 1].salesOrderId != item.salesOrderId);

                return _buildItemRow(
                  index,
                  item,
                  isFirstInGroup: isFirstInGroup,
                  isLastInGroup: isLastInGroup,
                );
              }),
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
                  label: 'SALES ORDER',
                  controller: _soSearchCtrl,
                  hintText: 'Search...',
                  isSearchVisible: _isSOSearchVisible,
                  onToggle: () =>
                      setState(() => _isSOSearchVisible = !_isSOSearchVisible),
                  onChanged: (v) {},
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
                  controller: _itemSearchCtrl,
                  hintText: 'Search items...',
                  isSearchVisible: _isItemSearchVisible,
                  onToggle: () => setState(
                    () => _isItemSearchVisible = !_isItemSearchVisible,
                  ),
                  onChanged: (v) {},
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
                  style: const TextStyle(
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
                  style: const TextStyle(
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
                child: const Text(
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

  Widget _buildQuantityCell(int index, Widget qtyInput, String warehouseName) {
    // Mock available quantity for demo
    final avlQty = 0;
    final isDanger = avlQty <= 0;
    final currentView = _rowSelectedViews[index] ?? 'Available for Sale';
    final item = _items[index];
    final currentQty = double.tryParse(_rowControllers[index].qtyCtrl.text) ?? item.qtyToPack;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 80, child: qtyInput),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currentView: ',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6B7280),
                fontFamily: 'Inter',
              ),
            ),
            Text(
              '$avlQty pcs',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF059669),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        WarehouseHoverPopover(
          warehouseName: warehouseName,
          selectedView: currentView,
          onViewChanged: (newView) {
            setState(() {
              _rowSelectedViews[index] = newView;
            });
          },
          onWarehouseChanged: (newName) {
            ref.read(warehousesProvider).whenData((warehouses) {
              final w = warehouses.firstWhere(
                (element) => element.name == newName,
                orElse: () => warehouses.first,
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
              const Icon(LucideIcons.layers, size: 10, color: AppTheme.primaryBlue),
              const SizedBox(width: 4),
              Text(
                warehouseName,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        if (!_isPicklistMode && currentQty > 0) ...[
          const SizedBox(height: 4),
          if (_savedBatchKeys.contains(index)) ...[
            InkWell(
              onTap: () => _showSelectBatchDialog(index),
              child: Text(
                _buildBatchSummaryText(index),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryBlue,
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
                    size: 10,
                    color: Color(0xFFEF4444),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Select Batch',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryBlue,
                      fontFamily: 'Inter',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildItemRow(int index, _PackageItem item, {bool isFirstInGroup = true, bool isLastInGroup = true}) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: const Border(bottom: BorderSide(color: _borderCol)),
                ),
                child: isFirstInGroup
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          item.salesOrderNumber ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _textPrimary, fontFamily: 'Inter'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Unit: pcs',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                        fontFamily: 'Inter',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  item.ordered.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  item.packed.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _buildQuantityCell(
                  index,
                  TextField(
                    controller: _rowControllers[index].qtyCtrl,
                    readOnly: !_canEditItems,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.all(8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: _borderCol),
                      ),
                      fillColor:
                          _canEditItems ? Colors.white : AppTheme.bgDisabled,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: _borderCol),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: _focusBorder),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _items[index] = _items[index]
                            .copyWith(qtyToPack: double.tryParse(v) ?? 0);
                      });
                      _checkForChanges();
                    },
                  ),
                  "ZABNIX PVT/LTD",
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    return ref.watch(salesCustomersProvider).when(
      data: (customers) => FormDropdown<SalesCustomer>(
        fillColor: Colors.white,
        enabled: true,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _textPrimary),
        value: _selectedCustomer,
        hint: 'Select Customer',
        items: customers,
        itemBuilder: (item, isSelected, isHovered) => _buildCustomerDropdownItem(item, isSelected, isHovered),
        displayStringForValue: (val) => val.displayName,
        searchStringForValue: (val) => val.displayName,
        onChanged: (val) {},
        height: 32,
      ),
      loading: () => const Skeleton(height: 32, width: double.infinity),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildSalesOrderDropdown() {
    if (_isPicklistMode) {
      return FormDropdown<SalesOrder>(
        fillColor: AppTheme.bgDisabled,
        enabled: false,
        value: null,
        hint: 'Select Sales Order',
        items: const [],
        itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<SalesOrder>(item, isSelected, isHovered, (s) => s.saleNumber),
        displayStringForValue: (s) => s.saleNumber,
        searchStringForValue: (s) => s.saleNumber,
        onChanged: (val) {},
        height: 32,
      );
    }

    return ref.watch(salesOrdersByCustomerProvider(_selectedCustomer?.id ?? '')).when(
      data: (orders) => FormDropdown<SalesOrder>(
        value: null,
        onChanged: (val) {},
        enabled: true,
        fillColor: Colors.white,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _textPrimary),
        multiSelect: true,
        selectedValues: _selectedSalesOrderDataList,
        onSelectedValuesChanged: (vals) {},
        hint: 'Select Sales Order',
        items: orders,
        itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<SalesOrder>(item, isSelected, isHovered, (val) => val.saleNumber),
        displayStringForValue: (val) => val.saleNumber,
        searchStringForValue: (val) => val.saleNumber,
        height: 32,
      ),
      loading: () => const Skeleton(height: 32, width: double.infinity),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildPicklistDropdown() {
    if (!_isPicklistMode) {
      return FormDropdown<Picklist>(
        fillColor: _selectedCustomer == null ? AppTheme.bgDisabled : Colors.white,
        enabled: _selectedCustomer != null,
        value: null,
        hint: 'Select Picklist',
        items: const [],
        itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<Picklist>(item, isSelected, isHovered, (p) => p.picklistNumber),
        displayStringForValue: (val) => val.picklistNumber,
        searchStringForValue: (val) => val.picklistNumber,
        onChanged: (val) {},
        height: 32,
      );
    }

    return ref.watch(picklistsProvider).when(
      data: (picklists) => FormDropdown<Picklist>(
        fillColor: Colors.white,
        enabled: true,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _textPrimary),
        value: _selectedPicklist,
        hint: 'Select Picklist',
        items: picklists,
        itemBuilder: (item, isSelected, isHovered) => _commonItemBuilder<Picklist>(item, isSelected, isHovered, (p) => p.picklistNumber),
        displayStringForValue: (val) => val.picklistNumber,
        searchStringForValue: (val) => val.picklistNumber,
        onChanged: (val) {},
        height: 32,
      ),
      loading: () => const Skeleton(height: 32, width: double.infinity),
      error: (e, _) => Text('Error: $e'),
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
        : const Color(0xFF1F2937);
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
                      fontWeight: FontWeight.w400,
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
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onToggle,
            icon: const Icon(LucideIcons.x, size: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
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
          qtyToPack: result.overwriteLineItem ? result.appliedQuantity : item.qtyToPack,
        );
        if (result.overwriteLineItem) {
          _rowControllers[index].qtyCtrl.text = result.appliedQuantity.toInt().toString();
        }
        _savedBatchKeys.add(index);
        _savedBatchCounts[index] = result.batchCount;
      });
      _checkForChanges();
    }
  }

  String _buildBatchSummaryText(int index) {
    final item = _items[index];
    final qty = double.tryParse(_rowControllers[index].qtyCtrl.text) ?? item.qtyToPack;
    return '${qty.toInt()} pcs taken from\n${_savedBatchCounts[index] ?? 1} ${(_savedBatchCounts[index] ?? 1) == 1 ? "batch" : "batches"}';
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
  final String? picklistNumber;

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
    this.picklistNumber,
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
    String? picklistNumber,
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
      picklistNumber: picklistNumber ?? this.picklistNumber,
    );
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

class _PackageItemRowController {
  final TextEditingController qtyCtrl;
  _PackageItemRowController({String text = '0'})
      : qtyCtrl = TextEditingController(text: text);
  void dispose() => qtyCtrl.dispose();
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

    if (warehouseId == null || warehouseId.isEmpty) {
      try {
        final warehouses = await ref.read(warehousesProvider.future);
        if (warehouses.isNotEmpty) {
          final defaultW = warehouses.firstWhere(
            (w) => w.name == widget.warehouseName,
            orElse: () => warehouses.first,
          );
          warehouseId = defaultW.id;
        }
      } catch (e) {
        debugPrint('Failed to resolve warehouse: $e');
      }
    }

    if (warehouseId == null || warehouseId.isEmpty) return;

    setState(() => _isLoadingBins = true);
    try {
      final repository = ref.read(inventoryPicklistRepositoryProvider);
      final bins = await repository.getWarehouseBins(
        warehouseId: warehouseId,
        productId: widget.itemId,
      );

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

  const _BinHoverBox({required this.message, required this.child, this.isEnabled = true});

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
      builder: (context) => CompositedTransformFollower(
        link: _layerLink,
        targetAnchor: Alignment.bottomCenter,
        followerAnchor: Alignment.topCenter,
        offset: const Offset(0, 4),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(widget.message, style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontFamily: 'Inter')),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _hideOverlay(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(onEnter: (_) => _showOverlay(), onExit: (_) => _hideOverlay(), child: widget.child),
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
