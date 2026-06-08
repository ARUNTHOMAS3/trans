// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/advanced_customer_search_modal.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/warehouse_change_confirm_dialog.dart';
import 'package:intl/intl.dart';

/// Data passed when opening the create page in edit mode.
class SalesReturnEditData {
  const SalesReturnEditData({
    required this.id,
    required this.rmaNumber,
    required this.customerName,
    required this.referenceNumber,
    required this.date,
    required this.creditOnlyGoods,
    required this.items,
    this.warehouseName,
    this.warehouseId,
    this.reason,
    this.status,
  });

  final String id;
  final String rmaNumber;
  final String customerName;
  final String referenceNumber;
  final String date;
  final bool creditOnlyGoods;
  final List<SalesReturnEditItem> items;
  final String? warehouseName;
  final String? warehouseId;
  final String? reason;
  final String? status;
}

class SalesReturnEditItem {
  const SalesReturnEditItem({
    required this.name,
    required this.returnQty,
    this.productId,
    this.rate = '0.00',
    this.shipped = '0',
    this.returned = '0',
    this.hsnCode = '',
    this.description = '',
    this.creditOnlyQty = '',
  });

  final String name;
  final String returnQty;
  final String? productId;
  final String rate;
  final String shipped;
  final String returned;
  final String hsnCode;
  final String description;
  final String creditOnlyQty;
}

/// Sales Return Add / Edit Page
class SalesReturnsCreatePage extends ConsumerStatefulWidget {
  const SalesReturnsCreatePage({super.key, this.editData});

  final SalesReturnEditData? editData;

  @override
  ConsumerState<SalesReturnsCreatePage> createState() =>
      _SalesReturnsCreatePageState();
}

class _SalesReturnsCreatePageState extends ConsumerState<SalesReturnsCreatePage> {
  static const double _tableFieldHeight = 44;
  static const String _rmaSequenceModule = 'rma';
  // --- Form State ---
  String? _selectedCustomer;
  late final TextEditingController _referenceNumberController;

  late final TextEditingController _rmaNumberController;
  late final TextEditingController _rmaDateController;
  final _rmaDateKey = GlobalKey();
  DateTime _rmaDate = DateTime.now();
  late final TextEditingController _rmaReasonController;
  bool _creditOnlyGoods = false;

  String _warehouseLocation = '';

  bool _rmaAutoGenerate = true;
  late final TextEditingController _rmaPrefixController;
  late final TextEditingController _rmaNextNumberController;
  final LookupsApiService _lookupsApiService = LookupsApiService();

  bool _showItemDetailsPanel = false;
  _SalesReturnItem? _detailsItem;
  bool _isSubmitting = false;
  String? _submittingStatus;

  static const double _rowMaxWidth = 1100.0;
  static const double _fieldHeight = 32.0;

  final List<_SalesReturnItem> _items = [];

  String _customerDisplayLabel(dynamic customer) {
    final display = (customer.displayName ?? '').toString().trim();
    if (display.isNotEmpty) return display;
    final company = (customer.companyName ?? '').toString().trim();
    if (company.isNotEmpty) return company;
    final fullName =
        '${(customer.firstName ?? '').toString().trim()} ${(customer.lastName ?? '').toString().trim()}'
            .trim();
    if (fullName.isNotEmpty) return fullName;
    return (customer.customerNumber ?? '').toString().trim();
  }

  bool get _isEditMode => widget.editData != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editData;

    _referenceNumberController = TextEditingController(
      text: edit != null && edit.referenceNumber != '-' ? edit.referenceNumber : '',
    );
    _rmaNumberController = TextEditingController(
      text: edit?.rmaNumber ?? '',
    );

