// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/models/purchases_purchase_returns_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/providers/purchases_purchase_returns_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/presentation/purchases_purchase_returns_overview.dart';
import 'package:zerpai_erp/modules/sales/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/advanced_customer_search_modal.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/providers/lookup_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/address_dialog.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';

//          Line item model

class _PRLineItem {
  Item? sourceItem;
  String? selectedTax;
  double? selectedTaxRate;
  String? selectedTaxId;
  String? selectedAccount;
  double returnedQty = 0.0;
  List<Map<String, dynamic>> batches = [];

  final TextEditingController orderedQtyController = TextEditingController();
  final TextEditingController returnQtyController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  _PRLineItem();

  void dispose() {
    orderedQtyController.dispose();
    returnQtyController.dispose();
    rateController.dispose();
    descriptionController.dispose();
  }

  PurchaseReturnItem toModel() {
    return PurchaseReturnItem(
      itemId: sourceItem?.id,
      itemName: sourceItem?.productName ?? '',
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      orderedQty: double.tryParse(orderedQtyController.text.trim()) ?? 0,
      returnQty: double.tryParse(returnQtyController.text.trim()) ?? 0,
      rate: double.tryParse(rateController.text.trim()) ?? 0,
      amount: _amount,
      taxRateName: selectedTax,
    );
  }

  double get _amount {
    final qty = double.tryParse(returnQtyController.text.trim()) ?? 0;
    final rate = double.tryParse(rateController.text.trim()) ?? 0;
    return qty * rate;
  }
}

//          Main page widget

class PurchaseReturnsCreatePage extends ConsumerStatefulWidget {
  final String? purchaseReturnId;

  const PurchaseReturnsCreatePage({super.key, this.purchaseReturnId});

  bool get isEdit => purchaseReturnId != null;

  @override
  ConsumerState<PurchaseReturnsCreatePage> createState() =>
      _PurchaseReturnsCreatePageState();
}

