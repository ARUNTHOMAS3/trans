import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_transfer_model.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/inventory/repositories/adjustments_repository.dart';
import 'package:zerpai_erp/modules/inventory/repositories/transfers_repository.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/modules/items/items/presentation/widgets/item_details_sidebar.dart';
import 'package:zerpai_erp/modules/items/items/services/products_api_service.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/inventory_batch_bin_selection_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/warehouse_change_confirm_dialog.dart';
import 'package:zerpai_erp/shared/widgets/buttons/z_split_action_menu_button.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/sections/attachment_section.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:web/web.dart' as web;

class InventoryTransferOrdersCreateScreen extends ConsumerStatefulWidget {
  const InventoryTransferOrdersCreateScreen({super.key, this.transferId});

  final String? transferId;

  @override
  ConsumerState<InventoryTransferOrdersCreateScreen> createState() =>
      _InventoryTransferOrdersCreateScreenState();
}

String _formatQuantityText(num value, {int maxDecimals = 6}) {
  final fixed = value.toStringAsFixed(maxDecimals);
  final noTrailingZeros = fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  if (noTrailingZeros.isEmpty || noTrailingZeros == '-0') return '0';
  return noTrailingZeros;
}

class _TransferItemDraft {
  _TransferItemDraft({
    required this.productIdController,
    required this.productNameController,
    required this.descriptionController,
    required this.quantityController,
    required this.sourceStockController,
    required this.destinationStockController,
  });

  final TextEditingController productIdController;
  final TextEditingController productNameController;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController sourceStockController;
  final TextEditingController destinationStockController;
  _TransferBinDialogResult? sourceBinResult;
  _TransferBinDialogResult? destinationBinResult;

  void dispose() {
    productIdController.dispose();
    productNameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    sourceStockController.dispose();
    destinationStockController.dispose();
  }
}

class _TransferBinOption {
  const _TransferBinOption({required this.id, required this.code});

  final String id;
  final String code;
}

class _TransferBatchOption {
  const _TransferBatchOption({
    required this.id,
    required this.reference,
    required this.manufacturerBatchNo,
    required this.mfgDate,
    required this.expiryDate,
    required this.availableQty,
    required this.connectedBinIds,
  });

  final String id;
  final String reference;
  final String manufacturerBatchNo;
  final String mfgDate;
  final String expiryDate;
  final double availableQty;
  final Set<String> connectedBinIds;
}

class _TransferBinEntry {
  const _TransferBinEntry({
    required this.binId,
    required this.binCode,
    required this.quantity,
    this.batchId = '',
    this.batchRef = '',
    this.manufacturerBatchNo = '',
    this.expiryDate = '',
    this.availableQty = 0,
  });

  final String binId;
  final String binCode;
  final double quantity;
  final String batchId;
  final String batchRef;
  final String manufacturerBatchNo;
  final String expiryDate;
  final double availableQty;
}

class _TransferBinDialogResult {
  const _TransferBinDialogResult({required this.entries});

  final List<_TransferBinEntry> entries;

  double get totalQuantity =>
      entries.fold<double>(0, (sum, entry) => sum + entry.quantity);
}

class _BinRowDraft {
  _BinRowDraft({
    String selectedBinId = '',
    String quantity = '',
    this.batchId = '',
    this.batchRef = '',
    this.manufacturerBatchNo = '',
    this.expiryDate = '',
    this.availableQty = 0,
  }) : quantityController = TextEditingController(text: quantity),
       selectedBinId = selectedBinId;

  final TextEditingController quantityController;
  String selectedBinId;
  String batchId;
  String batchRef;
  String manufacturerBatchNo;
  String expiryDate;
  double availableQty;

  void dispose() {
    quantityController.dispose();
  }
}

class _ProductOption {
  const _ProductOption({
    required this.id,
    required this.name,
    required this.code,
    required this.categoryId,
    required this.sku,
    required this.upc,
    required this.ean,
    required this.mpn,
    required this.isbn,
    required this.description,
    required this.trackBinLocation,
    required this.trackBatches,
  });

  final String id;
  final String name;
  final String code;
  final String categoryId;
  final String sku;
  final String upc;
  final String ean;
  final String mpn;
  final String isbn;
  final String description;
  final bool trackBinLocation;
  final bool trackBatches;

