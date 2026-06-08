// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart'
    as acct_model;
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/providers/vendor_credits_tax_provider.dart';
import 'package:zerpai_erp/shared/models/account_node.dart' as shared_acct;
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/sales_item_quick_edit_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/advanced_customer_search_modal.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/customers/providers/customers_provider.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/pricelists/pricelist/providers/pricelist_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/inventory_bin_batch_foc.dart';

class VendorCreditsCreatePage extends ConsumerStatefulWidget {
  final String? vendorCreditId;
  const VendorCreditsCreatePage({super.key, this.vendorCreditId});

  @override
  ConsumerState<VendorCreditsCreatePage> createState() =>
      _VendorCreditsCreatePageState();
}

class _VendorCreditsCreatePageState extends ConsumerState<VendorCreditsCreatePage> {
  static const double _tableFieldHeight = 44;
  static const double _labelWidth = 150.0;
  static const double _rowMaxWidth = 1400.0;
  static const double _gapWidth = 16.0;
  static const double _vendorFieldWidth = 500.0;
  static const double _fieldWidth = _rowMaxWidth - _labelWidth - _gapWidth;
  static const double _fieldHeight = 32.0;

  // --- Form State ---
  SalesCustomer? _selectedVendorObj;
  String? get _selectedVendor => _selectedVendorObj?.displayName;
  String? _selectedSourceOfSupply;
  String? _selectedDestinationOfSupply;
  String? _selectedBill;
  String? _selectedBillType;
  String? _selectedTransactionSeries = 'Default Transaction Series';
  bool _isReverseCharge = false;
  List<PlatformFile> _attachedFiles = [];
  bool _showItemDetailsPanel = false;
  _VCLineItem? _detailsItem;
  int _detailsInitialTab = 0;
  bool _showVendorDetailsPanel = false;

  late final TextEditingController _vcNumberController;
  late final TextEditingController _vcDateController;
  final _vcDateKey = GlobalKey();
  DateTime _vcDate = DateTime.now();
  late final TextEditingController _orderNumberController;
  late final TextEditingController _subjectController;
  late final TextEditingController _notesController;
  late final TextEditingController _shippingController;
  late final TextEditingController _adjustmentController;
  // _termsController removed â€” Terms & Conditions replaced by Notes + Attach Files
  late final TextEditingController _vcPrefixController;
  late final TextEditingController _vcNextNumberController;

  bool _vcAutoGenerate = true;
  Warehouse? _selectedWarehouse;
  String _discountType = 'At Transaction Level';
  PriceList? _selectedPriceList;
  late final TextEditingController _txnDiscountController;
  bool _txnDiscountIsPercent = true;

  String _taxType = 'TDS';
  String? _selectedTaxRate;

  final List<_VCLineItem> _items = [];

  // --- Total Tax Amount popover ---
  final LayerLink _totalTaxLayerLink = LayerLink();
  OverlayEntry? _totalTaxOverlay;
  Map<String, double> _taxOverrides = {};

  // --- Manage TDS/TCS popover ---
  OverlayEntry? _manageTaxOverlay;

