// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/item_quick_edit_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/constants/phone_prefixes.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/advanced_customer_search_modal.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/widgets/cn_grid_header.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

/// Credit Note Add Page
class CreditNoteCreatePage extends ConsumerStatefulWidget {
  final String? initialCustomer;
  final String? creditNoteId;

  const CreditNoteCreatePage({super.key, this.initialCustomer, this.creditNoteId});

  @override
  ConsumerState<CreditNoteCreatePage> createState() => _CreditNoteCreatePageState();
}

class _CreditNoteCreatePageState extends ConsumerState<CreditNoteCreatePage> {
  static const double _tableFieldHeight = 44;
  static const double _accountColumnWidth = 150;
  static const double _quantityColumnWidth = 105;
  static const double _rateColumnWidth = 140;
  static const double _discountColumnWidth = 120;
  static const double _taxColumnWidth = 160;
  static const double _amountColumnWidth = 170;
  // --- Form State ---
  String? _selectedCustomer;
  String? _selectedReason;
  String? _selectedTransactionSeries = 'Default Transaction Series';
  String? _selectedSalesperson;
  String? _selectedPlaceOfSupply;
  String? _selectedInvoiceNumber;
  String? _selectedInvoiceType;
  late final TextEditingController _referenceNumberController;
  late final TextEditingController _customerNotesController;
  late final TextEditingController _termsController;

  late final TextEditingController _rmaNumberController;
  late final TextEditingController _rmaDateController;
  final _rmaDateKey = GlobalKey();
  DateTime _rmaDate = DateTime.now();
  late final TextEditingController _rmaReasonController;
  bool _creditOnlyGoods = false;

  String _warehouseLocation = 'ZABNIX PRIVATE LIMITED';
  String _priceLevel = 'At Transaction Level';
  String? _selectedPriceList;

  bool _rmaAutoGenerate = true;
  late final TextEditingController _rmaPrefixController;
  late final TextEditingController _rmaNextNumberController;

  // Summary section state
  String _taxType = 'TDS';
  String? _selectedTaxRate;
  late final TextEditingController _shippingController;
  late final TextEditingController _adjustmentController;

  bool _showItemDetailsPanel = false;
  _CnLineItem? _detailsItem;
  bool _showCustomerDetailsPanel = false;

  // Adjusted constants: Reduced width as requested, fixed overflow by ensuring 32px height is handled by components
  static const double _labelWidth = 150.0;
  static const double _rowMaxWidth = 1400.0;
  static const double _gapWidth = 16.0;
  static const double _fieldWidth = _rowMaxWidth - _labelWidth - _gapWidth;
  static const double _customerFieldWidth = 500.0;
  static const double _fieldHeight = 32.0;

  final List<_CnLineItem> _items = [];

