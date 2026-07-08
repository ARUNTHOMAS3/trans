// ignore_for_file: deprecated_member_use
// lib/modules/items/composite_items/presentation/create.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/modules/items/items/models/unit_model.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository_impl.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/item_quick_edit_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';
import '../models/composite_item.dart';
import '../providers/composite_items_provider.dart';
import 'composite_item_visual_theme.dart';

class CompositeItemsCreatePage extends ConsumerStatefulWidget {
  final String? itemId;
  final bool isClone;
  const CompositeItemsCreatePage({super.key, this.itemId, this.isClone = false});

  @override
  ConsumerState<CompositeItemsCreatePage> createState() => _CompositeItemsCreatePageState();
}

class _CompositeItemsCreatePageState extends ConsumerState<CompositeItemsCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields State
  final TextEditingController _nameController = TextEditingController();
  String _itemType = 'Assembly Item'; // 'Assembly Item' or 'Kit Item'
  final TextEditingController _skuController = TextEditingController();
  String? _selectedUnit;
  String? _selectedCategory;
  bool _returnable = true;
  final TextEditingController _hsnCodeController = TextEditingController();
  String _taxPreference = 'Taxable';
  bool _trackBinLocation = false;
  bool _editingTaxRates = false;

  late final FocusNode _dimLengthFocusNode;
  late final FocusNode _dimWidthFocusNode;
  late final FocusNode _dimHeightFocusNode;
  bool _dimHovered = false;
  late final FocusNode _weightFocusNode;
  bool _weightHovered = false;

  void _onDimFocusChange() {
    setState(() {});
  }

  void _onWeightFocusChange() {
    setState(() {});
  }

  // New Fields: Sales & Purchase Information
  bool _sellable = true;
  final TextEditingController _sellingPriceController = TextEditingController();
  AccountOption? _salesAccount;
  final TextEditingController _salesDescriptionController = TextEditingController();

  bool _purchasable = true;
  final TextEditingController _costPriceController = TextEditingController();
  AccountOption? _purchaseAccount;
  final TextEditingController _purchaseDescriptionController = TextEditingController();

  late TaxOption? _intraStateTaxRate;
  late TaxOption? _interStateTaxRate;

  final TextEditingController _dimLengthController = TextEditingController();
  final TextEditingController _dimWidthController = TextEditingController();
  final TextEditingController _dimHeightController = TextEditingController();
  String _dimUnit = 'cm';

  final TextEditingController _weightController = TextEditingController();
  String _weightUnit = 'kg';

  String? _manufacturer;
  String? _brand;
  final TextEditingController _upcController = TextEditingController();
  final TextEditingController _mpnController = TextEditingController();
  final TextEditingController _eanController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();

  // Advanced Tracking State
  final TextEditingController _reorderLevelController = TextEditingController();
  String? _preferredVendor;
  // Preferred Vendor options load from the real `vendors` table into this
  // page's own state (via the vendor repository) so the dropdown can never get
  // stuck on a shared provider's loading flag.
  List<String> _vendorNames = [];
  bool _loadingVendors = false;
  String _advancedTracking = 'None';
  // Inventory Account loads real Assets-group accounts from the `accounts`
  // table (see _loadAccounts).
  String? _inventoryAccount;
  final List<String> _inventoryAccounts = [];
  String? _inventoryValuation = 'FIFO (First In, First Out)';
  final List<String> _inventoryValuations = ['FIFO (First In, First Out)', 'LIFO (Last In, First Out)', 'Average Cost'];
  final TextEditingController _reorderPointController = TextEditingController();

  String? _selectedAdgf = 'None';
  String? _selectedShedule = 'None';
  String? _selectedReportingTag = 'None';
  bool _pushedToECommerce = false;
  String? _exemptionReason;
  static const List<String> _exemptionReasons = ['GSTMARGINSCHEME', 'LACK OF STOCK'];

  // Selected Images
  final List<PlatformFile> _selectedImages = [];

  // Table Row State
  final List<AssociateRow> _associateRows = [];
  bool _showServicesTable = false;
  final List<AssociateRow> _serviceRows = [];
  int? _hoveredItemRowIndex;
  int? _hoveredServiceRowIndex;

  bool _allowPop = false;

  // Initial Form State variables for checking dirtiness
  String _initName = '';
  String _initItemType = 'Assembly Item';
  String _initSku = '';
  String? _initSelectedUnit;
  String? _initSelectedCategory;
  bool _initReturnable = true;
  String _initHsnCode = '';
  String _initTaxPreference = 'Taxable';
  bool _initPushedToECommerce = false;
  String? _initExemptionReason;
  bool _initSellable = true;
  String _initSellingPrice = '';
  String _initSalesAccount = '';
  String _initSalesDescription = '';
  bool _initPurchasable = true;
  String _initCostPrice = '';
  String _initPurchaseAccount = '';
  String _initPurchaseDescription = '';
  String _initIntraStateTaxRate = '';
  String _initInterStateTaxRate = '';
  String _initDimLength = '';
  String _initDimWidth = '';
  String _initDimHeight = '';
  String _initDimUnit = 'cm';
  String _initWeight = '';
  String _initWeightUnit = 'kg';
  String? _initManufacturer;
  String? _initBrand;
  String _initUpc = '';
  String _initMpn = '';
  String _initEan = '';
  String _initIsbn = '';
  String _initReorderLevel = '';
  String? _initPreferredVendor;
  String _initAdvancedTracking = 'None';
  String? _initInventoryAccount;
  String? _initInventoryValuation = 'FIFO (First In, First Out)';
  String _initReorderPoint = '';
  String? _initSelectedAdgf = 'None';
  String? _initSelectedShedule = 'None';
  String? _initSelectedReportingTag = 'None';
  bool _initTrackBinLocation = false;
  int _initImagesCount = 0;

  List<String> _initAssociateRowsData = [];
  List<String> _initServiceRowsData = [];
  bool _initShowServicesTable = false;

  void _captureInitialState() {
    _initName = _nameController.text;
    _initItemType = _itemType;
    _initSku = _skuController.text;
    _initSelectedUnit = _selectedUnit;
    _initSelectedCategory = _selectedCategory;
    _initReturnable = _returnable;
    _initHsnCode = _hsnCodeController.text;
    _initTaxPreference = _taxPreference;
    _initPushedToECommerce = _pushedToECommerce;
    _initExemptionReason = _exemptionReason;
    _initSellable = _sellable;
    _initSellingPrice = _sellingPriceController.text;
    _initSalesAccount = _salesAccount?.name ?? '';
    _initSalesDescription = _salesDescriptionController.text;
    _initPurchasable = _purchasable;
    _initCostPrice = _costPriceController.text;
    _initPurchaseAccount = _purchaseAccount?.name ?? '';
    _initPurchaseDescription = _purchaseDescriptionController.text;
    _initIntraStateTaxRate = _intraStateTaxRate?.name ?? '';
    _initInterStateTaxRate = _interStateTaxRate?.name ?? '';
    _initDimLength = _dimLengthController.text;
    _initDimWidth = _dimWidthController.text;
    _initDimHeight = _dimHeightController.text;
    _initDimUnit = _dimUnit;
    _initWeight = _weightController.text;
    _initWeightUnit = _weightUnit;
    _initManufacturer = _manufacturer;
    _initBrand = _brand;
    _initUpc = _upcController.text;
    _initMpn = _mpnController.text;
    _initEan = _eanController.text;
    _initIsbn = _isbnController.text;
    _initReorderLevel = _reorderLevelController.text;
    _initPreferredVendor = _preferredVendor;
    _initAdvancedTracking = _advancedTracking;
    _initInventoryAccount = _inventoryAccount;
    _initInventoryValuation = _inventoryValuation;
    _initReorderPoint = _reorderPointController.text;
    _initSelectedAdgf = _selectedAdgf;
    _initSelectedShedule = _selectedShedule;
    _initSelectedReportingTag = _selectedReportingTag;
    _initTrackBinLocation = _trackBinLocation;
    _initImagesCount = _selectedImages.length;

    _initAssociateRowsData = _associateRows.map((row) => 
      '${row.selectedItem ?? ''}_${row.quantityController.text}_${row.sellingPriceController.text}_${row.costPriceController.text}'
    ).toList();
    _initServiceRowsData = _serviceRows.map((row) => 
      '${row.selectedItem ?? ''}_${row.quantityController.text}_${row.sellingPriceController.text}_${row.costPriceController.text}'
    ).toList();
    _initShowServicesTable = _showServicesTable;
  }

  bool _hasUnsavedChanges() {
    if (_nameController.text != _initName) return true;
    if (_itemType != _initItemType) return true;
    if (_skuController.text != _initSku) return true;
    if (_selectedUnit != _initSelectedUnit) return true;
    if (_selectedCategory != _initSelectedCategory) return true;
    if (_returnable != _initReturnable) return true;
    if (_hsnCodeController.text != _initHsnCode) return true;
    if (_taxPreference != _initTaxPreference) return true;
    if (_pushedToECommerce != _initPushedToECommerce) return true;
    if (_exemptionReason != _initExemptionReason) return true;
    if (_sellable != _initSellable) return true;
    if (_sellingPriceController.text != _initSellingPrice) return true;
    if ((_salesAccount?.name ?? '') != _initSalesAccount) return true;
    if (_salesDescriptionController.text != _initSalesDescription) return true;
    if (_purchasable != _initPurchasable) return true;
    if (_costPriceController.text != _initCostPrice) return true;
    if ((_purchaseAccount?.name ?? '') != _initPurchaseAccount) return true;
    if (_purchaseDescriptionController.text != _initPurchaseDescription) return true;
    if ((_intraStateTaxRate?.name ?? '') != _initIntraStateTaxRate) return true;
    if ((_interStateTaxRate?.name ?? '') != _initInterStateTaxRate) return true;
    if (_dimLengthController.text != _initDimLength) return true;
    if (_dimWidthController.text != _initDimWidth) return true;
    if (_dimHeightController.text != _initDimHeight) return true;
    if (_dimUnit != _initDimUnit) return true;
    if (_weightController.text != _initWeight) return true;
    if (_weightUnit != _initWeightUnit) return true;
    if (_manufacturer != _initManufacturer) return true;
    if (_brand != _initBrand) return true;
    if (_upcController.text != _initUpc) return true;
    if (_mpnController.text != _initMpn) return true;
    if (_eanController.text != _initEan) return true;
    if (_isbnController.text != _initIsbn) return true;
    if (_reorderLevelController.text != _initReorderLevel) return true;
    if (_preferredVendor != _initPreferredVendor) return true;
    if (_advancedTracking != _initAdvancedTracking) return true;
    if (_inventoryAccount != _initInventoryAccount) return true;
    if (_inventoryValuation != _initInventoryValuation) return true;
    if (_reorderPointController.text != _initReorderPoint) return true;
    if (_selectedAdgf != _initSelectedAdgf) return true;
    if (_selectedShedule != _initSelectedShedule) return true;
    if (_selectedReportingTag != _initSelectedReportingTag) return true;
    if (_trackBinLocation != _initTrackBinLocation) return true;
    if (_selectedImages.length != _initImagesCount) return true;

    if (_showServicesTable != _initShowServicesTable) return true;

    final currentAssocData = _associateRows.map((row) => 
      '${row.selectedItem ?? ''}_${row.quantityController.text}_${row.sellingPriceController.text}_${row.costPriceController.text}'
    ).toList();
    if (currentAssocData.length != _initAssociateRowsData.length) return true;
    for (int i = 0; i < currentAssocData.length; i++) {
      if (currentAssocData[i] != _initAssociateRowsData[i]) return true;
    }

    final currentServiceData = _serviceRows.map((row) => 
      '${row.selectedItem ?? ''}_${row.quantityController.text}_${row.sellingPriceController.text}_${row.costPriceController.text}'
    ).toList();
    if (currentServiceData.length != _initServiceRowsData.length) return true;
    for (int i = 0; i < currentServiceData.length; i++) {
      if (currentServiceData[i] != _initServiceRowsData[i]) return true;
    }

    return false;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
      context.go('/$orgId/items/composite-items');
    }
  }

  void _handleExit() async {
    if (_hasUnsavedChanges()) {
      final bool stay = await showUnsavedChangesDialog(context);
      if (!stay && mounted) {
        setState(() => _allowPop = true);
        _goBack();
      }
    } else {
      setState(() => _allowPop = true);
      _goBack();
    }
  }

  List<String> _getServiceOptions() {
    final serviceItems = ref.watch(itemsControllerProvider)
        .items
        .where((i) => i.type.toLowerCase() == 'service')
        .map((i) => i.productName)
        .toList();
    if (serviceItems.isEmpty) {
      return [
        'Service A - Delivery',
        'Service B - Installation',
        'Service C - Consulting',
      ];
    }
    return serviceItems;
  }

  // Static Dropdown Options
  // Units load from the real `units` table via GET /products/lookups/units.
  // `_unitIdByName` maps the display label -> unit UUID for saving `unit_id`.
  final List<String> _units = [];
  Map<String, String> _unitIdByName = {};
  bool _loadingUnits = false;

  // Categories load from the real `categories` table (global lookup) via the
  // backend.
  final LookupsApiService _lookupsApi = LookupsApiService();
  final List<String> _categories = [];
  Map<String, String> _categoryIdByName = {};
  bool _loadingCategories = false;
  static const List<String> _taxes = ['Taxable', 'Non-Taxable', 'Out of Scope', 'Non-GST Supply'];
  // Sales (Income group) and Purchase (Expenses group) accounts load from the
  // real `accounts` table via GET /accountant/group/:group. Each list starts
  // with a non-selectable group header, followed by the real accounts.
  final List<AccountOption> _salesAccounts = [];
  final List<AccountOption> _purchaseAccounts = [];
  bool _loadingAccounts = false;
  static final List<TaxOption> _intraTaxRates = [
    const TaxOption(name: 'Tax Group', category: 'Tax Group', isHeader: true),
    const TaxOption(name: 'GST0 [0%]', category: 'Tax Group'),
    const TaxOption(name: 'GST12 [12%]', category: 'Tax Group'),
    const TaxOption(name: 'GST18 [18%]', category: 'Tax Group'),
    const TaxOption(name: 'GST28 [28%]', category: 'Tax Group'),
    const TaxOption(name: 'GST5 [5%]', category: 'Tax Group'),
  ];

  static final List<TaxOption> _interTaxRates = [
    const TaxOption(name: 'Tax', category: 'Tax', isHeader: true),
    const TaxOption(name: 'IGST0 [0%]', category: 'Tax'),
    const TaxOption(name: 'IGST12 [12%]', category: 'Tax'),
    const TaxOption(name: 'IGST18 [18%]', category: 'Tax'),
    const TaxOption(name: 'IGST28 [28%]', category: 'Tax'),
    const TaxOption(name: 'IGST5 [5%]', category: 'Tax'),
  ];
  final List<String> _manufacturers = ['CIPLA', 'MANKIND', 'USV', 'cipla'];
  // Brands load from the real `brands` table (global lookup) via GET /products/lookups/brands.
  final List<String> _brands = [];
  bool _loadingBrands = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _dimLengthFocusNode = FocusNode()..addListener(_onDimFocusChange);
    _dimWidthFocusNode = FocusNode()..addListener(_onDimFocusChange);
    _dimHeightFocusNode = FocusNode()..addListener(_onDimFocusChange);
    _weightFocusNode = FocusNode()..addListener(_onWeightFocusChange);

    _loadAccounts();
    _loadBrands();
    _loadVendors();
    _loadUnits();
    _intraStateTaxRate = _intraTaxRates.firstWhere((t) => t.name == 'GST12 [12%]');
    _interStateTaxRate = _interTaxRates.firstWhere((t) => t.name == 'IGST12 [12%]');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.itemId != null) {
        final state = ref.read(compositeItemsProvider);
        final item = state.records.firstWhere(
          (r) => r.id == widget.itemId,
          orElse: () => state.records.first,
        );
        _nameController.text = item.name;
        _skuController.text = widget.isClone ? '' : item.sku;
        _hsnCodeController.text = item.hsnCode;
        _reorderLevelController.text = item.reorderLevel.toString();
        _reorderPointController.text = item.reorderLevel.toString();
        _sellingPriceController.text = item.sellingPrice.toStringAsFixed(2);
        _costPriceController.text = item.costPrice.toStringAsFixed(2);
        _salesDescriptionController.text = item.description;
        _purchaseDescriptionController.text = item.purchaseDescription;
        _upcController.text = item.upc;
        _mpnController.text = item.mpn;
        _weightController.text = item.weight > 0 ? item.weight.toString() : '';

        if (item.dimensions.isNotEmpty) {
          final parts = item.dimensions.split(' ');
          if (parts.length >= 5) {
            _dimLengthController.text = parts[0];
            _dimWidthController.text = parts[2];
            _dimHeightController.text = parts[4];
            _dimUnit = parts[parts.length - 1];
          }
        }

        setState(() {
          _itemType = item.itemType;
          // Units load async; keep the item's unit and let _loadUnits reconcile.
          _selectedUnit = item.unit.trim().isEmpty ? null : item.unit;
          // Categories load async from the backend; keep the item's category
          // name and let _loadCategories reconcile it once the list arrives.
          _selectedCategory = item.category.trim().isEmpty ? null : item.category;
          _returnable = item.returnable;
          _trackBinLocation = item.trackBinLocation;
          _taxPreference = _taxes.firstWhere((t) => t.toLowerCase() == item.taxPreference.toLowerCase(), orElse: () => item.taxPreference);
          _exemptionReason = item.exemptionReason.isNotEmpty ? item.exemptionReason : null;
          _manufacturer = _manufacturers.firstWhere((m) => m.toLowerCase() == item.manufacturer.toLowerCase(), orElse: () => item.manufacturer);
          _brand = item.brand.trim().isEmpty ? null : item.brand;

          _associateRows.clear();
          _serviceRows.clear();
          _showServicesTable = false;

          final serviceOptions = _getServiceOptions();

          if (item.associateItems.isNotEmpty) {
            for (final assoc in item.associateItems) {
              // Strip " (x1)" suffix if present to match dropdown options
              String cleanAssoc = assoc;
              double quantity = 1.0;
              if (assoc.contains(' (x')) {
                final startIdx = assoc.indexOf(' (x');
                cleanAssoc = assoc.substring(0, startIdx);
                final endIdx = assoc.indexOf(')', startIdx);
                if (endIdx != -1) {
                  final qtyStr = assoc.substring(startIdx + 3, endIdx);
                  quantity = double.tryParse(qtyStr) ?? 1.0;
                }
              }

              // Check if cleanAssoc is a service
              final isService = serviceOptions.contains(cleanAssoc);

              if (isService) {
                _showServicesTable = true;
                
                // Find initial price if matching item is in controller
                final items = ref.read(itemsControllerProvider).items;
                final matched = items.firstWhere(
                  (item) => item.productName == cleanAssoc,
                  orElse: () => Item(type: '', productName: '', itemCode: '', unitId: ''),
                );
                double sp = 0.0;
                double cp = 0.0;
                if (matched.productName.isNotEmpty) {
                  sp = matched.sellingPrice ?? 0.0;
                  cp = matched.costPrice ?? 0.0;
                } else {
                  if (cleanAssoc == 'Service A - Delivery') {
                    sp = 150.00;
                    cp = 100.00;
                  } else if (cleanAssoc == 'Service B - Installation') {
                    sp = 250.00;
                    cp = 180.00;
                  } else if (cleanAssoc == 'Service C - Consulting') {
                    sp = 500.00;
                    cp = 300.00;
                  }
                }

                _serviceRows.add(
                  AssociateRow(
                    selectedItem: cleanAssoc,
                    quantity: quantity.toInt().toString(),
                    sellingPrice: sp.toStringAsFixed(2),
                    costPrice: cp.toStringAsFixed(2),
                  ),
                );
              } else {
                // Find initial price if matching item is in controller
                final items = ref.read(itemsControllerProvider).items;
                final matched = items.firstWhere(
                  (item) => item.productName == cleanAssoc,
                  orElse: () => Item(type: '', productName: '', itemCode: '', unitId: ''),
                );
                double sp = 0.0;
                double cp = 0.0;
                if (matched.productName.isNotEmpty) {
                  sp = matched.sellingPrice ?? 0.0;
                  cp = matched.costPrice ?? 0.0;
                } else {
                  if (cleanAssoc == 'BATCH TARCK ITEM') {
                    sp = 499.00;
                    cp = 350.00;
                  } else if (cleanAssoc == 'BATCH TRACK 2') {
                    sp = 120.00;
                    cp = 80.00;
                  } else if (cleanAssoc == 'BATCH TRACK 3') {
                    sp = 50.00;
                    cp = 30.00;
                  }
                }

                _associateRows.add(
                  AssociateRow(
                    selectedItem: cleanAssoc,
                    quantity: quantity.toInt().toString(),
                    sellingPrice: sp.toStringAsFixed(2),
                    costPrice: cp.toStringAsFixed(2),
                  ),
                );
              }
            }
          }

          if (_associateRows.isEmpty) {
            _associateRows.add(AssociateRow());
          }
        });
      } else {
        setState(() {
          _associateRows.add(AssociateRow());
        });
      }
      _captureInitialState();
    });
  }

  @override
  void dispose() {
    _dimLengthFocusNode.removeListener(_onDimFocusChange);
    _dimWidthFocusNode.removeListener(_onDimFocusChange);
    _dimHeightFocusNode.removeListener(_onDimFocusChange);
    _weightFocusNode.removeListener(_onWeightFocusChange);
    _dimLengthFocusNode.dispose();
    _dimWidthFocusNode.dispose();
    _dimHeightFocusNode.dispose();
    _weightFocusNode.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _hsnCodeController.dispose();
    _reorderLevelController.dispose();
    _reorderPointController.dispose();
    _sellingPriceController.dispose();
    _salesDescriptionController.dispose();
    _costPriceController.dispose();
    _purchaseDescriptionController.dispose();
    _dimLengthController.dispose();
    _dimWidthController.dispose();
    _dimHeightController.dispose();
    _weightController.dispose();
    _upcController.dispose();
    _mpnController.dispose();
    _eanController.dispose();
    _isbnController.dispose();
    for (final row in _associateRows) {
      row.dispose();
    }
    for (final row in _serviceRows) {
      row.dispose();
    }
    super.dispose();
  }

  // Copy Calculations
  void _copySellingPriceFromTotal() {
    double totalSellingPrice = 0.00;
    for (final row in _associateRows) {
      final q = double.tryParse(row.quantityController.text) ?? 1.0;
      final sp = double.tryParse(row.sellingPriceController.text) ?? 0.0;
      totalSellingPrice += sp * q;
    }
    if (_showServicesTable) {
      for (final row in _serviceRows) {
        final q = double.tryParse(row.quantityController.text) ?? 1.0;
        final sp = double.tryParse(row.sellingPriceController.text) ?? 0.0;
        totalSellingPrice += sp * q;
      }
    }
    setState(() {
      _sellingPriceController.text = totalSellingPrice.toStringAsFixed(2);
    });
  }

  void _copyCostPriceFromTotal() {
    double totalCostPrice = 0.00;
    for (final row in _associateRows) {
      final q = double.tryParse(row.quantityController.text) ?? 1.0;
      final cp = double.tryParse(row.costPriceController.text) ?? 0.0;
      totalCostPrice += cp * q;
    }
    if (_showServicesTable) {
      for (final row in _serviceRows) {
        final q = double.tryParse(row.quantityController.text) ?? 1.0;
        final cp = double.tryParse(row.costPriceController.text) ?? 0.0;
        totalCostPrice += cp * q;
      }
    }
    setState(() {
      _costPriceController.text = totalCostPrice.toStringAsFixed(2);
    });
  }

  // Label Builder Helper
  Widget _label(String text, {bool required = false, String? tooltip}) {
    final baseStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: required ? AppTheme.errorRed : AppTheme.textSecondary,
    );

    Widget labelText;
    if (!required) {
      labelText = Text(text, style: baseStyle.copyWith(color: AppTheme.textPrimary));
    } else {
      labelText = RichText(
        text: TextSpan(
          children: [
            TextSpan(text: text, style: baseStyle),
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppTheme.errorRed, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (tooltip != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: labelText),
          const SizedBox(width: 4),
          ZTooltip(
            message: tooltip,
            child: const Icon(
              LucideIcons.helpCircle,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      );
    }
    return labelText;
  }

  // Row layout helper for aligned labels and inputs
  Widget _fieldRow(
    Widget label,
    Widget field, {
    bool fixHeight = true,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double fieldWidth = 450,
  }) {
    Widget content = fixHeight ? SizedBox(height: 36, child: field) : field;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 140,
            child: Align(
              alignment: Alignment.centerLeft,
              child: label,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: fieldWidth),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  // Pick files logic
  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null) {
        setState(() {
          _selectedImages.addAll(result.files);
          if (_selectedImages.length > 15) {
            _selectedImages.removeRange(15, _selectedImages.length);
            ZerpaiToast.error(context, 'You can add up to 15 images maximum.');
          }
        });
      }
    } catch (e) {
      ZerpaiToast.error(context, 'Error browsing images: $e');
    }
  }

  // Save composite item logic
  /// Loads real categories from the `categories` table (global lookup) via the
  /// backend and populates the Category dropdown, keeping a name -> id map.
  /// Loads real Sales (Income) and Purchase (Expenses) accounts from the
  /// `accounts` table via `GET /accountant/group/:group`, each list prefixed
  /// with a non-selectable group header.
  Future<void> _loadAccounts() async {
    setState(() => _loadingAccounts = true);
    try {
      final api = ApiClient();
      final results = await Future.wait([
        api.get('/accountant/group/Income'),
        api.get('/accountant/group/Expenses'),
        api.get('/accountant/group/Assets'),
      ]);
      if (!mounted) return;
      final sales = _mapAccountRows(results[0].data, 'Income');
      final purchase = _mapAccountRows(results[1].data, 'Expenses');
      final inventoryNames =
          _mapAccountRows(results[2].data, 'Assets').map((a) => a.name).toList();
      setState(() {
        _salesAccounts
          ..clear()
          ..add(const AccountOption(name: 'Income', category: 'Income', isHeader: true))
          ..addAll(sales);
        _purchaseAccounts
          ..clear()
          ..add(const AccountOption(name: 'Expenses', category: 'Expenses', isHeader: true))
          ..addAll(purchase);
        _inventoryAccounts
          ..clear()
          ..addAll(inventoryNames);
        _salesAccount ??= _firstRealAccount(_salesAccounts, preferred: 'Sales');
        _purchaseAccount ??=
            _firstRealAccount(_purchaseAccounts, preferred: 'Cost of Goods Sold');
        _inventoryAccount ??= inventoryNames.contains('Inventory Asset')
            ? 'Inventory Asset'
            : (inventoryNames.isEmpty ? null : inventoryNames.first);
        // Keep the dirty-check baseline aligned with the async default selection.
        _initSalesAccount = _salesAccount?.name ?? '';
        _initPurchaseAccount = _purchaseAccount?.name ?? '';
        _initInventoryAccount = _inventoryAccount;
      });
    } catch (_) {
      // Leave lists empty on failure — an explicit empty state.
    } finally {
      if (mounted) setState(() => _loadingAccounts = false);
    }
  }

  List<AccountOption> _mapAccountRows(dynamic data, String group) {
    final List<dynamic> rows = data is List
        ? data
        : (data is Map ? (data['data'] as List? ?? []) : []);
    final opts = <AccountOption>[];
    for (final r in rows.whereType<Map>()) {
      final m = Map<String, dynamic>.from(r);
      final name = (m['user_account_name'] ?? m['system_account_name'] ?? '')
          .toString()
          .trim();
      if (name.isEmpty) continue;
      opts.add(AccountOption(name: name, category: group));
    }
    opts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return opts;
  }

  AccountOption? _firstRealAccount(List<AccountOption> list, {String? preferred}) {
    final real = list.where((a) => !a.isHeader).toList();
    if (real.isEmpty) return null;
    if (preferred != null) {
      for (final a in real) {
        if (a.name.toLowerCase() == preferred.toLowerCase()) return a;
      }
    }
    return real.first;
  }

  /// Loads active vendors from the real `vendors` table via `GET /vendors`
  /// (tenant-scoped) to populate the Preferred Vendor dropdown.
  /// Loads vendors from the real `vendors` table (tenant-scoped) via the vendor
  /// repository into [_vendorNames]. Uses a try/finally so the dropdown never
  /// sticks on "Loading vendors…".
  Future<void> _loadVendors() async {
    setState(() => _loadingVendors = true);
    try {
      final vendors =
          await ref.read(vendorRepositoryProvider).getAllVendors(limit: 500);
      if (!mounted) return;
      final names = vendors
          .map((v) => v.displayName)
          .where((n) => n.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() => _vendorNames = names);
    } catch (_) {
      // Leave empty on failure — an explicit empty state.
    } finally {
      if (mounted) setState(() => _loadingVendors = false);
    }
  }

  /// Loads units from the real `units` table via `GET /products/lookups/units`,
  /// keeping a display-label -> unit UUID map for saving `unit_id`.
  Future<void> _loadUnits() async {
    setState(() => _loadingUnits = true);
    try {
      final List<Unit> units = await _lookupsApi.getUnits();
      if (!mounted) return;
      final display = <String>[];
      final idByName = <String, String>{};
      for (final u in units) {
        if (!u.isActive) continue;
        final sym = (u.unitSymbol ?? '').trim();
        final label = sym.isNotEmpty ? '$sym - ${u.unitName}' : u.unitName;
        if (label.trim().isEmpty || u.id.isEmpty) continue;
        display.add(label);
        idByName[label] = u.id;
      }
      setState(() {
        _units
          ..clear()
          ..addAll(display);
        _unitIdByName = idByName;
        // Reconcile a preselected unit (edit/clone) against the real list.
        final sel = _selectedUnit;
        if (sel != null && !_units.contains(sel)) {
          final match = _units.firstWhere(
            (u) => u.toLowerCase().contains(sel.toLowerCase()),
            orElse: () => '',
          );
          _selectedUnit = match.isEmpty ? null : match;
        }
      });
    } catch (_) {
      // Leave empty on failure — an explicit empty state.
    } finally {
      if (mounted) setState(() => _loadingUnits = false);
    }
  }

  /// Loads brands from the real `brands` table (global lookup) via
  /// `GET /products/lookups/brands` to populate the Brand dropdown.
  Future<void> _loadBrands() async {
    setState(() => _loadingBrands = true);
    try {
      final rows = await _lookupsApi.getBrands();
      if (!mounted) return;
      final names = <String>[];
      for (final row in rows) {
        final name = (row['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        names.add(name);
      }
      setState(() {
        _brands
          ..clear()
          ..addAll(names);
        // Drop a preselected brand (e.g. from edit/clone) not in the real list.
        if (_brand != null && !_brands.contains(_brand)) {
          _brand = null;
        }
      });
    } catch (_) {
      // Leave empty on failure — an explicit empty state.
    } finally {
      if (mounted) setState(() => _loadingBrands = false);
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final rows = await _lookupsApi.getCategories();
      if (!mounted) return;
      final names = <String>[];
      final idByName = <String, String>{};
      for (final row in rows) {
        final name = (row['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        names.add(name);
        final id = (row['id'] ?? '').toString();
        if (id.isNotEmpty) idByName[name] = id;
      }
      setState(() {
        _categories
          ..clear()
          ..addAll(names);
        _categoryIdByName = idByName;
        // Drop a preselected category (e.g. from edit/clone) that isn't a real
        // category so the dropdown doesn't show a stale value.
        if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
      });
    } catch (_) {
      // Leave the list empty on failure — an explicit empty state.
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _saveCompositeItem() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_nameController.text.trim().isEmpty) {
      ZerpaiToast.error(context, 'Please enter Name');
      return;
    }
    if (_selectedUnit == null) {
      ZerpaiToast.error(context, 'Please select Unit');
      return;
    }
    final unitId = _unitIdByName[_selectedUnit];
    if (unitId == null || unitId.isEmpty) {
      ZerpaiToast.error(context, 'Please select a valid Unit');
      return;
    }
    if (_taxPreference == 'Non-Taxable' &&
        (_exemptionReason == null || _exemptionReason!.trim().isEmpty)) {
      ZerpaiToast.error(context, 'Please select or enter Exemption Reason');
      return;
    }

    // Resolve each component row to a real product id for composite_item_parts.
    final products = ref.read(itemsControllerProvider).items;
    String? productIdFor(String? name) {
      if (name == null || name.trim().isEmpty) return null;
      for (final p in products) {
        if (p.productName == name) {
          return (p.id != null && p.id!.isNotEmpty) ? p.id : null;
        }
      }
      return null;
    }

    final parts = <Map<String, dynamic>>[];
    final associateItemsList = <String>[];
    int skipped = 0;
    void consider(AssociateRow row) {
      final name = row.selectedItem;
      if (name == null || name.trim().isEmpty) return;
      final q = double.tryParse(row.quantityController.text) ?? 1.0;
      associateItemsList.add('$name (x${q.toInt()})');
      final pid = productIdFor(name);
      if (pid == null) {
        skipped++;
        return;
      }
      parts.add({
        'component_product_id': pid,
        'quantity': q,
        'selling_price_override':
            double.tryParse(row.sellingPriceController.text.replaceAll(',', '')) ?? 0,
        'cost_price_override':
            double.tryParse(row.costPriceController.text.replaceAll(',', '')) ?? 0,
      });
    }

    for (final row in _associateRows) {
      consider(row);
    }
    if (_showServicesTable) {
      for (final row in _serviceRows) {
        consider(row);
      }
    }

    if (associateItemsList.isEmpty) {
      ZerpaiToast.error(context, 'Please associate at least one item');
      return;
    }

    final selling = double.tryParse(_sellingPriceController.text) ?? 0.0;
    final cost = double.tryParse(_costPriceController.text) ?? 0.0;
    final isEditing = widget.itemId != null && !widget.isClone;

    // Edit mode: no backend update endpoint for composite items yet — keep the
    // existing local update behaviour.
    if (isEditing) {
      final updated =
          _buildLocalRecord(widget.itemId!, selling, cost, associateItemsList);
      ref.read(compositeItemsProvider.notifier).updateRecord(updated);
      ZerpaiToast.success(context, 'Composite Item updated successfully');
      _finishAndClose();
      return;
    }

    if (parts.isEmpty) {
      ZerpaiToast.error(
        context,
        'Select at least one existing product as a component',
      );
      return;
    }

    String? mapTax(String v) {
      switch (v) {
        case 'Taxable':
          return 'taxable';
        case 'Non-Taxable':
          return 'non-taxable';
        case 'Exempt':
          return 'exempt';
        default:
          return null;
      }
    }

    String? mapValuation(String? v) {
      if (v == null) return null;
      if (v.startsWith('FIFO')) return 'FIFO';
      if (v.startsWith('LIFO')) return 'LIFO';
      if (v.startsWith('Average')) return 'Weighted Average';
      return null;
    }

    final payload = <String, dynamic>{
      'product_name': _nameController.text.trim(),
      'type': _itemType == 'Kit Item' ? 'kit' : 'assembly',
      'unit_id': unitId,
      'is_returnable': _returnable,
      'push_to_ecommerce': _pushedToECommerce,
      'selling_price': selling,
      'cost_price': cost,
      'reorder_point': int.tryParse(_reorderPointController.text) ?? 0,
      'dimension_unit': _dimUnit,
      'weight_unit': _weightUnit,
      'parts': parts,
    };
    void putIfNotEmpty(String key, String value) {
      if (value.trim().isNotEmpty) payload[key] = value.trim();
    }

    putIfNotEmpty('sku', _skuController.text.toUpperCase());
    putIfNotEmpty('hsn_code', _hsnCodeController.text);
    putIfNotEmpty('sales_description', _salesDescriptionController.text);
    putIfNotEmpty('purchase_description', _purchaseDescriptionController.text);
    putIfNotEmpty('mpn', _mpnController.text);
    putIfNotEmpty('upc', _upcController.text);
    putIfNotEmpty('ean', _eanController.text);
    putIfNotEmpty('isbn', _isbnController.text);
    final catId = _categoryIdByName[_selectedCategory];
    if (catId != null) payload['category_id'] = catId;
    final tax = mapTax(_taxPreference);
    if (tax != null) payload['tax_preference'] = tax;
    final valMethod = mapValuation(_inventoryValuation);
    if (valMethod != null) payload['inventory_valuation_method'] = valMethod;
    final len = double.tryParse(_dimLengthController.text);
    if (len != null) payload['length'] = len;
    final wid = double.tryParse(_dimWidthController.text);
    if (wid != null) payload['width'] = wid;
    final hei = double.tryParse(_dimHeightController.text);
    if (hei != null) payload['height'] = hei;
    final wt = double.tryParse(_weightController.text);
    if (wt != null) payload['weight'] = wt;

    Map<String, dynamic> result;
    try {
      final resp = await ApiClient().post('/products/composite', data: payload);
      result = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : <String, dynamic>{};
    } catch (e) {
      if (!mounted) return;
      String msg = 'Failed to save composite item. Please try again.';
      try {
        final resp = (e as dynamic).response;
        final status = resp?.statusCode;
        final data = resp?.data;
        String backendMsg = '';
        if (data is Map) {
          final metaErr = (data['meta'] is Map) ? data['meta']['error'] : null;
          if (metaErr is Map && metaErr['message'] != null) {
            backendMsg = metaErr['message'].toString();
          } else if (data['message'] != null) {
            backendMsg = data['message'] is List
                ? (data['message'] as List).join(', ')
                : data['message'].toString();
          }
        }
        if (status == 409) {
          msg = backendMsg.isNotEmpty
              ? backendMsg
              : 'A composite item with this SKU already exists. Use a different SKU.';
        } else if (backendMsg.isNotEmpty) {
          msg = 'Save failed: $backendMsg';
        } else if (status != null) {
          msg = 'Save failed ($status). Please try again.';
        }
      } catch (_) {}
      ZerpaiToast.error(context, msg);
      return;
    }
    if (!mounted) return;

    final savedId =
        (result['id'] ?? 'CMP-${DateTime.now().millisecondsSinceEpoch}')
            .toString();
    final record =
        _buildLocalRecord(savedId, selling, cost, associateItemsList);
    ref.read(compositeItemsProvider.notifier).addRecord(record);
    if (skipped > 0) {
      ZerpaiToast.success(
        context,
        'Saved. $skipped component(s) without a matching product were not linked.',
      );
    } else {
      ZerpaiToast.success(context, 'Composite Item saved successfully');
    }
    _finishAndClose();
  }

  /// Builds the local [CompositeItem] used to update the in-memory list so the
  /// UI reflects the save immediately.
  CompositeItem _buildLocalRecord(
    String id,
    double selling,
    double cost,
    List<String> associateItemsList,
  ) {
    return CompositeItem(
      id: id,
      name: _nameController.text.trim(),
      itemType: _itemType,
      sku: _skuController.text.trim().toUpperCase(),
      unit: _selectedUnit?.split(' ').last ?? 'pcs',
      category: _selectedCategory ?? '',
      returnable: _returnable,
      hsnCode: _hsnCodeController.text.trim(),
      taxPreference: _taxPreference,
      sellingPrice: selling,
      costPrice: cost,
      associateItems: associateItemsList,
      manufacturer: _manufacturer ?? '',
      brand: _brand ?? '',
      reorderLevel: int.tryParse(_reorderPointController.text) ?? 0,
      trackBinLocation: _trackBinLocation,
      description: _salesDescriptionController.text.trim(),
      purchaseDescription: _purchaseDescriptionController.text.trim(),
      upc: _upcController.text.trim(),
      mpn: _mpnController.text.trim(),
      weight: double.tryParse(_weightController.text) ?? 0.0,
      dimensions:
          '${_dimLengthController.text.trim()} x ${_dimWidthController.text.trim()} x ${_dimHeightController.text.trim()} $_dimUnit',
      exemptionReason:
          _taxPreference == 'Non-Taxable' ? (_exemptionReason ?? '') : '',
    );
  }

  void _finishAndClose() {
    setState(() => _allowPop = true);
    if (context.canPop()) {
      context.pop();
    } else {
      final orgId =
          GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
      context.go('/$orgId/items/composite-items');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1024;

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Field
        _fieldRow(
          _label('Name', required: true),
          CustomTextField(
            controller: _nameController,
            hintText: '',
          ),
          fieldWidth: 450,
        ),

        // Item Type Field (Radio Options)
        _fieldRow(
          _label('Item Type', required: true),
          _buildItemTypeRadio(),
          fixHeight: false,
          crossAxisAlignment: CrossAxisAlignment.start,
          fieldWidth: 450,
        ),

        const SizedBox(height: 8),

        // SKU Field
        _fieldRow(
          _label('SKU', tooltip: 'Stock Keeping Unit. Unique identifier for tracking inventory.'),
          CustomTextField(
            controller: _skuController,
            contentCase: ContentCase.uppercase,
            hintText: '',
          ),
        ),

        // Unit Field
        _fieldRow(
          _label('Unit', required: true, tooltip: 'Unit of measurement used for this composite item.'),
          FormDropdown<String>(
            value: _selectedUnit,
            items: _units,
            hint: _loadingUnits ? 'Loading units…' : 'Select or type to add',
            onChanged: (v) => setState(() => _selectedUnit = v),
          ),
        ),

        // Category Field
        _fieldRow(
          _label('Category'),
          FormDropdown<String>(
            value: _selectedCategory,
            items: _categories,
            hint: _loadingCategories ? 'Loading categories…' : 'Select a category',
            allowClear: true,
            showSettings: true,
            settingsLabel: 'Manage Categories',
            settingsIcon: Icons.settings_outlined,
            onSettingsTap: _showManageCategoriesDialog,
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
        ),

        // Returnable Item checkbox
        Padding(
          padding: EdgeInsets.only(left: isWide ? 156.0 : 0.0, top: 4, bottom: 12),
          child: Wrap(
            spacing: 24,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _returnable,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (v) => setState(() => _returnable = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _label('Returnable Item', tooltip: 'Check if this composite item can be returned by clients.'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _pushedToECommerce,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (v) => setState(() => _pushedToECommerce = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _label('Push to E-commerce'),
                ],
              ),
            ],
          ),
        ),

        // HSN Code Field
        _fieldRow(
          _label('HSN Code'),
          CustomTextField(
            controller: _hsnCodeController,
            hintText: '',
          ),
        ),

        // Tax Preference Field
        _fieldRow(
          _label('Tax Preference', required: true),
          FormDropdown<String>(
            value: _taxPreference,
            items: _taxes,
            hint: '',
            onChanged: (v) {
              setState(() {
                _taxPreference = v ?? 'Taxable';
                if (_taxPreference != 'Non-Taxable') {
                  _exemptionReason = null;
                }
              });
            },
          ),
        ),
        if (_taxPreference == 'Non-Taxable') ...[
          _fieldRow(
            _label('Exemption\nReason', required: true, tooltip: 'Select or type to add exemption reason'),
            FormDropdown<String>(
              value: _exemptionReason,
              items: _exemptionReasons,
              hint: 'Select or type to add',
              allowCustomValue: true,
              onChanged: (v) => setState(() => _exemptionReason = v),
            ),
          ),
        ],
      ],
    );

    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageUploadArea(),
      ],
    );

    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          if (_allowPop && mounted) {
            setState(() => _allowPop = false);
          }
          return;
        }

        final bool stay = await showUnsavedChangesDialog(context);
        if (!stay && mounted) {
          setState(() => _allowPop = true);
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CompositeItemVisualTheme(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header Bar
          Container(
            height: 48,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (widget.itemId != null && !widget.isClone) ? 'Edit Composite Item' : 'New Composite Item',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: _handleExit,
                ),
            ],
          ),
        ),

          // Main Form Content
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upper Section (Grey Background Canvas)
                    Container(
                      color: AppTheme.bgLight,
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 13,
                                  child: leftColumn,
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 7,
                                  child: rightColumn,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                leftColumn,
                                const SizedBox(height: 24),
                                rightColumn,
                              ],
                            ),
                    ),

                    // Lower Section (White Background Canvas)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Associate Items Table Header/Title
                          Row(
                            children: [
                              Text(
                                'Associate Items',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.errorRed, // Red Label
                                ),
                              ),
                              const Text(
                                ' *',
                                style: TextStyle(color: AppTheme.errorRed, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Associate Items Table
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 850),
                            child: _buildAssociateItemsTable(),
                          ),

                          if (_showServicesTable) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Text(
                                  'Associate Services',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                                const Text(
                                  ' *',
                                  style: TextStyle(color: AppTheme.errorRed, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 850),
                              child: _buildAssociateServicesTable(),
                            ),
                          ],

                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 16),

                          // Sales & Purchase Information Sections
                          _buildSalesAndPurchaseSection(),

                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 16),

                          // Default Tax Rates
                          _buildDefaultTaxRatesSection(),

                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 16),

                          // Dimensions & Weight & Brand
                          _buildDimensionsBrandSection(),
                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 16),

                          // Additional Information
                          Text(
                            'Additional Information',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _trackBinLocation,
                                  activeColor: AppTheme.primaryBlue,
                                  onChanged: (v) => setState(() => _trackBinLocation = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Track Bin location for this item',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Enable this option if you want to track the bin locations for this item while creating transactions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 8),

                          // Advanced Inventory Tracking Section
                          _buildAdvancedInventoryTracking(),
                          _buildReportingTagsSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Docked Bottom Actions
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                ZButton.primary(
                  label: 'Save',
                  onPressed: _saveCompositeItem,
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Cancel',
                  onPressed: _handleExit,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
  );
}

  // Radio layout block builder
  Widget _buildItemTypeRadio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _itemType = 'Assembly Item'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Radio<String>(
                  value: 'Assembly Item',
                  groupValue: _itemType,
                  activeColor: AppTheme.primaryBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) {
                    if (v != null) setState(() => _itemType = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assembly Item',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A group of items combined together to be tracked and managed as a single item.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => setState(() => _itemType = 'Kit Item'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Radio<String>(
                  value: 'Kit Item',
                  groupValue: _itemType,
                  activeColor: AppTheme.primaryBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) {
                    if (v != null) setState(() => _itemType = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kit Item',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Individual items sold together as one kit.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Image upload card on the right
  Widget _buildImageUploadArea() {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: DottedBorder(
        color: const Color(0xFFD1D5DB),
        strokeWidth: 1.2,
        dashPattern: const [4, 3],
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white, // Keep upload surface white inside the grey canvas
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 40,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            if (_selectedImages.isEmpty) ...[
              const Text(
                'Drag image(s) here or',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: _pickImages,
                child: const Text(
                  'Browse images',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ] else ...[
              Text(
                '${_selectedImages.length} Image(s) Selected',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedImages.map((file) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.remove(file);
                            });
                          },
                          child: const Icon(Icons.close, size: 12, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImages,
                child: const Text(
                  'Add more images',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue, decoration: TextDecoration.underline),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'You can add up to 15 images, each not exceeding 5 MB in size and 7000 X 7000 pixels resolution.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
   ),
  );
 }

  // Associate Items Table Widget
  Widget _buildAssociateItemsTable() {
    return Column(
      children: [
        // Header Row
        Row(
          children: [
            const SizedBox(width: 32), // Gripper spacer outside border
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB)),
                    left: BorderSide(color: Color(0xFFE5E7EB)),
                    right: BorderSide(color: Color(0xFFE5E7EB)),
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Column 1: Item Details
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'Item Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: const Color(0xFFE5E7EB)),
                      // Column 2: Quantity
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: const Color(0xFFE5E7EB)),
                      // Column 3: Selling Price
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Selling Price',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: const Color(0xFFE5E7EB)),
                      // Column 4: Cost Price
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Cost Price',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 80), // Actions spacer outside border
          ],
        ),
        ReorderableListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _associateRows.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final movedRow = _associateRows.removeAt(oldIndex);
              _associateRows.insert(newIndex, movedRow);
              _hoveredItemRowIndex = null;
            });
          },
          itemBuilder: (context, index) {
            final row = _associateRows[index];
            return KeyedSubtree(
              key: ObjectKey(row),
              child: _buildAssociateItemRow(row, index),
            );
          },
        ),
        _buildTableFooter(),
      ],
    );
  }

  /// Keeps one empty trailing row in the Associate Items table so a new blank
  /// row appears automatically once the last row gets an item.
  void _ensureTrailingAssociateRow() {
    if (_associateRows.isEmpty || _associateRows.last.selectedItem != null) {
      _associateRows.add(AssociateRow());
    }
  }

  /// Row "..." menu (Edit Item / View Item Details) anchored under the button —
  /// same popover pattern as the Assemblies create page.
  Future<void> _showAssociateItemMenu(
    BuildContext btnCtx,
    AssociateRow row,
  ) async {
    final button = btnCtx.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(btnCtx).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final value = await showMenu<String>(
      context: btnCtx,
      position: position,
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      items: const [
        PopupMenuItem<String>(
          value: 'edit',
          padding: EdgeInsets.zero,
          height: 40,
          child: _AssociateItemMenuItem(
            icon: LucideIcons.pencil,
            label: 'Edit Item',
          ),
        ),
      ],
    );
    if (!mounted) return;
    if (value == 'edit') {
      _showEditAssociateItemDialog(row);
    }
  }

  /// Opens the shared rich item popover (ItemQuickEditDialog) — the same one the
  /// Assemblies "Edit Item" action uses — for the given Associate Items row.
  void _showEditAssociateItemDialog(AssociateRow row) {
    final itemsState = ref.read(itemsControllerProvider);
    final matched = itemsState.items.firstWhere(
      (item) => item.productName == row.selectedItem,
      orElse: () => Item(
        id: '',
        type: 'goods',
        productName: row.selectedItem ?? '',
        itemCode: '',
        unitId: '',
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ItemQuickEditDialog(
        item: matched,
        onUpdated: (updated) {
          setState(() {
            row.selectedItem = updated.productName;
            row.sellingPriceController.text = updated.sellingPrice?.toStringAsFixed(2) ?? '0.00';
            row.costPriceController.text = updated.costPrice?.toStringAsFixed(2) ?? '0.00';
          });
        },
      ),
    );
  }

  // Row builder for Associate Items
  Widget _buildAssociateItemRow(AssociateRow row, int index) {
    final isHovered = _hoveredItemRowIndex == index;
    // Real products from the `products` table (backend, online-first).
    final itemsState = ref.watch(itemsControllerProvider);
    final productNames = itemsState.items
        .map((i) => i.productName)
        .where((n) => n.isNotEmpty)
        .toList();
    final productsLoading = itemsState.isLoadingList && productNames.isEmpty;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItemRowIndex = index),
      onExit: (_) => setState(() => _hoveredItemRowIndex = null),
      child: Row(
        children: [
          // Drag handle (outside border)
          SizedBox(
            width: 32,
            child: Center(
              child: ReorderableDragStartListener(
                index: index,
                child: const MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Icon(
                    Icons.drag_indicator,
                    size: 18,
                    color: AppTheme.borderColorDark,
                  ),
                ),
              ),
            ),
          ),
          // Table cells inside border
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                minHeight: row.selectedItem == null ? 48 : 64,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(color: Color(0xFFE5E7EB)),
                  right: BorderSide(color: Color(0xFFE5E7EB)),
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Column 1: Item Details
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                size: 18,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: row.selectedItem == null
                                  ? SizedBox(
                                      height: 32,
                                      child: FormDropdown<String>(
                                  value: row.selectedItem,
                                  items: productNames,
                                  hint: productsLoading
                                      ? 'Loading products…'
                                      : (productNames.isEmpty
                                          ? 'No products found'
                                          : 'Click to select an item'),
                                  showSettings: true,
                                  settingsLabel: 'Add New Item',
                                  settingsIcon: Icons.add_circle_outline,
                                  hideBorderDefault: true,
                                  onSettingsTap: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (context) => ItemQuickEditDialog(
                                        item: Item(
                                          id: '',
                                          type: 'goods',
                                          productName: '',
                                          itemCode: '',
                                          unitId: '',
                                        ),
                                        onUpdated: (updated) {
                                          setState(() {
                                            row.selectedItem = updated.productName;
                                            row.sellingPriceController.text = updated.sellingPrice?.toStringAsFixed(2) ?? '0.00';
                                            row.costPriceController.text = updated.costPrice?.toStringAsFixed(2) ?? '0.00';
                                          });
                                        },
                                      ),
                                    );
                                  },
                                  onChanged: (v) {
                                    setState(() {
                                      row.selectedItem = v;
                                      final items = ref.read(itemsControllerProvider).items;
                                      final matched = items.firstWhere(
                                        (item) => item.productName == v,
                                        orElse: () => Item(type: '', productName: '', itemCode: '', unitId: ''),
                                      );
                                      if (matched.productName.isNotEmpty) {
                                        row.sellingPriceController.text = matched.sellingPrice?.toStringAsFixed(2) ?? '0.00';
                                        row.costPriceController.text = matched.costPrice?.toStringAsFixed(2) ?? '0.00';
                                      } else {
                                        if (v == 'BATCH TARCK ITEM') {
                                          row.sellingPriceController.text = '499.00';
                                          row.costPriceController.text = '350.00';
                                        } else if (v == 'BATCH TRACK 2') {
                                          row.sellingPriceController.text = '120.00';
                                          row.costPriceController.text = '80.00';
                                        } else {
                                          row.sellingPriceController.text = '50.00';
                                          row.costPriceController.text = '30.00';
                                        }
                                      }
                                      if (v != null) _ensureTrailingAssociateRow();
                                    });
                                  },
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            row.selectedItem!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Builder(
                                          builder: (btnCtx) => InkWell(
                                            onTap: () =>
                                                _showAssociateItemMenu(btnCtx, row),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFFD1D5DB)),
                                                color: Colors.white,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  LucideIcons.moreHorizontal,
                                                  size: 12,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              row.selectedItem = null;
                                              row.sellingPriceController.text =
                                                  '0.00';
                                              row.costPriceController.text =
                                                  '0.00';
                                            });
                                          },
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFFE5E7EB)),
                    // Column 2: Quantity
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Center(
                          child: row.selectedItem == null
                              ? SizedBox(
                                  height: 32,
                                  child: CustomTextField(
                              controller: row.quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              hideBorderDefault: true,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                              onChanged: (v) => setState(() {}),
                              ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                      child: CustomTextField(
                                        controller: row.quantityController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        hideBorderDefault: true,
                                        textStyle: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                        onChanged: (v) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${row.sellingPriceController.text} per unit',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFFE5E7EB)),
                    // Column 3: Selling Price
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: const Color(0xFFF9FAFB),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Center(
                          child: SizedBox(
                            height: 32,
                            child: CustomTextField(
                              controller: row.sellingPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              hideBorderDefault: true,
                              readOnly: true,
                              fillColor: Colors.transparent,
                              textStyle: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                              onChanged: (v) => setState(() {}),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFFE5E7EB)),
                    // Column 4: Cost Price
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: const Color(0xFFF9FAFB),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Center(
                          child: SizedBox(
                            height: 32,
                            child: CustomTextField(
                              controller: row.costPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              hideBorderDefault: true,
                              readOnly: true,
                              fillColor: Colors.transparent,
                              textStyle: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                              onChanged: (v) => setState(() {}),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Row Actions (outside border)
          Container(
            width: 80,
            padding: const EdgeInsets.only(left: 12),
            child: Visibility(
              visible: isHovered,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 3-dot (Insert Row) Button
                  PopupMenuButton<void>(
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    tooltip: '',
                    offset: const Offset(0, 26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 130),
                    itemBuilder: (context) => [
                      PopupMenuItem<void>(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            setState(() {
                              _hoveredItemRowIndex = null;
                              _hoveredServiceRowIndex = null;
                              _associateRows.insert(index + 1, AssociateRow());
                            });
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: const Center(
                            child: Text(
                              'Insert New Row',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 1.2),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.more_horiz,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close/Delete Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _hoveredItemRowIndex = null;
                        _hoveredServiceRowIndex = null;
                        if (_associateRows.length > 1) {
                          final removed = _associateRows.removeAt(index);
                          removed.dispose();
                        } else {
                          ZerpaiToast.error(context, 'At least one row is required');
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.shade200, width: 1.2),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.red,
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
    );
  }

  // Footer Totals Row
  Widget _buildTableFooter() {
    double totalSellingPrice = 0.00;
    double totalCostPrice = 0.00;

    for (final row in _associateRows) {
      final q = double.tryParse(row.quantityController.text) ?? 1.0;
      final sp = double.tryParse(row.sellingPriceController.text) ?? 0.0;
      final cp = double.tryParse(row.costPriceController.text) ?? 0.0;
      totalSellingPrice += sp * q;
      totalCostPrice += cp * q;
    }

    return Row(
      children: [
        const SizedBox(width: 32), // spacer for gripper outside border
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Add New Row & Add Services buttons (no border, white bg)
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _associateRows.add(AssociateRow());
                          });
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plusCircle, size: 14, color: AppTheme.primaryBlue),
                            SizedBox(width: 4),
                            Text(
                              'Add New Row',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '|',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showServicesTable = true;
                            _serviceRows.add(AssociateRow());
                          });
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plusCircle, size: 14, color: AppTheme.primaryBlue),
                            SizedBox(width: 4),
                            Text(
                              'Add Services',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right side: Totals Box (with borders)
              Expanded(
                flex: 6, // 2 (Quantity) + 2 (Selling Price) + 2 (Cost Price)
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      left: BorderSide(color: Color(0xFFE5E7EB)),
                      right: BorderSide(color: Color(0xFFE5E7EB)),
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Column 2: Total Label
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total (₹) :',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                        // Column 3: Total Selling Price
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: const Color(0xFFF9FAFB),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                totalSellingPrice.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                        // Column 4: Total Cost Price
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: const Color(0xFFF9FAFB),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                totalCostPrice.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 80), // spacer for actions outside border
      ],
    );
  }

  Widget _buildAssociateServicesTable() {
    return Column(
      children: [
        // Header Row
        Row(
          children: [
            const SizedBox(width: 32), // Gripper spacer outside border
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB)),
                    left: BorderSide(color: Color(0xFFE5E7EB)),
                    right: BorderSide(color: Color(0xFFE5E7EB)),
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Column 1: Service Details
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'Service Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: const Color(0xFFE5E7EB)),
                      // Column 2: Quantity
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: const Color(0xFFE5E7EB)),
                      // Column 3: Selling Price
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Selling Price',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: const Color(0xFFE5E7EB)),
                      // Column 4: Cost Price
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Cost Price',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 80), // Actions spacer outside border
          ],
        ),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _serviceRows.length,
          itemBuilder: (context, index) {
            final row = _serviceRows[index];
            return _buildAssociateServiceRow(row, index);
          },
        ),
        _buildServicesTableFooter(),
      ],
    );
  }

  Widget _buildAssociateServiceRow(AssociateRow row, int index) {
    final isHovered = _hoveredServiceRowIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredServiceRowIndex = index),
      onExit: (_) => setState(() => _hoveredServiceRowIndex = null),
      child: Row(
        children: [
          // Drag handle (outside border)
          const SizedBox(
            width: 32,
            child: Center(
              child: Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
            ),
          ),
          // Table cells inside border
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(color: Color(0xFFE5E7EB)),
                  right: BorderSide(color: Color(0xFFE5E7EB)),
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Column 1: Service Details
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.image_outlined,
                                size: 18,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: FormDropdown<String>(
                                  value: row.selectedItem,
                                  items: _getServiceOptions(),
                                  hint: 'Click to select an item',
                                  showSettings: true,
                                  settingsLabel: 'Add New Item',
                                  settingsIcon: Icons.add_circle_outline,
                                  hideBorderDefault: true,
                                  onSettingsTap: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (context) => ItemQuickEditDialog(
                                        item: Item(
                                          id: '',
                                          type: 'service',
                                          productName: '',
                                          itemCode: '',
                                          unitId: '',
                                        ),
                                        onUpdated: (updated) {
                                          setState(() {
                                            row.selectedItem = updated.productName;
                                            row.sellingPriceController.text = updated.sellingPrice?.toStringAsFixed(2) ?? '0.00';
                                            row.costPriceController.text = updated.costPrice?.toStringAsFixed(2) ?? '0.00';
                                          });
                                        },
                                      ),
                                    );
                                  },
                                  onChanged: (v) {
                                    setState(() {
                                      row.selectedItem = v;
                                      final items = ref.read(itemsControllerProvider).items;
                                      final matched = items.firstWhere(
                                        (item) => item.productName == v,
                                        orElse: () => Item(type: '', productName: '', itemCode: '', unitId: ''),
                                      );
                                      if (matched.productName.isNotEmpty) {
                                        row.sellingPriceController.text = matched.sellingPrice?.toStringAsFixed(2) ?? '0.00';
                                        row.costPriceController.text = matched.costPrice?.toStringAsFixed(2) ?? '0.00';
                                      } else {
                                        if (v == 'Service A - Delivery') {
                                          row.sellingPriceController.text = '150.00';
                                          row.costPriceController.text = '100.00';
                                        } else if (v == 'Service B - Installation') {
                                          row.sellingPriceController.text = '250.00';
                                          row.costPriceController.text = '180.00';
                                        } else if (v == 'Service C - Consulting') {
                                          row.sellingPriceController.text = '500.00';
                                          row.costPriceController.text = '300.00';
                                        } else {
                                          row.sellingPriceController.text = '0.00';
                                          row.costPriceController.text = '0.00';
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFFE5E7EB)),
                    // Column 2: Quantity
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Center(
                          child: SizedBox(
                            height: 32,
                            child: CustomTextField(
                              controller: row.quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              hideBorderDefault: true,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                              onChanged: (v) => setState(() {}),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFFE5E7EB)),
                    // Column 3: Selling Price
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: const Color(0xFFF9FAFB),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Center(
                          child: SizedBox(
                            height: 32,
                            child: CustomTextField(
                              controller: row.sellingPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              hideBorderDefault: true,
                              readOnly: true,
                              fillColor: Colors.transparent,
                              textStyle: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                              onChanged: (v) => setState(() {}),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: const Color(0xFFE5E7EB)),
                    // Column 4: Cost Price
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: const Color(0xFFF9FAFB),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Center(
                          child: SizedBox(
                            height: 32,
                            child: CustomTextField(
                              controller: row.costPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              hideBorderDefault: true,
                              readOnly: true,
                              fillColor: Colors.transparent,
                              textStyle: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                              onChanged: (v) => setState(() {}),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Row Actions (outside border)
          Container(
            width: 80,
            padding: const EdgeInsets.only(left: 12),
            child: Visibility(
              visible: isHovered,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 3-dot (Insert Row) Button
                  PopupMenuButton<void>(
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    tooltip: '',
                    offset: const Offset(0, 26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 130),
                    itemBuilder: (context) => [
                      PopupMenuItem<void>(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            setState(() {
                              _hoveredItemRowIndex = null;
                              _hoveredServiceRowIndex = null;
                              _serviceRows.insert(index + 1, AssociateRow());
                            });
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: const Center(
                            child: Text(
                              'Insert New Row',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 1.2),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.more_horiz,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close/Delete Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _hoveredItemRowIndex = null;
                        _hoveredServiceRowIndex = null;
                        _serviceRows.removeAt(index);
                        if (_serviceRows.isEmpty) {
                          _showServicesTable = false;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.shade200, width: 1.2),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.red,
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
    );
  }

  Widget _buildServicesTableFooter() {
    double totalSellingPrice = 0.00;
    double totalCostPrice = 0.00;

    for (final row in _serviceRows) {
      final q = double.tryParse(row.quantityController.text) ?? 1.0;
      final sp = double.tryParse(row.sellingPriceController.text) ?? 0.0;
      final cp = double.tryParse(row.costPriceController.text) ?? 0.0;
      totalSellingPrice += sp * q;
      totalCostPrice += cp * q;
    }

    return Row(
      children: [
        const SizedBox(width: 32), // spacer for gripper outside border
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Add New Row button (no border, white bg)
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _serviceRows.add(AssociateRow());
                          });
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plusCircle, size: 14, color: AppTheme.primaryBlue),
                            SizedBox(width: 4),
                            Text(
                              'Add New Row',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right side: Totals Box (with borders)
              Expanded(
                flex: 6, // 2 (Quantity) + 2 (Selling Price) + 2 (Cost Price)
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      left: BorderSide(color: Color(0xFFE5E7EB)),
                      right: BorderSide(color: Color(0xFFE5E7EB)),
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Column 2: Total Label
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total (₹) :',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                        // Column 3: Total Selling Price
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: const Color(0xFFF9FAFB),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                totalSellingPrice.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                        // Column 4: Total Cost Price
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: const Color(0xFFF9FAFB),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                totalCostPrice.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 80), // spacer for actions outside border
      ],
    );
  }

  // New section: Sales and Purchase Information columns
  Widget _buildSalesAndPurchaseSection() {
    final isWide = MediaQuery.of(context).size.width >= 1024;
    final isSellableEffective = _itemType == 'Kit Item' ? true : _sellable;

    final salesColumn = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 410),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sales Information',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_itemType != 'Kit Item') ...[
            Padding(
              padding: const EdgeInsets.only(left: 156),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _sellable,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (v) => setState(() => _sellable = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Sellable', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          _fieldRow(
            _label('Selling Price (INR)', required: true),
            isSellableEffective
                ? CustomTextField(
                    controller: _sellingPriceController,
                    hintText: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: true,
                    suffixWidget: InkWell(
                      onTap: _copySellingPriceFromTotal,
                      child: const Text(
                        'Copy from total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.block,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
            fixHeight: false,
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('Account', required: true),
            FormDropdown<AccountOption>(
              value: _salesAccount,
              items: _salesAccounts,
              hint: _loadingAccounts ? 'Loading accounts…' : '',
              enabled: isSellableEffective,
              fillColor: isSellableEffective ? Colors.white : const Color(0xFFF3F4F6),
              textStyle: TextStyle(
                fontSize: 13,
                color: isSellableEffective ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
              displayStringForValue: (val) => val.name,
              isItemEnabled: (item) => !item.isHeader,
              itemBuilder: (item, isSelected, isHovered) {
                if (item.isHeader) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 20, right: 10, top: 6, bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 14,
                          color: isHovered ? Colors.white : AppTheme.primaryBlue,
                        ),
                    ],
                  ),
                );
              },
              onChanged: (v) => setState(() => _salesAccount = v ?? _salesAccount),
            ),
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('Description'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _salesDescriptionController,
                  hintText: '',
                  maxLines: 3,
                  height: 70,
                  enabled: isSellableEffective,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Add item details to description',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.helpCircle,
                      size: 13,
                      color: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ],
                ),
            fixHeight: false,
            crossAxisAlignment: CrossAxisAlignment.start,
            fieldWidth: 250,
          ),
        ],
      ),
    );

    final purchaseColumn = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 410),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Purchase Information',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 156),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _purchasable,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (v) => setState(() => _purchasable = v ?? true),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Purchasable', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _fieldRow(
            _label('Cost Price (INR)', required: true),
            _purchasable
                ? CustomTextField(
                    controller: _costPriceController,
                    hintText: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: true,
                    suffixWidget: InkWell(
                      onTap: _copyCostPriceFromTotal,
                      child: const Text(
                        'Copy from total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.block,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
            fixHeight: false,
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('Account', required: true),
            FormDropdown<AccountOption>(
              value: _purchaseAccount,
              items: _purchaseAccounts,
              hint: _loadingAccounts ? 'Loading accounts…' : '',
              enabled: _purchasable,
              fillColor: _purchasable ? Colors.white : const Color(0xFFF3F4F6),
              textStyle: TextStyle(
                fontSize: 13,
                color: _purchasable ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
              displayStringForValue: (val) => val.name,
              isItemEnabled: (item) => !item.isHeader,
              itemBuilder: (item, isSelected, isHovered) {
                if (item.isHeader) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 20, right: 10, top: 6, bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 14,
                          color: isHovered ? Colors.white : AppTheme.primaryBlue,
                        ),
                    ],
                  ),
                );
              },
              onChanged: (v) => setState(() => _purchaseAccount = v ?? _purchaseAccount),
            ),
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('Description'),
            CustomTextField(
              controller: _purchaseDescriptionController,
              hintText: '',
              maxLines: 3,
              height: 70,
              enabled: _purchasable,
            ),
            fixHeight: false,
            crossAxisAlignment: CrossAxisAlignment.start,
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('Preferred Vendor'),
            FormDropdown<String>(
              value: _preferredVendor,
              items: _vendorNames,
              hint: _loadingVendors ? 'Loading vendors…' : 'Select a vendor',
              allowClear: true,
              enabled: _purchasable,
              fillColor: _purchasable ? Colors.white : const Color(0xFFF3F4F6),
              textStyle: TextStyle(
                fontSize: 13,
                color: _purchasable ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
              onChanged: (v) => setState(() => _preferredVendor = v),
            ),
            fieldWidth: 250,
          ),
        ],
      ),
    );

    if (_itemType == 'Kit Item') {
      return salesColumn;
    }

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          salesColumn,
          const SizedBox(width: 48),
          purchaseColumn,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          salesColumn,
          const SizedBox(height: 24),
          purchaseColumn,
        ],
      );
    }
  }

  // New section: Default Tax Rates dropdowns
  Widget _buildDefaultTaxRatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Default Tax Rates',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 8),
            ZTooltip(
              message: 'Edit',
              child: InkWell(
                onTap: () {
                  setState(() {
                    _editingTaxRates = !_editingTaxRates;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: _editingTaxRates ? AppTheme.primaryBlue : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_editingTaxRates) ...[
          _fieldRow(
            _label('Intra State Tax Rate'),
            FormDropdown<TaxOption>(
              value: _intraStateTaxRate,
              items: _intraTaxRates,
              hint: '',
              allowClear: true,
              displayStringForValue: (val) => val.name,
              isItemEnabled: (item) => !item.isHeader,
              itemBuilder: (item, isSelected, isHovered) {
                if (item.isHeader) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 20, right: 10, top: 6, bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 14,
                          color: isHovered ? Colors.white : AppTheme.primaryBlue,
                        ),
                    ],
                  ),
                );
              },
              onChanged: (v) => setState(() => _intraStateTaxRate = v),
            ),
          ),
          _fieldRow(
            _label('Inter State Tax Rate'),
            FormDropdown<TaxOption>(
              value: _interStateTaxRate,
              items: _interTaxRates,
              hint: '',
              allowClear: true,
              displayStringForValue: (val) => val.name,
              isItemEnabled: (item) => !item.isHeader,
              itemBuilder: (item, isSelected, isHovered) {
                if (item.isHeader) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 20, right: 10, top: 6, bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 14,
                          color: isHovered ? Colors.white : AppTheme.primaryBlue,
                        ),
                    ],
                  ),
                );
              },
              onChanged: (v) => setState(() => _interStateTaxRate = v),
            ),
          ),
        ] else ...[
          _fieldRow(
            Text(
              'Intra State Tax Rate',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _formatTaxRateText(_intraStateTaxRate),
            ),
          ),
          _fieldRow(
            Text(
              'Inter State Tax Rate',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dashed,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _formatTaxRateText(_interStateTaxRate),
            ),
          ),
        ],
      ],
    );
  }

  Widget _formatTaxRateText(TaxOption? value) {
    if (value == null) return const Text('None', style: TextStyle(fontSize: 13));
    final parts = value.name.split(' [');
    if (parts.length == 2) {
      final rateName = parts[0];
      final ratePercent = parts[1].replaceAll(']', '');
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: rateName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            TextSpan(
              text: ' ($ratePercent)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      value.name,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
    );
  }

  // New section: Dimensions & Weight & Brand
  Widget _buildDimensionsBrandSection() {
    final isWide = MediaQuery.of(context).size.width >= 1024;

    final leftColumn = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 410),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldRow(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Dimensions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ZTooltip(
                      message: 'Enter length, width, and height with units.',
                      child: const Icon(
                        LucideIcons.helpCircle,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '(Length X Width X Height)',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            _buildDimensionsField(),
            fixHeight: false,
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('Manufacturer'),
            FormDropdown<String>(
              value: _manufacturer,
              items: _manufacturers,
              hint: 'Select or Add Manufacturer',
              allowClear: true,
              showSettings: true,
              settingsLabel: 'Manage Manufacturers',
              settingsIcon: Icons.settings_outlined,
              onSettingsTap: _showManageManufacturersDialog,
              onChanged: (v) => setState(() => _manufacturer = v),
            ),
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('UPC', tooltip: 'Universal Product Code (12-digit barcode).'),
            CustomTextField(
              controller: _upcController,
              keyboardType: TextInputType.number,
              hintText: '',
            ),
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('EAN', tooltip: 'European Article Number (13-digit barcode).'),
            CustomTextField(
              controller: _eanController,
              keyboardType: TextInputType.number,
              hintText: '',
            ),
            fieldWidth: 250,
          ),
        ],
      ),
    );

    final rightColumn = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 410),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldRow(
            _label('Weight'),
            _buildWeightField(),
            fixHeight: false,
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('Brand'),
            FormDropdown<String>(
              value: _brand,
              items: _brands,
              hint: _loadingBrands ? 'Loading brands…' : 'Select or Add Brand',
              allowClear: true,
              showSettings: true,
              settingsLabel: 'Manage Brands',
              settingsIcon: Icons.settings_outlined,
              onSettingsTap: _showManageBrandsDialog,
              onChanged: (v) => setState(() => _brand = v),
            ),
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('MPN', tooltip: 'Manufacturer Part Number.'),
            CustomTextField(
              controller: _mpnController,
              hintText: '',
            ),
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('ISBN', tooltip: 'International Standard Book Number.'),
            CustomTextField(
              controller: _isbnController,
              keyboardType: TextInputType.number,
              hintText: '',
            ),
            fieldWidth: 250,
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftColumn,
          const SizedBox(width: 48),
          rightColumn,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftColumn,
          const SizedBox(height: 24),
          rightColumn,
        ],
      );
    }
  }

  // Dimensions row helper
  Widget _buildDimensionsField() {
    final hasFocus = _dimLengthFocusNode.hasFocus ||
        _dimWidthFocusNode.hasFocus ||
        _dimHeightFocusNode.hasFocus;
    final borderColor = hasFocus
        ? AppTheme.primaryBlueDark
        : (_dimHovered ? AppTheme.infoBlue : AppTheme.borderColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _dimHovered = true),
      onExit: (_) => setState(() => _dimHovered = false),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: hasFocus ? 1.5 : 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _dimLengthController,
                  focusNode: _dimLengthFocusNode,
                  hintText: '',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  border: Border.all(color: Colors.transparent),
                  fillColor: Colors.transparent,
                  hideBorderDefault: true,
                  padding: EdgeInsets.zero,
                  textAlign: TextAlign.center,
                ),
              ),
              const Text(
                'x',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: CustomTextField(
                  controller: _dimWidthController,
                  focusNode: _dimWidthFocusNode,
                  hintText: '',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  border: Border.all(color: Colors.transparent),
                  fillColor: Colors.transparent,
                  hideBorderDefault: true,
                  padding: EdgeInsets.zero,
                  textAlign: TextAlign.center,
                ),
              ),
              const Text(
                'x',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: CustomTextField(
                  controller: _dimHeightController,
                  focusNode: _dimHeightFocusNode,
                  hintText: '',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  border: Border.all(color: Colors.transparent),
                  fillColor: Colors.transparent,
                  hideBorderDefault: true,
                  padding: EdgeInsets.zero,
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                width: 1,
                height: double.infinity,
                color: AppTheme.borderColor,
              ),
              Container(
                width: 70,
                height: double.infinity,
                color: const Color(0xFFF3F4F6),
                child: FormDropdown<String>(
                  value: _dimUnit,
                  items: const ['cm', 'inch'],
                  hint: '',
                  hideBorderDefault: true,
                  fillColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onChanged: (v) => setState(() => _dimUnit = v ?? 'cm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Weight row helper
  Widget _buildWeightField() {
    final hasFocus = _weightFocusNode.hasFocus;
    final borderColor = hasFocus
        ? AppTheme.primaryBlueDark
        : (_weightHovered ? AppTheme.infoBlue : AppTheme.borderColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _weightHovered = true),
      onExit: (_) => setState(() => _weightHovered = false),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: hasFocus ? 1.5 : 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _weightController,
                  focusNode: _weightFocusNode,
                  hintText: '',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  border: Border.all(color: Colors.transparent),
                  fillColor: Colors.transparent,
                  hideBorderDefault: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              Container(
                width: 1,
                height: double.infinity,
                color: AppTheme.borderColor,
              ),
              Container(
                width: 70,
                height: double.infinity,
                color: const Color(0xFFF3F4F6),
                child: FormDropdown<String>(
                  value: _weightUnit,
                  items: const ['kg', 'g', 'lb', 'oz'],
                  hint: '',
                  hideBorderDefault: true,
                  fillColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onChanged: (v) => setState(() => _weightUnit = v ?? 'kg'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Advanced Inventory Settings builder
  Widget _buildAdvancedInventoryTracking() {
    final isWide = MediaQuery.of(context).size.width >= 1024;

    final inventoryAccountField = _fieldRow(
      _label('Inventory Account', required: true),
      FormDropdown<String>(
        value: _inventoryAccount,
        items: _inventoryAccounts,
        hint: _loadingAccounts ? 'Loading accounts…' : 'Select an account',
        onChanged: (val) => setState(() => _inventoryAccount = val ?? _inventoryAccount),
      ),
      fieldWidth: 250,
    );

    final inventoryValuationField = _fieldRow(
      _label('Inventory Valuation Method', required: true),
      FormDropdown<String>(
        value: _inventoryValuation,
        items: _inventoryValuations,
        hint: '',
        onChanged: (val) => setState(() => _inventoryValuation = val ?? 'FIFO (First In, First Out)'),
      ),
      fieldWidth: 250,
    );

    final reorderPointField = _fieldRow(
      _label('Reorder Point'),
      CustomTextField(
        controller: _reorderPointController,
        hintText: '',
        keyboardType: TextInputType.number,
      ),
      fieldWidth: 250,
    );

    Widget fieldsLayout;
    if (isWide) {
      fieldsLayout = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 410),
                child: inventoryAccountField,
              ),
              const SizedBox(width: 48),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 410),
                child: inventoryValuationField,
              ),
            ],
          ),
          Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 410),
                child: reorderPointField,
              ),
              const SizedBox(width: 48),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 410),
                child: const SizedBox(),
              ),
            ],
          ),
        ],
      );
    } else {
      fieldsLayout = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 410),
            child: inventoryAccountField,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 410),
            child: inventoryValuationField,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 410),
            child: reorderPointField,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Inventory Tracking',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<String>(
                  value: 'None',
                  groupValue: _advancedTracking,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setState(() => _advancedTracking = val ?? 'None'),
                ),
                const Text('None', style: TextStyle(fontSize: 13)),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'Track Serial Number',
                  groupValue: _advancedTracking,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setState(() => _advancedTracking = val ?? 'Track Serial Number'),
                ),
                const Text('Track Serial Number', style: TextStyle(fontSize: 13)),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'Track Batches',
                  groupValue: _advancedTracking,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setState(() => _advancedTracking = val ?? 'Track Batches'),
                ),
                const Text('Track Batches', style: TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        fieldsLayout,
      ],
    );
  }

  void _showManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _ManageCategoriesDialog(
          currentCategories: _categories,
          onCategoriesChanged: (updatedList) {
            setState(() {
              _categories.clear();
              _categories.addAll(updatedList);
            });
          },
          onCategorySelected: (selectedCat) {
            setState(() {
              _selectedCategory = selectedCat;
            });
          },
        );
      },
    );
  }

  void _showManageBrandsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _ManageBrandsDialog(
          currentBrands: _brands,
          onBrandsChanged: (updatedList) {
            setState(() {
              _brands.clear();
              _brands.addAll(updatedList);
            });
          },
          onBrandSelected: (selectedBrand) {
            setState(() {
              _brand = selectedBrand;
            });
          },
        );
      },
    );
  }

  void _showManageManufacturersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _ManageManufacturersDialog(
          currentManufacturers: _manufacturers,
          onManufacturersChanged: (updatedList) {
            setState(() {
              _manufacturers.clear();
              _manufacturers.addAll(updatedList);
            });
          },
          onManufacturerSelected: (selectedMfg) {
            setState(() {
              _manufacturer = selectedMfg;
            });
          },
        );
      },
    );
  }

  Widget _buildReportingTagsSection() {
    final isWide = MediaQuery.of(context).size.width >= 1024;

    final leftColumn = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 410),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldRow(
            _label('ADGF'),
            FormDropdown<String>(
              value: _selectedAdgf,
              items: const ['None', 'Option A', 'Option B'],
              hint: '',
              allowClear: true,
              onChanged: (v) => setState(() => _selectedAdgf = v),
            ),
            fieldWidth: 250,
          ),
          _fieldRow(
            _label('demo adavced\nreporting tag'),
            FormDropdown<String>(
              value: _selectedReportingTag,
              items: const ['None', 'Tag 1', 'Tag 2'],
              hint: '',
              allowClear: true,
              onChanged: (v) => setState(() => _selectedReportingTag = v),
            ),
            fixHeight: false,
            fieldWidth: 250,
          ),
        ],
      ),
    );

    final rightColumn = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 410),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldRow(
            _label('shedule'),
            FormDropdown<String>(
              value: _selectedShedule,
              items: const ['None', 'Schedule 1', 'Schedule 2'],
              hint: '',
              allowClear: true,
              onChanged: (v) => setState(() => _selectedShedule = v),
            ),
            fieldWidth: 250,
          ),
        ],
      ),
    );

    Widget columnsLayout;
    if (isWide) {
      columnsLayout = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftColumn,
          const SizedBox(width: 48),
          rightColumn,
        ],
      );
    } else {
      columnsLayout = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftColumn,
          const SizedBox(height: 24),
          rightColumn,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(color: Color(0xFFE5E7EB)),
        const SizedBox(height: 16),
        columnsLayout,
      ],
    );
  }

}