    if (edit != null && edit.date.isNotEmpty && edit.date != '-') {
      final parsed = DateFormat('dd-MM-yyyy').tryParse(edit.date) ??
          DateFormat('yyyy-MM-dd').tryParse(edit.date);
      if (parsed != null) {
        _rmaDate = parsed;
      }
    }
    _rmaDateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(_rmaDate),
    );
    _rmaReasonController = TextEditingController(
      text: edit?.reason ?? '',
    );
    _rmaPrefixController = TextEditingController();
    _rmaNextNumberController = TextEditingController();

    if (edit != null) {
      _selectedCustomer = edit.customerName;
      _creditOnlyGoods = edit.creditOnlyGoods;
      if (edit.warehouseName != null) _warehouseLocation = edit.warehouseName!;

      _items.clear();
      for (final item in edit.items) {
        final srItem = _SalesReturnItem(
          name: item.name,
          description: item.description,
          shipped: item.shipped,
          returned: item.returned,
          returnQty: item.returnQty,
          creditOnlyQty: item.creditOnlyQty,
          stock: '0 pcs',
          rate: item.rate,
        );
        srItem.hsnCode = item.hsnCode;
        _items.add(srItem);
      }
      if (_items.isEmpty) _addItem();
    } else {
      _items.clear();
      _addItem();
      _loadRmaSequenceSettings();
    }
  }

  String _formatSequenceNumber({
    required String prefix,
    required int nextNumber,
    required int padding,
    String suffix = '',
  }) {
    final padCount = padding < 0 ? 0 : padding;
    final numberPart = nextNumber.toString().padLeft(padCount, '0');
    return '$prefix$numberPart$suffix';
  }

  Future<void> _loadRmaSequenceSettings() async {
    final settings = await _lookupsApiService.getSequenceSettings(
      _rmaSequenceModule,
    );
    if (!mounted || settings == null) return;

    final rawPrefix = (settings['prefix'] ?? '').toString().trim();
    final prefix = (rawPrefix.isEmpty || rawPrefix == 'SALES_RETURN-')
        ? 'RMA-'
        : rawPrefix;
    final suffix = (settings['suffix'] ?? '').toString();
    final nextNumber = (settings['next_number'] as num?)?.toInt() ?? 1;
    final padding = (settings['padding'] as num?)?.toInt() ?? 0;
    final autoGenerateRaw = settings['auto_generate'];
    final autoGenerate = autoGenerateRaw is bool ? autoGenerateRaw : true;
    final formatted = _formatSequenceNumber(
      prefix: prefix,
      nextNumber: nextNumber,
      padding: padding,
      suffix: suffix,
    );

    setState(() {
      _rmaAutoGenerate = autoGenerate;
      _rmaPrefixController.text = prefix;
      _rmaNextNumberController.text = nextNumber.toString();
      if (_rmaAutoGenerate) {
        _rmaNumberController.text = formatted;
      }
    });

    if (prefix != rawPrefix) {
      await _lookupsApiService.updateSequenceSettings(
        _rmaSequenceModule,
        <String, dynamic>{
          'prefix': prefix,
          'nextNumber': nextNumber,
          'auto_generate': autoGenerate,
        },
      );
    }
  }

  void _addItem() {
    setState(() {
      _items.add(
        _SalesReturnItem(
          name: '',
          shipped: '0',
          returned: '0',
          returnQty: '',
          stock: '0 pcs',
          rate: '0.00',
        ),
      );
    });
  }

  void _removeItem(int index) {
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
            _items.removeWhere((item) => item.name.isEmpty);
            for (final entry in selectedWithQty.entries) {
              _items.add(
                _SalesReturnItem(
                  name: entry.key.productName,
                  shipped: '0',
                  returned: '0',
                  returnQty: entry.value.toString(),
                  stock: '0',
                ),
              );
            }
            if (_items.isEmpty) _addItem();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _referenceNumberController.dispose();
    _rmaNumberController.dispose();
    _rmaDateController.dispose();
    _rmaReasonController.dispose();
    _rmaPrefixController.dispose();
    _rmaNextNumberController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _updateRmaDate(DateTime date) {
    setState(() {
      _rmaDate = date;
      _rmaDateController.text = DateFormat('dd-MM-yyyy').format(date);
    });
  }

  void _openItemDetails(_SalesReturnItem item) {
    setState(() {
      _showItemDetailsPanel = true;
      _detailsItem = item;
    });
  }

  bool _hasLineEntryInProgress() {
    return _items.any((item) {
      final hasItem = item.name.trim().isNotEmpty;
      final returnQty =
          double.tryParse(item.returnQtyController.text.trim()) ?? 0;
      final creditOnlyQty =
          double.tryParse(item.creditOnlyQtyController.text.trim()) ?? 0;
      final hasReturnQty = returnQty > 0;
      final hasCreditOnlyQty = creditOnlyQty > 0;
      return hasItem || hasReturnQty || hasCreditOnlyQty;
    });
  }

  Future<void> _handleWarehouseChange(String nextWarehouse) async {
    final current = _warehouseLocation.trim();
    if (current == nextWarehouse.trim()) return;

    if (current.isNotEmpty && _hasLineEntryInProgress()) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (_) =>
            WarehouseChangeConfirmDialog(warehouseName: nextWarehouse),
      );
      if (shouldProceed != true) return;
    }

    if (!mounted) return;
    setState(() => _warehouseLocation = nextWarehouse);
  }

  void _setWarehouseWithoutWarning(String nextWarehouse) {
    final normalized = nextWarehouse.trim();
    if (normalized.isEmpty || normalized == _warehouseLocation.trim()) return;
    setState(() => _warehouseLocation = normalized);
  }

  void _goToSalesReturnsList() {
    if (!mounted) return;
    context.go(AppRoutes.salesReturns);
  }

  void _ensureDefaultWarehouseSelected(List<String> warehouseNames) {
    if (_warehouseLocation.trim().isNotEmpty || warehouseNames.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _warehouseLocation.trim().isNotEmpty) return;
      setState(() => _warehouseLocation = warehouseNames.first);
    });
  }

  Future<void> _showRmaPreferencesDialog() async {
    await _loadRmaSequenceSettings();
    final selectedEntityName = ref.read(entityProvider).name?.trim();
    final signedInOrgName = ref.read(authUserProvider)?.orgName.trim();
    final activeBranchName =
        (selectedEntityName != null && selectedEntityName.isNotEmpty)
        ? selectedEntityName
        : (signedInOrgName != null && signedInOrgName.isNotEmpty)
        ? signedInOrgName
        : 'Select Branch';
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RMA Preferences',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Material(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: _RmaPreferencesDialog(
              prefix: _rmaPrefixController.text,
              nextNumber: _rmaNextNumberController.text,
              autoGenerate: _rmaAutoGenerate,
              branchLabel: activeBranchName,
              onSave: (prefix, nextNumber, autoGenerate) async {
                final parsedNext = int.tryParse(nextNumber.trim()) ?? 1;
                final currentSettings =
                    await _lookupsApiService.getSequenceSettings(
                      _rmaSequenceModule,
                    ) ??
                    <String, dynamic>{};
                final padding =
                    (currentSettings['padding'] as num?)?.toInt() ?? 0;
                final suffix = (currentSettings['suffix'] ?? '').toString();

                await _lookupsApiService.updateSequenceSettings(
                  _rmaSequenceModule,
                  <String, dynamic>{
                    'prefix': prefix.trim(),
                    'nextNumber': parsedNext,
                    'auto_generate': autoGenerate,
                  },
                );

                setState(() {
                  _rmaAutoGenerate = autoGenerate;
                  _rmaPrefixController.text = prefix.trim();
                  _rmaNextNumberController.text = parsedNext.toString();
                  if (_rmaAutoGenerate) {
                    _rmaNumberController.text = _formatSequenceNumber(
                      prefix: prefix.trim(),
                      nextNumber: parsedNext,
                      padding: padding,
                      suffix: suffix,
                    );
                  }
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitSalesReturn({
    required String status,
    required List<dynamic> customers,
    required List<Warehouse> warehouses,
    required List<Item> availableItems,
  }) async {
    if (_isSubmitting) return;

    final customerName = _selectedCustomer?.trim() ?? '';
    if (customerName.isEmpty) {
      ZerpaiToast.error(context, 'Customer is required');
      return;
    }

    dynamic selectedCustomer;
    for (final customer in customers) {
      final displayName = _customerDisplayLabel(customer);
      if (displayName == customerName) {
        selectedCustomer = customer;
        break;
      }
    }
    final customerId = selectedCustomer == null
        ? null
        : (selectedCustomer.id?.toString() ?? '').trim();
    if (customerId == null || customerId.isEmpty) {
      ZerpaiToast.error(context, 'Selected customer is invalid');
      return;
    }

    final rmaNumber = _rmaNumberController.text.trim();
    if (rmaNumber.isEmpty) {
      ZerpaiToast.error(context, 'RMA number is required');
      return;
    }

    final warehouseName = _warehouseLocation.trim();
    if (warehouseName.isEmpty) {
      ZerpaiToast.error(context, 'Warehouse is required');
      return;
    }

    final selectedWarehouse = warehouses
        .where((warehouse) => warehouse.name.trim() == warehouseName)
        .cast<Warehouse?>()
        .firstWhere((warehouse) => warehouse != null, orElse: () => null);
    final warehouseId = selectedWarehouse?.id.trim();
    if (warehouseId == null || warehouseId.isEmpty) {
      ZerpaiToast.error(context, 'Selected warehouse is invalid');
      return;
    }

    double parseNum(String value) => double.tryParse(value.trim()) ?? 0;

    final itemPayload = <Map<String, dynamic>>[];
    for (final row in _items) {
      if (row.name.trim().isEmpty) continue;
      final resolvedItem =
          row.selectedItem ??
          availableItems
              .where((item) => item.productName.trim() == row.name.trim())
              .cast<Item?>()
              .firstWhere((item) => item != null, orElse: () => null);
      final productId = resolvedItem?.id?.trim();
      if (productId == null || productId.isEmpty) continue;

      itemPayload.add({
        'product_id': productId,
        'invoiced_qty': parseNum(row.shipped),
        'already_returned_qty': parseNum(row.returned),
        'return_qty': parseNum(row.returnQtyController.text),
        'receivable_qty': parseNum(row.returnQtyController.text),
        'credit_only_qty': parseNum(row.creditOnlyQtyController.text),
        'remarks': row.descriptionController.text.trim().isEmpty
            ? null
            : row.descriptionController.text.trim(),
      });
    }

    if (itemPayload.isEmpty) {
      ZerpaiToast.error(context, 'Add at least one valid item');
      return;
    }

    final payload = {
      'customer_id': customerId,
      'rma_number': rmaNumber,
      'return_date': DateFormat('yyyy-MM-dd').format(_rmaDate),
      'warehouse_id': warehouseId,
      'reason': _rmaReasonController.text.trim().isEmpty
          ? null
          : _rmaReasonController.text.trim(),
      'reference_number': _referenceNumberController.text.trim().isEmpty
          ? null
          : _referenceNumberController.text.trim(),
      'contains_credit_only_goods': _creditOnlyGoods,
      'status': status,
      'items': itemPayload,
    };

    setState(() {
      _isSubmitting = true;
      _submittingStatus = status;
    });
    try {
      final api = ref.read(apiClientProvider);
      if (_isEditMode) {
        await api.put('sales/returns/${widget.editData!.id}', data: payload);
      } else {
        await api.post('sales/returns', data: payload);
        if (_rmaAutoGenerate) await _loadRmaSequenceSettings();
      }
      if (!mounted) return;
      ZerpaiToast.success(
        context,
        _isEditMode
            ? 'Sales return updated successfully'
            : status == 'approved'
                ? 'Sales return saved and approved'
                : 'Sales return saved as draft',
      );
      _goToSalesReturnsList();
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to save sales return');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submittingStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final warehouseList = ref.watch(warehousesProvider).value ?? <Warehouse>[];
    final availableItems = ref.watch(itemsControllerProvider).items;
    final customerNames =
        customersAsync.asData?.value
            .map((customer) => _customerDisplayLabel(customer))
            .where((name) => name.trim().isNotEmpty)
            .toList() ??
        <String>[];
    final warehouseNames = warehouseList
        .map((warehouse) => warehouse.name)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    _ensureDefaultWarehouseSelected(warehouseNames);
    final selectedWarehouse = warehouseNames.contains(_warehouseLocation)
        ? _warehouseLocation
        : (warehouseNames.isNotEmpty ? warehouseNames.first : '');
    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: ZerpaiLayout(
            pageTitle: _isEditMode ? 'Edit Sales Return' : 'New Sales Return',
            enableBodyScroll: true,
            onSave: () {
              // Implementation for saving
            },
            useHorizontalPadding: true,
            footer: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: MaxWidthContainer(
                maxWidth: _rowMaxWidth,
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitSalesReturn(
                                  status: 'draft',
                                  customers:
                                      customersAsync.asData?.value ?? const [],
                                  warehouses: warehouseList,
                                  availableItems: availableItems,
                                ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                          child: (_isSubmitting && _submittingStatus == 'draft')
                              ? Skeletonizer(
                                  enabled: true,
                                  child: const Text(
                                    'Save as Draft',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textBody,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Save as Draft',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textBody,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 190,
                      child: ZButton.primary(
                        label: 'Save and Approve',
                        loading:
                            _isSubmitting && _submittingStatus == 'approved',
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitSalesReturn(
                                status: 'approved',
                                customers:
                                    customersAsync.asData?.value ?? const [],
                                warehouses: warehouseList,
                                availableItems: availableItems,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: _goToSalesReturnsList,
                    ),
                  ],
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: MaxWidthContainer(
                maxWidth: _rowMaxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // --- Header Fields ---
                    _CompactFormRow(
                      label: 'Customer Name',
                      required: true,
                      fieldWidth: 450,
                      child: Row(
                        children: [
                          Expanded(
                            child: FormDropdown<String>(
                              value: _selectedCustomer,
                              items: customerNames,
                              hint: customersAsync.isLoading
                                  ? 'Loading customers...'
                                  : 'Select or add a customer',
                              height: _fieldHeight,
                              showRightBorder: false,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              ),
                              onChanged: (val) =>
                                  setState(() => _selectedCustomer = val),
                            ),
                          ),
                          Container(
                            width: _fieldHeight,
                            height: _fieldHeight,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
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
                                final result =
                                    await AdvancedCustomerSearchModal.show(
                                      context,
                                    );
                                if (result != null) {
                                  setState(() {
                                    _selectedCustomer = result;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CompactFormRow(
                      label: 'Reason',
                      fieldWidth: 330,
                      child: CustomTextField(
                        controller: _rmaReasonController,
                        hintText: 'Type a reason',
                        height: _fieldHeight,
                        contentCase: ContentCase.sentence,
                      ),
                    ),
                    _CompactFormRow(
                      label: 'Reference#',
                      fieldWidth: 330,
                      child: CustomTextField(
                        controller: _referenceNumberController,
                        hintText: 'Enter reference number',
                        height: _fieldHeight,
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: AppTheme.borderLight),
                    ),

                    // --- RMA Section ---
                    _CompactFormRow(
                      label: 'RMA#',
                      required: true,
                      fieldWidth: 330,
                      child: CustomTextField(
                        controller: _rmaNumberController,
                        suffixWidget: GestureDetector(
                          onTap: _showRmaPreferencesDialog,
                          child: const Icon(
                            LucideIcons.settings,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        height: _fieldHeight,
                      ),
                    ),
                    _CompactFormRow(
                      label: 'Date',
                      required: true,
                      fieldWidth: 330,
                      child: CustomTextField(
                        key: _rmaDateKey,
                        controller: _rmaDateController,
                        readOnly: true,
                        onTap: () async {
                          final picked = await ZerpaiDatePicker.show(
                            context,
                            initialDate: _rmaDate,
                            targetKey: _rmaDateKey,
                          );
                          if (picked != null) _updateRmaDate(picked);
                        },
                        suffixWidget: const Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        height: _fieldHeight,
                      ),
                    ),
                    _CompactFormRow(
                      label: '',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _creditOnlyGoods,
                                  onChanged: (val) => setState(
                                    () => _creditOnlyGoods = val ?? false,
                                  ),
                                  activeColor: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'This sales return contains credit-only goods',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 32),
                            child: ZTooltip(
                              message:
                                  'Enable this if returned items are damaged or expired. Quantities entered here are not added back to stock.',
                              child: Icon(
                                LucideIcons.helpCircle,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- Item Table Toolbar ---
                    _ItemTableToolbar(
                      warehouseLocation: selectedWarehouse.isEmpty
                          ? null
                          : selectedWarehouse,
                      warehouseOptions: warehouseNames,
                      onWarehouseChanged: (value) {
                        _handleWarehouseChange(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- Items Grid ---
                    _SalesReturnItemsGrid(
                      items: _items,
                      creditOnly: _creditOnlyGoods,
                      warehouse: selectedWarehouse,
                      warehouseOptions: warehouseNames,
                      availableItems: availableItems,
                      onRemoveItem: _removeItem,
                      onAddItem: _addItem,
                      onAddBulkItems: _showBulkItemsDialog,
                      onWarehouseSelected: (value) {
                        _setWarehouseWithoutWarning(value);
                      },
                      onItemSelected: (index) {
                        if (index == _items.length - 1) {
                          _addItem();
                        }
                      },
                      onViewItemDetails: _openItemDetails,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showItemDetailsPanel && _detailsItem != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 380,
            child: _ItemDetailsSidePanel(
              item: _detailsItem!,
              onClose: () => setState(() {
                _showItemDetailsPanel = false;
                _detailsItem = null;
              }),
            ),
          ),
      ],
    );
  }
}

class _SalesReturnItem {
  String name;
  String description;
  String shipped;
  String returned;
  TextEditingController returnQtyController;
  TextEditingController creditOnlyQtyController;
  TextEditingController descriptionController;
  TextEditingController rateController;
  TextEditingController discountController;
  bool discountIsPercent = false;
  String stock;
  String hsnCode = '';
  Item? selectedItem;
  String? discount;
  String? reportingTag;
  String? account;
  String? tax;
  Map<String, String?> selectedTagValues = {};

  _SalesReturnItem({
    required this.name,
    this.description = '',
    required this.shipped,
    required this.returned,
    required String returnQty,
    String creditOnlyQty = '',
    required this.stock,
    String rate = '0.00',
    String discountValue = '0',
  }) : returnQtyController = TextEditingController(text: returnQty),
       creditOnlyQtyController = TextEditingController(text: creditOnlyQty),
       descriptionController = TextEditingController(text: description),
       rateController = TextEditingController(text: rate),
       discountController = TextEditingController(text: discountValue);

  void dispose() {
    returnQtyController.dispose();
    creditOnlyQtyController.dispose();
    descriptionController.dispose();
    rateController.dispose();
    discountController.dispose();
  }
}

/// Custom Compact Form Row with Overflow Fixes
class _CompactFormRow extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final double? fieldWidth;

  const _CompactFormRow({
    required this.label,
    this.required = false,
    required this.child,
    this.fieldWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: label.isEmpty
                ? const SizedBox.shrink()
                : RichText(
                    text: TextSpan(
                      text: label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        if (required)
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: fieldWidth ?? 434, child: child),
        ],
      ),
    );
  }
}

class _WarehouseStockPopover extends StatefulWidget {
  final Widget child;
  final String currentWarehouse;
  final List<String> warehouseOptions;
  final ValueChanged<String> onWarehouseSelected;

  const _WarehouseStockPopover({
    required this.child,
    required this.currentWarehouse,
    required this.warehouseOptions,
    required this.onWarehouseSelected,
  });

  @override
  State<_WarehouseStockPopover> createState() => _WarehouseStockPopoverState();
}

class _WarehouseStockPopoverState extends State<_WarehouseStockPopover> {
  OverlayEntry? _entry;
  bool _isAccountingStock = true;
  String _selectedView = 'Available for Sale';
  final LayerLink _layerLink = LayerLink();

  void _togglePopover() {
    if (_entry != null) {
      _removePopover();
    } else {
      _entry = _createOverlayEntry();
      Overlay.of(context).insert(_entry!);
      setState(() {});
    }
  }

  void _removePopover() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setOverlayState) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removePopover,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.black.withValues(alpha: 0.1)),
              ),
            ),
            Positioned(
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.bottomRight,
                offset: const Offset(0, -8),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: SizedBox(
                    width: 750,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                            child: Row(
                              children: [
                                const Text(
                                  'Warehouse Locations',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                const Text(
                                  'View: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  initialValue: _selectedView,
                                  onSelected: (val) {
                                    setOverlayState(() => _selectedView = val);
                                  },
                                  itemBuilder: (context) =>
                                      [
                                            'Available for Sale',
                                            'Stock on Hand',
                                            'Commited Stock',
                                          ]
                                          .map(
                                            (v) => PopupMenuItem(
                                              value: v,
                                              child: Text(
                                                v,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  child: Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.borderColor,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _selectedView,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Toggle
                                Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.primaryBlue,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => setOverlayState(
                                          () => _isAccountingStock = true,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _isAccountingStock
                                                ? AppTheme.primaryBlue
                                                : Colors.white,
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                  left: Radius.circular(3),
                                                ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Accounting Stock',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _isAccountingStock
                                                  ? Colors.white
                                                  : AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setOverlayState(
                                          () => _isAccountingStock = false,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: !_isAccountingStock
                                                ? AppTheme.primaryBlue
                                                : Colors.white,
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                  right: Radius.circular(3),
                                                ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Physical Stock',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: !_isAccountingStock
                                                  ? Colors.white
                                                  : AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: _removePopover,
                                  icon: const Icon(
                                    Icons.close,
                                    size: 20,
                                    color: AppTheme.errorRed,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.borderColor),
                          // Table Header
                          Container(
                            color: const Color(0xFFF9FAFB),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: const [
                                          Text(
                                            'Location Name ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          Icon(
                                            Icons.search,
                                            size: 14,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const VerticalDivider(
                                    width: 1,
                                    color: AppTheme.borderColor,
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 32,
                                          alignment: Alignment.center,
                                          child: Text(
                                            _isAccountingStock
                                                ? 'Accounting Stock'
                                                : 'Physical Stock',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const Divider(
                                          height: 1,
                                          color: AppTheme.borderColor,
                                        ),
                                        IntrinsicHeight(
                                          child: Row(
                                            children: [
                                              _buildSubHeader('Stock on Hand'),
                                              const VerticalDivider(
                                                width: 1,
                                                color: AppTheme.borderColor,
                                              ),
                                              _buildSubHeader(
                                                'Committed Stock',
                                              ),
                                              const VerticalDivider(
                                                width: 1,
                                                color: AppTheme.borderColor,
                                              ),
                                              _buildSubHeader(
                                                'Available for Sale',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.borderColor),
                          // Table Rows
                          _buildRow(
                            widget.warehouseOptions.isNotEmpty
                                ? widget.warehouseOptions.first
                                : widget.currentWarehouse,
                            '13.00',
                            '51.00',
                            '-38.00',
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildRow(
                            widget.warehouseOptions.length > 1
                                ? widget.warehouseOptions[1]
                                : (widget.warehouseOptions.isNotEmpty
                                      ? widget.warehouseOptions.first
                                      : widget.currentWarehouse),
                            '2.00',
                            '5.00',
                            '-3.00',
                          ),
                          const SizedBox(height: 24),
                          // Footer Notes
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Stock on Hand : This is calculated based on Bills and Invoices.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Committed Stock : Stock that is committed to sales order(s) but not yet invoiced',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Available for Sale : Stock on Hand - Committed Stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader(String label) {
    return Expanded(
      child: Container(
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRow(
    String name,
    String soh,
    String committed,
    String available,
  ) {
    final bool isSelected = widget.currentWarehouse == name;
    return InkWell(
      onTap: () {
        widget.onWarehouseSelected(name);
        _removePopover();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textDisabled,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      soh,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      committed,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      available,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(onTap: _togglePopover, child: widget.child),
    );
  }
}

class _SrGridHeader extends StatelessWidget {
  final String label;
  final bool center;

  const _SrGridHeader({required this.label, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _SalesReturnItemsGrid extends StatefulWidget {
  final bool creditOnly;
  final String warehouse;
  final List<String> warehouseOptions;
  final List<Item> availableItems;
  final List<_SalesReturnItem> items;
  final VoidCallback onAddItem;
  final VoidCallback onAddBulkItems;
  final Function(int) onRemoveItem;
  final Function(int) onItemSelected;
  final Function(_SalesReturnItem) onViewItemDetails;
  final ValueChanged<String> onWarehouseSelected;

  const _SalesReturnItemsGrid({
    required this.creditOnly,
    required this.warehouse,
    required this.warehouseOptions,
    required this.availableItems,
    required this.items,
    required this.onAddItem,
    required this.onAddBulkItems,
    required this.onRemoveItem,
    required this.onItemSelected,
    required this.onViewItemDetails,
    required this.onWarehouseSelected,
  });

  @override
  State<_SalesReturnItemsGrid> createState() => _SalesReturnItemsGridState();
}

class _SalesReturnItemsGridState extends State<_SalesReturnItemsGrid> {
  @override
  Widget build(BuildContext context) {
    const bs = BorderSide(color: AppTheme.borderLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── HEADER ──────────────────────────────────────────────
        _HoverableRowSlot(
          showX: false,
          onDelete: null,
          content: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: AppTheme.tableHeaderBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: const _SrGridHeader(label: 'ITEMS & DESCRIPTION'),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  Container(
                    width: 160,
                    color: AppTheme.tableHeaderBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    alignment: Alignment.center,
                    child: const _SrGridHeader(label: 'INVOICED', center: true),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  Container(
                    width: 140,
                    color: AppTheme.tableHeaderBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    alignment: Alignment.center,
                    child: const _SrGridHeader(label: 'RETURNED', center: true),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  if (widget.creditOnly)
                    Container(
                      width: 260,
                      color: AppTheme.tableHeaderBg,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: const _SrGridHeader(
                              label: 'RETURN DETAILS',
                              center: true,
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.borderLight),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: const _SrGridHeader(
                                      label: 'RECEIVABLE\nQUANTITY',
                                      center: true,
                                    ),
                                  ),
                                ),
                                const VerticalDivider(
                                  width: 1,
                                  color: AppTheme.borderLight,
                                ),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const _SrGridHeader(
                                          label: 'CREDIT-ONLY ',
                                          center: true,
                                        ),
                                        const ZTooltip(
                                          message:
                                              'The quantity specified under this category will not be received. You can only provide credits.',
                                          child: Icon(
                                            LucideIcons.helpCircle,
                                            size: 14,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: 200,
                      color: AppTheme.tableHeaderBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      alignment: Alignment.centerRight,
                      child: const _SrGridHeader(label: 'RETURN QUANTITY'),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ── DATA ROWS ────────────────────────────────────────────
        ...List.generate(widget.items.length, (index) {
          final hasData = widget.items[index].name.trim().isNotEmpty;
          return _HoverableRowSlot(
            showX: hasData,
            onDelete: () => widget.onRemoveItem(index),
            content: Container(
              decoration: BoxDecoration(
                border: Border(left: bs, right: bs, bottom: bs),
              ),
              child: _ItemRowWidget(
                item: widget.items[index],
                warehouse: widget.warehouse,
                warehouseOptions: widget.warehouseOptions,
                availableItems: widget.availableItems,
                creditOnly: widget.creditOnly,
                onRemove: () => widget.onRemoveItem(index),
                canRemove: index != 0,
                onItemSelected: () => widget.onItemSelected(index),
                onWarehouseSelected: widget.onWarehouseSelected,
              ),
            ),
          );
        }),

        // ── ADD ROW FOOTER ───────────────────────────────────────
        _HoverableRowSlot(
          showX: false,
          onDelete: null,
          content: Container(
            decoration: BoxDecoration(
              border: Border(left: bs, right: bs, bottom: bs),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: TextButton.icon(
                    onPressed: widget.onAddItem,
                    icon: const Icon(
                      LucideIcons.plusCircle,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    label: const Text(
                      'Add New Row',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: TextButton.icon(
                    onPressed: widget.onAddBulkItems,
                    icon: const Icon(
                      LucideIcons.plusCircle,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    label: const Text(
                      'Add Items in Bulk',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HoverableRowSlot extends StatefulWidget {
  final Widget content;
  final bool showX;
  final VoidCallback? onDelete;

  const _HoverableRowSlot({
    required this.content,
    required this.showX,
    this.onDelete,
  });

  @override
  State<_HoverableRowSlot> createState() => _HoverableRowSlotState();
}

class _HoverableRowSlotState extends State<_HoverableRowSlot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.content),
            SizedBox(
              width: 36,
              child: (widget.showX && _isHovered)
                  ? Center(
                      child: GestureDetector(
                        onTap: widget.onDelete,
                        behavior: HitTestBehavior.opaque,
                        child: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRowWidget extends StatefulWidget {
  final _SalesReturnItem item;
  final String warehouse;
  final List<String> warehouseOptions;
  final List<Item> availableItems;
  final bool creditOnly;
  final VoidCallback onRemove;
  final bool canRemove;
  final VoidCallback? onItemSelected;
  final ValueChanged<String> onWarehouseSelected;

  const _ItemRowWidget({
    required this.item,
    required this.warehouse,
    required this.warehouseOptions,
    required this.availableItems,
    required this.creditOnly,
    required this.onRemove,
    required this.onWarehouseSelected,
    this.canRemove = true,
    this.onItemSelected,
  });

  @override
  State<_ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<_ItemRowWidget> {
  Item? _resolveSelectedItem() {
    for (final candidate in widget.availableItems) {
      if (candidate.productName == widget.item.name) {
        return candidate;
      }
    }
    return widget.item.selectedItem;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final canEditRow = item.name.trim().isNotEmpty;
    final selectedItem = _resolveSelectedItem();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ITEMS & DESCRIPTION
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: item.name.isEmpty
                  ? FormDropdown<Item>(
                      value: selectedItem,
                      items: widget.availableItems,
                      hint: 'Type or click to select an item.',
                      height: _SalesReturnsCreatePageState._tableFieldHeight,
                      hideBorderDefault: true,
                      displayStringForValue: (value) => value.productName,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            item.selectedItem = val;
                            item.name = val.productName;
                            item.description = val.salesDescription ?? '';
                            item.descriptionController.text =
                                (val.salesDescription ?? '').trim().isNotEmpty
                                ? val.salesDescription!.trim()
                                : val.itemCode;
                          });
                          widget.onItemSelected?.call();
                        }
                      },
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (item.descriptionController.text.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.descriptionController.text,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            item.name = '';
                            item.selectedItem = null;
                            item.descriptionController.clear();
                          }),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              LucideIcons.x,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.borderLight),
          // INVOICED — read-only, centered
          SizedBox(
            width: 160,
            child: Center(
              child: Text(
                item.shipped,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.borderLight),
          // RETURNED — read-only, centered
          SizedBox(
            width: 140,
            child: Center(
              child: Text(
                item.returned,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.borderLight),
          // RETURN QUANTITY / RETURN DETAILS
          if (widget.creditOnly)
            SizedBox(
              width: 260,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 72,
                            height: 18,
                            child: TextField(
                              controller: item.returnQtyController,
                              enabled: canEditRow,
                              textAlign: TextAlign.right,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: '0',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Builder(
                            builder: (btnCtx) => GestureDetector(
                              onTap: canEditRow
                                  ? () {
                                      const dialogWidth = 420.0;
                                      const rowHeight = 48.0;
                                      const chromeHeight =
                                          106.0; // title + divider + search + divider
                                      const verticalMargin = 8.0;
                                      const gap = 6.0;

                                      final box =
                                          btnCtx.findRenderObject()
                                              as RenderBox;
                                      final triggerPos = box.localToGlobal(
                                        Offset.zero,
                                      );
                                      final triggerSize = box.size;
                                      final screen = MediaQuery.of(btnCtx).size;
                                      final locationsCount =
                                          widget.warehouseOptions.isEmpty
                                          ? 1
                                          : widget.warehouseOptions.length;

                                      final desiredHeight =
                                          chromeHeight +
                                          (locationsCount * rowHeight);
                                      final maxHeight =
                                          (screen.height - (verticalMargin * 2))
                                              .clamp(220.0, 520.0);
                                      final dialogHeight = desiredHeight.clamp(
                                        220.0,
                                        maxHeight,
                                      );
                                      final maxListHeight =
                                          (dialogHeight - chromeHeight).clamp(
                                            80.0,
                                            380.0,
                                          );

                                      double left =
                                          triggerPos.dx +
                                          triggerSize.width +
                                          gap;
                                      if (left + dialogWidth >
                                          screen.width - verticalMargin) {
                                        left =
                                            triggerPos.dx - dialogWidth - gap;
                                      }
                                      if (left + dialogWidth >
                                          screen.width - verticalMargin) {
                                        left =
                                            screen.width -
                                            dialogWidth -
                                            verticalMargin;
                                      }
                                      if (left < verticalMargin) {
                                        left = verticalMargin;
                                      }

                                      double top = triggerPos.dy - 16;
                                      final maxTop =
                                          screen.height -
                                          dialogHeight -
                                          verticalMargin;
                                      if (top > maxTop) top = maxTop;
                                      if (top < verticalMargin)
                                        top = verticalMargin;

                                      showGeneralDialog<void>(
                                        context: btnCtx,
                                        barrierDismissible: true,
                                        barrierLabel: '',
                                        barrierColor: Colors.transparent,
                                        transitionDuration: Duration.zero,
                                        pageBuilder: (ctx, _, __) => Stack(
                                          children: [
                                            Positioned(
                                              left: left,
                                              top: top,
                                              width: dialogWidth,
                                              child: Material(
                                                color: Colors.transparent,
                                                child: _WarehouseLocationsForm(
                                                  locations:
                                                      widget.warehouseOptions,
                                                  currentLocation:
                                                      widget.warehouse,
                                                  onSelected: widget
                                                      .onWarehouseSelected,
                                                  maxListHeight: maxListHeight,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(
                                    LucideIcons.warehouse,
                                    size: 12,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      widget.warehouse.trim().isEmpty
                                          ? 'Select Warehouse'
                                          : widget.warehouse,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: canEditRow
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 72,
                            child: TextField(
                              controller: item.creditOnlyQtyController,
                              enabled: canEditRow,
                              textAlign: TextAlign.right,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: '0',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 18,
                      child: TextField(
                        controller: item.returnQtyController,
                        enabled: canEditRow,
                        textAlign: TextAlign.right,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '0',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Builder(
                      builder: (btnCtx) => GestureDetector(
                        onTap: canEditRow
                            ? () {
                                const dialogWidth = 420.0;
                                const rowHeight = 48.0;
                                const chromeHeight =
                                    106.0; // title + divider + search + divider
                                const verticalMargin = 8.0;
                                const gap = 6.0;

                                final box =
                                    btnCtx.findRenderObject() as RenderBox;
                                final triggerPos = box.localToGlobal(
                                  Offset.zero,
                                );
                                final triggerSize = box.size;
                                final screen = MediaQuery.of(btnCtx).size;
                                final locationsCount =
                                    widget.warehouseOptions.isEmpty
                                    ? 1
                                    : widget.warehouseOptions.length;

                                final desiredHeight =
                                    chromeHeight + (locationsCount * rowHeight);
                                final maxHeight =
                                    (screen.height - (verticalMargin * 2))
                                        .clamp(220.0, 520.0);
                                final dialogHeight = desiredHeight.clamp(
                                  220.0,
                                  maxHeight,
                                );
                                final maxListHeight =
                                    (dialogHeight - chromeHeight).clamp(
                                      80.0,
                                      380.0,
                                    );

                                double left =
                                    triggerPos.dx + triggerSize.width + gap;
                                if (left + dialogWidth >
                                    screen.width - verticalMargin) {
                                  left = triggerPos.dx - dialogWidth - gap;
                                }
                                if (left + dialogWidth >
                                    screen.width - verticalMargin) {
                                  left =
                                      screen.width -
                                      dialogWidth -
                                      verticalMargin;
                                }
                                if (left < verticalMargin) {
                                  left = verticalMargin;
                                }

                                double top = triggerPos.dy - 16;
                                final maxTop =
                                    screen.height -
                                    dialogHeight -
                                    verticalMargin;
                                if (top > maxTop) top = maxTop;
                                if (top < verticalMargin) top = verticalMargin;

                                showGeneralDialog<void>(
                                  context: btnCtx,
                                  barrierDismissible: true,
                                  barrierLabel: '',
                                  barrierColor: Colors.transparent,
                                  transitionDuration: Duration.zero,
                                  pageBuilder: (ctx, _, __) => Stack(
                                    children: [
                                      Positioned(
                                        left: left,
                                        top: top,
                                        width: dialogWidth,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: _WarehouseLocationsForm(
                                            locations: widget.warehouseOptions,
                                            currentLocation: widget.warehouse,
                                            onSelected:
                                                widget.onWarehouseSelected,
                                            maxListHeight: maxListHeight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              LucideIcons.warehouse,
                              size: 12,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                widget.warehouse.trim().isEmpty
                                    ? 'Select Warehouse'
                                    : widget.warehouse,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: canEditRow
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }
}

class _ItemDetailsSidePanel extends StatefulWidget {
  final _SalesReturnItem item;
  final VoidCallback onClose;

  const _ItemDetailsSidePanel({required this.item, required this.onClose});

  @override
  State<_ItemDetailsSidePanel> createState() => _ItemDetailsSidePanelState();
}

class _ItemDetailsSidePanelState extends State<_ItemDetailsSidePanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(left: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Item Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.errorRed),
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
          // Item card
          Container(
            color: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: const Icon(
                    LucideIcons.image,
                    size: 28,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inventory Items',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.item.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.externalLink,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'pcs',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                _PanelTabButton(
                  label: 'ITEM DETAILS',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _PanelTabButton(
                  label: 'STOCK LOCATIONS',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                _PanelTabButton(
                  label: 'TRANSACTIONS',
                  selected: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _tab == 0
                  ? _buildItemDetailsTab()
                  : _tab == 1
                  ? _buildStockLocationsTab()
                  : _buildTransactionsTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelSectionHeading('Sales Information'),
        const SizedBox(height: 12),
        const _PanelDetailRow(label: 'Price', value: 'â‚¹115.00'),
        const SizedBox(height: 8),
        const _PanelDetailRow(label: 'Account', value: 'Sales'),
        const SizedBox(height: 24),
        const _PanelSectionHeading('Purchase Information'),
        const SizedBox(height: 12),
        const _PanelDetailRow(label: 'Price', value: 'â‚¹100.00'),
        const SizedBox(height: 8),
        const _PanelDetailRow(label: 'Account', value: 'Cost of Goods Sold'),
        const SizedBox(height: 24),
        const _PanelSectionHeading('Other Details'),
      ],
    );
  }

  Widget _buildStockLocationsTab() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: Text(
          'No stock location data available.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: Text(
          'No transactions available.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _PanelTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PanelTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: selected ? AppTheme.primaryBlue : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PanelSectionHeading extends StatelessWidget {
  final String text;
  const _PanelSectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _PanelDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _PanelDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Item Table Toolbar — above the items grid
// ---------------------------------------------------------------------------

class _ItemTableToolbar extends StatelessWidget {
  const _ItemTableToolbar({
    required this.warehouseLocation,
    required this.warehouseOptions,
    required this.onWarehouseChanged,
  });

  final String? warehouseLocation;
  final List<String> warehouseOptions;
  final ValueChanged<String> onWarehouseChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Warehouse Location',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 250,
            child: FormDropdown<String>(
              value: warehouseLocation,
              items: warehouseOptions,
              hint: 'Select Warehouse',
              height: 36,
              hideBorderDefault: true,
              onChanged: (v) {
                if (v != null) onWarehouseChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RmaPreferencesDialog extends StatefulWidget {
  final String prefix;
  final String nextNumber;
  final bool autoGenerate;
  final String branchLabel;
  final Future<void> Function(
    String prefix,
    String nextNumber,
    bool autoGenerate,
  )
  onSave;

  const _RmaPreferencesDialog({
    required this.prefix,
    required this.nextNumber,
    required this.autoGenerate,
    required this.branchLabel,
    required this.onSave,
  });

  @override
  State<_RmaPreferencesDialog> createState() => _RmaPreferencesDialogState();
}

class _RmaPreferencesDialogState extends State<_RmaPreferencesDialog> {
  late bool _autoGenerate;
  late final TextEditingController _prefixController;
  late final TextEditingController _nextNumberController;

  @override
  void initState() {
    super.initState();
    _autoGenerate = widget.autoGenerate;
    _prefixController = TextEditingController(text: widget.prefix);
    _nextNumberController = TextEditingController(text: widget.nextNumber);
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _nextNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Configure RMA Number Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.errorRed),
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
          // Branch / Series table
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Branch/Organisation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Associated Series',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.branchLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Default Transaction Series',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Info text
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Your RMA numbers are set on auto-generate mode to save your time.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Are you sure about changing this setting?',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Radio options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Option 1: Auto-generate
                InkWell(
                  onTap: () => setState(() => _autoGenerate = true),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _autoGenerate,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (val) =>
                            setState(() => _autoGenerate = val ?? true),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text(
                        'Continue auto-generating RMA numbers',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        LucideIcons.info,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
                if (_autoGenerate)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 8, bottom: 8),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prefix',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 120,
                              child: CustomTextField(
                                controller: _prefixController,
                                height: 32,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next Number',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 220,
                              child: CustomTextField(
                                controller: _nextNumberController,
                                height: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // Option 2: Manual
                InkWell(
                  onTap: () => setState(() => _autoGenerate = false),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: _autoGenerate,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (val) =>
                            setState(() => _autoGenerate = val ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text(
                        'Enter RMA numbers manually',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Row(
              children: [
                ZButton.primary(
                  label: 'Save',
                  onPressed: () async {
                    await widget.onSave(
                      _prefixController.text,
                      _nextNumberController.text,
                      _autoGenerate,
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MaxWidthContainer extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidthContainer({
    super.key,
    required this.maxWidth,
    required this.child,
  });

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

class _BulkMenuHoverItem extends StatefulWidget {
  final String label;
  const _BulkMenuHoverItem({required this.label});

  @override
  State<_BulkMenuHoverItem> createState() => _BulkMenuHoverItemState();
}

class _BulkMenuHoverItemState extends State<_BulkMenuHoverItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: _hovered ? const Color(0xFFEEF2FF) : Colors.transparent,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            color: _hovered ? AppTheme.primaryBlue : AppTheme.textPrimary,
            fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _BulkUpdateLineItemsDialog extends StatefulWidget {
  const _BulkUpdateLineItemsDialog();

  @override
  State<_BulkUpdateLineItemsDialog> createState() =>
      _BulkUpdateLineItemsDialogState();
}

class _BulkUpdateLineItemsDialogState
    extends State<_BulkUpdateLineItemsDialog> {
  String? _selectedAdgf = 'None';
  String? _selectedShedule = 'None';
  String? _selectedDemoTag = 'None';

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SizedBox(width: 600, child: _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bulk Update Line Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.errorRed),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 14,
                    color: AppTheme.errorRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select an option in the reporting tags to update them for all the selected line items.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADGF',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormDropdown<String>(
                      value: _selectedAdgf,
                      items: const ['None', 'Option 1', 'Option 2'],
                      hint: 'None',
                      height: 36,
                      onChanged: (val) => setState(() => _selectedAdgf = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'shedule',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormDropdown<String>(
                      value: _selectedShedule,
                      items: const ['None', 'Option 1', 'Option 2'],
                      hint: 'None',
                      height: 36,
                      onChanged: (val) =>
                          setState(() => _selectedShedule = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'demo adavced reporting tag',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 280,
                child: FormDropdown<String>(
                  value: _selectedDemoTag,
                  items: const ['None', 'Option 1', 'Option 2'],
                  hint: 'None',
                  height: 36,
                  onChanged: (val) => setState(() => _selectedDemoTag = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Note: Only the reporting tags you select will be updated in the line items. Other tags will not be updated.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: AppTheme.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulkUpdateAccountDialog extends StatefulWidget {
  const _BulkUpdateAccountDialog();

  @override
  State<_BulkUpdateAccountDialog> createState() =>
      _BulkUpdateAccountDialogState();
}

class _BulkUpdateAccountDialogState extends State<_BulkUpdateAccountDialog> {
  String? _selectedAccount;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SizedBox(
        width: 600,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bulk Update Line Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.errorRed),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Select an account for the selected line items.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              // Form Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Account',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 280,
                    child: FormDropdown<String>(
                      value: _selectedAccount,
                      items: const [
                        'Select an account',
                        'Account 1',
                        'Account 2',
                      ],
                      hint: 'Select an account',
                      height: 36,
                      onChanged: (val) =>
                          setState(() => _selectedAccount = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Success green
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF374151),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkUpdateDiscountAccountDialog extends StatefulWidget {
  const _BulkUpdateDiscountAccountDialog();

  @override
  State<_BulkUpdateDiscountAccountDialog> createState() =>
      _BulkUpdateDiscountAccountDialogState();
}

class _BulkUpdateDiscountAccountDialogState
    extends State<_BulkUpdateDiscountAccountDialog> {
  int _selectedValue = 0; // 0 for same account, 1 for choose account
  String? _selectedAccount;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SizedBox(
        width: 600,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bulk Update Line Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.errorRed),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose a discount account for the selected line items.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              // Radio Buttons
              Row(
                children: [
                  Radio<int>(
                    value: 0,
                    groupValue: _selectedValue,
                    onChanged: (val) => setState(() => _selectedValue = val!),
                    activeColor: AppTheme.primaryBlue,
                  ),
                  const Text(
                    "Use the same account as each item's sales account",
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  Radio<int>(
                    value: 1,
                    groupValue: _selectedValue,
                    onChanged: (val) => setState(() => _selectedValue = val!),
                    activeColor: AppTheme.primaryBlue,
                  ),
                  const Text(
                    "Choose Account",
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              if (_selectedValue == 1) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: SizedBox(
                    width: 280,
                    child: FormDropdown<String>(
                      value: _selectedAccount,
                      items: const [
                        'Select an account',
                        'Account 1',
                        'Account 2',
                      ],
                      hint: 'Select an account',
                      height: 36,
                      onChanged: (val) =>
                          setState(() => _selectedAccount = val),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Success green
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF374151),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _WarehouseLocationsForm extends StatefulWidget {
  final List<String> locations;
  final String currentLocation;
  final ValueChanged<String> onSelected;
  final double maxListHeight;

  const _WarehouseLocationsForm({
    required this.locations,
    required this.currentLocation,
    required this.onSelected,
    required this.maxListHeight,
  });

  @override
  State<_WarehouseLocationsForm> createState() =>
      _WarehouseLocationsFormState();
}

class _WarehouseLocationsFormState extends State<_WarehouseLocationsForm> {
  late String _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
  }

  @override
  Widget build(BuildContext context) {
    final locations = widget.locations.isEmpty
        ? <String>[widget.currentLocation]
        : widget.locations;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Bar with inline X button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                const Text(
                  'Warehouse Locations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.errorRed, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 14,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: const [
                Text(
                  'Location Name',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                SizedBox(width: 4),
                Icon(
                  LucideIcons.search,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          SizedBox(
            height: widget.maxListHeight,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                return RadioListTile<String>(
                  value: location,
                  groupValue: _selectedLocation,
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedLocation = val;
                    });
                    widget.onSelected(val);
                  },
                  activeColor: AppTheme.primaryBlue,
                  title: Text(
                    location,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
