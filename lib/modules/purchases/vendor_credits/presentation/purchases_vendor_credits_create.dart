// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart'
    as acct_model;
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/purchases/vendor_credits/providers/vendor_credits_tax_provider.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:zerpai_erp/modules/purchases/bills/providers/purchases_bills_provider.dart';
import 'package:zerpai_erp/shared/models/account_node.dart' as shared_acct;
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/pages/purchases_vendors_vendor_create.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/sales_item_quick_edit_dialog.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/manage_tds_tcs_rates_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/advanced_vendor_search_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_calendar.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/warehouse_popover.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
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

class _VendorCreditsCreatePageState
    extends ConsumerState<VendorCreditsCreatePage> {
  static const double _tableFieldHeight = 44;
  static const double _labelWidth = 150.0;
  static const double _rowMaxWidth = 1400.0;
  static const double _gapWidth = 16.0;
  static const double _vendorFieldWidth = 500.0;
  static const double _fieldWidth = _rowMaxWidth - _labelWidth - _gapWidth;
  static const double _fieldHeight = 32.0;

  // --- Form State ---
  Vendor? _selectedVendorObj;
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
  final LayerLink _vcDateLayerLink = LayerLink();
  OverlayEntry? _vcDateOverlay;
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
  double _selectedTaxRateValue = 0.0;
  List<Map<String, dynamic>> _tdsRatesList = [];
  List<Map<String, dynamic>> _tdsSectionsList = [];
  List<Map<String, dynamic>> _tcsRatesList = [];
  List<Map<String, dynamic>> _tcsNaturesList = [];
  bool _isLoadingTdsRates = false;
  Future<void>? _loadTdsFuture;
  String? _persistedVendorCreditId;
  final Map<String, Map<String, dynamic>> _persistedAttachmentCache = {};

  final List<_VCLineItem> _items = [];

  // --- Total Tax Amount popover ---
  final LayerLink _totalTaxLayerLink = LayerLink();
  OverlayEntry? _totalTaxOverlay;
  Map<String, double> _taxOverrides = {};

  // --- Manage TDS/TCS popover ---
  OverlayEntry? _manageTaxOverlay;
  bool _didAttemptExistingVendorCreditLoad = false;

  @override
  void initState() {
    super.initState();
    _persistedVendorCreditId = widget.vendorCreditId;
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vendorCreditId = widget.vendorCreditId?.trim();
      if ((vendorCreditId == null || vendorCreditId.isEmpty) &&
          _vcAutoGenerate) {
        await _syncVendorCreditNumberFromDb();
      }
      try {
        await ref.read(vendorProvider.notifier).loadVendors();
      } catch (_) {}
      try {
        await ref.read(billsProvider.notifier).loadBills();
      } catch (_) {}
      if (vendorCreditId != null &&
          vendorCreditId.isNotEmpty &&
          !_didAttemptExistingVendorCreditLoad) {
        _didAttemptExistingVendorCreditLoad = true;
        await _loadExistingVendorCredit(vendorCreditId);
      }
      try {
        await ref.read(itemsControllerProvider.notifier).loadLookupData();
      } catch (_) {}
      await _loadTdsRates();
    });
  }

  int _extractVendorCreditSequence(String number, String prefix) {
    final trimmedNumber = number.trim();
    final trimmedPrefix = prefix.trim();
    if (trimmedNumber.isEmpty || trimmedPrefix.isEmpty) return -1;
    if (!trimmedNumber.startsWith(trimmedPrefix)) return -1;
    final suffix = trimmedNumber.substring(trimmedPrefix.length).trim();
    if (suffix.isEmpty) return -1;
    return int.tryParse(suffix) ?? -1;
  }

  Future<void> _syncVendorCreditNumberFromDb() async {
    if (!_vcAutoGenerate) return;
    final entityId = ref.read(entityProvider).entityId;
    if (entityId == null || entityId.isEmpty) return;

    final prefix = _vcPrefixController.text.trim().isEmpty
        ? 'VC-'
        : _vcPrefixController.text.trim();
    final rows = await Supabase.instance.client
        .from('vendor_credits')
        .select('vendor_credit_number')
        .eq('entity_id', entityId)
        .order('created_at', ascending: false);

    var maxSequence = 0;
    for (final raw in rows as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final sequence = _extractVendorCreditSequence(
        row['vendor_credit_number']?.toString() ?? '',
        prefix,
      );
      if (sequence > maxSequence) {
        maxSequence = sequence;
      }
    }

    final nextSequence = maxSequence + 1;
    final nextNumber = nextSequence.toString().padLeft(5, '0');
    if (!mounted) return;
    setState(() {
      _vcNextNumberController.text = nextNumber;
      _vcNumberController.text = '$prefix$nextNumber';
    });
  }

  Future<void> _ensureVendorCreditNumberIsUnique({
    required String entityId,
    required String vendorCreditNumber,
  }) async {
    final normalizedNumber = vendorCreditNumber.trim();
    if (normalizedNumber.isEmpty) {
      throw Exception('Vendor credit number is required.');
    }

    final currentId = _persistedVendorCreditId?.trim();
    final existingRows = await Supabase.instance.client
        .from('vendor_credits')
        .select('id')
        .eq('entity_id', entityId)
        .eq('vendor_credit_number', normalizedNumber)
        .limit(10);

    for (final raw in existingRows as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final existingId = row['id']?.toString().trim() ?? '';
      if (existingId.isEmpty) continue;
      if (currentId != null && currentId.isNotEmpty && existingId == currentId) {
        continue;
      }
      throw Exception(
        'Vendor credit number $normalizedNumber already exists.',
      );
    }
  }

  @override
  void dispose() {
    _vcDateOverlay?.remove();
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

  static List<_VCTaxOption> _buildTaxOptions({
    required bool isKeralaIntraState,
    required List<TaxGroupItem> taxGroups,
    required List<TaxRateItem> igstRates,
  }) {
    final taxableOptions = isKeralaIntraState
        ? taxGroups
              .map(
                (g) => _VCTaxOption(
                  label: g.name,
                  description: '[${TaxGroupItem.fmtRate(g.rate)}%]',
                  rate: g.rate,
                ),
              )
              .toList(growable: false)
        : igstRates
              .map(
                (r) => _VCTaxOption(
                  label: r.name,
                  description: '[${TaxGroupItem.fmtRate(r.rate)}%]',
                  rate: r.rate,
                ),
              )
              .toList(growable: false);

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
      ...taxableOptions,
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
                id: a.id,
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

  void _applySelectedVendor(Vendor? vendor) {
    setState(() {
      _selectedVendorObj = vendor;
      _clearItemTaxes();
      if (vendor == null) {
        _selectedSourceOfSupply = null;
        _selectedDestinationOfSupply = null;
        _selectedBill = null;
      } else {
        _selectedSourceOfSupply = _vendorSourceOfSupply(vendor);
        _selectedDestinationOfSupply = null;
        _selectedBill = null;
      }
    });
  }

  Future<void> _showAdvancedVendorSearchDialog(List<Vendor> vendors) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      builder: (_) => AdvancedVendorSearchDialog(
        vendors: vendors,
        onSelect: _applySelectedVendor,
      ),
    );
  }

  Future<void> _showNewVendorDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.only(
          top: 0,
          bottom: 24,
          left: 40,
          right: 40,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const PurchasesVendorsVendorCreateScreen(isDialog: true),
          ),
        ),
      ),
    );
    if (!mounted) return;
    ref.read(vendorProvider.notifier).loadVendors();
  }

  void _addItem() {
    setState(() => _items.add(_VCLineItem()));
  }

  void _clearItemTaxes() {
    for (final item in _items) {
      item.selectedTax = null;
      item.selectedTaxRate = null;
    }
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
    final fullItem =
        lineItem.sourceItem ??
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
              lineItem.rateController.text = updated.costPrice!.toStringAsFixed(
                2,
              );
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

  void _reorderItem(int fromIndex, int toIndex) {
    if (fromIndex == toIndex ||
        fromIndex < 0 ||
        toIndex < 0 ||
        fromIndex >= _items.length ||
        toIndex > _items.length) {
      return;
    }

    setState(() {
      if (fromIndex < toIndex) {
        toIndex -= 1;
      }
      final moved = _items.removeAt(fromIndex);
      _items.insert(toIndex, moved);
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
        productUnitPack: _resolveProductUnitPack(lineItem.sourceItem),
        warehouseName: _selectedWarehouse?.name ?? '',
        warehouseId: _selectedWarehouse?.id ?? '',
        totalQuantity: double.tryParse(lineItem.qtyController.text.trim()) ?? 1,
        savedBatchData: lineItem.savedBatches
            .map(
              (b) => {
                'binLocation': b.binLocation,
                'binId': b.binId,
                'batchId': b.batchId,
                'layerId': b.layerId,
                'batchRef': b.referenceController.text,
                'batchNo': b.batchNo,
                'unitPack': b.unitPack,
                'mrp': b.mrp,
                'prate': b.purchaseRate,
                'mfgBatch': b.mfrBatchController.text,
                'mfgDate': b.mfrDateController.text,
                'expDate': b.expiryDateController.text,
                'qtyOut': b.quantityController.text,
                'foc': b.focQuantity,
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
            b.binLocation = row['binLocation'] ?? '';
            b.binId = row['binId'] ?? '';
            b.batchId = row['batchId'] ?? '';
            b.layerId = row['layerId'] ?? '';
            b.referenceController.text = row['batchRef'] ?? '';
            b.batchNo = row['batchNo'] ?? '';
            b.unitPack = row['unitPack'] ?? '';
            b.mrp = row['mrp'] ?? '';
            b.purchaseRate = row['prate'] ?? '';
            b.mfrBatchController.text = row['mfgBatch'] ?? '';
            b.mfrDateController.text = row['mfgDate'] ?? '';
            b.expiryDateController.text = row['expDate'] ?? '';
            b.quantityController.text = row['qtyOut'] ?? '';
            b.focQuantity = row['foc'] ?? '';
            return b;
          })
          .toList(growable: false);
    });

    await _persistVendorCreditItemBatches(lineItem);
  }

  String? _asUuidOrNull(String? value) {
    final trimmed = value?.trim() ?? '';
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(trimmed) ? trimmed : null;
  }

  String? _toDbDate(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    try {
      return DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd-MM-yyyy').parseStrict(trimmed));
    } catch (_) {
      return null;
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  String _toDisplayDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    return DateFormat('dd-MM-yyyy').format(parsed);
  }

  Future<_VCTaxOption?> _loadSavedTaxOption(String? taxId) async {
    final normalizedTaxId = taxId?.trim() ?? '';
    if (normalizedTaxId.isEmpty) return null;

    final supabase = Supabase.instance.client;

    try {
      final groupRow = await supabase
          .from('tax_groups')
          .select('id, tax_group_name, tax_rate')
          .eq('id', normalizedTaxId)
          .maybeSingle();
      if (groupRow != null) {
        final row = Map<String, dynamic>.from(groupRow);
        return _VCTaxOption(
          label: row['tax_group_name']?.toString() ?? '',
          description:
              '[${TaxGroupItem.fmtRate(_toDouble(row['tax_rate']))}%]',
          rate: _toDouble(row['tax_rate']),
        );
      }
    } catch (_) {}

    try {
      final rateRow = await supabase
          .from('tax_rates')
          .select('id, tax_name, tax_rate')
          .eq('id', normalizedTaxId)
          .maybeSingle();
      if (rateRow != null) {
        final row = Map<String, dynamic>.from(rateRow);
        return _VCTaxOption(
          label: row['tax_name']?.toString() ?? '',
          description:
              '[${TaxGroupItem.fmtRate(_toDouble(row['tax_rate']))}%]',
          rate: _toDouble(row['tax_rate']),
        );
      }
    } catch (_) {}

    return null;
  }

  Future<Item?> _loadSavedItem(String? productId) async {
    final normalizedProductId = productId?.trim() ?? '';
    if (normalizedProductId.isEmpty) return null;

    final existing = ref
        .read(itemsControllerProvider)
        .items
        .cast<Item?>()
        .firstWhere(
          (item) => item?.id == normalizedProductId,
          orElse: () => null,
        );
    if (existing != null) {
      return existing;
    }

    return ref
        .read(itemsControllerProvider.notifier)
        .ensureItemLoaded(normalizedProductId);
  }

  Future<void> _loadExistingVendorCredit(String vendorCreditId) async {
    final entityId = ref.read(entityProvider).entityId;
    if (entityId == null || entityId.isEmpty) {
      return;
    }
    try {
      final supabase = Supabase.instance.client;
      final creditSelect =
          'id, vendor_id, warehouse_id, vendor_credit_number, '
          'vendor_credit_date, bill_id, reference_number, subject, notes, '
          'reverse_charge_applicable';
      Map<String, dynamic>? vendorCreditRow;

      try {
        final byId = await supabase
            .from('vendor_credits')
            .select(creditSelect)
            .eq('id', vendorCreditId)
            .eq('entity_id', entityId)
            .maybeSingle();
        if (byId != null) {
          vendorCreditRow = Map<String, dynamic>.from(byId);
        }
      } catch (_) {}

      if (vendorCreditRow == null) {
        final byNumber = await supabase
            .from('vendor_credits')
            .select(creditSelect)
            .eq('vendor_credit_number', vendorCreditId)
            .eq('entity_id', entityId)
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (byNumber != null) {
          vendorCreditRow = Map<String, dynamic>.from(byNumber);
        }
      }

      if (vendorCreditRow == null) {
        return;
      }

      final resolvedVendorCreditId = vendorCreditRow['id']?.toString() ?? '';
      if (resolvedVendorCreditId.isEmpty) {
        return;
      }

      final vendors = ref.read(vendorProvider).vendors;
      final vendorId = vendorCreditRow['vendor_id']?.toString() ?? '';
      final selectedVendor = vendors.cast<Vendor?>().firstWhere(
        (vendor) => vendor?.id == vendorId,
        orElse: () => null,
      );

      final warehouseId = vendorCreditRow['warehouse_id']?.toString();
      final warehouses = await ref.read(warehousesProvider.future);
      final selectedWarehouse = warehouses.cast<Warehouse?>().firstWhere(
        (warehouse) => warehouse?.id == warehouseId,
        orElse: () => null,
      );

      final selectedBillId = vendorCreditRow['bill_id']?.toString();
      final bills = ref.read(billsProvider).bills;
      final selectedBill = bills.cast<PurchasesBill?>().firstWhere(
        (bill) => bill?.id == selectedBillId,
        orElse: () => null,
      );

      if (!mounted) return;
      setState(() {
        _persistedVendorCreditId = resolvedVendorCreditId;
        _selectedVendorObj = selectedVendor;
        _selectedWarehouse = selectedWarehouse;
        _selectedBill = selectedBill?.id;
        _selectedSourceOfSupply =
            selectedBill?.sourceOfSupply ??
            selectedVendor?.sourceOfSupply ??
            _selectedSourceOfSupply;
        _selectedDestinationOfSupply =
            selectedBill?.destinationToSupply ?? _selectedDestinationOfSupply;
        _vcNumberController.text =
            vendorCreditRow!['vendor_credit_number']?.toString() ?? '';
        final vendorCreditDate = DateTime.tryParse(
          vendorCreditRow['vendor_credit_date']?.toString() ?? '',
        );
        if (vendorCreditDate != null) {
          _vcDate = vendorCreditDate;
          _vcDateController.text = DateFormat(
            'dd-MM-yyyy',
          ).format(vendorCreditDate);
        }
        _orderNumberController.text =
            vendorCreditRow['reference_number']?.toString() ?? '';
        _subjectController.text = vendorCreditRow['subject']?.toString() ?? '';
        _notesController.text = vendorCreditRow['notes']?.toString() ?? '';
        _isReverseCharge =
            vendorCreditRow['reverse_charge_applicable'] as bool? ?? false;
      });

      final itemRowsRaw = await supabase
          .from('vendor_credit_items')
          .select(
            'id, product_id, account_id, quantity, rate, discount_percent, '
            'discount_amount, tax_id, remarks',
          )
          .eq('vendor_credit_id', resolvedVendorCreditId)
          .order('created_at');
      final itemRows = (itemRowsRaw as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);

      final vendorCreditItemIds = itemRows
          .map((row) => row['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final batchRowsByItemId = <String, List<Map<String, dynamic>>>{};
      if (vendorCreditItemIds.isNotEmpty) {
        try {
          final batchRowsRaw = await supabase
              .from('vendor_credit_item_batches')
              .select(
                'vendor_credit_item_id, batch_id, layer_id, bin_id, quantity_out, '
                'foc_qty, unit_pack, mrp, purchase_rate, expiry_date, '
                'manufacture_date, manufacture_batch_no',
              )
              .inFilter('vendor_credit_item_id', vendorCreditItemIds);
          for (final raw in batchRowsRaw as List) {
            final row = Map<String, dynamic>.from(raw as Map);
            final itemId = row['vendor_credit_item_id']?.toString() ?? '';
            if (itemId.isEmpty) continue;
            batchRowsByItemId.putIfAbsent(itemId, () => []).add(row);
          }
        } catch (_) {}
      }

      final attachmentRows = <Map<String, dynamic>>[];
      try {
        final attachmentRowsRaw = await supabase
            .from('vendor_credits_attachments')
            .select(
              'file_name, original_file_name, file_path, file_size, file_type',
            )
            .eq('vendor_credits_id', resolvedVendorCreditId);
        attachmentRows.addAll(
          (attachmentRowsRaw as List)
              .map((row) => Map<String, dynamic>.from(row as Map)),
        );
      } catch (_) {}

      final hydratedItems = <_VCLineItem>[];
      for (final row in itemRows) {
        final lineItem = _VCLineItem();
        lineItem.dbItemId = row['id']?.toString();
        try {
          lineItem.sourceItem = await _loadSavedItem(
            row['product_id']?.toString(),
          );
        } catch (_) {}
        lineItem.selectedAccount = row['account_id']?.toString();

        final qty = _toDouble(row['quantity']);
        final rate = _toDouble(row['rate']);
        final discountPercent = _toDouble(row['discount_percent']);
        final discountAmount = _toDouble(row['discount_amount']);

        lineItem.qtyController.text = qty.toStringAsFixed(2);
        lineItem.rateController.text = rate.toStringAsFixed(2);
        lineItem.discountIsPercent = discountPercent > 0;
        lineItem.discountController.text =
            (discountPercent > 0 ? discountPercent : discountAmount)
                .toStringAsFixed(discountPercent > 0 ? 2 : 0);
        lineItem.descriptionController.text = row['remarks']?.toString() ?? '';

        try {
          final taxOption = await _loadSavedTaxOption(row['tax_id']?.toString());
          if (taxOption != null && taxOption.label.isNotEmpty) {
            lineItem.selectedTax = taxOption.label;
            lineItem.selectedTaxRate =
                taxOption.rate > 0 ? taxOption.rate : null;
          }
        } catch (_) {}

        final batchRows =
            batchRowsByItemId[lineItem.dbItemId ?? ''] ??
            const <Map<String, dynamic>>[];
        lineItem.savedBatches = batchRows.map((row) {
          final batch = _VCBatch();
          batch.binId = row['bin_id']?.toString() ?? '';
          batch.batchId = row['batch_id']?.toString() ?? '';
          batch.layerId = row['layer_id']?.toString() ?? '';
          batch.unitPack = row['unit_pack']?.toString() ?? '';
          batch.mrp = _toDouble(row['mrp']).toStringAsFixed(2);
          batch.purchaseRate =
              _toDouble(row['purchase_rate']).toStringAsFixed(2);
          batch.focQuantity = _toDouble(row['foc_qty']).toStringAsFixed(2);
          batch.quantityController.text =
              _toDouble(row['quantity_out']).toStringAsFixed(2);
          batch.mfrBatchController.text =
              row['manufacture_batch_no']?.toString() ?? '';
          batch.mfrDateController.text =
              _toDisplayDate(row['manufacture_date']);
          batch.expiryDateController.text = _toDisplayDate(row['expiry_date']);
          return batch;
        }).toList(growable: false);

        hydratedItems.add(lineItem);
      }

      if (hydratedItems.isEmpty) {
        hydratedItems.add(_VCLineItem());
      }

      final hydratedFiles = <PlatformFile>[];
      final hydratedAttachmentCache = <String, Map<String, dynamic>>{};
      for (final row in attachmentRows) {
        final name =
            (row['original_file_name']?.toString().trim().isNotEmpty ?? false)
            ? row['original_file_name']!.toString().trim()
            : row['file_name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final size = int.tryParse(row['file_size']?.toString() ?? '0') ?? 0;
        final file = PlatformFile(name: name, size: size);
        hydratedFiles.add(file);
        hydratedAttachmentCache[_attachmentCacheKey(file)] = row;
      }

      if (!mounted) return;
      setState(() {
        for (final item in _items) {
          item.dispose();
        }
        _items
          ..clear()
          ..addAll(hydratedItems);
        _attachedFiles = hydratedFiles;
        _persistedAttachmentCache
          ..clear()
          ..addAll(hydratedAttachmentCache);
      });
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to load vendor credit for edit: $e');
    }
  }

  String _attachmentCacheKey(PlatformFile file) {
    return '${file.name}__${file.size}__${file.extension ?? ''}';
  }

  Map<String, dynamic> _buildVendorCreditPayload({
    required String entityId,
    required String vendorId,
    required String status,
  }) {
    final prefix = _vcPrefixController.text.trim().isEmpty
        ? 'VC-'
        : _vcPrefixController.text.trim();
    final nextNumber = _vcNextNumberController.text.trim().isEmpty
        ? '00001'
        : _vcNextNumberController.text.trim();
    final resolvedVendorCreditNumber = _vcNumberController.text.trim().isEmpty
        ? '$prefix$nextNumber'
        : _vcNumberController.text.trim();
    final payload = <String, dynamic>{
      'entity_id': entityId,
      'vendor_id': vendorId,
      'warehouse_id': _selectedWarehouse?.id,
      'vendor_credit_number': resolvedVendorCreditNumber,
      'vendor_credit_date': DateFormat('yyyy-MM-dd').format(_vcDate),
      'source_type': _selectedBill != null ? 'BILL' : 'DIRECT',
      'bill_id': _asUuidOrNull(_selectedBill),
      'reference_number': _orderNumberController.text.trim().isEmpty
          ? null
          : _orderNumberController.text.trim(),
      'subject': _subjectController.text.trim().isEmpty
          ? null
          : _subjectController.text.trim(),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'reverse_charge_applicable': _isReverseCharge,
      'subtotal': _subTotal,
      'discount_amount': _txnDiscountAmount,
      'tax_amount': _taxSummaryAmount,
      'adjustment_amount': _adjustmentAmount,
      'total_amount': _grandTotal,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (status.toLowerCase() == 'approved') {
      payload['approved_by'] = Supabase.instance.client.auth.currentUser?.id;
      payload['approved_at'] = DateTime.now().toIso8601String();
    }
    return payload;
  }

  Future<void> _insertVendorCreditAttachmentRows({
    required SupabaseClient supabase,
    required String vendorCreditId,
    required List<Map<String, dynamic>> files,
  }) async {
    if (files.isEmpty) return;

    final entityId = ref.read(entityProvider).entityId;
    final uploadedBy = supabase.auth.currentUser?.id;
    const attachmentForeignKey = 'vendor_credits_id';
    final variants = <List<Map<String, dynamic>>>[
      files
          .map(
            (file) => <String, dynamic>{
              attachmentForeignKey: vendorCreditId,
              'file_name': file['file_name'],
              'file_path': file['file_path'],
              'original_file_name': file['original_file_name'],
              'file_size': file['file_size'],
              'file_type': file['file_type'],
              'remarks': file['remarks'],
            },
          )
          .toList(growable: false),
      files
          .map(
            (file) => <String, dynamic>{
              attachmentForeignKey: vendorCreditId,
              'file_name': file['file_name'],
              'file_url': file['file_path'],
              'original_file_name': file['original_file_name'],
              'file_size': file['file_size'],
              'file_type': file['file_type'],
              'remarks': file['remarks'],
            },
          )
          .toList(growable: false),
      files
          .map(
            (file) => <String, dynamic>{
              attachmentForeignKey: vendorCreditId,
              'entity_id': entityId,
              'uploaded_by': uploadedBy,
              'file_name': file['file_name'],
              'file_path': file['file_path'],
              'original_file_name': file['original_file_name'],
              'file_size': file['file_size'],
              'file_type': file['file_type'],
              'remarks': file['remarks'],
            },
          )
          .toList(growable: false),
      files
          .map(
            (file) => <String, dynamic>{
              attachmentForeignKey: vendorCreditId,
              'entity_id': entityId,
              'uploaded_by': uploadedBy,
              'file_name': file['file_name'],
              'file_url': file['file_path'],
              'original_file_name': file['original_file_name'],
              'file_size': file['file_size'],
              'file_type': file['file_type'],
              'remarks': file['remarks'],
            },
          )
          .toList(growable: false),
    ];

    Object? lastError;
    for (final payload in variants) {
      try {
        await supabase.from('vendor_credits_attachments').insert(payload);
        return;
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? Exception('Failed to save vendor credit attachments.');
  }

  Future<void> _persistVendorCreditAttachments(String vendorCreditId) async {
    final supabase = Supabase.instance.client;
    final storage = StorageService();
    final rows = <Map<String, dynamic>>[];

    for (final file in _attachedFiles) {
      final cacheKey = _attachmentCacheKey(file);
      final cached = _persistedAttachmentCache[cacheKey];
      String? filePath = cached?['file_path']?.toString();

      if (filePath == null || filePath.isEmpty) {
        final uploaded = await storage.uploadPaymentAttachment(file);
        if (uploaded == null || uploaded.isEmpty) {
          throw Exception('Failed to upload attachment: ${file.name}');
        }
        filePath = uploaded;
      }

      final row = <String, dynamic>{
        'file_name': file.name,
        'file_path': filePath,
        'original_file_name': file.name,
        'file_size': file.size,
        'file_type': file.extension?.toLowerCase(),
        'remarks': null,
      };
      rows.add(row);
      _persistedAttachmentCache[cacheKey] = row;
    }

    final currentKeys = _attachedFiles.map(_attachmentCacheKey).toSet();
    _persistedAttachmentCache.removeWhere(
      (key, _) => !currentKeys.contains(key),
    );

    await supabase
        .from('vendor_credits_attachments')
        .delete()
        .eq('vendor_credits_id', vendorCreditId);

    await _insertVendorCreditAttachmentRows(
      supabase: supabase,
      vendorCreditId: vendorCreditId,
      files: rows,
    );
  }

  Future<void> _saveVendorCredit({
    required String status,
    required String successMessage,
    String? redirectRoute,
  }) async {
    try {
      final vendorCreditId = await _ensureVendorCreditDraftId(status: status);
      await _persistVendorCreditItems(vendorCreditId);
      await _persistVendorCreditAttachments(vendorCreditId);
      if (!mounted) return;
      ZerpaiToast.success(context, successMessage);
      if (redirectRoute != null && redirectRoute.isNotEmpty) {
        context.go(redirectRoute);
      }
    } catch (e) {
      if (!mounted) return;
      final actionLabel = status.toLowerCase() == 'approved'
          ? 'save and approve'
          : 'save draft';
      ZerpaiToast.error(context, 'Failed to $actionLabel: $e');
    }
  }

  Future<void> _handleSaveDraft() async {
    await _saveVendorCredit(
      status: 'draft',
      successMessage: 'Vendor credit draft saved successfully',
    );
  }

  Future<void> _handleSaveAsOpen() async {
    await _saveVendorCredit(
      status: 'open',
      successMessage: 'Vendor credit saved successfully',
      redirectRoute: AppRoutes.vendorCreditsReport,
    );
  }

  Future<String> _ensureVendorCreditDraftId({String status = 'draft'}) async {
    final entityId = ref.read(entityProvider).entityId;
    final vendorId = _selectedVendorObj?.id;
    if (entityId == null || entityId.isEmpty) {
      throw Exception('Entity is not selected.');
    }
    if (vendorId == null || vendorId.isEmpty) {
      throw Exception('Please select a vendor first.');
    }

    final supabase = Supabase.instance.client;
    if (_vcAutoGenerate) {
      await _syncVendorCreditNumberFromDb();
    }
    await _ensureVendorCreditNumberIsUnique(
      entityId: entityId,
      vendorCreditNumber: _vcNumberController.text.trim(),
    );
    final payload = _buildVendorCreditPayload(
      entityId: entityId,
      vendorId: vendorId,
      status: status,
    );

    if (_persistedVendorCreditId != null &&
        _persistedVendorCreditId!.isNotEmpty) {
      await supabase
          .from('vendor_credits')
          .update(payload)
          .eq('id', _persistedVendorCreditId!)
          .eq('entity_id', entityId);
      return _persistedVendorCreditId!;
    }

    final inserted = await supabase
        .from('vendor_credits')
        .insert({
          ...payload,
          'created_by': Supabase.instance.client.auth.currentUser?.id,
        })
        .select('id')
        .single();
    final id = inserted['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Failed to create vendor credit draft.');
    }
    _persistedVendorCreditId = id;
    return id;
  }

  double _lineTaxAmount(_VCLineItem item) {
    final taxRate =
        item.selectedTaxRate ?? _taxPercentFromLabel(item.selectedTax);
    if (taxRate <= 0) return 0;
    return _lineSubtotal(item) * taxRate / 100;
  }

  Future<String?> _resolveVendorCreditItemTaxId(_VCLineItem lineItem) async {
    final selectedTax = lineItem.selectedTax?.trim();
    if (selectedTax == null || selectedTax.isEmpty) {
      return null;
    }
    final taxRate =
        lineItem.selectedTaxRate ?? _taxPercentFromLabel(selectedTax);
    if (taxRate <= 0) {
      return null;
    }

    if (_isKeralaIntraStateSupply) {
      final taxGroups = await ref.read(taxGroupsProvider.future);
      for (final group in taxGroups) {
        if (group.name == selectedTax && group.rate == taxRate) {
          return group.id;
        }
      }
      return null;
    }

    final igstRates = await ref.read(igstTaxRatesProvider.future);
    for (final rate in igstRates) {
      if (rate.name == selectedTax && rate.rate == taxRate) {
        return rate.id;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _buildVendorCreditItemPayload({
    required String vendorCreditId,
    required _VCLineItem lineItem,
  }) async {
    final productId = lineItem.sourceItem?.id;
    if (productId == null || productId.isEmpty) {
      throw Exception('Please select an item first.');
    }

    final remarks = lineItem.descriptionController.text.trim();
    return <String, dynamic>{
      'vendor_credit_id': vendorCreditId,
      'product_id': productId,
      'account_id': _asUuidOrNull(lineItem.selectedAccount),
      'quantity': _parseMoney(lineItem.qtyController.text),
      'rate': _parseMoney(lineItem.rateController.text),
      'discount_percent': lineItem.discountIsPercent
          ? _parseMoney(lineItem.discountController.text)
          : 0,
      'discount_amount': lineItem.discountIsPercent
          ? 0
          : _parseMoney(lineItem.discountController.text),
      'tax_id': await _resolveVendorCreditItemTaxId(lineItem),
      'tax_amount': _lineTaxAmount(lineItem),
      'line_total': _lineSubtotal(lineItem),
      'remarks': remarks.isEmpty ? null : remarks,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<void> _persistVendorCreditItems(String vendorCreditId) async {
    final supabase = Supabase.instance.client;
    final activeItems = _items
        .where((item) => item.sourceItem?.id?.trim().isNotEmpty ?? false)
        .toList(growable: false);

    await supabase
        .from('vendor_credit_items')
        .delete()
        .eq('vendor_credit_id', vendorCreditId);

    for (final item in _items) {
      item.dbItemId = null;
    }

    for (final item in activeItems) {
      final payload = await _buildVendorCreditItemPayload(
        vendorCreditId: vendorCreditId,
        lineItem: item,
      );
      final inserted = await supabase
          .from('vendor_credit_items')
          .insert(payload)
          .select('id')
          .single();
      final itemId = inserted['id']?.toString();
      if (itemId == null || itemId.isEmpty) {
        throw Exception('Failed to save vendor credit item.');
      }
      item.dbItemId = itemId;
      await _persistVendorCreditItemBatches(item);
    }
  }

  Future<String> _ensureVendorCreditItemId(_VCLineItem lineItem) async {
    if (lineItem.dbItemId != null && lineItem.dbItemId!.isNotEmpty) {
      return lineItem.dbItemId!;
    }

    final vendorCreditId = await _ensureVendorCreditDraftId();
    final supabase = Supabase.instance.client;
    final payload = await _buildVendorCreditItemPayload(
      vendorCreditId: vendorCreditId,
      lineItem: lineItem,
    );

    final inserted = await supabase
        .from('vendor_credit_items')
        .insert(payload)
        .select('id')
        .single();
    final id = inserted['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Failed to create vendor credit item.');
    }
    lineItem.dbItemId = id;
    return id;
  }

  Future<void> _persistVendorCreditItemBatches(_VCLineItem lineItem) async {
    try {
      final validBatches = lineItem.savedBatches
          .where(
            (b) =>
                b.batchId.trim().isNotEmpty &&
                b.layerId.trim().isNotEmpty &&
                b.quantityController.text.trim().isNotEmpty,
          )
          .toList(growable: false);

      if (validBatches.isEmpty) {
        final existingItemId = lineItem.dbItemId;
        if (existingItemId != null && existingItemId.isNotEmpty) {
          await Supabase.instance.client
              .from('vendor_credit_item_batches')
              .delete()
              .eq('vendor_credit_item_id', existingItemId);
        }
        return;
      }

      final vendorCreditItemId = await _ensureVendorCreditItemId(lineItem);
      final warehouseId = _selectedWarehouse?.id;
      if (warehouseId == null || warehouseId.isEmpty) {
        throw Exception('Please select a warehouse first.');
      }

      final supabase = Supabase.instance.client;
      await supabase
          .from('vendor_credit_item_batches')
          .delete()
          .eq('vendor_credit_item_id', vendorCreditItemId);

      final rows = validBatches
          .map(
            (b) => <String, dynamic>{
              'vendor_credit_item_id': vendorCreditItemId,
              'batch_id': b.batchId.trim(),
              'layer_id': b.layerId.trim(),
              'warehouse_id': warehouseId,
              'bin_id': b.binId.trim().isEmpty ? null : b.binId.trim(),
              'quantity_out': _parseMoney(b.quantityController.text),
              'foc_qty': _parseMoney(b.focQuantity),
              'unit_pack': b.unitPack.trim().isEmpty ? null : b.unitPack.trim(),
              'mrp': _parseMoney(b.mrp),
              'purchase_rate': _parseMoney(b.purchaseRate),
              'expiry_date': _toDbDate(b.expiryDateController.text),
              'manufacture_date': _toDbDate(b.mfrDateController.text),
              'manufacture_batch_no': b.mfrBatchController.text.trim().isEmpty
                  ? null
                  : b.mfrBatchController.text.trim(),
            },
          )
          .toList(growable: false);

      if (rows.isNotEmpty) {
        await supabase.from('vendor_credit_item_batches').insert(rows);
      }
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to save batches: $e');
    }
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
              final wasAutoGenerate = _vcAutoGenerate;
              setState(() {
                _vcAutoGenerate = autoGenerate;
                _vcPrefixController.text = prefix;
                _vcNextNumberController.text = nextNumber;
                if (!_vcAutoGenerate) {
                  _vcNumberController.text = '$prefix$nextNumber';
                }
              });
              if (_vcAutoGenerate) {
                _syncVendorCreditNumberFromDb();
              } else if (wasAutoGenerate != _vcAutoGenerate) {
                setState(() {
                  _vcNumberController.text = '$prefix$nextNumber';
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickVCDate() async {
    if (_vcDateOverlay != null) {
      _closeVcDateOverlay();
      return;
    }

    _vcDateOverlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          ignoring: true,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _vcDateLayerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 6),
                child: IgnorePointer(
                  ignoring: false,
                  child: Material(
                    color: Colors.transparent,
                    child: ZerpaiCalendar(
                      selectedDate: _vcDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      onDateSelected: (date) {
                        setState(() {
                          _vcDate = date;
                          _vcDateController.text = DateFormat(
                            'dd-MM-yyyy',
                          ).format(date);
                        });
                        _closeVcDateOverlay();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_vcDateOverlay!);
    setState(() {});
  }

  void _closeVcDateOverlay() {
    _vcDateOverlay?.remove();
    _vcDateOverlay = null;
    if (mounted) setState(() {});
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
      final discountAmt = item.discountIsPercent ? gross * d / 100 : d;
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
  double get _selectedTdsTcsAmount => _subTotal * _selectedTaxRateValue / 100;
  double get _baseTotalBeforeTdsTcs =>
      _subTotal -
      _txnDiscountAmount +
      _shippingAmount +
      _taxSummaryAmount +
      _adjustmentAmount;

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

  bool _isKeralaPlace(String? value) {
    final normalized = value?.toLowerCase().trim() ?? '';
    if (normalized.isEmpty) return false;
    return normalized.contains('[kl]') || normalized.contains('kerala');
  }

  bool get _isKeralaIntraStateSupply {
    return _isKeralaPlace(_selectedSourceOfSupply) &&
        _isKeralaPlace(_selectedDestinationOfSupply);
  }

  bool get _isInterStateSupply {
    return !_isKeralaIntraStateSupply;
  }

  List<_VCTaxSummaryLine> get _taxSummaryLines {
    final taxableAmountsByRate = <double, double>{};
    for (final item in _items) {
      if (item.sourceItem == null) continue;
      final taxRate =
          item.selectedTaxRate ?? _taxPercentFromLabel(item.selectedTax);
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

  double get _grandTotal {
    final baseTotal = _baseTotalBeforeTdsTcs;
    if (_selectedTaxRateValue <= 0) {
      return baseTotal;
    }
    if (_taxType == 'TDS') {
      return baseTotal - _selectedTdsTcsAmount;
    }
    if (_taxType == 'TCS') {
      return baseTotal + _selectedTdsTcsAmount;
    }
    return baseTotal;
  }

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(vendorProvider);
    final billsState = ref.watch(billsProvider);
    final gstRegistrationTypesAsync = ref.watch(gstRegistrationTypesProvider);
    final gstTreatmentsAsync = ref.watch(gstTreatmentsProvider);
    final taxGroupsAsync = ref.watch(taxGroupsProvider);
    final igstTaxRatesAsync = ref.watch(igstTaxRatesProvider);
    final warehousesAsync = ref.watch(warehousesProvider);
    final warehouses = warehousesAsync.asData?.value ?? const <Warehouse>[];
    final billTypeOptions =
        gstRegistrationTypesAsync.asData?.value ??
        const <Map<String, String>>[];
    final gstTreatmentOptions =
        gstTreatmentsAsync.asData?.value ?? const <Map<String, String>>[];
    final vendorBills = _selectedVendorObj == null
        ? const <PurchasesBill>[]
        : billsState.bills
              .where((bill) => bill.vendorId == _selectedVendorObj!.id)
              .toList(growable: false);
    PurchasesBill? selectedBillRecord;
    if (_selectedBill != null) {
      for (final bill in vendorBills) {
        if (bill.id == _selectedBill) {
          selectedBillRecord = bill;
          break;
        }
      }
    }
    final accountTree = _buildAccountTree(
      ref.watch(chartOfAccountsProvider).roots,
    );
    final taxOptions = _buildTaxOptions(
      isKeralaIntraState: _isKeralaIntraStateSupply,
      taxGroups: taxGroupsAsync.asData?.value ?? const <TaxGroupItem>[],
      igstRates: igstTaxRatesAsync.asData?.value ?? const <TaxRateItem>[],
    );
    if (vendorState.isLoading && vendorState.vendors.isEmpty) {
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
                    ZButton.secondary(
                      label: 'Save as Draft',
                      onPressed: _handleSaveDraft,
                    ),
                    const SizedBox(width: 12),
                    ZButton.primary(
                      label: 'Save as Open',
                      onPressed: _handleSaveAsOpen,
                    ),
                    const SizedBox(width: 12),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: () => context.goNamed(AppRoutes.vendorCredits),
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
                                              final vendorState = ref.watch(
                                                vendorProvider,
                                              );
                                              return FormDropdown<Vendor>(
                                                value: _selectedVendorObj,
                                                items: vendorState.vendors,
                                                isLoading:
                                                    vendorState.isLoading,
                                                displayStringForValue: (c) =>
                                                    c.displayName,
                                                searchStringForValue: (c) =>
                                                    '${c.displayName} ${c.companyName ?? ''} ${c.vendorNumber ?? ''} ${c.gstin ?? ''}',
                                                hint: 'Select or add a vendor',
                                                height: _fieldHeight,
                                                menuMaxHeight: 320,
                                                itemHeight: 72,
                                                itemBuilder:
                                                    (
                                                      c,
                                                      isSelected,
                                                      isHovered,
                                                    ) => _VcVendorDropdownItem(
                                                      name: c.displayName,
                                                      code:
                                                          c.vendorNumber ?? '',
                                                      subtitle:
                                                          c.companyName ??
                                                          c.gstin ??
                                                          '',
                                                      isSelected: isSelected,
                                                      isHovered: isHovered,
                                                    ),
                                                showSettings: true,
                                                settingsLabel: 'New Vendor',
                                                settingsIcon: LucideIcons.plus,
                                                onSettingsTap:
                                                    _showNewVendorDialog,
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
                                                onChanged: _applySelectedVendor,
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
                                              final vendors = ref
                                                  .read(vendorProvider)
                                                  .vendors;
                                              if (vendors.isNotEmpty) {
                                                await _showAdvancedVendorSearchDialog(
                                                  vendors,
                                                );
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
                                            MediaQuery.of(context).size.width <
                                                    1000
                                                ? 16.0
                                                : 40.0,
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
                                vendor: _selectedVendorObj!,
                                labelWidth: _labelWidth,
                                gstTreatmentOptions: gstTreatmentOptions,
                              ),
                              // Source of Supply
                              _CompactFormRow(
                                label: 'Source of Supply',
                                required: true,
                                labelColor: AppTheme.errorRed,
                                fieldWidth: 330,
                                child: Builder(
                                  builder: (context) {
                                    final stateNames =
                                        ref
                                            .watch(statesProvider('IN'))
                                            .value
                                            ?.map((s) => s['name'] ?? '')
                                            .where((n) => n.isNotEmpty)
                                            .toList() ??
                                        [];
                                    return FormDropdown<String>(
                                      value: _selectedSourceOfSupply,
                                      items: stateNames,
                                      hint: 'Select Source of Supply',
                                      height: _fieldHeight,
                                      onChanged: (val) => setState(() {
                                        _selectedSourceOfSupply = val;
                                        _clearItemTaxes();
                                      }),
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
                                    final stateNames =
                                        ref
                                            .watch(statesProvider('IN'))
                                            .value
                                            ?.map((s) => s['name'] ?? '')
                                            .where((n) => n.isNotEmpty)
                                            .toList() ??
                                        [];
                                    return FormDropdown<String>(
                                      value: _selectedDestinationOfSupply,
                                      items: stateNames,
                                      hint: 'Select Destination of Supply',
                                      height: _fieldHeight,
                                      onChanged: (val) => setState(() {
                                        _selectedDestinationOfSupply = val;
                                        _clearItemTaxes();
                                      }),
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
                                      items: vendorBills
                                          .map((bill) => bill.id)
                                          .toList(growable: false),
                                      hint: _selectedVendorObj == null
                                          ? 'Select Vendor First'
                                          : 'Select Bill',
                                      enabled: _selectedVendorObj != null,
                                      isLoading:
                                          billsState.isLoading &&
                                          _selectedVendorObj != null,
                                      displayStringForValue: (billId) {
                                        for (final bill in vendorBills) {
                                          if (bill.id == billId) {
                                            final billNumber =
                                                bill.billNumber?.trim() ?? '';
                                            if (billNumber.isNotEmpty) {
                                              return billNumber;
                                            }
                                            final orderNumber =
                                                bill.orderNumber?.trim() ?? '';
                                            if (orderNumber.isNotEmpty) {
                                              return orderNumber;
                                            }
                                            return bill.id;
                                          }
                                        }
                                        return billId;
                                      },
                                      searchStringForValue: (billId) {
                                        for (final bill in vendorBills) {
                                          if (bill.id == billId) {
                                            return [
                                              bill.billNumber ?? '',
                                              bill.orderNumber ?? '',
                                              bill.vendorName,
                                            ].join(' ');
                                          }
                                        }
                                        return billId;
                                      },
                                      height: _fieldHeight,
                                      onChanged: (val) =>
                                          setState(() => _selectedBill = val),
                                    ),
                                    if (selectedBillRecord != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Bill Date: ${selectedBillRecord.billDate != null ? DateFormat('dd-MM-yyyy').format(selectedBillRecord.billDate!) : '-'}',
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
                                  items: billTypeOptions
                                      .map((item) => item['label'] ?? '')
                                      .where((label) => label.isNotEmpty)
                                      .toList(growable: false),
                                  hint: 'Select Bill Type',
                                  isLoading:
                                      gstRegistrationTypesAsync.isLoading &&
                                      billTypeOptions.isEmpty,
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
                      child: CompositedTransformTarget(
                        link: _vcDateLayerLink,
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
                      onReorderItem: _reorderItem,
                      onTotalsChanged: () => setState(() {}),
                      onAddBatches: _openBatchDialog,
                      warehouse: _selectedWarehouse?.name ?? '',
                      accountTree: accountTree,
                      taxOptions: taxOptions,
                      isReverseCharge: _isReverseCharge,
                      onViewItemDetails: _openItemDetails,
                      onViewItemDetailsTransactions: (item) =>
                          _openItemDetails(item, initialTab: 2),
                      onEditItem: _openEditItem,
                      defaultPriceList: _selectedPriceList,
                      priceListOptions: ref.watch(activePriceListsProvider),
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
                                if (_discountType ==
                                    'At Transaction Level') ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      4,
                                      20,
                                      4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                          onTap: () => setState(
                                            () => _txnDiscountIsPercent =
                                                !_txnDiscountIsPercent,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.bgDisabled,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: AppTheme.borderLight,
                                              ),
                                            ),
                                            child: Text(
                                              _txnDiscountIsPercent ? '%' : '₹',
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
                                if (_items.any(
                                  (i) => i.sourceItem != null,
                                )) ...[
                                  if (taxSummaryLines.isEmpty)
                                    const Divider(
                                      height: 1,
                                      color: AppTheme.borderLight,
                                    ),
                                  CompositedTransformTarget(
                                    link: _totalTaxLayerLink,
                                    child: Padding(
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
                                          const Text(
                                            'Total Tax Amount',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 150,
                                            height: 34,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: AppTheme.borderLight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                          ),
                                                      child: Text(
                                                        _formatMoney(
                                                          _taxSummaryAmount,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                        textAlign:
                                                            TextAlign.right,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    decoration:
                                                        const BoxDecoration(
                                                          border: Border(
                                                            left: BorderSide(
                                                              color: AppTheme
                                                                  .borderLight,
                                                            ),
                                                          ),
                                                        ),
                                                    child: const Text(
                                                      'INR',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => _showTotalTaxPopover(
                                              context,
                                              taxSummaryLines,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: AppTheme.primaryBlue,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Icon(
                                                LucideIcons.pencil,
                                                size: 13,
                                                color: AppTheme.primaryBlue,
                                              ),
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
    if (_taxType == 'TDS') {
      _showManageTdsRatesDialog();
      return;
    }
    if (_taxType == 'TCS') {
      _showManageTcsRatesDialog();
      return;
    }
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

    final accountTree = _buildAccountTree(
      ref.read(chartOfAccountsProvider).roots,
    );

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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppTheme.borderLight),
                              ),
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
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 18,
                                    color: AppTheme.textSecondary,
                                  ),
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
                                    showDialog<Map<String, dynamic>>(
                                      context: context,
                                      barrierColor: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      builder: (_) => Align(
                                        alignment: Alignment.topCenter,
                                        child: _VCNewTaxFormDialog(
                                          isTds: isTds,
                                          accountTree: accountTree,
                                          taxSections: isTds
                                              ? _tdsSectionsList
                                              : _tcsNaturesList,
                                        ),
                                      ),
                                    ).then((savedRate) {
                                      if (!mounted || savedRate == null) return;
                                      _applySavedTaxRate(
                                        isTds: isTds,
                                        savedRate: savedRate,
                                      );
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 9,
                            ),
                            decoration: const BoxDecoration(
                              color: AppTheme.tableHeaderBg,
                              border: Border(
                                top: BorderSide(color: AppTheme.borderLight),
                                bottom: BorderSide(color: AppTheme.borderLight),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'TAX NAME',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'RATE (%)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'NATURE OF COLLECTION',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'STATUS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Empty state
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                emptyLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
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

  Future<void> _loadTdsRates() async {
    if (_isLoadingTdsRates) {
      await _loadTdsFuture;
      return;
    }
    _isLoadingTdsRates = true;
    _loadTdsFuture = _performLoadTdsRates();
    await _loadTdsFuture;
    _isLoadingTdsRates = false;
  }

  Future<void> _performLoadTdsRates() async {
    try {
      final lookupsService = LookupsApiService();
      final rates = await lookupsService.getTdsRates();
      final sections = await lookupsService.getTdsSections();
      final tcsRates = await lookupsService.getTcsRates();
      final tcsNatures = await lookupsService.getTcsNatures();
      if (!mounted) return;
      setState(() {
        _tdsRatesList = rates;
        _tdsSectionsList = sections;
        _tcsRatesList = tcsRates;
        _tcsNaturesList = tcsNatures;
      });
    } catch (_) {}
  }

  void _applySavedTaxRate({
    required bool isTds,
    required Map<String, dynamic> savedRate,
  }) {
    final savedId = savedRate['id']?.toString();
    final savedName = savedRate['tax_name']?.toString();
    final savedValue =
        double.tryParse(
          (isTds ? savedRate['base_rate'] : savedRate['rate'])?.toString() ??
              '0',
        ) ??
        0.0;

    setState(() {
      final targetList = isTds ? _tdsRatesList : _tcsRatesList;
      final index = targetList.indexWhere(
        (row) =>
            (savedId != null && row['id']?.toString() == savedId) ||
            (savedName != null && row['tax_name']?.toString() == savedName),
      );

      if (index >= 0) {
        targetList[index] = savedRate;
      } else {
        targetList.add(savedRate);
      }

      _selectedTaxRate = savedId;
      _selectedTaxRateValue = savedValue;
    });
  }

  String _resolveProductUnitPack(Item? item) {
    if (item == null) return '';
    final lockedPack = item.lockUnitPack;
    if (lockedPack != null) {
      final whole = lockedPack.truncateToDouble();
      return lockedPack == whole
          ? whole.toInt().toString()
          : lockedPack.toString();
    }
    return item.unitPack?.trim() ?? '';
  }

  void _showManageTdsRatesDialog() async {
    if (_tdsRatesList.isEmpty) {
      await _loadTdsRates();
    }
    if (!mounted) return;
    final accountTree = _buildAccountTree(
      ref.read(chartOfAccountsProvider).roots,
    );
    await showDialog(
      context: context,
      builder: (context) => ManageTdsTcsRatesDialog(
        title: 'Manage TDS Rates',
        isTcs: false,
        items: _tdsRatesList,
        sections: _tdsSectionsList,
        showNewTaxMenu: false,
        showGroupAction: false,
        onNewTaxTap: () {
          Navigator.of(context).pop();
          showDialog<Map<String, dynamic>>(
            context: this.context,
            barrierColor: Colors.black.withValues(alpha: 0.35),
            builder: (_) => Align(
              alignment: Alignment.topCenter,
              child: _VCNewTaxFormDialog(
                isTds: true,
                accountTree: accountTree,
                taxSections: _tdsSectionsList,
              ),
            ),
          ).then((savedRate) {
            if (!mounted || savedRate == null) return;
            _applySavedTaxRate(isTds: true, savedRate: savedRate);
          });
        },
        selectedId: _selectedTaxRate,
        onSelect: (value) {
          setState(() {
            _selectedTaxRate = value['id']?.toString();
            _selectedTaxRateValue =
                double.tryParse(value['base_rate']?.toString() ?? '0') ?? 0.0;
          });
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncTdsRates(items);
          if (mounted) {
            setState(() => _tdsRatesList = updated);
          }
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }
          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'tds-rates',
              item['id'].toString(),
            );
            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This TDS rate is in use and cannot be deleted.';
            }
          } catch (_) {}
          return null;
        },
      ),
    );
    await _performLoadTdsRates();
  }

  void _showManageTcsRatesDialog() async {
    if (_tcsRatesList.isEmpty) {
      await _loadTdsRates();
    }
    if (!mounted) return;
    final accountTree = _buildAccountTree(
      ref.read(chartOfAccountsProvider).roots,
    );
    await showDialog(
      context: context,
      builder: (context) => ManageTdsTcsRatesDialog(
        title: 'Manage TCS Rates',
        isTcs: true,
        items: _tcsRatesList,
        sections: _tcsNaturesList,
        showNewTaxMenu: false,
        showGroupAction: false,
        onNewTaxTap: () {
          Navigator.of(context).pop();
          showDialog<Map<String, dynamic>>(
            context: this.context,
            barrierColor: Colors.black.withValues(alpha: 0.35),
            builder: (_) => Align(
              alignment: Alignment.topCenter,
              child: _VCNewTaxFormDialog(
                isTds: false,
                accountTree: accountTree,
                taxSections: _tcsNaturesList,
              ),
            ),
          ).then((savedRate) {
            if (!mounted || savedRate == null) return;
            _applySavedTaxRate(isTds: false, savedRate: savedRate);
          });
        },
        selectedId: _selectedTaxRate,
        onSelect: (value) {
          setState(() {
            _selectedTaxRate = value['id']?.toString();
            _selectedTaxRateValue =
                double.tryParse(value['rate']?.toString() ?? '0') ?? 0.0;
          });
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncTcsRates(items);
          if (mounted) {
            setState(() => _tcsRatesList = updated);
          }
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }
          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'tcs-rates',
              item['id'].toString(),
            );
            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This TCS rate is in use and cannot be deleted.';
            }
          } catch (_) {}
          return null;
        },
      ),
    );
    await _performLoadTdsRates();
  }

  void _showTotalTaxPopover(
    BuildContext context,
    List<_VCTaxSummaryLine> lines,
  ) {
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppTheme.borderLight),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Update Taxes Amount ( in INR )',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _totalTaxOverlay?.remove();
                                  _totalTaxOverlay = null;
                                  for (final c in controllers.values)
                                    c.dispose();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.primaryBlue,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 13,
                                    color: Colors.red,
                                  ),
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
                                        child: Text(
                                          line.label,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 100,
                                        height: 34,
                                        child: TextField(
                                          controller: controllers[line.label],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 9,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.borderLight,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.borderLight,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: AppTheme.primaryBlue,
                                              ),
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
                                  newOverrides[line.label] =
                                      double.tryParse(c.text.trim()) ??
                                      line.amount;
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
    final isTds = _taxType == 'TDS';
    final currentRates = isTds ? _tdsRatesList : _tcsRatesList;
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
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setState(() {
                    _taxType = val!;
                    _selectedTaxRate = null;
                    _selectedTaxRateValue = 0.0;
                  }),
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
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setState(() {
                    _taxType = val!;
                    _selectedTaxRate = null;
                    _selectedTaxRateValue = 0.0;
                  }),
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
              items: currentRates
                  .map((rate) => rate['id']?.toString() ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList(growable: false),
              hint: 'Select a Tax',
              height: 34,
              displayStringForValue: (id) {
                final match = currentRates
                    .cast<Map<String, dynamic>?>()
                    .firstWhere(
                      (rate) => rate?['id']?.toString() == id,
                      orElse: () => null,
                    );
                if (match == null) return 'Select a Tax';
                final taxName = (match['tax_name'] ?? match['tds_name'] ?? '')
                    .toString();
                final rawRate = isTds
                    ? match['base_rate']
                    : (match['rate'] ?? match['tds_rate']);
                final rateValue =
                    double.tryParse(rawRate?.toString() ?? '0') ?? 0.0;
                final rateText = rateValue == rateValue.roundToDouble()
                    ? rateValue.toStringAsFixed(0)
                    : rateValue.toStringAsFixed(2);
                return '$taxName [$rateText%]';
              },
              searchStringForValue: (id) {
                final match = currentRates
                    .cast<Map<String, dynamic>?>()
                    .firstWhere(
                      (rate) => rate?['id']?.toString() == id,
                      orElse: () => null,
                    );
                if (match == null) return '';
                return '${match['tax_name'] ?? match['tds_name'] ?? ''} '
                    '${match['base_rate'] ?? match['rate'] ?? ''}';
              },
              onChanged: (val) {
                final match = currentRates
                    .cast<Map<String, dynamic>?>()
                    .firstWhere(
                      (rate) => rate?['id']?.toString() == val,
                      orElse: () => null,
                    );
                setState(() {
                  _selectedTaxRate = val;
                  _selectedTaxRateValue = match == null
                      ? 0.0
                      : double.tryParse(
                              (isTds
                                          ? match['base_rate']
                                          : (match['rate'] ??
                                                match['tds_rate']))
                                      ?.toString() ??
                                  '0',
                            ) ??
                            0.0;
                });
              },
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
              _taxType == 'TDS'
                  ? '- ${_formatMoney(_selectedTdsTcsAmount)}'
                  : _formatMoney(_selectedTdsTcsAmount),
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

Map<String, dynamic>? _vendorBillingAddress(Vendor vendor) {
  final billing = vendor.billingAddress;
  if (billing != null && billing.isNotEmpty) return billing;

  final addresses = vendor.vendorAddresses ?? const <Map<String, dynamic>>[];
  for (final address in addresses) {
    final type = (address['address_type'] ?? address['addressType'])
        ?.toString()
        .toLowerCase();
    final isDefaultBilling =
        address['is_default_billing'] == true ||
        address['isDefaultBilling'] == true;
    if (isDefaultBilling || type == 'billing') {
      return address;
    }
  }
  return null;
}

String _vendorAddressValue(Map<String, dynamic>? address, String key) {
  if (address == null) return '';
  final value =
      address[key] ??
      address[_snakeCaseKey(key)] ??
      switch (key) {
        'street1' => address['addressStreet'] ?? address['address_street'],
        'street2' => address['addressPlace'] ?? address['address_place'],
        'zip' => address['pincode'],
        'country' => address['countryRegion'] ?? address['country_region'],
        _ => null,
      };
  return value?.toString().trim() ?? '';
}

String _snakeCaseKey(String value) {
  return value
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      )
      .replaceFirst(RegExp(r'^_'), '');
}

String _vendorSourceOfSupply(Vendor vendor) {
  final direct = vendor.sourceOfSupply?.trim() ?? '';
  if (direct.isNotEmpty) return direct;
  return _vendorAddressValue(_vendorBillingAddress(vendor), 'state');
}

String _vendorGstTreatmentLabel(String? rawValue) {
  switch (rawValue?.toLowerCase()) {
    case 'registered_business':
      return 'Registered Business';
    case 'unregistered_business':
      return 'Unregistered Business';
    case 'overseas':
      return 'Overseas';
    case 'consumer':
      return 'Consumer';
    default:
      return rawValue ?? 'Unregistered Business';
  }
}

class _VCVendorAddressPanel extends StatefulWidget {
  final Vendor vendor;
  final double labelWidth;
  final List<Map<String, String>> gstTreatmentOptions;

  const _VCVendorAddressPanel({
    required this.vendor,
    required this.labelWidth,
    required this.gstTreatmentOptions,
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

  // Overrides: null means use vendor data
  String? _overrideName;
  List<String>? _overrideLines;
  String? _overrideGstTreatment;
  String? _overrideGstin;

  List<String> get _billingLines {
    if (_overrideLines != null) return _overrideLines!;
    final lines = <String>[];
    final billingAddress = _vendorBillingAddress(widget.vendor);
    final street1 = _vendorAddressValue(billingAddress, 'street1');
    final street2 = _vendorAddressValue(billingAddress, 'street2');
    final city = _vendorAddressValue(billingAddress, 'city');
    final state = _vendorAddressValue(billingAddress, 'state');
    final zip = _vendorAddressValue(billingAddress, 'zip');
    final phone = _vendorAddressValue(billingAddress, 'phone');
    if (street1.isNotEmpty) lines.add(street1);
    if (street2.isNotEmpty) lines.add(street2);
    if (city.isNotEmpty) lines.add(city);
    if (state.isNotEmpty) lines.add(zip.isNotEmpty ? '$state $zip' : state);
    if (phone.isNotEmpty) lines.add('Phone: $phone');
    return lines;
  }

  String get _displayName =>
      _overrideName ?? widget.vendor.displayName.toUpperCase();

  String get _gstTreatmentLabel {
    if (_overrideGstTreatment != null) return _overrideGstTreatment!;
    final baseLabel = _vendorGstTreatmentLabel(widget.vendor.gstTreatment);
    return baseLabel == 'Registered Business'
        ? 'Registered Business - Regular'
        : baseLabel;
  }

  String get _gstinValue => _overrideGstin ?? widget.vendor.gstin ?? '';

  // â”€â”€ Billing address picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _closeBillingPicker() {
    _billingOverlay?.remove();
    _billingOverlay = null;
    if (mounted) setState(() {});
  }

  void _openBillingPicker(BuildContext context) {
    if (_billingOverlay != null) {
      _closeBillingPicker();
      return;
    }
    final addr = {'name': _displayName, 'lines': _billingLines};
    _billingOverlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeBillingPicker,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
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
                            _openAddressEditDialog(
                              context,
                              const <String, dynamic>{
                                'name': '',
                                'lines': <String>[],
                              },
                              isNew: true,
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
    Overlay.of(context).insert(_billingOverlay!);
    setState(() {});
  }

  void _openAddressEditDialog(
    BuildContext context,
    Map<String, dynamic> addr, {
    bool isNew = false,
  }) {
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
    if (_gstTreatmentOverlay != null) {
      _closeGstTreatmentPopover();
      return;
    }

    String selectedTreatment = _gstTreatmentLabel;
    final gstinCtrl = TextEditingController(text: _gstinValue);
    bool makePermanent = false;

    final treatments = widget.gstTreatmentOptions
        .map((item) => item['label'] ?? '')
        .where((label) => label.isNotEmpty)
        .toList(growable: false);

    if (treatments.isEmpty) {
      gstinCtrl.dispose();
      return;
    }

    if (!treatments.contains(selectedTreatment))
      selectedTreatment = treatments.first;

    _gstTreatmentOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
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
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                gstinCtrl.dispose();
                                _closeGstTreatmentPopover();
                              },
                              child: const Icon(
                                LucideIcons.x,
                                size: 14,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        const SizedBox(height: 12),
                        // GST Treatment
                        const Text(
                          'GST Treatment',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FormDropdown<String>(
                          value: selectedTreatment,
                          items: treatments,
                          height: 34,
                          onChanged: (v) {
                            if (v != null)
                              setPopup(() => selectedTreatment = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        // GSTIN
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'GSTIN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // TODO(GSTIN): Add GSTIN format validation using validateGstin(value) helper
                        TextField(
                          controller: gstinCtrl,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter GSTIN',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
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
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Get Taxpayer details',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Make it permanent
                        const Text(
                          'Make it permanent?',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: Checkbox(
                                value: makePermanent,
                                onChanged: (v) =>
                                    setPopup(() => makePermanent = v ?? false),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                activeColor: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Use these settings for all future transactions of this vendor.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
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
                                      _overrideGstTreatment =
                                          result['gstTreatment'];
                                      _overrideGstin =
                                          (result['gstin']?.isNotEmpty == true)
                                          ? result['gstin']
                                          : null;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Update',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                                  side: const BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 12),
                                ),
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
        ],
      ),
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
    if (_gstinOverlay != null) {
      _closeGstinPopover();
      return;
    }

    final gstin = _gstinValue;
    final state = _vendorAddressValue(
      _vendorBillingAddress(widget.vendor),
      'state',
    );
    final label = gstin.isNotEmpty
        ? '$gstin${state.isNotEmpty ? ' - $state' : ''}'
        : 'No GSTIN';

    _gstinOverlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeGstinPopover,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Icon(
                                      Icons.arrow_drop_up,
                                      size: 16,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: const Icon(
                                      Icons.arrow_drop_down,
                                      size: 16,
                                      color: AppTheme.textSecondary,
                                    ),
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
                              barrierColor: Colors.black.withValues(
                                alpha: 0.35,
                              ),
                              builder: (_) => _VCManageTaxInfoDialog(
                                gstin: _gstinValue,
                                placeOfSupply: state,
                                onSelected: (gstin) {
                                  if (mounted)
                                    setState(() => _overrideGstin = gstin);
                                },
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Manage Tax Informations',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  LucideIcons.settings,
                                  size: 14,
                                  color: AppTheme.primaryBlue,
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
        );
      },
    );
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
      padding: EdgeInsets.only(
        left: widget.labelWidth + 16,
        bottom: 12,
        top: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BILLING ADDRESS header with pencil
          CompositedTransformTarget(
            link: _billingLink,
            child: GestureDetector(
              onTap: () => _openBillingPicker(context),
              child: Container(
                padding: isBillingOpen
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : EdgeInsets.zero,
                decoration: isBillingOpen
                    ? BoxDecoration(
                        border: Border.all(color: AppTheme.primaryBlue),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
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
                      color: isBillingOpen
                          ? AppTheme.primaryBlue
                          : AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Vendor name
          Text(
            _displayName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          // Address lines
          ..._billingLines.map(
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
          // Space after last address line (after phone)
          const SizedBox(height: 10),
          // GST Treatment row with pencil
          CompositedTransformTarget(
            link: _gstTreatmentLink,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'GST Treatment: ',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                Text(
                  _gstTreatmentLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _openGstTreatmentPopover(context),
                  child: Icon(
                    LucideIcons.pencil,
                    size: 12,
                    color: isGstTreatmentOpen
                        ? AppTheme.primaryBlue
                        : AppTheme.textMuted,
                  ),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    _gstinValue,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _openGstinPopover(context),
                    child: Icon(
                      LucideIcons.pencil,
                      size: 12,
                      color: isGstinOpen
                          ? AppTheme.primaryBlue
                          : AppTheme.textMuted,
                    ),
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

  const _DatePickerField({
    required this.globalKey,
    required this.date,
    required this.onPick,
  });

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
                  color: date != null
                      ? AppTheme.textPrimary
                      : AppTheme.textHint,
                ),
              ),
            ),
            const Icon(
              LucideIcons.calendar,
              size: 14,
              color: AppTheme.textSecondary,
            ),
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
  final List<shared_acct.AccountNode> accountTree;
  final List<Map<String, dynamic>> taxSections;

  const _VCNewTaxFormDialog({
    required this.isTds,
    required this.accountTree,
    this.taxSections = const [],
  });

  @override
  State<_VCNewTaxFormDialog> createState() => _VCNewTaxFormDialogState();
}

class _VCNewTaxFormDialogState extends State<_VCNewTaxFormDialog> {
  final _taxNameCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  String _incomeAct = 'New Income Tax Act 2025';
  String? _natureOfCollection;
  String? _higherRateReason;
  bool _showAccountSelection = false;
  String? _selectedPayableAccount;
  String? _selectedReceivableAccount;
  bool _isHigherRate = false;
  bool _isSaving = false;
  String? _errorMessage;
  DateTime? _startDate = DateTime(2026, 4, 1);
  DateTime? _endDate;
  final _startDateKey = GlobalKey();
  final _endDateKey = GlobalKey();

  static const _incomeTaxActs = [
    'New Income Tax Act 2025',
    'Old Income Tax Act 1961',
  ];

  static const _higherTdsRateReasonOptions = [
    'Non-furnishing of PAN',
    'Non-filing of return of income',
  ];

  static const Map<String, String> _higherTdsRateReasonDescriptions = {
    'Non-furnishing of PAN':
        'Deduction is on higher rate under section 206AA/397(2)(b)(i) on account of non-furnishing of PAN',
    'Non-filing of return of income':
        'Deduction is on higher rate in view of section 206AB for non-filing of return of income',
  };

  static const _higherTcsRateReasonOptions = [
    'Non-furnishing of PAN',
    'Non-filing of return of income',
  ];

  static const Map<String, String> _higherTcsRateReasonDescriptions = {
    'Non-furnishing of PAN':
        'Collection is at higher rate under section 206CC/397(2)(b)(ii) on account of non-furnishing of PAN/Aadhaar by the collectee',
    'Non-filing of return of income':
        'Collection is at a higher rate in view of section 206CCA',
  };

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
    final higherLabel = widget.isTds
        ? 'This is a Higher TDS Rate'
        : 'This is a Higher TCS Rate';
    final sectionOptions = widget.taxSections
        .map(
          (section) =>
              (widget.isTds ? section['section_name'] : section['nature_name'])
                  .toString()
                  .trim(),
        )
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 790,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'New $typeLabel',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTaxDialogField(
                          label: 'Tax Name*',
                          labelColor: Colors.red,
                          child: CustomTextField(
                            controller: _taxNameCtrl,
                            hintText: '',
                            height: 38,
                          ),
                        ),
                      ),
                      const SizedBox(width: 34),
                      Expanded(
                        child: _buildTaxDialogField(
                          label: 'Rate (%)*',
                          labelColor: Colors.red,
                          child: CustomTextField(
                            controller: _rateCtrl,
                            hintText: '',
                            height: 38,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 354,
                    child: _buildTaxDialogField(
                      label: 'Applicable Income Tax Act',
                      child: FormDropdown<String>(
                        value: _incomeAct,
                        items: _incomeTaxActs,
                        hint: 'Select',
                        height: 38,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _incomeAct = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 354,
                    child: _buildTaxDialogField(
                      label: widget.isTds
                          ? 'Section*'
                          : 'Nature of Collection*',
                      labelColor: Colors.red,
                      child: FormDropdown<String>(
                        value: _natureOfCollection,
                        items: sectionOptions,
                        hint: 'Select a Tax Type.',
                        height: 38,
                        onChanged: (val) =>
                            setState(() => _natureOfCollection = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_showAccountSelection)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTaxDialogField(
                            label: '$typeLabel Payable Account',
                            child: AccountTreeDropdown(
                              value: _selectedPayableAccount,
                              nodes: widget.accountTree.isNotEmpty
                                  ? widget.accountTree
                                  : _vcFallbackAccountTree,
                              hint: 'Select an account',
                              height: 38,
                              borderRadius: BorderRadius.circular(4),
                              onChanged: (val) =>
                                  setState(() => _selectedPayableAccount = val),
                            ),
                          ),
                        ),
                        const SizedBox(width: 34),
                        Expanded(
                          child: _buildTaxDialogField(
                            label: '$typeLabel Receivable Account',
                            child: AccountTreeDropdown(
                              value: _selectedReceivableAccount,
                              nodes: widget.accountTree.isNotEmpty
                                  ? widget.accountTree
                                  : _vcFallbackAccountTree,
                              hint: 'Select an account',
                              height: 38,
                              borderRadius: BorderRadius.circular(4),
                              onChanged: (val) => setState(
                                () => _selectedReceivableAccount = val,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.info,
                          size: 15,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'By default, $typeLabel will be tracked under ',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppTheme.textBody,
                          ),
                        ),
                        Text(
                          payableLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textBody,
                          ),
                        ),
                        const Text(
                          ' and ',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppTheme.textBody,
                          ),
                        ),
                        Text(
                          receivableLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textBody,
                          ),
                        ),
                        const Text(
                          ' accounts. Click ',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppTheme.textBody,
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => _showAccountSelection = true),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  LucideIcons.pencil,
                                  size: 12,
                                  color: AppTheme.primaryBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Text(
                          ' to choose an account of your choice.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppTheme.textBody,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _isHigherRate,
                          onChanged: (v) => setState(() {
                            _isHigherRate = v ?? false;
                            if (!_isHigherRate) {
                              _higherRateReason = null;
                            }
                          }),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          activeColor: AppTheme.primaryBlue,
                          side: const BorderSide(
                            color: AppTheme.borderColor,
                            width: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        higherLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textBody,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ZTooltip(
                        message: widget.isTds
                            ? 'Select this if a higher TDS rate applies when PAN is not provided.'
                            : 'Select this if a higher TCS rate applies when PAN is not provided.',
                        child: Icon(
                          LucideIcons.helpCircle,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (_isHigherRate) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 354,
                      child: _buildTaxDialogField(
                        label: widget.isTds
                            ? 'Reason for Higher TDS Rate*'
                            : 'Reason for Higher TCS Rate*',
                        labelColor: Colors.red,
                        child: FormDropdown<String>(
                          value: _higherRateReason,
                          items: widget.isTds
                              ? _higherTdsRateReasonOptions
                              : _higherTcsRateReasonOptions,
                          hint: '',
                          height: 38,
                          itemHeight: 64,
                          itemEstimatedHeight: 64,
                          onChanged: (val) =>
                              setState(() => _higherRateReason = val),
                          itemBuilder: (item, isSelected, isHovered) {
                            final backgroundColor = isHovered
                                ? AppTheme.primaryBlue
                                : (isSelected
                                      ? const Color(0xFFF3F4F6)
                                      : Colors.white);
                            final titleColor = isHovered
                                ? Colors.white
                                : AppTheme.textPrimary;
                            final descriptionColor = isHovered
                                ? Colors.white
                                : AppTheme.textSecondary;
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.isTds
                                        ? (_higherTdsRateReasonDescriptions[item] ??
                                              '')
                                        : (_higherTcsRateReasonDescriptions[item] ??
                                              ''),
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.25,
                                      color: descriptionColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Text(
                        'Applicable Period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const ZTooltip(
                        message:
                            'The date range during which this rate is applicable.',
                        child: Icon(
                          LucideIcons.helpCircle,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTaxDialogField(
                          label: 'Start Date',
                          child: _DatePickerField(
                            globalKey: _startDateKey,
                            date: _startDate,
                            onPick: (d) => setState(() => _startDate = d),
                          ),
                        ),
                      ),
                      const SizedBox(width: 34),
                      Expanded(
                        child: _buildTaxDialogField(
                          label: 'End Date',
                          child: _DatePickerField(
                            globalKey: _endDateKey,
                            date: _endDate,
                            onPick: (d) => setState(() => _endDate = d),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              height: 74,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                  const SizedBox(width: 10),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _findAccountIdByName(String accountName) {
    String? match;

    void search(List<shared_acct.AccountNode> nodes) {
      for (final node in nodes) {
        if (match != null) return;
        if (node.selectable &&
            node.name.trim().toLowerCase() ==
                accountName.trim().toLowerCase()) {
          match = node.id;
          return;
        }
        if (node.children.isNotEmpty) {
          search(node.children);
        }
      }
    }

    final nodes = widget.accountTree.isNotEmpty
        ? widget.accountTree
        : _vcFallbackAccountTree;
    search(nodes);
    return match;
  }

  String? _resolveSelectedSectionId() {
    if (_natureOfCollection == null) {
      return null;
    }
    for (final section in widget.taxSections) {
      final name =
          (widget.isTds ? section['section_name'] : section['nature_name'])
              .toString()
              .trim();
      if (name == _natureOfCollection) {
        return section['id']?.toString();
      }
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final typeLabel = widget.isTds ? 'TDS' : 'TCS';
    final payableLabel = widget.isTds ? 'TDS Payable' : 'TCS Payable';
    final receivableLabel = widget.isTds ? 'TDS Receivable' : 'TCS Receivable';
    final name = _taxNameCtrl.text.trim();
    final rate = double.tryParse(_rateCtrl.text.trim());
    final sectionId = _resolveSelectedSectionId();

    if (name.isEmpty) {
      setState(() => _errorMessage = '$typeLabel tax name is required.');
      return;
    }
    if (rate == null) {
      setState(() => _errorMessage = 'Please enter a valid rate.');
      return;
    }
    if (sectionId == null) {
      setState(
        () => _errorMessage = widget.isTds
            ? 'Please select a section.'
            : 'Please select a nature.',
      );
      return;
    }
    if (_isHigherRate && (_higherRateReason?.isEmpty ?? true)) {
      setState(
        () => _errorMessage = widget.isTds
            ? 'Higher TDS rate reason is required before saving.'
            : 'Higher TCS rate reason is required before saving.',
      );
      return;
    }

    final payload = <String, dynamic>{
      'tax_name': name,
      if (widget.isTds) 'base_rate': rate else 'rate': rate,
      if (widget.isTds) 'section_id': sectionId else 'nature_id': sectionId,
      'payable_account_id':
          _selectedPayableAccount ?? _findAccountIdByName(payableLabel),
      'receivable_account_id':
          _selectedReceivableAccount ?? _findAccountIdByName(receivableLabel),
      'is_higher_rate': _isHigherRate,
      'reason_higher_rate': _higherRateReason,
      'applicable_from': _startDate?.toIso8601String(),
      'applicable_to': _endDate?.toIso8601String(),
      'is_active': true,
      if (!widget.isTds) 'income_tax_act': _incomeAct,
    };

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final lookupsService = LookupsApiService();
      final savedRows = widget.isTds
          ? await lookupsService.syncTdsRates([payload])
          : await lookupsService.syncTcsRates([payload]);
      if (!mounted) return;

      final savedItem = savedRows.isNotEmpty ? savedRows.first : payload;
      Navigator.of(context).pop(savedItem);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to save $typeLabel tax.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildTaxDialogField({
    required String label,
    Color labelColor = AppTheme.textPrimary,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _VCNewGstTaxDialog extends StatefulWidget {
  const _VCNewGstTaxDialog();

  @override
  State<_VCNewGstTaxDialog> createState() => _VCNewGstTaxDialogState();
}

class _VCNewGstTaxDialogState extends State<_VCNewGstTaxDialog> {
  final TextEditingController _taxNameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  String? _selectedTaxType;

  static const List<String> _taxTypes = <String>[
    'Tax Group',
    'IGST',
    'CGST',
    'SGST',
  ];

  @override
  void dispose() {
    _taxNameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 700,
        height: 333.64,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 58,
                padding: const EdgeInsets.fromLTRB(24, 0, 20, 0),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'New Tax',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(LucideIcons.x, size: 18, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormRow(
                        label: 'Tax Name*',
                        labelColor: AppTheme.errorRed,
                        child: CustomTextField(
                          controller: _taxNameController,
                          height: 38,
                          hintText: '',
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildFormRow(
                        label: 'Rate (%)*',
                        labelColor: AppTheme.errorRed,
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _rateController,
                                height: 38,
                                hintText: '',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9F9FB),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(6),
                                  bottomRight: Radius.circular(6),
                                ),
                                border: Border(
                                  top: BorderSide(color: AppTheme.borderLight),
                                  right: BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                  bottom: BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                              ),
                              child: const Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildFormRow(
                        label: 'Tax Type',
                        child: FormDropdown<String>(
                          value: _selectedTaxType,
                          items: _taxTypes,
                          hint: 'Select a Tax Type.',
                          height: 38,
                          showSearch: false,
                          onChanged: (value) {
                            setState(() => _selectedTaxType = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 88,
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Save',
                      onPressed: () => Navigator.of(context).pop(),
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
        ),
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    Color labelColor = AppTheme.textPrimary,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 258,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(child: child),
      ],
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
    return Container(
      color: AppTheme.bgDisabled,
      width: double.infinity,
      child: child,
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
    required this.onReorderItem,
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
    required this.priceListOptions,
  });

  final List<_VCLineItem> items;
  final List<Item> availableProducts;
  final Future<List<Item>> Function(String query) onSearchProducts;
  final VoidCallback onAddItem;
  final VoidCallback onAddBulkItems;
  final void Function(int) onInsertItem;
  final void Function(int) onDuplicateItem;
  final void Function(int) onRemoveItem;
  final void Function(int fromIndex, int toIndex) onReorderItem;
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
  final List<PriceList> priceListOptions;
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
              borderRadius: BorderRadius.circular(6),
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
                const Expanded(
                  flex: 14,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: _TH('ITEM DETAILS'),
                  ),
                ),
                _vLine(),
                const Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: _TH('ACCOUNT'),
                  ),
                ),
                _vLine(),
                const Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: _TH('QUANTITY', right: true),
                  ),
                ),
                _vLine(),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
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
                        vertical: 9,
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
                      vertical: 9,
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
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: _TH('AMOUNT', right: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Item rows
        Column(
          children: List.generate(widget.items.length, (index) {
            final showActions = _hoveredItemActionIndex == index;
            return KeyedSubtree(
              key: ValueKey(widget.items[index]),
              child: MouseRegion(
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
                child: Container(
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
                              _VCItemRow(
                                item: widget.items[index],
                                availableProducts: widget.availableProducts,
                                onSearchProducts: widget.onSearchProducts,
                                onChanged: widget.onTotalsChanged,
                                onAddBatches: () => widget.onAddBatches(
                                  widget.items[index],
                                ),
                                defaultWarehouse: widget.warehouse,
                                accountTree: widget.accountTree,
                                taxOptions: widget.taxOptions,
                                selectedStockView: _selectedStockView,
                                showAdditionalInformation:
                                    !_areAdditionalInfosHidden,
                                onStockViewChanged: (v) =>
                                    setState(() => _selectedStockView = v),
                                onViewItemDetails: () => widget
                                    .onViewItemDetails(widget.items[index]),
                                onViewItemDetailsTransactions: () =>
                                    widget.onViewItemDetailsTransactions(
                                      widget.items[index],
                                    ),
                                onEditItem: () =>
                                    widget.onEditItem(widget.items[index]),
                                defaultPriceList: widget.defaultPriceList,
                                priceListOptions: widget.priceListOptions,
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
                                child: Center(
                                  child: _buildRowActionMenu(index),
                                ),
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
              ),
            );
          }),
        ),
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
    required this.priceListOptions,
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
  final List<PriceList> priceListOptions;
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
        _previousRate = double.tryParse(widget.item.rateController.text) ?? 0.0;
      } else {
        _evaluateRateField();
        widget.onChanged();
      }
    });
    _hsnEditController = TextEditingController(
      text:
          widget.item.hsnCodeOverride ?? widget.item.sourceItem?.hsnCode ?? '',
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
      widget.item.rateController.text = (_previousRate + addVal)
          .toStringAsFixed(2);
      setState(() {});
      return;
    }
    if (val.startsWith('-=')) {
      final subVal = double.tryParse(val.substring(2)) ?? 0.0;
      widget.item.rateController.text = (_previousRate - subVal)
          .toStringAsFixed(2);
      setState(() {});
      return;
    }
    if (val.startsWith('*=')) {
      final mulVal = double.tryParse(val.substring(2)) ?? 1.0;
      widget.item.rateController.text = (_previousRate * mulVal)
          .toStringAsFixed(2);
      setState(() {});
      return;
    }
    if (val.startsWith('/=')) {
      final divVal = double.tryParse(val.substring(2)) ?? 1.0;
      if (divVal != 0) {
        widget.item.rateController.text = (_previousRate / divVal)
            .toStringAsFixed(2);
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
                                        if (v != null)
                                          setPopupState(() => selected = v);
                                      },
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
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
                                final val = _hsnEditController.text.trim();
                                setState(() {
                                  widget.item.hsnCodeOverride = val.isEmpty
                                      ? null
                                      : val;
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
      return (gross - discountAmt)
          .clamp(0.0, double.infinity)
          .toStringAsFixed(2);
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
            selected.purchaseAccountId ?? 'Cost of Goods Sold';
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
    PriceList? selectedRowPriceList;
    final selectedPriceListKey = item.selectedPriceList?.trim();
    if (selectedPriceListKey != null && selectedPriceListKey.isNotEmpty) {
      for (final priceList in widget.priceListOptions) {
        if (priceList.id == selectedPriceListKey ||
            priceList.name == selectedPriceListKey) {
          selectedRowPriceList = priceList;
          break;
        }
      }
    }
    selectedRowPriceList ??= widget.defaultPriceList;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ITEM DETAILS
              Expanded(
                flex: 14,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
                              height: _VendorCreditsCreatePageState
                                  ._tableFieldHeight,
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
                                    isSelected: isSelected,
                                    isHovered: isHovered,
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
                                  item.sourceItem!.type.toUpperCase() ==
                                          'SERVICE'
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
                    ],
                  ),
                ),
              ),
              _vLine(),
              // ACCOUNT
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: AccountTreeDropdown(
                    value: item.selectedAccount,
                    nodes: widget.accountTree.isNotEmpty
                        ? widget.accountTree
                        : _vcFallbackAccountTree,
                    hint: 'Select an account',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
                          productId: item.sourceItem?.id,
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
                                  item.warehouseLocation ??
                                      widget.defaultWarehouse,
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
                        if (item.sourceItem?.trackBatches == true) ...[
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
                                            decoration:
                                                TextDecoration.underline,
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
                    ],
                  ),
                ),
              ),
              _vLine(),
              // RATE
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
                          width: 170,
                          height: 28,
                          child: FormDropdown<PriceList>(
                            value: selectedRowPriceList,
                            items: widget.priceListOptions,
                            hint: 'Apply Price List',
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            iconSize: 12,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                            displayStringForValue: (priceList) =>
                                priceList.name,
                            hideBorderDefault: true,
                            allowClear: true,
                            onChanged: (v) {
                              setState(() => item.selectedPriceList = v?.id);
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
                            height:
                                _VendorCreditsCreatePageState._tableFieldHeight,
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
                              item.discountIsPercent ? '%' : '₹',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormDropdown<_VCTaxOption>(
                        value: item.selectedTax == null
                            ? null
                            : (() {
                                for (final option in widget.taxOptions) {
                                  if (!option.isHeader &&
                                      option.label == item.selectedTax) {
                                    return option;
                                  }
                                }
                                return null;
                              })(),
                        items: widget.taxOptions,
                        hint: 'Select a Tax',
                        height: _VendorCreditsCreatePageState._tableFieldHeight,
                        menuWidth: 360,
                        hideBorderDefault: true,
                        allowClear: true,
                        showSettings: true,
                        settingsLabel: 'New Tax',
                        settingsIcon: Icons.add_circle_outline,
                        onSettingsTap: () {
                          showGeneralDialog<void>(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: Colors.black.withValues(alpha: 0.35),
                            pageBuilder: (dialogContext, _, __) {
                              return const Align(
                                alignment: Alignment.topCenter,
                                child: _VCNewGstTaxDialog(),
                              );
                            },
                          );
                        },
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
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: isHovered
                                ? AppTheme.primaryBlue
                                : (isSelected
                                      ? AppTheme.bgDisabled
                                      : Colors.white),
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
                                              : AppTheme.textPrimary,
                                          fontWeight: (isHovered || isSelected)
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
                                            : AppTheme.textPrimary,
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
                              item.selectedTaxRate = val.rate > 0
                                  ? val.rate
                                  : null;
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
        ),
        if (widget.showAdditionalInformation)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 5, 12, 5),
            decoration: const BoxDecoration(
              color: Color(0xFFFBFAFA),
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: _VCReportingTagsPopoverButton(
              item: item,
              onChanged: () => setState(() {}),
              plain: true,
            ),
          ),
      ],
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
              ? '₹${widget.item.sourceItem!.costPrice!.toStringAsFixed(2)}'
              : '₹0.00',
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
              ? '₹${widget.item.sourceItem!.sellingPrice!.toStringAsFixed(2)}'
              : '₹0.00',
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
  String binLocation = '';
  String binId = '';
  String batchId = '';
  String layerId = '';
  String batchNo = '';
  String unitPack = '';
  String mrp = '';
  String purchaseRate = '';
  String focQuantity = '';
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
  String? dbItemId;
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
  shared_acct.AccountNode(id: 'Cost of Goods Sold', name: 'Cost of Goods Sold'),
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
  ConsumerState<_VCManageTaxInfoDialog> createState() =>
      _VCManageTaxInfoDialogState();
}

class _VCManageTaxInfoDialogState
    extends ConsumerState<_VCManageTaxInfoDialog> {
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
    final placeLabel = widget.placeOfSupply.isNotEmpty
        ? widget.placeOfSupply
        : 'â€”';

    return Dialog(
      backgroundColor: Colors.white,
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
                      style: TextStyle(
                        fontSize: 16,
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
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Add New Tax Information',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
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
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'GSTIN / UIN',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.errorRed,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '*',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.errorRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  ZTooltip(
                                    message:
                                        'Enter the 15-digit GSTIN or UIN number for this vendor.',
                                    child: const Icon(
                                      LucideIcons.helpCircle,
                                      size: 13,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _newGstinCtrl,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 9,
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
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  'Validate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Place of Supply',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.errorRed,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              FormDropdown<String>(
                                value: _newPlaceOfSupply,
                                items:
                                    ref
                                        .watch(statesProvider('IN'))
                                        .value
                                        ?.map((s) => s['name'] ?? '')
                                        .where((n) => n.isNotEmpty)
                                        .toList() ??
                                    [],
                                hint: '',
                                height: 34,
                                onChanged: (v) =>
                                    setState(() => _newPlaceOfSupply = v),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Save and Select',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 12),
                          ),
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
                    child: Text(
                      'GSTIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'PLACE OF SUPPLY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
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
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '(Primary Tax Information)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.accentGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      placeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  // Up/down scroll arrows (decorative)
                  Column(
                    children: const [
                      Icon(
                        Icons.arrow_drop_up,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
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

// â”€â”€â”€ Vendor Details Side Panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _VCVendorDetailsSidePanel extends StatefulWidget {
  final Vendor vendor;
  final VoidCallback onClose;

  const _VCVendorDetailsSidePanel({
    required this.vendor,
    required this.onClose,
  });

  @override
  State<_VCVendorDetailsSidePanel> createState() =>
      _VCVendorDetailsSidePanelState();
}

class _VCVendorDetailsSidePanelState extends State<_VCVendorDetailsSidePanel> {
  int _tab = 0;
  bool _showContactPersons = false;
  bool _showAddress = false;

  String get _gstTreatmentLabel =>
      _vendorGstTreatmentLabel(widget.vendor.gstTreatment);

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final billingAddress = _vendorBillingAddress(v);
    final contactPersons = v.contactPersons ?? const <Map<String, dynamic>>[];
    final primaryContact = contactPersons.isNotEmpty
        ? contactPersons.first
        : null;
    final primaryContactName =
        [
              primaryContact?['salutation'],
              primaryContact?['firstName'],
              primaryContact?['lastName'],
            ]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .join(' ');
    final primaryContactPhone =
        (primaryContact?['workPhone'] ?? primaryContact?['mobilePhone'])
            ?.toString()
            .trim();
    final primaryContactEmail = primaryContact?['email']?.toString().trim();
    final billingStreet = _vendorAddressValue(billingAddress, 'street1');
    final billingCity = _vendorAddressValue(billingAddress, 'city');
    final billingPhone = _vendorAddressValue(billingAddress, 'phone');
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
                    v.displayName.isEmpty
                        ? '?'
                        : v.displayName[0].toUpperCase(),
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
                        'Vendor',
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
                              v.displayName,
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
          // Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.borderLight),
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: Row(
              children: [
                _VCPanelTabButton(
                  label: 'Details',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _VCPanelTabButton(
                  label: 'Activity Log',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 18,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          LucideIcons.alertTriangle,
                                          size: 20,
                                          color: AppTheme.warningOrange,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Outstanding Payables',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          '₹0.00',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const VerticalDivider(
                                  width: 1,
                                  color: AppTheme.borderLight,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 18,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          LucideIcons.badgeDollarSign,
                                          size: 20,
                                          color: AppTheme.successGreen,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Unused Credits',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          '₹0.00',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
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
                                child: Text(
                                  'Contact Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: AppTheme.borderLight,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _VCPanelDetailRow(
                                      label: 'Vendor Type',
                                      value:
                                          (v.companyName?.trim().isNotEmpty ??
                                              false)
                                          ? 'Business'
                                          : 'Individual',
                                    ),
                                    const SizedBox(height: 14),
                                    _VCPanelDetailRow(
                                      label: 'Currency',
                                      value:
                                          v.currency?.trim().isNotEmpty == true
                                          ? v.currency!
                                          : 'INR',
                                    ),
                                    const SizedBox(height: 14),
                                    const _VCPanelDetailRow(
                                      label: 'Credit Limit',
                                      value: '₹0.00',
                                    ),
                                    const SizedBox(height: 14),
                                    _VCPanelDetailRow(
                                      label: 'Payment Terms',
                                      value:
                                          v.paymentTerms?.trim().isNotEmpty ==
                                              true
                                          ? v.paymentTerms!
                                          : 'â€”',
                                    ),
                                    const SizedBox(height: 14),
                                    _VCPanelDetailRow(
                                      label: 'GST Treatment',
                                      value: _gstTreatmentLabel,
                                    ),
                                    const SizedBox(height: 14),
                                    _VCPanelDetailRow(
                                      label: 'Place of Supply',
                                      value: _vendorSourceOfSupply(v).isNotEmpty
                                          ? _vendorSourceOfSupply(v)
                                          : 'â€”',
                                    ),
                                    const SizedBox(height: 14),
                                    const _VCPanelDetailRow(
                                      label: 'Tax Preference',
                                      value: 'Taxable',
                                    ),
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
                          count: contactPersons.length,
                          expanded: _showContactPersons,
                          onTap: () => setState(
                            () => _showContactPersons = !_showContactPersons,
                          ),
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
                                _VCPanelDetailRow(
                                  label: 'Name',
                                  value: primaryContactName.isNotEmpty
                                      ? primaryContactName
                                      : v.displayName,
                                ),
                                const SizedBox(height: 10),
                                _VCPanelDetailRow(
                                  label: 'Phone',
                                  value: primaryContactPhone?.isNotEmpty == true
                                      ? primaryContactPhone!
                                      : (v.phone ?? v.mobilePhone ?? 'â€”'),
                                ),
                                const SizedBox(height: 10),
                                _VCPanelDetailRow(
                                  label: 'Email',
                                  value: primaryContactEmail?.isNotEmpty == true
                                      ? primaryContactEmail!
                                      : (v.email ?? 'â€”'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Address tile
                        _VCPanelActionTile(
                          label: 'Address',
                          expanded: _showAddress,
                          onTap: () =>
                              setState(() => _showAddress = !_showAddress),
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
                                const Text(
                                  'BILLING ADDRESS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  v.displayName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (billingStreet.isNotEmpty)
                                  Text(
                                    billingStreet,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                if (billingCity.isNotEmpty)
                                  Text(
                                    billingCity,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                if (billingPhone.isNotEmpty)
                                  Text(
                                    'Phone: $billingPhone',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
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
    final detailColor = _hovered
        ? Colors.white.withValues(alpha: 0.82)
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
              Text(
                'Add New Address',
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
  ConsumerState<_VCAddressEditDialog> createState() =>
      _VCAddressEditDialogState();
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

  static const List<String> _countries = [
    'India',
    'United States',
    'United Kingdom',
    'UAE',
  ];

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

  Map<String, dynamic> _buildResult() {
    final lines = <String>[];
    if (_addressCtrl.text.trim().isNotEmpty)
      lines.add(_addressCtrl.text.trim());
    if (_street2Ctrl.text.trim().isNotEmpty)
      lines.add(_street2Ctrl.text.trim());
    if (_cityCtrl.text.trim().isNotEmpty) lines.add(_cityCtrl.text.trim());
    if (_pinCtrl.text.trim().isNotEmpty) lines.add(_pinCtrl.text.trim());
    if (_phoneCtrl.text.trim().isNotEmpty)
      lines.add('Phone: ${_phoneCtrl.text.trim()}');
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
                                items:
                                    ref
                                        .watch(statesProvider('IN'))
                                        .value
                                        ?.map((s) => s['name'] ?? '')
                                        .where((n) => n.isNotEmpty)
                                        .toList() ??
                                    [],
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: () => Navigator.pop(context, _buildResult()),
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
  final bool isSelected;
  final bool isHovered;

  const _VCProductDropdownItem({
    required this.productName,
    required this.itemCode,
    required this.isSelected,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isHovered
        ? AppTheme.primaryBlue
        : (isSelected ? AppTheme.bgDisabled : AppTheme.backgroundColor);
    final textColor = isHovered ? AppTheme.backgroundColor : AppTheme.textBody;
    final secondaryColor = isHovered
        ? AppTheme.backgroundColor
        : AppTheme.textSecondary;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
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
    this.plain = false,
  });
  final _VCLineItem item;
  final VoidCallback onChanged;
  final bool plain;

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
  static const Map<String, String> _groupLabels = {
    'ADGF': 'ADGF',
    'Schedule': 'shedule',
    'Demo Advanced Reporting Tag': 'demo advaced reporting tag',
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
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: TapRegion(
                groupId: this,
                onTapOutside: (event) {
                  _close();
                },
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                  child: Container(
                    width: 470,
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
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Wrap(
                            spacing: 26,
                            runSpacing: 18,
                            children: _tagGroups.entries.map((group) {
                              return SizedBox(
                                width: 198,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _groupLabels[group.key] ?? group.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FormDropdown<String>(
                                      value: tempValues[group.key],
                                      items: group.value,
                                      hint: 'None',
                                      height: 34,
                                      showSearch: false,
                                      allowClear: true,
                                      onChanged: (value) {
                                        setOverlayState(() {
                                          tempValues[group.key] = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Row(
                            children: [
                              ZButton.primary(
                                label: 'Save',
                                onPressed: () {
                                  widget.item.selectedTagValues = tempValues;
                                  widget.onChanged();
                                  _close();
                                },
                              ),
                              const SizedBox(width: 10),
                              ZButton.secondary(
                                label: 'Cancel',
                                onPressed: _close,
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
    if (widget.plain) {
      return TapRegion(
        groupId: this,
        child: CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.tag,
                  size: 12,
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
    return TapRegion(
      groupId: this,
      child: CompositedTransformTarget(
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
  final bool isSelected;
  final bool isHovered;

  const _VcVendorDropdownItem({
    required this.name,
    required this.code,
    required this.subtitle,
    required this.isSelected,
    required this.isHovered,
  });

  String get _initial {
    final t = name.trim();
    return t.isEmpty ? '?' : t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = isHovered || isSelected;
    final backgroundColor = isHovered
        ? AppTheme.primaryBlue
        : (isSelected ? AppTheme.bgDisabled : AppTheme.backgroundColor);
    final textColor = isHovered ? AppTheme.backgroundColor : AppTheme.textBody;
    final secondaryColor = isHovered
        ? AppTheme.backgroundColor
        : AppTheme.textSecondary;

    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
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
                        child: Text(
                          '|',
                          style: TextStyle(fontSize: 14, color: secondaryColor),
                        ),
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
                      Icon(
                        LucideIcons.building2,
                        size: 14,
                        color: secondaryColor,
                      ),
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