/// Hover-highlighted row for the Associate Items "..." menu — blue background
/// with white text/icon on hover, matching the app-wide dropdown menu style.
class _AssociateItemMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  const _AssociateItemMenuItem({required this.icon, required this.label});

  @override
  State<_AssociateItemMenuItem> createState() => _AssociateItemMenuItemState();
}

class _AssociateItemMenuItemState extends State<_AssociateItemMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 40,
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: _hovered ? const Color(0xFF2563EB) : Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 15,
              color: _hovered ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                color: _hovered ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssociateRow {
  String? selectedItem;
  final TextEditingController quantityController;
  final TextEditingController sellingPriceController;
  final TextEditingController costPriceController;

  AssociateRow({
    this.selectedItem,
    String quantity = '1',
    String sellingPrice = '0.00',
    String costPrice = '0.00',
  })  : quantityController = TextEditingController(text: quantity),
        sellingPriceController = TextEditingController(text: sellingPrice),
        costPriceController = TextEditingController(text: costPrice);

  void dispose() {
    quantityController.dispose();
    sellingPriceController.dispose();
    costPriceController.dispose();
  }
}

class _ManageCategoriesDialog extends StatefulWidget {
  final List<String> currentCategories;
  final ValueChanged<List<String>> onCategoriesChanged;
  final ValueChanged<String> onCategorySelected;