  factory _ProductOption.fromMap(Map<String, dynamic> json) {
    return _ProductOption(
      id: (json['id'] ?? '').toString(),
      name: (json['product_name'] ?? json['name'] ?? '').toString(),
      code: (json['item_code'] ?? json['sku'] ?? '').toString(),
      categoryId: (json['category_id'] ?? json['categoryId'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      upc: (json['upc'] ?? '').toString(),
      ean: (json['ean'] ?? '').toString(),
      mpn: (json['mpn'] ?? '').toString(),
      isbn: (json['isbn'] ?? '').toString(),
      description:
          (json['sales_description'] ??
                  json['salesDescription'] ??
                  json['description'] ??
                  '')
              .toString(),
      trackBinLocation:
          json['track_bin_location'] == true ||
          json['trackBinLocation'] == true,
      trackBatches:
          json['track_batches'] == true || json['trackBatches'] == true,
    );
  }

  String get label {
    if (code.trim().isEmpty) return name;
    return '$name (${code.trim()})';
  }

  Iterable<String> get searchableCodes sync* {
    if (code.trim().isNotEmpty) yield code.trim();
    if (sku.trim().isNotEmpty) yield sku.trim();
    if (upc.trim().isNotEmpty) yield upc.trim();
    if (ean.trim().isNotEmpty) yield ean.trim();
    if (mpn.trim().isNotEmpty) yield mpn.trim();
    if (isbn.trim().isNotEmpty) yield isbn.trim();
  }
}

class _InventoryTransferOrdersCreateScreenState
    extends ConsumerState<InventoryTransferOrdersCreateScreen> {
  final TransfersRepository _repository = TransfersRepository();
  final AdjustmentsRepository _adjustmentsRepository = AdjustmentsRepository();
  final ProductsApiService _productsApi = ProductsApiService();
  final GlobalKey _dateKey = GlobalKey();
  final TextEditingController _transferNumberCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _autoPrefixCtrl = TextEditingController(
    text: 'TO-',
  );
  final TextEditingController _autoNextNumberCtrl = TextEditingController(
    text: '00001',
  );
  final TextEditingController _scanInputCtrl = TextEditingController();
  final List<_TransferItemDraft> _items = <_TransferItemDraft>[];
  List<PlatformFile> _attachedFiles = <PlatformFile>[];
  List<_ProductOption> _productOptions = const <_ProductOption>[];
  bool _loadingProducts = false;
  Timer? _scanDebounce;
  List<_ProductOption> _scanSuggestions = const <_ProductOption>[];
  bool _isScanSearching = false;
  bool _showScanPanel = false;

  DateTime _transferDate = DateTime.now();
  Warehouse? _sourceWarehouse;
  Warehouse? _destinationWarehouse;
  bool _isSaving = false;
  String? _savingAction;
  bool _autoGenerateNumber = true;
  BuildContext? _drawerHostContext;
  bool _isHydratingExisting = false;
  StockTransfer? _editingTransfer;

  String get _orgId => GoRouterState.of(context).pathParameters['orgSystemId']!;
  bool get _isEditMode => (widget.transferId ?? '').trim().isNotEmpty;
  bool get _isLocationMismatch =>
      _sourceWarehouse != null &&
      _destinationWarehouse != null &&
      _sourceWarehouse!.id == _destinationWarehouse!.id;

  bool _hasAnyItemInTable() =>
      _items.any((row) => row.productIdController.text.trim().isNotEmpty);

  Future<void> _onSourceWarehouseChanged(Warehouse? value) async {
    if (value == null) return;
    final currentId = _sourceWarehouse?.id.trim();
    final nextId = value.id.trim();
    if (currentId == nextId) return;

    if (_sourceWarehouse != null && _hasAnyItemInTable()) {
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WarehouseChangeConfirmDialog(
          warehouseName: value.name,
          title: 'Changing the Warehouse will update item availability',
          primaryLabel: 'Proceed with the selected Warehouse',
        ),
      );
      if (proceed != true) return;
    }

    setState(() {
      _sourceWarehouse = value;
      for (final row in _items) {
        row.sourceBinResult = null;
      }
    });
    await _refreshAllRowsStocks();
  }

  Future<void> _onDestinationWarehouseChanged(Warehouse? value) async {
    if (value == null) return;
    final currentId = _destinationWarehouse?.id.trim();
    final nextId = value.id.trim();
    if (currentId == nextId) return;

    if (_destinationWarehouse != null && _hasAnyItemInTable()) {
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WarehouseChangeConfirmDialog(
          warehouseName: value.name,
          title: 'Changing the Warehouse will update item availability',
          primaryLabel: 'Proceed with the selected Warehouse',
        ),
      );
      if (proceed != true) return;
    }

    setState(() {
      _destinationWarehouse = value;
      for (final row in _items) {
        row.destinationBinResult = null;
      }
    });
    await _refreshAllRowsStocks();
  }

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _dateText;
    if (_isEditMode) {
      _autoGenerateNumber = false;
      _isHydratingExisting = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadExistingTransfer(),
      );
    } else {
      _items.add(_newItemRow());
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _seedTransferNumber(),
      );
    }
    _loadInitialProducts();
  }

  @override
  void dispose() {
    _transferNumberCtrl.dispose();
    _dateCtrl.dispose();
    _reasonCtrl.dispose();
    _autoPrefixCtrl.dispose();
    _autoNextNumberCtrl.dispose();
    _scanDebounce?.cancel();
    _scanInputCtrl.dispose();
    for (final row in _items) {
      row.dispose();
    }
    super.dispose();
  }

  _TransferItemDraft _newItemRow() {
    return _TransferItemDraft(
      productIdController: TextEditingController(),
      productNameController: TextEditingController(),
      descriptionController: TextEditingController(),
      quantityController: TextEditingController(text: '0'),
      sourceStockController: TextEditingController(text: '0.00'),
      destinationStockController: TextEditingController(text: '0.00'),
    );
  }

  _TransferItemDraft _rowFromTransferItem(StockTransferItem item) {
    final row = _newItemRow();
    row.productIdController.text = item.productId.trim();
    row.productNameController.text =
        (item.productName ?? item.productCode ?? item.productId).trim();
    row.descriptionController.text = (item.notes ?? '').trim();
    row.quantityController.text = _formatQuantityText(
      item.quantity,
      maxDecimals: 2,
    );
    row.sourceStockController.text = '0.00';
    row.destinationStockController.text = '0.00';
    row.sourceBinResult = _mapTransferBatches(
      item.sourceBatches
          .map(
            (batch) => _TransferBinEntry(
              binId: batch.binId.trim(),
              binCode: batch.binId.trim(),
              quantity: batch.qty,
              batchId: batch.batchId.trim(),
              batchRef: batch.batchId.trim(),
              manufacturerBatchNo: '',
              expiryDate: '',
              availableQty: batch.qty,
            ),
          )
          .toList(growable: false),
    );
    row.destinationBinResult = _mapTransferBatches(
      item.destinationBatches
          .map(
            (batch) => _TransferBinEntry(
              binId: batch.destinationBinId.trim(),
              binCode: batch.destinationBinId.trim(),
              quantity: batch.qty,
              batchId: batch.destinationBatchId.trim(),
              batchRef: batch.destinationBatchId.trim(),
              manufacturerBatchNo: '',
              expiryDate: '',
              availableQty: batch.qty,
            ),
          )
          .toList(growable: false),
    );
    return row;
  }

  _TransferBinDialogResult? _mapTransferBatches(
    List<_TransferBinEntry> entries,
  ) {
    final filtered = entries
        .where((entry) => entry.binId.trim().isNotEmpty && entry.quantity > 0)
        .toList(growable: false);
    if (filtered.isEmpty) return null;
    return _TransferBinDialogResult(entries: filtered);
  }

  Future<void> _ensureProductsForTransferItemsLoaded(
    List<StockTransferItem> items,
  ) async {
    final missingIds = items
        .map((item) => item.productId.trim())
        .where((id) => id.isNotEmpty && !_productOptions.any((p) => p.id == id))
        .toSet()
        .toList(growable: false);
    if (missingIds.isEmpty) return;

    final fetched = <_ProductOption>[];
    for (final productId in missingIds) {
      try {
        final payload = await _productsApi.fetchProductById(productId);
        if (payload == null) continue;
        final option = _ProductOption.fromMap(
          Map<String, dynamic>.from(payload),
        );
        if (option.id.isNotEmpty && option.name.trim().isNotEmpty) {
          fetched.add(option);
        }
      } catch (_) {}
    }

    if (!mounted || fetched.isEmpty) return;
    setState(() {
      _productOptions = <_ProductOption>[
        ..._productOptions,
        ...fetched.where(
          (item) => !_productOptions.any((existing) => existing.id == item.id),
        ),
      ];
    });
  }

  Future<void> _loadExistingTransfer() async {
    final transferId = (widget.transferId ?? '').trim();
    if (transferId.isEmpty) return;
    try {
      final results = await Future.wait([
        _repository.getTransfer(transferId),
        ref.read(warehousesProvider.future),
      ]);
      final transfer = results[0] as StockTransfer?;
      final warehouses = results[1] as List<Warehouse>;
      if (!mounted || transfer == null) return;

      final warehouseById = <String, Warehouse>{
        for (final warehouse in warehouses)
          if (warehouse.id.trim().isNotEmpty) warehouse.id.trim(): warehouse,
      };
      final sourceWarehouse = warehouseById[transfer.fromWarehouseId.trim()];
      final destinationWarehouse = warehouseById[transfer.toWarehouseId.trim()];

      final sourceBinOptions = await _loadBinOptionsForWarehouse(
        sourceWarehouse,
      );
      final destinationBinOptions = await _loadBinOptionsForWarehouse(
        destinationWarehouse,
      );
      final sourceBinCodeById = {
        for (final option in sourceBinOptions) option.id: option.code,
      };
      final destinationBinCodeById = {
        for (final option in destinationBinOptions) option.id: option.code,
      };

      if (!mounted) return;
      setState(() {
        _editingTransfer = transfer;
        _transferNumberCtrl.text = transfer.transferNumber?.trim() ?? '';
        _transferDate = transfer.transferDate;
        _dateCtrl.text = _dateText;
        _reasonCtrl.text = transfer.notes?.trim() ?? '';
        _sourceWarehouse =
            sourceWarehouse ??
            Warehouse(
              id: transfer.fromWarehouseId,
              name: transfer.fromWarehouseName,
            );
        _destinationWarehouse =
            destinationWarehouse ??
            Warehouse(
              id: transfer.toWarehouseId,
              name: transfer.toWarehouseName,
            );
        _items
          ..clear()
          ..addAll(
            transfer.items
                .map((item) {
                  final row = _rowFromTransferItem(item);
                  row.sourceBinResult = _mapTransferBatches(
                    item.sourceBatches
                        .map(
                          (batch) => _TransferBinEntry(
                            binId: batch.binId.trim(),
                            binCode:
                                sourceBinCodeById[batch.binId.trim()] ??
                                batch.binId.trim(),
                            quantity: batch.qty,
                            batchId: batch.batchId.trim(),
                            batchRef: batch.batchId.trim(),
                            manufacturerBatchNo: '',
                            expiryDate: '',
                            availableQty: batch.qty,
                          ),
                        )
                        .toList(growable: false),
                  );
                  row.destinationBinResult = _mapTransferBatches(
                    item.destinationBatches
                        .map(
                          (batch) => _TransferBinEntry(
                            binId: batch.destinationBinId.trim(),
                            binCode:
                                destinationBinCodeById[batch.destinationBinId
                                    .trim()] ??
                                batch.destinationBinId.trim(),
                            quantity: batch.qty,
                            batchId: batch.destinationBatchId.trim(),
                            batchRef: batch.destinationBatchId.trim(),
                            manufacturerBatchNo: '',
                            expiryDate: '',
                            availableQty: batch.qty,
                          ),
                        )
                        .toList(growable: false),
                  );
                  return row;
                })
                .toList(growable: false),
          );
      });
      await _ensureProductsForTransferItemsLoaded(transfer.items);
      for (final row in _items) {
        await _refreshRowStocks(row);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isHydratingExisting = false;
      });
      ZerpaiToast.error(context, 'Failed to load transfer order for editing');
      AppLogger.error(
        'Failed to hydrate existing transfer order',
        error: e,
        module: 'inventory_transfer_orders',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isHydratingExisting = false;
        });
      }
    }
  }

  bool _isBinTrackedRow(_TransferItemDraft row) {
    final product = _findSelectedProductOption(row.productIdController.text);
    return product?.trackBinLocation == true;
  }

  bool _isBatchTrackedRow(_TransferItemDraft row) {
    final product = _findSelectedProductOption(row.productIdController.text);
    if (product == null) return false;
    return product.trackBatches;
  }

  String _binSummaryText(_TransferBinDialogResult? result) {
    if (result == null || result.entries.isEmpty) return '';
    final qty = result.totalQuantity;
    final count = result.entries.length;
    return '${_formatQuantityText(qty, maxDecimals: 2)} pcs taken from $count ${count == 1 ? 'bin' : 'bins'}.';
  }

  Future<List<_TransferBinOption>> _loadBinOptionsForWarehouse(
    Warehouse? warehouse,
  ) async {
    if (warehouse == null || warehouse.id.trim().isEmpty) {
      return const <_TransferBinOption>[];
    }
    try {
      final rows = await _adjustmentsRepository.getBinOptions(warehouse.id);
      return rows
          .map(
            (row) => _TransferBinOption(
              id: (row['id'] ?? '').trim(),
              code: (row['bin_code'] ?? '').trim(),
            ),
          )
          .where((bin) => bin.id.isNotEmpty && bin.code.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <_TransferBinOption>[];
    }
  }

  Future<List<_TransferBatchOption>> _loadBatchOptions(
    String productId, {
    String? warehouseId,
  }) async {
    final id = productId.trim();
    if (id.isEmpty) return const <_TransferBatchOption>[];
    try {
      final rows = await _productsApi.getProductBatches(
        id,
        warehouseId: warehouseId,
      );
      String str(dynamic value) => (value ?? '').toString().trim();
      double numVal(dynamic value) {
        if (value is num) return value.toDouble();
        return double.tryParse((value ?? '').toString()) ?? 0;
      }

      final seen = <String>{};
      final out = <_TransferBatchOption>[];
      for (final row in rows) {
        final ref = str(
          row['batch_no'] ??
              row['batchNo'] ??
              row['batch_number'] ??
              row['batchNumber'] ??
              row['batch_reference'] ??
              row['batchReference'] ??
              row['name'] ??
              row['code'],
        );
        if (ref.isEmpty || seen.contains(ref)) continue;
        seen.add(ref);
        final batchId = str(
          row['batch_id'] ?? row['batchId'] ?? row['id'] ?? ref,
        );
        out.add(
          _TransferBatchOption(
            id: batchId.isEmpty ? ref : batchId,
            reference: ref,
            manufacturerBatchNo: str(
              row['manufacturer_batch_no'] ?? row['manufacturerBatchNo'],
            ),
            mfgDate: str(row['mfg_date'] ?? row['mfgDate']),
            expiryDate: str(row['expiry_date'] ?? row['expiryDate']),
            availableQty: numVal(
              row['quantity_available'] ??
                  row['qty_available'] ??
                  row['available_qty'] ??
                  row['available_quantity'] ??
                  row['stock'],
            ),
            connectedBinIds: (() {
              final raw = row['connected_bin_ids'];
              final source = raw is List ? raw : const <dynamic>[];
              return source
                  .map((e) => (e ?? '').toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toSet();
            })(),
          ),
        );
      }
      return out;
    } catch (_) {
      return const <_TransferBatchOption>[];
    }
  }

  Future<void> _openBinModal(int index, {required bool isSource}) async {
    final row = _items[index];
    final lineQty = double.tryParse(row.quantityController.text.trim()) ?? 0;
    if (lineQty <= 0) return;
    final warehouse = isSource ? _sourceWarehouse : _destinationWarehouse;
    final options = await _loadBinOptionsForWarehouse(warehouse);
    final product = _findSelectedProductOption(row.productIdController.text);
    final requiresBatch = product?.trackBatches == true;
    final batchOptions = requiresBatch
        ? await _loadBatchOptions(
            row.productIdController.text.trim(),
            warehouseId: _sourceWarehouse?.id.trim().isNotEmpty == true
                ? _sourceWarehouse!.id.trim()
                : null,
          )
        : const <_TransferBatchOption>[];
    if (!mounted) return;

    _TransferBatchOption? seedBatch;
    _TransferBinDialogResult? initialResult = isSource
        ? row.sourceBinResult
        : row.destinationBinResult;
    if (!isSource && requiresBatch) {
      final sourceEntries =
          row.sourceBinResult?.entries ?? const <_TransferBinEntry>[];
      final destinationEntries =
          row.destinationBinResult?.entries ?? const <_TransferBinEntry>[];

      if (destinationEntries.isEmpty && sourceEntries.isNotEmpty) {
        // Mirror source batch rows into destination by default so users can
        // assign bins for each selected source batch row.
        initialResult = _TransferBinDialogResult(
          entries: sourceEntries
              .map(
                (src) => _TransferBinEntry(
                  binId: '',
                  binCode: '',
                  quantity: src.quantity,
                  batchId: src.batchId,
                  batchRef: src.batchRef,
                  manufacturerBatchNo: src.manufacturerBatchNo,
                  expiryDate: src.expiryDate,
                  availableQty: src.availableQty,
                ),
              )
              .toList(growable: false),
        );
      }

      final srcEntry = sourceEntries.firstOrNull;
      if (srcEntry != null && srcEntry.batchId.isNotEmpty) {
        seedBatch = _TransferBatchOption(
          id: srcEntry.batchId,
          reference: srcEntry.batchRef,
          manufacturerBatchNo: srcEntry.manufacturerBatchNo,
          mfgDate: '',
          expiryDate: srcEntry.expiryDate,
          availableQty: srcEntry.availableQty,
          connectedBinIds: const <String>{},
        );
      }
    }
    final result = await showDialog<List<InventoryBatchBinDialogLine>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TransferSelectBinsDialog(
        title: 'Select Batches and Bin Locations',
        itemName: row.productNameController.text.trim().isEmpty
            ? 'Item'
            : row.productNameController.text.trim(),
        warehouseName: warehouse?.name ?? '-',
        totalQuantity: lineQty,
        options: options,
        batchOptions: batchOptions,
        initialResult: initialResult,
        isSource: isSource,
        requiresBatch: requiresBatch,
        seedBatch: seedBatch,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final entries = result
          .where((line) => line.binId.trim().isNotEmpty && line.qty > 0)
          .map(
            (line) => _TransferBinEntry(
              binId: line.binId,
              binCode: line.binCode,
              quantity: line.qty,
              batchId: line.batchId,
              batchRef: line.batchRef,
              manufacturerBatchNo: line.manufacturerBatchNo,
              expiryDate: line.expiryDate,
              availableQty: line.availableQty,
            ),
          )
          .toList(growable: false);
      final mappedResult = _TransferBinDialogResult(entries: entries);
      if (isSource) {
        row.sourceBinResult = mappedResult;
      } else {
        row.destinationBinResult = mappedResult;
      }
    });
  }

  Future<void> _seedTransferNumber() async {
    try {
      final rows = await _repository.getTransfers();
      int maxNo = 0;
      for (final row in rows) {
        final raw = (row.transferNumber ?? '').trim().toUpperCase();
        final match = RegExp(r'TO-(\d+)$').firstMatch(raw);
        if (match == null) continue;
        final n = int.tryParse(match.group(1) ?? '') ?? 0;
        if (n > maxNo) maxNo = n;
      }
      final next = (maxNo + 1).toString().padLeft(5, '0');
      if (!mounted) return;
      setState(() {
        _autoNextNumberCtrl.text = next;
        if (_autoGenerateNumber) {
          _transferNumberCtrl.text = '${_autoPrefixCtrl.text}$next';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _autoNextNumberCtrl.text = '00001';
        if (_autoGenerateNumber) {
          _transferNumberCtrl.text = '${_autoPrefixCtrl.text}00001';
        }
      });
    }
  }

  Future<void> _loadInitialProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final rows = await _productsApi.fetchProducts(limit: 60, offset: 0);
      if (!mounted) return;
      setState(() {
        _productOptions = rows
            .map(_ProductOption.fromMap)
            .where((p) => p.id.isNotEmpty && p.name.trim().isNotEmpty)
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _productOptions = const <_ProductOption>[]);
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<List<_ProductOption>> _searchProducts(String query) async {
    final q = query.trim();
    bool matches(_ProductOption p, String needle) {
      final n = needle.toLowerCase();
      final hay =
          '${p.name} ${p.code} ${p.sku} ${p.upc} ${p.ean} ${p.mpn} ${p.isbn} ${p.description}'
              .toLowerCase();
      return hay.contains(n);
    }

    if (q.isEmpty) return _productOptions;
    if (q.length < 2) {
      return _productOptions.where((p) => matches(p, q)).toList();
    }
    try {
      final items = await _productsApi.searchProducts(q, limit: 30);
      final remote = items
          .map(
            (item) => _ProductOption(
              id: item.id ?? '',
              name: item.productName,
              code: item.itemCode,
              categoryId: item.categoryId ?? '',
              sku: item.sku ?? '',
              upc: item.upc ?? '',
              ean: item.ean ?? '',
              mpn: item.mpn ?? '',
              isbn: item.isbn ?? '',
              description: item.salesDescription ?? '',
              trackBinLocation: false,
              trackBatches: true,
            ),
          )
          .where((p) => p.id.isNotEmpty && p.name.trim().isNotEmpty)
          .toList();
      final filteredRemote = remote.where((p) => matches(p, q)).toList();
      if (filteredRemote.isNotEmpty) return filteredRemote;
    } catch (_) {}
    return _productOptions.where((p) => matches(p, q)).toList();
  }

  Future<List<_ProductOption>> _resolveScanMatches(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) return const <_ProductOption>[];
    final normalized = query.toLowerCase();

    bool matchesAnyIdentifier(_ProductOption p) {
      for (final candidate in p.searchableCodes) {
        if (candidate.toLowerCase() == normalized) return true;
      }
      return false;
    }

    bool matchesByName(_ProductOption p) {
      final name = p.name.trim().toLowerCase();
      if (name.isEmpty) return false;
      return name.contains(normalized);
    }

    final localMatch = _productOptions
        .where((p) => matchesAnyIdentifier(p) || matchesByName(p))
        .toList();

    List<_ProductOption> matches = localMatch;
    if (matches.isEmpty) {
      try {
        final remote = await _searchProducts(query);
        matches = remote
            .where((p) => matchesAnyIdentifier(p) || matchesByName(p))
            .toList();
      } catch (_) {
        matches = <_ProductOption>[];
      }
    }
    return matches;
  }

  Future<void> _refreshScanSuggestions(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _scanSuggestions = const <_ProductOption>[];
        _isScanSearching = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _isScanSearching = true);
    final matches = await _resolveScanMatches(query);
    if (!mounted) return;
    setState(() {
      _scanSuggestions = matches;
      _isScanSearching = false;
    });
  }

  Future<void> _applyScanSelection(_ProductOption selected) async {
    final duplicateSelected = _items.asMap().entries.any(
      (entry) => entry.value.productIdController.text.trim() == selected.id,
    );
    if (duplicateSelected) {
      final duplicateName = selected.name.trim().isEmpty
          ? 'This item'
          : selected.name.trim();
      ZerpaiToast.error(
        context,
        '$duplicateName is already included in this transfer order',
      );
      return;
    }

    int targetIndex = _items.indexWhere(
      (row) => row.productIdController.text.trim().isEmpty,
    );
    if (targetIndex < 0) {
      setState(() => _items.add(_newItemRow()));
      targetIndex = _items.length - 1;
    }
    final row = _items[targetIndex];
    setState(() {
      if (!_productOptions.any((p) => p.id == selected.id)) {
        _productOptions = <_ProductOption>[..._productOptions, selected];
      }
      row.productIdController.text = selected.id;
      row.productNameController.text = selected.name;
      row.descriptionController.text = selected.description.trim();
      row.sourceBinResult = null;
      row.destinationBinResult = null;
    });
    if (row.descriptionController.text.trim().isEmpty) {
      final salesDesc = await _loadSalesDescription(selected.id);
      if (!mounted) return;
      if (row.productIdController.text.trim() == selected.id &&
          salesDesc.isNotEmpty) {
        setState(() {
          row.descriptionController.text = salesDesc;
        });
      }
    }
    await _refreshRowStocks(row);
    if (!mounted) return;
    _scanInputCtrl.clear();
    setState(() {
      _scanSuggestions = const <_ProductOption>[];
    });
  }

  Future<void> _refreshRowStocks(_TransferItemDraft row) async {
    final productId = row.productIdController.text.trim();
    if (productId.isEmpty) {
      row.sourceStockController.text = '0.00';
      row.destinationStockController.text = '0.00';
      return;
    }
    try {
      final stocks = await _productsApi.getProductWarehouseStocks(productId);
      if (!mounted) return;
      final source = _warehouseStockFor(stocks, _sourceWarehouse);
      final destination = _warehouseStockFor(stocks, _destinationWarehouse);
      setState(() {
        row.sourceStockController.text = source.toStringAsFixed(2);
        row.destinationStockController.text = destination.toStringAsFixed(2);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        row.sourceStockController.text = '0.00';
        row.destinationStockController.text = '0.00';
      });
    }
  }

  double _warehouseStockFor(
    List<WarehouseStockRow> rows,
    Warehouse? warehouse,
  ) {
    if (warehouse == null) return 0;
    String normalize(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final warehouseId = normalize(warehouse.id);
    final warehouseName = normalize(warehouse.name);
    final warehouseCode = normalize(warehouse.code ?? '');

    final match = rows.where((row) {
      final rowId = normalize(row.id);
      final rowName = normalize(row.name);
      if (rowId.isNotEmpty && warehouseId.isNotEmpty && rowId == warehouseId) {
        return true;
      }
      if (rowName.isNotEmpty &&
          warehouseName.isNotEmpty &&
          rowName == warehouseName) {
        return true;
      }
      if (warehouseCode.isNotEmpty &&
          ((rowId.isNotEmpty && rowId == warehouseCode) ||
              (rowName.isNotEmpty && rowName == warehouseCode))) {
        return true;
      }
      return false;
    }).toList();
    if (match.isEmpty) return 0;
    final row = match.first;

    // Prefer physical available first (live/bin-accurate), then accounting,
    // then on-hand/opening fallbacks if available numbers are not populated.
    final physicalAvailable = row.physical.available;
    if (physicalAvailable > 0) return physicalAvailable;

    final accountingAvailable = row.accounting.available;
    if (accountingAvailable > 0) return accountingAvailable;

    if (row.physical.onHand > 0) return row.physical.onHand;
    if (row.accounting.onHand > 0) return row.accounting.onHand;
    if (row.openingStock > 0) return row.openingStock;

    return 0;
  }

  Future<void> _refreshAllRowsStocks() async {
    for (final row in _items) {
      await _refreshRowStocks(row);
    }
  }

  Future<void> _openBulkItemsDialog() async {
    if (_loadingProducts) return;
    if (_productOptions.isEmpty) {
      await _loadInitialProducts();
    }
    if (!mounted) return;
    if (_productOptions.isEmpty) return;

    ref.read(itemsControllerProvider.notifier).loadLookupData();

    final items = _productOptions
        .map(
          (p) => Item(
            id: p.id,
            type: 'goods',
            productName: p.name,
            itemCode: p.code,
            unitId: '',
            categoryId: p.categoryId.isEmpty ? null : p.categoryId,
            salesDescription: p.description,
            sku: p.sku.isEmpty ? null : p.sku,
            upc: p.upc.isEmpty ? null : p.upc,
            ean: p.ean.isEmpty ? null : p.ean,
            mpn: p.mpn.isEmpty ? null : p.mpn,
            isbn: p.isbn.isEmpty ? null : p.isbn,
          ),
        )
        .toList(growable: false);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BulkItemsDialog(
        products: items,
        onItemsSelected: (selectedItems) async {
          if (!mounted || selectedItems.isEmpty) return;
          final selections = selectedItems.entries
              .map((entry) {
                final item = entry.key;
                final product = _productOptions.firstWhere(
                  (p) => p.id == item.id,
                );
                return (product: product, quantity: entry.value);
              })
              .toList(growable: false);
          await _applyBulkItemsSelection(selections);
        },
      ),
    );
  }

  Future<void> _applyBulkItemsSelection(
    List<({_ProductOption product, int quantity})> selections,
  ) async {
    if (selections.isEmpty) return;

    final existingProductIds = _items
        .map((row) => row.productIdController.text.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final uniqueSelections = selections
        .where((selection) {
          if (existingProductIds.contains(selection.product.id)) return false;
          existingProductIds.add(selection.product.id);
          return true;
        })
        .toList(growable: false);

    if (uniqueSelections.isEmpty) {
      if (mounted) {
        ZerpaiToast.error(
          context,
          'Duplicate items are not allowed. Remove the following items to proceed:',
        );
      }
      return;
    }

    setState(() {
      for (final selection in uniqueSelections) {
        final targetIndex = _items.indexWhere(
          (row) => row.productIdController.text.trim().isEmpty,
        );
        final row = targetIndex >= 0
            ? _items[targetIndex]
            : (() {
                final newRow = _newItemRow();
                _items.add(newRow);
                return newRow;
              })();

        row.productIdController.text = selection.product.id;
        row.productNameController.text = selection.product.name;
        row.descriptionController.text = selection.product.description.trim();
        row.quantityController.text = _formatQuantityText(
          selection.quantity,
          maxDecimals: 2,
        );
        row.sourceBinResult = null;
        row.destinationBinResult = null;
      }
    });

    for (final selection in uniqueSelections) {
      final row = _items.firstWhere(
        (r) => r.productIdController.text.trim() == selection.product.id,
      );
      if (row.descriptionController.text.trim().isEmpty) {
        final salesDesc = await _loadSalesDescription(selection.product.id);
        if (!mounted) return;
        if (row.productIdController.text.trim() == selection.product.id &&
            salesDesc.isNotEmpty) {
          setState(() => row.descriptionController.text = salesDesc);
        }
      }
      await _refreshRowStocks(row);
    }
  }

  Future<String> _loadSalesDescription(String productId) async {
    try {
      final payload = await _productsApi.fetchProductById(productId);
      if (payload == null) return '';
      return (payload['sales_description'] ??
              payload['salesDescription'] ??
              payload['description'] ??
              '')
          .toString()
          .trim();
    } catch (_) {
      return '';
    }
  }

  _ProductOption? _findSelectedProductOption(String productId) {
    final id = productId.trim();
    if (id.isEmpty) return null;
    for (final opt in _productOptions) {
      if (opt.id == id) return opt;
    }
    return null;
  }

  String get _dateText {
    final d = _transferDate.day.toString().padLeft(2, '0');
    final m = _transferDate.month.toString().padLeft(2, '0');
    final y = _transferDate.year.toString();
    return '$d-$m-$y';
  }

  bool _validate({bool showToast = true}) {
    if (_transferNumberCtrl.text.trim().isEmpty) {
      if (showToast) {
        ZerpaiToast.error(context, 'Please enter the Transfer Order number');
      }
      return false;
    }
    if (_sourceWarehouse == null) {
      if (showToast)
        ZerpaiToast.error(context, 'Please select source warehouse');
      return false;
    }
    if (_destinationWarehouse == null) {
      if (showToast) {
        ZerpaiToast.error(context, 'Please select destination warehouse');
      }
      return false;
    }
    if (_sourceWarehouse!.id == _destinationWarehouse!.id) {
      if (showToast) {
        ZerpaiToast.error(
          context,
          'Transfers cannot be made within the same location. Please choose a different one and proceed.',
        );
      }
      return false;
    }

    final duplicateNames = <String>[];
    final seen = <String, String>{};
    for (final item in _items) {
      final productId = item.productIdController.text.trim();
      final productName = item.productNameController.text.trim();
      if (productId.isEmpty) continue;
      if (seen.containsKey(productId)) {
        final label = productName.isNotEmpty
            ? productName
            : (seen[productId] ?? productId);
        if (!duplicateNames.contains(label)) duplicateNames.add(label);
      } else {
        seen[productId] = productName.isNotEmpty ? productName : productId;
      }
    }
    if (duplicateNames.isNotEmpty) {
      if (showToast) {
        ZerpaiToast.error(
          context,
          'Duplicate items are not allowed. Remove the following items to proceed: ${duplicateNames.join(', ')}',
        );
      }
      return false;
    }

    final hasAnyZeroQuantityItem = _items.any((item) {
      final hasProduct = item.productIdController.text.trim().isNotEmpty;
      final qty = double.tryParse(item.quantityController.text.trim()) ?? 0;
      return hasProduct && qty <= 0;
    });
    if (hasAnyZeroQuantityItem) {
      if (showToast) {
        ZerpaiToast.error(
          context,
          'Transactions cannot be created with Zero Quantity.',
        );
      }
      return false;
    }

    final hasMissingSourceBinsForSelectedItems = _items.any((item) {
      final hasProduct = item.productIdController.text.trim().isNotEmpty;
      final qty = double.tryParse(item.quantityController.text.trim()) ?? 0;
      final selected = item.sourceBinResult?.totalQuantity ?? 0;
      return hasProduct &&
          qty > 0 &&
          (_isBinTrackedRow(item) || _isBatchTrackedRow(item)) &&
          (item.sourceBinResult == null || (selected - qty).abs() > 0.0001);
    });
    if (hasMissingSourceBinsForSelectedItems) {
      if (showToast) {
        ZerpaiToast.error(
          context,
          'Make sure you have selected source bins/batches for tracked items.',
        );
      }
      return false;
    }

    final hasMissingDestinationBinsForSelectedItems = _items.any((item) {
      final hasProduct = item.productIdController.text.trim().isNotEmpty;
      final qty = double.tryParse(item.quantityController.text.trim()) ?? 0;
      final selected = item.destinationBinResult?.totalQuantity ?? 0;
      return hasProduct &&
          qty > 0 &&
          (_isBinTrackedRow(item) || _isBatchTrackedRow(item)) &&
          (item.destinationBinResult == null ||
              (selected - qty).abs() > 0.0001);
    });
    if (hasMissingDestinationBinsForSelectedItems) {
      if (showToast) {
        ZerpaiToast.error(
          context,
          'Make sure you have selected destination bins/batches for tracked items.',
        );
      }
      return false;
    }

    final hasAtLeastOneValidItem = _items.any((item) {
      final productName = item.productNameController.text.trim();
      final qty = double.tryParse(item.quantityController.text.trim()) ?? 0;
      return productName.isNotEmpty && qty > 0;
    });
    if (!hasAtLeastOneValidItem) {
      if (showToast) {
        ZerpaiToast.error(
          context,
          'Add at least one row with item and quantity > 0',
        );
      }
      return false;
    }
    return true;
  }

  List<StockTransferItem> _buildPayloadItems() {
    final List<StockTransferItem> payload = <StockTransferItem>[];
    for (final row in _items) {
      final productName = row.productNameController.text.trim();
      final productId = row.productIdController.text.trim().isEmpty
          ? productName
          : row.productIdController.text.trim();
      final qty = double.tryParse(row.quantityController.text.trim()) ?? 0;
      if (productId.isEmpty || qty <= 0) continue;
      final sourceEntries =
          row.sourceBinResult?.entries ?? const <_TransferBinEntry>[];
      final destinationEntries =
          row.destinationBinResult?.entries ?? const <_TransferBinEntry>[];
      final sourceBatches = sourceEntries
          .where((entry) => entry.binId.trim().isNotEmpty && entry.quantity > 0)
          .map(
            (entry) => TransferOrderSourceBatch(
              batchId: entry.batchId.trim(),
              layerId: '',
              warehouseId: _sourceWarehouse?.id.trim() ?? '',
              binId: entry.binId.trim(),
              qty: entry.quantity,
            ),
          )
          .toList(growable: false);
      final destinationBatches = destinationEntries
          .where((entry) => entry.binId.trim().isNotEmpty && entry.quantity > 0)
          .map(
            (entry) => TransferOrderDestinationBatch(
              sourceBatchId: entry.batchId.trim(),
              destinationBatchId: entry.batchId.trim(),
              destinationWarehouseId: _destinationWarehouse?.id.trim() ?? '',
              destinationBinId: entry.binId.trim(),
              qty: entry.quantity,
            ),
          )
          .toList(growable: false);
      payload.add(
        StockTransferItem(
          productId: productId,
          productName: productName.isEmpty ? null : productName,
          quantity: qty,
          sourceBatches: sourceBatches,
          destinationBatches: destinationBatches,
        ),
      );
    }
    return payload;
  }

  Future<void> _save({
    required bool initiate,
    String? forcedStatus,
    required String actionKey,
  }) async {
    if (_isSaving) return;
    if (!_validate()) return;

    final items = _buildPayloadItems();
    if (items.isEmpty) {
      ZerpaiToast.error(context, 'No valid transfer items to save');
      return;
    }

    setState(() {
      _isSaving = true;
      _savingAction = actionKey;
    });
    try {
      final now = DateTime.now();
      final draft = StockTransfer(
        id: _editingTransfer?.id ?? '',
        transferNumber: _transferNumberCtrl.text.trim().isEmpty
            ? null
            : _transferNumberCtrl.text.trim(),
        fromWarehouseId: _sourceWarehouse!.id,
        fromWarehouseName: _sourceWarehouse!.name,
        toWarehouseId: _destinationWarehouse!.id,
        toWarehouseName: _destinationWarehouse!.name,
        transferDate: _transferDate,
        status: 'draft',
        items: items,
        notes: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      final isEdit = _editingTransfer != null;
      final saved = isEdit
          ? await _repository.updateTransfer(_editingTransfer!.id, draft)
          : await _repository.createTransfer(draft);
      if (initiate) {
        await _repository.initiateTransfer(saved.id);
      }
      if (!mounted) return;
      if (!isEdit && _autoGenerateNumber) {
        final current = int.tryParse(_autoNextNumberCtrl.text) ?? 1;
        _autoNextNumberCtrl.text = (current + 1).toString().padLeft(5, '0');
      }
      ZerpaiToast.saved(context, 'Transfer order');
      if (isEdit) {
        context.go('/$_orgId/inventory/transfer-orders/${saved.id}');
      } else {
        context.go('/$_orgId/inventory/transfer-orders');
      }
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to save transfer order');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savingAction = null;
        });
      }
    }
  }

  Future<void> _openItemDetailsDrawerForRow(
    BuildContext rowContext,
    int rowIndex,
  ) async {
    if (rowIndex < 0 || rowIndex >= _items.length) return;
    final itemId = _items[rowIndex].productIdController.text.trim();
    if (itemId.isEmpty) {
      ZerpaiToast.error(context, 'Select an item first');
      return;
    }
    try {
      final item = await ref
          .read(itemsControllerProvider.notifier)
          .ensureItemLoaded(itemId, forceRefresh: true);
      if (!mounted) return;
      if (item == null) {
        ZerpaiToast.error(context, 'Failed to load item details.');
        return;
      }
      ref.read(itemDetailsSidebarProvider.notifier).state = item;
      final drawerContext = _drawerHostContext ?? rowContext;
      final scaffoldState = Scaffold.maybeOf(drawerContext);
      scaffoldState?.openEndDrawer();
    } catch (_) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to load item details.');
    }
  }

  void _openEditItemForRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= _items.length) return;
    final itemId = _items[rowIndex].productIdController.text.trim();
    if (itemId.isEmpty) {
      ZerpaiToast.error(context, 'Select an item first');
      return;
    }
    final targetPath = '/$_orgId/items/edit/$itemId';
    if (kIsWeb) {
      web.window.open(targetPath, '_blank');
      return;
    }
    context.push(targetPath);
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(warehousesProvider);
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      endDrawer: const ItemDetailsSidebar(),
      actions: const [],
      child: Builder(
        builder: (drawerHostContext) {
          _drawerHostContext = drawerHostContext;
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const Divider(height: 1, color: AppTheme.borderColor),
                Expanded(
                  child: warehousesAsync.when(
                    data: (warehouses) {
                      if (_isEditMode && _isHydratingExisting) {
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                          children: const [_TransferOrderCreateSkeleton()],
                        );
                      }
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        children: [_formBody(warehouses)],
                      );
                    },
                    loading: () => ListView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      children: const [_TransferOrderCreateSkeleton()],
                    ),
                    error: (_, __) => ListView(
                      padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                      children: [
                        Text(
                          'Unable to load locations.',
                          style: TextStyle(color: AppTheme.errorRedDark),
                        ),
                      ],
                    ),
                  ),
                ),
                _footerActions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 12, 14),
      child: Row(
        children: [
          const Icon(LucideIcons.filePlus2, size: 20, color: AppTheme.textBody),
          const SizedBox(width: 8),
          Text(
            _isEditMode ? 'Edit Transfer Order' : 'New Transfer Order',
            style: AppTheme.pageTitle.copyWith(fontSize: 22),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              if (_isEditMode && _editingTransfer != null) {
                context.go(
                  '/$_orgId/inventory/transfer-orders/${_editingTransfer!.id}',
                );
                return;
              }
              context.go('/$_orgId/inventory/transfer-orders');
            },
            icon: const Icon(LucideIcons.x, size: 20),
            color: AppTheme.textSecondary,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Future<void> _openNumberSettingsDialog() async {
    bool autoGenerate = _autoGenerateNumber;
    final prefixCtrl = TextEditingController(text: _autoPrefixCtrl.text);
    final nextCtrl = TextEditingController(text: _autoNextNumberCtrl.text);
    bool isSaving = false;
    String? inlineError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              alignment: Alignment.topCenter,
              backgroundColor: AppTheme.backgroundColor,
              surfaceTintColor: AppTheme.backgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              insetPadding: EdgeInsets.zero,
              child: SizedBox(
                width: 580,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Center(
                                child: Text(
                                  'Configure Transfer Order# Preferences',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              icon: const Icon(
                                LucideIcons.x,
                                size: 18,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Auto-generating transfer orders numbers can save your time. '
                              'Would you like to change your current setting?',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            RadioScope<bool>(
                              value: autoGenerate,
                              onChanged: (value) {
                                setDialogState(() {
                                  autoGenerate = value;
                                  inlineError = null;
                                });
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      RadioGroupItem<bool>(
                                        value: true,
                                        label:
                                            'Auto-generate transfer orders numbers',
                                        activeColor: AppTheme.primaryBlue,
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      SizedBox(width: 6),
                                      ZTooltip(
                                        message:
                                            'Auto-generates Transfer Order numbers using Prefix and Next Number.',
                                      ),
                                    ],
                                  ),
                                  if (autoGenerate)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 18,
                                        top: 6,
                                        bottom: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 104,
                                            child: CustomTextField(
                                              label: 'Prefix',
                                              controller: prefixCtrl,
                                              enabled: !isSaving,
                                              contentCase:
                                                  ContentCase.uppercase,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          SizedBox(
                                            width: 240,
                                            child: CustomTextField(
                                              label: 'Next Number',
                                              controller: nextCtrl,
                                              enabled: !isSaving,
                                              keyboardType:
                                                  TextInputType.number,
                                              forceUppercase: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  const RadioGroupItem<bool>(
                                    value: false,
                                    label:
                                        'Manually enter transfer orders numbers for each entry',
                                    activeColor: AppTheme.primaryBlue,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ),
                            if (inlineError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                inlineError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      final trimmedPrefix = prefixCtrl.text
                                          .trim()
                                          .toUpperCase();
                                      final parsedNext = int.tryParse(
                                        nextCtrl.text.trim(),
                                      );

                                      if (autoGenerate) {
                                        if (trimmedPrefix.isEmpty) {
                                          setDialogState(() {
                                            inlineError =
                                                'Prefix is required for auto-generation.';
                                          });
                                          return;
                                        }
                                        if (parsedNext == null ||
                                            parsedNext <= 0) {
                                          setDialogState(() {
                                            inlineError =
                                                'Next Number must be a positive number.';
                                          });
                                          return;
                                        }
                                      }

                                      setDialogState(() {
                                        isSaving = true;
                                        inlineError = null;
                                      });

                                      setState(() {
                                        _autoGenerateNumber = autoGenerate;
                                        _autoPrefixCtrl.text = autoGenerate
                                            ? trimmedPrefix
                                            : (trimmedPrefix.isEmpty
                                                  ? 'TO-'
                                                  : trimmedPrefix);
                                        _autoNextNumberCtrl.text =
                                            (parsedNext ?? 1)
                                                .toString()
                                                .padLeft(5, '0');
                                        if (_autoGenerateNumber) {
                                          _transferNumberCtrl.text =
                                              '${_autoPrefixCtrl.text}${_autoNextNumberCtrl.text}';
                                        }
                                      });

                                      Navigator.of(dialogContext).pop();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentGreen,
                                foregroundColor: AppTheme.backgroundColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    prefixCtrl.dispose();
    nextCtrl.dispose();
  }

  Widget _formBody(List<Warehouse> warehouses) {
    final hasBothLocationsSelected =
        _sourceWarehouse != null && _destinationWarehouse != null;
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 1100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inlineLabeledField(
              label: 'Transfer Order#*',
              requiredLabel: true,
              child: SizedBox(
                width: 330,
                child: CustomTextField(
                  controller: _transferNumberCtrl,
                  readOnly: _autoGenerateNumber,
                  forceUppercase: true,
                  suffixWidget: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ZTooltip(
                      message:
                          'Click here to enable or disable auto-generation of Transfer Order numbers.',
                      child: InkWell(
                        onTap: _openNumberSettingsDialog,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.settings,
                            size: 16,
                            color: AppTheme.primaryBlueDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _inlineLabeledField(
              label: 'Date',
              child: SizedBox(
                width: 330,
                child: InkWell(
                  key: _dateKey,
                  onTap: () async {
                    final picked = await ZerpaiDatePicker.show(
                      context,
                      initialDate: _transferDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      targetKey: _dateKey,
                    );
                    if (picked == null) return;
                    setState(() {
                      _transferDate = picked;
                      _dateCtrl.text = _dateText;
                    });
                  },
                  child: IgnorePointer(
                    child: CustomTextField(
                      controller: _dateCtrl,
                      readOnly: true,
                      suffixWidget: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _inlineLabeledField(
              label: 'Reason',
              child: SizedBox(
                width: 330,
                child: CustomTextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  height: 80,
                  contentCase: ContentCase.sentence,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppTheme.borderColor),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 330,
                  child: _labeledField(
                    label: 'Source Warehouse*',
                    requiredLabel: true,
                    child: FormDropdown<Warehouse>(
                      value: _sourceWarehouse,
                      items: warehouses.where((w) => w.isActive).toList(),
                      onChanged: _onSourceWarehouseChanged,
                      hint: 'Select source warehouse',
                      displayStringForValue: (w) => w.name,
                    ),
                  ),
                ),
                const SizedBox(width: 36),
                ZTooltip(
                  message: 'Swap Source Warehouse and Destination Warehouse',
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(LucideIcons.repeat2, size: 16),
                      onPressed: () {
                        setState(() {
                          final source = _sourceWarehouse;
                          _sourceWarehouse = _destinationWarehouse;
                          _destinationWarehouse = source;
                        });
                        _refreshAllRowsStocks();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 36),
                SizedBox(
                  width: 330,
                  child: _labeledField(
                    label: 'Destination Warehouse*',
                    requiredLabel: true,
                    child: FormDropdown<Warehouse>(
                      value: _destinationWarehouse,
                      items: warehouses.where((w) => w.isActive).toList(),
                      onChanged: _onDestinationWarehouseChanged,
                      hint: 'Select destination warehouse',
                      displayStringForValue: (w) => w.name,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_isLocationMismatch)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: ZTooltip(
                      message:
                          'Transfers cannot be made within the same location. Please choose a different one and proceed.',
                      child: Icon(
                        LucideIcons.alertTriangle,
                        size: 18,
                        color: AppTheme.errorRedDark,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 330,
                  child: _locationAddressBlock(_sourceWarehouse),
                ),
                const SizedBox(width: 102),
                SizedBox(
                  width: 330,
                  child: _locationAddressBlock(_destinationWarehouse),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 1030,
              child: IgnorePointer(
                ignoring: !hasBothLocationsSelected,
                child: Opacity(
                  opacity: hasBothLocationsSelected ? 1 : 0.35,
                  child: _itemsSection(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 14),
            IgnorePointer(
              ignoring: !hasBothLocationsSelected,
              child: Opacity(
                opacity: hasBothLocationsSelected ? 1 : 0.35,
                child: _attachFilesSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: AppTheme.tableHeaderBg,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Item Table',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    setState(() {
                      _showScanPanel = !_showScanPanel;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.scan,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Scan Item',
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
              ],
            ),
          ),
          if (_showScanPanel)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.scan,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Item Details',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          _scanDebounce?.cancel();
                          setState(() {
                            _showScanPanel = false;
                            _scanInputCtrl.clear();
                            _scanSuggestions = const <_ProductOption>[];
                            _isScanSearching = false;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Close Scan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                LucideIcons.x,
                                size: 13,
                                color: AppTheme.errorRedDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 540,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 34,
                          child: TextField(
                            controller: _scanInputCtrl,
                            autofocus: true,
                            onTap: () {
                              if (_scanInputCtrl.text.trim().isEmpty) {
                                setState(() {
                                  _scanSuggestions = const <_ProductOption>[];
                                });
                              }
                            },
                            onChanged: (value) {
                              _scanDebounce?.cancel();
                              _scanDebounce = Timer(
                                const Duration(milliseconds: 220),
                                () {
                                  _refreshScanSuggestions(value);
                                },
                              );
                            },
                            onSubmitted: (_) async {
                              if (_scanSuggestions.isNotEmpty) {
                                await _applyScanSelection(
                                  _scanSuggestions.first,
                                );
                                return;
                              }
                              final query = _scanInputCtrl.text.trim();
                              if (query.isNotEmpty) {
                                ZerpaiToast.error(
                                  context,
                                  'No matching item found. Select from dropdown results.',
                                );
                              }
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Search/scan by name, SKU, code, barcode',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Builder(
                            builder: (context) {
                              final query = _scanInputCtrl.text.trim();
                              final visibleSuggestions = query.isEmpty
                                  ? _productOptions
                                  : _scanSuggestions;

                              if (_isScanSearching) {
                                return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: 4,
                                  itemBuilder: (_, __) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 12,
                                          width: 180,
                                          decoration: BoxDecoration(
                                            color: AppTheme.tableHeaderBg,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          height: 10,
                                          width: 90,
                                          decoration: BoxDecoration(
                                            color: AppTheme.tableHeaderBg,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              if (visibleSuggestions.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    query.isEmpty
                                        ? 'No products loaded yet'
                                        : 'No matching items',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: visibleSuggestions.length,
                                itemBuilder: (context, index) {
                                  final item = visibleSuggestions[index];
                                  return InkWell(
                                    onTap: () => _applyScanSelection(item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (item.code.trim().isNotEmpty ||
                                              item.sku.trim().isNotEmpty)
                                            Text(
                                              '${item.code.trim()} ${item.sku.trim()}'
                                                  .trim(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 52,
                  child: Text(
                    'ITEM DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Text(
                    'CURRENT AVAILABILITY',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'TRANSFER QUANTITY',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 34),
              ],
            ),
          ),
          ...List<Widget>.generate(_items.length, (index) {
            final row = _items[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: AppTheme.borderColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.tableHeaderBg,
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(
                      LucideIcons.image,
                      size: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: row.productIdController.text.trim().isEmpty
                                  ? SizedBox(
                                      height: 38,
                                      child: FormDropdown<_ProductOption>(
                                        value: _findSelectedProductOption(
                                          row.productIdController.text,
                                        ),
                                        items: _productOptions,
                                        hint:
                                            'Type or click to select an item.',
                                        isLoading: _loadingProducts,
                                        onSearch: _searchProducts,
                                        displayStringForValue: (opt) =>
                                            opt.label,
                                        searchStringForValue: (opt) =>
                                            '${opt.name} ${opt.code}',
                                        onChanged: (value) async {
                                          if (value == null) return;
                                          final selectedProductId = value.id;
                                          final duplicateSelected = _items
                                              .asMap()
                                              .entries
                                              .any(
                                                (entry) =>
                                                    entry.key != index &&
                                                    entry
                                                            .value
                                                            .productIdController
                                                            .text
                                                            .trim() ==
                                                        selectedProductId,
                                              );
                                          if (duplicateSelected) {
                                            final duplicateName =
                                                value.name.trim().isEmpty
                                                ? 'This item'
                                                : value.name.trim();
                                            ZerpaiToast.error(
                                              context,
                                              '$duplicateName is already included in this transfer order',
                                            );
                                            return;
                                          }
                                          setState(() {
                                            if (!_productOptions.any(
                                              (p) => p.id == value.id,
                                            )) {
                                              _productOptions =
                                                  <_ProductOption>[
                                                    ..._productOptions,
                                                    value,
                                                  ];
                                            }
                                            row.productIdController.text =
                                                value.id;
                                            row.productNameController.text =
                                                value.name;
                                            row.descriptionController.text =
                                                value.description.trim();
                                            row.sourceBinResult = null;
                                            row.destinationBinResult = null;
                                          });
                                          if (row.descriptionController.text
                                              .trim()
                                              .isEmpty) {
                                            final salesDesc =
                                                await _loadSalesDescription(
                                                  selectedProductId,
                                                );
                                            if (!mounted) return;
                                            if (row.productIdController.text
                                                        .trim() ==
                                                    selectedProductId &&
                                                salesDesc.isNotEmpty) {
                                              setState(() {
                                                row.descriptionController.text =
                                                    salesDesc;
                                              });
                                            }
                                          }
                                          await _refreshRowStocks(row);
                                        },
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                        top: 2,
                                        left: 2,
                                      ),
                                      child: Text(
                                        row.productNameController.text
                                                .trim()
                                                .isEmpty
                                            ? 'Item'
                                            : row.productNameController.text
                                                  .trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 29 / 2,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                            ),
                            if (row.productIdController.text
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  splashColor: AppTheme.backgroundColor
                                      .withValues(alpha: 0),
                                  highlightColor: AppTheme.primaryBlueDark,
                                  hoverColor: AppTheme.primaryBlueDark,
                                ),
                                child: PopupMenuButton<String>(
                                  tooltip: '',
                                  color: AppTheme.backgroundColor,
                                  elevation: 6,
                                  offset: const Offset(0, 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 168,
                                    maxWidth: 168,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _openEditItemForRow(index);
                                      return;
                                    }
                                    if (value == 'details') {
                                      _openItemDetailsDrawerForRow(
                                        context,
                                        index,
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      height: 34,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      labelTextStyle:
                                          WidgetStateProperty.resolveWith<
                                            TextStyle?
                                          >((states) {
                                            final hovered =
                                                states.contains(
                                                  WidgetState.hovered,
                                                ) ||
                                                states.contains(
                                                  WidgetState.focused,
                                                );
                                            return TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: hovered
                                                  ? AppTheme.backgroundColor
                                                  : AppTheme.textPrimary,
                                            );
                                          }),
                                      child: const Text('Edit Item'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'details',
                                      height: 34,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      labelTextStyle:
                                          WidgetStateProperty.resolveWith<
                                            TextStyle?
                                          >((states) {
                                            final hovered =
                                                states.contains(
                                                  WidgetState.hovered,
                                                ) ||
                                                states.contains(
                                                  WidgetState.focused,
                                                );
                                            return TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: hovered
                                                  ? AppTheme.backgroundColor
                                                  : AppTheme.textPrimary,
                                            );
                                          }),
                                      child: const Text('View Item Details'),
                                    ),
                                  ],
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    child: const Icon(
                                      LucideIcons.moreHorizontal,
                                      size: 10,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: _items.length <= 1
                                    ? null
                                    : () {
                                        setState(() {
                                          final removed = _items.removeAt(
                                            index,
                                          );
                                          removed.dispose();
                                        });
                                      },
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.textSecondary.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: row.descriptionController,
                          hintText: 'Add a description to your item',
                          contentCase: ContentCase.sentence,
                          hideBorderDefault: true,
                          fillColor: AppTheme.tableHeaderBg,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 20,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Source Stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text('${row.sourceStockController.text} pcs'),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: AppTheme.borderColor,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Destination Stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                '${row.destinationStockController.text} pcs',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomTextField(
                          controller: row.quantityController,
                          hintText: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.right,
                          onTap: () {
                            final text = row.quantityController.text.trim();
                            if (text == '0' ||
                                text == '0.0' ||
                                text == '0.00') {
                              row.quantityController.clear();
                            }
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 6),
                        Builder(
                          builder: (_) {
                            final qty =
                                double.tryParse(
                                  row.quantityController.text.trim(),
                                ) ??
                                0;
                            final isBatchTracked = _isBatchTrackedRow(row);
                            final isBinTracked = _isBinTrackedRow(row);
                            final usesBatchBinModal =
                                qty > 0 && (isBinTracked || isBatchTracked);
                            if (usesBatchBinModal) {
                              final sourceSummary = _binSummaryText(
                                row.sourceBinResult,
                              );
                              final destinationSummary = _binSummaryText(
                                row.destinationBinResult,
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (sourceSummary.isNotEmpty)
                                    InkWell(
                                      onTap: () =>
                                          _openBinModal(index, isSource: true),
                                      child: Text(
                                        sourceSummary,
                                        style: const TextStyle(
                                          color: AppTheme.primaryBlueDark,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  else
                                    InkWell(
                                      onTap: () =>
                                          _openBinModal(index, isSource: true),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          const Icon(
                                            LucideIcons.alertTriangle,
                                            size: 14,
                                            color: AppTheme.errorRedDark,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Select source bins',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.primaryBlueDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  if (destinationSummary.isNotEmpty)
                                    InkWell(
                                      onTap: () =>
                                          _openBinModal(index, isSource: false),
                                      child: Text(
                                        destinationSummary,
                                        style: const TextStyle(
                                          color: AppTheme.primaryBlueDark,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  else
                                    InkWell(
                                      onTap: () =>
                                          _openBinModal(index, isSource: false),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          const Icon(
                                            LucideIcons.alertTriangle,
                                            size: 14,
                                            color: AppTheme.errorRedDark,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Select destination bins',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.primaryBlueDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }
                            if (qty <= 0 ||
                                (!isBinTracked && !isBatchTracked)) {
                              return const SizedBox.shrink();
                            }
                            return InkWell(
                              onTap: () => _openBinModal(index, isSource: true),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Icon(
                                    LucideIcons.alertTriangle,
                                    size: 14,
                                    color: AppTheme.errorRedDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Select source bins',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.primaryBlueDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _items.add(_newItemRow())),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_circle,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Add New Row',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _openBulkItemsDialog,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_circle,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Add Items in Bulk',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.w500,
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

  Widget _attachFilesSection() {
    return AttachmentSection(
      title: 'Attach File(s) to Transfer Order',
      files: _attachedFiles,
      onFilesChanged: (updated) => setState(() => _attachedFiles = updated),
      maxFiles: 5,
      allowedExtensions: const <String>['pdf', 'jpg', 'jpeg', 'png'],
      titleFontSize: 12,
      helperFontSize: 12,
    );
  }

  Widget _footerActions() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () => _save(initiate: false, actionKey: 'draft'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.backgroundColor,
                foregroundColor: AppTheme.textPrimary,
                elevation: 0,
                minimumSize: const Size(0, 34),
                maximumSize: const Size(double.infinity, 34),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                side: const BorderSide(color: AppTheme.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: _isSaving && _savingAction == 'draft'
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save as Draft'),
            ),
          ),
          const SizedBox(width: 8),
          _buildInitiateSplitButton(),
          const SizedBox(width: 8),
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () => context.go('/$_orgId/inventory/transfer-orders'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 34),
                maximumSize: const Size(double.infinity, 34),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppTheme.borderColor),
                foregroundColor: AppTheme.textPrimary,
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitiateSplitButton() {
    return ZSplitActionMenuButton(
      height: 34,
      triggerLabel: 'Initiate transfer',
      isDisabled: _isSaving,
      onPrimaryPressed: () => _save(initiate: true, actionKey: 'initiate'),
      menuItems: [
        ZSplitActionMenuItem(
          label: 'Save and Submit',
          isLoading: _isSaving && _savingAction == 'save_submit',
          onPressed: () => _save(
            initiate: true,
            forcedStatus: 'pending',
            actionKey: 'save_submit',
          ),
        ),
        ZSplitActionMenuItem(
          label: 'Mark as Transferred',
          isLoading: _isSaving && _savingAction == 'mark_transferred',
          onPressed: () => _save(
            initiate: true,
            forcedStatus: 'in_transit',
            actionKey: 'mark_transferred',
          ),
        ),
      ],
    );
  }

  Widget _labeledField({
    required String label,
    required Widget child,
    bool requiredLabel = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: requiredLabel ? AppTheme.errorRedDark : AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _inlineLabeledField({
    required String label,
    required Widget child,
    bool requiredLabel = false,
    double labelWidth = 180,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: requiredLabel
                  ? AppTheme.errorRedDark
                  : AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _locationAddressBlock(Warehouse? warehouse) {
    final raw = (warehouse?.address ?? '').trim();
    if (raw.isEmpty) {
      return const SizedBox.shrink();
    }
    final lines = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _TransferSelectBinsDialog extends StatefulWidget {
  const _TransferSelectBinsDialog({
    required this.title,
    required this.itemName,
    required this.warehouseName,
    required this.totalQuantity,
    required this.options,
    required this.batchOptions,
    required this.initialResult,
    required this.isSource,
    required this.requiresBatch,
    this.seedBatch,
  });

  final String title;
  final String itemName;
  final String warehouseName;
  final double totalQuantity;
  final List<_TransferBinOption> options;
  final List<_TransferBatchOption> batchOptions;
  final _TransferBinDialogResult? initialResult;
  final bool isSource;
  final bool requiresBatch;
  final _TransferBatchOption? seedBatch;

  @override
  State<_TransferSelectBinsDialog> createState() =>
      _TransferSelectBinsDialogState();
}

class _TransferSelectBinsDialogState extends State<_TransferSelectBinsDialog> {
  final List<_BinRowDraft> _rows = <_BinRowDraft>[];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialResult;
    if (initial != null && initial.entries.isNotEmpty) {
      for (final entry in initial.entries) {
        _rows.add(
          _BinRowDraft(
            selectedBinId: entry.binId,
            quantity: _formatQuantityText(entry.quantity, maxDecimals: 2),
            batchId: entry.batchId,
            batchRef: entry.batchRef,
            manufacturerBatchNo: entry.manufacturerBatchNo,
            expiryDate: entry.expiryDate,
            availableQty: entry.availableQty,
          ),
        );
      }
    }
    if (_rows.isEmpty) {
      final seed = widget.seedBatch;
      _rows.add(
        _BinRowDraft(
          batchId: seed?.id ?? '',
          batchRef: seed?.reference ?? '',
          manufacturerBatchNo: seed?.manufacturerBatchNo ?? '',
          expiryDate: seed?.expiryDate ?? '',
          availableQty: seed?.availableQty ?? 0,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialLines = _rows
        .map((row) {
          final selected = widget.options
              .where((option) => option.id == row.selectedBinId)
              .firstOrNull;
          return InventoryBatchBinDialogLine(
            binId: row.selectedBinId,
            binCode: selected?.code ?? '',
            qty: double.tryParse(row.quantityController.text.trim()) ?? 0,
            batchId: row.batchId,
            batchRef: row.batchRef,
            manufacturerBatchNo: row.manufacturerBatchNo,
            expiryDate: row.expiryDate,
            availableQty: row.availableQty,
          );
        })
        .toList(growable: false);
    return InventoryBatchBinSelectionDialog(
      title: widget.title,
      locationName: widget.warehouseName,
      locationContextLabel: 'Warehouse',
      itemName: widget.itemName,
      totalQuantity: widget.totalQuantity,
      options: widget.options
          .map(
            (option) => InventoryBatchBinDialogBinOption(
              id: option.id,
              code: option.code,
              stock: 0,
            ),
          )
          .toList(growable: false),
      batchOptions: widget.batchOptions
          .map(
            (option) => InventoryBatchBinDialogBatchOption(
              id: option.id,
              reference: option.reference,
              manufacturerBatchNo: option.manufacturerBatchNo,
              mfgDate: option.mfgDate,
              expiryDate: option.expiryDate,
              availableQty: option.availableQty,
              connectedBinIds: option.connectedBinIds,
            ),
          )
          .toList(growable: false),
      initialLines: initialLines,
      isSource: widget.isSource,
      requiresBatch: widget.requiresBatch,
      quantityUnitLabel: 'pcs',
    );
  }
}

class _TransferOrderCreateSkeleton extends StatelessWidget {
  const _TransferOrderCreateSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ZFormSkeleton(rows: 6),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(14),
          child: const ZTableSkeleton(rows: 4, columns: 4),
        ),
        const SizedBox(height: 18),
        const ZBone(height: 16, width: 220),
        const SizedBox(height: 10),
        const ZBone(height: 42, width: 132),
      ],
    );
  }
}