class _PurchaseReturnsCreatePageState
    extends ConsumerState<PurchaseReturnsCreatePage> {
  static const double _fieldHeight = 32.0;
  static const double _tableFieldHeight = 32.0;
  static const double _labelWidth = 150.0;
  static const double _gapWidth = 16.0;
  static const double _rowMaxWidth = 1400.0;
  static const double _vendorFieldWidth = 450.0;

  //          Form state
  Vendor? _selectedVendorObj;
  String? get _selectedVendorName => _selectedVendorObj?.displayName;

  String? _selectedBill;
  String? _selectedSourceOfSupply;
  String? _selectedDestinationOfSupply;
  String? _selectedTransactionSeries = 'Default Transaction Series';

  bool _isReverseCharge = false;
  List<PlatformFile> _attachedFiles = [];

  late final TextEditingController _returnNumberController;
  late final TextEditingController _returnDateController;
  final _returnDateKey = GlobalKey();
  DateTime _returnDate = DateTime.now();

  late final TextEditingController _purchaseOrderController;
  late final TextEditingController _purchaseReceiveController;
  late final TextEditingController _reasonController;
  late final TextEditingController _notesController;
  late final TextEditingController _adjustmentController;
  late final TextEditingController _prPrefixController;
  late final TextEditingController _prNextNumberController;

  bool _prAutoGenerate = true;
  String _warehouseLocation = '';
  String _discountType = 'At Transaction Level';
  PriceList? _selectedPriceList;

  final List<_PRLineItem> _items = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _returnNumberController = TextEditingController(text: 'PR-00001');
    _returnDateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(_returnDate),
    );
    _purchaseOrderController = TextEditingController();
    _purchaseReceiveController = TextEditingController();
    _reasonController = TextEditingController();
    _notesController = TextEditingController();
    _adjustmentController = TextEditingController();
    _prPrefixController = TextEditingController(text: 'PR-');
    _prNextNumberController = TextEditingController(text: '00001');
    _addItem();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorProvider.notifier).loadVendors();
      ref.read(itemsControllerProvider.notifier).loadItems();
      if (widget.isEdit) {
        _loadForEdit();
      }
    });
    if (!widget.isEdit) {
      _fetchNextNumber();
    }
  }

  @override
  void dispose() {
    _returnNumberController.dispose();
    _returnDateController.dispose();
    _purchaseOrderController.dispose();
    _purchaseReceiveController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _adjustmentController.dispose();
    _prPrefixController.dispose();
    _prNextNumberController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  //          Item management

  void _addItem() => setState(() => _items.add(_PRLineItem()));

  void _insertItem(int index) =>
      setState(() => _items.insert(index + 1, _PRLineItem()));

  void _duplicateItem(int index) {
    setState(() {
      final src = _items[index];
      final dup = _PRLineItem()
        ..sourceItem = src.sourceItem
        ..selectedTax = src.selectedTax
        ..selectedAccount = src.selectedAccount;
      dup.orderedQtyController.text = src.orderedQtyController.text;
      dup.returnQtyController.text = src.returnQtyController.text;
      dup.rateController.text = src.rateController.text;
      dup.descriptionController.text = src.descriptionController.text;
      _items.insert(index + 1, dup);
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _showBulkItemsDialog() {
    final products = ref.read(itemsControllerProvider).items;
    showDialog(
      context: context,
      builder: (ctx) => BulkItemsDialog(
        products: products,
        onItemsSelected: (selectedWithQty) {
          setState(() {
            _items.removeWhere((item) => item.sourceItem == null);
            for (final entry in selectedWithQty.entries) {
              final line = _PRLineItem();
              line.sourceItem = entry.key;
              line.rateController.text =
                  entry.key.costPrice?.toStringAsFixed(2) ?? '0.00';
              line.returnQtyController.text = entry.value.toString();
              _items.add(line);
            }
            if (_items.isEmpty) _addItem();
          });
        },
      ),
    );
  }

  //          Number preference dialog

  void _showPreferencesDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Purchase Return Preferences',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => Align(
        alignment: Alignment.topCenter,
        child: Material(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          color: Colors.white,
          child: _PRPreferencesDialog(
            prefix: _prPrefixController.text,
            nextNumber: _prNextNumberController.text,
            autoGenerate: _prAutoGenerate,
            onSave: (prefix, nextNumber, autoGenerate) {
              setState(() {
                _prAutoGenerate = autoGenerate;
                _prPrefixController.text = prefix;
                _prNextNumberController.text = nextNumber;
                if (autoGenerate) {
                  _returnNumberController.text = '$prefix$nextNumber';
                }
              });
            },
          ),
        ),
      ),
    );
  }

  //          Date picker

  Future<void> _pickReturnDate() async {
    final date = await ZerpaiDatePicker.show(
      context,
      initialDate: _returnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      targetKey: _returnDateKey,
    );
    if (date == null) return;
    setState(() {
      _returnDate = date;
      _returnDateController.text = DateFormat('dd-MM-yyyy').format(date);
    });
  }

  //          Data loading

  Future<void> _fetchNextNumber() async {
    try {
      final number = await ref
          .read(purchaseReturnsRepositoryProvider)
          .getNextReturnNumber();
      if (mounted && number.isNotEmpty) _returnNumberController.text = number;
    } catch (e) {
      AppLogger.warning(
        'Could not fetch next return number: $e',
        module: 'purchases',
      );
    }
  }

  Future<void> _loadForEdit() async {
    try {
      PurchaseReturn? ret;
      try {
        ret = await ref
            .read(purchaseReturnsRepositoryProvider)
            .getPurchaseReturn(widget.purchaseReturnId!);
      } catch (_) {}

      if (ret != null) {
        _selectedVendorObj = Vendor(
          id: ret.vendorId ?? '',
          displayName: ret.vendorName ?? '',
          companyName: ret.vendorName ?? '',
          gstin: '29AABCA9876E1Z2',
        );
        _selectedBill = 'B2B/25-26/00098';
        _selectedSourceOfSupply = '[KA] - Karnataka';
        _selectedDestinationOfSupply = '[KL] - Kerala';
        _returnNumberController.text = ret.returnNumber;
        _purchaseOrderController.text = ret.purchaseOrderNumber ?? '';
        _purchaseReceiveController.text = ret.purchaseReceiveNumber ?? '';
        _notesController.text = ret.notes ?? '';
        _returnDate = ret.returnDate ?? DateTime.now();
        _returnDateController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(_returnDate);

        for (final item in _items) item.dispose();
        _items.clear();

        for (final item in ret.items) {
          final line = _PRLineItem();
          line.sourceItem = Item(
            id: item.itemId ?? '',
            type: 'goods',
            productName: item.itemName,
            itemCode: 'ITEM-001',
            unitId: 'unit-1',
            costPrice: item.rate,
          );
          line.orderedQtyController.text = item.orderedQty > 0
              ? item.orderedQty.toStringAsFixed(0)
              : '';
          line.returnQtyController.text = item.returnQty > 0
              ? item.returnQty.toStringAsFixed(0)
              : '';
          line.rateController.text = item.rate > 0
              ? item.rate.toStringAsFixed(2)
              : '';
          line.descriptionController.text = item.description ?? '';
          line.selectedTax = item.taxRateName;
          _items.add(line);
        }
        if (_items.isEmpty) _addItem();
        setState(() {});
        return;
      }

      final detail = ref.read(
        purchaseReturnDetailProvider(widget.purchaseReturnId!),
      );
      if (detail != null) {
        final vendors = ref.read(vendorProvider).vendors;
        final matchedVendor = vendors.firstWhere(
          (v) => v.displayName == detail.vendorName || v.id == detail.id,
          orElse: () => Vendor(
            id: '',
            displayName: detail.vendorName,
            companyName: detail.vendorName,
            gstin: '',
          ),
        );
        _selectedVendorObj = matchedVendor;
        _returnNumberController.text = detail.returnNumber;
        _purchaseOrderController.text = detail.purchaseOrderNumber ?? '';
        _purchaseReceiveController.text = detail.purchaseReceiveNumber ?? '';
        _selectedBill = detail.billNumber;
        _selectedSourceOfSupply = detail.sourceOfSupply;
        _selectedDestinationOfSupply = detail.destinationOfSupply;
        _returnDate = detail.date;
        _returnDateController.text = DateFormat('dd-MM-yyyy').format(_returnDate);

        for (final item in _items) item.dispose();
        _items.clear();

        for (final item in detail.items) {
          final line = _PRLineItem();
          line.sourceItem = Item(
            id: 'item-mock-${item.name}',
            type: 'goods',
            productName: item.name,
            itemCode: 'ITEM-001',
            unitId: 'unit-1',
            costPrice: item.rate,
            sellingPrice: item.rate,
            sku: 'SKU-001',
            upc: '',
            ean: '',
            isbn: '',
            mpn: '',
          );
          line.returnQtyController.text = item.returnQty.toStringAsFixed(0);
          line.rateController.text = item.rate.toStringAsFixed(2);
          line.descriptionController.text = item.description;
          line.selectedTax = item.taxRate;
          _items.add(line);
        }
      }
      if (_items.isEmpty) _addItem();
      setState(() {});
    } catch (e) {
      AppLogger.error(
        'Failed to load purchase return for edit: $e',
        module: 'purchases',
      );
    }
  }

  //          Calculations

  double _parseMoney(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0;

  String _formatMoney(double value) => value.toStringAsFixed(2);

  double _lineSubtotal(_PRLineItem item) {
    final qty = _parseMoney(item.returnQtyController.text);
    final rate = _parseMoney(item.rateController.text);
    return (qty * rate).clamp(0.0, double.infinity);
  }

  double get _subTotal => _items
      .where((i) => i.sourceItem != null || i.returnQtyController.text.isNotEmpty)
      .fold(0.0, (s, i) => s + _lineSubtotal(i));

  bool get _isIntraState {
    final s = (_selectedSourceOfSupply ?? '').toLowerCase();
    final d = (_selectedDestinationOfSupply ?? '').toLowerCase();
    if (s.isEmpty || d.isEmpty) return true;
    final sCode = s.split(']').first.replaceAll('[', '').trim();
    final dCode = d.split(']').first.replaceAll('[', '').trim();
    if (sCode.isNotEmpty && dCode.isNotEmpty && sCode == dCode) return true;
    return s == d || (s.contains('kerala') && d.contains('kerala'));
  }

  double _parseTaxRate(String? taxStr) {
    if (taxStr == null) return 0.0;
    final match = RegExp(r'\[(\d+(\.\d+)?)%\]').firstMatch(taxStr) ??
        RegExp(r'(\d+(\.\d+)?)%').firstMatch(taxStr);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, double> get _taxBreakdown {
    final s = (_selectedSourceOfSupply ?? '').trim();
    final d = (_selectedDestinationOfSupply ?? '').trim();
    if (s.isEmpty || d.isEmpty) return {};
    final Map<String, double> map = {};
    for (final item in _items) {
      if (item.sourceItem == null && item.returnQtyController.text.isEmpty) continue;
      final qty = _parseMoney(item.returnQtyController.text);
      final rate = _parseMoney(item.rateController.text);
      final lineSubtotal = qty * rate;
      final taxRate = _parseTaxRate(item.selectedTax);
      if (taxRate <= 0) continue;
      final lineTax = lineSubtotal * (taxRate / 100.0);

      if (_isIntraState) {
        final halfRate = taxRate / 2;
        final halfAmt = lineTax / 2;
        final rateStr = halfRate % 1 == 0 ? halfRate.toInt().toString() : halfRate.toStringAsFixed(1);
        final cgstKey = 'CGST$rateStr [$rateStr%]';
        final sgstKey = 'SGST$rateStr [$rateStr%]';
        map[cgstKey] = (map[cgstKey] ?? 0.0) + halfAmt;
        map[sgstKey] = (map[sgstKey] ?? 0.0) + halfAmt;
      } else {
        final rateStr = taxRate % 1 == 0 ? taxRate.toInt().toString() : taxRate.toStringAsFixed(1);
        final igstKey = 'IGST$rateStr [$rateStr%]';
        map[igstKey] = (map[igstKey] ?? 0.0) + lineTax;
      }
    }
    return map;
  }

  double get _totalTax => _taxBreakdown.values.fold(0.0, (a, b) => a + b);

  double get _totalQuantity => _items
      .where((i) => i.sourceItem != null || i.returnQtyController.text.isNotEmpty)
      .fold(0.0, (s, i) => s + _parseMoney(i.returnQtyController.text));

  double get _adjustmentAmount => _parseMoney(_adjustmentController.text);
  double get _grandTotal => _subTotal + _totalTax + _adjustmentAmount;

  Map<String, double> _billedQtyMap = {};

  Future<void> _fetchBilledQuantitiesForVendor(String vendorId) async {
    if (vendorId.isEmpty) {
      if (mounted) setState(() => _billedQtyMap = {});
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('bill_items')
          .select('product_id, quantity, bills!inner(vendor_id, is_delete, status)')
          .eq('bills.vendor_id', vendorId)
          .eq('bills.is_delete', false)
          .neq('bills.status', 'void');

      final Map<String, double> qtyMap = {};
      for (final row in (response as List<dynamic>)) {
        final pid = row['product_id'] as String?;
        final q = (row['quantity'] as num?)?.toDouble() ?? 0.0;
        if (pid != null && pid.isNotEmpty) {
          qtyMap[pid] = (qtyMap[pid] ?? 0.0) + q;
        }
      }
      if (mounted) {
        setState(() => _billedQtyMap = qtyMap);
      }
    } catch (e) {
      AppLogger.error('Error fetching billed quantities for vendor: $e');
    }
  }

  void _showBatchModal(_PRLineItem item) {
    final qtyToReturn = double.tryParse(item.returnQtyController.text) ?? 0.0;
    showDialog(
      context: context,
      builder: (ctx) => _AddBatchDialog(
        itemName: item.sourceItem?.productName ?? 'Item',
        productId: item.sourceItem?.id ?? '',
        totalQuantity: qtyToReturn,
        warehouseName: _warehouseLocation,
        warehouseId: _warehouseLocation,
        initialBatches: item.batches,
        onSave: (batches) {
          setState(() {
            item.batches = batches;
            final totalPcs = batches.fold<double>(
              0,
              (sum, b) =>
                  sum + (double.tryParse(b['quantity']?.toString() ?? '0') ?? 0),
            );
            if (totalPcs > 0) {
              item.returnQtyController.text = totalPcs % 1 == 0
                  ? totalPcs.toInt().toString()
                  : totalPcs.toStringAsFixed(0);
            }
          });
        },
      ),
    );
  }

  final LayerLink _gstLink = LayerLink();
  OverlayEntry? _gstOverlay;

  void _closeGstOverlay() {
    _gstOverlay?.remove();
    _gstOverlay = null;
  }

  void _showTaxPreferencesDialog() {
    if (_selectedVendorObj == null) return;
    _closeGstOverlay();
    final vendor = _selectedVendorObj!;
    final overlay = Overlay.of(context);
    _gstOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeGstOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _gstLink,
            showWhenUnlinked: false,
            offset: const Offset(-354, 16),
            child: Material(
              color: Colors.transparent,
              child: _ConfigureTaxPreferencesDialog(
                initialTreatment: vendor.gstTreatment ?? 'Unregistered Business',
                initialGstin: vendor.gstin ?? '',
                onUpdate: (val, gstinVal, isPermanent) async {
                  final updatedVendor = vendor.copyWith(
                    gstTreatment: val,
                    gstin: gstinVal,
                  );
                  try {
                    ref.read(vendorProvider.notifier).updateVendorLocally(vendor.id, updatedVendor);
                    await ref.read(vendorProvider.notifier).updateVendor(vendor.id, updatedVendor);
                  } catch (e) {
                    debugPrint('Error updating vendor tax preferences: $e');
                  }
                  if (mounted) {
                    setState(() {
                      _selectedVendorObj = updatedVendor;
                    });
                  }
                  _closeGstOverlay();
                },
                onCancel: _closeGstOverlay,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_gstOverlay!);
  }

  final LayerLink _billingAddressLink = LayerLink();
  OverlayEntry? _addressDropdownOverlay;

  void _closeAddressDropdownOverlay() {
    _addressDropdownOverlay?.remove();
    _addressDropdownOverlay = null;
  }

  void _showAddressDropdownList({
    required Vendor vendor,
    required LayerLink link,
  }) {
    _closeAddressDropdownOverlay();
    final allAddresses = _getAllVendorAddresses(vendor);

    _addressDropdownOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeAddressDropdownOverlay,
          child: Stack(
            children: [
              const Positioned.fill(child: SizedBox.expand()),
              CompositedTransformFollower(
                link: link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 4),
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                    child: Container(
                      width: 340,
                      constraints: const BoxConstraints(maxHeight: 320),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: allAddresses.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final addr = allAddresses[i];
                                return _buildAddressDropdownItem(
                                  vendor: vendor,
                                  address: addr,
                                );
                              },
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          InkWell(
                            onTap: () {
                              _closeAddressDropdownOverlay();
                              _showAddressModal(
                                vendor: vendor,
                                customTitle: 'Billing Address',
                                isNewAddress: true,
                              );
                            },
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              color: Colors.white,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.plus, size: 14, color: Color(0xFF2563EB)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add New Address',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
    Overlay.of(context).insert(_addressDropdownOverlay!);
  }

  Map<String, dynamic> _normalizeAddress(Map<String, dynamic> address) {
    return {
      'attention': address['attention']?.toString() ?? '',
      'street1': (address['street1'] ?? address['street'] ?? address['address_street'] ?? address['addressStreet'] ?? '').toString(),
      'street2': (address['street2'] ?? address['place'] ?? address['address_place'] ?? address['addressPlace'] ?? '').toString(),
      'city': address['city']?.toString() ?? '',
      'state': address['state']?.toString() ?? '',
      'zip': (address['zip'] ?? address['pincode'] ?? address['zipCode'] ?? '').toString(),
      'country': (address['country'] ?? address['countryRegion'] ?? address['country_region'] ?? '').toString(),
      'phone': address['phone']?.toString() ?? '',
      if (address['id'] != null) 'id': address['id'].toString(),
    };
  }

  bool _areAddressesEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    String norm(dynamic val) => (val?.toString() ?? '').trim().toLowerCase();
    final streetA = norm(a['street1'] ?? a['street'] ?? a['address_street']);
    final streetB = norm(b['street1'] ?? b['street'] ?? b['address_street']);
    return streetA == streetB &&
        norm(a['city']) == norm(b['city']) &&
        norm(a['zip'] ?? a['pincode']) == norm(b['zip'] ?? b['pincode']);
  }

  List<Map<String, dynamic>> _getAllVendorAddresses(Vendor vendor) {
    final list = <Map<String, dynamic>>[];
    if (vendor.vendorAddresses != null && vendor.vendorAddresses!.isNotEmpty) {
      for (final addr in vendor.vendorAddresses!) {
        list.add(Map<String, dynamic>.from(addr));
      }
    } else if (vendor.billingAddress != null && vendor.billingAddress!.isNotEmpty) {
      list.add(Map<String, dynamic>.from(vendor.billingAddress!));
    }
    return list;
  }

  List<Map<String, dynamic>> _updateVendorAddressesDefaultFlags({
    required Vendor vendor,
    required Map<String, dynamic> selectedAddr,
  }) {
    final currentList = vendor.vendorAddresses ?? [];
    return currentList.map((addr) {
      final isMatch = _areAddressesEqual(addr, selectedAddr);
      final updated = Map<String, dynamic>.from(addr);
      updated['is_default_billing'] = isMatch;
      updated['isDefaultBilling'] = isMatch;
      return updated;
    }).toList();
  }

  Widget _buildAddressDropdownItem({
    required Vendor vendor,
    required Map<String, dynamic> address,
  }) {
    final statesList = ref.watch(statesProvider('IN')).valueOrNull ?? [];
    final countriesList = ref.watch(countriesProvider(null)).valueOrNull ?? [];

    final attention = address['attention']?.toString() ?? '';
    final street1 = (address['street1'] ?? address['street'] ?? '').toString();
    final street2 = (address['street2'] ?? address['place'] ?? '').toString();
    final cityStateZip = [
      address['city']?.toString() ?? '',
      address['state']?.toString() ?? '',
      (address['zip'] ?? address['pincode'] ?? '').toString(),
    ].where((s) => s.isNotEmpty).join(', ');
    final country = (address['country'] ?? address['countryRegion'] ?? '').toString();
    final phone = address['phone']?.toString() ?? '';

    final isSelected = _areAddressesEqual(vendor.billingAddress ?? {}, address);

    final rawLines = [
      if (street1.isNotEmpty) street1,
      if (street2.isNotEmpty) street2,
      if (cityStateZip.isNotEmpty) cityStateZip,
      if (country.isNotEmpty) country,
      if (phone.isNotEmpty) 'Phone: $phone',
    ];

    final lines = rawLines.map((l) => _resolveNameIfUuid(l, statesList, countriesList)).toList();

    bool isHovered = false;
    return StatefulBuilder(
      builder: (ctx, setSt) {
        return MouseRegion(
          onEnter: (_) => setSt(() => isHovered = true),
          onExit: (_) => setSt(() => isHovered = false),
          child: GestureDetector(
            onTap: () async {
              _closeAddressDropdownOverlay();
              final updatedAddresses = _updateVendorAddressesDefaultFlags(
                vendor: vendor,
                selectedAddr: address,
              );
              final normalizedAddr = _normalizeAddress(address);
              final updated = vendor.copyWith(
                billingAddress: normalizedAddr,
                vendorAddresses: updatedAddresses,
              );
              setState(() {
                _selectedVendorObj = updated;
                final pos = normalizedAddr['state']?.toString();
                if (pos != null && pos.isNotEmpty) {
                  final sList = ref.read(statesProvider('IN')).valueOrNull ?? [];
                  final dOptions = sList.map((s) {
                    final code = s['code'] ?? s['shortCode'] ?? '';
                    final name = s['name'] ?? '';
                    return code.isNotEmpty ? '[$code] - $name' : name;
                  }).where((str) => str.isNotEmpty).toList();
                  final matched = dOptions.firstWhere(
                    (opt) => opt.toLowerCase().contains(pos.toLowerCase()),
                    orElse: () => pos,
                  );
                  _selectedSourceOfSupply = matched;
                  _selectedDestinationOfSupply = matched;
                }
              });
              try {
                ref.read(vendorProvider.notifier).updateVendorLocally(vendor.id, updated);
                await ref.read(vendorProvider.notifier).updateVendor(vendor.id, updated);
                if (mounted) {
                  ZerpaiToast.success(context, 'Vendor address updated');
                }
              } catch (e) {
                if (mounted) {
                  ZerpaiToast.error(context, 'Failed to update address: $e');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHovered
                    ? const Color(0xFF3B82F6)
                    : (isSelected ? const Color(0xFFEFF6FF) : Colors.white),
                border: Border.all(
                  color: isHovered
                      ? const Color(0xFF3B82F6)
                      : (isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB)),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Text(
                          attention.isNotEmpty ? attention : 'Billing Address',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isHovered
                                ? Colors.white
                                : (isSelected ? const Color(0xFF2563EB) : const Color(0xFF1F2937)),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...lines.map(
                        (l) => Text(
                          l,
                          style: TextStyle(
                            fontSize: 11,
                            color: isHovered
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF4B5563),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () {
                        _closeAddressDropdownOverlay();
                        _showAddressModal(
                          vendor: vendor,
                          initialAddress: address,
                          customTitle: 'Billing Address',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isHovered
                              ? Colors.white.withValues(alpha: 0.2)
                              : (isSelected ? Colors.white : const Color(0xFFF3F4F6)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          LucideIcons.pencil,
                          size: 13,
                          color: isHovered
                              ? Colors.white
                              : (isSelected ? const Color(0xFF2563EB) : const Color(0xFF4B5563)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddressModal({
    required Vendor vendor,
    Map<String, dynamic>? initialAddress,
    String? customTitle,
    bool isNewAddress = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AddressDialog(
        title: customTitle ?? 'Billing Address',
        initialAddress: initialAddress ?? {},
        onSave: (newAddr) async {
          final normalized = _normalizeAddress(newAddr);
          final currentAddresses = vendor.vendorAddresses ?? [];
          final updatedList = List<Map<String, dynamic>>.from(currentAddresses);
          if (initialAddress != null) {
            final idx = updatedList.indexWhere((a) => _areAddressesEqual(a, initialAddress));
            if (idx != -1) {
              updatedList[idx] = normalized;
            } else {
              updatedList.add(normalized);
            }
          } else {
            updatedList.add(normalized);
          }

          final updated = vendor.copyWith(
            billingAddress: normalized,
            vendorAddresses: updatedList,
          );

          setState(() {
            _selectedVendorObj = updated;
          });

          try {
            ref.read(vendorProvider.notifier).updateVendorLocally(vendor.id, updated);
            await ref.read(vendorProvider.notifier).updateVendor(vendor.id, updated);
            if (mounted) {
              ZerpaiToast.success(context, 'Address saved successfully');
            }
          } catch (e) {
            if (mounted) {
              ZerpaiToast.error(context, 'Failed to save address: $e');
            }
          }

          setState(() {
            _selectedVendorObj = updated;
          });

          try {
            ref.read(vendorProvider.notifier).updateVendorLocally(vendor.id, updated);
            await ref.read(vendorProvider.notifier).updateVendor(vendor.id, updated);
            if (mounted) {
              ZerpaiToast.success(context, 'Address saved successfully');
            }
          } catch (e) {
            if (mounted) {
              ZerpaiToast.error(context, 'Failed to save address: $e');
            }
          }
        },
      ),
    );
  }

  void _onVendorSelected(Vendor? val) {
    setState(() {
      _selectedVendorObj = val;
      if (val == null) {
        _selectedSourceOfSupply = null;
        _selectedDestinationOfSupply = null;
        _selectedBill = null;
        _billedQtyMap = {};
      } else {
        _fetchBilledQuantitiesForVendor(val.id);
        final allCustomers = ref.read(salesCustomersProvider).valueOrNull ?? [];
        final cust = allCustomers.firstWhere(
          (c) => c.id == val.id,
          orElse: () => SalesCustomer(id: val.id, displayName: val.displayName),
        );
        String? pos = cust.placeOfSupply ?? val.sourceOfSupply;
        final sList = ref.read(statesProvider('IN')).valueOrNull ?? [];
        final dOptions = sList.map((s) {
          final code = s['code'] ?? s['shortCode'] ?? '';
          final name = s['name'] ?? '';
          return code.isNotEmpty ? '[$code] - $name' : name;
        }).where((str) => str.isNotEmpty).toList();

        if (pos != null && pos.isNotEmpty) {
          final matchedState = dOptions.firstWhere(
            (s) => s.toLowerCase().contains(pos.toLowerCase()),
            orElse: () => pos,
          );
          _selectedSourceOfSupply = matchedState;
          _selectedDestinationOfSupply = matchedState;
        } else {
          _selectedSourceOfSupply = null;
          _selectedDestinationOfSupply = null;
        }
      }
    });
  }

  //          Save

  Future<void> _save({bool draft = true}) async {
    final validItems = _items
        .where(
          (i) => i.sourceItem != null || i.returnQtyController.text.isNotEmpty,
        )
        .toList();
    if (validItems.isEmpty) {
      ZerpaiToast.error(context, 'Add at least one item to the return.');
      return;
    }
    setState(() => _saving = true);

    final ret = PurchaseReturn(
      id: widget.purchaseReturnId,
      returnNumber: _returnNumberController.text.trim(),
      returnDate: _returnDate,
      vendorId: _selectedVendorObj?.id,
      vendorName: _selectedVendorObj?.displayName,
      purchaseOrderNumber: _purchaseOrderController.text.trim().isEmpty
          ? null
          : _purchaseOrderController.text.trim(),
      purchaseReceiveNumber: _purchaseReceiveController.text.trim().isEmpty
          ? null
          : _purchaseReceiveController.text.trim(),
      status: draft ? 'draft' : 'confirmed',
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      subtotal: _subTotal,
      total: _grandTotal,
      items: validItems.map((i) => i.toModel()).toList(),
    );

    try {
      final notifier = ref.read(purchaseReturnsProvider.notifier);
      if (widget.isEdit) {
        final updated = await notifier.updateReturn(
          widget.purchaseReturnId!,
          ret,
        );
        if (mounted) {
          setState(() => _saving = false);
          if (updated != null) {
            ZerpaiToast.success(context, 'Purchase return updated.');
            context.go('${AppRoutes.purchaseReturns}?id=${updated.id}');
          } else {
            ZerpaiToast.error(context, 'Failed to update purchase return.');
          }
        }
      } else {
        final created = await notifier.createReturn(ret);
        if (mounted) {
          setState(() => _saving = false);
          if (created != null) {
            ZerpaiToast.success(
              context,
              draft
                  ? 'Purchase return saved as draft.'
                  : 'Purchase return confirmed.',
            );
            context.go('${AppRoutes.purchaseReturns}?id=${created.id}');
          } else {
            ZerpaiToast.error(context, 'Failed to save purchase return.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ZerpaiToast.error(context, 'An error occurred. Please try again.');
        AppLogger.error('Save purchase return error: $e', module: 'purchases');
      }
    }
  }

  //          Build

  @override
  Widget build(BuildContext context) {
    final vendorsState = ref.watch(vendorProvider);
    final vendors = vendorsState.vendors;
    final vendorIsLoading = vendorsState.isLoading;

    final statesAsync = ref.watch(statesProvider('IN'));
    final statesList = statesAsync.valueOrNull ?? [];
    final countriesAsync = ref.watch(countriesProvider(null));
    final countriesList = countriesAsync.valueOrNull ?? [];

    final dynamicStateOptions = statesList.map((s) {
      final code = s['code'] ?? s['shortCode'] ?? '';
      final name = s['name'] ?? '';
      return code.isNotEmpty ? '[$code] - $name' : name;
    }).where((str) => str.isNotEmpty).toList();

    return Container(
      color: Colors.white,
      child: ZerpaiLayout(
        pageTitle: '',
        enableBodyScroll: true,
        useHorizontalPadding: false,
        useTopPadding: false,
        footer: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          child: _MaxWidthContainer(
            maxWidth: _rowMaxWidth,
            child: Row(
              children: [
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _save(draft: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: AppTheme.borderLight),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      _saving ? 'Saving...' : 'Save as Draft',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(draft: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Save and Confirm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.purchaseReturns),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: AppTheme.borderLight),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.checkCircle2,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Inventory Tracking',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '|  PDF Template: \'Standard Template\'',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {},
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: _MaxWidthContainer(
            maxWidth: _rowMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  widget.isEdit
                      ? 'Edit Purchase Return'
                      : 'New Purchase Return',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                //          Vendor header band
                _HeaderBackgroundBand(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Vendor Name
                        _CompactFormRow(
                          label: 'Vendor Name',
                          required: true,
                          labelColor: AppTheme.errorRed,
                          fieldWidth: 750,
                          child: Row(
                            children: [
                              SizedBox(
                                width: _vendorFieldWidth,
                                child: widget.isEdit
                                    ? CustomTextField(
                                        controller: TextEditingController(
                                          text: _selectedVendorName ?? '',
                                        ),
                                        height: _fieldHeight,
                                        readOnly: true,
                                        enabled: false,
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: FormDropdown<Vendor>(
                                              value: _selectedVendorObj,
                                              items: vendors,
                                              isLoading: vendorIsLoading,
                                              showSearch: true,
                                              menuWidth: 450,
                                              displayStringForValue: (v) =>
                                                  v.displayName,
                                              searchStringForValue: (v) =>
                                                  '${v.displayName} ${v.vendorNumber ?? ''} ${v.companyName ?? ''} ${v.gstin ?? ''}',
                                              hint: 'Select or type a vendor',
                                              height: _fieldHeight,
                                              menuMaxHeight: 320,
                                              showRightBorder: false,
                                              itemBuilder: (v, isSelected, isHovered) =>
                                                  _buildVendorDropdownItem(
                                                    v,
                                                    isSelected,
                                                    isHovered,
                                                  ),
                                              textStyle: _selectedVendorObj != null
                                                  ? const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF1F2937),
                                                    )
                                                  : null,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(4),
                                                    bottomLeft: Radius.circular(
                                                      4,
                                                    ),
                                                  ),
                                              allowClear: true,
                                              onChanged: _onVendorSelected,
                                            ),
                                          ),
                                          Container(
                                            width: _fieldHeight,
                                            height: _fieldHeight,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.successGreen,
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(4),
                                                bottomRight: Radius.circular(4),
                                              ),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                LucideIcons.search,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              onPressed: () async {
                                                final allCustomers =
                                                    ref
                                                        .read(
                                                          salesCustomersProvider,
                                                        )
                                                        .valueOrNull ??
                                                    [];
                                                final result =
                                                    await AdvancedCustomerSearchModal.show(
                                                      context,
                                                      customers: allCustomers,
                                                    );
                                                if (result != null && mounted) {
                                                  final matched = allCustomers
                                                      .firstWhere(
                                                        (c) =>
                                                            c.displayName ==
                                                            result,
                                                        orElse: () =>
                                                            allCustomers.first,
                                                      );
                                                  _onVendorSelected(Vendor(
                                                    id: matched.id,
                                                    displayName:
                                                        matched.displayName,
                                                    sourceOfSupply: matched.placeOfSupply,
                                                    gstTreatment: matched.gstTreatment,
                                                    gstin: matched.gstin,
                                                  ));
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              if (_selectedVendorName != null || _selectedVendorObj != null) ...[
                                const SizedBox(width: 12),
                                _PRCurrencyBadge(selectedVendor: _selectedVendorObj),
                              ],
                            ],
                          ),
                        ),

                        // Show address + bill fields only after vendor selected
                        if (_selectedVendorObj != null) ...[
                          _PRVendorAddressPanel(
                            vendor: _selectedVendorObj!,
                            labelWidth: _labelWidth,
                            billingAddressLink: _billingAddressLink,
                            gstLink: _gstLink,
                            statesList: statesList,
                            countriesList: countriesList,
                            onEditBillingAddress: () => _showAddressDropdownList(
                              vendor: _selectedVendorObj!,
                              link: _billingAddressLink,
                            ),
                            onEditGstTreatment: _showTaxPreferencesDialog,
                          ),
                          // Source of Supply
                          _CompactFormRow(
                            label: 'Source of Supply',
                            required: true,
                            labelColor: AppTheme.errorRed,
                            fieldWidth: 330,
                            child: FormDropdown<String>(
                              value: _selectedSourceOfSupply,
                              enabled: !widget.isEdit,
                              items: dynamicStateOptions,
                              showSearch: true,
                              hint: 'Select source of supply',
                              height: _fieldHeight,
                              textStyle: _selectedSourceOfSupply != null && _selectedSourceOfSupply!.isNotEmpty
                                  ? const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    )
                                  : null,
                              onChanged: widget.isEdit
                                  ? (_) {}
                                  : (v) =>
                                      setState(() => _selectedSourceOfSupply = v),
                            ),
                          ),
                          // Destination of Supply
                          _CompactFormRow(
                            label: 'Destination of Supply',
                            required: true,
                            labelColor: AppTheme.errorRed,
                            fieldWidth: 330,
                            child: FormDropdown<String>(
                              value: _selectedDestinationOfSupply,
                              enabled: !widget.isEdit,
                              items: dynamicStateOptions,
                              showSearch: true,
                              hint: 'Select destination of supply',
                              height: _fieldHeight,
                              textStyle: _selectedDestinationOfSupply != null && _selectedDestinationOfSupply!.isNotEmpty
                                  ? const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    )
                                  : null,
                              onChanged: widget.isEdit
                                  ? (_) {}
                                  : (v) => setState(
                                      () => _selectedDestinationOfSupply = v,
                                    ),
                            ),
                          ),
                          // Bill#
                          _CompactFormRow(
                            label: 'Bill#',
                            fieldWidth: 330,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FormDropdown<String>(
                                  value: _selectedBill,
                                  enabled: !widget.isEdit,
                                  items: const [
                                    'BILL-001',
                                    'BILL-002',
                                    'B2B/25-26/00089',
                                    'B2B/25-26/00098',
                                    'B2B/25-26/00101',
                                  ],
                                  hint: 'Select linked bill',
                                  height: _fieldHeight,
                                  allowClear: !widget.isEdit,
                                  onChanged: widget.isEdit
                                      ? (_) {}
                                      : (v) =>
                                          setState(() => _selectedBill = v),
                                ),
                                if (_selectedBill != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bill Date: ${DateFormat('dd-MM-yyyy').format(_returnDate)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                //          Purchase Return#
                _CompactFormRow(
                  label: 'Purchase Return#',
                  required: true,
                  labelColor: AppTheme.errorRed,
                  fieldWidth: 500,
                  child: Row(
                    children: [
                      Expanded(
                        child: FormDropdown<String>(
                          value: _selectedTransactionSeries,
                          items: const [
                            'Default Transaction Series',
                            'Purchase Return Series',
                          ],
                          height: _fieldHeight,
                          onChanged: (v) =>
                              setState(() => _selectedTransactionSeries = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          controller: _returnNumberController,
                          height: _fieldHeight,
                          suffixWidget: ZTooltip(
                            message:
                                'Enable or disable auto-generation of Purchase Return numbers.',
                            child: GestureDetector(
                              onTap: _showPreferencesDialog,
                              child: const Icon(
                                LucideIcons.settings,
                                size: 14,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Purchase Order#
                _CompactFormRow(
                  label: 'Purchase Order#',
                  fieldWidth: 330,
                  child: CustomTextField(
                    controller: _purchaseOrderController,
                    height: _fieldHeight,
                    hintText: 'Reference PO number',
                  ),
                ),

                // Purchase Receive#
                _CompactFormRow(
                  label: 'Receive#',
                  fieldWidth: 330,
                  child: CustomTextField(
                    controller: _purchaseReceiveController,
                    height: _fieldHeight,
                    hintText: 'Reference receive number',
                  ),
                ),

                // Purchase Return Date
                _CompactFormRow(
                  label: 'Purchase Return Date',
                  fieldWidth: 330,
                  child: CustomTextField(
                    key: _returnDateKey,
                    controller: _returnDateController,
                    readOnly: true,
                    onTap: _pickReturnDate,
                    height: _fieldHeight,
                    suffixWidget: const Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),

                //          Reason for Return
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: _labelWidth,
                        child: const Row(
                          children: [
                            Text(
                              'Reason for Return',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(width: 4),
                            ZTooltip(
                              message:
                                  'Briefly describe why goods are being returned to the vendor.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: _gapWidth),
                      SizedBox(
                        width: 330,
                        child: CustomTextField(
                          controller: _reasonController,
                          hintText:
                              'e.g. Damaged goods, wrong items delivered, quality issue',
                          height: _fieldHeight,
                        ),
                      ),
                    ],
                  ),
                ),

                //          Reverse charge
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const SizedBox(width: _labelWidth + _gapWidth),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Checkbox(
                          value: _isReverseCharge,
                          onChanged: (v) =>
                              setState(() => _isReverseCharge = v ?? false),
                          activeColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'This transaction is applicable for reverse charge',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                //          Item table toolbar
                _PRItemTableToolbar(
                  warehouseLocation: _warehouseLocation,
                  onWarehouseChanged: (v) =>
                      setState(() => _warehouseLocation = v),
                  discountType: _discountType,
                  onDiscountTypeChanged: (v) =>
                      setState(() => _discountType = v),
                  selectedPriceList: _selectedPriceList,
                  priceListOptions:
                      ref.watch(realPriceListsProvider).valueOrNull ?? [],
                  priceListsLoading: ref
                      .watch(realPriceListsProvider)
                      .isLoading,
                  onPriceListChanged: (v) =>
                      setState(() => _selectedPriceList = v),
                ),
                const SizedBox(height: 16),

                //          Items grid
                _PRItemsGrid(
                  items: _items,
                  availableProducts: ref.watch(itemsControllerProvider).items,
                  onSearchProducts: (q) =>
                      ref.read(itemsControllerProvider.notifier).searchItems(q),
                  onAddItem: _addItem,
                  onAddBulkItems: _showBulkItemsDialog,
                  onInsertItem: _insertItem,
                  onDuplicateItem: _duplicateItem,
                  onRemoveItem: _removeItem,
                  onTotalsChanged: () => setState(() {}),
                  warehouse: _warehouseLocation,
                  isReverseCharge: _isReverseCharge,
                  billedQtyMap: _billedQtyMap,
                  onSelectBatch: _showBatchModal,
                  sourceOfSupply: _selectedSourceOfSupply,
                  destinationOfSupply: _selectedDestinationOfSupply,
                ),

                const SizedBox(height: 32),

                //          Totals panel
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Sub Total
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Sub Total',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        _formatMoney(_subTotal),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total Quantity : ${_totalQuantity % 1 == 0 ? _totalQuantity.toInt() : _totalQuantity.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_taxBreakdown.isNotEmpty) ...[
                              for (final entry in _taxBreakdown.entries)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    4,
                                    20,
                                    6,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        _formatMoney(entry.value),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            // Adjustment
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 120,
                                    child: Text(
                                      'Adjustment',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    fit: FlexFit.tight,
                                    child: CustomTextField(
                                      controller: _adjustmentController,
                                      hintText: '0.00',
                                      height: 34,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const ZTooltip(
                                    message:
                                        'Any additional adjustment amount (positive or negative).',
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      _formatMoney(_adjustmentAmount),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                            // Total
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _formatMoney(_grandTotal),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
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

                const SizedBox(height: 32),

                // Notes + Attach Files (Full-bleed edge-to-edge container matching purchases_bills_create.dart)
                _PRNotesAndAttachmentsBand(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notes Section
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 400,
                              ),
                              child: TextField(
                                controller: _notesController,
                                maxLines: 4,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter any notes for this purchase return',
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      6,
                                    ),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      6,
                                    ),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      6,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'It will not be shown in PDF',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),
                      // Vertical Divider
                      Container(
                        width: 1,
                        height: 140,
                        color: const Color(0xFFDBEAFE),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      const SizedBox(width: 24),

                      // Attach File(s) Section
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Attach File(s) to Purchase Return',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FileUploadButton(
                                  files: _attachedFiles,
                                  maxFiles: 10,
                                  onFilesChanged: (files) => setState(
                                    () => _attachedFiles = files,
                                  ),
                                ),
                                Container(
                                  height: 34,
                                  width: 34,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.backgroundColor,
                                    border: Border(
                                      top: BorderSide(
                                        color: AppTheme.borderColor,
                                      ),
                                      right: BorderSide(
                                        color: AppTheme.borderColor,
                                      ),
                                      bottom: BorderSide(
                                        color: AppTheme.borderColor,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(4),
                                      bottomRight: Radius.circular(4),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You can upload a maximum of 10 files, 5MB each',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 24),

                //          Additional Fields note
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    children: [
                      TextSpan(
                        text: 'Additional Fields: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text:
                            'Start adding custom fields for your purchase returns by going to ',
                      ),
                      TextSpan(
                        text: 'Settings',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(text: '   †’ '),
                      TextSpan(
                        text: 'Purchases',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(text: '   †’ '),
                      TextSpan(
                        text: 'Purchase Returns',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
String _resolveNameIfUuid(
  String text,
  List<Map<String, String>> states,
  List<Map<String, String>> countries,
) {
  if (text.isEmpty) return text;
  final uuidRegex = RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}');
  return text.replaceAllMapped(uuidRegex, (match) {
    final uuid = match.group(0)!;
    final matchedState = states.firstWhere(
      (s) => s['id'] == uuid,
      orElse: () => {},
    );
    if (matchedState.isNotEmpty && (matchedState['name']?.isNotEmpty ?? false)) {
      return matchedState['name']!;
    }
    final matchedCountry = countries.firstWhere(
      (c) => c['id'] == uuid,
      orElse: () => {},
    );
    if (matchedCountry.isNotEmpty && (matchedCountry['name']?.isNotEmpty ?? false)) {
      return matchedCountry['name']!;
    }
    return uuid;
  });
}

  Widget _buildVendorDropdownItem(Vendor v, bool isSelected, bool isHovered) {
    final firstName = (v.firstName ?? '').trim();
    final initialSource = firstName.isNotEmpty
        ? firstName
        : (v.displayName.isNotEmpty ? v.displayName : '?');
    final initial = initialSource.substring(0, 1).toUpperCase();

    final backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.white);
    final primaryTextColor = isHovered ? Colors.white : AppTheme.textPrimary;
    final secondaryTextColor = isHovered
        ? Colors.white.withValues(alpha: 0.85)
        : AppTheme.textSecondary;

    final topLine = v.vendorNumber != null && v.vendorNumber!.isNotEmpty
        ? '${v.displayName} | ${v.vendorNumber}'
        : v.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isHovered ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
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
                  ),
                ),
                if (v.companyName != null && v.companyName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    v.companyName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextColor,
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

//          Currency badge

class _PRCurrencyBadge extends ConsumerWidget {
  final Vendor? selectedVendor;

  const _PRCurrencyBadge({this.selectedVendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = selectedVendor?.currency ?? 'INR';
    final dbCurrencies = ref.watch(currenciesProvider(null)).valueOrNull;

    String symbol = '₹';
    String label = '$currencyCode - Indian Rupee';

    if (dbCurrencies != null && dbCurrencies.isNotEmpty) {
      final match = dbCurrencies.firstWhere(
        (c) => c.code.toUpperCase() == currencyCode.toUpperCase(),
        orElse: () => CurrencyOption(
          id: '',
          code: currencyCode,
          name: 'Indian Rupee',
          symbol: '₹',
          decimals: 2,
          format: '',
          label: '$currencyCode - Indian Rupee',
        ),
      );
      if (match.code.isNotEmpty) {
        symbol = match.symbol.isNotEmpty ? match.symbol : '₹';
        label = match.label;
      }
    } else if (currencyCode == 'USD') {
      symbol = '\$';
      label = 'USD - US Dollar';
    } else if (currencyCode == 'EUR') {
      symbol = '€';
      label = 'EUR - Euro';
    } else if (currencyCode == 'GBP') {
      symbol = '£';
      label = 'GBP - British Pound';
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

//          Vendor address panel

class _PRVendorAddressPanel extends ConsumerWidget {
  final Vendor vendor;
  final double labelWidth;
  final LayerLink billingAddressLink;
  final LayerLink gstLink;
  final VoidCallback onEditBillingAddress;
  final VoidCallback? onEditGstTreatment;
  final List<Map<String, String>> statesList;
  final List<Map<String, String>> countriesList;

  const _PRVendorAddressPanel({
    required this.vendor,
    required this.labelWidth,
    required this.billingAddressLink,
    required this.gstLink,
    required this.onEditBillingAddress,
    this.onEditGstTreatment,
    required this.statesList,
    required this.countriesList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(salesCustomersProvider).valueOrNull ?? [];
    final c = customers.firstWhere(
      (cust) => cust.id == vendor.id,
      orElse: () => SalesCustomer(id: vendor.id, displayName: vendor.displayName),
    );

    final bAddrLines = <String>[];
    if (c.billingAddressStreet1 != null && c.billingAddressStreet1!.isNotEmpty) {
      bAddrLines.add(c.billingAddressStreet1!);
    }
    if (c.billingAddressStreet2 != null && c.billingAddressStreet2!.isNotEmpty) {
      bAddrLines.add(c.billingAddressStreet2!);
    }
    final cityStateZip = [
      if (c.billingAddressCity != null && c.billingAddressCity!.isNotEmpty) c.billingAddressCity!,
      if (c.billingAddressStateId != null && c.billingAddressStateId!.isNotEmpty) c.billingAddressStateId!,
      if (c.billingAddressZip != null && c.billingAddressZip!.isNotEmpty) c.billingAddressZip!,
    ].join(', ');
    if (cityStateZip.isNotEmpty) bAddrLines.add(cityStateZip);
    if (c.billingAddressCountryId != null && c.billingAddressCountryId!.isNotEmpty) {
      bAddrLines.add(c.billingAddressCountryId!);
    }
    if (c.billingAddressPhone != null && c.billingAddressPhone!.isNotEmpty) {
      bAddrLines.add('Phone: ${c.billingAddressPhone!}');
    }

    if (bAddrLines.isEmpty && vendor.billingAddress != null && vendor.billingAddress!.isNotEmpty) {
      final addr = vendor.billingAddress!;
      final street1 = addr['street1'] as String? ?? addr['street'] as String? ?? '';
      final street2 = addr['street2'] as String? ?? addr['place'] as String? ?? '';
      final city = addr['city'] as String? ?? '';
      final state = addr['state'] as String? ?? '';
      final zip = addr['zip'] as String? ?? addr['pincode'] as String? ?? '';
      final country = addr['country'] as String? ?? addr['countryRegion'] as String? ?? '';
      final phone = addr['phone'] as String? ?? '';
      if (street1.isNotEmpty) bAddrLines.add(street1);
      if (street2.isNotEmpty) bAddrLines.add(street2);
      final csz = [city, state, zip].where((s) => s.isNotEmpty).join(', ');
      if (csz.isNotEmpty) bAddrLines.add(csz);
      if (country.isNotEmpty) bAddrLines.add(country);
      if (phone.isNotEmpty) bAddrLines.add('Phone: $phone');
    }

    final resolvedLines = bAddrLines
        .map((l) => _resolveNameIfUuid(l, statesList, countriesList))
        .toList();

    final gstTreatment = c.gstTreatment ?? vendor.gstTreatment ?? 'Unregistered Business';
    final gstin = c.gstin ?? vendor.gstin;

    return Padding(
      padding: EdgeInsets.only(
        left: labelWidth + 16,
        bottom: 12,
        top: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BILLING ADDRESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              CompositedTransformTarget(
                link: billingAddressLink,
                child: InkWell(
                  onTap: onEditBillingAddress,
                  child: const Icon(
                    LucideIcons.pencil,
                    size: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
          if (resolvedLines.isEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: onEditBillingAddress,
              child: const Text(
                'New Address',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              vendor.displayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            for (final line in resolvedLines)
              Text(
                line,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4B5563),
                  height: 1.4,
                ),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GST Treatment: ',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                gstTreatment,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 4),
              CompositedTransformTarget(
                link: gstLink,
                child: InkWell(
                  onTap: onEditGstTreatment,
                  child: const Icon(
                    LucideIcons.pencil,
                    size: 11,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          if (gstin != null && gstin.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'GSTIN: ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                Text(
                  gstin,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.pencil,
                  size: 11,
                  color: Color(0xFF2563EB),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Preferences dialog
class _PRPreferencesDialog extends StatefulWidget {
  final String prefix;
  final String nextNumber;
  final bool autoGenerate;
  final void Function(String prefix, String nextNumber, bool autoGenerate)
  onSave;

  const _PRPreferencesDialog({
    required this.prefix,
    required this.nextNumber,
    required this.autoGenerate,
    required this.onSave,
  });

  @override
  State<_PRPreferencesDialog> createState() => _PRPreferencesDialogState();
}

class _PRPreferencesDialogState extends State<_PRPreferencesDialog> {
  late bool _auto;
  late final TextEditingController _prefixCtrl;
  late final TextEditingController _nextCtrl;

  @override
  void initState() {
    super.initState();
    _auto = widget.autoGenerate;
    _prefixCtrl = TextEditingController(text: widget.prefix);
    _nextCtrl = TextEditingController(text: widget.nextNumber);
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _nextCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Purchase Return Preferences',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Auto-generate Return#',
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              Switch(
                value: _auto,
                onChanged: (v) => setState(() => _auto = v),
                activeColor: AppTheme.primaryBlue,
              ),
            ],
          ),
          if (_auto) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _prefixCtrl,
                    hintText: 'Prefix (e.g. PR-)',
                    height: 34,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    controller: _nextCtrl,
                    hintText: 'Next number',
                    height: 34,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ZButton.secondary(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              ZButton.primary(
                label: 'Save',
                onPressed: () {
                  widget.onSave(_prefixCtrl.text, _nextCtrl.text, _auto);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Item table toolbar

class _PRItemTableToolbar extends ConsumerWidget {
  final String warehouseLocation;
  final ValueChanged<String> onWarehouseChanged;
  final String discountType;
  final ValueChanged<String> onDiscountTypeChanged;
  final PriceList? selectedPriceList;
  final List<PriceList> priceListOptions;
  final bool priceListsLoading;
  final ValueChanged<PriceList?> onPriceListChanged;

  const _PRItemTableToolbar({
    required this.warehouseLocation,
    required this.onWarehouseChanged,
    required this.discountType,
    required this.onDiscountTypeChanged,
    required this.selectedPriceList,
    required this.priceListOptions,
    this.priceListsLoading = false,
    required this.onPriceListChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehouses = ref.watch(warehousesProvider).valueOrNull ?? [];
    final warehouseNames = warehouses
        .map((w) => w.name)
        .where((n) => n.isNotEmpty)
        .toList();
    final effectiveWarehouse = warehouseNames.contains(warehouseLocation)
        ? warehouseLocation
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Warehouse
          SizedBox(
            width: 280,
            child: CustomPaint(
              foregroundPainter: const _DottedUnderlinePainter(),
              child: warehouses.isEmpty
                  ? const SizedBox(
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                    )
                  : FormDropdown<String>(
                      value: effectiveWarehouse,
                      items: warehouseNames,
                      hint: 'Select Warehouse',
                      height: 36,
                      hideBorderDefault: true,
                      allowClear: true,
                      onChanged: (v) {
                        if (v != null) onWarehouseChanged(v);
                      },
                    ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
          // Discount type
          SizedBox(
            width: 200,
            child: Row(
              children: [
                const Icon(
                  LucideIcons.percent,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FormDropdown<String>(
                    value: discountType,
                    items: const ['At Transaction Level', 'At Line Item Level'],
                    height: 36,
                    hideBorderDefault: true,
                    onChanged: (v) {
                      if (v != null) onDiscountTypeChanged(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
          // Price list
          SizedBox(
            width: 200,
            child: Row(
              children: [
                const Icon(
                  LucideIcons.clipboardList,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FormDropdown<PriceList>(
                    value: selectedPriceList,
                    items: priceListOptions,
                    hint: priceListsLoading
                        ? 'Loading...'
                        : 'Select Price List',
                    height: 36,
                    hideBorderDefault: true,
                    allowClear: true,
                    displayStringForValue: (pl) => pl.name,
                    onChanged: onPriceListChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedUnderlinePainter extends CustomPainter {
  const _DottedUnderlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borderLight
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    final y = size.height;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Items grid

class _PRItemsGrid extends StatefulWidget {
  final List<_PRLineItem> items;
  final List<Item> availableProducts;
  final Future<List<Item>> Function(String query) onSearchProducts;
  final VoidCallback onAddItem;
  final VoidCallback onAddBulkItems;
  final void Function(int) onInsertItem;
  final void Function(int) onDuplicateItem;
  final void Function(int) onRemoveItem;
  final VoidCallback onTotalsChanged;
  final String warehouse;
  final bool isReverseCharge;
  final Map<String, double> billedQtyMap;
  final void Function(_PRLineItem) onSelectBatch;
  final String? sourceOfSupply;
  final String? destinationOfSupply;

  const _PRItemsGrid({
    required this.items,
    required this.availableProducts,
    required this.onSearchProducts,
    required this.onAddItem,
    required this.onAddBulkItems,
    required this.onInsertItem,
    required this.onDuplicateItem,
    required this.onRemoveItem,
    required this.onTotalsChanged,
    required this.warehouse,
    required this.isReverseCharge,
    required this.billedQtyMap,
    required this.onSelectBatch,
    this.sourceOfSupply,
    this.destinationOfSupply,
  });

  @override
  State<_PRItemsGrid> createState() => _PRItemsGridState();
}

class _PRItemsGridState extends State<_PRItemsGrid> {
  static const double _rowActionWidth = 28;
  static const double _rowActionsWidth = _rowActionWidth * 2;
  static const double _rowMenuWidth = 220;

  bool _isBulkUpdateActive = false;
  bool _areAdditionalInfosHidden = false;
  int? _hoveredItemActionIndex;
  final TextEditingController _itemDetailsSearchCtrl = TextEditingController();
  bool _showSearchItemDetails = false;
  // ignore: unused_field
  String _itemDetailsSearchQuery = '';

  @override
  void dispose() {
    _itemDetailsSearchCtrl.dispose();
    super.dispose();
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
          _TH(label),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggle,
            child: const Icon(
              LucideIcons.search,
              size: 13,
              color: AppTheme.textSecondary,
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
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
              textAlign: textAlign,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
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
            child: const Icon(
              LucideIcons.x,
              size: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgDisabled,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.settings, size: 16, color: AppTheme.textSecondary),
          Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildAddRowButton() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: widget.onAddItem,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.plusCircle,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Add New Row',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(
            width: 1,
            color: Color(0xFFE5E7EB),
            thickness: 1,
            indent: 6,
            endIndent: 6,
          ),
          PopupMenuButton<String>(
            tooltip: '',
            offset: const Offset(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            color: Colors.white,
            onSelected: (val) {
              if (val == 'header') {
                widget.onAddItem();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'header',
                height: 36,
                child: Row(
                  children: [
                    Icon(LucideIcons.plusCircle, size: 14, color: AppTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      'Add New Header',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkAddButton() {
    return InkWell(
      onTap: widget.onAddBulkItems,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.plusCircle,
              size: 16,
              color: AppTheme.primaryBlue,
            ),
            SizedBox(width: 6),
            Text(
              'Add Items in Bulk',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowActionMenuItem({
    required String label,
    required VoidCallback onPressed,
  }) {
    return MenuItemButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        minimumSize: const WidgetStatePropertyAll(Size(_rowMenuWidth, 40)),
        overlayColor: WidgetStatePropertyAll(
          AppTheme.backgroundColor.withValues(alpha: 0),
        ),
        backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
      ),
      child: _PRRowActionMenuHoverItem(
        label: label,
        width: _rowMenuWidth,
        height: 40,
      ),
    );
  }

  Widget _buildRowActionMenu(int index) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppTheme.backgroundColor),
        surfaceTintColor: const WidgetStatePropertyAll(
          AppTheme.backgroundColor,
        ),
        elevation: const WidgetStatePropertyAll(6),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.borderLight),
          ),
        ),
      ),
      menuChildren: [
        _buildRowActionMenuItem(
          label: _areAdditionalInfosHidden
              ? 'Show Additional Information'
              : 'Hide Additional Information',
          onPressed: () => setState(
            () => _areAdditionalInfosHidden = !_areAdditionalInfosHidden,
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        _buildRowActionMenuItem(
          label: 'Clone',
          onPressed: () => widget.onDuplicateItem(index),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        _buildRowActionMenuItem(
          label: 'Insert New Row',
          onPressed: () => widget.onInsertItem(index),
        ),
        _buildRowActionMenuItem(
          label: 'Insert Items in Bulk',
          onPressed: widget.onAddBulkItems,
        ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(4),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table header bar
        Container(
          margin: const EdgeInsets.only(right: _rowActionsWidth),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              const Text(
                'Item Table',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              PopupMenuButton<int>(
                offset: const Offset(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.borderLight),
                ),
                color: AppTheme.backgroundColor,
                elevation: 4,
                tooltip: '',
                onSelected: (value) {
                  if (value == 0) {
                    setState(() => _isBulkUpdateActive = true);
                  } else if (value == 1) {
                    setState(
                      () => _areAdditionalInfosHidden =
                          !_areAdditionalInfosHidden,
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<int>(
                    value: 0,
                    padding: EdgeInsets.zero,
                    height: 40,
                    child: _PRBulkMenuHoverItem(
                      label: 'Bulk Update Line Items',
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 1,
                    padding: EdgeInsets.zero,
                    height: 40,
                    child: _PRBulkMenuHoverItem(
                      label: _areAdditionalInfosHidden
                          ? 'Show All Additional Information'
                          : 'Hide All Additional Information',
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.checkCircle,
                        size: 16,
                        color: AppTheme.primaryBlueDark,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Bulk Actions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildHeaderActionButton(),
            ],
          ),
        ),
        if (_isBulkUpdateActive)
          Container(
            margin: const EdgeInsets.only(right: _rowActionsWidth),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              border: const Border(
                left: BorderSide(color: AppTheme.borderLight),
                right: BorderSide(color: AppTheme.borderLight),
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Select a field to bulk update across all rows.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _isBulkUpdateActive = false),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Column headers
        Container(
          margin: const EdgeInsets.only(right: _rowActionsWidth),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.borderLight),
              left: BorderSide(color: AppTheme.borderLight),
              right: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: 40),
                _vLine(),
                Expanded(
                  flex: 10,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: _buildHeaderSearchField(
                      label: 'ITEM DETAILS',
                      controller: _itemDetailsSearchCtrl,
                      hintText: 'Search items...',
                      onChanged: (val) {
                        setState(() => _itemDetailsSearchQuery = val);
                      },
                      isSearchVisible: _showSearchItemDetails,
                      onToggle: () {
                        setState(() {
                          _showSearchItemDetails = !_showSearchItemDetails;
                          if (!_showSearchItemDetails) {
                            _itemDetailsSearchCtrl.clear();
                            _itemDetailsSearchQuery = '';
                          }
                        });
                      },
                    ),
                  ),
                ),
                _vLine(),
                const Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    child: _TH('BILLED QTY', right: true),
                  ),
                ),
                _vLine(),
                const Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    child: _TH('RETURNED QTY', right: true),
                  ),
                ),
                _vLine(),
                const Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: _TH('QTY TO RETURN', right: true),
                  ),
                ),
                _vLine(),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        _TH('RATE'),
                        SizedBox(width: 4),
                        ZTooltip(
                          message:
                              'You can perform basic calculations directly in this field using parentheses ( ) and arithmetic operators: + - / *',
                          child: Icon(
                            LucideIcons.calculator,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _vLine(),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: widget.isReverseCharge
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'TAX',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '(REVERSE CHARGE)',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : const _TH(
                            'TAX',
                            tooltip:
                                'Applicable tax for the items. You can select a tax rate from the list.',
                          ),
                  ),
                ),
                _vLine(),
                const Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: _TH('AMOUNT', right: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Item rows
        ...List.generate(widget.items.length, (index) {
          final showActions = _hoveredItemActionIndex == index;
          return MouseRegion(
            onEnter: (_) {
              if (_hoveredItemActionIndex != index)
                setState(() => _hoveredItemActionIndex = index);
            },
            onExit: (_) {
              if (_hoveredItemActionIndex == index)
                setState(() => _hoveredItemActionIndex = null);
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      border: Border(
                        left: BorderSide(color: AppTheme.borderLight),
                        right: BorderSide(color: AppTheme.borderLight),
                        bottom: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: _PRItemRow(
                      item: widget.items[index],
                      availableProducts: widget.availableProducts,
                      onSearchProducts: widget.onSearchProducts,
                      onChanged: widget.onTotalsChanged,
                      defaultWarehouse: widget.warehouse,
                      showAdditionalInformation: !_areAdditionalInfosHidden,
                      billedQtyMap: widget.billedQtyMap,
                      onSelectBatch: widget.onSelectBatch,
                      sourceOfSupply: widget.sourceOfSupply,
                      destinationOfSupply: widget.destinationOfSupply,
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: !showActions,
                  child: AnimatedOpacity(
                    opacity: showActions ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: Row(
                      children: [
                        SizedBox(
                          width: _rowActionWidth,
                          child: Center(child: _buildRowActionMenu(index)),
                        ),
                        SizedBox(
                          width: _rowActionWidth,
                          child: Center(
                            child: GestureDetector(
                              onTap: () => widget.onRemoveItem(index),
                              behavior: HitTestBehavior.opaque,
                              child: const _PRRowActionIconButton(
                                icon: LucideIcons.x,
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
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildAddRowButton(),
            const SizedBox(width: 12),
            _buildBulkAddButton(),
          ],
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────

class _PRItemRow extends ConsumerStatefulWidget {
  final _PRLineItem item;
  final List<Item> availableProducts;
  final Future<List<Item>> Function(String) onSearchProducts;
  final VoidCallback onChanged;
  final String defaultWarehouse;
  final bool showAdditionalInformation;
  final Map<String, double> billedQtyMap;
  final void Function(_PRLineItem) onSelectBatch;
  final String? sourceOfSupply;
  final String? destinationOfSupply;

  const _PRItemRow({
    required this.item,
    required this.availableProducts,
    required this.onSearchProducts,
    required this.onChanged,
    required this.defaultWarehouse,
    required this.showAdditionalInformation,
    required this.billedQtyMap,
    required this.onSelectBatch,
    this.sourceOfSupply,
    this.destinationOfSupply,
  });

  @override
  ConsumerState<_PRItemRow> createState() => _PRItemRowState();
}

class _PRItemRowState extends ConsumerState<_PRItemRow> {
  String _computeAmount(_PRLineItem item) {
    final qty = double.tryParse(item.returnQtyController.text) ?? 0;
    final rate = double.tryParse(item.rateController.text) ?? 0;
    return (qty * rate).clamp(0.0, double.infinity).toStringAsFixed(2);
  }

  String _getBatchSummaryText(List<Map<String, dynamic>> batches) {
    if (batches.isEmpty) return '';
    final count = batches.length;
    double totalPcs = 0;
    for (final b in batches) {
      final q = double.tryParse(b['quantity']?.toString() ?? '0') ?? 0;
      totalPcs += q;
    }
    final pcsStr = totalPcs % 1 == 0 ? totalPcs.toInt().toString() : totalPcs.toStringAsFixed(0);
    final batchWord = count == 1 ? 'batch' : 'batches';
    return '$pcsStr pcs taken from $count $batchWord.';
  }

  void _onItemSelected(Item? selected) {
    setState(() {
      widget.item.sourceItem = selected;
      if (selected != null) {
        widget.item.rateController.text =
            selected.costPrice?.toStringAsFixed(2) ?? '0.00';
        widget.item.descriptionController.text =
            selected.purchaseDescription ?? '';

        final itemsState = ref.read(itemsControllerProvider);
        final taxOptions = _buildTaxOptions(
          itemsState,
          widget.sourceOfSupply,
          widget.destinationOfSupply,
        );

        final resolvedTax = _resolveTaxOptionForProduct(
          selected,
          taxOptions,
          widget.sourceOfSupply,
          widget.destinationOfSupply,
        );

        widget.item.selectedTax = resolvedTax.label;
        widget.item.selectedTaxId = resolvedTax.id;
        widget.item.selectedTaxRate = resolvedTax.rate;
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final productId = item.sourceItem?.id;
    final billedQty = productId != null ? (widget.billedQtyMap[productId] ?? 0.0) : 0.0;
    final billedQtyText = billedQty % 1 == 0 ? billedQty.toInt().toString() : billedQty.toStringAsFixed(2);
    final returnedQtyText = item.returnedQty % 1 == 0 ? item.returnedQty.toInt().toString() : item.returnedQty.toStringAsFixed(2);
    final qtyToReturnVal = double.tryParse(item.returnQtyController.text) ?? 0.0;

    final itemsState = ref.watch(itemsControllerProvider);
    final taxOptions = _buildTaxOptions(
      itemsState,
      widget.sourceOfSupply,
      widget.destinationOfSupply,
    );

    if (item.sourceItem != null && (item.selectedTax == null || item.selectedTax == 'Non-Taxable')) {
      final pref = item.sourceItem?.taxPreference?.toLowerCase() ?? '';
      if (pref != 'non-taxable' && pref != 'non_taxable') {
        final resolvedTax = _resolveTaxOptionForProduct(
          item.sourceItem!,
          taxOptions,
          widget.sourceOfSupply,
          widget.destinationOfSupply,
        );
        item.selectedTax = resolvedTax.label;
        item.selectedTaxId = resolvedTax.id;
        item.selectedTaxRate = resolvedTax.rate;
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grip handle
          const SizedBox(
            width: 40,
            child: Padding(
              padding: EdgeInsets.only(top: 14),
              child: Align(
                alignment: Alignment.topCenter,
                child: Icon(
                  LucideIcons.gripVertical,
                  size: 16,
                  color: AppTheme.borderLight,
                ),
              ),
            ),
          ),
          _vLine(),
          // ITEM DETAILS
          Expanded(
            flex: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: item.sourceItem == null
                  ? Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.bgDisabled,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: const Icon(
                            LucideIcons.image,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FormDropdown<Item>(
                            value: item.sourceItem,
                            items: widget.availableProducts,
                            hint: 'Type or click to select an item.',
                            height: _PurchaseReturnsCreatePageState._tableFieldHeight,
                            hideBorderDefault: true,
                            allowClear: true,
                            displayStringForValue: (p) => p.productName,
                            searchStringForValue: (p) =>
                                '${p.productName} ${p.itemCode} ${p.sku ?? ''}',
                            onSearch: widget.onSearchProducts,
                            itemBuilder: (product, isSelected, isHovered) =>
                                Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isHovered || isSelected
                                        ? Colors.transparent
                                        : const Color(0xFFE5E7EB),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: _PRProductDropdownItem(
                                productName: product.productName,
                                costPrice: product.costPrice,
                                highlighted: isSelected || isHovered,
                              ),
                            ),
                            onChanged: _onItemSelected,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                border: Border.all(color: AppTheme.borderLight),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: item.sourceItem!.primaryImageUrl != null &&
                                      item.sourceItem!.primaryImageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        item.sourceItem!.primaryImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(LucideIcons.image,
                                                size: 16, color: AppTheme.textMuted),
                                      ),
                                    )
                                  : const Icon(LucideIcons.image,
                                      size: 16, color: AppTheme.textMuted),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.sourceItem!.productName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          LucideIcons.moreHorizontal,
                                          size: 16,
                                          color: AppTheme.textSecondary,
                                        ),
                                        itemBuilder: (ctx) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit Item',
                                                style: TextStyle(fontSize: 13)),
                                          ),
                                          const PopupMenuItem(
                                            value: 'details',
                                            child: Text('View Item Details',
                                                style: TextStyle(fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            item.sourceItem = null;
                                            item.descriptionController.clear();
                                            item.rateController.clear();
                                            item.returnQtyController.clear();
                                          });
                                          widget.onChanged();
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(LucideIcons.x,
                                              size: 14, color: AppTheme.textMuted),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Focus(
                                    onFocusChange: (_) => setState(() {}),
                                    child: Builder(
                                      builder: (focusCtx) {
                                        final isFocused =
                                            Focus.of(focusCtx).hasFocus;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 120),
                                          height: 64,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isFocused
                                                  ? const Color(0xFF0088FF)
                                                  : AppTheme.borderLight,
                                              width: isFocused ? 1.5 : 1.0,
                                            ),
                                          ),
                                          child: TextField(
                                            controller: item.descriptionController,
                                            maxLines: null,
                                            expands: true,
                                            textAlignVertical:
                                                TextAlignVertical.top,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textPrimary),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              hintText:
                                                  'Add a description to your item',
                                              hintStyle: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textMuted),
                                              filled: true,
                                              fillColor: Colors.transparent,
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.sourceItem!.type
                                                      .toUpperCase() ==
                                                  'SERVICE'
                                              ? const Color(0xFFF97316)
                                              : const Color(0xFF0088FF),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          item.sourceItem!.type.toUpperCase() ==
                                                  'SERVICE'
                                              ? 'SERVICE'
                                              : 'GOODS',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (item.sourceItem!.hsnCode != null &&
                                          item.sourceItem!.hsnCode!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          item.sourceItem!.type.toUpperCase() ==
                                                  'SERVICE'
                                              ? 'SAC Code: '
                                              : 'HSN Code: ',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary),
                                        ),
                                        const Icon(LucideIcons.pencil,
                                            size: 10, color: Color(0xFF0088FF)),
                                        const SizedBox(width: 3),
                                        Text(
                                          item.sourceItem!.hsnCode!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF0088FF),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          _vLine(),
          // BILLED QTY (Readonly value)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                billedQtyText,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          _vLine(),
          // RETURNED QTY (Readonly value)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                returnedQtyText,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          _vLine(),
          // QTY TO RETURN (Text Field + Select Batch button if qty > 0)
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: item.returnQtyController,
                    height: _PurchaseReturnsCreatePageState._tableFieldHeight,
                    textAlign: TextAlign.right,
                    hintText: '0',
                    hideBorderDefault: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged();
                    },
                  ),
                  if (item.batches.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => widget.onSelectBatch(item),
                      child: Text(
                        _getBatchSummaryText(item.batches),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563EB),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ] else if (qtyToReturnVal > 0) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => widget.onSelectBatch(item),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            LucideIcons.alertTriangle,
                            size: 12,
                            color: AppTheme.errorRed,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Select Batch',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryBlue,
                              decoration: TextDecoration.underline,
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
          _vLine(),
          // RATE
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomTextField(
                    controller: item.rateController,
                    height: _PurchaseReturnsCreatePageState._tableFieldHeight,
                    textAlign: TextAlign.right,
                    hintText: '0.00',
                    hideBorderDefault: true,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged();
                    },
                  ),
                  if (item.sourceItem != null) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {},
                      child: const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _vLine(),
          // TAX
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormDropdown<_PRTaxOption>(
                    value: item.selectedTax == null
                        ? null
                        : taxOptions.firstWhere(
                            (o) => o.label == item.selectedTax,
                            orElse: () => taxOptions.firstWhere(
                              (o) => !o.isHeader,
                              orElse: () => taxOptions[0],
                            ),
                          ),
                    items: taxOptions,
                    hint: 'Select Tax',
                    height: _PurchaseReturnsCreatePageState._tableFieldHeight,
                    menuWidth: 360,
                    hideBorderDefault: true,
                    allowClear: true,
                    displayStringForValue: (o) => o.label,
                    isItemEnabled: (o) => !o.isHeader,
                    itemBuilder: (option, isSelected, isHovered) {
                      if (option.isHeader) {
                        return Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          color: Colors.white,
                          width: double.infinity,
                          child: Text(
                            option.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        );
                      }
                      final isIndented = option.label.startsWith('GST') ||
                          option.label.startsWith('IGST');
                      return Container(
                        padding: EdgeInsets.only(
                          left: isIndented ? 28 : 16,
                          right: 16,
                          top: option.description != null ? 10 : 8,
                          bottom: option.description != null ? 10 : 8,
                        ),
                        color: isHovered ? AppTheme.primaryBlue : Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isHovered
                                          ? Colors.white
                                          : (isSelected
                                              ? AppTheme.primaryBlue
                                              : const Color(0xFF1E293B)),
                                      fontWeight: (isHovered || isSelected)
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 16,
                                    color: isHovered
                                        ? Colors.white
                                        : AppTheme.primaryBlue,
                                  ),
                              ],
                            ),
                            if (option.description != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                option.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isHovered
                                      ? Colors.white70
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    onChanged: (val) {
                      if (val != null && !val.isHeader) {
                        setState(() {
                          item.selectedTax = val.label;
                          item.selectedTaxRate = val.rate;
                          item.selectedTaxId = val.id;
                        });
                        widget.onChanged();
                      } else if (val == null) {
                        setState(() {
                          item.selectedTax = null;
                          item.selectedTaxRate = null;
                          item.selectedTaxId = null;
                        });
                        widget.onChanged();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          _vLine(),
          // AMOUNT
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '₹${_computeAmount(item)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//          Layout helpers

class _MaxWidthContainer extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const _MaxWidthContainer({required this.maxWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class _HeaderBackgroundBand extends StatelessWidget {
  final Widget child;

  const _HeaderBackgroundBand({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = screenWidth < 1000 ? 16.0 : 40.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyWidth = screenWidth - (hPad * 2);
        final rightBleed = (bodyWidth - constraints.maxWidth + hPad)
            .clamp(0.0, double.infinity)
            .toDouble();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: -hPad,
              right: -rightBleed,
              child: const ColoredBox(color: AppTheme.bgDisabled),
            ),
            child,
          ],
        );
      },
    );
  }
}

class _PRNotesAndAttachmentsBand extends StatelessWidget {
  final Widget child;

  const _PRNotesAndAttachmentsBand({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = screenWidth < 1000 ? 16.0 : 40.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyWidth = screenWidth - (hPad * 2);
        final rightBleed = (bodyWidth - constraints.maxWidth + hPad)
            .clamp(0.0, double.infinity)
            .toDouble();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: -hPad,
              right: -rightBleed,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  border: Border.symmetric(
                    horizontal: BorderSide(color: Color(0xFFDBEAFE)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: child,
            ),
          ],
        );
      },
    );
  }
}

class _CompactFormRow extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final double? fieldWidth;
  final Color labelColor;
  final CrossAxisAlignment crossAxisAlignment;

  const _CompactFormRow({
    required this.label,
    this.required = false,
    required this.child,
    this.fieldWidth,
    this.labelColor = AppTheme.textPrimary,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final requested = fieldWidth ?? 434;
        final available = constraints.hasBoundedWidth
            ? constraints.maxWidth - 150 - 16
            : requested;
        final effective = available < requested
            ? (available > 0 ? available : 0.0)
            : requested;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              SizedBox(
                width: 150,
                child: label.isEmpty
                    ? const SizedBox.shrink()
                    : RichText(
                        text: TextSpan(
                          text: label,
                          style: TextStyle(
                            fontSize: 13,
                            color: labelColor,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            if (required)
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  color: labelColor == AppTheme.textPrimary
                                      ? AppTheme.errorRed
                                      : labelColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              SizedBox(width: effective, child: child),
            ],
          ),
        );
      },
    );
  }
}

//          Table header helper

class _TH extends StatelessWidget {
  final String text;
  final bool right;
  final String? tooltip;

  const _TH(this.text, {this.right = false, this.tooltip});

  @override
  Widget build(BuildContext context) {
    Widget content = Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      maxLines: 1,
      softWrap: false,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.4,
      ),
    );
    if (tooltip != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          content,
          const SizedBox(width: 4),
          ZTooltip(
            message: tooltip!,
            child: const Icon(
              LucideIcons.helpCircle,
              size: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      );
    }
    return content;
  }
}

Widget _vLine() =>
    const SizedBox(width: 1, child: ColoredBox(color: AppTheme.borderLight));

//          Row action hover item

class _PRRowActionMenuHoverItem extends StatefulWidget {
  final String label;
  final double width;
  final double height;

  const _PRRowActionMenuHoverItem({
    required this.label,
    required this.width,
    required this.height,
  });

  @override
  State<_PRRowActionMenuHoverItem> createState() =>
      _PRRowActionMenuHoverItemState();
}

class _PRRowActionMenuHoverItemState extends State<_PRRowActionMenuHoverItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _hovered ? AppTheme.primaryBlue : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400,
            color: _hovered ? AppTheme.backgroundColor : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

//          Row action icon button

class _PRRowActionIconButton extends StatefulWidget {
  final IconData icon;

  const _PRRowActionIconButton({required this.icon});

  @override
  State<_PRRowActionIconButton> createState() => _PRRowActionIconButtonState();
}

class _PRRowActionIconButtonState extends State<_PRRowActionIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _hovered ? AppTheme.bgDisabled : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          widget.icon,
          size: 16,
          color: _hovered ? AppTheme.errorRed : AppTheme.textMuted,
        ),
      ),
    );
  }
}

//          Bulk menu hover item

class _PRBulkMenuHoverItem extends StatefulWidget {
  final String label;

  const _PRBulkMenuHoverItem({required this.label});

  @override
  State<_PRBulkMenuHoverItem> createState() => _PRBulkMenuHoverItemState();
}

class _PRBulkMenuHoverItemState extends State<_PRBulkMenuHoverItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        height: 40,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _hovered ? AppTheme.primaryBlue : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            color: _hovered ? AppTheme.backgroundColor : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

//          Tax options

class _PRTaxOption {
  final String label;
  final String? description;
  final bool isHeader;
  final String? id;
  final double? rate;

  const _PRTaxOption({
    required this.label,
    this.description,
    this.isHeader = false,
    this.id,
    this.rate,
  });
}

_PRTaxOption _resolveTaxOptionForProduct(
  Item selected,
  List<_PRTaxOption> taxOptions,
  String? sourceOfSupply,
  String? destinationOfSupply,
) {
  final pref = selected.taxPreference?.toLowerCase() ?? '';
  if (pref == 'non-taxable' || pref == 'non_taxable') {
    return taxOptions.firstWhere(
      (o) => o.label == 'Non-Taxable',
      orElse: () => taxOptions.firstWhere((o) => !o.isHeader, orElse: () => taxOptions[0]),
    );
  }
  if (pref == 'exempt') {
    return taxOptions.firstWhere(
      (o) => o.label == 'Out of Scope',
      orElse: () => taxOptions.firstWhere((o) => !o.isHeader, orElse: () => taxOptions[0]),
    );
  }

  final src = sourceOfSupply?.toLowerCase().trim() ?? '';
  final dest = destinationOfSupply?.toLowerCase().trim() ?? '';
  final isIntra = (src.isEmpty || dest.isEmpty) ? true : (src == dest);
  final targetTaxId = isIntra ? selected.intraStateTaxId : selected.interStateTaxId;

  if (targetTaxId != null && targetTaxId.isNotEmpty) {
    final matchById = taxOptions.where((o) => !o.isHeader && o.id == targetTaxId).firstOrNull;
    if (matchById != null) return matchById;

    final numStr = targetTaxId.replaceAll(RegExp(r'[^0-9.]'), '');
    final numericRate = double.tryParse(numStr);
    if (numericRate != null) {
      final matchByRate = taxOptions.where((o) => !o.isHeader && o.rate == numericRate).firstOrNull;
      if (matchByRate != null) return matchByRate;
    }
  }

  final defaultTaxableRate = taxOptions.firstWhere(
    (o) => !o.isHeader && o.rate != null && o.rate! > 0,
    orElse: () => taxOptions.firstWhere(
      (o) => !o.isHeader && o.label != 'Non-Taxable' && o.label != 'Out of Scope' && o.label != 'Non-GST Supply',
      orElse: () => taxOptions.firstWhere((o) => !o.isHeader, orElse: () => taxOptions[0]),
    ),
  );

  return defaultTaxableRate;
}

List<_PRTaxOption> _buildTaxOptions(
  dynamic itemsState,
  String? sourceOfSupply,
  String? destinationOfSupply,
) {
  final options = <_PRTaxOption>[
    const _PRTaxOption(label: 'Non-Taxable'),
    const _PRTaxOption(
      label: 'Out of Scope',
      description:
          'Supplies on which you don\'t charge any GST or include them in the returns.',
    ),
    const _PRTaxOption(
      label: 'Non-GST Supply',
      description:
          'Supplies which do not come under GST such as petroleum products and liquor.',
    ),
  ];

  final isIntraState = (sourceOfSupply == null ||
          destinationOfSupply == null ||
          sourceOfSupply.isEmpty ||
          destinationOfSupply.isEmpty)
      ? true
      : (sourceOfSupply.toLowerCase().trim() ==
          destinationOfSupply.toLowerCase().trim());

  final taxRates = itemsState?.taxRates ?? [];
  final taxGroups = itemsState?.taxGroups ?? [];

  if (taxRates.isNotEmpty) {
    options.add(const _PRTaxOption(label: 'Tax Rates', isHeader: true));
    for (final tr in taxRates) {
      String rateLabel = tr.taxName;
      if (!rateLabel.contains('[')) {
        final rStr = tr.taxRate % 1 == 0
            ? tr.taxRate.toInt().toString()
            : tr.taxRate.toStringAsFixed(2);
        rateLabel = '${tr.taxName} [$rStr%]';
      }
      options.add(_PRTaxOption(label: rateLabel, id: tr.id, rate: tr.taxRate));
    }
  } else {
    final prefix = isIntraState ? 'GST' : 'IGST';
    options.add(const _PRTaxOption(label: 'Tax Rates', isHeader: true));
    options.add(_PRTaxOption(label: '$prefix 0 [0%]', id: '0', rate: 0));
    options.add(_PRTaxOption(label: '$prefix 5 [5%]', id: '5', rate: 5));
    options.add(_PRTaxOption(label: '$prefix 12 [12%]', id: '12', rate: 12));
    options.add(_PRTaxOption(label: '$prefix 18 [18%]', id: '18', rate: 18));
    options.add(_PRTaxOption(label: '$prefix 28 [28%]', id: '28', rate: 28));
  }

  if (taxGroups.isNotEmpty) {
    options.add(const _PRTaxOption(label: 'Tax Group', isHeader: true));
    for (final dynamic tg in taxGroups) {
      String groupLabel = '';
      double rateVal = 0.0;
      String? tgId;

      if (tg is TaxRate) {
        groupLabel = tg.taxName;
        rateVal = tg.taxRate;
        tgId = tg.id;
      } else if (tg is Map) {
        groupLabel = tg['group_name']?.toString() ?? tg['tax_name']?.toString() ?? '';
        rateVal = double.tryParse(tg['total_rate']?.toString() ?? tg['tax_rate']?.toString() ?? '0') ?? 0.0;
        tgId = tg['id']?.toString();
      } else {
        try {
          groupLabel = (tg as dynamic).groupName ?? (tg as dynamic).taxName ?? '';
          rateVal = (tg as dynamic).totalRate ?? (tg as dynamic).taxRate ?? 0.0;
          tgId = (tg as dynamic).id?.toString();
        } catch (_) {}
      }

      if (groupLabel.isNotEmpty) {
        if (!groupLabel.contains('[')) {
          final rStr = rateVal % 1 == 0
              ? rateVal.toInt().toString()
              : rateVal.toStringAsFixed(2);
          groupLabel = '$groupLabel [$rStr%]';
        }
        options.add(_PRTaxOption(label: groupLabel, id: tgId, rate: rateVal));
      }
    }
  }

  return options;
}

//          Product dropdown item

class _PRProductDropdownItem extends StatelessWidget {
  final String productName;
  final double? costPrice;
  final bool highlighted;

  const _PRProductDropdownItem({
    required this.productName,
    this.costPrice,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    Color text = const Color(0xFF111827);
    Color subtext = const Color(0xFF6B7280);

    if (highlighted) {
      text = Colors.white;
      subtext = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: highlighted ? AppTheme.primaryBlue : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
                    color: text,
                  ),
                ),
                if (costPrice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Purchase Rate: ₹${costPrice!.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: subtext),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────
// Batch Selection Dialog & Helpers

class _BatchRowData {
  String? binLocation;
  String? batchNo;
  String packSize;
  late TextEditingController mrpCtrl;
  late TextEditingController pRateCtrl;
  DateTime? expiryDate;
  late TextEditingController quantityCtrl;

  _BatchRowData({
    this.binLocation,
    this.batchNo,
    this.packSize = 'Pack of 10 Items',
    double mrp = 0.0,
    double pRate = 0.0,
    this.expiryDate,
    String quantity = '0',
  }) {
    mrpCtrl = TextEditingController(text: mrp.toStringAsFixed(0));
    pRateCtrl = TextEditingController(text: pRate.toStringAsFixed(0));
    quantityCtrl = TextEditingController(text: quantity);
  }

  factory _BatchRowData.fromMap(Map<String, dynamic> map) {
    return _BatchRowData(
      binLocation: map['bin_location'] as String?,
      batchNo: map['batch_no'] as String?,
      packSize: map['pack_size'] as String? ?? 'Pack of 10 Items',
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      pRate: (map['p_rate'] as num?)?.toDouble() ?? 0.0,
      expiryDate: map['expiry_date'] as DateTime?,
      quantity: map['quantity']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bin_location': binLocation,
      'batch_no': batchNo,
      'pack_size': packSize,
      'mrp': double.tryParse(mrpCtrl.text) ?? 0.0,
      'p_rate': double.tryParse(pRateCtrl.text) ?? 0.0,
      'expiry_date': expiryDate,
      'quantity': double.tryParse(quantityCtrl.text) ?? 0.0,
    };
  }
}

class _AddBatchDialog extends ConsumerStatefulWidget {
  final String itemName;
  final String productId;
  final double totalQuantity;
  final String warehouseName;
  final String warehouseId;
  final List<Map<String, dynamic>> initialBatches;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const _AddBatchDialog({
    required this.itemName,
    required this.productId,
    required this.totalQuantity,
    required this.warehouseName,
    required this.warehouseId,
    required this.initialBatches,
    required this.onSave,
  });

  @override
  ConsumerState<_AddBatchDialog> createState() => _AddBatchDialogState();
}

class _AddBatchDialogState extends ConsumerState<_AddBatchDialog> {
  late List<_BatchRowData> _rows;
  bool _overwriteLineItem = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBatches.isNotEmpty) {
      _rows = widget.initialBatches
          .map((b) => _BatchRowData.fromMap(b))
          .toList();
    } else {
      _rows = [
        _BatchRowData(
          quantity: widget.totalQuantity % 1 == 0
              ? widget.totalQuantity.toInt().toString()
              : widget.totalQuantity.toStringAsFixed(2),
        ),
      ];
    }
  }

  double get _quantityToBeAdded {
    return _rows.fold(
      0.0,
      (sum, r) => sum + (double.tryParse(r.quantityCtrl.text) ?? 0.0),
    );
  }

  void _addRow() {
    setState(() {
      _rows.add(_BatchRowData());
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        _rows.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch bins for warehouse
    final binsAsync = ref.watch(binsLookupProvider(widget.warehouseId));
    final loadedBins = binsAsync.valueOrNull ?? [];
    List<String> binOptions = loadedBins
        .map((b) => b['bin_code'] ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
    if (binOptions.isEmpty) {
      binOptions = const ['Default Bin', 'Bin A-1', 'Bin B-2', 'test 1 central5-te...'];
    }

    // 2. Fetch batches for product
    final batchesAsync = ref.watch(batchLookupProvider(widget.productId));
    final allProductBatches = batchesAsync.valueOrNull ?? [];

    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      child: Container(
        width: 1080,
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Add Batch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
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
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            // Location
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.home, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Location : ${widget.warehouseName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            // Batch Details Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text(
                    'BATCH DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Item: ${widget.itemName}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Total Quantity : ${widget.totalQuantity % 1 == 0 ? widget.totalQuantity.toInt() : widget.totalQuantity} | Quantity to be added : ${_quantityToBeAdded % 1 == 0 ? _quantityToBeAdded.toInt() : _quantityToBeAdded}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Checkbox overwrite
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: _overwriteLineItem,
                      onChanged: (val) => setState(() => _overwriteLineItem = val ?? false),
                      activeColor: AppTheme.successGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overwrite the line item with ${widget.totalQuantity % 1 == 0 ? widget.totalQuantity.toInt() : widget.totalQuantity} quantities',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Table
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      color: const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: const [
                          Expanded(flex: 3, child: Text('BIN LOCATION*', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorRed))),
                          Expanded(flex: 3, child: Text('BATCH NO*', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorRed))),
                          Expanded(flex: 4, child: Text('PACK SIZE*', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorRed))),
                          Expanded(flex: 2, child: Text('MRP*', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorRed))),
                          Expanded(flex: 2, child: Text('P RATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary))),
                          Expanded(flex: 3, child: Text('EXPIRY DATE*', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorRed))),
                          Expanded(flex: 2, child: Text('QUANTITY*', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorRed))),
                          SizedBox(width: 32),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    // Table Rows
                    for (int i = 0; i < _rows.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            // Bin Location
                            Expanded(
                              flex: 3,
                              child: FormDropdown<String>(
                                value: _rows[i].binLocation,
                                items: binOptions,
                                hint: 'Select Bin',
                                height: 36,
                                onChanged: (v) {
                                  setState(() {
                                    _rows[i].binLocation = v;
                                    _rows[i].batchNo = null;
                                    _rows[i].mrpCtrl.text = '0';
                                    _rows[i].pRateCtrl.text = '0';
                                    _rows[i].expiryDate = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Batch No
                            Expanded(
                              flex: 3,
                              child: Builder(
                                builder: (context) {
                                  final hasSelectedBin = _rows[i].binLocation != null && _rows[i].binLocation!.isNotEmpty;
                                  final selectedBin = _rows[i].binLocation?.toLowerCase() ?? '';

                                  List<Map<String, dynamic>> matchingBatches = [];
                                  if (hasSelectedBin) {
                                    matchingBatches = allProductBatches.where((b) {
                                      final binIds = b['bin_ids'] is Set
                                          ? b['bin_ids'] as Set
                                          : (b['bin_ids'] is Iterable ? (b['bin_ids'] as Iterable).toSet() : <String>{});
                                      final binCodes = b['bin_codes'] is Set
                                          ? b['bin_codes'] as Set
                                          : (b['bin_codes'] is Iterable ? (b['bin_codes'] as Iterable).toSet() : <String>{});
                                      final singleCode = (b['bin_code'] ?? b['binCode'] ?? '').toString().toLowerCase();

                                      return binCodes.contains(selectedBin) ||
                                             binIds.contains(_rows[i].binLocation) ||
                                             singleCode == selectedBin ||
                                             (binCodes.isEmpty && binIds.isEmpty && singleCode.isEmpty);
                                    }).toList();

                                    if (matchingBatches.isEmpty) {
                                      matchingBatches = allProductBatches;
                                    }
                                  }

                                  final selectedBatchObj = matchingBatches.firstWhere(
                                    (b) => (b['batch_no'] ?? b['batchNo'])?.toString().trim() == _rows[i].batchNo?.trim(),
                                    orElse: () => <String, dynamic>{},
                                  );

                                  return FormDropdown<Map<String, dynamic>>(
                                    enabled: hasSelectedBin,
                                    value: selectedBatchObj.isEmpty ? null : selectedBatchObj,
                                    items: matchingBatches,
                                    hint: 'Select Batch',
                                    height: 36,
                                    showSearch: true,
                                    menuMaxHeight: 350,
                                    menuWidth: 320,
                                    searchStringForValue: (item) => (item['batch_no'] ?? item['batchNo'] ?? '').toString(),
                                    displayStringForValue: (item) => (item['batch_no'] ?? item['batchNo'] ?? '').toString(),
                                    itemBuilder: (item, isSelected, isHovered) {
                                      final batchNo = item['batch_no'] ?? item['batchNo'] ?? '-';
                                      final balance = item['balance']?.toString() ?? '0';
                                      final expDate = item['expiry_date']?.toString() ?? item['expiryDate']?.toString() ?? '-';
                                      final mrp = item['mrp']?.toString() ?? '0';
                                      final ptr = item['ptr']?.toString() ?? item['prate']?.toString() ?? '0';

                                      final displayText = '$batchNo | Bal: $balance | Exp: $expDate | MRP: $mrp | prate: $ptr';

                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        color: isHovered
                                            ? const Color(0xFF3B82F6)
                                            : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
                                        child: Text(
                                          displayText,
                                          softWrap: true,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isHovered ? Colors.white : AppTheme.textPrimary,
                                          ),
                                        ),
                                      );
                                    },
                                    onChanged: (selectedMap) {
                                      if (selectedMap == null) return;
                                      setState(() {
                                        final bNo = (selectedMap['batch_no'] ?? selectedMap['batchNo'])?.toString();
                                        _rows[i].batchNo = bNo;
                                        
                                        final mrpVal = selectedMap['mrp'];
                                        if (mrpVal != null) {
                                          _rows[i].mrpCtrl.text = (mrpVal is num)
                                              ? mrpVal.toStringAsFixed(0)
                                              : mrpVal.toString();
                                        }

                                        final ptrVal = selectedMap['ptr'] ?? selectedMap['prate'];
                                        if (ptrVal != null) {
                                          _rows[i].pRateCtrl.text = (ptrVal is num)
                                              ? ptrVal.toStringAsFixed(0)
                                              : ptrVal.toString();
                                        }

                                        final expVal = selectedMap['expiry_date'] ?? selectedMap['expiryDate'];
                                        if (expVal != null) {
                                          if (expVal is DateTime) {
                                            _rows[i].expiryDate = expVal;
                                          } else if (expVal is String && expVal.isNotEmpty) {
                                            _rows[i].expiryDate = DateTime.tryParse(expVal);
                                          }
                                        }

                                        if (selectedMap['pack_size'] != null && selectedMap['pack_size'].toString().isNotEmpty) {
                                          _rows[i].packSize = selectedMap['pack_size'].toString();
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Pack Size
                            Expanded(
                              flex: 4,
                              child: CustomTextField(
                                controller: TextEditingController(text: _rows[i].packSize),
                                readOnly: true,
                                height: 36,
                                hideBorderDefault: false,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // MRP
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: _rows[i].mrpCtrl,
                                height: 36,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // P Rate
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: _rows[i].pRateCtrl,
                                height: 36,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Expiry Date
                            Expanded(
                              flex: 3,
                              child: Builder(
                                builder: (btnCtx) {
                                  final key = GlobalKey();
                                  final dStr = _rows[i].expiryDate == null
                                      ? ''
                                      : "${_rows[i].expiryDate!.day.toString().padLeft(2, '0')}/${_rows[i].expiryDate!.month.toString().padLeft(2, '0')}/${_rows[i].expiryDate!.year}";
                                  return InkWell(
                                    key: key,
                                    onTap: () async {
                                      final d = await ZerpaiDatePicker.show(
                                        btnCtx,
                                        initialDate: _rows[i].expiryDate ?? DateTime.now(),
                                        targetKey: key,
                                      );
                                      if (d != null) setState(() => _rows[i].expiryDate = d);
                                    },
                                    child: IgnorePointer(
                                      child: CustomTextField(
                                        controller: TextEditingController(text: dStr),
                                        hintText: 'dd/mm/yyyy',
                                        height: 36,
                                        suffixWidget: const Icon(LucideIcons.calendar, size: 14, color: AppTheme.textSecondary),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Quantity
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: _rows[i].quantityCtrl,
                                height: 36,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete row button
                            InkWell(
                              onTap: () => _removeRow(i),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(LucideIcons.xCircle, size: 18, color: AppTheme.errorRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < _rows.length - 1)
                        const Divider(height: 1, color: AppTheme.borderLight),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // New Row Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: InkWell(
                onTap: _addRow,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.plus, size: 14, color: AppTheme.primaryBlue),
                    SizedBox(width: 4),
                    Text(
                      'New Row',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppTheme.borderLight),
            // Bottom Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: () {
                      widget.onSave(_rows.map((r) => r.toMap()).toList());
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 12),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
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

class _ConfigureTaxPreferencesDialog extends StatefulWidget {
  final String initialTreatment;
  final String initialGstin;
  final Function(String, String, bool) onUpdate;
  final VoidCallback onCancel;

  const _ConfigureTaxPreferencesDialog({
    required this.initialTreatment,
    required this.initialGstin,
    required this.onUpdate,
    required this.onCancel,
  });

  @override
  State<_ConfigureTaxPreferencesDialog> createState() =>
      _ConfigureTaxPreferencesDialogState();
}

class _ConfigureTaxPreferencesDialogState
    extends State<_ConfigureTaxPreferencesDialog> {
  late String _selectedTreatment;
  late TextEditingController _gstinCtrl;
  bool _makePermanent = false;

  final List<Map<String, String>> _treatments = [
    {
      'label': 'Registered Business - Regular',
      'desc': 'Business that is registered under GST',
    },
    {
      'label': 'Registered Business - Composition',
      'desc': 'Business that is registered under the Composition Scheme in GST',
    },
    {
      'label': 'Unregistered Business',
      'desc': 'Business that has not been registered under GST',
    },
    {
      'label': 'Consumer',
      'desc':
          'Individual or business that is not registered and consumes goods/services',
    },
    {'label': 'Overseas', 'desc': 'Business located outside India'},
    {
      'label': 'Special Economic Zone (SEZ)',
      'desc': 'Business located in a SEZ unit or developer',
    },
    {
      'label': 'Deemed Export',
      'desc':
          'Business involved in supply of goods to certain notified purposes',
    },
  ];

  bool get _isRegistered {
    return _selectedTreatment == 'Registered Business - Regular' ||
        _selectedTreatment == 'Registered Business - Composition' ||
        _selectedTreatment == 'Special Economic Zone (SEZ)' ||
        _selectedTreatment == 'Deemed Export';
  }

  @override
  void initState() {
    super.initState();
    _selectedTreatment = widget.initialTreatment;
    _gstinCtrl = TextEditingController(text: widget.initialGstin);
  }

  @override
  void dispose() {
    _gstinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CustomPaint(
            size: const Size(14, 8),
            painter: _TrianglePainter(
              color: Colors.white,
              isUp: true,
              hasBorder: true,
            ),
          ),
        ),
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDDDDD)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Configure Tax Preferences',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancel,
                      child: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GST Treatment',
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    ),
                    const SizedBox(height: 8),
                    FormDropdown<Map<String, String>>(
                      height: 32,
                      value: _treatments.firstWhere(
                        (t) => t['label'] == _selectedTreatment,
                        orElse: () => _treatments[2],
                      ),
                      items: _treatments,
                      showSearch: false,
                      fillColor: Colors.white,
                      displayStringForValue: (v) => v['label']!,
                      itemBuilder: (item, isSelected, isHovered) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          color: isHovered
                              ? const Color(0xFF3B82F6)
                              : (isSelected
                                    ? const Color(0xFFF3F4F6)
                                    : Colors.transparent),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isHovered
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['desc']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isHovered
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTreatment = val['label']!;
                          });
                        }
                      },
                    ),
                    if (_isRegistered) ...[
                      const SizedBox(height: 20),
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'GSTIN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.redAccent,
                                fontFamily: 'Inter',
                              ),
                            ),
                            TextSpan(
                              text: '*',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: CustomTextField(
                          controller: _gstinCtrl,
                          hintText: 'Enter GSTIN',
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Get Taxpayer details',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Make it permanent?',
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _makePermanent,
                            onChanged: (val) =>
                                setState(() => _makePermanent = val!),
                            activeColor: const Color(0xFF22C55E),
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Use these settings for all future transactions of this vendor.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          widget.onUpdate(_selectedTreatment, _gstinCtrl.text.trim(), _makePermanent),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF19A05E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF333333)),
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
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool isUp;
  final bool hasBorder;
  _TrianglePainter({
    required this.color,
    this.isUp = false,
    this.hasBorder = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (isUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width / 2, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);

    if (hasBorder) {
      final borderPaint = Paint()
        ..color = const Color(0xFFDDDDDD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