  @override
  void initState() {
    super.initState();
    _vcNumberController = TextEditingController(text: 'VC-00001');
    _vcDateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(_vcDate),
    );
    _orderNumberController = TextEditingController();
    _subjectController = TextEditingController();
    _notesController = TextEditingController();
    _shippingController = TextEditingController();
    _adjustmentController = TextEditingController();
    _vcPrefixController = TextEditingController(text: 'VC-');
    _vcNextNumberController = TextEditingController(text: '00001');
    _txnDiscountController = TextEditingController();
    _addItem();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsControllerProvider.notifier).loadLookupData();
    });
  }

  @override
  void dispose() {
    _vcNumberController.dispose();
    _vcDateController.dispose();
    _orderNumberController.dispose();
    _subjectController.dispose();
    _notesController.dispose();
    _shippingController.dispose();
    _adjustmentController.dispose();
    _vcPrefixController.dispose();
    _vcNextNumberController.dispose();
    _txnDiscountController.dispose();
    _totalTaxOverlay?.remove();
    _manageTaxOverlay?.remove();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  static List<_VCTaxOption> _buildTaxOptions(List<TaxGroupItem> groups) {
    return [
      const _VCTaxOption(
        label: 'Non-Taxable',
        description: 'Supply is exempt from GST. Exemption reason required.',
      ),
      const _VCTaxOption(
        label: 'Out of Scope',
        description:
            "Supplies on which you don't charge any GST or include them in the returns.",
      ),
      const _VCTaxOption(
        label: 'Non-GST Supply',
        description:
            'Supplies which do not come under GST such as petroleum products and liquor.',
      ),
      const _VCTaxOption(label: 'Taxable', isHeader: true),
      if (groups.isEmpty) ...[
        const _VCTaxOption(label: 'GST 0%', description: '[0%]', rate: 0),
        const _VCTaxOption(label: 'GST 5%', description: '[5%]', rate: 5),
        const _VCTaxOption(label: 'GST 12%', description: '[12%]', rate: 12),
        const _VCTaxOption(label: 'GST 18%', description: '[18%]', rate: 18),
        const _VCTaxOption(label: 'GST 28%', description: '[28%]', rate: 28),
      ] else
        ...groups.map(
          (g) => _VCTaxOption(
            label: g.name,
            description: '[${TaxGroupItem.fmtRate(g.rate)}%]',
            rate: g.rate,
          ),
        ),
    ];
  }

  static List<shared_acct.AccountNode> _buildAccountTree(
    List<acct_model.AccountNode> nodes,
  ) {
    // Flatten entire tree first, preserving accountGroup and accountType
    final flat = <acct_model.AccountNode>[];
    void collect(List<acct_model.AccountNode> list) {
      for (final n in list) {
        if (n.isActive && !n.isDeleted) flat.add(n);
        collect(n.children);
      }
    }
    collect(nodes);
    if (flat.isEmpty) return const [];

    // Group: accountGroup â†’ accountType â†’ accounts
    final byGroup = <String, Map<String, List<acct_model.AccountNode>>>{};
    for (final n in flat) {
      final group = n.accountGroup.isEmpty ? 'Other' : n.accountGroup;
      final type = n.accountType.isEmpty ? group : n.accountType;
      byGroup.putIfAbsent(group, () => {})[type] ??= [];
      byGroup[group]![type]!.add(n);
    }

    final result = <shared_acct.AccountNode>[];
    for (final groupEntry in byGroup.entries) {
      final typeMap = groupEntry.value;
      final typeNodes = <shared_acct.AccountNode>[];

      for (final typeEntry in typeMap.entries) {
        final accounts = typeEntry.value
            .map(
              (a) => shared_acct.AccountNode(
                id: a.name,
                name: a.name,
                selectable: true,
              ),
            )
            .toList();

        // If all accounts share the same type name as the group, skip type header
        if (typeEntry.key == groupEntry.key && typeMap.length == 1) {
          typeNodes.addAll(accounts);
        } else {
          typeNodes.add(
            shared_acct.AccountNode(
              id: '__type__${groupEntry.key}__${typeEntry.key}',
              name: typeEntry.key,
              selectable: false,
              children: accounts,
            ),
          );
        }
      }

      result.add(
        shared_acct.AccountNode(
          id: '__group__${groupEntry.key}',
          name: groupEntry.key,
          selectable: false,
          children: typeNodes,
        ),
      );
    }
    return result;
  }

  void _addItem() {
    setState(() => _items.add(_VCLineItem()));
  }

  void _openItemDetails(_VCLineItem item, {int initialTab = 0}) {
    setState(() {
      _showItemDetailsPanel = true;
      _detailsItem = item;
      _detailsInitialTab = initialTab;
      _showVendorDetailsPanel = false;
    });
  }

  void _openVendorDetails() {
    if (_selectedVendorObj == null) return;
    setState(() {
      _showVendorDetailsPanel = true;
      _showItemDetailsPanel = false;
      _detailsItem = null;
    });
  }

  void _openEditItem(_VCLineItem lineItem) {
    final fullItem = lineItem.sourceItem ??
        Item(
          type: 'goods',
          productName: '',
          itemCode: '',
          unitId: '',
          hsnCode: lineItem.hsnCodeOverride,
          taxPreference: 'taxable',
          costPrice: double.tryParse(lineItem.rateController.text),
        );

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => SalesItemQuickEditDialog(
        item: fullItem,
        onUpdated: (updated) {
          setState(() {
            lineItem.sourceItem = updated;
            lineItem.hsnCodeOverride = null;
            if (updated.costPrice != null) {
              lineItem.rateController.text =
                  updated.costPrice!.toStringAsFixed(2);
            }
          });
        },
      ),
    );
  }

  void _insertItem(int index) {
    setState(() => _items.insert(index + 1, _VCLineItem()));
  }

  void _duplicateItem(int index) {
    setState(() {
      final original = _items[index];
      final dup = _VCLineItem();
      dup.sourceItem = original.sourceItem;
      dup.selectedTax = original.selectedTax;
      dup.selectedTaxRate = original.selectedTaxRate;
      dup.selectedAccount = original.selectedAccount;
      dup.selectedPriceList = original.selectedPriceList;
      dup.itcStatus = original.itcStatus;
      dup.discountIsPercent = original.discountIsPercent;
      dup.discountController.text = original.discountController.text;
      dup.selectedTagValues = Map.from(original.selectedTagValues);
      dup.qtyController.text = original.qtyController.text;
      dup.rateController.text = original.rateController.text;
      dup.descriptionController.text = original.descriptionController.text;
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
              final line = _VCLineItem();
              line.sourceItem = entry.key;
              line.rateController.text =
                  entry.key.costPrice?.toStringAsFixed(2) ?? '0.00';
              line.qtyController.text = entry.value.toString();
              _items.add(line);
            }
            if (_items.isEmpty) _addItem();
          });
        },
      ),
    );
  }

  Future<void> _openBatchDialog(_VCLineItem lineItem) async {
    final result = await showDialog<PicklistBatchDialogResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => PicklistSelectBatchesDialog(
        itemName: lineItem.sourceItem?.productName ?? '',
        productId: lineItem.sourceItem?.id ?? '',
        warehouseName: _selectedWarehouse?.name ?? '',
        warehouseId: _selectedWarehouse?.id ?? '',
        totalQuantity: double.tryParse(lineItem.qtyController.text.trim()) ?? 1,
        savedBatchData: lineItem.savedBatches
            .map(
              (b) => {
                'batchRef': b.referenceController.text,
                'mfgBatch': b.mfrBatchController.text,
                'mfgDate': b.mfrDateController.text,
                'expDate': b.expiryDateController.text,
                'qtyOut': b.quantityController.text,
              },
            )
            .toList(growable: false),
      ),
    );

    if (!mounted || result?.batchDataList == null) return;

    setState(() {
      lineItem.savedBatches = result!.batchDataList!
          .map((row) {
            final b = _VCBatch();
            b.referenceController.text = row['batchRef'] ?? '';
            b.mfrBatchController.text = row['mfgBatch'] ?? '';
            b.mfrDateController.text = row['mfgDate'] ?? '';
            b.expiryDateController.text = row['expDate'] ?? '';
            b.quantityController.text = row['qtyOut'] ?? '';
            return b;
          })
          .toList(growable: false);
    });
  }

  void _showVCPreferencesDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Vendor Credit Preferences',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => Align(
        alignment: Alignment.topCenter,
        child: Material(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          color: Colors.white,
          child: _VCPreferencesDialog(
            prefix: _vcPrefixController.text,
            nextNumber: _vcNextNumberController.text,
            autoGenerate: _vcAutoGenerate,
            onSave: (prefix, nextNumber, autoGenerate) {
              setState(() {
                _vcAutoGenerate = autoGenerate;
                _vcPrefixController.text = prefix;
                _vcNextNumberController.text = nextNumber;
              });
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickVCDate() async {
    final date = await ZerpaiDatePicker.show(
      context,
      initialDate: _vcDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      targetKey: _vcDateKey,
    );
    if (date == null) return;
    setState(() {
      _vcDate = date;
      _vcDateController.text = DateFormat('dd-MM-yyyy').format(date);
    });
  }

  double _parseMoney(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0;

  String _formatMoney(double value) => value.toStringAsFixed(2);

  double _lineSubtotal(_VCLineItem item) {
    if (item.sourceItem == null) return 0;
    final qty = _parseMoney(item.qtyController.text);
    final rate = _parseMoney(item.rateController.text);
    final gross = qty * rate;
    if (_discountType == 'At Line Item Level') {
      final d = _parseMoney(item.discountController.text);
      final discountAmt =
          item.discountIsPercent ? gross * d / 100 : d;
      return (gross - discountAmt).clamp(0.0, double.infinity);
    }
    return gross.clamp(0.0, double.infinity);
  }

  double get _txnDiscountAmount {
    if (_discountType != 'At Transaction Level') return 0;
    final d = _parseMoney(_txnDiscountController.text);
    if (d <= 0) return 0;
    return _txnDiscountIsPercent ? _subTotal * d / 100 : d;
  }

  double get _subTotal => _items
      .where((item) => item.sourceItem != null)
      .fold(0.0, (sum, item) => sum + _lineSubtotal(item));

  double get _shippingAmount => _parseMoney(_shippingController.text);
  double get _adjustmentAmount => _parseMoney(_adjustmentController.text);

  double _taxPercentFromLabel(String? label) {
    if (label == null) return 0;
    final normalized = label.toLowerCase();
    if (normalized.contains('non-taxable') ||
        normalized.contains('out of scope') ||
        normalized.contains('non-gst') ||
        normalized.contains('not taxable') ||
        normalized.contains('none')) {
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
    final place = _selectedDestinationOfSupply?.toLowerCase().trim();
    if (place == null || place.isEmpty) return false;
    return !place.contains('[kl]') && !place.contains('kerala');
  }

  List<_VCTaxSummaryLine> get _taxSummaryLines {
    final taxableAmountsByRate = <double, double>{};
    for (final item in _items) {
      if (item.sourceItem == null) continue;
      final taxRate = item.selectedTaxRate ?? _taxPercentFromLabel(item.selectedTax);
      if (taxRate <= 0) continue;
      taxableAmountsByRate.update(
        taxRate,
        (amount) => amount + _lineSubtotal(item),
        ifAbsent: () => _lineSubtotal(item),
      );
    }
    final entries = taxableAmountsByRate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final lines = <_VCTaxSummaryLine>[];
    for (final entry in entries) {
      final rate = entry.key;
      final taxableAmount = entry.value;
      if (_isInterStateSupply) {
        final rateText = rate == rate.roundToDouble()
            ? rate.toStringAsFixed(0)
            : rate.toStringAsFixed(1);
        lines.add(
          _VCTaxSummaryLine(
            label: 'IGST$rateText [$rateText%]',
            amount: taxableAmount * rate / 100,
          ),
        );
      } else {
        final splitRate = rate / 2;
        final splitAmount = taxableAmount * splitRate / 100;
        final rateText = splitRate == splitRate.roundToDouble()
            ? splitRate.toStringAsFixed(0)
            : splitRate.toStringAsFixed(1);
        lines
          ..add(
            _VCTaxSummaryLine(
              label: 'CGST$rateText [$rateText%]',
              amount: splitAmount,
            ),
          )
          ..add(
            _VCTaxSummaryLine(
              label: 'SGST$rateText [$rateText%]',
              amount: splitAmount,
            ),
          );
      }
    }
    return lines;
  }

  double get _taxSummaryAmount {
    if (_taxOverrides.isNotEmpty) {
      return _taxOverrides.values.fold(0.0, (sum, amt) => sum + amt);
    }
    return _taxSummaryLines.fold(0.0, (sum, line) => sum + line.amount);
  }

  double get _grandTotal =>
      _subTotal - _txnDiscountAmount + _shippingAmount + _taxSummaryAmount + _adjustmentAmount;

  @override
  Widget build(BuildContext context) {
    final customersLoading = ref.watch(customersProvider).isLoading;
    final warehousesAsync = ref.watch(warehousesProvider);
    final warehouses = warehousesAsync.asData?.value ?? const <Warehouse>[];
    final accountTree = _buildAccountTree(
      ref.watch(chartOfAccountsProvider).roots,
    );
    final taxOptions = _buildTaxOptions(
      ref.watch(taxGroupsProvider).asData?.value ?? const [],
    );
    if (customersLoading) {
      return ZerpaiLayout(
        pageTitle: widget.vendorCreditId != null
            ? 'Edit Vendor Credit'
            : 'New Vendor Credit',
        enableBodyScroll: true,
        onSave: () {},
        useHorizontalPadding: false,
        child: const VendorCreditAddSkeleton(),
      );
    }

    final taxSummaryLines = _taxSummaryLines;

    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: ZerpaiLayout(
            pageTitle: widget.vendorCreditId != null
                ? 'Edit Vendor Credit'
                : 'New Vendor Credit',
            enableBodyScroll: true,
            onSave: () {},
            useHorizontalPadding: true,
            footer: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: _MaxWidthContainer(
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
                      onPressed: () => context.go(AppRoutes.vendorCredits),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // --- Vendor Header Band ---
                    _HeaderBackgroundBand(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Vendor Name with INR badge
                            _CompactFormRow(
                              label: 'Vendor Name',
                              required: true,
                              labelColor: AppTheme.errorRed,
                              fieldWidth: _selectedVendor == null
                                  ? _vendorFieldWidth + 12 + 72
                                  : _fieldWidth,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: _vendorFieldWidth,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final customersAsync = ref.watch(
                                                customersProvider,
                                              );
                                              return FormDropdown<
                                                SalesCustomer
                                              >(
                                                value: _selectedVendorObj,
                                                items:
                                                    customersAsync
                                                        .asData
                                                        ?.value
                                                        .cast<SalesCustomer>() ??
                                                    const <SalesCustomer>[],
                                                isLoading:
                                                    customersAsync.isLoading,
                                                displayStringForValue: (c) =>
                                                    c.displayName,
                                                searchStringForValue: (c) =>
                                                    '${c.displayName} ${c.companyName ?? ''} ${c.customerNumber ?? ''} ${c.gstin ?? ''}',
                                                hint: 'Select or add a vendor',
                                                height: _fieldHeight,
                                                menuMaxHeight: 320,
                                                itemHeight: 72,
                                                itemBuilder: (c, isSelected, isHovered) =>
                                                    _VcVendorDropdownItem(
                                                      name: c.displayName,
                                                      code: c.customerNumber ?? '',
                                                      subtitle: c.companyName ?? c.gstin ?? '',
                                                      highlighted: isSelected || isHovered,
                                                    ),
                                                showRightBorder: false,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topLeft: Radius.circular(
                                                        4,
                                                      ),
                                                      bottomLeft:
                                                          Radius.circular(4),
                                                    ),
                                                allowClear: true,
                                                onChanged: (val) => setState(() {
                                                  _selectedVendorObj = val;
                                                  if (val == null) {
                                                    _selectedSourceOfSupply =
                                                        null;
                                                    _selectedDestinationOfSupply =
                                                        null;
                                                    _selectedBill = null;
                                                  } else {
                                                    _selectedSourceOfSupply =
                                                        val.placeOfSupply;
                                                  }
                                                }),
                                              );
                                            },
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
                                              final List<SalesCustomer> customers = ref
                                                      .read(customersProvider)
                                                      .asData
                                                      ?.value
                                                      .cast<SalesCustomer>() ??
                                                  const <SalesCustomer>[];
                                              final result =
                                                  await AdvancedCustomerSearchModal
                                                      .show(context, customers: customers);
                                              if (result != null &&
                                                  mounted &&
                                                  customers.isNotEmpty) {
                                                setState(() {
                                                  _selectedVendorObj = customers.firstWhere(
                                                    (c) => c.displayName == result,
                                                    orElse: () => customers.first,
                                                  );
                                                  _selectedSourceOfSupply =
                                                      _selectedVendorObj?.placeOfSupply;
                                                  _selectedDestinationOfSupply = null;
                                                  _selectedBill = null;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedVendor != null) ...[
                                    const SizedBox(width: 12),
                                    const _VCCurrencyBadge(),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Transform.translate(
                                          offset: Offset(
                                            MediaQuery.of(context).size.width < 1000 ? 16.0 : 40.0,
                                            0,
                                          ),
                                          child: _VCVendorDetailsTag(
                                            vendorName: _selectedVendor!,
                                            onTap: _openVendorDetails,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_selectedVendorObj != null) ...[
                              // Billing address + GST Treatment panel
                              _VCVendorAddressPanel(
                                customer: _selectedVendorObj!,
                                labelWidth: _labelWidth,
                              ),
                              // Source of Supply
                              _CompactFormRow(
                                label: 'Source of Supply',
                                required: true,
                                labelColor: AppTheme.errorRed,
                                fieldWidth: 330,
                                child: Builder(
                                  builder: (context) {
                                    final stateNames = ref.watch(statesProvider('IN')).value?.map((s) => s['name'] ?? '').where((n) => n.isNotEmpty).toList() ?? [];
                                    return FormDropdown<String>(
                                      value: _selectedSourceOfSupply,
                                      items: stateNames,
                                      hint: 'Select Source of Supply',
                                      height: _fieldHeight,
                                      onChanged: (val) => setState(() => _selectedSourceOfSupply = val),
                                    );
                                  },
                                ),
                              ),
                              // Destination of Supply
                              _CompactFormRow(
                                label: 'Destination of Supply',
                                required: true,
                                labelColor: AppTheme.errorRed,
                                fieldWidth: 330,
                                child: Builder(
                                  builder: (context) {
                                    final stateNames = ref.watch(statesProvider('IN')).value?.map((s) => s['name'] ?? '').where((n) => n.isNotEmpty).toList() ?? [];
                                    return FormDropdown<String>(
                                      value: _selectedDestinationOfSupply,
                                      items: stateNames,
                                      hint: 'Select Destination of Supply',
                                      height: _fieldHeight,
                                      onChanged: (val) => setState(() => _selectedDestinationOfSupply = val),
                                    );
                                  },
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
                                      items: const [
                                        '33333',
                                        'BILL-001',
                                        'BILL-002',
                                      ],
                                      hint: 'Select Bill',
                                      height: _fieldHeight,
                                      onChanged: (val) =>
                                          setState(() => _selectedBill = val),
                                    ),
                                    if (_selectedBill != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Bill Date: 12-05-2026',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Bill Type
                              _CompactFormRow(
                                label: 'Bill Type',
                                fieldWidth: 330,
                                child: FormDropdown<String>(
                                  value: _selectedBillType,
                                  items: const [
                                    'B2B',
                                    'B2C Large',
                                    'B2C Others',
                                    'Export',
                                  ],
                                  hint: 'Select Bill Type',
                                  height: _fieldHeight,
                                  onChanged: (val) =>
                                      setState(() => _selectedBillType = val),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Credit Note# ---
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
                                'Vendor Credit Series',
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
                              controller: _vcNumberController,
                              height: _fieldHeight,
                              suffixWidget: ZTooltip(
                                message:
                                    'Click here to enable or disable auto-generation of Vendor Credit numbers.',
                                child: GestureDetector(
                                  onTap: _showVCPreferencesDialog,
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
                    _CompactFormRow(
                      label: 'Order Number',
                      fieldWidth: 330,
                      child: CustomTextField(
                        controller: _orderNumberController,
                        height: _fieldHeight,
                      ),
                    ),
                    _CompactFormRow(
                      label: 'Vendor Credit Date',
                      fieldWidth: 330,
                      child: CustomTextField(
                        key: _vcDateKey,
                        controller: _vcDateController,
                        readOnly: true,
                        onTap: _pickVCDate,
                        height: _fieldHeight,
                        suffixWidget: const Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),

                    // Subject row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: _labelWidth,
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
                                      'You can enter up to 250 characters. If you do not require this field, you can mark it as inactive under Vendor Credits preferences.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: _gapWidth),
                          SizedBox(
                            width: 434,
                            child: CustomTextField(
                              controller: _subjectController,
                              hintText:
                                  'Let your vendor know what this Vendor Credit is for',
                              height: _fieldHeight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Reverse Charge
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
                              side: const BorderSide(
                                color: AppTheme.borderLight,
                              ),
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

                    // --- Item Table Toolbar ---
                    _VCItemTableToolbar(
                      selectedWarehouse: _selectedWarehouse,
                      warehouses: warehouses,
                      onWarehouseChanged: (w) =>
                          setState(() => _selectedWarehouse = w),
                      discountType: _discountType,
                      onDiscountTypeChanged: (val) =>
                          setState(() => _discountType = val),
                      selectedPriceList: _selectedPriceList,
                      priceListOptions: ref.watch(activePriceListsProvider),
                      onPriceListChanged: (val) =>
                          setState(() => _selectedPriceList = val),
                    ),
                    const SizedBox(height: 16),

                    // --- Items Grid ---
                    _VCItemsGrid(
                      items: _items,
                      availableProducts: ref
                          .watch(itemsControllerProvider)
                          .items,
                      onSearchProducts: (q) => ref
                          .read(itemsControllerProvider.notifier)
                          .searchItems(q),
                      onAddItem: _addItem,
                      onAddBulkItems: _showBulkItemsDialog,
                      onInsertItem: _insertItem,
                      onDuplicateItem: _duplicateItem,
                      onRemoveItem: _removeItem,
                      onTotalsChanged: () => setState(() {}),
                      onAddBatches: _openBatchDialog,
                      warehouse: _selectedWarehouse?.name ?? '',
                      accountTree: accountTree,
                      taxOptions: taxOptions,
                      isReverseCharge: _isReverseCharge,
                      onViewItemDetails: _openItemDetails,
                      onViewItemDetailsTransactions: (item) => _openItemDetails(item, initialTab: 2),
                      onEditItem: _openEditItem,
                      defaultPriceList: _selectedPriceList,
                      discountType: _discountType,
                    ),

                    const SizedBox(height: 32),

                    // --- Summary Row (Totals only) ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Spacer(),
                        // Totals Panel
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
                                // Transaction-level Discount
                                if (_discountType == 'At Transaction Level') ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 120,
                                          child: Text(
                                            'Discount',
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
                                            controller: _txnDiscountController,
                                            hintText: '0',
                                            height: 34,
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => setState(() =>
                                              _txnDiscountIsPercent =
                                                  !_txnDiscountIsPercent),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.bgDisabled,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: AppTheme.borderLight),
                                            ),
                                            child: Text(
                                              _txnDiscountIsPercent ? '%' : 'â‚¹',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            _formatMoney(_txnDiscountAmount),
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
                                ],
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
                                // Total Tax Amount â€” always visible once any item is selected
                                if (_items.any((i) => i.sourceItem != null)) ...[
                                  if (taxSummaryLines.isEmpty)
                                    const Divider(height: 1, color: AppTheme.borderLight),
                                  CompositedTransformTarget(
                                    link: _totalTaxLayerLink,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Total Tax Amount',
                                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 150,
                                            height: 34,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppTheme.borderLight),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                                      child: Text(
                                                        _formatMoney(_taxSummaryAmount),
                                                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                                        textAlign: TextAlign.right,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    decoration: const BoxDecoration(
                                                      border: Border(left: BorderSide(color: AppTheme.borderLight)),
                                                    ),
                                                    child: const Text('INR', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => _showTotalTaxPopover(context, taxSummaryLines),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppTheme.primaryBlue),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(LucideIcons.pencil, size: 13, color: AppTheme.primaryBlue),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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

                    // --- Notes + Attach Files ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: AppTheme.bgLight),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Notes
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
                                      'Will be displayed on the vendor credit',
                                  maxLines: 4,
                                  height: 100,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40),
                          // Attach Files
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attach File(s) to Vendor Credits',
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
                                      variant: FileUploadButtonVariant.button,
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
                                  'You can upload a maximum of 5 files, 10MB each',
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

                    const SizedBox(height: 28),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    const SizedBox(height: 24),

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
                                'Start adding custom fields for your vendor credits by going to ',
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
                            text: 'Vendor Credits',
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
        // Item details side panel
        if (_showItemDetailsPanel && _detailsItem != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 380,
            child: _VCItemDetailsSidePanel(
              item: _detailsItem!,
              initialTab: _detailsInitialTab,
              onClose: () => setState(() {
                _showItemDetailsPanel = false;
                _detailsItem = null;
                _detailsInitialTab = 0;
              }),
            ),
          ),
        // Vendor details side panel
        if (_showVendorDetailsPanel && _selectedVendorObj != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 440,
            child: _VCVendorDetailsSidePanel(
              vendor: _selectedVendorObj!,
              onClose: () => setState(() => _showVendorDetailsPanel = false),
            ),
          ),
      ],
    );
  }

  Widget _buildGstSummaryRows(List<_VCTaxSummaryLine> lines) {
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

  void _showManageTaxPopover(BuildContext context) {
    _manageTaxOverlay?.remove();
    _manageTaxOverlay = null;

    final isTds = _taxType == 'TDS';
    final title = isTds ? 'Manage TDS' : 'Manage TCS';
    final taxesLabel = isTds ? 'TDS taxes' : 'TCS taxes';
    final newBtnLabel = isTds ? '+ New TDS Tax' : '+ New TCS Tax';
    final emptyLabel = isTds ? 'No TDS Taxes to show' : 'No TCS Taxes to show';

    void close() {
      _manageTaxOverlay?.remove();
      _manageTaxOverlay = null;
    }

    _manageTaxOverlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: close,
        child: Stack(
          children: [
            Container(color: Colors.black.withValues(alpha: 0.35)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    color: Colors.white,
                    elevation: 12,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    child: Container(
                      width: 700,
                      constraints: const BoxConstraints(maxHeight: 560),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: close,
                                  child: const Icon(LucideIcons.x, size: 18, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          // Sub-header row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    taxesLabel,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    close();
                                    showDialog<void>(
                                      context: context,
                                      barrierColor: Colors.black.withValues(alpha: 0.35),
                                      builder: (_) => Align(
                                        alignment: Alignment.topCenter,
                                        child: _VCNewTaxFormDialog(isTds: isTds),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successDark,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      newBtnLabel,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Table header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                            decoration: const BoxDecoration(
                              color: AppTheme.tableHeaderBg,
                              border: Border(
                                top: BorderSide(color: AppTheme.borderLight),
                                bottom: BorderSide(color: AppTheme.borderLight),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('TAX NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.4))),
                                Expanded(flex: 2, child: Text('RATE (%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.4))),
                                Expanded(flex: 3, child: Text('NATURE OF COLLECTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.4))),
                                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.4))),
                              ],
                            ),
                          ),
                          // Empty state
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                emptyLabel,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
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

    Overlay.of(context).insert(_manageTaxOverlay!);
  }

  void _showTotalTaxPopover(BuildContext context, List<_VCTaxSummaryLine> lines) {
    _totalTaxOverlay?.remove();
    _totalTaxOverlay = null;

    // When no tax lines exist yet, show a generic editable row so the user
    // can still manually enter a tax amount override.
    final effectiveLines = lines.isNotEmpty
        ? lines
        : [_VCTaxSummaryLine(label: 'Tax Amount', amount: _taxSummaryAmount)];

    final controllers = {
      for (final l in effectiveLines)
        l.label: TextEditingController(text: l.amount.toStringAsFixed(2)),
    };

    _totalTaxOverlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _totalTaxOverlay?.remove();
          _totalTaxOverlay = null;
          for (final c in controllers.values) c.dispose();
        },
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _totalTaxLayerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  color: Colors.white,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Update Taxes Amount ( in INR )',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _totalTaxOverlay?.remove();
                                    _totalTaxOverlay = null;
                                    for (final c in controllers.values) c.dispose();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.primaryBlue),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(LucideIcons.x, size: 13, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Tax lines
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                            child: Column(
                              children: [
                                for (final line in effectiveLines)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(line.label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 100,
                                          height: 34,
                                          child: TextField(
                                            controller: controllers[line.label],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.borderLight)),
                                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.borderLight)),
                                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Update button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                            child: ZButton.primary(
                              label: 'Update',
                              onPressed: () {
                                final newOverrides = <String, double>{};
                                for (final line in effectiveLines) {
                                  final c = controllers[line.label];
                                  if (c != null) {
                                    newOverrides[line.label] = double.tryParse(c.text.trim()) ?? line.amount;
                                  }
                                }
                                _totalTaxOverlay?.remove();
                                _totalTaxOverlay = null;
                                for (final c in controllers.values) c.dispose();
                                setState(() => _taxOverrides = newOverrides);
                              },
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
      ),
    );

    Overlay.of(context).insert(_totalTaxOverlay!);
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
              showSettings: true,
              settingsLabel: _taxType == 'TDS' ? 'Manage TDS' : 'Manage TCS',
              settingsIcon: LucideIcons.settings,
              onSettingsTap: () => _showManageTaxPopover(context),
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

// ---------------------------------------------------------------------------
// Currency badge
// ---------------------------------------------------------------------------

class _VCCurrencyBadge extends StatelessWidget {
  const _VCCurrencyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _VendorCreditsCreatePageState._fieldHeight,
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

// ---------------------------------------------------------------------------
// Vendor billing address panel
// ---------------------------------------------------------------------------

class _VCVendorAddressPanel extends StatefulWidget {
  final SalesCustomer customer;
  final double labelWidth;

  const _VCVendorAddressPanel({
    required this.customer,
    required this.labelWidth,
  });

  @override
  State<_VCVendorAddressPanel> createState() => _VCVendorAddressPanelState();
}

class _VCVendorAddressPanelState extends State<_VCVendorAddressPanel> {
  final LayerLink _billingLink = LayerLink();
  OverlayEntry? _billingOverlay;

  final LayerLink _gstinLink = LayerLink();
  OverlayEntry? _gstinOverlay;

  final LayerLink _gstTreatmentLink = LayerLink();
  OverlayEntry? _gstTreatmentOverlay;

  // Overrides: null means use customer data
  String? _overrideName;
  List<String>? _overrideLines;
  String? _overrideGstTreatment;
  String? _overrideGstin;

  List<String> get _billingLines {
    if (_overrideLines != null) return _overrideLines!;
    final c = widget.customer;
    final lines = <String>[];
    if ((c.billingAddressStreet1 ?? '').isNotEmpty) lines.add(c.billingAddressStreet1!);
    if ((c.billingAddressStreet2 ?? '').isNotEmpty) lines.add(c.billingAddressStreet2!);
    if ((c.billingAddressCity ?? '').isNotEmpty) lines.add(c.billingAddressCity!);
    if ((c.billingAddressStateId ?? '').isNotEmpty) {
      final zip = (c.billingAddressZip ?? '').isNotEmpty ? ' ${c.billingAddressZip}' : '';
      lines.add('${c.billingAddressStateId}$zip');
    }
    if ((c.billingAddressPhone ?? '').isNotEmpty) lines.add('Phone: ${c.billingAddressPhone}');
    return lines;
  }

  String get _displayName => _overrideName ?? widget.customer.displayName.toUpperCase();

  String get _gstTreatmentLabel {
    if (_overrideGstTreatment != null) return _overrideGstTreatment!;
    switch (widget.customer.gstTreatment?.toLowerCase()) {
      case 'registered_business': return 'Registered Business - Regular';
      case 'unregistered_business': return 'Unregistered Business';
      case 'overseas': return 'Overseas';
      case 'consumer': return 'Consumer';
      default: return widget.customer.gstTreatment ?? 'Unregistered Business';
    }
  }

  String get _gstinValue => _overrideGstin ?? widget.customer.gstin ?? '';

  // â”€â”€ Billing address picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _closeBillingPicker() {
    _billingOverlay?.remove();
    _billingOverlay = null;
    if (mounted) setState(() {});
  }

  void _openBillingPicker(BuildContext context) {
    if (_billingOverlay != null) { _closeBillingPicker(); return; }
    final addr = {'name': _displayName, 'lines': _billingLines};
    _billingOverlay = OverlayEntry(builder: (ctx) {
      return Stack(children: [
        GestureDetector(onTap: _closeBillingPicker, behavior: HitTestBehavior.translucent, child: const SizedBox.expand()),
        CompositedTransformFollower(
          link: _billingLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 20),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: AppTheme.backgroundColor,
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _VCAddressPickerRow(
                      address: addr,
                      isSelected: true,
                      onSelected: _closeBillingPicker,
                      onEdit: () {
                        _closeBillingPicker();
                        _openAddressEditDialog(context, addr);
                      },
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    _VCNewAddressAction(
                      onTap: () {
                        _closeBillingPicker();
                        _openAddressEditDialog(context, const <String, dynamic>{'name': '', 'lines': <String>[]}, isNew: true);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]);
    });
    Overlay.of(context).insert(_billingOverlay!);
    setState(() {});
  }

  void _openAddressEditDialog(BuildContext context, Map<String, dynamic> addr, {bool isNew = false}) {
    showDialog<Map<String, dynamic>?>(
      context: context,
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.4),
      useSafeArea: false,
      builder: (_) => _VCAddressEditDialog(
        address: addr,
        title: isNew ? 'New Billing Address' : 'Billing Address',
        isNewAddress: isNew,
      ),
    ).then((result) {
      if (result != null && mounted) {
        setState(() {
          _overrideName = result['name'] as String?;
          _overrideLines = (result['lines'] as List?)?.cast<String>();
        });
      }
    });
  }

  // â”€â”€ GST Treatment popover â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _closeGstTreatmentPopover() {
    _gstTreatmentOverlay?.remove();
    _gstTreatmentOverlay = null;
    if (mounted) setState(() {});
  }

  void _openGstTreatmentPopover(BuildContext context) {
    if (_gstTreatmentOverlay != null) { _closeGstTreatmentPopover(); return; }

    String selectedTreatment = _gstTreatmentLabel;
    final gstinCtrl = TextEditingController(text: _gstinValue);
    bool makePermanent = false;

    const treatments = [
      'Registered Business - Regular',
      'Registered Business - Composition',
      'Unregistered Business',
      'Consumer',
      'Overseas',
      'Special Economic Zone',
      'Deemed Export',
      'Tax Deductor',
      'SEZ Developer',
    ];

    if (!treatments.contains(selectedTreatment)) selectedTreatment = treatments.first;

    _gstTreatmentOverlay = OverlayEntry(
      builder: (ctx) => Stack(children: [
        GestureDetector(
          onTap: () {
            gstinCtrl.dispose();
            _closeGstTreatmentPopover();
          },
          behavior: HitTestBehavior.translucent,
          child: const SizedBox.expand(),
        ),
        CompositedTransformFollower(
          link: _gstTreatmentLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 6),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: StatefulBuilder(
              builder: (context, setPopup) {
                return Container(
                  width: 320,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Configure Tax Preferences',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              gstinCtrl.dispose();
                              _closeGstTreatmentPopover();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.primaryBlue, width: 1.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(LucideIcons.x, size: 12, color: AppTheme.errorRed),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 12),
                      // GST Treatment
                      const Text('GST Treatment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      FormDropdown<String>(
                        value: selectedTreatment,
                        items: treatments,
                        height: 34,
                        onChanged: (v) { if (v != null) setPopup(() => selectedTreatment = v); },
                      ),
                      const SizedBox(height: 12),
                      // GSTIN
                      const Text.rich(
                        TextSpan(children: [
                          TextSpan(text: 'GSTIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                          TextSpan(text: '*', style: TextStyle(fontSize: 12, color: AppTheme.errorRed)),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: gstinCtrl,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Enter GSTIN',
                          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: AppTheme.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: AppTheme.borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {},
                        child: const Text('Get Taxpayer details', style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 12),
                      // Make it permanent
                      const Text('Make it permanent?', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: Checkbox(
                              value: makePermanent,
                              onChanged: (v) => setPopup(() => makePermanent = v ?? false),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              activeColor: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Use these settings for all future transactions of this vendor.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Footer buttons
                      Row(
                        children: [
                          SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () {
                                final result = {
                                  'gstTreatment': selectedTreatment,
                                  'gstin': gstinCtrl.text.trim(),
                                };
                                gstinCtrl.dispose();
                                _closeGstTreatmentPopover();
                                if (mounted) {
                                  setState(() {
                                    _overrideGstTreatment = result['gstTreatment'];
                                    _overrideGstin = (result['gstin']?.isNotEmpty == true) ? result['gstin'] : null;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: const Text('Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 30,
                            child: OutlinedButton(
                              onPressed: () {
                                gstinCtrl.dispose();
                                _closeGstTreatmentPopover();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                side: const BorderSide(color: AppTheme.borderLight),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );

    Overlay.of(context).insert(_gstTreatmentOverlay!);
    setState(() {});
  }

  // â”€â”€ GSTIN picker popover â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _closeGstinPopover() {
    _gstinOverlay?.remove();
    _gstinOverlay = null;
    if (mounted) setState(() {});
  }

  void _openGstinPopover(BuildContext context) {
    if (_gstinOverlay != null) { _closeGstinPopover(); return; }

    final gstin = _gstinValue;
    final state = widget.customer.billingAddressStateId ?? '';
    final label = gstin.isNotEmpty ? '$gstin${state.isNotEmpty ? ' - $state' : ''}' : 'No GSTIN';

    _gstinOverlay = OverlayEntry(builder: (ctx) {
      return Stack(children: [
        GestureDetector(onTap: _closeGstinPopover, behavior: HitTestBehavior.translucent, child: const SizedBox.expand()),
        CompositedTransformFollower(
          link: _gstinLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.white,
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // GSTIN row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: const Icon(Icons.arrow_drop_up, size: 16, color: AppTheme.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    // Manage Tax Informations
                    InkWell(
                      onTap: () {
                        _closeGstinPopover();
                        showDialog<void>(
                          context: context,
                          barrierColor: Colors.black.withValues(alpha: 0.35),
                          builder: (_) => _VCManageTaxInfoDialog(
                            gstin: _gstinValue,
                            placeOfSupply: widget.customer.billingAddressStateId ?? '',
                            onSelected: (gstin) {
                              if (mounted) setState(() => _overrideGstin = gstin);
                            },
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              'Manage Tax Informations',
                              style: TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(width: 6),
                            Icon(LucideIcons.settings, size: 14, color: AppTheme.primaryBlue),
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
      ]);
    });
    Overlay.of(context).insert(_gstinOverlay!);
    setState(() {});
  }

  @override
  void dispose() {
    _billingOverlay?.remove();
    _gstinOverlay?.remove();
    _gstTreatmentOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBillingOpen = _billingOverlay != null;
    final isGstinOpen = _gstinOverlay != null;
    final isGstTreatmentOpen = _gstTreatmentOverlay != null;
    final hasGstin = _gstinValue.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: widget.labelWidth + 16, bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BILLING ADDRESS header with pencil
          CompositedTransformTarget(
            link: _billingLink,
            child: GestureDetector(
              onTap: () => _openBillingPicker(context),
              child: Container(
                padding: isBillingOpen ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4) : EdgeInsets.zero,
                decoration: isBillingOpen
                    ? BoxDecoration(border: Border.all(color: AppTheme.primaryBlue), borderRadius: BorderRadius.circular(4))
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'BILLING ADDRESS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Icon(LucideIcons.pencil, size: 12, color: isBillingOpen ? AppTheme.primaryBlue : AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Vendor name
          Text(_displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          // Address lines
          ..._billingLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(line, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ),
          ),
          // Space after last address line (after phone)
          const SizedBox(height: 10),
          // GST Treatment row with pencil
          CompositedTransformTarget(
            link: _gstTreatmentLink,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('GST Treatment: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                Text(_gstTreatmentLabel, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _openGstTreatmentPopover(context),
                  child: Icon(LucideIcons.pencil, size: 12, color: isGstTreatmentOpen ? AppTheme.primaryBlue : AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // GSTIN row with pencil popover
          if (hasGstin) ...[
            CompositedTransformTarget(
              link: _gstinLink,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'GSTIN: ',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500, letterSpacing: 0.3),
                  ),
                  Text(
                    _gstinValue,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _openGstinPopover(context),
                    child: Icon(LucideIcons.pencil, size: 12, color: isGstinOpen ? AppTheme.primaryBlue : AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable date-picker trigger field
// ---------------------------------------------------------------------------

class _DatePickerField extends StatelessWidget {
  final GlobalKey globalKey;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  const _DatePickerField({required this.globalKey, required this.date, required this.onPick});

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: globalKey,
      onTap: () async {
        final picked = await ZerpaiDatePicker.show(
          context,
          initialDate: date ?? DateTime.now(),
          targetKey: globalKey,
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null ? _fmt(date!) : 'dd-MM-yyyy',
                style: TextStyle(
                  fontSize: 13,
                  color: date != null ? AppTheme.textPrimary : AppTheme.textHint,
                ),
              ),
            ),
            const Icon(LucideIcons.calendar, size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New TDS / TCS Tax Form Dialog
// ---------------------------------------------------------------------------

class _VCNewTaxFormDialog extends StatefulWidget {
  final bool isTds;
  const _VCNewTaxFormDialog({required this.isTds});

  @override
  State<_VCNewTaxFormDialog> createState() => _VCNewTaxFormDialogState();
}

class _VCNewTaxFormDialogState extends State<_VCNewTaxFormDialog> {
  final _taxNameCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  String _incomeAct = 'New Income Tax Act 2025';
  String? _natureOfCollection;
  bool _isHigherRate = false;
  DateTime? _startDate = DateTime(2026, 4, 1);
  DateTime? _endDate;
  final _startDateKey = GlobalKey();
  final _endDateKey = GlobalKey();

  static const _incomeTaxActs = [
    'New Income Tax Act 2025',
    'Old Income Tax Act 1961',
  ];

  static const _natureOptions = [
    'Sale of Goods',
    'Provision of Services',
    'Sale of Scrap',
    'Sale of Minerals',
    'Tendu Leaves',
    'Timber - Forest Lease',
    'Timber - Other Mode',
    'Any Other Forest Produce',
    'Alcoholic Liquor',
    'Parking Lot',
    'Toll Plaza',
    'Mining & Quarrying',
  ];

  @override
  void dispose() {
    _taxNameCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = widget.isTds ? 'TDS' : 'TCS';
    final payableLabel = widget.isTds ? 'TDS Payable' : 'TCS Payable';
    final receivableLabel = widget.isTds ? 'TDS Receivable' : 'TCS Receivable';
    final higherLabel = widget.isTds ? 'This is a Higher TDS Rate' : 'This is a Higher TCS Rate';

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 18, 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'New $typeLabel',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(LucideIcons.x, size: 18, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            // Form body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Tax Name + Rate
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                text: 'Tax Name',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                              ),
                            ),
                            const SizedBox(height: 6),
                            CustomTextField(
                              controller: _taxNameCtrl,
                              hintText: '',
                              height: 36,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                text: 'Rate (%)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                              ),
                            ),
                            const SizedBox(height: 6),
                            CustomTextField(
                              controller: _rateCtrl,
                              hintText: '',
                              height: 36,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Applicable Income Tax Act
                  const Text('Applicable Income Tax Act', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  FormDropdown<String>(
                    value: _incomeAct,
                    items: _incomeTaxActs,
                    hint: 'Select',
                    height: 36,
                    onChanged: (val) { if (val != null) setState(() => _incomeAct = val); },
                  ),
                  const SizedBox(height: 16),
                  // Nature of Collection
                  RichText(
                    text: const TextSpan(
                      text: 'Nature of Collection',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                      children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                    ),
                  ),
                  const SizedBox(height: 6),
                  FormDropdown<String>(
                    value: _natureOfCollection,
                    items: _natureOptions,
                    hint: 'Select a Tax Type.',
                    height: 36,
                    onChanged: (val) => setState(() => _natureOfCollection = val),
                  ),
                  const SizedBox(height: 16),
                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.info, size: 14, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: AppTheme.textBody),
                              children: [
                                TextSpan(text: 'By default, $typeLabel will be tracked under '),
                                TextSpan(text: payableLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const TextSpan(text: ' and '),
                                TextSpan(text: receivableLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const TextSpan(text: ' accounts. Click Edit to choose an account of your choice. '),
                                const TextSpan(
                                  text: 'Edit',
                                  style: TextStyle(color: AppTheme.primaryBlue, decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Higher rate checkbox
                  Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _isHigherRate,
                          onChanged: (v) => setState(() => _isHigherRate = v ?? false),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(higherLabel, style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                      const SizedBox(width: 6),
                      ZTooltip(
                        message: 'Select this if a higher $typeLabel rate applies when PAN is not provided.',
                        child: const Icon(LucideIcons.helpCircle, size: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Applicable Period
                  Row(
                    children: [
                      const Text('Applicable Period', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(width: 6),
                      ZTooltip(
                        message: 'The date range during which this $typeLabel rate is applicable.',
                        child: const Icon(LucideIcons.helpCircle, size: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Date', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 6),
                            _DatePickerField(
                              globalKey: _startDateKey,
                              date: _startDate,
                              onPick: (d) => setState(() => _startDate = d),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Date', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 6),
                            _DatePickerField(
                              globalKey: _endDateKey,
                              date: _endDate,
                              onPick: (d) => setState(() => _endDate = d),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      ZButton.primary(label: 'Save', onPressed: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      ZButton.secondary(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
                    ],
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
}

// ---------------------------------------------------------------------------
// Tax Summary Line
// ---------------------------------------------------------------------------

class _VCTaxSummaryLine {
  final String label;
  final double amount;
  const _VCTaxSummaryLine({required this.label, required this.amount});
}

// ---------------------------------------------------------------------------
// Layout helpers (mirrors credit note add page pattern)
// ---------------------------------------------------------------------------

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
              SizedBox(width: effectiveFieldWidth, child: child),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Item Table Toolbar
// ---------------------------------------------------------------------------

class _VCItemTableToolbar extends StatelessWidget {
  const _VCItemTableToolbar({
    required this.discountType,
    required this.onDiscountTypeChanged,
    required this.selectedPriceList,
    required this.priceListOptions,
    required this.onPriceListChanged,
    required this.selectedWarehouse,
    required this.warehouses,
    required this.onWarehouseChanged,
  });

  final String discountType;
  final ValueChanged<String> onDiscountTypeChanged;
  final PriceList? selectedPriceList;
  final List<PriceList> priceListOptions;
  final ValueChanged<PriceList?> onPriceListChanged;
  final Warehouse? selectedWarehouse;
  final List<Warehouse> warehouses;
  final ValueChanged<Warehouse?> onWarehouseChanged;

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
                  : FormDropdown<Warehouse>(
                      value: selectedWarehouse,
                      items: warehouses,
                      hint: 'Select Warehouse',
                      height: 36,
                      hideBorderDefault: true,
                      onChanged: onWarehouseChanged,
                    ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
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
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
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
                    hint: 'Select Price List',
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

// ---------------------------------------------------------------------------
// Items grid (table only â€” notes/totals moved to parent)
// ---------------------------------------------------------------------------

class _VCItemsGrid extends StatefulWidget {
  const _VCItemsGrid({
    required this.items,
    required this.availableProducts,
    required this.onSearchProducts,
    required this.onAddItem,
    required this.onAddBulkItems,
    required this.onInsertItem,
    required this.onDuplicateItem,
    required this.onRemoveItem,
    required this.onTotalsChanged,
    required this.onAddBatches,
    required this.warehouse,
    required this.accountTree,
    required this.taxOptions,
    required this.isReverseCharge,
    required this.onViewItemDetails,
    required this.onViewItemDetailsTransactions,
    required this.onEditItem,
    required this.discountType,
    this.defaultPriceList,
  });

  final List<_VCLineItem> items;
  final List<Item> availableProducts;
  final Future<List<Item>> Function(String query) onSearchProducts;
  final VoidCallback onAddItem;
  final VoidCallback onAddBulkItems;
  final void Function(int) onInsertItem;
  final void Function(int) onDuplicateItem;
  final void Function(int) onRemoveItem;
  final VoidCallback onTotalsChanged;
  final Future<void> Function(_VCLineItem) onAddBatches;
  final String warehouse;
  final List<shared_acct.AccountNode> accountTree;
  final List<_VCTaxOption> taxOptions;
  final bool isReverseCharge;
  final void Function(_VCLineItem) onViewItemDetails;
  final void Function(_VCLineItem) onViewItemDetailsTransactions;
  final void Function(_VCLineItem) onEditItem;
  final PriceList? defaultPriceList;
  final String discountType;

  @override
  State<_VCItemsGrid> createState() => _VCItemsGridState();
}

class _VCItemsGridState extends State<_VCItemsGrid> {
  String _selectedStockView = 'Available for Sale';
  static const double _rowActionWidth = 28;
  static const double _rowActionsWidth = _rowActionWidth * 2;
  static const double _rowMenuWidth = 220;

  bool _isBulkUpdateActive = false;
  String _selectedUpdateField = '';
  bool _areAdditionalInfosHidden = false;
  int? _hoveredItemActionIndex;

  void _openBulkUpdateDialog({required String field, required Widget child}) {
    setState(() => _selectedUpdateField = field);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppTheme.textPrimary.withValues(alpha: 0.1),
      pageBuilder: (context, anim1, anim2) {
        return Align(alignment: Alignment.topCenter, child: child);
      },
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
      child: _VCRowActionMenuHoverItem(
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
          onPressed: () {
            setState(
              () => _areAdditionalInfosHidden = !_areAdditionalInfosHidden,
            );
          },
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
                    child: _VCBulkMenuHoverItem(
                      label: 'Bulk Update Line Items',
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 1,
                    padding: EdgeInsets.zero,
                    height: 40,
                    child: _VCBulkMenuHoverItem(
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
            ],
          ),
        ),
        if (_isBulkUpdateActive)
          Container(
            margin: const EdgeInsets.only(right: _rowActionsWidth),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              border: Border(
                left: BorderSide(color: AppTheme.borderLight),
                right: BorderSide(color: AppTheme.borderLight),
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: Row(
              children: [
                _VCBulkUpdateActionButton(
                  label: 'Update Reporting Tags',
                  isSelected: _selectedUpdateField == 'ReportingTags',
                  onTap: () => _openBulkUpdateDialog(
                    field: 'ReportingTags',
                    child: const _VCBulkUpdateLineItemsDialog(),
                  ),
                ),
                const SizedBox(width: 8),
                _VCBulkUpdateActionButton(
                  label: 'Update Account',
                  isSelected: _selectedUpdateField == 'Account',
                  onTap: () => _openBulkUpdateDialog(
                    field: 'Account',
                    child: const _VCBulkUpdateAccountDialog(),
                  ),
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
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border(
              left: BorderSide(color: AppTheme.borderLight),
              right: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: IntrinsicHeight(
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
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: _TH('ACCOUNT'),
                  ),
                ),
                _vLine(),
                const Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: _TH('QUANTITY', right: true),
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
                if (widget.discountType == 'At Line Item Level') ...[
                  const Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: _TH('DISCOUNT', right: true),
                    ),
                  ),
                  _vLine(),
                ],
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
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        border: Border(
                          left: BorderSide(color: AppTheme.borderLight),
                          right: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Column(
                        children: [
                          _VCItemRow(
                            item: widget.items[index],
                            availableProducts: widget.availableProducts,
                            onSearchProducts: widget.onSearchProducts,
                            onChanged: widget.onTotalsChanged,
                            onAddBatches: () =>
                                widget.onAddBatches(widget.items[index]),
                            defaultWarehouse: widget.warehouse,
                            accountTree: widget.accountTree,
                            taxOptions: widget.taxOptions,
                            selectedStockView: _selectedStockView,
                            showAdditionalInformation:
                                !_areAdditionalInfosHidden,
                            onStockViewChanged: (v) =>
                                setState(() => _selectedStockView = v),
                            onViewItemDetails: () =>
                                widget.onViewItemDetails(widget.items[index]),
                            onViewItemDetailsTransactions: () =>
                                widget.onViewItemDetailsTransactions(widget.items[index]),
                            onEditItem: () =>
                                widget.onEditItem(widget.items[index]),
                            defaultPriceList: widget.defaultPriceList,
                            discountType: widget.discountType,
                          ),
                          if (index < widget.items.length - 1)
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IgnorePointer(
                        ignoring: !showActions,
                        child: AnimatedOpacity(
                          opacity: showActions ? 1 : 0,
                          duration: const Duration(milliseconds: 120),
                          child: SizedBox(
                            width: _rowActionWidth,
                            child: Center(child: _buildRowActionMenu(index)),
                          ),
                        ),
                      ),
                      _VCDeleteRowButton(
                        enabled: widget.items.length > 1,
                        onTap: () => widget.onRemoveItem(index),
                      ),
                    ],
                  ),
                ],
              ),
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
            border: Border(
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

// ---------------------------------------------------------------------------
// Item row
// ---------------------------------------------------------------------------

class _VCItemRow extends StatefulWidget {
  const _VCItemRow({
    required this.item,
    required this.availableProducts,
    required this.onSearchProducts,
    required this.onChanged,
    required this.onAddBatches,
    required this.defaultWarehouse,
    required this.accountTree,
    required this.taxOptions,
    required this.selectedStockView,
    required this.showAdditionalInformation,
    required this.onStockViewChanged,
    required this.onViewItemDetails,
    required this.onViewItemDetailsTransactions,
    required this.onEditItem,
    required this.discountType,
    this.defaultPriceList,
  });

  final _VCLineItem item;
  final List<Item> availableProducts;
  final Future<List<Item>> Function(String query) onSearchProducts;
  final VoidCallback onChanged;
  final VoidCallback onAddBatches;
  final String defaultWarehouse;
  final List<shared_acct.AccountNode> accountTree;
  final List<_VCTaxOption> taxOptions;
  final String selectedStockView;
  final bool showAdditionalInformation;
  final ValueChanged<String> onStockViewChanged;
  final VoidCallback onViewItemDetails;
  final VoidCallback onViewItemDetailsTransactions;
  final VoidCallback onEditItem;
  final PriceList? defaultPriceList;
  final String discountType;

  @override
  State<_VCItemRow> createState() => _VCItemRowState();
}

class _VCItemRowState extends State<_VCItemRow> {
  late final FocusNode _rateFocusNode;
  double _previousRate = 0.0;

  final LayerLink _hsnLayerLink = LayerLink();
  OverlayEntry? _hsnOverlay;
  late final TextEditingController _hsnEditController;

  final LayerLink _itcLayerLink = LayerLink();
  OverlayEntry? _itcOverlay;

  @override
  void initState() {
    super.initState();
    _rateFocusNode = FocusNode();
    _rateFocusNode.addListener(() {
      if (_rateFocusNode.hasFocus) {
        _previousRate =
            double.tryParse(widget.item.rateController.text) ?? 0.0;
      } else {
        _evaluateRateField();
        widget.onChanged();
      }
    });
    _hsnEditController = TextEditingController(
      text: widget.item.hsnCodeOverride ?? widget.item.sourceItem?.hsnCode ?? '',
    );
  }

  @override
  void dispose() {
    _rateFocusNode.dispose();
    _hsnOverlay?.remove();
    _hsnEditController.dispose();
    _itcOverlay?.remove();
    super.dispose();
  }

  void _evaluateRateField() {
    final val = widget.item.rateController.text.trim();
    if (val.isEmpty) return;

    if (val.startsWith('+=')) {
      final addVal = double.tryParse(val.substring(2)) ?? 0.0;
      widget.item.rateController.text =
          (_previousRate + addVal).toStringAsFixed(2);
      setState(() {});
      return;
    }
    if (val.startsWith('-=')) {
      final subVal = double.tryParse(val.substring(2)) ?? 0.0;
      widget.item.rateController.text =
          (_previousRate - subVal).toStringAsFixed(2);
      setState(() {});
      return;
    }
    if (val.startsWith('*=')) {
      final mulVal = double.tryParse(val.substring(2)) ?? 1.0;
      widget.item.rateController.text =
          (_previousRate * mulVal).toStringAsFixed(2);
      setState(() {});
      return;
    }
    if (val.startsWith('/=')) {
      final divVal = double.tryParse(val.substring(2)) ?? 1.0;
      if (divVal != 0) {
        widget.item.rateController.text =
            (_previousRate / divVal).toStringAsFixed(2);
        setState(() {});
      }
      return;
    }

    try {
      String exp = val;
      if (exp.startsWith('=')) exp = exp.substring(1);

      final match =
          RegExp(r'^([\d.]+)\s*([\+\-\*\/])\s*([\d.]+)$').firstMatch(exp);
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

  void _closeItcPopover() {
    _itcOverlay?.remove();
    _itcOverlay = null;
  }

  void _showItcPopover(BuildContext context) {
    if (_itcOverlay != null) {
      _closeItcPopover();
      return;
    }
    String selected = widget.item.itcStatus;

    _itcOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeItcPopover,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _itcLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: StatefulBuilder(
                  builder: (context, setPopupState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Input Tax Credit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _closeItcPopover,
                              child: const Icon(
                                LucideIcons.x,
                                size: 14,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final option in const [
                          'Eligible For ITC',
                          'Ineligible - As per Section 17 (5)',
                          'Ineligible - Others',
                        ])
                          InkWell(
                            onTap: () => setPopupState(() => selected = option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Radio<String>(
                                      value: option,
                                      groupValue: selected,
                                      onChanged: (v) {
                                        if (v != null) setPopupState(() => selected = v);
                                      },
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      activeColor: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => widget.item.itcStatus = selected);
                              widget.onChanged();
                              _closeItcPopover();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_itcOverlay!);
  }

  void _closeHsnPopover() {
    _hsnOverlay?.remove();
    _hsnOverlay = null;
    if (mounted) setState(() {});
  }

  void _showHsnPopover(BuildContext context) {
    if (_hsnOverlay != null) {
      _closeHsnPopover();
      return;
    }
    _hsnEditController.text =
        widget.item.hsnCodeOverride ?? widget.item.sourceItem?.hsnCode ?? '';

    _hsnOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeHsnPopover,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _hsnLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HSN Code',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: TextField(
                              controller: _hsnEditController,
                              autofocus: true,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              LucideIcons.search,
                              size: 14,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () {
                                final val =
                                    _hsnEditController.text.trim();
                                setState(() {
                                  widget.item.hsnCodeOverride =
                                      val.isEmpty ? null : val;
                                });
                                widget.onChanged();
                                _closeHsnPopover();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            child: OutlinedButton(
                              onPressed: _closeHsnPopover,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                side: const BorderSide(
                                  color: AppTheme.borderLight,
                                ),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
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
    );

    Overlay.of(context).insert(_hsnOverlay!);
    if (mounted) setState(() {});
  }

  String _computeAmount(_VCLineItem item) {
    final qty = double.tryParse(item.qtyController.text) ?? 0;
    final rate = double.tryParse(item.rateController.text) ?? 0;
    final gross = qty * rate;
    if (widget.discountType == 'At Line Item Level') {
      final d = double.tryParse(item.discountController.text) ?? 0;
      final discountAmt = item.discountIsPercent ? gross * d / 100 : d;
      return (gross - discountAmt).clamp(0.0, double.infinity).toStringAsFixed(2);
    }
    return gross.clamp(0.0, double.infinity).toStringAsFixed(2);
  }

  void _onItemSelected(Item? selected) {
    setState(() {
      widget.item.sourceItem = selected;
      if (selected != null) {
        final baseRate = selected.costPrice ?? 0.0;
        final pl = widget.defaultPriceList;
        final effectiveRate = pl != null
            ? pl.calculatePrice(selected.id ?? '', baseRate)
            : baseRate;
        widget.item.rateController.text = effectiveRate.toStringAsFixed(2);
        widget.item.selectedAccount =
            selected.purchaseAccountName ?? 'Cost of Goods Sold';
        widget.item.descriptionController.text =
            selected.purchaseDescription ?? '';
        if (widget.item.qtyController.text.isEmpty ||
            widget.item.qtyController.text == '0.00') {
          widget.item.qtyController.text = '1.00';
        }
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          height: _VendorCreditsCreatePageState._tableFieldHeight,
                          hideBorderDefault: true,
                          allowClear: false,
                          displayStringForValue: (p) => p.productName,
                          searchStringForValue: (p) =>
                              '${p.productName} ${p.itemCode} ${p.sku ?? ''}',
                          onSearch: widget.onSearchProducts,
                          itemBuilder: (product, isSelected, isHovered) =>
                              _VCProductDropdownItem(
                                productName: product.productName,
                                itemCode: product.itemCode,
                                highlighted: isSelected || isHovered,
                              ),
                          onChanged: _onItemSelected,
                        ),
                      ),
                      if (item.sourceItem != null) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          offset: const Offset(0, 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                          constraints: const BoxConstraints(
                            minWidth: 200,
                            maxWidth: 200,
                          ),
                          onSelected: (val) {
                            if (val == 'details') {
                              widget.onEditItem();
                            } else if (val == 'view') {
                              widget.onViewItemDetails();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'details',
                              padding: EdgeInsets.zero,
                              height: 44,
                              child: _VCRowMenuHoverItem(
                                label: 'Item Details',
                                icon: LucideIcons.pencil,
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'view',
                              padding: EdgeInsets.zero,
                              height: 44,
                              child: _VCRowMenuHoverItem(
                                label: 'View Item Details',
                                icon: LucideIcons.shoppingBag,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 2),
                        GestureDetector(
                          onTap: () => _onItemSelected(null),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              LucideIcons.x,
                              size: 14,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ),
                      ],
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
                              color: AppTheme.infoBg,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              item.sourceItem!.type.toUpperCase() == 'SERVICE'
                                  ? 'SERVICE'
                                  : 'GOODS',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.infoTextDark,
                              ),
                            ),
                          ),
                          if (item.sourceItem != null) ...[
                            const SizedBox(width: 8),
                            CompositedTransformTarget(
                              link: _hsnLayerLink,
                              child: GestureDetector(
                                onTap: () => _showHsnPopover(context),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'HSN: ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      item.hsnCodeOverride ??
                                          item.sourceItem?.hsnCode ??
                                          'â€”',
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
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (widget.showAdditionalInformation) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 48, bottom: 4),
                      child: _VCReportingTagsPopoverButton(
                        item: item,
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _vLine(),
          // ACCOUNT
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: AccountTreeDropdown(
                value: item.selectedAccount,
                nodes: widget.accountTree.isNotEmpty
                    ? widget.accountTree
                    : _vcFallbackAccountTree,
                hint: 'Select Account',
                height: _VendorCreditsCreatePageState._tableFieldHeight,
                border: Border.all(color: Colors.transparent),
                onChanged: (value) {
                  setState(() => item.selectedAccount = value);
                  widget.onChanged();
                },
              ),
            ),
          ),
          _vLine(),
          // QUANTITY
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomTextField(
                    controller: item.qtyController,
                    height: _VendorCreditsCreatePageState._tableFieldHeight,
                    textAlign: TextAlign.right,
                    hintText: '0',
                    hideBorderDefault: true,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => widget.onChanged(),
                  ),
                  if (item.sourceItem != null) ...[
                    const SizedBox(height: 4),
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
                          ? '${item.sourceItem!.stockOnHand?.toStringAsFixed(0) ?? '0'} pcs'
                          : '${item.sourceItem!.stockOnHand?.toStringAsFixed(0) ?? '0'} pcs',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    WarehouseHoverPopover(
                      warehouseName:
                          item.warehouseLocation ?? widget.defaultWarehouse,
                      selectedView: widget.selectedStockView,
                      onViewChanged: widget.onStockViewChanged,
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
                              item.warehouseLocation ?? widget.defaultWarehouse,
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
                    GestureDetector(
                      onTap: widget.onAddBatches,
                      child: item.savedBatches.isEmpty
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  LucideIcons.alertTriangle,
                                  size: 12,
                                  color: AppTheme.errorRed,
                                ),
                                SizedBox(width: 4),
                                Flexible(
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
                              '${item.savedBatches.fold(0, (sum, b) => sum + (int.tryParse(b.quantityController.text) ?? 0))} pcs / ${item.savedBatches.length} ${item.savedBatches.length == 1 ? 'batch' : 'batches'}',
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
                    focusNode: _rateFocusNode,
                    height: _VendorCreditsCreatePageState._tableFieldHeight,
                    textAlign: TextAlign.right,
                    hintText: '0.00',
                    hideBorderDefault: true,
                    keyboardType: TextInputType.text,
                    onChanged: (_) => widget.onChanged(),
                  ),
                  if (item.sourceItem != null) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 20,
                      child: FormDropdown<String>(
                        value: item.selectedPriceList ??
                            widget.defaultPriceList?.name,
                        items: const [
                          'Standard Selling',
                          'Wholesale Price',
                          'Retail Price',
                        ],
                        hint: 'Apply Price List',
                        height: 20,
                        hideBorderDefault: true,
                        allowClear: true,
                        onChanged: (v) {
                          setState(() => item.selectedPriceList = v);
                          widget.onChanged();
                        },
                      ),
                    ),
                    InkWell(
                      onTap: widget.onViewItemDetailsTransactions,
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
          // DISCOUNT (line item level only)
          if (widget.discountType == 'At Line Item Level') ...[
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: item.discountController,
                        height: _VendorCreditsCreatePageState._tableFieldHeight,
                        textAlign: TextAlign.right,
                        hintText: '0',
                        hideBorderDefault: true,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => widget.onChanged(),
                      ),
                    ),
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          item.discountIsPercent = !item.discountIsPercent;
                        });
                        widget.onChanged();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDisabled,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Text(
                          item.discountIsPercent ? '%' : 'â‚¹',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _vLine(),
          ],
          // TAX
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormDropdown<_VCTaxOption>(
                    value: item.selectedTax == null
                        ? null
                        : widget.taxOptions.firstWhere(
                            (o) => o.label == item.selectedTax,
                            orElse: () => widget.taxOptions.firstWhere(
                              (o) => !o.isHeader,
                              orElse: () => const _VCTaxOption(label: ''),
                            ),
                          ),
                    items: widget.taxOptions,
                    hint: 'Select Tax',
                    height: _VendorCreditsCreatePageState._tableFieldHeight,
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
                        setState(() {
                          item.selectedTax = val.label;
                          item.selectedTaxRate = val.rate > 0 ? val.rate : null;
                        });
                        widget.onChanged();
                      } else if (val == null) {
                        setState(() {
                          item.selectedTax = null;
                          item.selectedTaxRate = null;
                        });
                        widget.onChanged();
                      }
                    },
                  ),
                  if (item.sourceItem != null) ...[
                    const SizedBox(height: 4),
                    CompositedTransformTarget(
                      link: _itcLayerLink,
                      child: GestureDetector(
                        onTap: () => _showItcPopover(context),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.itcStatus,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.pencil,
                              size: 10,
                              color: AppTheme.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _vLine(),
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
      ),
    );
  }
}

class _VCRowActionMenuHoverItem extends StatefulWidget {
  const _VCRowActionMenuHoverItem({
    required this.label,
    required this.width,
    required this.height,
  });

  final String label;
  final double width;
  final double height;

  @override
  State<_VCRowActionMenuHoverItem> createState() =>
      _VCRowActionMenuHoverItemState();
}

class _VCRowActionMenuHoverItemState extends State<_VCRowActionMenuHoverItem> {
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

class _VCDeleteRowButton extends StatefulWidget {
  const _VCDeleteRowButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_VCDeleteRowButton> createState() => _VCDeleteRowButtonState();
}

class _VCDeleteRowButtonState extends State<_VCDeleteRowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final canDelete = widget.enabled;
    return SizedBox(
      width: 28,
      child: Center(
        child: MouseRegion(
          cursor: canDelete
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) {
            if (canDelete) setState(() => _hovered = true);
          },
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: canDelete ? widget.onTap : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hovered && canDelete
                    ? AppTheme.errorRed
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                LucideIcons.x,
                size: 16,
                color: canDelete
                    ? (_hovered ? Colors.white : AppTheme.errorRed)
                    : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VCRowActionIconButton extends StatefulWidget {
  const _VCRowActionIconButton({required this.icon});

  final IconData icon;

  @override
  State<_VCRowActionIconButton> createState() => _VCRowActionIconButtonState();
}

class _VCRowActionIconButtonState extends State<_VCRowActionIconButton> {
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

class _VCBulkMenuHoverItem extends StatefulWidget {
  const _VCBulkMenuHoverItem({required this.label});

  final String label;

  @override
  State<_VCBulkMenuHoverItem> createState() => _VCBulkMenuHoverItemState();
}

class _VCBulkMenuHoverItemState extends State<_VCBulkMenuHoverItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = _hovered
        ? AppTheme.backgroundColor
        : AppTheme.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered
              ? AppTheme.primaryBlue
              : AppTheme.backgroundColor.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VCBulkUpdateActionButton extends StatelessWidget {
  const _VCBulkUpdateActionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.successGreen,
          borderRadius: BorderRadius.circular(4),
          border: isSelected
              ? Border.all(color: AppTheme.primaryBlue, width: 2)
              : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.backgroundColor,
          ),
        ),
      ),
    );
  }
}

class _VCBulkUpdateLineItemsDialog extends StatefulWidget {
  const _VCBulkUpdateLineItemsDialog();

  @override
  State<_VCBulkUpdateLineItemsDialog> createState() =>
      _VCBulkUpdateLineItemsDialogState();
}

class _VCBulkUpdateLineItemsDialogState
    extends State<_VCBulkUpdateLineItemsDialog> {
  String? _selectedAdgf = 'None';
  String? _selectedSchedule = 'None';
  String? _selectedDemoTag = 'None';

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: AppTheme.backgroundColor,
      elevation: 8,
      shadowColor: AppTheme.textPrimary.withValues(alpha: 0.25),
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
                borderRadius: BorderRadius.circular(4),
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
                child: _VCBulkDialogDropdown(
                  label: 'ADGF',
                  value: _selectedAdgf,
                  onChanged: (value) => setState(() => _selectedAdgf = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _VCBulkDialogDropdown(
                  label: 'Schedule',
                  value: _selectedSchedule,
                  onChanged: (value) =>
                      setState(() => _selectedSchedule = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 280,
            child: _VCBulkDialogDropdown(
              label: 'Demo Advanced Reporting Tag',
              value: _selectedDemoTag,
              onChanged: (value) => setState(() => _selectedDemoTag = value),
            ),
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
          _VCBulkDialogActions(onUpdate: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

class _VCBulkUpdateAccountDialog extends StatefulWidget {
  const _VCBulkUpdateAccountDialog();

  @override
  State<_VCBulkUpdateAccountDialog> createState() =>
      _VCBulkUpdateAccountDialogState();
}

class _VCBulkUpdateAccountDialogState
    extends State<_VCBulkUpdateAccountDialog> {
  String? _selectedAccount;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: AppTheme.backgroundColor,
      elevation: 8,
      shadowColor: AppTheme.textPrimary.withValues(alpha: 0.25),
      child: SizedBox(
        width: 600,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VCBulkDialogHeader(
                title: 'Bulk Update Line Items',
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select an account for the selected line items.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 280,
                child: _VCBulkDialogDropdown(
                  label: 'Choose Account',
                  value: _selectedAccount,
                  items: const [
                    'Select an account',
                    'Cost of Goods Sold',
                    'Purchases',
                    'Purchase Returns and Allowances',
                    'Other Expenses',
                  ],
                  hint: 'Select an account',
                  onChanged: (value) =>
                      setState(() => _selectedAccount = value),
                ),
              ),
              const SizedBox(height: 24),
              _VCBulkDialogActions(onUpdate: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}

class _VCBulkUpdateDiscountAccountDialog extends StatefulWidget {
  const _VCBulkUpdateDiscountAccountDialog();

  @override
  State<_VCBulkUpdateDiscountAccountDialog> createState() =>
      _VCBulkUpdateDiscountAccountDialogState();
}

class _VCBulkUpdateDiscountAccountDialogState
    extends State<_VCBulkUpdateDiscountAccountDialog> {
  int _selectedValue = 0;
  String? _selectedAccount;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: AppTheme.backgroundColor,
      elevation: 8,
      shadowColor: AppTheme.textPrimary.withValues(alpha: 0.25),
      child: SizedBox(
        width: 600,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VCBulkDialogHeader(
                title: 'Bulk Update Line Items',
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose a discount account for the selected line items.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              RadioListTile<int>(
                value: 0,
                groupValue: _selectedValue,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primaryBlue,
                title: const Text(
                  "Use the same account as each item's purchase account",
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
                onChanged: (value) =>
                    setState(() => _selectedValue = value ?? 0),
              ),
              RadioListTile<int>(
                value: 1,
                groupValue: _selectedValue,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primaryBlue,
                title: const Text(
                  'Choose Account',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
                onChanged: (value) =>
                    setState(() => _selectedValue = value ?? 1),
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
                        'Cost of Goods Sold',
                        'Purchases',
                        'Purchase Returns and Allowances',
                        'Other Expenses',
                      ],
                      hint: 'Select an account',
                      height: 36,
                      onChanged: (value) =>
                          setState(() => _selectedAccount = value),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _VCBulkDialogActions(onUpdate: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}

class _VCBulkDialogHeader extends StatelessWidget {
  const _VCBulkDialogHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(4),
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
    );
  }
}

class _VCBulkDialogDropdown extends StatelessWidget {
  const _VCBulkDialogDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    this.items = const ['None', 'Option 1', 'Option 2'],
    this.hint = 'None',
  });

  final String label;
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 8),
        FormDropdown<String>(
          value: value,
          items: items,
          hint: hint,
          height: 36,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _VCBulkDialogActions extends StatelessWidget {
  const _VCBulkDialogActions({required this.onUpdate});

  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: onUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successGreen,
            foregroundColor: AppTheme.backgroundColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            backgroundColor: AppTheme.bgDisabled,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Line item data model
// ---------------------------------------------------------------------------
// Item Details Side Panel
// ---------------------------------------------------------------------------

class _VCItemDetailsSidePanel extends StatefulWidget {
  final _VCLineItem item;
  final VoidCallback onClose;
  final int initialTab;

  const _VCItemDetailsSidePanel({
    required this.item,
    required this.onClose,
    this.initialTab = 0,
  });

  @override
  State<_VCItemDetailsSidePanel> createState() =>
      _VCItemDetailsSidePanelState();
}

class _VCItemDetailsSidePanelState extends State<_VCItemDetailsSidePanel> {
  late int _tab;
  bool _otherDetailsExpanded = false;
  String _txnType = 'Vendor Credits';
  bool _txnTypeDropdownOpen = false;
  String _txnStatus = 'All';
  bool _txnStatusDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

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
            color: AppTheme.infoBg,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderMid),
                  ),
                  child: const Icon(
                    LucideIcons.image,
                    size: 28,
                    color: AppTheme.textMuted,
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
                              (widget.item.sourceItem?.productName ?? 'ITEM')
                                  .toUpperCase(),
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
                _VCPanelTabButton(
                  label: 'ITEM DETAILS',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _VCPanelTabButton(
                  label: 'STOCK LOCATIONS',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                _VCPanelTabButton(
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
              child: _VCPanelStatCard(
                icon: LucideIcons.truck,
                label: 'To Be Received',
                value: '0.00',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _VCPanelStatCard(
                icon: LucideIcons.arrowRightLeft,
                label: 'To Be Billed',
                value: '0.00',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _VCPanelSectionHeading(
          'Purchase Information',
          color: AppTheme.textPrimary,
        ),
        const SizedBox(height: 12),
        _VCPanelDetailRow(
          label: 'Cost Price',
          value: widget.item.sourceItem?.costPrice != null
              ? 'â‚¹${widget.item.sourceItem!.costPrice!.toStringAsFixed(2)}'
              : 'â‚¹0.00',
        ),
        const SizedBox(height: 8),
        const _VCPanelDetailRow(label: 'Account', value: 'Cost of Goods Sold'),
        const SizedBox(height: 24),
        const _VCPanelSectionHeading(
          'Sales Information',
          color: AppTheme.textPrimary,
        ),
        const SizedBox(height: 12),
        _VCPanelDetailRow(
          label: 'Selling Price',
          value: widget.item.sourceItem?.sellingPrice != null
              ? 'â‚¹${widget.item.sourceItem!.sellingPrice!.toStringAsFixed(2)}'
              : 'â‚¹0.00',
        ),
        const SizedBox(height: 8),
        const _VCPanelDetailRow(label: 'Account', value: 'Sales'),
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
                const Text(
                  'Other Details',
                  style: TextStyle(
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
          const _VCPanelDetailRow(
            label: 'Inventory Account',
            value: 'Inventory Asset',
          ),
        ],
      ],
    );
  }

  Widget _buildStockLocationsTab() {
    const rows = [
      ('ZABNIX PRIVATE LIMITED', true, '0.00', '0.00', '0.00'),
      ('DEMO WAREHOUSE 1 (Warehouse)', false, '0.00', '0.00', '0.00'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: const Row(
            children: [
              _VCStockColHeader(
                label: 'LOCATION\nNAME',
                flex: 3,
                align: TextAlign.left,
              ),
              _VCStockColHeader(
                label: 'STOCK ON\nHAND',
                flex: 2,
                align: TextAlign.right,
              ),
              _VCStockColHeader(
                label: 'COMMITTED\nSTOCK',
                flex: 2,
                align: TextAlign.right,
              ),
              _VCStockColHeader(
                label: 'AVAILABLE\nFOR SALE',
                flex: 2,
                align: TextAlign.right,
              ),
            ],
          ),
        ),
        ...rows.map((r) {
          final (name, starred, onHand, committed, available) = r;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(
                        starred ? LucideIcons.star : LucideIcons.star,
                        size: 12,
                        color: starred
                            ? AppTheme.warningOrange
                            : AppTheme.borderLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    onHand,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    committed,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    available,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    const txnTypes = [
      'Purchase Orders',
      'Bills',
      'Vendor Credits',
      'Sales Orders',
      'Invoices',
      'Credit Notes',
    ];
    final statusOptions =
        (_txnType == 'Vendor Credits' || _txnType == 'Credit Notes')
        ? ['All', 'Open', 'Closed', 'Void']
        : (_txnType == 'Bills' || _txnType == 'Invoices')
        ? ['All', 'Draft', 'Sent', 'Partially Paid', 'Paid', 'Void']
        : ['All', 'Draft', 'Confirmed', 'Billed', 'Void'];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                  'No $_txnType found for this item.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
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
                        (opt) => _VCStockDropdownOption(
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
                        (opt) => _VCStockDropdownOption(
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

class _VCPanelTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _VCPanelTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

class _VCPanelStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _VCPanelStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.infoBg,
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

class _VCPanelSectionHeading extends StatelessWidget {
  final String text;
  final Color color;
  const _VCPanelSectionHeading(this.text, {this.color = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color),
    );
  }
}

class _VCPanelDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _VCPanelDetailRow({required this.label, required this.value});

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

class _VCStockColHeader extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _VCStockColHeader({
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

class _VCStockDropdownOption extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _VCStockDropdownOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_VCStockDropdownOption> createState() => _VCStockDropdownOptionState();
}

class _VCStockDropdownOptionState extends State<_VCStockDropdownOption> {
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
              color: _hovered ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _VCBatch {
  final referenceController = TextEditingController();
  final mfrBatchController = TextEditingController();
  final mfrDateController = TextEditingController();
  final expiryDateController = TextEditingController();
  final quantityController = TextEditingController();

  void dispose() {
    referenceController.dispose();
    mfrBatchController.dispose();
    mfrDateController.dispose();
    expiryDateController.dispose();
    quantityController.dispose();
  }
}

class _VCLineItem {
  Item? sourceItem;
  String? selectedTax;
  double? selectedTaxRate;
  String? selectedAccount;
  String? selectedPriceList;
  String itcStatus = 'Eligible For ITC';
  String? warehouseLocation;
  String? hsnCodeOverride;
  bool discountIsPercent = true;
  Map<String, String?> selectedTagValues = {};
  List<_VCBatch> savedBatches = [];
  final qtyController = TextEditingController(text: '1.00');
  final rateController = TextEditingController(text: '0.00');
  final discountController = TextEditingController(text: '0');
  final descriptionController = TextEditingController();

  void dispose() {
    qtyController.dispose();
    rateController.dispose();
    discountController.dispose();
    descriptionController.dispose();
    for (final b in savedBatches) {
      b.dispose();
    }
  }
}

// Fallback shown while chartOfAccountsProvider is still loading
final List<shared_acct.AccountNode> _vcFallbackAccountTree = [
  shared_acct.AccountNode(
    id: 'Cost of Goods Sold',
    name: 'Cost of Goods Sold',
  ),
  shared_acct.AccountNode(id: 'Purchases', name: 'Purchases'),
  shared_acct.AccountNode(
    id: 'Purchase Returns and Allowances',
    name: 'Purchase Returns and Allowances',
  ),
  shared_acct.AccountNode(id: 'Other Expenses', name: 'Other Expenses'),
];

// â”€â”€â”€ Manage Tax Informations Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VCManageTaxInfoDialog extends ConsumerStatefulWidget {
  final String gstin;
  final String placeOfSupply;
  final ValueChanged<String> onSelected;

  const _VCManageTaxInfoDialog({
    required this.gstin,
    required this.placeOfSupply,
    required this.onSelected,
  });

  @override
  ConsumerState<_VCManageTaxInfoDialog> createState() => _VCManageTaxInfoDialogState();
}

class _VCManageTaxInfoDialogState extends ConsumerState<_VCManageTaxInfoDialog> {
  bool _showAddForm = false;
  final TextEditingController _newGstinCtrl = TextEditingController();
  String? _newPlaceOfSupply;

  @override
  void dispose() {
    _newGstinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeLabel = widget.placeOfSupply.isNotEmpty ? widget.placeOfSupply : 'â€”';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(left: 80, right: 80, top: 0, bottom: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, minHeight: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Manage Tax Informations',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryBlue, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),

            // â”€â”€ Add New Tax Information button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _showAddForm = !_showAddForm;
                    if (!_showAddForm) {
                      _newGstinCtrl.clear();
                      _newPlaceOfSupply = null;
                    }
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Add New Tax Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
            ),

            // â”€â”€ Inline Add Form â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_showAddForm) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Two fields row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text.rich(
                                    TextSpan(children: [
                                      TextSpan(text: 'GSTIN / UIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.errorRed, letterSpacing: 0.3)),
                                      TextSpan(text: '*', style: TextStyle(fontSize: 12, color: AppTheme.errorRed)),
                                    ]),
                                  ),
                                  const SizedBox(width: 4),
                                  ZTooltip(
                                    message: 'Enter the 15-digit GSTIN or UIN number for this vendor.',
                                    child: const Icon(LucideIcons.helpCircle, size: 13, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _newGstinCtrl,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(color: AppTheme.borderLight),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(color: AppTheme.borderLight),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(color: AppTheme.primaryBlue),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {},
                                child: const Text('Validate', style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: 'Place of Supply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.errorRed, letterSpacing: 0.3)),
                                  TextSpan(text: '*', style: TextStyle(fontSize: 12, color: AppTheme.errorRed)),
                                ]),
                              ),
                              const SizedBox(height: 6),
                              FormDropdown<String>(
                                value: _newPlaceOfSupply,
                                items: ref.watch(statesProvider('IN')).value?.map((s) => s['name'] ?? '').where((n) => n.isNotEmpty).toList() ?? [],
                                hint: '',
                                height: 34,
                                onChanged: (v) => setState(() => _newPlaceOfSupply = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final gstin = _newGstinCtrl.text.trim();
                            if (gstin.isNotEmpty) {
                              widget.onSelected(gstin);
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('Save and Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() {
                            _showAddForm = false;
                            _newGstinCtrl.clear();
                            _newPlaceOfSupply = null;
                          }),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.borderLight),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // â”€â”€ Table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            const SizedBox(height: 16),
            // Table header
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight),
                  bottom: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: const [
                  Expanded(
                    flex: 5,
                    child: Text('GSTIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.4)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text('PLACE OF SUPPLY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.4)),
                  ),
                  SizedBox(width: 24),
                ],
              ),
            ),
            // Table row â€” primary entry
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.gstin.isNotEmpty ? widget.gstin : 'â€”',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '(Primary Tax Information)',
                          style: TextStyle(fontSize: 11, color: AppTheme.accentGreen, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      placeLabel,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                  // Up/down scroll arrows (decorative)
                  Column(
                    children: const [
                      Icon(Icons.arrow_drop_up, size: 18, color: AppTheme.textSecondary),
                      Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Vendor Details Tag â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VCVendorDetailsTag extends StatelessWidget {
  final String vendorName;
  final VoidCallback onTap;

  const _VCVendorDetailsTag({required this.vendorName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: AppTheme.textSecondary,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 220,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      vendorName,
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
                  const Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.backgroundColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// â”€â”€â”€ Vendor Details Side Panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VCVendorDetailsSidePanel extends StatefulWidget {
  final SalesCustomer vendor;
  final VoidCallback onClose;

  const _VCVendorDetailsSidePanel({required this.vendor, required this.onClose});

  @override
  State<_VCVendorDetailsSidePanel> createState() => _VCVendorDetailsSidePanelState();
}

class _VCVendorDetailsSidePanelState extends State<_VCVendorDetailsSidePanel> {
  int _tab = 0;
  bool _showContactPersons = false;
  bool _showAddress = false;

  String get _gstTreatmentLabel {
    switch (widget.vendor.gstTreatment?.toLowerCase()) {
      case 'registered_business': return 'Registered Business';
      case 'unregistered_business': return 'Unregistered Business';
      case 'overseas': return 'Overseas';
      case 'consumer': return 'Consumer';
      default: return widget.vendor.gstTreatment ?? 'Unregistered Business';
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
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
          // Header
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
                    v.displayName.isEmpty ? '?' : v.displayName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vendor', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              v.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
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
                            child: const Icon(LucideIcons.externalLink, size: 14, color: AppTheme.primaryBlue),
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
                    child: Icon(LucideIcons.x, size: 20, color: AppTheme.errorRed),
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderLight), bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                _VCPanelTabButton(label: 'Details', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                _VCPanelTabButton(label: 'Activity Log', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
              ],
            ),
          ),
          // Body
          Expanded(
            child: _tab == 0
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary cards
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.alertTriangle, size: 20, color: AppTheme.warningOrange),
                                        const SizedBox(height: 12),
                                        const Text('Outstanding Payables', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                        const SizedBox(height: 10),
                                        const Text('â‚¹0.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                      ],
                                    ),
                                  ),
                                ),
                                const VerticalDivider(width: 1, color: AppTheme.borderLight),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.badgeDollarSign, size: 20, color: AppTheme.successGreen),
                                        const SizedBox(height: 12),
                                        const Text('Unused Credits', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                        const SizedBox(height: 10),
                                        const Text('â‚¹0.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Contact details card
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Contact Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                              ),
                              const Divider(height: 1, color: AppTheme.borderLight),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _VCPanelDetailRow(label: 'Vendor Type', value: v.customerType ?? 'Individual'),
                                    const SizedBox(height: 14),
                                    const _VCPanelDetailRow(label: 'Currency', value: 'INR'),
                                    const SizedBox(height: 14),
                                    const _VCPanelDetailRow(label: 'Credit Limit', value: 'â‚¹0.00'),
                                    const SizedBox(height: 14),
                                    const _VCPanelDetailRow(label: 'Payment Terms', value: 'â€”'),
                                    const SizedBox(height: 14),
                                    _VCPanelDetailRow(label: 'GST Treatment', value: _gstTreatmentLabel),
                                    const SizedBox(height: 14),
                                    _VCPanelDetailRow(label: 'Place of Supply', value: v.placeOfSupply ?? 'â€”'),
                                    const SizedBox(height: 14),
                                    const _VCPanelDetailRow(label: 'Tax Preference', value: 'Taxable'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Contact Persons tile
                        _VCPanelActionTile(
                          label: 'Contact Persons',
                          count: 1,
                          expanded: _showContactPersons,
                          onTap: () => setState(() => _showContactPersons = !_showContactPersons),
                        ),
                        if (_showContactPersons) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderLight),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                _VCPanelDetailRow(label: 'Name', value: v.displayName),
                                const SizedBox(height: 10),
                                _VCPanelDetailRow(label: 'Phone', value: v.phone ?? v.mobilePhone ?? 'â€”'),
                                const SizedBox(height: 10),
                                _VCPanelDetailRow(label: 'Email', value: v.email ?? 'â€”'),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Address tile
                        _VCPanelActionTile(
                          label: 'Address',
                          expanded: _showAddress,
                          onTap: () => setState(() => _showAddress = !_showAddress),
                        ),
                        if (_showAddress) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderLight),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('BILLING ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                                const SizedBox(height: 8),
                                Text(v.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                const SizedBox(height: 4),
                                if ((v.billingAddressStreet1 ?? '').isNotEmpty)
                                  Text(v.billingAddressStreet1!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                if ((v.billingAddressCity ?? '').isNotEmpty)
                                  Text(v.billingAddressCity!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                if ((v.billingAddressPhone ?? '').isNotEmpty)
                                  Text('Phone: ${v.billingAddressPhone}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const Center(
                    child: Text('No activity log available.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Address Picker Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VCAddressPickerRow extends StatefulWidget {
  final Map<String, dynamic> address;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback? onEdit;

  const _VCAddressPickerRow({
    required this.address,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
  });

  @override
  State<_VCAddressPickerRow> createState() => _VCAddressPickerRowState();
}

class _VCAddressPickerRowState extends State<_VCAddressPickerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lines = widget.address['lines'] as List<String>? ?? const <String>[];
    final bgColor = _hovered
        ? AppTheme.primaryBlue
        : widget.isSelected
            ? AppTheme.bgDisabled
            : AppTheme.backgroundColor;
    final titleColor = _hovered ? Colors.white : AppTheme.textPrimary;
    final detailColor = _hovered ? Colors.white.withValues(alpha: 0.82) : AppTheme.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.address['name'] as String? ?? '',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: titleColor),
                    ),
                    const SizedBox(height: 4),
                    ...lines.map((line) => Text(line, style: TextStyle(fontSize: 12, color: detailColor))),
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
                      color: _hovered ? Colors.white : AppTheme.primaryBlue,
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

// â”€â”€â”€ New Address Action â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VCNewAddressAction extends StatefulWidget {
  final VoidCallback onTap;
  const _VCNewAddressAction({required this.onTap});

  @override
  State<_VCNewAddressAction> createState() => _VCNewAddressActionState();
}

class _VCNewAddressActionState extends State<_VCNewAddressAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = _hovered ? Colors.white : AppTheme.primaryBlue;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.plus, size: 14, color: fgColor),
              const SizedBox(width: 8),
              Text('Add New Address', style: TextStyle(fontSize: 13, color: fgColor, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Address Edit Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VCAddressEditDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> address;
  final String title;
  final bool isNewAddress;

  const _VCAddressEditDialog({
    required this.address,
    required this.title,
    this.isNewAddress = false,
  });

  @override
  ConsumerState<_VCAddressEditDialog> createState() => _VCAddressEditDialogState();
}

class _VCAddressEditDialogState extends ConsumerState<_VCAddressEditDialog> {
  late final TextEditingController _attentionCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _street2Ctrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _faxCtrl;
  String? _country;
  String? _state;

  static const List<String> _countries = ['India', 'United States', 'United Kingdom', 'UAE'];

  @override
  void initState() {
    super.initState();
    final lines = widget.address['lines'] as List<String>? ?? [];
    _attentionCtrl = TextEditingController(text: widget.address['name'] as String? ?? '');
    _addressCtrl   = TextEditingController(text: lines.isNotEmpty ? lines[0] : '');
    _street2Ctrl   = TextEditingController(text: lines.length > 1 ? lines[1] : '');
    _cityCtrl      = TextEditingController(text: lines.length > 2 ? lines[2] : '');
    _pinCtrl       = TextEditingController(text: lines.length > 3 ? lines[3].replaceAll(RegExp(r'[^0-9]'), '') : '');
    _phoneCtrl     = TextEditingController(text: lines.length > 4 ? lines[4].replaceAll(RegExp(r'[^0-9]'), '') : '');
    _faxCtrl       = TextEditingController();
    _country       = widget.isNewAddress ? null : 'India';
    _state         = widget.isNewAddress ? null : 'Kerala';
  }

  @override
  void dispose() {
    for (final c in [_attentionCtrl, _addressCtrl, _street2Ctrl, _cityCtrl, _pinCtrl, _phoneCtrl, _faxCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildResult() {
    final lines = <String>[];
    if (_addressCtrl.text.trim().isNotEmpty) lines.add(_addressCtrl.text.trim());
    if (_street2Ctrl.text.trim().isNotEmpty) lines.add(_street2Ctrl.text.trim());
    if (_cityCtrl.text.trim().isNotEmpty) lines.add(_cityCtrl.text.trim());
    if (_pinCtrl.text.trim().isNotEmpty) lines.add(_pinCtrl.text.trim());
    if (_phoneCtrl.text.trim().isNotEmpty) lines.add('Phone: ${_phoneCtrl.text.trim()}');
    return {'name': _attentionCtrl.text.trim(), 'lines': lines};
  }

  @override
  Widget build(BuildContext context) {
    final noteText = widget.isNewAddress
        ? 'This address will be added for this vendor.'
        : 'Changes made here will be updated for this vendor.';

    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(left: 80, right: 80, top: 0, bottom: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryBlue, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
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
                      onChanged: (v) => setState(() => _country = v),
                    ),
                    const SizedBox(height: 16),
                    _label('Address'),
                    const SizedBox(height: 6),
                    CustomTextField(controller: _addressCtrl, maxLines: 3, hintText: 'Street / Area'),
                    const SizedBox(height: 8),
                    CustomTextField(controller: _street2Ctrl, maxLines: 3, hintText: 'Street 2'),
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
                                items: ref.watch(statesProvider('IN')).value?.map((s) => s['name'] ?? '').where((n) => n.isNotEmpty).toList() ?? [],
                                hint: 'Select state',
                                onChanged: (v) => setState(() => _state = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _field('Pin Code', _pinCtrl, keyboardType: TextInputType.number)),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.borderLight),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text('+91', style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                                        SizedBox(width: 4),
                                        Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
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
                        Expanded(child: _field('Fax Number', _faxCtrl, keyboardType: TextInputType.phone)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(text: 'Note: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          TextSpan(text: noteText, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.borderLight))),
              child: Row(
                children: [
                  ZButton.primary(label: 'Save', onPressed: () => Navigator.pop(context, _buildResult())),
                  const SizedBox(width: 10),
                  ZButton.secondary(label: 'Cancel', onPressed: () => Navigator.pop(context)),
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
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
      );

  Widget _field(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text}) {
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

class _VCTaxOption {
  final String label;
  final String? description;
  final bool isHeader;
  final double rate;

  const _VCTaxOption({
    required this.label,
    this.description,
    this.isHeader = false,
    this.rate = 0,
  });
}


// ---------------------------------------------------------------------------
// Preferences dialog
// ---------------------------------------------------------------------------

class _VCPreferencesDialog extends StatefulWidget {
  const _VCPreferencesDialog({
    required this.prefix,
    required this.nextNumber,
    required this.autoGenerate,
    required this.onSave,
  });

  final String prefix;
  final String nextNumber;
  final bool autoGenerate;
  final void Function(String prefix, String nextNumber, bool autoGenerate)
  onSave;

  @override
  State<_VCPreferencesDialog> createState() => _VCPreferencesDialogState();
}

class _VCPreferencesDialogState extends State<_VCPreferencesDialog> {
  late final TextEditingController _prefix;
  late final TextEditingController _nextNumber;
  late bool _autoGenerate;

  @override
  void initState() {
    super.initState();
    _prefix = TextEditingController(text: widget.prefix);
    _nextNumber = TextEditingController(text: widget.nextNumber);
    _autoGenerate = widget.autoGenerate;
  }

  @override
  void dispose() {
    _prefix.dispose();
    _nextNumber.dispose();
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Configure Vendor Credit Number Preferences',
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Associated Series',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Default Transaction Series',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Your vendor credit numbers are set on auto-generate mode to save your time. Are you sure about changing this setting?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textBody,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Radio<bool>(
                        value: true,
                        groupValue: _autoGenerate,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (val) =>
                            setState(() => _autoGenerate = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Continue auto-generating vendor credit numbers',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (_autoGenerate) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Prefix',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      CustomTextField(
                                        controller: _prefix,
                                        height: 32,
                                        hintText: 'VC-',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Next Number',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      CustomTextField(
                                        controller: _nextNumber,
                                        height: 32,
                                        hintText: '00001',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Radio<bool>(
                        value: false,
                        groupValue: _autoGenerate,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (val) =>
                            setState(() => _autoGenerate = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Enter vendor credit numbers manually',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    ZButton.primary(
                      label: 'Save',
                      onPressed: () {
                        widget.onSave(
                          _prefix.text,
                          _nextNumber.text,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row three-dots menu hover item
// ---------------------------------------------------------------------------

class _VCRowMenuHoverItem extends StatefulWidget {
  final String label;
  final IconData? icon;
  const _VCRowMenuHoverItem({required this.label, this.icon});

  @override
  State<_VCRowMenuHoverItem> createState() => _VCRowMenuHoverItemState();
}

class _VCRowMenuHoverItemState extends State<_VCRowMenuHoverItem> {
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

// ---------------------------------------------------------------------------
// Product dropdown item widget
// ---------------------------------------------------------------------------

class _VCProductDropdownItem extends StatelessWidget {
  final String productName;
  final String itemCode;
  final bool highlighted;

  const _VCProductDropdownItem({
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

// ---------------------------------------------------------------------------
// Reporting tags popover
// ---------------------------------------------------------------------------

class _VCReportingTagsPopoverButton extends StatefulWidget {
  const _VCReportingTagsPopoverButton({
    required this.item,
    required this.onChanged,
  });
  final _VCLineItem item;
  final VoidCallback onChanged;

  @override
  State<_VCReportingTagsPopoverButton> createState() =>
      _VCReportingTagsPopoverButtonState();
}

class _VCReportingTagsPopoverButtonState
    extends State<_VCReportingTagsPopoverButton> {
  static const Map<String, List<String>> _tagGroups = {
    'ADGF': ['Budget', 'Actual', 'Forecast'],
    'Schedule': ['Monthly', 'Quarterly', 'Annual'],
    'Demo Advanced Reporting Tag': ['Value A', 'Value B', 'Value C'],
  };

  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();

  void _toggle() => _entry != null ? _close() : _open();

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _open() {
    final tempValues = Map<String, String?>.from(widget.item.selectedTagValues);

    _entry = OverlayEntry(
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setOverlayState) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  widget.item.selectedTagValues = tempValues;
                  widget.onChanged();
                  _close();
                },
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
                child: Container(
                  width: 320,
                  constraints: const BoxConstraints(maxHeight: 360),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
                        child: Text(
                          'Reporting Tags',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _tagGroups.entries.map((group) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  10,
                                  12,
                                  6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: group.value.map((tag) {
                                        final selected =
                                            tempValues[group.key] == tag;
                                        return GestureDetector(
                                          onTap: () => setOverlayState(() {
                                            tempValues[group.key] = selected
                                                ? null
                                                : tag;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? AppTheme.primaryBlue
                                                  : AppTheme.bgDisabled,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tag,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: selected
                                                    ? Colors.white
                                                    : AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _close,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ZButton.primary(
                              label: 'Apply',
                              onPressed: () {
                                widget.item.selectedTagValues = tempValues;
                                widget.onChanged();
                                _close();
                              },
                            ),
                          ],
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
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  int get _selectedCount =>
      widget.item.selectedTagValues.values.where((v) => v != null).length;

  @override
  Widget build(BuildContext context) {
    final isOpen = _entry != null;
    final count = _selectedCount;
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isOpen ? AppTheme.primaryBlue : AppTheme.borderLight,
              width: isOpen ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.tag,
                size: 13,
                color: isOpen ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                count > 0 ? 'Reporting Tags ($count)' : 'Reporting Tags',
                style: TextStyle(
                  fontSize: 12,
                  color: count > 0
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: isOpen ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table column header
// ---------------------------------------------------------------------------

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

// â”€â”€ Vendor dropdown item â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VcVendorDropdownItem extends StatelessWidget {
  final String name;
  final String code;
  final String subtitle;
  final bool highlighted;

  const _VcVendorDropdownItem({
    required this.name,
    required this.code,
    required this.subtitle,
    required this.highlighted,
  });

  String get _initial {
    final t = name.trim();
    return t.isEmpty ? '?' : t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        highlighted ? AppTheme.backgroundColor : AppTheme.textBody;
    final secondaryColor =
        highlighted ? AppTheme.backgroundColor : AppTheme.textSecondary;

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
          // Avatar circle
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
                // Name | Code row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (code.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('|',
                            style: TextStyle(
                                fontSize: 14, color: secondaryColor)),
                      ),
                      Text(
                        code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LucideIcons.building2,
                          size: 14, color: secondaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          subtitle,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VCPanelActionTile extends StatelessWidget {
  final String label;
  final int? count;
  final bool expanded;
  final VoidCallback onTap;

  const _VCPanelActionTile({
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
