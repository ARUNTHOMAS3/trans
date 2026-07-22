// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/models/purchases_purchase_returns_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/providers/purchases_purchase_returns_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
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
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:file_picker/file_picker.dart';

// â”€â”€ Line item model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PRLineItem {
  Item? sourceItem;
  String? selectedTax;
  String? selectedAccount;

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

// â”€â”€ Main page widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
  static const double _tableFieldHeight = 44.0;
  static const double _labelWidth = 150.0;
  static const double _gapWidth = 16.0;
  static const double _rowMaxWidth = 1400.0;
  static const double _vendorFieldWidth = 500.0;

  // â”€â”€ Form state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    if (widget.isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadForEdit());
    } else {
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

  // â”€â”€ Item management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Number preference dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Date picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Data loading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      final ret = await ref
          .read(purchaseReturnsRepositoryProvider)
          .getPurchaseReturn(widget.purchaseReturnId!);
      if (ret == null || !mounted) return;

      _returnNumberController.text = ret.returnNumber;
      _purchaseOrderController.text = ret.purchaseOrderNumber ?? '';
      _purchaseReceiveController.text = ret.purchaseReceiveNumber ?? '';
      _notesController.text = ret.notes ?? '';
      _returnDate = ret.returnDate ?? DateTime.now();
      _returnDateController.text = DateFormat('dd-MM-yyyy').format(_returnDate);

      for (final item in _items) item.dispose();
      _items.clear();

      for (final item in ret.items) {
        final line = _PRLineItem();
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
    } catch (e) {
      AppLogger.error(
        'Failed to load purchase return for edit: $e',
        module: 'purchases',
      );
    }
  }

  // â”€â”€ Calculations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  double _parseMoney(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0;

  String _formatMoney(double value) => value.toStringAsFixed(2);

  double _lineSubtotal(_PRLineItem item) {
    final qty = _parseMoney(item.returnQtyController.text);
    final rate = _parseMoney(item.rateController.text);
    return (qty * rate).clamp(0.0, double.infinity);
  }

  double get _subTotal => _items
      .where((i) => i.sourceItem != null)
      .fold(0.0, (s, i) => s + _lineSubtotal(i));

  double get _adjustmentAmount => _parseMoney(_adjustmentController.text);
  double get _grandTotal => _subTotal + _adjustmentAmount;

  // â”€â”€ Save â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final customers = customersAsync.valueOrNull ?? [];
    final vendors = customers
        .map((c) => Vendor(id: c.id, displayName: c.displayName))
        .toList();
    final vendorIsLoading = customersAsync.isLoading;

    return Container(
      color: Colors.white,
      child: ZerpaiLayout(
        pageTitle: widget.isEdit
            ? 'Edit Purchase Return'
            : 'New Purchase Return',
        enableBodyScroll: true,
        useHorizontalPadding: true,
        footer: Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: _MaxWidthContainer(
            maxWidth: _rowMaxWidth,
            child: Row(
              children: [
                ZButton.primary(
                  label: _saving ? 'Savingâ€¦' : 'Save as Draft',
                  onPressed: _saving ? null : () => _save(draft: true),
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Save and Confirm',
                  onPressed: _saving ? null : () => _save(draft: false),
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Cancel',
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.purchaseReturns),
                ),
              ],
            ),
          ),
        ),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          child: _MaxWidthContainer(
            maxWidth: _rowMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // â”€â”€ Vendor header band â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _HeaderBackgroundBand(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vendor Name
                        _CompactFormRow(
                          label: 'Vendor Name',
                          required: true,
                          labelColor: AppTheme.errorRed,
                          fieldWidth: _vendorFieldWidth + 12 + 72,
                          child: Row(
                            children: [
                              SizedBox(
                                width: _vendorFieldWidth,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: FormDropdown<Vendor>(
                                        value: _selectedVendorObj,
                                        items: vendors,
                                        isLoading: vendorIsLoading,
                                        displayStringForValue: (v) =>
                                            v.displayName,
                                        searchStringForValue: (v) =>
                                            '${v.displayName} ${v.gstin ?? ''}',
                                        hint: 'Select or type a vendor',
                                        height: _fieldHeight,
                                        menuMaxHeight: 320,
                                        showRightBorder: false,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          bottomLeft: Radius.circular(4),
                                        ),
                                        allowClear: true,
                                        onChanged: (val) => setState(() {
                                          _selectedVendorObj = val;
                                          if (val == null) {
                                            _selectedSourceOfSupply = null;
                                            _selectedDestinationOfSupply = null;
                                            _selectedBill = null;
                                          }
                                        }),
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
                                                  .read(salesCustomersProvider)
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
                                                      c.displayName == result,
                                                  orElse: () =>
                                                      allCustomers.first,
                                                );
                                            setState(() {
                                              _selectedVendorObj = Vendor(
                                                id: matched.id,
                                                displayName:
                                                    matched.displayName,
                                              );
                                              _selectedSourceOfSupply = null;
                                              _selectedDestinationOfSupply =
                                                  null;
                                              _selectedBill = null;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedVendorName != null) ...[
                                const SizedBox(width: 12),
                                const _PRCurrencyBadge(),
                              ],
                            ],
                          ),
                        ),

                        // Show address + bill fields only after vendor selected
                        if (_selectedVendorObj != null) ...[
                          _PRVendorAddressPanel(
                            vendor: _selectedVendorObj!,
                            labelWidth: _labelWidth,
                          ),
                          // Source of Supply
                          _CompactFormRow(
                            label: 'Source of Supply',
                            required: true,
                            labelColor: AppTheme.errorRed,
                            fieldWidth: 330,
                            child: FormDropdown<String>(
                              value: _selectedSourceOfSupply,
                              items: const [
                                '[KL] - Kerala',
                                '[TN] - Tamil Nadu',
                                '[KA] - Karnataka',
                                '[MH] - Maharashtra',
                                '[DL] - Delhi',
                              ],
                              hint: 'Select source of supply',
                              height: _fieldHeight,
                              onChanged: (v) =>
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
                              items: const [
                                '[KL] - Kerala',
                                '[TN] - Tamil Nadu',
                                '[KA] - Karnataka',
                                '[MH] - Maharashtra',
                                '[DL] - Delhi',
                              ],
                              hint: 'Select destination of supply',
                              height: _fieldHeight,
                              onChanged: (v) => setState(
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
                                  items: const ['BILL-001', 'BILL-002'],
                                  hint: 'Select linked bill',
                                  height: _fieldHeight,
                                  allowClear: true,
                                  onChanged: (v) =>
                                      setState(() => _selectedBill = v),
                                ),
                                if (_selectedBill != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bill Date: â€”',
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

                // â”€â”€ Purchase Return# â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                // â”€â”€ Purchase Order# â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _CompactFormRow(
                  label: 'Purchase Order#',
                  fieldWidth: 330,
                  child: CustomTextField(
                    controller: _purchaseOrderController,
                    height: _fieldHeight,
                    hintText: 'Reference PO number',
                  ),
                ),

                // â”€â”€ Purchase Receive# â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _CompactFormRow(
                  label: 'Receive#',
                  fieldWidth: 330,
                  child: CustomTextField(
                    controller: _purchaseReceiveController,
                    height: _fieldHeight,
                    hintText: 'Reference receive number',
                  ),
                ),

                // â”€â”€ Purchase Return Date â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                // â”€â”€ Reason for Return â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                        width: 434,
                        child: CustomTextField(
                          controller: _reasonController,
                          hintText:
                              'e.g. Damaged goods, wrong items delivered, quality issueâ€¦',
                          height: _fieldHeight,
                        ),
                      ),
                    ],
                  ),
                ),

                // â”€â”€ Reverse charge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

                // â”€â”€ Item table toolbar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _PRItemTableToolbar(
                  warehouseLocation: _warehouseLocation,
                  onWarehouseChanged: (v) =>
                      setState(() => _warehouseLocation = v),
                  discountType: _discountType,
                  onDiscountTypeChanged: (v) =>
                      setState(() => _discountType = v),
                  selectedPriceList: _selectedPriceList,
                  priceListOptions: ref.watch(activePriceListsProvider),
                  priceListsLoading: ref
                      .watch(priceListNotifierProvider)
                      .isLoading,
                  onPriceListChanged: (v) =>
                      setState(() => _selectedPriceList = v),
                ),
                const SizedBox(height: 16),

                // â”€â”€ Items grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                ),

                const SizedBox(height: 32),

                // â”€â”€ Totals panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sub Total
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                12,
                              ),
                              child: Row(
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
                            ),
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
                                    'Total (â‚¹)',
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

                // â”€â”€ Notes + Attach Files â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppTheme.bgLight),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _notesController,
                              hintText:
                                  'Will be displayed on the purchase return',
                              maxLines: 4,
                              height: 100,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            border: Border.all(color: AppTheme.borderLight),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attach File(s) to Purchase Return',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FileUploadButton(
                                    files: _attachedFiles,
                                    maxFiles: 5,
                                    onFilesChanged: (files) =>
                                        setState(() => _attachedFiles = files),
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
                                'You can upload a maximum of 5 files, 10MB each',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 24),

                // â”€â”€ Additional Fields note â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                      TextSpan(text: ' â†’ '),
                      TextSpan(
                        text: 'Purchases',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(text: ' â†’ '),
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

// â”€â”€ Currency badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PRCurrencyBadge extends StatelessWidget {
  const _PRCurrencyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _PurchaseReturnsCreatePageState._fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.badgeDollarSign,
            size: 16,
            color: AppTheme.successGreen,
          ),
          SizedBox(width: 6),
          Text(
            'INR',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Vendor address panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PRVendorAddressPanel extends StatefulWidget {
  final Vendor vendor;
  final double labelWidth;

  const _PRVendorAddressPanel({required this.vendor, required this.labelWidth});

  @override
  State<_PRVendorAddressPanel> createState() => _PRVendorAddressPanelState();
}

class _PRVendorAddressPanelState extends State<_PRVendorAddressPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    return Padding(
      padding: EdgeInsets.only(
        left: widget.labelWidth + 16,
        bottom: 12,
        top: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'BILLING ADDRESS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  LucideIcons.pencil,
                  size: 12,
                  color: _open ? AppTheme.primaryBlue : AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            v.displayName.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if ((v.gstin ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'GSTIN: ${v.gstin}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// â”€â”€ Preferences dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Item table toolbar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Items grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    return InkWell(
      onTap: widget.onAddItem,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(6),
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
                      size: 18,
                      color: AppTheme.primaryBlueDark,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add New Row',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              color: AppTheme.borderLight,
              thickness: 1,
              indent: 8,
              endIndent: 8,
            ),
            InkWell(
              onTap: () {},
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkAddButton() {
    return InkWell(
      onTap: widget.onAddBulkItems,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.plusCircle,
              size: 18,
              color: AppTheme.primaryBlueDark,
            ),
            SizedBox(width: 8),
            Text(
              'Add Items in Bulk',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textBody,
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
            color: AppTheme.backgroundColor,
            border: Border(
              left: BorderSide(color: AppTheme.borderLight),
              right: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 40),
              const Expanded(
                flex: 14,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: _TH('ITEM DETAILS'),
                ),
              ),
              _vLine(),
              const Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: _TH('ORDERED QTY', right: true),
                ),
              ),
              _vLine(),
              const Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: _TH('RETURN QTY', right: true),
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
                    children: [
                      const _TH('RATE'),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.layoutGrid,
                        size: 14,
                        color: AppTheme.textSecondary,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      border: Border(
                        left: BorderSide(color: AppTheme.borderLight),
                        right: BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                    child: Column(
                      children: [
                        _PRItemRow(
                          item: widget.items[index],
                          availableProducts: widget.availableProducts,
                          onSearchProducts: widget.onSearchProducts,
                          onChanged: widget.onTotalsChanged,
                          defaultWarehouse: widget.warehouse,
                          showAdditionalInformation: !_areAdditionalInfosHidden,
                        ),
                        if (index < widget.items.length - 1)
                          const Divider(height: 1, color: AppTheme.borderLight),
                      ],
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
        // Table bottom border
        Container(
          margin: const EdgeInsets.only(right: _rowActionsWidth),
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            border: const Border(
              left: BorderSide(color: AppTheme.borderLight),
              right: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
        ),
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

// â”€â”€ Item row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PRItemRow extends StatefulWidget {
  final _PRLineItem item;
  final List<Item> availableProducts;
  final Future<List<Item>> Function(String) onSearchProducts;
  final VoidCallback onChanged;
  final String defaultWarehouse;
  final bool showAdditionalInformation;

  const _PRItemRow({
    required this.item,
    required this.availableProducts,
    required this.onSearchProducts,
    required this.onChanged,
    required this.defaultWarehouse,
    required this.showAdditionalInformation,
  });

  @override
  State<_PRItemRow> createState() => _PRItemRowState();
}

class _PRItemRowState extends State<_PRItemRow> {
  String _computeAmount(_PRLineItem item) {
    final qty = double.tryParse(item.returnQtyController.text) ?? 0;
    final rate = double.tryParse(item.rateController.text) ?? 0;
    return (qty * rate).clamp(0.0, double.infinity).toStringAsFixed(2);
  }

  void _onItemSelected(Item? selected) {
    setState(() {
      widget.item.sourceItem = selected;
      if (selected != null) {
        widget.item.rateController.text =
            selected.costPrice?.toStringAsFixed(2) ?? '0.00';
        widget.item.descriptionController.text =
            selected.purchaseDescription ?? '';
        if (widget.item.returnQtyController.text.isEmpty ||
            widget.item.returnQtyController.text == '0.00') {
          widget.item.returnQtyController.text = '1.00';
        }
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        // ITEM DETAILS
        Expanded(
          flex: 14,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.bgDisabled,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.image,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormDropdown<Item>(
                        value: item.sourceItem,
                        items: widget.availableProducts,
                        hint: 'Type or click to select an item.',
                        height:
                            _PurchaseReturnsCreatePageState._tableFieldHeight,
                        hideBorderDefault: true,
                        allowClear: true,
                        displayStringForValue: (p) => p.productName,
                        searchStringForValue: (p) =>
                            '${p.productName} ${p.itemCode} ${p.sku ?? ''}',
                        onSearch: widget.onSearchProducts,
                        itemBuilder: (product, isSelected, isHovered) =>
                            _PRProductDropdownItem(
                              productName: product.productName,
                              itemCode: product.itemCode,
                              highlighted: isSelected || isHovered,
                            ),
                        onChanged: _onItemSelected,
                      ),
                    ),
                  ],
                ),
                if (item.sourceItem != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: CustomTextField(
                      controller: item.descriptionController,
                      hintText: 'Item description',
                      height: 32,
                      hideBorderDefault: true,
                      maxLines: 2,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.selectionActiveBg,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            item.sourceItem!.type.toUpperCase() == 'SERVICE'
                                ? 'SERVICE'
                                : 'GOODS',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        if (item.sourceItem!.hsnCode != null) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'HSN: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            item.sourceItem!.hsnCode!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.pencil,
                            size: 10,
                            color: AppTheme.primaryBlue,
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
        _vLine(),
        // ORDERED QTY
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: CustomTextField(
              controller: item.orderedQtyController,
              height: _PurchaseReturnsCreatePageState._tableFieldHeight,
              textAlign: TextAlign.right,
              hintText: '0',
              hideBorderDefault: true,
              keyboardType: TextInputType.number,
              onChanged: (_) => widget.onChanged(),
            ),
          ),
        ),
        _vLine(),
        // RETURN QTY
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: CustomTextField(
              controller: item.returnQtyController,
              height: _PurchaseReturnsCreatePageState._tableFieldHeight,
              textAlign: TextAlign.right,
              hintText: '0',
              hideBorderDefault: true,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                setState(() {});
                widget.onChanged();
              },
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
                      : _prTaxOptionItems.firstWhere(
                          (o) => o.label == item.selectedTax,
                          orElse: () => _prTaxOptionItems[4],
                        ),
                  items: _prTaxOptionItems,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: AppTheme.bgLight,
                        width: double.infinity,
                        child: Text(
                          option.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }
                    final active = isHovered || isSelected;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: isHovered ? AppTheme.primaryBlue : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                              : AppTheme.textPrimary),
                                    fontWeight: active
                                        ? FontWeight.w600
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
                            const SizedBox(height: 4),
                            Text(
                              option.description!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isHovered
                                    ? Colors.white70
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  onChanged: (val) {
                    if (val != null && !val.isHeader) {
                      setState(() => item.selectedTax = val.label);
                      widget.onChanged();
                    } else if (val == null) {
                      setState(() => item.selectedTax = null);
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
                'â‚¹${_computeAmount(item)}',
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
    );
  }
}

// â”€â”€ Layout helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Table header helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

Widget _vLine() => const VerticalDivider(width: 1, color: AppTheme.borderLight);

// â”€â”€ Row action hover item â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Row action icon button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          color: _hovered ? AppTheme.primaryBlue : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          widget.icon,
          size: 16,
          color: _hovered ? AppTheme.backgroundColor : AppTheme.errorRed,
        ),
      ),
    );
  }
}

// â”€â”€ Bulk menu hover item â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Tax options â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PRTaxOption {
  final String label;
  final String? description;
  final bool isHeader;

  const _PRTaxOption({
    required this.label,
    this.description,
    this.isHeader = false,
  });
}

final List<_PRTaxOption> _prTaxOptionItems = [
  const _PRTaxOption(
    label: 'Non-Taxable',
    description: 'Supply is exempt from GST. Exemption reason required.',
  ),
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
  const _PRTaxOption(label: 'Taxable', isHeader: true),
  const _PRTaxOption(label: 'GST 0%', description: '0%'),
  const _PRTaxOption(label: 'GST 5%', description: '[5%]'),
  const _PRTaxOption(label: 'GST 12%', description: '[12%]'),
  const _PRTaxOption(label: 'GST 18%', description: '[18%]'),
  const _PRTaxOption(label: 'GST 28%', description: '[28%]'),
  const _PRTaxOption(label: 'Taxable Group', isHeader: true),
  const _PRTaxOption(label: 'GST 5% + GST 12%', description: '[17%]'),
];

// â”€â”€ Product dropdown item â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PRProductDropdownItem extends StatelessWidget {
  final String productName;
  final String itemCode;
  final bool highlighted;

  const _PRProductDropdownItem({
    required this.productName,
    required this.itemCode,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = highlighted
        ? AppTheme.backgroundColor
        : AppTheme.textBody;
    final secondaryColor = highlighted
        ? AppTheme.backgroundColor
        : AppTheme.textSecondary;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.primaryBlue : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.bgDisabled,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              LucideIcons.package,
              size: 16,
              color: highlighted ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 10),
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
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (itemCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    itemCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: secondaryColor),
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