  @override
  void initState() {
    super.initState();
    _referenceNumberController = TextEditingController();
    _customerNotesController = TextEditingController();
    _termsController = TextEditingController();
    _rmaNumberController = TextEditingController(
      text: widget.creditNoteId ?? 'CN-00001',
    );
    _rmaDateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(_rmaDate),
    );
    _rmaReasonController = TextEditingController();
    _rmaPrefixController = TextEditingController(text: 'CN-');
    _rmaNextNumberController = TextEditingController(text: '00001');
    _shippingController = TextEditingController();
    _adjustmentController = TextEditingController();
    _selectedCustomer = widget.initialCustomer;
    _items.clear();
    _addItem(); // Add first row by default
  }

  void _addItem() {
    setState(() {
      _items.add(
        _CnLineItem(
          name: '',
          shipped: '0',
          returned: '0',
          returnQty: '',
          stock: '0 pcs',
          rate: '',
        ),
      );
    });
  }

  void _insertItemAfter(int index) {
    setState(() {
      _items.insert(
        index + 1,
        _CnLineItem(
          name: '',
          shipped: '0',
          returned: '0',
          returnQty: '',
          stock: '0 pcs',
          rate: '',
        ),
      );
    });
  }

  void _cloneItem(int index) {
    final source = _items[index];
    setState(() {
      _items.insert(
        index + 1,
        _CnLineItem(
            name: source.name,
            description: source.descriptionController.text,
            shipped: source.shipped,
            returned: source.returned,
            returnQty: source.returnQtyController.text,
            stock: source.stock,
            hsnCode: source.hsnCode,
            discount: source.discount,
            reportingTag: source.reportingTag,
            account: source.account,
            tax: source.tax,
            rate: source.rateController.text,
            discountValue: source.discountController.text,
            discountIsPercent: source.discountIsPercent,
            costPrice: source.costPrice,
          )
          ..selectedTagValues = Map<String, String?>.from(
            source.selectedTagValues,
          ),
      );
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
            _items.removeWhere((item) => item.name.isEmpty);
            for (final entry in selectedWithQty.entries) {
              _items.add(
                _CnLineItem(
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
    _customerNotesController.dispose();
    _termsController.dispose();
    _rmaNumberController.dispose();
    _rmaDateController.dispose();
    _rmaReasonController.dispose();
    _rmaPrefixController.dispose();
    _rmaNextNumberController.dispose();
    _shippingController.dispose();
    _adjustmentController.dispose();
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

  void _openItemDetails(_CnLineItem item) {
    setState(() {
      _showItemDetailsPanel = true;
      _detailsItem = item;
      _showCustomerDetailsPanel = false;
    });
  }

  void _openEditItem(_CnLineItem lineItem) {
    // Build an Item from sourceItem if available, otherwise construct a minimal one
    final fullItem =
        lineItem.sourceItem ??
        Item(
          type: 'goods',
          productName: lineItem.name,
          itemCode: lineItem.name.isEmpty ? 'CN_ITEM' : lineItem.name,
          unitId: '',
          hsnCode: lineItem.hsnCode,
          taxPreference: lineItem.tax != null
              ? (lineItem.tax!.toLowerCase().contains('non')
                    ? 'non-taxable'
                    : 'taxable')
              : 'taxable',
          sellingPrice: double.tryParse(lineItem.rateController.text),
          costPrice: lineItem.costPrice,
        );

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => ItemQuickEditDialog(
        item: fullItem,
        onUpdated: (updated) {
          setState(() {
            lineItem.sourceItem = updated;
            lineItem.name = updated.productName;
            lineItem.hsnCode = updated.hsnCode ?? lineItem.hsnCode;
            lineItem.rateController.text = updated.sellingPrice.toString();
          });
        },
      ),
    );
  }

  void _openBatchDialog(_CnLineItem lineItem) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.only(
          top: 0,
          left: 40,
          right: 40,
          bottom: 24,
        ),
        alignment: Alignment.topCenter,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: _CnAddBatchesPopover(
            item: lineItem,
            onClose: () => Navigator.of(ctx).pop(),
            onSave: (batches) {
              setState(() {
                lineItem.savedBatches
                  ..clear()
                  ..addAll(batches);
              });
              Navigator.of(ctx).pop();
            },
          ),
        ),
      ),
    );
  }

  void _openCustomerDetails() {
    if (_selectedCustomer == null) return;

    setState(() {
      _showCustomerDetailsPanel = true;
      _showItemDetailsPanel = false;
      _detailsItem = null;
    });
  }

  void _showAddContactPersonDialog() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Contact Person',
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.58),
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final horizontalInset = screenWidth < 1000 ? 0.0 : 96.0;

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalInset,
              0,
              horizontalInset,
              0,
            ),
            child: Material(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: _AddContactPersonDialog(
                onClose: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRmaPreferencesDialog() {
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
              onSave: (prefix, nextNumber, autoGenerate) {
                setState(() {
                  _rmaAutoGenerate = autoGenerate;
                  _rmaPrefixController.text = prefix;
                  _rmaNextNumberController.text = nextNumber;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  double _parseMoney(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0;
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(2);
  }

  String _formatRate(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  double _lineSubtotal(_CnLineItem item) {
    final quantity = _parseMoney(item.returnQtyController.text);
    final rate = _parseMoney(item.rateController.text);
    final discount = _parseMoney(item.discountController.text);
    final gross = quantity * rate;
    final discountAmount = item.discountIsPercent
        ? gross * discount / 100
        : discount;
    final subtotal = gross - discountAmount;
    return subtotal < 0 ? 0.0 : subtotal;
  }

  double get _subTotal {
    return _items
        .where((item) => item.name.trim().isNotEmpty)
        .fold(0.0, (sum, item) => sum + _lineSubtotal(item));
  }

  double get _shippingAmount => _parseMoney(_shippingController.text);

  double get _adjustmentAmount => _parseMoney(_adjustmentController.text);

  double _taxPercentFromLabel(String? label) {
    if (label == null) return 0;
    final normalized = label.toLowerCase();
    if (normalized.contains('not taxable') ||
        normalized.contains('non-gst') ||
        normalized.contains('out of scope') ||
        normalized.contains('exempt')) {
      return 0;
    }

    return RegExp(r'(\d+(?:\.\d+)?)\s*%')
        .allMatches(label)
        .fold<double>(
          0.0,
          (sum, match) => sum + _parseMoney(match.group(1) ?? '0'),
        );
  }

  bool get _isInterStateSupply {
    final place = _selectedPlaceOfSupply?.toLowerCase().trim();
    if (place == null || place.isEmpty) return false;
    return !place.contains('[kl]') && !place.contains('kerala');
  }

  List<_CnTaxSummaryLine> get _taxSummaryLines {
    final taxableAmountsByRate = <double, double>{};

    for (final item in _items) {
      if (item.name.trim().isEmpty) continue;

      final taxRate = _taxPercentFromLabel(item.tax);
      if (taxRate <= 0) continue;

      taxableAmountsByRate.update(
        taxRate,
        (amount) => amount + _lineSubtotal(item),
        ifAbsent: () => _lineSubtotal(item),
      );
    }

    final entries = taxableAmountsByRate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final lines = <_CnTaxSummaryLine>[];
    for (final entry in entries) {
      final rate = entry.key;
      final taxableAmount = entry.value;
      if (_isInterStateSupply) {
        final rateText = _formatRate(rate);
        lines.add(
          _CnTaxSummaryLine(
            label: 'IGST$rateText [$rateText%]',
            amount: taxableAmount * rate / 100,
          ),
        );
      } else {
        final splitRate = rate / 2;
        final rateText = _formatRate(splitRate);
        final splitAmount = taxableAmount * splitRate / 100;
        lines
          ..add(
            _CnTaxSummaryLine(
              label: 'CGST$rateText [$rateText%]',
              amount: splitAmount,
            ),
          )
          ..add(
            _CnTaxSummaryLine(
              label: 'SGST$rateText [$rateText%]',
              amount: splitAmount,
            ),
          );
      }
    }

    return lines;
  }

  double get _taxSummaryAmount {
    return _taxSummaryLines.fold(0.0, (sum, line) => sum + line.amount);
  }

  double get _grandTotal {
    return _subTotal + _shippingAmount + _taxSummaryAmount + _adjustmentAmount;
  }

  @override
  Widget build(BuildContext context) {
    final taxSummaryLines = _taxSummaryLines;

    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: ZerpaiLayout(
            pageTitle: widget.creditNoteId != null
                ? 'Edit Credit Note'
                : 'New Credit Note',
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
                    ZButton.primary(label: 'Save as Draft', onPressed: () {}),
                    const SizedBox(width: 12),
                    ZButton.secondary(
                      label: 'Save and Approve',
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
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
                    _HeaderBackgroundBand(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CompactFormRow(
                              label: 'Customer Name',
                              required: true,
                              labelColor: AppTheme.errorRed,
                              fieldWidth: _selectedCustomer == null
                                  ? _customerFieldWidth
                                  : _fieldWidth,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: _customerFieldWidth,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: FormDropdown<String>(
                                            value: _selectedCustomer,
                                            items: _cnCustomerDropdownNames,
                                            hint: 'Select a customer',
                                            placeholder: 'Search',
                                            height: _fieldHeight,
                                            menuMaxHeight: 300,
                                            itemHeight: 72,
                                            displayStringForValue: (customer) =>
                                                customer,
                                            searchStringForValue: (customer) {
                                              final details =
                                                  _cnCustomerDropdownDetails[customer];
                                              return [
                                                customer,
                                                if (details != null)
                                                  details.code,
                                                if (details != null)
                                                  details.addressLine,
                                              ].join(' ');
                                            },
                                            itemBuilder:
                                                (
                                                  customer,
                                                  isSelected,
                                                  isHovered,
                                                ) {
                                                  final details =
                                                      _cnCustomerDropdownDetails[customer];
                                                  return _CnCustomerDropdownItem(
                                                    customerName: customer,
                                                    customerCode:
                                                        details?.code ??
                                                        'CUS-00000',
                                                    addressLine:
                                                        details?.addressLine ??
                                                        customer,
                                                    highlighted:
                                                        isSelected || isHovered,
                                                  );
                                                },
                                            allowClear: true,
                                            showRightBorder: false,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  bottomLeft: Radius.circular(
                                                    4,
                                                  ),
                                                ),
                                            onChanged: (val) => setState(() {
                                              _selectedCustomer = val;
                                              if (val == null) {
                                                _showCustomerDetailsPanel =
                                                    false;
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
                                              final result =
                                                  await AdvancedCustomerSearchModal.show(
                                                    context,
                                                  );
                                              if (result != null) {
                                                setState(() {
                                                  _selectedCustomer = result;
                                                  _showCustomerDetailsPanel =
                                                      false;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedCustomer != null) ...[
                                    const SizedBox(width: 12),
                                    const _CnCurrencyBadge(),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Transform.translate(
                                          offset: Offset(
                                            MediaQuery.of(context).size.width <
                                                    1000
                                                ? 16.0
                                                : 40.0,
                                            0,
                                          ),
                                          child: _CnCustomerDetailsTag(
                                            customerName: _selectedCustomer!,
                                            onTap: _openCustomerDetails,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_selectedCustomer == null)
                              _CompactFormRow(
                                label: 'Reason',
                                fieldWidth: 330,
                                child: FormDropdown<String>(
                                  value: _selectedReason,
                                  items: const [
                                    'Damaged',
                                    'Wrong item',
                                    'Other',
                                  ],
                                  hint: 'Select a reason',
                                  height: _fieldHeight,
                                  onChanged: (val) =>
                                      setState(() => _selectedReason = val),
                                ),
                              ),
                            if (_selectedCustomer != null) ...[
                              _CnCustomerAddressPanel(
                                customerName: _selectedCustomer!,
                                width: _customerFieldWidth,
                              ),
                              _CompactFormRow(
                                label: 'Place of Supply',
                                required: true,
                                labelColor: AppTheme.errorRed,
                                fieldWidth: 330,
                                child: FormDropdown<String>(
                                  value: _selectedPlaceOfSupply,
                                  items: const [
                                    '[KL] - Kerala',
                                    '[TN] - Tamil Nadu',
                                    '[KA] - Karnataka',
                                  ],
                                  hint: 'Select Place of Supply',
                                  height: _fieldHeight,
                                  onChanged: (val) => setState(
                                    () => _selectedPlaceOfSupply = val,
                                  ),
                                ),
                              ),
                              _CompactFormRow(
                                label: 'Invoice#',
                                fieldWidth: 330,
                                child: FormDropdown<String>(
                                  value: _selectedInvoiceNumber,
                                  items: const [
                                    'INV-001',
                                    'INV-002',
                                    'INV-003',
                                  ],
                                  hint: 'Select Invoice',
                                  height: _fieldHeight,
                                  onChanged: (val) => setState(
                                    () => _selectedInvoiceNumber = val,
                                  ),
                                ),
                              ),
                              _CompactFormRow(
                                label: 'Invoice Type',
                                fieldWidth: 330,
                                child: FormDropdown<String>(
                                  value: _selectedInvoiceType,
                                  items: const [
                                    'Tax Invoice',
                                    'Bill of Supply',
                                  ],
                                  hint: 'Select Invoice Type',
                                  height: _fieldHeight,
                                  onChanged: (val) => setState(
                                    () => _selectedInvoiceType = val,
                                  ),
                                ),
                              ),
                              _CompactFormRow(
                                label: 'Reason',
                                fieldWidth: 330,
                                child: FormDropdown<String>(
                                  value: _selectedReason,
                                  items: const [
                                    'Damaged',
                                    'Wrong item',
                                    'Other',
                                  ],
                                  hint: 'Select a reason',
                                  height: _fieldHeight,
                                  onChanged: (val) =>
                                      setState(() => _selectedReason = val),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // --- Credit Note Section ---
                    _CompactFormRow(
                      label: 'Credit Note#',
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
                                'Manual',
                              ],
                              height: _fieldHeight,
                              onChanged: (val) => setState(
                                () => _selectedTransactionSeries = val,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: _rmaNumberController,
                              suffixWidget: ZTooltip(
                                message:
                                    'Click here to enable or disable auto-generation of Credit Note numbers.',
                                child: GestureDetector(
                                  onTap: _showRmaPreferencesDialog,
                                  child: const Icon(
                                    LucideIcons.settings,
                                    size: 14,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              height: _fieldHeight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CompactFormRow(
                      label: 'Reference#',
                      fieldWidth: 330,
                      child: CustomTextField(
                        controller: _referenceNumberController,
                        height: _fieldHeight,
                      ),
                    ),
                    _CompactFormRow(
                      label: 'Credit Note Date',
                      required: true,
                      labelColor: AppTheme.errorRed,
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
                        height: _fieldHeight,
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: AppTheme.borderLight),
                    ),

                    _CompactFormRow(
                      label: 'Salesperson',
                      fieldWidth: 330,
                      child: FormDropdown<String>(
                        value: _selectedSalesperson,
                        items: const ['John Doe', 'Jane Smith'],
                        hint: 'Select or Add Salesperson',
                        height: _fieldHeight,
                        onChanged: (val) =>
                            setState(() => _selectedSalesperson = val),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: AppTheme.borderLight),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            child: Row(
                              children: const [
                                Text(
                                  'Subject',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(width: 4),
                                ZTooltip(
                                  message:
                                      'You can enter up to 250 characters. If you do not require this field, you can mark it as inactive under credit note preferences.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 434,
                            child: CustomTextField(
                              hintText:
                                  'Let your customer know what this Credit Note is for',
                              height: _fieldHeight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Item Table Toolbar ---
                    _ItemTableToolbar(
                      warehouseLocation: _warehouseLocation,
                      warehouseOptions: const [
                        'ZABNIX PRIVATE LIMITED',
                        'WAREHOUSE 2',
                        'PRIMARY WAREHOUSE',
                        'SECONDARY WAREHOUSE',
                      ],
                      onWarehouseChanged: (val) =>
                          setState(() => _warehouseLocation = val),
                      priceLevel: _priceLevel,
                      priceLevelOptions: const [
                        'At Transaction Level',
                        'Sales Price',
                        'Purchase Price',
                        'Marked Price',
                      ],
                      onPriceLevelChanged: (val) =>
                          setState(() => _priceLevel = val),
                      selectedPriceList: _selectedPriceList,
                      priceListOptions: const [
                        'Standard Selling',
                        'Wholesale Price',
                        'Retail Price',
                      ],
                      onPriceListChanged: (val) =>
                          setState(() => _selectedPriceList = val),
                    ),
                    const SizedBox(height: 16),

                    // --- Items Grid ---
                    _CnItemsGrid(
                      items: _items,
                      creditOnly: _creditOnlyGoods,
                      warehouse: _warehouseLocation,
                      onInsertItem: _insertItemAfter,
                      onCloneItem: _cloneItem,
                      onRemoveItem: _removeItem,
                      onAddItem: _addItem,
                      onAddBulkItems: _showBulkItemsDialog,
                      onItemSelected: (index) {
                        if (index == _items.length - 1) {
                          _addItem();
                        } else {
                          setState(() {});
                        }
                      },
                      onViewItemDetails: _openItemDetails,
                      onEditItem: _openEditItem,
                      onTotalsChanged: () => setState(() {}),
                      onAddBatches: _openBatchDialog,
                    ),

                    const SizedBox(height: 32),

                    // --- Summary Section ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Customer Notes
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer Notes',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _customerNotesController,
                                hintText:
                                    'Will be displayed on the credit note',
                                maxLines: 4,
                                height: 100,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        // Totals
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
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
                                // Shipping Charges
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 120,
                                        child: Text(
                                          'Shipping\nCharges',
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
                                          controller: _shippingController,
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
                                            'Amount spent on shipping the goods.',
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          _formatMoney(_shippingAmount),
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
                                if (taxSummaryLines.isNotEmpty) ...[
                                  const Divider(
                                    height: 1,
                                    color: AppTheme.borderLight,
                                  ),
                                  _buildGstSummaryRows(taxSummaryLines),
                                ],
                                // TDS / TCS and Adjustment order depends on selection
                                // TDS selected: TDS row first, Adjustment below
                                // TCS selected: Adjustment above, TCS row below
                                if (_taxType == 'TDS') ...[
                                  _buildTaxRow(),
                                  _buildAdjustmentRow(),
                                ] else ...[
                                  _buildAdjustmentRow(),
                                  _buildTaxRow(),
                                ],
                                // Round Off
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    12,
                                    20,
                                    12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Round Off',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          _formatMoney(0),
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
                                      Text(
                                        'Total (₹)',
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

                    // --- Terms & Conditions ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: CustomTextField(
                            controller: _termsController,
                            hintText:
                                'Enter the terms and conditions of your business to be displayed in your transaction',
                            maxLines: 5,
                            height: 120,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 24),

                    // --- Email Communications (visible only after customer is selected) ---
                    if (_selectedCustomer != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email Communications',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Add New button (dashed border)
                              InkWell(
                                onTap: _showAddContactPersonDialog,
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF6B7280),
                                      width: 1.2,
                                      // Dashed via custom painter not supported directly;
                                      // use a DashedBorderContainer alternative:
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        LucideIcons.plusCircle,
                                        size: 15,
                                        color: Color(0xFF4F46E5),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Add New',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                LucideIcons.alertTriangle,
                                size: 16,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'No contact persons found.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 24),
                    ],

                    // --- Additional Fields ---
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Additional Fields: ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text:
                                'Start adding custom fields for your credit notes by going to ',
                          ),
                          TextSpan(
                            text: 'Settings',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          TextSpan(text: ' → '),
                          TextSpan(
                            text: 'Sales',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          TextSpan(text: ' → '),
                          TextSpan(
                            text: 'Credit Notes',
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
        ),
        if (_showItemDetailsPanel && _detailsItem != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 380,
            child: _CnItemDetailsSidePanel(
              item: _detailsItem!,
              onClose: () => setState(() {
                _showItemDetailsPanel = false;
                _detailsItem = null;
              }),
            ),
          ),
        if (_showCustomerDetailsPanel && _selectedCustomer != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 440,
            child: _CnCustomerDetailsSidePanel(
              customerName: _selectedCustomer!,
              onClose: () => setState(() => _showCustomerDetailsPanel = false),
            ),
          ),
      ],
    );
  }

  Widget _buildGstSummaryRows(List<_CnTaxSummaryLine> lines) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            height: (lines.length * 34).toDouble(),
            color: AppTheme.borderLight,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            line.label,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: Text(
                            _formatMoney(line.amount),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
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
      ),
    );
  }

  Widget _buildTaxRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Radio<String>(
                  value: 'TDS',
                  groupValue: _taxType,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _taxType = val!),
                ),
                const Text(
                  'TDS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Radio<String>(
                  value: 'TCS',
                  groupValue: _taxType,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => setState(() => _taxType = val!),
                ),
                const Text(
                  'TCS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.tight,
            child: FormDropdown<String>(
              value: _selectedTaxRate,
              items: const ['5%', '10%', '15%', '20%', '28%'],
              hint: 'Select a Tax',
              height: 34,
              onChanged: (val) => setState(() => _selectedTaxRate = val),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              _taxType == 'TDS' ? '- 0.00' : '0.00',
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
    );
  }

  Widget _buildAdjustmentRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Text(
              'Adjustment',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
                'Add any other +ve or -ve charges that need to be applied to adjust the total amount of the transaction. Eg. +10 or -10.',
            maxWidth: 280,
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
    );
  }
}

class _CnTaxOption {
  final String label;
  final String? description;
  final bool isHeader;

  const _CnTaxOption({
    required this.label,
    this.description,
    this.isHeader = false,
  });
}

final List<_CnTaxOption> _cnTaxOptions = [
  const _CnTaxOption(
    label: 'Non-Taxable',
    description: 'Supply is exempt from GST. Exemption reason required.',
  ),
  const _CnTaxOption(
    label: 'Out of Scope',
    description:
        'Supplies on which you don\'t charge any GST or include them in the returns.',
  ),
  const _CnTaxOption(
    label: 'Non-GST Supply',
    description:
        'Supplies which do not come under GST such as petroleum products and liquor.',
  ),
  const _CnTaxOption(label: 'Taxable', isHeader: true),
  const _CnTaxOption(label: 'GST 0%', description: '0%'),
  const _CnTaxOption(label: 'GST 5%', description: '[5%]'),
  const _CnTaxOption(label: 'GST 12%', description: '[12%]'),
  const _CnTaxOption(label: 'GST 18%', description: '[18%]'),
  const _CnTaxOption(label: 'GST 28%', description: '[28%]'),
  const _CnTaxOption(label: 'Taxable Group', isHeader: true),
  const _CnTaxOption(label: 'GST 5% + GST 12%', description: '[17%]'),
];

class _CnLineItem {
  String name;
  String description;
  String shipped;
  String returned;
  TextEditingController returnQtyController;
  TextEditingController descriptionController;
  TextEditingController rateController;
  TextEditingController discountController;
  bool discountIsPercent;
  String stock;
  String hsnCode;
  String? discount;
  String? reportingTag;
  String? account;
  String? tax;
  String? exemptionReason;
  String? warehouseLocation;
  String? priceList;
  List<_CnBatch> savedBatches = [];
  Map<String, String?> selectedTagValues = {};
  double costPrice;
  // Full item reference for edit dialog
  Item? sourceItem;

  _CnLineItem({
    required this.name,
    this.description = '',
    required this.shipped,
    required this.returned,
    required String returnQty,
    required this.stock,
    this.hsnCode = '30049084',
    this.discount,
    this.reportingTag,
    this.account,
    this.tax = 'GST 5%',
    String rate = '',
    String discountValue = '',
    this.discountIsPercent = true,
    this.costPrice = 0.0,
  }) : returnQtyController = TextEditingController(text: returnQty),
       descriptionController = TextEditingController(text: description),
       rateController = TextEditingController(text: rate),
       discountController = TextEditingController(text: discountValue);

  void dispose() {
    returnQtyController.dispose();
    descriptionController.dispose();
    rateController.dispose();
    discountController.dispose();
  }
}

class _CnTaxSummaryLine {
  final String label;
  final double amount;

  const _CnTaxSummaryLine({required this.label, required this.amount});
}

/// Custom Compact Form Row with Overflow Fixes
class _CompactFormRow extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final double? fieldWidth;
  final Color labelColor;

  const _CompactFormRow({
    required this.label,
    this.required = false,
    required this.child,
    this.fieldWidth,
    this.labelColor = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final requestedFieldWidth = fieldWidth ?? 434;
        final availableFieldWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth - 150 - 16
            : requestedFieldWidth;
        final effectiveFieldWidth = availableFieldWidth < requestedFieldWidth
            ? (availableFieldWidth > 0 ? availableFieldWidth : 0.0)
            : requestedFieldWidth;

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
              SizedBox(width: effectiveFieldWidth, child: child),
            ],
          ),
        );
      },
    );
  }
}

const List<String> _cnCustomerDropdownNames = [
  'SAHAKAR MEDICALS AND SURGICALS HYPER STORE LLP',
  'SAHAKAR MEDICALS AND SURGICALS THRISSUR LLP',
  'SAHAKAR MEDICALS AND SURGICALS TIRUR LLP',
  'Walk-in Customer',
  'Customer 1',
  'Customer 2',
  'CUS-1',
  'CUS-2',
  'CUS-3',
];

const Map<String, _CnCustomerDropdownDetails> _cnCustomerDropdownDetails = {
  'SAHAKAR MEDICALS AND SURGICALS HYPER STORE LLP': _CnCustomerDropdownDetails(
    code: 'CUS-00016',
    addressLine: 'SAHAKAR MEDICALS AND SURGICALS MAKKARAPARAMBA',
  ),
  'SAHAKAR MEDICALS AND SURGICALS THRISSUR LLP': _CnCustomerDropdownDetails(
    code: 'CUS-00015',
    addressLine: 'SAHAKAR MEDICALS AND SURGICALS THRISSUR LLP',
  ),
  'SAHAKAR MEDICALS AND SURGICALS TIRUR LLP': _CnCustomerDropdownDetails(
    code: 'CUS-00017',
    addressLine: 'SAHAKAR MEDICALS AND SURGICALS TIRUR LLP',
  ),
  'Walk-in Customer': _CnCustomerDropdownDetails(
    code: 'CUS-00009',
    addressLine: 'Walk-in Customer',
  ),
  'Customer 1': _CnCustomerDropdownDetails(
    code: 'CUS-00001',
    addressLine: 'malayanakath(h), vengoor (po)',
  ),
  'Customer 2': _CnCustomerDropdownDetails(
    code: 'CUS-00002',
    addressLine: 'malayanakath(h), vengoor',
  ),
  'CUS-1': _CnCustomerDropdownDetails(
    code: 'CUS-00003',
    addressLine: 'THARAVADU STARLEX, Mysuru - Ooty Rd',
  ),
  'CUS-2': _CnCustomerDropdownDetails(
    code: 'CUS-00004',
    addressLine: 'malayanakath(h), perinthalmanna',
  ),
  'CUS-3': _CnCustomerDropdownDetails(
    code: 'CUS-00005',
    addressLine: 'Kerala 679322, India',
  ),
};

class _CnCustomerDropdownDetails {
  final String code;
  final String addressLine;

  const _CnCustomerDropdownDetails({
    required this.code,
    required this.addressLine,
  });
}

class _CnCustomerDropdownItem extends StatelessWidget {
  final String customerName;
  final String customerCode;
  final String addressLine;
  final bool highlighted;

  const _CnCustomerDropdownItem({
    required this.customerName,
    required this.customerCode,
    required this.addressLine,
    required this.highlighted,
  });

  String get _initial {
    final trimmed = customerName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = highlighted
        ? AppTheme.backgroundColor
        : AppTheme.textBody;
    final secondaryColor = highlighted
        ? AppTheme.backgroundColor
        : AppTheme.textSecondary;

    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.primaryBlue : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.bgDisabled,
              shape: BoxShape.circle,
              border: highlighted
                  ? Border.all(color: AppTheme.backgroundColor, width: 1.5)
                  : null,
            ),
            child: Text(
              _initial,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '|',
                        style: TextStyle(fontSize: 14, color: secondaryColor),
                      ),
                    ),
                    Text(
                      customerCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      LucideIcons.building2,
                      size: 14,
                      color: secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        addressLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewCustomerFormDialog extends StatefulWidget {
  final VoidCallback onClose;

  const _NewCustomerFormDialog({required this.onClose});

  @override
  State<_NewCustomerFormDialog> createState() => _NewCustomerFormDialogState();
}

class _NewCustomerFormDialogState extends State<_NewCustomerFormDialog> {
  static const double _labelWidth = 240;
  static const double _fieldHeight = 36;
  static const double _maxSheetWidth = 1480;
  static const double _minContentWidth = 760;
  static const double _singleFieldWidth = 410;
  static const double _addressColumnWidth = 360;
  static const double _addressLabelWidth = 108;
  static const double _addressFieldWidth = 252;

  String _customerType = 'Individual';
  String? _salutation;
  String? _displayName;
  String _customerLanguage = 'English';
  String? _gstTreatment;
  String? _placeOfSupply;
  String _taxPreference = 'Taxable';
  String _currency = 'INR- Indian Rupee';
  String _paymentTerms = 'Net 360';
  String _workPhonePrefix = '+91';
  String _mobilePrefix = '+91';
  String? _billingCountry;
  String? _billingState;
  String _billingPhonePrefix = '+91';
  String? _shippingCountry;
  String? _shippingState;
  String _shippingPhonePrefix = '+91';
  String? _priceList;
  bool _enablePortal = false;
  String _activeTab = 'Other Details';
  List<PlatformFile> _documents = [];

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _customerNumberController;
  late final TextEditingController _workPhoneController;
  late final TextEditingController _mobileController;
  late final TextEditingController _panController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _billingAttentionController;
  late final TextEditingController _billingStreet1Controller;
  late final TextEditingController _billingStreet2Controller;
  late final TextEditingController _billingCityController;
  late final TextEditingController _billingPinCodeController;
  late final TextEditingController _billingPhoneController;
  late final TextEditingController _billingFaxController;
  late final TextEditingController _shippingAttentionController;
  late final TextEditingController _shippingStreet1Controller;
  late final TextEditingController _shippingStreet2Controller;
  late final TextEditingController _shippingCityController;
  late final TextEditingController _shippingPinCodeController;
  late final TextEditingController _shippingPhoneController;
  late final TextEditingController _shippingFaxController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _companyNameController = TextEditingController();
    _emailController = TextEditingController();
    _customerNumberController = TextEditingController(text: 'CUS-00023');
    _workPhoneController = TextEditingController();
    _mobileController = TextEditingController();
    _panController = TextEditingController();
    _creditLimitController = TextEditingController();
    _billingAttentionController = TextEditingController();
    _billingStreet1Controller = TextEditingController();
    _billingStreet2Controller = TextEditingController();
    _billingCityController = TextEditingController();
    _billingPinCodeController = TextEditingController();
    _billingPhoneController = TextEditingController();
    _billingFaxController = TextEditingController();
    _shippingAttentionController = TextEditingController();
    _shippingStreet1Controller = TextEditingController();
    _shippingStreet2Controller = TextEditingController();
    _shippingCityController = TextEditingController();
    _shippingPinCodeController = TextEditingController();
    _shippingPhoneController = TextEditingController();
    _shippingFaxController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _customerNumberController.dispose();
    _workPhoneController.dispose();
    _mobileController.dispose();
    _panController.dispose();
    _creditLimitController.dispose();
    _billingAttentionController.dispose();
    _billingStreet1Controller.dispose();
    _billingStreet2Controller.dispose();
    _billingCityController.dispose();
    _billingPinCodeController.dispose();
    _billingPhoneController.dispose();
    _billingFaxController.dispose();
    _shippingAttentionController.dispose();
    _shippingStreet1Controller.dispose();
    _shippingStreet2Controller.dispose();
    _shippingCityController.dispose();
    _shippingPinCodeController.dispose();
    _shippingPhoneController.dispose();
    _shippingFaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final candidateSheetWidth = size.width < 1000
        ? size.width
        : size.width * 0.72;
    final sheetWidth = candidateSheetWidth > _maxSheetWidth
        ? _maxSheetWidth
        : candidateSheetWidth;
    final contentCandidateWidth = sheetWidth - 48;
    final contentWidth = contentCandidateWidth < _minContentWidth
        ? _minContentWidth
        : contentCandidateWidth;

    return SizedBox(
      width: sheetWidth,
      height: size.height,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppTheme.backgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: AppTheme.bgLight,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  const Text(
                    'New Customer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        LucideIcons.x,
                        size: 20,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 44),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopSection(),
                        const SizedBox(height: 42),
                        _buildTabs(),
                        const SizedBox(height: 34),
                        if (_activeTab == 'Other Details')
                          _buildOtherDetails()
                        else if (_activeTab == 'Address')
                          _buildAddressDetails()
                        else
                          const SizedBox(height: 180),
                        const SizedBox(height: 28),
                        _buildAddMoreDetailsLink(),
                        const SizedBox(height: 84),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CustomerDialogRow(
          label: 'Customer Type',
          labelWidth: _labelWidth,
          info: true,
          child: Row(
            children: [
              _CustomerTypeOption(
                value: 'Business',
                groupValue: _customerType,
                onChanged: (value) => setState(() => _customerType = value),
              ),
              const SizedBox(width: 24),
              _CustomerTypeOption(
                value: 'Individual',
                groupValue: _customerType,
                onChanged: (value) => setState(() => _customerType = value),
              ),
            ],
          ),
        ),
        _CustomerDialogRow(
          label: 'Primary Contact',
          labelWidth: _labelWidth,
          info: true,
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: FormDropdown<String>(
                  value: _salutation,
                  items: const ['Mr.', 'Mrs.', 'Ms.', 'Dr.'],
                  hint: 'Salutation',
                  height: _fieldHeight,
                  onChanged: (value) => setState(() => _salutation = value),
                ),
              ),
              SizedBox(
                width: 200,
                child: CustomTextField(
                  controller: _firstNameController,
                  hintText: 'First Name',
                  height: _fieldHeight,
                  autoFocus: true,
                ),
              ),
              SizedBox(
                width: 200,
                child: CustomTextField(
                  controller: _lastNameController,
                  hintText: 'Last Name',
                  height: _fieldHeight,
                ),
              ),
            ],
          ),
        ),
        _CustomerDialogRow(
          label: 'Company Name',
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: CustomTextField(
              controller: _companyNameController,
              height: _fieldHeight,
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'Display Name',
          required: true,
          info: true,
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: FormDropdown<String>(
              value: _displayName,
              items: const ['First Name Last Name', 'Company Name'],
              hint: 'Select or type to add',
              height: _fieldHeight,
              allowCustomValue: true,
              onChanged: (value) => setState(() => _displayName = value),
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'Email Address',
          info: true,
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: CustomTextField(
              controller: _emailController,
              height: _fieldHeight,
              prefixIcon: LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'Customer Number',
          required: true,
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: CustomTextField(
              controller: _customerNumberController,
              height: _fieldHeight,
              suffixWidget: const Icon(
                LucideIcons.settings,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'Phone',
          info: true,
          labelWidth: _labelWidth,
          child: Wrap(
            spacing: 32,
            runSpacing: 10,
            children: [
              _PhoneEntry(
                selectedPrefix: _workPhonePrefix,
                controller: _workPhoneController,
                hintText: 'Work Phone',
                onPrefixChanged: (value) =>
                    setState(() => _workPhonePrefix = value ?? '+91'),
              ),
              _PhoneEntry(
                selectedPrefix: _mobilePrefix,
                controller: _mobileController,
                hintText: 'Mobile',
                onPrefixChanged: (value) =>
                    setState(() => _mobilePrefix = value ?? '+91'),
              ),
            ],
          ),
        ),
        _CustomerDialogRow(
          label: 'Customer Language',
          infoBelow: true,
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: FormDropdown<String>(
              value: _customerLanguage,
              items: const ['English', 'Hindi', 'Malayalam'],
              height: _fieldHeight,
              onChanged: (value) {
                if (value != null) setState(() => _customerLanguage = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    const tabs = [
      'Other Details',
      'Address',
      'Custom Fields',
      'Reporting Tags',
      'Remarks',
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            _CustomerDialogTab(
              label: tab,
              selected: _activeTab == tab,
              onTap: () => setState(() => _activeTab = tab),
            ),
        ],
      ),
    );
  }

  Widget _buildOtherDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CustomerDialogRow(
          label: 'GST Treatment',
          required: true,
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: FormDropdown<String>(
              value: _gstTreatment,
              items: const [
                'Registered Business',
                'Unregistered Business',
                'Consumer',
              ],
              hint: 'Select a GST treatment',
              height: _fieldHeight,
              onChanged: (value) => setState(() => _gstTreatment = value),
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'Place of Supply',
          required: true,
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: FormDropdown<String>(
              value: _placeOfSupply,
              items: const [
                '[KL] - Kerala',
                '[TN] - Tamil Nadu',
                '[KA] - Karnataka',
              ],
              height: _fieldHeight,
              onChanged: (value) => setState(() => _placeOfSupply = value),
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'PAN',
          info: true,
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: CustomTextField(
              controller: _panController,
              height: _fieldHeight,
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'Tax Preference',
          required: true,
          labelWidth: _labelWidth,
          child: Row(
            children: [
              _CustomerTypeOption(
                value: 'Taxable',
                groupValue: _taxPreference,
                onChanged: (value) => setState(() => _taxPreference = value),
              ),
              const SizedBox(width: 24),
              _CustomerTypeOption(
                value: 'Tax Exempt',
                groupValue: _taxPreference,
                onChanged: (value) => setState(() => _taxPreference = value),
              ),
            ],
          ),
        ),
        _CustomerDialogRow(
          label: 'Currency',
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: FormDropdown<String>(
              value: _currency,
              items: const ['INR- Indian Rupee', 'USD- US Dollar'],
              height: _fieldHeight,
              onChanged: (value) {
                if (value != null) setState(() => _currency = value);
              },
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'Credit Limit',
          info: true,
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: _fieldHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'INR',
                    style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ),
                Expanded(
                  child: CustomTextField(
                    controller: _creditLimitController,
                    height: _fieldHeight,
                    showLeftBorder: false,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'Payment Terms',
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: FormDropdown<String>(
              value: _paymentTerms,
              items: const ['Net 15', 'Net 30', 'Net 360'],
              height: _fieldHeight,
              onChanged: (value) {
                if (value != null) setState(() => _paymentTerms = value);
              },
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'Price List',
          required: true,
          labelWidth: _labelWidth,
          child: SizedBox(
            width: _singleFieldWidth,
            child: FormDropdown<String>(
              value: _priceList,
              items: const [
                'Retail Price',
                'Wholesale Price',
                'Standard Selling',
              ],
              height: _fieldHeight,
              onChanged: (value) => setState(() => _priceList = value),
            ),
          ),
        ),
        _CustomerDialogRow(
          label: 'Enable Portal?',
          info: true,
          labelWidth: _labelWidth,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _enablePortal,
                  activeColor: AppTheme.infoBlue,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) =>
                      setState(() => _enablePortal = value ?? false),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Allow portal access for this customer',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        _CustomerDialogRow(
          label: 'Documents',
          labelWidth: _labelWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FileUploadButton(
                    files: _documents,
                    maxFiles: 10,
                    onFilesChanged: (files) =>
                        setState(() => _documents = files),
                  ),
                  Container(
                    height: 34,
                    width: 38,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      border: Border(
                        top: BorderSide(color: AppTheme.borderColor),
                        right: BorderSide(color: AppTheme.borderColor),
                        bottom: BorderSide(color: AppTheme.borderColor),
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'You can upload a maximum of 10 files, 10MB each',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyBillingAddressToShipping() {
    setState(() {
      _shippingAttentionController.text = _billingAttentionController.text;
      _shippingStreet1Controller.text = _billingStreet1Controller.text;
      _shippingStreet2Controller.text = _billingStreet2Controller.text;
      _shippingCityController.text = _billingCityController.text;
      _shippingPinCodeController.text = _billingPinCodeController.text;
      _shippingPhoneController.text = _billingPhoneController.text;
      _shippingFaxController.text = _billingFaxController.text;
      _shippingCountry = _billingCountry;
      _shippingState = _billingState;
      _shippingPhonePrefix = _billingPhonePrefix;
    });
  }

  Widget _buildAddressDetails() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _addressColumnWidth,
          child: _buildAddressColumn(
            title: const Text(
              'Billing Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            attentionController: _billingAttentionController,
            country: _billingCountry,
            onCountryChanged: (value) =>
                setState(() => _billingCountry = value),
            street1Controller: _billingStreet1Controller,
            street2Controller: _billingStreet2Controller,
            cityController: _billingCityController,
            state: _billingState,
            onStateChanged: (value) => setState(() => _billingState = value),
            pinCodeController: _billingPinCodeController,
            phonePrefix: _billingPhonePrefix,
            onPhonePrefixChanged: (value) =>
                setState(() => _billingPhonePrefix = value ?? '+91'),
            phoneController: _billingPhoneController,
            faxController: _billingFaxController,
          ),
        ),
        const SizedBox(width: 64),
        SizedBox(
          width: _addressColumnWidth,
          child: _buildAddressColumn(
            title: Row(
              children: [
                const Text(
                  'Shipping Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '(',
                  style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                ),
                InkWell(
                  onTap: _copyBillingAddressToShipping,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.arrowDown,
                          size: 15,
                          color: AppTheme.primaryBlue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Copy billing address',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Text(
                  ')',
                  style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                ),
              ],
            ),
            attentionController: _shippingAttentionController,
            country: _shippingCountry,
            onCountryChanged: (value) =>
                setState(() => _shippingCountry = value),
            street1Controller: _shippingStreet1Controller,
            street2Controller: _shippingStreet2Controller,
            cityController: _shippingCityController,
            state: _shippingState,
            onStateChanged: (value) => setState(() => _shippingState = value),
            pinCodeController: _shippingPinCodeController,
            phonePrefix: _shippingPhonePrefix,
            onPhonePrefixChanged: (value) =>
                setState(() => _shippingPhonePrefix = value ?? '+91'),
            phoneController: _shippingPhoneController,
            faxController: _shippingFaxController,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressColumn({
    required Widget title,
    required TextEditingController attentionController,
    required String? country,
    required ValueChanged<String?> onCountryChanged,
    required TextEditingController street1Controller,
    required TextEditingController street2Controller,
    required TextEditingController cityController,
    required String? state,
    required ValueChanged<String?> onStateChanged,
    required TextEditingController pinCodeController,
    required String phonePrefix,
    required ValueChanged<String?> onPhonePrefixChanged,
    required TextEditingController phoneController,
    required TextEditingController faxController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 28,
          child: Align(alignment: Alignment.centerLeft, child: title),
        ),
        const SizedBox(height: 28),
        _buildAddressRow(
          label: 'Attention',
          child: _buildAddressTextField(attentionController),
        ),
        _buildAddressRow(
          label: 'Country/Region',
          child: _buildAddressDropdown(
            value: country,
            items: const ['India', 'United States', 'United Kingdom'],
            hint: 'Select',
            onChanged: onCountryChanged,
          ),
        ),
        _buildAddressRow(
          label: 'Address',
          alignTop: true,
          child: Column(
            children: [
              _buildAddressTextField(
                street1Controller,
                hintText: 'Street 1',
                height: 58,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildAddressTextField(
                street2Controller,
                hintText: 'Street 2',
                height: 58,
                maxLines: 2,
              ),
            ],
          ),
        ),
        _buildAddressRow(
          label: 'City',
          child: _buildAddressTextField(cityController),
        ),
        _buildAddressRow(
          label: 'State',
          child: _buildAddressDropdown(
            value: state,
            items: const ['Kerala', 'Tamil Nadu', 'Karnataka'],
            hint: 'Select or type to add',
            allowCustomValue: true,
            onChanged: onStateChanged,
          ),
        ),
        _buildAddressRow(
          label: 'Pin Code',
          child: _buildAddressTextField(
            pinCodeController,
            keyboardType: TextInputType.number,
          ),
        ),
        _buildAddressRow(
          label: 'Phone',
          child: _PhoneEntry(
            width: _addressFieldWidth,
            selectedPrefix: phonePrefix,
            controller: phoneController,
            hintText: '',
            onPrefixChanged: onPhonePrefixChanged,
          ),
        ),
        _buildAddressRow(
          label: 'Fax Number',
          child: _buildAddressTextField(faxController),
        ),
      ],
    );
  }

  Widget _buildAddressRow({
    required String label,
    required Widget child,
    bool alignTop = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: alignTop
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _addressLabelWidth,
            child: Padding(
              padding: EdgeInsets.only(top: alignTop ? 8 : 0),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(width: _addressFieldWidth, child: child),
        ],
      ),
    );
  }

  Widget _buildAddressTextField(
    TextEditingController controller, {
    String? hintText,
    double? height,
    int? maxLines,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return CustomTextField(
      controller: controller,
      hintText: hintText,
      height: height ?? _fieldHeight,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      contentCase: ContentCase.none,
      textStyle: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
    );
  }

  Widget _buildAddressDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    bool allowCustomValue = false,
  }) {
    return FormDropdown<String>(
      value: value,
      items: items,
      hint: hint,
      height: _fieldHeight,
      allowCustomValue: allowCustomValue,
      textStyle: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      onChanged: onChanged,
    );
  }

  Widget _buildAddMoreDetailsLink() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => setState(() => _activeTab = 'Other Details'),
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Text(
            'Add more details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          ZButton.primary(label: 'Save', onPressed: widget.onClose),
          const SizedBox(width: 8),
          ZButton.secondary(label: 'Cancel', onPressed: widget.onClose),
        ],
      ),
    );
  }
}

class _CustomerDialogRow extends StatelessWidget {
  final String label;
  final bool required;
  final bool info;
  final bool infoBelow;
  final double labelWidth;
  final Widget child;

  const _CustomerDialogRow({
    required this.label,
    required this.child,
    required this.labelWidth,
    this.required = false,
    this.info = false,
    this.infoBelow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: infoBelow
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: EdgeInsets.only(top: infoBelow ? 2 : 0),
              child: infoBelow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          required ? '$label*' : label,
                          style: TextStyle(
                            fontSize: 14,
                            color: required
                                ? AppTheme.errorRed
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const ZTooltip(
                          message: 'Additional information for this field.',
                        ),
                      ],
                    )
                  : Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 8,
                      children: [
                        Text(
                          required ? '$label*' : label,
                          style: TextStyle(
                            fontSize: 14,
                            color: required
                                ? AppTheme.errorRed
                                : AppTheme.textPrimary,
                          ),
                        ),
                        if (info)
                          const ZTooltip(
                            message: 'Additional information for this field.',
                          ),
                      ],
                    ),
            ),
          ),
          Flexible(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ],
      ),
    );
  }
}

class _CustomerTypeOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _CustomerTypeOption({
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            activeColor: AppTheme.infoBlue,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (selected) {
              if (selected != null) onChanged(selected);
            },
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _PhoneEntry extends StatelessWidget {
  final double width;
  final String selectedPrefix;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String?> onPrefixChanged;

  const _PhoneEntry({
    this.width = 225,
    required this.selectedPrefix,
    required this.controller,
    required this.hintText,
    required this.onPrefixChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: FormDropdown<String>(
              value: selectedPrefix,
              items: phonePrefixOptions,
              hint: '+91',
              height: _NewCustomerFormDialogState._fieldHeight,
              showSearch: false,
              menuWidth: 260,
              displayStringForValue: (value) => value,
              searchStringForValue: (value) =>
                  phonePrefixLabels[value] ?? value,
              itemBuilder: (item, isSelected, isHovered) {
                return Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  color: isHovered
                      ? AppTheme.primaryBlue
                      : AppTheme.backgroundColor,
                  child: Text(
                    phonePrefixLabels[item] ?? item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isHovered
                          ? AppTheme.backgroundColor
                          : AppTheme.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                );
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
              onChanged: onPrefixChanged,
            ),
          ),
          Expanded(
            child: CustomTextField(
              controller: controller,
              hintText: hintText,
              height: _NewCustomerFormDialogState._fieldHeight,
              keyboardType: TextInputType.phone,
              contentCase: ContentCase.none,
              showLeftBorder: false,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerDialogTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CustomerDialogTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 0, 42, 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.infoBlue : AppTheme.borderLight,
              width: selected ? 4 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CnCurrencyBadge extends StatelessWidget {
  const _CnCurrencyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _CreditNoteCreatePageState._fieldHeight,
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

class _CnCustomerDetailsTag extends StatelessWidget {
  final String customerName;
  final VoidCallback onTap;

  const _CnCustomerDetailsTag({
    required this.customerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 360.0;
        final tagWidth = availableWidth < 360.0 ? availableWidth : 360.0;

        return Material(
          color: AppTheme.textSecondary,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: tagWidth.clamp(0.0, 220.0),
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.backgroundColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: AppTheme.backgroundColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HelpPopover extends StatefulWidget {
  final Widget child;
  const _HelpPopover({required this.child});

  @override
  State<_HelpPopover> createState() => _HelpPopoverState();
}

class _HelpPopoverState extends State<_HelpPopover> {
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();

  void _togglePopover() {
    if (_entry != null) {
      _entry!.remove();
      _entry = null;
    } else {
      _entry = _createOverlayEntry();
      Overlay.of(context).insert(_entry!);
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePopover,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: 280,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(10, -40),
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBulletRow(
                            'Enable this option if your sales return contains items that are damaged or expired.',
                          ),
                          const SizedBox(height: 12),
                          _buildBulletRow(
                            'The quantity specified under this category will not be brought back into stock.',
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: -8,
                      top: 40,
                      child: CustomPaint(
                        size: const Size(8, 12),
                        painter: _PopoverArrowPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: Colors.black),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(onTap: _togglePopover, child: widget.child),
    );
  }
}

class _WarehouseStockPopover extends StatefulWidget {
  final Widget child;
  final String currentWarehouse;
  final ValueChanged<String> onWarehouseSelected;

  const _WarehouseStockPopover({
    required this.child,
    required this.currentWarehouse,
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
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.borderLight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _selectedView,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(width: 6),
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
                            'ZABNIX PRIVATE LIMITED',
                            '13.00',
                            '51.00',
                            '-38.00',
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildRow(
                            'DEMO WAREHOUSE 1 (Warehouse)',
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

class _PopoverArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CnGridCell extends StatefulWidget {
  final Widget child;
  final double? width;
  final bool isExpanded;
  final Alignment alignment;
  final Color? backgroundColor;
  final bool showDivider;
  final EdgeInsets padding;

  const _CnGridCell({
    required this.child,
    this.width,
    this.isExpanded = false,
    this.alignment = Alignment.topCenter,
    this.backgroundColor,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
  });

  @override
  State<_CnGridCell> createState() => _CnGridCellState();
}

class _CnGridCellState extends State<_CnGridCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = AppTheme.bgDisabled;
    Widget content = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: _isHovered
            ? hoverColor
            : (widget.backgroundColor ?? Colors.transparent),
        padding: widget.padding,
        alignment: widget.alignment,
        child: widget.child,
      ),
    );

    Widget result;
    if (widget.showDivider) {
      result = Row(
        mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isExpanded)
            Expanded(child: content)
          else
            SizedBox(width: widget.width, child: content),
          const VerticalDivider(
            width: 1,
            color: AppTheme.borderLight,
            thickness: 1,
            indent: 0,
            endIndent: 0,
          ),
        ],
      );
    } else {
      result = widget.isExpanded
          ? content
          : SizedBox(width: widget.width, child: content);
    }

    return widget.isExpanded ? Expanded(child: result) : result;
  }
}

class _DottedUnderlinePainter extends CustomPainter {
  const _DottedUnderlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borderMid
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const dashWidth = 3.0;
    const dashGap = 4.0;
    final y = size.height - 2;
    var startX = 0.0;

    while (startX < size.width) {
      final endX = (startX + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CnItemsGrid extends StatefulWidget {
  final bool creditOnly;
  final String warehouse;
  final List<_CnLineItem> items;
  final VoidCallback onAddItem;
  final VoidCallback onAddBulkItems;
  final Function(int) onInsertItem;
  final Function(int) onCloneItem;
  final Function(int) onRemoveItem;
  final Function(int) onItemSelected;
  final Function(_CnLineItem) onViewItemDetails;
  final Function(_CnLineItem) onEditItem;
  final Function(_CnLineItem) onAddBatches;
  final VoidCallback? onTotalsChanged;

  const _CnItemsGrid({
    required this.creditOnly,
    required this.warehouse,
    required this.items,
    required this.onAddItem,
    required this.onAddBulkItems,
    required this.onInsertItem,
    required this.onCloneItem,
    required this.onRemoveItem,
    required this.onItemSelected,
    required this.onViewItemDetails,
    required this.onEditItem,
    required this.onAddBatches,
    this.onTotalsChanged,
  });

  @override
  State<_CnItemsGrid> createState() => _CnItemsGridState();
}

class _CnItemsGridState extends State<_CnItemsGrid> {
  String _selectedStockView = 'Available for Sale';
  static const double _rowActionWidth = 28;
  static const double _rowActionsWidth = _rowActionWidth * 2;
  static const double _rowMenuWidth = 220;

  bool _isBulkUpdateActive = false;
  String _selectedUpdateField = '';
  bool _areAdditionalInfosHidden = false;
  int? _hoveredItemActionIndex;

  Widget _buildInfoItem(
    IconData icon,
    String label,
    List<String> items,
    Function(String) onSelected, {
    double iconSize = 14,
  }) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      color: Colors.white,
      elevation: 4,
      tooltip: '',
      onSelected: onSelected,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            LucideIcons.chevronDown,
            size: 12,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              padding: EdgeInsets.zero,
              child: _CnInfoDropdownHoverItem(label: item),
            ),
          )
          .toList(),
    );
  }

  PopupMenuItem<int> _buildRowActionMenuItem({
    required int value,
    required String label,
    bool highlighted = false,
  }) {
    return PopupMenuItem<int>(
      value: value,
      padding: EdgeInsets.zero,
      height: highlighted ? 44 : 40,
      child: _CnRowActionMenuHoverItem(
        label: label,
        width: _rowMenuWidth,
        height: highlighted ? 44 : 40,
        highlighted: highlighted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(right: _rowActionsWidth),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.borderLight),
              left: BorderSide(color: AppTheme.borderLight),
              right: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: Column(
            children: [
              // Item Table title row - inside the box
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Item Table',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const SizedBox.shrink(),
                      label: const Text(
                        '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                    const SizedBox.shrink(),
                    PopupMenuButton<int>(
                      offset: const Offset(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppTheme.borderLight),
                      ),
                      color: Colors.white,
                      elevation: 4,
                      tooltip: '',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              LucideIcons.checkCircle,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Bulk Actions',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 0) {
                          setState(() {
                            _isBulkUpdateActive = true;
                          });
                        } else if (value == 1) {
                          setState(() {
                            _areAdditionalInfosHidden =
                                !_areAdditionalInfosHidden;
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<int>(
                          value: 0,
                          padding: EdgeInsets.zero,
                          height: 40,
                          child: _CnBulkMenuHoverItem(
                            label: 'Bulk Update Line Items',
                          ),
                        ),
                        PopupMenuItem<int>(
                          value: 1,
                          padding: EdgeInsets.zero,
                          height: 40,
                          child: _CnBulkMenuHoverItem(
                            label: _areAdditionalInfosHidden
                                ? 'Show All Additional Information'
                                : 'Hide All Additional Information',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isBulkUpdateActive) ...[
                const Divider(height: 1, color: AppTheme.borderLight),
                Container(
                  color: const Color(0xFFEEF2FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _CnBulkUpdateActionButton(
                        label: 'Update Reporting Tags',
                        isSelected: _selectedUpdateField == 'ReportingTags',
                        hasDropdown: false,
                        onDropdownTap: null,
                        onTap: () {
                          setState(
                            () => _selectedUpdateField = 'ReportingTags',
                          );
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: Colors.black.withValues(alpha: 0.1),
                            pageBuilder: (context, anim1, anim2) {
                              return Align(
                                alignment: Alignment.topCenter,
                                child: const _CnBulkUpdateLineItemsDialog(),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _CnBulkUpdateActionButton(
                        label: 'Update Account',
                        isSelected: _selectedUpdateField == 'Account',
                        hasDropdown: false,
                        onDropdownTap: null,
                        onTap: () {
                          setState(() => _selectedUpdateField = 'Account');
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: Colors.black.withValues(alpha: 0.1),
                            pageBuilder: (context, anim1, anim2) {
                              return Align(
                                alignment: Alignment.topCenter,
                                child: const _CnBulkUpdateAccountDialog(),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _CnBulkUpdateActionButton(
                        label: 'Update Discount Account',
                        isSelected: _selectedUpdateField == 'DiscountAccount',
                        hasDropdown: false,
                        onDropdownTap: null,
                        onTap: () {
                          setState(
                            () => _selectedUpdateField = 'DiscountAccount',
                          );
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: Colors.black.withValues(alpha: 0.1),
                            pageBuilder: (context, anim1, anim2) {
                              return Align(
                                alignment: Alignment.topCenter,
                                child:
                                    const _CnBulkUpdateDiscountAccountDialog(),
                              );
                            },
                          );
                        },
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () =>
                            setState(() => _isBulkUpdateActive = false),
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
              ],
              const Divider(height: 1, color: AppTheme.borderLight),
              // Header row - fixed-width columns with vertical dividers
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CnGridCell(
                      isExpanded: true,
                      backgroundColor: AppTheme.tableHeaderBg,
                      alignment: Alignment.topLeft,
                      child: const Row(
                        children: [
                          SizedBox(width: 48),
                          SizedBox(width: 8),
                          CnGridHeader(label: 'ITEM DETAILS'),
                        ],
                      ),
                    ),
                    _CnGridCell(
                      width: _CreditNoteCreatePageState._accountColumnWidth,
                      backgroundColor: AppTheme.tableHeaderBg,
                      alignment: Alignment.topLeft,
                      child: const CnGridHeader(label: 'ACCOUNT'),
                    ),
                    _CnGridCell(
                      width: _CreditNoteCreatePageState._quantityColumnWidth,
                      backgroundColor: AppTheme.tableHeaderBg,
                      alignment: Alignment.topRight,
                      child: const CnGridHeader(label: 'QUANTITY'),
                    ),
                    _CnGridCell(
                      width: _CreditNoteCreatePageState._rateColumnWidth,
                      backgroundColor: AppTheme.tableHeaderBg,
                      alignment: Alignment.topRight,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'RATE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            LucideIcons.calculator,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    _CnGridCell(
                      width: _CreditNoteCreatePageState._discountColumnWidth,
                      backgroundColor: AppTheme.tableHeaderBg,
                      alignment: Alignment.topRight,
                      child: const CnGridHeader(label: 'DISCOUNT'),
                    ),
                    _CnGridCell(
                      width: _CreditNoteCreatePageState._taxColumnWidth,
                      backgroundColor: AppTheme.tableHeaderBg,
                      alignment: Alignment.topLeft,
                      child: const Row(
                        children: [
                          Text(
                            'TAX',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          SizedBox(width: 4),
                          ZTooltip(
                            message:
                                'Tax can only be applied to an item after choosing a customer. Please select a customer from the Customer Name drop-down.',
                          ),
                        ],
                      ),
                    ),
                    _CnGridCell(
                      width: _CreditNoteCreatePageState._amountColumnWidth,
                      backgroundColor: AppTheme.tableHeaderBg,
                      alignment: Alignment.topRight,
                      showDivider: false,
                      child: const CnGridHeader(label: 'AMOUNT'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Item rows - each uses IntrinsicHeight so action buttons align with row height
        ...List.generate(widget.items.length, (index) {
          final showActions = _hoveredItemActionIndex == index;

          return MouseRegion(
            onEnter: (_) {
              if (_hoveredItemActionIndex != index) {
                setState(() => _hoveredItemActionIndex = index);
              }
            },
            onExit: (_) {
              if (_hoveredItemActionIndex == index) {
                setState(() => _hoveredItemActionIndex = null);
              }
            },
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppTheme.borderLight),
                          right: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Column(
                        children: [
                          _CnItemRowWidget(
                            item: widget.items[index],
                            creditOnly: widget.creditOnly,
                            warehouse: widget.warehouse,
                            selectedStockView: _selectedStockView,
                            onStockViewChanged: (val) =>
                                setState(() => _selectedStockView = val),
                            onItemSelected: () => widget.onItemSelected(index),
                            onViewItemDetails: () =>
                                widget.onViewItemDetails(widget.items[index]),
                            onEditItem: () =>
                                widget.onEditItem(widget.items[index]),
                            onAddBatches: () =>
                                widget.onAddBatches(widget.items[index]),
                            onRemoveItem: () => widget.onRemoveItem(index),
                            onTotalsChanged: widget.onTotalsChanged,
                          ),
                          if (!_areAdditionalInfosHidden) ...[
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                            Container(
                              color: const Color(0xFFF9FAFB),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 48),
                                  const SizedBox(width: 8),
                                  _buildInfoItem(
                                    LucideIcons.badgePercent,
                                    'Discount',
                                    ['Discount 1', 'Discount 2'],
                                    (val) {},
                                    iconSize: 20,
                                  ),
                                  const SizedBox(width: 24),
                                  PopupMenuButton<void>(
                                    offset: const Offset(0, 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      side: const BorderSide(
                                        color: AppTheme.borderLight,
                                      ),
                                    ),
                                    color: Colors.white,
                                    elevation: 4,
                                    tooltip: '',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          LucideIcons.tag,
                                          size: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Reporting Tags',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          LucideIcons.chevronDown,
                                          size: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ],
                                    ),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem<void>(
                                        enabled: false,
                                        padding: EdgeInsets.zero,
                                        child: _CnReportingTagsForm(),
                                      ),
                                    ],
                                  ),
                                  if (widget.items[index].name.isNotEmpty) ...[
                                    const SizedBox(width: 24),
                                    _CnCostPriceButton(
                                      item: widget.items[index],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          if (index != widget.items.length - 1)
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
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
                            child: Center(
                              child: PopupMenuButton<int>(
                                offset: Offset.zero,
                                position: PopupMenuPosition.under,
                                constraints: const BoxConstraints(
                                  minWidth: _rowMenuWidth,
                                  maxWidth: _rowMenuWidth,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                                color: Colors.white,
                                elevation: 6,
                                tooltip: '',
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  if (value == 0) {
                                    setState(() {
                                      _areAdditionalInfosHidden =
                                          !_areAdditionalInfosHidden;
                                    });
                                  } else if (value == 1) {
                                    widget.onCloneItem(index);
                                  } else if (value == 2) {
                                    widget.onInsertItem(index);
                                  } else if (value == 3) {
                                    widget.onAddBulkItems();
                                  }
                                },
                                itemBuilder: (context) => [
                                  _buildRowActionMenuItem(
                                    value: 0,
                                    label: _areAdditionalInfosHidden
                                        ? 'Show Additional Information'
                                        : 'Hide Additional Information',
                                  ),
                                  const PopupMenuDivider(height: 1),
                                  _buildRowActionMenuItem(
                                    value: 1,
                                    label: 'Clone',
                                  ),
                                  const PopupMenuDivider(height: 1),
                                  _buildRowActionMenuItem(
                                    value: 2,
                                    label: 'Insert New Row',
                                  ),
                                  _buildRowActionMenuItem(
                                    value: 3,
                                    label: 'Insert Items in Bulk',
                                  ),
                                ],
                                child: const Icon(
                                  LucideIcons.moreHorizontal,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: _rowActionWidth,
                            child: Center(
                              child: GestureDetector(
                                onTap: () => widget.onRemoveItem(index),
                                behavior: HitTestBehavior.opaque,
                                child: const _CnRowActionIconButton(
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
            ),
          );
        }),
        Container(
          margin: const EdgeInsets.only(right: _rowActionsWidth),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppTheme.borderLight),
              right: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: Padding(
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

class _CnItemRowWidget extends StatefulWidget {
  final _CnLineItem item;
  final bool creditOnly;
  final String warehouse;
  final String selectedStockView;
  final ValueChanged<String>? onStockViewChanged;
  final VoidCallback? onItemSelected;
  final VoidCallback? onViewItemDetails;
  final VoidCallback? onEditItem;
  final VoidCallback? onAddBatches;
  final VoidCallback? onRemoveItem;
  final VoidCallback? onTotalsChanged;

  const _CnItemRowWidget({
    required this.item,
    required this.creditOnly,
    required this.warehouse,
    required this.selectedStockView,
    this.onStockViewChanged,
    this.onItemSelected,
    this.onViewItemDetails,
    this.onEditItem,
    this.onAddBatches,
    this.onRemoveItem,
    this.onTotalsChanged,
  });

  @override
  State<_CnItemRowWidget> createState() => _CnItemRowWidgetState();
}

class _CnItemRowWidgetState extends State<_CnItemRowWidget> {
  late final FocusNode _rateFocusNode;
  double _previousRate = 0.0;

  // HSN edit popover
  final LayerLink _hsnLayerLink = LayerLink();
  OverlayEntry? _hsnOverlay;
  late final TextEditingController _hsnEditController;

  // Exemption reason popover
  final LayerLink _exemptionLayerLink = LayerLink();
  OverlayEntry? _exemptionOverlay;

  void _notifyTotalsChanged() {
    widget.onTotalsChanged?.call();
  }

  @override
  void initState() {
    super.initState();
    _rateFocusNode = FocusNode();
    _rateFocusNode.addListener(() {
      if (_rateFocusNode.hasFocus) {
        _previousRate = double.tryParse(widget.item.rateController.text) ?? 0.0;
      } else {
        _evaluateRateField();
        _notifyTotalsChanged();
      }
    });
    _hsnEditController = TextEditingController(text: widget.item.hsnCode);
  }

  @override
  void dispose() {
    _rateFocusNode.dispose();
    _closeHsnOverlay();
    _closeExemptionOverlay();
    _hsnEditController.dispose();
    super.dispose();
  }

  void _openHsnOverlay() {
    _hsnEditController.text = widget.item.hsnCode;
    _hsnOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeHsnOverlay,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
            CompositedTransformFollower(
              link: _hsnLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(-120, 20),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.white,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 340,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: StatefulBuilder(
                      builder: (ctx, setOverlayState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HSN Code',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _hsnEditController,
                                    hintText: 'Enter HSN code',
                                    autoFocus: true,
                                    onSubmitted: (_) => _saveHsn(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Icon(
                                    LucideIcons.search,
                                    size: 20,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ZButton.primary(
                                  label: 'Save',
                                  onPressed: _saveHsn,
                                ),
                                const SizedBox(width: 8),
                                ZButton.secondary(
                                  label: 'Close',
                                  onPressed: _closeHsnOverlay,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_hsnOverlay!);
    setState(() {});
  }

  void _closeHsnOverlay() {
    _hsnOverlay?.remove();
    _hsnOverlay = null;
    if (mounted) setState(() {});
  }

  void _saveHsn() {
    setState(() => widget.item.hsnCode = _hsnEditController.text.trim());
    _closeHsnOverlay();
  }

  bool get _isNonTaxable {
    final tax = widget.item.tax ?? '';
    return tax == 'Non-Taxable' ||
        tax == 'Out of Scope' ||
        tax == 'Non-GST Supply';
  }

  void _openExemptionOverlay() {
    String? picked = widget.item.exemptionReason;
    const reasons = [
      'GSTMARGINSCHEME',
      'LACK OF STOCK',
      'EXEMPTED',
      'OTHERGROUNDS',
    ];
    _exemptionOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeExemptionOverlay,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
            CompositedTransformFollower(
              link: _exemptionLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(-200, 24),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.white,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 360,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: StatefulBuilder(
                      builder: (ctx, setOverlayState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Choose the reason for exemption',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _closeExemptionOverlay,
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 18,
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Exemption Reason*',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.errorRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FormDropdown<String>(
                              value: picked,
                              items: reasons,
                              hint: 'Select or type to add',
                              height: 40,
                              displayStringForValue: (v) => v,
                              itemBuilder: (val, isSelected, isHovered) =>
                                  Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    color: isHovered
                                        ? AppTheme.primaryBlue
                                        : Colors.white,
                                    child: Text(
                                      val,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isHovered
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                              onChanged: (val) =>
                                  setOverlayState(() => picked = val),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                ZButton.primary(
                                  label: 'Update',
                                  onPressed: picked == null
                                      ? null
                                      : () {
                                          setState(
                                            () => widget.item.exemptionReason =
                                                picked,
                                          );
                                          _closeExemptionOverlay();
                                        },
                                ),
                                const SizedBox(width: 8),
                                ZButton.secondary(
                                  label: 'Cancel',
                                  onPressed: _closeExemptionOverlay,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_exemptionOverlay!);
    setState(() {});
  }

  void _closeExemptionOverlay() {
    _exemptionOverlay?.remove();
    _exemptionOverlay = null;
    if (mounted) setState(() {});
  }

  void _evaluateRateField() {
    final val = widget.item.rateController.text.trim();
    if (val.isEmpty) return;

    if (val.startsWith('+=')) {
      final addVal = double.tryParse(val.substring(2)) ?? 0.0;
      final newVal = _previousRate + addVal;
      widget.item.rateController.text = newVal.toStringAsFixed(2);
      setState(() {});
      return;
    }
    if (val.startsWith('-=')) {
      final subVal = double.tryParse(val.substring(2)) ?? 0.0;
      final newVal = _previousRate - subVal;
      widget.item.rateController.text = newVal.toStringAsFixed(2);
      setState(() {});
      return;
    }
    if (val.startsWith('*=')) {
      final mulVal = double.tryParse(val.substring(2)) ?? 1.0;
      final newVal = _previousRate * mulVal;
      widget.item.rateController.text = newVal.toStringAsFixed(2);
      setState(() {});
      return;
    }
    if (val.startsWith('/=')) {
      final divVal = double.tryParse(val.substring(2)) ?? 1.0;
      if (divVal != 0) {
        final newVal = _previousRate / divVal;
        widget.item.rateController.text = newVal.toStringAsFixed(2);
        setState(() {});
      }
      return;
    }

    try {
      String exp = val;
      if (exp.startsWith('=')) exp = exp.substring(1);

      final match = RegExp(
        r'^([\d.]+)\s*([\+\-\*\/])\s*([\d.]+)$',
      ).firstMatch(exp);
      if (match != null) {
        final a = double.tryParse(match.group(1)!) ?? 0;
        final op = match.group(2)!;
        final b = double.tryParse(match.group(3)!) ?? 0;
        double result = 0.0;
        switch (op) {
          case '+':
            result = a + b;
            break;
          case '-':
            result = a - b;
            break;
          case '*':
            result = a * b;
            break;
          case '/':
            result = b != 0 ? a / b : 0;
            break;
        }
        widget.item.rateController.text = result.toStringAsFixed(2);
        setState(() {});
      } else {
        final result = double.tryParse(exp);
        if (result != null) {
          widget.item.rateController.text = result.toStringAsFixed(2);
          setState(() {});
        }
      }
    } catch (_) {}
  }

  String _computeAmount(_CnLineItem item) {
    final qty = double.tryParse(item.returnQtyController.text) ?? 0;
    final rate = double.tryParse(item.rateController.text) ?? 0;
    final discount = double.tryParse(item.discountController.text) ?? 0;
    final gross = qty * rate;
    final discountAmount = item.discountIsPercent
        ? gross * discount / 100
        : discount;
    final amount = gross - discountAmount;
    return (amount < 0 ? 0.0 : amount).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CnGridCell(
                  isExpanded: true,
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: const Icon(
                          LucideIcons.image,
                          size: 20,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: item.name.isEmpty
                            ? FormDropdown<String>(
                                value: null,
                                items: const [
                                  'BATCH TARCK ITEM',
                                  'Item A',
                                  'Item B',
                                  'Item C',
                                  'Item D',
                                  'Item E',
                                  'ITEM-5',
                                  'ITEM-6',
                                  'ITEM-7',
                                  'ITEM-8',
                                ],
                                hint: 'Type or click to select an item.',
                                height:
                                    _CreditNoteCreatePageState._tableFieldHeight,
                                hideBorderDefault: true,
                                showSettings: true,
                                settingsLabel: 'Add New Item',
                                settingsIcon: LucideIcons.plusCircle,
                                onSettingsTap: () {
                                  showDialog<void>(
                                    context: context,
                                    barrierColor: Colors.black.withValues(
                                      alpha: 0.4,
                                    ),
                                    builder: (_) => const _CnNewItemDialog(
                                      title: 'New Item',
                                      item: null,
                                    ),
                                  );
                                },
                                itemBuilder: (val, isSelected, isHovered) {
                                  final active = isHovered || isSelected;
                                  return Container(
                                    color: active
                                        ? AppTheme.primaryBlue
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          val,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: active
                                                ? Colors.white
                                                : AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Rate: ₹200.00',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: active
                                                ? Colors.white70
                                                : AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      item.name = val;
                                      if (val == 'BATCH TARCK ITEM') {
                                        item.descriptionController.text =
                                            'sales description demo txt';
                                        item.costPrice = 95.0;
                                      } else {
                                        item.costPrice = 0.0;
                                      }
                                    });
                                    widget.onItemSelected?.call();
                                    _notifyTotalsChanged();
                                  }
                                },
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        offset: const Offset(0, 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: const BorderSide(
                                            color: AppTheme.borderLight,
                                          ),
                                        ),
                                        color: Colors.white,
                                        elevation: 4,
                                        tooltip: '',
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          LucideIcons.moreHorizontal,
                                          size: 16,
                                          color: AppTheme.textSecondary,
                                        ),
                                        iconSize: 16,
                                        onSelected: (val) {
                                          if (val == 'view') {
                                            widget.onViewItemDetails?.call();
                                          }
                                          if (val == 'edit') {
                                            widget.onEditItem?.call();
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            padding: EdgeInsets.zero,
                                            height: 44,
                                            child: _CnBulkMenuHoverItem(
                                              label: 'Edit Item',
                                              icon: LucideIcons.pencil,
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'view',
                                            padding: EdgeInsets.zero,
                                            height: 44,
                                            child: _CnBulkMenuHoverItem(
                                              label: 'View Item Details',
                                              icon: LucideIcons.shoppingBag,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 2),
                                      GestureDetector(
                                        onTap: () =>
                                            widget.onRemoveItem?.call(),
                                        child: const Icon(
                                          LucideIcons.xCircle,
                                          size: 16,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    controller: item.descriptionController,
                                    hintText: 'Add a description',
                                    maxLines: 3,
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                        child: const Text(
                                          'GOODS',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'HSN Code: ${item.hsnCode}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.primaryBlue,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      CompositedTransformTarget(
                                        link: _hsnLayerLink,
                                        child: GestureDetector(
                                          onTap: _hsnOverlay == null
                                              ? _openHsnOverlay
                                              : _closeHsnOverlay,
                                          child: const Icon(
                                            LucideIcons.pencil,
                                            size: 12,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                // ACCOUNT
                _CnGridCell(
                  width: _CreditNoteCreatePageState._accountColumnWidth,
                  alignment: Alignment.topLeft,
                  child: FormDropdown<String>(
                    value: item.account,
                    items: const [
                      'Sales',
                      'Cost of Goods Sold',
                      'Other Income',
                    ],
                    hint: 'Select Account',
                    height: _CreditNoteCreatePageState._tableFieldHeight,
                    hideBorderDefault: true,
                    onChanged: (val) => setState(() => item.account = val),
                  ),
                ),
                // QUANTITY
                _CnGridCell(
                  width: _CreditNoteCreatePageState._quantityColumnWidth,
                  alignment: Alignment.topRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomTextField(
                        controller: item.returnQtyController,
                        hintText: '0',
                        height: _CreditNoteCreatePageState._tableFieldHeight,
                        hideBorderDefault: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        onChanged: (_) {
                          setState(() {});
                          _notifyTotalsChanged();
                        },
                      ),
                      const SizedBox(height: 4),
                      if (item.name.isNotEmpty) ...[
                        Text(
                          '${widget.selectedStockView}:',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        Text(
                          widget.selectedStockView == 'Available for Sale'
                              ? '72 pcs'
                              : '103 pcs',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 4),
                        WarehouseHoverPopover(
                          productId: item.sourceItem?.id,
                          warehouseName:
                              item.warehouseLocation ??
                              'ZABNIX PRIVATE LIMITED',
                          selectedView: widget.selectedStockView,
                          onViewChanged: (val) =>
                              widget.onStockViewChanged?.call(val),
                          onWarehouseChanged: (val) {
                            setState(() => item.warehouseLocation = val);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(
                                LucideIcons.home,
                                size: 12,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  item.warehouseLocation ??
                                      'ZABNIX PRIVATE LIMITED',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: widget.onAddBatches,
                          child: item.savedBatches.isEmpty
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Icon(
                                      LucideIcons.alertTriangle,
                                      size: 12,
                                      color: AppTheme.errorRed,
                                    ),
                                    const SizedBox(width: 4),
                                    const Flexible(
                                      child: Text(
                                        'Add Batches',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.errorRed,
                                          decoration: TextDecoration.underline,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  '${item.savedBatches.fold(0, (sum, b) => sum + (int.tryParse(b.quantityController.text) ?? 0))} pcs added to ${item.savedBatches.length} ${item.savedBatches.length == 1 ? 'batch' : 'batches'}.',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
                // RATE
                _CnGridCell(
                  width: _CreditNoteCreatePageState._rateColumnWidth,
                  alignment: Alignment.topRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomTextField(
                        controller: item.rateController,
                        hintText: '0.00',
                        focusNode: _rateFocusNode,
                        height: _CreditNoteCreatePageState._tableFieldHeight,
                        hideBorderDefault: true,
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.right,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        onChanged: (_) {
                          setState(() {});
                          _notifyTotalsChanged();
                        },
                        onSubmitted: (val) {
                          _evaluateRateField();
                          _notifyTotalsChanged();
                        },
                      ),
                      const SizedBox(height: 4),
                      if (item.name.isNotEmpty) ...[
                        FormDropdown<String>(
                          value: item.priceList,
                          items: const [
                            'Standard Selling',
                            'Wholesale Price',
                            'Retail Price',
                          ],
                          hint: 'Pricelist',
                          height: 28,
                          allowClear: true,
                          onChanged: (val) =>
                              setState(() => item.priceList = val),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => widget.onViewItemDetails?.call(),
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
                // DISCOUNT
                _CnGridCell(
                  width: _CreditNoteCreatePageState._discountColumnWidth,
                  alignment: Alignment.topRight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: item.discountController,
                          hintText: '0',
                          height: _CreditNoteCreatePageState._tableFieldHeight,
                          hideBorderDefault: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          onChanged: (val) {
                            if (item.discountIsPercent) {
                              final doubleValue = double.tryParse(val) ?? 0;
                              if (doubleValue > 100) {
                                item.discountController.text = '100';
                                item
                                    .discountController
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: item.discountController.text.length,
                                  ),
                                );
                              }
                            }
                            setState(() {});
                            _notifyTotalsChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<bool>(
                        offset: const Offset(0, 4),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          maxWidth: 44,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppTheme.borderLight),
                        ),
                        color: Colors.white,
                        elevation: 4,
                        tooltip: '',
                        onSelected: (val) {
                          setState(() {
                            item.discountIsPercent = val;
                            if (item.discountIsPercent) {
                              final doubleValue =
                                  double.tryParse(
                                    item.discountController.text,
                                  ) ??
                                  0;
                              if (doubleValue > 100) {
                                item.discountController.text = '100';
                              }
                            }
                          });
                          _notifyTotalsChanged();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<bool>(
                            value: true,
                            padding: EdgeInsets.zero,
                            height: 40,
                            child: _CnDiscountTypeOption(
                              label: '%',
                              selected: item.discountIsPercent,
                            ),
                          ),
                          PopupMenuItem<bool>(
                            value: false,
                            padding: EdgeInsets.zero,
                            height: 40,
                            child: _CnDiscountTypeOption(
                              label: '₹',
                              selected: !item.discountIsPercent,
                            ),
                          ),
                        ],
                        child: Container(
                          height: _CreditNoteCreatePageState._tableFieldHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderLight),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.discountIsPercent ? '%' : '₹',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // TAX
                _CnGridCell(
                  width: _CreditNoteCreatePageState._taxColumnWidth,
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FormDropdown<_CnTaxOption>(
                        value: _cnTaxOptions.firstWhere(
                          (o) => o.label == item.tax,
                          orElse: () => _cnTaxOptions[5],
                        ),
                        items: _cnTaxOptions,
                        hint: 'Select a Tax',
                        height: _CreditNoteCreatePageState._tableFieldHeight,
                        menuWidth: 360,
                        hideBorderDefault: true,
                        displayStringForValue: (o) => o.label,
                        isItemEnabled: (o) => !o.isHeader,
                        itemBuilder: (option, isSelected, isHovered) {
                          if (option.isHeader) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: const Color(0xFFF9FAFB),
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
                            color: isHovered
                                ? AppTheme.primaryBlue
                                : Colors.white,
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
                            setState(() {
                              item.tax = val.label;
                              if (!_isNonTaxable) item.exemptionReason = null;
                            });
                            _notifyTotalsChanged();
                            if (_isNonTaxable && _exemptionOverlay == null) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _openExemptionOverlay(),
                              );
                            }
                          }
                        },
                      ),
                      if (_isNonTaxable) ...[
                        const SizedBox(height: 4),
                        CompositedTransformTarget(
                          link: _exemptionLayerLink,
                          child: GestureDetector(
                            onTap: _exemptionOverlay == null
                                ? _openExemptionOverlay
                                : _closeExemptionOverlay,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    item.exemptionReason ??
                                        'Exemption reason not chosen*',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: item.exemptionReason != null
                                          ? AppTheme.textSecondary
                                          : AppTheme.errorRed,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Icon(
                                    LucideIcons.pencil,
                                    size: 11,
                                    color: item.exemptionReason != null
                                        ? AppTheme.textSecondary
                                        : AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // AMOUNT
                _CnGridCell(
                  width: _CreditNoteCreatePageState._amountColumnWidth,
                  alignment: Alignment.topRight,
                  showDivider: false,
                  child: Text(
                    _computeAmount(item),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
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

class _CnItemDetailsSidePanel extends StatefulWidget {
  final _CnLineItem item;
  final VoidCallback onClose;

  const _CnItemDetailsSidePanel({required this.item, required this.onClose});

  @override
  State<_CnItemDetailsSidePanel> createState() =>
      _CnItemDetailsSidePanelState();
}

class _CnItemDetailsSidePanelState extends State<_CnItemDetailsSidePanel> {
  int _tab = 0;
  bool _otherDetailsExpanded = false;
  String _stockView = 'Physical Stock';
  bool _stockDropdownOpen = false;
  String _txnType = 'Credit Notes';
  bool _txnTypeDropdownOpen = false;
  String _txnStatus = 'All';
  bool _txnStatusDropdownOpen = false;

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
        Row(
          children: [
            Expanded(
              child: _PanelStatCard(
                icon: LucideIcons.truck,
                label: 'To Be Shipped',
                value: '10.00',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PanelStatCard(
                icon: LucideIcons.arrowRightLeft,
                label: 'To Be Received',
                value: '56.00',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _PanelSectionHeading(
          'Sales Information',
          color: AppTheme.textPrimary,
        ),
        const SizedBox(height: 12),
        const _PanelDetailRow(label: 'Price', value: '₹115.00'),
        const SizedBox(height: 8),
        const _PanelDetailRow(label: 'Account', value: 'Sales'),
        const SizedBox(height: 24),
        const _PanelSectionHeading(
          'Purchase Information',
          color: AppTheme.textPrimary,
        ),
        const SizedBox(height: 12),
        const _PanelDetailRow(label: 'Price', value: '₹100.00'),
        const SizedBox(height: 8),
        const _PanelDetailRow(label: 'Account', value: 'Cost of Goods Sold'),
        const SizedBox(height: 8),
        const Divider(color: AppTheme.borderLight, height: 1),
        const SizedBox(height: 8),
        InkWell(
          onTap: () =>
              setState(() => _otherDetailsExpanded = !_otherDetailsExpanded),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  'Other Details',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _otherDetailsExpanded
                      ? LucideIcons.chevronDown
                      : LucideIcons.chevronRight,
                  size: 14,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        ),
        if (_otherDetailsExpanded) ...[
          const SizedBox(height: 10),
          const _PanelDetailRow(
            label: 'Inventory Account',
            value: 'Inventory Asset',
          ),
        ],
      ],
    );
  }

  Widget _buildStockLocationsTab() {
    const options = ['Physical Stock', 'Accounting Stock'];
    const rows = [
      ('SAHAKAR TIRUR', true, '0.00', '0.00', '0.00'),
      ('ZABNIX PRIVATE LIMITED', false, '103.00', '31.00', '72.00'),
      ('DEMO WAREHOUSE 1 (Warehouse)', false, '30.00', '5.00', '25.00'),
    ];

    final tableContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 52),
        const SizedBox(height: 16),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: const [
              _StockColHeader(
                label: 'LOCATION\nNAME',
                flex: 3,
                align: TextAlign.left,
              ),
              _StockColHeader(
                label: 'STOCK ON\nHAND',
                flex: 2,
                align: TextAlign.right,
              ),
              _StockColHeader(
                label: 'COMMITTED\nSTOCK',
                flex: 2,
                align: TextAlign.right,
              ),
              _StockColHeader(
                label: 'AVAILABLE FOR\nSALE',
                flex: 2,
                align: TextAlign.right,
              ),
            ],
          ),
        ),
        ...rows.map((r) {
          final (name, starred, onHand, committed, available) = r;
          return Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (starred) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '★',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFD4A017),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    onHand,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    committed,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    available,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        tableContent,
        // Dropdown trigger + floating list sit on top
        Positioned(
          top: 0,
          left: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () =>
                    setState(() => _stockDropdownOpen = !_stockDropdownOpen),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _stockDropdownOpen
                          ? AppTheme.primaryBlue
                          : AppTheme.borderLight,
                      width: _stockDropdownOpen ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _stockView,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_stockDropdownOpen)
                IntrinsicWidth(
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: options
                          .map(
                            (opt) => _StockDropdownOption(
                              label: opt,
                              selected: opt == _stockView,
                              onTap: () => setState(() {
                                _stockView = opt;
                                _stockDropdownOpen = false;
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    const txnTypes = [
      'Sales Orders',
      'Invoices',
      'Delivery Challans',
      'Credit Notes',
      'Purchase Orders',
      'Bills',
      'Vendor Credits',
    ];
    final statusOptions =
        (_txnType == 'Credit Notes' || _txnType == 'Vendor Credits')
        ? ['All', 'Open', 'Closed', 'Void']
        : (_txnType == 'Invoices' || _txnType == 'Bills')
        ? ['All', 'Draft', 'Sent', 'Partially Paid', 'Paid', 'Void']
        : (_txnType == 'Delivery Challans')
        ? ['All', 'Draft', 'Confirmed', 'Void']
        : (_txnType == 'Purchase Orders')
        ? ['All', 'Draft', 'Confirmed', 'Billed', 'Void']
        : [
            'All',
            'Draft',
            'Partially Invoiced',
            'Invoiced',
            'Closed',
            'Void',
            'Confirmed',
          ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: type dropdown + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Type dropdown trigger
                GestureDetector(
                  onTap: () => setState(() {
                    _txnTypeDropdownOpen = !_txnTypeDropdownOpen;
                    _txnStatusDropdownOpen = false;
                  }),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _txnType,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.chevronDown,
                        size: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Status label
                const Text(
                  'Status:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() {
                    _txnStatusDropdownOpen = !_txnStatusDropdownOpen;
                    _txnTypeDropdownOpen = false;
                  }),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _txnStatus,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.chevronDown,
                        size: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.borderLight, height: 1),
            SizedBox(
              height: (_txnTypeDropdownOpen || _txnStatusDropdownOpen)
                  ? 320
                  : 40,
            ),
            if (!_txnTypeDropdownOpen && !_txnStatusDropdownOpen)
              Center(
                child: Text(
                  'No $_txnType created yet.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        // Tap-outside dismiss — behind the dropdown lists
        if (_txnTypeDropdownOpen || _txnStatusDropdownOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() {
                _txnTypeDropdownOpen = false;
                _txnStatusDropdownOpen = false;
              }),
            ),
          ),
        // Type dropdown overlay — on top so MouseRegion works for all items
        if (_txnTypeDropdownOpen)
          Positioned(
            top: 28,
            left: 0,
            child: IntrinsicWidth(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: txnTypes
                      .map(
                        (opt) => _StockDropdownOption(
                          label: opt,
                          selected: opt == _txnType,
                          onTap: () => setState(() {
                            _txnType = opt;
                            _txnTypeDropdownOpen = false;
                            _txnStatus = 'All';
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        // Status dropdown overlay — on top so MouseRegion works for all items
        if (_txnStatusDropdownOpen)
          Positioned(
            top: 28,
            right: 0,
            child: IntrinsicWidth(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: statusOptions
                      .map(
                        (opt) => _StockDropdownOption(
                          label: opt,
                          selected: opt == _txnStatus,
                          onTap: () => setState(() {
                            _txnStatus = opt;
                            _txnStatusDropdownOpen = false;
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CnCustomerDetailsSidePanel extends StatefulWidget {
  final String customerName;
  final VoidCallback onClose;

  const _CnCustomerDetailsSidePanel({
    required this.customerName,
    required this.onClose,
  });

  @override
  State<_CnCustomerDetailsSidePanel> createState() =>
      _CnCustomerDetailsSidePanelState();
}

class _CnCustomerDetailsSidePanelState
    extends State<_CnCustomerDetailsSidePanel> {
  int _tab = 0;
  bool _showContactPersons = false;
  bool _showAddress = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: const Border(left: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.bgDisabled,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.customerName.isEmpty
                        ? '?'
                        : widget.customerName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryBlue),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              LucideIcons.externalLink,
                              size: 14,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.borderLight),
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: Row(
              children: [
                _PanelTabButton(
                  label: 'Details',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _PanelTabButton(
                  label: 'Activity Log',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _CnCustomerSummaryCards(),
                        const SizedBox(height: 18),
                        _CnCustomerContactCard(
                          customerName: widget.customerName,
                        ),
                        const SizedBox(height: 16),
                        _CnCustomerPanelActionTile(
                          label: 'Contact Persons',
                          count: 1,
                          expanded: _showContactPersons,
                          onTap: () => setState(
                            () => _showContactPersons = !_showContactPersons,
                          ),
                        ),
                        if (_showContactPersons) ...[
                          const SizedBox(height: 8),
                          _CnContactPersonsDropdown(
                            customerName: widget.customerName,
                          ),
                        ],
                        const SizedBox(height: 10),
                        _CnCustomerPanelActionTile(
                          label: 'Address',
                          expanded: _showAddress,
                          onTap: () =>
                              setState(() => _showAddress = !_showAddress),
                        ),
                        if (_showAddress) ...[
                          const SizedBox(height: 8),
                          _CnCustomerAddressDropdown(
                            customerName: widget.customerName,
                          ),
                        ],
                      ],
                    ),
                  )
                : const Center(
                    child: Text(
                      'No activity log available.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CnCustomerSummaryCards extends StatelessWidget {
  const _CnCustomerSummaryCards();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: const [
            Expanded(
              child: _CnCustomerMetricCard(
                icon: LucideIcons.alertTriangle,
                iconColor: AppTheme.warningOrange,
                label: 'Outstanding Receivables',
                value: '₹0.00',
              ),
            ),
            VerticalDivider(width: 1, color: AppTheme.borderLight),
            Expanded(
              child: _CnCustomerMetricCard(
                icon: LucideIcons.badgeDollarSign,
                iconColor: AppTheme.successGreen,
                label: 'Unused Credits',
                value: '₹0.00',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CnCustomerMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _CnCustomerMetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CnCustomerContactCard extends StatelessWidget {
  final String customerName;

  const _CnCustomerContactCard({required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Contact Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const _PanelDetailRow(
                  label: 'Customer Type',
                  value: 'Individual',
                ),
                const SizedBox(height: 14),
                const _PanelDetailRow(label: 'Currency', value: 'INR'),
                const SizedBox(height: 14),
                const _PanelDetailRow(label: 'Credit Limit', value: '₹0.00'),
                const SizedBox(height: 14),
                const _PanelDetailRow(label: 'Payment Terms', value: 'Net 360'),
                const SizedBox(height: 14),
                const _PanelDetailRow(
                  label: 'Portal Status',
                  value: 'Disabled',
                ),
                const SizedBox(height: 14),
                const _PanelDetailRow(
                  label: 'Customer Language',
                  value: 'English',
                ),
                const SizedBox(height: 14),
                const _PanelDetailRow(label: 'Price List', value: 'Pricelist'),
                const SizedBox(height: 14),
                const _PanelDetailRow(
                  label: 'GST Treatment',
                  value: 'Unregistered Business',
                ),
                const SizedBox(height: 14),
                const _PanelDetailRow(
                  label: 'Place of Supply',
                  value: 'Kerala',
                ),
                const SizedBox(height: 14),
                const _PanelDetailRow(
                  label: 'Tax Preference',
                  value: 'Taxable',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CnCustomerPanelActionTile extends StatelessWidget {
  final String label;
  final int? count;
  final bool expanded;
  final VoidCallback onTap;

  const _CnCustomerPanelActionTile({
    required this.label,
    this.count,
    this.expanded = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.backgroundColor,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Icon(
              expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 18,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CnContactPersonsDropdown extends StatelessWidget {
  final String customerName;

  const _CnContactPersonsDropdown({required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _PanelDetailRow(label: 'Name', value: customerName),
          const SizedBox(height: 10),
          const _PanelDetailRow(label: 'Phone', value: '+91-9895357101'),
          const SizedBox(height: 10),
          const _PanelDetailRow(label: 'Email', value: '-'),
        ],
      ),
    );
  }
}

class _CnCustomerAddressDropdown extends StatelessWidget {
  final String customerName;

  const _CnCustomerAddressDropdown({required this.customerName});

  Widget _buildAddressBlock(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          customerName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddressBlock('BILLING ADDRESS', _cnBillingAddressLines),
          const Divider(height: 24, color: AppTheme.borderLight),
          _buildAddressBlock('SHIPPING ADDRESS', _cnShippingAddressLines),
        ],
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

class _StockDropdownOption extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StockDropdownOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_StockDropdownOption> createState() => _StockDropdownOptionState();
}

class _StockDropdownOptionState extends State<_StockDropdownOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: _hovered ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StockColHeader extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _StockColHeader({
    required this.label,
    required this.flex,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          textAlign: align,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PanelStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PanelStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelSectionHeading extends StatelessWidget {
  final String text;
  final Color color;
  const _PanelSectionHeading(this.text, {this.color = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color),
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
// Item Table Toolbar - above the items grid
// ---------------------------------------------------------------------------

class _ItemTableToolbar extends StatelessWidget {
  const _ItemTableToolbar({
    required this.warehouseLocation,
    required this.warehouseOptions,
    required this.onWarehouseChanged,
    required this.priceLevel,
    required this.priceLevelOptions,
    required this.onPriceLevelChanged,
    required this.selectedPriceList,
    required this.priceListOptions,
    required this.onPriceListChanged,
  });

  final String warehouseLocation;
  final List<String> warehouseOptions;
  final ValueChanged<String> onWarehouseChanged;
  final String priceLevel;
  final List<String> priceLevelOptions;
  final ValueChanged<String> onPriceLevelChanged;
  final String? selectedPriceList;
  final List<String> priceListOptions;
  final ValueChanged<String?> onPriceListChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Warehouse location - left side
          const Text(
            'Warehouse Location',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 280,
            child: CustomPaint(
              foregroundPainter: const _DottedUnderlinePainter(),
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
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
          // Price List - near warehouse
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
                  child: FormDropdown<String>(
                    value: selectedPriceList,
                    items: priceListOptions,
                    hint: 'Select Price List',
                    height: 36,
                    hideBorderDefault: true,
                    allowClear: true,
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

class _RmaPreferencesDialog extends StatefulWidget {
  final String prefix;
  final String nextNumber;
  final bool autoGenerate;
  final void Function(String prefix, String nextNumber, bool autoGenerate)
  onSave;

  const _RmaPreferencesDialog({
    required this.prefix,
    required this.nextNumber,
    required this.autoGenerate,
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
                    'Configure Credit Note Number Preferences',
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
          // Location / Series table
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Location',
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
                  children: const [
                    Expanded(
                      child: Text(
                        'ZABNIX PRIVATE LIMITED',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
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
                  'Your Credit Note Numbers are set on auto-generate mode to save your time.',
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
                        'Continue auto-generating Credit Note Numbers',
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
                        'Enter Credit Note Numbers manually',
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
                  onPressed: () {
                    widget.onSave(
                      _prefixController.text,
                      _nextNumberController.text,
                      _autoGenerate,
                    );
                    Navigator.of(context).pop();
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

class _HeaderBackgroundBand extends StatelessWidget {
  final Widget child;

  const _HeaderBackgroundBand({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 1000 ? 16.0 : 40.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyWidth = screenWidth - (horizontalPadding * 2);
        final rightBleed =
            (bodyWidth - constraints.maxWidth + horizontalPadding)
                .clamp(0.0, double.infinity)
                .toDouble();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: -horizontalPadding,
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

class _CnRowActionMenuHoverItem extends StatefulWidget {
  final String label;
  final double width;
  final double height;
  final bool highlighted;

  const _CnRowActionMenuHoverItem({
    required this.label,
    required this.width,
    required this.height,
    this.highlighted = false,
  });

  @override
  State<_CnRowActionMenuHoverItem> createState() =>
      _CnRowActionMenuHoverItemState();
}

class _CnRowActionMenuHoverItemState extends State<_CnRowActionMenuHoverItem> {
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

class _CnRowActionIconButton extends StatefulWidget {
  final IconData icon;

  const _CnRowActionIconButton({required this.icon});

  @override
  State<_CnRowActionIconButton> createState() => _CnRowActionIconButtonState();
}

class _CnRowActionIconButtonState extends State<_CnRowActionIconButton> {
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

class _CnBulkMenuHoverItem extends StatefulWidget {
  final String label;
  final IconData? icon;
  const _CnBulkMenuHoverItem({required this.label, this.icon});

  @override
  State<_CnBulkMenuHoverItem> createState() => _CnBulkMenuHoverItemState();
}

class _CnBulkMenuHoverItemState extends State<_CnBulkMenuHoverItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered ? Colors.white : AppTheme.textPrimary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 14, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CnInfoDropdownHoverItem extends StatefulWidget {
  final String label;

  const _CnInfoDropdownHoverItem({required this.label});

  @override
  State<_CnInfoDropdownHoverItem> createState() =>
      _CnInfoDropdownHoverItemState();
}

class _CnInfoDropdownHoverItemState extends State<_CnInfoDropdownHoverItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            color: _hovered ? Colors.white : AppTheme.textPrimary,
            fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _CnBulkUpdateActionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool hasDropdown;
  final VoidCallback onTap;
  final VoidCallback? onDropdownTap;

  const _CnBulkUpdateActionButton({
    required this.label,
    required this.isSelected,
    this.hasDropdown = false,
    required this.onTap,
    this.onDropdownTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isSelected
        ? Border.all(color: AppTheme.primaryBlue, width: 2)
        : null;

    if (!hasDropdown) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.successGreen,
            borderRadius: BorderRadius.circular(6),
            border: border,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Split button: label on left, vertical divider, chevron on right
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.successGreen,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              color: Colors.transparent,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white.withAlpha(100)),
          GestureDetector(
            onTap: onDropdownTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              color: Colors.transparent,
              child: const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CnBulkUpdateLineItemsDialog extends StatefulWidget {
  const _CnBulkUpdateLineItemsDialog();

  @override
  State<_CnBulkUpdateLineItemsDialog> createState() =>
      _CnBulkUpdateLineItemsDialogState();
}

class _CnBulkUpdateLineItemsDialogState
    extends State<_CnBulkUpdateLineItemsDialog> {
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

class _CnBulkUpdateAccountDialog extends StatefulWidget {
  const _CnBulkUpdateAccountDialog();

  @override
  State<_CnBulkUpdateAccountDialog> createState() =>
      _CnBulkUpdateAccountDialogState();
}

class _CnBulkUpdateAccountDialogState
    extends State<_CnBulkUpdateAccountDialog> {
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

class _CnBulkUpdateDiscountAccountDialog extends StatefulWidget {
  const _CnBulkUpdateDiscountAccountDialog();

  @override
  State<_CnBulkUpdateDiscountAccountDialog> createState() =>
      _CnBulkUpdateDiscountAccountDialogState();
}

class _CnBulkUpdateDiscountAccountDialogState
    extends State<_CnBulkUpdateDiscountAccountDialog> {
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

const List<String> _cnBillingAddressLines = [
  'malayanakath(h)',
  'vengoor (po)',
  'perinthalmanna',
  'Kerala 679322',
  'India',
  'Phone: +91-9895357101',
];

const List<String> _cnShippingAddressLines = [
  'malayanakath(h)',
  'vengoor',
  'PERINTHALMANNA',
  'perinthalmanna',
  'kerala 679322',
  'India',
  'Phone: +91-08606259910',
];

class _CnCustomerAddressPanel extends StatefulWidget {
  final String customerName;
  final double? width;
  const _CnCustomerAddressPanel({required this.customerName, this.width});

  @override
  State<_CnCustomerAddressPanel> createState() =>
      _CnCustomerAddressPanelState();
}

class _CnCustomerAddressPanelState extends State<_CnCustomerAddressPanel> {
  final LayerLink _billingLink = LayerLink();
  final LayerLink _shippingLink = LayerLink();
  OverlayEntry? _billingOverlay;
  OverlayEntry? _shippingOverlay;

  int _selectedBillingIndex = 0;
  int _selectedShippingIndex = 0;

  List<Map<String, dynamic>> get _addresses => [
    {'name': widget.customerName, 'lines': _cnBillingAddressLines},
    {
      'name': '${widget.customerName} (Branch)',
      'lines': [
        'vengoor',
        'PERINTHALMANNA',
        'perinthalmanna, Kerala',
        'India , 679322',
        '+91-08606259910',
      ],
    },
  ];

  void _openPicker({required bool isBilling}) {
    final link = isBilling ? _billingLink : _shippingLink;
    final selectedIndex = isBilling
        ? _selectedBillingIndex
        : _selectedShippingIndex;

    final overlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => _closePicker(isBilling: isBilling),
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              offset: const Offset(0, 24),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: AppTheme.backgroundColor,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 340,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._addresses.asMap().entries.map((entry) {
                          final i = entry.key;
                          final addr = entry.value;
                          final isSelected = i == selectedIndex;
                          return _CnAddressPickerRow(
                            address: addr,
                            isSelected: isSelected,
                            onSelected: () {
                              setState(() {
                                if (isBilling) {
                                  _selectedBillingIndex = i;
                                } else {
                                  _selectedShippingIndex = i;
                                }
                              });
                              _closePicker(isBilling: isBilling);
                            },
                            onEdit: isSelected
                                ? () {
                                    _closePicker(isBilling: isBilling);
                                    _openEditDialog(
                                      context,
                                      addr,
                                      isBilling: isBilling,
                                    );
                                  }
                                : null,
                          );
                        }),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        _CnNewAddressAction(
                          onTap: () {
                            _closePicker(isBilling: isBilling);
                            _openNewAddressDialog(
                              context,
                              isBilling: isBilling,
                            );
                          },
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

    if (isBilling) {
      _billingOverlay?.remove();
      _billingOverlay = overlay;
    } else {
      _shippingOverlay?.remove();
      _shippingOverlay = overlay;
    }

    Overlay.of(context).insert(overlay);
    setState(() {});
  }

  void _closePicker({required bool isBilling}) {
    if (isBilling) {
      _billingOverlay?.remove();
      _billingOverlay = null;
    } else {
      _shippingOverlay?.remove();
      _shippingOverlay = null;
    }
    if (mounted) setState(() {});
  }

  void _openEditDialog(
    BuildContext context,
    Map<String, dynamic> addr, {
    required bool isBilling,
    bool isNewAddress = false,
  }) {
    final addressTitle = isBilling ? 'Billing Address' : 'Shipping Address';
    showDialog<void>(
      context: context,
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.4),
      useSafeArea: false,
      builder: (_) => _CnAddressEditDialog(
        address: addr,
        title: isNewAddress ? 'New $addressTitle' : addressTitle,
        isNewAddress: isNewAddress,
      ),
    );
  }

  void _openNewAddressDialog(BuildContext context, {required bool isBilling}) {
    _openEditDialog(
      context,
      const <String, dynamic>{'name': '', 'lines': <String>[]},
      isBilling: isBilling,
      isNewAddress: true,
    );
  }

  @override
  void dispose() {
    _billingOverlay?.remove();
    _shippingOverlay?.remove();
    super.dispose();
  }

  Widget _buildAddressColumn({
    required String title,
    required LayerLink link,
    required bool isBilling,
    required int selectedIndex,
  }) {
    final addr = _addresses[selectedIndex];
    final lines = addr['lines'] as List<String>;
    final isOpen = isBilling
        ? _billingOverlay != null
        : _shippingOverlay != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: link,
          child: GestureDetector(
            onTap: () => isOpen
                ? _closePicker(isBilling: isBilling)
                : _openPicker(isBilling: isBilling),
            child: Container(
              padding: isOpen
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : EdgeInsets.zero,
              decoration: isOpen
                  ? BoxDecoration(
                      border: Border.all(color: AppTheme.primaryBlue),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
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
                    color: isOpen
                        ? AppTheme.primaryBlue
                        : AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          addr['name'] as String,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 166, bottom: 8, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: widget.width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAddressColumn(
                  title: 'BILLING ADDRESS',
                  link: _billingLink,
                  isBilling: true,
                  selectedIndex: _selectedBillingIndex,
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _buildAddressColumn(
                  title: 'SHIPPING ADDRESS',
                  link: _shippingLink,
                  isBilling: false,
                  selectedIndex: _selectedShippingIndex,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Address Picker Popup Rows ──────────────────────────────────────────────────

class _CnAddressPickerRow extends StatefulWidget {
  final Map<String, dynamic> address;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback? onEdit;

  const _CnAddressPickerRow({
    required this.address,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
  });

  @override
  State<_CnAddressPickerRow> createState() => _CnAddressPickerRowState();
}

class _CnAddressPickerRowState extends State<_CnAddressPickerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lines = widget.address['lines'] as List<String>? ?? const <String>[];
    final bgColor = _hovered
        ? AppTheme.primaryBlue
        : widget.isSelected
        ? AppTheme.bgDisabled
        : AppTheme.backgroundColor;
    final titleColor = _hovered
        ? AppTheme.backgroundColor
        : AppTheme.textPrimary;
    final detailColor = _hovered
        ? AppTheme.backgroundColor.withValues(alpha: 0.82)
        : AppTheme.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.address['name'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...lines.map(
                      (line) => Text(
                        line,
                        style: TextStyle(fontSize: 12, color: detailColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onEdit != null)
                GestureDetector(
                  onTap: widget.onEdit,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      LucideIcons.pencil,
                      size: 14,
                      color: _hovered
                          ? AppTheme.backgroundColor
                          : AppTheme.primaryBlue,
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

class _CnNewAddressAction extends StatefulWidget {
  final VoidCallback onTap;

  const _CnNewAddressAction({required this.onTap});

  @override
  State<_CnNewAddressAction> createState() => _CnNewAddressActionState();
}

class _CnNewAddressActionState extends State<_CnNewAddressAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = _hovered ? AppTheme.backgroundColor : AppTheme.primaryBlue;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.plusCircle, size: 16, color: fgColor),
              const SizedBox(width: 8),
              Text(
                'New address',
                style: TextStyle(
                  fontSize: 13,
                  color: fgColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── New Item Dialog ────────────────────────────────────────────────────────────

class _CnNewItemDialog extends StatefulWidget {
  final String title;
  final _CnLineItem? item;
  const _CnNewItemDialog({this.title = 'New Item', this.item});

  @override
  State<_CnNewItemDialog> createState() => _CnNewItemDialogState();
}

class _CnNewItemDialogState extends State<_CnNewItemDialog> {
  String _type = 'Goods';
  String _taxPreference = 'Taxable';
  String _unit = '';
  String _category = '';
  String? _manufacturer;
  String? _brand;
  String _inventoryValuation = 'FIFO (First In, First Out)';
  String _trackingMode = 'None';
  String _dimUnit = 'cm';
  String _weightUnit = 'kg';
  bool _returnable = true;
  bool _sellable = true;
  bool _purchasable = true;
  bool _trackInventory = true;

  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _salesDescCtrl = TextEditingController();
  final _purchaseDescCtrl = TextEditingController();
  final _dimLCtrl = TextEditingController();
  final _dimWCtrl = TextEditingController();
  final _dimHCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _upcCtrl = TextEditingController();
  final _mpnCtrl = TextEditingController();
  final _eanCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _reorderCtrl = TextEditingController();

  static const _units = ['PCS', 'KG', 'LTR', 'MTR', 'BOX', 'PACK'];
  static const _categories = ['Electronics', 'Pharma', 'FMCG', 'Other'];
  static const _taxPreferences = ['Taxable', 'Non-Taxable', 'Exempt'];
  static const _salesAccounts = ['Sales', 'Other Income'];
  static const _purchaseAccounts = ['Cost of Goods Sold', 'Purchases'];
  static const _vendors = ['Vendor A', 'Vendor B'];
  static const _inventoryAccounts = ['Inventory Asset', 'Stock Account'];
  static const _valuationMethods = [
    'FIFO (First In, First Out)',
    'LIFO (Last In, First Out)',
    'Average Cost',
  ];
  static const _manufacturers = [
    'CIPLA',
    'Sun Pharma',
    "Dr. Reddy's",
    'Abbott',
  ];
  static const _brands = ['Brand A', 'Brand B', 'Brand C'];
  static const _reportingTagDefs = [
    ('ADGF', ['None', 'Option 1', 'Option 2']),
    ('Schedule', ['None', 'H', 'H1', 'X']),
    ('Demo advanced reporting tag', ['None', 'Tag 1', 'Tag 2']),
  ];

  final Map<String, String> _tagValues = {};

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _nameCtrl.text = item.name;
      _hsnCtrl.text = item.hsnCode;
      if (item.tax != null) _taxPreference = item.tax!;
    }
    for (final tag in _reportingTagDefs) {
      _tagValues[tag.$1] = 'None';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _skuCtrl,
      _hsnCtrl,
      _sellingPriceCtrl,
      _costPriceCtrl,
      _salesDescCtrl,
      _purchaseDescCtrl,
      _dimLCtrl,
      _dimWCtrl,
      _dimHCtrl,
      _weightCtrl,
      _upcCtrl,
      _mpnCtrl,
      _eanCtrl,
      _isbnCtrl,
      _reorderCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(context).size.height - 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryBlue,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type — ? tooltip next to label, radios on right
                      _hRow(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Type',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const ZTooltip(
                              message:
                                  'Select if this item is a physical good or a service. Remember that you cannot change the type if this item is included in a transaction.',
                              maxWidth: 280,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _radio('Goods'),
                            const SizedBox(width: 16),
                            _radio('Service'),
                          ],
                        ),
                      ),
                      _hRow(
                        _reqLabel('Name'),
                        CustomTextField(controller: _nameCtrl, autoFocus: true),
                      ),
                      _hRow(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'SKU',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const ZTooltip(
                              message: 'The Stock Keeping Unit of the item',
                            ),
                          ],
                        ),
                        CustomTextField(controller: _skuCtrl),
                      ),
                      _hRow(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _reqLabel('Unit'),
                            const SizedBox(width: 4),
                            const ZTooltip(
                              message:
                                  'The item will be measured in terms of this unit (e.g.: kg, dozen)',
                              maxWidth: 220,
                            ),
                          ],
                        ),
                        FormDropdown<String>(
                          value: _unit.isEmpty ? null : _unit,
                          items: _units,
                          onChanged: (v) => setState(() => _unit = v ?? ''),
                          hint: 'Select unit',
                        ),
                      ),
                      _hRow(
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        FormDropdown<String>(
                          value: _category.isEmpty ? null : _category,
                          items: _categories,
                          onChanged: (v) => setState(() => _category = v ?? ''),
                          hint: 'Select Category',
                          allowClear: true,
                        ),
                      ),
                      // Returnable checkbox — offset to align with field column
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 130 + 12),
                            Checkbox(
                              value: _returnable,
                              onChanged: (v) =>
                                  setState(() => _returnable = v ?? true),
                              activeColor: AppTheme.primaryBlue,
                              side: const BorderSide(
                                color: AppTheme.borderLight,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Returnable Item',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.helpCircle,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                      _hRow(
                        const Text(
                          'HSN Code',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        CustomTextField(controller: _hsnCtrl),
                      ),
                      _hRow(
                        _reqLabel('Tax Preference'),
                        FormDropdown<String>(
                          value: _taxPreference,
                          items: _taxPreferences,
                          onChanged: (v) => setState(
                            () => _taxPreference = v ?? _taxPreference,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 10),

                      // Dimensions + Weight — inline two-column
                      _pairRow(
                        label1: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Dimensions',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '(Length X Width X Height)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        field1: _dimensionField(),
                        label2: const Text(
                          'Weight',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        field2: _unitAttachedNumberField(
                          controller: _weightCtrl,
                          unit: _weightUnit,
                          units: const ['kg', 'g', 'lb'],
                          onUnitChanged: (v) =>
                              setState(() => _weightUnit = v ?? 'kg'),
                        ),
                        crossAlign: CrossAxisAlignment.start,
                      ),
                      const SizedBox(height: 10),

                      // Manufacturer + Brand
                      _pairRow(
                        label1: const Text(
                          'Manufacturer',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        field1: FormDropdown<String>(
                          value: _manufacturer,
                          items: _manufacturers,
                          onChanged: (v) => setState(() => _manufacturer = v),
                          hint: 'Select Manufacturer',
                          allowClear: true,
                        ),
                        label2: const Text(
                          'Brand',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        field2: FormDropdown<String>(
                          value: _brand,
                          items: _brands,
                          onChanged: (v) => setState(() => _brand = v),
                          hint: 'Select Brand',
                          allowClear: true,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // UPC + MPN
                      _pairRow(
                        label1: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'UPC',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(width: 4),
                            ZTooltip(
                              message:
                                  'Twelve digit unique number associated with the bar code (Universal Product Code)',
                              maxWidth: 240,
                            ),
                          ],
                        ),
                        field1: CustomTextField(controller: _upcCtrl),
                        label2: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'MPN',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(width: 4),
                            ZTooltip(
                              message:
                                  'Manufacturing Part Number unambiguously identifies a part design',
                              maxWidth: 240,
                            ),
                          ],
                        ),
                        field2: CustomTextField(controller: _mpnCtrl),
                      ),
                      const SizedBox(height: 10),

                      // EAN + ISBN
                      _pairRow(
                        label1: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'EAN',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(width: 4),
                            ZTooltip(
                              message:
                                  'Thirteen digit unique number (International Article Number)',
                              maxWidth: 240,
                            ),
                          ],
                        ),
                        field1: CustomTextField(controller: _eanCtrl),
                        label2: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'ISBN',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(width: 4),
                            ZTooltip(
                              message:
                                  'Thirteen digit unique commercial book identifier (International Standard Book Number)',
                              maxWidth: 240,
                            ),
                          ],
                        ),
                        field2: CustomTextField(controller: _isbnCtrl),
                      ),
                      const Divider(height: 32, color: AppTheme.borderLight),

                      // Sales + Purchase Information
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _infoSection(isSales: true)),
                          const SizedBox(width: 32),
                          Expanded(child: _infoSection(isSales: false)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Default Tax Rates
                      Row(
                        children: [
                          const Text(
                            'Default Tax Rates',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            LucideIcons.pencil,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _taxRateRow('Intra State Tax Rate', 'GST12 (12 %)'),
                      const SizedBox(height: 8),
                      _taxRateRow('Inter State Tax Rate', 'IGST12 (12 %)'),
                      const SizedBox(height: 20),

                      // Track Inventory
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _trackInventory,
                            onChanged: (v) =>
                                setState(() => _trackInventory = v ?? true),
                            activeColor: AppTheme.primaryBlue,
                            side: const BorderSide(color: AppTheme.borderLight),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Track Inventory for this item',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "You cannot enable/disable inventory tracking once you've created transactions for this item",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (_trackInventory) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFD666)),
                          ),
                          child: const Text(
                            'Note: You can configure the opening stock and stock tracking for this item under the Items module',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B6914),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Advanced Inventory Tracking',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _trackingRadio('None'),
                        _trackingRadio('Track Serial Number'),
                        _trackingRadio('Track Batches'),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _reqDropdown(
                                'Inventory Account',
                                '',
                                _inventoryAccounts,
                                (_) {},
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _reqDropdown(
                                'Inventory Valuation Method',
                                _inventoryValuation,
                                _valuationMethods,
                                (v) => setState(
                                  () => _inventoryValuation =
                                      v ?? _inventoryValuation,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 300,
                          child: _optField(
                            'Reorder Point',
                            _reorderCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                      const Divider(height: 32, color: AppTheme.borderLight),

                      // Reporting Tags
                      const Text(
                        'Reporting Tags',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._buildReportingTagRows(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Save',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
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
      ),
    );
  }

  List<Widget> _buildReportingTagRows() {
    final rows = <Widget>[];
    for (int i = 0; i < _reportingTagDefs.length; i += 2) {
      final tag1 = _reportingTagDefs[i];
      if (i + 1 < _reportingTagDefs.length) {
        final tag2 = _reportingTagDefs[i + 1];
        rows.add(
          _pairRow(
            label1: Text(
              tag1.$1,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
            field1: FormDropdown<String>(
              value: _tagValues[tag1.$1],
              items: tag1.$2,
              onChanged: (v) =>
                  setState(() => _tagValues[tag1.$1] = v ?? 'None'),
            ),
            label2: Text(
              tag2.$1,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
            field2: FormDropdown<String>(
              value: _tagValues[tag2.$1],
              items: tag2.$2,
              onChanged: (v) =>
                  setState(() => _tagValues[tag2.$1] = v ?? 'None'),
            ),
          ),
        );
      } else {
        rows.add(
          _hRow(
            Text(
              tag1.$1,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
            FormDropdown<String>(
              value: _tagValues[tag1.$1],
              items: tag1.$2,
              onChanged: (v) =>
                  setState(() => _tagValues[tag1.$1] = v ?? 'None'),
            ),
          ),
        );
      }
      rows.add(const SizedBox(height: 10));
    }
    return rows;
  }

  Widget _reqLabel(String text) => RichText(
    text: TextSpan(
      text: text,
      style: const TextStyle(fontSize: 13, color: AppTheme.errorRed),
      children: const [
        TextSpan(
          text: '*',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _hRow(Widget label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 130, child: label),
          const SizedBox(width: 12),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _pairRow({
    required Widget label1,
    required Widget field1,
    required Widget label2,
    required Widget field2,
    CrossAxisAlignment crossAlign = CrossAxisAlignment.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: crossAlign,
        children: [
          SizedBox(width: 110, child: label1),
          const SizedBox(width: 10),
          Expanded(child: field1),
          const SizedBox(width: 24),
          SizedBox(width: 90, child: label2),
          const SizedBox(width: 10),
          Expanded(child: field2),
        ],
      ),
    );
  }

  Widget _radio(String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Radio<String>(
        value: label,
        groupValue: _type,
        onChanged: (v) => setState(() => _type = v ?? _type),
        activeColor: AppTheme.primaryBlue,
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      ),
    ],
  );

  Widget _trackingRadio(String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Radio<String>(
        value: label,
        groupValue: _trackingMode,
        onChanged: (v) => setState(() => _trackingMode = v ?? _trackingMode),
        activeColor: AppTheme.primaryBlue,
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      ),
    ],
  );

  Widget _optField(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      CustomTextField(controller: ctrl, keyboardType: keyboardType),
    ],
  );

  Widget _reqDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const TextSpan(
              text: '*',
              style: TextStyle(fontSize: 13, color: AppTheme.errorRed),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      FormDropdown<String>(
        value: value.isEmpty ? null : value,
        items: items,
        onChanged: onChanged,
      ),
    ],
  );

  Widget _dimensionField() {
    return _unitAttachedInputShell(
      unit: _dimUnit,
      units: const ['cm', 'm', 'in', 'ft'],
      onUnitChanged: (v) => setState(() => _dimUnit = v ?? 'cm'),
      child: Row(
        children: [
          Expanded(child: _inlineNumberInput(_dimLCtrl)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'x',
              style: TextStyle(fontSize: 14, color: AppTheme.textDisabled),
            ),
          ),
          Expanded(child: _inlineNumberInput(_dimWCtrl)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'x',
              style: TextStyle(fontSize: 14, color: AppTheme.textDisabled),
            ),
          ),
          Expanded(child: _inlineNumberInput(_dimHCtrl)),
        ],
      ),
    );
  }

  Widget _unitAttachedNumberField({
    required TextEditingController controller,
    required String unit,
    required List<String> units,
    required ValueChanged<String?> onUnitChanged,
  }) {
    return _unitAttachedInputShell(
      unit: unit,
      units: units,
      onUnitChanged: onUnitChanged,
      child: _inlineNumberInput(controller, textAlign: TextAlign.start),
    );
  }

  Widget _unitAttachedInputShell({
    required Widget child,
    required String unit,
    required List<String> units,
    required ValueChanged<String?> onUnitChanged,
  }) {
    return Container(
      height: 38,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: child,
            ),
          ),
          SizedBox(
            width: 66,
            child: FormDropdown<String>(
              value: unit,
              items: units,
              onChanged: onUnitChanged,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              fillColor: AppTheme.bgDisabled,
              borderRadius: BorderRadius.zero,
              border: const Border(
                left: BorderSide(color: AppTheme.borderColor),
              ),
              showArrowOnSelection: true,
              showSearch: false,
              textStyle: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineNumberInput(
    TextEditingController controller, {
    TextAlign textAlign = TextAlign.center,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: textAlign,
      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _infoSection({required bool isSales}) {
    final title = isSales ? 'Sales Information' : 'Purchase Information';
    final checkLabel = isSales ? 'Sellable' : 'Purchasable';
    final checked = isSales ? _sellable : _purchasable;
    final priceLabel = isSales ? 'Selling Price' : 'Cost Price';
    final priceCtrl = isSales ? _sellingPriceCtrl : _costPriceCtrl;
    final accounts = isSales ? _salesAccounts : _purchaseAccounts;
    final defaultAccount = isSales ? 'Sales' : 'Cost of Goods Sold';
    final descCtrl = isSales ? _salesDescCtrl : _purchaseDescCtrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Checkbox(
              value: checked,
              onChanged: (v) => setState(() {
                if (isSales) {
                  _sellable = v ?? true;
                } else {
                  _purchasable = v ?? true;
                }
              }),
              activeColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.borderLight),
            ),
            Text(
              checkLabel,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: priceLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const TextSpan(
                text: '*',
                style: TextStyle(fontSize: 13, color: AppTheme.errorRed),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        CustomTextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          prefixWidget: const Text(
            'INR',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          prefixBox: true,
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Account',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextSpan(
                text: '*',
                style: TextStyle(fontSize: 13, color: AppTheme.errorRed),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        FormDropdown<String>(
          value: defaultAccount,
          items: accounts,
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        CustomTextField(controller: descCtrl, maxLines: 3),
        if (!isSales) ...[
          const SizedBox(height: 12),
          const Text(
            'Preferred Vendor',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          FormDropdown<String>(
            value: null,
            items: _vendors,
            onChanged: (_) {},
            hint: 'Select vendor',
          ),
        ],
      ],
    );
  }

  Widget _taxRateRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dashed,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
      ],
    ),
  );
}

// ─── Address Edit Dialog ───────────────────────────────────────────────────────

class _CnAddressEditDialog extends StatefulWidget {
  final Map<String, dynamic> address;
  final String title;
  final bool isNewAddress;
  const _CnAddressEditDialog({
    required this.address,
    required this.title,
    this.isNewAddress = false,
  });

  @override
  State<_CnAddressEditDialog> createState() => _CnAddressEditDialogState();
}

class _CnAddressEditDialogState extends State<_CnAddressEditDialog> {
  late final TextEditingController _attentionCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _street2Ctrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _faxCtrl;
  String? _country;
  String? _state;

  List<String> _countries = [];
  List<String> _states = [];
  List<Map<String, dynamic>> _dbCountries = [];

  Future<void> _loadCountries() async {
    try {
      final lookupsService = LookupsApiService();
      final countries = await lookupsService.getCountries();
      if (mounted) {
        setState(() {
          _dbCountries = countries;
          _countries = countries
              .map((c) => c['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          
          if (_country != null && _country!.isNotEmpty && !_countries.contains(_country)) {
            _countries.insert(0, _country!);
          }
        });
        if (_country != null) {
          _loadStatesForCountry(_country!);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadStatesForCountry(String countryName) async {
    final match = _dbCountries.firstWhere(
      (c) => (c['name']?.toString() ?? '').toLowerCase() == countryName.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );
    final shortCode = match['short_code']?.toString() ?? '';
    if (shortCode.isEmpty) {
      setState(() {
        _states = [];
      });
      return;
    }

    try {
      final lookupsService = LookupsApiService();
      final states = await lookupsService.getStates(shortCode);
      if (mounted) {
        setState(() {
          _states = states
              .map((s) => s['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          
          if (_state != null && _state!.isNotEmpty && !_states.contains(_state)) {
            _states.insert(0, _state!);
          }
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    final lines = widget.address['lines'] as List<String>? ?? [];
    _attentionCtrl = TextEditingController(
      text: widget.address['name'] as String? ?? '',
    );
    _addressCtrl = TextEditingController(
      text: lines.isNotEmpty ? lines[0] : '',
    );
    _street2Ctrl = TextEditingController(
      text: lines.length > 1 ? lines[1] : '',
    );
    _cityCtrl = TextEditingController(text: lines.length > 2 ? lines[2] : '');
    _pinCtrl = TextEditingController(
      text: lines.length > 3 ? lines[3].replaceAll(RegExp(r'[^0-9]'), '') : '',
    );
    _phoneCtrl = TextEditingController(
      text: lines.length > 4 ? lines[4].replaceAll(RegExp(r'[^0-9]'), '') : '',
    );
    _faxCtrl = TextEditingController();
    _country = widget.isNewAddress ? null : 'India';
    _state = widget.isNewAddress ? null : 'Kerala';
    _loadCountries();
  }

  @override
  void dispose() {
    for (final c in [
      _attentionCtrl,
      _addressCtrl,
      _street2Ctrl,
      _cityCtrl,
      _pinCtrl,
      _phoneCtrl,
      _faxCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noteText = widget.isNewAddress
        ? 'This address will be added for this customer.'
        : 'Changes made here will be updated for this customer.';

    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        left: 80,
        right: 80,
        top: 0,
        bottom: 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryBlue,
                          width: 1.5,
                        ),
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

            // ── Scrollable body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Attention', _attentionCtrl),
                    const SizedBox(height: 16),
                    _label('Country/Region'),
                    const SizedBox(height: 6),
                    FormDropdown<String>(
                      value: _country,
                      items: _countries,
                      hint: 'Select country',
                      onChanged: (v) {
                        setState(() {
                          _country = v;
                          _state = null;
                        });
                        if (v != null) {
                          _loadStatesForCountry(v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Address'),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _addressCtrl,
                      maxLines: 3,
                      hintText: 'Street / Area',
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _street2Ctrl,
                      maxLines: 3,
                      hintText: 'Street 2',
                    ),
                    const SizedBox(height: 16),
                    _field('City', _cityCtrl),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('State'),
                              const SizedBox(height: 6),
                              FormDropdown<String>(
                                value: _state,
                                items: _states,
                                hint: 'Select state',
                                onChanged: (v) => setState(() => _state = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field(
                            'Pin Code',
                            _pinCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Phone'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.borderLight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          '+91',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      hintText: 'Phone number',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field(
                            'Fax Number',
                            _faxCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Note: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: noteText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Footer ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
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

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppTheme.textPrimary,
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        CustomTextField(controller: ctrl, keyboardType: keyboardType),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _CnDiscountTypeOption extends StatelessWidget {
  final String label;
  final bool selected;

  const _CnDiscountTypeOption({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Container(
        width: 36,
        height: 34,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppTheme.primaryBlueDark : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CnCostPriceButton extends StatefulWidget {
  final _CnLineItem item;
  const _CnCostPriceButton({required this.item});

  @override
  State<_CnCostPriceButton> createState() => _CnCostPriceButtonState();
}

class _CnCostPriceButtonState extends State<_CnCostPriceButton> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _overlay;
  late final TextEditingController _costController;

  static const double _popoverHeight = 340;

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(
      text: widget.item.costPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _costController.dispose();
    _closeOverlay();
    super.dispose();
  }

  void _openOverlay() {
    _costController.text = widget.item.costPrice.toStringAsFixed(2);

    // Measure anchor position to decide above/below
    final renderBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final screenHeight = MediaQuery.of(context).size.height;
    double yOffset = 28;
    Alignment followerAlignment = Alignment.topLeft;
    if (renderBox != null) {
      final anchorPos = renderBox.localToGlobal(Offset.zero);
      final anchorBottom = anchorPos.dy + renderBox.size.height;
      final spaceBelow = screenHeight - anchorBottom;
      if (spaceBelow < _popoverHeight && anchorPos.dy > _popoverHeight) {
        // Not enough space below — flip above
        yOffset = -(renderBox.size.height + _popoverHeight + 4);
        followerAlignment = Alignment.bottomLeft;
      }
    }

    _overlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeOverlay,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, yOffset),
              child: Align(
                alignment: followerAlignment,
                child: Material(
                  color: Colors.white,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 320,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: StatefulBuilder(
                      builder: (ctx2, setOverlayState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Cost Price',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _closeOverlay,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppTheme.primaryBlue,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        LucideIcons.x,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Rupee prefix + input
                                  Container(
                                    height: 36,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.borderLight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: AppTheme.borderLight,
                                              ),
                                            ),
                                            color: Color(0xFFF9FAFB),
                                          ),
                                          child: const Text(
                                            '₹',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: _costController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Info banner
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4E6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'If you update the cost price manually, the system will not update the cost price automatically based on the recent transactions.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF92400E),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Recent Price + Apply
                                  Row(
                                    children: [
                                      Text(
                                        'Recent Price: ₹${widget.item.costPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () {
                                          setOverlayState(() {
                                            _costController.text = widget
                                                .item
                                                .costPrice
                                                .toStringAsFixed(2);
                                          });
                                        },
                                        child: const Text(
                                          'Apply',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // View Purchase Information
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'View Purchase Information',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Update + Cancel
                                  Row(
                                    children: [
                                      ZButton.primary(
                                        label: 'Update',
                                        onPressed: () {
                                          final parsed =
                                              double.tryParse(
                                                _costController.text.trim(),
                                              ) ??
                                              widget.item.costPrice;
                                          setState(
                                            () =>
                                                widget.item.costPrice = parsed,
                                          );
                                          _closeOverlay();
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ZButton.secondary(
                                        label: 'Cancel',
                                        onPressed: _closeOverlay,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      key: _anchorKey,
      link: _layerLink,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.tag, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            'Cost Price: ₹${widget.item.costPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _overlay == null ? _openOverlay : _closeOverlay,
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CnReportingTagsForm extends StatelessWidget {
  const _CnReportingTagsForm();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 650,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Reporting Tags',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            value: 'None',
                            items: const ['None', 'Option 1', 'Option 2'],
                            hint: 'None',
                            height: 36,
                            onChanged: (val) {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
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
                            value: 'None',
                            items: const ['None', 'Option 1', 'Option 2'],
                            hint: 'None',
                            height: 36,
                            onChanged: (val) {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                        value: 'None',
                        items: const ['None', 'Option 1', 'Option 2'],
                        hint: 'None',
                        height: 36,
                        onChanged: (val) {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
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
                    'Save',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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

class _AddContactPersonDialog extends StatefulWidget {
  final VoidCallback onClose;

  const _AddContactPersonDialog({required this.onClose});

  @override
  State<_AddContactPersonDialog> createState() =>
      _AddContactPersonDialogState();
}

class _AddContactPersonDialogState extends State<_AddContactPersonDialog> {
  static const double _fieldHeight = 36.0;
  static const double _labelWidth = 200.0;
  static const double _rowGap = 16.0;
  static const double _fieldColumnGap = 32.0;
  static const double _uploadColumnGap = 56.0;

  String? _salutation;
  String _workPhonePrefix = '+91';
  String _mobilePrefix = '+91';
  PlatformFile? _profileImage;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _workPhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _workPhoneController.dispose();
    _mobileController.dispose();
    _whatsappController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
      allowMultiple: false,
    );
    if (!mounted) return;
    if (result != null && result.files.isNotEmpty) {
      setState(() => _profileImage = result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width - 192)
        .clamp(760.0, 1660.0)
        .toDouble();

    return SizedBox(
      width: dialogWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.fromLTRB(32, 0, 24, 0),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add Contact Person',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 34,
                    height: 46,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryBlue, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 22,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _CnContactDialogRow(
                        label: 'Name',
                        labelWidth: _labelWidth,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 160,
                              child: FormDropdown<String>(
                                value: _salutation,
                                items: const ['Mr.', 'Mrs.', 'Ms.', 'Dr.'],
                                hint: 'Salutation',
                                height: _fieldHeight,
                                showSearch: false,
                                onChanged: (value) {
                                  setState(() => _salutation = value);
                                },
                              ),
                            ),
                            const SizedBox(width: _fieldColumnGap),
                            Expanded(
                              child: CustomTextField(
                                controller: _firstNameController,
                                hintText: 'First Name',
                                height: _fieldHeight,
                              ),
                            ),
                            const SizedBox(width: _fieldColumnGap),
                            Expanded(
                              child: CustomTextField(
                                controller: _lastNameController,
                                hintText: 'Last Name',
                                height: _fieldHeight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: _rowGap),
                      _CnContactDialogRow(
                        label: 'Email Address',
                        labelWidth: _labelWidth,
                        child: CustomTextField(
                          controller: _emailController,
                          height: _fieldHeight,
                          keyboardType: TextInputType.emailAddress,
                          contentCase: ContentCase.none,
                        ),
                      ),
                      const SizedBox(height: _rowGap),
                      _CnContactDialogRow(
                        label: 'Phone',
                        labelWidth: _labelWidth,
                        child: Column(
                          children: [
                            _CnContactDialogPhoneField(
                              prefix: _workPhonePrefix,
                              controller: _workPhoneController,
                              hintText: 'Work Phone',
                              onPrefixChanged: (value) {
                                if (value != null) {
                                  setState(() => _workPhonePrefix = value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _CnContactDialogPhoneField(
                              prefix: _mobilePrefix,
                              controller: _mobileController,
                              hintText: 'Mobile',
                              onPrefixChanged: (value) {
                                if (value != null) {
                                  setState(() => _mobilePrefix = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: _rowGap),
                      _CnContactDialogRow(
                        label: 'WhatsApp',
                        labelWidth: _labelWidth,
                        child: CustomTextField(
                          controller: _whatsappController,
                          hintText: 'WhatsApp Number',
                          height: _fieldHeight,
                          contentCase: ContentCase.none,
                          prefixBox: true,
                          prefixWidget: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFDCF8C6),
                            ),
                            child: const Icon(
                              LucideIcons.messageCircle,
                              size: 13,
                              color: Color(0xFF25D366),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: _rowGap),
                      _CnContactDialogRow(
                        label: 'Other Details',
                        labelWidth: _labelWidth,
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _designationController,
                                hintText: 'Designation',
                                height: _fieldHeight,
                              ),
                            ),
                            const SizedBox(width: _fieldColumnGap),
                            Expanded(
                              child: CustomTextField(
                                controller: _departmentController,
                                hintText: 'Department',
                                height: _fieldHeight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _uploadColumnGap),
                _CnContactProfileUploadBox(
                  fileName: _profileImage?.name,
                  onUpload: _pickProfileImage,
                ),
              ],
            ),
          ),
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                ZButton.primary(label: 'Save', onPressed: widget.onClose),
                const SizedBox(width: 12),
                ZButton.secondary(label: 'Cancel', onPressed: widget.onClose),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CnContactDialogRow extends StatelessWidget {
  final String label;
  final double labelWidth;
  final Widget child;

  const _CnContactDialogRow({
    required this.label,
    required this.labelWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _CnContactDialogPhoneField extends StatelessWidget {
  final String prefix;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String?> onPrefixChanged;

  const _CnContactDialogPhoneField({
    required this.prefix,
    required this.controller,
    required this.hintText,
    required this.onPrefixChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: FormDropdown<String>(
            value: prefix,
            items: phonePrefixOptions,
            hint: '+91',
            height: _AddContactPersonDialogState._fieldHeight,
            showSearch: false,
            menuWidth: 260,
            displayStringForValue: (value) => value,
            searchStringForValue: (value) => phonePrefixLabels[value] ?? value,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            onChanged: onPrefixChanged,
          ),
        ),
        Expanded(
          child: CustomTextField(
            controller: controller,
            hintText: hintText,
            height: _AddContactPersonDialogState._fieldHeight,
            keyboardType: TextInputType.phone,
            contentCase: ContentCase.none,
            showLeftBorder: false,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

class _CnContactProfileUploadBox extends StatelessWidget {
  final String? fileName;
  final VoidCallback onUpload;

  const _CnContactProfileUploadBox({
    required this.fileName,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _CnDashedBorderPainter(
        color: AppTheme.borderMid,
        radius: 4,
      ),
      child: Container(
        width: 340,
        height: 300,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        color: AppTheme.backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue,
              ),
              child: const Icon(
                LucideIcons.upload,
                size: 20,
                color: AppTheme.backgroundColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Drag & Drop Profile Image',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supported Files: jpg, jpeg, png, gif, bmp',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            const Text(
              'Maximum File Size: 5MB',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            InkWell(
              onTap: onUpload,
              child: Text(
                fileName ?? 'Upload File',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CnDashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _CnDashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + 4),
          Offset.zero,
        );
        distance += 8;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CnDashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _QuickAddCustomerDialog extends StatefulWidget {
  final Function(String) onSave;

  const _QuickAddCustomerDialog({required this.onSave});

  @override
  State<_QuickAddCustomerDialog> createState() =>
      _QuickAddCustomerDialogState();
}

class _QuickAddCustomerDialogState extends State<_QuickAddCustomerDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
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
                    'New Customer',
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
                      border: Border.all(color: AppTheme.borderLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Form fields
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Customer Name*',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomTextField(
                        controller: _nameController,
                        height: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Customer Email',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomTextField(
                        controller: _emailController,
                        height: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Customer Phone',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomTextField(
                        controller: _phoneController,
                        height: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Row(
              children: [
                ZButton.primary(
                  label: 'Save',
                  onPressed: () {
                    if (_nameController.text.trim().isNotEmpty) {
                      widget.onSave(_nameController.text.trim());
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to full add customer page or show advanced form
                  },
                  child: const Text(
                    'Add More Details',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
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
    );
  }
}

class _CnAddBatchesPopover extends StatefulWidget {
  final _CnLineItem item;
  final VoidCallback onClose;
  final Function(List<_CnBatch>) onSave;

  const _CnAddBatchesPopover({
    required this.item,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_CnAddBatchesPopover> createState() => _CnAddBatchesPopoverState();
}

class _CnAddBatchesPopoverState extends State<_CnAddBatchesPopover> {
  late final List<_CnBatch> _batches;
  bool _overwriteLineItem = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.savedBatches.isNotEmpty) {
      _batches = List.from(widget.item.savedBatches);
    } else {
      _batches = [_CnBatch()..quantityController.text = '1'];
    }
  }

  @override
  void dispose() {
    // Only dispose batches not held in savedBatches (to avoid double-dispose)
    for (var b in _batches) {
      if (!widget.item.savedBatches.contains(b)) {
        b.referenceController.dispose();
        b.mfrBatchController.dispose();
        b.mfrDateController.dispose();
        b.expiryDateController.dispose();
        b.quantityController.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Add Batches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primaryBlue),
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
              const Divider(height: 1),
              // Info Area
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Location : ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          widget.item.warehouseLocation ??
                              'ZABNIX PRIVATE LIMITED',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.name.isEmpty
                                ? 'BATCH TRACK ITEM'
                                : widget.item.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'Total Quantity : ${widget.item.returnQtyController.text}.00 pcs',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Text(
                          'Quantity to be added : 0 pcs',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Checkbox(
                          value: _overwriteLineItem,
                          onChanged: (val) =>
                              setState(() => _overwriteLineItem = val!),
                          visualDensity: VisualDensity.compact,
                        ),
                        const Text(
                          'Overwrite the line item with 1 quantities',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.helpCircle,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Table Header
              Container(
                color: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'BATCH REFERENCE#*',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'MANUFACTURER BATCH#',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'MANUFACTURED DATE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'EXPIRY DATE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'QUANTITY IN*',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorRed,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 24),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Table Body
              Expanded(
                child: SingleChildScrollView(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _batches.length,
                    itemBuilder: (context, index) {
                      final b = _batches[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: b.isExisting
                                  ? _CnBatchSearchDropdown(
                                      selectedBatch: b.referenceController.text,
                                      onChanged: (batch) {
                                        setState(() {
                                          b.referenceController.text =
                                              batch['name']!;
                                          b.mfrBatchController.text =
                                              batch['mfrBatch'] ?? '';
                                          b.mfrDateController.text =
                                              batch['mfrDate'] ?? '';
                                          b.expiryDateController.text =
                                              batch['expiryDate'] ?? '';
                                          b.balance = batch['balance'];
                                        });
                                      },
                                    )
                                  : _CnAddBatchField(
                                      controller: b.referenceController,
                                      hint: 'Enter Batch#',
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: _CnAddBatchField(
                                controller: b.mfrBatchController,
                                hint: 'Enter MFR Batch#',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: _CnAddBatchField(
                                controller: b.mfrDateController,
                                hint: 'dd-MM-yyyy',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: _CnAddBatchField(
                                controller: b.expiryDateController,
                                hint: 'dd-MM-yyyy',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: _CnAddBatchField(
                                controller: b.quantityController,
                                hint: '1',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _batches.removeAt(index);
                                  if (_batches.isEmpty) {
                                    _batches.add(
                                      _CnBatch()..quantityController.text = '1',
                                    );
                                  }
                                  // Sync removal back to savedBatches so summary updates live
                                  widget.item.savedBatches
                                    ..clear()
                                    ..addAll(_batches);
                                });
                              },
                              child: const Icon(
                                LucideIcons.xCircle,
                                size: 18,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Add Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          final onlyRow =
                              _batches.length == 1 &&
                              _batches[0].referenceController.text.isEmpty;
                          if (onlyRow) {
                            _batches[0].isExisting = false;
                          } else {
                            _batches.add(_CnBatch());
                          }
                        });
                      },
                      child: Row(
                        children: const [
                          Icon(
                            LucideIcons.plus,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'New Batch',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () {
                        setState(() {
                          final onlyRow =
                              _batches.length == 1 &&
                              _batches[0].referenceController.text.isEmpty;
                          if (onlyRow) {
                            _batches[0].isExisting = true;
                          } else {
                            final newBatch = _CnBatch()..isExisting = true;
                            _batches.add(newBatch);
                          }
                        });
                      },
                      child: Row(
                        children: const [
                          Icon(
                            LucideIcons.plus,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Existing Batch',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Save',
                      onPressed: () => widget.onSave(_batches),
                    ),
                    const SizedBox(width: 12),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: widget.onClose,
                    ),
                    const Spacer(),
                    const Text(
                      'Batches added: 1/100',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
  }
}

class _CnAddBatchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextAlign textAlign;

  const _CnAddBatchField({
    required this.controller,
    required this.hint,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        textAlign: textAlign,
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class _CnBatch {
  final referenceController = TextEditingController();
  final mfrBatchController = TextEditingController();
  final mfrDateController = TextEditingController();
  final expiryDateController = TextEditingController();
  final quantityController = TextEditingController();
  bool isExisting = false;
  String? selectedBatchId;
  String? balance;
}

class _CnBatchSearchDropdown extends StatelessWidget {
  final String selectedBatch;
  final Function(Map<String, String>) onChanged;

  const _CnBatchSearchDropdown({
    required this.selectedBatch,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mockBatches = [
      {
        'name': 'awsxdgbj',
        'balance': '85 pcs',
        'mfrBatch': 'MFR-001',
        'mfrDate': '2026-01-01',
        'expiryDate': '2027-01-01',
      },
      {
        'name': '456',
        'balance': '1 pcs',
        'mfrBatch': 'MFR-002',
        'mfrDate': '2026-02-15',
        'expiryDate': '2027-02-15',
      },
      {
        'name': 'sdadw',
        'balance': '20 pcs',
        'mfrBatch': 'MFR-003',
        'mfrDate': '2026-03-20',
        'expiryDate': '2027-03-20',
      },
    ];

    return FormDropdown<Map<String, String>>(
      value: selectedBatch.isEmpty
          ? null
          : mockBatches.firstWhere(
              (b) => b['name'] == selectedBatch,
              orElse: () => mockBatches[0],
            ),
      items: mockBatches,
      hint: 'Select Batch',
      height: 32,
      menuWidth: 320,
      itemHeight: 72,
      maxVisibleItems: 2,
      forceDownward: true,
      displayStringForValue: (b) => b['name'] ?? '',
      itemBuilder: (batch, isSelected, isHovered) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: (isSelected || isHovered)
              ? AppTheme.primaryBlue
              : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                batch['name']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: (isSelected || isHovered)
                      ? Colors.white
                      : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Balance in batch: ${batch['balance']}',
                style: TextStyle(
                  fontSize: 11,
                  color: (isSelected || isHovered)
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }
}