  const _ManageCategoriesDialog({
    required this.currentCategories,
    required this.onCategoriesChanged,
    required this.onCategorySelected,
  });

  @override
  State<_ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<_ManageCategoriesDialog> {
  late List<_CategoryNode> _nodes;
  bool _showForm = false;
  _CategoryNode? _editingNode;
  final TextEditingController _nameCtrl = TextEditingController();
  String? _selectedParentName;

  @override
  void initState() {
    super.initState();
    _parseCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _parseCategories() {
    _nodes = [];
    _CategoryNode? lastParent;
    for (final cat in widget.currentCategories) {
      if (cat.startsWith('• ')) {
        final name = cat.substring(2);
        if (lastParent != null) {
          lastParent.children.add(_CategoryNode(name: name, parent: lastParent));
        } else {
          _nodes.add(_CategoryNode(name: name));
        }
      } else {
        lastParent = _CategoryNode(name: cat);
        _nodes.add(lastParent);
      }
    }
  }

  void _saveChanges() {
    final List<String> flattened = [];
    for (final parent in _nodes) {
      flattened.add(parent.name);
      for (final child in parent.children) {
        flattened.add('• ${child.name}');
      }
    }
    widget.onCategoriesChanged(flattened);
  }

  void _addNewCategory(String name, String? parentName) {
    setState(() {
      if (parentName == null || parentName.isEmpty) {
        _nodes.add(_CategoryNode(name: name));
      } else {
        final parent = _nodes.firstWhere((n) => n.name == parentName, orElse: () => _nodes.first);
        parent.children.add(_CategoryNode(name: name, parent: parent));
      }
      _saveChanges();
    });
  }



  void _deleteCategory(_CategoryNode node) {
    setState(() {
      if (node.parent == null) {
        _nodes.remove(node);
      } else {
        node.parent!.children.remove(node);
      }
      _saveChanges();
    });
  }

  void _editCategoryNode(_CategoryNode node, String newName, String? newParentName) {
    setState(() {
      node.name = newName;

      final oldParent = node.parent;
      if (oldParent?.name != newParentName) {
        if (oldParent == null) {
          _nodes.remove(node);
        } else {
          oldParent.children.remove(node);
        }

        if (newParentName == null || newParentName.isEmpty) {
          node.parent = null;
          _nodes.add(node);
        } else {
          final targetParent = _nodes.firstWhere((n) => n.name == newParentName, orElse: () => _nodes.first);
          node.parent = targetParent;
          targetParent.children.add(node);
        }
      }
      _saveChanges();
    });
  }

  Widget _buildInlineForm() {
    final parentOptions = _nodes
        .where((n) => n != _editingNode)
        .map((n) => n.name)
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        border: Border.all(color: const Color(0xFFFEF08A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 140,
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Category Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.errorRed,
                        ),
                      ),
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: AppTheme.errorRed,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                height: 36,
                child: CustomTextField(
                  controller: _nameCtrl,
                  hintText: '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 140,
                child: Text(
                  'Parent Category',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 300,
                height: 36,
                child: FormDropdown<String>(
                  value: _selectedParentName,
                  items: parentOptions,
                  hint: '',
                  allowClear: true,
                  onChanged: (v) => setState(() => _selectedParentName = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ZerpaiToast.error(context, 'Category Name is required');
                    return;
                  }
                  
                  setState(() {
                    if (_editingNode == null) {
                      _addNewCategory(name, _selectedParentName);
                    } else {
                      _editCategoryNode(_editingNode!, name, _selectedParentName);
                    }
                    _showForm = false;
                    _editingNode = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showForm = false;
                    _editingNode = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Dialog(
        alignment: Alignment.topCenter,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        insetPadding: const EdgeInsets.only(left: 40, right: 40, top: 0, bottom: 24),
        child: Container(
          width: 700,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 48,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.errorRed, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),

              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showForm) ...[
                      _buildInlineForm(),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.borderColor),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CATEGORIES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showForm = true;
                              _editingNode = null;
                              _nameCtrl.clear();
                              _selectedParentName = null;
                            });
                          },
                          icon: const Icon(Icons.add_circle, size: 16, color: AppTheme.primaryBlue),
                          label: const Text(
                            'Add New Category',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    Column(
                      children: _buildTreeRows(),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  List<Widget> _buildTreeRows() {
    final List<Widget> list = [];
    for (final parent in _nodes) {
      list.add(
        _CategoryRow(
          name: parent.name,
          isParent: true,
          isExpanded: parent.isExpanded,
          onToggleExpand: () {
            setState(() {
              parent.isExpanded = !parent.isExpanded;
            });
          },
          onApply: () {
            widget.onCategorySelected(parent.name);
            Navigator.of(context).pop();
          },
          onEdit: () {
            setState(() {
              _showForm = true;
              _editingNode = parent;
              _nameCtrl.text = parent.name;
              _selectedParentName = parent.parent?.name;
            });
          },
          onDelete: () => _deleteCategory(parent),
        ),
      );

      if (parent.isExpanded) {
        for (int i = 0; i < parent.children.length; i++) {
          final child = parent.children[i];
          final isLast = i == parent.children.length - 1;
          list.add(
            _CategoryRow(
              name: child.name,
              isParent: false,
              onApply: () {
                widget.onCategorySelected('• ${child.name}');
                Navigator.of(context).pop();
              },
              onEdit: () {
                setState(() {
                  _showForm = true;
                  _editingNode = child;
                  _nameCtrl.text = child.name;
                  _selectedParentName = child.parent?.name;
                });
              },
              onDelete: () => _deleteCategory(child),
              prefixLines: [
                _buildTreeLine(isLast),
              ],
            ),
          );
        }
      }
    }
    return list;
  }

  Widget _buildTreeLine(bool isLast) {
    return SizedBox(
      width: 46,
      height: 38,
      child: Stack(
        children: [
          Positioned(
            left: 30,
            top: 0,
            bottom: isLast ? 19 : 0,
            child: Container(width: 1.2, color: const Color(0xFFD1D5DB)),
          ),
          Positioned(
            left: 30,
            right: 0,
            top: 19,
            child: Container(height: 1.2, color: const Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }
}

class _CategoryNode {
  String name;
  List<_CategoryNode> children;
  _CategoryNode? parent;
  bool isExpanded = true;

  _CategoryNode({
    required this.name,
    List<_CategoryNode>? children,
    this.parent,
  }) : children = children ?? [];
}

class _CategoryRow extends StatefulWidget {
  final String name;
  final bool isParent;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<Widget>? prefixLines;

  const _CategoryRow({
    required this.name,
    required this.isParent,
    this.isExpanded = true,
    this.onToggleExpand,
    required this.onApply,
    required this.onEdit,
    required this.onDelete,
    this.prefixLines,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF3F4F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (widget.prefixLines != null) ...widget.prefixLines!,

            if (widget.isParent) ...[
              InkWell(
                onTap: widget.onToggleExpand,
                child: Icon(
                  widget.isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.folder_open,
                size: 16,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 8),
            ],

            Text(
              widget.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.isParent ? FontWeight.w600 : FontWeight.normal,
                color: AppTheme.textPrimary,
              ),
            ),

            const Spacer(),

            if (_isHovered) ...[
              InkWell(
                onTap: widget.onApply,
                child: const Text(
                  'Apply this Category',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('|', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
              const SizedBox(width: 8),
              InkWell(
                onTap: widget.onEdit,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    const Text('Edit', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('|', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
              const SizedBox(width: 8),
              InkWell(
                onTap: widget.onDelete,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 13, color: Colors.red[600]),
                    const SizedBox(width: 4),
                    const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AccountOption {
  final String name;
  final String category;
  final bool isHeader;

  const AccountOption({
    required this.name,
    required this.category,
    this.isHeader = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountOption &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          category == other.category &&
          isHeader == other.isHeader;

  @override
  int get hashCode => name.hashCode ^ category.hashCode ^ isHeader.hashCode;

  @override
  String toString() => name;
}

class TaxOption {
  final String name;
  final String category;
  final bool isHeader;

  const TaxOption({
    required this.name,
    required this.category,
    this.isHeader = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaxOption &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          category == other.category &&
          isHeader == other.isHeader;

  @override
  int get hashCode => name.hashCode ^ category.hashCode ^ isHeader.hashCode;

  @override
  String toString() => name;
}

class _ManageBrandsDialog extends StatefulWidget {
  final List<String> currentBrands;
  final ValueChanged<List<String>> onBrandsChanged;
  final ValueChanged<String> onBrandSelected;

  const _ManageBrandsDialog({
    required this.currentBrands,
    required this.onBrandsChanged,
    required this.onBrandSelected,
  });

  @override
  State<_ManageBrandsDialog> createState() => _ManageBrandsDialogState();
}

class _ManageBrandsDialogState extends State<_ManageBrandsDialog> {
  late List<String> _brands;
  String? _editingBrand;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final LookupsApiService _lookups = LookupsApiService();
  String _search = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _brands = List.from(widget.currentBrands);
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    widget.onBrandsChanged(_brands);
  }

  List<String> get _filteredBrands {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _brands;
    return _brands.where((b) => b.toLowerCase().contains(q)).toList();
  }

  Widget _buildInlineForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Brand Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.errorRed,
                  ),
                ),
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: CustomTextField(
              controller: _nameCtrl,
              hintText: '',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        final name = _nameCtrl.text.trim();
                        if (name.isEmpty) {
                          ZerpaiToast.error(context, 'Brand Name is required');
                          return;
                        }
                        if (_editingBrand == null) {
                          // New brand — persist to the `brands` table, then select it.
                          final exists = _brands
                              .any((b) => b.toLowerCase() == name.toLowerCase());
                          if (!exists) {
                            setState(() => _saving = true);
                            try {
                              await _lookups.createBrand(name);
                            } catch (_) {
                              if (mounted) {
                                setState(() => _saving = false);
                                ZerpaiToast.error(context, 'Failed to add brand');
                              }
                              return;
                            }
                            if (!mounted) return;
                            setState(() {
                              _brands.add(name);
                              _saving = false;
                            });
                            _saveChanges();
                          }
                          if (!mounted) return;
                          widget.onBrandSelected(name);
                          Navigator.of(context).pop();
                        } else {
                          setState(() {
                            final idx = _brands.indexOf(_editingBrand!);
                            if (idx != -1) _brands[idx] = name;
                            _editingBrand = null;
                            _nameCtrl.clear();
                          });
                          _saveChanges();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  _editingBrand == null ? 'Save and Select' : 'Save',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _editingBrand = null;
                    _nameCtrl.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Dialog(
        alignment: Alignment.topCenter,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        insetPadding: const EdgeInsets.only(left: 40, right: 40, top: 0, bottom: 24),
        child: Container(
          width: 700,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage Brands',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.errorRed, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _buildInlineForm(),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(
                    top: BorderSide(color: AppTheme.borderColor),
                    bottom: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Text(
                  'BRANDS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: SizedBox(
                  height: 36,
                  child: CustomTextField(
                    controller: _searchCtrl,
                    hintText: 'Search brands',
                  ),
                ),
              ),
              SizedBox(
                height: 300,
                child: Builder(
                  builder: (context) {
                    final filtered = _filteredBrands;
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No brands found',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ),
                      );
                    }
                    // Lazy list — only builds visible rows (the brands table can
                    // hold thousands of entries).
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.borderColor),
                      itemBuilder: (context, i) {
                        final name = filtered[i];
                        return _BrandRow(
                          name: name,
                          onApply: () {
                            widget.onBrandSelected(name);
                            Navigator.of(context).pop();
                          },
                          onEdit: () {
                            setState(() {
                              _editingBrand = name;
                              _nameCtrl.text = name;
                            });
                          },
                          onDelete: () {
                            setState(() {
                              _brands.remove(name);
                              _saveChanges();
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatefulWidget {
  final String name;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BrandRow({
    required this.name,
    required this.onApply,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_BrandRow> createState() => _BrandRowState();
}

class _BrandRowState extends State<_BrandRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onApply,
        hoverColor: const Color(0xFFF3F4F6),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_isHovered) ...[
                InkWell(
                  onTap: widget.onEdit,
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 15, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: widget.onDelete,
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline, size: 15, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageManufacturersDialog extends StatefulWidget {
  final List<String> currentManufacturers;
  final ValueChanged<List<String>> onManufacturersChanged;
  final ValueChanged<String> onManufacturerSelected;

  const _ManageManufacturersDialog({
    required this.currentManufacturers,
    required this.onManufacturersChanged,
    required this.onManufacturerSelected,
  });

  @override
  State<_ManageManufacturersDialog> createState() => _ManageManufacturersDialogState();
}

class _ManageManufacturersDialogState extends State<_ManageManufacturersDialog> {
  late List<String> _manufacturers;
  String? _editingManufacturer;
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manufacturers = List.from(widget.currentManufacturers);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    widget.onManufacturersChanged(_manufacturers);
  }

  Widget _buildInlineForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Manufacturer Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.errorRed,
                  ),
                ),
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: CustomTextField(
              controller: _nameCtrl,
              hintText: '',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ZerpaiToast.error(context, 'Manufacturer Name is required');
                    return;
                  }

                  setState(() {
                    if (_editingManufacturer == null) {
                      if (!_manufacturers.contains(name)) {
                        _manufacturers.add(name);
                      }
                      _saveChanges();
                      widget.onManufacturerSelected(name);
                      Navigator.of(context).pop();
                    } else {
                      final idx = _manufacturers.indexOf(_editingManufacturer!);
                      if (idx != -1) {
                        _manufacturers[idx] = name;
                      }
                      _saveChanges();
                      _editingManufacturer = null;
                      _nameCtrl.clear();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  _editingManufacturer == null ? 'Save and Select' : 'Save',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _editingManufacturer = null;
                    _nameCtrl.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Dialog(
        alignment: Alignment.topCenter,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        insetPadding: const EdgeInsets.only(left: 40, right: 40, top: 0, bottom: 24),
        child: Container(
          width: 700,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage Manufacturers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.errorRed, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _buildInlineForm(),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(
                    top: BorderSide(color: AppTheme.borderColor),
                    bottom: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Text(
                  'MANUFACTURERS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (int i = 0; i < _manufacturers.length; i++) ...[
                        _ManufacturerRow(
                          name: _manufacturers[i],
                          onApply: () {
                            widget.onManufacturerSelected(_manufacturers[i]);
                            Navigator.of(context).pop();
                          },
                          onEdit: () {
                            setState(() {
                              _editingManufacturer = _manufacturers[i];
                              _nameCtrl.text = _manufacturers[i];
                            });
                          },
                          onDelete: () {
                            setState(() {
                              _manufacturers.removeAt(i);
                              _saveChanges();
                            });
                          },
                        ),
                        const Divider(height: 1, color: AppTheme.borderColor),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManufacturerRow extends StatefulWidget {
  final String name;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ManufacturerRow({
    required this.name,
    required this.onApply,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ManufacturerRow> createState() => _ManufacturerRowState();
}

class _ManufacturerRowState extends State<_ManufacturerRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onApply,
        hoverColor: const Color(0xFFF3F4F6),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_isHovered) ...[
                InkWell(
                  onTap: widget.onEdit,
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 15, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: widget.onDelete,
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline, size: 15, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
